# TopK 算法

TopK是指从arr[n]中找出最大的K个数

## 算法一 排序

将N个数排序之后，取出最大的K个数。假设10个数的数组，从中找出top3,可以有如下做法

```
import random
arr=[random.randint(1,20) for x in range(10)]
arr.sort()
arr[-3:]
```

时间复杂度O(n * lg(n)),明明只需要topK,但对全局都进行了排序，因此这个方法的复杂度很高。通过局部的排序，仅对K个元素进行排序，可以缩小复杂度，使复杂度变成O(n * k)

## 算法二 堆

堆(heap)是一种满足特定条件的完全二叉树，主要可分为两种类型

- 大顶堆(max heap): 任意节点的值 ≥ 其子节点的值
- 小顶堆(min heap)：任意节点的值 ≤ 其子节点的值

堆作为完全二叉树的一个特例，具有以下特性:

- 最底层节点靠左填充，其他层的节点都被填满。
- 我们将二叉树的根节点称为“堆顶”，将底层最靠右的节点称为“堆底”。
- 对于大顶堆（小顶堆），堆顶元素（即根节点）的值分别是最大（最小）的。

堆是一种完全二叉树，完全二叉树非常适合用数组来表示。当使用数组来表示完全二叉树时，元素代表节点值，索引代表节点在二叉树中的位置。给定索引 𝑖 ，其左子节点索引为 2𝑖 + 1 ，右子节点索引为 2𝑖 + 2 ，父节点索引为 (𝑖 − 1)/2
（向下取整）。当索引越界时，表示空节点或节点不存在。

需求是找到TopK, 这K个元素实际上是不需要排序的，因此采取这K个值不排序的方法能够进一步降低复杂度。用arr的前K个元素生成一个小顶堆，用来存储当前最大的K个元素。堆的大小是不变的，只需要对堆顶元素进行替换操作，然后从顶至底进行堆化。从arr的第K+1一个元素开始，遍历arr中的每一个元素，如果元素大于堆顶，就替换堆顶元素，调整堆，以保证堆内的K个元素，总是当前最大的K个元素。

```c++

#define HEAP_LEFT(i)   (2 * i + 1)
#define HEAP_RIGHT(i)  (2 * i + 2)
#define HEAP_PARENT(i) ((i-1) >> 1)

template <typename T>
void heapify(T arr[], int len, int start)
{
    int child = HEAP_LEFT(start);
    int right = HEAP_RIGHT(start);
    while (child < len) {
        if (right < len && arr[right] < arr[child]) {
            child = right;
        }

        if (arr[child] < arr[start]) {
            swap<T>(&arr[child], &arr[idx]);
            start = child;
            child = HEAP_LEFT(start);
        } else {
            break;
        }
    }
}

template<typename T>
void topK(T arr[], int k, int n)
{
    T heap[k];
    memcpy(heap, arr, sizeof(T) * k);
    for (int i = k / 2 - 1; i >= 0; --i) {
        heapify<T>(heap, k, i);
    }
    for (int i = k; i < n; ++i) {
        if (heap[0] < arr[i]) {
            heap[0] = arr[i];
            heapify<T>(heap, k, 0);
        }
    }
}    
    
```

## 算法三 分治法

与快速排序相类似, TopK是希望求出arr[n]中最大的k个数, 如果找到了第k大的数, 做一次partition, 就能找到没有排序的最大的K个数。

与排序不同的是, 这里按照大到小排序, 做完一次partition:

- 如果i大于k, 则说明arr[i]左边的元素都大于k, 于是只递归arr[1, i-1]里第k大的元素即可
- 如果i小于k, 则说明说明第k大的元素在arr[i]的右边, 于是只递归arr[i+1, n]里第k-i大的元素即可

这样就能找到第K大的元素, 然后再做一次partition, 就能找到最大的K个元素。

## 后记

文中涉及的算法均可在 [github.com/krahets/hello‑algo](github.com/krahets/hello‑algo) 中找到详细解释
