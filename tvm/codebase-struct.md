# directory-structure

<!-- TOC -->
- [directory-structure](#directory-structure)
  - [主目录结构](#主目录结构)
  - [详细结构](#详细结构)
    - [python](#python)
    - [src](#src)
    - [topi](#topi)
<!-- /TOC -->

所有复杂代码都在ｃ++中实现，python是为了用户接口，但是c++也可以调用python里面的接口

## 主目录结构

├── ***3rdparty*** 第三方软件库，其中一些以git submodule的形式包含， 包括 HalideIR, rang, dlpack等一些开源软件  
├── ***apps*** 包含了一些基于TVM的扩展项目，也作为如何使用tvm的例程  
├── ***cmake*** tvm编译用的cmake  
├── ***conda*** conda是一个开源的软件包管理系统和环境管理系统，用于安装多个版本的软件包及其依赖关系，并在它们之间轻松切换,这里实现了tvm的安装的包装，使得tvm安装更加方便  
├── ***docker*** 基于docker的tvm快速部署，包含了一系列的dockerfile和安装脚本，能够根据dockerfile直接生成相应的镜像，省去了安装依赖环境的烦恼  
├── ***docs*** 基于rst的文档，和官网的doc是一样的  
├── ***golang*** tvm runtime的golang接口  
├── ***include*** src 目录下的cc文件对应的头文件  
├── ***jvm*** tvm runtime的java接口  
├── ***nnvm*** nnvm实现，我们使用relay  
├── ***python*** 可以理解为软件前端，c++可以理解为软件后端，python实现了对c++代码的封装，可以控制编译流程  
├── ***rust*** Rust是一门系统编程语言，专注于安全，尤其是并发安全，支持函数式和命令式以及泛型等编程范式的多范式语言,放在tvm中不知道是要做什么，似乎是不影响我们了解tvm的编译过程  
├── ***src*** op编译相关的c++代码和runtime部署相关的c++代码  
├── ***tests*** 应该是测试相关的  
├── ***topi*** op的实现在这里，包含的compute和schedule实现，实现支持c++和python  
├── ***tutorials*** 一些demo  
├── ***vta*** versatile tensor accelerator
└── ***web*** This folder contains TVM WebAssembly and Javascript backend through Emscripten  

## 详细结构

### python

可以理解为软件前端，c++可以理解为软件后端，python实现了对c++代码的封装，可以控制编译流程

├── python  
│   └── tvm  
│       ├── _api_internal.py  
│       ├── api.py **生成tensor** [转到c++中实现](#api_lang.cc)  
│       ├── arith.py  
│       ├── attrs.py  
│       ├── autotvm  
│       ├── build_module.py **包含了tvm.build(),利用schedule,input tensor, output tensor, target 来生成tvm.module， 同时包含了tvm.lower(),这是build过程的第一步**  
│       ├── codegen.py  
│       ├── container.py  
│       ├── ***contrib*** 一些非核心特性的API，类似于一个小工具库，其中包含一些对第三方工具的包装  
│       ├── datatype.py  
│       ├── error.py  
│       ├── exec  
│       ├── expr.py  
│       ├── _ffi **在这里tvm实现了对python的包装**  
│       ├── generic.py  
│       ├── hybrid  
│       ├── __init__.py  
│       ├── intrin.py  
│       ├── ir_builder.py  
│       ├── ir_pass.py  
│       ├── make.py  
│       ├── module.py **实现了tvm.module的定义， module包含了一个编译好的func,可以使用函数调用语法进行调用**  
│       ├── **ndarray.py** 实现了NDarray类，但实际上文件的大多数method与ctx有关，用于创建不同的ctx实例，估计后续会有命名优化
│       ├── node.py  
│       ├── _pyversion.py  
│       ├── relay  
│       │   ├── ***backend***  
│       │   ├── _base.py  
│       │   ├── base.py  
│       │   ├── _build_module.py  
│       │   ├── **build_module.py** relay 的build入口
│       │   ├── contrib.py  
│       │   ├── debug.py  
│       │   ├── expr_functor.py  
│       │   ├── _expr.py  
│       │   ├── **expr.py**  The expression nodes of Relay 以及各种各样的expr  
│       │   ├── expr.pyi  
│       │   ├── feature.py  
│       │   ├── ***frontend*** relay前端，包含tensorflow, caffe, mxnet 等网络  
│       │   ├── grammar  
│       │   ├── image.py  
│       │   ├── __init__.py  
│       │   ├── _make.py  
│       │   ├── _module.py  
│       │   ├── module.py  
│       │   ├── _module.pyi  
│       │   ├── nn.py  
│       │   ├── ***op***  
│       │   ├── param_dict.py  
│       │   ├── _parser.py  
│       │   ├── parser.py  
│       │   ├── prelude.py  
│       │   ├── prelude.rly  
│       │   ├── quantize  
│       │   ├── scope_builder.py  
│       │   ├── _transform.py  
│       │   ├── transform.py  
│       │   ├── transform.pyi  
│       │   ├── ty.py  
│       │   ├── ty.pyi  
│       │   └── vision.py  
│       ├── ***rpc***  
│       ├── schedule.py **包含class schedule的定义，create_schedule通过node机制来实现c++类型到python类型的转换并返回一个schedule对象,c++中也有一个对应的schedule定义**  
│       ├── stmt.py  
│       ├── tag.py  
│       ├── target.py  
│       ├── tensor_intrin.py  
│       ├── tensor.py <span id="tensor.py"> **tensor的抽象，例如A = tvm.placeholder((n,), name='A')， A就是一个tensor， 也包含operation的抽象** </span> [tensor具体实现在c++中](#tensor.cc)  
│       └── testing.py  

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
│   │   ├── ***cuda*** cuda runtime 接口实现  
│   │   ├── dsl_api.h  
│   │   ├── dso_module.cc  
│   │   ├── file_util.cc  
│   │   ├── file_util.h  
│   │   ├── ***graph***  
│   │   ├── meta_data.h  
│   │   ├── ***metal***  
│   │   ├── module.cc  
│   │   ├── module_util.cc  
│   │   ├── module_util.h  
│   │   ├── ndarray.cc  
│   │   ├── ***opencl*** opencl runtime 接口实现  
│   │   ├── ***opengl*** opengl runtime 接口实现
│   │   ├── **pack_func.h**  PackedFunc 定义与实现
│   │   ├── **registry.cc** PackedFunc 相关
│   │   ├── ***rocm*** rocm runtime 接口实现
│   │   ├── ***rpc*** rpc runtime接口实现  
│   │   ├── runtime_base.h  
│   │   ├── ***sgx***  
│   │   ├── ***stackvm***  
│   │   ├── system_lib_module.cc  
│   │   ├── threading_backend.cc  
│   │   ├── thread_pool.cc  
│   │   ├── thread_storage_scope.h  
│   │   ├── ***vm***  
│   │   ├── ***vulkan***  
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
