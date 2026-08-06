"""Publish Ookla speedtest results for node_exporter's textfile collector."""

import json
import os
import subprocess
import sys
import tempfile
import time

SPEEDTEST_BIN = os.environ.get("SPEEDTEST_BIN", "speedtest")
TEXTFILE_DIR = os.environ.get(
    "TEXTFILE_DIR", "/var/lib/prometheus-node-exporter-text-files"
)
OUTPUT_NAME = "speedtest.prom"

# Ookla's CLI prompts on first run without these, which would hang a
# non-interactive unit indefinitely.
SPEEDTEST_ARGS = ["--accept-license", "--accept-gdpr", "--format=json"]

# Below systemd's TimeoutStartSec, so a wedged test is reported as a failure
# rather than being killed before it can write anything.
SPEEDTEST_TIMEOUT_SECONDS = 240

UP_HELP = "1 if the most recent WAN test succeeded, 0 otherwise."


def escape_label_value(value: object) -> str:
    """Escape a label value per the Prometheus exposition format."""
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )


def render_metric(
    name: str,
    help_text: str,
    value: float,
    labels: dict[str, object] | None = None,
) -> list[str]:
    """Render one gauge as HELP/TYPE/sample lines."""
    lines = [f"# HELP {name} {help_text}", f"# TYPE {name} gauge"]
    if labels:
        pairs = ",".join(
            f'{key}="{escape_label_value(labels[key])}"'
            for key in sorted(labels)
        )
        lines.append(f"{name}{{{pairs}}} {value}")
    else:
        lines.append(f"{name} {value}")
    return lines


def run_speedtest() -> dict:
    """Run the Ookla CLI and return its parsed result."""
    completed = subprocess.run(
        [SPEEDTEST_BIN, *SPEEDTEST_ARGS],
        capture_output=True,
        text=True,
        timeout=SPEEDTEST_TIMEOUT_SECONDS,
        check=True,
    )
    result = json.loads(completed.stdout)
    if result.get("type") != "result" or "bandwidth" not in result.get(
        "download", {}
    ):
        raise ValueError(
            f"unexpected speedtest output: {completed.stdout[:200]}"
        )
    return result


def build_success_metrics(result: dict, duration: int, now: int) -> list[str]:
    """Render the full metric set from a successful test."""
    server = result.get("server", {})
    labels = {
        "server_country": server.get("country", ""),
        "server_host": server.get("host", ""),
        "server_id": server.get("id", ""),
        # Ookla puts the city in `location` and the operator in `name`, the
        # reverse of the library the old exporter used.
        "server_name": server.get("location", ""),
        "server_sponsor": server.get("name", ""),
        "user_ip": result.get("interface", {}).get("externalIp", ""),
        "user_isp": result.get("isp", ""),
    }

    lines: list[str] = []
    lines += render_metric("speedtest_up", UP_HELP, 1)
    lines += render_metric(
        "speedtest_download_speed_Bps",
        "Download throughput in bytes per second.",
        result["download"]["bandwidth"],
        labels,
    )
    lines += render_metric(
        "speedtest_upload_speed_Bps",
        "Upload throughput in bytes per second.",
        result["upload"]["bandwidth"],
        labels,
    )
    lines += render_metric(
        "speedtest_latency_seconds",
        "Measured latency on last speed test.",
        result["ping"]["latency"] / 1000,
        labels,
    )
    lines += render_metric(
        "speedtest_jitter_seconds",
        "Latency jitter measured during the test.",
        result["ping"]["jitter"] / 1000,
        labels,
    )
    lines += render_metric(
        "speedtest_packet_loss_ratio",
        "Fraction of packets lost during the test.",
        result.get("packetLoss", 0) / 100,
        labels,
    )
    lines += render_metric(
        "speedtest_scrape_duration_seconds",
        "Wall-clock duration of the test run.",
        duration,
    )
    lines += render_metric(
        "speedtest_last_run_timestamp_seconds",
        "Unix time of the last test attempt.",
        now,
    )
    return lines


def build_failure_metrics(now: int) -> list[str]:
    """Render the failure case."""
    lines = render_metric("speedtest_up", UP_HELP, 0)
    lines += render_metric(
        "speedtest_last_run_timestamp_seconds",
        "Unix time of the last test attempt.",
        now,
    )
    return lines


def write_atomically(lines: list[str]) -> None:
    """Replace the .prom file in one step."""
    body = "\n".join(lines) + "\n"
    handle, scratch = tempfile.mkstemp(
        dir=TEXTFILE_DIR, prefix="speedtest.", suffix=".tmp"
    )
    try:
        with os.fdopen(handle, "w") as scratch_file:
            scratch_file.write(body)
        os.chmod(scratch, 0o644)
        os.replace(scratch, os.path.join(TEXTFILE_DIR, OUTPUT_NAME))
    except Exception:
        os.unlink(scratch)
        raise


def main() -> int:
    started = time.time()
    try:
        result = run_speedtest()
    except (
        OSError,
        subprocess.SubprocessError,
        json.JSONDecodeError,
        ValueError,
    ) as error:
        print(f"speedtest failed: {error}", file=sys.stderr)
        write_atomically(build_failure_metrics(int(time.time())))
        return 1

    finished = time.time()
    write_atomically(
        build_success_metrics(result, int(finished - started), int(finished))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
