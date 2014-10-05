/*
 ipl.s
*/
	.text	
	.code16
	jmp	entry
	.byte	0x90
	.ascii	"TINY_IPL"	# ブートセクタの名前
	.word	512		# 1セクタのバイト数
	.byte	1		# クラスタの数
	.word	1		# FAT開始セクタ
	.byte	2		# FATの個数
	.word	224		# ルートディレクトリ領域のエントリ数
	.word	2880		# ドライブのセクタ数
	.byte   0xF0		# メディアタイプ
	.word	9		# FAT領域のセクタ数
	.word	18		# 1トラックのセクタ数
	.word	2		# ヘッド数
	.int	0		# ?
	.int	2880		# ドライブのセクタ数
	.byte	0, 0, 0x29	# ?
	.int	0xFFFFFFFF	# ボリュームシリアル番号
	.ascii	"TINY-OS    "	# ディスクの名前
	.ascii	"FAT12   "	# フォーマットの名前
	.space 18

// プログラム
	.set	MAX_RETRY, 5	# 再読み込み最大回数
	.set	MAX_SECTOR, 18	# 最大セクタ数
	.set	MAX_HEAD, 2	# 最大ヘッド数
	.set	MAX_CYLINDER, 10	# 最大シリンダ数

entry:
	movw	$0, %ax
	movw	%ax, %ss
	movw	$0x7C00, %sp
	movw	%ax, %ds

	// 2セクタから1セクタ分読み込む
	movw	$0x0820, %ax
	movw	%ax, %es
	movb	$0, %ch		# シリンダ0
	movb	$0, %dh		# ヘッド0
	movb	$2, %cl		# セクタ2

readloop:	
	movw	$0, %si		# 失敗回数

retry:
	movb	$0x02, %ah	# Read sector(s) into memory
	movb	$1, %al		# 1セクタ読み込む
	movw	$0, %bx		# ES:BX Data buffer(0x8200に読み込む)
	movb	$0x00, %dl	# Aドライブ
	int	$0x13		# BIOS interrupt call
	jnc	next		# 読み込みOK でnextへ

	add	$1, %si
	cmp	$MAX_RETRY, %si
	jae	error		# SI >= MAX_RETRY でerrorへ

	movb	$0x00, %ah	# Reset disk system
	movb	$0x00, %dl	# Aドライブ
	int	$0x13
	jmp	retry

next:
	movw	%es, %ax	# ES = ES + 0x20(512バイト)
	add	$0x20, %ax
	movw	%ax, %es
	// セクタ
	add	$1, %cl
	cmp	$MAX_SECTOR, %cl
	jbe	readloop	# セクタは 1 〜 MAX_SECTOR
	movb	$1, %cl
	// ヘッド
	add	$1, %dh
	cmp	$MAX_HEAD, %dh
	jb	readloop	# ヘッドは 0 〜 MAX_HEAD - 1
	movb	$0, %dh
	// シリンダ
	add	$1, %ch
	cmp	$MAX_CYLINDER, %ch
	jb	readloop	# シリンダは 0 〜 MAX_CYLINDER - 1

	movb	%ch, (0x0ff0)	# 読み込んだシリンダ数を記録する
	jmp	0xC200		# 0x8000 + 0x4200 = 0xC200
	
error:	
	movw	$msg, %si
putloop:
	movb	(%si), %al
	add	$1, %si
	cmp	$0, %al
	je	fin		# メッセージの後ろの0x00で終了する
	movb	$0x0E, %ah	# Write Character in TTY Mode
	movw	$15, %bx	# カラーコード
	int	$0x10		# BIOS interrupt call
	jmp	putloop
fin:
	hlt
	jmp	fin

// メッセージ	
msg:	
	.string	"\n\nload error\n"

	.org 0x1FE
	.byte 0x55, 0xAA	# 55AAでブートセクタ
