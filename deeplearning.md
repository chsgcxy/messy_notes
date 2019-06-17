# deeplearning

[TOC]

## 半精度浮点

一个fp16数据占据两个字节，1位符号位，5位指数位，10位有效精度

- 符号位
  - 0：正数
  - 1：负数
- 指数位：与15的偏差
  - max_e=11110-01111=15
  - min_e=00001-01111=-14
  - 00000和11111有其他意义
- 数值计算公式为：(-1)^signbit  * 2^(e) * (1+significantbits)
- 最大值：0 11110 1111111111=(-1)^0 * 2^15 * (1+1-2^-10)=65504
- 最小值：0 00001 0000000000=2^-14=6.10 * 10^-5

## 卷积

实际上是对应数据相乘然后求和，可以理解为加权求和

## 数据归一化

归一化（标准化）可以定义为：把你需要处理的数据经过处理后（通过某种算法）限制在你需要的一定范围内。
首先归一化是为了后面数据处理的方便，其次是保证模型运行时收敛加快，归一化并不是约束到0~1之间

## 深度学习框架

框架 | 前端 | 后端 | 硬件
---|---|---|---
tensorflow | XLA | LLVM | GPU / ARM / X86
tensorflow/Caffe2/PyTorch/MXNet | Poplar | POPLAR GRAPH COMPILER | IPU
tensorflow/ONNX/CoreML | TVM(NNVM) | cuda/LLVM/Metal/OpenCL |
tensorflow/MxNet/ONNX | NGraph | IA Transformer/NNP |
