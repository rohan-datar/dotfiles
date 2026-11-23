package main

import (
	"encoding/json"
	"strings"
	"testing"
)

const testRepo = oortCloud

var headA = strings.Repeat("a", 40)
var headB = strings.Repeat("b", 40)
var base = strings.Repeat("c", 40)

func pklPin(v, digest string) string {
	return `  image = "ghcr.io/vendor/widget:v` + v + `@sha256:` + strings.Repeat(digest, 64) + `"`
}

func patch(old, new string) Delta {
	return Delta{Filename: "apps/widget/app.pkl", Status: "modified", Additions: 1, Deletions: 1, Patch: "@@ -1 +1 @@\n-" + old + "\n+" + new}
}

func TestDiffClassifier(t *testing.T) {
	a := pklPin("1.2.3", "a")
	b := pklPin("1.2.4", "b")
	chart := patch(`  version = "1.2.3"`, `  version = "1.2.4"`)
	chart.Patch = "@@ -1,2 +1,2 @@\n   // renovate: datasource=helm depName=demo registryUrl=https://example.com/charts\n" + strings.SplitN(chart.Patch, "\n", 2)[1]
	missingAnnot := patch(`  version = "1.2.3"`, `  version = "1.2.4"`)
	addedFile := patch(a, b)
	addedFile.Status = "added"
	rawCode := patch(a, b)
	rawCode.Filename = "scripts/install.pkl"
	rename := patch(a, b)
	rename.Status = "renamed"
	truncated := patch(a, b)
	truncated.Additions, truncated.Deletions = 2, 2
	lock := Delta{Filename: "flake.lock", Status: "modified"}
	for _, tc := range []struct {
		name           string
		changes        []Delta
		want, lockOnly bool
	}{
		{"patch", []Delta{patch(a, b)}, true, false},
		{"minor", []Delta{patch(a, pklPin("1.3.0", "b"))}, true, false},
		{"major", []Delta{patch(a, pklPin("2.0.0", "b"))}, false, false},
		{"downgrade", []Delta{patch(a, pklPin("1.2.2", "b"))}, false, false},
		{"digestOnly", []Delta{patch(a, pklPin("1.2.3", "b"))}, false, false},
		{"sameDigest", []Delta{patch(a, pklPin("1.2.4", "a"))}, false, false},
		{"otherPackage", []Delta{patch(a, strings.Replace(b, "widget", "impostor", 1))}, false, false},
		{"sideEffect", []Delta{patch(a, b+`; dangerous = true`)}, false, false},
		{"whitespace", []Delta{patch(a, "  "+b)}, false, false},
		{"chart", []Delta{chart}, true, false},
		{"missingAnnot", []Delta{missingAnnot}, false, false},
		{"added", []Delta{addedFile}, false, false},
		{"renamed", []Delta{rename}, false, false},
		{"rawCode", []Delta{rawCode}, false, false},
		{"truncated", []Delta{truncated}, false, false},
		{"empty", nil, false, false},
		{"lockOnly", []Delta{lock}, true, true},
		{"lockInOort", []Delta{lock}, false, false},
		{"lockMixed", []Delta{lock, patch(a, b)}, false, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			repo := oortCloud
			if tc.lockOnly {
				repo = dotfiles
			}
			got, err := classify(repo, tc.changes)
			if (err == nil) != tc.want || got.LockOnly != tc.lockOnly {
				t.Fatalf("classify() = %+v, %v", got, err)
			}
		})
	}
}

func TestVersionFamilies(t *testing.T) {
	for _, test := range []struct {
		old, new string
		want     bool
	}{
		{"7.0.3.10918", "7.0.4.11345", true}, {"7.0.3.10918", "7.0.3.11345", false},
		{"7.0.3-bookworm", "7.1.0-bookworm", true}, {"7.0.3-bookworm", "7.1.0-alpine", false},
		{"7.0", "7.1", false}, {"v7.0.3", "7.0.4", false}, {"7.0.3", "7.0.4-rc1", false},
	} {
		if got := boundedBump(test.old, test.new); got != test.want {
			t.Errorf("boundedBump(%q,%q)=%v", test.old, test.new, got)
		}
	}
}

func opened(author string) Pull {
	var p Pull
	p.Number, p.State, p.User.Login = 27, "open", author
	p.Head.SHA, p.Base.SHA, p.Base.Ref = headA, base, "main"
	p.Head.Repo.FullName, p.Base.Repo.FullName = testRepo, testRepo
	return p
}

func TestAuthorGate(t *testing.T) {
	for author, expected := range map[string]string{"rohan-datar": "pass", "renovate[bot]": "pass", agent: "deny", "different[bot]": "pass", "": "deny"} {
		if kind, _ := preliminary(opened(author), testRepo); kind != expected {
			t.Errorf("%q: got %s, want %s", author, kind, expected)
		}
	}
	p := opened(agent)
	p.Labels = []struct{ Name string }{{"security-autofix"}}
	p.Body = "Update for GHSA-abc2-def3-xyz4"
	if kind, _ := preliminary(p, testRepo); kind != "fix" {
		t.Errorf("got %s, want fix", kind)
	}
	p.Labels = append(p.Labels, struct{ Name string }{"auto-revert"})
	if kind, _ := preliminary(p, testRepo); kind != "revert" {
		t.Errorf("got %s, want revert", kind)
	}
	p.Head.Repo.FullName = "other/oort-cloud"
	if kind, _ := preliminary(p, testRepo); kind != "deny" {
		t.Errorf("got %s, want deny", kind)
	}
	if _, err := classify(dotfiles, []Delta{patch(pklPin("1.2.3", "a"), pklPin("1.2.4", "b"))}); err == nil {
		t.Error("accepted Pkl changes in dotfiles")
	}
}

func lockDocument(rev, channel, host string, other bool) []byte {
	m := map[string]any{"version": 7, "root": "root", "nodes": map[string]any{
		"root": map[string]any{"inputs": map[string]any{"nixpkgs": "nixpkgs_2"}},
		"nixpkgs_2": map[string]any{
			"original": map[string]any{"type": "tarball", "url": "https://channels.nixos.org/" + channel + "/nixexprs.tar.zst"},
			"locked":   map[string]any{"type": "tarball", "lastModified": 1795249095, "narHash": "sha256-" + strings.Repeat("A", 43) + "=", "rev": rev, "url": "https://" + host + "/nixpkgs/nixpkgs-26.11pre1125912." + rev[:12] + "/nixexprs.tar.zst"},
		},
	}}
	if other {
		m["nodes"].(map[string]any)["foreign"] = "added"
	}
	b, _ := json.MarshalIndent(m, "", "  ")
	return b
}

func TestLockPolicy(t *testing.T) {
	canonical := func(rev string) []byte { return lockDocument(rev, "nixpkgs-unstable", "releases.nixos.org", false) }
	a, b := canonical(headA), canonical(headB)
	l, err := lockChange(a, b)
	if err != nil || l.Old != headA || l.New != headB || l.Ref != "nixpkgs-unstable" {
		t.Fatalf("%+v %v", l, err)
	}
	for _, bad := range [][]byte{
		a, lockDocument(headB, "nixos-unstable", "releases.nixos.org", false),
		lockDocument(headB, "nixpkgs-unstable", "evil.example", false),
		lockDocument(headB, "nixpkgs-unstable", "releases.nixos.org", true),
		[]byte(strings.Replace(string(b), "\"root\": \"root\",", "\"root\": \"foreign\",\n  \"root\": \"root\",", 1)),
		append(append([]byte(nil), b...), []byte("{}")...),
	} {
		if _, err := lockChange(a, bad); err == nil {
			t.Error("unsafe lock change accepted")
		}
	}
}

func TestExactInverseAndTreeCompleteness(t *testing.T) {
	a, b := entry{Mode: "100644", SHA: headA, Path: "a", Type: "blob"}, entry{Mode: "100644", SHA: headB, Path: "a", Type: "blob"}
	if _, err := diffState(map[string]entry{"a": a}, map[string]entry{"a": b}, nil); err == nil {
		t.Fatal("unlisted changed file accepted")
	}
	original := map[string]fileState{"a": {a, b}}
	if !inverse(original, map[string]fileState{"a": {b, a}}) {
		t.Fatal("exact reversal not recognized")
	}
	wrongMode := a
	wrongMode.Mode = "100755"
	if inverse(original, map[string]fileState{"a": {b, wrongMode}}) {
		t.Fatal("mode change accepted")
	}
	if inverse(original, map[string]fileState{"a": {b, a}, "b": {a, b}}) {
		t.Fatal("extra change accepted")
	}
}
