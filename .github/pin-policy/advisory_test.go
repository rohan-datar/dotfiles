package main

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"
)

func TestCriticalAdvisory(t *testing.T) {
	for _, tc := range []struct {
		name, advisory, nvd string
		components          []string
		lock, want          bool
	}{
		{"CVSS", `[{"cve_id":"CVE-2026-1234","severity":"high","cvss_severities":{"cvss_v4":{"score":9.2}},"vulnerabilities":[{"package":{"name":"widget"}}]}]`, "", []string{"ghcr.io/vendor/widget"}, false, true},
		{"critical", `[{"cve_id":"CVE-2026-1234","severity":"critical","vulnerabilities":[{"package":{"name":"widget"}}]}]`, "", []string{"widget"}, false, true},
		{"unrelatedComponent", `[{"cve_id":"CVE-2026-1234","severity":"critical","vulnerabilities":[{"package":{"name":"widget"}}]}]`, "", []string{"widget", "different"}, false, false},
		{"wrongCVE", `[{"cve_id":"CVE-2026-5678","severity":"critical","vulnerabilities":[{"package":{"name":"widget"}}]}]`, "", []string{"widget"}, false, false},
		{"withdrawn", `[{"cve_id":"CVE-2026-1234","severity":"critical","withdrawn_at":"2026-11-23","vulnerabilities":[{"package":{"name":"widget"}}]}]`, "", []string{"widget"}, false, false},
		{"kernel", `[]`, `{"vulnerabilities":[{"cve":{"id":"CVE-2026-1234","metrics":{"cvssMetricV31":[{"cvssData":{"baseScore":9.8}}]},"configurations":[{"nodes":[{"cpeMatch":[{"vulnerable":true,"criteria":"cpe:2.3:o:linux:linux_kernel:*"}]}]}]}}]}`, nil, true, true},
		{"kernelContextOnly", `[]`, `{"vulnerabilities":[{"cve":{"id":"CVE-2026-1234","metrics":{"cvssMetricV31":[{"cvssData":{"baseScore":9.8}}]},"configurations":[{"nodes":[{"cpeMatch":[{"vulnerable":false,"criteria":"cpe:2.3:o:linux:linux_kernel:*"}]}]}]}}]}`, nil, true, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := &http.Client{Transport: transportFunc(func(req *http.Request) (*http.Response, error) {
				body := tc.advisory
				if req.URL.Host == "services.nvd.nist.gov" {
					if req.Header.Get("Authorization") != "" {
						t.Fatal("GitHub credential crossed to NVD")
					}
					body = tc.nvd
				} else if req.URL.Host != "api.github.com" || req.URL.Path != "/advisories" {
					t.Fatal("unexpected endpoint")
				}
				return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body))}, nil
			})}
			gh := &GitHub{client: client, token: "test"}
			got, err := gh.critical(context.Background(), "CVE-2026-1234", tc.components, tc.lock)
			if err != nil || got != tc.want {
				t.Fatalf("verified=%t, err=%v", got, err)
			}
		})
	}
}
