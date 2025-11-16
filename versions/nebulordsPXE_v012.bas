  ;***************************************************************
  ;  NEBULORDS PXE - Version 012
  ;  Warlords-style Space Combat with Paddle Controls
  ; 
  ;  Changes from v011:
  ;  - Tweaked sprite visuals. Exactly double the height of original nebulords
  ;  - Thickened top and bottom border PXE uses 8 vertical lines per playfield block to 
  ;    equal roughly 1 block width horizontally.
  ;  - Changed start positions to visually be in the corners of the screen
  ;  - Added cool gradient colors for sprites similar to background: 
  ;    Repeated blue/cyan for player 1 and purple/violet gradient for player 2
  ; 
  ;  Changes from v010:
  ;  - DOUBLED all Y velocities to compensate for PXE's taller screen
  ;    (PXE uses 176 lines vs standard kernel's ~88 lines)
  ;  - Added NUSIZ sprite doubling (NUSIZ0/1 = $05) for double-width sprites
  ;  - Expanded sprite graphics from 13 to 24 lines (stretched vertically)
  ;  - Sprites now match size/movement feel of original Nebulords
  ;
  ;  Technical details:
  ;  - PXE's 176-line playfield is 2x taller than standard kernel
  ;  - Same velocity values appeared half as fast vertically
  ;  - Solution: Double all Y velocities (1→2, 2→4, 254→252, 255→254)
  ;
  ;  Controls:
  ;  - Paddle 0/1: Direction (16 positions)
  ;  - Paddle 0 button (joy0right): Hold to move Player 1
  ;  - Paddle 1 button (joy0left): Hold to move Player 2
  ;***************************************************************

  ;***************************************************************
  ;  PXE Kernel Setup
  ;***************************************************************
  set kernel PXE

  ; Set Playfield to full 40 pixel width
  PF_MODE = $fd

  ; Each line of data draws one line on screen
  PF_FRAC_INC = 0

  ; Configure paddle reading for 17 divisions
  PaddleRange0 = 136
  PaddleRange1 = 136

  ;***************************************************************
  ;  Constants
  ;***************************************************************
  const MOVE_SPEED = 1           ; Pixels per frame constant velocity

  ;***************************************************************
  ;  Variable declarations
  ;***************************************************************
  ; Player 1 (Paddle 0)
  dim p1_xpos = a
  dim p1_ypos = b
  dim p1_direction = c
  dim p1_xvel = d
  dim p1_yvel = e

  ; Player 2 (Paddle 1)
  dim p2_xpos = f
  dim p2_ypos = g
  dim p2_direction = h
  dim p2_xvel = i
  dim p2_yvel = j

  ; Temp variables
  dim temp_paddle = k
  dim temp_dir = l

  ; Ball
  dim ball_xvel = m
  dim ball_yvel = n

  ;***************************************************************
  ;  Initialize game
  ;***************************************************************
__Game_Init
  COLUBK = $00
  COLUPF = $0E
  
  ballheight = 1

  ; Enable double-width sprites (like original Nebulords v051)
  ; PXE uses virtual sprites: NUSIZ0 for player0, _NUSIZ1 for player1
  NUSIZ0 = $05
  _NUSIZ1 = $05

  p1_xpos = 25 : p1_ypos = 35
  p2_xpos = 135 : p2_ypos = 35

  p1_direction = 12
  p2_direction = 4

  p1_xvel = 0 : p1_yvel = 0
  p2_xvel = 0 : p2_yvel = 0

  ballx = 80 : bally = 88
  ballheight = 4

  temp_dir = (rand & 15)
  gosub __Set_Ball_Velocity

  gosub __Setup_Playfield

  ;***************************************************************
  ;  Define ship sprites - Simple blocky design stretched to 24 lines
  ;  (Same design as v010, just taller to match PXE proportions)
  ;***************************************************************
  player0:
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000011
  %11000011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011
  %11000011
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end

  player0color:
  $90
  $92
  $94
  $96
  $98
  $9a
  $9c
  $9e
  $90
  $92
  $94
  $96
  $98
  $9a
  $9c
  $9e
  $90
  $92
  $94
  $96
  $98
  $9a
  $9c
  $9e
  $90
  $92
end

  player1:
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000011
  %11000011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011
  %11000011
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end

  player1color:
  $70
  $72
  $74
  $76
  $78
  $7a
  $7c
  $7e
  $70
  $72
  $74
  $76
  $78
  $7a
  $7c
  $7e
  $70
  $72
  $74
  $76
  $78
  $7a
  $7c
  $7e
  $70
  $72
end


  ;***************************************************************
  ;  MAIN LOOP
  ;***************************************************************
__Main_Loop

  ;***************************************************************
  ;  Read Paddle 0 for Player 1 direction
  ;***************************************************************
  temp_paddle = Paddle0
  p1_direction = temp_paddle / 8
  if p1_direction >= 16 then p1_direction = 0
  temp_dir = p1_direction
  gosub __Set_P1_Velocity

  ;***************************************************************
  ;  Read Paddle 1 for Player 2 direction
  ;***************************************************************
  temp_paddle = Paddle1
  p2_direction = temp_paddle / 8
  if p2_direction >= 16 then p2_direction = 0
  temp_dir = p2_direction
  gosub __Set_P2_Velocity

  ;***************************************************************
  ;  Apply movement ONLY if paddle button is held
  ;  Using CORRECT paddle button syntax!
  ;***************************************************************
  ; Player 1: Paddle 0 button is joy0right
  if joy0right then p1_xpos = p1_xpos + p1_xvel : p1_ypos = p1_ypos + p1_yvel

  ; Player 2: Paddle 1 button is joy0left
  if joy0left then p2_xpos = p2_xpos + p2_xvel : p2_ypos = p2_ypos + p2_yvel

  ;***************************************************************
  ;  Boundary checking for Players
  ;***************************************************************
  if p1_xpos < 8 then p1_xpos = 8
  if p1_xpos > 150 then p1_xpos = 150
  if p1_ypos < 10 then p1_ypos = 10
  if p1_ypos > 160 then p1_ypos = 160

  if p2_xpos < 8 then p2_xpos = 8
  if p2_xpos > 150 then p2_xpos = 150
  if p2_ypos < 10 then p2_ypos = 10
  if p2_ypos > 160 then p2_ypos = 160

  ;***************************************************************
  ;  Ball physics - DOUBLED Y velocities to match X velocities
  ;***************************************************************
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel

  if ballx < 8 then ballx = 8 : ball_xvel = 0 - ball_xvel
  if ballx > 152 then ballx = 152 : ball_xvel = 0 - ball_xvel
  if bally < 10 then bally = 10 : ball_yvel = 0 - ball_yvel
  if bally > 162 then bally = 162 : ball_yvel = 0 - ball_yvel

  ;***************************************************************
  ;  Update sprite positions
  ;***************************************************************
  player0x = p1_xpos
  player0y = p1_ypos
  player1x = p2_xpos
  player1y = p2_ypos

  drawscreen
  goto __Main_Loop


  ;***************************************************************
  ;  SUBROUTINES - Y velocities DOUBLED for PXE's taller screen
  ;***************************************************************
__Set_P1_Velocity
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __P1V_0 __P1V_1 __P1V_2 __P1V_3 __P1V_4 __P1V_5 __P1V_6 __P1V_7 __P1V_8 __P1V_9 __P1V_10 __P1V_11 __P1V_12 __P1V_13 __P1V_14 __P1V_15

__P1V_0
  p1_xvel = 0 : p1_yvel = 254 : return
__P1V_1
  p1_xvel = 1 : p1_yvel = 252 : return
__P1V_2
  p1_xvel = 1 : p1_yvel = 254 : return
__P1V_3
  p1_xvel = 2 : p1_yvel = 254 : return
__P1V_4
  p1_xvel = 1 : p1_yvel = 0 : return
__P1V_5
  p1_xvel = 2 : p1_yvel = 2 : return
__P1V_6
  p1_xvel = 1 : p1_yvel = 2 : return
__P1V_7
  p1_xvel = 1 : p1_yvel = 4 : return
__P1V_8
  p1_xvel = 0 : p1_yvel = 2 : return
__P1V_9
  p1_xvel = 255 : p1_yvel = 4 : return
__P1V_10
  p1_xvel = 255 : p1_yvel = 2 : return
__P1V_11
  p1_xvel = 254 : p1_yvel = 2 : return
__P1V_12
  p1_xvel = 255 : p1_yvel = 0 : return
__P1V_13
  p1_xvel = 254 : p1_yvel = 254 : return
__P1V_14
  p1_xvel = 255 : p1_yvel = 254 : return
__P1V_15
  p1_xvel = 255 : p1_yvel = 252 : return

__Set_P2_Velocity
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __P2V_0 __P2V_1 __P2V_2 __P2V_3 __P2V_4 __P2V_5 __P2V_6 __P2V_7 __P2V_8 __P2V_9 __P2V_10 __P2V_11 __P2V_12 __P2V_13 __P2V_14 __P2V_15

__P2V_0
  p2_xvel = 0 : p2_yvel = 254 : return
__P2V_1
  p2_xvel = 1 : p2_yvel = 252 : return
__P2V_2
  p2_xvel = 1 : p2_yvel = 254 : return
__P2V_3
  p2_xvel = 2 : p2_yvel = 254 : return
__P2V_4
  p2_xvel = 1 : p2_yvel = 0 : return
__P2V_5
  p2_xvel = 2 : p2_yvel = 2 : return
__P2V_6
  p2_xvel = 1 : p2_yvel = 2 : return
__P2V_7
  p2_xvel = 1 : p2_yvel = 4 : return
__P2V_8
  p2_xvel = 0 : p2_yvel = 2 : return
__P2V_9
  p2_xvel = 255 : p2_yvel = 4 : return
__P2V_10
  p2_xvel = 255 : p2_yvel = 2 : return
__P2V_11
  p2_xvel = 254 : p2_yvel = 2 : return
__P2V_12
  p2_xvel = 255 : p2_yvel = 0 : return
__P2V_13
  p2_xvel = 254 : p2_yvel = 254 : return
__P2V_14
  p2_xvel = 255 : p2_yvel = 254 : return
__P2V_15
  p2_xvel = 255 : p2_yvel = 252 : return

__Set_Ball_Velocity
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __BV_0 __BV_1 __BV_2 __BV_3 __BV_4 __BV_5 __BV_6 __BV_7 __BV_8 __BV_9 __BV_10 __BV_11 __BV_12 __BV_13 __BV_14 __BV_15

__BV_0
  ball_xvel = 0 : ball_yvel = 254 : return
__BV_1
  ball_xvel = 1 : ball_yvel = 252 : return
__BV_2
  ball_xvel = 1 : ball_yvel = 254 : return
__BV_3
  ball_xvel = 2 : ball_yvel = 254 : return
__BV_4
  ball_xvel = 1 : ball_yvel = 0 : return
__BV_5
  ball_xvel = 2 : ball_yvel = 2 : return
__BV_6
  ball_xvel = 1 : ball_yvel = 2 : return
__BV_7
  ball_xvel = 1 : ball_yvel = 4 : return
__BV_8
  ball_xvel = 0 : ball_yvel = 2 : return
__BV_9
  ball_xvel = 255 : ball_yvel = 4 : return
__BV_10
  ball_xvel = 255 : ball_yvel = 2 : return
__BV_11
  ball_xvel = 254 : ball_yvel = 2 : return
__BV_12
  ball_xvel = 255 : ball_yvel = 0 : return
__BV_13
  ball_xvel = 254 : ball_yvel = 254 : return
__BV_14
  ball_xvel = 255 : ball_yvel = 254 : return
__BV_15
  ball_xvel = 255 : ball_yvel = 252 : return


  ;***************************************************************
  ;  Setup Playfield - 3 row borders like v005
  ;***************************************************************
__Setup_Playfield
  playfield:
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  X......................................X
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end

  ; Rainbow cycling playfield colors (one per line)
  pfcolors:
  $10
  $12
  $14
  $16
  $18
  $1a
  $1c
  $1e
  $20
  $22
  $24
  $26
  $28
  $2a
  $2c
  $2e
  $30
  $32
  $34
  $36
  $38
  $3a
  $3c
  $3e
  $40
  $42
  $44
  $46
  $48
  $4a
  $4c
  $4e
  $50
  $52
  $54
  $56
  $58
  $5a
  $5c
  $5e
  $60
  $62
  $64
  $66
  $68
  $6a
  $6c
  $6e
  $70
  $72
  $74
  $76
  $78
  $7a
  $7c
  $7e
  $80
  $82
  $84
  $86
  $88
  $8a
  $8c
  $8e
  $90
  $92
  $94
  $96
  $98
  $9a
  $9c
  $9e
  $a0
  $a2
  $a4
  $a6
  $a8
  $aa
  $ac
  $ae
  $b0
  $b2
  $b4
  $b6
  $b8
  $ba
  $bc
  $be
  $c0
  $c2
  $c4
  $c6
  $c8
  $ca
  $cc
  $ce
  $d0
  $d2
  $d4
  $d6
  $d8
  $da
  $dc
  $de
  $e0
  $e2
  $e4
  $e6
  $e8
  $ea
  $ec
  $ee
  $f0
  $f2
  $f4
  $f6
  $f8
  $fa
  $fc
  $fe
  $10
  $12
  $14
  $16
  $18
  $1a
  $1c
  $1e
  $20
  $22
  $24
  $26
  $28
  $2a
  $2c
  $2e
  $30
  $32
  $34
  $36
  $38
  $3a
  $3c
  $3e
  $40
  $42
  $44
  $46
  $48
  $4a
  $4c
  $4e
  $50
  $52
  $54
  $56
  $58
  $5a
  $5c
  $5e
  $60
  $62
  $64
  $66
  $68
  $6a
  $6c
  $6e
  $70
  $72
  $74
  $76
  $78
  $7a
  $7c
  $7e
end
  return
