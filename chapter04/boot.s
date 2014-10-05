.set	BOTPAK,  0x00280000 # bootpackのロード先
.set	DSKCAC,  0x00100000 # ディスクキャッシュの場所
.set	DSKCAC0, 0x00008000 # ディスクキャッシュの場所(リアルモード)

// BOOT_INFO
.set	CYLS, 0x0ff0	# シリンダ数
.set	LEDS,0x0ff1	# LEDの状態
.set	VMODE, 0x0ff2	# ビデオモード
.set	SCRNX, 0x0ff4	# 解像度X
.set	SCRNY, 0x0ff6	# 解像度Y
.set	VRAM, 0x0ff8	# VRAMの開始アドレス

.text
.code16

	// ビデオモードを変更する
	movb	$0x00, %ah	# VGA Graphics 320x200x8bit
	movb	$0x13, %al
	int	$0x10

	// 画面の状態を記録する
	movb	$8, (VMODE)
	movw	$320, (SCRNX)
	movw	$200, (SCRNY)
	movl	$0x000a0000, (VRAM)

	// LEDの状態を記録する
	movb	$0x02, %ah
	int	$0x16
	movb	%al, (LEDS)

	// PICが割り込みを受け付けないようにする
	movb	$0xff, %al
	outb	%al, $0x21
	nop			# outは連続して使用しない
	outb	%al, $0xa1
	cli			# CPUでも割り込み禁止

	// A20互換モードを無効にして1MB以上のアドレスにアクセスできるようにする
	call	waitkbdout
	movb	$0xd1, %al
	outb	%al, $0x64
	call	waitkbdout
	movb	$0xdf, %al	# A20を有効にする
	outb	%al, $0x60
	call	waitkbdout

	// プロテクトモードに移行する
.arch i486
	lgdt	(GDTR0)
	movl	%cr0, %eax
	andl	$0x7fffffff, %eax	# ページング禁止
	orl	$0x00000001, %eax	# プロテクトモード移行
	movl	%eax, %cr0
	jmp	pipelineflush
pipelineflush:
	movw	$1*8, %ax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

	// bootpackを転送する
	movl	$bootpack, %esi	# 転送元
	movl	$BOTPAK, %edi	# 転送先
	movl	$512*1024/4, %ecx # 4で割っているのは4バイト単位で処理するため
	call	memcpy

	// ディスクイメージを本来の位置へ転送する

	// ブートセクタ
	movl	$0x7c00, %esi
	movl	$DSKCAC, %edi
	movl	$512/4, %ecx
	call	memcpy
	
	// 残り
	movl	$DSKCAC0+512, %esi
	movl	$DSKCAC+512, %edi
	movl	$0, %ecx
	movb	(CYLS), %cl	  # 読み込んだシリンダ数
	imull	$512*18*2/4, %ecx # 1シリンダあたりのバイト数/4を掛ける
	sub	$512/4, %ecx      # IPL分を引く
	call	memcpy

	// bootpackを起動する
	movl	$BOTPAK, %ebx
	movl	16(%ebx), %ecx
	addl	$3, %ecx
	shrl	$2, %ecx
	jz	skip		# 転送するものがない
	movl	20(%ebx), %esi  # .dataのアドレス
	addl	%ebx, %esi
	movl	12(%ebx), %edi	# .data転送先
	call	memcpy
skip:	
	movl	12(%ebx), %esp  # スタック初期値
	ljmpl	$2*8, $0x0000001b
	
waitkbdout:
	inb	$0x64, %al
	andb	$0x02, %al
#	inb	$0x60, %al # 元のソースにはないコード
	jnz	waitkbdout
	ret

memcpy:
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%eax, (%edi)
	addl	$4, %edi
	subl	$1, %ecx
	jnz	memcpy
	ret

.align 16
	
GDT0:
	// GDTの構成
	// short limit_low, base_low
	// char base_mid, access_right
	// char limit_high, base_high
	
	// null selector
	.skip	8, 0x00
	// base=0x00000000 limit=0xcfffff access_right=0x92
	.word	0xffff, 0x0000, 0x9200, 0x00cf
	// base=0x00280000 limit=0x47ffff access_right=0x9a
	.word	0xffff, 0x0000, 0x9a28, 0x0047
	.word	0x0000
	
GDTR0:
	.word	8 * 3 - 1	# GDTのサイズ?
	.int	GDT0

.align 16
bootpack:
	# + 0 : stack+.data+heap の大きさ（4KBの倍数）
	.int	0x00
	# + 4 : シグネチャ 書籍では"Hari"
	.ascii "Tiny"
	# + 8 : mmarea の大きさ（4KBの倍数）
	.int	0x00
	# +12 : スタック初期値＆.data転送先
	.int	0x00310000
	# +16 : .dataのサイズ
	.int	0x11a8
	# +20 : .dataの初期値列がファイルのどこにあるか
	.int	0x10c8
	# +24 +28 のセットで 1bからの命令が E9 XXXXXXXX (JMP)になり、C言語のエントリポイントにJMPするようだ
	# +24 : 0xe9000000
	.int 	0xe9000000
	# +28 : エントリアドレス-0x20
	.int	0x04
	# +32 : heap領域（malloc領域）開始アドレス
	.int	0x00
