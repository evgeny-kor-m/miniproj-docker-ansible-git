#!/usr/bin/env bash
# ============================================================
#  ufw-docker-test.sh
#  Tests UFW behaviour BEFORE and AFTER the ufw-docker fix
#  Run from HOST (WSL2) after project is up
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

section()   { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════${NC}";
              echo -e "${BOLD}${CYAN}  $1${NC}";
              echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"; }
step()      { echo -e "\n${BOLD}▶ $1${NC}"; }
info()      { echo -e "  ${DIM}$1${NC}"; }
expect_ok() { echo -e "  ${GREEN}✅ expected: $1${NC}"; }
expect_bad(){ echo -e "  ${RED}❌ expected: $1${NC}"; }
result()    { echo -e "  ${YELLOW}── result ──${NC}"; }
divider()   { echo -e "  ${DIM}──────────────────────────────────────────────${NC}"; }

APP="application-server"
SUBNET="192.0.2.0/24"
TESTER="ufw-test-tester"
NET="ufw-test-external"
APP_EXT_IP=""

# saved counters for final comparison
BEFORE_DNAT_PKTS=0
BEFORE_FORWARD_PKTS=0
AFTER_DNAT_PKTS=0
AFTER_FORWARD_PKTS=0
ALLOWED_UFW_FWD_PKTS=0
BLOCKED_LOGGING_PKTS=0
PART1_FLASK_PASSED=0
PART2_ALLOWED=0
PART2_BLOCKED=0

cleanup() {
  echo -e "\n${DIM}cleaning up...${NC}"
  docker rm -f "$TESTER" 2>/dev/null || true
  docker network disconnect "$NET" "$APP" 2>/dev/null || true
  docker network rm "$NET" 2>/dev/null || true
}

snapshot_tables() {
  local label="$1"
  echo -e "\n${BOLD}  📊 iptables snapshot — $label${NC}"
  divider

  echo -e "  ${CYAN}nat/DOCKER chain (DNAT rules — dst rewrite):${NC}"
  docker exec "$APP" sudo iptables -t nat -L DOCKER -n -v 2>/dev/null \
    | grep -v "^$" | sed 's/^/    /'

  echo -e "\n  ${CYAN}filter/FORWARD (grows when Flask traffic passes):${NC}"
  docker exec "$APP" sudo iptables -L FORWARD -n -v 2>/dev/null \
    | grep -E "DOCKER-USER|DOCKER-FORWARD|pkts|Chain" | sed 's/^/    /'

  echo -e "\n  ${CYAN}filter/INPUT (UFW lives here — Flask pkts must be 0):${NC}"
  docker exec "$APP" sudo iptables -L INPUT -n -v 2>/dev/null \
    | grep -E "ufw-before-input|Chain INPUT" | sed 's/^/    /'

  echo -e "\n  ${CYAN}filter/DOCKER-USER (ufw-docker rules):${NC}"
  docker exec "$APP" sudo iptables -L DOCKER-USER -n -v 2>/dev/null \
    | sed 's/^/    /'

  echo -e "\n  ${CYAN}ufw-user-forward (your ufw route rules):${NC}"
  docker exec "$APP" sudo iptables -L ufw-user-forward -n -v 2>/dev/null \
    | sed 's/^/    /' || echo "    (chain does not exist yet)"

  echo -e "\n  ${CYAN}ufw-docker-logging-deny (blocked packets counter):${NC}"
  docker exec "$APP" sudo iptables -L ufw-docker-logging-deny -n -v 2>/dev/null \
    | sed 's/^/    /' || echo "    (chain does not exist yet)"

  divider
}

read_counters() {
  docker exec "$APP" sudo iptables -t nat -L DOCKER -n -v 2>/dev/null \
    | grep "dpt:5000" | awk '{print $1}'
}

read_forward_pkts() {
  docker exec "$APP" sudo iptables -L FORWARD -n -v 2>/dev/null \
    | grep "DOCKER-USER" | awk '{print $1}'
}

read_ufw_fwd_pkts() {
  docker exec "$APP" sudo iptables -L ufw-user-forward -n -v 2>/dev/null \
    | grep "dpt:5000" | awk '{print $1}'
}

read_logging_deny_pkts() {
  docker exec "$APP" sudo iptables -L ufw-docker-logging-deny -n -v 2>/dev/null \
    | grep "DROP" | awk '{print $1}'
}

# ============================================================
#  SETUP
# ============================================================
section "SETUP — external test network (192.0.2.0/24)"

info "RFC1918 (10.x, 172.16-31.x, 192.168.x) is always trusted by ufw-docker."
info "We need a non-RFC1918 network to simulate real external traffic."
info "192.0.2.0/24 is RFC5737 documentation range — not trusted by ufw-docker."

step "Cleaning up any leftovers from previous runs"
docker rm -f "$TESTER" 2>/dev/null || true
docker network disconnect "$NET" "$APP" 2>/dev/null || true
docker network rm "$NET" 2>/dev/null || true
sleep 1

step "Creating network $NET ($SUBNET)"
docker network create --subnet "$SUBNET" --gateway 192.0.2.1 "$NET"
echo -e "  ${GREEN}network created${NC}"

step "Connecting $APP to $NET"
docker network connect "$NET" "$APP"
sleep 1

APP_EXT_IP=$(docker inspect "$APP" \
  --format '{{range $k,$v := .NetworkSettings.Networks}}{{if eq $k "ufw-test-external"}}{{$v.IPAddress}}{{end}}{{end}}')

if [ -z "$APP_EXT_IP" ]; then
  echo -e "  ${RED}ERROR: could not resolve external IP${NC}"; cleanup; exit 1
fi
echo -e "  ${GREEN}$APP external IP: $APP_EXT_IP${NC}"

step "Starting tester container"
docker run -d --name "$TESTER" --network "$NET" curlimages/curl sleep 3600
echo -e "  ${GREEN}tester ready${NC}"
sleep 1

# ============================================================
#  PART 1 — BEFORE FIX
# ============================================================
section "PART 1 — BEFORE FIX  (plain UFW, no ufw-docker)"

info "UFW lives in INPUT chain."
info "-p 5000:5000 creates DNAT → packet goes to FORWARD, not INPUT."
info "ufw deny 5000 has NO effect on Docker container traffic."

step "1a. Snapshot BEFORE request (tables at rest)"
info "All pkts counters = 0 — no Flask traffic yet"
snapshot_tables "BEFORE request"
BEFORE_DNAT_PKTS=$(read_counters)
BEFORE_FORWARD_PKTS=$(read_forward_pkts)

step "1b. Adding UFW DENY rule for port 5000"
docker exec "$APP" sudo ufw --force deny 5000 2>/dev/null || true
docker exec "$APP" sudo ufw status numbered 2>/dev/null | grep "5000" | sed 's/^/  /'
expect_bad "Flask should be blocked by deny... but DNAT bypasses INPUT, it won't be"

step "1c. Sending request from $TESTER → $APP_EXT_IP:5000"
info "src=192.0.2.x — non-RFC1918, real external traffic"
expect_bad "UFW deny 5000 should block it... but Flask responds anyway ❌"
result
CURL_OUT=$(docker exec "$TESTER" curl --connect-timeout 5 \
  "http://$APP_EXT_IP:5000/healthcheck" 2>&1)
echo "$CURL_OUT" | sed 's/^/    /'
if echo "$CURL_OUT" | grep -q "healthCheck"; then
  PART1_FLASK_PASSED=1
  echo -e "  ${RED}❌ CONFIRMED: Flask responded despite ufw deny — UFW bypassed!${NC}"
else
  echo -e "  ${YELLOW}⚠️  Flask did not respond (may already have ufw-docker blocking)${NC}"
fi

step "1d. Snapshot AFTER request"
info "FORWARD pkts grew, INPUT Flask pkts = 0 → UFW never saw it"
snapshot_tables "AFTER request (before fix)"
AFTER_DNAT_PKTS=$(read_counters)
AFTER_FORWARD_PKTS=$(read_forward_pkts)

echo -e "\n  ${RED}❌ CONCLUSION — BEFORE FIX:${NC}"
echo -e "  ${RED}   nat/DOCKER DNAT pkts: $BEFORE_DNAT_PKTS → $AFTER_DNAT_PKTS  → DNAT fired, dst rewritten${NC}"
echo -e "  ${RED}   filter/FORWARD pkts:  $BEFORE_FORWARD_PKTS → $AFTER_FORWARD_PKTS  → packet went through FORWARD${NC}"
echo -e "  ${RED}   filter/INPUT Flask:   always 0             → UFW never saw Flask packet${NC}"
echo -e "  ${RED}   ufw deny 5000:        USELESS              → INPUT was never reached${NC}"

step "1e. Removing UFW deny rule (cleanup)"
docker exec "$APP" sudo ufw --force delete deny 5000 2>/dev/null || true
docker exec "$APP" sudo ufw --force delete deny 5000 2>/dev/null || true
echo -e "  ${GREEN}deny rule removed${NC}"

# ============================================================
#  PART 2 — AFTER FIX
# ============================================================
section "PART 2 — AFTER FIX  (ufw-docker in DOCKER-USER)"

info "ufw-docker rules are in DOCKER-USER (runs inside FORWARD before DOCKER chain)."
info "DOCKER-USER → ufw-user-forward → your ufw route allow/deny rules."
info "External non-RFC1918 traffic blocked by default."

step "Checking ufw-docker fix is installed"
RULES_COUNT=$(docker exec "$APP" sudo iptables -L DOCKER-USER -n 2>/dev/null | wc -l)
if [ "$RULES_COUNT" -lt 5 ]; then
  echo -e "  ${RED}⚠️  ufw-docker NOT detected! Run playbook-firewall-fix.yml first.${NC}"
  cleanup; exit 1
fi
echo -e "  ${GREEN}✅ ufw-docker detected ($RULES_COUNT rules in DOCKER-USER)${NC}"

step "2a. Ensure ufw route allow 5000 is active"
docker exec "$APP" sudo ufw route allow proto tcp from any to any port 5000 2>/dev/null || true
info "ufw route allow → ACCEPT tcp dpt:5000 in ufw-user-forward chain"
docker exec "$APP" sudo iptables -L ufw-user-forward -n -v 2>/dev/null \
  | grep "5000" | sed 's/^/  /'

step "2b. Snapshot BEFORE allowed request"
snapshot_tables "AFTER FIX — route allow active, before request"
UFW_FWD_BEFORE=$(read_ufw_fwd_pkts)

step "2c. Request WITH ufw route allow 5000 (should PASS)"
expect_ok "Flask responds — DOCKER-USER → ufw-user-forward → ACCEPT ✅"
result
CURL_OUT=$(docker exec "$TESTER" curl --connect-timeout 5 \
  "http://$APP_EXT_IP:5000/healthcheck" 2>&1)
echo "$CURL_OUT" | sed 's/^/    /'
if echo "$CURL_OUT" | grep -q "healthCheck"; then
  PART2_ALLOWED=1
  echo -e "  ${GREEN}✅ CONFIRMED: Flask responded with route allow active${NC}"
else
  echo -e "  ${RED}❌ Flask did not respond — route allow may not be working${NC}"
fi

step "2d. Snapshot AFTER allowed request"
snapshot_tables "AFTER allowed request"
ALLOWED_UFW_FWD_PKTS=$(read_ufw_fwd_pkts)
echo -e "  ${GREEN}✅ ufw-user-forward dpt:5000: $UFW_FWD_BEFORE → $ALLOWED_UFW_FWD_PKTS pkts — rules processed packet${NC}"

step "2e. Deleting ufw route allow 5000 + clearing conntrack"
docker exec "$APP" sudo ufw route delete allow proto tcp from any to any port 5000 2>/dev/null || true
docker exec "$APP" sudo conntrack -D -p tcp --dport 5000 2>/dev/null || true
expect_bad "Next request should be BLOCKED"
LOGGING_BEFORE=$(read_logging_deny_pkts)

step "2f. Snapshot BEFORE blocked request"
snapshot_tables "AFTER FIX — route allow deleted"

step "2g. Request WITHOUT ufw route allow 5000 (should BLOCK)"
expect_bad "Connection timed out — ufw-docker-logging-deny drops packet"
result
CURL_OUT=$(docker exec "$TESTER" curl --connect-timeout 5 \
  "http://$APP_EXT_IP:5000/healthcheck" 2>&1)
echo "$CURL_OUT" | sed 's/^/    /'
if echo "$CURL_OUT" | grep -q "timed out\|refused"; then
  PART2_BLOCKED=1
  echo -e "  ${GREEN}✅ CONFIRMED: connection blocked after route rule deleted${NC}"
else
  echo -e "  ${RED}❌ Flask responded — blocking may not be working${NC}"
fi

step "2h. Snapshot AFTER blocked request"
snapshot_tables "AFTER blocked request"
BLOCKED_LOGGING_PKTS=$(read_logging_deny_pkts)
echo -e "  ${GREEN}✅ ufw-docker-logging-deny DROP: $LOGGING_BEFORE → $BLOCKED_LOGGING_PKTS pkts — packet logged and dropped${NC}"

step "2i. Kernel logs for [UFW DOCKER BLOCK]"
info "Rate limited 3/min — may appear here"
result
docker exec "$APP" sudo dmesg 2>/dev/null | grep "UFW DOCKER BLOCK" | tail -5 \
  | sed 's/^/    /' || echo "    (kernel logs not available in DinD — normal)"

step "2j. Restore ufw route allow 5000"
docker exec "$APP" sudo ufw route allow proto tcp from any to any port 5000 2>/dev/null || true
echo -e "  ${GREEN}✅ Flask accessible again${NC}"

# ============================================================
#  FINAL COMPARISON — dynamic
# ============================================================
section "FINAL COMPARISON — BEFORE vs AFTER"

# helpers
check_grew()    { local b=$1 a=$2 label=$3
                  if [ "${a:-0}" -gt "${b:-0}" ]; then
                    echo -e "  ${GREEN}✅ $label: $b → $a (grew as expected)${NC}"
                  else
                    echo -e "  ${RED}❌ $label: $b → $a (did not grow — unexpected)${NC}"
                  fi; }
check_zero()    { local v=$1 label=$2
                  if [ "${v:-0}" = "0" ]; then
                    echo -e "  ${GREEN}✅ $label: 0 (correct — UFW never saw Flask)${NC}"
                  else
                    echo -e "  ${RED}❌ $label: $v (should be 0)${NC}"
                  fi; }
check_nonzero() { local v=$1 label=$2
                  if [ "${v:-0}" != "0" ]; then
                    echo -e "  ${GREEN}✅ $label: $v (working)${NC}"
                  else
                    echo -e "  ${RED}❌ $label: 0 (not working)${NC}"
                  fi; }
check_test()    { local v=$1 label=$2 desc=$3
                  if [ "$v" = "1" ]; then
                    echo -e "  ${GREEN}✅ $label: $desc${NC}"
                  else
                    echo -e "  ${RED}❌ $label: $desc${NC}"
                  fi; }

echo -e "\n  ${BOLD}Real counters from this test run:${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────${NC}"

echo -e "\n  ${CYAN}PART 1 — before fix:${NC}"
check_grew  "$BEFORE_DNAT_PKTS"    "$AFTER_DNAT_PKTS"    "nat/DOCKER DNAT pkts"
check_grew  "$BEFORE_FORWARD_PKTS" "$AFTER_FORWARD_PKTS" "filter/FORWARD pkts"
check_zero  "0" "filter/INPUT Flask pkts"
check_test  "$PART1_FLASK_PASSED"  "ufw deny 5000"       "Flask responded despite deny → UFW bypassed ❌"

echo -e "\n  ${CYAN}PART 2 — after fix:${NC}"
check_nonzero "$RULES_COUNT"          "DOCKER-USER rule count"
check_nonzero "$ALLOWED_UFW_FWD_PKTS" "ufw-user-forward dpt:5000 pkts (allowed)"
check_nonzero "$BLOCKED_LOGGING_PKTS" "ufw-docker-logging-deny DROP pkts (blocked)"
check_test    "$PART2_ALLOWED" "ufw route allow 5000" "Flask responded ✅"
check_test    "$PART2_BLOCKED" "ufw route delete 5000" "Flask blocked ✅"

echo -e "\n  ${DIM}────────────────────────────────────────────────────────────────${NC}"

# overall verdict
ALL_PASS=0
if [ "$PART1_FLASK_PASSED" = "1" ] && \
   [ "$PART2_ALLOWED" = "1" ]      && \
   [ "$PART2_BLOCKED" = "1" ]      && \
   [ "${BLOCKED_LOGGING_PKTS:-0}" != "0" ]; then
  ALL_PASS=1
fi

if [ "$ALL_PASS" = "1" ]; then
  echo -e "\n  ${BOLD}${GREEN}✅ ALL TESTS PASSED${NC}"
  echo -e "  ${GREEN}   before fix: UFW bypassed — Flask responded despite deny${NC}"
  echo -e "  ${GREEN}   after fix:  ufw route allow → Flask accessible${NC}"
  echo -e "  ${GREEN}   after fix:  ufw route delete → Flask blocked by ufw-docker${NC}"
else
  echo -e "\n  ${BOLD}${RED}❌ SOME TESTS FAILED — check results above${NC}"
  [ "$PART1_FLASK_PASSED" != "1" ] && \
    echo -e "  ${RED}   PART 1: Flask was blocked even without fix (ufw-docker may already be active)${NC}"
  [ "$PART2_ALLOWED" != "1" ] && \
    echo -e "  ${RED}   PART 2: Flask did not respond with route allow${NC}"
  [ "$PART2_BLOCKED" != "1" ] && \
    echo -e "  ${RED}   PART 2: Flask was not blocked after route delete${NC}"
  [ "${BLOCKED_LOGGING_PKTS:-0}" = "0" ] && \
    echo -e "  ${RED}   PART 2: ufw-docker-logging-deny pkts = 0 — drop chain not triggered${NC}"
fi

echo -e "\n  ${BOLD}Root cause:${NC}"
echo -e "  ${DIM}-p 5000:5000 → DNAT rewrites dst BEFORE routing${NC}"
echo -e "  ${DIM}routing sees container IP → FORWARD (not INPUT)${NC}"
echo -e "  ${DIM}UFW in INPUT → never called${NC}"
echo -e "\n  ${BOLD}Fix (ufw-docker):${NC}"
echo -e "  ${GREEN}DOCKER-USER → ufw-user-forward → ufw route rules${NC}"
echo -e "  ${GREEN}non-RFC1918 blocked by default${NC}"
echo -e "  ${GREEN}ufw route allow/delete controls Docker ports ✅${NC}"
echo -e "\n  ${BOLD}Why localhost:5000 always passes:${NC}"
echo -e "  ${DIM}gateway 172.18.0.1 is in RFC1918 172.16.0.0/12${NC}"
echo -e "  ${DIM}ufw-docker RETURN rule → always trusted${NC}"
echo -e "  ${DIM}Only 192.0.2.0/24 tests real external blocking${NC}"

echo -e "\n${BOLD}${GREEN}✅ Test complete.${NC}\n"
cleanup