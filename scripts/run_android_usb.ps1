<#
.SYNOPSIS
Runs the Flutter app on a physical Android USB device with adb reverse configured.

.EXAMPLE
.\scripts\run_android_usb.ps1

.EXAMPLE
.\scripts\run_android_usb.ps1 -DeviceId R5CT123456A -BackendPort 3600 -FlutterArgs "--debug"
#>
[CmdletBinding()]
param(
  [string]$DeviceId,

  [ValidateRange(1, 65535)]
  [int]$BackendPort = 3600,

  [string[]]$FlutterArgs = @()
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Fail {
  param([string]$Message)

  Write-Error $Message
  exit 1
}

function Resolve-AdbPath {
  $candidates = New-Object System.Collections.Generic.List[string]

  foreach ($root in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
    if ([string]::IsNullOrWhiteSpace($root)) {
      continue
    }

    $candidates.Add((Join-Path $root 'platform-tools\adb.exe'))
    $candidates.Add((Join-Path $root 'adb.exe'))
  }

  if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'))
  }

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  $adbCommand = Get-Command 'adb.exe' -ErrorAction SilentlyContinue
  if ($adbCommand) {
    return $adbCommand.Source
  }

  $adbCommand = Get-Command 'adb' -ErrorAction SilentlyContinue
  if ($adbCommand) {
    return $adbCommand.Source
  }

  return $null
}

function Test-BackendHealth {
  param([int]$Port)

  $healthUrl = "http://127.0.0.1:$Port/health"

  try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 5
  } catch {
    Fail "Backend health check failed at $healthUrl. Start the backend on 127.0.0.1:$Port or pass -BackendPort."
  }

  if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
    Fail "Backend health check returned HTTP $($response.StatusCode) at $healthUrl."
  }

  try {
    $payload = $response.Content | ConvertFrom-Json
    if ($payload.status -and $payload.status -ne 'healthy') {
      Fail "Backend health status is '$($payload.status)' (expected 'healthy'). Start the backend and retry."
    }
  } catch {
    Write-Warning "Backend health endpoint is reachable, but the response was not JSON."
  }

  Write-Host "Backend health OK: $healthUrl"
}

function Get-AdbDevices {
  param([string]$AdbPath)

  try {
    $lines = & $AdbPath devices -l
  } catch {
    Fail "Unable to run adb at '$AdbPath'. Check the Android SDK installation."
  }

  if ($LASTEXITCODE -ne 0) {
    Fail "adb devices failed with exit code $LASTEXITCODE."
  }

  $devices = @()
  foreach ($line in $lines) {
    if ($line -match '^\s*$' -or $line -match '^List of devices attached') {
      continue
    }

    if ($line -match '^(\S+)\s+(\S+)(?:\s+(.*))?$') {
      $devices += [pscustomobject]@{
        Id = $matches[1]
        State = $matches[2]
        Details = $matches[3]
      }
    }
  }

  return $devices
}

function Select-AndroidDevice {
  param(
    [array]$Devices,
    [string]$RequestedDeviceId
  )

  if ($RequestedDeviceId) {
    $match = $Devices | Where-Object { $_.Id -eq $RequestedDeviceId } | Select-Object -First 1
    if (-not $match) {
      $knownDevices = ($Devices | ForEach-Object { "$($_.Id) [$($_.State)]" }) -join ', '
      if ([string]::IsNullOrWhiteSpace($knownDevices)) {
        $knownDevices = 'none'
      }

      Fail "Android device '$RequestedDeviceId' was not found. Connected devices: $knownDevices."
    }

    if ($match.State -ne 'device') {
      Fail "Android device '$RequestedDeviceId' is '$($match.State)', not ready. Unlock it, authorize USB debugging, then retry."
    }

    return $match.Id
  }

  $readyDevices = @($Devices | Where-Object { $_.State -eq 'device' })

  if ($readyDevices.Count -eq 0) {
    $knownDevices = ($Devices | ForEach-Object { "$($_.Id) [$($_.State)]" }) -join ', '
    if ([string]::IsNullOrWhiteSpace($knownDevices)) {
      Fail 'No Android USB devices found. Connect a device with USB debugging enabled.'
    }

    Fail "No ready Android USB devices found. Connected devices: $knownDevices. Unlock and authorize the target device."
  }

  if ($readyDevices.Count -gt 1) {
    $choices = ($readyDevices | ForEach-Object { $_.Id }) -join ', '
    Fail "Multiple ready Android devices found: $choices. Re-run with -DeviceId <id>."
  }

  return $readyDevices[0].Id
}

Test-BackendHealth -Port $BackendPort

if (Test-Path -LiteralPath (Join-Path $repoRoot 'pubspec.yaml') -PathType Leaf) {
  Set-Location -LiteralPath $repoRoot
}

$adbPath = Resolve-AdbPath
if (-not $adbPath) {
  Fail 'adb was not found. Set ANDROID_HOME or ANDROID_SDK_ROOT, install Android SDK platform-tools, or add adb to PATH.'
}

Write-Host "Using adb: $adbPath"

$devices = Get-AdbDevices -AdbPath $adbPath
$selectedDevice = Select-AndroidDevice -Devices $devices -RequestedDeviceId $DeviceId

Write-Host "Using Android device: $selectedDevice"

& $adbPath -s $selectedDevice reverse "tcp:$BackendPort" "tcp:$BackendPort"
if ($LASTEXITCODE -ne 0) {
  Fail "adb reverse failed for device '$selectedDevice' on tcp:$BackendPort."
}

Write-Host "adb reverse OK: device tcp:$BackendPort -> host tcp:$BackendPort"

$apiBaseUrl = "http://127.0.0.1:$BackendPort/api/v1"
$flutterRunArgs = @(
  'run',
  '-d',
  $selectedDevice,
  "--dart-define=API_BASE_URL=$apiBaseUrl"
)
$flutterRunArgs += $FlutterArgs

Write-Host "Running: flutter $($flutterRunArgs -join ' ')"
& flutter @flutterRunArgs
exit $LASTEXITCODE
