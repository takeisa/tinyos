.file "func.s"
	
.global io_hlt
.global io_cli, io_sti, io_stihlt
.global io_in8, io_in16, io_in32
.global io_out8, io_out16, io_out32
.global io_load_eflags, io_store_eflags
.global write_mem8

.arch i486

.section .text
	
io_hlt:		# void io_hlt(void)
	hlt
	ret

io_cli:		# void io_cli(void)
	cli
	ret

io_sti:		# void io_sti(void)
	sti
	ret

io_stihlt:	# void io_stihlt(void)
	sti
	hlt
	ret

io_in8:		# int io_in8(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inb	%dx, %al
	ret

io_in16:	# int io_in16(int port)
	movl	4(%esp), %edx
	movl	$0, %eax
	inw	%dx, %ax
	ret

io_in32:	# int io_in32(int port)
	movl	4(%esp), %edx
	inl	%dx, %eax
	ret

io_out8:	# void io_out8(int port, int data)
	movl	4(%esp), %edx	# port
	movl	8(%esp), %eax	# data
	outb	%al, %dx
	ret
	
io_out16:	# void io_out16(int port, int data)
	movl	4(%esp), %edx	# port
	movl	8(%esp), %eax	# data
	outw	%ax, %dx
	ret
	
io_out32:	# void io_out32(int port, int data)
	movl	4(%esp), %edx	# port
	movl	8(%esp), %eax	# data
	outl	%eax, %dx
	ret

io_load_eflags:		# int io_load_eflags(void)
	pushfl			
	pop	%eax		# eax <- eflags
	ret

io_store_eflags:	# void io_store_eflags(int eflags)
	movl	4(%esp), %eax
	push	%eax		
	popfl			# eflags <- %eax
	ret
	
write_mem8:	# void write_mem8(int addr, int date)
 	movl	4(%esp), %ecx
 	movb	8(%esp), %al
 	movb	%al, (%ecx)
 	ret

