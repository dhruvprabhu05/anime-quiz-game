# Minimal Wally installer: resolves deps via api.wally.run and writes the same
# Packages/ layout `wally install` produces (root links + _Index).
import json, os, re, io, sys, zipfile, shutil, urllib.request
API = "https://api.wally.run/v1"
HDR = {"Wally-Version": "0.3.2"}
def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HDR), timeout=60).read()
def vt(v): return tuple(int(x) for x in re.findall(r"\d+", v)[:3])
def match(ver, req):
    v = vt(ver)
    for part in [p.strip() for p in req.split(",")]:
        m = re.match(r"(>=|<=|>|<|=|\^)?\s*(.+)", part); op, b = m.group(1) or "^", vt(m.group(2))
        if op == "^":
            hi = (b[0]+1,0,0) if b[0] > 0 else (0,b[1]+1,0)
            if not (b <= v < hi): return False
        elif op == ">=" and not v >= b: return False
        elif op == ">" and not v > b: return False
        elif op == "<" and not v < b: return False
        elif op == "<=" and not v <= b: return False
        elif op == "=" and v != b: return False
    return True
meta = {}
def versions(pkg):
    if pkg not in meta:
        meta[pkg] = json.loads(get(f"{API}/package-metadata/{pkg}"))["versions"]
    return meta[pkg]
def resolve(pkg, req):
    vs = sorted((x for x in versions(pkg) if match(x["package"]["version"], req)), key=lambda x: vt(x["package"]["version"]), reverse=True)
    if not vs: sys.exit(f"no version of {pkg} matches {req}")
    return vs[0]
root, deps = sys.argv[1], json.loads(sys.argv[2])  # {"React": "jsdotlua/react@17.2.1"}
out = os.path.join(root, "Packages"); shutil.rmtree(out, ignore_errors=True); os.makedirs(os.path.join(out, "_Index"))
chosen = {}  # pkg -> metadata
def key(m): s, n = m["package"]["name"].split("/"); return f"{s}_{n}@{m['package']['version']}", n
def install(spec):
    pkg, req = spec.split("@", 1)
    m = resolve(pkg, req)
    if pkg in chosen:
        if vt(chosen[pkg]["package"]["version"]) >= vt(m["package"]["version"]): return chosen[pkg]
    chosen[pkg] = m
    folder, name = key(m)
    dest = os.path.join(out, "_Index", folder)
    if not os.path.exists(dest):
        data = get(f"{API}/package-contents/{pkg}/{m['package']['version']}")
        zipfile.ZipFile(io.BytesIO(data)).extractall(os.path.join(dest, name))
        print("fetched", folder)
    for alias, dspec in m.get("dependencies", {}).items():
        dm = install(dspec)
        dfolder, dname = key(dm)
        with open(os.path.join(dest, f"{alias}.lua"), "w") as f:
            f.write(f'return require(script.Parent.Parent["{dfolder}"]["{dname}"])\n')
    return m
for alias, spec in deps.items():
    m = install(spec); folder, name = key(m)
    with open(os.path.join(out, f"{alias}.lua"), "w") as f:
        f.write(f'return require(script.Parent._Index["{folder}"]["{name}"])\n')
print("done:", sorted(os.listdir(os.path.join(out, "_Index"))))
