#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"

bold="$(printf '\033[1m')"
green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
red="$(printf '\033[31m')"
blue="$(printf '\033[34m')"
reset="$(printf '\033[0m')"

print_header() {
  echo
  echo "${bold}${blue}SignalDesk Demo Test Suite${reset}"
  echo "Target: ${BASE_URL}"
  echo "----------------------------------------"
}

post_event() {
  local name="$1"
  local payload="$2"

  echo
  echo "${bold}${yellow}▶ Scenario:${reset} ${name}"
  echo "${bold}Payload:${reset}"
  echo "${payload}" | jq . 2>/dev/null || echo "${payload}"

  echo
  echo "${bold}Response:${reset}"
  curl -s -X POST "${BASE_URL}/event" \
    -H "Content-Type: application/json" \
    -d "${payload}" | jq . 2>/dev/null || true

  echo
  echo "${green}✓ Sent:${reset} ${name}"
}

login_attack() {
  post_event "login attack" '{
    "type": "login",
    "user": "demo-attacker-login",
    "risk": 94,
    "attempts": 9,
    "ip": "unknown",
    "velocitySpike": true,
    "geoMismatch": false,
    "source": "demo-test-suite"
  }'
}

payment_fraud() {
  post_event "payment fraud" '{
    "type": "payment",
    "user": "demo-attacker-payment",
    "amount": 18000,
    "currency": "EUR",
    "risk": 96,
    "ip": "unknown",
    "geoMismatch": true,
    "velocitySpike": true,
    "source": "demo-test-suite"
  }'
}

geo_mismatch() {
  post_event "geo mismatch" '{
    "type": "geodata",
    "user": "demo-user-geo",
    "risk": 82,
    "ip": "185.220.101.77",
    "country": "unknown",
    "lastKnownCountry": "SE",
    "geoMismatch": true,
    "source": "demo-test-suite"
  }'
}

velocity_spike() {
  post_event "velocity spike" '{
    "type": "login",
    "user": "demo-user-velocity",
    "risk": 88,
    "attempts": 14,
    "velocitySpike": true,
    "ip": "unknown",
    "source": "demo-test-suite"
  }'
}

normal_user() {
  post_event "normal user" '{
    "type": "login",
    "user": "demo-normal-user",
    "risk": 18,
    "attempts": 1,
    "ip": "trusted",
    "geoMismatch": false,
    "velocitySpike": false,
    "source": "demo-test-suite"
  }'
}

repeated_offender() {
  post_event "repeated offender / first signal" '{
    "type": "login",
    "user": "demo-repeat-offender",
    "risk": 79,
    "attempts": 7,
    "ip": "unknown",
    "velocitySpike": true,
    "source": "demo-test-suite"
  }'

  sleep 1

  post_event "repeated offender / payment escalation" '{
    "type": "payment",
    "user": "demo-repeat-offender",
    "amount": 12000,
    "currency": "EUR",
    "risk": 93,
    "ip": "unknown",
    "geoMismatch": true,
    "velocitySpike": true,
    "source": "demo-test-suite"
  }'

  sleep 1

  post_event "repeated offender / second payment pattern" '{
    "type": "payment",
    "user": "demo-repeat-offender",
    "amount": 16000,
    "currency": "EUR",
    "risk": 97,
    "ip": "unknown",
    "geoMismatch": true,
    "velocitySpike": true,
    "source": "demo-test-suite"
  }'
}

system_drift() {
  echo
  echo "${bold}${yellow}▶ Scenario:${reset} system drift"
  echo "Injecting mixed high-risk volume to push drift away from baseline..."

  for i in $(seq 1 8); do
    post_event "system drift / burst $i" "{
      \"type\": \"login\",
      \"user\": \"demo-drift-user-$i\",
      \"risk\": $((78 + i)),
      \"attempts\": $((5 + i)),
      \"ip\": \"unknown\",
      \"velocitySpike\": true,
      \"geoMismatch\": $([ $((i % 2)) -eq 0 ] && echo true || echo false),
      \"source\": \"demo-test-suite\"
    }"
    sleep 0.3
  done
}

summary() {
  echo
  echo "${bold}${blue}Current Summary${reset}"
  curl -s "${BASE_URL}/api/summary" | jq . 2>/dev/null || true

  echo
  echo "${bold}${blue}Latest Incident${reset}"
  curl -s "${BASE_URL}/api/incidents" | jq '.[0]' 2>/dev/null || true

  echo
  echo "${bold}${blue}Latest Action${reset}"
  curl -s "${BASE_URL}/api/actions" | jq '.[0]' 2>/dev/null || true
}

run_all() {
  login_attack
  sleep 1
  payment_fraud
  sleep 1
  geo_mismatch
  sleep 1
  velocity_spike
  sleep 1
  normal_user
  sleep 1
  repeated_offender
  sleep 1
  system_drift
  sleep 1
  summary
}

menu() {
  while true; do
    print_header
    echo "1) login attack"
    echo "2) payment fraud"
    echo "3) geo mismatch"
    echo "4) velocity spike"
    echo "5) normal user"
    echo "6) repeated offender"
    echo "7) system drift"
    echo "8) run all"
    echo "9) summary"
    echo "0) exit"
    echo
    read -rp "Choose scenario: " choice

    case "$choice" in
      1) login_attack ;;
      2) payment_fraud ;;
      3) geo_mismatch ;;
      4) velocity_spike ;;
      5) normal_user ;;
      6) repeated_offender ;;
      7) system_drift ;;
      8) run_all ;;
      9) summary ;;
      0) exit 0 ;;
      *) echo "${red}Unknown option.${reset}" ;;
    esac

    echo
    read -rp "Press Enter to continue..."
  done
}

print_usage() {
  echo "Usage:"
  echo "  ./scripts/demo-tests.sh menu"
  echo "  ./scripts/demo-tests.sh login"
  echo "  ./scripts/demo-tests.sh payment"
  echo "  ./scripts/demo-tests.sh geo"
  echo "  ./scripts/demo-tests.sh velocity"
  echo "  ./scripts/demo-tests.sh normal"
  echo "  ./scripts/demo-tests.sh repeat"
  echo "  ./scripts/demo-tests.sh drift"
  echo "  ./scripts/demo-tests.sh all"
  echo "  ./scripts/demo-tests.sh summary"
  echo
  echo "Optional:"
  echo "  BASE_URL=http://localhost:3000 ./scripts/demo-tests.sh all"
}

main() {
  local cmd="${1:-menu}"

  case "$cmd" in
    menu) menu ;;
    login|login_attack) print_header; login_attack; summary ;;
    payment|payment_fraud) print_header; payment_fraud; summary ;;
    geo|geo_mismatch) print_header; geo_mismatch; summary ;;
    velocity|velocity_spike) print_header; velocity_spike; summary ;;
    normal|normal_user) print_header; normal_user; summary ;;
    repeat|repeated|repeated_offender) print_header; repeated_offender; summary ;;
    drift|system_drift) print_header; system_drift; summary ;;
    all|run_all) print_header; run_all ;;
    summary) print_header; summary ;;
    help|-h|--help) print_usage ;;
    *) print_usage; exit 1 ;;
  esac
}

main "$@"
