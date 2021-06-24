CON
              CLOCK = $1423D70A            ' 25.175 MHz


PUB start(_frame_buffer_1, _frame_buffer_2, _frame_buffer_3, _pointer_1, _pointer_2, _pointer_3, _config)

              longfill(@frame_start_1, _frame_buffer_1, 1)
              longfill(@frame_start_2, _frame_buffer_2, 1)
              longfill(@frame_start_3, _frame_buffer_3, 1)
              longfill(@src_addr_1, _pointer_1, 1)
              longfill(@src_addr_2, _pointer_2, 1)
              longfill(@src_addr_3, _pointer_3, 1)
              longfill(@cursor_blink, _config+3*4, 1)
              longfill(@cursor_mode, _config+5*4, 1)
              longfill(@blink_ptr, _config+4*4, 1)
              cognew(@cog, 0)

              return

DAT

'==========================================================================================

              org
cog
              ' Initialize output pins, video and PLL
              mov dira, #$FF
              mov vcfg, vcfg_init
              mov vscl, vscl_pixels
              movi ctra, #%00001_101
              mov frqa, frqa_value


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
picture
              call #external

              ' Prefill three buffer frames
              mov trans_addr, #0
              wrlong trans_addr, src_addr_1
              add trans_addr, #80
              wrlong trans_addr, src_addr_2
              add trans_addr, #80
              wrlong trans_addr, src_addr_3

              ' Vertical back porch
              mov line_count, #33+40
              call #blank_lines

              mov segment_count, #8
:loop
              ' Draw buffer 1
              mov frame_ptr, frame_start_1
              call #display_segment
              add trans_addr, #80
              wrlong trans_addr, src_addr_1
              ' Draw buffer 2
              mov frame_ptr, frame_start_2
              call #display_segment
              add trans_addr, #80
              wrlong trans_addr, src_addr_2
              ' Draw buffer 3
              mov frame_ptr, frame_start_3
              call #display_segment
              add trans_addr, #80
              wrlong trans_addr, src_addr_3
              djnz segment_count, #:loop
              ' Draw buffer 1 in the end
              mov frame_ptr, frame_start_1
              call #display_segment

              ' Vertical front porch
              mov line_count, #10+40
              call #blank_lines

              ' Vertical sync
              mov line_count, #2
              call #vsync_lines

              ' Animate the cursor
              call #cursor
              call #blink

              jmp #picture


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' One text line of 80 characters
display_segment
              mov line_count, #16
:loop
              call #display_line
              djnz line_count, #:loop
display_segment_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' One video line
display_line
              mov vscl, #48            ' Horizontal back porch
              waitvid color_sync, #0

              mov char_count, #40
              sub frame_ptr, #4
              mov vscl, vscl_pixels
:loop
              add frame_ptr, #4
              rdlong frame_value, frame_ptr
              waitvid color_test, frame_value
              djnz char_count, #:loop

              mov vscl, #16            ' Horizontal front porch
              waitvid color_sync, #0
              mov vscl, #96            ' Horizontal sync
              waitvid color_sync, #2

              add frame_ptr, #4
display_line_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Blank line
blank_lines
              mov vscl, #256           ' Back porch + Frame + Front porch
              waitvid color_sync, #0
              mov vscl, #256
              waitvid color_sync, #0
              mov vscl, #192
              waitvid color_sync, #0
              mov vscl, #96            ' Horizontal sync
              waitvid color_sync, #2
              djnz line_count, #blank_lines
blank_lines_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Blank line with vsync
vsync_lines
              mov vscl, #256           ' Back porch + Frame + Front porch
              waitvid color_sync, #1
              mov vscl, #256
              waitvid color_sync, #1
              mov vscl, #192
              waitvid color_sync, #1
              mov vscl, #96            ' Horizontal sync pulse width
              waitvid color_sync, #3
              djnz line_count, #vsync_lines
vsync_lines_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Animate the cursor
cursor
              rdbyte cursor_type, cursor_mode
              cmp cursor_type, #$00             wz
              if_z  mov cursor_value, #1
              if_z  jmp #cursor_finish
              cmp cursor_type, #$20             wz
              if_z  mov cursor_value, #0
              if_z  jmp #cursor_finish

              cmp cursor_type, #$40             wz
              if_z  add cursor_cnt, #1
              add cursor_cnt, #1
              cmp cursor_cnt, #20               wz
              if_z  mov cursor_cnt, #0
              if_z  xor cursor_value, #1
cursor_finish
              wrlong cursor_value, cursor_blink
cursor_ret
              ret

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Provide the blinking interval
blink
              add blink_cnt, #1
              cmp blink_cnt, #20               wz
              if_z  mov blink_cnt, #0
              if_z  xor blink_value, #1
              wrlong blink_value, blink_ptr
blink_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

external
              ' Check if external input is connected
              mov display_ena, ina
              test display_ena, external_test           wz
              if_z  jmp #external_end
              mov dira, #0
              jmp #external
external_end
              mov dira, #$FF
external_ret
              ret

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

frqa_value    long CLOCK

              ' VSCFG initialization value:
              '   VMode  = VGA mode
              '   CMode  = 4 colors
              '   VGroup = P7..P0
              '   VPins  = all
vcfg_init     long %0_01_1_0_0_000_00000000000_000_0_11111111

              ' VSCL value for pushing out pixels
              '   PixelClocks = 1
              '   FrameClocks = 16
vscl_pixels   long %000000000000_00000001_000000010000

              ' VSCL value for pushing out sync signals
              '   PixelClocks = 0
              '   FrameClocks = x
vscl_sync     long %000000000000_00000000_000000000000

              ' "Color" values for synchronization
              '   0 - no sync
              '   1 - H sync
              '   2 - V sync
              '   3 - H & V sync
color_sync    long $00010203

color_test    long $FF035703
pixels_test   long $FF55AA00

external_test long $40000000

color_start   long 0
frame_start_1 long 0
frame_start_2 long 0
frame_start_3 long 0
src_addr_1    long 0
src_addr_2    long 0
src_addr_3    long 0

cursor_blink  long 0
cursor_cnt    long 0
cursor_value  long 0
cursor_mode   long 0

blink_ptr     long 0
blink_value   long 0
blink_cnt     long 0

segment_count res 1
line_count    res 1
char_count    res 1

color_ptr     res 1
frame_ptr     res 1

color_value   res 1
frame_value   res 1

trans_addr    res 1

cursor_type   res 1

display_ena   res 1