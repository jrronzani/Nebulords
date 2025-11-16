  ;***************************************************************
  ;  NEBULORDS PXE - Version 015
  ;  Warlords-style Space Combat with Paddle Controls
  ;
  ;  Changes from v014:
  ;  - Added rotating paddle sprites using player2/player3
  ;  - Created 7 rotation frames for paddle bar
  ;  - Implemented 16-direction paddle positioning lookup table
  ;  - Paddles rotate around ship perimeter based on direction
  ;  - Fixed: Direction mapping (0=South, 8=North matches paddle dial)
  ;  - Fixed: Sprite orientation (horizontal bar for N/S, vertical for E/W)
  ;  - Fixed: Vertical positioning (adjusted Y offsets for proper placement)
  ;
  ;  Technical details:
  ;  - Paddle sprites use player2 (P1) and player3 (P2)
  ;  - 16 paddle positions: 0=S, 4=W, 8=N, 12=E
  ;  - Horizontal bar (8px wide) for North/South positions
  ;  - Vertical bar (8 scanlines tall) for East/West positions
  ;  - Diagonal bars for intermediate directions
  ;  - Sprite data defined inline per direction (batari Basic requirement)
  ;
  ;  Controls:
  ;  - Paddle 0/1: Direction (16 positions, 0=South bottom of dial)
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

  ; Paddle colors
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
  ;  Paddle dial: 0=South(bottom), 4=West, 8=North(top), 12=East
  ;  Sprites: Horizontal bar for N/S, Vertical bar for E/W
  ;***************************************************************
__Update_P1_Paddle
  on temp_dir goto __P1P_0 __P1P_1 __P1P_2 __P1P_3 __P1P_4 __P1P_5 __P1P_6 __P1P_7 __P1P_8 __P1P_9 __P1P_10 __P1P_11 __P1P_12 __P1P_13 __P1P_14 __P1P_15

; Direction 0: South (bottom) - HORIZONTAL BAR
__P1P_0
  player2:
  %011110
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %011110
end
  player2x = p1_xpos + 4 : player2y = p1_ypos + 28
  return

; Direction 1: SSW
__P1P_1
  player2:
  %11110000
  %11110000
  %01111000
  %01111100
  %00111110
  %00111110
  %00011111
  %00001111
end
  player2x = p1_xpos + 0 : player2y = p1_ypos + 18
  return

; Direction 2: SW (135°)
__P1P_2
  player2:
  %11111000
  %11111100
  %01111110
  %01111110
  %00111111
  %00011111
end
  player2x = p1_xpos - 3 : player2y = p1_ypos + 12
  return

; Direction 3: WSW
__P1P_3
  player2:
  %11111100
  %11111110
  %11111110
  %01111111
  %01111111
end
  player2x = p1_xpos - 5 : player2y = p1_ypos + 6
  return

; Direction 4: West (left) - VERTICAL BAR
__P1P_4
  player2:
  %011110
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %011110

end
  player2x = p1_xpos - 8 : player2y = p1_ypos + 8
  return

; Direction 5: WNW
__P1P_5
  player2:
  %01111111
  %01111111
  %11111110
  %11111110
  %11111100
end
  player2x = p1_xpos - 5 : player2y = p1_ypos - 6
  return

; Direction 6: NW (45°)
__P1P_6
  player2:
  %00011111
  %00111111
  %01111110
  %01111110
  %11111100
  %11111000
end
  player2x = p1_xpos - 3 : player2y = p1_ypos - 12
  return

; Direction 7: NNW
__P1P_7
  player2:
  %00001111
  %00011111
  %00111110
  %00111110
  %01111100
  %01111000
  %11110000
  %11110000
end
  player2x = p1_xpos + 0 : player2y = p1_ypos - 18
  return

; Direction 8: North (top) - HORIZONTAL BAR
__P1P_8
  player2:
  %011110
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %011110
end
  player2x = p1_xpos + 4 : player2y = p1_ypos - 11
  return

; Direction 9: NNE
__P1P_9
  player2:
  %00001111
  %00011111
  %00111110
  %00111110
  %01111100
  %01111000
  %11110000
  %11110000
end
  player2x = p1_xpos + 8 : player2y = p1_ypos - 18
  return

; Direction 10: NE (45°)
__P1P_10
  player2:
  %00011111
  %00111111
  %01111110
  %01111110
  %11111100
  %11111000
end
  player2x = p1_xpos + 11 : player2y = p1_ypos - 12
  return

; Direction 11: ENE
__P1P_11
  player2:
  %01111111
  %01111111
  %11111110
  %11111110
  %11111100
end
  player2x = p1_xpos + 13 : player2y = p1_ypos - 6
  return

; Direction 12: East (right) - VERTICAL BAR
__P1P_12
  player2:
  %011110
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %011110
end
  player2x = p1_xpos + 16 : player2y = p1_ypos + 8
  return

; Direction 13: ESE
__P1P_13
  player2:
  %11111100
  %11111110
  %11111110
  %01111111
  %01111111
end
  player2x = p1_xpos + 13 : player2y = p1_ypos + 6
  return

; Direction 14: SE (135°)
__P1P_14
  player2:
  %11111000
  %11111100
  %01111110
  %01111110
  %00111111
  %00011111
end
  player2x = p1_xpos + 11 : player2y = p1_ypos + 12
  return

; Direction 15: SSE
__P1P_15
  player2:
  %11110000
  %11110000
  %01111000
  %01111100
  %00111110
  %00111110
  %00011111
  %00001111
end
  player2x = p1_xpos + 8 : player2y = p1_ypos + 18
  return


  ;***************************************************************
  ;  Update Player 2 Paddle Position
  ;  temp_dir contains current direction (0-15)
  ;  Paddle dial: 0=South(bottom), 4=West, 8=North(top), 12=East
  ;***************************************************************
__Update_P2_Paddle
  on temp_dir goto __P2P_0 __P2P_1 __P2P_2 __P2P_3 __P2P_4 __P2P_5 __P2P_6 __P2P_7 __P2P_8 __P2P_9 __P2P_10 __P2P_11 __P2P_12 __P2P_13 __P2P_14 __P2P_15

; Direction 0: South (bottom) - HORIZONTAL BAR
__P2P_0
  player3:
  %11111111
  %11111111
  %11111111
  %11111111
end
  player3x = p2_xpos + 4 : player3y = p2_ypos + 22
  return

; Direction 1: SSW
__P2P_1
  player3:
  %11110000
  %11110000
  %01111000
  %01111100
  %00111110
  %00111110
  %00011111
  %00001111
end
  player3x = p2_xpos + 0 : player3y = p2_ypos + 18
  return

; Direction 2: SW (135°)
__P2P_2
  player3:
  %11111000
  %11111100
  %01111110
  %01111110
  %00111111
  %00011111
end
  player3x = p2_xpos - 3 : player3y = p2_ypos + 12
  return

; Direction 3: WSW
__P2P_3
  player3:
  %11111100
  %11111110
  %11111110
  %01111111
  %01111111
end
  player3x = p2_xpos - 5 : player3y = p2_ypos + 6
  return

; Direction 4: West (left) - VERTICAL BAR
__P2P_4
  player3:
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  player3x = p2_xpos - 8 : player3y = p2_ypos + 0
  return

; Direction 5: WNW
__P2P_5
  player3:
  %01111111
  %01111111
  %11111110
  %11111110
  %11111100
end
  player3x = p2_xpos - 5 : player3y = p2_ypos - 6
  return

; Direction 6: NW (45°)
__P2P_6
  player3:
  %00011111
  %00111111
  %01111110
  %01111110
  %11111100
  %11111000
end
  player3x = p2_xpos - 3 : player3y = p2_ypos - 12
  return

; Direction 7: NNW
__P2P_7
  player3:
  %00001111
  %00011111
  %00111110
  %00111110
  %01111100
  %01111000
  %11110000
  %11110000
end
  player3x = p2_xpos + 0 : player3y = p2_ypos - 18
  return

; Direction 8: North (top) - HORIZONTAL BAR
__P2P_8
  player3:
  %11111111
  %11111111
  %11111111
  %11111111
end
  player3x = p2_xpos + 4 : player3y = p2_ypos - 22
  return

; Direction 9: NNE
__P2P_9
  player3:
  %00001111
  %00011111
  %00111110
  %00111110
  %01111100
  %01111000
  %11110000
  %11110000
end
  player3x = p2_xpos + 8 : player3y = p2_ypos - 18
  return

; Direction 10: NE (45°)
__P2P_10
  player3:
  %00011111
  %00111111
  %01111110
  %01111110
  %11111100
  %11111000
end
  player3x = p2_xpos + 11 : player3y = p2_ypos - 12
  return

; Direction 11: ENE
__P2P_11
  player3:
  %01111111
  %01111111
  %11111110
  %11111110
  %11111100
end
  player3x = p2_xpos + 13 : player3y = p2_ypos - 6
  return

; Direction 12: East (right) - VERTICAL BAR
__P2P_12
  player3:
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  player3x = p2_xpos + 16 : player3y = p2_ypos + 0
  return

; Direction 13: ESE
__P2P_13
  player3:
  %11111100
  %11111110
  %11111110
  %01111111
  %01111111
end
  player3x = p2_xpos + 13 : player3y = p2_ypos + 6
  return

; Direction 14: SE (135°)
__P2P_14
  player3:
  %11111000
  %11111100
  %01111110
  %01111110
  %00111111
  %00011111
end
  player3x = p2_xpos + 11 : player3y = p2_ypos + 12
  return

; Direction 15: SSE
__P2P_15
  player3:
  %11110000
  %11110000
  %01111000
  %01111100
  %00111110
  %00111110
  %00011111
  %00001111
end
  player3x = p2_xpos + 8 : player3y = p2_ypos + 18
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
