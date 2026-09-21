<#
.SYNOPSIS
    DemoMaker 스킬을 Claude Code 와 Codex 에 설치합니다.

.DESCRIPTION
    저장소의 shared\ 에 있는 템플릿과 참고 자료를, 대상 도구가 읽는 스킬 폴더로 복사합니다.
    두 도구는 스킬을 찾는 경로와 참고 자료 폴더의 이름이 서로 다르므로 이 스크립트가 맞춰 줍니다.

        Claude Code : <범위>\.claude\skills\demo-maker\  (참고 자료 폴더 이름은 reference)
        Codex       : <범위>\.agents\skills\demo-maker\  (참고 자료 폴더 이름은 references)

.PARAMETER Target
    설치할 대상입니다. claude, codex, all 중 하나이며 기본값은 all 입니다.

.PARAMETER Scope
    user 이면 홈 폴더에 설치해 모든 프로젝트에서 쓰고, repo 이면 특정 저장소 안에만 설치합니다.
    기본값은 user 입니다.

.PARAMETER RepoPath
    Scope 가 repo 일 때 설치할 저장소의 경로입니다. 생략하면 현재 폴더를 씁니다.

.PARAMETER DestRoot
    설치 위치의 뿌리를 직접 지정합니다. 시험 설치에 씁니다. 지정하면 Scope 와 RepoPath 는 무시됩니다.

.PARAMETER Uninstall
    설치하는 대신 해당 스킬 폴더를 지웁니다.

.EXAMPLE
    .\install.ps1
    두 도구 모두에 설치합니다.

.EXAMPLE
    .\install.ps1 -Target codex
    Codex 에만 설치합니다.

.EXAMPLE
    .\install.ps1 -Target claude -Scope repo -RepoPath C:\work\myproject
    특정 저장소 안에만 설치해 그 저장소에서 일할 때만 보이게 합니다.
#>
[CmdletBinding()]
param(
    [ValidateSet('claude', 'codex', 'all')]
    [string] $Target = 'all',

    [ValidateSet('user', 'repo')]
    [string] $Scope = 'user',

    [string] $RepoPath,

    [string] $DestRoot,

    [switch] $Uninstall
)

$ErrorActionPreference = 'Stop'

$SkillName = 'demo-maker'
$SourceRoot = Split-Path -Parent $PSScriptRoot

function Get-DestinationRoot {
    param([string] $Tool)

    if ($DestRoot) { return (Join-Path $DestRoot $Tool) }
    if ($Scope -eq 'user') { return $HOME }
    if ($RepoPath) { return $RepoPath }
    return (Get-Location).Path
}

function Get-SkillPath {
    param([string] $Tool)

    $root = Get-DestinationRoot -Tool $Tool
    # 도구마다 스킬을 찾는 폴더가 다릅니다.
    if ($Tool -eq 'claude') { $holder = '.claude\skills' } else { $holder = '.agents\skills' }
    return (Join-Path (Join-Path $root $holder) $SkillName)
}

function Install-One {
    param([string] $Tool)

    $skillSource = Join-Path $SourceRoot "$Tool\skills\$SkillName"
    if (-not (Test-Path $skillSource)) {
        throw "원본을 찾지 못했습니다: $skillSource"
    }

    $destination = Get-SkillPath -Tool $Tool

    if ($Uninstall) {
        if (Test-Path $destination) {
            Remove-Item -Recurse -Force $destination
            Write-Host "[$Tool] 지웠습니다 — $destination"
        } else {
            Write-Host "[$Tool] 설치되어 있지 않습니다 — $destination"
        }
        return
    }

    # 예전 설치본이 남아 있으면 지운 자리에 새로 놓습니다. 파일이 섞이면 원인을 찾기 어렵습니다.
    if (Test-Path $destination) { Remove-Item -Recurse -Force $destination }
    New-Item -ItemType Directory -Force -Path $destination | Out-Null

    # ① 도구별 원본 (SKILL.md 와 Codex 의 agents\openai.yaml)
    Copy-Item -Recurse -Force -Path (Join-Path $skillSource '*') -Destination $destination

    # ② 공용 템플릿
    $templates = Join-Path $destination 'templates'
    New-Item -ItemType Directory -Force -Path $templates | Out-Null
    Copy-Item -Force -Path (Join-Path $SourceRoot 'shared\templates\*') -Destination $templates

    # ③ 공용 참고 자료. 폴더 이름이 도구마다 다릅니다.
    if ($Tool -eq 'claude') { $referenceName = 'reference' } else { $referenceName = 'references' }
    $reference = Join-Path $destination $referenceName
    New-Item -ItemType Directory -Force -Path $reference | Out-Null
    Copy-Item -Force -Path (Join-Path $SourceRoot 'shared\reference\*') -Destination $reference

    $count = (Get-ChildItem -Recurse -File $destination).Count
    Write-Host "[$Tool] 설치했습니다 — $destination (파일 $count 개)"
}

$targets = @()
if ($Target -eq 'all') { $targets = @('claude', 'codex') } else { $targets = @($Target) }

foreach ($tool in $targets) { Install-One -Tool $tool }

if (-not $Uninstall) {
    Write-Host ''
    Write-Host '불러 쓰는 법:'
    if ($targets -contains 'claude') { Write-Host '  Claude Code : /demo-maker' }
    if ($targets -contains 'codex')  { Write-Host '  Codex       : $demo-maker  (또는 /skills 목록에서 선택)' }
    Write-Host '이미 실행 중인 세션이라면 한 번 다시 시작해야 목록에 나타납니다.'
}
