# ST-Link V2 → DAPLink（macOS）

把廉价独立 **ST-Link V2** 克隆（USB `0483:3748`）刷成开源 **CMSIS-DAP**（`DAP103`，USB `1209:da42`），方便给 APM32、GD32、nRF52 等 ST-Link 不认的 Cortex-M 芯片下载。

固件基于 [devanlai/dap42](https://github.com/devanlai/dap42)，刷写工具基于 [GabyPCgeeK/stlink-tool](https://github.com/GabyPCgeeK/stlink-tool)。ST 的 bootloader 会保留，之后还能刷回 ST-Link。

## 你需要

- macOS（已在 Apple Silicon 上试过）
- 独立 ST-Link V2 克隆，VID/PID 为 `0483:3748`
- 芯片 Flash 最好是 **128KB**（本仓库固件约 14KB，链在 `0x08004000`）
- [libusb](https://libusb.info/)、[pyOCD](https://pyocd.io/)：`brew install libusb && pip3 install pyocd`

## 怎么看现在是哪种模式

| 模式 | USB 名称 | ID |
|------|----------|-----|
| ST bootloader | `STM32 STLink` | `0483:3748` |
| DAPLink | `DAP103 CMSIS-DAP` | `1209:da42` |

```bash
system_profiler SPUSBDataType | rg -i 'STLink|DAP103|CMSIS'
pyocd list
```

## 刷 DAPLink

1. 插上仿真器。若 `pyocd` 报 USB 超时，拔掉再插，等 2 秒。
2. 确认是 bootloader：

   ```bash
   ./stlink-tool/stlink-tool -p
   ```

   应看到 `STLinkV2 Bootloader Found`、`Current Mode: 1`。
3. 刷预编译固件：

   ```bash
   ./stlink-tool/stlink-tool firmware/DAP103-HID-STBOOT.bin
   ```

写到中途 USB 卡死很常见，拔掉换口再插，再执行同一条命令即可。不要同时开 `pyocd list`。

## 启动 DAPLink

克隆每次上电常停在 ST bootloader。固件已经在里面时，跑：

```bash
./start-daplink.sh
```

成功后 `pyocd list` 会显示 `Devanarchy DAP103 CMSIS-DAP`。

## 给目标芯片下载

```bash
# 先看本机 pyocd 认哪些型号
pyocd list --targets

# 例：STM32 / 极海 APM32（有 pack 时选对应型号）
pyocd flash -t stm32f103rc your.hex
```

没有内置型号就 `pyocd pack install` 对应厂家包，或在 Keil 里选 CMSIS-DAP。

接线：`SWDIO`、`SWCLK`、`GND`、`3.3V`。这套固件的 **RESET 在 PB6**（很多克隆排针上的 RST），能接上更好。

## 重新编译固件（可选）

需要带 newlib 的 `arm-none-eabi-gcc`（Homebrew 的 `arm-none-eabi-gcc` 往往缺头文件，可用 [xpack](https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack)）。

```bash
git clone --recurse-submodules https://github.com/devanlai/dap42.git
# 打上 patches/ 里的改动后：
make TARGET=STM32F103-HID-STBOOT -C dap42
```

改动要点：固件链到 `0x08004000`，启动时清 ST bootloader 留下的中断并设置 `VTOR`。

## 许可与致谢

- 预编译固件来自 dap42，许可见 [devanlai/dap42](https://github.com/devanlai/dap42)
- `stlink-tool` 为 MIT，见其目录内 README
- 本仓库脚本按 MIT 使用
