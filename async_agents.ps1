# ==============================================================================
# 🌌 Async Agents - Specialized AI Asset Synchronizer (Windows Edition)
# ==============================================================================
# This script synchronizes specialized AI instructions, skills, and personas
# from the central repository and integrates them into any local project.
#
# Usage:
#   .\async_agents.ps1 [tech|asset] [-Clean] [-Branch name]
# ==============================================================================

# --- Configuration ---
$REPO = "DiegoVilla27/agents-ai-store"
$DEFAULT_BRANCH = "main"
$AGENT_BASE = ".agents"
$GITHUB_RAW = "https://raw.githubusercontent.com/$REPO"
$GITHUB_API = "https://api.github.com/repos/$REPO"

$TECHS = @("angular", "react", "flutter", "nextjs", "nestjs", "react-native", "shared")

# --- Global Counters ---
$SYNC_COUNT_SKILLS = 0
$SYNC_COUNT_INST = 0
$SYNC_COUNT_AGENTS = 0

# --- Utility Functions ---
function info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Blue }
function success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function error_msg($msg) { Write-Host "❌ $msg" -ForegroundColor Red; exit 1 }
function header($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

function usage() {
    Write-Host "Usage: .\async_agents.ps1 [techs|assets...] [options]"
    Write-Host ""
    Write-Host "Techs:"
    Write-Host "  $($TECHS -join ' ')"
    Write-Host ""
    Write-Host "Assets:"
    Write-Host "  The name of a specific skill, instruction, or agent."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Clean         Deletes the .agents directory before downloading."
    Write-Host "  -Branch B      Specifies a different branch (default: main)."
    Write-Host "  -Local P       Specifies a local path to the store for development."
    Write-Host "  -Help          Shows this message."
    exit 0
}

# --- Argument Parsing ---
$SELECTED_ITEMS = @()
$CLEAN_MODE = $false
$BRANCH = $DEFAULT_BRANCH
$LOCAL_PATH = ""

$i = 0
while ($i -lt $args.Count) {
    $arg = $args[$i]
    switch ($arg) {
        "-Clean" { $CLEAN_MODE = $true }
        "-Branch" { $i++; $BRANCH = $args[$i] }
        "-Local" { $i++; $LOCAL_PATH = $args[$i] }
        "-Help" { usage }
        { $_ -like "-*" } { warn "Unknown option: $arg" }
        Default { $SELECTED_ITEMS += $arg }
    }
    $i++
}

# --- Download Logic ---
function Download-Asset($tech, $type, $name, $sourceDir) {
    $icon = "🛠"
    if ($type -eq "instructions") { $icon = "📜" }
    if ($type -eq "agents") { $icon = "🤖" }

    $targetPath = Join-Path $AGENT_BASE $type
    if ($type -ne "agents") {
        $targetPath = Join-Path $targetPath $name
    }

    $files = @()
    if ($type -eq "skills") {
        $files = @("SKILL.md", "config.json", "EXAMPLES.md")
    } elseif ($type -eq "instructions") {
        $files = @("INSTRUCTION.md")
    } elseif ($type -eq "agents") {
        $files = @("$name.json")
    }

    $found = $false
    foreach ($file in $files) {
        if (-not (Test-Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }
        
        $targetFile = Join-Path $targetPath $file

        if ($LOCAL_PATH) {
            # Local Mode
            $srcFile = Join-Path $sourceDir $tech
            $srcFile = Join-Path $srcFile $type
            if ($type -ne "agents") {
                $srcFile = Join-Path $srcFile $name
            }
            $srcFile = Join-Path $srcFile $file

            if (Test-Path $srcFile) {
                Copy-Item -Path $srcFile -Destination $targetFile -Force
                if ($file -eq $files[1] -or $type -ne "skills") {
                    info "Processing $icon $name ($tech/$type)..."
                }
                Write-Host "  📁 $file [COPIED]"
                $found = $true
            }
        } else {
            # Remote Mode
            $fileUrl = "$GITHUB_RAW/$BRANCH/$tech/$type/"
            if ($type -ne "agents") {
                $fileUrl += "$name/"
            }
            $fileUrl += "$file"

            try {
                Invoke-WebRequest -Uri $fileUrl -OutFile $targetFile -ErrorAction Stop
                if ($file -eq $files[1] -or $type -ne "skills") {
                    info "Processing $icon $name ($tech/$type)..."
                }
                Write-Host "  🌐 $file [DOWNLOADED]"
                $found = $true
            } catch {
                # Skip if file not found
            }
        }
    }

    if ($found) {
        if ($type -eq "skills") { $script:SYNC_COUNT_SKILLS++ }
        elseif ($type -eq "instructions") { $script:SYNC_COUNT_INST++ }
        else { $script:SYNC_COUNT_AGENTS++ }

        # Recursive sync for Agents
        if ($type -eq "agents") {
            $agentFile = Join-Path $AGENT_BASE "agents"
            $agentFile = Join-Path $agentFile "$name.json"

            if (Test-Path $agentFile) {
                try {
                    $agentData = Get-Content -Raw $agentFile | ConvertFrom-Json
                    
                    # Sync Instructions
                    if ($agentData.instructions) {
                        foreach ($inst in $agentData.instructions) {
                            if ($inst) {
                                Find-And-Download-Asset "instructions" $inst $sourceDir
                            }
                        }
                    }
                    # Sync Skills
                    if ($agentData.skills) {
                        foreach ($skill in $agentData.skills) {
                            if ($skill) {
                                Find-And-Download-Asset "skills" $skill $sourceDir
                            }
                        }
                    }
                } catch {
                    warn "Failed to parse $name.json for dependencies."
                }
            }
        }
        return $true
    }
    return $false
}

function Find-And-Download-Asset($type, $name, $sourceDir) {
    # Check if already downloaded
    $pathToCheck = Join-Path $AGENT_BASE $type
    if ($type -eq "agents") {
        $pathToCheck = Join-Path $pathToCheck "$name.json"
    } else {
        $pathToCheck = Join-Path $pathToCheck $name
    }
    if (Test-Path $pathToCheck) { return $true }

    foreach ($tech in $TECHS) {
        if (Download-Asset $tech $type $name $sourceDir) {
            return $true
        }
    }
    return $false
}

function Sync-Tech($tech, $sourceDir) {
    header "Syncing Technology: $tech"

    $folders = @()
    if ($LOCAL_PATH) {
        $agentDir = Join-Path $sourceDir $tech
        $agentDir = Join-Path $agentDir "agents"
        if (Test-Path $agentDir) {
            $folders = Get-ChildItem -Path $agentDir -Filter "*.json" | ForEach-Object { $_.BaseName }
        }
    } else {
        try {
            $apiUrl = "$GITHUB_API/contents/$tech/agents?ref=$BRANCH"
            $response = Invoke-RestMethod -Uri $apiUrl
            $folders = $response | Where-Object { $_.type -eq "file" -and $_.name -like "*.json" } | ForEach-Object { $_.name.Replace(".json", "") }
        } catch {
            # No agents found or error
        }
    }

    if ($folders) {
        foreach ($folder in $folders) {
            if ($folder) {
                Download-Asset $tech "agents" $folder $sourceDir
            }
        }
    } else {
        # Fallback: Sync everything
        $types = @("instructions", "skills")
        foreach ($type in $types) {
            $subfolders = @()
            if ($LOCAL_PATH) {
                $typeDir = Join-Path $sourceDir $tech
                $typeDir = Join-Path $typeDir $type
                if (Test-Path $typeDir) {
                    $subfolders = Get-ChildItem -Path $typeDir -Directory | ForEach-Object { $_.Name }
                }
            } else {
                try {
                    $apiUrl = "$GITHUB_API/contents/$tech/$type?ref=$BRANCH"
                    $response = Invoke-RestMethod -Uri $apiUrl
                    $subfolders = $response | Where-Object { $_.type -eq "dir" } | ForEach-Object { $_.name }
                } catch { }
            }

            foreach ($sub in $subfolders) {
                if ($sub) {
                    Download-Asset $tech $type $sub $sourceDir
                }
            }
        }
    }
}

# --- Main Execution ---
header "🌌 Async Agents Synchronizer"

if ($LOCAL_PATH) {
    info "LOCAL MODE: Source '$LOCAL_PATH'"
    $SRC_DIR = $LOCAL_PATH
} else {
    info "REMOTE MODE: Repository $REPO ($BRANCH)"
    $SRC_DIR = ""
}

if ($CLEAN_MODE) {
    info "Cleaning $AGENT_BASE directory..."
    if (Test-Path $AGENT_BASE) {
        Remove-Item -Path $AGENT_BASE -Recurse -Force
    }
}

if ($SELECTED_ITEMS.Count -eq 0) {
    # Full Sync
    foreach ($tech in $TECHS) {
        Sync-Tech $tech $SRC_DIR
    }
} else {
    # Targeted Sync
    foreach ($item in $SELECTED_ITEMS) {
        $isTech = $false
        foreach ($t in $TECHS) {
            if ($item -eq $t) {
                $isTech = $true
                break
            }
        }

        if ($isTech) {
            Sync-Tech $item $SRC_DIR
        } else {
            header "Searching for asset: $item"
            $found = $false
            if (Find-And-Download-Asset "agents" $item $SRC_DIR) { $found = $true }
            elseif (Find-And-Download-Asset "instructions" $item $SRC_DIR) { $found = $true }
            elseif (Find-And-Download-Asset "skills" $item $SRC_DIR) { $found = $true }

            if (-not $found) { warn "Asset '$item' not found in any technology category." }
        }
    }
}

header "Summary"
success "🤖 Agents synced: $SYNC_COUNT_AGENTS"
success "🛠 Skills synced: $SYNC_COUNT_SKILLS"
success "📜 Instructions synced: $SYNC_COUNT_INST"
info "✨ All assets are ready in $AGENT_BASE/"
