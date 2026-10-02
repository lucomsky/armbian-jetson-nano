# Jetson Nano B01: QSPI boot firmware

This Armbian image doesn't contain a bootloader for the board. Boot works like this:

```
BootROM -> NVIDIA boot chain (nvtboot/cboot) -> U-Boot   [all in module QSPI flash]
        -> U-Boot distro boot finds EFI/BOOT/BOOTAA64.EFI on the SD card
        -> GRUB (Armbian) -> mainline kernel + tegra210-p3450-0000.dtb
```

The module's QSPI must have the **L4T 32.5 or newer** boot chain (JetPack 4.5+; the last one is
JetPack 4.6.x / L4T 32.7.x). From 32.5 on, U-Boot lives in QSPI and has EFI support. With older firmware,
U-Boot was read from the SD card, so the Armbian SD card can't boot.

## How to check

### A. No SD card, HDMI monitor + USB keyboard (no extra hardware)

1. Remove the SD card and power the board on.
2. **New firmware (32.5+):** the NVIDIA logo appears, and U-Boot then starts and prints
   `Hit any key to stop autoboot` (on HDMI, and always on the serial console). Press a key, then type:
   ```
   version
   ```
   `U-Boot 2020.04-...` means the QSPI firmware is new enough. Type `help bootefi` to confirm EFI support.
3. **Old firmware (< 32.5):** with no SD card nothing useful happens (black screen, or the logo and then a
   hang). U-Boot isn't in QSPI.

### B. Serial console (most reliable)

Use a 3.3 V USB-UART adapter on the **J50** header (the button header under the module):

| J50 pin | Signal       | Adapter |
|---------|--------------|---------|
| 3       | UART2 RXD    | TX      |
| 4       | UART2 TXD    | RX      |
| 7       | GND          | GND     |

`picocom -b 115200 /dev/ttyUSB0`, then power on. The log shows the cboot and U-Boot versions. Check pin
numbers against the carrier silkscreen. Never connect the adapter's VCC pin.

This is also the console Armbian uses (`console=ttyS0,115200n8`), so it's very useful for first-boot debugging.

### C. A working JetPack SD card is already in use (SSH / CLI)

The most direct check reads the U-Boot version string straight from the QSPI flash:
```
cat /proc/mtd                       # mtd0: 00400000 00001000 "spi32766.0"  (4 MiB QSPI)
sudo strings /dev/mtd0 | grep -m3 -E 'U-Boot 20[0-9]{2}\.[0-9]{2}'
```
`U-Boot 2020.04-...` means U-Boot is in QSPI (L4T 32.5+) and the board is good to go. No match means it's too old.

Our board (checked 2026-10-02): `U-Boot 2020.04-g46e4604c78 (Jul 26 2021 - 12:09:42 -0700)`, i.e. JetPack 4.6 / L4T 32.6.x. OK.

Other checks:
```
cat /etc/nv_tegra_release           # e.g. "# R32 (release), REVISION: 7.x"
dpkg -l nvidia-l4t-bootloader       # this package writes QSPI on boot
```
If R32 REVISION ≥ 5 has been booted on this board, its QSPI was updated automatically.

## How to update (if old or unknown)

**Easiest: boot the official SD image once.**
1. Download the *Jetson Nano Developer Kit SD Card Image*, JetPack **4.6.1** (`jetson-nano-jp461-sd-card-image.zip`),
   from NVIDIA's JetPack archive.
2. Write it to an SD card (balenaEtcher or `dd`), boot, and finish the OEM setup.
   On first boot `nv-l4t-bootloader-config` writes the new boot chain to QSPI. Reboot once more.
3. Check with method A, then put in the Armbian SD card.

**Alternative: flash only QSPI from an x86 host** (L4T 32.7.x BSP, board in recovery mode:
short FC REC to GND on J50, power on, `lsusb` shows `0955:7f21`):
```
sudo ./flash.sh jetson-nano-qspi-sd mmcblk0p1
```

After this, you don't need to touch QSPI again. Armbian updates only change the SD card.
