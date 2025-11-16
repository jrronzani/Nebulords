  ;***************************************************************
  ;  NEBULORDS PXE - Version 015
  ;  Warlords-style Space Combat with Paddle Controls
  ;
  ;  Changes from v014:
  ;  - Added rotating paddle sprites using player2/player3
  ;  - Created 7 rotation frames for paddle bar (8px wide × 4-8px tall)
  ;  - Implemented 16-direction paddle positioning lookup table
  ;  - Doubled Y offsets from v051 to match PXE's 176-line screen
  ;  - Paddles now rotate around ship perimeter based on direction
  ;
  ;  Technical details:
  ;  - Paddle sprites use player2 (P1) and player3 (P2)
  ;  - 16 paddle positions around ship center
  ;  - Y offsets doubled from standard kernel version
  ;  - X offsets interpolated for 16-direction support
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
  dim paddle_frame = var_m  ; Which rotation frame to use

  ; Ball
  dim ball_xvel = n
  dim ball_yvel = o

  ;***************************************************************
  ;  Initialize game
  ;***************************************************************
__Game_Init
  COLUBK = $00
  COLUPF = $0E

  ballheight = 1

  ; Enable double-width sprites for ships
  NUSIZ0 = $05
  _NUSIZ1 = $05

  ; Single-width for paddles
  NUSIZ2 = $00
  NUSIZ3 = $00

  p1_xpos = 25 : p1_ypos = 35
  p2_xpos = 117 : p2_ypos = 35

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
  ;  Define ship sprites - 26 scanlines tall, blocky design
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
  ;  Paddle sprites - 7 rotation frames
  ;  Frame 0: Horizontal (E/W)
  ;  Frame 1: Slight diagonal (22.5°)
  ;  Frame 2: Diagonal (45°)
  ;  Frame 3: Steep (67.5°)
  ;  Frame 4: Vertical (N/S)
  ;  Frames 5-6: Mirrored versions of 3-1
  ;***************************************************************

  ; Frame 0: Horizontal bar (8 wide × 4 tall)
  player2_0:
  %11111111
  %11111111
  %11111111
  %11111111
end

  ; Frame 1: 22.5° angle
  player2_1:
  %01111111
  %01111111
  %11111110
  %11111110
  %11111100
end

  ; Frame 2: 45° diagonal
  player2_2:
  %00011111
  %00111111
  %01111110
  %01111110
  %11111100
  %11111000
end

  ; Frame 3: 67.5° steep
  player2_3:
  %00001111
  %00011111
  %00111110
  %00111110
  %01111100
  %01111000
  %11110000
  %11110000
end

  ; Frame 4: Vertical bar
  player2_4:
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end

  ; Frame 5: 112.5° (mirror of frame 3)
  player2_5:
  %11110000
  %11111000
  %01111100
  %01111100
  %00111110
  %00111110
  %00011111
  %00001111
end

  ; Frame 6: 135° (mirror of frame 2)
  player2_6:
  %11111000
  %11111100
  %01111110
  %01111110
  %00111111
  %00011111
end

  ; Colors for paddles
  player2color:
  $9e
  $9e
  $9e
  $9e
  $9e
  $9e
  $9e
  $9e
end

  player3color:
  $7e
  $7e
  $7e
  $7e
  $7e
  $7e
  $7e
  $7e
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
  ;***************************************************************
  ; Player 1: Paddle 0 button is joy0right
  if joy0right then p1_xpos = p1_xpos + p1_xvel : p1_ypos = p1_ypos + p1_yvel

  ; Player 2: Paddle 1 button is joy0left
  if joy0left then p2_xpos = p2_xpos + p2_xvel : p2_ypos = p2_ypos + p2_yvel

  ;***************************************************************
  ;  Boundary checking for Players
  ;***************************************************************
  if p1_xpos < 3 then p1_xpos = 3
  if p1_xpos > 139 then p1_xpos = 139
  if p1_ypos < 8 then p1_ypos = 8
  if p1_ypos > 135 then p1_ypos = 135

  if p2_xpos < 3 then p2_xpos = 3
  if p2_xpos > 139 then p2_xpos = 139
  if p2_ypos < 8 then p2_ypos = 8
  if p2_ypos > 135 then p2_ypos = 135

  ;***************************************************************
  ;  Ball physics
  ;***************************************************************
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel

  if ballx < 4 then ballx = 4 : ball_xvel = 0 - ball_xvel
  if ballx > 155 then ballx = 155 : ball_xvel = 0 - ball_xvel
  if bally < 8 then bally = 8 : ball_yvel = 0 - ball_yvel
  if bally > 157 then bally = 157 : ball_yvel = 0 - ball_yvel

  ;***************************************************************
  ;  Update paddle positions based on direction
  ;***************************************************************
  temp_dir = p1_direction
  gosub __Update_P1_Paddle

  temp_dir = p2_direction
  gosub __Update_P2_Paddle

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
  ;  SUBROUTINES - Y velocities DOUBLED for PXE
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
  ;  Update Player 1 Paddle Position
  ;  temp_dir contains current direction (0-15)
  ;  Positions paddle around ship perimeter with proper rotation
  ;***************************************************************
__Update_P1_Paddle
  on temp_dir goto __P1P_0 __P1P_1 __P1P_2 __P1P_3 __P1P_4 __P1P_5 __P1P_6 __P1P_7 __P1P_8 __P1P_9 __P1P_10 __P1P_11 __P1P_12 __P1P_13 __P1P_14 __P1P_15

; Direction 0: North (top)
__P1P_0
  player2x = p1_xpos + 6
  player2y = p1_ypos - 28
  player2pointer = player2_4  ; Vertical frame
  return

; Direction 1: NNE
__P1P_1
  player2x = p1_xpos + 9
  player2y = p1_ypos - 25
  player2pointer = player2_3  ; Steep frame
  return

; Direction 2: NE
__P1P_2
  player2x = p1_xpos + 13
  player2y = p1_ypos - 22
  player2pointer = player2_2  ; 45° frame
  return

; Direction 3: ENE
__P1P_3
  player2x = p1_xpos + 15
  player2y = p1_ypos - 15
  player2pointer = player2_1  ; Slight angle frame
  return

; Direction 4: East (right)
__P1P_4
  player2x = p1_xpos + 17
  player2y = p1_ypos - 8
  player2pointer = player2_0  ; Horizontal frame
  return

; Direction 5: ESE
__P1P_5
  player2x = p1_xpos + 15
  player2y = p1_ypos - 1
  player2pointer = player2_1  ; Slight angle (flipped)
  return

; Direction 6: SE
__P1P_6
  player2x = p1_xpos + 13
  player2y = p1_ypos + 6
  player2pointer = player2_6  ; 135° frame
  return

; Direction 7: SSE
__P1P_7
  player2x = p1_xpos + 9
  player2y = p1_ypos + 8
  player2pointer = player2_5  ; Steep (mirrored)
  return

; Direction 8: South (bottom)
__P1P_8
  player2x = p1_xpos + 6
  player2y = p1_ypos + 10
  player2pointer = player2_4  ; Vertical frame
  return

; Direction 9: SSW
__P1P_9
  player2x = p1_xpos + 2
  player2y = p1_ypos + 8
  player2pointer = player2_5  ; Steep (mirrored)
  return

; Direction 10: SW
__P1P_10
  player2x = p1_xpos - 1
  player2y = p1_ypos + 6
  player2pointer = player2_6  ; 135° frame
  return

; Direction 11: WSW
__P1P_11
  player2x = p1_xpos - 3
  player2y = p1_ypos - 1
  player2pointer = player2_1  ; Slight angle
  return

; Direction 12: West (left)
__P1P_12
  player2x = p1_xpos - 5
  player2y = p1_ypos - 8
  player2pointer = player2_0  ; Horizontal frame
  return

; Direction 13: WNW
__P1P_13
  player2x = p1_xpos - 3
  player2y = p1_ypos - 15
  player2pointer = player2_1  ; Slight angle
  return

; Direction 14: NW
__P1P_14
  player2x = p1_xpos - 1
  player2y = p1_ypos - 22
  player2pointer = player2_2  ; 45° frame
  return

; Direction 15: NNW
__P1P_15
  player2x = p1_xpos + 2
  player2y = p1_ypos - 25
  player2pointer = player2_3  ; Steep frame
  return


  ;***************************************************************
  ;  Update Player 2 Paddle Position
  ;  temp_dir contains current direction (0-15)
  ;***************************************************************
__Update_P2_Paddle
  on temp_dir goto __P2P_0 __P2P_1 __P2P_2 __P2P_3 __P2P_4 __P2P_5 __P2P_6 __P2P_7 __P2P_8 __P2P_9 __P2P_10 __P2P_11 __P2P_12 __P2P_13 __P2P_14 __P2P_15

; Direction 0: North
__P2P_0
  player3x = p2_xpos + 6
  player3y = p2_ypos - 28
  player3pointer = player2_4
  return

; Direction 1: NNE
__P2P_1
  player3x = p2_xpos + 9
  player3y = p2_ypos - 25
  player3pointer = player2_3
  return

; Direction 2: NE
__P2P_2
  player3x = p2_xpos + 13
  player3y = p2_ypos - 22
  player3pointer = player2_2
  return

; Direction 3: ENE
__P2P_3
  player3x = p2_xpos + 15
  player3y = p2_ypos - 15
  player3pointer = player2_1
  return

; Direction 4: East
__P2P_4
  player3x = p2_xpos + 17
  player3y = p2_ypos - 8
  player3pointer = player2_0
  return

; Direction 5: ESE
__P2P_5
  player3x = p2_xpos + 15
  player3y = p2_ypos - 1
  player3pointer = player2_1
  return

; Direction 6: SE
__P2P_6
  player3x = p2_xpos + 13
  player3y = p2_ypos + 6
  player3pointer = player2_6
  return

; Direction 7: SSE
__P2P_7
  player3x = p2_xpos + 9
  player3y = p2_ypos + 8
  player3pointer = player2_5
  return

; Direction 8: South
__P2P_8
  player3x = p2_xpos + 6
  player3y = p2_ypos + 10
  player3pointer = player2_4
  return

; Direction 9: SSW
__P2P_9
  player3x = p2_xpos + 2
  player3y = p2_ypos + 8
  player3pointer = player2_5
  return

; Direction 10: SW
__P2P_10
  player3x = p2_xpos - 1
  player3y = p2_ypos + 6
  player3pointer = player2_6
  return

; Direction 11: WSW
__P2P_11
  player3x = p2_xpos - 3
  player3y = p2_ypos - 1
  player3pointer = player2_1
  return

; Direction 12: West
__P2P_12
  player3x = p2_xpos - 5
  player3y = p2_ypos - 8
  player3pointer = player2_0
  return

; Direction 13: WNW
__P2P_13
  player3x = p2_xpos - 3
  player3y = p2_ypos - 15
  player3pointer = player2_1
  return

; Direction 14: NW
__P2P_14
  player3x = p2_xpos - 1
  player3y = p2_ypos - 22
  player3pointer = player2_2
  return

; Direction 15: NNW
__P2P_15
  player3x = p2_xpos + 2
  player3y = p2_ypos - 25
  player3pointer = player2_3
  return


  ;***************************************************************
  ;  Setup Playfield - 8 row borders
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
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end

  ; Rainbow cycling playfield colors
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
