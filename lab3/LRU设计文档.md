## LRU设计文档

### 概念

- 最久未使用(least recently used, LRU)算法：利用局部性，通过过去的访问情况预测未来的访问情况，我们可以认为最近还被访问过的页面将来被访问的可能性大，而很久没访问过的页面将来不太可能被访问。于是我们比较当前内存里的页面最近一次被访问的时间，把上一次访问时间离现在最久的页面置换出去。

### 设计思路与代码分析

核心函数如下所示，此函数被调用时，会遍历所有可交换页，若该页近期被访问过，则清除visited，否则加一

```
static int _lru_accessed_check(struct mm_struct *mm)
{
    cprintf("\nbegin accessed check----------------------------------\n");
    list_entry_t *head = (list_entry_t *)mm->sm_priv;   //头指针
    assert(head != NULL);
    list_entry_t *entry = head;
    while ((entry = list_prev(entry)) != head)
    {
        struct Page *entry_page = le2page(entry, pra_page_link);
        pte_t *tmp_pte = get_pte(mm->pgdir, entry_page->pra_vaddr, 0);
        cprintf("the ppn value of the pte of the vaddress is: 0x%x  \n", (*tmp_pte) >> 10);




        if (*tmp_pte & PTE_A)  //如果近期被访问过，visited清零(visited越大表示越长时间没被访问)
        {
            entry_page->visited = 0;
            *tmp_pte = *tmp_pte ^ PTE_A;//清除访问位
        }
        else
        {
            //未被访问就加一
            entry_page->visited++;
        }




        cprintf("the visited goes to %d\n", entry_page->visited);
    }
    cprintf("end accessed check------------------------------------\n\n");
}
```

下面函数用于选出被换出的页，同样遍历可交换页，维护一个最大的visited值和对应的list_entry，遍历结束后即可得到拥有最大visited值的page用于换出

```
static int _lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    _lru_accessed_check(mm);
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    
    list_entry_t *entry = list_prev(head);
    list_entry_t *pTobeDel = entry;
    uint_t largest_visted = le2page(entry, pra_page_link)->visited;     //最长时间未被访问的page，比较的是visited
    while (1)
    {
        //entry转一圈，遍历结束
        // 遍历找到最大的visited，表示最早被访问的
        if (entry == head)
        {
            break;
        }
        if (le2page(entry, pra_page_link)->visited > largest_visted)
        {
            largest_visted = le2page(entry, pra_page_link)->visited;
            // le2page(entry, pra_page_link)->visited = 0;
            pTobeDel = entry;
            // curr_ptr = entry;
        }
        entry = list_prev(entry);
    }



    list_del(pTobeDel);
    *ptr_page = le2page(pTobeDel, pra_page_link);
    cprintf("curr_ptr %p\n", pTobeDel);
    return 0;
}
```

### 测试结果

![image-20231029172940336](./src_typora/image-20231029172940336.png)