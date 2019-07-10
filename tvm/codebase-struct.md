# directory-structure

所有繁重代码都在ｃ++中实现，python是为了用户接口，但是c++也可以调用python里面的接口

- Look up an operator implementation by querying the operator registry
- Generate a compute expression and a schedule for the operator
- Compile the operator into object code

TVM defines the compiled object as Module. The user can get the compiled function from Module as PackedFunc

## 主目录结构

.  
├── conda  
├── golang  
├── include  
├── python **可以理解为软件前端，c++可以理解为软件后端，python实现了对c++代码的封装，可以控制编译流程**  
├── rust  
├── src **op编译相关的c++代码和runtime部署相关的c++代码**  
└── topi **op的实现在这里，包含的compute和schedule实现，实现支持c++和python**  

## 详细结构

### conda

├── conda  
│   ├── build_cpu.sh  
│   ├── build_cuda.sh  
│   ├── conda_build_config.yaml  
│   ├── cross-linux.cmake  
│   ├── Dockerfile.template  
│   ├── render_cuda.py  
│   ├── tvm  
│   └── tvm-libs  

### golang

├── golang  
│   ├── Makefile  
│   ├── sample  
│   └── src  

### include

├── include  
│   └── tvm  
│       ├── api_registry.h  
│       ├── arithmetic.h  
│       ├── attrs.h  
│       ├── base.h  
│       ├── buffer.h  
│       ├── build_module.h  
│       ├── c_dsl_api.h  
│       ├── channel.h  
│       ├── codegen.h  
│       ├── data_layout.h  
│       ├── expr.h  
│       ├── expr_operator.h  
│       ├── ir_functor_ext.h  
│       ├── ir.h  
│       ├── ir_mutator.h  
│       ├── ir_pass.h  
│       ├── ir_visitor.h  
│       ├── logging.h  
│       ├── lowered_func.h  
│       ├── operation.h  
│       ├── packed_func_ext.h  
│       ├── relay  
│       │   ├── adt.h  
│       │   ├── analysis.h  
│       │   ├── attrs  
│       │   │   ├── algorithm.h  
│       │   │   ├── annotation.h  
│       │   │   ├── debug.h  
│       │   │   ├── device_copy.h  
│       │   │   ├── image.h  
│       │   │   ├── nn.h  
│       │   │   ├── transform.h  
│       │   │   └── vision.h  
│       │   ├── base.h  
│       │   ├── error.h  
│       │   ├── expr_functor.h  
│       │   ├── expr.h  
│       │   ├── feature.h  
│       │   ├── interpreter.h  
│       │   ├── module.h  
│       │   ├── op_attr_types.h  
│       │   ├── op.h  
│       │   ├── pattern_functor.h  
│       │   ├── transform.h  
│       │   └── type.h  
│       ├── runtime  
│       │   ├── c_backend_api.h  
│       │   ├── c_runtime_api.h  
│       │   ├── device_api.h  
│       │   ├── module.h  
│       │   ├── ndarray.h  
│       │   ├── node_base.h  
│       │   ├── object.h  
│       │   ├── packed_func.h  
│       │   ├── registry.h  
│       │   ├── serializer.h  
│       │   ├── threading_backend.h  
│       │   ├── util.h  
│       │   └── vm.h  
│       ├── schedule.h  
│       ├── schedule_pass.h  
│       ├── target_info.h  
│       ├── tensor.h **对应tensor.cc的** <span id="tensor.h"> **头文件** </span>  
│       ├── tensor_intrin.h  
│       └── tvm.h  

### python

可以理解为软件前端，c++可以理解为软件后端，python实现了对c++代码的封装，可以控制编译流程

├── python  
│   └── tvm  
│       ├── _api_internal.py  
│       ├── api.py **生成tensor** [转到c++中实现](#api_lang.cc)  
│       ├── arith.py  
│       ├── attrs.py  
│       ├── autotvm  
│       │   ├── database.py  
│       │   ├── env.py  
│       │   ├── feature.py  
│       │   ├── graph_tuner  
│       │   │   ├── base_graph_tuner.py  
│       │   │   ├── _base.py  
│       │   │   ├── dynamic_programming_stage.py  
│       │   │   ├── dynamic_programming_tuner.py  
│       │   │   ├── __init__.py  
│       │   │   ├── pbqp_tuner.py  
│       │   │   └── utils  
│       │   │       ├── __init__.py  
│       │   │       ├── traverse_graph.py  
│       │   │       └── utils.py  
│       │   ├── __init__.py  
│       │   ├── measure  
│       │   │   ├── executor.py  
│       │   │   ├── __init__.py  
│       │   │   ├── local_executor.py  
│       │   │   ├── measure_methods.py  
│       │   │   ├── measure.py  
│       │   │   └── __pycache__  
│       │   ├── record.py  
│       │   ├── task  
│       │   │   ├── code_hash.py  
│       │   │   ├── dispatcher.py  
│       │   │   ├── __init__.py  
│       │   │   ├── nnvm_integration.py  
│       │   │   ├── relay_integration.py  
│       │   │   ├── space.py  
│       │   │   ├── task.py  
│       │   │   └── topi_integration.py  
│       │   ├── tophub.py  
│       │   ├── tuner  
│       │   │   ├── callback.py  
│       │   │   ├── ga_tuner.py  
│       │   │   ├── gridsearch_tuner.py  
│       │   │   ├── __init__.py  
│       │   │   ├── metric.py  
│       │   │   ├── model_based_tuner.py  
│       │   │   ├── sa_model_optimizer.py  
│       │   │   ├── tuner.py  
│       │   │   ├── xgboost_cost_model.py  
│       │   │   └── xgboost_tuner.py  
│       │   └── util.py  
│       ├── build_module.py **包含了tvm.build(),利用schedule,input tensor, output tensor, target 来生成tvm.module， 同时包含了tvm.lower(),这是build过程的第一步**  
│       ├── codegen.py  
│       ├── container.py  
│       ├── contrib  
│       │   ├── cblas.py  
│       │   ├── cc.py  
│       │   ├── clang.py  
│       │   ├── cublas.py  
│       │   ├── cudnn.py  
│       │   ├── debugger  
│       │   │   ├── debug_result.py  
│       │   │   ├── debug_runtime.py  
│       │   │   └── __init__.py  
│       │   ├── dlpack.py  
│       │   ├── download.py  
│       │   ├── emscripten.py  
│       │   ├── graph_runtime.py  
│       │   ├── __init__.py  
│       │   ├── miopen.py  
│       │   ├── mps.py  
│       │   ├── mxnet.py  
│       │   ├── ndk.py  
│       │   ├── nnpack.py  
│       │   ├── nvcc.py  
│       │   ├── peak.py  
│       │   ├── pickle_memoize.py  
│       │   ├── random.py  
│       │   ├── rocblas.py  
│       │   ├── rocm.py  
│       │   ├── rpc.py  
│       │   ├── sdaccel.py  
│       │   ├── sparse.py  
│       │   ├── spirv.py  
│       │   ├── tar.py  
│       │   ├── util.py  
│       │   ├── verilog.py  
│       │   └── xcode.py  
│       ├── datatype.py  
│       ├── error.py  
│       ├── exec  
│       │   ├── autotvm_log_editor.py  
│       │   ├── __init__.py  
│       │   ├── measure_peak.py  
│       │   ├── query_rpc_tracker.py  
│       │   ├── rpc_proxy.py  
│       │   ├── rpc_server.py  
│       │   └── rpc_tracker.py  
│       ├── expr.py  
│       ├── _ffi **在这里tvm实现了对python的包装**  
│       │   ├── base.py  
│       │   ├── _ctypes  
│       │   │   ├── function.py  
│       │   │   ├── __init__.py  
│       │   │   ├── ndarray.py  
│       │   │   ├── node.py  
│       │   │   └── types.py  
│       │   ├── function.py  
│       │   ├── __init__.py  
│       │   ├── libinfo.py  
│       │   ├── ndarray.py  
│       │   ├── node_generic.py  
│       │   ├── node.py  
│       │   └── runtime_ctypes.py  
│       ├── generic.py  
│       ├── hybrid  
│       │   ├── calls.py  
│       │   ├── __init__.py  
│       │   ├── module.py  
│       │   ├── parser.py  
│       │   ├── preprocessor.py  
│       │   ├── runtime.py  
│       │   └── util.py  
│       ├── __init__.py  
│       ├── intrin.py  
│       ├── ir_builder.py  
│       ├── ir_pass.py  
│       ├── make.py  
│       ├── module.py **实现了tvm.module的定义， module包含了一个编译好的func,可以使用函数调用语法进行调用**  
│       ├── ndarray.py  
│       ├── node.py  
│       ├── _pyversion.py  
│       ├── relay  
│       │   ├── adt.py  
│       │   ├── _analysis.py  
│       │   ├── analysis.py  
│       │   ├── annotation.py  
│       │   ├── backend  
│       │   │   ├── _backend.py  
│       │   │   ├── compile_engine.py  
│       │   │   ├── graph_runtime_codegen.py  
│       │   │   ├── __init__.py  
│       │   │   ├── interpreter.py  
│       │   │   ├── _vm.py  
│       │   │   └── vm.py  
│       │   ├── _base.py  
│       │   ├── base.py  
│       │   ├── _build_module.py  
│       │   ├── build_module.py  
│       │   ├── contrib.py  
│       │   ├── debug.py  
│       │   ├── expr_functor.py  
│       │   ├── _expr.py  
│       │   ├── expr.py  
│       │   ├── expr.pyi  
│       │   ├── feature.py  
│       │   ├── frontend  
│       │   │   ├── caffe2.py  
│       │   │   ├── common.py  
│       │   │   ├── coreml.py  
│       │   │   ├── darknet.py  
│       │   │   ├── __init__.py  
│       │   │   ├── keras.py  
│       │   │   ├── mxnet.py  
│       │   │   ├── nnvm_common.py  
│       │   │   ├── onnx.py  
│       │   │   ├── tensorflow_parser.py  
│       │   │   ├── tensorflow.py  
│       │   │   └── tflite.py  
│       │   ├── grammar  
│       │   │   ├── __init__.py  
│       │   │   ├── py3  
│       │   │   │   ├── Relay.interp  
│       │   │   │   ├── RelayLexer.interp  
│       │   │   │   ├── RelayLexer.py  
│       │   │   │   ├── RelayLexer.tokens  
│       │   │   │   ├── RelayParser.py  
│       │   │   │   ├── Relay.tokens  
│       │   │   │   └── RelayVisitor.py  
│       │   │   └── Relay.g4  
│       │   ├── image.py  
│       │   ├── __init__.py  
│       │   ├── _make.py  
│       │   ├── _module.py  
│       │   ├── module.py  
│       │   ├── _module.pyi  
│       │   ├── nn.py  
│       │   ├── op  
│       │   │   ├── _algorithm.py  
│       │   │   ├── algorithm.py  
│       │   │   ├── annotation  
│       │   │   │   ├── annotation.py  
│       │   │   │   ├── __init__.py  
│       │   │   │   └── _make.py  
│       │   │   ├── contrib  
│       │   │   │   ├── _contrib.py  
│       │   │   │   ├── contrib.py  
│       │   │   │   ├── __init__.py  
│       │   │   │   └── _make.py  
│       │   │   ├── image  
│       │   │   │   ├── _image.py  
│       │   │   │   ├── image.py  
│       │   │   │   ├── __init__.py  
│       │   │   │   └── _make.py  
│       │   │   ├── __init__.py  
│       │   │   ├── _make.py  
│       │   │   ├── nn  
│       │   │   │   ├── __init__.py  
│       │   │   │   ├── _make.py  
│       │   │   │   ├── _nn.py  
│       │   │   │   └── nn.py  
│       │   │   ├── op_attrs.py  
│       │   │   ├── op.py  
│       │   │   ├── _reduce.py  
│       │   │   ├── reduce.py  
│       │   │   ├── _tensor_grad.py  
│       │   │   ├── _tensor.py  
│       │   │   ├── tensor.py  
│       │   │   ├── _transform.py  
│       │   │   ├── transform.py  
│       │   │   └── vision  
│       │   │       ├── __init__.py  
│       │   │       ├── _make.py  
│       │   │       ├── multibox.py  
│       │   │       ├── nms.py  
│       │   │       ├── _rcnn.py  
│       │   │       ├── rcnn.py  
│       │   │       ├── _vision.py  
│       │   │       ├── _yolo.py  
│       │   │       └── yolo.py  
│       │   ├── param_dict.py  
│       │   ├── _parser.py  
│       │   ├── parser.py  
│       │   ├── prelude.py  
│       │   ├── prelude.rly  
│       │   ├── quantize  
│       │   │   ├── _annotate.py  
│       │   │   ├── __init__.py  
│       │   │   ├── _quantize.py  
│       │   │   └── quantize.py  
│       │   ├── scope_builder.py  
│       │   ├── _transform.py  
│       │   ├── transform.py  
│       │   ├── transform.pyi  
│       │   ├── ty.py  
│       │   ├── ty.pyi  
│       │   └── vision.py  
│       ├── rpc  
│       │   ├── base.py  
│       │   ├── client.py  
│       │   ├── __init__.py  
│       │   ├── proxy.py  
│       │   ├── server.py  
│       │   ├── tornado_util.py  
│       │   └── tracker.py  
│       ├── schedule.py **包含class schedule的定义，create_schedule通过node机制来实现c++类型到python类型的转换并返回一个schedule对象,c++中也有一个对应的schedule定义**  
│       ├── stmt.py  
│       ├── tag.py  
│       ├── target.py  
│       ├── tensor_intrin.py  
│       ├── tensor.py <span id="tensor.py"> **tensor的抽象，例如A = tvm.placeholder((n,), name='A')， A就是一个tensor， 也包含operation的抽象** </span> [tensor具体实现在c++中](#tensor.cc)  
│       └── testing.py  

### rust

├── rust  
│   ├── frontend  
│   ├── macros  
│   └── runtime

### src

├── src  
│   ├── api **c++对上层的接口，每个接口都可以在python端调用，均通过TVM_REGISTER_API进行注册， 在python端通过_api_internal.进行调用**  
│   │   ├── api_arith.cc  
│   │   ├── api_base.cc  
│   │   ├── api_codegen.cc  
│   │   ├── api_ir.cc  
│   │   ├── api_lang.cc <span id="api_lang.cc"> **包含创建tensor相关的api接口** </span>  
│   │   ├── api_pass.cc  
│   │   ├── api_schedule.cc  
│   │   ├── api_test.cc  
│   │   └── dsl_api.cc  
│   ├── arithmetic  
│   │   ├── analyzer.cc  
│   │   ├── bound_deducer.cc  
│   │   ├── canonical_simplify.cc  
│   │   ├── compute_expr.h  
│   │   ├── const_fold.h  
│   │   ├── const_int_bound.cc  
│   │   ├── detect_linear_equation.cc  
│   │   ├── domain_touched.cc  
│   │   ├── int_op_overflow.h  
│   │   ├── int_set.cc  
│   │   ├── int_set.h  
│   │   ├── modular_set.cc  
│   │   ├── pattern_match.h  
│   │   ├── rewrite_simplify.cc  
│   │   ├── rewrite_simplify.h  
│   │   └── stmt_simplify.cc  
│   ├── autotvm  
│   │   ├── feature_visitor.cc  
│   │   ├── feature_visitor.h  
│   │   ├── touch_extractor.cc  
│   │   └── touch_extractor.h  
│   ├── codegen  
│   │   ├── build_common.h  
│   │   ├── build_module.cc  
│   │   ├── codegen_aocl.cc  
│   │   ├── codegen.cc  
│   │   ├── codegen_c.cc  
│   │   ├── codegen_c.h  
│   │   ├── codegen_c_host.cc  
│   │   ├── codegen_c_host.h  
│   │   ├── codegen_cuda.cc  
│   │   ├── codegen_cuda.h  
│   │   ├── codegen_metal.cc  
│   │   ├── codegen_metal.h  
│   │   ├── codegen_opencl.cc  
│   │   ├── codegen_opencl.h  
│   │   ├── codegen_opengl.cc  
│   │   ├── codegen_opengl.h  
│   │   ├── codegen_source_base.cc  
│   │   ├── codegen_source_base.h  
│   │   ├── codegen_vhls.cc  
│   │   ├── codegen_vhls.h  
│   │   ├── datatype  
│   │   │   ├── registry.cc  
│   │   │   └── registry.h  
│   │   ├── intrin_rule_aocl.cc  
│   │   ├── intrin_rule.cc  
│   │   ├── intrin_rule_cuda.cc  
│   │   ├── intrin_rule.h  
│   │   ├── intrin_rule_metal.cc  
│   │   ├── intrin_rule_opencl.cc  
│   │   ├── intrin_rule_opengl.cc  
│   │   ├── intrin_rule_vhls.cc  
│   │   ├── llvm  
│   │   │   ├── codegen_amdgpu.cc  
│   │   │   ├── codegen_arm.cc  
│   │   │   ├── codegen_cpu.cc  
│   │   │   ├── codegen_cpu.h  
│   │   │   ├── codegen_llvm.cc  
│   │   │   ├── codegen_llvm.h  
│   │   │   ├── codegen_nvptx.cc  
│   │   │   ├── codegen_x86_64.cc  
│   │   │   ├── intrin_rule_llvm.cc  
│   │   │   ├── intrin_rule_llvm.h  
│   │   │   ├── intrin_rule_nvptx.cc  
│   │   │   ├── intrin_rule_rocm.cc  
│   │   │   ├── llvm_common.cc  
│   │   │   ├── llvm_common.h  
│   │   │   └── llvm_module.cc  
│   │   ├── opt  
│   │   │   ├── build_aocl_off.cc  
│   │   │   ├── build_cuda_off.cc  
│   │   │   ├── build_cuda_on.cc  
│   │   │   ├── build_metal_off.cc  
│   │   │   ├── build_opencl_off.cc  
│   │   │   ├── build_opengl_off.cc  
│   │   │   ├── build_rocm_off.cc  
│   │   │   ├── build_sdaccel_off.cc  
│   │   │   └── README  
│   │   ├── source_module.cc  
│   │   ├── spirv  
│   │   │   ├── build_vulkan.cc  
│   │   │   ├── codegen_spirv.cc  
│   │   │   ├── codegen_spirv.h  
│   │   │   ├── intrin_rule_spirv.cc  
│   │   │   ├── ir_builder.cc  
│   │   │   └── ir_builder.h 
│   │   └── stackvm  
│   │       ├── codegen_stackvm.cc  
│   │       └── codegen_stackvm.h  
│   ├── common  
│   │   ├── arena.h  
│   │   ├── base64.h  
│   │   ├── pipe.h  
│   │   ├── ring_buffer.h  
│   │   └── socket.h  
│   ├── contrib  
│   │   ├── cblas  
│   │   │   ├── cblas.cc  
│   │   │   └── gemm_common.h  
│   │   ├── cublas  
│   │   │   ├── cublas.cc  
│   │   │   ├── cublas_utils.cc  
│   │   │   └── cublas_utils.h  
│   │   ├── cudnn  
│   │   │   ├── conv_forward.cc  
│   │   │   ├── cudnn_utils.cc  
│   │   │   └── cudnn_utils.h  
│   │   ├── hybrid  
│   │   │   ├── codegen_hybrid.cc  
│   │   │   └── codegen_hybrid.h  
│   │   ├── miopen  
│   │   │   ├── conv_forward.cc  
│   │   │   ├── miopen_utils.cc  
│   │   │   └── miopen_utils.h  
│   │   ├── mps  
│   │   │   ├── conv.mm  
│   │   │   ├── gemm.mm  
│   │   │   ├── mps_utils.h  
│   │   │   └── mps_utils.mm  
│   │   ├── nnpack  
│   │   │   ├── convolution.cc  
│   │   │   ├── fully_connected.cc  
│   │   │   ├── nnpack_utils.cc  
│   │   │   └── nnpack_utils.h  
│   │   ├── random  
│   │   │   ├── mt_random_engine.cc  
│   │   │   ├── random.cc  
│   │   │   └── sgx_random_engine.cc  
│   │   ├── rocblas  
│   │   │   └── rocblas.cc  
│   │   └── sort  
│   │       └── sort.cc  
│   ├── lang  
│   │   ├── api_registry.cc  
│   │   ├── attr_functor.h  
│   │   ├── attrs.cc  
│   │   ├── buffer.cc  
│   │   ├── channel.cc  
│   │   ├── data_layout.cc  
│   │   ├── expr.cc  
│   │   ├── expr_operator.cc  
│   │   ├── ir.cc  
│   │   ├── lowered_func.cc  
│   │   ├── reflection.cc  
│   │   ├── target_info.cc  
│   │   └── tensor.cc  <span id="tensor.cc"> **tensor表达的实现** </span> [对应python中的tensor](#tensor.py) | [对应头文件](#tensor.h)  
│   ├── op  
│   │   ├── compute_op.cc  
│   │   ├── compute_op.h  
│   │   ├── cross_thread_reduction.cc  
│   │   ├── extern_op.cc  
│   │   ├── hybrid_op.cc  
│   │   ├── hybrid_op.h  
│   │   ├── op_util.cc  
│   │   ├── op_util.h  
│   │   ├── placeholder_op.cc  
│   │   ├── scan_op.cc  
│   │   ├── tensor_compute_op.cc  
│   │   └── tensorize.cc  
│   ├── pass  
│   │   ├── arg_binder.cc  
│   │   ├── arg_binder.h  
│   │   ├── bound_checker.cc  
│   │   ├── combine_context_call.cc  
│   │   ├── coproc_sync.cc  
│   │   ├── detect_device.cc  
│   │   ├── inject_copy_intrin.cc  
│   │   ├── inject_double_buffer.cc  
│   │   ├── inject_prefetch.cc  
│   │   ├── inject_virtual_thread.cc  
│   │   ├── inline.cc  
│   │   ├── ir_deep_compare.cc  
│   │   ├── ir_mutator.cc  
│   │   ├── ir_util.cc  
│   │   ├── ir_util.h  
│   │   ├── ir_visitor.cc  
│   │   ├── lift_attr_scope.cc  
│   │   ├── loop_partition.cc  
│   │   ├── lower_custom_datatypes.cc  
│   │   ├── lower_intrin.cc  
│   │   ├── lower_thread_allreduce.cc  
│   │   ├── lower_tvm_builtin.cc  
│   │   ├── lower_warp_memory.cc  
│   │   ├── make_api.cc  
│   │   ├── narrow_channel_access.cc  
│   │   ├── remap_thread_axis.cc  
│   │   ├── remove_no_op.cc  
│   │   ├── rewrite_unsafe_select.cc  
│   │   ├── simple_passes.cc  
│   │   ├── split_host_device.cc  
│   │   ├── split_pipeline.cc  
│   │   ├── ssa.cc  
│   │   ├── storage_access.cc  
│   │   ├── storage_access.h  
│   │   ├── storage_flatten.cc  
│   │   ├── storage_rewrite.cc  
│   │   ├── storage_sync.cc  
│   │   ├── unroll_loop.cc  
│   │   ├── vectorize_loop.cc  
│   │   ├── verify_gpu_code.cc  
│   │   └── verify_memory.cc  
│   ├── relay **管理计算图的组件（提供一种计算图的表达，即IR），计算图中的node使用src目录下的一些基础架构进行编译和执行**  
│   │   ├── backend  
│   │   │   ├── build_module.cc  
│   │   │   ├── compile_engine.cc  
│   │   │   ├── compile_engine.h  
│   │   │   ├── graph_plan_memory.cc  
│   │   │   ├── graph_runtime_codegen.cc  
│   │   │   ├── interpreter.cc  
│   │   │   ├── param_dict.cc  
│   │   │   ├── param_dict.h  
│   │   │   ├── utils.h  
│   │   │   └── vm  
│   │   │       ├── compiler.cc  
│   │   │       ├── inline_primitives.cc  
│   │   │       ├── lambda_lift.cc  
│   │   │       └── vm.cc  
│   │   ├── ir  
│   │   │   ├── adt.cc  
│   │   │   ├── alpha_equal.cc  
│   │   │   ├── base.cc  
│   │   │   ├── doc.cc  
│   │   │   ├── doc.h  
│   │   │   ├── error.cc  
│   │   │   ├── expr.cc  
│   │   │   ├── expr_functor.cc  
│   │   │   ├── hash.cc  
│   │   │   ├── module.cc  
│   │   │   ├── op.cc  
│   │   │   ├── pattern_functor.cc  
│   │   │   ├── pretty_printer.cc  
│   │   │   ├── type.cc  
│   │   │   ├── type_functor.cc  
│   │   │   └── type_functor.h  
│   │   ├── op  
│   │   │   ├── algorithm  
│   │   │   │   ├── argsort.cc  
│   │   │   │   └── topk.cc  
│   │   │   ├── annotation  
│   │   │   │   └── annotation.cc  
│   │   │   ├── debug.cc  
│   │   │   ├── device_copy.cc  
│   │   │   ├── image  
│   │   │   │   └── resize.cc  
│   │   │   ├── nn  
│   │   │   │   ├── convolution.cc  
│   │   │   │   ├── nn.cc  
│   │   │   │   ├── pad.cc  
│   │   │   │   ├── pooling.cc  
│   │   │   │   └── upsampling.cc  
│   │   │   ├── op_common.h  
│   │   │   ├── tensor  
│   │   │   │   ├── binary.cc  
│   │   │   │   ├── reduce.cc  
│   │   │   │   ├── transform.cc  
│   │   │   │   └── unary.cc  
│   │   │   ├── type_relations.cc  
│   │   │   ├── type_relations.h  
│   │   │   └── vision  
│   │   │       ├── multibox_op.cc  
│   │   │       ├── nms.cc  
│   │   │       ├── rcnn_op.cc  
│   │   │       └── yolo.cc  
│   │   └── pass  
│   │       ├── alter_op_layout.cc  
│   │       ├── alter_op_layout.h  
│   │       ├── canonicalize_cast.cc  
│   │       ├── canonicalize_ops.cc  
│   │       ├── combine_parallel_conv2d.cc  
│   │       ├── dead_code.cc  
│   │       ├── de_duplicate.cc  
│   │       ├── dependency_graph.cc  
│   │       ├── dependency_graph.h  
│   │       ├── device_annotation.cc  
│   │       ├── eliminate_common_subexpr.cc  
│   │       ├── eta_expand.cc  
│   │       ├── expr_subst.cc  
│   │       ├── expr_subst.h  
│   │       ├── feature.cc  
│   │       ├── fold_constant.cc  
│   │       ├── fold_scale_axis.cc  
│   │       ├── forward_rewrite.cc  
│   │       ├── fuse_ops.cc  
│   │       ├── gradient.cc  
│   │       ├── kind_check.cc  
│   │       ├── let_list.h  
│   │       ├── mac_count.cc  
│   │       ├── match_exhaustion.cc  
│   │       ├── partial_eval.cc  
│   │       ├── pass_manager.cc  
│   │       ├── pass_util.h  
│   │       ├── pattern_util.h  
│   │       ├── quantize.cc  
│   │       ├── quantize.h  
│   │       ├── simplify_inference.cc  
│   │       ├── to_a_normal_form.cc  
│   │       ├── to_cps.cc  
│   │       ├── to_graph_normal_form.cc  
│   │       ├── type_infer.cc  
│   │       ├── type_solver.cc  
│   │       ├── type_solver.h  
│   │       ├── util.cc  
│   │       └── well_formed.cc  
│   ├── runtime  
│   │   ├── builtin_fp16.cc  
│   │   ├── c_dsl_api.cc  
│   │   ├── cpu_device_api.cc  
│   │   ├── c_runtime_api.cc  
│   │   ├── cuda  
│   │   │   ├── cuda_common.h  
│   │   │   ├── cuda_device_api.cc  
│   │   │   ├── cuda_module.cc  
│   │   │   └── cuda_module.h  
│   │   ├── dsl_api.h  
│   │   ├── dso_module.cc  
│   │   ├── file_util.cc  
│   │   ├── file_util.h  
│   │   ├── graph  
│   │   │   ├── debug  
│   │   │   │   └── graph_runtime_debug.cc  
│   │   │   ├── graph_runtime.cc  
│   │   │   └── graph_runtime.h  
│   │   ├── meta_data.h  
│   │   ├── metal  
│   │   │   ├── metal_common.h  
│   │   │   ├── metal_device_api.mm  
│   │   │   ├── metal_module.h  
│   │   │   └── metal_module.mm  
│   │   ├── module.cc  
│   │   ├── module_util.cc  
│   │   ├── module_util.h  
│   │   ├── ndarray.cc  
│   │   ├── opencl  
│   │   │   ├── aocl  
│   │   │   │   ├── aocl_common.h  
│   │   │   │   ├── aocl_device_api.cc  
│   │   │   │   ├── aocl_module.cc  
│   │   │   │   └── aocl_module.h  
│   │   │   ├── opencl_common.h  
│   │   │   ├── opencl_device_api.cc  
│   │   │   ├── opencl_module.cc  
│   │   │   ├── opencl_module.h  
│   │   │   └── sdaccel  
│   │   │       ├── sdaccel_common.h  
│   │   │       ├── sdaccel_device_api.cc  
│   │   │       ├── sdaccel_module.cc  
│   │   │       └── sdaccel_module.h  
│   │   ├── opengl  
│   │   │   ├── opengl_common.h  
│   │   │   ├── opengl_device_api.cc  
│   │   │   ├── opengl_module.cc  
│   │   │   └── opengl_module.h  
│   │   ├── pack_args.h  
│   │   ├── registry.cc  
│   │   ├── rocm  
│   │   │   ├── rocm_common.h  
│   │   │   ├── rocm_device_api.cc  
│   │   │   ├── rocm_module.cc  
│   │   │   └── rocm_module.h  
│   │   ├── rpc  
│   │   │   ├── rpc_device_api.cc  
│   │   │   ├── rpc_event_impl.cc  
│   │   │   ├── rpc_module.cc  
│   │   │   ├── rpc_server_env.cc  
│   │   │   ├── rpc_session.cc  
│   │   │   ├── rpc_session.h  
│   │   │   └── rpc_socket_impl.cc  
│   │   ├── runtime_base.h  
│   │   ├── sgx  
│   │   │   ├── common.h  
│   │   │   ├── trusted  
│   │   │   │   ├── ecall_registry.h  
│   │   │   │   ├── runtime.cc  
│   │   │   │   ├── runtime.h  
│   │   │   │   └── threading_backend.cc  
│   │   │   ├── tvm.edl  
│   │   │   └── untrusted  
│   │   │       └── sgx_module.cc  
│   │   ├── stackvm  
│   │   │   ├── stackvm.cc  
│   │   │   ├── stackvm.h  
│   │   │   ├── stackvm_module.cc  
│   │   │   └── stackvm_module.h  
│   │   ├── system_lib_module.cc  
│   │   ├── threading_backend.cc  
│   │   ├── thread_pool.cc  
│   │   ├── thread_storage_scope.h  
│   │   ├── vm  
│   │   │   ├── memory_manager.cc  
│   │   │   ├── memory_manager.h  
│   │   │   ├── naive_allocator.h  
│   │   │   ├── object.cc  
│   │   │   ├── pooled_allocator.h  
│   │   │   └── vm.cc  
│   │   ├── vulkan  
│   │   │   ├── vulkan_common.h  
│   │   │   ├── vulkan_device_api.cc  
│   │   │   ├── vulkan_module.cc  
│   │   │   └── vulkan_module.h  
│   │   ├── workspace_pool.cc  
│   │   └── workspace_pool.h  
│   └── schedule  
│       ├── auto_inline_elem_wise.cc  
│       ├── bound.cc **bound实现，bound infrence是推断出所有循环边界和中间缓冲区大小的过程**  
│       ├── graph.cc **与bound有关**  
│       ├── graph.h  
│       ├── message_passing.cc **与bound有关**  
│       ├── message_passing.h  
│       ├── schedule_dataflow_rewrite.cc  
│       ├── schedule_lang.cc  
│       └── schedule_ops.cc **定义ScheduleOps(),返回stmt**  

### topi

├── topi  
│   ├── include  
│   │   └── topi  
│   │       ├── broadcast.h  
│   │       ├── contrib  
│   │       │   ├── cublas.h  
│   │       │   └── rocblas.h  
│   │       ├── cuda  
│   │       │   ├── dense.h  
│   │       │   ├── extern.h  
│   │       │   ├── injective.h  
│   │       │   ├── normalization.h  
│   │       │   ├── pooling.h  
│   │       │   ├── reduction.h  
│   │       │   └── softmax.h  
│   │       ├── detail  
│   │       │   ├── array_utils.h  
│   │       │   ├── broadcast.h  
│   │       │   ├── constant_utils.h  
│   │       │   ├── extern.h  
│   │       │   ├── fuse.h  
│   │       │   ├── pad_utils.h  
│   │       │   └── ravel_unravel.h  
│   │       ├── elemwise.h  
│   │       ├── generic  
│   │       │   ├── default.h  
│   │       │   ├── extern.h  
│   │       │   └── injective.h  
│   │       ├── image  
│   │       │   └── resize.h  
│   │       ├── nn  
│   │       │   ├── batch_matmul.h  
│   │       │   ├── bias_add.h  
│   │       │   ├── bnn.h  
│   │       │   ├── dense.h  
│   │       │   ├── dilate.h  
│   │       │   ├── flatten.h  
│   │       │   ├── l2_normalize.h  
│   │       │   ├── local_response_norm.h  
│   │       │   ├── mapping.h  
│   │       │   ├── pooling.h  
│   │       │   ├── softmax.h  
│   │       │   └── upsampling.h  
│   │       ├── nn.h  
│   │       ├── reduction.h  
│   │       ├── rocm  
│   │       │   ├── dense.h  
│   │       │   └── normalization.h  
│   │       ├── tags.h  
│   │       ├── transform.h  
│   │       ├── vision  
│   │       │   └── reorg.h  
│   │       └── x86  
│   │           ├── bnn.h  
│   │           ├── default.h  
│   │           └── injective.h  
│   ├── python  
│   │   ├── setup.py  
│   │   └── topi  
│   │       ├── arm_cpu  
│   │       │   ├── bitserial_conv2d.py  
│   │       │   ├── bitserial_dense.py  
│   │       │   ├── conv2d.py  
│   │       │   ├── conv2d_transpose.py  
│   │       │   ├── depthwise_conv2d.py  
│   │       │   ├── __init__.py  
│   │       │   └── injective.py  
│   │       ├── broadcast.py  
│   │       ├── cpp.py  
│   │       ├── cuda  
│   │       │   ├── batch_matmul.py  
│   │       │   ├── conv2d_direct.py  
│   │       │   ├── conv2d_hwcn.py  
│   │       │   ├── conv2d_int8.py  
│   │       │   ├── conv2d.py  
│   │       │   ├── conv2d_transpose_nchw.py  
│   │       │   ├── conv2d_winograd.py  
│   │       │   ├── deformable_conv2d.py  
│   │       │   ├── dense.py  
│   │       │   ├── depthwise_conv2d.py  
│   │       │   ├── extern.py  
│   │       │   ├── group_conv2d_nchw.py  
│   │       │   ├── __init__.py  
│   │       │   ├── injective.py  
│   │       │   ├── nms.py  
│   │       │   ├── nn.py  
│   │       │   ├── pooling.py  
│   │       │   ├── rcnn  
│   │       │   │   ├── __init__.py  
│   │       │   │   ├── proposal.py  
│   │       │   │   └── __pycache__  
│   │       │   ├── reduction.py  
│   │       │   ├── softmax.py  
│   │       │   ├── sort.py  
│   │       │   ├── ssd  
│   │       │   │   ├── __init__.py  
│   │       │   │   ├── multibox.py  
│   │       │   │   └── __pycache__  
│   │       │   ├── tensor_intrin.py  
│   │       │   └── vision.py  
│   │       ├── generic  
│   │       │   ├── extern.py  
│   │       │   ├── __init__.py  
│   │       │   ├── injective.py  
│   │       │   ├── nn.py  
│   │       │   ├── sort.py  
│   │       │   └── vision.py  
│   │       ├── generic_op_impl.py  
│   │       ├── hls  
│   │       │   ├── __init__.py  
│   │       │   ├── injective.py  
│   │       │   ├── nn.py  
│   │       │   └── __pycache__  
│   │       ├── image  
│   │       │   ├── __init__.py  
│   │       │   └── resize.py  
│   │       ├── __init__.py  
│   │       ├── intel_graphics  
│   │       │   ├── conv2d.py  
│   │       │   ├── __init__.py  
│   │       │   └── __pycache__  
│   │       ├── mali  
│   │       │   ├── conv2d.py  
│   │       │   ├── dense.py  
│   │       │   ├── depthwise_conv2d.py  
│   │       │   ├── __init__.py  
│   │       │   └── __pycache__  
│   │       ├── math.py  
│   │       ├── nn  
│   │       │   ├── batch_matmul.py  
│   │       │   ├── bitserial_conv2d.py  
│   │       │   ├── bitserial_dense.py  
│   │       │   ├── bitserial_util.py  
│   │       │   ├── bnn.py  
│   │       │   ├── conv2d.py  
│   │       │   ├── conv2d_transpose.py  
│   │       │   ├── deformable_conv2d.py  
│   │       │   ├── dense.py  
│   │       │   ├── depthwise_conv2d.py  
│   │       │   ├── dilate.py  
│   │       │   ├── elemwise.py  
│   │       │   ├── flatten.py  
│   │       │   ├── __init__.py  
│   │       │   ├── l2_normalize.py  
│   │       │   ├── local_response_norm.py  
│   │       │   ├── mapping.py  
│   │       │   ├── pad.py  
│   │       │   ├── pooling.py  
│   │       │   ├── softmax.py  
│   │       │   ├── upsampling.py  
│   │       │   └── util.py  
│   │       ├── opengl  
│   │       │   ├── conv2d_nchw.py  
│   │       │   ├── dense.py  
│   │       │   ├── __init__.py  
│   │       │   ├── injective.py  
│   │       │   ├── pooling.py  
│   │       │   └── softmax.py  
│   │       ├── reduction.py  
│   │       ├── rocm  
│   │       │   ├── conv2d.py  
│   │       │   ├── dense.py  
│   │       │   ├── __init__.py  
│   │       │   ├── nn.py  
│   │       │   └── __pycache__  
│   │       ├── sort.py  
│   │       ├── sparse  
│   │       │   ├── csrmm.py  
│   │       │   ├── csrmv.py  
│   │       │   ├── dense.py  
│   │       │   ├── __init__.py  
│   │       │   └── __pycache__  
│   │       ├── tag.py  
│   │       ├── tensor.py  
│   │       ├── testing  
│   │       │   ├── batch_matmul.py  
│   │       │   ├── bilinear_resize_python.py  
│   │       │   ├── conv2d_hwcn_python.py  
│   │       │   ├── conv2d_nchw_python.py  
│   │       │   ├── conv2d_nhwc_python.py  
│   │       │   ├── conv2d_transpose_nchw_python.py  
│   │       │   ├── deformable_conv2d_nchw_python.py  
│   │       │   ├── depthwise_conv2d_python.py  
│   │       │   ├── dilate_python.py  
│   │       │   ├── gather_nd_python.py  
│   │       │   ├── __init__.py  
│   │       │   ├── l2_normalize_python.py  
│   │       │   ├── lrn_python.py  
│   │       │   ├── reorg_python.py  
│   │       │   ├── roi_align_python.py  
│   │       │   ├── roi_pool_python.py  
│   │       │   ├── sequence_mask_python.py  
│   │       │   ├── slice_axis_python.py  
│   │       │   ├── softmax_python.py  
│   │       │   ├── strided_slice_python.py  
│   │       │   └── upsampling_python.py  
│   │       ├── transform.py  
│   │       ├── util.py  
│   │       ├── vision  
│   │       │   ├── __init__.py  
│   │       │   ├── nms.py  
│   │       │   ├── rcnn  
│   │       │   │   ├── __init__.py  
│   │       │   │   ├── proposal.py  
│   │       │   │   ├── roi_align.py  
│   │       │   │   └── roi_pool.py  
│   │       │   ├── reorg.py  
│   │       │   └── ssd  
│   │       │       ├── __init__.py  
│   │       │       ├── multibox.py  
│   │       │       └── __pycache__  
│   │       └── x86  
│   │           ├── batch_matmul.py  
│   │           ├── binarize_pack.py  
│   │           ├── binary_dense.py  
│   │           ├── bitserial_conv2d.py  
│   │           ├── bitserial_dense.py  
│   │           ├── check_targets.py  
│   │           ├── conv2d_avx_1x1.py  
│   │           ├── conv2d_avx_common.py  
│   │           ├── conv2d.py  
│   │           ├── dense.py  
│   │           ├── depthwise_conv2d.py  
│   │           ├── __init__.py  
│   │           ├── injective.py  
│   │           ├── nn.py  
│   │           ├── pooling.py  
│   │           ├── roi_align.py  
│   │           ├── tensor_intrin.py  
│   │           └── util.py  
│   ├── recipe  
│   │   ├── broadcast 
│   │   │   └── test_broadcast_map.py  
│   │   ├── conv  
│   │   │   ├── depthwise_conv2d_test.py  
│   │   │   ├── test_conv2d_hwcn_map.py  
│   │   │   └── test_conv_int8_intel.py  
│   │   ├── gemm  
│   │   │   ├── android_gemm_square.py  
│   │   │   ├── cuda_gemm_square.py  
│   │   │   └── gemm_int8.py  
│   │   ├── reduce  
│   │   │   └── test_reduce_map.py  
│   │   └── rnn  
│   │       ├── lstm.py  
│   │       └── matexp.py  
│   ├── src  
│   │   └── topi.cc  
│   └── tests  
