# 多线程编程

## 使用std::thread实现多线程

c++11新引入的头文件，用来支持多线程编程。有atomic,thread,mutex,condition_variable

- thread 不能被copy构造

### 代码举例

```c++
std::function<void()> async_function = nullptr;
std::mutex async_mutex;
std::condition_variable async_cond;
bool async_running;
bool async_started = false;

std::thread *async_thread = new std::thread([this] {
    while (true) {
        std::unique_lock<std::mutex> lock(async_mutex);
        async_cond.wait(lock, [this] {
            return async_function || !async_running;
        });

        if (!async_running && !async_function)
            break;
        async_function();
        async_function = nullptr;
    }
});

void run_async(std::function<void()> func)
{
    {
        std::lock_guard<std::mutex> lock(async_mutex);
        async_started = true;
        async_function = func;
    }

    async_cond.notify_all();
}

bool async_done() {
    if (async_started) {
        if (async_function == nullptr) {
            async_started = false;
            return true;
        }
    }

    return false;
}
```

## 使用openmp实现多线程

OpenMP是一种用于共享内存并行系统的多线程程序设计方案，编译器根据程序中添加的pragma指令，自动将程序并行处理

编译制导指令以#pragma omp 开始，后面可以跟具体的指令

[具体的可以参考别人的博客](https://blog.csdn.net/u011808673/article/details/80319792)

## TBB

todo...据说这个流行？
