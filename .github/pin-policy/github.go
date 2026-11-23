package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
)

const githubRoot = "https://api.github.com"
const maxAPIResponse = 8 << 20

// This client is read-only. Do not include upstream bodies, URLs or credentials
// in failure summaries. The caller disables redirects.
func request(ctx context.Context, client *http.Client, endpoint, token string, output any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return fmt.Errorf("construct upstream request")
	}
	if req.URL.Host == "api.github.com" {
		req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
		req.Header.Set("Accept", "application/vnd.github+json")
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
	} else if token != "" {
		return fmt.Errorf("refusing to send GitHub token to another host")
	}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("upstream request failed")
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("upstream returned HTTP %d", resp.StatusCode)
	}
	data, err := io.ReadAll(io.LimitReader(resp.Body, maxAPIResponse+1))
	if err != nil || len(data) > maxAPIResponse || bytes.Equal(bytes.TrimSpace(data), []byte("null")) || json.Unmarshal(data, output) != nil {
		return fmt.Errorf("invalid or oversized upstream response")
	}
	return nil
}

type GitHub struct {
	client *http.Client
	token  string
}

func (gh *GitHub) repo(ctx context.Context, repo, path string, output any) error {
	if repo != oortCloud && repo != dotfiles {
		return fmt.Errorf("repository not allowed")
	}
	return request(ctx, gh.client, githubRoot+"/repos/"+repo+path, gh.token, output)
}

func (gh *GitHub) pull(ctx context.Context, repo string, n int) (Pull, error) {
	var p Pull
	err := gh.repo(ctx, repo, fmt.Sprintf("/pulls/%d", n), &p)
	if err == nil && (p.Number != n || p.User.Login == "") {
		err = fmt.Errorf("unexpected PR identity")
	}
	return p, err
}

type comparison struct {
	Status    string
	MergeBase struct{ SHA string } `json:"merge_base_commit"`
	Files     []Delta
}

func (gh *GitHub) compare(ctx context.Context, repo, base, head string) (comparison, error) {
	var out comparison
	if !sha.MatchString(base) || !sha.MatchString(head) {
		return out, fmt.Errorf("invalid compare SHA")
	}
	err := gh.repo(ctx, repo, "/compare/"+base+"..."+head+"?per_page=1", &out)
	return out, err
}

type entry struct{ Mode, SHA, Path, Type string }

type fileState struct{ Before, After entry }

type diff struct {
	Files []Delta
	State map[string]fileState
}

func (gh *GitHub) tree(ctx context.Context, repo, rev string) (map[string]entry, error) {
	if !sha.MatchString(rev) {
		return nil, fmt.Errorf("invalid tree SHA")
	}
	var out struct {
		Truncated bool
		Tree      []entry
	}
	if err := gh.repo(ctx, repo, "/git/trees/"+rev+"?recursive=1", &out); err != nil {
		return nil, err
	}
	if out.Truncated {
		return nil, fmt.Errorf("git tree exceeded API limit")
	}
	tree := make(map[string]entry, len(out.Tree))
	if out.Tree == nil {
		return nil, fmt.Errorf("missing Git tree data")
	}
	for _, e := range out.Tree {
		if e.Path == "" || !sha.MatchString(e.SHA) || e.Mode == "" || e.Type == "" {
			return nil, fmt.Errorf("unreadable Git tree entry")
		}
		if e.Type != "tree" {
			if _, exists := tree[e.Path]; exists {
				return nil, fmt.Errorf("duplicate Git tree entry")
			}
			tree[e.Path] = e
		}
	}
	return tree, nil
}

func diffState(before, after map[string]entry, files []Delta) (map[string]fileState, error) {
	state := make(map[string]fileState, len(files))
	put := func(path string, a, b entry) bool {
		if _, exists := state[path]; exists || a == b {
			return false
		}
		state[path] = fileState{a, b}
		return true
	}
	for _, f := range files {
		if f.Filename == "" || !sha.MatchString(f.SHA) {
			return nil, fmt.Errorf("invalid comparison file entry")
		}
		a, b := before[f.Filename], after[f.Filename]
		if f.Status == "renamed" {
			old := before[f.PreviousFilename]
			if old.SHA == "" || a.SHA != "" || b.SHA != f.SHA || after[f.PreviousFilename].SHA != "" ||
				!put(f.PreviousFilename, old, entry{}) || !put(f.Filename, entry{}, b) {
				return nil, fmt.Errorf("invalid rename tree entries")
			}
			continue
		}
		if !put(f.Filename, a, b) {
			return nil, fmt.Errorf("duplicate or unchanged diff entry")
		}
		if (b.SHA != "" && f.SHA != b.SHA) || (b.SHA == "" && f.SHA != a.SHA) {
			return nil, fmt.Errorf("file SHA differs from tree")
		}
	}

	for path, a := range before {
		if a != after[path] {
			if _, ok := state[path]; !ok {
				return nil, fmt.Errorf("incomplete diff: missing changed tree entry")
			}
		}
	}
	for path := range after {
		if _, existed := before[path]; !existed {
			if _, ok := state[path]; !ok {
				return nil, fmt.Errorf("incomplete diff: missing added tree entry")
			}
		}
	}
	return state, nil
}

func (gh *GitHub) diff(ctx context.Context, repo, base, head string, requireCurrentBase bool) (diff, error) {
	c, err := gh.compare(ctx, repo, base, head)
	if err != nil {
		return diff{}, err
	}
	if requireCurrentBase && (c.Status != "ahead" || c.MergeBase.SHA != base) {
		return diff{}, fmt.Errorf("PR branch is not up to date with main")
	}
	if len(c.Files) == 0 || len(c.Files) > maxFiles {
		return diff{}, fmt.Errorf("empty or oversized diff")
	}
	if !sha.MatchString(c.MergeBase.SHA) || (c.Status != "ahead" && c.Status != "diverged") {
		return diff{}, fmt.Errorf("could not verify comparison base")
	}
	before, err := gh.tree(ctx, repo, c.MergeBase.SHA)
	if err != nil {
		return diff{}, err
	}
	after, err := gh.tree(ctx, repo, head)
	if err != nil {
		return diff{}, err
	}
	state, err := diffState(before, after, c.Files)
	return diff{c.Files, state}, err
}

func (gh *GitHub) blob(ctx context.Context, repo, rev string) ([]byte, error) {
	if !sha.MatchString(rev) {
		return nil, fmt.Errorf("invalid blob SHA")
	}
	var out struct{ Encoding, Content string }
	if err := gh.repo(ctx, repo, "/git/blobs/"+rev, &out); err != nil {
		return nil, err
	}
	if out.Encoding != "base64" {
		return nil, fmt.Errorf("unexpected encoding for Git blob")
	}
	return base64.StdEncoding.DecodeString(out.Content)
}

func (gh *GitHub) lockFastForward(ctx context.Context, repo string, s fileState) (bool, error) {
	a, err := gh.blob(ctx, repo, s.Before.SHA)
	if err != nil {
		return false, err
	}
	b, err := gh.blob(ctx, repo, s.After.SHA)
	if err != nil {
		return false, err
	}
	change, err := lockChange(a, b)
	if err != nil {
		return false, err
	}
	var c comparison
	// Compare's file patches only appear on page 1. Only ancestry is needed here.
	endpoint := fmt.Sprintf("%s/repos/%s/%s/compare/%s...%s?per_page=1&page=2", githubRoot, change.Owner, change.Repo, change.Old, change.New)
	if err := request(ctx, gh.client, endpoint, gh.token, &c); err != nil {
		return false, err
	}
	if c.Status != "ahead" || c.MergeBase.SHA != change.Old {
		return false, nil
	}
	// GitHub may resolve a SHA from a fork in the same network; a mere
	// fast-forward could introduce arbitrary fork code. Require the proposed
	// revision to be an ancestor of the fixed original upstream branch too.
	endpoint = fmt.Sprintf("%s/repos/%s/%s/compare/%s...%s?per_page=1&page=2", githubRoot, change.Owner, change.Repo, change.New, change.Ref)
	if err := request(ctx, gh.client, endpoint, gh.token, &c); err != nil {
		return false, err
	}
	return (c.Status == "identical" || c.Status == "ahead") && c.MergeBase.SHA == change.New, nil
}

func inverse(original, proposed map[string]fileState) bool {
	if len(original) == 0 || len(original) != len(proposed) {
		return false
	}
	for path, s := range original {
		if proposed[path] != (fileState{s.After, s.Before}) {
			return false
		}
	}
	return true
}

func (gh *GitHub) isRevert(ctx context.Context, repo string, p Pull) (bool, error) {
	refs := revertRef.FindAllString(p.Body, 2)
	if len(refs) != 1 {
		return false, nil
	}
	n, _ := strconv.Atoi(strings.TrimSpace(strings.TrimPrefix(refs[0], "Reverts #")))
	if n == p.Number {
		return false, nil
	}
	prior, err := gh.pull(ctx, repo, n)
	if err != nil {
		return false, err
	}
	if !prior.Merged || prior.Base.Ref != "main" || prior.Base.Repo.FullName != repo ||
		prior.User.Login != agent || !sha.MatchString(prior.MergeCommit) || !sha.MatchString(prior.Head.SHA) {
		return false, nil
	}
	var commit struct {
		SHA     string
		Parents []struct{ SHA string }
	}
	if err := gh.repo(ctx, repo, "/git/commits/"+prior.MergeCommit, &commit); err != nil {
		return false, err
	}
	if commit.SHA != prior.MergeCommit || len(commit.Parents) < 1 || len(commit.Parents) > 2 ||
		(len(commit.Parents) == 2 && commit.Parents[1].SHA != prior.Head.SHA) {
		return false, nil
	}
	parent := commit.Parents[0].SHA
	original, err := gh.diff(ctx, repo, parent, prior.MergeCommit, true)
	if err != nil {
		return false, err
	}
	// A rebase with several commits reports only its last integration SHA.
	// Compare the complete original PR too so a partial inverse cannot pass.
	priorPR, err := gh.diff(ctx, repo, parent, prior.Head.SHA, false)
	if err != nil {
		return false, err
	}
	if len(original.State) != len(priorPR.State) {
		return false, nil
	}
	for path, state := range original.State {
		if priorPR.State[path] != state {
			return false, nil
		}
	}
	proposed, err := gh.diff(ctx, repo, p.Base.SHA, p.Head.SHA, true)
	if err != nil {
		return false, err
	}
	return inverse(original.State, proposed.State), nil
}
