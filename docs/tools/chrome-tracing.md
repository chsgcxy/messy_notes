# 使用chrome-tracing工具查看性能分析log

最近接到需求，想要以图形化的方式展现出gem5的指令流，这方便分析指令顺序，以指导工具链通过对指令重排来提高指令执行效率。

google-chrome有trace Event Profiling Too,这是分析浏览器性能的，我们可以借用这个来分析gem5指令性能。

参考资料如下:

https://www.chromium.org/developers/how-tos/trace-event-profiling-tool

https://www.gamasutra.com/view/news/176420/Indepth_Using_Chrometracing_to_view_your_inline_profiling_data.php

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
