# Muse next to Vibe Buddy

With these scripts you can put Meta's [Muse Gadget](https://github.com/facebookincubator/muse-gadget-sdk) firmware on a Vibe Buddy box next to Vibe Buddy. Both stay on the box. The K2 key at reset chooses which one starts.

**Not supported.** Neither Vibe Buddy nor Meta supports this. These scripts do not contain Muse: you build it from Meta's SDK yourself, flash it yourself and give it your own SDK token. The token is for your own, personal use: do not share it, and do not put it in a box that you sell. Read Meta's [Gadget SDK Terms](https://gadgets.muse.ai/sdk-terms) first.

## What you need

- A Vibe Buddy box: ALIENTEK ATK-DNESP32S3-BOX V1.1.
- [ESP-IDF v6.0.3](https://docs.espressif.com/projects/esp-idf/en/v6.0.3/esp32s3/get-started/), installed at `~/esp/esp-idf-v6.0.3` (or set `IDF_PATH`).
- The Vibe Buddy firmware package, version 0.6.2 or later: `VibeBuddy-firmware-v….zip` from the [firmware releases](https://github.com/second-state/vibebuddy/releases). Its bootloader can start Muse, and its partition table has room for it.
- An SDK token from gadgets.muse.ai > Account > SDK tokens.
- The Muse app on your phone.

## Build Muse

```sh
git clone https://github.com/facebookincubator/muse-gadget-sdk
./build.sh muse-gadget-sdk
```

The Muse source is not changed. `sdkconfig.vibebuddy` only moves Muse in flash and turns off its updates. The build has no token.

## Flash Muse

1. Quit the Vibe Buddy app. It holds the box's port.
2. Connect the box with the USB-C port marked USB-SLAVE.
3. Flash:

   ```sh
   ./flash.sh VibeBuddy-firmware-v0.6.2.zip /dev/cu.usbmodem101
   ```

4. Send your token. Run this in your own terminal, so that the token stays on your computer:

   ```sh
   ./send-token.py /dev/cu.usbmodem101 mgst_…
   ```

The box starts Muse. Vibe Buddy, its Character, its settings and its pairings stay on the box.

## Pair Muse

1. In the Muse app, turn on Settings > Devices > Developer mode.
2. Add the device: Settings > Devices > Add Device. It shows as `MuseGadget-XXXXXX`.
3. When the app asks you to confirm, press K0 once.
4. Choose your Wi-Fi.

Hold K0 to talk to Muse. K1 opens Muse's menu. To start Muse's setup again, hold K0 for 5 seconds.

## Switch between Vibe Buddy and Muse

1. Push K2 down and hold it.
2. Press and release RESET.
3. Keep K2 down for 2 more seconds.

The box keeps the choice until you switch again, also after Muse powers off and wakes. Do not hold K0 at reset: K0 is BOOT, and the chip goes into its download mode.

## Update

- **Vibe Buddy:** update it from the Vibe Buddy app as usual. Muse stays.
- **Muse:** it can't update itself on the box. Build it again and flash it again. Your pairing and Wi-Fi stay. Muse logs `esp_ota_mark_app_valid_cancel_rollback failed` when it connects; this does no harm.

## Remove Muse

Install Vibe Buddy again from the Vibe Buddy app; the box then starts Vibe Buddy. The Muse image stays, so K2 at reset still starts it. To remove it, erase its partition:

```sh
python -m esptool --chip esp32s3 -p /dev/cu.usbmodem101 erase-region 0xc30000 0x3d0000
```

## How it works

| Partition | Offset | Size | For |
|---|---|---|---|
| `muse_tbl` | 0xc14000 | 4 KB | Muse's own partition table (`partitions.csv`) |
| `muse_nvs` | 0xc15000 | 48 KB | Muse's settings: Wi-Fi, token, pairing |
| `boot_sel` | 0xc21000 | 4 KB | Which app starts |
| `muse` | 0xc30000 | 3.8 MB | Muse |

Muse's own partition table shows Muse only its settings and its app, so Muse can't change Vibe Buddy's data. The bootloader reads `boot_sel` at each start and changes it when K2 is held at reset. It reads K2 only when the box has a Muse image. A damaged Muse image makes the box start Vibe Buddy.
