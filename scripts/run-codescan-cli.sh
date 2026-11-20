#!/usr/bin/env bash
# CSN-336: run SonarScanner CLI against CodeScan and assert on the log.
# Required env: CODESCAN_URL, CODESCAN_TOKEN, CODESCAN_ORG, CODESCAN_PROJECT_KEY
# Optional env: SCAN_SOURCES (default force-app), BRANCH_NAME, SCANNER_VERSION, EXPECT_FIX (true|false)
set -uo pipefail
SCANNER_VERSION="${SCANNER_VERSION:-5.0.1.3006}"
SCAN_SOURCES="${SCAN_SOURCES:-force-app}"
EXPECT_FIX="${EXPECT_FIX:-true}"
LOG=codescan-scan.log

echo "== Environment =="
cat /etc/os-release 2>/dev/null | head -3
( ldd --version 2>&1 | head -1 ) || true
java -version 2>&1 | head -1

if [ ! -d "sonar-scanner-${SCANNER_VERSION}" ]; then
  curl -sSLo scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}.zip"
  unzip -q scanner.zip && rm scanner.zip
fi

BRANCH_ARGS=()
[ -n "${BRANCH_NAME:-}" ] && BRANCH_ARGS=(-Dsonar.branch.name="${BRANCH_NAME}")

START=$(date +%s)
"sonar-scanner-${SCANNER_VERSION}/bin/sonar-scanner" -X \
  -Dsonar.host.url="${CODESCAN_URL}" \
  -Dsonar.login="${CODESCAN_TOKEN}" \
  -Dsonar.organization="${CODESCAN_ORG}" \
  -Dsonar.projectKey="${CODESCAN_PROJECT_KEY}" \
  -Dsonar.sources="${SCAN_SOURCES}" \
  -Dsonar.qualitygate.wait=true \
  "${BRANCH_ARGS[@]}" 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}
END=$(date +%s)

echo
echo "================ CSN-336 CHECKS ================"
echo "Scanner exit code : $RC"
echo "Analysis duration : $((END-START)) s"
FAIL=0
check() { if eval "$2"; then echo "PASS  $1"; else echo "FAIL  $1"; FAIL=1; fi; }

if [ "$EXPECT_FIX" = "true" ]; then
  check "No 'fcntl64: symbol not found'"          "! grep -q 'fcntl64' $LOG"
  check "No 'Error relocating' (musl/glibc)"      "! grep -q 'Error relocating' $LOG"
  check "No 'Stream closed' from engine"          "! grep -q 'Stream closed' $LOG"
  check "linuxstatic ESLint engine used"          "grep -q 'codescan-language-eslint-linuxstatic' $LOG"
  check "Old glibc engine NOT used"               "! grep -Eq 'codescan-language-eslint-linux([^s]|$)' $LOG"
  check "codescanlang sensor ran"                 "grep -q 'codescanlang' $LOG"
  check "EXECUTION SUCCESS"                       "grep -q 'EXECUTION SUCCESS' $LOG"
  check "Scanner exit code 0 (incl. Quality Gate)" "[ $RC -eq 0 ] || grep -q 'QUALITY GATE STATUS: FAILED' $LOG"
else
  echo "Baseline/negative run (EXPECT_FIX=false) - expecting the original CSN-336 failure on Alpine:"
  check "Original failure reproduced (fcntl64)"   "grep -q 'fcntl64' $LOG"
fi
grep -E 'QUALITY GATE STATUS|ANALYSIS SUCCESSFUL|Sensor .*codescanlang|Extracting .*eslint' $LOG | sed 's/^/  log> /' || true
echo "================================================"
exit $FAIL
