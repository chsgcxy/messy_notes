# runtime

[TOC]

runtime中的代码主要干了三件事情

- 初始化过程，解析graph，转换为内部数据结构，调用DeviceAPI，在device上分配内存空间
- 参数设置过程，将参数copy到分配好的device内存空间上
- 运行过程，遍历执行解析完的graph中的function

## runtime-flow

example tvm:build with target cuda and target host llvm

```plantuml
(split_dev_host_funcs) -> (fdevice)
(split_dev_host_funcs) -> (fhost)
(lowered_funcs) -> (split_dev_host_funcs) : tvm::build

(fdevice) --> (codegen.build_cuda)
rectangle "device code" {
    (CUDAModuleNode : runtime::ModuleNode) as CUDAModuleNode
    (codegen.build_cuda) --> CUDAModuleNode
}

(fhost) --> (codegen.build_llvm)
rectangle "host code" {
    (LLVMModuleNode : runtime::ModuleNode) as LLVMModuleNode
    (codegen.build_llvm) --> LLVMModuleNode
    LLVMModuleNode --> (TVMBackendGetFuncFromEnv)
    (TVMBackendGetFuncFromEnv) -> (TVMFuncCall)
}

CUDAModuleNode .left.> LLVMModuleNode: LLVMModuleNode.Import(CUDAModuleNode)
(TVMBackendGetFuncFromEnv) .up.> CUDAModuleNode: CUDAModuleNode.GetFunction
(TVMFuncCall) .> CUDAModuleNode: PackedFunc(CUDAWrappedFunc)
```

runtime work flow

```plantuml
rectangle greaph_runtime.creat {
    (根据python传入的ctx, 构建c++内部定义的TVMContext vector) as creat_step1
    note left
        从python/tvm/contrib/graph_runtime.py
        进入src/runtime/graph/graph_runtime.cc
    endnote

    (实例化第三方软件dmlc的JSONReader) as creat_step2
    note right
        dmlc(Distributed Machine Learning Common Codebase)
        分布式机器学习通用代码库,
        提供了构建高效且可扩展的分布式机器学习库的能力
        GraphRuntime 依赖于 JSONReader
    endnote

    (利用JSONReader将graph.json转化为内部数据结构, 完成load过程) as creat_step3

    (将graph的attrs_.dltype转换为TVMType) as creat_step4
    note left
        "attrs": {
            "dltype": [
                "list_str", 
                [
                    "float32", 
                    "float32",
                ]
            ],
    endnote

    (构建池节点pool_entry) as creat_step5
    note left
        bytes = dltype[i] * shape[i]
        从所有节点中给出每个storage_id对应的节点的bytes最大值
    endnote

    (每个storage_id对应的storage_pool_使用DeviceAPI AllocDataSpace) as creat_step6
    note right
        所有的target的实现都继承于DeviceAPI接口
        DeviceAPI 受 DeviceAPIManager 管理
        通过 "device_api." + target 的方式可以找到具体 DeviceAPI
        具体 DeviceAPI 通过 TVM_REGISTER_GLOBAL 进行注册
        具体 DeviceAPI 分布在 src/runtime 主目录及各个子目录下
    endnote

    (根据storage_pool_ 构建 data_entry_, 完成SetupStorage过程) as creat_step7

    (遍历graph中所有非‘null’节点，\n \
    构建DLTensor向量， \n \
    并且获取每一个node的func组成op_execs_向量) as creat_step8

    creat_step1 -right-> creat_step2
    creat_step2 -down-> creat_step3
    creat_step3 -left-> creat_step4
    creat_step4 -down-> creat_step5
    creat_step5 -right-> creat_step6
    creat_step6 -down-> creat_step7
    creat_step7 -left-> creat_step8

    (creat end) as ce
    creat_step8 --> ce
}

rectangle "tvm build result"{
    (Graph)
    note left
        a string of dict, similar to str({})
        "{
            "nodes": [
                {
                    "op": "null",
                    "name": "x",
                    "inputs": []
                },
                {
                    "op": "tvm_op",
                    "name": "relu0",
                    "attrs": {
                        "flatten_data": "0",
                        "func_name": "fuse_l2_normalize_relu",
                        "num_inputs": "1",
                        "num_outputs": "1"
                    },
                    "inputs": [[0, 0, 0]]  
                }
            ],
            "arg_nodes": [0],
            "node_row_ptr": [0, 1, 2],
            "heads": [[1, 0, 0]],
            ......
        }"
    endnote
    (Graph) ..> creat_step1

    (Lib)
    note left
        a Module object, contain lib.so
    endnote
    (Lib) ..> creat_step1

    (params)
    note left
        a dict contains node params ...
        {'p22': <tvm.NDArray shape=(8, 16, 3, 3, 8, 32), cpu(0)>
            array([[[[[[-2.49230769e-02,  2.73413258e-03, ...,
             7.61547452e-03, -6.19848166e-03, -2.52313819e-02],
           [ 2.66786274e-02,  4.06193052e-04,  5.14294626e-03, ...,
            -3.45390639e-03,  4.50841105e-03,  5.40218735e-03],
         ......
        }
    endnote
}

(ctx)
note left
    a object class TVMContext or a list of TVMContext
    tvm.cpu(0)
    tvm.gpu(0)
    tvm.opencl(0)
endnote
(ctx) ..> creat_step1

(GraphModule)
note right
    a wrapper of class GraphRuntime in c++
    本质上是一个Module实例，这个实例作为container包含了GraphRuntime实例
endnote
ce --> (GraphModule): return a object of GraphModule

(picture image data) as input_data

(调用set_input完成参数输入) as set_input
note right
    call by PackedFunc GraphRuntime::GetFunction from python to c++
    将输入数据copy到data_entry_对应的node里面
    如果输入参数是param，循环是在python侧完成的
    c++ 接口每次只接受一个node的数据
endnote
params ..> set_input
input_data ..> set_input
(GraphModule) --> set_input


(GraphModule.run) as run
note right
    so easy.............

    void GraphRuntime::Run() {
    // setup the array and requirements.
    for (size_t i = 0; i < op_execs_.size(); ++i) {
        if (op_execs_[i]) op_execs_[i]();
    }
    }
endnote
set_input --> run

(GraphModule.get_output) as get_output
note right
    从data_entry_中获取输出节点数据
    graph 中heads字段保存了输出note信息
    heads is a list of entries as the output of the graph.
    在Init阶段便解析到了GraphRuntime的outputs_字段中
endnote
run --> get_output
```

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

## Module

```plantuml
(host module\nclass tvm::runtime::Module) as hm
(device module\nclass tvm::runtime::Module) as dm

(param \n以graph中的node的name为key的参数字典) as param

(graph \n包含所有node的json表达) as graph

[device.so] --> dm

hm --> (runtime Init): input
dm <-- hm : call
(param) --> (runtime Init): input
(graph) --> (runtime Init): input
```

对于runtime输入Module来讲，它有很多子类，对应每一种target,除此之外RelayBuildModule和GraphRuntimeCodeGenModule也是module子类，其中RelayBuildModule是在relay前端之后创建的，实现在**relay.build_module._BuildModule**中,负责进行relay层build。==GraphRuntimeCodeGenModule这个子类的作用后续补充==

## graph

官方文档有比较明确的介绍，其中attr中的storage_id是在编译时创建的存储ID，一个storage_id对应一块内存，storage_id与Tensor是一对多的关系。

## param

a dict

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
