# Linux的同步和互斥机制

在面对需要同步和互斥机制的场景时，只有熟练掌握linux提供的同步和互斥机制，才能灵活运用，举一反三。

- 自旋锁(spin lock)
- 互斥量(mutex)
- 信号量(semaphore)
- 读写锁(read-write lock)

下面就逐一进行分析

## 自旋锁

在驱动开发中，经常会用到自旋锁。自旋锁在等锁的时候，会一直轮询，而不会睡眠当前线程，所以它经常用在
需要在中断上下文(不能进行sleep)进行数据保护的场景。所谓自旋，就是轮询，会持续占有CPU，因此临界区的处理
应该越简洁越好。只要等待的代价低于调度的代价，那就赚了。

代码结构上，横向来看，spinlock的实现分为SMP和UP两个大分支，每个分支下根据是否是debug又有所不同。纵向来看，
包含架构无关的API层以及架构相关的arch层。

![spinlock文件关系](../imgs/spinlock_files.png)

arm的spinlock宝华老师以及众多网友已经分析的很透彻了，这里插入相关文档，以供自己后续回顾

https://blog.csdn.net/zhoutaopower/article/details/86598839

https://blog.csdn.net/21cnbao/article/details/108091149

因为近期RISCV接触的比较多，所以干脆分析一下RISCV的spinlock实现吧

riscv的smp对于arch_spin_lock的定义如下，并没有arm那样的owner和next，只有一个lock。

```c
typedef struct {
    volatile unsigned int lock;
} arch_spinlock_t;
```

在 arch/riscv/include/asm/spinlock.h 中实现了底层的spinlock方法

```c
static inline int arch_spin_trylock(arch_spinlock_t *lock)
{
    int tmp = 1, busy;

    __asm__ __volatile__ (
        "   amoswap.w %0, %2, %1\n"
        RISCV_ACQUIRE_BARRIER
        : "=r" (busy), "+A" (lock->lock)
        : "r" (tmp)
        : "memory");

    return !busy;
}

static inline void arch_spin_lock(arch_spinlock_t *lock)
{
    while (1) {
        if (arch_spin_is_locked(lock))
            continue;

        if (arch_spin_trylock(lock))
            break;
    }
}
```

在riscv原子指令集扩展一篇中，已经熟悉了amoswap.w是原子内存操作指令,其中指令格式为amoswap.w rd, rs2, (rs1),
实际上通过原子交换操作来确保lock标志完整写入内存。
