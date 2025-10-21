# Two Network Simulation

Simulating network problem between two nodes 

---

## Two Network Simulation - Summary

This project demonstrates how to simulate network problems between two nodes using Docker Compose. It creates a three-network architecture, with two services (`container-a` and `container-b`) attached to three networks (`network1`, `network2`, and `network3`). The shared network (`network3`) allows the two containers to communicate. The project provides a script to simulate network failures, such as packet loss, latency, and disconnections. This can be useful for testing the robustness of distributed systems.

## Requirements
 - You need docker in your host, you can use docker engine, docker desktop or even podman whatever suit you.
 - linux base environment, (if your host windows better you need using WSL2 that can controling your docker via cli, or if you using mac then you need bash)

## 🖧 Designing the Multi-Network Docker Compose Setup

Docker Compose file creates the three-network architecture. 
It defines two services (`container-a` and `container-b`) and three networks (`network1`, `network2`, and `network3`). `container-a` is attached to `network1` and `network3`, while `container-b` is attached to `network2` and `network3`. This makes `network3` the shared, interconnected network that allows the two containers to communicate.

### 🧩 Two Network Simulation Architecture

This diagram illustrates how the project sets up and simulates network failures
between two containers connected via multiple Docker networks.

    ┌────────────────────────────────────────────────────────────┐
    │                         Docker Host                        │
    │                                                            │
    │  ┌─────────────────────┐       ┌────────────────────┐      │
    │  │    container-a      │       │    container-b     │      │
    │  │  (Service A Node)   │◄─────►│  (Service B Node)  │      │
    │  │                     │       │                    │      │
    │  │  • network1         │       │  • network2        │      │
    │  │  • network3 (shared)┼───────┼──• network3        │      │
    │  │                     │       │                    │      │
    │  └─────────────────────┘       └────────────────────┘      │
    │                                                            │
    │  Networks:                                                 │
    │   • network1 → private to container-a                      │
    │   • network2 → private to container-b                      │
    │   • network3 → shared between both (communication link)    │
    │                                                            │
    │  Simulation:                                               │
    │   ┌──────────────────────────────────────────────────────┐ │
    │   │ simulate-network-failures-using-tc.sh                │ │
    │   │  • add latency (e.g., 200ms)                         │ │
    │   │  • introduce packet loss (e.g., 30%)                 │ │
    │   │  • disconnect / reconnect containers                 │ │
    │   │  • emulate real-world unstable links                 │ │
    │   └──────────────────────────────────────────────────────┘ │
    │                                                            │
    └────────────────────────────────────────────────────────────┘

### 🧠 Architecture Summary
Purpose: Test how distributed systems behave under unstable network conditions.
Components:
- container-a, container-b → application nodes
- network1, network2 → isolated networks
- network3 → shared link for communication

Apps in containers:
- container-a is setup and running a tcp-time-server that open in port 5000
- the tcp-time-server is broadcast datetime each second into it is client
- container-b is setup and running a tcp-time-client that connect into container-a with port 5000

## ⚙️ The Tools

### Docker Compose 
I am already provide simple script to running the docker compose with:
    
    ./compose.sh

it retrieve commands:

    Commands:
        up        - 🚀 Create and Start the containers in detached mode
        down      - 🛑 Stop and remove the containers
        recompose - 🔄 Recompose the containers (down + up)
        start     - ▶️ Start existing containers
        stop      - ⏸️ Stop running containers
        restart   - 🔄 Restart the containers
        help      - ❓ Show this help message


### Network Fail Simulation 
It is using:
- tc (traffic control) commands in the shell script simulate real network faults.
- netem controller small container that create within docker compose to simulate real network faults.

You can use provided script tool name:

#### for tc:

    Usage: ./sim-net-fail-tc.sh [mode]
    Modes:
    disconnect        🚫 Temporarily disconnect container-a from shared network
    reconnect         🔁 Reconnect container-a to shared network
    packetloss        🌐 Simulate 20% packet loss and 100ms delay
    throttle          🐢 Limit bandwidth to 100kbit with 400ms latency
    outage            💥Bring down the shared network temporarily
    dnsfail           ❌ Break DNS resolution
    flap              🪠 Intermittent connect/disconnect every 10s
    reset             🧹Restore normal network conditions

    Examples:
    ./sim-net-fail-tc.sh packetloss
    ./sim-net-fail-tc.sh reset


#### for netem:

    Usage: ./sim-net-fail-netem.sh [mode]
    Modes:
    packetloss   -> 🌐 20% packet loss, 100ms delay
    throttle     -> 🐢 Bandwidth limit 100kbit, latency 400ms
    disconnect   -> 🚫 Disconnect A from shared network
    reconnect    -> 🔁 Reconnect A from shared network
    outage       -> 🚫 Disconnect both from network3 for 10s
    dnsfail      -> ❌ Break DNS for A
    flap         -> 🪠 Intermittent connect/disconnect (5 cycles)
    reset        -> 🧹 Resetting and Remove all netem rules

    Examples:
    ./sim-net-fail-netem.sh packetloss
    ./sim-net-fail-netem.sh reset


both of them have help for the usage just give them param with **"help"**

    ./sim-net-fail-tc.sh help
    or
    ./sim-net-fail-netem.sh


### Miscellaneous 
I had create some misc script to interactively connect into container-a or container-b, and even a mini monitoring that container-b is received data from container-b

#### connect interactively into container-a:

    ./container-a.sh

it is connect into container-a and you can interact within container-a


#### connect interactively into container-b:

    ./container-b.sh

it is connect into container-a and you can interact within container-a

#### monitoring container-b:

    ./monitoring-container-b.sh

it is monitoring log of tcp-time-client app that receive data each second from container-a


