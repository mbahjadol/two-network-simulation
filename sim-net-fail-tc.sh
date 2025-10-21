#!/usr/bin/env bash
# ==========================================================
# Simulate various network failures for a 3-network setup
# ==========================================================
# Requires: docker, tc (installed inside containers)
# ==========================================================

CONTA_A="container-a"
CONTA_B="container-b"
CURRENT_PROJECT_DIR="two-network-simulation"
INNER_DOCKER_COMPOSE_SHARED_NETWORK="network3"
NET_SHARED="${CURRENT_PROJECT_DIR}_${INNER_DOCKER_COMPOSE_SHARED_NETWORK}"

show_help() {
  echo "Usage: $0 [mode]"
  echo "Modes:"
  echo "  disconnect        Temporarily disconnect container-a from shared network"
  echo "  packetloss        Simulate 20% packet loss and 100ms delay"
  echo "  throttle          Limit bandwidth to 100kbit with 400ms latency"
  echo "  outage            Bring down the shared network temporarily"
  echo "  dnsfail           Break DNS resolution"
  echo "  flap              Intermittent connect/disconnect every 10s"
  echo "  reset             Restore normal network conditions"
  echo
  echo "Examples:"
  echo "  $0 packetloss"
  echo "  $0 reset"
}

ensure_tc() {
  docker exec "$1" sh -c "which tc >/dev/null 2>&1 || (apt update -y && apt install -y iproute2)"
}

case "$1" in
  disconnect)
    echo "🚫 Disconnecting $CONTA_A from $NET_SHARED..."
    docker network disconnect "$NET_SHARED" "$CONTA_A"
    # sleep 5
    # echo "🔁 Reconnecting $CONTA_A..."
    # docker network connect "$NET_SHARED" "$CONTA_A"
    ;;

  packetloss)
    echo "🌐 Simulating 20% packet loss and 100ms delay on $CONTA_A..."
    ensure_tc "$CONTA_A"
    docker exec "$CONTA_A" tc qdisc add dev eth0 root netem loss 20% delay 100ms
    ;;

  throttle)
    echo "🐢 Limiting bandwidth on $CONTA_A..."
    ensure_tc "$CONTA_A"
    docker exec "$CONTA_A" tc qdisc add dev eth0 root tbf rate 100kbit burst 32kbit latency 400ms
    ;;

  outage)
    echo "💥 Simulating network3 outage..."
    docker network disconnect "$NET_SHARED" "$CONTA_A"
    docker network disconnect "$NET_SHARED" "$CONTA_B"
    sleep 10
    echo "🔁 Restoring network3 connections..."
    docker network connect "$NET_SHARED" "$CONTA_A"
    docker network connect "$NET_SHARED" "$CONTA_B"
    ;;

  dnsfail)
    echo "❌ Breaking DNS in $CONTA_A..."
    docker exec "$CONTA_A" sh -c 'echo "nameserver 127.0.0.1" > /etc/resolv.conf'
    ;;

  flap)
    echo "🔁 Starting intermittent network flapping..."
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
    echo "🧹 Resetting all network conditions..."
    docker exec "$CONTA_A" tc qdisc del dev eth0 root 2>/dev/null || true
    docker exec "$CONTA_B" tc qdisc del dev eth0 root 2>/dev/null || true
    echo "✅ All restored."
    ;;

  *)
    show_help
    ;;
esac
