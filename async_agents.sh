#!/usr/bin/env bash

# ==============================================================================
# 🌌 Async Agents - Specialized AI Asset Synchronizer
# ==============================================================================
# Synchronizes specialized AI AGENTS.md and skills from the central repository
# directly into your local project's .agents/ root folder.
#
# Usage:
#   ./async_agents.sh [tech|skill] [--clean] [--branch name] [--local path]
#
# Examples:
#   ./async_agents.sh angular
#   ./async_agents.sh nestjs --clean
#   ./async_agents.sh clean-code
# ==============================================================================

# --- Configuration ---
REPO="DiegoVilla27/agents-ai-store"
DEFAULT_BRANCH="main"
AGENT_BASE=".agents"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO"
GITHUB_API="https://api.github.com/repos/$REPO"

TECHS=("angular" "react" "flutter" "nextjs" "nestjs" "react-native" "shared" "ui-ux-designer" "digital-marketer" "express" "spring-boot")

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Global Counters ---
SYNC_COUNT_SKILLS=0
SYNC_COUNT_AGENTS=0

# --- Utility Functions ---
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }

usage() {
    echo "Usage: $0 [techs|skills...] [options]"
    echo ""
    echo "Available Technologies:"
    echo "  ${TECHS[*]}"
    echo ""
    echo "Options:"
    echo "  --clean         Deletes the .agents directory before downloading."
    echo "  --branch B      Specifies a different branch (default: main)."
    echo "  --local P       Specifies a local path to the store for development."
    echo "  --help          Shows this message."
    exit 0
}

# --- Initialization ---
SELECTED_ITEMS=()
CLEAN_MODE=false
BRANCH=$DEFAULT_BRANCH
LOCAL_PATH=""

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean) CLEAN_MODE=true; shift ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --local) LOCAL_PATH="$2"; shift 2 ;;
        --help) usage ;;
        -*) warn "Unknown option: $1"; shift ;;
        *) SELECTED_ITEMS+=("$1"); shift ;;
    esac
done

# --- Download / Copy Helper ---
sync_file() {
    local src_rel_path=$1
    local dst_rel_path=$2
    local label=$3

    local target_file="$AGENT_BASE/$dst_rel_path"
    mkdir -p "$(dirname "$target_file")"

    if [ -n "$LOCAL_PATH" ]; then
        local src_file="$LOCAL_PATH/$src_rel_path"
        if [ -f "$src_file" ]; then
            cp "$src_file" "$target_file"
            echo "  📁 $label [COPIED]"
            return 0
        fi
    else
        local file_url="$GITHUB_RAW/$BRANCH/$src_rel_path"
        if curl -s --head --fail "$file_url" > /dev/null 2>&1; then
            curl -s -L "$file_url" -o "$target_file"
            echo "  🌐 $label [DOWNLOADED]"
            return 0
        fi
    fi
    return 1
}

# --- Skill Sync Logic ---
sync_skill_by_path() {
    local tech=$1
    local skill_name=$2

    if [ -f "$AGENT_BASE/skills/$skill_name/SKILL.md" ]; then
        return 0
    fi

    local found=false
    if [ -n "$LOCAL_PATH" ]; then
        local skill_dir="$LOCAL_PATH/$tech/skills/$skill_name"
        if [ -d "$skill_dir" ]; then
            info "Processing 🛠 Skill: $skill_name ($tech)..."
            mkdir -p "$AGENT_BASE/skills/$skill_name"
            cp -r "$skill_dir/"* "$AGENT_BASE/skills/$skill_name/"
            echo "  📁 SKILL.md [COPIED]"
            found=true
        fi
    else
        local skill_url="$GITHUB_RAW/$BRANCH/$tech/skills/$skill_name/SKILL.md"
        if curl -s --head --fail "$skill_url" > /dev/null 2>&1; then
            info "Processing 🛠 Skill: $skill_name ($tech)..."
            mkdir -p "$AGENT_BASE/skills/$skill_name"
            curl -s -L "$skill_url" -o "$AGENT_BASE/skills/$skill_name/SKILL.md"
            echo "  🌐 SKILL.md [DOWNLOADED]"

            for aux in "config.json" "EXAMPLES.md"; do
                local aux_url="$GITHUB_RAW/$BRANCH/$tech/skills/$skill_name/$aux"
                if curl -s --head --fail "$aux_url" > /dev/null 2>&1; then
                    curl -s -L "$aux_url" -o "$AGENT_BASE/skills/$skill_name/$aux"
                    echo "  🌐 $aux [DOWNLOADED]"
                fi
            done
            found=true
        fi
    fi

    if [ "$found" = true ]; then
        ((SYNC_COUNT_SKILLS++))
        return 0
    fi
    return 1
}

find_and_sync_skill() {
    local skill_name=$1

    if [ -f "$AGENT_BASE/skills/$skill_name/SKILL.md" ]; then
        return 0
    fi

    for tech in "${TECHS[@]}"; do
        if sync_skill_by_path "$tech" "$skill_name"; then
            return 0
        fi
    done
    return 1
}

# --- Technology Sync Logic ---
sync_technology() {
    local tech=$1
    header "Syncing Technology Package: $tech"

    if [ "$tech" != "shared" ]; then
        info "Processing 🤖 Agent protocol ($tech/AGENTS.md)..."
        if sync_file "$tech/AGENTS.md" "AGENTS.md" "AGENTS.md ($tech)"; then
            ((SYNC_COUNT_AGENTS++))
        else
            warn "AGENTS.md not found for technology '$tech'."
        fi
    fi

    local skill_names=()
    if [ -n "$LOCAL_PATH" ]; then
        if [ -d "$LOCAL_PATH/$tech/skills" ]; then
            for d in "$LOCAL_PATH/$tech/skills"/*/; do
                if [ -d "$d" ]; then
                    skill_names+=("$(basename "$d")")
                fi
            done
        fi
    else
        if command -v jq &> /dev/null; then
            local api_res
            api_res=$(curl -s -f "$GITHUB_API/contents/$tech/skills?ref=$BRANCH" 2>/dev/null)
            if [ -n "$api_res" ]; then
                while IFS= read -r sname; do
                    if [ -n "$sname" ]; then
                        skill_names+=("$sname")
                    fi
                done < <(echo "$api_res" | jq -r '.[] | select(.type == "dir") | .name' 2>/dev/null)
            fi
        fi
    fi

    for sname in "${skill_names[@]}"; do
        sync_skill_by_path "$tech" "$sname"
    done

    if [ -f "$AGENT_BASE/AGENTS.md" ]; then
        info "Resolving dependency skills referenced in AGENTS.md..."
        local ref_skills
        ref_skills=$(grep -E "^\s*-\s*\`[a-zA-Z0-9_-]+\`" "$AGENT_BASE/AGENTS.md" 2>/dev/null | sed -E 's/.*\`([a-zA-Z0-9_-]+)\`/\1/')
        while IFS= read -r rskill; do
            if [ -n "$rskill" ]; then
                find_and_sync_skill "$rskill"
            fi
        done <<< "$ref_skills"
    fi
}

# --- Main Execution ---
header "🌌 Async Agents Synchronizer"

if [ -n "$LOCAL_PATH" ]; then
    info "LOCAL MODE: Source '$LOCAL_PATH'"
else
    info "REMOTE MODE: Repository $REPO ($BRANCH)"
fi

if [ "$CLEAN_MODE" = true ]; then
    info "Cleaning $AGENT_BASE directory..."
    rm -rf "$AGENT_BASE"
fi

if [ ${#SELECTED_ITEMS[@]} -eq 0 ]; then
    info "No specific technology provided. Syncing all technologies..."
    for tech in "${TECHS[@]}"; do
        sync_technology "$tech"
    done
else
    for item in "${SELECTED_ITEMS[@]}"; do
        is_tech=false
        for t in "${TECHS[@]}"; do
            if [ "$item" = "$t" ]; then
                is_tech=true
                break
            fi
        done

        if [ "$is_tech" = true ]; then
            sync_technology "$item"
        else
            header "Searching for skill: $item"
            if ! find_and_sync_skill "$item"; then
                warn "Skill or technology '$item' not found."
            fi
        fi
    done
fi

header "Sync Summary"
if [ $SYNC_COUNT_AGENTS -gt 0 ]; then
    success "🤖 AGENTS.md protocol synced to $AGENT_BASE/AGENTS.md"
fi
success "🛠 Skills synced: $SYNC_COUNT_SKILLS"
info "✨ All assets are ready in $AGENT_BASE/"
