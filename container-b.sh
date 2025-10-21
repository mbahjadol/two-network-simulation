#!/bin/bash
# ==========================================================
# Enter container-b shell interactively
# ==========================================================
echo " 🐚 Entering container-b shell interactively..."
docker compose exec -it container-b /bin/bash
# ==========================================================