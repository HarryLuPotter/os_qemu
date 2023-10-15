## Buddy System设计

> 学号：2111698	姓名：于泽林



### 概念

**Buddy System**是linux操作系统内核中使用的一种物理内存的管理算法，内核中会把内存按照页来组织分配，随着进程的对内存的申请和释放，系统的内存会不断的区域碎片化，到最后会发现，明明系统还有很多空闲内存，却无法分配出一块连续的内存，这对于系统来说并不是好事。而**Buddy System**算法就是为了缓解这种碎片化。它把系统中要管理的物理内存按照页面个数分为不同的组，分别对应大小不同的连续内存块，每组中的内存块大小都相等，为2的幂次个物理页。

### 设计思路

构建一个**空闲链表数组**来作为我们的主要数据结构。其中，数组的每一项存储着一个空闲链表头，指向一条空闲链表，每条链表将其所在数组下标所对应大小的空闲块链接起来（一条链表中的空闲块大小相同）。即，数组的第**i**个元素所指向的链表中，链接了所有大小为$2^i$个页的块。

### 代码分析

```
typedef struct
{
    unsigned int max_order;             //实际最高阶
    list_entry_t free_array[MAX_ORDER + 1]; //空闲块链表组成的数组
    unsigned int nr_free;               //本数据结构管理的空闲页的数量
} free_buddy_t;
```

上面展示的是管理空闲物理内存块的主要数据结构，里面最重要的部分就是**free_array**，称之为**空闲链表数组**



```
static bool is_power_of_2(size_t n)
{
    return !(n & (n - 1));
}


static unsigned int log2(size_t n)
{
    unsigned int order = 0;
    while (n > 1)
    {
        ++order;
        n >>= 1;
    }
    return order;
}


static size_t ROUNDDOWN_POWER_OF_2(size_t n)
{
    size_t ret = 1;
    while (n > 1)
    {
        ret <<= 1;
        n >>= 1;
    }
    return ret;
}


static size_t ROUNDUP_POWER_OF_2(size_t n)
{
    size_t ret = ROUNDDOWN_POWER_OF_2(n);
    return n == ret ? ret : (ret << 1);
}

static inline unsigned int page2idx(struct Page *page)
{
    return page - pages;
}
```

展示了一些简单的辅助函数，根据命令就可判断出每个函数的用途



```
static void buddy_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0);
    size_t pn = ROUNDDOWN_POWER_OF_2(n); //实际上要管理的页数
    max_order = log2(pn);       //对应阶数

    for (struct Page *p = base; p != base + pn; ++p)
    {
        assert(PageReserved(p));
        p->flags = 0;       //状态位置零
        p->property = 0;   //buddy system中的property代表当前头页管理的页数的阶数
        set_page_ref(p, 0); //引用位置零
    }

    nr_free = pn;
    base->property = max_order;
    SetPageProperty(base);  //base设置为头页
    list_add(&(free_array[max_order]), &(base->page_link));  //链入
}
```

由于伙伴系统只能管理页总数为2的幂大小的内存块，所以在本函数中首先需要对输入的参数进行对2的幂的向下取整，也就是说可能需要舍弃一部分物理内存。之后进行对实际管理的每个页初始化并且将头页链入链表数组的下标为**max_order**的位置，也即有意义的最高位，作为初始内存



```
static void buddy_split(size_t order)   //从阶数为order的空闲块中挑一个分裂
{
    assert(order > 0 && order <= max_order);

    if (list_empty(&(free_array[order])))   //当前order没有空闲块，递归
        buddy_split(order + 1);
    
    struct Page *page_left = le2page(list_next(&(free_array[order])), page_link);
    page_left->property -= 1;
    struct Page *page_right = page_left + (1 << (page_left->property));
    SetPageProperty(page_right);    //设为头页
    page_right->property = page_left->property;

    list_del(list_next(&(free_array[order])));
    list_add(&(free_array[order - 1]), &(page_left->page_link));
    list_add(&(page_left->page_link), &(page_right->page_link));
}

static struct Page* buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > nr_free) return NULL;

    struct Page *ret = NULL;    //要返回的指针
    size_t pn = ROUNDUP_POWER_OF_2(n);  //实际上要分配的页数
    unsigned int order = log2(pn);  //要分配的页数的阶数

    if (list_empty(&(free_array[order])))
        buddy_split(order + 1);

    ret = le2page(list_next(&(free_array[order])), page_link);
    list_del(list_next(&(free_array[order])));

    ClearPageProperty(ret);
    nr_free -= pn;
    return ret;
}
```

分配大小为n个页的内存时，同样应分配2的幂，也即pn。首先检查有无大小为pn的块，若无则调用**buddy_split**函数，从更大的块中分裂下来，递归调用直至找到要求的大小，之后执行分配操作。



```
static struct Page* get_buddy(struct Page *page)
{
    unsigned int order = page->property;
    unsigned int buddy_idx = page2idx(page) ^ (1 << order);
    return pages + buddy_idx;
}


static void buddy_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    unsigned int order = base->property;
    size_t pn = (1 << order);
    assert(pn == ROUNDUP_POWER_OF_2(n));

    struct Page* left_block = base;
    list_add(&(free_array[order]), &(left_block->page_link));   //把要释放的块先放入空表内

    struct Page* buddy = get_buddy(left_block);
    while (left_block->property < max_order && PageProperty(buddy)) //满足合并条件
    {
        if (left_block > buddy) //若left_block在右边，调换位置
        {
            struct Page* tmp = left_block;
            left_block = buddy;
            buddy = tmp;
        }

        list_del(&(left_block->page_link));
        list_del(&(buddy->page_link));
        left_block->property += 1;
        buddy->property = 0;
        SetPageProperty(left_block);
        ClearPageProperty(buddy);
    }

    nr_free += pn;
}
```

释放内存的操作需要有一个前置的知识点，即如何找到页数组中目标块的伙伴块的头页的下标。通过观察不难发现，对于大小为$2^{order}$的块及其伙伴块，两者的头页的下标二进制仅相差一个bit，就是编号为order的那个bit，所以采用异或的方式获得。故释放内存的步骤就是找到目标块的伙伴块，检查二者是否可以合并成一个大块，若可以则递归检查合并，直到不能合并或者已到达最大块为止。









