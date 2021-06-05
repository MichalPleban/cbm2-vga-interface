PUB start(_ibm_screen, _mode, _cursor_mode)

              longfill(@ibm_screen, _ibm_screen, 1)
              longfill(@mode_ptr, _mode, 1)
              longfill(@cursor_mode, _cursor_mode, 1)
              cognew(@cog, 0)

              return

DAT

'==========================================================================================

              org
cog
              mov write_ptr, ibm_screen
              add max_screen, ibm_screen

loop
              waitpne port_value, port_mask
              waitpeq port_value, port_mask

              mov bus_addr, ina
              mov bus_data, ina
              shr bus_addr, #16
              and bus_addr, addr_mask
              shr bus_data, #8
              and bus_data, #$FF

              cmp bus_addr, cmd_port      wz
              if_e  jmp #cmd_write
              cmp bus_addr, data_port     wz
              if_e  jmp #data_write

              jmp #loop

cmd_write
              test bus_data, #$80         wz
              if_e jmp #cmd_ptr
              cmp bus_data, #$80          wz
              if_e jmp #cmd_off
              cmp bus_data, #$81          wz
              if_e jmp #cmd_on
              cmp bus_data, #$82          wz
              if_e jmp #cmd_clear
              cmp bus_data, #$83          wz
              if_e jmp #cmd_scroll
              cmp bus_data, #$84          wz
              if_e jmp #cmd_cursoron
              cmp bus_data, #$85          wz
              if_e jmp #cmd_cursoroff

              jmp #loop


              ' Command 0x - set write pointer
cmd_ptr
              and bus_data, #$07
              shl bus_data, #9
              mov write_ptr, bus_data
              add write_ptr, ibm_screen
              jmp #loop

              ' Command 80 - switch to Commodore mode
cmd_off
              wrlong mode_cbm, mode_ptr
              jmp #loop

              ' Command 81 - switch to IBM mode
cmd_on
              wrlong mode_ibm, mode_ptr
              jmp #loop

              ' Command 82 - clear IBM screen
cmd_clear
              mov write_ptr, ibm_screen
              mov write_cnt, clear_cnt
loop1
              wrlong clear_value, write_ptr
              add write_ptr, #4
              djnz write_cnt, #loop1
              jmp #loop

              ' Command 83 - scroll IBM screen
cmd_scroll
              mov write_ptr, ibm_screen
              mov read_ptr, ibm_screen
              add read_ptr, #160
              mov write_cnt, scroll_cnt
loop2
              rdlong tmp, read_ptr
              wrlong tmp, write_ptr
              add read_ptr, #4
              add write_ptr, #4
              djnz write_cnt, #loop2
              mov write_cnt, #40
              jmp #loop1

              ' Write data to the pointer
data_write
              wrbyte bus_data, write_ptr
              cmp write_ptr, max_screen   wz
              if_ne  add write_ptr, #1
              jmp #loop

              ' Command 84 - cursor ON
cmd_cursoron
              wrlong cursor_on, cursor_mode
              jmp #loop

              ' Command 85 - cursor OFF
cmd_cursoroff
              wrlong cursor_off, cursor_mode
              jmp #loop

ibm_screen    long 0
port_value    long $00000000
port_mask     long $80000000
addr_mask     long $0FFF

cmd_port      long $0ABC      ' 55996
data_port     long $0ABD      ' 55997

mode_ptr      long 0
mode_cbm      long 0
mode_ibm      long 1

write_ptr     long 0
max_screen    long 4095

clear_value   long $0A200A20
clear_cnt     long 1000

scroll_cnt    long 960

cursor_mode   long 0
cursor_on     long $60
cursor_off    long $20

bus_addr      res 1
bus_data      res 1

ibm_ptr       res 1

read_ptr      res 1
write_cnt     res 1

tmp           res 1