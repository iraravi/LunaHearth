#!/usr/bin/env python3
"""Offline repository checks. This is not a vulnerability scanner or Sonar quality gate.
Reports locations only, never suspected secret values. No network access.
"""
import json
import pathlib
import plistlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent.parent
findings = []
checks = []

def finding(rule, path, line=None):
    findings.append(dict(rule=rule, file=str(path), line=line))

rules = {
    "forced-try-or-cast": r"\b(?:try|as)!\s",
    "unsafe-concurrency-override": r"@unchecked\s+Sendable|nonisolated\(unsafe\)",
    "third-party-runtime-import": r"^import\s+(?:Firebase\w*|Supabase|Realm\w*|Sentry|Amplitude|Mixpanel|OpenAI|Anthropic)\b",
    "private-key-material": r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "credential-literal": r"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,}|AKIA[A-Z0-9]{16})\b",
}
sources = sorted((root / "LunaHearth").rglob("*.swift"))
for path in sources:
    text = path.read_text()
    for rule, pattern in rules.items():
        for match in re.finditer(pattern, text, re.MULTILINE):
            finding(rule, path.relative_to(root), text.count("\n", 0, match.start()) + 1)
checks.append(dict(check="production-source-patterns", files=len(sources)))

info = plistlib.loads((root / "LunaHearth/Resources/Info.plist").read_bytes())
ats = info.get("NSAppTransportSecurity", {})
if ats.get("NSAllowsArbitraryLoads") or ats.get("NSAllowsArbitraryLoadsInWebContent") or ats.get("NSExceptionDomains"):
    finding("transport-security-exception-review", "LunaHearth/Resources/Info.plist")
for key in ("NSCameraUsageDescription", "NSCalendarsFullAccessUsageDescription", "NSRemindersFullAccessUsageDescription"):
    if not str(info.get(key, "")).strip():
        finding("missing-permission-purpose-" + key, "LunaHearth/Resources/Info.plist")
privacy = plistlib.loads((root / "LunaHearth/Resources/PrivacyInfo.xcprivacy").read_bytes())
if privacy.get("NSPrivacyTracking") is not False:
    finding("tracking-declaration-review", "LunaHearth/Resources/PrivacyInfo.xcprivacy")
reasons = {x.get("NSPrivacyAccessedAPIType"): x.get("NSPrivacyAccessedAPITypeReasons", []) for x in privacy.get("NSPrivacyAccessedAPITypes", [])}
if "CA92.1" not in reasons.get("NSPrivacyAccessedAPICategoryUserDefaults", []):
    finding("missing-app-defaults-reason", "LunaHearth/Resources/PrivacyInfo.xcprivacy")
checks.append(dict(check="privacy-permissions-and-transport-plists"))

project = (root / "project.yml").read_text()
for expected in ("SWIFT_VERSION: 6.0", "SWIFT_STRICT_CONCURRENCY: complete", 'iOS: "18.0"', "dependencies: []"):
    if expected not in project:
        finding("project-contract-review: " + expected, "project.yml")
checks.append(dict(check="swift-concurrency-minimum-os-and-runtime-dependencies"))
tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
for name in filter(None, tracked):
    path = pathlib.Path(name)
    if path.suffix in (".p8", ".p12", ".mobileprovision") or path.name in (".env", ".env.local"):
        finding("tracked-credential-file", name)
    if path.suffix in (".swift", ".py", ".sh", ".yml", ".yaml", ".json", ".properties") and (root / path).is_file():
        text = (root / path).read_text()
        for rule in ("private-key-material", "credential-literal"):
            for match in re.finditer(rules[rule], text):
                if path.parts[0] != "LunaHearth":
                    finding(rule, name, text.count("\n", 0, match.start()) + 1)
checks.append(dict(check="tracked-credential-files-and-common-literal-patterns"))
print(json.dumps(dict(scope="offline heuristic checks; no Sonar scan, CVE database or live Apple validation", checks=checks, findings=findings), indent=2))
sys.exit(bool(findings))
