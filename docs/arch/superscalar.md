# 超标量处理器设计

本文是对《超标量处理器设计》的个人总结

## 什么是超标量处理器

如果一个处理器在每个cycle可以取出多于一条指令送到流水线中，并且使用硬件来对指令进行调度，那么这个处理器就可以被成为超标量处理器。超标量处理器可以是顺序执行的也可以是乱序执行的。
这里重点讨论乱序(发射和执行可以乱序)执行的超标量处理器。首先应该明白，超标量处理器没有一套固定的设计原则，更多的时候，需要根据实际的场景，结合对性能，功耗，能效比，单核还是多核，成本等各种因素进行有针对性的设计。

现代的超标量处理器一般包含下面几个步骤, 后续针对每一个步骤会展开讨论

```text
        -----------
        | icache  |
        -----------
             |
             |
             V
           fetch
             |
             |
             V
           decode
             |
             |
             V
        register rename
             |
             |
             V
          dispatch
             |
             |
             V
           issue
             |
             |
             V
      register file read
             |
             |
             V
          execute
             |
             |
             V
          write back
             |
             |
             V
           commit
```

---

## cache

我觉得随着硬件技术的进步，我们可能不再需要cache， DRAM的性能能够接近甚至达到cache水平。但在未来的一段时间，cache仍然是解决CPU与DRAM之间速度的唯一手段。
当然，最重要的还是cache的思维，在计算机领域，通过增加一层来解决问题的思维。

这里不讨论Cache原理，重点讨论Cache的实现。
ICache只有读操作，相对简单，对于DCache, 它需要有多端口设计。这就牵扯到Cache的多端口设计下的，容量和面积以及速度的关系。

多路组相联的Cache因为要按照一定顺序比较多个Tag, 因此延迟要比直接映射Cache的延迟大。甚至为了保证时序，还需要拆解成多级流水。

![../imgs/cache_2way.png](../imgs/cache_2way.png)
![../imgs/cache_multi_cycle.png](../imgs/cache_multi_cycle.png)

cache的tag与data的串行访问还是并行访问也会对性能和功耗有影响，并行访问会导致主频上不去，功耗大，但访问cache的周期能够缩短。

全相联cache没有index，需要用到CAM(Content Address Memory), 在整个Cache中进行Tag比较。这种有着最大的灵活度，不容易出现miss, 但延迟也是最大的。

注意区分write back and write allocate 与 write through and no-Write allocate.

### cache line的替换策略

- LRU(Least Recently Used)方法, 2选一就用1bit寄存器来标识。伪LRU就使用分级的多级二选一进行选择。
- 随机替换(Random Replacement),当cache容量较大时，miss率和LRU差不多。一般采用时钟算法来实现近似随机，本质上是计数器，宽度等于cahce的way的个数，硬件复杂度低。

### cache性能优化

- Write buffer: 被替换的 dirty cache line 先写入write buffer， 择机写入下级存储器。这会增加cache的复杂度，当发生cache miss的时候，不仅需要从下级存储器查找数据，还需要从write buffer中查找，并且write buffer中的数据优先。
- pipline: 往往为了保证设计主频，需要对cache访问进行流水化。尤其是在写操作时，必须保证先比较完tag再写数据。常见的可以将tag SRAM的读取和比较放在一个周期，写Data Sram放在下一个周期。一旦分流水，那么就会产生读的数据正好在写流水线中的情况。这就又需要将load指令携带的地址和store指令的流水线寄存器进行比较。
- 多级结构。这里又分了Inclusive和Exclusive。即L2 Cache是否包含L1 Cache中的内容。虽然Exclusive类型的cache策略可以提高容量利用，但现代大多数处理器都采用Inclusive的Cache.
- Victim Cache. 保存最近被踢出的cache数据。[^1]
- Filter Cache. 先过滤掉偶然访问的数据，避免这类数据进入cache占资源
- 预取。可以提前取数据进入cache，但为了避免cache污染，可以将预取的放到一个单独的缓存中。当然预取就有成功率，就会因为判断错误而浪费功耗和带宽。[^2]
- 多端口Cache. Data SRAM一般采用multi-banking的组织方式。影响这种方式性能的关键因素就是bank conflict。可以通过更多的bank来降低冲突概率。[^3]

AMD Opteron 双端口D-Cache设计实例

![../imgs/multi-bank-cache.png](../imgs/multi-bank-cache.PNG)
![../imgs/amd_opteron_dcache.png](../imgs/amd_opteron_dcache.png)

---

## MMU

[^1]: 这是一种备份思想，虽然给每个人分配了晚餐，但也不想每个人都给足够的食物，就多备了几份，给那些饭量大的人
[^2]: 如果CPU能够有类似AI的学习机制，有比较大的空间能够用来学习数据地址的规律，在预取时能够保证比较高的准确率，那么效率一定能提高不少
[^3]: 想象一下极限情况，如果每个数据都有一个端口，那么必然也不会存在端口冲突，但是代价也是巨大的，需要无数根线来连接。
