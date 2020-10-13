# stm32f207 emwin + freertos 调试过程问题简要记录

[TOC]

## 链接出错，超出地址范围

添加emwin后编译能够通过，链接的时候报错，符号超出地址范围

错误打印类似如下

```txt
.\Objects\printer.axf: Error: L6406E: No space in execution regions with .ANY selector matching guiconf.o(.bss).
.\Objects\printer.axf: Error: L6406E: No space in execution regions with .ANY selector matching heap_4.o(.bss).
.\Objects\printer.axf: Error: L6406E: No space in execution regions with .ANY selector matching startup_stm32f2xx.o(STACK).
```

GUIConf.c 中定义了GUI可用的flash字节数,默认很大，改小即可

```c
// Define the available number of bytes available for the GUI
// the orign GUI_NUMBYTES is too larger
//#define GUI_NUMBYTES  0x200000
#define GUI_NUMBYTES   0xc800
```

## FRAMEWIN 界面在freertos调度之前初始化可以正常显示，在任务中无法正常运行

```c
xTaskCreate(task_helloworld, "hello world", 64, NULL, 1, NULL);
xTaskCreate(task_touch, "touch", 128, NULL, 2, &handle_touch);
xTaskCreate(task_ui, "ui", 1024, NULL, 1, &handle_gui);
```

创建了3个任务，其中任务hello world 和 touch 能够同时加入执行，一旦加入ui task,就会卡死，去掉ui 任务就能正常调度

怀疑堆栈溢出

- 把ui task 堆栈大小改为512， 仅保留这一个任务，发现ui能够正常显示
- 这时再加入hello world 任务，hello world 任务也能够正常得到执行
- 此时再加入touch任务，又出现卡死现象

基本确定堆栈不够用

尝试修改启动文件中的栈大小

```c
Stack_Size      EQU     0x00001800

                AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem       SPACE   Stack_Size
__initial_sp

```

将栈大小由原来的0x800改为0x1800, 问题解决

## 在UI中触摸无法触发事件

触摸驱动本身调试ok, 也通过如下触摸任务不断更新触摸状态

```c
void touch_update(void)
{
  GUI_PID_STATE pstate;

  if (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_10)) {
        pstate.Pressed = 0;
      goto store;
    }

    touch_read_phy();
    touch_trans(&pstate, &g_touch);
  printf("pressed=%d, (%d,%d)\r\n", pstate.Pressed, pstate.x, pstate.y);

store:
  GUI_PID_StoreState(&pstate);
}
```

但触摸FRAME_WIN中的控件，仍然没有触摸事件产生，确认配套版本的emwin 参考手册，确认操作方法没错，查看
GUI_PID_STATE 的定义，发现只有Layer没有赋值

```c
typedef struct {
  int x,y;
  U8  Pressed;
  U8  Layer;
} GUI_PID_STATE;
```

查看emwin配置GUIConf.h

```c
#define GUI_NUM_LAYERS            2    // Maximum number of available layers
```

猜测是不是因为Layer没有赋值而导致传错了Layer, 尝试在代码中添加pstate.Layer = 0; 

添加后部分代码如下

```c
  GUI_PID_STATE pstate;

  pstate.Layer = 0;
  if (GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_10)) {
```

再次测试，能够触发触摸事件，问题得到解决
