$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Split-Path -Parent $scriptDir
$repoRoot = Resolve-Path (Join-Path $appDir "../../../..")
$protoRoot = Join-Path $repoRoot "libs/proto"
$outDir = Join-Path $repoRoot "libs/flutter-libs/fusion_lib/lib/generated/proto"

if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# Resolve protobuf include path:
# 1) PROTOBUF_INCLUDE env var
# 2) protoc\..\include
$protobufInclude = $env:PROTOBUF_INCLUDE
if ([string]::IsNullOrWhiteSpace($protobufInclude)) {
  $protocCmd = Get-Command protoc -ErrorAction SilentlyContinue
  if (-not $protocCmd) {
    throw "protoc not found in PATH. Install protobuf or set PROTOBUF_INCLUDE."
  }

  $protocPath = $protocCmd.Source
  $protocDir = Split-Path -Parent $protocPath
  $protobufInclude = Join-Path (Split-Path -Parent $protocDir) "include"
}

$structProto = Join-Path $protobufInclude "google/protobuf/struct.proto"
$timestampProto = Join-Path $protobufInclude "google/protobuf/timestamp.proto"
if (-not (Test-Path $structProto) -or -not (Test-Path $timestampProto)) {
  throw "Could not find google protobuf well-known types under: $protobufInclude"
}

# Create a temporary protoc plugin wrapper for Windows
$tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("fusion-protoc-plugin-" + [guid]::NewGuid())) -Force
$pluginBat = Join-Path $tempDir.FullName "protoc-gen-dart.bat"
@"
@echo off
cd /d "$appDir"
dart run protoc_plugin:protoc_plugin %*
"@ | Set-Content -Path $pluginBat -Encoding ASCII

$protoFiles = @(
  $structProto
  $timestampProto
  (Join-Path $protoRoot "fusion/controllers.proto")
  (Join-Path $protoRoot "fusion/device_config.proto")
  (Join-Path $protoRoot "fusion/device_config_audio.proto")
  (Join-Path $protoRoot "fusion/device_config_dro.proto")
  (Join-Path $protoRoot "fusion/device_config_static.proto")
  (Join-Path $protoRoot "fusion/devices.proto")
  (Join-Path $protoRoot "fusion/health.proto")
  (Join-Path $protoRoot "fusion/metadata.proto")
  (Join-Path $protoRoot "fusion/pava.proto")
  (Join-Path $protoRoot "fusion/sessions.proto")
  (Join-Path $protoRoot "fusion/software_update.proto")
  (Join-Path $protoRoot "fusion/tasks.proto")
  (Join-Path $protoRoot "fusion/time_machine.proto")
  (Join-Path $protoRoot "fusion/udp.proto")
  (Join-Path $protoRoot "fusion/version.proto")
  (Join-Path $protoRoot "fusion/vip.proto")
  (Join-Path $protoRoot "fusion/websocket.proto")
)

$args = @(
  "-I", $protoRoot
  "-I", $protobufInclude
  "--plugin=protoc-gen-dart=$pluginBat"
  "--dart_out=$outDir"
) + $protoFiles

& protoc @args
if ($LASTEXITCODE -ne 0) {
  throw "protoc failed with exit code $LASTEXITCODE"
}

Write-Host "Generated protobuf Dart files in $outDir"