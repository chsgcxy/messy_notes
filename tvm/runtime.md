# runtime

runtime中的代码主要干了三件事情

- 初始化过程，解析graph，转换为内部数据结构，调用DeviceAPI，在device上分配内存空间
- 参数设置过程，将参数copy到分配好的device内存空间上
- 运行过程，遍历执行解析完的graph中的function

## runtime-flow

![runtime flow](../out/tvm/runtime/runtime.png)

## code-flow

python/tvm/contrib/graph_runtime.py 中实现了runtime creat的python接口

```python
def create(graph_json_str, libmod, ctx):
    fcreate = get_global_func("tvm.graph_runtime.create")
    return GraphModule(fcreate(graph_json_str, libmod, *device_type_id))
```

python/tvm/contrib/debugger/debug_runtime.py 中实现了涵盖debug功能的runtime creat python接口

```python
def create(graph_json_str, libmod, ctx, dump_root=None):
    fcreate = get_global_func("tvm.graph_runtime_debug.create")
    func_obj = fcreate(graph_json_str, libmod, *device_type_id)
    return GraphModuleDebug(func_obj, ctx, graph_json_str, dump_root)
```

fcreate 返回包含c++代码中creat方法的handle的Function, 调用fcreate则陷入到c++中执行， c++的代码主要集中在**src/runtime/graph/graph_runtime.cc中**

## deviceAPI

deviceAPI是一个接口，每种target都对应实现了该接口，deviceAPI 更多的是针对内存管理，部分API封装在**c_runtime_api.cc**中供上层调用，在python端可以通过_LIB.xxxx的方式进行调用

- CPUDeviceAPI
- CUDADeviceAPI
- OpenCLWorkspace
- OpenGLWorkspace
- ROCMDeviceAPI
- RPCDeviceAPI
- VTADeviceAPI

```c++
class TVM_DLL DeviceAPI {
 public:
  virtual ~DeviceAPI() {}
  virtual void SetDevice(TVMContext ctx) = 0;
  virtual void GetAttr(TVMContext ctx, DeviceAttrKind kind, TVMRetValue* rv) = 0;
  virtual void* AllocDataSpace(TVMContext ctx,
                               size_t nbytes,
                               size_t alignment,
                               TVMType type_hint) = 0;
  virtual void FreeDataSpace(TVMContext ctx, void* ptr) = 0;
  virtual void CopyDataFromTo(const void* from,
                              size_t from_offset,
                              void* to,
                              size_t to_offset,
                              size_t num_bytes,
                              TVMContext ctx_from,
                              TVMContext ctx_to,
                              TVMType type_hint,
                              TVMStreamHandle stream) = 0;
  virtual TVMStreamHandle CreateStream(TVMContext ctx);
  virtual void FreeStream(TVMContext ctx, TVMStreamHandle stream);
  virtual void StreamSync(TVMContext ctx, TVMStreamHandle stream) = 0;
  virtual void SetStream(TVMContext ctx, TVMStreamHandle stream) {}
  virtual void SyncStreamFromTo(TVMContext ctx,
                                        TVMStreamHandle event_src,
                                        TVMStreamHandle event_dst);
  virtual void* AllocWorkspace(TVMContext ctx,
                                       size_t nbytes,
                                       TVMType type_hint = {});
  virtual void FreeWorkspace(TVMContext ctx, void* ptr);
  static DeviceAPI* Get(TVMContext ctx, bool allow_missing = false);
};
```

### SetDevice

主要是处理device id， 对于cuda来讲，应该就是第几个板卡；对于cpu，这个接口并没有意义。

这个接口在整个runtime过程中没有地方进行主动调用，在cuda的实现中，对于deviceAPI的每个接口，里面都会调用自己的cudaSetDevice接口。

### GetAttr

根据传入的不同的DeviceAttrKind，返回不同的设备属性，cuda每一个库函数都要求传入device_id，这个接口在设计时感觉像基于cuda库进行的封装，命名上跟cuda很像。

在python class TVMContext(python/tvm/_ffi/runtime_ctypes.py)中封装了GetAttr的上层调用,在图编译和执行的流程中不会被调用

### AllocDataSpace

在device上申请内存空间

在runtime Init的时候，会调用该接口，在devie上为tensor分配空间

### FreeDataSpace

在c++ 类class NDArray 的析构函数里面会进行调用， NDArray里面包含了DLTensor

### CopyDataFromTo

实现了数据copy，支持host之间，device之间和host-device直接的数据copy

### CreateStream

只有cuda支持，实际上也没有找到在什么地方有调用

### AllocWorkspace

分配工作空间，内部实际上还是调用AllocDataSpace

什么情况下使用？
