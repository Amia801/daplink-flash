# ST-Link V2 → DAPLink

**[中文教程](#zh)** · **[English guide](#en)**

把廉价独立 **ST-Link V2** 克隆刷成开源 **CMSIS-DAP**。Windows / macOS / Linux 通用。

Flash a cheap standalone **ST-Link V2** clone into open-source **CMSIS-DAP**. Works on Windows, macOS, and Linux.

固件基于 [devanlai/dap42](https://github.com/devanlai/dap42)，刷写工具基于 [GabyPCgeeK/stlink-tool](https://github.com/GabyPCgeeK/stlink-tool)。ST 原厂 bootloader **会保留**，以后还能刷回去。

Firmware is based on [devanlai/dap42](https://github.com/devanlai/dap42). The flasher is based on [GabyPCgeeK/stlink-tool](https://github.com/GabyPCgeeK/stlink-tool). The original ST bootloader **stays on the dongle**, so you can restore ST-Link later.

---

<a id="zh"></a>

# ST-Link V2 → DAPLink（中文喂饭教程）

[English](#en)

## 这是干什么的？

淘宝 / 拼多多上那种金属壳、独立的 **ST-Link V2**，插上电脑后 USB 一般是：

- 名字：`STM32 STLink`
- ID：`0483:3748`

它只能比较好地给 **STM32** 下载。遇到极海 APM32、兆易 GD32、Nordic nRF52 等芯片，ST 官方工具经常不认。

刷完本仓库的固件后，它会变成开源的 **CMSIS-DAP**（本仓库用的是 `DAP103`）：

- 名字：`DAP103 CMSIS-DAP`
- ID：`1209:da42`

之后可以用 [pyOCD](https://pyocd.io/)、Keil（选 CMSIS-DAP）、OpenOCD 等给更多 Cortex-M 芯片下载。

> **不会变砖。** 前 16KB 的 ST bootloader 还在。克隆每次插上常常先停在 bootloader，所以还能再刷、也能刷回原版 ST-Link。

## 先看你的仿真器能不能刷

**可以刷（本教程就是为它写的）：**

- 独立的金属壳 / 塑料壳 ST-Link V2 克隆
- USB 显示 `STM32 STLink`，ID 是 `0483:3748`
- 里面是 STM32F103，Flash **128KB 最好**；固件大约 14KB，链在 `0x08004000`，**64KB 的克隆通常也能刷**

**不要刷：**

- Nucleo / Discovery 开发板上**板载**的 ST-Link
- ST-Link **V2.1**（USB ID 经常是 `0483:374b`，还会弹出 U 盘）
- ST-Link **V3**、J-Link、DAPLink 正版调试器

不确定也没关系：按下面步骤装好工具后，用探测命令看输出。能看到 `STLinkV2 Bootloader Found` 就可以继续。

## 你需要准备

硬件：

1. 一台电脑：Windows 10/11、macOS 或 Linux
2. 上面说的那种独立 ST-Link V2 克隆
3. USB 线（很多克隆是一体的，插上即可）
4. 要下载程序的目标板（有 `SWDIO`、`SWCLK`、`GND`；能接 `3.3V` 和复位更好）

软件：不用事先装一堆东西。下面每一步都会告诉你复制哪条命令。

## 全程会用到的三个“模式”

刷的时候仿真器会在这几种身份之间切换。对照这个表，就不会慌：

| 你现在处于 | USB 名称 | USB ID | 说明 |
|------------|----------|--------|------|
| ST bootloader | `STM32 STLink` | `0483:3748` | 刚插上最常见。可以刷固件，也可以启动已有固件 |
| DAPLink 已启动 | `DAP103 CMSIS-DAP` | `1209:da42` | 刷成功并且已经启动，这时才能给目标芯片下载 |
| 原版 ST-Link 固件 | `STM32 STLink` | `0483:3748` | 还没刷，或已经刷回 ST 官方固件 |

## 第 1 步：把本仓库拿到电脑上

**方法 A：会用 Git（推荐）**

打开终端，复制：

```bash
git clone https://github.com/Amia801/daplink-flash.git
cd daplink-flash
```

**方法 B：不会 Git**

1. 打开 https://github.com/Amia801/daplink-flash
2. 点绿色的 **Code** → **Download ZIP**
3. 解压，记住解压后的文件夹位置

然后在这个文件夹里打开终端：

- **Windows：** 在文件夹空白处 Shift + 右键，选「在终端中打开」；或在资源管理器地址栏输入 `cmd` 再回车
- **macOS：** 打开「终端」，把文件夹拖进终端窗口，先输入 `cd `（带空格）再拖
- **Linux：** 在文件夹空白处右键 → Open in Terminal

后面所有命令都默认你已经 `cd` 进了 `daplink-flash` 这个目录。

## 第 2 步：安装编译器和 Python

只看你自己的系统，另外两段跳过。

### Windows

1. 安装 [Python 3](https://www.python.org/downloads/)。安装时**务必勾选** `Add python.exe to PATH`。
2. 打开「命令提示符」或 PowerShell，安装 pyOCD：

```bat
py -m pip install -U pyocd
```

3. 安装 [MSYS2](https://www.msys2.org/)。装完后从开始菜单打开 **MSYS2 MinGW 64-bit**（名字里一定要有 MinGW，不要用纯 MSYS 那个）。
4. 在 MinGW 64-bit 窗口里安装编译器：

```bash
pacman -S --needed make mingw-w64-x86_64-gcc mingw-w64-x86_64-pkgconf mingw-w64-x86_64-libusb
```

5. 用 `cd` 进到本仓库，例如：

```bash
cd /c/Users/你的用户名/Downloads/daplink-flash
```

Windows 路径 `C:\Users\...` 在 MSYS2 里要写成 `/c/Users/...`。

### macOS

如果还没有 Homebrew，先装：https://brew.sh

然后：

```bash
brew install libusb pkg-config python3
python3 -m pip install -U pyocd
```

### Linux（Debian / Ubuntu / Linux Mint）

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libusb-1.0-0-dev python3 python3-pip python3-venv
python3 -m pip install -U pyocd
```

Fedora：

```bash
sudo dnf install gcc make pkgconf-pkg-config libusb1-devel python3 python3-pip
python3 -m pip install -U pyocd
```

Arch：

```bash
sudo pacman -S base-devel pkgconf libusb python python-pip
python3 -m pip install -U pyocd
```

如果 `pip` 提示权限不够，可以改用：

```bash
python3 -m pip install -U --user pyocd
```

装完后，下面这些命令都能用（哪个有就用哪个）：

```bash
pyocd --version
python3 -m pyocd --version
py -m pyocd --version
```

## 第 3 步：编译刷写工具 `stlink-tool`

仓库里**没有**现成可执行文件，每个系统都要自己编一次。在仓库根目录执行：

```bash
cd stlink-tool
make
cd ..
```

成功的话：

- macOS / Linux 会得到 `stlink-tool/stlink-tool`
- Windows（MSYS2）会得到 `stlink-tool/stlink-tool.exe`

如果提示没有 `make` 命令，改用 `mingw32-make`（同一套 MSYS2 包）。  
如果 `make` 报找不到 `pkg-config` 或 `libusb`，回到第 2 步把依赖补齐后再编。

## 第 4 步：让电脑允许访问这个 USB 设备

这一步很多人卡死。请按系统做。

### Windows：用 Zadig 换成 WinUSB

原版 ST 驱动经常不让 `stlink-tool` 访问设备。

1. 先把 ST-Link **插上电脑**
2. 下载 [Zadig](https://zadig.akeo.ie/)
3. 打开 Zadig → 菜单 **Options** → 勾选 **List All Devices**
4. 在下拉列表里找到 `STM32 STLink`（USB ID 是 `0483` `3748`）
5. 右边驱动选 **WinUSB**，点 **Replace Driver**
6. **不要**给键盘、鼠标、摄像头换驱动

换完后，设备管理器里它可能显示成 WinUSB 设备，这是正常的。

刷成 DAPLink 之后，Windows 一般会自动用 HID 驱动，不用再对 `1209:da42` 跑一遍 Zadig。

### macOS

不用装驱动，跳过。

### Linux：装 udev 规则（只要做一次）

```bash
sudo cp udev/99-stlink-daplink.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

然后**拔掉仿真器再插上**。不要用 `sudo` 跑后面的刷写命令，除非规则没生效。

## 第 5 步：插上仿真器，确认电脑认到了

插上后等 2 秒。如果 `pyocd` 报 USB 超时，拔掉换一个口再插，再等 2 秒。

**Windows（PowerShell）：**

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_0483|VID_1209' } | Format-Table Status, FriendlyName, InstanceId -AutoSize
```

**macOS：**

```bash
system_profiler SPUSBDataType | grep -i -A6 -e 'STLink' -e 'DAP103' -e 'CMSIS' -e '3748' -e 'da42'
```

**Linux：**

```bash
lsusb | grep -i -e '0483:3748' -e '1209:da42' -e 'STLink' -e 'DAP'
```

刷之前，你应该能看到 `0483:3748`。如果完全看不到设备：换线、换口、不要走劣质扩展坞。

## 第 6 步：探测 —— 确认它在 bootloader

在仓库根目录执行。

**macOS / Linux：**

```bash
./stlink-tool/stlink-tool -p
```

**Windows（MSYS2 MinGW 64-bit）：**

```bash
./stlink-tool/stlink-tool.exe -p
```

**Windows（普通 cmd，如果 exe 已经编好）：**

```bat
stlink-tool\stlink-tool.exe -p
```

成功时会出现类似：

```
STLinkV2 Bootloader Found
STLink Type: M [STM8/STM32 Debugger]
...
Reported Flash Size: 64KB   （或 128KB）
Current Mode: 1
```

关键就两句：

- 有 `STLinkV2 Bootloader Found`
- 有 `Current Mode: 1`（1 = bootloader）

如果是权限错误（Linux 的 `LIBUSB_ERROR_ACCESS`）：回到第 4 步装 udev，或临时 `sudo` 再试一次。  
如果 Windows 找不到设备：回到第 4 步用 Zadig。  
如果什么都没有：拔掉换口，关干净所有 `pyocd list`、STM32CubeProgrammer、Keil 再试。

## 第 7 步：刷入 DAPLink 固件

确认探测成功后，刷仓库自带的预编译固件：

**macOS / Linux：**

```bash
./stlink-tool/stlink-tool firmware/DAP103-HID-STBOOT.bin
```

**Windows（MSYS2）：**

```bash
./stlink-tool/stlink-tool.exe firmware/DAP103-HID-STBOOT.bin
```

**Windows（cmd）：**

```bat
stlink-tool\stlink-tool.exe firmware\DAP103-HID-STBOOT.bin
```

刷的时候：

- **不要**同时开着 `pyocd list`、STM32 官方工具、Keil 的调试会话
- 写到一半 USB 卡死、命令挂住，**非常常见**。拔掉，换一个 USB 口插上，等 2 秒，**再执行同一条命令**即可，不用从头装环境
- 多试一两次是正常的

## 第 8 步：启动 DAPLink

廉价克隆每次上电，经常**停在 ST bootloader**，即使固件已经在 Flash 里。所以刷完（以及以后每次想用 CMSIS-DAP 时）要启动一次：

**macOS / Linux：**

```bash
./start-daplink.sh
```

**Windows（cmd）：**

```bat
start-daplink.bat
```

脚本做的事就是：运行一次不带参数的 `stlink-tool`（让 bootloader 跳到已刷的固件），等 1 秒，然后 `pyocd list`。

成功时 `pyocd list` 会类似：

```
  #   Probe/Board          Unique ID                  Target
---------------------------------------------------------------
  0   Devanarchy DAP103 CMSIS-DAP   0000000000000000     ?
```

也可以自己再查一遍 USB：这时应是 `1209:da42` / `DAP103 CMSIS-DAP`。

如果还是 `0483:3748`：再跑一次启动脚本；仍不行就把第 7 步再刷一遍。

## 第 9 步：接到目标芯片，下载程序

接线（先断电再接）：

```
ST-Link 克隆                目标板
-------------               -------------
SWDIO  -------------------> SWDIO / DIO / SWD
SWCLK  -------------------> SWCLK / CLK / SWC
GND    -------------------> GND
3.3V   -------------------> 3.3V     （目标板需要仿真器供电时才接）
RST    -------------------> NRST/RST （可选，但强烈建议接）
```

注意：

- **不要乱接 5V**，除非你明确知道目标板吃 5V
- 这套固件的 **RESET 在 PB6**，对应很多克隆排针上印着 `RST` 的那根。接上复位会稳很多
- `GND` 必须共地

先看本机 pyOCD 认识哪些型号：

```bash
pyocd list --targets
```

没有 `pyocd` 命令时：

```bash
python3 -m pyocd list --targets
```

Windows 也可以：

```bat
py -m pyocd list --targets
```

下载例子：

```bash
# STM32 / 部分极海 APM32（有对应 pack 时选更精确的型号）
pyocd flash -t stm32f103rc your.hex
```

没有内置型号时，先装厂家 pack：

```bash
pyocd pack find gd32
pyocd pack find apm32
pyocd pack install <刚才搜到的包名>
```

也可以在 Keil 里把调试器选成 **CMSIS-DAP**，不必用命令行。

## 出了问题怎么办

**探测不到 / `LIBUSB_ERROR_ACCESS` / `LIBUSB_ERROR_NOT_FOUND`**

- Windows：Zadig 有没有给 `0483:3748` 换成 WinUSB
- Linux：udev 规则装了没有，装完有没有拔插
- 关掉 CubeProgrammer、Keil、VS Code 的调试、另一个 `pyocd list`
- 换 USB 口，不要用劣质扩展坞；USB 超时就拔掉重插等 2 秒

**刷到一半卡住**

拔掉 → 换口 → 再刷同一条命令。bootloader 还在，重复刷是安全的。

**`stlink-tool` 编译失败**

- macOS：`brew install libusb pkg-config`
- Linux：把 `libusb-1.0-0-dev` / `libusb1-devel` 装上
- Windows：必须在 **MSYS2 MinGW 64-bit** 里编译，不要用 VS 开发者命令行

**刷完还是 ST-Link，Keil / pyOCD 看不到 DAP103**

这是正常现象：克隆停在 bootloader。跑第 8 步的启动脚本。

**`pyocd list` 是空的**

先确认 USB 已经是 `1209:da42`。还是 `0483:3748` 就先启动 DAPLink。已经是 DAP103 仍为空：重装 `pyocd`，或换 `python3 -m pyocd list`。

**Flash 报 64KB，能不能刷？**

可以先试。固件约 14KB，放在 bootloader 后面。若刷入或启动失败，再换 128KB 的克隆。

**以后每次插上是不是都要启动？**

很多克隆是的。养成习惯：插上 → 跑 `start-daplink.sh` / `start-daplink.bat` → 再开 IDE。

## 重新编译固件（可选，一般不用）

仓库的 `firmware/DAP103-HID-STBOOT.bin` 已经能用。只有你改了源码才需要这一节。

需要带 newlib 的 `arm-none-eabi-gcc`。Homebrew 的 `arm-none-eabi-gcc` 常常缺头文件，建议用 [xpack](https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack)。

```bash
git clone --recurse-submodules https://github.com/devanlai/dap42.git
# 把 patches/ 里的改动打到 dap42 上之后：
make TARGET=STM32F103-HID-STBOOT -C dap42
```

改动要点：固件链到 `0x08004000`；启动时清掉 ST bootloader 留下的中断，并设置 `VTOR`。详见 `patches/README.md`。

## 刷回原版 ST-Link（可选）

仿真器停在 bootloader 时（刚插上、USB 仍是 `0483:3748`），用 ST 官方升级工具即可：

[STSW-LINK007](https://www.st.com/en/development-tools/stsw-link007.html)

Windows 若已用 Zadig 换过 WinUSB，官方工具可能认不到，需要把驱动改回 ST 的，或在另一台没换过驱动的电脑上刷回。

## 许可与致谢

- 预编译固件来自 dap42，许可见 [devanlai/dap42](https://github.com/devanlai/dap42)
- `stlink-tool` 为 MIT，见其目录内 README
- 本仓库脚本按 MIT 使用

---

<a id="en"></a>

# ST-Link V2 → DAPLink (English, step by step)

[中文](#zh)

## What this does

Those cheap standalone metal-case **ST-Link V2** clones usually show up as:

- USB name: `STM32 STLink`
- USB ID: `0483:3748`

They work reasonably for **STM32**, and poorly for Geehy APM32, GigaDevice GD32, Nordic nRF52, and other Cortex-M parts that ST tools do not know.

After flashing this repo, the dongle becomes open-source **CMSIS-DAP** (`DAP103`):

- USB name: `DAP103 CMSIS-DAP`
- USB ID: `1209:da42`

You can then use [pyOCD](https://pyocd.io/), Keil (CMSIS-DAP), OpenOCD, and similar tools.

> **This does not brick the dongle.** The first 16KB ST bootloader stays. These clones often land in the bootloader on every plug-in, so you can reflash or restore official ST-Link firmware later.

## Will my probe work?

**Yes, this guide is for:**

- A standalone ST-Link V2 clone (metal or plastic dongle, not onboard)
- USB shows `STM32 STLink` with ID `0483:3748`
- STM32F103 inside. **128KB Flash is best.** The image is about 14KB and is linked at `0x08004000`, so **64KB clones usually work too**

**Do not flash:**

- Onboard ST-Link on Nucleo / Discovery boards
- ST-Link **V2.1** (often `0483:374b`, with a mass-storage drive)
- ST-Link **V3**, J-Link, or a dongle that is already DAPLink

Not sure? Install the tools below and run the probe command. If you see `STLinkV2 Bootloader Found`, continue.

## What you need

Hardware:

1. A computer: Windows 10/11, macOS, or Linux
2. The standalone ST-Link V2 clone above
3. A USB cable (many clones are captive-cable)
4. A target board with `SWDIO`, `SWCLK`, `GND` (`3.3V` and reset recommended)

Software is installed in the steps below. Copy one command at a time.

## The three USB “modes”

| Mode | USB name | USB ID | Meaning |
|------|----------|--------|---------|
| ST bootloader | `STM32 STLink` | `0483:3748` | Most common right after plugging in. You can flash or jump to existing firmware |
| DAPLink running | `DAP103 CMSIS-DAP` | `1209:da42` | Flash succeeded **and** the app is running. This is when you can program a target |
| Stock ST-Link firmware | `STM32 STLink` | `0483:3748` | Not converted yet, or restored to ST firmware |

## Step 1 — Get this repository

**Option A: Git (recommended)**

```bash
git clone https://github.com/Amia801/daplink-flash.git
cd daplink-flash
```

**Option B: ZIP**

1. Open https://github.com/Amia801/daplink-flash
2. Click green **Code** → **Download ZIP**
3. Unzip it and remember the folder path

Open a terminal **in that folder**:

- **Windows:** Shift+right-click empty space → “Open in Terminal”, or type `cmd` in Explorer’s address bar
- **macOS:** open Terminal, type `cd ` (with a space), drag the folder in
- **Linux:** right-click the folder → Open in Terminal

Every later command assumes your current directory is `daplink-flash`.

## Step 2 — Install a compiler and Python

Follow **only** your OS.

### Windows

1. Install [Python 3](https://www.python.org/downloads/). Check **Add python.exe to PATH**.
2. Install pyOCD:

```bat
py -m pip install -U pyocd
```

3. Install [MSYS2](https://www.msys2.org/). Open **MSYS2 MinGW 64-bit** from the Start menu (the MinGW one, not plain MSYS).
4. In that MinGW 64-bit window:

```bash
pacman -S --needed make mingw-w64-x86_64-gcc mingw-w64-x86_64-pkgconf mingw-w64-x86_64-libusb
```

5. `cd` into this repo, for example:

```bash
cd /c/Users/YourName/Downloads/daplink-flash
```

Windows `C:\Users\...` is `/c/Users/...` inside MSYS2.

### macOS

Install Homebrew from https://brew.sh if needed, then:

```bash
brew install libusb pkg-config python3
python3 -m pip install -U pyocd
```

### Linux (Debian / Ubuntu / Linux Mint)

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libusb-1.0-0-dev python3 python3-pip python3-venv
python3 -m pip install -U pyocd
```

Fedora:

```bash
sudo dnf install gcc make pkgconf-pkg-config libusb1-devel python3 python3-pip
python3 -m pip install -U pyocd
```

Arch:

```bash
sudo pacman -S base-devel pkgconf libusb python python-pip
python3 -m pip install -U pyocd
```

If pip complains about permissions:

```bash
python3 -m pip install -U --user pyocd
```

Check that one of these works:

```bash
pyocd --version
python3 -m pyocd --version
py -m pyocd --version
```

## Step 3 — Build `stlink-tool`

This repo does **not** ship a ready-made binary. From the repo root:

```bash
cd stlink-tool
make
cd ..
```

You should get:

- macOS / Linux: `stlink-tool/stlink-tool`
- Windows (MSYS2): `stlink-tool/stlink-tool.exe`

If `make` is not found, use `mingw32-make` instead.  
If `make` cannot find `pkg-config` or `libusb`, finish Step 2 and build again.

## Step 4 — Allow USB access

This is the step that traps most people.

### Windows: Zadig → WinUSB

The stock ST driver often blocks `stlink-tool`.

1. **Plug in** the ST-Link
2. Download [Zadig](https://zadig.akeo.ie/)
3. Zadig → **Options** → **List All Devices**
4. Select `STM32 STLink` (USB ID `0483` `3748`)
5. Choose **WinUSB** on the right → **Replace Driver**
6. **Do not** replace the driver for your keyboard, mouse, or camera

Device Manager may then show a WinUSB device. That is expected.

After the dongle becomes DAPLink, Windows usually binds the HID driver to `1209:da42` by itself. You do not need Zadig again for that ID.

### macOS

No extra driver. Skip.

### Linux: udev rule (once)

```bash
sudo cp udev/99-stlink-daplink.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Unplug and replug the dongle. Do not use `sudo` for later flash commands unless the rule did not take effect.

## Step 5 — Plug in and check that the OS sees it

Wait 2 seconds after plugging in. If pyOCD reports a USB timeout, unplug, try another port, wait 2 seconds.

**Windows (PowerShell):**

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_0483|VID_1209' } | Format-Table Status, FriendlyName, InstanceId -AutoSize
```

**macOS:**

```bash
system_profiler SPUSBDataType | grep -i -A6 -e 'STLink' -e 'DAP103' -e 'CMSIS' -e '3748' -e 'da42'
```

**Linux:**

```bash
lsusb | grep -i -e '0483:3748' -e '1209:da42' -e 'STLink' -e 'DAP'
```

Before flashing you should see `0483:3748`. If you see nothing: change cable/port, avoid cheap hubs.

## Step 6 — Probe the bootloader

From the repo root.

**macOS / Linux:**

```bash
./stlink-tool/stlink-tool -p
```

**Windows (MSYS2 MinGW 64-bit):**

```bash
./stlink-tool/stlink-tool.exe -p
```

**Windows (cmd, after the exe exists):**

```bat
stlink-tool\stlink-tool.exe -p
```

A good result looks like:

```
STLinkV2 Bootloader Found
STLink Type: M [STM8/STM32 Debugger]
...
Reported Flash Size: 64KB   (or 128KB)
Current Mode: 1
```

You need both:

- `STLinkV2 Bootloader Found`
- `Current Mode: 1` (1 = bootloader)

Linux `LIBUSB_ERROR_ACCESS`: redo the udev rule in Step 4, or try once with `sudo`.  
Windows “no device”: redo Zadig in Step 4.  
No output at all: unplug, change port, quit every `pyocd list`, STM32CubeProgrammer, and Keil session.

## Step 7 — Flash DAPLink

**macOS / Linux:**

```bash
./stlink-tool/stlink-tool firmware/DAP103-HID-STBOOT.bin
```

**Windows (MSYS2):**

```bash
./stlink-tool/stlink-tool.exe firmware/DAP103-HID-STBOOT.bin
```

**Windows (cmd):**

```bat
stlink-tool\stlink-tool.exe firmware\DAP103-HID-STBOOT.bin
```

While flashing:

- Do **not** leave `pyocd list`, ST tools, or a Keil debug session running
- USB wedging halfway is **common**. Unplug, use another port, wait 2 seconds, run **the same command** again. You do not need to reinstall anything
- A retry or two is normal

## Step 8 — Start DAPLink

Cheap clones often **stay in the ST bootloader** after every power-up, even when firmware is already in Flash. After flashing — and later whenever you want CMSIS-DAP — start it:

**macOS / Linux:**

```bash
./start-daplink.sh
```

**Windows (cmd):**

```bat
start-daplink.bat
```

The script runs `stlink-tool` with no arguments (bootloader jumps to the flashed app), waits one second, then runs `pyocd list`.

Success looks like:

```
  #   Probe/Board          Unique ID                  Target
---------------------------------------------------------------
  0   Devanarchy DAP103 CMSIS-DAP   0000000000000000     ?
```

USB should now be `1209:da42` / `DAP103 CMSIS-DAP`.

If it is still `0483:3748`, run the start script again. If that still fails, repeat Step 7.

## Step 9 — Wire the target and program it

Wire with power off:

```
ST-Link clone               Target
-------------               -------------
SWDIO  -------------------> SWDIO / DIO / SWD
SWCLK  -------------------> SWCLK / CLK / SWC
GND    -------------------> GND
3.3V   -------------------> 3.3V     (only if the target should be powered by the probe)
RST    -------------------> NRST/RST (optional, strongly recommended)
```

Notes:

- Do **not** attach 5V unless you know the target wants 5V
- On this firmware, **RESET is PB6**, which is the `RST` pin on many clone headers. Connecting reset is much more reliable
- `GND` must be common

List pyOCD target names:

```bash
pyocd list --targets
```

If `pyocd` is not on `PATH`:

```bash
python3 -m pyocd list --targets
```

Windows:

```bat
py -m pyocd list --targets
```

Flash example:

```bash
# STM32 / some Geehy APM32 parts (pick a more specific name if you installed a pack)
pyocd flash -t stm32f103rc your.hex
```

If the MCU is not built in:

```bash
pyocd pack find gd32
pyocd pack find apm32
pyocd pack install <pack-name-from-search>
```

In Keil you can also just select **CMSIS-DAP** as the debug adapter.

## Troubleshooting

**Probe fails / `LIBUSB_ERROR_ACCESS` / `LIBUSB_ERROR_NOT_FOUND`**

- Windows: did Zadig install WinUSB on `0483:3748`?
- Linux: udev rule installed, then unplug/replug?
- Close CubeProgrammer, Keil, VS Code debug, and extra `pyocd list` processes
- Change USB ports; skip cheap hubs; on timeout, unplug, replug, wait 2 seconds

**Flash hangs halfway**

Unplug → another port → same flash command. The bootloader is still there; retrying is safe.

**`stlink-tool` will not build**

- macOS: `brew install libusb pkg-config`
- Linux: install `libusb-1.0-0-dev` / `libusb1-devel`
- Windows: build inside **MSYS2 MinGW 64-bit**, not a Visual Studio prompt

**Still looks like ST-Link; Keil / pyOCD do not see DAP103**

Normal: the clone is sitting in the bootloader. Run Step 8.

**`pyocd list` is empty**

Confirm USB is `1209:da42`. If it is still `0483:3748`, start DAPLink first. If it is already DAP103: reinstall `pyocd`, or use `python3 -m pyocd list`.

**Probe reports 64KB Flash. Can I flash?**

Try it. The image is ~14KB behind the bootloader. If flash or startup fails, use a 128KB clone.

**Do I have to start DAPLink on every plug-in?**

On many clones, yes. Habit: plug in → `start-daplink.sh` / `start-daplink.bat` → then open the IDE.

## Rebuild the firmware (optional)

`firmware/DAP103-HID-STBOOT.bin` is enough for most people.

You need `arm-none-eabi-gcc` **with newlib**. Homebrew’s `arm-none-eabi-gcc` often lacks headers; use [xpack](https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack).

```bash
git clone --recurse-submodules https://github.com/devanlai/dap42.git
# Apply the changes in patches/, then:
make TARGET=STM32F103-HID-STBOOT -C dap42
```

The firmware is linked at `0x08004000`. At startup it clears interrupts left by the ST bootloader and sets `VTOR`. See `patches/README.md`.

## Restore official ST-Link firmware (optional)

When the dongle is in the bootloader (just plugged in, USB still `0483:3748`), use ST’s updater:

[STSW-LINK007](https://www.st.com/en/development-tools/stsw-link007.html)

If Windows was switched to WinUSB with Zadig, the official tool may not see the device. Restore ST’s driver, or recover on a machine that still has the ST driver.

## License and credits

- Prebuilt firmware comes from dap42; see [devanlai/dap42](https://github.com/devanlai/dap42)
- `stlink-tool` is MIT; see the README in that folder
- Scripts in this repository are MIT
