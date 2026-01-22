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
cat > "$LAUNCHER" << 'EOF'
#!/bin/bash
node ~/vibe-kanban-had/latest/bin/cli.js "$@"
EOF
chmod +x "$LAUNCHER"

echo ""
echo "Done! Build copied to: $DIST_DIR/$VERSION_NAME"
echo "Latest symlink: $DIST_DIR/latest"
echo "Launcher: $LAUNCHER"
echo ""
echo "Run with: ~/vibe-kanban-local.sh"
