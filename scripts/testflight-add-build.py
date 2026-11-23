#!/usr/bin/env python3
"""Add an uploaded build to the Developer Receipt Debug TestFlight group.

That group uses Manual build distribution, which Apple can't change after a group is created,
so run this after every upload:  python3 -I scripts/testflight-add-build.py 96
Uses the App Store Connect API key in ~/.appstoreconnect/private_keys (never stored in the repo)."""
import base64, json, os, subprocess, sys, time, urllib.request, urllib.error

KEY = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_Y78SCV37RU.p8")
KID, ISS = "Y78SCV37RU", "278f79ef-d215-47fc-82e0-b88d1239f11b"

def b64(b): return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def token():
    now = int(time.time())
    head = b64(json.dumps({"alg": "ES256", "kid": KID, "typ": "JWT"}).encode())
    body = b64(json.dumps({"iss": ISS, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}).encode())
    msg = f"{head}.{body}".encode()
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY], input=msg, capture_output=True, check=True).stdout
    # DER ECDSA signature -> raw r||s
    i = 2 + (1 if der[1] & 0x80 else 0)
    def read_int(i):
        assert der[i] == 2; n = der[i + 1]; v = der[i + 2:i + 2 + n]; return v.lstrip(b"\0").rjust(32, b"\0"), i + 2 + n
    r, i = read_int(i); s, _ = read_int(i)
    return f"{head}.{body}.{b64(r + s)}"

APP, GROUP = "6811447245", "a3280c67-8135-47f7-9d48-3e5bd050f84b"  # Developer Receipt Debug

def call(method, path, body=None):
    req = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method,
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        text = resp.read().decode()
        return json.loads(text) if text else None

build = sys.argv[1]
found = call("GET", f"/v1/builds?filter%5Bapp%5D={APP}&filter%5Bversion%5D={build}&fields%5Bbuilds%5D=version,processingState")["data"]
if not found: sys.exit(f"Build {build} not found yet. Wait for processing and try again.")
state = found[0]["attributes"]["processingState"]
if state != "VALID": sys.exit(f"Build {build} is {state}. Wait until processing finishes.")
call("POST", f"/v1/betaGroups/{GROUP}/relationships/builds", {"data": [{"type": "builds", "id": found[0]["id"]}]})
print(f"Build {build} added to Developer Receipt Debug.")
