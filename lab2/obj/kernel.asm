
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	57a60613          	addi	a2,a2,1402 # ffffffffc02065b8 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	76a010ef          	jal	ra,ffffffffc02017b8 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00001517          	auipc	a0,0x1
ffffffffc020005a:	77a50513          	addi	a0,a0,1914 # ffffffffc02017d0 <etext+0x6>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>



    //初始化物理内存管理
    pmm_init();  // init physical memory management
ffffffffc020006a:	026010ef          	jal	ra,ffffffffc0201090 <pmm_init>



    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	200010ef          	jal	ra,ffffffffc02012aa <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	1cc010ef          	jal	ra,ffffffffc02012aa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200140:	00001517          	auipc	a0,0x1
ffffffffc0200144:	6e050513          	addi	a0,a0,1760 # ffffffffc0201820 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00001517          	auipc	a0,0x1
ffffffffc020015a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0201840 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00001597          	auipc	a1,0x1
ffffffffc0200166:	66858593          	addi	a1,a1,1640 # ffffffffc02017ca <etext>
ffffffffc020016a:	00001517          	auipc	a0,0x1
ffffffffc020016e:	6f650513          	addi	a0,a0,1782 # ffffffffc0201860 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	e9a58593          	addi	a1,a1,-358 # ffffffffc0206010 <edata>
ffffffffc020017e:	00001517          	auipc	a0,0x1
ffffffffc0200182:	70250513          	addi	a0,a0,1794 # ffffffffc0201880 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	42e58593          	addi	a1,a1,1070 # ffffffffc02065b8 <end>
ffffffffc0200192:	00001517          	auipc	a0,0x1
ffffffffc0200196:	70e50513          	addi	a0,a0,1806 # ffffffffc02018a0 <etext+0xd6>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00007597          	auipc	a1,0x7
ffffffffc02001a2:	81958593          	addi	a1,a1,-2023 # ffffffffc02069b7 <end+0x3ff>
ffffffffc02001a6:	00000797          	auipc	a5,0x0
ffffffffc02001aa:	e9078793          	addi	a5,a5,-368 # ffffffffc0200036 <kern_init>
ffffffffc02001ae:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001bc:	95be                	add	a1,a1,a5
ffffffffc02001be:	85a9                	srai	a1,a1,0xa
ffffffffc02001c0:	00001517          	auipc	a0,0x1
ffffffffc02001c4:	70050513          	addi	a0,a0,1792 # ffffffffc02018c0 <etext+0xf6>
}
ffffffffc02001c8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ca:	eedff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02001ce <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ce:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d0:	00001617          	auipc	a2,0x1
ffffffffc02001d4:	62060613          	addi	a2,a2,1568 # ffffffffc02017f0 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00001517          	auipc	a0,0x1
ffffffffc02001e0:	62c50513          	addi	a0,a0,1580 # ffffffffc0201808 <etext+0x3e>
void print_stackframe(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e6:	1c6000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001ea <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ea:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ec:	00001617          	auipc	a2,0x1
ffffffffc02001f0:	7e460613          	addi	a2,a2,2020 # ffffffffc02019d0 <commands+0xe0>
ffffffffc02001f4:	00001597          	auipc	a1,0x1
ffffffffc02001f8:	7fc58593          	addi	a1,a1,2044 # ffffffffc02019f0 <commands+0x100>
ffffffffc02001fc:	00001517          	auipc	a0,0x1
ffffffffc0200200:	7fc50513          	addi	a0,a0,2044 # ffffffffc02019f8 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00001617          	auipc	a2,0x1
ffffffffc020020e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0201a08 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	81e58593          	addi	a1,a1,-2018 # ffffffffc0201a30 <commands+0x140>
ffffffffc020021a:	00001517          	auipc	a0,0x1
ffffffffc020021e:	7de50513          	addi	a0,a0,2014 # ffffffffc02019f8 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	81a60613          	addi	a2,a2,-2022 # ffffffffc0201a40 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	83258593          	addi	a1,a1,-1998 # ffffffffc0201a60 <commands+0x170>
ffffffffc0200236:	00001517          	auipc	a0,0x1
ffffffffc020023a:	7c250513          	addi	a0,a0,1986 # ffffffffc02019f8 <commands+0x108>
ffffffffc020023e:	e79ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc0200242:	60a2                	ld	ra,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	ef1ff0ef          	jal	ra,ffffffffc020013e <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f71ff0ef          	jal	ra,ffffffffc02001ce <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7115                	addi	sp,sp,-224
ffffffffc020026c:	e962                	sd	s8,144(sp)
ffffffffc020026e:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00001517          	auipc	a0,0x1
ffffffffc0200274:	6c850513          	addi	a0,a0,1736 # ffffffffc0201938 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	ed86                	sd	ra,216(sp)
ffffffffc020027a:	e9a2                	sd	s0,208(sp)
ffffffffc020027c:	e5a6                	sd	s1,200(sp)
ffffffffc020027e:	e1ca                	sd	s2,192(sp)
ffffffffc0200280:	fd4e                	sd	s3,184(sp)
ffffffffc0200282:	f952                	sd	s4,176(sp)
ffffffffc0200284:	f556                	sd	s5,168(sp)
ffffffffc0200286:	f15a                	sd	s6,160(sp)
ffffffffc0200288:	ed5e                	sd	s7,152(sp)
ffffffffc020028a:	e566                	sd	s9,136(sp)
ffffffffc020028c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	e29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200292:	00001517          	auipc	a0,0x1
ffffffffc0200296:	6ce50513          	addi	a0,a0,1742 # ffffffffc0201960 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00001c97          	auipc	s9,0x1
ffffffffc02002ac:	648c8c93          	addi	s9,s9,1608 # ffffffffc02018f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00001997          	auipc	s3,0x1
ffffffffc02002b4:	6d898993          	addi	s3,s3,1752 # ffffffffc0201988 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00001917          	auipc	s2,0x1
ffffffffc02002bc:	6d890913          	addi	s2,s2,1752 # ffffffffc0201990 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00001b17          	auipc	s6,0x1
ffffffffc02002c6:	6d6b0b13          	addi	s6,s6,1750 # ffffffffc0201998 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00001a97          	auipc	s5,0x1
ffffffffc02002ce:	726a8a93          	addi	s5,s5,1830 # ffffffffc02019f0 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	360010ef          	jal	ra,ffffffffc0201636 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	4b2010ef          	jal	ra,ffffffffc020179a <strchr>
ffffffffc02002ec:	c925                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ee:	00144583          	lbu	a1,1(s0)
ffffffffc02002f2:	00040023          	sb	zero,0(s0)
ffffffffc02002f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f8:	f5fd                	bnez	a1,ffffffffc02002e6 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002fa:	dce9                	beqz	s1,ffffffffc02002d4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	6582                	ld	a1,0(sp)
ffffffffc02002fe:	00001d17          	auipc	s10,0x1
ffffffffc0200302:	5f2d0d13          	addi	s10,s10,1522 # ffffffffc02018f0 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	464010ef          	jal	ra,ffffffffc0201770 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	450010ef          	jal	ra,ffffffffc0201770 <strcmp>
ffffffffc0200324:	f57d                	bnez	a0,ffffffffc0200312 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200326:	00141793          	slli	a5,s0,0x1
ffffffffc020032a:	97a2                	add	a5,a5,s0
ffffffffc020032c:	078e                	slli	a5,a5,0x3
ffffffffc020032e:	97e6                	add	a5,a5,s9
ffffffffc0200330:	6b9c                	ld	a5,16(a5)
ffffffffc0200332:	8662                	mv	a2,s8
ffffffffc0200334:	002c                	addi	a1,sp,8
ffffffffc0200336:	fff4851b          	addiw	a0,s1,-1
ffffffffc020033a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020033c:	f8055ce3          	bgez	a0,ffffffffc02002d4 <kmonitor+0x6a>
}
ffffffffc0200340:	60ee                	ld	ra,216(sp)
ffffffffc0200342:	644e                	ld	s0,208(sp)
ffffffffc0200344:	64ae                	ld	s1,200(sp)
ffffffffc0200346:	690e                	ld	s2,192(sp)
ffffffffc0200348:	79ea                	ld	s3,184(sp)
ffffffffc020034a:	7a4a                	ld	s4,176(sp)
ffffffffc020034c:	7aaa                	ld	s5,168(sp)
ffffffffc020034e:	7b0a                	ld	s6,160(sp)
ffffffffc0200350:	6bea                	ld	s7,152(sp)
ffffffffc0200352:	6c4a                	ld	s8,144(sp)
ffffffffc0200354:	6caa                	ld	s9,136(sp)
ffffffffc0200356:	6d0a                	ld	s10,128(sp)
ffffffffc0200358:	612d                	addi	sp,sp,224
ffffffffc020035a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020035c:	00044783          	lbu	a5,0(s0)
ffffffffc0200360:	dfc9                	beqz	a5,ffffffffc02002fa <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200362:	03448863          	beq	s1,s4,ffffffffc0200392 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200366:	00349793          	slli	a5,s1,0x3
ffffffffc020036a:	0118                	addi	a4,sp,128
ffffffffc020036c:	97ba                	add	a5,a5,a4
ffffffffc020036e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200372:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200376:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	e591                	bnez	a1,ffffffffc0200384 <kmonitor+0x11a>
ffffffffc020037a:	b749                	j	ffffffffc02002fc <kmonitor+0x92>
            buf ++;
ffffffffc020037c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	00044583          	lbu	a1,0(s0)
ffffffffc0200382:	ddad                	beqz	a1,ffffffffc02002fc <kmonitor+0x92>
ffffffffc0200384:	854a                	mv	a0,s2
ffffffffc0200386:	414010ef          	jal	ra,ffffffffc020179a <strchr>
ffffffffc020038a:	d96d                	beqz	a0,ffffffffc020037c <kmonitor+0x112>
ffffffffc020038c:	00044583          	lbu	a1,0(s0)
ffffffffc0200390:	bf91                	j	ffffffffc02002e4 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d21ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020039a:	b7f1                	j	ffffffffc0200366 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	61a50513          	addi	a0,a0,1562 # ffffffffc02019b8 <commands+0xc8>
ffffffffc02003a6:	d11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc02003aa:	b72d                	j	ffffffffc02002d4 <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06430313          	addi	t1,t1,100 # ffffffffc0206410 <is_panic>
ffffffffc02003b4:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	02031c63          	bnez	t1,ffffffffc0200400 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	8432                	mv	s0,a2
ffffffffc02003d0:	00006717          	auipc	a4,0x6
ffffffffc02003d4:	04f72023          	sw	a5,64(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003da:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003dc:	85aa                	mv	a1,a0
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	69250513          	addi	a0,a0,1682 # ffffffffc0201a70 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00001517          	auipc	a0,0x1
ffffffffc02003f8:	4f450513          	addi	a0,a0,1268 # ffffffffc02018e8 <etext+0x11e>
ffffffffc02003fc:	cbbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200400:	064000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200404:	4501                	li	a0,0
ffffffffc0200406:	e65ff0ef          	jal	ra,ffffffffc020026a <kmonitor>
ffffffffc020040a:	bfed                	j	ffffffffc0200404 <__panic+0x58>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	2ec010ef          	jal	ra,ffffffffc0201710 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007b323          	sd	zero,6(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00001517          	auipc	a0,0x1
ffffffffc0200436:	65e50513          	addi	a0,a0,1630 # ffffffffc0201a90 <commands+0x1a0>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	2c40106f          	j	ffffffffc0201710 <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	29e0106f          	j	ffffffffc02016f4 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	2d20106f          	j	ffffffffc020172c <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	30678793          	addi	a5,a5,774 # ffffffffc0200774 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00001517          	auipc	a0,0x1
ffffffffc0200488:	72450513          	addi	a0,a0,1828 # ffffffffc0201ba8 <commands+0x2b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00001517          	auipc	a0,0x1
ffffffffc0200498:	72c50513          	addi	a0,a0,1836 # ffffffffc0201bc0 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00001517          	auipc	a0,0x1
ffffffffc02004a6:	73650513          	addi	a0,a0,1846 # ffffffffc0201bd8 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00001517          	auipc	a0,0x1
ffffffffc02004b4:	74050513          	addi	a0,a0,1856 # ffffffffc0201bf0 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00001517          	auipc	a0,0x1
ffffffffc02004c2:	74a50513          	addi	a0,a0,1866 # ffffffffc0201c08 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00001517          	auipc	a0,0x1
ffffffffc02004d0:	75450513          	addi	a0,a0,1876 # ffffffffc0201c20 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00001517          	auipc	a0,0x1
ffffffffc02004de:	75e50513          	addi	a0,a0,1886 # ffffffffc0201c38 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00001517          	auipc	a0,0x1
ffffffffc02004ec:	76850513          	addi	a0,a0,1896 # ffffffffc0201c50 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00001517          	auipc	a0,0x1
ffffffffc02004fa:	77250513          	addi	a0,a0,1906 # ffffffffc0201c68 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00001517          	auipc	a0,0x1
ffffffffc0200508:	77c50513          	addi	a0,a0,1916 # ffffffffc0201c80 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00001517          	auipc	a0,0x1
ffffffffc0200516:	78650513          	addi	a0,a0,1926 # ffffffffc0201c98 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00001517          	auipc	a0,0x1
ffffffffc0200524:	79050513          	addi	a0,a0,1936 # ffffffffc0201cb0 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00001517          	auipc	a0,0x1
ffffffffc0200532:	79a50513          	addi	a0,a0,1946 # ffffffffc0201cc8 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	7a450513          	addi	a0,a0,1956 # ffffffffc0201ce0 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00001517          	auipc	a0,0x1
ffffffffc020054e:	7ae50513          	addi	a0,a0,1966 # ffffffffc0201cf8 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00001517          	auipc	a0,0x1
ffffffffc020055c:	7b850513          	addi	a0,a0,1976 # ffffffffc0201d10 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00001517          	auipc	a0,0x1
ffffffffc020056a:	7c250513          	addi	a0,a0,1986 # ffffffffc0201d28 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00001517          	auipc	a0,0x1
ffffffffc0200578:	7cc50513          	addi	a0,a0,1996 # ffffffffc0201d40 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00001517          	auipc	a0,0x1
ffffffffc0200586:	7d650513          	addi	a0,a0,2006 # ffffffffc0201d58 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00001517          	auipc	a0,0x1
ffffffffc0200594:	7e050513          	addi	a0,a0,2016 # ffffffffc0201d70 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00001517          	auipc	a0,0x1
ffffffffc02005a2:	7ea50513          	addi	a0,a0,2026 # ffffffffc0201d88 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00001517          	auipc	a0,0x1
ffffffffc02005b0:	7f450513          	addi	a0,a0,2036 # ffffffffc0201da0 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00001517          	auipc	a0,0x1
ffffffffc02005be:	7fe50513          	addi	a0,a0,2046 # ffffffffc0201db8 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	80850513          	addi	a0,a0,-2040 # ffffffffc0201dd0 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	81250513          	addi	a0,a0,-2030 # ffffffffc0201de8 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	81c50513          	addi	a0,a0,-2020 # ffffffffc0201e00 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	82650513          	addi	a0,a0,-2010 # ffffffffc0201e18 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	83050513          	addi	a0,a0,-2000 # ffffffffc0201e30 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	83a50513          	addi	a0,a0,-1990 # ffffffffc0201e48 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	84450513          	addi	a0,a0,-1980 # ffffffffc0201e60 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	84e50513          	addi	a0,a0,-1970 # ffffffffc0201e78 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	85450513          	addi	a0,a0,-1964 # ffffffffc0201e90 <commands+0x5a0>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	85650513          	addi	a0,a0,-1962 # ffffffffc0201ea8 <commands+0x5b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	85650513          	addi	a0,a0,-1962 # ffffffffc0201ec0 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0201ed8 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	86650513          	addi	a0,a0,-1946 # ffffffffc0201ef0 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201f08 <commands+0x618>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76563          	bltu	a4,a5,ffffffffc0200742 <interrupt_handler+0x96>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	3f070713          	addi	a4,a4,1008 # ffffffffc0201aac <commands+0x1bc>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	47250513          	addi	a0,a0,1138 # ffffffffc0201b40 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	44650513          	addi	a0,a0,1094 # ffffffffc0201b20 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	3fa50513          	addi	a0,a0,1018 # ffffffffc0201ae0 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	46e50513          	addi	a0,a0,1134 # ffffffffc0201b60 <commands+0x270>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200702:	d3fff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200706:	00006797          	auipc	a5,0x6
ffffffffc020070a:	d2a78793          	addi	a5,a5,-726 # ffffffffc0206430 <ticks>
ffffffffc020070e:	639c                	ld	a5,0(a5)
ffffffffc0200710:	06400713          	li	a4,100
ffffffffc0200714:	0785                	addi	a5,a5,1
ffffffffc0200716:	02e7f733          	remu	a4,a5,a4
ffffffffc020071a:	00006697          	auipc	a3,0x6
ffffffffc020071e:	d0f6bb23          	sd	a5,-746(a3) # ffffffffc0206430 <ticks>
ffffffffc0200722:	c315                	beqz	a4,ffffffffc0200746 <interrupt_handler+0x9a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200724:	60a2                	ld	ra,8(sp)
ffffffffc0200726:	0141                	addi	sp,sp,16
ffffffffc0200728:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	45e50513          	addi	a0,a0,1118 # ffffffffc0201b88 <commands+0x298>
ffffffffc0200732:	985ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200736:	00001517          	auipc	a0,0x1
ffffffffc020073a:	3ca50513          	addi	a0,a0,970 # ffffffffc0201b00 <commands+0x210>
ffffffffc020073e:	979ff06f          	j	ffffffffc02000b6 <cprintf>
            print_trapframe(tf);
ffffffffc0200742:	f09ff06f          	j	ffffffffc020064a <print_trapframe>
}
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200748:	06400593          	li	a1,100
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	42c50513          	addi	a0,a0,1068 # ffffffffc0201b78 <commands+0x288>
}
ffffffffc0200754:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200756:	961ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020075a <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc020075a:	11853783          	ld	a5,280(a0)
ffffffffc020075e:	0007c863          	bltz	a5,ffffffffc020076e <trap+0x14>
    switch (tf->cause) {
ffffffffc0200762:	472d                	li	a4,11
ffffffffc0200764:	00f76363          	bltu	a4,a5,ffffffffc020076a <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200768:	8082                	ret
            print_trapframe(tf);
ffffffffc020076a:	ee1ff06f          	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc020076e:	f3fff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc0200774 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200774:	14011073          	csrw	sscratch,sp
ffffffffc0200778:	712d                	addi	sp,sp,-288
ffffffffc020077a:	e002                	sd	zero,0(sp)
ffffffffc020077c:	e406                	sd	ra,8(sp)
ffffffffc020077e:	ec0e                	sd	gp,24(sp)
ffffffffc0200780:	f012                	sd	tp,32(sp)
ffffffffc0200782:	f416                	sd	t0,40(sp)
ffffffffc0200784:	f81a                	sd	t1,48(sp)
ffffffffc0200786:	fc1e                	sd	t2,56(sp)
ffffffffc0200788:	e0a2                	sd	s0,64(sp)
ffffffffc020078a:	e4a6                	sd	s1,72(sp)
ffffffffc020078c:	e8aa                	sd	a0,80(sp)
ffffffffc020078e:	ecae                	sd	a1,88(sp)
ffffffffc0200790:	f0b2                	sd	a2,96(sp)
ffffffffc0200792:	f4b6                	sd	a3,104(sp)
ffffffffc0200794:	f8ba                	sd	a4,112(sp)
ffffffffc0200796:	fcbe                	sd	a5,120(sp)
ffffffffc0200798:	e142                	sd	a6,128(sp)
ffffffffc020079a:	e546                	sd	a7,136(sp)
ffffffffc020079c:	e94a                	sd	s2,144(sp)
ffffffffc020079e:	ed4e                	sd	s3,152(sp)
ffffffffc02007a0:	f152                	sd	s4,160(sp)
ffffffffc02007a2:	f556                	sd	s5,168(sp)
ffffffffc02007a4:	f95a                	sd	s6,176(sp)
ffffffffc02007a6:	fd5e                	sd	s7,184(sp)
ffffffffc02007a8:	e1e2                	sd	s8,192(sp)
ffffffffc02007aa:	e5e6                	sd	s9,200(sp)
ffffffffc02007ac:	e9ea                	sd	s10,208(sp)
ffffffffc02007ae:	edee                	sd	s11,216(sp)
ffffffffc02007b0:	f1f2                	sd	t3,224(sp)
ffffffffc02007b2:	f5f6                	sd	t4,232(sp)
ffffffffc02007b4:	f9fa                	sd	t5,240(sp)
ffffffffc02007b6:	fdfe                	sd	t6,248(sp)
ffffffffc02007b8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007bc:	100024f3          	csrr	s1,sstatus
ffffffffc02007c0:	14102973          	csrr	s2,sepc
ffffffffc02007c4:	143029f3          	csrr	s3,stval
ffffffffc02007c8:	14202a73          	csrr	s4,scause
ffffffffc02007cc:	e822                	sd	s0,16(sp)
ffffffffc02007ce:	e226                	sd	s1,256(sp)
ffffffffc02007d0:	e64a                	sd	s2,264(sp)
ffffffffc02007d2:	ea4e                	sd	s3,272(sp)
ffffffffc02007d4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007d6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007d8:	f83ff0ef          	jal	ra,ffffffffc020075a <trap>

ffffffffc02007dc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007dc:	6492                	ld	s1,256(sp)
ffffffffc02007de:	6932                	ld	s2,264(sp)
ffffffffc02007e0:	10049073          	csrw	sstatus,s1
ffffffffc02007e4:	14191073          	csrw	sepc,s2
ffffffffc02007e8:	60a2                	ld	ra,8(sp)
ffffffffc02007ea:	61e2                	ld	gp,24(sp)
ffffffffc02007ec:	7202                	ld	tp,32(sp)
ffffffffc02007ee:	72a2                	ld	t0,40(sp)
ffffffffc02007f0:	7342                	ld	t1,48(sp)
ffffffffc02007f2:	73e2                	ld	t2,56(sp)
ffffffffc02007f4:	6406                	ld	s0,64(sp)
ffffffffc02007f6:	64a6                	ld	s1,72(sp)
ffffffffc02007f8:	6546                	ld	a0,80(sp)
ffffffffc02007fa:	65e6                	ld	a1,88(sp)
ffffffffc02007fc:	7606                	ld	a2,96(sp)
ffffffffc02007fe:	76a6                	ld	a3,104(sp)
ffffffffc0200800:	7746                	ld	a4,112(sp)
ffffffffc0200802:	77e6                	ld	a5,120(sp)
ffffffffc0200804:	680a                	ld	a6,128(sp)
ffffffffc0200806:	68aa                	ld	a7,136(sp)
ffffffffc0200808:	694a                	ld	s2,144(sp)
ffffffffc020080a:	69ea                	ld	s3,152(sp)
ffffffffc020080c:	7a0a                	ld	s4,160(sp)
ffffffffc020080e:	7aaa                	ld	s5,168(sp)
ffffffffc0200810:	7b4a                	ld	s6,176(sp)
ffffffffc0200812:	7bea                	ld	s7,184(sp)
ffffffffc0200814:	6c0e                	ld	s8,192(sp)
ffffffffc0200816:	6cae                	ld	s9,200(sp)
ffffffffc0200818:	6d4e                	ld	s10,208(sp)
ffffffffc020081a:	6dee                	ld	s11,216(sp)
ffffffffc020081c:	7e0e                	ld	t3,224(sp)
ffffffffc020081e:	7eae                	ld	t4,232(sp)
ffffffffc0200820:	7f4e                	ld	t5,240(sp)
ffffffffc0200822:	7fee                	ld	t6,248(sp)
ffffffffc0200824:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200826:	10200073          	sret

ffffffffc020082a <buddy_init>:
    return page - pages;
}
    
static void buddy_init() //初始化free_buddy结构体
{
    max_order = 0;
ffffffffc020082a:	00006797          	auipc	a5,0x6
ffffffffc020082e:	c007a723          	sw	zero,-1010(a5) # ffffffffc0206438 <free_buddy>
    nr_free = 0;
ffffffffc0200832:	00006797          	auipc	a5,0x6
ffffffffc0200836:	d407af23          	sw	zero,-674(a5) # ffffffffc0206590 <free_buddy+0x158>
    for (int i = 0; i < MAX_ORDER; ++i)
ffffffffc020083a:	00006797          	auipc	a5,0x6
ffffffffc020083e:	c0678793          	addi	a5,a5,-1018 # ffffffffc0206440 <free_buddy+0x8>
ffffffffc0200842:	00006717          	auipc	a4,0x6
ffffffffc0200846:	d3e70713          	addi	a4,a4,-706 # ffffffffc0206580 <free_buddy+0x148>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020084a:	e79c                	sd	a5,8(a5)
ffffffffc020084c:	e39c                	sd	a5,0(a5)
ffffffffc020084e:	07c1                	addi	a5,a5,16
ffffffffc0200850:	fee79de3          	bne	a5,a4,ffffffffc020084a <buddy_init+0x20>
        list_init(free_array + i);
}
ffffffffc0200854:	8082                	ret

ffffffffc0200856 <buddy_nr_free_pages>:


static size_t buddy_nr_free_pages()
{
    return nr_free;
}
ffffffffc0200856:	00006517          	auipc	a0,0x6
ffffffffc020085a:	d3a56503          	lwu	a0,-710(a0) # ffffffffc0206590 <free_buddy+0x158>
ffffffffc020085e:	8082                	ret

ffffffffc0200860 <buddy_free_pages>:
{
ffffffffc0200860:	1141                	addi	sp,sp,-16
ffffffffc0200862:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200864:	12058963          	beqz	a1,ffffffffc0200996 <buddy_free_pages+0x136>
    unsigned int order = base->property;
ffffffffc0200868:	01052803          	lw	a6,16(a0)
    size_t pn = (1 << order);
ffffffffc020086c:	4e85                	li	t4,1
    while (n > 1)
ffffffffc020086e:	4785                	li	a5,1
    size_t pn = (1 << order);
ffffffffc0200870:	010e9ebb          	sllw	t4,t4,a6
ffffffffc0200874:	000e861b          	sext.w	a2,t4
    while (n > 1)
ffffffffc0200878:	0eb7fd63          	bleu	a1,a5,ffffffffc0200972 <buddy_free_pages+0x112>
ffffffffc020087c:	87ae                	mv	a5,a1
    size_t ret = 1;
ffffffffc020087e:	4705                	li	a4,1
    while (n > 1)
ffffffffc0200880:	4685                	li	a3,1
        n >>= 1;
ffffffffc0200882:	8385                	srli	a5,a5,0x1
        ret <<= 1;
ffffffffc0200884:	0706                	slli	a4,a4,0x1
    while (n > 1)
ffffffffc0200886:	fed79ee3          	bne	a5,a3,ffffffffc0200882 <buddy_free_pages+0x22>
    return n == ret ? ret : (ret << 1);
ffffffffc020088a:	00e58363          	beq	a1,a4,ffffffffc0200890 <buddy_free_pages+0x30>
ffffffffc020088e:	0706                	slli	a4,a4,0x1
    assert(pn == ROUNDUP_POWER_OF_2(n));
ffffffffc0200890:	0ee61363          	bne	a2,a4,ffffffffc0200976 <buddy_free_pages+0x116>
    return page - pages;
ffffffffc0200894:	00006797          	auipc	a5,0x6
ffffffffc0200898:	d1c78793          	addi	a5,a5,-740 # ffffffffc02065b0 <pages>
ffffffffc020089c:	639c                	ld	a5,0(a5)
ffffffffc020089e:	00002697          	auipc	a3,0x2
ffffffffc02008a2:	83a68693          	addi	a3,a3,-1990 # ffffffffc02020d8 <buddySystem+0x38>
ffffffffc02008a6:	6294                	ld	a3,0(a3)
ffffffffc02008a8:	40f50733          	sub	a4,a0,a5
ffffffffc02008ac:	870d                	srai	a4,a4,0x3
ffffffffc02008ae:	02d70733          	mul	a4,a4,a3
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
ffffffffc02008b2:	02081693          	slli	a3,a6,0x20
ffffffffc02008b6:	9281                	srli	a3,a3,0x20
ffffffffc02008b8:	00006897          	auipc	a7,0x6
ffffffffc02008bc:	b8088893          	addi	a7,a7,-1152 # ffffffffc0206438 <free_buddy>
ffffffffc02008c0:	0692                	slli	a3,a3,0x4
ffffffffc02008c2:	00d88e33          	add	t3,a7,a3
ffffffffc02008c6:	010e3303          	ld	t1,16(t3)
    list_add(&(free_array[order]), &(left_block->page_link));   //把要释放的块先放入空表内
ffffffffc02008ca:	01850593          	addi	a1,a0,24
ffffffffc02008ce:	06a1                	addi	a3,a3,8
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02008d0:	00b33023          	sd	a1,0(t1)
    unsigned int buddy_idx = page2idx(page) ^ (1 << order);
ffffffffc02008d4:	01d74733          	xor	a4,a4,t4
    return pages + buddy_idx;
ffffffffc02008d8:	1702                	slli	a4,a4,0x20
ffffffffc02008da:	9301                	srli	a4,a4,0x20
ffffffffc02008dc:	00271613          	slli	a2,a4,0x2
    while (left_block->property < max_order && PageProperty(buddy)) //满足合并条件
ffffffffc02008e0:	0008af03          	lw	t5,0(a7)
ffffffffc02008e4:	00be3823          	sd	a1,16(t3)
    list_add(&(free_array[order]), &(left_block->page_link));   //把要释放的块先放入空表内
ffffffffc02008e8:	96c6                	add	a3,a3,a7
    return pages + buddy_idx;
ffffffffc02008ea:	9732                	add	a4,a4,a2
ffffffffc02008ec:	070e                	slli	a4,a4,0x3
    elm->next = next;
ffffffffc02008ee:	02653023          	sd	t1,32(a0)
    elm->prev = prev;
ffffffffc02008f2:	ed14                	sd	a3,24(a0)
ffffffffc02008f4:	97ba                	add	a5,a5,a4
    while (left_block->property < max_order && PageProperty(buddy)) //满足合并条件
ffffffffc02008f6:	07e87363          	bleu	t5,a6,ffffffffc020095c <buddy_free_pages+0xfc>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02008fa:	6798                	ld	a4,8(a5)
ffffffffc02008fc:	8305                	srli	a4,a4,0x1
ffffffffc02008fe:	8b05                	andi	a4,a4,1
ffffffffc0200900:	cf31                	beqz	a4,ffffffffc020095c <buddy_free_pages+0xfc>
ffffffffc0200902:	00878613          	addi	a2,a5,8
ffffffffc0200906:	00850693          	addi	a3,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020090a:	4e09                	li	t3,2
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020090c:	5375                	li	t1,-3
        if (left_block > buddy) //若left_block在右边，调换位置
ffffffffc020090e:	00a7f863          	bleu	a0,a5,ffffffffc020091e <buddy_free_pages+0xbe>
ffffffffc0200912:	85b6                	mv	a1,a3
ffffffffc0200914:	872a                	mv	a4,a0
ffffffffc0200916:	86b2                	mv	a3,a2
ffffffffc0200918:	853e                	mv	a0,a5
ffffffffc020091a:	862e                	mv	a2,a1
ffffffffc020091c:	87ba                	mv	a5,a4
    __list_del(listelm->prev, listelm->next);
ffffffffc020091e:	01853803          	ld	a6,24(a0)
ffffffffc0200922:	710c                	ld	a1,32(a0)
        left_block->property += 1;
ffffffffc0200924:	4918                	lw	a4,16(a0)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200926:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc020092a:	0105b023          	sd	a6,0(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc020092e:	0187b803          	ld	a6,24(a5)
ffffffffc0200932:	738c                	ld	a1,32(a5)
ffffffffc0200934:	2705                	addiw	a4,a4,1
    prev->next = next;
ffffffffc0200936:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc020093a:	0105b023          	sd	a6,0(a1)
ffffffffc020093e:	c918                	sw	a4,16(a0)
        buddy->property = 0;
ffffffffc0200940:	0007a823          	sw	zero,16(a5)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200944:	41c6b02f          	amoor.d	zero,t3,(a3)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200948:	6066302f          	amoand.d	zero,t1,(a2)
    while (left_block->property < max_order && PageProperty(buddy)) //满足合并条件
ffffffffc020094c:	490c                	lw	a1,16(a0)
ffffffffc020094e:	0008a703          	lw	a4,0(a7)
ffffffffc0200952:	00e5f563          	bleu	a4,a1,ffffffffc020095c <buddy_free_pages+0xfc>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200956:	6798                	ld	a4,8(a5)
ffffffffc0200958:	8b09                	andi	a4,a4,2
ffffffffc020095a:	fb55                	bnez	a4,ffffffffc020090e <buddy_free_pages+0xae>
    nr_free += pn;
ffffffffc020095c:	1588a783          	lw	a5,344(a7)
}
ffffffffc0200960:	60a2                	ld	ra,8(sp)
    nr_free += pn;
ffffffffc0200962:	01d78ebb          	addw	t4,a5,t4
ffffffffc0200966:	00006797          	auipc	a5,0x6
ffffffffc020096a:	c3d7a523          	sw	t4,-982(a5) # ffffffffc0206590 <free_buddy+0x158>
}
ffffffffc020096e:	0141                	addi	sp,sp,16
ffffffffc0200970:	8082                	ret
    size_t ret = 1;
ffffffffc0200972:	4705                	li	a4,1
ffffffffc0200974:	bf19                	j	ffffffffc020088a <buddy_free_pages+0x2a>
    assert(pn == ROUNDUP_POWER_OF_2(n));
ffffffffc0200976:	00001697          	auipc	a3,0x1
ffffffffc020097a:	7a268693          	addi	a3,a3,1954 # ffffffffc0202118 <buddySystem+0x78>
ffffffffc020097e:	00001617          	auipc	a2,0x1
ffffffffc0200982:	76a60613          	addi	a2,a2,1898 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200986:	08800593          	li	a1,136
ffffffffc020098a:	00001517          	auipc	a0,0x1
ffffffffc020098e:	77650513          	addi	a0,a0,1910 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200992:	a1bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200996:	00001697          	auipc	a3,0x1
ffffffffc020099a:	74a68693          	addi	a3,a3,1866 # ffffffffc02020e0 <buddySystem+0x40>
ffffffffc020099e:	00001617          	auipc	a2,0x1
ffffffffc02009a2:	74a60613          	addi	a2,a2,1866 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc02009a6:	08500593          	li	a1,133
ffffffffc02009aa:	00001517          	auipc	a0,0x1
ffffffffc02009ae:	75650513          	addi	a0,a0,1878 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc02009b2:	9fbff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02009b6 <buddy_split>:
{
ffffffffc02009b6:	7179                	addi	sp,sp,-48
ffffffffc02009b8:	f406                	sd	ra,40(sp)
ffffffffc02009ba:	f022                	sd	s0,32(sp)
ffffffffc02009bc:	ec26                	sd	s1,24(sp)
ffffffffc02009be:	e84a                	sd	s2,16(sp)
ffffffffc02009c0:	e44e                	sd	s3,8(sp)
    assert(order > 0 && order <= max_order);
ffffffffc02009c2:	c145                	beqz	a0,ffffffffc0200a62 <buddy_split+0xac>
ffffffffc02009c4:	00006797          	auipc	a5,0x6
ffffffffc02009c8:	a747e783          	lwu	a5,-1420(a5) # ffffffffc0206438 <free_buddy>
ffffffffc02009cc:	842a                	mv	s0,a0
ffffffffc02009ce:	00006497          	auipc	s1,0x6
ffffffffc02009d2:	a6a48493          	addi	s1,s1,-1430 # ffffffffc0206438 <free_buddy>
ffffffffc02009d6:	08a7e663          	bltu	a5,a0,ffffffffc0200a62 <buddy_split+0xac>
    return list->next == list;
ffffffffc02009da:	00451913          	slli	s2,a0,0x4
ffffffffc02009de:	012489b3          	add	s3,s1,s2
ffffffffc02009e2:	0109b703          	ld	a4,16(s3)
    if (list_empty(&(free_array[order])))   //当前order没有空闲块，递归
ffffffffc02009e6:	00890793          	addi	a5,s2,8
ffffffffc02009ea:	97a6                	add	a5,a5,s1
ffffffffc02009ec:	06f70563          	beq	a4,a5,ffffffffc0200a56 <buddy_split+0xa0>
    page_left->property -= 1;
ffffffffc02009f0:	ff872683          	lw	a3,-8(a4)
    struct Page *page_right = page_left + (1 << (page_left->property));
ffffffffc02009f4:	4785                	li	a5,1
    page_left->property -= 1;
ffffffffc02009f6:	36fd                	addiw	a3,a3,-1
    struct Page *page_right = page_left + (1 << (page_left->property));
ffffffffc02009f8:	00d7963b          	sllw	a2,a5,a3
ffffffffc02009fc:	00261793          	slli	a5,a2,0x2
ffffffffc0200a00:	97b2                	add	a5,a5,a2
ffffffffc0200a02:	078e                	slli	a5,a5,0x3
ffffffffc0200a04:	17a1                	addi	a5,a5,-24
ffffffffc0200a06:	97ba                	add	a5,a5,a4
    page_left->property -= 1;
ffffffffc0200a08:	fed72c23          	sw	a3,-8(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200a0c:	00878613          	addi	a2,a5,8
ffffffffc0200a10:	4689                	li	a3,2
ffffffffc0200a12:	40d6302f          	amoor.d	zero,a3,(a2)
    return listelm->next;
ffffffffc0200a16:	9926                	add	s2,s2,s1
ffffffffc0200a18:	01093683          	ld	a3,16(s2)
    page_right->property = page_left->property;
ffffffffc0200a1c:	ff872603          	lw	a2,-8(a4)
    list_add(&(free_array[order - 1]), &(page_left->page_link));
ffffffffc0200a20:	147d                	addi	s0,s0,-1
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a22:	628c                	ld	a1,0(a3)
ffffffffc0200a24:	6694                	ld	a3,8(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a26:	0412                	slli	s0,s0,0x4
    page_right->property = page_left->property;
ffffffffc0200a28:	cb90                	sw	a2,16(a5)
    prev->next = next;
ffffffffc0200a2a:	e594                	sd	a3,8(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a2c:	00848633          	add	a2,s1,s0
    next->prev = prev;
ffffffffc0200a30:	e28c                	sd	a1,0(a3)
    list_add(&(free_array[order - 1]), &(page_left->page_link));
ffffffffc0200a32:	0421                	addi	s0,s0,8
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a34:	6a14                	ld	a3,16(a2)
ffffffffc0200a36:	9426                	add	s0,s0,s1
    prev->next = next->prev = elm;
ffffffffc0200a38:	ea18                	sd	a4,16(a2)
    elm->prev = prev;
ffffffffc0200a3a:	e300                	sd	s0,0(a4)
    list_add(&(page_left->page_link), &(page_right->page_link));
ffffffffc0200a3c:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc0200a40:	e290                	sd	a2,0(a3)
}
ffffffffc0200a42:	70a2                	ld	ra,40(sp)
ffffffffc0200a44:	7402                	ld	s0,32(sp)
ffffffffc0200a46:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200a48:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200a4a:	ef98                	sd	a4,24(a5)
ffffffffc0200a4c:	64e2                	ld	s1,24(sp)
ffffffffc0200a4e:	6942                	ld	s2,16(sp)
ffffffffc0200a50:	69a2                	ld	s3,8(sp)
ffffffffc0200a52:	6145                	addi	sp,sp,48
ffffffffc0200a54:	8082                	ret
        buddy_split(order + 1);
ffffffffc0200a56:	0505                	addi	a0,a0,1
ffffffffc0200a58:	f5fff0ef          	jal	ra,ffffffffc02009b6 <buddy_split>
ffffffffc0200a5c:	0109b703          	ld	a4,16(s3)
ffffffffc0200a60:	bf41                	j	ffffffffc02009f0 <buddy_split+0x3a>
    assert(order > 0 && order <= max_order);
ffffffffc0200a62:	00001697          	auipc	a3,0x1
ffffffffc0200a66:	6e668693          	addi	a3,a3,1766 # ffffffffc0202148 <buddySystem+0xa8>
ffffffffc0200a6a:	00001617          	auipc	a2,0x1
ffffffffc0200a6e:	67e60613          	addi	a2,a2,1662 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200a72:	05600593          	li	a1,86
ffffffffc0200a76:	00001517          	auipc	a0,0x1
ffffffffc0200a7a:	68a50513          	addi	a0,a0,1674 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200a7e:	92fff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200a82 <basic_check>:

static void
basic_check(void) {
ffffffffc0200a82:	7139                	addi	sp,sp,-64
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a84:	4505                	li	a0,1
basic_check(void) {
ffffffffc0200a86:	fc06                	sd	ra,56(sp)
ffffffffc0200a88:	f822                	sd	s0,48(sp)
ffffffffc0200a8a:	f426                	sd	s1,40(sp)
ffffffffc0200a8c:	f04a                	sd	s2,32(sp)
ffffffffc0200a8e:	ec4e                	sd	s3,24(sp)
ffffffffc0200a90:	e852                	sd	s4,16(sp)
ffffffffc0200a92:	e456                	sd	s5,8(sp)
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a94:	572000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200a98:	2c050163          	beqz	a0,ffffffffc0200d5a <basic_check+0x2d8>
ffffffffc0200a9c:	842a                	mv	s0,a0
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a9e:	4505                	li	a0,1
ffffffffc0200aa0:	566000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200aa4:	84aa                	mv	s1,a0
ffffffffc0200aa6:	28050a63          	beqz	a0,ffffffffc0200d3a <basic_check+0x2b8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aaa:	4505                	li	a0,1
ffffffffc0200aac:	55a000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200ab0:	892a                	mv	s2,a0
ffffffffc0200ab2:	26050463          	beqz	a0,ffffffffc0200d1a <basic_check+0x298>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ab6:	14940263          	beq	s0,s1,ffffffffc0200bfa <basic_check+0x178>
ffffffffc0200aba:	14a40063          	beq	s0,a0,ffffffffc0200bfa <basic_check+0x178>
ffffffffc0200abe:	12a48e63          	beq	s1,a0,ffffffffc0200bfa <basic_check+0x178>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ac2:	401c                	lw	a5,0(s0)
ffffffffc0200ac4:	14079b63          	bnez	a5,ffffffffc0200c1a <basic_check+0x198>
ffffffffc0200ac8:	409c                	lw	a5,0(s1)
ffffffffc0200aca:	14079863          	bnez	a5,ffffffffc0200c1a <basic_check+0x198>
ffffffffc0200ace:	411c                	lw	a5,0(a0)
ffffffffc0200ad0:	14079563          	bnez	a5,ffffffffc0200c1a <basic_check+0x198>
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

//
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ad4:	00006797          	auipc	a5,0x6
ffffffffc0200ad8:	adc78793          	addi	a5,a5,-1316 # ffffffffc02065b0 <pages>
ffffffffc0200adc:	639c                	ld	a5,0(a5)
ffffffffc0200ade:	00001597          	auipc	a1,0x1
ffffffffc0200ae2:	5fa58593          	addi	a1,a1,1530 # ffffffffc02020d8 <buddySystem+0x38>
ffffffffc0200ae6:	6194                	ld	a3,0(a1)
ffffffffc0200ae8:	40f40733          	sub	a4,s0,a5
ffffffffc0200aec:	870d                	srai	a4,a4,0x3
ffffffffc0200aee:	02d70733          	mul	a4,a4,a3
ffffffffc0200af2:	00002697          	auipc	a3,0x2
ffffffffc0200af6:	9f668693          	addi	a3,a3,-1546 # ffffffffc02024e8 <nbase>
ffffffffc0200afa:	6290                	ld	a2,0(a3)

    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200afc:	00006697          	auipc	a3,0x6
ffffffffc0200b00:	91c68693          	addi	a3,a3,-1764 # ffffffffc0206418 <npage>
ffffffffc0200b04:	6294                	ld	a3,0(a3)
ffffffffc0200b06:	06b2                	slli	a3,a3,0xc
ffffffffc0200b08:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b0a:	0732                	slli	a4,a4,0xc
ffffffffc0200b0c:	12d77763          	bleu	a3,a4,ffffffffc0200c3a <basic_check+0x1b8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b10:	618c                	ld	a1,0(a1)
ffffffffc0200b12:	40f48733          	sub	a4,s1,a5
ffffffffc0200b16:	870d                	srai	a4,a4,0x3
ffffffffc0200b18:	02b70733          	mul	a4,a4,a1
ffffffffc0200b1c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b1e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b20:	14d77d63          	bleu	a3,a4,ffffffffc0200c7a <basic_check+0x1f8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b24:	40f507b3          	sub	a5,a0,a5
ffffffffc0200b28:	878d                	srai	a5,a5,0x3
ffffffffc0200b2a:	02b787b3          	mul	a5,a5,a1
ffffffffc0200b2e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b30:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b32:	12d7f463          	bleu	a3,a5,ffffffffc0200c5a <basic_check+0x1d8>

    //list_entry_t free_list_store = free_list;
    // list_init(&free_list);
    // assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
ffffffffc0200b36:	00006997          	auipc	s3,0x6
ffffffffc0200b3a:	90298993          	addi	s3,s3,-1790 # ffffffffc0206438 <free_buddy>
    nr_free = 0;

    assert(alloc_page() == NULL);
ffffffffc0200b3e:	4505                	li	a0,1
    unsigned int nr_free_store = nr_free;
ffffffffc0200b40:	1589aa83          	lw	s5,344(s3)
    nr_free = 0;
ffffffffc0200b44:	00006797          	auipc	a5,0x6
ffffffffc0200b48:	a407a623          	sw	zero,-1460(a5) # ffffffffc0206590 <free_buddy+0x158>
    assert(alloc_page() == NULL);
ffffffffc0200b4c:	4ba000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200b50:	1a051563          	bnez	a0,ffffffffc0200cfa <basic_check+0x278>

    free_page(p0);
ffffffffc0200b54:	4585                	li	a1,1
ffffffffc0200b56:	8522                	mv	a0,s0
ffffffffc0200b58:	4f2000ef          	jal	ra,ffffffffc020104a <free_pages>
    free_page(p1);
ffffffffc0200b5c:	4585                	li	a1,1
ffffffffc0200b5e:	8526                	mv	a0,s1
ffffffffc0200b60:	4ea000ef          	jal	ra,ffffffffc020104a <free_pages>
    free_page(p2);
ffffffffc0200b64:	4585                	li	a1,1
ffffffffc0200b66:	854a                	mv	a0,s2
ffffffffc0200b68:	4e2000ef          	jal	ra,ffffffffc020104a <free_pages>
    assert(nr_free == 3);
ffffffffc0200b6c:	1589a703          	lw	a4,344(s3)
ffffffffc0200b70:	478d                	li	a5,3
ffffffffc0200b72:	16f71463          	bne	a4,a5,ffffffffc0200cda <basic_check+0x258>

    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b76:	4505                	li	a0,1
ffffffffc0200b78:	48e000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200b7c:	842a                	mv	s0,a0
ffffffffc0200b7e:	12050e63          	beqz	a0,ffffffffc0200cba <basic_check+0x238>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b82:	4505                	li	a0,1
ffffffffc0200b84:	482000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200b88:	84aa                	mv	s1,a0
ffffffffc0200b8a:	10050863          	beqz	a0,ffffffffc0200c9a <basic_check+0x218>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b8e:	4505                	li	a0,1
ffffffffc0200b90:	476000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200b94:	892a                	mv	s2,a0
ffffffffc0200b96:	26050263          	beqz	a0,ffffffffc0200dfa <basic_check+0x378>

    assert(alloc_page() == NULL);
ffffffffc0200b9a:	4505                	li	a0,1
ffffffffc0200b9c:	46a000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200ba0:	22051d63          	bnez	a0,ffffffffc0200dda <basic_check+0x358>

    free_page(p0);
ffffffffc0200ba4:	4585                	li	a1,1
ffffffffc0200ba6:	8522                	mv	a0,s0
ffffffffc0200ba8:	4a2000ef          	jal	ra,ffffffffc020104a <free_pages>
    // assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
ffffffffc0200bac:	4505                	li	a0,1
ffffffffc0200bae:	458000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200bb2:	8a2a                	mv	s4,a0
ffffffffc0200bb4:	20a41363          	bne	s0,a0,ffffffffc0200dba <basic_check+0x338>
    assert(alloc_page() == NULL);
ffffffffc0200bb8:	4505                	li	a0,1
ffffffffc0200bba:	44c000ef          	jal	ra,ffffffffc0201006 <alloc_pages>
ffffffffc0200bbe:	1c051e63          	bnez	a0,ffffffffc0200d9a <basic_check+0x318>

    assert(nr_free == 0);
ffffffffc0200bc2:	1589a783          	lw	a5,344(s3)
ffffffffc0200bc6:	1a079a63          	bnez	a5,ffffffffc0200d7a <basic_check+0x2f8>
    //free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
ffffffffc0200bca:	8552                	mv	a0,s4
ffffffffc0200bcc:	4585                	li	a1,1
    nr_free = nr_free_store;
ffffffffc0200bce:	00006797          	auipc	a5,0x6
ffffffffc0200bd2:	9d57a123          	sw	s5,-1598(a5) # ffffffffc0206590 <free_buddy+0x158>
    free_page(p);
ffffffffc0200bd6:	474000ef          	jal	ra,ffffffffc020104a <free_pages>
    free_page(p1);
ffffffffc0200bda:	8526                	mv	a0,s1
ffffffffc0200bdc:	4585                	li	a1,1
ffffffffc0200bde:	46c000ef          	jal	ra,ffffffffc020104a <free_pages>
    free_page(p2);
}
ffffffffc0200be2:	7442                	ld	s0,48(sp)
ffffffffc0200be4:	70e2                	ld	ra,56(sp)
ffffffffc0200be6:	74a2                	ld	s1,40(sp)
ffffffffc0200be8:	69e2                	ld	s3,24(sp)
ffffffffc0200bea:	6a42                	ld	s4,16(sp)
ffffffffc0200bec:	6aa2                	ld	s5,8(sp)
    free_page(p2);
ffffffffc0200bee:	854a                	mv	a0,s2
}
ffffffffc0200bf0:	7902                	ld	s2,32(sp)
    free_page(p2);
ffffffffc0200bf2:	4585                	li	a1,1
}
ffffffffc0200bf4:	6121                	addi	sp,sp,64
    free_page(p2);
ffffffffc0200bf6:	4540006f          	j	ffffffffc020104a <free_pages>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200bfa:	00001697          	auipc	a3,0x1
ffffffffc0200bfe:	38668693          	addi	a3,a3,902 # ffffffffc0201f80 <commands+0x690>
ffffffffc0200c02:	00001617          	auipc	a2,0x1
ffffffffc0200c06:	4e660613          	addi	a2,a2,1254 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200c0a:	0b000593          	li	a1,176
ffffffffc0200c0e:	00001517          	auipc	a0,0x1
ffffffffc0200c12:	4f250513          	addi	a0,a0,1266 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200c16:	f96ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c1a:	00001697          	auipc	a3,0x1
ffffffffc0200c1e:	38e68693          	addi	a3,a3,910 # ffffffffc0201fa8 <commands+0x6b8>
ffffffffc0200c22:	00001617          	auipc	a2,0x1
ffffffffc0200c26:	4c660613          	addi	a2,a2,1222 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200c2a:	0b100593          	li	a1,177
ffffffffc0200c2e:	00001517          	auipc	a0,0x1
ffffffffc0200c32:	4d250513          	addi	a0,a0,1234 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200c36:	f76ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c3a:	00001697          	auipc	a3,0x1
ffffffffc0200c3e:	3ae68693          	addi	a3,a3,942 # ffffffffc0201fe8 <commands+0x6f8>
ffffffffc0200c42:	00001617          	auipc	a2,0x1
ffffffffc0200c46:	4a660613          	addi	a2,a2,1190 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200c4a:	0b300593          	li	a1,179
ffffffffc0200c4e:	00001517          	auipc	a0,0x1
ffffffffc0200c52:	4b250513          	addi	a0,a0,1202 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200c56:	f56ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200c5a:	00001697          	auipc	a3,0x1
ffffffffc0200c5e:	3ce68693          	addi	a3,a3,974 # ffffffffc0202028 <commands+0x738>
ffffffffc0200c62:	00001617          	auipc	a2,0x1
ffffffffc0200c66:	48660613          	addi	a2,a2,1158 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200c6a:	0b500593          	li	a1,181
ffffffffc0200c6e:	00001517          	auipc	a0,0x1
ffffffffc0200c72:	49250513          	addi	a0,a0,1170 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200c76:	f36ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c7a:	00001697          	auipc	a3,0x1
ffffffffc0200c7e:	38e68693          	addi	a3,a3,910 # ffffffffc0202008 <commands+0x718>
ffffffffc0200c82:	00001617          	auipc	a2,0x1
ffffffffc0200c86:	46660613          	addi	a2,a2,1126 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200c8a:	0b400593          	li	a1,180
ffffffffc0200c8e:	00001517          	auipc	a0,0x1
ffffffffc0200c92:	47250513          	addi	a0,a0,1138 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200c96:	f16ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c9a:	00001697          	auipc	a3,0x1
ffffffffc0200c9e:	2a668693          	addi	a3,a3,678 # ffffffffc0201f40 <commands+0x650>
ffffffffc0200ca2:	00001617          	auipc	a2,0x1
ffffffffc0200ca6:	44660613          	addi	a2,a2,1094 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200caa:	0c600593          	li	a1,198
ffffffffc0200cae:	00001517          	auipc	a0,0x1
ffffffffc0200cb2:	45250513          	addi	a0,a0,1106 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200cb6:	ef6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cba:	00001697          	auipc	a3,0x1
ffffffffc0200cbe:	26668693          	addi	a3,a3,614 # ffffffffc0201f20 <commands+0x630>
ffffffffc0200cc2:	00001617          	auipc	a2,0x1
ffffffffc0200cc6:	42660613          	addi	a2,a2,1062 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200cca:	0c500593          	li	a1,197
ffffffffc0200cce:	00001517          	auipc	a0,0x1
ffffffffc0200cd2:	43250513          	addi	a0,a0,1074 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200cd6:	ed6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200cda:	00001697          	auipc	a3,0x1
ffffffffc0200cde:	38668693          	addi	a3,a3,902 # ffffffffc0202060 <commands+0x770>
ffffffffc0200ce2:	00001617          	auipc	a2,0x1
ffffffffc0200ce6:	40660613          	addi	a2,a2,1030 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200cea:	0c300593          	li	a1,195
ffffffffc0200cee:	00001517          	auipc	a0,0x1
ffffffffc0200cf2:	41250513          	addi	a0,a0,1042 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200cf6:	eb6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cfa:	00001697          	auipc	a3,0x1
ffffffffc0200cfe:	34e68693          	addi	a3,a3,846 # ffffffffc0202048 <commands+0x758>
ffffffffc0200d02:	00001617          	auipc	a2,0x1
ffffffffc0200d06:	3e660613          	addi	a2,a2,998 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200d0a:	0be00593          	li	a1,190
ffffffffc0200d0e:	00001517          	auipc	a0,0x1
ffffffffc0200d12:	3f250513          	addi	a0,a0,1010 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200d16:	e96ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d1a:	00001697          	auipc	a3,0x1
ffffffffc0200d1e:	24668693          	addi	a3,a3,582 # ffffffffc0201f60 <commands+0x670>
ffffffffc0200d22:	00001617          	auipc	a2,0x1
ffffffffc0200d26:	3c660613          	addi	a2,a2,966 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200d2a:	0ae00593          	li	a1,174
ffffffffc0200d2e:	00001517          	auipc	a0,0x1
ffffffffc0200d32:	3d250513          	addi	a0,a0,978 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200d36:	e76ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d3a:	00001697          	auipc	a3,0x1
ffffffffc0200d3e:	20668693          	addi	a3,a3,518 # ffffffffc0201f40 <commands+0x650>
ffffffffc0200d42:	00001617          	auipc	a2,0x1
ffffffffc0200d46:	3a660613          	addi	a2,a2,934 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200d4a:	0ad00593          	li	a1,173
ffffffffc0200d4e:	00001517          	auipc	a0,0x1
ffffffffc0200d52:	3b250513          	addi	a0,a0,946 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200d56:	e56ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d5a:	00001697          	auipc	a3,0x1
ffffffffc0200d5e:	1c668693          	addi	a3,a3,454 # ffffffffc0201f20 <commands+0x630>
ffffffffc0200d62:	00001617          	auipc	a2,0x1
ffffffffc0200d66:	38660613          	addi	a2,a2,902 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200d6a:	0ac00593          	li	a1,172
ffffffffc0200d6e:	00001517          	auipc	a0,0x1
ffffffffc0200d72:	39250513          	addi	a0,a0,914 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200d76:	e36ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200d7a:	00001697          	auipc	a3,0x1
ffffffffc0200d7e:	31668693          	addi	a3,a3,790 # ffffffffc0202090 <commands+0x7a0>
ffffffffc0200d82:	00001617          	auipc	a2,0x1
ffffffffc0200d86:	36660613          	addi	a2,a2,870 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200d8a:	0d200593          	li	a1,210
ffffffffc0200d8e:	00001517          	auipc	a0,0x1
ffffffffc0200d92:	37250513          	addi	a0,a0,882 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200d96:	e16ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d9a:	00001697          	auipc	a3,0x1
ffffffffc0200d9e:	2ae68693          	addi	a3,a3,686 # ffffffffc0202048 <commands+0x758>
ffffffffc0200da2:	00001617          	auipc	a2,0x1
ffffffffc0200da6:	34660613          	addi	a2,a2,838 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200daa:	0d000593          	li	a1,208
ffffffffc0200dae:	00001517          	auipc	a0,0x1
ffffffffc0200db2:	35250513          	addi	a0,a0,850 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200db6:	df6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200dba:	00001697          	auipc	a3,0x1
ffffffffc0200dbe:	2b668693          	addi	a3,a3,694 # ffffffffc0202070 <commands+0x780>
ffffffffc0200dc2:	00001617          	auipc	a2,0x1
ffffffffc0200dc6:	32660613          	addi	a2,a2,806 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200dca:	0cf00593          	li	a1,207
ffffffffc0200dce:	00001517          	auipc	a0,0x1
ffffffffc0200dd2:	33250513          	addi	a0,a0,818 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200dd6:	dd6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200dda:	00001697          	auipc	a3,0x1
ffffffffc0200dde:	26e68693          	addi	a3,a3,622 # ffffffffc0202048 <commands+0x758>
ffffffffc0200de2:	00001617          	auipc	a2,0x1
ffffffffc0200de6:	30660613          	addi	a2,a2,774 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200dea:	0c900593          	li	a1,201
ffffffffc0200dee:	00001517          	auipc	a0,0x1
ffffffffc0200df2:	31250513          	addi	a0,a0,786 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200df6:	db6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dfa:	00001697          	auipc	a3,0x1
ffffffffc0200dfe:	16668693          	addi	a3,a3,358 # ffffffffc0201f60 <commands+0x670>
ffffffffc0200e02:	00001617          	auipc	a2,0x1
ffffffffc0200e06:	2e660613          	addi	a2,a2,742 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200e0a:	0c700593          	li	a1,199
ffffffffc0200e0e:	00001517          	auipc	a0,0x1
ffffffffc0200e12:	2f250513          	addi	a0,a0,754 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200e16:	d96ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200e1a <buddy_alloc_pages>:
{
ffffffffc0200e1a:	1101                	addi	sp,sp,-32
ffffffffc0200e1c:	ec06                	sd	ra,24(sp)
ffffffffc0200e1e:	e822                	sd	s0,16(sp)
ffffffffc0200e20:	e426                	sd	s1,8(sp)
ffffffffc0200e22:	e04a                	sd	s2,0(sp)
    assert(n > 0);
ffffffffc0200e24:	c571                	beqz	a0,ffffffffc0200ef0 <buddy_alloc_pages+0xd6>
    if (n > nr_free) return NULL;
ffffffffc0200e26:	00005797          	auipc	a5,0x5
ffffffffc0200e2a:	76a7e783          	lwu	a5,1898(a5) # ffffffffc0206590 <free_buddy+0x158>
ffffffffc0200e2e:	08a7ee63          	bltu	a5,a0,ffffffffc0200eca <buddy_alloc_pages+0xb0>
    while (n > 1)
ffffffffc0200e32:	4785                	li	a5,1
ffffffffc0200e34:	0af50963          	beq	a0,a5,ffffffffc0200ee6 <buddy_alloc_pages+0xcc>
ffffffffc0200e38:	872a                	mv	a4,a0
    size_t ret = 1;
ffffffffc0200e3a:	4685                	li	a3,1
    while (n > 1)
ffffffffc0200e3c:	4605                	li	a2,1
ffffffffc0200e3e:	a011                	j	ffffffffc0200e42 <buddy_alloc_pages+0x28>
        ret <<= 1;
ffffffffc0200e40:	86be                	mv	a3,a5
        n >>= 1;
ffffffffc0200e42:	8305                	srli	a4,a4,0x1
        ret <<= 1;
ffffffffc0200e44:	00169793          	slli	a5,a3,0x1
    while (n > 1)
ffffffffc0200e48:	fec71ce3          	bne	a4,a2,ffffffffc0200e40 <buddy_alloc_pages+0x26>
    return n == ret ? ret : (ret << 1);
ffffffffc0200e4c:	06f50863          	beq	a0,a5,ffffffffc0200ebc <buddy_alloc_pages+0xa2>
ffffffffc0200e50:	00269793          	slli	a5,a3,0x2
    unsigned int order = log2(pn);  //要分配的页数的阶数
ffffffffc0200e54:	0007841b          	sext.w	s0,a5
    while (n > 1)
ffffffffc0200e58:	06f77563          	bleu	a5,a4,ffffffffc0200ec2 <buddy_alloc_pages+0xa8>
        ret <<= 1;
ffffffffc0200e5c:	4501                	li	a0,0
    while (n > 1)
ffffffffc0200e5e:	4705                	li	a4,1
        n >>= 1;
ffffffffc0200e60:	8385                	srli	a5,a5,0x1
        ++order;
ffffffffc0200e62:	2505                	addiw	a0,a0,1
        n >>= 1;
ffffffffc0200e64:	2401                	sext.w	s0,s0
    while (n > 1)
ffffffffc0200e66:	fee79de3          	bne	a5,a4,ffffffffc0200e60 <buddy_alloc_pages+0x46>
ffffffffc0200e6a:	02051793          	slli	a5,a0,0x20
ffffffffc0200e6e:	9381                	srli	a5,a5,0x20
ffffffffc0200e70:	00479713          	slli	a4,a5,0x4
ffffffffc0200e74:	0721                	addi	a4,a4,8
    return list->next == list;
ffffffffc0200e76:	00005917          	auipc	s2,0x5
ffffffffc0200e7a:	5c290913          	addi	s2,s2,1474 # ffffffffc0206438 <free_buddy>
ffffffffc0200e7e:	0792                	slli	a5,a5,0x4
ffffffffc0200e80:	00f904b3          	add	s1,s2,a5
ffffffffc0200e84:	689c                	ld	a5,16(s1)
    if (list_empty(&(free_array[order])))
ffffffffc0200e86:	974a                	add	a4,a4,s2
ffffffffc0200e88:	04e78863          	beq	a5,a4,ffffffffc0200ed8 <buddy_alloc_pages+0xbe>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e8c:	6798                	ld	a4,8(a5)
ffffffffc0200e8e:	6394                	ld	a3,0(a5)
    ret = le2page(list_next(&(free_array[order])), page_link);
ffffffffc0200e90:	fe878513          	addi	a0,a5,-24
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200e94:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200e96:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200e98:	e314                	sd	a3,0(a4)
ffffffffc0200e9a:	5775                	li	a4,-3
ffffffffc0200e9c:	60e7b02f          	amoand.d	zero,a4,(a5)
    nr_free -= pn;
ffffffffc0200ea0:	15892783          	lw	a5,344(s2)
}
ffffffffc0200ea4:	60e2                	ld	ra,24(sp)
ffffffffc0200ea6:	64a2                	ld	s1,8(sp)
    nr_free -= pn;
ffffffffc0200ea8:	4087843b          	subw	s0,a5,s0
ffffffffc0200eac:	00005797          	auipc	a5,0x5
ffffffffc0200eb0:	6e87a223          	sw	s0,1764(a5) # ffffffffc0206590 <free_buddy+0x158>
}
ffffffffc0200eb4:	6442                	ld	s0,16(sp)
ffffffffc0200eb6:	6902                	ld	s2,0(sp)
ffffffffc0200eb8:	6105                	addi	sp,sp,32
ffffffffc0200eba:	8082                	ret
    unsigned int order = log2(pn);  //要分配的页数的阶数
ffffffffc0200ebc:	0007841b          	sext.w	s0,a5
ffffffffc0200ec0:	bf71                	j	ffffffffc0200e5c <buddy_alloc_pages+0x42>
    while (n > 1)
ffffffffc0200ec2:	4721                	li	a4,8
    unsigned int order = 0;
ffffffffc0200ec4:	4501                	li	a0,0
ffffffffc0200ec6:	4781                	li	a5,0
ffffffffc0200ec8:	b77d                	j	ffffffffc0200e76 <buddy_alloc_pages+0x5c>
}
ffffffffc0200eca:	60e2                	ld	ra,24(sp)
ffffffffc0200ecc:	6442                	ld	s0,16(sp)
ffffffffc0200ece:	64a2                	ld	s1,8(sp)
ffffffffc0200ed0:	6902                	ld	s2,0(sp)
    if (n > nr_free) return NULL;
ffffffffc0200ed2:	4501                	li	a0,0
}
ffffffffc0200ed4:	6105                	addi	sp,sp,32
ffffffffc0200ed6:	8082                	ret
        buddy_split(order + 1);
ffffffffc0200ed8:	2505                	addiw	a0,a0,1
ffffffffc0200eda:	1502                	slli	a0,a0,0x20
ffffffffc0200edc:	9101                	srli	a0,a0,0x20
ffffffffc0200ede:	ad9ff0ef          	jal	ra,ffffffffc02009b6 <buddy_split>
ffffffffc0200ee2:	689c                	ld	a5,16(s1)
ffffffffc0200ee4:	b765                	j	ffffffffc0200e8c <buddy_alloc_pages+0x72>
    while (n > 1)
ffffffffc0200ee6:	4721                	li	a4,8
ffffffffc0200ee8:	4405                	li	s0,1
    unsigned int order = 0;
ffffffffc0200eea:	4501                	li	a0,0
ffffffffc0200eec:	4781                	li	a5,0
ffffffffc0200eee:	b761                	j	ffffffffc0200e76 <buddy_alloc_pages+0x5c>
    assert(n > 0);
ffffffffc0200ef0:	00001697          	auipc	a3,0x1
ffffffffc0200ef4:	1f068693          	addi	a3,a3,496 # ffffffffc02020e0 <buddySystem+0x40>
ffffffffc0200ef8:	00001617          	auipc	a2,0x1
ffffffffc0200efc:	1f060613          	addi	a2,a2,496 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200f00:	06800593          	li	a1,104
ffffffffc0200f04:	00001517          	auipc	a0,0x1
ffffffffc0200f08:	1fc50513          	addi	a0,a0,508 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200f0c:	ca0ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200f10 <buddy_init_memmap>:
{
ffffffffc0200f10:	1141                	addi	sp,sp,-16
ffffffffc0200f12:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f14:	c9e9                	beqz	a1,ffffffffc0200fe6 <buddy_init_memmap+0xd6>
    size_t ret = 1;
ffffffffc0200f16:	4605                	li	a2,1
    while (n > 1)
ffffffffc0200f18:	4785                	li	a5,1
ffffffffc0200f1a:	02800693          	li	a3,40
    unsigned int order = 0;
ffffffffc0200f1e:	4701                	li	a4,0
    while (n > 1)
ffffffffc0200f20:	02b67363          	bleu	a1,a2,ffffffffc0200f46 <buddy_init_memmap+0x36>
        n >>= 1;
ffffffffc0200f24:	8185                	srli	a1,a1,0x1
        ret <<= 1;
ffffffffc0200f26:	0606                	slli	a2,a2,0x1
    while (n > 1)
ffffffffc0200f28:	fef59ee3          	bne	a1,a5,ffffffffc0200f24 <buddy_init_memmap+0x14>
ffffffffc0200f2c:	00261693          	slli	a3,a2,0x2
ffffffffc0200f30:	96b2                	add	a3,a3,a2
ffffffffc0200f32:	068e                	slli	a3,a3,0x3
    while (n > 1)
ffffffffc0200f34:	08c5f763          	bleu	a2,a1,ffffffffc0200fc2 <buddy_init_memmap+0xb2>
ffffffffc0200f38:	87b2                	mv	a5,a2
    unsigned int order = 0;
ffffffffc0200f3a:	4701                	li	a4,0
    while (n > 1)
ffffffffc0200f3c:	4585                	li	a1,1
        n >>= 1;
ffffffffc0200f3e:	8385                	srli	a5,a5,0x1
        ++order;
ffffffffc0200f40:	2705                	addiw	a4,a4,1
    while (n > 1)
ffffffffc0200f42:	feb79ee3          	bne	a5,a1,ffffffffc0200f3e <buddy_init_memmap+0x2e>
    max_order = log2(pn);       //对应阶数
ffffffffc0200f46:	00005797          	auipc	a5,0x5
ffffffffc0200f4a:	4ee7a923          	sw	a4,1266(a5) # ffffffffc0206438 <free_buddy>
    for (struct Page *p = base; p != base + pn; ++p)
ffffffffc0200f4e:	96aa                	add	a3,a3,a0
ffffffffc0200f50:	06d50463          	beq	a0,a3,ffffffffc0200fb8 <buddy_init_memmap+0xa8>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f54:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0200f56:	87aa                	mv	a5,a0
ffffffffc0200f58:	8b05                	andi	a4,a4,1
ffffffffc0200f5a:	e709                	bnez	a4,ffffffffc0200f64 <buddy_init_memmap+0x54>
ffffffffc0200f5c:	a0ad                	j	ffffffffc0200fc6 <buddy_init_memmap+0xb6>
ffffffffc0200f5e:	6798                	ld	a4,8(a5)
ffffffffc0200f60:	8b05                	andi	a4,a4,1
ffffffffc0200f62:	c335                	beqz	a4,ffffffffc0200fc6 <buddy_init_memmap+0xb6>
        p->flags = 0;       //状态位置零
ffffffffc0200f64:	0007b423          	sd	zero,8(a5)
        p->property = 0;   //buddy system中的property代表当前头页管理的页数的阶数
ffffffffc0200f68:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200f6c:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + pn; ++p)
ffffffffc0200f70:	02878793          	addi	a5,a5,40
ffffffffc0200f74:	fef695e3          	bne	a3,a5,ffffffffc0200f5e <buddy_init_memmap+0x4e>
ffffffffc0200f78:	00005697          	auipc	a3,0x5
ffffffffc0200f7c:	4c068693          	addi	a3,a3,1216 # ffffffffc0206438 <free_buddy>
ffffffffc0200f80:	4298                	lw	a4,0(a3)
    nr_free = pn;
ffffffffc0200f82:	00005797          	auipc	a5,0x5
ffffffffc0200f86:	60c7a723          	sw	a2,1550(a5) # ffffffffc0206590 <free_buddy+0x158>
    base->property = max_order;
ffffffffc0200f8a:	c918                	sw	a4,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200f8c:	4789                	li	a5,2
ffffffffc0200f8e:	00850713          	addi	a4,a0,8
ffffffffc0200f92:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200f96:	0006e783          	lwu	a5,0(a3)
    list_add(&(free_array[max_order]), &(base->page_link));  //链入
ffffffffc0200f9a:	01850593          	addi	a1,a0,24
}
ffffffffc0200f9e:	60a2                	ld	ra,8(sp)
ffffffffc0200fa0:	0792                	slli	a5,a5,0x4
ffffffffc0200fa2:	00f68633          	add	a2,a3,a5
ffffffffc0200fa6:	6a18                	ld	a4,16(a2)
    list_add(&(free_array[max_order]), &(base->page_link));  //链入
ffffffffc0200fa8:	07a1                	addi	a5,a5,8
ffffffffc0200faa:	97b6                	add	a5,a5,a3
    prev->next = next->prev = elm;
ffffffffc0200fac:	e30c                	sd	a1,0(a4)
ffffffffc0200fae:	ea0c                	sd	a1,16(a2)
    elm->next = next;
ffffffffc0200fb0:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200fb2:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200fb4:	0141                	addi	sp,sp,16
ffffffffc0200fb6:	8082                	ret
ffffffffc0200fb8:	00005697          	auipc	a3,0x5
ffffffffc0200fbc:	48068693          	addi	a3,a3,1152 # ffffffffc0206438 <free_buddy>
ffffffffc0200fc0:	b7c9                	j	ffffffffc0200f82 <buddy_init_memmap+0x72>
    unsigned int order = 0;
ffffffffc0200fc2:	4701                	li	a4,0
ffffffffc0200fc4:	b749                	j	ffffffffc0200f46 <buddy_init_memmap+0x36>
        assert(PageReserved(p));
ffffffffc0200fc6:	00001697          	auipc	a3,0x1
ffffffffc0200fca:	17268693          	addi	a3,a3,370 # ffffffffc0202138 <buddySystem+0x98>
ffffffffc0200fce:	00001617          	auipc	a2,0x1
ffffffffc0200fd2:	11a60613          	addi	a2,a2,282 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200fd6:	04700593          	li	a1,71
ffffffffc0200fda:	00001517          	auipc	a0,0x1
ffffffffc0200fde:	12650513          	addi	a0,a0,294 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0200fe2:	bcaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200fe6:	00001697          	auipc	a3,0x1
ffffffffc0200fea:	0fa68693          	addi	a3,a3,250 # ffffffffc02020e0 <buddySystem+0x40>
ffffffffc0200fee:	00001617          	auipc	a2,0x1
ffffffffc0200ff2:	0fa60613          	addi	a2,a2,250 # ffffffffc02020e8 <buddySystem+0x48>
ffffffffc0200ff6:	04100593          	li	a1,65
ffffffffc0200ffa:	00001517          	auipc	a0,0x1
ffffffffc0200ffe:	10650513          	addi	a0,a0,262 # ffffffffc0202100 <buddySystem+0x60>
ffffffffc0201002:	baaff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201006 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {    //检测sstatus寄存器并且保存SIE位的状态，暂停时钟中断
ffffffffc0201006:	100027f3          	csrr	a5,sstatus
ffffffffc020100a:	8b89                	andi	a5,a5,2
ffffffffc020100c:	eb89                	bnez	a5,ffffffffc020101e <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) { 
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020100e:	00005797          	auipc	a5,0x5
ffffffffc0201012:	59278793          	addi	a5,a5,1426 # ffffffffc02065a0 <pmm_manager>
ffffffffc0201016:	639c                	ld	a5,0(a5)
ffffffffc0201018:	0187b303          	ld	t1,24(a5)
ffffffffc020101c:	8302                	jr	t1
struct Page *alloc_pages(size_t n) { 
ffffffffc020101e:	1141                	addi	sp,sp,-16
ffffffffc0201020:	e406                	sd	ra,8(sp)
ffffffffc0201022:	e022                	sd	s0,0(sp)
ffffffffc0201024:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201026:	c3eff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020102a:	00005797          	auipc	a5,0x5
ffffffffc020102e:	57678793          	addi	a5,a5,1398 # ffffffffc02065a0 <pmm_manager>
ffffffffc0201032:	639c                	ld	a5,0(a5)
ffffffffc0201034:	8522                	mv	a0,s0
ffffffffc0201036:	6f9c                	ld	a5,24(a5)
ffffffffc0201038:	9782                	jalr	a5
ffffffffc020103a:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {   //恢复时钟中断
    if (flag) {
        intr_enable();
ffffffffc020103c:	c22ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201040:	8522                	mv	a0,s0
ffffffffc0201042:	60a2                	ld	ra,8(sp)
ffffffffc0201044:	6402                	ld	s0,0(sp)
ffffffffc0201046:	0141                	addi	sp,sp,16
ffffffffc0201048:	8082                	ret

ffffffffc020104a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {    //检测sstatus寄存器并且保存SIE位的状态，暂停时钟中断
ffffffffc020104a:	100027f3          	csrr	a5,sstatus
ffffffffc020104e:	8b89                	andi	a5,a5,2
ffffffffc0201050:	eb89                	bnez	a5,ffffffffc0201062 <free_pages+0x18>
// 释放从base开始的n个页
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201052:	00005797          	auipc	a5,0x5
ffffffffc0201056:	54e78793          	addi	a5,a5,1358 # ffffffffc02065a0 <pmm_manager>
ffffffffc020105a:	639c                	ld	a5,0(a5)
ffffffffc020105c:	0207b303          	ld	t1,32(a5)
ffffffffc0201060:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201062:	1101                	addi	sp,sp,-32
ffffffffc0201064:	ec06                	sd	ra,24(sp)
ffffffffc0201066:	e822                	sd	s0,16(sp)
ffffffffc0201068:	e426                	sd	s1,8(sp)
ffffffffc020106a:	842a                	mv	s0,a0
ffffffffc020106c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020106e:	bf6ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201072:	00005797          	auipc	a5,0x5
ffffffffc0201076:	52e78793          	addi	a5,a5,1326 # ffffffffc02065a0 <pmm_manager>
ffffffffc020107a:	639c                	ld	a5,0(a5)
ffffffffc020107c:	85a6                	mv	a1,s1
ffffffffc020107e:	8522                	mv	a0,s0
ffffffffc0201080:	739c                	ld	a5,32(a5)
ffffffffc0201082:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201084:	6442                	ld	s0,16(sp)
ffffffffc0201086:	60e2                	ld	ra,24(sp)
ffffffffc0201088:	64a2                	ld	s1,8(sp)
ffffffffc020108a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020108c:	bd2ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc0201090 <pmm_init>:
    pmm_manager = &buddySystem;    //选择分配策略
ffffffffc0201090:	00001797          	auipc	a5,0x1
ffffffffc0201094:	01078793          	addi	a5,a5,16 # ffffffffc02020a0 <buddySystem>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201098:	638c                	ld	a1,0(a5)

/* pmm_init - initialize the physical memory management */


//在init.c中被调用
void pmm_init(void) {
ffffffffc020109a:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020109c:	00001517          	auipc	a0,0x1
ffffffffc02010a0:	0dc50513          	addi	a0,a0,220 # ffffffffc0202178 <buddySystem+0xd8>
void pmm_init(void) {
ffffffffc02010a4:	ec06                	sd	ra,24(sp)
    pmm_manager = &buddySystem;    //选择分配策略
ffffffffc02010a6:	00005717          	auipc	a4,0x5
ffffffffc02010aa:	4ef73d23          	sd	a5,1274(a4) # ffffffffc02065a0 <pmm_manager>
void pmm_init(void) {
ffffffffc02010ae:	e822                	sd	s0,16(sp)
ffffffffc02010b0:	e426                	sd	s1,8(sp)
    pmm_manager = &buddySystem;    //选择分配策略
ffffffffc02010b2:	00005417          	auipc	s0,0x5
ffffffffc02010b6:	4ee40413          	addi	s0,s0,1262 # ffffffffc02065a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010ba:	ffdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc02010be:	601c                	ld	a5,0(s0)
ffffffffc02010c0:	679c                	ld	a5,8(a5)
ffffffffc02010c2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010c4:	57f5                	li	a5,-3
ffffffffc02010c6:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02010c8:	00001517          	auipc	a0,0x1
ffffffffc02010cc:	0c850513          	addi	a0,a0,200 # ffffffffc0202190 <buddySystem+0xf0>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010d0:	00005717          	auipc	a4,0x5
ffffffffc02010d4:	4cf73c23          	sd	a5,1240(a4) # ffffffffc02065a8 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02010d8:	fdffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02010dc:	46c5                	li	a3,17
ffffffffc02010de:	06ee                	slli	a3,a3,0x1b
ffffffffc02010e0:	40100613          	li	a2,1025
ffffffffc02010e4:	16fd                	addi	a3,a3,-1
ffffffffc02010e6:	0656                	slli	a2,a2,0x15
ffffffffc02010e8:	07e005b7          	lui	a1,0x7e00
ffffffffc02010ec:	00001517          	auipc	a0,0x1
ffffffffc02010f0:	0bc50513          	addi	a0,a0,188 # ffffffffc02021a8 <buddySystem+0x108>
ffffffffc02010f4:	fc3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);  ////把pages指针指向内核所占内存空间结束后的第一页
ffffffffc02010f8:	777d                	lui	a4,0xfffff
ffffffffc02010fa:	00006797          	auipc	a5,0x6
ffffffffc02010fe:	4bd78793          	addi	a5,a5,1213 # ffffffffc02075b7 <end+0xfff>
ffffffffc0201102:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201104:	00088737          	lui	a4,0x88
ffffffffc0201108:	00005697          	auipc	a3,0x5
ffffffffc020110c:	30e6b823          	sd	a4,784(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);  ////把pages指针指向内核所占内存空间结束后的第一页
ffffffffc0201110:	4601                	li	a2,0
ffffffffc0201112:	00005717          	auipc	a4,0x5
ffffffffc0201116:	48f73f23          	sd	a5,1182(a4) # ffffffffc02065b0 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {  //将管理的所有页都先设置成reserved
ffffffffc020111a:	4681                	li	a3,0
ffffffffc020111c:	00005897          	auipc	a7,0x5
ffffffffc0201120:	2fc88893          	addi	a7,a7,764 # ffffffffc0206418 <npage>
ffffffffc0201124:	00005597          	auipc	a1,0x5
ffffffffc0201128:	48c58593          	addi	a1,a1,1164 # ffffffffc02065b0 <pages>
ffffffffc020112c:	4805                	li	a6,1
ffffffffc020112e:	fff80537          	lui	a0,0xfff80
ffffffffc0201132:	a011                	j	ffffffffc0201136 <pmm_init+0xa6>
ffffffffc0201134:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc0201136:	97b2                	add	a5,a5,a2
ffffffffc0201138:	07a1                	addi	a5,a5,8
ffffffffc020113a:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {  //将管理的所有页都先设置成reserved
ffffffffc020113e:	0008b703          	ld	a4,0(a7)
ffffffffc0201142:	0685                	addi	a3,a3,1
ffffffffc0201144:	02860613          	addi	a2,a2,40
ffffffffc0201148:	00a707b3          	add	a5,a4,a0
ffffffffc020114c:	fef6e4e3          	bltu	a3,a5,ffffffffc0201134 <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201150:	6190                	ld	a2,0(a1)
ffffffffc0201152:	00271793          	slli	a5,a4,0x2
ffffffffc0201156:	97ba                	add	a5,a5,a4
ffffffffc0201158:	fec006b7          	lui	a3,0xfec00
ffffffffc020115c:	078e                	slli	a5,a5,0x3
ffffffffc020115e:	96b2                	add	a3,a3,a2
ffffffffc0201160:	96be                	add	a3,a3,a5
ffffffffc0201162:	c02007b7          	lui	a5,0xc0200
ffffffffc0201166:	08f6e863          	bltu	a3,a5,ffffffffc02011f6 <pmm_init+0x166>
ffffffffc020116a:	00005497          	auipc	s1,0x5
ffffffffc020116e:	43e48493          	addi	s1,s1,1086 # ffffffffc02065a8 <va_pa_offset>
ffffffffc0201172:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc0201174:	45c5                	li	a1,17
ffffffffc0201176:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201178:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc020117a:	04b6e963          	bltu	a3,a1,ffffffffc02011cc <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020117e:	601c                	ld	a5,0(s0)
ffffffffc0201180:	7b9c                	ld	a5,48(a5)
ffffffffc0201182:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	0bc50513          	addi	a0,a0,188 # ffffffffc0202240 <buddySystem+0x1a0>
ffffffffc020118c:	f2bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201190:	00004697          	auipc	a3,0x4
ffffffffc0201194:	e7068693          	addi	a3,a3,-400 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201198:	00005797          	auipc	a5,0x5
ffffffffc020119c:	28d7b423          	sd	a3,648(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011a0:	c02007b7          	lui	a5,0xc0200
ffffffffc02011a4:	06f6e563          	bltu	a3,a5,ffffffffc020120e <pmm_init+0x17e>
ffffffffc02011a8:	609c                	ld	a5,0(s1)
}
ffffffffc02011aa:	6442                	ld	s0,16(sp)
ffffffffc02011ac:	60e2                	ld	ra,24(sp)
ffffffffc02011ae:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011b0:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02011b2:	8e9d                	sub	a3,a3,a5
ffffffffc02011b4:	00005797          	auipc	a5,0x5
ffffffffc02011b8:	3ed7b223          	sd	a3,996(a5) # ffffffffc0206598 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011bc:	00001517          	auipc	a0,0x1
ffffffffc02011c0:	0a450513          	addi	a0,a0,164 # ffffffffc0202260 <buddySystem+0x1c0>
ffffffffc02011c4:	8636                	mv	a2,a3
}
ffffffffc02011c6:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011c8:	eeffe06f          	j	ffffffffc02000b6 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);   //开始地址按页对齐
ffffffffc02011cc:	6785                	lui	a5,0x1
ffffffffc02011ce:	17fd                	addi	a5,a5,-1
ffffffffc02011d0:	96be                	add	a3,a3,a5
ffffffffc02011d2:	77fd                	lui	a5,0xfffff
ffffffffc02011d4:	8efd                	and	a3,a3,a5



//此函数根据输入的物理地址返回管理它所在页的page结构体的地址
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) { //若物理页号大于一共的物理页数，报错
ffffffffc02011d6:	00c6d793          	srli	a5,a3,0xc
ffffffffc02011da:	04e7f663          	bleu	a4,a5,ffffffffc0201226 <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc02011de:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];   
ffffffffc02011e0:	97aa                	add	a5,a5,a0
ffffffffc02011e2:	00279513          	slli	a0,a5,0x2
ffffffffc02011e6:	953e                	add	a0,a0,a5
ffffffffc02011e8:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02011ea:	8d95                	sub	a1,a1,a3
ffffffffc02011ec:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02011ee:	81b1                	srli	a1,a1,0xc
ffffffffc02011f0:	9532                	add	a0,a0,a2
ffffffffc02011f2:	9782                	jalr	a5
ffffffffc02011f4:	b769                	j	ffffffffc020117e <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011f6:	00001617          	auipc	a2,0x1
ffffffffc02011fa:	fe260613          	addi	a2,a2,-30 # ffffffffc02021d8 <buddySystem+0x138>
ffffffffc02011fe:	08c00593          	li	a1,140
ffffffffc0201202:	00001517          	auipc	a0,0x1
ffffffffc0201206:	ffe50513          	addi	a0,a0,-2 # ffffffffc0202200 <buddySystem+0x160>
ffffffffc020120a:	9a2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020120e:	00001617          	auipc	a2,0x1
ffffffffc0201212:	fca60613          	addi	a2,a2,-54 # ffffffffc02021d8 <buddySystem+0x138>
ffffffffc0201216:	0ac00593          	li	a1,172
ffffffffc020121a:	00001517          	auipc	a0,0x1
ffffffffc020121e:	fe650513          	addi	a0,a0,-26 # ffffffffc0202200 <buddySystem+0x160>
ffffffffc0201222:	98aff0ef          	jal	ra,ffffffffc02003ac <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201226:	00001617          	auipc	a2,0x1
ffffffffc020122a:	fea60613          	addi	a2,a2,-22 # ffffffffc0202210 <buddySystem+0x170>
ffffffffc020122e:	07900593          	li	a1,121
ffffffffc0201232:	00001517          	auipc	a0,0x1
ffffffffc0201236:	ffe50513          	addi	a0,a0,-2 # ffffffffc0202230 <buddySystem+0x190>
ffffffffc020123a:	972ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020123e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020123e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201242:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201244:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201248:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020124a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020124e:	f022                	sd	s0,32(sp)
ffffffffc0201250:	ec26                	sd	s1,24(sp)
ffffffffc0201252:	e84a                	sd	s2,16(sp)
ffffffffc0201254:	f406                	sd	ra,40(sp)
ffffffffc0201256:	e44e                	sd	s3,8(sp)
ffffffffc0201258:	84aa                	mv	s1,a0
ffffffffc020125a:	892e                	mv	s2,a1
ffffffffc020125c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201260:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201262:	03067e63          	bleu	a6,a2,ffffffffc020129e <printnum+0x60>
ffffffffc0201266:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201268:	00805763          	blez	s0,ffffffffc0201276 <printnum+0x38>
ffffffffc020126c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020126e:	85ca                	mv	a1,s2
ffffffffc0201270:	854e                	mv	a0,s3
ffffffffc0201272:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201274:	fc65                	bnez	s0,ffffffffc020126c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201276:	1a02                	slli	s4,s4,0x20
ffffffffc0201278:	020a5a13          	srli	s4,s4,0x20
ffffffffc020127c:	00001797          	auipc	a5,0x1
ffffffffc0201280:	1b478793          	addi	a5,a5,436 # ffffffffc0202430 <error_string+0x38>
ffffffffc0201284:	9a3e                	add	s4,s4,a5
}
ffffffffc0201286:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201288:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020128c:	70a2                	ld	ra,40(sp)
ffffffffc020128e:	69a2                	ld	s3,8(sp)
ffffffffc0201290:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201292:	85ca                	mv	a1,s2
ffffffffc0201294:	8326                	mv	t1,s1
}
ffffffffc0201296:	6942                	ld	s2,16(sp)
ffffffffc0201298:	64e2                	ld	s1,24(sp)
ffffffffc020129a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020129c:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020129e:	03065633          	divu	a2,a2,a6
ffffffffc02012a2:	8722                	mv	a4,s0
ffffffffc02012a4:	f9bff0ef          	jal	ra,ffffffffc020123e <printnum>
ffffffffc02012a8:	b7f9                	j	ffffffffc0201276 <printnum+0x38>

ffffffffc02012aa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012aa:	7119                	addi	sp,sp,-128
ffffffffc02012ac:	f4a6                	sd	s1,104(sp)
ffffffffc02012ae:	f0ca                	sd	s2,96(sp)
ffffffffc02012b0:	e8d2                	sd	s4,80(sp)
ffffffffc02012b2:	e4d6                	sd	s5,72(sp)
ffffffffc02012b4:	e0da                	sd	s6,64(sp)
ffffffffc02012b6:	fc5e                	sd	s7,56(sp)
ffffffffc02012b8:	f862                	sd	s8,48(sp)
ffffffffc02012ba:	f06a                	sd	s10,32(sp)
ffffffffc02012bc:	fc86                	sd	ra,120(sp)
ffffffffc02012be:	f8a2                	sd	s0,112(sp)
ffffffffc02012c0:	ecce                	sd	s3,88(sp)
ffffffffc02012c2:	f466                	sd	s9,40(sp)
ffffffffc02012c4:	ec6e                	sd	s11,24(sp)
ffffffffc02012c6:	892a                	mv	s2,a0
ffffffffc02012c8:	84ae                	mv	s1,a1
ffffffffc02012ca:	8d32                	mv	s10,a2
ffffffffc02012cc:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012ce:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012d0:	00001a17          	auipc	s4,0x1
ffffffffc02012d4:	fd0a0a13          	addi	s4,s4,-48 # ffffffffc02022a0 <buddySystem+0x200>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012d8:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012dc:	00001c17          	auipc	s8,0x1
ffffffffc02012e0:	11cc0c13          	addi	s8,s8,284 # ffffffffc02023f8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012e4:	000d4503          	lbu	a0,0(s10)
ffffffffc02012e8:	02500793          	li	a5,37
ffffffffc02012ec:	001d0413          	addi	s0,s10,1
ffffffffc02012f0:	00f50e63          	beq	a0,a5,ffffffffc020130c <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02012f4:	c521                	beqz	a0,ffffffffc020133c <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012f6:	02500993          	li	s3,37
ffffffffc02012fa:	a011                	j	ffffffffc02012fe <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02012fc:	c121                	beqz	a0,ffffffffc020133c <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02012fe:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201300:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201302:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201304:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201308:	ff351ae3          	bne	a0,s3,ffffffffc02012fc <vprintfmt+0x52>
ffffffffc020130c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201310:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201314:	4981                	li	s3,0
ffffffffc0201316:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201318:	5cfd                	li	s9,-1
ffffffffc020131a:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020131c:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201320:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201322:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201326:	0ff6f693          	andi	a3,a3,255
ffffffffc020132a:	00140d13          	addi	s10,s0,1
ffffffffc020132e:	20d5e563          	bltu	a1,a3,ffffffffc0201538 <vprintfmt+0x28e>
ffffffffc0201332:	068a                	slli	a3,a3,0x2
ffffffffc0201334:	96d2                	add	a3,a3,s4
ffffffffc0201336:	4294                	lw	a3,0(a3)
ffffffffc0201338:	96d2                	add	a3,a3,s4
ffffffffc020133a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020133c:	70e6                	ld	ra,120(sp)
ffffffffc020133e:	7446                	ld	s0,112(sp)
ffffffffc0201340:	74a6                	ld	s1,104(sp)
ffffffffc0201342:	7906                	ld	s2,96(sp)
ffffffffc0201344:	69e6                	ld	s3,88(sp)
ffffffffc0201346:	6a46                	ld	s4,80(sp)
ffffffffc0201348:	6aa6                	ld	s5,72(sp)
ffffffffc020134a:	6b06                	ld	s6,64(sp)
ffffffffc020134c:	7be2                	ld	s7,56(sp)
ffffffffc020134e:	7c42                	ld	s8,48(sp)
ffffffffc0201350:	7ca2                	ld	s9,40(sp)
ffffffffc0201352:	7d02                	ld	s10,32(sp)
ffffffffc0201354:	6de2                	ld	s11,24(sp)
ffffffffc0201356:	6109                	addi	sp,sp,128
ffffffffc0201358:	8082                	ret
    if (lflag >= 2) {
ffffffffc020135a:	4705                	li	a4,1
ffffffffc020135c:	008a8593          	addi	a1,s5,8
ffffffffc0201360:	01074463          	blt	a4,a6,ffffffffc0201368 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0201364:	26080363          	beqz	a6,ffffffffc02015ca <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0201368:	000ab603          	ld	a2,0(s5)
ffffffffc020136c:	46c1                	li	a3,16
ffffffffc020136e:	8aae                	mv	s5,a1
ffffffffc0201370:	a06d                	j	ffffffffc020141a <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201372:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201376:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201378:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020137a:	b765                	j	ffffffffc0201322 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc020137c:	000aa503          	lw	a0,0(s5)
ffffffffc0201380:	85a6                	mv	a1,s1
ffffffffc0201382:	0aa1                	addi	s5,s5,8
ffffffffc0201384:	9902                	jalr	s2
            break;
ffffffffc0201386:	bfb9                	j	ffffffffc02012e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201388:	4705                	li	a4,1
ffffffffc020138a:	008a8993          	addi	s3,s5,8
ffffffffc020138e:	01074463          	blt	a4,a6,ffffffffc0201396 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201392:	22080463          	beqz	a6,ffffffffc02015ba <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0201396:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020139a:	24044463          	bltz	s0,ffffffffc02015e2 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc020139e:	8622                	mv	a2,s0
ffffffffc02013a0:	8ace                	mv	s5,s3
ffffffffc02013a2:	46a9                	li	a3,10
ffffffffc02013a4:	a89d                	j	ffffffffc020141a <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02013a6:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013aa:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02013ac:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02013ae:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02013b2:	8fb5                	xor	a5,a5,a3
ffffffffc02013b4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013b8:	1ad74363          	blt	a4,a3,ffffffffc020155e <vprintfmt+0x2b4>
ffffffffc02013bc:	00369793          	slli	a5,a3,0x3
ffffffffc02013c0:	97e2                	add	a5,a5,s8
ffffffffc02013c2:	639c                	ld	a5,0(a5)
ffffffffc02013c4:	18078d63          	beqz	a5,ffffffffc020155e <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02013c8:	86be                	mv	a3,a5
ffffffffc02013ca:	00001617          	auipc	a2,0x1
ffffffffc02013ce:	11660613          	addi	a2,a2,278 # ffffffffc02024e0 <error_string+0xe8>
ffffffffc02013d2:	85a6                	mv	a1,s1
ffffffffc02013d4:	854a                	mv	a0,s2
ffffffffc02013d6:	240000ef          	jal	ra,ffffffffc0201616 <printfmt>
ffffffffc02013da:	b729                	j	ffffffffc02012e4 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02013dc:	00144603          	lbu	a2,1(s0)
ffffffffc02013e0:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013e4:	bf3d                	j	ffffffffc0201322 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02013e6:	4705                	li	a4,1
ffffffffc02013e8:	008a8593          	addi	a1,s5,8
ffffffffc02013ec:	01074463          	blt	a4,a6,ffffffffc02013f4 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02013f0:	1e080263          	beqz	a6,ffffffffc02015d4 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02013f4:	000ab603          	ld	a2,0(s5)
ffffffffc02013f8:	46a1                	li	a3,8
ffffffffc02013fa:	8aae                	mv	s5,a1
ffffffffc02013fc:	a839                	j	ffffffffc020141a <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02013fe:	03000513          	li	a0,48
ffffffffc0201402:	85a6                	mv	a1,s1
ffffffffc0201404:	e03e                	sd	a5,0(sp)
ffffffffc0201406:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201408:	85a6                	mv	a1,s1
ffffffffc020140a:	07800513          	li	a0,120
ffffffffc020140e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201410:	0aa1                	addi	s5,s5,8
ffffffffc0201412:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201416:	6782                	ld	a5,0(sp)
ffffffffc0201418:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020141a:	876e                	mv	a4,s11
ffffffffc020141c:	85a6                	mv	a1,s1
ffffffffc020141e:	854a                	mv	a0,s2
ffffffffc0201420:	e1fff0ef          	jal	ra,ffffffffc020123e <printnum>
            break;
ffffffffc0201424:	b5c1                	j	ffffffffc02012e4 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201426:	000ab603          	ld	a2,0(s5)
ffffffffc020142a:	0aa1                	addi	s5,s5,8
ffffffffc020142c:	1c060663          	beqz	a2,ffffffffc02015f8 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201430:	00160413          	addi	s0,a2,1
ffffffffc0201434:	17b05c63          	blez	s11,ffffffffc02015ac <vprintfmt+0x302>
ffffffffc0201438:	02d00593          	li	a1,45
ffffffffc020143c:	14b79263          	bne	a5,a1,ffffffffc0201580 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201440:	00064783          	lbu	a5,0(a2)
ffffffffc0201444:	0007851b          	sext.w	a0,a5
ffffffffc0201448:	c905                	beqz	a0,ffffffffc0201478 <vprintfmt+0x1ce>
ffffffffc020144a:	000cc563          	bltz	s9,ffffffffc0201454 <vprintfmt+0x1aa>
ffffffffc020144e:	3cfd                	addiw	s9,s9,-1
ffffffffc0201450:	036c8263          	beq	s9,s6,ffffffffc0201474 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201454:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201456:	18098463          	beqz	s3,ffffffffc02015de <vprintfmt+0x334>
ffffffffc020145a:	3781                	addiw	a5,a5,-32
ffffffffc020145c:	18fbf163          	bleu	a5,s7,ffffffffc02015de <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201460:	03f00513          	li	a0,63
ffffffffc0201464:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201466:	0405                	addi	s0,s0,1
ffffffffc0201468:	fff44783          	lbu	a5,-1(s0)
ffffffffc020146c:	3dfd                	addiw	s11,s11,-1
ffffffffc020146e:	0007851b          	sext.w	a0,a5
ffffffffc0201472:	fd61                	bnez	a0,ffffffffc020144a <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201474:	e7b058e3          	blez	s11,ffffffffc02012e4 <vprintfmt+0x3a>
ffffffffc0201478:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020147a:	85a6                	mv	a1,s1
ffffffffc020147c:	02000513          	li	a0,32
ffffffffc0201480:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201482:	e60d81e3          	beqz	s11,ffffffffc02012e4 <vprintfmt+0x3a>
ffffffffc0201486:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201488:	85a6                	mv	a1,s1
ffffffffc020148a:	02000513          	li	a0,32
ffffffffc020148e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201490:	fe0d94e3          	bnez	s11,ffffffffc0201478 <vprintfmt+0x1ce>
ffffffffc0201494:	bd81                	j	ffffffffc02012e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201496:	4705                	li	a4,1
ffffffffc0201498:	008a8593          	addi	a1,s5,8
ffffffffc020149c:	01074463          	blt	a4,a6,ffffffffc02014a4 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc02014a0:	12080063          	beqz	a6,ffffffffc02015c0 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02014a4:	000ab603          	ld	a2,0(s5)
ffffffffc02014a8:	46a9                	li	a3,10
ffffffffc02014aa:	8aae                	mv	s5,a1
ffffffffc02014ac:	b7bd                	j	ffffffffc020141a <vprintfmt+0x170>
ffffffffc02014ae:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02014b2:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014b6:	846a                	mv	s0,s10
ffffffffc02014b8:	b5ad                	j	ffffffffc0201322 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02014ba:	85a6                	mv	a1,s1
ffffffffc02014bc:	02500513          	li	a0,37
ffffffffc02014c0:	9902                	jalr	s2
            break;
ffffffffc02014c2:	b50d                	j	ffffffffc02012e4 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02014c4:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02014c8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02014cc:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014ce:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02014d0:	e40dd9e3          	bgez	s11,ffffffffc0201322 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02014d4:	8de6                	mv	s11,s9
ffffffffc02014d6:	5cfd                	li	s9,-1
ffffffffc02014d8:	b5a9                	j	ffffffffc0201322 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02014da:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02014de:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014e4:	bd3d                	j	ffffffffc0201322 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02014e6:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02014ea:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014ee:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02014f0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02014f4:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02014f8:	fcd56ce3          	bltu	a0,a3,ffffffffc02014d0 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02014fc:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02014fe:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201502:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201506:	0196873b          	addw	a4,a3,s9
ffffffffc020150a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020150e:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201512:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201516:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020151a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020151e:	fcd57fe3          	bleu	a3,a0,ffffffffc02014fc <vprintfmt+0x252>
ffffffffc0201522:	b77d                	j	ffffffffc02014d0 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201524:	fffdc693          	not	a3,s11
ffffffffc0201528:	96fd                	srai	a3,a3,0x3f
ffffffffc020152a:	00ddfdb3          	and	s11,s11,a3
ffffffffc020152e:	00144603          	lbu	a2,1(s0)
ffffffffc0201532:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201534:	846a                	mv	s0,s10
ffffffffc0201536:	b3f5                	j	ffffffffc0201322 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0201538:	85a6                	mv	a1,s1
ffffffffc020153a:	02500513          	li	a0,37
ffffffffc020153e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201540:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201544:	02500793          	li	a5,37
ffffffffc0201548:	8d22                	mv	s10,s0
ffffffffc020154a:	d8f70de3          	beq	a4,a5,ffffffffc02012e4 <vprintfmt+0x3a>
ffffffffc020154e:	02500713          	li	a4,37
ffffffffc0201552:	1d7d                	addi	s10,s10,-1
ffffffffc0201554:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201558:	fee79de3          	bne	a5,a4,ffffffffc0201552 <vprintfmt+0x2a8>
ffffffffc020155c:	b361                	j	ffffffffc02012e4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020155e:	00001617          	auipc	a2,0x1
ffffffffc0201562:	f7260613          	addi	a2,a2,-142 # ffffffffc02024d0 <error_string+0xd8>
ffffffffc0201566:	85a6                	mv	a1,s1
ffffffffc0201568:	854a                	mv	a0,s2
ffffffffc020156a:	0ac000ef          	jal	ra,ffffffffc0201616 <printfmt>
ffffffffc020156e:	bb9d                	j	ffffffffc02012e4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201570:	00001617          	auipc	a2,0x1
ffffffffc0201574:	f5860613          	addi	a2,a2,-168 # ffffffffc02024c8 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201578:	00001417          	auipc	s0,0x1
ffffffffc020157c:	f5140413          	addi	s0,s0,-175 # ffffffffc02024c9 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201580:	8532                	mv	a0,a2
ffffffffc0201582:	85e6                	mv	a1,s9
ffffffffc0201584:	e032                	sd	a2,0(sp)
ffffffffc0201586:	e43e                	sd	a5,8(sp)
ffffffffc0201588:	1c2000ef          	jal	ra,ffffffffc020174a <strnlen>
ffffffffc020158c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201590:	6602                	ld	a2,0(sp)
ffffffffc0201592:	01b05d63          	blez	s11,ffffffffc02015ac <vprintfmt+0x302>
ffffffffc0201596:	67a2                	ld	a5,8(sp)
ffffffffc0201598:	2781                	sext.w	a5,a5
ffffffffc020159a:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc020159c:	6522                	ld	a0,8(sp)
ffffffffc020159e:	85a6                	mv	a1,s1
ffffffffc02015a0:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015a2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02015a4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015a6:	6602                	ld	a2,0(sp)
ffffffffc02015a8:	fe0d9ae3          	bnez	s11,ffffffffc020159c <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015ac:	00064783          	lbu	a5,0(a2)
ffffffffc02015b0:	0007851b          	sext.w	a0,a5
ffffffffc02015b4:	e8051be3          	bnez	a0,ffffffffc020144a <vprintfmt+0x1a0>
ffffffffc02015b8:	b335                	j	ffffffffc02012e4 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02015ba:	000aa403          	lw	s0,0(s5)
ffffffffc02015be:	bbf1                	j	ffffffffc020139a <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02015c0:	000ae603          	lwu	a2,0(s5)
ffffffffc02015c4:	46a9                	li	a3,10
ffffffffc02015c6:	8aae                	mv	s5,a1
ffffffffc02015c8:	bd89                	j	ffffffffc020141a <vprintfmt+0x170>
ffffffffc02015ca:	000ae603          	lwu	a2,0(s5)
ffffffffc02015ce:	46c1                	li	a3,16
ffffffffc02015d0:	8aae                	mv	s5,a1
ffffffffc02015d2:	b5a1                	j	ffffffffc020141a <vprintfmt+0x170>
ffffffffc02015d4:	000ae603          	lwu	a2,0(s5)
ffffffffc02015d8:	46a1                	li	a3,8
ffffffffc02015da:	8aae                	mv	s5,a1
ffffffffc02015dc:	bd3d                	j	ffffffffc020141a <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02015de:	9902                	jalr	s2
ffffffffc02015e0:	b559                	j	ffffffffc0201466 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02015e2:	85a6                	mv	a1,s1
ffffffffc02015e4:	02d00513          	li	a0,45
ffffffffc02015e8:	e03e                	sd	a5,0(sp)
ffffffffc02015ea:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015ec:	8ace                	mv	s5,s3
ffffffffc02015ee:	40800633          	neg	a2,s0
ffffffffc02015f2:	46a9                	li	a3,10
ffffffffc02015f4:	6782                	ld	a5,0(sp)
ffffffffc02015f6:	b515                	j	ffffffffc020141a <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02015f8:	01b05663          	blez	s11,ffffffffc0201604 <vprintfmt+0x35a>
ffffffffc02015fc:	02d00693          	li	a3,45
ffffffffc0201600:	f6d798e3          	bne	a5,a3,ffffffffc0201570 <vprintfmt+0x2c6>
ffffffffc0201604:	00001417          	auipc	s0,0x1
ffffffffc0201608:	ec540413          	addi	s0,s0,-315 # ffffffffc02024c9 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020160c:	02800513          	li	a0,40
ffffffffc0201610:	02800793          	li	a5,40
ffffffffc0201614:	bd1d                	j	ffffffffc020144a <vprintfmt+0x1a0>

ffffffffc0201616 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201616:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201618:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020161c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020161e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201620:	ec06                	sd	ra,24(sp)
ffffffffc0201622:	f83a                	sd	a4,48(sp)
ffffffffc0201624:	fc3e                	sd	a5,56(sp)
ffffffffc0201626:	e0c2                	sd	a6,64(sp)
ffffffffc0201628:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020162a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020162c:	c7fff0ef          	jal	ra,ffffffffc02012aa <vprintfmt>
}
ffffffffc0201630:	60e2                	ld	ra,24(sp)
ffffffffc0201632:	6161                	addi	sp,sp,80
ffffffffc0201634:	8082                	ret

ffffffffc0201636 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201636:	715d                	addi	sp,sp,-80
ffffffffc0201638:	e486                	sd	ra,72(sp)
ffffffffc020163a:	e0a2                	sd	s0,64(sp)
ffffffffc020163c:	fc26                	sd	s1,56(sp)
ffffffffc020163e:	f84a                	sd	s2,48(sp)
ffffffffc0201640:	f44e                	sd	s3,40(sp)
ffffffffc0201642:	f052                	sd	s4,32(sp)
ffffffffc0201644:	ec56                	sd	s5,24(sp)
ffffffffc0201646:	e85a                	sd	s6,16(sp)
ffffffffc0201648:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc020164a:	c901                	beqz	a0,ffffffffc020165a <readline+0x24>
        cprintf("%s", prompt);
ffffffffc020164c:	85aa                	mv	a1,a0
ffffffffc020164e:	00001517          	auipc	a0,0x1
ffffffffc0201652:	e9250513          	addi	a0,a0,-366 # ffffffffc02024e0 <error_string+0xe8>
ffffffffc0201656:	a61fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc020165a:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020165c:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020165e:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201660:	4aa9                	li	s5,10
ffffffffc0201662:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201664:	00005b97          	auipc	s7,0x5
ffffffffc0201668:	9acb8b93          	addi	s7,s7,-1620 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020166c:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201670:	abffe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201674:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201676:	00054b63          	bltz	a0,ffffffffc020168c <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020167a:	00a95b63          	ble	a0,s2,ffffffffc0201690 <readline+0x5a>
ffffffffc020167e:	029a5463          	ble	s1,s4,ffffffffc02016a6 <readline+0x70>
        c = getchar();
ffffffffc0201682:	aadfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201686:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201688:	fe0559e3          	bgez	a0,ffffffffc020167a <readline+0x44>
            return NULL;
ffffffffc020168c:	4501                	li	a0,0
ffffffffc020168e:	a099                	j	ffffffffc02016d4 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201690:	03341463          	bne	s0,s3,ffffffffc02016b8 <readline+0x82>
ffffffffc0201694:	e8b9                	bnez	s1,ffffffffc02016ea <readline+0xb4>
        c = getchar();
ffffffffc0201696:	a99fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc020169a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020169c:	fe0548e3          	bltz	a0,ffffffffc020168c <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016a0:	fea958e3          	ble	a0,s2,ffffffffc0201690 <readline+0x5a>
ffffffffc02016a4:	4481                	li	s1,0
            cputchar(c);
ffffffffc02016a6:	8522                	mv	a0,s0
ffffffffc02016a8:	a43fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc02016ac:	009b87b3          	add	a5,s7,s1
ffffffffc02016b0:	00878023          	sb	s0,0(a5)
ffffffffc02016b4:	2485                	addiw	s1,s1,1
ffffffffc02016b6:	bf6d                	j	ffffffffc0201670 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc02016b8:	01540463          	beq	s0,s5,ffffffffc02016c0 <readline+0x8a>
ffffffffc02016bc:	fb641ae3          	bne	s0,s6,ffffffffc0201670 <readline+0x3a>
            cputchar(c);
ffffffffc02016c0:	8522                	mv	a0,s0
ffffffffc02016c2:	a29fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc02016c6:	00005517          	auipc	a0,0x5
ffffffffc02016ca:	94a50513          	addi	a0,a0,-1718 # ffffffffc0206010 <edata>
ffffffffc02016ce:	94aa                	add	s1,s1,a0
ffffffffc02016d0:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02016d4:	60a6                	ld	ra,72(sp)
ffffffffc02016d6:	6406                	ld	s0,64(sp)
ffffffffc02016d8:	74e2                	ld	s1,56(sp)
ffffffffc02016da:	7942                	ld	s2,48(sp)
ffffffffc02016dc:	79a2                	ld	s3,40(sp)
ffffffffc02016de:	7a02                	ld	s4,32(sp)
ffffffffc02016e0:	6ae2                	ld	s5,24(sp)
ffffffffc02016e2:	6b42                	ld	s6,16(sp)
ffffffffc02016e4:	6ba2                	ld	s7,8(sp)
ffffffffc02016e6:	6161                	addi	sp,sp,80
ffffffffc02016e8:	8082                	ret
            cputchar(c);
ffffffffc02016ea:	4521                	li	a0,8
ffffffffc02016ec:	9fffe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc02016f0:	34fd                	addiw	s1,s1,-1
ffffffffc02016f2:	bfbd                	j	ffffffffc0201670 <readline+0x3a>

ffffffffc02016f4 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc02016f4:	00005797          	auipc	a5,0x5
ffffffffc02016f8:	91478793          	addi	a5,a5,-1772 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc02016fc:	6398                	ld	a4,0(a5)
ffffffffc02016fe:	4781                	li	a5,0
ffffffffc0201700:	88ba                	mv	a7,a4
ffffffffc0201702:	852a                	mv	a0,a0
ffffffffc0201704:	85be                	mv	a1,a5
ffffffffc0201706:	863e                	mv	a2,a5
ffffffffc0201708:	00000073          	ecall
ffffffffc020170c:	87aa                	mv	a5,a0
}
ffffffffc020170e:	8082                	ret

ffffffffc0201710 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201710:	00005797          	auipc	a5,0x5
ffffffffc0201714:	d1878793          	addi	a5,a5,-744 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201718:	6398                	ld	a4,0(a5)
ffffffffc020171a:	4781                	li	a5,0
ffffffffc020171c:	88ba                	mv	a7,a4
ffffffffc020171e:	852a                	mv	a0,a0
ffffffffc0201720:	85be                	mv	a1,a5
ffffffffc0201722:	863e                	mv	a2,a5
ffffffffc0201724:	00000073          	ecall
ffffffffc0201728:	87aa                	mv	a5,a0
}
ffffffffc020172a:	8082                	ret

ffffffffc020172c <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc020172c:	00005797          	auipc	a5,0x5
ffffffffc0201730:	8d478793          	addi	a5,a5,-1836 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201734:	639c                	ld	a5,0(a5)
ffffffffc0201736:	4501                	li	a0,0
ffffffffc0201738:	88be                	mv	a7,a5
ffffffffc020173a:	852a                	mv	a0,a0
ffffffffc020173c:	85aa                	mv	a1,a0
ffffffffc020173e:	862a                	mv	a2,a0
ffffffffc0201740:	00000073          	ecall
ffffffffc0201744:	852a                	mv	a0,a0
ffffffffc0201746:	2501                	sext.w	a0,a0
ffffffffc0201748:	8082                	ret

ffffffffc020174a <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc020174a:	c185                	beqz	a1,ffffffffc020176a <strnlen+0x20>
ffffffffc020174c:	00054783          	lbu	a5,0(a0)
ffffffffc0201750:	cf89                	beqz	a5,ffffffffc020176a <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201752:	4781                	li	a5,0
ffffffffc0201754:	a021                	j	ffffffffc020175c <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201756:	00074703          	lbu	a4,0(a4)
ffffffffc020175a:	c711                	beqz	a4,ffffffffc0201766 <strnlen+0x1c>
        cnt ++;
ffffffffc020175c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020175e:	00f50733          	add	a4,a0,a5
ffffffffc0201762:	fef59ae3          	bne	a1,a5,ffffffffc0201756 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201766:	853e                	mv	a0,a5
ffffffffc0201768:	8082                	ret
    size_t cnt = 0;
ffffffffc020176a:	4781                	li	a5,0
}
ffffffffc020176c:	853e                	mv	a0,a5
ffffffffc020176e:	8082                	ret

ffffffffc0201770 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201770:	00054783          	lbu	a5,0(a0)
ffffffffc0201774:	0005c703          	lbu	a4,0(a1)
ffffffffc0201778:	cb91                	beqz	a5,ffffffffc020178c <strcmp+0x1c>
ffffffffc020177a:	00e79c63          	bne	a5,a4,ffffffffc0201792 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc020177e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201780:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201784:	0585                	addi	a1,a1,1
ffffffffc0201786:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020178a:	fbe5                	bnez	a5,ffffffffc020177a <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020178c:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020178e:	9d19                	subw	a0,a0,a4
ffffffffc0201790:	8082                	ret
ffffffffc0201792:	0007851b          	sext.w	a0,a5
ffffffffc0201796:	9d19                	subw	a0,a0,a4
ffffffffc0201798:	8082                	ret

ffffffffc020179a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020179a:	00054783          	lbu	a5,0(a0)
ffffffffc020179e:	cb91                	beqz	a5,ffffffffc02017b2 <strchr+0x18>
        if (*s == c) {
ffffffffc02017a0:	00b79563          	bne	a5,a1,ffffffffc02017aa <strchr+0x10>
ffffffffc02017a4:	a809                	j	ffffffffc02017b6 <strchr+0x1c>
ffffffffc02017a6:	00b78763          	beq	a5,a1,ffffffffc02017b4 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02017aa:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02017ac:	00054783          	lbu	a5,0(a0)
ffffffffc02017b0:	fbfd                	bnez	a5,ffffffffc02017a6 <strchr+0xc>
    }
    return NULL;
ffffffffc02017b2:	4501                	li	a0,0
}
ffffffffc02017b4:	8082                	ret
ffffffffc02017b6:	8082                	ret

ffffffffc02017b8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02017b8:	ca01                	beqz	a2,ffffffffc02017c8 <memset+0x10>
ffffffffc02017ba:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02017bc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02017be:	0785                	addi	a5,a5,1
ffffffffc02017c0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02017c4:	fec79de3          	bne	a5,a2,ffffffffc02017be <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02017c8:	8082                	ret
