package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"
)

func (gh *GitHub) evaluate(ctx context.Context, repo string, n int, eventHead string) (string, error) {
	p, err := gh.pull(ctx, repo, n)
	if err != nil {
		return "", fmt.Errorf("read pull request: %w", err)
	}
	if !sha.MatchString(eventHead) || eventHead != p.Head.SHA {
		return "", fmt.Errorf("pull request head has changed since this run was queued")
	}
	kind, reason := preliminary(p, repo)
	switch kind {
	case "pass":
		return reason, nil
	case "revert":
		ok, err := gh.isRevert(ctx, repo, p)
		if err != nil {
			return "", fmt.Errorf("verify revert: %w", err)
		}
		if !ok {
			return "", fmt.Errorf("not the exact inverse of a previously merged pallas-agent PR (use Reverts #N)")
		}
		reason = "Verified exact inverse of a previously merged pallas-agent PR"
	case "fix":
		reason, err = gh.securityFix(ctx, repo, p)
		if err != nil {
			return "", err
		}
	default:
		return "", fmt.Errorf("%s", reason)
	}
	current, err := gh.pull(ctx, repo, n)
	if err != nil {
		return "", fmt.Errorf("re-read pull request: %w", err)
	}
	if !current.target(repo) || !p.samePolicyInput(current) {
		return "", fmt.Errorf("PR policy inputs changed during verification; start a fresh run")
	}
	return reason, nil
}

func (gh *GitHub) securityFix(ctx context.Context, repo string, p Pull) (string, error) {
	diff, err := gh.diff(ctx, repo, p.Base.SHA, p.Head.SHA, true)
	if err != nil {
		return "", fmt.Errorf("verify complete diff against main: %w", err)
	}
	pins, err := classify(repo, diff.Files)
	if err != nil {
		return "", err
	}
	for _, s := range diff.State {
		if s.Before.Mode != "100644" || s.After.Mode != s.Before.Mode || s.Before.Type != "blob" || s.After.Type != "blob" {
			return "", fmt.Errorf("file mode changes, symlinks and submodules require owner approval")
		}
	}
	if pins.LockOnly {
		ok, err := gh.lockFastForward(ctx, repo, diff.State["flake.lock"])
		if err != nil {
			return "", fmt.Errorf("verify canonical nixpkgs update: %w", err)
		}
		if !ok {
			return "", fmt.Errorf("nixpkgs update is not a fast-forward on the canonical channel")
		}
	}
	ids := advisoryID.FindAllString(p.Body, 7)
	if len(ids) > 6 {
		return "", fmt.Errorf("too many cited advisories to verify")
	}
	for _, id := range ids {
		ok, err := gh.critical(ctx, id, pins.Components, pins.LockOnly)
		if err != nil {
			return "", fmt.Errorf("verify advisory %s: %w", id, err)
		}
		if ok {
			return "Verified pin-only security update: " + id, nil
		}
	}
	return "", fmt.Errorf("no verified critical advisory matches the update")
}

func run() (string, error) {
	repo := os.Getenv("GITHUB_REPOSITORY")
	n, err := strconv.Atoi(os.Getenv("PR_NUMBER"))
	head := os.Getenv("PR_HEAD_SHA")
	token := os.Getenv("GITHUB_TOKEN")
	if err != nil || n <= 0 || !sha.MatchString(head) || token == "" || os.Getenv("GITHUB_EVENT_NAME") != "pull_request_target" {
		return "", fmt.Errorf("invalid pull_request_target environment or missing GITHUB_TOKEN")
	}
	client := &http.Client{
		Timeout:       20 * time.Second,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	gh := GitHub{client: client, token: token}
	return gh.evaluate(ctx, repo, n, head)
}

func main() {
	message, err := run()
	code := 0
	if err != nil {
		message, code = "Blocked: "+err.Error(), 1
	}
	fmt.Println("pin-policy:", message)
	if path := os.Getenv("GITHUB_STEP_SUMMARY"); path != "" {
		f, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
		if err != nil {
			fmt.Fprintln(os.Stderr, "pin-policy: cannot write step summary")
			os.Exit(1)
		}
		_, err = fmt.Fprintf(f, "### pin-policy\n\n%s\n", message)
		if closeErr := f.Close(); err != nil || closeErr != nil {
			fmt.Fprintln(os.Stderr, "pin-policy: cannot write step summary")
			os.Exit(1)
		}
	}
	os.Exit(code)
}
