# RISCV原子操作

在宝华的《atomic实现原理》一文中提及了atomic(原子操作)的实现方式(其实他还是想说cache相关的东西), 但文中提到了几种通常的atomic实现方式

- 一种是bus lock，锁住总线，不让其他CPU进行内存操作，但这种方式破坏性比较大
- 一种是Cacheline Lock，借助多核cache一致性MESI协议

在看文章的时候，我想到了riscv的指令集扩展中，有atomic扩展，即原子操作指令扩展。那么就有了如下疑问

- RISCV指令集的A扩展是什么？目的是解决什么问题？目前处于什么开发状态？
- linux内核中对于RISCV的原子操作支持目前是什么样的？涉及到A扩展吗?

## RISCV的A扩展

> The standard atomic-instruction extension, named “A”, contains instructions that atomically read-modify-write memory to support synchronization between multiple RISC-V harts running in the same memory space.

很显然，RISCV的A扩展正是为了实现原子操作而设计的

> The two forms of atomic instruction provided are load-reserved/store-conditional instructions and atomic fetch-and-op memory instructions.

A扩展提供了两种形式的原子操作指令，一种load-reserved/store-conditional， 另一种fetch-and-op memory instructions

### load-reserved/store-conditional(加载保留/条件存储)

提供了LR.W/D 和 SC.W/D两组指令,LR指令从存储器读一个数值,同时处理器会监视这个存储器地址,看它是否会被其他处理器修改;
SC指令发现在此期间没有其他处理器修改这个值,则将新值写入该地址。因此一个原子的LR/SC指令对,就是LR读取值,进行一些计算,
然后试图保存新值。如果保存失败,那么需要重新开始整个序列。这样就保证了每一个处理器都能准确的执行完读改写流程

```asm
# a0 holds address of memory location
# a1 holds expected value
# a2 holds desired value
# a0 holds return value, 0 if successful, !0 otherwise
cas:
    lr.w t0, (a0) # Load original value.
    bne t0, a1, fail # Doesn’t match, so fail.
    sc.w t0, a2, (a0) # Try to update.
    bnez t0, cas # Retry if store-conditional failed.
    li a0, 0 # Set return to success.
    jr ra # Return.
fail:
    li a0, 1 # Set return to failure.
    jr ra # Return.
```

通过sc.w的返回值可以判定是否完成了原子操作，如果失败了，要从lr.w开始重新进行，在LR指令和SC指令之间执行的动态代码,只能
来自于基本“I”的子集,不能包括load指令、store指令、向后跳转指令或者向后的分支指令、FENCE指令、SYSTEM指令，且必须由不超
过16条整数指令的代码顺序存放在存储器中构成

通过spike的代码能够进一步理解spec中所谓的

> An SC instruction can never be observed by another RISC-V hart before the LR instruction that established the reservation.

```c++

// lr.w
require_extension('A');
auto res = MMU.load_int32(RS1, true);
MMU.acquire_load_reservation(RS1);
WRITE_RD(res);

// sc.w
require_extension('A');

bool have_reservation = MMU.check_load_reservation(RS1, 4);

if (have_reservation)
  MMU.store_uint32(RS1, RS2);

MMU.yield_load_reservation();

WRITE_RD(!have_reservation);
```

可以看出，lr.w会将当前要存储的地址记录在reservation中，在执行sc.w时，会检查之前的lr指令标记的reservation地址是否是sc指令要存储地址，如果是，那么执行存储操作，如果不是，那么跳过存储操作，复位该reservation地址，并返回失败。当然，spike只是一个功能模拟器，
它在同一时间其实只有一个CPU在执行指令，所以它在step函数中在切换CPU时处理reservation标记即可。

```c++
void sim_t::step(size_t n)
{
  for (size_t i = 0, steps = 0; i < n; i += steps)
  {
    steps = std::min(n - i, INTERLEAVE - current_step);
    procs[current_proc]->step(steps);

    current_step += steps;
    if (current_step == INTERLEAVE)
    {
      current_step = 0;
      procs[current_proc]->get_mmu()->yield_load_reservation();
      }
    }
  }
}
```

但其实已经能够看出，LR/SC不会锁住总线，能够更高效的处理并发访问。

### Atomic Memory Operations(AMO)

- AMOSWAP.W/D
- AMOADD.W/D
- AMOAND.W/D
- AMOOR.W/D
- AMOXOR.W/D
- AMOMAX[U].W/D
- AMOMIN[U].W/D

目前支持上述原子内存操作指令，来看一下spec中给出的用法，其中a0为锁所在地址

```asm
li t0, 1 # Initialize swap value.
again:
lw t1, (a0) # Check if lock is held.
bnez t1, again # Retry if held.
amoswap.w.aq t1, t0, (a0) # Attempt to acquire lock.
bnez t1, again # Retry if held.
# ...
# Critical section.
# ...
amoswap.w.rl x0, x0, (a0) # Release lock by storing 0.
```

#### 实现分析

举例amoadd.w来分析设计与实现

spike实现

```c++
#define amo_func(type) \
    template<typename op> \
    type##_t amo_##type(reg_t addr, op f) { \
      try { \
        auto lhs = load_##type(addr, true); \
        store_##type(addr, f(lhs)); \
        return lhs; \
      } catch (trap_load_address_misaligned& t) { \
        /* AMO faults should be reported as store faults */ \
        throw trap_store_address_misaligned(t.get_tval(), t.get_tval2(), t.get_tinst()); \
      } catch (trap_load_page_fault& t) { \
        /* AMO faults should be reported as store faults */ \
        throw trap_store_page_fault(t.get_tval(), t.get_tval2(), t.get_tinst()); \
      } catch (trap_load_access_fault& t) { \
        /* AMO faults should be reported as store faults */ \
        throw trap_store_access_fault(t.get_tval(), t.get_tval2(), t.get_tinst()); \
      } \
    }

amo_func(uint32)

// amoadd.w实现
require_extension('A');
WRITE_RD(sext32(MMU.amo_uint32(RS1, [&](uint32_t lhs) { return lhs + RS2; })));
```

我们可以看到，在spike中，直接将load和store组合起来实现了原子操作，这里spec的设计有些难以理解，
amoadd.w返回的rd是加法运算之前的内存中的值，而不是加法之后的结果，或许后续我能理解这样设计的目的吧，
现在总感觉是写错了。

riscv-test中的测试case实现

```asm
    li a0, 0xffffffff80000000;
    li a1, 0xfffffffffffff800;
    la a3, amo_operand;
    sd a0, 0(a3);
    amoadd.d a4, a1, 0(a3);
    li  x29, MASK_XLEN(0xffffffff80000000);
    bne a4, x29, fail;

    ld a5, 0(a3);
    li  x29, MASK_XLEN(0xffffffff7ffff800);
    bne a5, x29, fail;

    # try again after a cache miss
    amoadd.d a4, a1, 0(a3);
    li  x29, MASK_XLEN(0xffffffff7ffff800);
    bne a4, x29, fail;

    ld a5, 0(a3);
    li  x29, MASK_XLEN(0xffffffff7ffff000);
    bne a5, x29, fail;

  .bss
  .align 3
amo_operand:
  .dword 0
```

也是认为返回值为累加之前的内存值

## linux内核对于RISCV原子操作的支持

在最新的linux5.11版本中，很容易在arch/riscv/include/asm/atomic.h中找到内存原子操作

```c
/*
 * First, the atomic ops that have no ordering constraints and therefor don't
 * have the AQ or RL bits set.  These don't return anything, so there's only
 * one version to worry about.
 */
#define ATOMIC_OP(op, asm_op, I, asm_type, c_type, prefix)		\
static __always_inline							\
void atomic##prefix##_##op(c_type i, atomic##prefix##_t *v)		\
{									\
	__asm__ __volatile__ (						\
		"	amo" #asm_op "." #asm_type " zero, %1, %0"	\
		: "+A" (v->counter)					\
		: "r" (I)						\
		: "memory");						\
}									\

#ifdef CONFIG_GENERIC_ATOMIC64
#define ATOMIC_OPS(op, asm_op, I)					\
        ATOMIC_OP (op, asm_op, I, w, int,   )
#else
#define ATOMIC_OPS(op, asm_op, I)					\
        ATOMIC_OP (op, asm_op, I, w, int,   )				\
        ATOMIC_OP (op, asm_op, I, d, s64, 64)
#endif

ATOMIC_OPS(add, add,  i)
ATOMIC_OPS(sub, add, -i)
ATOMIC_OPS(and, and,  i)
ATOMIC_OPS( or,  or,  i)
ATOMIC_OPS(xor, xor,  i)
```
