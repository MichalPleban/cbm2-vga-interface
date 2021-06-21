CON
              _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
              _xinfreq = 5_000_000

VAR
              long  frame_buffer_1[640]
              long  frame_buffer_2[640]
              long  frame_buffer_3[640]
              long  pointer_1, pointer_2, pointer_3
              long  cursor_pos, cursor_blink, cursor_mode, blink
              long  mode
              long  graph
              byte  cbm_screen[2048]
              byte  ibm_screen[4096]

OBJ
              display: "display"
              convert: "convert"
              io: "io"
              ibm: "ibm"

PUB main

              init
              start
              clock

PRI start

              display.start(@frame_buffer_1, @frame_buffer_2, @frame_buffer_3, @pointer_1, @pointer_2, @pointer_3, @cursor_blink, @cursor_mode, @blink)
              convert.start(@cbm_screen, @cbm_font, @ibm_screen, @ibm_font, @frame_buffer_1, @pointer_1, @cursor_pos, @cursor_blink, @mode, @graph, @blink)
              convert.start(@cbm_screen, @cbm_font, @ibm_screen, @ibm_font, @frame_buffer_2, @pointer_2, @cursor_pos, @cursor_blink, @mode, @graph, @blink)
              convert.start(@cbm_screen, @cbm_font, @ibm_screen, @ibm_font, @frame_buffer_3, @pointer_3, @cursor_pos, @cursor_blink, @mode, @graph, @blink)
              io.start(@cbm_screen, @cursor_pos, @graph, @mode, @cursor_mode)
              ibm.start(@ibm_screen, @mode, @cursor_mode)
              return

PRI init | x, y

              cursor_pos := 0
              mode := 0
              graph := 0
              cursor_blink := 0
              blink := 0
              cursor_mode := $60
              longfill(@cbm_screen, $20202020, 500)
              longfill(@ibm_screen, $07200720, 1000)

'              repeat x from 0 to 31
'                  repeat y from 0 to 7
'                      cbm_screen[(x+4) * 2 + (y+2) * 160] := x + y * 32
'              repeat x from 0 to 15
'                  repeat y from 0 to 15
'                      ibm_screen[x*6+y*160] := "<"
'                      ibm_screen[x*6+y*160+2] := ">"
'                      ibm_screen[x*6+y*160+1] := x + 16 * y
'                      ibm_screen[x*6+y*160+3] := x + 16 * y

              return

PRI clock
              dira[28] := 1
              repeat
                  outa[28] := 1
                  waitcnt(cnt + clkfreq / 100)
                  outa[28] := 0
                  waitcnt(cnt + clkfreq / 100)

DAT

cbm_font      file "cbm_us_8x16.bin"
              file "cbm_din_8x16.bin"
ibm_font      file "IBM_VGA_8x16.bin"