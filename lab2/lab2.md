# Lab2:物理内存和页表



## 练习1：理解first-fit 连续物理内存分配算法（思考题）

>first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合 kern/mm/default_pmm.c 中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相
>关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
>- 你的first fit算法是否有进一步的改进空间？

以下依次对default_init，default_init_memmap，default_alloc_pages， default_free_pages等函数进行分析.

- default_init

  以下是default_init函数相关的代码:

  ```c
  free_area_t free_area;
  
  #define free_list (free_area.free_list)
  #define nr_free (free_area.nr_free)
  
  static void
  default_init(void) {
      list_init(&free_list);
      nr_free = 0; // 空闲页面的数量
  }
  ```

  我们跳转到结构体`free_area_t`的定义处，发现其作用是维护一个双向链表来记录空闲的页面，其中`free_list`用于存储该链表的头部，`nr_free`用于记录该链表中空闲页面的数量。

  ```c
  /* free_area_t - maintains a doubly linked list to record free (unused) pages */
  typedef struct {
      list_entry_t free_list;         // the list header
      unsigned int nr_free;           // number of free pages in this free list
  } free_area_t;
  ```

  据此可以认识到，default_init函数用于初始化一个双向链表来记录空闲的页面，并将空闲页总数`nr_free`初始化为0。

- default_init_memmap

  这段代码主要分为两部分,我们逐段进行分析.

  - 第一部分是
  
    ```c
  	  assert(n > 0); // 确保传入的页面数量是有效的
  	  struct Page *p = base;
  	  for (; p != base + n; p ++) {
  		  assert(PageReserved(p)); // 确保本页不是保留页
  		  p->flags = p->property = 0;
  		  set_page_ref(p, 0); // 将页面的引用计数设置为0
  	  }
  	  base->property = n; // base块内空闲的页数设为n
  	  SetPageProperty(base); // 将base标记为首页
  	  nr_free += n; // 新增了n个可用的物理页面
    ```
  
    其作用是初始化一个物理内存块。
  
    在这段代码中，`base`指向这段物理内存块的起始地址，`n`表示页面的数量。循环遍历这些页面，对每个页面执行以下操作：
  
    1. 使用`assert`宏定义检查页面是否是保留页面，如果不是保留页面，说明传入的页面不是空闲页面，会触发断言错误。
  
    2. `flags`和`property`是`Page`结构体中的两个成员，`flags`用于存储页面的状态标志，置为0标记有效，`property`用于记录页内空闲块的数量。
  
    3. 将页面的引用计数清零，表示当前没有任何进程使用该页面。
  
    随后,将`base`页面的属性标记设置为`n`，表示这一段物理页面是连续的，并且共有`n`个页面。
  
    使用`SetPageProperty`宏定义将`base`标记为首页。实际上是对PG_property进行了一个置1操作。
    
    ```c
    #define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))
    ```
    
    定义PG_property处有一段说明
    
    ```c
    #define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.
    ```
	  
	  即，如果一页的该位为1，则对应页应是一个空闲块的块首页；若为0，则对应页要么是一个已分配块的块首页，要么不是块中首页。
	  
	- 第二部分是
	
	  ```c
	  	if (list_empty(&free_list)) { // 判断链表free_list是否为空
	          // 如果为空，说明当前链表中没有可用的页面，直接将base页面添加到链表中
	          list_add(&free_list, &(base->page_link));
	      } else {
	          list_entry_t* le = &free_list;
	          while ((le = list_next(le)) != &free_list) {
                // 将链表节点le转换为struct Page类型的指针
	              struct Page* page = le2page(le, page_link);
                // 链表中的页面是按照地址从小到大排序的,如果base小于page,说明找到了插入位置
	              if (base < page) {
                    list_add_before(le, &(base->page_link));
	                  break;
                } else if (list_next(le) == &free_list) {
	                  // 如果已经遍历到了最后一个节点,则将base页面添加到链表末尾
                    list_add(le, &(base->page_link));
	              }
            }
	      }
    ```
	
    其作用是通过遍历链表，将第一部分中初始化的空闲块插入链表，并确保链表中的页面按照地址从小到大排序。
  
    首先是一个条件语句，判断链表`free_list`是否为空。如果为空，说明当前链表中没有可用的页面，直接将`base`页面添加到链表中。
  
    如果链表不为空，进入一个循环，遍历链表中的每个节点。在每次迭代中，将当前节点转换为`struct Page`类型的指针`page`，然后比较`base`和`page`的地址。
  
    如果`base`小于`page`，说明找到了插入位置，使用`list_add_before`函数将`base`页面插入到当前节点的前面。
  
    如果`base`不小于`page`，继续判断当前节点是否是链表中的最后一个节点。如果是最后一个节点，说明`base`应该插入到链表的末尾，使用`list_add`函数将`base`页面添加到链表中。
  
- default_alloc_pages
  
  以下是default_alloc_pages相关代码
  
  ```c
  static struct Page *
  default_alloc_pages(size_t n) {
      assert(n > 0);
      if (n > nr_free) { // 如果n大于空闲页面的数量,无法进行分配
          return NULL;
      }
      struct Page *page = NULL;
      list_entry_t *le = &free_list; // 指向空闲页链表头结点的指针
      while ((le = list_next(le)) != &free_list) {
          struct Page *p = le2page(le, page_link);
          if (p->property >= n) { // 块内空闲页足够进行分配
              page = p;
              break;
          }
      }
      // 找到了满足条件的页面,进行页面分配
      if (page != NULL) {
          list_entry_t* prev = list_prev(&(page->page_link));
          list_del(&(page->page_link)); // 从链表中删除该page
          if (page->property > n) { // 还有剩余的空闲页
              struct Page *p = page + n;
              p->property = page->property - n; // 设置p的剩余空闲页数
              SetPageProperty(p); // 将p标记为首页
              list_add(prev, &(p->page_link)); // 将剩余的空闲页插入到prev后,放回链表
          }
          nr_free -= n; // 总空闲页数减n
          ClearPageProperty(page); // 将page页面的property属性清零
      }
      return page;
  }
  ```
  
  这段代码通过遍历链表,找到链表中第一个块内空闲页数大于n的块,然后进行页面分配.
  
  代码逻辑如下：
  
  1. 首先，代码对输入的页面数量进行了断言，确保要分配的页面数量大于0。
  
  2. 然后，代码判断如果要分配的页面数量大于当前空闲页面的数量（`nr_free`），则返回NULL，表示无法分配足够的页面。
  
  3. 接下来，代码定义了一个指向页面的指针`page`，并初始化为NULL。同时，定义了一个指向空闲页面链表的指针`le`，初始化为指向空闲页面链表头节点。
  
  4. 进入循环，代码通过遍历空闲页面链表，找到第一个满足要求的页面。具体地，通过`list_next`函数遍历链表，将遍历到的节点转换为`Page`结构体指针`p`，然后判断该页面的`property`属性是否大于等于要分配的页面数量`n`。如果满足条件，则将`page`指针指向该页面，并跳出循环。
  
  5. 如果找到了满足要求的页面（即page不为NULL），则进行页面分配的操作：
  
     - 首先，通过`list_prev`函数找到`page`页面在链表中的前一个节点，并将其保存在`prev`指针中。
  
     - 然后，通过`list_del`函数将`page`页面从链表中删除。
  
     - 接着，判断page页面的property属性是否大于要分配的页面数量n
  
       如果大于，则表示该页面还有剩余的空闲页面，需要将剩余的页面添加回链表中：
  
       - 创建一个指向剩余页面的指针`p`，通过将`page`指针加上要分配的页面数量`n`得到。
       - 将`p`页面的`property`属性设置为剩余页面的数量。
       - 通过`SetPageProperty`函数将`p`页面设置为头页面。
       - 通过`list_add`函数将`p`页面插入到链表中`prev`节点的后面。
  
     - 最后，更新空闲页面数量`nr_free`，减去分配的页面数量`n`。
  
     - 通过`ClearPageProperty`函数将`page`页面的`property`属性清零。
  
  6. 返回分配的页面指针`page`。
  
- default_free_pages
  
  以下是default_free_pages相关代码
  
  ```c
  static void
  default_free_pages(struct Page *base, size_t n) {
      assert(n > 0);
      struct Page *p = base;
      for (; p != base + n; p ++) {
          assert(!PageReserved(p) && !PageProperty(p)); // 确认是已分配或已占用的页
          p->flags = 0; // 标记为可用状态
          set_page_ref(p, 0); // 引用计数清零
      }
      base->property = n; // 块内空闲页数设为n
      SetPageProperty(base); // base标记为首页
      nr_free += n; // 总空闲页数加n
  
      // 将空闲块插入链表中
      if (list_empty(&free_list)) {
          list_add(&free_list, &(base->page_link));
      } else {
          list_entry_t* le = &free_list;
          while ((le = list_next(le)) != &free_list) {
              struct Page* page = le2page(le, page_link);
              if (base < page) {
                  list_add_before(le, &(base->page_link));
                  break;
              } else if (list_next(le) == &free_list) {
                  list_add(le, &(base->page_link));
              }
          }
      }
  	// 检查base的前一个页面是否与其相邻，如果是，则将它们合并为一个连续的空闲页面，并将前一个页面从链表中删除
      list_entry_t* le = list_prev(&(base->page_link)); // 插入位置的前一个节点
      if (le != &free_list) { // 插入位置不是头节点
          p = le2page(le, page_link); // 转为page结构体指针
          if (p + p->property == base) { // 判断base与前一个page之间的页面是否空闲
              p->property += base->property; // 合并空闲页面数量
              ClearPageProperty(base); // 将base页面的空闲页面清零
              list_del(&(base->page_link)); // 从链表中删除base页面的节点
              base = p; // 将base页面的指针更新为前一个页面的指针p
          }
      }
  
      // 检查base的后一个页面是否与其相邻，如果是，则将它们合并为一个连续的空闲页面，并将后一个页面从链表中删除
      le = list_next(&(base->page_link));
      if (le != &free_list) {
          p = le2page(le, page_link);
          if (base + base->property == p) {
              base->property += p->property;
              ClearPageProperty(p);
              list_del(&(p->page_link));
          }
      }
  }
  ```
  
  这段代码的作用是将一段连续的页面标记为空闲页面，并将其添加到空闲页面链表中。它还实现了对相邻的空闲页面的合并。
  
  函数的实现过程如下：
  
  1. 首先，对输入参数进行检查，确保页面数量`n`大于0。
  2. 然后，使用一个循环遍历这段页面数组，对每个页面进行如下操作：
     - 检查页面是否为保留页面或头页面，如果是则断言失败。
     - 将页面的标志位清零，将页面的引用计数设置为0。
  3. 将这段页面的第一个页面`base`标记为一个空闲页面的头页面，将其`property`属性设置为页面数量`n`，并将其添加到空闲页面链表中。
  4. 如果空闲页面链表为空，则将`base`添加到链表中。
  5. 如果空闲页面链表不为空，则遍历链表中的每个页面，找到`base`应该插入的位置，并将其插入到链表中。
  6. 检查`base`的前一个页面是否与其相邻，如果是，则将它们合并为一个连续的空闲页面，并将前一个页面从链表中删除。
  7. 检查`base`的后一个页面是否与其相邻，如果是，则将它们合并为一个连续的空闲页面，并将后一个页面从链表中删除。
  
- 对于以上实现的first fit算法,可能的改进空间包括:
  
  1. 使用更高效的数据结构：当前实现中使用了一个简单的双向链表来存储空闲页面。如果空闲页面数量很大，可以考虑使用其他更高效的数据结构，如红黑树、跳表等，以提高查找和删除的效率。
  2. 优化合并操作：当前实现中的合并操作是一次只合并相邻的两个页面。可以考虑优化合并操作，例如一次性合并多个相邻的页面，以减少遍历链表的次数。
  
  
  

## 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

>在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
>请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
>
>- 你的 Best-Fit 算法是否有进一步的改进空间？

- best_fit_init_memmap用于初始化一个内存块

  首先通过遍历,将每一页的标志和属性信息都设为0,同时将引用计数设为0,代码如下.

  ```c
  for (; p != base + n; p ++) {
          assert(PageReserved(p));
  
          /*LAB2 EXERCISE 2: YOUR CODE*/ 
          // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
          p->flags = p->property = 0;
          set_page_ref(p, 0);
      }
  ```

  随后将初始化的内存块插入链表中,当链表不为空时,需要找到第一个大于base的页，将base插入到它前面;如果找不到,则在尾部插入.代码如下

  ```c
  		while ((le = list_next(le)) != &free_list) {
              struct Page* page = le2page(le, page_link);
               /*LAB2 EXERCISE 2: YOUR CODE*/ 
              // 编写代码
              // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
              // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
              if (base < page)
              {
                  list_add_before(le, &(base->page_link));
                  break;
              }
              else if (list_next(le) == &free_list)
              {
                  list_add(le, &(base->page_link));
              }
          }
  ```

- best_fit_alloc_pages

  我们使用`min_size`变量来记录当前找到的最小连续空闲页框数量。在遍历空闲链表时，我们首先判断当前页面是否满足需求，并且其连续空闲页框数量是否小于`min_size`。如果满足这两个条件，则更新`best_fit_page`为当前页面，并更新`min_size`为当前连续空闲页框数量。

  最后，我们将找到的最佳适配页面从空闲链表中删除，并进行合并操作，如果合并后剩余的空闲页框数量大于需求页框数量，则将剩余页面添加回空闲链表中。代码如下

  ```c
  	/*LAB2 EXERCISE 2: YOUR CODE*/ 
      // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
      // 遍历空闲链表，查找满足需求的空闲页框
      // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
      while ((le = list_next(le)) != &free_list)
      {
          struct Page *p = le2page(le, page_link);
          if (p->property >= n && p->property < min_size)
          {
              page = p;
              min_size = p->property; // 找到了比min_size还小的页面,更新min_size的值
          }
      }
  
      if (page != NULL) {
          list_entry_t* prev = list_prev(&(page->page_link));
          list_del(&(page->page_link));
          if (page->property > n) {
              struct Page *p = page + n;
              p->property = page->property - n;
              SetPageProperty(p);
              list_add(prev, &(p->page_link));
          }
          nr_free -= n;
          ClearPageProperty(page);
      }
  ```

- best_fit_free_pages  

  将块内页面的标志清零,引用数清零后,设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值.代码如下
  
  ```c
  /*LAB2 EXERCISE 2: YOUR CODE*/ 
      // 编写代码
      // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
      base->property = n;
      SetPageProperty(base);
      nr_free += n;
  ```
  
  在将释放的页块加入链表后,将base与前一个页面是否与其相邻，如果是，则将它们合并为一个连续的空闲页面，并将前一个页面从链表中删除.代码如下
  
  ```c
  list_entry_t* le = list_prev(&(base->page_link));
      if (le != &free_list) {
          p = le2page(le, page_link);
          /*LAB2 EXERCISE 2: YOUR CODE*/ 
           // 编写代码
          // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
          // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
          // 3、清除当前页块的属性标记，表示不再是空闲页块
          // 4、从链表中删除当前页块
          // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
          if (p + p->property == base) {
              p->property += base->property;
              ClearPageProperty(base);
              list_del(&(base->page_link));
              base = p;
          }
      }
  ```
  
- 对于以上实现的first fit算法,可能的改进空间包括:
  
  1. 使用更高效的数据结构：当前实现中使用了一个简单的双向链表来存储空闲页面。如果空闲页面数量很大，可以考虑使用其他更高效的数据结构，如红黑树、跳表等，以提高查找和删除的效率。
  2. 优化合并操作：当前实现中的合并操作是一次只合并相邻的两个页面。可以考虑优化合并操作，例如一次性合并多个相邻的页面，以减少遍历链表的次数。
  





- 知识点

    - 实验中与os课程对应的知识点

    1. 为确保内存管理修改相关数据时不被中断打断，提供两个功能，通常需要将sstatus寄存器的状态位SIE保存下来并且屏蔽中断的功能
    2. 机制和策略，操作系统在管理内存时所采取的一系列机制，包括内存分配，页面置换等，策略则是选择具体的算法来实现，这些策略和算法的选择会影响操作系统的性能和资源利用率。

    - 没对应的知识点

    1. 双向链表的实现与使用
    2. 链接脚本相关的若干知识点
