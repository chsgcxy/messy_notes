# tvm

[TOC]

## Concept

### Module

一个编译好的对象。可以通过Module以PackedFunc的形式来获取编译后的Func。runtime可以动态获取Func

### Pass

### Op

### Tensor

### Func

## PackedFunc

tvm使用c++实现了一堆接口，这些接口通过PackedFunc封装，使得python调用c++非常easy.

```plantuml
class Registry {
    {field} -std::string name_;
    {field} -PackedFunc func_;
    {field} +struct Manager;

    {method} +TVM_DLL Registry& set_body(PackedFunc f);
    {method} +Registry& set_body(PackedFunc::FType f);
    {method} +TVM_DLL static Registry& Register(const std::string& name, bool override = false);
    {method} +TVM_DLL static const PackedFunc* Get(const std::string& name);
}

class PackedFunc {
    {field} -FType body_;

    +using FType = std::function<void (TVMArgs args, TVMRetValue* rv)>;

    {method} +explicit PackedFunc(FType body) : body_(body) {}
    {method} +template<typename... Args> 
    inline TVMRetValue operator()(Args&& ...args) const;
    {method} +inline void CallPacked(TVMArgs args, TVMRetValue* rv) const;
}

class manager {
    {field} +std::unordered_map<std::string, Registry*> fmap;
    {method} +static Manager* Global();
}

Registry --> PackedFunc
Registry --> manager
```

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

**_LIB**是直接以CDLL的方式加载了libtvm.so动态链接库

python/tvm/_ffi/base.py

```python
def _load_lib():
    """Load libary by searching possible path."""
    lib_path = libinfo.find_lib_path()
    lib = ctypes.CDLL(lib_path[0], ctypes.RTLD_GLOBAL)
    # DMatrix functions
    lib.TVMGetLastError.restype = ctypes.c_char_p
    return lib, os.path.basename(lib_path[0])

# version number
__version__ = libinfo.__version__
# library instance of nnvm
_LIB, _LIB_NAME = _load_lib()
```

编译和部署都用到了PackedFunc

- All TVM’s compiler pass functions are exposed to frontend as PackedFunc, see here
- The compiled module also returns the compiled function as PackedFunc

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

```plantuml
(relay python frontend) as rpf
note right
    @目录 python/tvm/relay/frontend/
end note

rectangle model-formats {
    (MXNet) -down-> rpf: relay.frontend.from_mxnet
    (TensorFlow) -down->rpf: relay.frontend.from_tensorflow
    (CoreML) -down->rpf: relay.frontend.from_coreml
    (ONNX) -down->rpf: relay.frontend.from_onnx
    (***) -down->rpf: relay.frontend.from_***
}

rpf -down-> (mod): output
note left
    @包含了funcs的全局的relay module
    @目录 python/tvm/relay/module.py
    @是对src/relay/目录下的一些接口的封装
    @module 本质上也是一个node
    @每一个global func 都通过一个唯一的
    tvm.relay.GlobalVar来区别
end note

rpf -down-> (params): output
note left
    @dict of str to NDArray
     Input parameters to the graph
     that do not change during inference time.
    @Used for constant folding.
end note

(mod) -down-> (func): mod[mod.entry_func]
note left
    @A function declaration expression
    @python/tvm/relay/expr.py
    @继承于Expr, Expr 是RelayNode的子类
end note

(relay.build) as rb
(target) as target
note right 
    {"aocl", "aocl_sw_emu", "c",
    "cuda", "ext_dev", "hybrid",
    "llvm", "metal", "nvptx", "opencl",
    "opengl", "rocm", "sdaccel",
    "stackvm", "vulkan"}
end note

target -left-> rb: input
(target_host) as th
note left: can be:cuda
th -> rb: input
(func) -down-> rb: input
(params) -down-> rb: input

rb -down-> (graph): output
rb -down-> (lib): output
rb -down-> (-params): output

(graph_runtime.create) as grc
(graph) -down-> grc: input
(lib) -down-> grc: input
(ctx: tvm.cpu0) -> grc: input

grc -down-> (runtime): output
(runtime.setinput) as rs
(-params) -down-> rs: input
(image data) -down-> rs: input
(runtime) -down-> rs: runtime method
(runtime.run) as rr
(runtime.getoutput) as rg
rs -> rr: runtime method
rr -> rg: runtime method
```

```plantuml
(python/tvm/relay/build_module.py\n\n build) as ptrbb
rectangle input {
    entity func
    entity target
    entity target_host
    entity params
}
func .down-> ptrbb: input
target .down-> ptrbb: input
target_host .down-> ptrbb: input
params .down-> ptrbb: input

(python/tvm/relay/build_module.py\n\n BuildModule.build) as bmb
(src/relay/backend/build_module.cc\n\n RelayBuildModule.SetParam) as rbmsp
(src/relay/backend/build_module.cc\n\n RelayBuildModule.Build) as rbmb
(src/relay/backend/build_module.cc\n\n RelayBuildModule.BuildRelay) as rbmbr
ptrbb -right-> bmb: func, target, target_host, params
bmb -right-> rbmsp: params
rbmsp -down-> rbmb: func, target, target_host
rbmb -left-> rbmbr: in RelayBuildModule

(src/relay/backend/build_module.cc\n\n RelayBuildModule.BindParamsByName) as rbmbpbn
(src/relay/backend/build_module.cc\n\n RelayBuildModule.Optimize) as rbmo
(relay::ModuleNode::FromExpr creat a relay::module) as rmfe
rbmbr -left-> rbmbpbn: func, params
rbmbpbn -down-> rmfe: func
rmfe -right-> rbmo: "relay::Module, target, params"

(src/relay/backend/build_module.cc\n\n new a GraphCodegen) as nag
rbmo -right-> nag

(src/relay/backend/graph_runtime_codegen.cc\n\n GraphRuntimeCodegenModule.init) as grcmi
(src/relay/backend/graph_runtime_codegen.cc\n\n GraphRuntimeCodegenModule.codegen) as grcmc
nag -down-> grcmi: target
grcmi -left-> grcmc: func

(src/codegen/build_module.cc\n\n tvm::build) as tb
rectangle output {
    entity "graph" as graph
    entity "new params" as np
    entity "mod" as mod
}
grcmc .down-> graph: output
grcmc .down-> np: output
grcmc -left-> tb: LowerFunc, target_host
tb .down-> mod: output
```

### build过程

#### relay前端

```python
# tvm/tutorials/frontend/from_mxnet.py
def from_mxnet(symbol,
               shape=None,
               dtype="float32",
               arg_params=None,
               aux_params=None):
    mod = _module.Module()
    func = _from_mxnet_impl(symbol, shape, dtype, mod)
    mod["main"] = func
    return mod, params
```

Module是一个python类，通过register_relay_node注册到了一个python全局的node字典中。

```python
# python/tvm/relay/module.py
@register_relay_node
class Module(RelayNode):
    def __init__(self, functions=None, type_definitions=None):
        self.__init_handle_by_constructor__(_make.Module, functions, type_definitions)
```

_make.Module是获取了c++实现的一个Module构建方法。_init_api将c++中的global_func按照模块动态组成了python中各个模块的方法。_init_api 主要调用了_init_api_prefix来实现功能，其中get_global_func返回了一个Function实例，
Function继承于FunctionBase，其中实现了__call__方法，所以Python中module类的方法中可以通过类似_module.Module_ContainGlobalVar(self, var)的操作来实现对c++的调用

```python
# python/tvm/relay/_make.py
_init_api("relay._make", __name__)

# python/tvm/_ffi/function.py
def _init_api_prefix(module_name, prefix):
    for name in list_global_func_names():
        f = get_global_func(name)
        ff = _get_api(f)
        ff.__name__ = fname
        setattr(target_module, ff.__name__, ff)

def get_global_func(name, allow_missing=False):
    handle = FunctionHandle()
    check_call(_LIB.TVMFuncGetGlobal(c_str(name), ctypes.byref(handle)))
    if handle.value:
        return Function(handle, False)

class Function(_FunctionBase):

class FunctionBase(object):
    def __call__(self, *args):
        if _LIB.TVMFuncCall(
                self.handle, values, tcodes, ctypes.c_int(num_args),
                ctypes.byref(ret_val), ctypes.byref(ret_tcode)) != 0:
            raise get_last_ffi_error()
        return RETURN_SWITCH[ret_tcode.value](ret_val)
```

c++中的接口通过TVM_REGISTER_API进行注册,其中ModuleNode::make返回了Module实例

```c++
// src/relay/ir/module.cc
TVM_REGISTER_API("relay._make.Module")
.set_body_typed(ModuleNode::make);

Module ModuleNode::make(tvm::Map<GlobalVar, Function> global_funcs,
                        tvm::Map<GlobalTypeVar, TypeData> global_type_defs)
```

self.__init_handle_by_constructor__最终通过_LIB.TVMFuncCall完成真正的c++函数执行，这个调用是不是很熟悉？对的，在FunctionBase的__call__方法中也是这样实现的PackedFunc的由Python到c++的调用

其中RETURN_SWITCH是一个字典，实现了c++变量类型到python变量类型的转换

```python
# python/tvm/_ffi/_ctypes/function.py
def __init_handle_by_constructor__(fconstructor, args):
    if _LIB.TVMFuncCall(
            fconstructor.handle, values, tcodes, ctypes.c_int(num_args),
            ctypes.byref(ret_val), ctypes.byref(ret_tcode)) != 0:
        return RETURN_SWITCH[ret_tcode.value](ret_val)

RETURN_SWITCH[TypeCode.FUNC_HANDLE] = _handle_return_func
RETURN_SWITCH[TypeCode.MODULE_HANDLE] = _return_module

# python/tvm/_ffi/_ctypes/types.py
RETURN_SWITCH = {
    TypeCode.INT: lambda x: x.v_int64,
    TypeCode.FLOAT: lambda x: x.v_float64,
    TypeCode.HANDLE: _return_handle,
    TypeCode.NULL: lambda x: None,
    TypeCode.STR: lambda x: py_str(x.v_str),
    TypeCode.BYTES: _return_bytes,
    TypeCode.TVM_CONTEXT: _return_context
}
```


#### 转换原始graph为exper

创建完成modudle实例之后，_from_mxnet_impl 遍历了原始graph的node, 根据op名称的不同，填充不同的expr实例到node_map
并且把最终输出节点对应的Function实例返回，module实例的'main'节点安装为该func

```python
# python/tvm/relay/frontend/mxnet.py
def _from_mxnet_impl(symbol, shape_dict, dtype_info, mod=None):
    jgraph = json.loads(symbol.tojson())
    jnodes = jgraph["nodes"]
    node_map = {}

    for nid, node in enumerate(jnodes):
        if op_name == "null":
            node_map[nid] = [_expr.var(node_name, shape=shape, dtype=dtype)]
        elif op_name in _convert_map:
            res = _convert_map[op_name](children, attrs)
    outputs = [node_map[e[0]][e[1]] for e in jgraph["heads"]]
    func = _expr.Function(analysis.free_vars(outputs), outputs)
    return func
```

其中_convert_map是relay 的 mxnet前端准备好的一个字典，记录着每个op对应的relay的表达。null node代表占位/变量或者输入节点，被实例化为Var(A local variable in Relay)

```python
# python/tvm/relay/expr.py
@register_relay_node
class Var(Expr):
    def __init__(self, name_hint, type_annotation=None):
        self.__init_handle_by_constructor__(
            _make.Var, name_hint, type_annotation)

class Expr(RelayNode):
    def __call__(self, *args):
        return Call(self, args)

@register_relay_node
class Call(Expr):
    def __init__(self, op, args, attrs=None, type_args=None):
        if not type_args:
            type_args = []
        self.__init_handle_by_constructor__(
            _make.Call, op, args, attrs, type_args)

```

#### Relay层Build

通过调用 relay.build_module._BuildModule 创建RelayBuildModule，该函数返回一个c++的Module类实例，
在python端转换该实例为Pthon Module类实例（_init_api()接口中会进行处理）

```c++
// src/relay/backend/build_module.cc
runtime::Module RelayBuildCreate() {
  std::shared_ptr<RelayBuildModule> exec = std::make_shared<RelayBuildModule>();
  return runtime::Module(exec);
}
```

```python
# python/tvm/module.py
_init_api("tvm.module")
_set_class_module(Module)
```

python中 class Module对应于c++中的class Module, ModuleBase 提供了__getitem__方法，可以使得
module[func_string] 能够调用到c++中的ModuleNode对应的function.

```python
# python/tvm/module.py
class Module(ModuleBase):

# python/tvm/_ffi/function.py
class ModuleBase(object):
    def get_function(self, name, query_imports=False):
        ret_handle = FunctionHandle()
        check_call(_LIB.TVMModGetFunction(
            self.handle, c_str(name),
            ctypes.c_int(query_imports),
            ctypes.byref(ret_handle)))
        return Function(ret_handle, False)
    def __getitem__(self, name):
        if not isinstance(name, string_types):
            raise ValueError("Can only take string as function name")
        return self.get_function(name)
```

在c++中，module的GetFunction实际上会调用ModuleNode的GetFunction

```c++
// src/runtime/c_runtime_api.cc
int TVMModGetFunction(TVMModuleHandle mod,
                      const char* func_name,
                      int query_imports,
                      TVMFunctionHandle *func) {
    PackedFunc pf = static_cast<Module*>(mod)->GetFunction(
        func_name, query_imports != 0);
    *func = new PackedFunc(pf);
}

// include/tvm/runtime/packed_func.h
inline PackedFunc Module::GetFunction(const std::string& name, bool query_imports) {
    PackedFunc pf = node_->GetFunction(name, node_);
    return pf;
}
```

可以参考如下类图

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

这样，在python中调用self.mod["build"]，则真正执行了c++中的RelayBuildModule的build功能

```python
# python/tvm/relay/build_module.py
class BuildModule(object):
    def __init__(self):
        self.mod = _build_module._BuildModule()
        self._build = self.mod["build"]
    def build(self, func, target=None, target_host=None, params=None):
        self._build(func, target, target_host)
```

RelayBuildModule 的 build, 必须要注意的是，***Module*** 和 ***ModuleNode*** 存在于多个命名空间中，要注意区分，这里返回的是包含 **runtime::ModuleNode** 的 **runtime::Module**

```c++
class RelayBuildModule : public runtime::ModuleNode {
    PackedFunc GetFunction(const std::string& name,
                            const std::shared_ptr<ModuleNode>& sptr_to_self) final {
        if (name == "build") {
            return PackedFunc([sptr_to_self, this](TVMArgs args, TVMRetValue* rv) {
                this->Build(args[0], args[1], args[2]);
            });
        }
    }
}
```

## codebase-structure-overview

[跳转到软件目录结构](./codebase-struct.md)
