# ==============================================================================
# 🌌 Async Agents - Specialized AI Asset Synchronizer (Windows Edition)
# ==============================================================================
# Synchronizes specialized AI AGENTS.md protocols and skills from the central
# repository directly into your local project's .agents/ root folder.
#
# Usage:
#   .\async_agents.ps1 [tech|skill] [-Clean] [-Branch name] [-Local path]
# ==============================================================================

# --- Configuration ---
$REPO = "DiegoVilla27/agents-ai-store"
$DEFAULT_BRANCH = "main"
$AGENT_BASE = ".agents"
$GITHUB_RAW = "https://raw.githubusercontent.com/$REPO"
$GITHUB_API = "https://api.github.com/repos/$REPO"

$TECHS = @("angular", "react", "flutter", "nextjs", "nestjs", "react-native", "ionic", "shared", "ui-ux-designer", "digital-marketer", "express", "spring-boot")

# --- Global Counters ---
$SYNC_COUNT_SKILLS = 0
$SYNC_COUNT_AGENTS = 0

# --- Utility Functions ---
function info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Blue }
function success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function error_msg($msg) { Write-Host "❌ $msg" -ForegroundColor Red; exit 1 }
function header($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

function usage() {
    Write-Host "Usage: .\async_agents.ps1 [techs|skills...] [options]"
    Write-Host ""
    Write-Host "Available Technologies:"
    Write-Host "  $($TECHS -join ' ')"
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
    switch -regex ($arg) {
        "^-Clean$" { $CLEAN_MODE = $true }
        "^-Branch$" { $i++; $BRANCH = $args[$i] }
        "^-Local$" { $i++; $LOCAL_PATH = $args[$i] }
        "^-Help$" { usage }
        "^-.*" { warn "Unknown option: $arg" }
        Default { $SELECTED_ITEMS += $arg }
    }
    $i++
}

# --- Smart Merge Helper ---
function Sync-AgentsMd($tech) {
    $srcRelPath = "$tech/AGENTS.md"
    $targetFile = Join-Path $AGENT_BASE "AGENTS.md"

    if (-not (Test-Path $AGENT_BASE)) {
        New-Item -ItemType Directory -Path $AGENT_BASE -Force | Out-Null
    }

    $content = ""
    if ($LOCAL_PATH) {
        $srcFile = Join-Path $LOCAL_PATH $srcRelPath
        if (Test-Path $srcFile) {
            $content = Get-Content -Raw -Path $srcFile
        }
    } else {
        $fileUrl = "$GITHUB_RAW/$BRANCH/$srcRelPath"
        try {
            $content = (Invoke-WebRequest -Uri $fileUrl -ErrorAction Stop).Content
        } catch {
            warn "AGENTS.md not found for technology '$tech'."
            return $false
        }
    }

    if (-not $content) { return $false }

    if (-not (Test-Path $targetFile)) {
        Set-Content -Path $targetFile -Value $content -Encoding UTF8
        Write-Host "  🌐 AGENTS.md ($tech) [CREATED]"
        $script:SYNC_COUNT_AGENTS++
        return $true
    } else {
        $existingContent = Get-Content -Raw -Path $targetFile
        $lines = $content -split "`r?\n"
        $firstHeader = ($lines | Where-Object { $_ -like "# *" } | Select-Object -First 1)

        if ($firstHeader -and $existingContent.Contains($firstHeader)) {
            Write-Host "  ℹ️  AGENTS.md ($tech protocol already present)"
            return $true
        }

        $merged = "`n`n---`n`n" + $content
        Add-Content -Path $targetFile -Value $merged -Encoding UTF8
        Write-Host "  🌐 AGENTS.md ($tech protocol [MERGED])"
        $script:SYNC_COUNT_AGENTS++
        return $true
    }
}

function Sync-SkillByPath($tech, $skillName) {
    $skillMdCheck = Join-Path $AGENT_BASE "skills"
    $skillMdCheck = Join-Path $skillMdCheck $skillName
    $skillMdCheck = Join-Path $skillMdCheck "SKILL.md"

    if (Test-Path $skillMdCheck) {
        return $true
    }

    $found = $false
    if ($LOCAL_PATH) {
        $skillDir = Join-Path $LOCAL_PATH $tech
        $skillDir = Join-Path $skillDir "skills"
        $skillDir = Join-Path $skillDir $skillName

        if (Test-Path $skillDir) {
            info "Processing 🛠 Skill: $skillName ($tech)..."
            $targetDir = Join-Path $AGENT_BASE "skills"
            $targetDir = Join-Path $targetDir $skillName
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Copy-Item -Path "$skillDir\*" -Destination $targetDir -Recurse -Force
            Write-Host "  📁 SKILL.md [COPIED]"
            $found = $true
        }
    } else {
        $skillUrl = "$GITHUB_RAW/$BRANCH/$tech/skills/$skillName/SKILL.md"
        try {
            $targetDir = Join-Path $AGENT_BASE "skills"
            $targetDir = Join-Path $targetDir $skillName
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            $targetFile = Join-Path $targetDir "SKILL.md"
            Invoke-WebRequest -Uri $skillUrl -OutFile $targetFile -ErrorAction Stop
            info "Processing 🛠 Skill: $skillName ($tech)..."
            Write-Host "  🌐 SKILL.md [DOWNLOADED]"

            foreach ($aux in @("config.json", "EXAMPLES.md")) {
                $auxUrl = "$GITHUB_RAW/$BRANCH/$tech/skills/$skillName/$aux"
                $auxTarget = Join-Path $targetDir $aux
                try {
                    Invoke-WebRequest -Uri $auxUrl -OutFile $auxTarget -ErrorAction Stop
                    Write-Host "  🌐 $aux [DOWNLOADED]"
                } catch {}
            }
            $found = $true
        } catch {}
    }

    if ($found) {
        $script:SYNC_COUNT_SKILLS++
        return $true
    }
    return $false
}

function Find-And-Sync-Skill($skillName) {
    $skillMdCheck = Join-Path $AGENT_BASE "skills"
    $skillMdCheck = Join-Path $skillMdCheck $skillName
    $skillMdCheck = Join-Path $skillMdCheck "SKILL.md"

    if (Test-Path $skillMdCheck) { return $true }

    foreach ($tech in $TECHS) {
        if (Sync-SkillByPath $tech $skillName) {
            return $true
        }
    }
    return $false
}

function Sync-Technology($tech) {
    header "Syncing Technology Package: $tech"

    info "Processing 🤖 Agent protocol ($tech/AGENTS.md)..."
    Sync-AgentsMd $tech | Out-Null

    $skillNames = @()
    if ($LOCAL_PATH) {
        $skillsDir = Join-Path $LOCAL_PATH $tech
        $skillsDir = Join-Path $skillsDir "skills"
        if (Test-Path $skillsDir) {
            $skillNames = Get-ChildItem -Path $skillsDir -Directory | ForEach-Object { $_.Name }
        }
    } else {
        try {
            $apiUrl = "$GITHUB_API/contents/$tech/skills?ref=$BRANCH"
            $res = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
            $skillNames = $res | Where-Object { $_.type -eq "dir" } | ForEach-Object { $_.name }
        } catch {}
    }

    foreach ($sname in $skillNames) {
        Sync-SkillByPath $tech $sname
    }

    $agentsMdFile = Join-Path $AGENT_BASE "AGENTS.md"
    if (Test-Path $agentsMdFile) {
        info "Resolving dependency skills referenced in AGENTS.md..."
        $content = Get-Content -Path $agentsMdFile
        foreach ($line in $content) {
            if ($line -match "^\s*-\s*`([^`]+)`") {
                $refSkill = $matches[1]
                if ($refSkill) {
                    Find-And-Sync-Skill $refSkill | Out-Null
                }
            }
        }
    }
}

# --- Main Execution ---
header "🌌 Async Agents Synchronizer"

if ($LOCAL_PATH) {
    info "LOCAL MODE: Source '$LOCAL_PATH'"
} else {
    info "REMOTE MODE: Repository $REPO ($BRANCH)"
}

if ($CLEAN_MODE) {
    info "Cleaning $AGENT_BASE directory..."
    if (Test-Path $AGENT_BASE) {
        Remove-Item -Path $AGENT_BASE -Recurse -Force
    }
}

if ($SELECTED_ITEMS.Count -eq 0) {
    info "No specific technology provided. Syncing all technologies..."
    foreach ($tech in $TECHS) {
        Sync-Technology $tech
    }
} else {
    foreach ($item in $SELECTED_ITEMS) {
        if ($TECHS -contains $item) {
            Sync-Technology $item
        } else {
            header "Searching for skill: $item"
            if (-not (Find-And-Sync-Skill $item)) {
                warn "Skill or technology '$item' not found."
            }
        }
    }
}

header "Sync Summary"
if ($SYNC_COUNT_AGENTS -gt 0) {
    success "🤖 AGENTS.md protocol synced/merged to $AGENT_BASE/AGENTS.md"
}
success "🛠 Skills synced: $SYNC_COUNT_SKILLS"
info "✨ All assets are ready in $AGENT_BASE/"
