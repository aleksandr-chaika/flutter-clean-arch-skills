#!/bin/bash
# install.sh — Installs flutter-clean-arch skills + agents + hooks to project's .claude/
#
# Usage:
#   ./install.sh                  # Installs to .claude/
#   ./install.sh /path/to/.claude # Installs to custom path

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.claude}"

echo "📦 Installing flutter-clean-arch skills to $TARGET/"

mkdir -p "$TARGET/skills" "$TARGET/agents" "$TARGET/hooks"

# Copy skills (knowledge bases)
cp -r "$SCRIPT_DIR/skills/"* "$TARGET/skills/"

# Copy agents
cp -r "$SCRIPT_DIR/agents/"* "$TARGET/agents/"

# Copy hooks
cp -r "$SCRIPT_DIR/hooks/"* "$TARGET/hooks/"
chmod +x "$TARGET/hooks/"*.sh

# Handle settings merge
if [ -f "$TARGET/settings.json" ]; then
  echo "⚠️  $TARGET/settings.json already exists."
  echo "   Merge hooks from $SCRIPT_DIR/settings-hooks.json manually."
else
  cp "$SCRIPT_DIR/settings-hooks.json" "$TARGET/settings.json"
  echo "✅ Created $TARGET/settings.json with hook config"
fi

SKILL_COUNT=$(find "$TARGET/skills" -name "SKILL.md" | wc -l | tr -d ' ')
AGENT_COUNT=$(find "$TARGET/agents" -name "*.md" | wc -l | tr -d ' ')
HOOK_COUNT=$(find "$TARGET/hooks" -name "*.sh" | wc -l | tr -d ' ')

echo ""
echo "✅ Installed to $TARGET/"
echo "   Skills: $SKILL_COUNT"
echo "   Agents: $AGENT_COUNT"
echo "   Hooks:  $HOOK_COUNT"
echo ""
echo "🚀 Restart Claude Code to pick up changes."
echo "   Then use: /orchestrator"
