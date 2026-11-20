#!/usr/bin/env python3
"""CSN-336 TC-09: generate a large JS/LWC/VF workload under ./perf for analysis-time comparison.
Usage: python3 scripts/generate-large-project.py [files=1500] [lines_per_file=200]
Also writes one ~1 MB minified-style file to stress the engine."""
import os, sys, random
files = int(sys.argv[1]) if len(sys.argv) > 1 else 1500
lines = int(sys.argv[2]) if len(sys.argv) > 2 else 200
random.seed(336)
base = os.path.join('perf', 'main', 'default')
for sub in ('staticresources', 'lwc', 'pages'):
    os.makedirs(os.path.join(base, sub), exist_ok=True)

def js_body(n):
    out = []
    for i in range(n):
        k = random.randint(0, 5)
        if k == 0:   out.append(f"var v{i} = {i};")
        elif k == 1: out.append(f"if (window.x{i} == null) {{ console.log('v{i}'); }}")
        elif k == 2: out.append(f"function f{i}(a, b) {{ return a + b + {i}; }}")
        elif k == 3: out.append(f"const o{i} = {{ id: {i}, name: 'n{i}' }};")
        elif k == 4: out.append(f"let s{i} = [1,2,3].map(x => x * {i});")
        else:        out.append(f"// comment line {i}")
    return "\n".join(out) + "\n"

meta_js = ('<?xml version="1.0" encoding="UTF-8"?>\n<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">'
           '<cacheControl>Private</cacheControl><contentType>application/javascript</contentType></StaticResource>\n')
third = files // 3
for i in range(third):  # static resources
    p = os.path.join(base, 'staticresources', f'perf_res_{i}')
    open(p + '.js', 'w').write(js_body(lines)); open(p + '.resource-meta.xml', 'w').write(meta_js)
for i in range(third):  # LWC
    d = os.path.join(base, 'lwc', f'perfCmp{i}'); os.makedirs(d, exist_ok=True)
    open(os.path.join(d, f'perfCmp{i}.js'), 'w').write(
        "import { LightningElement } from 'lwc';\nexport default class PerfCmp extends LightningElement {\n"
        "  connectedCallback() {\n" + "".join("    " + l + "\n" for l in js_body(lines).splitlines()) + "  }\n}\n")
    open(os.path.join(d, f'perfCmp{i}.html'), 'w').write('<template><p>perf</p></template>\n')
for i in range(files - 2 * third):  # VF with inline script + $Resource
    open(os.path.join(base, 'pages', f'PerfPage{i}.page'), 'w').write(
        f'<apex:page>\n<apex:includeScript value="{{!$Resource.perf_res_{i % max(third,1)}}}"/>\n<script>\n'
        + js_body(lines // 2) + '</script>\n</apex:page>\n')
# one big minified-style file (~1 MB)
big = ";".join(f"var m{i}=function(a){{return a=={i}?{i}:a}}" for i in range(30000))
open(os.path.join(base, 'staticresources', 'perf_big_min.js'), 'w').write(big)
open(os.path.join(base, 'staticresources', 'perf_big_min.resource-meta.xml'), 'w').write(meta_js)
print(f"Generated {files} files x ~{lines} lines + 1 large minified file under ./perf")
