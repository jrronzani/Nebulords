  ;***************************************************************
  ;  NEBULORDS PXE - Version 005
  ;  Warlords-style Space Combat with Paddle Controls
  ;
  ;  Changes from v004:
  ;  - Fixed variable allocation (temp vars back to k,l slots)
  ;  - Added thicker playfield borders (3 rows top/bottom)
  ;  - Fixed player colors to be more distinct
  ;    P1=$AC (bright cyan), P2=$46 (bright purple/magenta)
  ;
  ;  Controls:
  ;  - Paddle 0/1: Direction (16 positions, both extremes = South)
  ;  - Paddle Button: Hold to move in paddle direction
  ;***************************************************************

  ;***************************************************************
  ;  PXE Kernel Setup
  ;***************************************************************
  set kernel PXE

  ; Set Playfield to full 40 pixel width
  ; Mode $fd: 40-pixel width, use PF_FRAC_INC for resolution
  PF_MODE = $fd

  ; Each line of data draws one line on screen (no fractional increment)
  PF_FRAC_INC = 0

  ; Configure paddle reading for 17 divisions (0-136 range)
  ; 136 = 17 × 8, giving positions 0-16 (with 16 wrapping to 0)
  PaddleRange0 = 136
  PaddleRange1 = 136

  ;***************************************************************
  ;  Constants
  ;***************************************************************
  const MOVE_SPEED = 1           ; Pixels per frame constant velocity
  const PADDLE_DIVISIONS = 16    ; 16-direction movement
  const BALL_SPEED = 1           ; Ball speed (pixels per frame)

  ;***************************************************************
  ;  Variable declarations
  ;***************************************************************
  ; Player 1 (Paddle 0)
  dim p1_xpos = a
  dim p1_ypos = b
  dim p1_direction = c           ; Current direction (0-15)
  dim p1_xvel = d                ; X velocity (-2 to +2)
  dim p1_yvel = e                ; Y velocity (-2 to +2)

  ; Player 2 (Paddle 1)
  dim p2_xpos = f
  dim p2_ypos = g
  dim p2_direction = h           ; Current direction (0-15)
  dim p2_xvel = i                ; X velocity (-2 to +2)
  dim p2_yvel = j                ; Y velocity (-2 to +2)

  ; Temp variables (KEEP THESE IN ORIGINAL SLOTS!)
  dim temp_paddle = k            ; Temp for paddle reading
  dim temp_dir = l               ; Temp for direction calculation

  ; Ball (moved to different slots)
  dim ball_xvel = m              ; Ball X velocity
  dim ball_yvel = n              ; Ball Y velocity

  ;***************************************************************
  ;  Initialize game
  ;***************************************************************
__Game_Init
  ; Set colors
  COLUBK = $00                   ; Black background
  COLUPF = $0E                   ; White playfield border (overridden by pfcolors)
  COLUP0 = $AC                   ; Bright cyan for Player 1
  COLUP1 = $46                   ; Bright purple/magenta for Player 2

  ; Starting positions (left and right sides, centered vertically)
  p1_xpos = 30 : p1_ypos = 60
  p2_xpos = 130 : p2_ypos = 60

  ; Initial directions (facing each other)
  ; 0=S, going clockwise: East is 12, West is 4
  p1_direction = 12              ; East (facing right)
  p2_direction = 4               ; West (facing left)

  ; Initialize velocities to zero (movement is button-activated)
  p1_xvel = 0 : p1_yvel = 0
  p2_xvel = 0 : p2_yvel = 0

  ; Initialize ball in center with random direction
  ballx = 80 : bally = 88
  ballheight = 1

  ; Random ball direction
  temp_dir = (rand & 15)
  gosub __Set_Ball_Velocity

  ; Draw the playfield and colors once
  gosub __Setup_Playfield

  ;***************************************************************
  ;  Define ship sprites (13 pixels tall, based on v051)
  ;***************************************************************
  player0:
  %00111100
  %00111100
  %00111100
  %11000011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011
  %00111100
  %00111100
  %00111100
end

  player1:
  %00111100
  %00111100
  %00111100
  %11000011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011
  %00111100
  %00111100
  %00111100
end


  ;***************************************************************
  ;  MAIN LOOP
  ;***************************************************************
__Main_Loop

  ;***************************************************************
  ;  Read Paddle 0 for Player 1 direction
  ;***************************************************************
  ; PXE kernel provides direct access to Paddle0 variable
  temp_paddle = Paddle0

  ; Convert paddle value (0-136) to direction (0-15)
  ; Divide by 8 to get 17 divisions (0-17), wrap 16+ to 0
  p1_direction = temp_paddle / 8
  if p1_direction >= 16 then p1_direction = 0

  ; Set P1 velocity based on direction
  temp_dir = p1_direction
  gosub __Set_P1_Velocity

  ;***************************************************************
  ;  Read Paddle 1 for Player 2 direction
  ;***************************************************************
  ; PXE kernel provides direct access to Paddle1 variable
  temp_paddle = Paddle1

  ; Convert paddle value (0-136) to direction (0-15)
  p2_direction = temp_paddle / 8
  if p2_direction >= 16 then p2_direction = 0

  ; Set P2 velocity based on direction
  temp_dir = p2_direction
  gosub __Set_P2_Velocity

  ;***************************************************************
  ;  Apply movement ONLY if paddle button is held
  ;***************************************************************
  ; Player 1: paddle button 0 is joy0fire in PXE
  if joy0fire then p1_xpos = p1_xpos + p1_xvel : p1_ypos = p1_ypos + p1_yvel

  ; Player 2: paddle button 1 is joy1fire in PXE
  if joy1fire then p2_xpos = p2_xpos + p2_xvel : p2_ypos = p2_ypos + p2_yvel

  ;***************************************************************
  ;  Boundary checking for Players
  ;***************************************************************
  ; Player 1
  if p1_xpos < 8 then p1_xpos = 8
  if p1_xpos > 150 then p1_xpos = 150
  if p1_ypos < 10 then p1_ypos = 10
  if p1_ypos > 160 then p1_ypos = 160

  ; Player 2
  if p2_xpos < 8 then p2_xpos = 8
  if p2_xpos > 150 then p2_xpos = 150
  if p2_ypos < 10 then p2_ypos = 10
  if p2_ypos > 160 then p2_ypos = 160

  ;***************************************************************
  ;  Ball physics
  ;***************************************************************
  ; Move ball
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel

  ; Ball boundary checking with bounce
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

  ;***************************************************************
  ;  Draw the screen and loop
  ;***************************************************************
  drawscreen
  goto __Main_Loop


  ;***************************************************************
  ;  SUBROUTINES
  ;***************************************************************

  ;***************************************************************
  ;  Set Player 1 velocity based on direction (0-15)
  ;  temp_dir contains direction
  ;  Uses constant velocity (MOVE_SPEED)
  ;
  ;  User Direction map (clockwise from South):
  ;  0=S, 1=SSW, 2=SW, 3=WSW, 4=W, 5=WNW, 6=NW, 7=NNW
  ;  8=N, 9=NNE, 10=NE, 11=ENE, 12=E, 13=ESE, 14=SE, 15=SSE
  ;***************************************************************
__Set_P1_Velocity
  ; Offset user direction by +8 to align with velocity table
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __P1V_0 __P1V_1 __P1V_2 __P1V_3 __P1V_4 __P1V_5 __P1V_6 __P1V_7 __P1V_8 __P1V_9 __P1V_10 __P1V_11 __P1V_12 __P1V_13 __P1V_14 __P1V_15

__P1V_0   ; North (0,-1)
  p1_xvel = 0 : p1_yvel = 255 : return
__P1V_1   ; NNE (1,-2)
  p1_xvel = 1 : p1_yvel = 254 : return
__P1V_2   ; NE (1,-1)
  p1_xvel = 1 : p1_yvel = 255 : return
__P1V_3   ; ENE (2,-1)
  p1_xvel = 2 : p1_yvel = 255 : return
__P1V_4   ; East (1,0)
  p1_xvel = 1 : p1_yvel = 0 : return
__P1V_5   ; ESE (2,1)
  p1_xvel = 2 : p1_yvel = 1 : return
__P1V_6   ; SE (1,1)
  p1_xvel = 1 : p1_yvel = 1 : return
__P1V_7   ; SSE (1,2)
  p1_xvel = 1 : p1_yvel = 2 : return
__P1V_8   ; South (0,1)
  p1_xvel = 0 : p1_yvel = 1 : return
__P1V_9   ; SSW (-1,2)
  p1_xvel = 255 : p1_yvel = 2 : return
__P1V_10  ; SW (-1,1)
  p1_xvel = 255 : p1_yvel = 1 : return
__P1V_11  ; WSW (-2,1)
  p1_xvel = 254 : p1_yvel = 1 : return
__P1V_12  ; West (-1,0)
  p1_xvel = 255 : p1_yvel = 0 : return
__P1V_13  ; WNW (-2,-1)
  p1_xvel = 254 : p1_yvel = 255 : return
__P1V_14  ; NW (-1,-1)
  p1_xvel = 255 : p1_yvel = 255 : return
__P1V_15  ; NNW (-1,-2)
  p1_xvel = 255 : p1_yvel = 254 : return

  ;***************************************************************
  ;  Set Player 2 velocity based on direction (0-15)
  ;***************************************************************
__Set_P2_Velocity
  ; Offset user direction by +8 to align with velocity table
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __P2V_0 __P2V_1 __P2V_2 __P2V_3 __P2V_4 __P2V_5 __P2V_6 __P2V_7 __P2V_8 __P2V_9 __P2V_10 __P2V_11 __P2V_12 __P2V_13 __P2V_14 __P2V_15

__P2V_0   ; North
  p2_xvel = 0 : p2_yvel = 255 : return
__P2V_1   ; NNE
  p2_xvel = 1 : p2_yvel = 254 : return
__P2V_2   ; NE
  p2_xvel = 1 : p2_yvel = 255 : return
__P2V_3   ; ENE
  p2_xvel = 2 : p2_yvel = 255 : return
__P2V_4   ; East
  p2_xvel = 1 : p2_yvel = 0 : return
__P2V_5   ; ESE
  p2_xvel = 2 : p2_yvel = 1 : return
__P2V_6   ; SE
  p2_xvel = 1 : p2_yvel = 1 : return
__P2V_7   ; SSE
  p2_xvel = 1 : p2_yvel = 2 : return
__P2V_8   ; South
  p2_xvel = 0 : p2_yvel = 1 : return
__P2V_9   ; SSW
  p2_xvel = 255 : p2_yvel = 2 : return
__P2V_10  ; SW
  p2_xvel = 255 : p2_yvel = 1 : return
__P2V_11  ; WSW
  p2_xvel = 254 : p2_yvel = 1 : return
__P2V_12  ; West
  p2_xvel = 255 : p2_yvel = 0 : return
__P2V_13  ; WNW
  p2_xvel = 254 : p2_yvel = 255 : return
__P2V_14  ; NW
  p2_xvel = 255 : p2_yvel = 255 : return
__P2V_15  ; NNW
  p2_xvel = 255 : p2_yvel = 254 : return

  ;***************************************************************
  ;  Set Ball velocity based on direction (0-15)
  ;  temp_dir contains direction
  ;***************************************************************
__Set_Ball_Velocity
  ; Offset by +8 to align with table (same as player velocities)
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __BV_0 __BV_1 __BV_2 __BV_3 __BV_4 __BV_5 __BV_6 __BV_7 __BV_8 __BV_9 __BV_10 __BV_11 __BV_12 __BV_13 __BV_14 __BV_15

__BV_0   ; North
  ball_xvel = 0 : ball_yvel = 255 : return
__BV_1   ; NNE
  ball_xvel = 1 : ball_yvel = 254 : return
__BV_2   ; NE
  ball_xvel = 1 : ball_yvel = 255 : return
__BV_3   ; ENE
  ball_xvel = 2 : ball_yvel = 255 : return
__BV_4   ; East
  ball_xvel = 1 : ball_yvel = 0 : return
__BV_5   ; ESE
  ball_xvel = 2 : ball_yvel = 1 : return
__BV_6   ; SE
  ball_xvel = 1 : ball_yvel = 1 : return
__BV_7   ; SSE
  ball_xvel = 1 : ball_yvel = 2 : return
__BV_8   ; South
  ball_xvel = 0 : ball_yvel = 1 : return
__BV_9   ; SSW
  ball_xvel = 255 : ball_yvel = 2 : return
__BV_10  ; SW
  ball_xvel = 255 : ball_yvel = 1 : return
__BV_11  ; WSW
  ball_xvel = 254 : ball_yvel = 1 : return
__BV_12  ; West
  ball_xvel = 255 : ball_yvel = 0 : return
__BV_13  ; WNW
  ball_xvel = 254 : ball_yvel = 255 : return
__BV_14  ; NW
  ball_xvel = 255 : ball_yvel = 255 : return
__BV_15  ; NNW
  ball_xvel = 255 : ball_yvel = 254 : return


  ;***************************************************************
  ;  Setup Playfield - Full 40-pixel width border (176 lines)
  ;  With thicker top/bottom borders and rainbow color cycling
  ;***************************************************************
__Setup_Playfield
  playfield:
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
