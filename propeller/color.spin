PUB start(_cbm_screen, _ibm_screen, _color_buffer, _mode)

              longfill(@cbm_screen, _cbm_screen, 1)
              longfill(@ibm_screen, _ibm_screen, 1)
              longfill(@color_buffer, _color_buffer, 1)
              longfill(@mode_ptr, _mode, 1)
              cognew(@cog, 0)

              return

DAT

'==========================================================================================

              org
cog

:loop
              rdlong do_ibm, mode_ptr
              cmp do_ibm, #1                      wz
              if_e  jmp #:ibm

              call #screen_cbm
              jmp #:end
:ibm
              call #screen_ibm
:end
              jmp #:loop


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
               ' Convert colors of the screen (Commodore)
screen_cbm
              mov src_ptr, cbm_screen
              mov dst_ptr, color_buffer
              mov screen_cnt, screen_size
:loop
              rdbyte char_value, src_ptr
              add src_ptr, #1
              and char_value, #$80               wz
              if_z  mov color_value, color_normal
              if_nz mov color_value, color_invert
              wrword color_value, dst_ptr
              add dst_ptr, #2
              djnz screen_cnt, #:loop
screen_cbm_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
               ' Convert colors of the screen (IBM)
screen_ibm
              mov src_ptr, ibm_screen
              mov dst_ptr, color_buffer
              mov screen_cnt, screen_size

              add src_ptr, #1
:loop
              rdbyte char_value, src_ptr
              add src_ptr, #2
              add char_value, #translation
              movs :fetch, char_value
              nop
:fetch
              mov color_value, color_normal
              wrword color_value, dst_ptr
              add dst_ptr, #2
              djnz screen_cnt, #:loop
screen_ibm_ret
              ret

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

mode_ptr      long 0

cbm_screen    long 0
ibm_screen    long 0
color_buffer  long 0

color_normal  long $5703
color_invert  long $0357

screen_size   long 2000

translation   file "colors.bin"

do_ibm        res 1

src_ptr       res 1
dst_ptr       res 1

screen_cnt    res 1
char_value    res 1
color_value   res 1