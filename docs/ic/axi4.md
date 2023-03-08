# AXI4

valid/ready握手协议

AXI4有多种子类型：

- AXI4: 一般用于高性能存储映射需求
- AXI4-Lite: 一般用于简单的，低吞吐量的存储映射（例如控制与状态寄存器之间的映射）
- AXI4-Stream: 一般用于高速的数据流

名词解释：

- Transaction：操作，一笔操作在多个通道上进行，构成一个完整的信息交换
- Burst：单个地址传输多个数据，有三种模式。
- Outstanding: 一个传输没有完成就可以发送下一个

总线带宽的计算

```text
trans_size = beat_size * burst_len
bandwidth = trans_counter * trans_size / trans_time
```

注意相同ID不乱序

## AXI4-stream

todo...
