# 利用Trace进行性能分析

前面已经总结过借助google的tracing来进行性能分析的方法[使用chrome-tracing工具查看性能分析log](../tools/chrome-tracing.md)。最近需要让芯片验证的同事提供一些仿真的trace，以便进行性能分析。芯片验证同事却不知道应该提供怎样的trace, 我也没法比较详细的给他进行描述，一是因为trace必然要具体问题具体分析，笼统的指导意见很难落地。二是我自己对此也没有一个好的总结。所以把之前做的一些trace在这里借机做一些总结，以便后续能够提供一套相对普适的方法和工具来做trace的性能分析。

## 核心思想

- trace采用事件的形式，以指令为对象，记录指令在某个cycle触发了怎样的事件，以此来分析性能优化的可能性。
- 指令要有全局唯一的ID(比如说PC)来识别(在有些结构中可能不保存全局唯一ID, 这时要找到转换的位置，建立全局唯一ID与模块ID的关系)
- 事件类型参考google tracing提供的事件格式来制定，比较常用的就是complete event, instant event 和 duration event
- 尽可能的保证生成的json文件只针对某一个具体的问题。大而全的json文件看起来是很头疼的，我们需要针对具体问题生成不同的json文件，用来对某个具体的性能问题做分析。

## 详细设计

```text
     _________________________                              _________________________________________
    |                         |         toolchain          |                                         |
    |    instructions code    |  ------------------------> |      instruction.elf or bin or hex      |
    |_________________________|                            |_________________________________________|
                                                                     |                   |
                                                                     |                   |
                           ------------------------------------------|                   |
                           |                                                             |
       ____________________V___________________                                __________V____________
      |                                        |                              |                       |
      |                simulator               |                              |           DUT         |
      |________________________________________|                              |_______________________|
                 |                     |                                                 |
                 |                     |                                                 |
       __________V_________     _______V_______                               ___________V_____________
      |                    |   |               |                             |                         |
      |  instruction flow  |   |  depend flow  |                             |       trace flow        |
      |____________________|   |_______________|                             |_________________________|
                     |                 |                                           |      
                     |                 |                                           |
            _________V_________________V___________________________________________V_________
           |                                                                                 |
           |                                flow to json to html                             |
           |_________________________________________________________________________________|
                                                  |
                                                  |  
                                      —————————————————————————
                                     |                         |
                                     |    performance.html     |
                                     |_________________________|
```

### trace flow

事件可以采用如下的格式：

```txt
[trace event] ts=653.00 mod=fetch ch=2 pc=0x00000008 id=1 ......
```

### instruction flow

指令的信息可以来自于很多地方，作为模拟器开发者，我认为解析模拟器的指令执行log是一条比较好的来源，因为模拟器的log我们可控性比较高，解析难度小。
比如下面的log就很容易解析

```text
core 0: 0x0000000000000000 imovl r1,r0,123412341
    oprands   : r0 = 0x3fc4986395a2de5d
    commit log: r1 = 0x3fc49863075b1f75

core 0: 0x0000000000000008 imovh r3,r2,324512345
    oprands   : r2 = 0x3fc4986395a2de5d
    commit log: r3 = 0x1357aa5995a2de5d

core 0: 0x0000000000000000 pre f16
    oprands   : f16 = [0x0000000000000000, 0x0000000000000000]
    commit log:
```

通过对应的pc信息，就能知道事件对应的指令信息

### depend flow

指令依赖链的分析，对于ooo CPU来讲还是比较重要的，单条依赖链的执行速度其实是相对固定的，如果CPU能够同时容纳多条依赖链，那么指令执行的并行度就比较高，意味着更快。
对于单条依赖链，指令之间的cycle间隔就要看流水线的性能，如果有bypass等机制，那么依赖链上的指令执行就会更快。

## 过程中遇到的问题

### 显示顺序问题

在实际操作过程中，遇到了一个问题，找到了一个简单的解决方法：

tracing是按照时间进行解析的，也就是说，哪个pid先出现，先显示哪个。往往我们在调试CPU时，希望按照一定的单元顺序来排列会更好。那么我们可以利用instant event，在第0个cycle，按照我们想要的顺序来排列pid.
这样在显示的时候会更加友好

### trace解析问题

对于在rtl中增加的trace打印，往往不会是按照事件来打印的，可能进buffer的这个动作在好几个cycle中都有打印，我们需要在解析时做一些融合。