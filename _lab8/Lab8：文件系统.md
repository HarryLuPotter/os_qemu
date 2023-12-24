# Lab8：文件系统 #

### 练习

对实验报告的要求：

- 基于markdown格式来完成，以文本方式为主
- 填写各个基本练习中要求完成的报告内容
- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习0：填写已有实验

本实验依赖实验2/3/4/5/6/7。请把你做的实验2/3/4/5/6/7的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”/“LAB5”/“LAB6” /“LAB7”的注释相应部分。并确保编译通过。注意：为了能够正确执行lab8的测试应用程序，可能需对已完成的实验2/3/4/5/6/7的代码进行进一步改进。
proc.c 中，在 proc_struct 结构中加入了一个 file_struct，需要在 alloc_proc 时加上对它的初始化，就是加上一行：

proc->filesp = NULL;

#### 练习1: 完成读文件操作的实现（需要编码）

首先了解打开文件的处理流程，然后参考本实验后续的文件读写操作的过程分析，填写在 kern/fs/sfs/sfs_inode.c中 的sfs_io_nolock()函数，实现读文件中数据的代码。

```c
// (1) If offset isn't aligned with the first block
    blkoff = offset % SFS_BLKSIZE;//计算未对齐部分的大小
    if (blkoff != 0) {
        size_t first_block_size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
        //如果还有剩余块（nblks != 0），则第一个块的大小是块大小减去未对齐的部分。
        //如果没有剩余块，即这是最后一个块，则第一个块的大小是结束位置（endpos）减去偏移量。
        ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino);
        //通过块映射加载块号为blkno的块对应的磁盘块号（ino），并将其存储在ino中。
        if (ret != 0) {
            goto out;
        }
        ret = sfs_buf_op(sfs, buf, first_block_size, ino, blkoff);
        //执行文件系统缓冲区操作，将磁盘块的数据加载到缓冲区中或将缓冲区的数据写入磁盘块。
        //buf是指向缓冲区的指针，first_block_size是操作的大小，ino是磁盘块号，blkoff是未对齐的偏移量。
        if (ret != 0) {
            goto out;
        }
        alen += first_block_size;//累积已处理的数据长度
        buf += first_block_size;//将缓冲区指针移动到下一个要处理的位置
        if (nblks == 0) {
            goto out;
        }
        blkno++;
        nblks--;//减少剩余块的计数
    }

    // (2) Rd/Wr aligned blocks
    while (nblks > 0) {//处理剩余的所有块
        ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino);
        //通过块映射加载块号为blkno的块对应的磁盘块号（ino），并将其存储在ino中。
        if (ret != 0) {
            goto out;
        }
        ret = sfs_block_op(sfs, buf, ino, 1);
        if (ret != 0) {
            goto out;
        }
        alen += SFS_BLKSIZE;
        buf += SFS_BLKSIZE;
        nblks--;
        blkno++;
    }

    // (3) If the end position isn't aligned with the last block
    if (endpos % SFS_BLKSIZE != 0) {
        //检查endpos是否对齐到块的边界。如果不对齐，说明最后一个块被部分写入。
        ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino);
        if (ret != 0) {
            goto out;
        }
        ret = sfs_buf_op(sfs, buf + alen, endpos % SFS_BLKSIZE, ino, 0);
        if (ret != 0) {
            goto out;
        }
        alen += endpos % SFS_BLKSIZE;
    }  
```

#### 练习2: 完成基于文件系统的执行程序机制的实现（需要编码）

改写proc.c中的load_icode函数和其他相关函数，实现基于文件系统的执行程序机制。执行：make qemu。如果能看看到sh用户程序的执行界面，则基本成功了。如果在sh用户界面上可以执行”ls”,”hello”等其他放置在sfs文件系统中的其他执行程序，则可以认为本实验基本成功。

在实验5的基础上，需要对load_icode进行更改，需要使用文件句柄来加载ELF格式的可执行文件。按照ELF文件的程序头表来加载各个段，包括TEXT、DATA、BSS等。

需要完成以下操作：

- 创建新的内存管理结构（`struct mm_struct`）和页目录表。
- 读取 ELF 文件头，检查 ELF 文件的有效性。
- 针对 ELF 文件中的每个可加载的段（ELF_PT_LOAD）：
  - 创建虚拟内存区域，设置权限和属性。
  - 分配物理页，将文件中的数据拷贝到新分配的页中。
  - 处理文件大小不等于内存大小的情况，填充多余的空间。
  - 在页表中建立映射关系。
- 关闭 ELF 文件。
- 创建用户栈区域，分配几页用于用户栈，并设置权限。
- 更新内存管理结构的引用计数，设置当前进程的内存管理结构和 CR3 寄存器，更新页目录地址寄存器。
- 在用户栈中设置 argc 和 argv。
- 设置陷阱帧，包括用户栈的栈顶、入口地址、状态寄存器等。

```c
assert(argc >= 0 && argc <= EXEC_MAX_ARG_NUM);
// 如果当前进程已经有内存管理结构（mm），表示进程已经有了内存空间，触发 panic。
if (current->mm != NULL) {
    panic("load_icode: current->mm must be empty.\n");
}

int ret = -E_NO_MEM;
struct mm_struct *mm;
// 创建新的内存管理结构
if ((mm = mm_create()) == NULL) {
    goto bad_mm;
}
// 设置新的页目录表
if (setup_pgdir(mm) != 0) {
    goto bad_pgdir_cleanup_mm;
}

struct Page *page;
// 读取 ELF 文件头
struct elfhdr __elf, *elf = &__elf;
if ((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0) {
    goto bad_elf_cleanup_pgdir;
}
// 检查 ELF 文件的有效性
if (elf->e_magic != ELF_MAGIC) {
    ret = -E_INVAL_ELF;
    goto bad_elf_cleanup_pgdir;
}

struct proghdr __ph, *ph = &__ph;
uint32_t vm_flags, perm, phnum;
// 循环处理 ELF 文件中的每一个程序头
for (phnum = 0; phnum < elf->e_phnum; phnum++) {
    off_t phoff = elf->e_phoff + sizeof(struct proghdr) * phnum;
    // 读取程序头
    if ((ret = load_icode_read(fd, ph, sizeof(struct proghdr), phoff)) != 0) {
        goto bad_cleanup_mmap;
    }
    // 如果不是可加载的段，跳过
    if (ph->p_type != ELF_PT_LOAD) {
        continue;
    }
    // 检查文件大小是否合法
    if (ph->p_filesz > ph->p_memsz) {
        ret = -E_INVAL_ELF;
        goto bad_cleanup_mmap;
    }
    // 根据标志设置虚拟内存区域的权限和属性
    vm_flags = 0, perm = PTE_U | PTE_V;
    if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
    if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
    if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
    // 修改权限位，适用于 RISC-V
    if (vm_flags & VM_READ) perm |= PTE_R;
    if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
    if (vm_flags & VM_EXEC) perm |= PTE_X;
    // 建立虚拟内存区域
    if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    off_t offset = ph->p_offset;
    size_t off, size;
    uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

    ret = -E_NO_MEM;

    end = ph->p_va + ph->p_filesz;
    // 循环处理每一页
    while (start < end) {
        if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
            ret = -E_NO_MEM;
            goto bad_cleanup_mmap;
        }
        off = start - la, size = PGSIZE - off, la += PGSIZE;
        if (end < la) {
            size -= la - end;
        }
        // 从文件中读取数据，拷贝到新分配的页中
        if ((ret = load_icode_read(fd, page2kva(page) + off, size, offset)) != 0) {
            goto bad_cleanup_mmap;
        }
        start += size, offset += size;
    }
    end = ph->p_va + ph->p_memsz;

    if (start < la) {
        // 处理文件大小等于内存大小的情况
        if (start == end) {
            continue;
        }
        off = start + PGSIZE - la, size = PGSIZE - off;
        if (end < la) {
            size -= la - end;
        }
        // 在新页中填充 0
        memset(page2kva(page) + off, 0, size);
        start += size;
        assert((end < la && start == end) || (end >= la && start == la));
    }
    // 处理剩余的页面
    while (start < end) {
        if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
            ret = -E_NO_MEM;
            goto bad_cleanup_mmap;
        }
        off = start - la, size = PGSIZE - off, la += PGSIZE;
        if (end < la) {
            size -= la - end;
        }
        // 在新页中填充 0
        memset(page2kva(page) + off, 0, size);
        start += size;
    }
}
// 关闭文件
sysfile_close(fd);

// 创建用户栈区域
vm_flags = VM_READ | VM_WRITE | VM_STACK;
if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
    goto bad_cleanup_mmap;
}
// 分配用户栈的几页，并设置权限
assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);

// 增加内存管理结构的引用计数
mm_count_inc(mm);
// 设置当前进程的内存管理结构、cr3 寄存器，更新页目录地址寄存器
current->mm = mm;
current->cr3 = PADDR(mm->pgdir);
lcr3(PADDR(mm->pgdir));

// 设置 argc 和 argv 在用户栈中的位置
uint32_t argv_size = 0, i;
for (i = 0; i < argc; i++) {
    argv_size += strnlen(kargv[i], EXEC_MAX_ARG_LEN + 1) + 1;
}
uintptr_t stacktop = USTACKTOP - (argv_size / sizeof(long) + 1) * sizeof(long);
char **uargv = (char **)(stacktop - argc * sizeof(char *));
argv_size = 0;
for (i = 0; i < argc; i++) {
    uargv[i] = strcpy((char *)(stacktop + argv_size), kargv[i]);
    argv_size += strnlen(kargv[i], EXEC_MAX_ARG_LEN + 1) + 1;
}
// 设置用户栈的栈顶
stacktop = (uintptr_t)uargv - sizeof(int);
*(int *)stacktop = argc;

// 设置陷阱帧，包括用户栈的栈顶、入口地址、状态寄存器等
struct trapframe *tf = current->tf;
// 保留 sstatus 寄存器的值
uintptr_t sstatus = tf->status;
memset(tf, 0, sizeof(struct trapframe));
tf->gpr.sp = stacktop;
tf->epc = elf->e_entry;
tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ret = 0;
// 返回成功
out:
    return ret;

// 错误处理，需要清理已经分配的资源
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;

```



#### 扩展练习 Challenge1：完成基于“UNIX的PIPE机制”的设计方案

如果要在ucore里加入UNIX的管道（Pipe)机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个(或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的PIPE机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

**解答**：

数据结构定义：

1. **管道结构（`struct pipe`）：**

    ```c
    struct pipe {
        struct spinlock lock;      // 用于管道操作的自旋锁
        struct semaphore rsem;     // 读信号量
        struct semaphore wsem;     // 写信号量
        struct pipe_buffer *buffer; // 管道缓冲区
        // 其他可能需要的字段...
    };
    ```

2. **管道缓冲区结构（`struct pipe_buffer`）：**

    ```c
    struct pipe_buffer {
        char data[PIPE_BUF_SIZE];  // 管道数据缓冲区
        size_t size;                // 当前缓冲区中的数据大小
        // 其他可能需要的字段...
    };
    ```

接口设计：

1. **初始化管道（`pipe_init`）：**

    ```c
    void pipe_init(struct pipe *p) {
        spinlock_init(&p->lock);
        sem_init(&p->rsem, 0); // 初始化为 0，表示初始时没有可读数据
        sem_init(&p->wsem, PIPE_BUF_SIZE); // 初始化为缓冲区大小，表示初始时有整个缓冲区可写
        p->buffer = create_pipe_buffer(); // 创建管道缓冲区
    }
    ```

2. **读取数据（`pipe_read`）：**

    ```c
    ssize_t pipe_read(struct pipe *p, char *buf, size_t count) {
        sem_wait(&p->rsem); // 等待可读信号
        spinlock_acquire(&p->lock);

        size_t read_size = min(count, p->buffer->size);
        memcpy(buf, p->buffer->data, read_size);
        p->buffer->size -= read_size;

        spinlock_release(&p->lock);
        sem_signal(&p->wsem); // 释放可写信号

        return read_size;
    }
    ```

3. **写入数据（`pipe_write`）：**

    ```c
    ssize_t pipe_write(struct pipe *p, const char *buf, size_t count) {
        sem_wait(&p->wsem); // 等待可写信号
        spinlock_acquire(&p->lock);
    
        size_t write_size = min(count, PIPE_BUF_SIZE - p->buffer->size);
        memcpy(p->buffer->data + p->buffer->size, buf, write_size);
        p->buffer->size += write_size;
    
        spinlock_release(&p->lock);
        sem_signal(&p->rsem); // 释放可读信号
    
        return write_size;
    }
    ```

同步互斥问题的处理：

- **自旋锁：** 使用 `struct spinlock` 来保护对管道缓冲区的读写操作，确保在多线程或多进程环境下的原子性。

- **信号量：** 使用 `struct semaphore` 来实现读端和写端的同步。`rsem` 信号量表示可读数据的数量，`wsem` 信号量表示可写空间的数量。通过信号量的等待和释放操作，确保在读写过程中的正确同步。

- **管道缓冲区大小限制：** 在写入数据时，需要检查管道缓冲区的剩余空间，避免数据溢出。同样，读取数据时需要检查缓冲区中是否有足够的数据可读。

#### 扩展练习 Challenge2：完成基于“UNIX的软连接和硬连接机制”的设计方案

如果要在ucore里加入UNIX的软连接和硬连接机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个(或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的软连接和硬连接机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

**解答**

数据结构：

1. **`inode` 结构体扩展：**

    ```c
    struct inode {
        // 其他字段...
        uint32_t i_flags;  // inode 标志，用于表示连接类型等
        union {
            uint32_t i_links_count;  // 硬连接的链接计数
            char *i_symlink_target;  // 软连接的目标路径
        };
        struct spinlock i_lock;  // 自旋锁，用于同步对 inode 结构体的访问
    };
    ```

2. **`dentry` 结构体扩展：**

    ```c
    struct dentry {
        // 其他字段...
        char *d_iname;  // 软连接的目标路径
        struct spinlock d_lock;  // 自旋锁，用于同步对 dentry 结构体的访问
    };
    ```

接口：

1. **创建硬连接：**

    ```c
    int hard_link(const char *oldpath, const char *newpath);
    ```

    - 检查 oldpath 是否有效，并获取其对应的 inode。
    - 在新路径 newpath 处创建一个目录项，共享相同的 inode。
    - 增加 inode 的链接计数。

2. **创建软连接：**

    ```c
    int symlink(const char *target, const char *linkpath);
    ```

    - 在 linkpath 处创建一个目录项，该目录项指向一个新的 inode。
    - 为新 inode 分配空间以存储软连接目标路径。
    - 将软连接目标路径写入新 inode。

3. **读取软连接目标路径：**

    ```c
    ssize_t readlink(const char *path, char *buf, size_t bufsiz);
    ```

    - 读取给定路径的 inode。
    - 如果 inode 是软连接，则读取其中的目标路径到缓冲区 buf。

4. **删除链接：**

    ```c
    int unlink(const char *pathname);
    ```

    - 检查路径是否有效，并获取其对应的 inode。
    - 如果是硬链接，则减少 inode 的链接计数。
    - 如果是软链接，则释放相关的 inode 和目录项。

5. **同步互斥处理：**

    - 使用锁保护对 `inode` 结构体和相关数据结构的访问，确保对链接计数和目标路径的操作是原子的。
    - 在增加或减少链接计数时使用自旋锁以防止竞态条件。
    - 在写入软连接目标路径时使用锁以确保正确的写入和防止多个进程同时修改。
    
    ```c
    // 初始化锁
    void lock_init(struct spinlock *lock) {
        // ... 初始化锁的相关操作
    }
    
    // 获取锁
    void lock_acquire(struct spinlock *lock) {
        // ... 获取锁的相关操作
    }
    
    // 释放锁
    void lock_release(struct spinlock *lock) {
        // ... 释放锁的相关操作
    }
    ```

设计思路：

1. `inode` 结构体中的 `i_flags` 可以用于标志连接类型，例如硬连接或软连接。
2. `dentry` 结构体中的 `d_iname` 字段存储软连接的目标路径。
3. 创建硬链接时，需要检查链接计数并增加它。
4. 创建软连接时，需要为新的 inode 分配空间以存储软连接目标路径，并写入目标路径。
5. 在删除链接时，需要减少链接计数，并在硬链接的计数为零时释放相关资源。
6. 为了处理同步互斥问题，需要使用锁来保护对相关数据结构的访问。增加和减少链接计数时使用自旋锁，以确保原子性。在写入软连接目标路径时使用锁，以确保正确的写入和防止多个进程同时修改。

