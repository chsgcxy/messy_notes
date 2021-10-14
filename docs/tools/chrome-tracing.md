# 使用chrome-tracing工具查看性能分析log

最近接到需求，想要以图形化的方式展现出gem5的指令流，这方便分析指令顺序，以指导工具链通过对指令重排来提高指令执行效率。

google-chrome有trace Event Profiling Too,这是分析浏览器性能的，我们可以借用这个来分析gem5指令性能。

参考资料如下:

[https://www.chromium.org/developers/how-tos/trace-event-profiling-tool]

[https://www.gamasutra.com/view/news/176420/Indepth_Using_Chrometracing_to_view_your_inline_profiling_data.php]

实际上，其中的tracing是在catapult(Catapult is the home for several performance tools that span from gathering, displaying and analyzing performance data)这个工具集合中

[https://chromium.googlesource.com/catapult/+/refs/heads/main/README.md]
[https://chromium.googlesource.com/catapult]
[https://github.com/catapult-project/catapult]

## 我的实现

核心思想是，在gem5代码中添加log打印，运行完gem5后，通过脚本解析log,将log转换成 trace-event-profiling-tool需要的json格式。
使用工具打开json文件即可。

gem5中添加log

```c++
#define DPRINTF_STC_PERF(eu, name, ev, state)  do { \
    DPRINTF(StcPerf, \
        "[STC Perf Tag] UnitName:%s,InstName:%s,Event:%s,Status:%s\n", \
        eu, name, ev, state); \
} while (0)

#define DPRINTF_STC_PERF_INSTS(ncpInst, ev, state)  do { \
    const char *eu; \
    if (ncpInst->getFlag(NeuralCPInst::IsVME) || \
            ncpInst->getFlag(NeuralCPInst::IsRVV)) \
        eu = "vme"; \
    else if (ncpInst->getFlag(NeuralCPInst::IsMME)) \
        eu = "mme"; \
    else \
        eu = "mte"; \
    DPRINTF(StcPerf, \
        "[STC Perf Tag] UnitName:%s,InstName:%s,Event:%s,Status:%s," \
        "InstId:%x-%x\n", \
        eu, ncpInst->getName(), ev, state, \
        (uint64_t)ncpInst, ncpInst->inst->machInst); \
} while (0)
```

log解析成json

```python
#!/usr/bin/env python3

import json
import argparse

helps = '''
python3 perf-parser.py -f 123.log

use a [StcPerf] debug-flags to creat log file
./build/RISCV/gem5.debug --debug-flags=StcPerf ...... > 123.log
a file named perf_events.json will be created after run this script
'''
parser = argparse.ArgumentParser()
parser.add_argument('--file', '-f', help='log file')
parser.usage = helps
args = parser.parse_args()

if args.file is None:
    parser.print_help()
    exit(1)

# 4906000: system.cpu0.ncp: [STC Perf Tag] UnitName:vme,
# InstName:vlh,InstId:5640c40763401205d087,Event:InstInNCP,
# Status:start
def line2record(line):
    record = {}
    info0, info1 = line.strip('\n').split('[STC Perf Tag]')
    ticks, systeminfo, *others = info0.strip(' ').split(':')
    cycles = int(ticks) // 1000
    record['cycles'] = cycles
    idstr, *others = systeminfo[systeminfo.find('cpu'):].split('.')
    if idstr[3:].isdecimal():
        cpuid = int(idstr[3:])
    else:
        cpuid = 0
    record['cpuid'] = cpuid
    keyvalues = info1.strip(' ').split(',')
    keyvalues_splited = [keyvalue.split(':') for keyvalue in keyvalues]
    for keyvalue in keyvalues_splited:
        record[keyvalue[0]] = keyvalue[1]
    return record


''' a event example
{

     "cat": "MY_SUBSYSTEM",  //catagory

     "pid": 4260,  //process ID

     "tid": 4776, //thread ID

     "ts": 2168627922668, //time-stamp of this event

     "ph": "B", // Begin sample

     "name": "doSomethingCostly", //name of this event

     "args": { //arguments associated with this event.

       }
}
'''
def record2event(record):
    event = {}
    event['cat'] = 'insts'
    if record['Event'] == 'SysDMA':
        event['pid'] = 'global'
        event['tid'] = "　sysdma"
    else:
        event['pid'] = record['cpuid']
        if record['Event'] == 'Sync':
            event['tid'] = "　sync"
        elif record['Event'] == 'Issue':
            event['tid'] = "　mcu"
        elif record['UnitName'] == 'mme':
            event['tid'] = "　mme"
        elif record['UnitName'] == 'vme':
            event['tid'] = "　vme"
        elif record['UnitName'] == 'mte':
            event['tid'] = "　mte"
        else:
            print('unsupported UnitName in record(vme/mme/mte supported only)')
            print(record)
            exit(1)

    event['name'] = record['InstName']
    event['ts'] = record['cycles']
    if record['Status'] == 'start':
        event['ph'] = 'B'
    elif record['Status'] == 'stop':
        event['ph'] = 'E'
    else:
        event['ph'] = 'i'
    event['args'] = record
    return event

events = []

with open(args.file, 'r') as filp:
    for line in filp:
        if '[STC Perf Tag]' not in line:
            continue
        record = line2record(line)
        event = record2event(record)
        events.append(event)

with open('perf_events.json', 'w') as filp:
    json.dump(events, filp, separators=(',', ':'),
        sort_keys=True, indent=4)

```

将生成的json文件用google-tools打开即可，在google浏览器中输入：**chrome://tracing/**

## tracing 格式详解

在使用google tracing的时候，要牢记 ***它是按照线程的逻辑进行设计的, 一个线程在同一段时间内肯定只能执行一个任务。所以我们在用来表示指令时，应该将不同的指令看作不同的线程，一般情况下，我们可以按照硬件资源来划分线程， 比如说buffer的容量是8, 那么就可以认为有8个线程***。这样我们就能理解为什么有些时候它解析的和我们设想的不一样。

### duration event

如果一个事件持续一段时间，那么可以使用这种事件类型。比如说用来记录指令的生命周期，指令fetch为B， 指令被commit记为E。
看下面的示例，假如add和sub指令在cycle=1时fetch, 在cycle=6时add被提交，在cycle=10时，sub指令被提交。

```json
[
  {"ts": 1, "pid": "CPU0", "tid": 1, "ph": "B", "name": "add"},
  {"ts": 1, "pid": "CPU0", "tid": 2, "ph": "B", "name": "sub"},
  {"ts": 6, "pid": "CPU0", "tid": 1, "ph": "E", "name": "add"},
  {"ts": 10, "pid": "CPU0", "tid": 2, "ph": "E", "name": "sub"}
]
```

### complete event

complete event实际上就是duration event的融合，这样能够缩小整个json文件的大小， 当然也意味着我们解析trace的脚本需要做更多。

complete event 的 dur = E->ts - B->ts, 同时 ts代表了起始时间。

```json
[
  {"ts": 1, "pid": "CPU0", "tid": 1, "ph": "X", "dur": 6, "name": "add"},
  {"ts": 1, "pid": "CPU0", "tid": 2, "ph": "X", "dur": 10, "name": "sub"}
]
```

### instant event

只是用来记录事件发生了，但是不占用时间。下面的例子添加了三种类型的instant事件

```json
[
  {"ts": 1, "pid": "CPU0", "tid": 1, "ph": "X", "dur": 6, "name": "add0"},
  {"ts": 1, "pid": "CPU0", "tid": 2, "ph": "X", "dur": 10, "name": "sub0"},
  {"ts": 1, "pid": "CPU1", "tid": 1, "ph": "X", "dur": 6, "name": "add1"},
  {"ts": 1, "pid": "CPU1", "tid": 2, "ph": "X", "dur": 10, "name": "sub1"},
  {"ts": 2, "pid": "CPU0", "tid": 2, "ph": "i", "s": "t", "name": "inst issue"},
  {"ts": 4, "pid": "CPU1", "tid": 1, "ph": "i", "s": "p", "name": "cpu1 halt"},
  {"ts": 5, "pid": "CPU0", "tid": 2, "ph": "i", "s": "g", "name": "stop"}
]
```

### counter event

用类似柱状图的形式粗略的表示出各个成员所占的数量和比例

```json
[
  {"pid": 0, "name": "ctr", "ph": "C", "ts": 0, "args": {"cats": 0, "dogs": 7, "pig": 5}},
  {"pid": 0, "name": "ctr", "ph": "C", "ts": 10, "args": {"cats": 10, "dogs": 14, "pig": 10}},
  {"pid": 0, "name": "ctr", "ph": "C", "ts": 20, "args": {"cats": 20, "dogs": 21, "pig": 5}},
  {"pid": 0, "name": "ctr", "ph": "C", "ts": 30, "args": {"cats": 30, "dogs": 28, "pig": 10}},
  {"pid": 0, "name": "ctr", "ph": "C", "ts": 40, "args": {"cats": 40, "dogs": 35, "pig": 5}}
]
```

### async event

异步事件，多了一个id用来标识同一组事件。

## 环境集成

关于如何使用已经总结完毕了，对于一般的应用场景来讲，了解上面这些已经足够了，我们生成json文件，然后在google浏览器中输入chrome://tracing/，再在里面打开我们的json文件，就能看到我们生成的波形了。
但在很多场景中，这是无法实现的。因为一般IC公司的保密性很高，又很难保证工作的机器中一定能够安装google-chrome, 所以我们要使用另一种方法来生成。

### 方法一：直接使用repo中的可执行文件生成

在catapult的repo中，tracing/bin/目录下有trace2html的工具，可以直接输入json文件，输出html。实际测试，firefox, chrome, edge都能正常显示。

```shell
$CATAPULT/tracing/bin/trace2html my_trace.json --output=my_trace.html && open my_trace.html
```

### 方法二：集成到python脚本中

在catapult的repo中，tracing/trace_build目录下有很多python文件，可以像下面这样使用, 需要设置path_to_catapult

```python
import sys
import os

sys.path.append(os.path.join(path_to_catapult, 'tracing'))
from tracing_build import trace2html
with open('my_trace.html', 'w', encoding='utf-8') as new_file:
  trace2html.WriteHTMLForTracesToFile(['./dut_perf_waitbuffer.json'], new_file)
```
