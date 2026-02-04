#!/bin/bash
set -e

# Config
DIST_DIR="$HOME/vibe-kanban-had"
LAUNCHER="$HOME/vibe-kanban-local.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Generate version folder name: YYYYMMDD-HHMMSS-<commit>
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
COMMIT=$(git rev-parse --short HEAD)
VERSION_NAME="${TIMESTAMP}-${COMMIT}"

echo "=== Building NPX CLI ==="
cd "$PROJECT_ROOT"
pnpm run build:npx

echo "=== Creating distribution folder ==="
mkdir -p "$DIST_DIR/$VERSION_NAME"

# Copy npx-cli contents
cp -r "$PROJECT_ROOT/npx-cli/bin" "$DIST_DIR/$VERSION_NAME/"
cp -r "$PROJECT_ROOT/npx-cli/dist" "$DIST_DIR/$VERSION_NAME/"
cp "$PROJECT_ROOT/npx-cli/package.json" "$DIST_DIR/$VERSION_NAME/"

echo "=== Updating latest symlink ==="
rm -rf "$DIST_DIR/latest"
ln -s "$DIST_DIR/$VERSION_NAME" "$DIST_DIR/latest"

echo "=== Creating launcher script ==="
cat > "$LAUNCHER" << EOF
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title vibe-kanban-local
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Launch Vibe Kanban (local build) with remote backend
# @raycast.author Hadouin

PROJECT_ROOT="$PROJECT_ROOT"

# Start remote in background
cd "\$PROJECT_ROOT/crates/remote"
docker compose --env-file "\$PROJECT_ROOT/.env.remote" \\
  -f docker-compose.yml -f docker-compose.local.yml up -d

# Wait for remote to be healthy
echo "Waiting for remote backend..."
until curl -s http://localhost:4001/health > /dev/null 2>&1; do sleep 1; done
echo "Remote backend ready!"

# Open Ghostty with VK
open -na "Ghostty" --args -e bash -c "VK_SHARED_API_BASE=http://localhost:4001 PORT=4000 node ~/vibe-kanban-had/latest/bin/cli.js; exec bash"
EOF
chmod +x "$LAUNCHER"

echo ""
echo "Done! Build copied to: $DIST_DIR/$VERSION_NAME"
echo "Latest symlink: $DIST_DIR/latest"
echo "Launcher: $LAUNCHER"
echo ""
echo "Run with: ~/vibe-kanban-local.sh"
