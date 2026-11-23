package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
)

type transportFunc func(*http.Request) (*http.Response, error)

func (f transportFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func mockGitHub(t *testing.T, reply func(*http.Request) (int, any)) *GitHub {
	t.Helper()
	client := &http.Client{Transport: transportFunc(func(req *http.Request) (*http.Response, error) {
		if req.Method != http.MethodGet || req.URL.Host != "api.github.com" || req.Header.Get("Authorization") != "Bearer test" {
			t.Fatal("request is not an authenticated GitHub GET")
		}
		status, value := reply(req)
		body, err := json.Marshal(value)
		if err != nil {
			t.Fatal(err)
		}
		return &http.Response{StatusCode: status, Body: io.NopCloser(strings.NewReader(string(body)))}, nil
	})}
	return &GitHub{client: client, token: "test"}
}

func TestEvaluateAuthorAndAPIError(t *testing.T) {
	for _, tc := range []struct {
		name, author, eventHead string
		status                  int
		wantError               string
	}{
		{"non-agent", "other[bot]", headA, 200, ""},
		{"missing label", agent, headA, 200, "Missing security-autofix"},
		{"stale head", agent, headB, 200, "head has changed"},
		{"API error", "other[bot]", headA, 403, "HTTP 403"},
		{"missing author", "", headA, 200, "unexpected PR identity"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			gh := mockGitHub(t, func(req *http.Request) (int, any) {
				if req.URL.Path != "/repos/"+testRepo+"/pulls/27" {
					t.Fatal("unexpected call before policy decision")
				}
				return tc.status, opened(tc.author)
			})
			msg, err := gh.evaluate(context.Background(), testRepo, 27, tc.eventHead)
			if tc.wantError == "" && (err != nil || msg == "") || tc.wantError != "" && (err == nil || !strings.Contains(err.Error(), tc.wantError)) {
				t.Fatalf("message=%q, error=%v; wanted error containing %q", msg, err, tc.wantError)
			}
		})
	}
}

func compareJSON(status, mergeBase string, changes ...Delta) map[string]any {
	return map[string]any{"status": status, "merge_base_commit": map[string]string{"sha": mergeBase}, "files": changes}
}

func TestEvaluateSecurityFix(t *testing.T) {
	for _, tc := range []struct{ name, wantError string }{
		{"accept", ""}, {"patch omitted", "missing or non-paired patch"}, {"changed mode", "file mode changes"},
		{"advisory API fails", "HTTP 503"}, {"label removed", "inputs changed"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			p := opened(agent)
			p.Labels = []struct{ Name string }{{"security-autofix"}}
			p.Body = "CVE-2026-1234"
			change := patch(pklPin("1.9.8", "a"), pklPin("1.10.0", "b"))
			change.SHA = headB
			if tc.name == "patch omitted" {
				change.Patch = ""
			}
			mode := "100644"
			if tc.name == "changed mode" {
				mode = "100755"
			}
			reads := 0
			gh := mockGitHub(t, func(req *http.Request) (int, any) {
				switch strings.TrimPrefix(req.URL.Path, "/repos/"+testRepo) {
				case "/pulls/27":
					reads++
					if reads == 2 && tc.name == "label removed" {
						p.Labels = nil
					}
					return 200, p
				case "/compare/" + base + "..." + headA:
					return 200, compareJSON("ahead", base, change)
				case "/git/trees/" + base:
					return 200, map[string]any{"tree": []entry{{Mode: "100644", SHA: headA, Path: change.Filename, Type: "blob"}}}
				case "/git/trees/" + headA:
					return 200, map[string]any{"tree": []entry{{Mode: mode, SHA: change.SHA, Path: change.Filename, Type: "blob"}}}
				case "/advisories":
					if tc.name == "advisory API fails" {
						return 503, map[string]string{"message": "unavailable"}
					}
					return 200, json.RawMessage(`[{"cve_id":"CVE-2026-1234","severity":"critical","vulnerabilities":[{"package":{"name":"widget"}}]}]`)
				}
				t.Fatal("unexpected API endpoint")
				return 404, nil
			})
			msg, err := gh.evaluate(context.Background(), testRepo, 27, headA)
			if tc.wantError == "" && (err != nil || msg != "Verified pin-only security update: CVE-2026-1234") || tc.wantError != "" && (err == nil || !strings.Contains(err.Error(), tc.wantError)) {
				t.Fatalf("message=%q, error=%v; wanted error containing %q", msg, err, tc.wantError)
			}
		})
	}
}

func TestLockFastForward(t *testing.T) {
	for _, upstream := range []bool{true, false} {
		t.Run(fmt.Sprintf("upstream=%v", upstream), func(t *testing.T) {
			gh := mockGitHub(t, func(req *http.Request) (int, any) {
				prefix := "/repos/" + dotfiles + "/git/blobs/"
				if rev, ok := strings.CutPrefix(req.URL.Path, prefix); ok {
					if rev != headA && rev != headB {
						t.Fatal("unexpected lock blob")
					}
					return 200, map[string]string{"encoding": "base64", "content": base64.StdEncoding.EncodeToString(lockDocument(rev, "nixpkgs-unstable", "releases.nixos.org", false))}
				}
				switch req.URL.Path {
				case "/repos/NixOS/nixpkgs/compare/" + headA + "..." + headB:
					return 200, compareJSON("ahead", headA)
				case "/repos/NixOS/nixpkgs/compare/" + headB + "...nixpkgs-unstable":
					if upstream {
						return 200, compareJSON("ahead", headB)
					}
					return 200, compareJSON("diverged", headA)
				}
				t.Fatal("unexpected API endpoint")
				return 404, nil
			})
			got, err := gh.lockFastForward(context.Background(), dotfiles, fileState{Before: entry{SHA: headA}, After: entry{SHA: headB}})
			if err != nil || got != upstream {
				t.Fatalf("verified=%v, err=%v", got, err)
			}
		})
	}
}

func TestVerifyRevert(t *testing.T) {
	for _, tc := range []struct {
		name                                string
		priorAuthor                         string
		priorMatches, proposedMatches, want bool
	}{
		{"exact", agent, true, true, true},
		{"not exact", agent, true, false, false},
		{"partial integration", agent, false, true, false},
		{"not agent", "rohan-datar", true, true, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			parent, merged, originalHead := strings.Repeat("1", 40), strings.Repeat("2", 40), strings.Repeat("3", 40)
			p := opened(agent)
			p.Body = "Reverts #21"
			prior := opened(tc.priorAuthor)
			prior.Number, prior.Merged, prior.MergeCommit, prior.Head.SHA = 21, true, merged, originalHead
			before, after := entry{Mode: "100644", SHA: headA, Path: "flake.lock", Type: "blob"}, entry{Mode: "100644", SHA: headB, Path: "flake.lock", Type: "blob"}
			other := before
			other.SHA = strings.Repeat("4", 40)
			priorAfter, proposedAfter := after, before
			if !tc.priorMatches {
				priorAfter = other
			}
			if !tc.proposedMatches {
				proposedAfter = other
			}
			delta := func(e entry) Delta { return Delta{Filename: e.Path, SHA: e.SHA, Status: "modified"} }
			tree := func(e entry) map[string]any { return map[string]any{"tree": []entry{e}} }
			gh := mockGitHub(t, func(req *http.Request) (int, any) {
				switch strings.TrimPrefix(req.URL.Path, "/repos/"+testRepo) {
				case "/pulls/21":
					return 200, prior
				case "/git/commits/" + merged:
					return 200, map[string]any{"sha": merged, "parents": []map[string]string{{"sha": parent}}}
				case "/compare/" + parent + "..." + merged:
					return 200, compareJSON("ahead", parent, delta(after))
				case "/compare/" + parent + "..." + originalHead:
					return 200, compareJSON("ahead", parent, delta(priorAfter))
				case "/compare/" + p.Base.SHA + "..." + p.Head.SHA:
					return 200, compareJSON("ahead", p.Base.SHA, delta(proposedAfter))
				case "/git/trees/" + parent:
					return 200, tree(before)
				case "/git/trees/" + merged:
					return 200, tree(after)
				case "/git/trees/" + originalHead:
					return 200, tree(priorAfter)
				case "/git/trees/" + p.Base.SHA:
					return 200, tree(after)
				case "/git/trees/" + p.Head.SHA:
					return 200, tree(proposedAfter)
				}
				t.Fatal("unexpected API endpoint")
				return 404, nil
			})
			got, err := gh.isRevert(context.Background(), testRepo, p)
			if err != nil || got != tc.want {
				t.Fatalf("verified=%t, err=%v", got, err)
			}
		})
	}
}
