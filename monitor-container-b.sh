#!/bin/bash

# Monitoring script for container-b to log network connectivity status
docker compose exec -it container-b /bin/bash -c "tail -f /tcp_client_log.txt"