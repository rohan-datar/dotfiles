package main

import (
	"context"
	"fmt"
	"net/url"
	"strings"
)

const nvdURL = "https://services.nvd.nist.gov/rest/json/cves/2.0"

func (gh *GitHub) critical(ctx context.Context, id string, components []string, isLock bool) (bool, error) {
	query := "ghsa_id"
	if strings.HasPrefix(id, "CVE-") {
		query = "cve_id"
	}
	var advisories []struct {
		GHSA           string `json:"ghsa_id"`
		CVE            string `json:"cve_id"`
		Type, Severity string
		Withdrawn      *string `json:"withdrawn_at"`
		CVSS           struct{ Score float64 }
		CVSSSeverities struct {
			V3 struct{ Score float64 } `json:"cvss_v3"`
			V4 struct{ Score float64 } `json:"cvss_v4"`
		} `json:"cvss_severities"`
		Vulnerabilities []struct{ Package struct{ Name string } }
	}
	endpoint := githubRoot + "/advisories?per_page=30&" + query + "=" + url.QueryEscape(id)
	err := request(ctx, gh.client, endpoint, gh.token, &advisories)
	if err != nil {
		return false, fmt.Errorf("query GitHub advisories: %w", err)
	}
	if len(advisories) >= 30 {
		return false, fmt.Errorf("too many matching GitHub advisories to verify")
	}
	for _, a := range advisories {
		if (a.GHSA != id && a.CVE != id) || a.Withdrawn != nil || a.Type == "malware" ||
			(a.Severity != "critical" && max(a.CVSS.Score, a.CVSSSeverities.V3.Score, a.CVSSSeverities.V4.Score) < 9) {
			continue
		}
		// Every changed component must match: an unrelated image/chart must
		// not ride along with a qualifying update. Ecosystem aliases are not guessed.
		all := len(components) > 0
		for _, c := range components {
			matched := false
			for _, v := range a.Vulnerabilities {
				if matchesPackage(c, v.Package.Name) {
					matched = true
					break
				}
			}
			all = all && matched
		}
		if all {
			return true, nil
		}
		if isLock {
			for _, v := range a.Vulnerabilities {
				switch strings.ToLower(v.Package.Name) {
				case "linux", "linux_kernel", "linux-kernel", "nixpkgs":
					return true, nil
				}
			}
		}
	}
	if isLock && query == "cve_id" {
		return gh.criticalKernelCVE(ctx, id)
	}
	return false, nil
}

func (gh *GitHub) criticalKernelCVE(ctx context.Context, id string) (bool, error) {
	type cvss struct {
		Data struct {
			Score    float64 `json:"baseScore"`
			Severity string  `json:"baseSeverity"`
		} `json:"cvssData"`
	}
	var out struct {
		Vulnerabilities []struct {
			CVE struct {
				ID             string
				Status         string `json:"vulnStatus"`
				Metrics        map[string][]cvss
				Configurations []struct {
					Nodes []struct {
						Matches []struct {
							Vulnerable bool
							Criteria   string
						} `json:"cpeMatch"`
					}
				}
			}
		}
	}
	// NVD is public. Never send the installation token to another origin.
	if err := request(ctx, gh.client, nvdURL+"?cveId="+url.QueryEscape(id), "", &out); err != nil {
		return false, fmt.Errorf("query NVD: %w", err)
	}
	for _, v := range out.Vulnerabilities {
		c := v.CVE
		if c.ID != id || c.Status == "Rejected" {
			continue
		}
		critical := false
		for _, name := range []string{"cvssMetricV40", "cvssMetricV31", "cvssMetricV30", "cvssMetricV2"} {
			for _, m := range c.Metrics[name] {
				if (m.Data.Score >= 9 && m.Data.Score <= 10) || strings.EqualFold(m.Data.Severity, "critical") {
					critical = true
				}
			}
		}
		if !critical {
			continue
		}
		for _, config := range c.Configurations {
			for _, node := range config.Nodes {
				for _, m := range node.Matches {
					if m.Vulnerable && strings.HasPrefix(m.Criteria, "cpe:2.3:o:linux:linux_kernel:") {
						return true, nil
					}
				}
			}
		}
	}
	return false, nil
}
