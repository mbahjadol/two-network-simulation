#!/usr/bin/env bash
# ==========================================================
# Universal network failure simulator (with netem sidecar)
# ==========================================================
# Requires:
#   - docker-compose up (with netem-controller running)
#   - privileged sidecar container with iproute2 & iptables
# ==========================================================

NETEM="netem-controller"
CONTA_A="container-a"
CONTA_B="container-b"
CURRENT_PROJECT_DIR="two-network-simulation"
INNER_DOCKER_COMPOSE_SHARED_NETWORK="network3"
NET_SHARED="${CURRENT_PROJECT_DIR}_${INNER_DOCKER_COMPOSE_SHARED_NETWORK}"

show_help() {
  echo "Usage: $0 [mode]"
  echo "Modes:"
  echo "  packetloss   -> 20% packet loss, 100ms delay"
  echo "  throttle     -> Bandwidth limit 100kbit, latency 400ms"
  echo "  disconnect   -> Disconnect A from shared network"
  echo "  reconnect    -> Reconnect A from shared network"
  echo "  outage       -> Disconnect both from network3 for 10s"
  echo "  dnsfail      -> Break DNS for A"
  echo "  flap         -> Intermittent connect/disconnect (5 cycles)"
  echo "  reset        -> Remove all netem rules"
  echo
  echo "Examples:"
  echo "  $0 packetloss"
  echo "  $0 reset"
}

ensure_tc() {
  docker exec "$NETEM" sh -c "apk add --no-cache iproute2 iptables" >/dev/null
}

get_iface() {
  docker exec "$NETEM" sh -c "ip link | grep -B1 \"$1\" | head -n1 | awk -F: '{print \$2}' | tr -d ' '"
}

case "$1" in
  packetloss)
    ensure_tc
    echo "🌐 Simulating 20% packet loss and 100ms delay..."
    docker exec "$NETEM" tc qdisc add dev eth0 root netem loss 20% delay 100ms || true
    ;;
  throttle)
    ensure_tc
    echo "🐢 Applying bandwidth throttling..."
    docker exec "$NETEM" tc qdisc add dev eth0 root tbf rate 100kbit burst 32kbit latency 400ms || true
    ;;
  disconnect)
    echo "🚫 Disconnecting $CONTA_A from $NET_SHARED..."
    docker network disconnect "$NET_SHARED" "$CONTA_A"
    ;;
  reconnect)
    echo "🔁 Reconnecting $CONTA_A to $NET_SHARED..."
    docker network connect "$NET_SHARED" "$CONTA_A"
    ;;
  outage)
    echo "💥 Simulating total network3 outage..."
    docker network disconnect "$NET_SHARED" "$CONTA_A"
    docker network disconnect "$NET_SHARED" "$CONTA_B"
    sleep 10
    echo "🔁 Restoring network3..."
    docker network connect "$NET_SHARED" "$CONTA_A"
    docker network connect "$NET_SHARED" "$CONTA_B"
    ;;
  dnsfail)
    echo "❌ Breaking DNS in $CONTA_A..."
    docker exec "$CONTA_A" sh -c 'echo "nameserver 127.0.0.1" > /etc/resolv.conf'
    ;;
  flap)
    echo "🔁 Starting intermittent network flapping (5 cycles)..."
    for i in {1..5}; do
      echo "Cycle $i: disconnect..."
      docker network disconnect "$NET_SHARED" "$CONTA_A"
      sleep 5
      echo "Cycle $i: reconnect..."
      docker network connect "$NET_SHARED" "$CONTA_A"
      sleep 5
    done
    ;;
  reset)
    echo "🧹 Resetting all network modifications..."
    docker exec "$NETEM" tc qdisc del dev eth0 root 2>/dev/null || true
    echo "✅ All network conditions restored."
    ;;
  *)
    show_help
    ;;
esac
