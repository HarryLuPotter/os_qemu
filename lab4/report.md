#### 练习1：分配并初始化一个进程控制块（需要编码）
alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在 alloc_proc 函数的实现中，需要初始化的 proc_struct 结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明 proc_struct 中 `struct context context` 和 `struct trapframe *tf` 成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

`alloc_proc` 函数的实现思路就是创建一个新的进程控制块，然后对所有成员变量进行初始化；根据实验指导书，除了几个成员变量设置特殊值之外，其他成员变量均初始化为0。

```c
//kern/process/proc.c
static struct proc_struct *alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    proc->state = PROC_UNINIT; // 设置为初始态
    proc->pid = -1; // pid的未初始化值
    proc->runs = 0;
    proc->kstack = 0;
    proc->need_resched = 0;
    proc->parent = NULL;
    proc->mm = NULL;
    memset(&(proc->context), 0, sizeof(struct context));
    proc->tf = NULL;
    proc->cr3 = boot_cr3; //由于是内核线程，共享内核虚拟内存空间，使用内核页目录表的基址
    proc->flags = 0;
    memset(proc->name, 0, PROC_NAME_LEN);

    }
    return proc;
}
```

- `context`：`context`中保存了进程执行的上下文，也就是几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态。切换过程的实现在`kern/process/switch.S`。`switch_to`函数将from线程的`context`保存到堆栈中，并且将to线程的`context`从堆栈中恢复，用以保存from线程的运行状态，并且切换到to线程的运行状态。

- `tf`：`tf`里保存了进程的中断帧。具体来说，proc_init函数中调用kernel_thread函数为线程 initproc的中断帧分配了空间，并且进行了初始化工作。如将函数fn赋值给s0寄存器，将fn函数的参数赋值给s1寄存器，并且将入口点（epc）设置为 kernel_thread_entry 函数。然后调用do_fork函数，用创建的中断帧`tf`创建线程initproc，同时将上下文中的 ra 设置为了 `forkret` 函数的入口。

  接下来是切换到新线程的过程。cpu_idle()->schedule()->proc_run()->switch_to()，在switch_to会ret到上下文中的 ra 指向的地方，即`forkret` 函数，其指向forkrets。随后forkrets->__trapret，从中断帧恢复所有寄存器，并跳转到epc指向的函数，即kernel_thread_entry。最终在kernel_thread_entry中跳转到新进程要执行的函数。

#### 练习2：为新创建的内核线程分配资源（需要编码）
创建一个内核线程需要分配和设置好很多资源。kernel_thread 函数通过调用do_fork函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明 ucore 是否做到给每个新 fork 的线程一个唯一的id？请说明你的分析和理由。

`do_fork` 函数创建了当前内核线程的一个副本，设置新的控制块中的每个成员变量。

```c
//kern/process/proc.c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
        // 1. Call alloc_proc to allocate a proc_struct
    proc = alloc_proc();
    
    // 将子进程的父节点设为当前进程
    proc->parent = current;
    //    2. call setup_kstack to allocate a kernel stack for child process
    if(setup_kstack(proc)){
        goto bad_fork_cleanup_kstack;
    }
    
    // 3. Call copy_mm to duplicate OR share mm according to clone_flags
    copy_mm(clone_flags, proc);
    

    // 4. Call copy_thread to setup tf and context in proc_struct
    copy_thread(proc, stack, tf);

    // 5. Insert proc_struct into hash_list and proc_list
        bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);
        list_add(&proc_list, &(proc->list_link));
        nr_process++;
    }
    local_intr_restore(intr_flag);
    // 6. Call wakeup_proc to make the new child process RUNNABLE
    wakeup_proc(proc);

    // 7. Set the return value using the child proc's pid
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

在ucore中，通过`get_pid`函数来分配新进程的pid，该函数使用了静态变量`last_pid`和`next_safe`来维护可用pid的上界，从`last_pid`到`next_safe`之间的区间内能够保证为可用的pid号。每次调用`get_pid`时，除了在该合法区间取一个pid分配给新进程，还要维护这个区间。通过循环检查所有进程的pid，重新找到一个满足条件的区间，确保pid是唯一的。

#### 练习3：编写proc_run 函数（需要编码）
proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用 `/kern/sync/sync.h` 中定义好的宏 `local_intr_save(x)` 和 `local_intr_restore(x)` 来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h` 中提供了 `lcr3(unsigned int cr3)` 函数，可实现修改CR3寄存器值的功能。
- 实现上下文切换。`/kern/process` 中已经预先编写好了 `switch.S`，其中定义了 `switch_to()` 函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

完成代码编写后，编译并运行代码：make qemu

如果可以得到如附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

`proc_run` 函数的实现如下：

```c
//kern/process/proc.c
void proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
       struct proc_struct *prev = current, *next = proc;
        bool intr_flag;
        local_intr_save(intr_flag);
            current = proc;
            lcr3(proc->cr3);
            switch_to(&(prev->context), &(next->context));
        local_intr_restore(intr_flag);
    }
}
```

在本实验执行过程中，一共创建了两个内核线程：  
1. `idleproc`，第0个内核线程，它的主要目的是在系统没有其他任务需要执行时，占用 CPU 时间，同时便于进程调度的统一化。具体来说，idleproc内核线程的工作就是不停地查询，看是否有其他内核线程可以执行了，如果有，马上让调度器选择那个内核线程执行。
2. `initproc`，第1个内核线程，在本次实验中只用于打印字符串"hello world"。

#### 扩展练习 Challenge：

- 说明语句 `local_intr_save(intr_flag);....local_intr_restore(intr_flag);` 是如何实现开关中断的？

语句 `local_intr_save(intr_flag);` 和 `local_intr_restore(intr_flag);` 结合起来实现了开关中断的功能。首先，`local_intr_save` 会保存当前中断是否打开，将其状态存储在 `intr_flag` 变量中。这样可以确保在进入关键代码段之前，中断状态被保存下来。然后，在关键代码段执行完毕后，通过 `local_intr_restore`，根据保存的中断状态 `intr_flag`，将 `sstatus` 的 `SIE` 位设置为相应的状态，从而恢复中断的开关状态。

具体来说，`local_intr_save` 通过调用 `__intr_save` 函数保存当前中断状态，并将结果存储在 `intr_flag` 中。接着，在关键代码段执行完毕后，`local_intr_restore` 通过调用 `__intr_restore` 函数根据保存的中断状态 `intr_flag`，来设置 `sstatus` 的 `SIE` 位，从而恢复中断的状态。
