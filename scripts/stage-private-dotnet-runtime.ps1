[CmdletBinding()]
param([Parameter(Mandatory)] [string]$OutputDirectory)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dotnetCommand = Get-Command dotnet -CommandType Application | Select-Object -First 1
if ($null -eq $dotnetCommand) { throw 'The .NET SDK host was not found.' }
$dotnetRoot = Split-Path -Parent $dotnetCommand.Source
$runtimeLine = (& $dotnetCommand.Source --list-runtimes | Where-Object { $_ -match '^Microsoft\.NETCore\.App 10\.' } | Select-Object -Last 1)
if ($runtimeLine -notmatch '^Microsoft\.NETCore\.App (?<version>\S+) \[') { throw 'A .NET 10 Microsoft.NETCore.App runtime was not found.' }
$runtimeVersion = $Matches.version
$runtimeSource = Join-Path $dotnetRoot "shared\Microsoft.NETCore.App\$runtimeVersion"
if (-not (Test-Path -LiteralPath $runtimeSource -PathType Container)) { throw "Runtime source was not found: $runtimeSource" }

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $dotnetRoot 'dotnet.exe') -Destination (Join-Path $OutputDirectory 'dotnet.exe') -Force
Copy-Item -LiteralPath (Join-Path $dotnetRoot 'host') -Destination (Join-Path $OutputDirectory 'host') -Recurse -Force
$sharedOutput = Join-Path $OutputDirectory "shared\Microsoft.NETCore.App\$runtimeVersion"
New-Item -ItemType Directory -Force -Path $sharedOutput | Out-Null
Get-ChildItem -LiteralPath $runtimeSource -Force | Copy-Item -Destination $sharedOutput -Recurse -Force
Write-Host "Staged private .NET runtime $runtimeVersion at $OutputDirectory."
