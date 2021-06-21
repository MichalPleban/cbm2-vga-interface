CON
              _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
              _xinfreq = 5_000_000

VAR
              long  frame_buffer_1[640]
              long  frame_buffer_2[640]
              long  frame_buffer_3[640]
              long  pointer_1, pointer_2, pointer_3
              long  config[6]
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

              display.start(@frame_buffer_1, @frame_buffer_2, @frame_buffer_3, @pointer_1, @pointer_2, @pointer_3, @config)
              convert.start(@cbm_screen, @cbm_font, @ibm_screen, @ibm_font, @frame_buffer_1, @pointer_1, @config)
              convert.start(@cbm_screen, @cbm_font, @ibm_screen, @ibm_font, @frame_buffer_2, @pointer_2, @config)
              convert.start(@cbm_screen, @cbm_font, @ibm_screen, @ibm_font, @frame_buffer_3, @pointer_3, @config)
              io.start(@cbm_screen, @config)
              ibm.start(@ibm_screen, @config)
              return

PRI init | x, y

              config[0] := 0    ' Cursor position
              config[1] := 0    ' IBM mode
              config[2] := 0    ' Graphics mode
              config[3] := 0    ' Cursor blink indicator
              config[4] := 0    ' Character blink indicator
              config[5] := $40  ' Cursor mode
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