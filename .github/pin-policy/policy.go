package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"path"
	"regexp"
	"strconv"
	"strings"
)

const (
	agent     = "pallas-agent[bot]"
	oortCloud = "rohan-datar/oort-cloud"
	dotfiles  = "rohan-datar/dotfiles"
	maxFiles  = 40
)

var (
	sha             = regexp.MustCompile(`^[0-9a-f]{40}$`)
	advisoryID      = regexp.MustCompile(`\b(?:GHSA-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}|CVE-[0-9]{4}-[0-9]{4,})\b`)
	revertRef       = regexp.MustCompile(`(?m)^Reverts #[1-9][0-9]{0,8}[ \t]*\r?$`)
	pklFile         = regexp.MustCompile(`^(apps|infrastructure)/(?:[A-Za-z0-9_-]+/)+[A-Za-z0-9_-]+\.pkl$`)
	imageLine       = regexp.MustCompile(`^([ \t]*(?:(?:local )?[A-Za-z_][A-Za-z0-9_]* = )?)"([a-z0-9.-]+(?::[0-9]+)?/[a-z0-9_.-]+(?:/[a-z0-9_.-]+)*):([A-Za-z0-9_.-]+)@sha256:([a-f0-9]{64})"([ \t]*)$`)
	chartLine       = regexp.MustCompile(`^([ \t]*version = )"([0-9]+\.[0-9]+\.[0-9]+)"([ \t]*)$`)
	chartAnnotation = regexp.MustCompile(`^[ \t]*// renovate: datasource=helm depName=([a-z0-9][a-z0-9._/-]*)(?:[ \t]+registryUrl=\S+)?[ \t]*$`)
	version         = regexp.MustCompile(`^(v?)([0-9]{1,9})\.([0-9]{1,9})\.([0-9]{1,9})(?:\.([0-9]{1,9}))?(-[a-z][a-z0-9]*)?$`)
	releaseTarball  = regexp.MustCompile(`^https://releases\.nixos\.org/nixpkgs/nixpkgs-[0-9]+\.[0-9]+pre[0-9]+\.([a-f0-9]{12})/nixexprs\.tar\.zst$`)
	narHash         = regexp.MustCompile(`^sha256-[A-Za-z0-9+/]{43}=$`)
	hunk            = regexp.MustCompile(`^@@ -[0-9]+(?:,([0-9]+))? \+[0-9]+(?:,([0-9]+))? @@(?: .*)?$`)
)

type Pull struct {
	Number        int
	Body, State   string
	Draft, Merged bool
	User          struct{ Login string }
	MergeCommit   string `json:"merge_commit_sha"`
	Labels        []struct{ Name string }
	Head, Base    struct {
		SHA, Ref string
		Repo     struct {
			FullName string `json:"full_name"`
		}
	}
}

func (p Pull) label(name string) bool {
	for _, l := range p.Labels {
		if l.Name == name {
			return true
		}
	}
	return false
}

func (p Pull) target(repo string) bool {
	return p.Number > 0 && p.State == "open" && !p.Merged && p.Base.Ref == "main" &&
		p.Base.Repo.FullName == repo && sha.MatchString(p.Head.SHA) && sha.MatchString(p.Base.SHA)
}

func (p Pull) samePolicyInput(current Pull) bool {
	return current.Head.SHA == p.Head.SHA && current.Base.SHA == p.Base.SHA &&
		current.Body == p.Body && current.Draft == p.Draft && current.User.Login == p.User.Login &&
		current.Head.Repo.FullName == p.Head.Repo.FullName &&
		current.label("auto-revert") == p.label("auto-revert") && current.label("security-autofix") == p.label("security-autofix")
}

type Delta struct {
	Filename, Status, Patch, SHA string
	PreviousFilename             string `json:"previous_filename"`
	Additions, Deletions         int
}

type PinDiff struct {
	Components []string
	LockOnly   bool
}

func boundedBump(old, new string) bool {
	a, b := version.FindStringSubmatch(old), version.FindStringSubmatch(new)
	if a == nil || b == nil || a[1] != b[1] || a[2] != b[2] || a[6] != b[6] || (a[5] == "") != (b[5] == "") {
		return false
	}
	// Only a real minor or patch increase; do not treat a digest-only retag or
	// a vendor-specific build/prerelease suffix as a security version bump.
	am, _ := strconv.Atoi(a[3])
	bm, _ := strconv.Atoi(b[3])
	ap, _ := strconv.Atoi(a[4])
	bp, _ := strconv.Atoi(b[4])
	return bm > am || (bm == am && bp > ap)
}

func changedPin(old, new, preceding string) (string, error) {
	a, b := imageLine.FindStringSubmatch(old), imageLine.FindStringSubmatch(new)
	if a != nil && b != nil && a[1] == b[1] && a[2] == b[2] && a[5] == b[5] && a[4] != b[4] {
		if !boundedBump(a[3], b[3]) {
			return "", fmt.Errorf("image update is not a same-major minor/patch bump")
		}
		return a[2], nil
	}
	a, b = chartLine.FindStringSubmatch(old), chartLine.FindStringSubmatch(new)
	ann := chartAnnotation.FindStringSubmatch(preceding)
	if a != nil && b != nil && ann != nil && a[1] == b[1] && a[3] == b[3] {
		if !boundedBump(a[2], b[2]) {
			return "", fmt.Errorf("chart update is not a same-major minor/patch bump")
		}
		return ann[1], nil
	}
	return "", fmt.Errorf("changed line is not an unchanged-package image or annotated Helm pin")
}

// GitHub may omit or truncate a patch. Check the hunk and whole-file counts,
// and only accept one-for-one edits; the API's immutable compare fixes the inputs.
func patchPins(f Delta) ([]string, error) {
	if f.Patch == "" || f.Additions == 0 || f.Additions != f.Deletions {
		return nil, fmt.Errorf("missing or non-paired patch")
	}
	lines := strings.Split(strings.TrimSuffix(f.Patch, "\n"), "\n")
	var pins []string
	for len(lines) > 0 {
		m := hunk.FindStringSubmatch(lines[0])
		if m == nil {
			return nil, fmt.Errorf("invalid patch hunk")
		}
		oldLeft, newLeft := 1, 1
		if m[1] != "" {
			oldLeft, _ = strconv.Atoi(m[1])
		}
		if m[2] != "" {
			newLeft, _ = strconv.Atoi(m[2])
		}
		lines = lines[1:]
		previous := ""
		for oldLeft > 0 || newLeft > 0 {
			if len(lines) == 0 || lines[0] == "" {
				return nil, fmt.Errorf("truncated patch")
			}
			line := lines[0]
			lines = lines[1:]
			switch line[0] {
			case ' ':
				oldLeft--
				newLeft--
				previous = line[1:]
			case '-':
				var before, after []string
				before = append(before, line[1:])
				for len(lines) > 0 && strings.HasPrefix(lines[0], "-") {
					before = append(before, lines[0][1:])
					lines = lines[1:]
				}
				for len(lines) > 0 && strings.HasPrefix(lines[0], "+") {
					after = append(after, lines[0][1:])
					lines = lines[1:]
				}
				if len(before) != len(after) {
					return nil, fmt.Errorf("non-paired line edit")
				}
				for i := range before {
					component, err := changedPin(before[i], after[i], previous)
					if err != nil {
						return nil, err
					}
					pins = append(pins, component)
					previous = ""
				}
				oldLeft -= len(before)
				newLeft -= len(after)
			default:
				return nil, fmt.Errorf("unexpected patch line")
			}
			if oldLeft < 0 || newLeft < 0 {
				return nil, fmt.Errorf("patch hunk count mismatch")
			}
		}
	}
	if len(pins) != f.Additions {
		return nil, fmt.Errorf("patch edit count mismatch")
	}
	return pins, nil
}

func classify(repo string, files []Delta) (PinDiff, error) {
	if len(files) == 0 || len(files) > maxFiles {
		return PinDiff{}, fmt.Errorf("empty or oversized diff")
	}
	if repo == dotfiles && len(files) == 1 && files[0].Filename == "flake.lock" && files[0].Status == "modified" {
		return PinDiff{LockOnly: true}, nil
	}
	if repo != oortCloud {
		return PinDiff{}, fmt.Errorf("only root nixpkgs updates in flake.lock qualify in dotfiles")
	}
	var out PinDiff
	for _, f := range files {
		if f.Status != "modified" || !pklFile.MatchString(f.Filename) {
			return PinDiff{}, fmt.Errorf("diff includes additions, removals, renames, or non-manifest files")
		}
		pins, err := patchPins(f)
		if err != nil {
			return PinDiff{}, err
		}
		out.Components = append(out.Components, pins...)
	}
	return out, nil
}

func matchesPackage(component, affected string) bool {
	affected = strings.ToLower(affected)
	return affected == component || affected == path.Base(component)
}

type lockedInput struct{ Owner, Repo, Ref, Old, New string }

// The lock graph and source identity are immutable. Only the revision and its
// content-hash/timestamp may move, for the single explicitly allowed input.
func lockChange(before, after []byte) (lockedInput, error) {
	decode := func(b []byte) (map[string]any, error) {
		var v map[string]any
		d := json.NewDecoder(bytes.NewReader(b))
		d.UseNumber()
		if err := d.Decode(&v); err != nil {
			return nil, err
		}
		if d.Decode(new(any)) != io.EOF {
			return nil, fmt.Errorf("trailing data in flake.lock")
		}
		// Read and re-encode comparison alone would hide duplicate JSON keys.
		// Nix-generated flake locks are canonically indented and sorted.
		canonical, err := json.MarshalIndent(v, "", "  ")
		if err != nil || !bytes.Equal(bytes.TrimRight(b, "\n"), canonical) {
			return nil, fmt.Errorf("flake.lock is not canonical Nix JSON")
		}
		return v, nil
	}
	a, err := decode(before)
	if err != nil {
		return lockedInput{}, err
	}
	b, err := decode(after)
	if err != nil {
		return lockedInput{}, err
	}
	get := func(doc map[string]any) (map[string]any, map[string]any) {
		nodes, _ := doc["nodes"].(map[string]any)
		root, _ := doc["root"].(string)
		rootNode, _ := nodes[root].(map[string]any)
		inputs, _ := rootNode["inputs"].(map[string]any)
		key, _ := inputs["nixpkgs"].(string)
		nix, _ := nodes[key].(map[string]any)
		locked, _ := nix["locked"].(map[string]any)
		original, _ := nix["original"].(map[string]any)
		return locked, original
	}
	la, oa := get(a)
	lb, ob := get(b)
	canonicalTarball := func(original, locked map[string]any, rev string) bool {
		if original["type"] != "tarball" || locked["type"] != "tarball" || original["url"] != "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst" {
			return false
		}
		url, _ := locked["url"].(string)
		m := releaseTarball.FindStringSubmatch(url)
		return m != nil && strings.HasPrefix(rev, m[1])
	}
	old, _ := la["rev"].(string)
	new, _ := lb["rev"].(string)
	if !canonicalTarball(oa, la, old) || !canonicalTarball(ob, lb, new) || !sha.MatchString(old) || !sha.MatchString(new) || old == new {
		return lockedInput{}, fmt.Errorf("flake.lock does not exclusively update the canonical nixpkgs revision")
	}
	hash, _ := lb["narHash"].(string)
	timestamp, ok := lb["lastModified"].(json.Number)
	if !narHash.MatchString(hash) || !ok {
		return lockedInput{}, fmt.Errorf("invalid nixpkgs metadata")
	}
	if n, err := timestamp.Int64(); err != nil || n <= 0 {
		return lockedInput{}, fmt.Errorf("invalid nixpkgs timestamp")
	}
	keys := []string{"rev", "narHash", "lastModified", "url"}
	for _, key := range keys {
		delete(la, key)
		delete(lb, key)
	}

	x, _ := json.Marshal(a)
	y, _ := json.Marshal(b)
	if !bytes.Equal(x, y) {
		return lockedInput{}, fmt.Errorf("flake.lock changed inputs, source identity, or graph")
	}
	return lockedInput{"NixOS", "nixpkgs", "nixpkgs-unstable", old, new}, nil
}

// GitHub enforces the other required CI checks; this check decides only policy.
func preliminary(p Pull, repo string) (kind, reason string) {
	if !p.target(repo) || p.User.Login == "" {
		return "deny", "Could not identify an open pull request targeting main"
	}
	if p.User.Login != agent {
		return "pass", "Not a pallas-agent PR; normal GitHub merge flow"
	}
	if p.Head.Repo.FullName != repo || p.Draft {
		return "deny", "Draft PR or unexpected head repository"
	}
	if p.label("auto-revert") {
		return "revert", ""
	}
	if !p.label("security-autofix") {
		return "deny", "Missing security-autofix or auto-revert label"
	}
	if !advisoryID.MatchString(p.Body) {
		return "deny", "No GHSA or CVE cited in the PR body"
	}
	return "fix", ""
}
