#!/bin/zsh

# ==============================================================================
# 🌌 Async Agents - Specialized AI Asset Synchronizer
# ==============================================================================
# This script synchronizes specialized AI instructions, skills, and personas
# from the central repository and integrates them into any local project.
#
# Usage:
#   ./async_agents.sh [tech|asset] [--clean] [--branch name]
# ==============================================================================

# --- Configuration ---
REPO="DiegoVilla27/agents-ai-store"
DEFAULT_BRANCH="main"
AGENT_BASE=".agents"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO"
GITHUB_API="https://api.github.com/repos/$REPO"

TECHS=("angular" "react" "flutter" "nextjs" "nestjs" "react-native" "shared")

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Global Counters ---
SYNC_COUNT_SKILLS=0
SYNC_COUNT_INST=0
SYNC_COUNT_AGENTS=0

# --- Utility Functions ---
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }

usage() {
    echo "Usage: $0 [techs|assets...] [options]"
    echo ""
    echo "Techs:"
    echo "  ${TECHS[*]}"
    echo ""
    echo "Assets:"
    echo "  The name of a specific skill, instruction, or agent."
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

# --- Download Logic ---
download_asset() {
    local tech=$1
    local type=$2    # "skills", "instructions", or "agents"
    local name=$3    # folder or file name
    local source_dir=$4
    local icon="🛠"
    
    if [ "$type" = "instructions" ]; then icon="📜"; fi
    if [ "$type" = "agents" ]; then icon="🤖"; fi
    
    # Avoid duplicate processing in the same run if needed (optional)
    
    local target_path="$AGENT_BASE/$tech/$type/$name"
    if [ "$type" = "agents" ]; then
        target_path="$AGENT_BASE/$tech/$type"
    fi
    
    local files=()
    if [ "$type" = "skills" ]; then
        files=("SKILL.md" "config.json" "EXAMPLES.md")
    elif [ "$type" = "instructions" ]; then
        files=("INSTRUCTION.md")
    elif [ "$type" = "agents" ]; then
        files=("$name.json")
    fi
    
    local found=false
    for file in "${files[@]}"; do
        local target_file="$target_path/$file"
        
        if [ -n "$LOCAL_PATH" ]; then
            # Local Mode
            local src_file="$source_dir/$tech/$type/$name/$file"
            if [ "$type" = "agents" ]; then src_file="$source_dir/$tech/$type/$file"; fi
            
            if [ -f "$src_file" ]; then
                mkdir -p "$target_path"
                cp "$src_file" "$target_file"
                if [ "$file" = "${files[1]}" ] || [ "$type" != "skills" ]; then 
                    info "Processing $icon $name ($tech/$type)..."
                fi
                echo "  📁 $file [COPIED]"
                found=true
            fi
        else
            # Remote Mode
            local file_url="$GITHUB_RAW/$BRANCH/$tech/$type/$name/$file"
            if [ "$type" = "agents" ]; then file_url="$GITHUB_RAW/$BRANCH/$tech/$type/$file"; fi
            
            # Check if file exists before downloading to avoid noise
            if curl -s --head --fail "$file_url" > /dev/null; then
                mkdir -p "$target_path"
                curl -s -L "$file_url" -o "$target_file"
                if [ "$file" = "${files[1]}" ] || [ "$type" != "skills" ]; then 
                    info "Processing $icon $name ($tech/$type)..."
                fi
                echo "  🌐 $file [DOWNLOADED]"
                found=true
            fi
        fi
    done
    
    if [ "$found" = true ]; then
        if [ "$type" = "skills" ]; then ((SYNC_COUNT_SKILLS++)); elif [ "$type" = "instructions" ]; then ((SYNC_COUNT_INST++)); else ((SYNC_COUNT_AGENTS++)); fi
        
        # Recursive sync for Agents
        if [ "$type" = "agents" ]; then
            local agent_file="$AGENT_BASE/$tech/agents/$name.json"
            if [ -f "$agent_file" ]; then
                if ! command -v jq &> /dev/null; then warn "jq not found. Dependency-based sync skipped."; return 0; fi
                
                # Sync Instructions
                local inst_list=$(jq -r '.instructions[]?' "$agent_file" 2>/dev/null)
                for inst in ${(f)inst_list}; do
                    if [ -n "$inst" ]; then
                        find_and_download_asset "instructions" "$inst" "$source_dir"
                    fi
                done
                # Sync Skills
                local skill_list=$(jq -r '.skills[]?' "$agent_file" 2>/dev/null)
                for skill in ${(f)skill_list}; do
                    if [ -n "$skill" ]; then
                        find_and_download_asset "skills" "$skill" "$source_dir"
                    fi
                done
            fi
        fi
        return 0
    else
        return 1
    fi
}

find_and_download_asset() {
    local type=$1
    local name=$2
    local source_dir=$3
    
    # Check if already downloaded in any tech to avoid duplicates
    if [ -d "$AGENT_BASE" ]; then
        if find "$AGENT_BASE" -type d -name "$name" | grep -q "/$type/$name$"; then
            return 0
        fi
    fi

    for tech in "${TECHS[@]}"; do
        if download_asset "$tech" "$type" "$name" "$source_dir"; then
            return 0
        fi
    done
    return 1
}

sync_tech() {
    local tech=$1
    local source_dir=$2
    
    header "Syncing Technology: $tech"
    
    # 1. Discover Agents in this tech folder
    local folders=()
    if [ -n "$LOCAL_PATH" ]; then
        folders=$(ls "$source_dir/$tech/agents"/*.json 2>/dev/null | xargs -n 1 basename -s .json)
    else
        if ! command -v jq &> /dev/null; then error "Discovery requires 'jq'."; fi
        folders=$(curl -s -f "$GITHUB_API/contents/$tech/agents?ref=$BRANCH" | jq -r '.[] | select(.type == "file" and (.name | endswith(".json"))) | .name' | sed 's/\.json$//' 2>/dev/null)
    fi
    
    if [ -n "$folders" ]; then
        # Agent-Centric Sync: The agent will pull its own dependencies
        for folder in ${(f)folders}; do
            if [ -n "$folder" ]; then
                download_asset "$tech" "agents" "$folder" "$source_dir"
            fi
        done
    else
        # Fallback: Sync everything if no agents found (useful for 'shared' folder)
        local types=("instructions" "skills")
        for type in "${types[@]}"; do
            local subfolders=()
            if [ -n "$LOCAL_PATH" ]; then
                subfolders=$(ls -d "$source_dir/$tech/$type"/*/ 2>/dev/null | xargs -n 1 basename)
            else
                subfolders=$(curl -s -f "$GITHUB_API/contents/$tech/$type?ref=$BRANCH" | jq -r '.[] | select(.type == "dir") | .name' 2>/dev/null)
            fi
            
            for sub in ${(f)subfolders}; do
                if [ -n "$sub" ]; then
                    download_asset "$tech" "$type" "$sub" "$source_dir"
                fi
            done
        done
    fi
}

# --- Main Execution ---
header "🌌 Async Agents Synchronizer"

if [ -n "$LOCAL_PATH" ]; then
    info "LOCAL MODE: Source '$LOCAL_PATH'"
    SRC_DIR="$LOCAL_PATH"
else
    info "REMOTE MODE: Repository $REPO ($BRANCH)"
    SRC_DIR=""
fi

if [ "$CLEAN_MODE" = true ]; then
    info "Cleaning $AGENT_BASE directory..."
    rm -rf "$AGENT_BASE"
fi

if [ ${#SELECTED_ITEMS[@]} -eq 0 ]; then
    # Full Sync: All Techs
    for tech in "${TECHS[@]}"; do
        sync_tech "$tech" "$SRC_DIR"
    done
else
    # Targeted Sync
    for item in "${SELECTED_ITEMS[@]}"; do
        # Check if item is a technology
        is_tech=false
        for t in "${TECHS[@]}"; do
            if [ "$item" = "$t" ]; then
                is_tech=true
                break
            fi
        done
        
        if [ "$is_tech" = true ]; then
            sync_tech "$item" "$SRC_DIR"
        else
            header "Searching for asset: $item"
            found=false
            # Try as Agent, then Instruction, then Skill
            if find_and_download_asset "agents" "$item" "$SRC_DIR"; then
                found=true
            elif find_and_download_asset "instructions" "$item" "$SRC_DIR"; then
                found=true
            elif find_and_download_asset "skills" "$item" "$SRC_DIR"; then
                found=true
            fi
            
            if [ "$found" = false ]; then warn "Asset '$item' not found in any technology category."; fi
        fi
    done
fi

header "Summary"
success "🤖 Agents synced: $SYNC_COUNT_AGENTS"
success "🛠 Skills synced: $SYNC_COUNT_SKILLS"
success "📜 Instructions synced: $SYNC_COUNT_INST"
info "✨ All assets are ready in $AGENT_BASE/"
