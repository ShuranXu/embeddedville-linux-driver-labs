#!/usr/bin/env python3
"""Course-scoped build, QEMU, evidence, and one-time submission CLI."""
from __future__ import annotations
import argparse, hashlib, json, os, pathlib, shutil, subprocess, sys, tempfile, time, urllib.error, urllib.request, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
IDENTITY = json.loads((ROOT / ".embeddedville-workspace.json").read_text())
LOCK = json.loads((ROOT / "release-lock.json").read_text())
ACTIVITIES = set(IDENTITY["activities"])
ALLOW_PREFIXES = ("src/", "include/", "evidence/")
ALLOW_FILES = {"Makefile"}

def run(*cmd: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(cmd))
    return subprocess.run(cmd, cwd=ROOT, text=True, check=check)

def activity(value: str | None) -> str:
    if not value or value not in ACTIVITIES:
        raise SystemExit(f"Unknown or missing --activity. Expected one of: {', '.join(sorted(ACTIVITIES))}")
    return value

def doctor(_: argparse.Namespace) -> None:
    problems=[]
    if not str(ROOT).startswith("/workspaces/") and sys.platform != "win32": problems.append("workspace is not under /workspaces")
    for name in ("make", "gcc", "qemu-system-x86_64"):
        if shutil.which(name) is None: problems.append(f"missing {name}")
    qemu = subprocess.run(["qemu-system-x86_64", "--version"], text=True, capture_output=True).stdout if shutil.which("qemu-system-x86_64") else ""
    if LOCK["sources"]["qemu"]["version"] not in qemu: problems.append("QEMU version differs from release lock")
    print(f"course={IDENTITY['courseId']} starter={IDENTITY['starterVersion']} contract={IDENTITY['contractVersion']}")
    if problems: raise SystemExit("doctor failed: " + "; ".join(problems))
    print("doctor: ready; QEMU uses software TCG and guest transport is localhost-only")

def build(args: argparse.Namespace) -> None:
    target = activity(args.activity) if args.activity else "all"
    run("make", "W=1", f"ACTIVITY={target}")
    if shutil.which("sparse"): run("make", "C=1", f"ACTIVITY={target}")

def boot(_: argparse.Namespace) -> None:
    runner = ROOT / "tools" / "qemu-boot.sh"
    if not runner.exists(): raise SystemExit("Guest image is not provisioned. Run ./lab reset after the release image is available.")
    run("bash", str(runner))

def test(args: argparse.Namespace) -> None:
    item = activity(args.activity)
    build(argparse.Namespace(activity=item))
    run("bash", "tests/public/run.sh", item)
    evidence = ROOT / "evidence"; evidence.mkdir(exist_ok=True)
    (evidence / "manifest.json").write_text(json.dumps({"schemaVersion":1,"courseId":IDENTITY["courseId"],"contractVersion":IDENTITY["contractVersion"],"starterVersion":IDENTITY["starterVersion"],"activityId":item,"generatedAt":int(time.time())}, indent=2)+"\n")

def reset(_: argparse.Namespace) -> None:
    run("make", "clean", check=False)
    shutil.rmtree(ROOT / ".lab-state", ignore_errors=True)
    print("Generated build and runtime state cleared; learner source was preserved.")

def snapshot(item: str) -> tuple[pathlib.Path, dict, str, str]:
    files=[]
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file(): continue
        rel=path.relative_to(ROOT).as_posix()
        if rel in ALLOW_FILES or rel.startswith(ALLOW_PREFIXES):
            data=path.read_bytes(); files.append({"path":rel,"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),"type":"file"})
    manifest={"schemaVersion":1,"files":files}
    canonical=json.dumps(manifest,separators=(",",":"),sort_keys=True).encode()
    out=ROOT/"evidence"/f"{item}-submission.zip"; out.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(out,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for entry in files:
            info=zipfile.ZipInfo(entry["path"],(1980,1,1,0,0,0)); info.external_attr=0o100644<<16
            archive.writestr(info,(ROOT/entry["path"]).read_bytes())
    digest=hashlib.sha256(out.read_bytes()).hexdigest()
    return out,manifest,hashlib.sha256(canonical).hexdigest(),digest

def package(args: argparse.Namespace) -> None:
    item=activity(args.activity); out,manifest,manifest_digest,digest=snapshot(item)
    print(json.dumps({"archive":str(out),"bytes":out.stat().st_size,"manifestSha256":manifest_digest,"snapshotSha256":digest,"files":len(manifest["files"])},indent=2))

def request(url: str, payload: dict, token: str | None=None) -> dict:
    headers={"Content-Type":"application/json"}
    if token: headers["Authorization"]="Bearer "+token
    req=urllib.request.Request(url,data=json.dumps(payload).encode(),headers=headers,method="POST")
    with urllib.request.urlopen(req,timeout=30) as response: return json.load(response)

def submit(args: argparse.Namespace) -> None:
    item=activity(args.activity)
    if item not in {"ldd1-capstone-qevent","ldd2-capstone-edu"}: raise SystemExit("Only the capstone is submitted for completion; labs are formative.")
    out,manifest,manifest_digest,digest=snapshot(item); origin=os.environ.get("EMBEDDEDVILLE_ORIGIN","https://embeddedville.com")
    session=request(origin+"/api/workspace-submission-sessions",{"courseId":IDENTITY["courseId"],"activityId":item,"repository":IDENTITY["repository"],"starterVersion":IDENTITY["starterVersion"],"baseRef":IDENTITY["starterVersion"],"headCommit":None,"dirty":True,"manifestSha256":manifest_digest,"snapshotSha256":digest,"snapshotBytes":out.stat().st_size})
    print("Approve this exact snapshot:",session["verificationUri"])
    while True:
        req=urllib.request.Request(origin+f"/api/workspace-submission-sessions/{session['id']}/status",headers={"Authorization":"Bearer "+session["pollToken"]})
        with urllib.request.urlopen(req,timeout=30) as response: status=json.load(response)["status"]
        if status=="approved": break
        if status in {"denied","expired","consumed"}: raise SystemExit("pairing "+status)
        time.sleep(2)
    exchanged=request(origin+f"/api/workspace-submission-sessions/{session['id']}/exchange",{},session["pollToken"])
    boundary="----embeddedville-driver-boundary"; body=(f"--{boundary}\r\nContent-Disposition: form-data; name=\"manifest\"\r\n\r\n{json.dumps(manifest,separators=(',',':'),sort_keys=True)}\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"snapshot\"; filename=\"{out.name}\"\r\nContent-Type: application/zip\r\n\r\n").encode()+out.read_bytes()+f"\r\n--{boundary}--\r\n".encode()
    req=urllib.request.Request(origin+f"/api/workspace-submission-sessions/{session['id']}/submit",data=body,headers={"Authorization":"Bearer "+exchanged["submissionToken"],"Content-Type":"multipart/form-data; boundary="+boundary},method="POST")
    with urllib.request.urlopen(req,timeout=60) as response: print(json.dumps(json.load(response),indent=2))

def main() -> None:
    parser=argparse.ArgumentParser(prog="./lab"); sub=parser.add_subparsers(required=True)
    for name,fn in (("doctor",doctor),("boot",boot),("reset",reset)):
        command=sub.add_parser(name); command.set_defaults(fn=fn)
    for name,fn in (("build",build),("run",test),("test",test),("package",package),("submit",submit)):
        command=sub.add_parser(name); command.add_argument("--activity"); command.set_defaults(fn=fn)
    args=parser.parse_args(); args.fn(args)
if __name__=="__main__": main()
