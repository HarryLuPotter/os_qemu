#include <buddySystem.h>
#include <list.h>
#include <string.h>
#include <pmm.h>

free_buddy_t free_buddy;

#define free_array (free_buddy.free_array)
#define nr_free (free_buddy.nr_free)
#define max_order (free_buddy.max_order)


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
    
static void buddy_init() //初始化free_buddy结构体
{
    max_order = 0;
    nr_free = 0;
    for (int i = 0; i < MAX_ORDER; ++i)
        list_init(free_array + i);
}


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


static size_t buddy_nr_free_pages()
{
    return nr_free;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    //list_entry_t free_list_store = free_list;
    // list_init(&free_list);
    // assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    // assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    //free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

const struct pmm_manager buddySystem = {
    .name = "buddySystem",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = basic_check,
};