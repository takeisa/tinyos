OUTPUT_FORMAT("binary");

IPL_BASE = 0x7C00;

SECTIONS {
	 . = IPL_BASE;
	 .text   : {*(.text)}
	 .data   : {*(.data)}
}
