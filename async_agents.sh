#!/bin/zsh

# ==============================================================================
# 🌌 Async Agents - Specialized AI Asset Synchronizer
# ==============================================================================
# This script synchronizes specialized AI instructions, skills, and personas
# from the central repository and integrates them into any local project.
#
# Usage:
#   ./async_agents.sh [asset_name1] [asset_name2] [--clean] [--branch name]
# ==============================================================================

# --- Configuration ---
REPO="DiegoVilla27/skills-ai-store"
DEFAULT_BRANCH="main"
AGENT_BASE=".agents"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO"
GITHUB_API="https://api.github.com/repos/$REPO"

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
    echo "Usage: $0 [assets...] [options]"
    echo ""
    echo "Assets:"
    echo "  The name(s) of the skill, instruction, or agent (persona) folders."
    echo "  If omitted, all assets will be synced."
    echo ""
    echo "Options:"
    echo "  --clean         Deletes the .agents directory before downloading."
    echo "  --branch B      Specifies a different branch (default: main)."
    echo "  --local P       Specifies a local path to the store for development."
    echo "  --skills        Only sync skills."
    echo "  --instructions  Only sync instructions."
    echo "  --agents        Only sync agent personas."
    echo "  --help          Shows this message."
    exit 0
}

# --- Initialization ---
SELECTED_ASSETS=()
CLEAN_MODE=false
BRANCH=$DEFAULT_BRANCH
LOCAL_PATH=""
SCAN_SKILLS=true
SCAN_INSTRUCTIONS=true
SCAN_AGENTS=true

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean) CLEAN_MODE=true; shift ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --local) LOCAL_PATH="$2"; shift 2 ;;
        --skills) SCAN_INSTRUCTIONS=false; SCAN_AGENTS=false; shift ;;
        --instructions) SCAN_SKILLS=false; SCAN_AGENTS=false; shift ;;
        --agents) SCAN_SKILLS=false; SCAN_INSTRUCTIONS=false; shift ;;
        --help) usage ;;
        -*) warn "Unknown option: $1"; shift ;;
        *) SELECTED_ASSETS+=("$1"); shift ;;
    esac
done

# --- Download Logic ---
download_asset() {
    local type=$1    # "skills", "instructions", or "agents"
    local name=$2    # folder or file name
    local source_dir=$3
    local icon="🛠"
    
    if [ "$type" = "instructions" ]; then icon="📜"; fi
    if [ "$type" = "agents" ]; then icon="🤖"; fi
    
    info "Processing $icon $name ($type)..."
    
    local target_path="$AGENT_BASE/$type/$name"
    if [ "$type" = "agents" ]; then
        target_path="$AGENT_BASE/$type"
    fi
    mkdir -p "$target_path"
    
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
            local src_file="$source_dir/$type/$name/$file"
            if [ "$type" = "agents" ]; then src_file="$source_dir/$type/$file"; fi
            
            if [ -f "$src_file" ]; then
                cp "$src_file" "$target_file"
                echo "  📁 $file [COPIED]"
                found=true
            fi
        else
            # Remote Mode
            local file_url="$GITHUB_RAW/$BRANCH/.agents/$type/$name/$file"
            if [ "$type" = "agents" ]; then file_url="$GITHUB_RAW/$BRANCH/.agents/$type/$file"; fi
            
            curl -s -f -L "$file_url" -o "$target_file"
            if [ $? -eq 0 ]; then
                echo "  🌐 $file [DOWNLOADED]"
                found=true
            fi
        fi
    done
    
    if [ "$found" = true ]; then
        # Recursive sync for Agents
        if [ "$type" = "agents" ]; then
            local agent_file="$AGENT_BASE/agents/$name.json"
            if [ -f "$agent_file" ]; then
                # Sync Instructions
                local inst_list=$(jq -r '.instructions[]?' "$agent_file" 2>/dev/null)
                for inst in ${(f)inst_list}; do
                    if [ -n "$inst" ]; then
                        download_asset "instructions" "$inst" "$source_dir"
                        ((SYNC_COUNT_INST++))
                    fi
                done
                # Sync Skills
                local skill_list=$(jq -r '.skills[]?' "$agent_file" 2>/dev/null)
                for skill in ${(f)skill_list}; do
                    if [ -n "$skill" ]; then
                        download_asset "skills" "$skill" "$source_dir"
                        ((SYNC_COUNT_SKILLS++))
                    fi
                done
            fi
        fi
        return 0
    else
        if [ "$type" != "agents" ]; then rm -rf "$target_path"; fi
        return 1
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

if [ ${#SELECTED_ASSETS[@]} -eq 0 ]; then
    # Full Discovery Sync
    for type in "agents" "instructions" "skills"; do
        if [ "$type" = "skills" ] && [ "$SCAN_SKILLS" = false ]; then continue; fi
        if [ "$type" = "instructions" ] && [ "$SCAN_INSTRUCTIONS" = false ]; then continue; fi
        if [ "$type" = "agents" ] && [ "$SCAN_AGENTS" = false ]; then continue; fi
        
        header "Syncing $type"
        
        if [ -n "$LOCAL_PATH" ]; then
            if [ "$type" = "agents" ]; then
                folders=$(ls "$LOCAL_PATH/.agents/agents"/*.json 2>/dev/null | xargs -n 1 basename -s .json)
            else
                folders=$(ls -d "$LOCAL_PATH/.agents/$type"/*/ 2>/dev/null | xargs -n 1 basename)
            fi
        else
            if ! command -v jq &> /dev/null; then error "Discovery requires 'jq'. Install it or specify names manually."; fi
            if [ "$type" = "agents" ]; then
                folders=$(curl -s -f "$GITHUB_API/contents/.agents/agents?ref=$BRANCH" | jq -r '.[] | select(.type == "file" and (.name | endswith(".json"))) | .name' | sed 's/\.json$//' 2>/dev/null)
            else
                folders=$(curl -s -f "$GITHUB_API/contents/.agents/$type?ref=$BRANCH" | jq -r '.[] | select(.type == "dir") | .name' 2>/dev/null)
            fi
        fi
        
        for folder in ${(f)folders}; do
            if [ -n "$folder" ]; then
                if download_asset "$type" "$folder" "$LOCAL_PATH/.agents"; then
                    if [ "$type" = "skills" ]; then ((SYNC_COUNT_SKILLS++)); elif [ "$type" = "instructions" ]; then ((SYNC_COUNT_INST++)); else ((SYNC_COUNT_AGENTS++)); fi
                fi
            fi
        done
    done
else
    # Targeted Sync
    for asset in "${SELECTED_ASSETS[@]}"; do
        header "Searching for $asset"
        found=false
        
        # Try as Agent first (priority)
        if download_asset "agents" "$asset" "$LOCAL_PATH/.agents"; then
            ((SYNC_COUNT_AGENTS++))
            found=true
        else
            # Try as Instruction
            if download_asset "instructions" "$asset" "$LOCAL_PATH/.agents"; then
                ((SYNC_COUNT_INST++))
                found=true
            else
                # Try as Skill
                if download_asset "skills" "$asset" "$LOCAL_PATH/.agents"; then
                    ((SYNC_COUNT_SKILLS++))
                    found=true
                fi
            fi
        fi
        
        if [ "$found" = false ]; then warn "Asset '$asset' not found in repo."; fi
    done
fi

header "Summary"
success "🤖 Agents synced: $SYNC_COUNT_AGENTS"
success "🛠 Skills synced: $SYNC_COUNT_SKILLS"
success "📜 Instructions synced: $SYNC_COUNT_INST"
info "✨ All assets are ready in $AGENT_BASE/"
