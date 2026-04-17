#!/bin/zsh

# ==============================================================================
# 🌌 Skills AI Store - Downloader
# ==============================================================================
# This script downloads specialized AI skills from the central repository
# and integrates them into any local development project.
#
# Usage:
#   ./download_skills.sh [skill_name1] [skill_name2] [--clean] [--branch name]
# ==============================================================================

# --- Configuration ---
REPO="DiegoVilla27/skills-ai-store"
DEFAULT_BRANCH="main"
TARGET_DIR=".agents/skills"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO"
GITHUB_API="https://api.github.com/repos/$REPO"

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Utility Functions ---
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

usage() {
    echo "Usage: $0 [skills...] [options]"
    echo ""
    echo "Skills:"
    echo "  The name(s) of the skill folder(s) in the store. If omitted, the script will attempt to list all available skills."
    echo ""
    echo "Options:"
    echo "  --clean       Deletes the skills directory before downloading."
    echo "  --branch B    Specifies a different branch (default: main)."
    echo "  --local P     Specifies a local path to the store for development (skips GitHub)."
    echo "  --help        Shows this message."
    exit 0
}

# --- Initialization ---
SELECTED_SKILLS=()
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
        *) SELECTED_SKILLS+=("$1"); shift ;;
    esac
done

# --- Download/Copy Mode ---
if [ -n "$LOCAL_PATH" ]; then
    info "LOCAL MODE: Using source '$LOCAL_PATH'"
    # Validate local path
    if [ ! -d "$LOCAL_PATH" ]; then
        error "Local path '$LOCAL_PATH' does not exist."
    fi
    # The skills directory is expected to be under .agents/skills in the local path
    SOURCE_DIR="$LOCAL_PATH/.agents/skills"
    if [ ! -d "$SOURCE_DIR" ]; then
        error "Could not find '$SOURCE_DIR'."
    fi
else
    info "REMOTE MODE: Repository $REPO ($BRANCH)"
fi

# --- Cleanup Logic ---
if [ "$CLEAN_MODE" = true ]; then
    info "Cleaning skills directory: $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
fi

# --- Fetch Skills List (if none specified) ---
if [ ${#SELECTED_SKILLS[@]} -eq 0 ]; then
    if [ -n "$LOCAL_PATH" ]; then
        # List local folders
        ALL_SKILLS=$(ls -d "$SOURCE_DIR"/*/ 2>/dev/null | xargs -n 1 basename)
    else
        # Discovery requires jq
        if ! command -v jq &> /dev/null; then
            warn "Skill discovery requires 'jq'. Please install it or specify skill names manually."
            warn "Example: ./download_skills.sh react_core web_tailwind"
            exit 1
        fi

        info "Fetching available skills from branch '$BRANCH'..."
        # Try to use GitHub API to list folders
        API_URL="$GITHUB_API/contents/.agents/skills?ref=$BRANCH"
        ALL_SKILLS=$(curl -s -f "$API_URL" | jq -r '.[] | select(.type == "dir") | .name' 2>/dev/null)
    fi
    
    if [ -z "$ALL_SKILLS" ]; then
        warn "Could not retrieve skills list from the repository."
        warn "Please ensure the repository is public or you have the correct network access."
        exit 1
    fi
    
    SELECTED_SKILLS=(${(f)ALL_SKILLS})
    info "Skills discovered: ${SELECTED_SKILLS[*]}"
fi

# --- Download/Copy Skills ---
mkdir -p "$TARGET_DIR"

for skill in "${SELECTED_SKILLS[@]}"; do
    echo "----------------------------------------------------"
    info "Processing: $skill..."
    
    SKILL_PATH="$TARGET_DIR/$skill"
    mkdir -p "$SKILL_PATH"
    
    # Potential files to fetch
    FILES_TO_GET=("SKILL.md" "config.json" "EXAMPLES.md")
    FOUND_ANY=false

    for file in "${FILES_TO_GET[@]}"; do
        TARGET_FILE="$SKILL_PATH/$file"
        
        if [ -n "$LOCAL_PATH" ]; then
            # Local Mode: Copy if exists
            SOURCE_FILE="$SOURCE_DIR/$skill/$file"
            if [ -f "$SOURCE_FILE" ]; then
                cp "$SOURCE_FILE" "$TARGET_FILE"
                echo "  📁 $file [COPIED]"
                FOUND_ANY=true
            fi
        else
            # Remote Mode: Download
            FILE_URL="$GITHUB_RAW/$BRANCH/.agents/skills/$skill/$file"
            curl -s -f -L "$FILE_URL" -o "$TARGET_FILE"
            if [ $? -eq 0 ]; then
                echo "  🌐 $file [DOWNLOADED]"
                FOUND_ANY=true
            fi
        fi
    done

    if [ "$FOUND_ANY" = true ]; then
        success "Skill '$skill' is ready."
    else
        warn "No content found for '$skill'. Removing empty directory..."
        rm -rf "$SKILL_PATH"
    fi
done

echo "----------------------------------------------------"
success "✨ Process completed successfully."
