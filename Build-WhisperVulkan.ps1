<#
  Build whisper.cpp with Vulkan GPU support on this Windows PC (same result as the GitHub workflow).

  Needs (one-off):
    winget install -e --id Git.Git
    winget install -e --id Kitware.CMake
    winget install -e --id Microsoft.VisualStudio.2022.BuildTools --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    winget install -e --id KhronosGroup.VulkanSDK
  Then open a NEW PowerShell window and run:
    powershell -ExecutionPolicy Bypass -File .\Build-WhisperVulkan.ps1
#>
param(
  [string]$Tag = "v1.9.5",
  [string]$WorkDir = "$PSScriptRoot\build-work"
)
$ErrorActionPreference = "Stop"

function Need($cmd, $hint) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "$cmd not found. $hint" }
}
Need git   "Install Git: winget install -e --id Git.Git"
Need cmake "Install CMake: winget install -e --id Kitware.CMake"
if (-not $env:VULKAN_SDK -or -not (Test-Path "$env:VULKAN_SDK\Bin\glslc.exe")) {
  throw "Vulkan SDK not found (VULKAN_SDK not set or glslc.exe missing). Install it: winget install -e --id KhronosGroup.VulkanSDK, then open a new PowerShell window."
}

New-Item -ItemType Directory -Force $WorkDir | Out-Null
$src = Join-Path $WorkDir "whisper.cpp"
if (-not (Test-Path "$src\.git")) {
  git clone --depth 1 --branch $Tag https://github.com/ggml-org/whisper.cpp $src
} else {
  git -C $src fetch --depth 1 origin tag $Tag
  git -C $src checkout --force $Tag
}

cmake -S $src -B "$src\build" -A x64 `
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON `
  -DGGML_VULKAN=ON -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON `
  -DWHISPER_BUILD_IS_DEV=OFF -DWHISPER_BUILD_TESTS=OFF -DWHISPER_SDL2=OFF
if ($LASTEXITCODE) { throw "CMake configure failed (is the Visual Studio C++ Build Tools workload installed?)" }

cmake --build "$src\build" --config Release -j $env:NUMBER_OF_PROCESSORS
if ($LASTEXITCODE) { throw "Build failed" }

$bin = "$src\build\bin\Release"
$pkg = Join-Path $PSScriptRoot "whisper-vulkan-win-x64-$Tag"
Remove-Item $pkg -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory $pkg | Out-Null
Copy-Item "$bin\whisper-cli.exe", "$bin\whisper-server.exe", "$bin\whisper-bench.exe" $pkg -ErrorAction SilentlyContinue
Copy-Item "$bin\*.dll" $pkg
Copy-Item "$src\LICENSE" "$pkg\LICENSE-whisper.cpp.txt"
"whisper.cpp $Tag ($(git -C $src rev-parse HEAD)) - Vulkan + CPU backends - built locally $(Get-Date -Format 'yyyy-MM-dd')" |
  Set-Content "$pkg\BUILD-INFO.txt"

Compress-Archive -Path "$pkg\*" -DestinationPath "$pkg.zip" -Force
Write-Host "`nDone: $pkg.zip"
Write-Host "Check the GPU is picked up:  & '$pkg\whisper-cli.exe' -m <model.bin> -f <audio.wav>"
Write-Host "  and look for a 'ggml_vulkan: Found N Vulkan devices' line naming your graphics card."
