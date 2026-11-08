"""Member 4 interface: GUI-independent validation and calls to SWI-Prolog.

No third-party Python packages required. Each call uses an isolated Prolog
process; administrator storage and route search remain teammates' components.
"""
from __future__ import annotations

import json
import math
import os
from pathlib import Path
import shutil
import subprocess

OPTIONS = {"avoid_unpaved", "avoid_broken_cisterns", "avoid_deep_potholes"}
CONDITIONS = {"broken_cistern", "deep_pothole"}
BRIDGE = Path(__file__).parent / "prolog" / "bridge.pl"


class IntegrationError(RuntimeError):
    """A useful error for the GUI to display."""


def _number(value, label):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
        raise ValueError(f"{label} must be a finite nonnegative number")


def _choices(values, allowed, label):
    if not isinstance(values, list) or any(not isinstance(v, str) or v not in allowed for v in values):
        raise ValueError(f"Invalid {label}; allowed values: {', '.join(sorted(allowed))}")


def validate_road(road):
    if not isinstance(road, dict):
        raise ValueError("Each road must be a dictionary")
    for key in ("id", "source", "destination"):
        if not isinstance(road.get(key), str) or not road[key].strip():
            raise ValueError(f"Road {key} must be a nonempty string")
    for key in ("distance", "time"):
        _number(road.get(key), key)
    for key, allowed in (("type", {"paved", "unpaved"}), ("status", {"open", "closed"}),
                         ("direction", {"one_way", "two_way"})):
        if road.get(key) not in allowed:
            raise ValueError(f"Invalid road {key}")
    _choices(road.get("conditions"), CONDITIONS, "conditions")


class PrologClient:
    def __init__(self, executable=None, timeout=10):
        self.executable = executable or os.environ.get("SWIPL") or shutil.which("swipl")
        fallback = Path("C:/Program Files/swipl/bin/swipl.exe")
        if not self.executable and fallback.exists():
            self.executable = str(fallback)
        if not self.executable:
            raise IntegrationError("SWI-Prolog was not found. Install it or set SWIPL to its executable path.")
        self.timeout = timeout

    def _call(self, request):
        try:
            result = subprocess.run(
                [self.executable, "-q", "-s", str(BRIDGE)],
                input=json.dumps(request, allow_nan=False), capture_output=True,
                text=True, encoding="utf-8", timeout=self.timeout,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise IntegrationError(f"Unable to run Prolog: {exc}") from exc
        if result.returncode:
            raise IntegrationError(f"Prolog failed: {result.stderr.strip()}")
        try:
            response = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise IntegrationError("Prolog returned an invalid response") from exc
        if not response.get("ok"):
            raise IntegrationError(response.get("error", "Unknown Prolog error"))
        return response

    def condition_time(self, base_time, conditions):
        _number(base_time, "base_time")
        _choices(conditions, CONDITIONS, "conditions")
        return self._call(dict(action="condition_time", base_time=base_time, conditions=conditions))["time"]

    def eligible_edges(self, roads, options=None):
        options = [] if options is None else options
        _choices(options, OPTIONS, "route options")
        if not isinstance(roads, list):
            raise ValueError("Roads must be a list")
        seen = set()
        for road in roads:
            validate_road(road)
            if road["id"] in seen:
                raise ValueError(f"Duplicate road id: {road['id']}")
            seen.add(road["id"])
        return self._call(dict(action="traversals", roads=roads, options=options))["edges"]
