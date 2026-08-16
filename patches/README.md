These patches make [dap42](https://github.com/devanlai/dap42) coexist with the ST-Link V2 bootloader.

Apply on a current dap42 tree, then:

```bash
make TARGET=STM32F103-HID-STBOOT -C dap42
```
