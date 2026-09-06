#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [skill-name|--all] [options]

Install Jumo skills from jumo-skills repository.
Default (no arguments): install ALL skills to Claude Code, Codex, and agent skills (~/.agents/skills).

Arguments:
  skill-name    Name of the skill to install (e.g., jumo-model-understanding)
  --all          Install ALL skills (default when no skill name given)

Options:
  --claude       Install to Claude Code (~/.claude/skills/)
  --codex        Install to Codex CLI (~/.codex/skills/)
  --agents       Install to Zed / agent skills (~/.agents/skills/)
  --dir <path>   Install to custom directory

Environment:
  JUMO_SKILLS_REF     Branch or tag to install from (default: main)

Examples:
  $0                              # install all skills to Claude Code + Codex + agents
  $0 jumo-model-understanding     # install one skill
  $0 --all --dir ~/my-skills      # install all skills to custom dir
  $0 jumo-model-align --codex     # install one skill to Codex
  $0 --all --agents               # install all skills to ~/.agents/skills

Available skills:
  jumo-model-understanding — understand current Jumo language concepts and model layout
  jumo-model-align         — sync jumo/model and code annotations
  jumo-impl-track          — read/write/validate jumo/model/impl/usecases.json (usecase → code mapping)
  facts-to-jumo-draft      — synthesize jumo/draft from facts
  jumo-extract             — extract Rust/Java facts with jumo-code extract
  jumo-code-quality        — generate/interpret code-quality.json (code quality, coverage, module rollups)
  jumo-project-init        — set up Jumo directory structure
  generated-skeleton-implementation — work inside generated Rust/Java skeletons
  http-rust-axum           — implement HttpRust skeletons
  http-java-spring-boot    — implement Java Spring Boot skeletons
  jumo-codegen-strategy    — choose jumo-code generate vs AI, and verify against the model
EOF
}

ALL_SKILLS=(
  jumo-model-understanding
  jumo-model-align
  jumo-impl-track
  jumo-extract
  jumo-code-quality
  facts-to-jumo-draft
  jumo-project-init
  generated-skeleton-implementation
  http-rust-axum
  http-java-spring-boot
  jumo-codegen-strategy
)

skill_names=()
target_dirs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --claude)
      target_dirs+=("$HOME/.claude/skills")
      shift
      ;;
    --codex)
      target_dirs+=("$HOME/.codex/skills")
      shift
      ;;
    --agents)
      target_dirs+=("$HOME/.agents/skills")
      shift
      ;;
    --all)
      skill_names=("${ALL_SKILLS[@]}")
      shift
      ;;
    --dir)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --dir requires a path argument" >&2
        exit 2
      fi
      target_dirs+=("$2")
      shift 2
      ;;
    -*)
      echo "Error: Unknown option $1" >&2
      usage
      exit 2
      ;;
    *)
      skill_names+=("$1")
      shift
      ;;
  esac
done

# Default: install all skills
if [[ ${#skill_names[@]} -eq 0 ]]; then
  skill_names=("${ALL_SKILLS[@]}")
fi

# Default: install to all three platforms if none specified
if [[ ${#target_dirs[@]} -eq 0 ]]; then
  target_dirs+=("$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills")
fi

# Determine repo root (for local install fallback)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  repo_root=""
fi

tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

# Resolve source for a single skill (local or remote)
resolve_src() {
  local skill_name="$1"
  local candidate="$repo_root/skills/$skill_name"

  if [[ -d "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  # Clone from GitHub
  local ref="${JUMO_SKILLS_REF:-main}"

  if [[ -z "$tmp_dir" ]]; then
    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/jumo-skills.XXXXXX")"
    echo "Cloning dayu-sec/jumo-skills (ref: $ref)..."
    if ! git clone --depth 1 --branch "$ref" "https://github.com/dayu-sec/jumo-skills.git" "$tmp_dir/repo" 2>/dev/null; then
      if ! git clone --depth 1 "https://github.com/dayu-sec/jumo-skills.git" "$tmp_dir/repo" 2>/dev/null; then
        echo "Failed to clone dayu-sec/jumo-skills" >&2
        exit 1
      fi
    fi
  fi

  local src="$tmp_dir/repo/skills/$skill_name"
  if [[ ! -d "$src" ]]; then
    echo "Skill not found: $skill_name" >&2
    return 1
  fi
  echo "$src"
  return 0
}

# Install skills
echo ""
echo "Installing ${#skill_names[@]} skill(s)..."
echo ""

installed=0
for skill_name in "${skill_names[@]}"; do
  src_dir="$(resolve_src "$skill_name")" || continue

  for target_base in "${target_dirs[@]}"; do
    dst_dir="$target_base/$skill_name"

    mkdir -p "$target_base"
    rm -rf "$dst_dir"
    cp -R "$src_dir" "$dst_dir"

    platform="custom"
    case "$target_base" in
      */.codex/skills) platform="codex" ;;
      */.claude/skills) platform="claude-code" ;;
      */.agents/skills) platform="agents" ;;
    esac

    echo "  [$platform] $skill_name"
    installed=$((installed + 1))
  done
done

echo ""
echo "Done. $installed skill(s) installed."
echo "Location: ${target_dirs[*]}"
