# ChooChooTracker on H700 Hardware

Unofficial Docker build recipe that packages
[ChooChooTracker](https://github.com/paiheulevrai/Choochootracker) as a
PortMaster port for Allwinner H700 devices (tested target: Anbernic RG35XX Pro
running KNULLI). It contains no upstream source; the Dockerfile clones a pinned
upstream commit at build time. ChooChooTracker is by its upstream author and
keeps its own license.

**Status / caveats**

- **PortMaster must be installed** on the device first. A launch crash during
  testing was caused by PortMaster being missing, not by the app.
- The small audio profile below is a precaution: it is **not proven** to be
  required. An earlier build coincided with system audio going silent on one
  device; the cause was never established, so treat this as experimental,
  test on a backed-up card, and keep Audio Output on **Default**.
- Not affiliated with or endorsed by the upstream project.

## About the build

This Docker build cross-compiles the main ChooChooTracker editor for ARM64
(AArch64), then creates the project's existing PortMaster package. The RG35XX
Pro uses an Allwinner H700 Cortex-A53, and KNULLI's H700 build targets AArch64.
It applies a small KNULLI H700 audio profile: the output-device picker is
disabled, any previously saved device choice is cleared for this run, and SDL
uses the system-default audio path. This avoids explicitly opening a named SDL
device such as `ACodec`; it does not change ALSA mixer controls.

## Build on Windows

Run these commands from this folder in PowerShell with Docker Desktop and
Buildx available:

```powershell
docker buildx build --platform linux/amd64 --no-cache --output "type=local,dest=dist-h700" .
```

The package will be created at `dist-h700\choochootracker.zip`. To build a different
branch, tag, or commit of the upstream project, add
`--build-arg CHOOCHOO_REF=<branch-tag-or-commit>`.

The container uses an upstream commit pinned by default in the Dockerfile,
Ubuntu 22.04's ARM64 SDL2 and ALSA development packages fetched from Ubuntu's
ARM64 Ports mirror, and the upstream `Makefile.portmaster`. The H700 audio
changes are applied directly to the checked-out SDL backend, and the build
verifies the expected edits before compiling. If you change `CHOOCHOO_REF`, the
source must still contain the expected SDL backend lines. This builds the main
editor, not the separate `choochooplayer` visualizer.

## Install on KNULLI

Copy `choochootracker.zip` to the KNULLI SD card's PortMaster autoinstall folder:

```text
/userdata/system/.local/share/PortMaster/autoinstall/
```

Open PortMaster on the device to install the package, then launch ChooChooTracker
from Ports. This installs a PortMaster port and does not replace or modify the
KNULLI firmware.

This profile removes the named-device open path implicated by the `ACodec`
failure, but cannot guarantee audio will work on the device without a hardware
test. Install and test only with KNULLI's **Default** output selected. The
package does not modify or replace KNULLI firmware.
