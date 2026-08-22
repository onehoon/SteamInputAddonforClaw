[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$')] [string]$Version,
    [Parameter(Mandatory)] [ValidateSet('Debug', 'Release')] [string]$Configuration,
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string]$PublishDirectory,
    [switch]$NoRestore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimeProject = Join-Path $PSScriptRoot '..\src\SteamInputAddonforClaw\SteamInputAddonforClaw.csproj'
$uiProject = Join-Path $PSScriptRoot '..\src\SteamInputAddonforClaw.UI\SteamInputAddonforClaw.UI.csproj'
$qamProject = Join-Path $PSScriptRoot '..\src\SteamInputAddonforClaw.QamHost\SteamInputAddonforClaw.QamHost.csproj'
$runtimeOutput = [System.IO.Path]::GetFullPath($PublishDirectory)
$uiOutput = Join-Path $runtimeOutput 'ui'
$qamOutput = Join-Path $runtimeOutput 'qam'
$privateDotnetOutput = Join-Path $runtimeOutput 'dotnet'

if (Test-Path -LiteralPath $runtimeOutput) {
    Remove-Item -LiteralPath $runtimeOutput -Recurse -Force
}
New-Item -ItemType Directory -Path $runtimeOutput -Force | Out-Null
New-Item -ItemType Directory -Path $uiOutput -Force | Out-Null
New-Item -ItemType Directory -Path $qamOutput -Force | Out-Null

$commonArguments = @(
    '--configuration', $Configuration,
    '--runtime', 'win-x64',
    '--self-contained', 'true',
    "/p:Version=$Version"
)
if ($NoRestore) { $commonArguments += '--no-restore' }

dotnet publish $runtimeProject @commonArguments '--output' $runtimeOutput
if ($LASTEXITCODE -ne 0) { throw "Runtime publish failed with exit code $LASTEXITCODE." }

dotnet publish $uiProject @commonArguments '--output' $uiOutput
if ($LASTEXITCODE -ne 0) { throw "UI publish failed with exit code $LASTEXITCODE." }

$qamArguments = @('--configuration', $Configuration, '--runtime', 'win-x64', '--self-contained', 'false', "/p:Version=$Version", '/p:AppHostDotNetSearch=AppRelative', '/p:AppHostRelativeDotNet=../dotnet')
if ($NoRestore) { $qamArguments += '--no-restore' }
dotnet publish $qamProject @qamArguments '--output' $qamOutput
if ($LASTEXITCODE -ne 0) { throw "QamHost publish failed with exit code $LASTEXITCODE." }

& (Join-Path $PSScriptRoot 'stage-private-dotnet-runtime.ps1') -OutputDirectory $privateDotnetOutput
if ($LASTEXITCODE -ne 0) { throw "Private .NET runtime staging failed with exit code $LASTEXITCODE." }

Write-Host "Published Runtime and external UI layout at $runtimeOutput with version $Version."
