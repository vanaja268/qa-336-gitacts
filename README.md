# CSN-336 – GitHub Actions test data

**Ticket:** CSN-336, Copado–CodeScan analysis fails with `fcntl64: symbol not found`
**Fix under test:** PR #750 (apex-pmd). The Linux ESLint engine is now built as `node22-linuxstatic-x64`, and the loader starts `codescan-language-eslint-linuxstatic` instead of `codescan-language-eslint-linux`. One static binary should now run on both **glibc** (Ubuntu) and **musl** (Alpine).

All the JS this test data adds is analysed by that ESLint engine: VF inline script, JS Static Resources, LWC and Aura. Apex is included as a control.

---

## 1. Setup (one time)

1. Create a new GitHub repo, for example `csn-336-gha-test`, and push the contents of this zip to `main`.
2. In CodeScan, on the **environment where the fix is deployed** (QA/Test), create a project and note the org key and project key.
3. In GitHub, go to **Settings → Secrets and variables → Actions** and add:

   | Type | Name | Value |
   |---|---|---|
   | Secret | `CODESCAN_TOKEN` | CodeScan token with Execute Analysis + Browse |
   | Variable | `CODESCAN_URL` | URL of the QA/Test CodeScan instance with the fix |
   | Variable | `CODESCAN_ORG` | Organization key |
   | Variable | `CODESCAN_PROJECT_KEY` | Project key |

> The scanner downloads the CodeScan plugins from `CODESCAN_URL`. If that URL points at an environment **without** PR #750, the fix isn't being tested.

## 2. What the workflow runs

`.github/workflows/csn-336-codescan.yml` has three jobs, run one after another:

| Job | Runner / OS | Purpose |
|---|---|---|
| `ubuntu-official-action` | ubuntu-latest (glibc) | The customer path: `codescan-io/codescan-scanner-action@2.0`, push and PR, with a SARIF artifact |
| `ubuntu-cli-checks` | ubuntu-latest (glibc) | Regression check that the new static binary still works on glibc, with automatic log checks |
| `alpine-cli-checks` | `alpine:3.20` container (musl) | **The fix itself**: the same environment family as the failing Copado runner, with automatic log checks |

The CLI jobs run `scripts/run-codescan-cli.sh`. It prints a **CSN-336 CHECKS** block with PASS/FAIL for each check, plus the analysis duration, and fails the job if any check fails. The full log is uploaded as an artifact.

Manual run options (**Actions → CSN-336 CodeScan verification → Run workflow**):

- `include_edge_cases`: also scan `edge-cases/`
- `large_project` plus `large_file_count`: generate a performance workload under `perf/`
- `expect_fix = false`: a negative/baseline run against an environment **without** the fix. The Alpine job then expects the original `fcntl64` error.

## 3. Test data map

| File | Used by | Seeded content |
|---|---|---|
| `pages/CSN336_ResourcePage.page` | TC-01 | Exact ticket scenario: `$Resource.csn336_app_js` + zip resource + inline `<script>` with `==`, `console.log`, `eval`, unused var, innerHTML XSS |
| `staticresources/csn336_app_js.js` | TC-01 | `var`, unused var, `==`, `console.log`, `debugger`, `new Function`, `eval`, duplicate key, unreachable code |
| `pages/CSN336_CleanPage.page` + `csn336_clean_js.js` | TC-02 | Clean files, **0 JS issues expected** |
| `staticresources/csn336_lib/lib/csn336-lib.js` | TC-03 | JS inside a zip static resource: `==`, `console.warn`, `with` |
| `lwc/csn336Widget/*` | TC-04 | `var`, unused, `==`, `console.log`, `innerHTML`, setTimeout in connectedCallback |
| `aura/CSN336Cmp/*` | TC-05 | Controller and helper: unused, `==`, `console.log`, `innerHTML`, `eval` |
| `classes/CSN336Controller.cls` | TC-06, TC-10 | Apex control (SOQL/DML in loop, empty catch) + **fake** hard-coded password for Gitleaks |
| `edge-cases/*` | TC-08 | Empty JS, JS with a syntax error, non-ASCII file name |
| `scripts/generate-large-project.py` | TC-09 | Generates N static resources, LWC and VF pages, plus one ~1 MB minified file |

> Which rule fires for each seeded line depends on the quality profile on the project. Treat the comments as "issues expected in this area". The key point is that JS issues are **reported at all**, not exactly 0.

## 4. Test cases

| ID | Scenario | How | Expected result |
|---|---|---|---|
| TC-01 | VF page + JS Static Resource via `$Resource` (ticket repro) | Push to `main` | All 3 jobs green. On the Alpine job: no `fcntl64`, `Error relocating` or `Stream closed`; `Sensor cs-vf Checks [codescanlang]` finishes; `EXECUTION SUCCESS`. Issues appear on `CSN336_ResourcePage.page` and `csn336_app_js.js` in CodeScan |
| TC-02 | Clean VF + clean JS | Same run | Both files analysed, 0 issues on them, so no false positives |
| TC-03 | JS in a zip static resource | Same run | `csn336-lib.js` is analysed and issues are reported (or confirm current product behaviour for zipped resources and note it) |
| TC-04 | LWC JS | Same run | Issues reported on `csn336Widget.js` in all 3 jobs |
| TC-05 | Aura controller + helper | Same run | Issues reported on both Aura JS files |
| TC-06 | Apex control | Same run | Apex issues identical across the Ubuntu, Alpine and baseline runs (not affected by the change) |
| TC-07 | Same results on glibc and musl | Compare branches `csn336-ubuntu-glibc` and `csn336-alpine-musl` in CodeScan | **Same issue count and issue list** on both branches |
| TC-08 | Edge cases | Run workflow with `include_edge_cases = true` | Syntax-error file is logged as a parse error and **skipped**; the scan still finishes with `EXECUTION SUCCESS`; the engine doesn't crash or hang; the unicode file is analysed |
| TC-09 | Performance (large project) | Run workflow with `large_project = true`, `large_file_count = 1500`. Repeat against prod/baseline (26.0.24) | Compare the "Analysis duration" line. Flag if the new build is >10–15% slower or runs out of memory or times out. Do it for a normal run (default) and a large run |
| TC-10 | Gitleaks regression | Same run (fake password in Apex), if secret scanning is enabled for the project | Secret detected; no native-binary load error on Ubuntu or Alpine |
| TC-11 | Pull request flow | Create a branch, change `csn336_app_js.js` (for example add `eval('x')`), open a PR to `main` | `ubuntu-official-action` runs; PR analysis is created in CodeScan; new issue shown; Quality Gate status returned (no "Pull request … not found") |
| TC-12 | Engine caching | Re-run the CLI jobs on the same commit | Second run works; the log shows the `linuxstatic` engine; no extraction error |
| TC-13 | Negative baseline (optional, proves the test is valid) | Point `CODESCAN_URL` at an environment **without** the fix and run with `expect_fix = false` | Alpine job reproduces the `fcntl64` failure, which confirms the test data catches the bug. Ubuntu should still pass |

## 5. Result recording

For each run, record the CodeScan version, scanner version, job, OS, PASS/FAIL, analysis duration, JS issue count and Apex issue count. Attach `codescan-scan.log` from the artifacts.

## 6. Notes and limitations

- **Not covered by PR #750:** Copado reporting "0 violations" when the scanner fails, and the Quality Gate "not found" error. These are integration-side issues to verify separately in Copado.
- The engine is still **x64 only**; ARM64 Linux runners aren't covered by this fix.
- The "linuxstatic ESLint engine used" check reads a DEBUG line (`Extracting …`). The CLI jobs run with `-X`, so it shows. If only this check fails, search the log manually for `eslint`.
- `sonar.qualitygate.wait=true` makes the CLI wait for the Quality Gate. A **red** gate counts as a pass for this ticket, because the analysis itself worked.
- `CSN336Controller.cls` contains a **fake** password for the Gitleaks check. It isn't a real credential. If GitHub push protection complains, allow it for this test repo.
