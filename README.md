# koalacut-whisper-vulkan

**Unofficial Windows builds of [whisper.cpp](https://github.com/ggml-org/whisper.cpp) with Vulkan GPU support** — speech-to-text on AMD Radeon, Intel and NVIDIA graphics, with no CUDA, ROCm or HIP SDK to install.

Made for [KoalaCut](#about-koalacut), shared so anyone can use them.

> [!NOTE]
> This is **not** an official whisper.cpp release and isn't affiliated with or endorsed by the whisper.cpp / ggml authors. Each build is compiled by GitHub Actions, unmodified, from the official source at a pinned release tag — the [workflow](.github/workflows/build-whisper-vulkan.yml) is the whole recipe.

## Why this exists

As of whisper.cpp v1.9.5, the official Windows downloads are CPU, BLAS and CUDA (NVIDIA) builds — there's no Vulkan build. Vulkan comes with every normal AMD, Intel and NVIDIA graphics driver, so one Vulkan build gives GPU transcription on almost any Windows PC, and falls back to the CPU on the rest.

## Download

Get the latest zip from **[Releases](../../releases)**:

| File | What it is |
|---|---|
| `whisper-vulkan-win-x64-<version>.zip` | The programs and libraries — unzip anywhere |
| `whisper-vulkan-win-x64-<version>.zip.sha256` | Checksum for verifying the download |

Releases are tagged `whisper-vulkan-<whisper.cpp version>`, e.g. `whisper-vulkan-v1.9.5`. Published releases are never replaced, so a link to a specific version keeps working and always gives the same file.

### Requirements

- Windows 10 or 11, 64-bit (x64)
- For GPU speed: a graphics driver with Vulkan support — in practice AMD Radeon RX 400 series or newer (including Ryzen built-in graphics), Intel Iris Xe / Arc, or NVIDIA GTX 900 series or newer, with an up-to-date driver
- No GPU, or an old one? It still works — on the CPU

Nothing else to install: the Microsoft Visual C++ runtime is included in the zip.

## What's in the zip

| File | Purpose |
|---|---|
| `whisper-cli.exe` | Command-line transcriber |
| `whisper-server.exe` | HTTP server that keeps a model loaded between requests |
| `whisper-bench.exe` | Benchmark |
| `whisper.dll`, `ggml.dll`, `ggml-base.dll` | Core libraries |
| `ggml-vulkan.dll` | GPU backend (Vulkan) |
| `ggml-cpu-*.dll` | CPU backends — the best one for the PC's processor is picked automatically |
| `vcruntime140*.dll`, `msvcp140*.dll`, … | Microsoft Visual C++ runtime |
| `BUILD-INFO.txt` | whisper.cpp version, source commit, build run |
| `LICENSE-whisper.cpp.txt` | whisper.cpp's MIT licence |

Keep all the files together in one folder — the GPU and CPU backends are loaded from next to the `.exe`.

## Quick start

1. Download a model (ggml `.bin` format) from [ggerganov/whisper.cpp on Hugging Face](https://huggingface.co/ggerganov/whisper.cpp) — e.g. `ggml-small.bin` or `ggml-large-v3-turbo.bin`.
2. Convert your audio to 16 kHz mono WAV:
   ```
   ffmpeg -i input.mp4 -ar 16000 -ac 1 -c:a pcm_s16le audio.wav
   ```
3. Transcribe:
   ```
   whisper-cli.exe -m ggml-small.bin -f audio.wav -l auto -osrt
   ```

Useful options:

| Option | Does |
|---|---|
| `-l en` / `-l auto` | Language, or detect it |
| `-osrt`, `-ovtt`, `-otxt` | Subtitle / text output |
| `-ojf -of <name>` | Full JSON: segments, per-token timings and confidence |
| `-ng` | Force CPU (no GPU) |
| `-dev N` | Use GPU number N on PCs with more than one |
| `--vad -vm <vad-model.bin>` | Skip silence with the Silero voice-activity model ([download](https://huggingface.co/ggml-org/whisper-vad)) |
| `-pp` | Print progress |

Run `whisper-cli.exe --help` for everything.

### Is it using my GPU?

Near the start of the output, look for a line like:

```
whisper_backend_init_gpu: using Vulkan0 backend
```

If it says `no GPU found`, update your graphics driver (AMD: *AMD Software: Adrenalin Edition* → Check for updates) and try again. It will still transcribe — on the CPU.

Rough graphics memory needed: `small` ~0.9 GB, `medium` / `large-v3-turbo` ~2 GB, `large-v3` ~4 GB. Built-in graphics share system memory, so `small` or `large-v3-turbo` suit them best.

## Verify a download

**Checksum** — in PowerShell, compare with the `.sha256` file:

```powershell
(Get-FileHash .\whisper-vulkan-win-x64-v1.9.5.zip -Algorithm SHA256).Hash.ToLower()
```

**Build provenance** — every release zip is attested by GitHub, proving it was built by this repository's workflow (not uploaded by hand). With the [GitHub CLI](https://cli.github.com/):

```
gh attestation verify whisper-vulkan-win-x64-v1.9.5.zip --repo <owner>/koalacut-whisper-vulkan
```

The programs aren't code-signed, so Windows SmartScreen or antivirus may ask before the first run. The two checks above are how to confirm the file is genuine.

## Build it yourself

**On GitHub (no tools needed):** fork this repo → **Actions** → **Build whisper.cpp (Vulkan, Windows)** → **Run workflow**. Enter the whisper.cpp tag (e.g. `v1.9.5`); tick **publish** to create a release in your fork. Takes about 20–30 minutes.

**On your own PC:** see [`Build-WhisperVulkan.ps1`](Build-WhisperVulkan.ps1) — install the four tools listed at the top (Git, CMake, Visual Studio Build Tools with C++, Vulkan SDK), then:

```powershell
powershell -ExecutionPolicy Bypass -File .\Build-WhisperVulkan.ps1 -Tag v1.9.5
```

Build settings used: `GGML_VULKAN=ON`, `GGML_BACKEND_DL=ON`, `GGML_CPU_ALL_VARIANTS=ON`, `GGML_NATIVE=OFF`, `BUILD_SHARED_LIBS=ON`, Release, x64.

## Maintaining this repo

- **New whisper.cpp version:** a monthly check (*Check for whisper.cpp updates*) shows a notice on the Actions page when one is out. Run the build workflow with the new tag and **publish** ticked, test the zip with KoalaCut, then point KoalaCut at the new release link.
- **Never replace a published release** — KoalaCut and others link to specific versions. Publish a new tag instead.
- **Vulkan SDK version:** if the SDK download fails, the version may have been retired — use the current one from [vulkan.lunarg.com/sdk/home](https://vulkan.lunarg.com/sdk/home) (*Windows*) in the `vulkan_sdk` box.
- **Scheduled checks pause** after 60 days with no activity in a public repo. Re-enable from the Actions tab if needed.

## Support

These builds are provided **as-is**, without support, and Issues are turned off. Problems with whisper.cpp itself belong in the [whisper.cpp repository](https://github.com/ggml-org/whisper.cpp/issues). KoalaCut users: report problems through KoalaCut.

## About KoalaCut

KoalaCut is a local-first app for finding and cutting the best clips from podcasts and long videos. It uses these builds for GPU transcription on AMD, Intel and NVIDIA graphics.

## Licence

- The build scripts and docs in this repo: [MIT](LICENSE) © 2026 Khalm Down Hobbies.
- whisper.cpp and ggml: MIT © The ggml authors — included in every zip as `LICENSE-whisper.cpp.txt`.
- The Microsoft Visual C++ runtime files are redistributed under Microsoft's Visual Studio redistribution terms.
