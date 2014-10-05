void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);

void box_fill8(unsigned char *vram, int width, int x0, int y0, int x1, int y1, unsigned char c);

void draw_border(void);
void draw_boxes(void);
void draw_desktop(void);

#define COLOR_BLACK	0
#define COLOR_RED	1
#define COLOR_GREEN	2
#define COLOR_BLUE	4
#define COLOR_WHITE	7
#define COLOR_GRAY	8
#define COLOR_DARK_AQUA 14
#define COLOR_DARK_GRAY 15

void Main(void) {
  //__asm__("hlt\n\t");

  init_palette();

  // draw_border();
  // draw_boxes();
  draw_desktop();
  
  for (;;) {
    io_hlt();
  }
}

void draw_border() {
  int i;
  char *p;

  p = (char *)0xa0000;

  for (i = 0; i <= 0xffff; i++) {
    *p = i & 0xf;
    p++;
  }
}

void draw_boxes() {
  char *vram = (char*)0xa0000;
  int width = 320;
  box_fill8(vram, width, 20, 20, 120, 120, COLOR_RED);
  box_fill8(vram, width, 70, 50, 170, 150, COLOR_GREEN);
  box_fill8(vram, width, 120, 80, 220, 180, COLOR_BLUE);
}

void box_fill8(unsigned char *vram, int width, int x0, int y0, int x1, int y1, unsigned char c) {
  int x, y;
  for (y = y0; y <= y1; y++) {
    for (x = x0; x <= x1; x++) {
      vram[y * width + x] = c;
    }
  }
}

void draw_desktop(void) {
  char *vram;
  int width, height;

  vram = (char *) 0xa0000;
  width = 320;
  height = 200;

  box_fill8(vram, width, 0,          0,           width -  1, height - 29, COLOR_DARK_AQUA);
  box_fill8(vram, width, 0,          height - 28, width -  1, height - 28, COLOR_GRAY);
  box_fill8(vram, width, 0,          height - 27, width -  1, height - 27, COLOR_WHITE);
  box_fill8(vram, width, 0,          height - 26, width -  1, height -  1, COLOR_GRAY);
  box_fill8(vram, width, 3,          height - 24, 59,         height - 24, COLOR_WHITE);
  box_fill8(vram, width, 2,          height - 24,  2,         height -  4, COLOR_WHITE);
  box_fill8(vram, width, 3,          height -  4, 59,         height -  4, COLOR_DARK_GRAY);
  box_fill8(vram, width, 59,         height - 23, 59,         height -  5, COLOR_DARK_GRAY);
  box_fill8(vram, width, 2,          height -  3, 59,         height -  3, COLOR_BLACK);
  box_fill8(vram, width, 60,         height - 24, 60,         height -  3, COLOR_BLACK);
  box_fill8(vram, width, width - 47, height - 24, width -  4, height - 24, COLOR_DARK_GRAY);
  box_fill8(vram, width, width - 47, height - 23, width - 47, height -  4, COLOR_DARK_GRAY);
  box_fill8(vram, width, width - 47, height -  3, width -  4, height -  3, COLOR_WHITE);
  box_fill8(vram, width, width -  3, height - 24, width -  3, height -  3, COLOR_WHITE);
}

void init_palette(void) {
  /* static を付けると正しくパレットを設定できない */
  /* 実行時の table_rgbのアドレスがずれる？ */
  unsigned char table_rgb[16 * 3] = {
    0x00, 0x00, 0x00, /* 0: 黒 */
    0xff, 0x00, 0x00, /* 1: 明るい赤 */
    0x00, 0xff, 0x00, /* 2: 明るい緑 */
    0xff, 0xff, 0x00, /* 3: 明るい黄色 */
    0x00, 0x00, 0xff, /* 4: 明るい青 */ 
    0xff, 0x00, 0xff, /* 5: 明るい紫 */ 
    0x00, 0xff, 0xff, /* 6: 明るい水色 */
    0xff, 0xff, 0xff, /* 7: 白 */       
    0xc6, 0xc6, 0xc6, /* 8: 明るい灰色 */
    0x84, 0x00, 0x00, /* 9: 暗い赤 */   
    0x00, 0x84, 0x00, /* 10: 暗い緑 */  
    0x84, 0x84, 0x00, /* 11: 暗い黄色 */
    0x00, 0x00, 0x84, /* 12: 暗い青 */  
    0x84, 0x00, 0x84, /* 13: 暗い紫 */  
    0x00, 0x84, 0x84, /* 14: 暗い水色 */
    0x84, 0x84, 0x84  /* 15: 暗い灰色 */
  };
  set_palette(0, 15, table_rgb);
  return;
}

void set_palette(int start, int end, unsigned char *rgb) {
  int i, eflags;
  /* 割り込み許可フラグの値を記録する */
  eflags = io_load_eflags();
  /* 許可フラグを 0 にして割り込み禁止にする */
  io_cli();

  io_out8(0x03c8, start);
  for (i = start; i <= end; i++) {
    io_out8(0x03c9, rgb[0] / 4);
    io_out8(0x03c9, rgb[1] / 4);
    io_out8(0x03c9, rgb[2] / 4);
    rgb += 3;
  }

  /* 割り込み許可フラグを元に戻す */
  io_store_eflags(eflags);
  
  return;
}
