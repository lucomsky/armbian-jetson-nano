# Armbian for NVIDIA Jetson Nano (P3449-0000-B01)

An Armbian image for the Jetson Nano Developer Kit B01 (4 GB). It uses the mainline kernel with open-source
graphics, so there's no NVIDIA L4T and no CUDA.

| Item       | Choice                                                    |
|------------|-----------------------------------------------------------|
| Base       | Ubuntu 26.04 LTS `resolute`                               |
| Desktop    | XFCE (`DESKTOP_TIER=mid`)                                 |
| Kernel     | Armbian `uefi-arm64` `current` (mainline 6.18 LTS)        |
| Boot       | QSPI U-Boot (L4T) -> EFI -> GRUB -> kernel + `tegra210-p3450-0000.dtb` |
| Graphics   | `tegra-drm` (HDMI/DP) + `nouveau` (GM20B GPU), Mesa       |
| Network    | onboard RTL8111 GbE (`r8169`, PCIe); USB Wi-Fi dongles via the full firmware package |
| USB        | 4x USB 3.0 (`xhci-tegra`, needs `nvidia/tegra210/xusb.bin` firmware, included) |

## Layout

- `armbian-build/`: [armbian/build](https://github.com/armbian/build) as a git submodule, pinned to a tested commit
- `userpatches/config-jetson-nano-xfce.conf`: the build configuration
- `build.sh`: syncs `userpatches/` into the framework and runs the build
- `docs/qspi-firmware.md`: **read this first**. How to check and update the board's boot firmware.

## Build

Requirements: x86_64 or arm64 Linux, Docker (the framework runs the build in a container), about 60 GB free disk.
On an x86_64 host, the arm64 QEMU binfmt handler must be registered **on the host** (the container can't do it):

```sh
sudo apt-get install -y qemu-user-static binfmt-support
ls /proc/sys/fs/binfmt_misc/ | grep qemu-aarch64   # must print qemu-aarch64
```

```sh
git clone --recurse-submodules <this repo>
./build.sh
```

Output: `armbian-build/output/images/Armbian-*_Jetson-nano_resolute_current_*_xfce_desktop.img(.xz)`.

Extra framework options can be passed through, e.g. `./build.sh jetson-nano-xfce KERNEL_CONFIGURE=yes`.

## Flash and boot

1. Make sure the QSPI firmware is L4T 32.5+ ([docs/qspi-firmware.md](docs/qspi-firmware.md)).
2. Write the image: `xzcat Armbian-*.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress`
   (or balenaEtcher).
3. Insert the SD card, connect HDMI, Ethernet and a keyboard. Use a 5 V / 4 A barrel jack (J25) with the J48 jumper
   fitted for a desktop workload, because micro-USB power is marginal.
4. Armbian's first-boot wizard asks for a root password and a user, then XFCE starts.

## Updating the Armbian framework

```sh
git -C armbian-build fetch && git -C armbian-build checkout <new-commit>
git add armbian-build && git commit -m "Bump armbian/build"
```

## Notes

- In upstream Armbian, Jetson Nano is an **EOS** (end-of-support) board, so it gets no official images or
  support. Its board file still exists and builds.
