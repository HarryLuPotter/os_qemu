#ifndef __KERN_MM_BUDDYSYSTEM_H__
#define __KERN_MM_BUDDYSYSTEM_H__

#include <pmm.h>


#define MAX_ORDER 20

extern const struct pmm_manager buddySystem;


typedef struct
{
    unsigned int max_order;             //实际最高阶
    list_entry_t free_array[MAX_ORDER + 1]; //空闲块链表组成的数组
    unsigned int nr_free;               //本数据结构管理的空闲页的数量
} free_buddy_t;





#endif /* ! __KERN_MM_BUDDYSYSTEM_H__ */