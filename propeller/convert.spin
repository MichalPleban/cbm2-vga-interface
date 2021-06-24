
PUB start(_cbm_screen, _cbm_font, _ibm_screen, _ibm_font, _frame_buffer, _pointer, _config)

              longfill(@cbm_screen, _cbm_screen, 1)
              longfill(@cbm_font, _cbm_font, 1)
              longfill(@ibm_screen, _ibm_screen, 1)
              longfill(@ibm_font, _ibm_font, 1)
              longfill(@frame_buffer, _frame_buffer, 1)
              longfill(@ptr_addr, _pointer, 1)
              longfill(@cursor_addr, _config+0*4, 1)
              longfill(@cursor_show, _config+3*4, 1)
              longfill(@mode_ptr, _config+1*4, 1)
              longfill(@graph_ptr, _config+2*4, 1)
              longfill(@blink_ptr, _config+4*4, 1)
              longfill(@german_ptr, _config+6*4, 1)
              longfill(@altfont_ptr, _config+7*4, 1)
              cognew(@cog, 0)

              return


DAT

'==========================================================================================

              org
cog

              ' Wait for synchronization from display cog
:loop
              rdlong char_number, ptr_addr
              cmp char_number, ptr_null           wz
              if_e jmp #:loop

              ' Reset synchronization pointer
              wrlong ptr_null, ptr_addr

              ' Start drawing from received pointer
              mov dst_ptr, frame_buffer

              ' Read cursor position and visibility
              rdlong crsr_visible, cursor_show
              rdlong blink_visible, blink_ptr
              and crsr_visible, #1                wz
              if_nz rdlong cursor_ptr, cursor_addr
              if_z  mov cursor_ptr, #0
              if_z  sub cursor_ptr, #1

              rdlong do_ibm, mode_ptr
              cmp do_ibm, #1                      wz
              if_e  jmp #:ibm

              call #cbm_line
              jmp #:end
:ibm
              call #ibm_line

:end

              jmp #:loop


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Draw a whole line of 80 characters (Commodore)
cbm_line
              rdlong do_graph, graph_ptr
              mov src_ptr, cbm_screen
              add src_ptr, char_number
              mov font_start, cbm_font
              mov char_count, #40

              ' Test if German font needs to be displayed
              rdlong tmp_1, german_ptr
              rdlong tmp_2, altfont_ptr
              and tmp_1, #1                      wz
              if_z  jmp #:loop
              and tmp_2, #1                      wz
              if_nz jmp #:loop
              add font_start, font_size

:loop
              mov display_xor, #0
              mov display_or, #0

              ' Read two bytes
              rdbyte char_value_1, src_ptr
              add src_ptr, #1
              rdbyte char_value_2, src_ptr
              add src_ptr, #1

              ' Handle cursor display
              cmp char_number, cursor_ptr           wz
              if_z  mov display_xor, char_mask_1
              add char_number, #1
              cmp char_number, cursor_ptr           wz
              if_z  mov display_xor, char_mask_2
              add char_number, #1

              ' Handle character reverse
              mov reverse_1, char_value_1
              and reverse_1, #$80                   wz
              if_nz xor display_xor, char_mask_1
              mov reverse_2, char_value_2
              and reverse_2, #$80                   wz
              if_nz xor display_xor, char_mask_2

              ' Prepare characters
              cmp do_graph, #1                      wz
              and char_value_1, #$7F
              and char_value_2, #$7F
              if_e  or char_value_1, #$80
              if_e  or char_value_2, #$80
              mov underline_1, #0
              mov underline_2, #0
              mov blank_1, #0
              mov blank_2, #0

              call #draw_chars
              djnz char_count, #:loop
cbm_line_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Draw a whole line of 80 characters (IBM)
ibm_line
              mov src_ptr, ibm_screen
              shl char_number, #1
              add src_ptr, char_number
              shr char_number, #1
              mov font_start, ibm_font
              mov char_count, #40
:loop
              mov display_xor, #0
              mov display_or, #0

              ' Read two words
              rdword char_value_1, src_ptr
              add src_ptr, #2
              rdword char_value_2, src_ptr
              add src_ptr, #2

              ' Handle cursor display
              cmp char_number, cursor_ptr           wz
              if_z  mov display_xor, char_mask_1
              add char_number, #1
              cmp char_number, cursor_ptr           wz
              if_z  mov display_xor, char_mask_2
              add char_number, #1

              ' Invert characters
              mov tmp_1, char_value_1
              shr tmp_1, #8
              and tmp_1, #$77
              cmp tmp_1, #$70                       wz
              if_e  xor display_xor, char_mask_1
              mov tmp_2, char_value_2
              shr tmp_2, #8
              and tmp_2, #$77
              cmp tmp_2, #$70                       wz
              if_e  xor display_xor, char_mask_2

              ' High intensity characters
              mov tmp_1, char_value_1
              shr tmp_1, #8
              and tmp_1, #$08
              cmp tmp_1, #$08                       wz
              if_e  or display_or, char_int_1
              mov tmp_2, char_value_2
              shr tmp_2, #8
              and tmp_2, #$08
              cmp tmp_2, #$08                       wz
              if_e  or display_or, char_int_2

              ' Underline characters
              mov underline_1, char_value_1
              shr underline_1, #8
              and underline_1, #$07
              mov underline_2, char_value_2
              shr underline_2, #8
              and underline_2, #$07

              ' Blank characters
              mov blank_1, char_value_1
              and blank_1, blank_mask
              cmp blank_1, #0                        wz
              if_e  mov blank_1, #1
              if_ne mov blank_1, char_value_1
              if_ne shr blank_1, #15
              if_ne and blank_1, blink_visible
              mov blank_2, char_value_2
              and blank_2, blank_mask
              cmp blank_2, #0                        wz
              if_e  mov blank_2, #1
              if_ne mov blank_2, char_value_2
              if_ne shr blank_2, #15
              if_ne and blank_2, blink_visible

              and char_value_1, #$FF
              and char_value_2, #$FF

              call #draw_chars
              djnz char_count, #:loop
ibm_line_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Draw two adjacent characters
draw_chars
              mov font_ptr_1, char_value_1
              shl font_ptr_1, #4
              add font_ptr_1, font_start
              mov font_ptr_2, char_value_2
              shl font_ptr_2, #4
              add font_ptr_2, font_start

              ' Handle underline display
              mov display_undr, #0
              cmp underline_1, #1               wz
              if_e  or display_undr, char_mask_1
              cmp underline_2, #1               wz
              if_e  or display_undr, char_mask_2

              ' Handle character blanking
              mov display_and, #0
              cmp blank_1, #1                   wz
              if_ne or display_and, char_mask_1
              cmp blank_2, #1                   wz
              if_ne or display_and, char_mask_2

              ' Write 4 x 4 longs
              mov font_count, #4
:loop
              rdlong font_tmp_1, font_ptr_1
              add font_ptr_1, #4
              rdlong font_tmp_2, font_ptr_2
              add font_ptr_2, #4
              call #translate
              wrlong display_value, dst_ptr
              add dst_ptr, #160
              call #translate
              wrlong display_value, dst_ptr
              add dst_ptr, #160
              call #translate
              ' Line #14 - draw underline
              cmp font_count, #1                wz
              if_e  or display_value, display_undr
'              if_e  and display_value, display_and
              wrlong display_value, dst_ptr
              add dst_ptr, #160
              call #translate
              wrlong display_value, dst_ptr
              add dst_ptr, #160
              djnz font_count, #:loop

              sub dst_ptr, dst_sub
draw_chars_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
              ' Translate binary font into display data
translate
              mov font_value_1, font_tmp_1
              and font_value_1, #$FF
              add font_value_1, #translation
              movs :fetch_1, font_value_1
              shr font_tmp_1, #8
:fetch_1
              mov display_value, 0

              mov font_value_2, font_tmp_2
              and font_value_2, #$FF
              add font_value_2, #translation
              movs :fetch_2, font_value_2
              shr font_tmp_2, #8
:fetch_2
              mov display_tmp, 0

              shl display_tmp, #16
              or display_value, display_tmp
              and display_value, display_and
              or display_value, display_or
              xor display_value, display_xor
translate_ret
              ret


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

mode_ptr      long 0
graph_ptr     long 0

cbm_screen    long 0
ibm_screen    long 0
frame_buffer  long 0
cbm_font      long 0
ibm_font      long 0
ptr_addr      long 0

german_ptr    long 0
altfont_ptr   long 0
font_size     long 4096

cursor_addr   long 0
cursor_show   long 0

blink_ptr     long 0

dst_sub       long 2556
ptr_null      long $FFFFFFFF
char_mask_1   long $00005555
char_mask_2   long $55550000
char_int_1    long $0000AAAA
char_int_2    long $AAAA0000

blank_mask    long $7700

translation   file "conversion.bin"

do_ibm        res 1
do_graph      res 1

src_ptr       res 1
dst_ptr       res 1
font_start    res 1
font_ptr_1    res 1
font_ptr_2    res 1

crsr_visible  res 1
cursor_ptr    res 1

blink_visible res 1

line_count    res 1
char_count    res 1
font_count    res 1

char_value_1  res 1
char_value_2  res 1
font_value_1  res 1
font_value_2  res 1

underline_1   res 1
underline_2   res 1
reverse_1     res 1
reverse_2     res 1
cursor_1      res 1
cursor_2      res 1
blank_1       res 1
blank_2       res 1

display_value res 1

font_tmp_1    res 1
font_tmp_2    res 1
display_tmp   res 1

display_xor   res 1
display_undr  res 1
display_and   res 1
display_or    res 1

char_number   res 1

tmp_1         res 1
tmp_2         res 1
