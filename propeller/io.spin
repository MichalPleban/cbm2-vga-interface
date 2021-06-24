PUB start(_cbm_screen, _config)

              longfill(@cbm_screen, _cbm_screen, 1)
              longfill(@cursor_pos, _config+0*4, 1)
              longfill(@graph_ptr, _config+2*4, 1)
              longfill(@mode_ptr, _config+1*4, 1)
              longfill(@cursor_mode, _config+5*4, 1)
              longfill(@german_ptr, _config+6*4, 1)
              longfill(@altfont_ptr, _config+7*4, 1)
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

              cmp bus_addr, crtc_regval     wz
              if_e  jmp #crtc_valwr

              cmp bus_addr, crtc_regno      wz
              if_e  jmp #crtc_regwr

              cmp bus_addr, tpi_port        wz
              if_e  jmp #tpi_write

              test bus_addr, io_area        wz
              if_ne jmp #io_write

              mov cbm_ptr, cbm_screen
              add cbm_ptr, bus_addr
              wrbyte bus_data, cbm_ptr
              cmp bus_addr, #0              wz
              if_e  wrbyte mode_value, mode_ptr
              jmp #cog

io_write

              jmp #cog

crtc_regwr
              mov crtc_register, bus_data
              jmp #cog

crtc_valwr
              cmp crtc_register, #02        wz
              if_e  jmp #:crtc_02
              cmp crtc_register, #12        wz
              if_e  jmp #:crtc_12
              cmp crtc_register, #10        wz
              if_e  jmp #:crtc_10
              cmp crtc_register, #14        wz
              if_e  jmp #:crtc_14
              cmp crtc_register, #15        wz
              if_ne jmp #cog

              mov cursor_lo, bus_data
:cursor
              mov bus_data, cursor_hi
              shl bus_data, #8
              or bus_data, cursor_lo
              wrlong bus_data, cursor_pos
              jmp #cog

:crtc_14
              and bus_data, #$07
              mov cursor_hi, bus_data
              jmp #:cursor

:crtc_10
              and bus_data, #$60
              wrlong bus_data, cursor_mode
              jmp #:cursor

:crtc_02
              cmp bus_data, #$50            wz
              if_e  mov bus_data, #1
              if_ne mov bus_data, #0
              wrlong bus_data, german_ptr
              jmp #cog

:crtc_12
              mov altfont_value, bus_data
              and altfont_value, #$10
              shr altfont_value, #4
              wrlong altfont_value, altfont_ptr
              jmp #cog

tpi_write
              test bus_data, #$10           wz
              if_z  mov bus_data, #0
              if_nz mov bus_data, #1
              wrlong bus_data, graph_ptr
              jmp #cog

cbm_screen    long 0
port_value    long $00000000
port_mask     long $80000000
addr_mask     long $0FFF

io_area       long $0800
crtc_regno    long $0800
crtc_regval   long $0801
tpi_port      long $0E06

cursor_pos    long 0
graph_ptr     long 0
mode_ptr      long 0
mode_value    long 0

german_ptr    long 0
altfont_ptr   long 0
altfont_value long 0

cursor_mode   long 0

bus_addr      res 1
bus_data      res 1

cbm_ptr       res 1

crtc_register res 1
cursor_lo     res 1
cursor_hi     res 1