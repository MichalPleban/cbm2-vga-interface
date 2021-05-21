PUB start(_ibm_screen, _mode)

              longfill(@ibm_screen, _ibm_screen, 1)
              longfill(@mode_ptr, _mode, 1)
              cognew(@cog, 0)

              return

DAT

'==========================================================================================

              org
cog
              waitpne port_value, port_mask
              waitpeq port_value, port_mask

              mov bus_addr, ina
              mov bus_data, ina
              shr bus_addr, #16
              and bus_addr, addr_mask
              shr bus_data, #8
              and bus_data, #$FF

              cmp bus_addr, cmd_port     wz
              if_e  jmp #cmd_write

              jmp #cog

cmd_write
              cmp bus_data, #80          wz
              if_e jmp #cmd_switch
              cmp bus_data, #81          wz
              if_e jmp #cmd_clear

              jmp #cog

              ' Command 80 - switch to IBM mode
cmd_switch
              wrlong mode_ibm, mode_ptr
              jmp #cog

              ' Command 81 - clear IBM screen
cmd_clear
              mov write_ptr, ibm_screen
              mov write_cnt, clear_cnt
:loop
              wrlong clear_value, write_ptr
              add write_ptr, #4
              djnz clear_cnt, #:loop
              jmp #cog

ibm_screen    long 0
port_value    long $00000000
port_mask     long $80000000
addr_mask     long $0FFF

cmd_port      long $0ABC
data_port     long $0ABD      ' 55996

mode_ptr      long 0
mode_ibm      long 1

clear_value   long $0A200A20
clear_cnt     long 1000

bus_addr      res 1
bus_data      res 1

ibm_ptr       res 1

write_ptr     res 1
write_cnt     res 1
