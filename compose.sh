#!/bin/bash

function get_help() {
  echo "Two-Network Simulation Environment"
  echo  
  echo "Usage: $0 [up|down|start|stop|restart]"
  echo
  echo "Commands:"
  echo "  up        - 🚀 Create and Start the containers in detached mode"
  echo "  down      - 🛑 Stop and remove the containers"
  echo "  recompose - 🔄 Recompose the containers (down + up)"
  echo "  start     - ▶️ Start existing containers"
  echo "  stop      - ⏸️ Stop running containers"
  echo "  restart   - 🔄 Restart the containers"
  echo "  help      - ❓ Show this help message"
  echo
}

if [ "$1" = "up" ]; then
  echo "🚀 Create and starting containers..."
  docker compose up -d
elif [ "$1" = "down" ]; then
  echo "🛑 Stopping and removing containers..."
  docker compose down
elif [ "$1" = "recompose" ]; then
  echo "🔄 Recomposing containers..."
  docker compose down
  docker compose up -d
elif [ "$1" = "start" ]; then
  echo "▶️ Starting existing containers..."
  docker compose start -d
elif [ "$1" = "stop" ]; then
  echo "⏸️ Stopping running containers..."
  docker compose stop
elif [ "$1" = "restart" ]; then
  echo "🔄 Restarting containers..."
  docker compose restart
elif [ -z "$1" ] || [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  get_help
else
  echo "❌ Invalid parameter: $1"
  echo "Usage: $0 [up|down|start|stop|restart]"
  exit 1
fi

