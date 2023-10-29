## 练习0：填写已有实验

>本实验依赖实验2。请把你做的实验2的代码填入本实验中代码中有“LAB2”的注释相应部分。（建议手动补充，不要直接使用merge）

将trap.c,default_pmm.c和pmm.c等文件中修改过的内容填入到lab3对应的文件中。

## 练习1：理解基于FIFO的页面替换算法（思考题）

>描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
>
>- 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

页面替换的过程可以分为页面换入和页面换出两个部分。页面换入部分在vmm.c中，而页面换出部分在swap_fifo.c中。函数的功能主要在注释中进行说明。

- 页面换入

  ```c
  // vmm.c
  /* do_pgfault - 中断处理程序，用于处理页面故障异常
   * @mm         : 控制一组使用相同PDT的vma的结构体
   * @error_code : 在trapframe->tf_err中由x86硬件设置的错误代码
   * @addr       : 导致内存访问异常的地址（CR2寄存器的内容）
   *
   * 调用图：trap--> trap_dispatch-->pgfault_handler-->do_pgfault
   * 处理器为ucore的do_pgfault函数提供了两个信息项，以帮助诊断异常并从中恢复。
   *   (1) CR2寄存器的内容。处理器将CR2寄存器加载为生成异常的32位线性地址。do_pgfault函数可以使用该地址来定位相应的页目录和页表项。
   *   (2) 内核栈上的错误代码。页面故障的错误代码与其他异常的格式不同。错误代码告诉异常处理程序三件事：
   *         -- P标志（位0）指示异常是由于不存在的页面（0）还是由于访问权限违规或使用了保留位（1）引起的。
   *         -- W/R标志（位1）指示引发异常的内存访问是读取（0）还是写入（1）。
   *         -- U/S标志（位2）指示处理器在异常发生时是否以用户模式（1）或特权模式（0）执行。
   */
  int
  do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
      int ret = -E_INVAL; // Invalid parameter
   
      // mm结构体控制一组使用相同PDT的vma。
      // vma_struct结构体描述一段连续的虚拟地址，从vm_start到vm_end。 
      struct vma_struct *vma = find_vma(mm, addr);
  
      pgfault_num++;
      // 出错地址是否在mm控制的范围内
      if (vma == NULL || vma->vm_start > addr) {
          cprintf("not valid addr %x, and  can not find it in vma\n", addr);
          goto failed;
      }
  
      /* IF (write an existed addr ) OR
       *    (write an non_existed addr && addr is writable) OR
       *    (read  an non_existed addr && addr is readable)
       * THEN
       *    continue process
       */
  
      // perm标识mm->padir页表中对应addr的二级页表的各个权限位
      uint32_t perm = PTE_U;
      if (vma->vm_flags & VM_WRITE) {
          perm |= (PTE_R | PTE_W);
      }
      addr = ROUNDDOWN(addr, PGSIZE);
  
      ret = -E_NO_MEM;
  
      pte_t *ptep=NULL;
      /*
       * 也许您想要帮助注释，下面的注释可以帮助您完成代码
       *
       * 一些有用的宏和定义，您可以在下面的实现中使用它们。
       * 宏或函数：
       *   get_pte：获取一个pte，并返回此pte的内核虚拟地址，用于la
       *            如果PT中不包含此pte，则为PT分配一个页面（注意第三个参数'1'）
       *   pgdir_alloc_page：调用alloc_page和page_insert函数来分配一个页面大小的内存并设置
       *            一个地址映射pa <--> la，其中线性地址la和PDT pgdir
       * 定义：
       *   VM_WRITE  ：如果vma->vm_flags & VM_WRITE == 1/0，则vma是可写/不可写的
       *   PTE_W           0x002                   // 页面表/目录条目标志位：可写
       *   PTE_U           0x004                   // 页面表/目录条目标志位：用户可访问
       * 变量：
       *   mm->pgdir：这些vma的PDT
       *
       */
  
  
      ptep = get_pte(mm->pgdir, addr, 1); // get_pte - 获取pte并返回此pte的内核虚拟地址，用于la 
                                          // 如果PT不包含此pte，则为PT分配一个页面 
                                          // 返回值：此pte的内核虚拟地址
                                           
                                           
      if (*ptep == 0) {
          if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
              cprintf("pgdir_alloc_page in do_pgfault failed\n");
              goto failed;
          }
      } else {
          /*LAB3 EXERCISE 3: YOUR CODE
          * 请你根据以下信息提示，补充函数
          * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
          * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
          *
          *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
          *  宏或函数:
          *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
          *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
          *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
          *    swap_map_swappable ： 设置页面可交换
          */
         
          if (swap_init_ok) {
              struct Page *page = NULL;
              // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
              //(1）According to the mm AND addr, try
              //to load the content of right disk page
              //into the memory which page managed.
              //(2) According to the mm,
              //addr AND page, setup the
              //map of phy addr <---> logical addr
              //(3) make the page swappable.
  
  
              // 将addr线性地址对应的物理页数据从磁盘交换到物理内存中，令Page指针指向交换成功后的物理页
              // 此时的page中有需要的数据，但是page还没有插入链表中
              if ((swap_in(mm, addr, &page)) != 0) {
                  // swap_in返回值不为0，表示换入失败
                  cprintf("swap_in in do_pgfault failed\n");
                  goto failed;
              }    
              // 将交换进来的page页与mm->padir页表中对应addr的二级页表项建立映射关系(perm标识这个二级页表的各个权限位)
              page_insert(mm->pgdir, page, addr, perm);
              // 当前page是为可交换的，将其加入全局虚拟内存交换管理器的管理
              swap_map_swappable(mm, addr, page, 1);
  
  
              page->pra_vaddr = addr;
          } else {
              cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
              goto failed;
          }
     }
  
     ret = 0;
  failed:
      return ret;
  }
  
  ```

  以下对其中调用的get_pte，swap_in，page_insert和swap_map_swappable函数做进一步说明。

  ```c
  // pmm.c
  // get_pte - 获取pte并返回此pte的内核虚拟地址，用于la 
  // - 如果PT不包含此pte，则为PT分配一个页面 
  // 参数： 
  // pgdir：PDT的内核虚拟基地址 
  // la：需要映射的线性地址 
  // create：一个逻辑值，决定是否为PT分配一个页面 
  // 返回值：此pte的内核虚拟地址
  pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) 
      /*
       * 
       * 如果您需要访问物理地址，请使用KADDR()
       * 请阅读pmm.h以获取有用的宏 
       * 也许您想要帮助注释，下面的注释可以帮助您完成代码 
       * 一些有用的宏和定义，您可以在下面的实现中使用它们。 
       * 
       * 宏或函数：
       * PDX(la) = 虚拟地址la的页目录条目索引。
       * KADDR(pa)：获取物理地址并返回相应的内核虚拟地址。
       * set_page_ref(page,1)：表示此页被引用一次。
       * page2pa(page)：获取此（struct Page *）page管理的内存的物理地址。
       * struct Page * alloc_page()：分配一个页面 
       * memset(void *s, char c, size_t n)：将指针s指向的内存区域的前n个字节设置为指定值c。 
       * 
       * 定义：
       * PTE_P 0x001 // 页面表/目录条目标志位：存在
       * PTE_W 0x002 // 页面表/目录条目标志位：可写
       * PTE_U 0x004 // 页面表/目录条目标志位：用户可访问
       */
  ```

  ```c
  // swap.c
  // 将addr线性地址对应的物理页数据从磁盘交换到物理内存中，令Page指针指向交换成功后的物理页
  int
  swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)
  {
       struct Page *result = alloc_page();
       assert(result!=NULL);
       // 从mm->pgdir获取addr所在的虚拟地址
       pte_t *ptep = get_pte(mm->pgdir, addr, 0);
       // cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
      
       int r;
       // 从ptep中读取数据到result页面
       if ((r = swapfs_read(*ptep, result)) != 0)
       {
          assert(r!=0);
       }
       cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
       *ptr_result=result;
       return 0;
  }
  
  // swapfs.c
  // 函数的参数是一个交换条目（swap_entry_t）和一个页面（struct Page *）。
  // 函数使用swap_offset(entry)计算交换条目在交换分区中的偏移量，并将该偏移量乘以PAGE_NSECT得到扇区的偏移量。
  // 然后，函数调用ide_read_secs函数来从交换设备（SWAP_DEV_NO）读取指定数量的扇区数据到给定页面的内核虚拟地址（page2kva(page)）。
  // 最后，函数返回ide_read_secs的返回值。
  int
  swapfs_read(swap_entry_t entry, struct Page *page) {
      return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
  }
  ```

  ```c
  // pmm.c
  // page_insert - 构建一个Page的物理地址与线性地址la之间的映射
  // 参数：
  //  pgdir：PDT的内核虚拟基地址
  //  page：需要映射的Page
  //  la：需要映射的线性地址
  //  perm：在相关的pte中设置的此Page的权限
  // 返回值：始终为0
  // 注意：PT已更改，因此需要使TLB无效化
  int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) 
  ```

  swap_map_swappable函数中调用了sm的map_swappable函数，即_fifo_map_swappable函数。

  ```c
  // swap_fifo.c
  // 将当前换进来的页加入到mm对象的访问顺序列表中，每次加在链表头的后面，这样越先被访问的页，在链表中越靠后
  static int
  _fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
  {
      // sm_priv 指向访问顺序列表头部的指针
      list_entry_t *head = (list_entry_t*) mm->sm_priv;
      // pra_page_link的开头表示第一次访问时间最近的页
      // 结尾表示第一次访问时间最远的页
      list_entry_t *entry = &(page->pra_page_link);
   
      assert(entry != NULL && head != NULL);
  
      // 调用list_add函数将entry插入到head之后的位置
      list_add(head, entry);
      return 0;
  }
  ```

- 页面换出

  ```c
  // swap_fifo.c
  // 首先我们要找到需要被换出的页，并用一个指针entry指示这个需要被换出的页。
  // 再用le2page找到对应的page，最后删除entry指向的页并用找到的page替赋值给参数中的ptr_page
  static int
  _fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
  {
       list_entry_t *head=(list_entry_t*) mm->sm_priv;
           assert(head != NULL);
       assert(in_tick==0);
       /* Select the victim */
       //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
       //(2)  set the addr of addr of this page to ptr_page
       // 最早进入访问顺序列表中的元素
      list_entry_t* entry = list_prev(head);
      if (entry != head) {
          list_del(entry);
          *ptr_page = le2page(entry, pra_page_link);
      } else {
          *ptr_page = NULL;
      }
      return 0;
  }
  ```

## 练习2：深入理解不同分页模式的工作原理（思考题）

>get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
>
>- get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
>- 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

我们先对get_pte函数功能以及其实现方法进行具体的分析:

```c
// get_pte - 获取pte并返回此pte的内核虚拟地址，用于la 
// - 如果PT不包含此pte，则为PT分配一个页面 
// 参数： 
// pgdir：PDT的内核虚拟基地址 
// la：需要映射的线性地址 
// create：一个逻辑值，决定是否为PT分配一个页面 
// 返回值：此pte的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    /*
     * 
     * 如果您需要访问物理地址，请使用KADDR()
     * 请阅读pmm.h以获取有用的宏 
     * 也许您想要帮助注释，下面的注释可以帮助您完成代码 
     * 一些有用的宏和定义，您可以在下面的实现中使用它们。 
     * 
     * 宏或函数：
     * PDX(la) = the index of page directory entry of VIRTUAL ADDRESS la.
     * KADDR(pa)：获取物理地址并返回相应的内核虚拟地址。
     * set_page_ref(page,1)：表示此页被引用一次。
     * page2pa(page)：获取此（struct Page *）page管理的内存的物理地址。
     * struct Page * alloc_page()：分配一个页面 
     * memset(void *s, char c, size_t n)：将指针s指向的内存区域的前n个字节设置为指定值c。 
     * 
     * 定义：
     * PTE_P 0x001 // 页面表/目录条目标志位：存在
     * PTE_W 0x002 // 页面表/目录条目标志位：可写
     * PTE_U 0x004 // 页面表/目录条目标志位：用户可访问
     */
    // PDX1(la)：对应la的大大页表项在大大页表中的偏移
    pde_t *pdep1 = &pgdir[PDX1(la)]; // 找到对应la的大大页表项
    if (!(*pdep1 & PTE_V)) { // 如果该大大页表项无效，则分配一个页面
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            // create设置为不分配 或 分配失败
            return NULL;
        }
        // 分配成功，将引用计数设为1
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page); // 获取页面物理地址
        memset(KADDR(pa), 0, PGSIZE); // KADDR获取pa对应的虚拟地址，然后将前4096个字节设为0
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建 大大页表项--->大页 的映射
    }
    // PDX0(la)：对应la的大页表项在大页表中的偏移
    // PDE_ADDR(*pdep1)：找到大大页表项pdep1对应的大页表
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)]; // 根据在大页表中的偏移找到对应la的大页表项
    if (!(*pdep0 & PTE_V)) { // 如果该大页表项无效，则分配一个页面
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    // PDE_ADDR(*pdep0)：找到大页表项pdep0对应的页表
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 根据页表中的偏移找到对应la的PTE
}
```

1. 这段代码的主要操作是，在页表中找到需要的页表项，如果找不到，就创建一个页表项。由于这里采用的是sv39分页机制，其中存在三级页表，需要从大大页表里找需要的大页表，从大页表里找页表，再在页表里找到需要的页表项，所以这里会存在相似的代码。
2. 我认为这种写法不好，需要在多个地方重复编写相似的逻辑。一方面，将查找和分配合并在一个函数中可能会导致函数的逻辑不够清晰；另一方面，如果在未来需要对查找和分配进行单独的修改或优化或者增加一级页表，需要对每一段代码都进行修改，较为繁琐，不便于维护。

## 练习3：给未被映射的地址映射上物理页（需要编程）

>补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
>
>请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
>- 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
>- 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
>  - 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

```c
// mm/vmm.c do_pgfault
		if (swap_init_ok) {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.


            // 将addr线性地址对应的物理页数据从磁盘交换到物理内存中(令Page指针指向交换成功后的物理页)
            if ((swap_in(mm, addr, &page)) != 0) {
                // swap_in返回值不为0，表示换入失败
                cprintf("swap_in in do_pgfault failed\n");
                goto failed;
            }    
            // 将交换进来的page页与mm->padir页表中对应addr的二级页表项建立映射关系(perm标识这个二级页表的各个权限位)
            page_insert(mm->pgdir, page, addr, perm);
            // 当前page是为可交换的，将其加入全局虚拟内存交换管理器的管理
            swap_map_swappable(mm, addr, page, 1);


            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
```



## 练习4：补充完成Clock页替换算法（需要编程）

>通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。(提示:要输出curr_ptr的值才能通过make grade)
>
>请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
>- 比较Clock页替换算法和FIFO算法的不同。

```c
// mm/swap_clock.c
static int
_clock_init_mm(struct mm_struct *mm)
{     
     /*LAB3 EXERCISE 4: YOUR CODE*/ 
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     /******************************************************/
     list_init(&pra_list_head);
     curr_ptr = &pra_list_head;
     mm->sm_priv = &pra_list_head;
     /********************************************************/
     return 0;
}
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: YOUR CODE*/ 
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    // 将页面的visited标志置为1，表示该页面已被访问

    /********************************************************/
    list_add_before(curr_ptr, entry);
    page->visited = 0;
    /********************************************************/
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     list_entry_t *p = list_next(head);
    assert(p!=head);
    while (1) {
        /*LAB3 EXERCISE 4: YOUR CODE*/ 
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        // 获取当前页面对应的Page结构指针
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        /*************************************************************************************/
        if (curr_ptr == head)
        {
            curr_ptr = curr_ptr->next;
        }
        struct Page *p = le2page(curr_ptr, pra_page_link);
        if (p->visited == 1)
        {
            p->visited = 0;
            curr_ptr = curr_ptr->next;
        }
        else{
            *ptr_page = p;
            cprintf("curr_ptr 0xffffffff%08x\n", curr_ptr);
            list_del(curr_ptr);
            curr_ptr = curr_ptr->next;
            break;
        }
        			/************************************************************************************************/
    }
    return 0;
}
```

- 不同之处：时钟页替换算法与FIFO 算法是类似的，不同之处是在时钟页替换算法中跳过了访问位为 1 的页

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）

如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？
**好处与优势**：

1.采用一个大页的方式可以减少页表的项数。在分级页表中，每级页表都需要存储许多页表项，当虚拟地址空间非常大时，页表项数量会迅速增加。使用大页可以减少页表的级数和页表项的数量，提高内存访问效率。
2.当使用大页方式时，我们可以避免多次查找页表项，减少层次结构，避免了如实验中由一级页表映射至二级页表后再映射到物理页帧的复杂方式，提升了访问速度。
3.使用大页映射方式可以减小系统开销，诸如实验中所涉及的页表结构体，每插入一个页表需要额外的内存开销，而采用大页可以在一个页表中映射更多物理页帧，减小了内存开销。
4.对于本身内存较大的系统更加有利，由于实验只涉及到较小内存与较少虚拟地址与物理地址的映射关系，所以在实验中并不突出，但是在实际场景下当内存较大时，大页表的优势较为突出。

**坏处与风险**：

1.可能产生内存浪费，当进程分配页表时如果进程只使用了页表的一部分空间，而剩下的部分将被浪费。
2.当我们使用诸如实验中模拟的小型系统时，内存分配较少，而如果使用较大页表进行内存管理会使得空间被进一步浪费。
3.如果物理页帧不存在连续的较大内存，当物理内存不能满足页表需要时，可能会造成读取溢出或映射错误。

