#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <../sync/sync.h>
#include <riscv.h>
#include <buddySystem.h>




// virtual address of physical page array
struct Page *pages;



// amount of physical memory (in pages)



size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000



//npage = maxpa / PGSIZE; npage - nbase = (maxpa - DRAM_BASE) / PGSIZE = os管理的物理内存的页数
// DRAM_BASE = 0x80000000   maxpa = 0x88000000



// os管理的空间的起始页号
const size_t nbase = DRAM_BASE / PGSIZE; 

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;   


static void check_alloc_page(void);  //测试功能

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {  
    pmm_manager = &buddySystem;    //选择分配策略
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory


//尝试分配n个页
struct Page *alloc_pages(size_t n) { 
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
    }
    local_intr_restore(intr_flag);
    return page;
}





// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
// 释放从base开始的n个页
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
//返回可用页数量
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

static void page_init(void) {
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint64_t mem_end = PHYSICAL_MEMORY_END; //硬编码取代 sbi_query_memory()接口

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
            mem_end - 1);

    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];  //end是内核程序结束位置的虚拟地址

    npage = maxpa / PGSIZE;
    //kernel在end[]结束, pages是剩下的页的开始
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);  ////把pages指针指向内核所占内存空间结束后的第一页

    for (size_t i = 0; i < npage - nbase; i++) {  //将管理的所有页都先设置成reserved
        SetPageReserved(pages + i);
    }


    // 可以自由使用的物理内存地址，sizeof(struct Page) * (npage - nbase)指的是跳过了存放页结构体所占用的物理内存空间
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));

    mem_begin = ROUNDUP(freemem, PGSIZE);   //开始地址按页对齐
    mem_end = ROUNDDOWN(mem_end, PGSIZE);   //结束地址按页对齐
    if (freemem < mem_end) {
        // 初始化要管理的所有页（调用选择的pmm_manager的init_memmap函数）
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */


//在init.c中被调用
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();  //初始化分配器

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();  //初始化物理页

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    //三级页表地址
    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
