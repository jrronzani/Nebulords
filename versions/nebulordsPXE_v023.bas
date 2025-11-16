  ;***************************************************************
  ;  NEBULORDS PXE - Version 023
  ;  Warlords-style Space Combat with Paddle Controls
  ;
  ;  Changes from v021:
  ;  - Extended deceleration range for finer stopping control
  ;  - Start speed: 10 (same as v021)
  ;  - Stopping threshold: 20 (was 10) - more granular deceleration
  ;  - Acceleration speed: UNCHANGED from v021 (8 steps to max)
  ;  - Result: Snappy acceleration + precise deceleration
  ;
  ;  Physics System:
  ;  - speed_x/y: Frames between pixel moves (lower = faster)
  ;  - max_speed = 2: Top speed (moves every 2 frames)
  ;  - Start at speed 10, accelerate to 2 (8 steps)
  ;  - Decelerate from 2 up to 20 before stopping (18 steps)
  ;  - accel_delay = 3: Frames between acceleration steps
  ;  - dir_x/y: Movement direction (0=stopped, 1=positive, 255=negative)
  ;  - Button held: Thrust in current paddle direction
  ;  - Button released: Drift at current velocity
  ;  - Wall hit: Bounce (reverse direction)
  ;  - Tapping: More granular deceleration for micro-adjustments
  ;
  ;  Technical details:
  ;  - Paddle sprites use player2 (P1) and player3 (P2)
  ;  - 16 paddle positions: 0=S, 4=W, 8=N, 12=E
  ;  - Single 9-scanline rounded bar sprite for all directions
  ;  - Sprite data defined inline per direction (batari Basic requirement)
  ;
  ;  Controls:
  ;  - Paddle 0/1: Direction (16 positions, 0=South bottom of dial)
  ;  - Paddle 0 button (joy0right): Hold to thrust Player 1
  ;  - Paddle 1 button (joy0left): Hold to thrust Player 2
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
  ;  Physics Constants
  ;***************************************************************
  const max_speed = 2            ; Max speed (lower = faster, frames between moves)
  const accel_delay = 3          ; Frames between accel (higher = slower accel)

  ;***************************************************************
  ;  Variable declarations
  ;***************************************************************
  ; Player 1 (Paddle 0) - Physics
  dim p1_xpos = a
  dim p1_ypos = b
  dim p1_direction = c
  dim p1_speed_x = d             ; Frames between X moves (10=slow, max_speed=fast)
  dim p1_speed_y = e             ; Frames between Y moves
  dim p1_frame_x = m             ; Frame counter for X movement
  dim p1_frame_y = n             ; Frame counter for Y movement
  dim p1_dir_x = p               ; X direction: 0=none, 1=right, 255=left
  dim p1_dir_y = q               ; Y direction: 0=none, 1=down, 255=up

  ; Player 2 (Paddle 1) - Physics
  dim p2_xpos = f
  dim p2_ypos = g
  dim p2_direction = h
  dim p2_speed_x = i             ; Frames between X moves
  dim p2_speed_y = j             ; Frames between Y moves
  dim p2_frame_x = r             ; Frame counter for X movement
  dim p2_frame_y = s             ; Frame counter for Y movement
  dim p2_dir_x = t               ; X direction
  dim p2_dir_y = u               ; Y direction

  ; Shared
  dim accel_counter = v          ; Frame counter for acceleration delay

  ; Temp variables
  dim temp_paddle = k
  dim temp_dir = l

  ; Ball
  dim ball_xvel = w
  dim ball_yvel = x

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

  ; Initialize P1 physics - start stationary
  p1_speed_x = 10 : p1_speed_y = 10
  p1_frame_x = 10 : p1_frame_y = 10
  p1_dir_x = 0 : p1_dir_y = 0

  ; Initialize P2 physics - start stationary
  p2_speed_x = 10 : p2_speed_y = 10
  p2_frame_x = 10 : p2_frame_y = 10
  p2_dir_x = 0 : p2_dir_y = 0

  ; Acceleration counter
  accel_counter = 0

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

  ;***************************************************************
  ;  Read Paddle 1 for Player 2 direction
  ;***************************************************************
  temp_paddle = Paddle1
  p2_direction = temp_paddle / 8
  if p2_direction >= 16 then p2_direction = 0

  ;***************************************************************
  ;  Acceleration counter - only accelerate every N frames
  ;***************************************************************
  accel_counter = accel_counter + 1
  if accel_counter >= accel_delay then accel_counter = 0

  ;***************************************************************
  ;  Thrust Physics - Apply when button held
  ;***************************************************************
  ; Player 1: Paddle 0 button is joy0right
  if joy0right && accel_counter = 0 then temp_dir = p1_direction : gosub __P1_Thrust

  ; Player 2: Paddle 1 button is joy0left
  if joy0left && accel_counter = 0 then temp_dir = p2_direction : gosub __P2_Thrust

  ;***************************************************************
  ;  Apply frame-based movement (drift with momentum)
  ;***************************************************************
  gosub __P1_Apply_Movement
  gosub __P2_Apply_Movement

  ;***************************************************************
  ;  Wall Bounce for Players
  ;***************************************************************
  gosub __P1_Wall_Bounce
  gosub __P2_Wall_Bounce

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
  ;  THRUST PHYSICS SUBROUTINES
  ;***************************************************************

__P1_Thrust
  ; Apply thrust in direction temp_dir (0-15)
  ; Rotated by 8 to match paddle dial (0=South)
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __P1T_0 __P1T_1 __P1T_2 __P1T_3 __P1T_4 __P1T_5 __P1T_6 __P1T_7 __P1T_8 __P1T_9 __P1T_10 __P1T_11 __P1T_12 __P1T_13 __P1T_14 __P1T_15

; Direction 0: North (up)
__P1T_0
  gosub __P1_Accel_Up : return
; Direction 1: NNE
__P1T_1
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
; Direction 2: NE
__P1T_2
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
; Direction 3: ENE
__P1T_3
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
; Direction 4: East (right)
__P1T_4
  gosub __P1_Accel_Right : return
; Direction 5: ESE
__P1T_5
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
; Direction 6: SE
__P1T_6
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
; Direction 7: SSE
__P1T_7
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
; Direction 8: South (down)
__P1T_8
  gosub __P1_Accel_Down : return
; Direction 9: SSW
__P1T_9
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
; Direction 10: SW
__P1T_10
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
; Direction 11: WSW
__P1T_11
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
; Direction 12: West (left)
__P1T_12
  gosub __P1_Accel_Left : return
; Direction 13: WNW
__P1T_13
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
; Direction 14: NW
__P1T_14
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
; Direction 15: NNW
__P1T_15
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return


__P1_Accel_Right
  ; If moving left, decelerate
  if p1_dir_x = 255 then p1_speed_x = p1_speed_x + 1 : if p1_speed_x >= 20 then p1_dir_x = 0 : p1_speed_x = 20
  ; If stopped or moving right, accelerate right
  if p1_dir_x = 0 then p1_dir_x = 1
  if p1_dir_x = 1 then if p1_speed_x > max_speed then p1_speed_x = p1_speed_x - 1
  return

__P1_Accel_Left
  ; If moving right, decelerate
  if p1_dir_x = 1 then p1_speed_x = p1_speed_x + 1 : if p1_speed_x >= 20 then p1_dir_x = 0 : p1_speed_x = 20
  ; If stopped or moving left, accelerate left
  if p1_dir_x = 0 then p1_dir_x = 255
  if p1_dir_x = 255 then if p1_speed_x > max_speed then p1_speed_x = p1_speed_x - 1
  return

__P1_Accel_Up
  ; If moving down, decelerate
  if p1_dir_y = 1 then p1_speed_y = p1_speed_y + 1 : if p1_speed_y >= 20 then p1_dir_y = 0 : p1_speed_y = 20
  ; If stopped or moving up, accelerate up
  if p1_dir_y = 0 then p1_dir_y = 255
  if p1_dir_y = 255 then if p1_speed_y > max_speed then p1_speed_y = p1_speed_y - 1
  return

__P1_Accel_Down
  ; If moving up, decelerate
  if p1_dir_y = 255 then p1_speed_y = p1_speed_y + 1 : if p1_speed_y >= 20 then p1_dir_y = 0 : p1_speed_y = 20
  ; If stopped or moving down, accelerate down
  if p1_dir_y = 0 then p1_dir_y = 1
  if p1_dir_y = 1 then if p1_speed_y > max_speed then p1_speed_y = p1_speed_y - 1
  return


__P2_Thrust
  ; Apply thrust in direction temp_dir (0-15)
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __P2T_0 __P2T_1 __P2T_2 __P2T_3 __P2T_4 __P2T_5 __P2T_6 __P2T_7 __P2T_8 __P2T_9 __P2T_10 __P2T_11 __P2T_12 __P2T_13 __P2T_14 __P2T_15

__P2T_0
  gosub __P2_Accel_Up : return
__P2T_1
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_2
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_3
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_4
  gosub __P2_Accel_Right : return
__P2T_5
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_6
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_7
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_8
  gosub __P2_Accel_Down : return
__P2T_9
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_10
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_11
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_12
  gosub __P2_Accel_Left : return
__P2T_13
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_14
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_15
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return


__P2_Accel_Right
  if p2_dir_x = 255 then p2_speed_x = p2_speed_x + 1 : if p2_speed_x >= 20 then p2_dir_x = 0 : p2_speed_x = 20
  if p2_dir_x = 0 then p2_dir_x = 1
  if p2_dir_x = 1 then if p2_speed_x > max_speed then p2_speed_x = p2_speed_x - 1
  return

__P2_Accel_Left
  if p2_dir_x = 1 then p2_speed_x = p2_speed_x + 1 : if p2_speed_x >= 20 then p2_dir_x = 0 : p2_speed_x = 20
  if p2_dir_x = 0 then p2_dir_x = 255
  if p2_dir_x = 255 then if p2_speed_x > max_speed then p2_speed_x = p2_speed_x - 1
  return

__P2_Accel_Up
  if p2_dir_y = 1 then p2_speed_y = p2_speed_y + 1 : if p2_speed_y >= 20 then p2_dir_y = 0 : p2_speed_y = 20
  if p2_dir_y = 0 then p2_dir_y = 255
  if p2_dir_y = 255 then if p2_speed_y > max_speed then p2_speed_y = p2_speed_y - 1
  return

__P2_Accel_Down
  if p2_dir_y = 255 then p2_speed_y = p2_speed_y + 1 : if p2_speed_y >= 20 then p2_dir_y = 0 : p2_speed_y = 20
  if p2_dir_y = 0 then p2_dir_y = 1
  if p2_dir_y = 1 then if p2_speed_y > max_speed then p2_speed_y = p2_speed_y - 1
  return


__P1_Apply_Movement
  ; Apply X movement (frame-based velocity)
  if p1_dir_x <> 0 then p1_frame_x = p1_frame_x - 1
  if p1_frame_x = 0 then p1_xpos = p1_xpos + p1_dir_x : p1_frame_x = p1_speed_x

  ; Apply Y movement (frame-based velocity) - DOUBLED for PXE
  if p1_dir_y <> 0 then p1_frame_y = p1_frame_y - 1
  if p1_frame_y = 0 then p1_ypos = p1_ypos + p1_dir_y : p1_ypos = p1_ypos + p1_dir_y : p1_frame_y = p1_speed_y

  return


__P2_Apply_Movement
  ; Apply X movement
  if p2_dir_x <> 0 then p2_frame_x = p2_frame_x - 1
  if p2_frame_x = 0 then p2_xpos = p2_xpos + p2_dir_x : p2_frame_x = p2_speed_x

  ; Apply Y movement - DOUBLED for PXE
  if p2_dir_y <> 0 then p2_frame_y = p2_frame_y - 1
  if p2_frame_y = 0 then p2_ypos = p2_ypos + p2_dir_y : p2_ypos = p2_ypos + p2_dir_y : p2_frame_y = p2_speed_y

  return


__P1_Wall_Bounce
  ; Check left wall
  if p1_xpos < 3 then p1_dir_x = 1 : p1_xpos = 3 : p1_frame_x = p1_speed_x

  ; Check right wall
  if p1_xpos > 139 then p1_dir_x = 255 : p1_xpos = 139 : p1_frame_x = p1_speed_x

  ; Check top wall
  if p1_ypos < 8 then p1_dir_y = 1 : p1_ypos = 8 : p1_frame_y = p1_speed_y

  ; Check bottom wall
  if p1_ypos > 135 then p1_dir_y = 255 : p1_ypos = 135 : p1_frame_y = p1_speed_y

  return


__P2_Wall_Bounce
  ; Check left wall
  if p2_xpos < 3 then p2_dir_x = 1 : p2_xpos = 3 : p2_frame_x = p2_speed_x

  ; Check right wall
  if p2_xpos > 139 then p2_dir_x = 255 : p2_xpos = 139 : p2_frame_x = p2_speed_x

  ; Check top wall
  if p2_ypos < 8 then p2_dir_y = 1 : p2_ypos = 8 : p2_frame_y = p2_speed_y

  ; Check bottom wall
  if p2_ypos > 135 then p2_dir_y = 255 : p2_ypos = 135 : p2_frame_y = p2_speed_y

  return

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
  ;  User manually set cardinal positions, interpolated intermediate
  ;  All positions use same sprite (rounded bar)
  ;***************************************************************
__Update_P1_Paddle
  on temp_dir goto __P1P_0 __P1P_1 __P1P_2 __P1P_3 __P1P_4 __P1P_5 __P1P_6 __P1P_7 __P1P_8 __P1P_9 __P1P_10 __P1P_11 __P1P_12 __P1P_13 __P1P_14 __P1P_15

; Direction 0: South (MANUAL)
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

; Direction 1: SSW (interpolated)
__P1P_1
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
  player2x = p1_xpos - 1 : player2y = p1_ypos + 24
  return

; Direction 2: SW (interpolated)
__P1P_2
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
  player2x = p1_xpos - 5 : player2y = p1_ypos + 21
  return

; Direction 3: WSW (interpolated)
__P1P_3
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
  player2x = p1_xpos - 8 : player2y = p1_ypos + 15
  return

; Direction 4: West (MANUAL)
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

; Direction 5: WNW (interpolated)
__P1P_5
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
  player2x = p1_xpos - 8 : player2y = p1_ypos + 1
  return

; Direction 6: NW (interpolated)
__P1P_6
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
  player2x = p1_xpos - 5 : player2y = p1_ypos - 5
  return

; Direction 7: NNW (interpolated)
__P1P_7
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
  player2x = p1_xpos - 2 : player2y = p1_ypos - 9
  return

; Direction 8: North (MANUAL)
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

; Direction 9: NNE (interpolated)
__P1P_9
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
  player2x = p1_xpos + 8 : player2y = p1_ypos - 9
  return

; Direction 10: NE (interpolated)
__P1P_10
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
  player2x = p1_xpos + 13 : player2y = p1_ypos - 5
  return

; Direction 11: ENE (interpolated)
__P1P_11
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
  player2x = p1_xpos + 16 : player2y = p1_ypos + 1
  return

; Direction 12: East (MANUAL)
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

; Direction 13: ESE (interpolated)
__P1P_13
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
  player2x = p1_xpos + 16 : player2y = p1_ypos + 15
  return

; Direction 14: SE (interpolated)
__P1P_14
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
  player2x = p1_xpos + 13 : player2y = p1_ypos + 21
  return

; Direction 15: SSE (interpolated)
__P1P_15
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
  player2x = p1_xpos + 9 : player2y = p1_ypos + 24
  return


  ;***************************************************************
  ;  Update Player 2 Paddle Position
  ;  temp_dir contains current direction (0-15)
  ;  Paddle dial: 0=South(bottom), 4=West, 8=North(top), 12=East
  ;  Same offsets as Player 1, same sprite
  ;***************************************************************
__Update_P2_Paddle
  on temp_dir goto __P2P_0 __P2P_1 __P2P_2 __P2P_3 __P2P_4 __P2P_5 __P2P_6 __P2P_7 __P2P_8 __P2P_9 __P2P_10 __P2P_11 __P2P_12 __P2P_13 __P2P_14 __P2P_15

; Direction 0: South (MANUAL)
__P2P_0
  player3:
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
  player3x = p2_xpos + 3 : player3y = p2_ypos + 28
  return

; Direction 1: SSW (calculated from P1 + offset)
__P2P_1
  player3:
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
  player3x = p2_xpos - 2 : player3y = p2_ypos + 24
  return

; Direction 2: SW (calculated from P1 + offset)
__P2P_2
  player3:
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
  player3x = p2_xpos - 6 : player3y = p2_ypos + 21
  return

; Direction 3: WSW (calculated from P1 + offset)
__P2P_3
  player3:
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
  player3x = p2_xpos - 9 : player3y = p2_ypos + 15
  return

; Direction 4: West (calculated from P1 + offset)
__P2P_4
  player3:
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
  player3x = p2_xpos - 9 : player3y = p2_ypos + 8
  return

; Direction 5: WNW (calculated from P1 + offset)
__P2P_5
  player3:
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
  player3x = p2_xpos - 9 : player3y = p2_ypos + 1
  return

; Direction 6: NW (calculated from P1 + offset)
__P2P_6
  player3:
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
  player3x = p2_xpos - 6 : player3y = p2_ypos - 5
  return

; Direction 7: NNW (calculated from P1 + offset)
__P2P_7
  player3:
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
  player3x = p2_xpos - 3 : player3y = p2_ypos - 9
  return

; Direction 8: North (calculated from P1 + offset)
__P2P_8
  player3:
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
  player3x = p2_xpos + 3 : player3y = p2_ypos - 11
  return

; Direction 9: NNE (calculated from P1 + offset)
__P2P_9
  player3:
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
  player3x = p2_xpos + 7 : player3y = p2_ypos - 9
  return

; Direction 10: NE (calculated from P1 + offset)
__P2P_10
  player3:
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
  player3x = p2_xpos + 12 : player3y = p2_ypos - 5
  return

; Direction 11: ENE (calculated from P1 + offset)
__P2P_11
  player3:
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
  player3x = p2_xpos + 15 : player3y = p2_ypos + 1
  return

; Direction 12: East (calculated from P1 + offset)
__P2P_12
  player3:
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
  player3x = p2_xpos + 15 : player3y = p2_ypos + 8
  return

; Direction 13: ESE (calculated from P1 + offset)
__P2P_13
  player3:
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
  player3x = p2_xpos + 15 : player3y = p2_ypos + 15
  return

; Direction 14: SE (calculated from P1 + offset)
__P2P_14
  player3:
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
  player3x = p2_xpos + 12 : player3y = p2_ypos + 21
  return

; Direction 15: SSE (calculated from P1 + offset)
__P2P_15
  player3:
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
  player3x = p2_xpos + 8 : player3y = p2_ypos + 24
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
