.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void) # 内核线程的入口点
	move a0, s1				# 用于传递参数
	jalr s0					# s0寄存器存的是fn地址

	jal do_exit
