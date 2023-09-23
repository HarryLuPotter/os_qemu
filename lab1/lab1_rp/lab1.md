# lab1:中断处理机制
## 练习1：理解内核启动中的程序入口操作
> 阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？

指令 `la sp, bootstacktop`是将bootstacktop标签的地址加载到sp寄存器中，目的是为了设置栈顶指针，以便于初始化内核栈，内核初始栈空间用于存储内核执行过程中的临时数据和函数调用的上下文信息。具体来说，内核初始栈空间的用途包括：

1. 存储函数调用的上下文信息：当内核执行函数调用时，需要保存当前函数的返回地址、函数参数、局部变量等信息。这些信息被存储在内核初始栈空间中，以便在函数返回时恢复上下文。
2. 存储中断处理程序的上下文信息：当发生硬件中断或软件中断时，内核需要保存当前执行的进程的上下文信息，并切换到中断处理程序的上下文。这些上下文信息包括程序计数器、寄存器状态等，都被保存在内核初始栈空间中。
3. 存储内核执行过程中的临时数据：内核执行过程中可能需要临时存储一些数据，例如函数调用时的临时变量、中断处理程序的临时数据等。这些临时数据被存储在内核初始栈空间中，以便在需要时进行读写操作。



>  tail kern_init 完成了什么操作，目的是什么？

指令 tail kern_init执行了一个跳转指令，跳转到kern_init，目的是在启动过程中将控制传递给内核的初始化程序，tail是一个尾调用指令，用于在函数末尾无返回地跳转到另一个函数，也即不会保存当前返回地址到寄存器ra中从而节省栈空间，并加快内核启动。



## 练习2：完善中断处理

> 请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

首先调用clock_set_next_event()设置下次时钟中断，判断ticks整除`TICK_NUM`时打印并使得`num++`，当num=10时，调用sbi_shutdown()关机，运用这个思路填写了下面代码：
```
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   YOUR CODE :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
            if(++ticks % TICK_NUM == 0)
            {
            	print_ticks();
            	++num;
            }
            if(num==10)
            {
            	sbi_shutdown();
            }
            break;
    }
}
```



## 扩展练习 Challenge1：描述与理解中断流程
> 描述ucore中中处理中断异常的流程（从异常的产生开始）

首先，STVEC寄存器是一个存储异常处理程序入口地址的寄存器。在RISC-V架构中，当发生异常或中断时，处理器会根据异常类型和中断原因来找到相应的异常处理程序。而在`idt_init`函数中我们看到程序将`__alltraps`的地址写到了STVEC寄存器中

```
 	void idt_init(void) {
    extern void __alltraps(void);
   
    write_csr(sscratch, 0);
    
    write_csr(stvec, &__alltraps);
}
```

那么`__alltraps`在哪里呢？

我们在`trapentry.S`中找到了它，定义如下

```
__alltraps:
    SAVE_ALL

    move  a0, sp
    jal trap
    
    .globl __trapret
```

首先调用了SAVE_ALL过程，将上下文信息入栈保存起来，之后调用trap函数

```
void trap(struct trapframe *tf) 
{
	trap_dispatch(tf);
}
```

而trap函数调用了`trap_dispatch`函数，按照中断类型分情况处理

```
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
}
```

之后运行具体中断或异常处理程序（~~代码太长不贴出来了~~），处理结束后执行了`__trapret`，恢复了上下文并通过`sret`从中断处理程序（或异常处理程序）返回到先前的特权级，并将epc的值赋给pc，程序从原先的地方继续运行

```
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
```

至此分析结束



> 其中mov a0，sp的目的是什么？

`move a0, sp`将此时sp的值传递给a0，是由于RISCV规定参数的传递应使用参数寄存器（a0-a7），本条指令之后要做的事情是汇编调用c函数，所以需要传入参数`struct trapframe *tf`，方式就是给`a0`寄存器赋值为栈指针，供中断处理函数使用



> SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？

SAVE_ALL中寄存器保存在栈中的位置是由sp栈顶指针的位置决定的，通过sp的值加上偏移量确定。



> 对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

中断触发时有一些寄存器需要保存，如PC寄存器、部分通用寄存器、堆栈指针寄存器，除此之外其他寄存器的状态是否需要保存取决于具体的中断种类以及处理需求，一些不会在处理程序中更改的寄存器可以不用保存。



## 扩展练习 Challenge2：理解上下文切换机制
> 在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

对于`csrw`指令，个人的理解是这里作为一个临时寄存器使用，在栈空间扩展之前将sp的值存在sscratch寄存器中，而`csrrw`指令则首先将sscratch寄存器的值赋给s0，同时做清零操作，之后通过` STORE s0, 2*REGBYTES(sp)`实际上将原先的sp值保存下来



> save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

首先搞清楚这两个scr分别用来做什么

`stval` 寄存器通常用于存储导致异常的指令或数据的值。在异常处理程序中，可能需要访问 `stval` 来获取有关异常原因的详细信息，例如无效的地址或数据。

`scause` 寄存器存储了引发异常或中断的原因代码（异常码）。在异常处理程序中，通常使用 `scause` 来确定异常的类型，然后采取适当的处理措施。

这些都是在异常处理过程中非常有用的信息，将它们保存进栈中而不是直接通过读寄存器的方式的原因，本人推测可能是因为避免覆盖。而不还原它们的原因很简单，就是因为中断处理结束之后这些寄存器的信息没有用，没必要还原。



## 扩展练习Challenge3：完善异常中断

> 编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。

处理非法指令时epc寄存器指向异常指令地址，在遭遇异常指令时我们想知道异常指令地址，则需要将epc的值的16进制形式输出，即可得到相应的地址，在输出后更新寄存器值，根据**触发异常的指令长度**不同将epc的值进行改变。
```
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction\n");
            cprintf("exception address: %x\n",tf->epc);
            tf->epc+=4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
             */
            cprintf("breakpoint\n");
            cprintf("exception address: %x\n",tf->epc);
            tf->epc+=2;
            break;
    }
}
```



## 实验结果

我采用了内联汇编的方式通过`ebreak`和`mret`两条指令触发两种异常，将其加在了`clock.c`文件的`clock_init`函数中

```
void clock_init(void) {
    // trigger
    __asm__ volatile (
        "ebreak\n"
        "mret\n"
    );

    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}
```

最终运行结果如下图所示

![image1](.\src\image1.png)

不难看出三种中断都被正常处理



> 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）

- **权限模式**：CPU上电后，依次经过机器态、监管态、用户态三个模式，机器态下运行的代码通常是操作系统的引导代码（Bootloader），监管态通常由操作系统内核使用，用户态用于执行用户应用程序。

- **中断向量表**：中断向量表是用于查找中断处理程序地址的数据结构。尽管没有设置和使用中断向量表的具体操作，但是涉及了中断向量表的控制和用途，以确保正确地将中断路由到相应的处理程序。



> 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

- x86架构中严格区分异常和中断，而riscv架构中可以进行自定义，其中就包括更改异常处理程序中的epc
- 在阅读了ucore的源码之后，观察到了开发大型程序的整体架构，其中包含了非常多的抽象层，很多函数的函数体里面仅仅是调用了另一个函数，猜测是为了提高代码的可阅读性。