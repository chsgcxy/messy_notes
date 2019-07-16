# tvm

[TOP]

## Concept

### Module

一个编译好的对象。可以通过Module以PackedFunc的形式来获取编译后的Func。runtime可以动态获取Func

### Pass

### Op

### Tensor

### Func

## PackedFunc

tvm使用c++实现了一堆接口，这些接口通过PackedFunc封装，使得python调用c++非常easy.

![Packed Function c++](../out/tvm/packedfunc/PackedFunc.png)

c++中实现了对c++函数的管理

python中，**get_global_func** 调用_LIB.TVMFuncGetGlobal来获取PackedFunc指针，然后将其作为handle实例化Function

```python
class Function(_FunctionBase):

class FunctionBase(object):
    def __init__(self, handle, is_global):
        self.handle = handle
        self.is_global = is_global

    def __call__(self, *args):
        temp_args = []
        values, tcodes, num_args = _make_tvm_args(args, temp_args)
        ret_val = TVMValue()
        ret_tcode = ctypes.c_int()
        if _LIB.TVMFuncCall(
                self.handle, values, tcodes, ctypes.c_int(num_args),
                ctypes.byref(ret_val), ctypes.byref(ret_tcode)) != 0:
            raise get_last_ffi_error()
        _ = temp_args
        _ = args
        return RETURN_SWITCH[ret_tcode.value](ret_val)
```

在python端调用Function的过程也就是调用其__call__方法，其中又调用了_LIB.TVMFuncCall来实现对PackedFunc的实际调用

调用过程实际上是调用了PackedFunc的**CallPacked**方法

```c++
inline void PackedFunc::CallPacked(TVMArgs args, TVMRetValue* rv) const {
  body_(args, rv);
}
```

## Node

[跳转到Node子系统介绍](./node.md)

## relay

### relay.build_module.build

**relay.build_module.build** returns three components:

- the execution graph in json format
- the TVM module library of compiled functions specifically for this graph on the target hardware
- the parameter blobs of the model

about optimization
> During the compilation, Relay does the graph-level optimization while TVM does the tensor-level optimization, resulting in an optimized runtime module for model serving.

about tvm schedule
> TVM asks the user to provide a description of the computation called a schedule. A schedule is a set of transformation of computation that transforms the loop of computations in the program

## 流程

tvm-input-output-flow![tvm-input-output-flow](../out/tvm/input-output-flow/tvm-input-output-flow.png)

relay-build-flow![relay-build-flow](../out/tvm/relay-build-flow/relay-build-flow.png)

## codebase-structure-overview

[跳转到软件目录结构](./codebase-struct.md)
