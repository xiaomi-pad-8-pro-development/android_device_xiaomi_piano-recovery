#!/usr/bin/env python3
"""Flatten the vendored upstream manifest and resolve every revision to a SHA."""
import argparse
import concurrent.futures
import copy
import json
import re
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT / "manifests/upstream"

def flatten(upstream=UPSTREAM):
    projects, remotes = {}, {}
    default = None
    def read(name):
        nonlocal default
        for e in ET.parse(upstream / name).getroot():
            if e.tag == "include":
                read(e.attrib["name"])
            elif e.tag == "remote":
                remotes[e.attrib["name"]] = copy.deepcopy(e)
            elif e.tag == "default":
                default = copy.deepcopy(e)
            elif e.tag == "project":
                projects[e.get("path", e.attrib["name"])] = copy.deepcopy(e)
            elif e.tag == "remove-project":
                for path, project in list(projects.items()):
                    if ((not e.get("path") or e.get("path") == path)
                        and (not e.get("name") or e.get("name") == project.get("name"))):
                        del projects[path]
            elif e.tag not in ("superproject", "contactinfo"):
                raise ValueError("unsupported manifest element " + e.tag)
    read("default.xml")
    return projects, remotes, default

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--flavor", choices=("twrp", "ofox"), default="twrp")
    args = parser.parse_args()
    flavor = args.flavor
    upstream = UPSTREAM if flavor == "twrp" else ROOT / "manifests/ofox-upstream"
    projects, remotes, default = flatten(upstream)
    cache = json.loads((ROOT / "manifests/sources.lock.json").read_text())
    cached = {(r["url"], r["upstream_revision"]): r["commit"] for r in cache
              if r["upstream_revision"].startswith("refs/tags/")}
    def resolve(item):
        path, project = item
        remote = project.get("remote", default.get("remote"))
        revision = project.get("revision", default.get("revision"))
        url = remotes[remote].get("fetch").rstrip("/") + "/" + project.get("name")
        if (url, revision) in cached:
            sha = cached[(url, revision)]
        elif re.fullmatch(r"[0-9a-f]{40}", revision):
            sha = revision
        else:
            ref = revision if revision.startswith("refs/") else "refs/heads/" + revision
            output = subprocess.check_output(
                ["git", "ls-remote", "--exit-code", url, ref, ref + "^{}"],
                text=True, timeout=120)
            refs = dict(line.split()[::-1] for line in output.splitlines())
            sha = refs.get(ref + "^{}", refs.get(ref))
            if not sha:
                raise ValueError("unresolved revision " + path)
        project.set("revision", sha)
        # Fixed SHAs are intentionally fetched without branch-only sync hints.
        project.attrib.pop("clone-depth", None)
        return {"path": path, "url": url, "upstream_revision": revision, "commit": sha}
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        records = list(pool.map(resolve, sorted(projects.items())))
    root = ET.Element("manifest")
    for remote in remotes.values():
        root.append(remote)
    default.attrib.pop("revision", None)
    root.append(default)
    for path in sorted(projects):
        root.append(projects[path])
    ET.indent(root)
    ET.ElementTree(root).write(ROOT / f"manifests/{flavor}-locked.xml", encoding="utf-8", xml_declaration=True)
    (ROOT / ("manifests/sources.lock.json" if flavor == "twrp" else "manifests/ofox-sources.lock.json")).write_text(json.dumps(records, indent=2) + "\n")
    pins = ET.Element("manifest")
    for path in sorted(projects):
        project = projects[path]
        ET.SubElement(pins, "extend-project", {"name": project.get("name"), "path": path, "revision": project.get("revision")})
    ET.indent(pins)
    ET.ElementTree(pins).write(ROOT / f"manifests/{flavor}-pins.xml", encoding="utf-8", xml_declaration=True)
    # Preserve declared manifest provenance; refresh the count and snapshot hashes.
    import hashlib
    metadata_path = ROOT / ("manifests/baseline.json" if flavor == "twrp" else "manifests/ofox-baseline.json")
    metadata = json.loads(metadata_path.read_text())
    metadata["project_count"] = len(records)
    metadata["upstream_files"] = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in upstream.glob("*.xml")}
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n")
    print("Locked", len(records), "projects")

if __name__ == "__main__":
    main()
