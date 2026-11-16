# 在 VibeBuddy 盒子上同时装 Muse

用这里的脚本，可以把 Meta 的 [Muse Gadget](https://github.com/facebookincubator/muse-gadget-sdk) 固件装到 VibeBuddy 盒子上，和 VibeBuddy 共存。两个都留在盒子里，开机时用 K2 键选择启动哪一个。

**不提供支持。** VibeBuddy 和 Meta 都不支持这种用法。这些脚本里不包含 Muse：Muse 要你自己用 Meta 的 SDK 构建、自己刷入，并使用你自己的 SDK token。token 仅限个人使用：不要分享，也不要放进你出售的盒子。开始前请先阅读 Meta 的 [Gadget SDK Terms](https://gadgets.muse.ai/sdk-terms)。

## 需要准备

- VibeBuddy 盒子：ALIENTEK ATK-DNESP32S3-BOX V1.1。
- [ESP-IDF v6.0.3](https://docs.espressif.com/projects/esp-idf/en/v6.0.3/esp32s3/get-started/)，装在 `~/esp/esp-idf-v6.0.3`（或者设置 `IDF_PATH`）。
- VibeBuddy 固件包，0.6.2 或更高版本：从[固件发布页](https://github.com/second-state/vibebuddy/releases)下载 `VibeBuddy-firmware-v….zip`。它的 bootloader 能启动 Muse，分区表也给 Muse 留了空间。
- SDK token：在 gadgets.muse.ai 的 Account > SDK tokens 里申请。
- 手机上的 Muse App。

## 构建 Muse

```sh
git clone https://github.com/facebookincubator/muse-gadget-sdk
./build.sh muse-gadget-sdk
```

Muse 的源码不做任何修改。`sdkconfig.vibebuddy` 只改 Muse 在 flash 里的位置，并关掉它的自动更新。构建出来的固件里不含 token。

## 刷入 Muse

1. 退出 VibeBuddy App，它会占用盒子的串口。
2. 用标着 USB-SLAVE 的 USB-C 口连接盒子。
3. 刷入：

   ```sh
   ./flash.sh VibeBuddy-firmware-v0.6.2.zip /dev/cu.usbmodem101
   ```

4. 写入 token。请在你自己的终端里运行，token 只留在你的电脑上：

   ```sh
   ./send-token.py /dev/cu.usbmodem101 mgst_…
   ```

盒子会启动进入 Muse。VibeBuddy 本身、它的角色、设置和配对都会保留在盒子里。

## 配对 Muse

1. 在 Muse App 里打开 Settings > Devices > Developer mode。
2. 添加设备：Settings > Devices > Add Device，设备名显示为 `MuseGadget-XXXXXX`。
3. App 让你确认时，按一下 K0。
4. 选择你的 Wi-Fi。

按住 K0 跟 Muse 说话，K1 打开 Muse 的菜单。想重新配对，按住 K0 五秒。

## 在 VibeBuddy 和 Muse 之间切换

1. 按住 K2 不放。
2. 按一下 RESET 再松开。
3. K2 再按住 2 秒。

切换后会一直保持这个选择，Muse 关机再唤醒也不会变。复位时不要按住 K0：K0 是 BOOT 键，按住会让芯片进入下载模式。

## 更新

- **VibeBuddy：** 照常在 VibeBuddy App 里更新，Muse 不受影响。
- **Muse：** 不能在盒子上自己更新，要重新构建、重新刷入。配对和 Wi-Fi 会保留。Muse 连上服务时会打出 `esp_ota_mark_app_valid_cancel_rollback failed`，不影响使用。

## 移除 Muse

在 VibeBuddy App 里重新安装 VibeBuddy，盒子就会启动 VibeBuddy。Muse 的固件还留在盒子里，所以复位时按住 K2 仍然能进入 Muse。要彻底移除，擦掉它的分区：

```sh
python -m esptool --chip esp32s3 -p /dev/cu.usbmodem101 erase-region 0xc30000 0x3d0000
```

## 工作原理

| 分区 | 起始地址 | 大小 | 用途 |
|---|---|---|---|
| `muse_tbl` | 0xc14000 | 4 KB | Muse 自己的分区表（`partitions.csv`） |
| `muse_nvs` | 0xc15000 | 48 KB | Muse 的设置：Wi-Fi、token、配对 |
| `boot_sel` | 0xc21000 | 4 KB | 记录启动哪一个 |
| `muse` | 0xc30000 | 3.8 MB | Muse 固件 |

Muse 的分区表里只有它自己的设置和固件，所以 Muse 改不到 VibeBuddy 的数据。bootloader 每次启动时读 `boot_sel`，复位时如果 K2 是按住的，就切换到另一个。只有盒子里装了 Muse，bootloader 才会去读 K2。如果 Muse 固件损坏，盒子会改为启动 VibeBuddy。
