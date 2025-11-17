  ;***************************************************************
  ;  NEBULORDS PXE - Version 034
  ;  Warlords-style Space Combat with Paddle Controls
  ;
  ;  Changes from v033:
  ;  - SCORE TRACKING: Track wins for each player
  ;  - ROUND END DETECTION: When player dies, opponent wins the round
  ;  - INVINCIBILITY PERIOD: 3-second period after round win (players can move but can't be hit)
  ;  - Round resets after invincibility expires
  ;
  ;  Complete feature set from v030-v034:
  ;  - Ball/paddle collision with catching and launching mechanics
  ;  - Brick destruction system with hitbox detection
  ;  - Core hit detection and player death
  ;  - Score tracking and round-based gameplay
  ;  NOTE: Using ORIGINAL sprite design from v028-v030
  ;
  ;  Physics System:
  ;  - speed_x/y: Frames between pixel moves (lower = faster)
  ;  - max_speed = 2: Top speed (moves every 2 frames)
  ;  - Slowest speed = 16: 1 pixel every 16 frames
  ;  - Step by 2: 8 total speed steps
  ;  - accel_delay = 3: Frames between thrust applications
  ;  - dir_x/y: Movement direction (0=stopped, 1=positive, 255=negative)
  ;
  ;  Collision System:
  ;  - Rectangular hitboxes: 18×28 pixels (extends 1px on all sides)
  ;  - Larger than visible sprite to create "force field" effect
  ;  - P2 hitbox offset accounts for player1 sprite positioning difference
  ;  - Prevents ships from sinking into each other visually
  ;  - Ships bounce off each other when hitboxes overlap
  ;  - Velocities reversed and ships separated to prevent sticking
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
  ;  Ball/Catching Constants
  ;***************************************************************
  const fast_ball_duration = 240 ; 4 seconds at 60fps (launch fast mode)
  const auto_launch_time = 180   ; 3 seconds at 60fps (auto-launch delay)
  const catch_cooldown_time = 240 ; 4 seconds at 60fps (cooldown after auto-launch)

  ;***************************************************************
  ;  Round/Score Constants
  ;***************************************************************
  const invincibility_duration = 180 ; 3 seconds at 60fps (post-round invincibility)

  ;***************************************************************
  ;  Collision Constants (Hitbox sizes)
  ;***************************************************************
  const sprite_width = 16        ; Visual sprite width (double-width, 8 bits doubled)
  const sprite_height = 26       ; Visual sprite height (26 scanlines)
  const hitbox_offset_x = 1      ; Hitbox extends 1 pixel beyond sprite horizontally
  const hitbox_offset_y = 1      ; Hitbox extends 1 pixel beyond sprite vertically
  const ship_width = 18          ; Total hitbox width: 16 + 1 + 1 = 18
  const ship_height = 28         ; Total hitbox height: 26 + 1 + 1 = 28
  const p2_hitbox_offset = 1     ; P2 hitbox X offset due to player1 sprite positioning

  ;***************************************************************
  ;  Variable declarations
  ;  NOTE: Using player0x/y and player1x/y system variables directly (no custom xpos/ypos)
  ;***************************************************************
  ; Player 1 (Paddle 0) - Physics (7 vars per player)
  dim p1_direction = a
  dim p1_speed_x = b             ; Frames between X moves
  dim p1_speed_y = c             ; Frames between Y moves
  dim p1_frame_x = d             ; Frame counter for X movement
  dim p1_frame_y = e             ; Frame counter for Y movement
  dim p1_dir_x = f               ; X direction: 0=none, 1=right, 255=left
  dim p1_dir_y = g               ; Y direction: 0=none, 1=down, 255=up

  ; Player 2 (Paddle 1) - Physics (7 vars per player)
  dim p2_direction = h
  dim p2_speed_x = i             ; Frames between X moves
  dim p2_speed_y = j             ; Frames between Y moves
  dim p2_frame_x = k             ; Frame counter for X movement
  dim p2_frame_y = l             ; Frame counter for Y movement
  dim p2_dir_x = m               ; X direction
  dim p2_dir_y = n               ; Y direction

  ; Shared
  dim accel_counter = p          ; Frame counter for acceleration delay

  ; Temp variables
  dim temp_paddle = q
  dim temp_dir = r

  ; Ball
  dim ball_xvel = s
  dim ball_yvel = t
  dim ball_state = u             ; 0=free, 1=attached to P1, 2=attached to P2
  dim ball_speed_timer = v       ; Countdown for fast mode duration
  dim p1_catch_timer = w         ; Countdown for auto-launch (counts up 0-180)
  dim p2_catch_timer = x         ; Countdown for auto-launch
  dim p1_state = y               ; bit 0=button held, bit 1=cooldown active
  dim p2_state = z               ; bit 0=button held, bit 1=cooldown active

  ; Brick/Shield state (PXE extra variables)
  dim p1_bricks = var0           ; bit 0=top, bit 1=left, bit 2=right, bit 3=bottom (1=intact)
  dim p2_bricks = var1           ; bit 0=top, bit 1=left, bit 2=right, bit 3=bottom (1=intact)

  ; Score and round state
  dim p1_score = var2            ; Player 1 score (wins)
  dim p2_score = var3            ; Player 2 score (wins)
  dim invincibility_timer = var4 ; Countdown for invincibility period (180 frames = 3 seconds)

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

  player0x = 25 : player0y = 35
  player1x = 117 : player1y = 35

  p1_direction = 12
  p2_direction = 4

  ; Initialize P1 physics - start stationary
  p1_speed_x = 16 : p1_speed_y = 16
  p1_dir_x = 0 : p1_dir_y = 0
  p1_frame_x = p1_speed_x : p1_frame_y = p1_speed_y

  ; Initialize P2 physics - start stationary
  p2_speed_x = 16 : p2_speed_y = 16
  p2_dir_x = 0 : p2_dir_y = 0
  p2_frame_x = p2_speed_x : p2_frame_y = p2_speed_y

  ; Acceleration counter
  accel_counter = 0

  ; Initialize catching system
  ball_state = 0             ; Ball starts free
  ball_speed_timer = 0       ; No fast mode at start
  p1_catch_timer = 0 : p2_catch_timer = 0
  p1_state = 0 : p2_state = 0 ; No button held, no cooldown

  ; Initialize brick states - all intact (bits 0-3 set)
  p1_bricks = %00001111      ; Top, Left, Right, Bottom all intact
  p2_bricks = %00001111      ; Top, Left, Right, Bottom all intact

  ; Initialize scores and round state
  p1_score = 0 : p2_score = 0
  invincibility_timer = 0    ; No invincibility at start

  ballx = 80 : bally = 88
  ballheight = 4

  temp_dir = (rand & 15)
  gosub __Set_Ball_Velocity_Slow  ; Use SLOW velocity at start

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
  ;  Track button state and handle ball launching
  ;***************************************************************
  ; P1 button tracking
  if joy0right then goto __P1_Button_Down
  ; Button released - launch if ball attached
  if p1_state{0} && ball_state = 1 then gosub __P1_Launch_Ball
  p1_state{0} = 0
  goto __P1_Button_Done
__P1_Button_Down
  p1_state{0} = 1
__P1_Button_Done

  ; P2 button tracking
  if joy0left then goto __P2_Button_Down
  ; Button released - launch if ball attached
  if p2_state{0} && ball_state = 2 then gosub __P2_Launch_Ball
  p2_state{0} = 0
  goto __P2_Button_Done
__P2_Button_Down
  p2_state{0} = 1
__P2_Button_Done

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
  ;  Player-on-Player Collision Detection
  ;***************************************************************
  gosub __Player_Collision

  ;***************************************************************
  ;  Ball physics - attached or free
  ;***************************************************************
  if ball_state = 1 then gosub __Ball_Follow_P1 : goto __Skip_Ball_Physics
  if ball_state = 2 then gosub __Ball_Follow_P2 : goto __Skip_Ball_Physics

  ; Ball is free - normal physics
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel

  if ballx < 4 then ballx = 4 : ball_xvel = 0 - ball_xvel
  if ballx > 155 then ballx = 155 : ball_xvel = 0 - ball_xvel
  if bally < 8 then bally = 8 : ball_yvel = 0 - ball_yvel
  if bally > 157 then bally = 157 : ball_yvel = 0 - ball_yvel

  ;***************************************************************
  ;  Ball/Paddle Collision Detection (only when ball free)
  ;***************************************************************
  if collision(ball,player2) then gosub __Check_P1_Paddle
  if collision(ball,player3) then gosub __Check_P2_Paddle

  ;***************************************************************
  ;  Ball/Ship Collision Detection - Brick breaking (skip during invincibility)
  ;***************************************************************
  if invincibility_timer > 0 then goto __Skip_Ball_Physics

  if collision(ball,player0) then gosub __P1_Brick_Hit
  if collision(ball,player1) then gosub __P2_Brick_Hit

__Skip_Ball_Physics

  ;***************************************************************
  ;  Update timers
  ;***************************************************************
  ; Fast ball timer - slow down when expires
  if ball_speed_timer > 0 then ball_speed_timer = ball_speed_timer - 1
  if ball_speed_timer = 1 then gosub __Slow_Ball_Down

  ; P1 catch timer and auto-launch
  if ball_state = 1 then p1_catch_timer = p1_catch_timer + 1
  if p1_catch_timer >= auto_launch_time then gosub __P1_Auto_Launch

  ; P2 catch timer and auto-launch
  if ball_state = 2 then p2_catch_timer = p2_catch_timer + 1
  if p2_catch_timer >= auto_launch_time then gosub __P2_Auto_Launch

  ; P1 cooldown timer
  if p1_state{1} then p1_catch_timer = p1_catch_timer - 1
  if p1_catch_timer = 0 then p1_state{1} = 0

  ; P2 cooldown timer
  if p2_state{1} then p2_catch_timer = p2_catch_timer - 1
  if p2_catch_timer = 0 then p2_state{1} = 0

  ; Invincibility timer - countdown and reset round when expires
  if invincibility_timer > 0 then invincibility_timer = invincibility_timer - 1
  if invincibility_timer = 1 then gosub __Round_Reset

  ;***************************************************************
  ;  Update paddle positions based on direction
  ;***************************************************************
  temp_dir = p1_direction
  gosub __Update_P1_Paddle

  temp_dir = p2_direction
  gosub __Update_P2_Paddle

  ;***************************************************************
  ;  Update ship sprites based on brick destruction state
  ;***************************************************************
  gosub __Update_P1_Ship_Sprite
  gosub __Update_P2_Ship_Sprite

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
  if p1_dir_x = 255 then p1_speed_x = p1_speed_x + 2 : if p1_speed_x >= 16 then p1_dir_x = 0 : p1_speed_x = 16
  ; If stopped or moving right, accelerate right
  if p1_dir_x = 0 then p1_dir_x = 1
  if p1_dir_x = 1 then if p1_speed_x > max_speed then p1_speed_x = p1_speed_x - 2
  return

__P1_Accel_Left
  ; If moving right, decelerate
  if p1_dir_x = 1 then p1_speed_x = p1_speed_x + 2 : if p1_speed_x >= 16 then p1_dir_x = 0 : p1_speed_x = 16
  ; If stopped or moving left, accelerate left
  if p1_dir_x = 0 then p1_dir_x = 255
  if p1_dir_x = 255 then if p1_speed_x > max_speed then p1_speed_x = p1_speed_x - 2
  return

__P1_Accel_Up
  ; If moving down, decelerate
  if p1_dir_y = 1 then p1_speed_y = p1_speed_y + 2 : if p1_speed_y >= 16 then p1_dir_y = 0 : p1_speed_y = 16
  ; If stopped or moving up, accelerate up
  if p1_dir_y = 0 then p1_dir_y = 255
  if p1_dir_y = 255 then if p1_speed_y > max_speed then p1_speed_y = p1_speed_y - 2
  return

__P1_Accel_Down
  ; If moving up, decelerate
  if p1_dir_y = 255 then p1_speed_y = p1_speed_y + 2 : if p1_speed_y >= 16 then p1_dir_y = 0 : p1_speed_y = 16
  ; If stopped or moving down, accelerate down
  if p1_dir_y = 0 then p1_dir_y = 1
  if p1_dir_y = 1 then if p1_speed_y > max_speed then p1_speed_y = p1_speed_y - 2
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
  if p2_dir_x = 255 then p2_speed_x = p2_speed_x + 2 : if p2_speed_x >= 16 then p2_dir_x = 0 : p2_speed_x = 16
  if p2_dir_x = 0 then p2_dir_x = 1
  if p2_dir_x = 1 then if p2_speed_x > max_speed then p2_speed_x = p2_speed_x - 2
  return

__P2_Accel_Left
  if p2_dir_x = 1 then p2_speed_x = p2_speed_x + 2 : if p2_speed_x >= 16 then p2_dir_x = 0 : p2_speed_x = 16
  if p2_dir_x = 0 then p2_dir_x = 255
  if p2_dir_x = 255 then if p2_speed_x > max_speed then p2_speed_x = p2_speed_x - 2
  return

__P2_Accel_Up
  if p2_dir_y = 1 then p2_speed_y = p2_speed_y + 2 : if p2_speed_y >= 16 then p2_dir_y = 0 : p2_speed_y = 16
  if p2_dir_y = 0 then p2_dir_y = 255
  if p2_dir_y = 255 then if p2_speed_y > max_speed then p2_speed_y = p2_speed_y - 2
  return

__P2_Accel_Down
  if p2_dir_y = 255 then p2_speed_y = p2_speed_y + 2 : if p2_speed_y >= 16 then p2_dir_y = 0 : p2_speed_y = 16
  if p2_dir_y = 0 then p2_dir_y = 1
  if p2_dir_y = 1 then if p2_speed_y > max_speed then p2_speed_y = p2_speed_y - 2
  return


__P1_Apply_Movement
  ; Apply X movement (frame-based velocity)
  if p1_dir_x <> 0 then p1_frame_x = p1_frame_x - 1
  if p1_frame_x = 0 then player0x = player0x + p1_dir_x : p1_frame_x = p1_speed_x

  ; Apply Y movement (frame-based velocity) - DOUBLED for PXE
  if p1_dir_y <> 0 then p1_frame_y = p1_frame_y - 1
  if p1_frame_y = 0 then player0y = player0y + p1_dir_y : player0y = player0y + p1_dir_y : p1_frame_y = p1_speed_y

  return


__P2_Apply_Movement
  ; Apply X movement
  if p2_dir_x <> 0 then p2_frame_x = p2_frame_x - 1
  if p2_frame_x = 0 then player1x = player1x + p2_dir_x : p2_frame_x = p2_speed_x

  ; Apply Y movement - DOUBLED for PXE
  if p2_dir_y <> 0 then p2_frame_y = p2_frame_y - 1
  if p2_frame_y = 0 then player1y = player1y + p2_dir_y : player1y = player1y + p2_dir_y : p2_frame_y = p2_speed_y

  return


__P1_Wall_Bounce
  ; Check left wall
  if player0x < 3 then p1_dir_x = 1 : player0x = 3 : p1_frame_x = p1_speed_x

  ; Check right wall
  if player0x > 139 then p1_dir_x = 255 : player0x = 139 : p1_frame_x = p1_speed_x

  ; Check top wall
  if player0y < 8 then p1_dir_y = 1 : player0y = 8 : p1_frame_y = p1_speed_y

  ; Check bottom wall
  if player0y > 135 then p1_dir_y = 255 : player0y = 135 : p1_frame_y = p1_speed_y

  return


__P2_Wall_Bounce
  ; Check left wall
  if player1x < 3 then p2_dir_x = 1 : player1x = 3 : p2_frame_x = p2_speed_x

  ; Check right wall
  if player1x > 139 then p2_dir_x = 255 : player1x = 139 : p2_frame_x = p2_speed_x

  ; Check top wall
  if player1y < 8 then p2_dir_y = 1 : player1y = 8 : p2_frame_y = p2_speed_y

  ; Check bottom wall
  if player1y > 135 then p2_dir_y = 255 : player1y = 135 : p2_frame_y = p2_speed_y

  return


__Player_Collision
  ; AABB Collision Detection between Player 1 and Player 2
  ; Check if hitboxes overlap on both X and Y axes
  ; Note: P2 uses adjusted position due to player1 sprite origin offset

  ; X-axis overlap check (accounting for P2 hitbox offset)
  ; player0x < (player1x - p2_hitbox_offset) + ship_width && player0x + ship_width > (player1x - p2_hitbox_offset)
  if player0x >= player1x - p2_hitbox_offset + ship_width then goto __No_Collision
  if player0x + ship_width <= player1x - p2_hitbox_offset then goto __No_Collision

  ; Y-axis overlap check
  ; player0y < player1y + ship_height && player0y + ship_height > player1y
  if player0y >= player1y + ship_height then goto __No_Collision
  if player0y + ship_height <= player1y then goto __No_Collision

  ; Collision detected! Reverse velocities and separate ships

  ; Reverse X direction
  if p1_dir_x = 1 then p1_dir_x = 255 : goto __PC_CheckP1Y
  if p1_dir_x = 255 then p1_dir_x = 1
__PC_CheckP1Y
  ; Reverse Y direction
  if p1_dir_y = 1 then p1_dir_y = 255 : goto __PC_P2X
  if p1_dir_y = 255 then p1_dir_y = 1

__PC_P2X
  ; Reverse P2 X direction
  if p2_dir_x = 1 then p2_dir_x = 255 : goto __PC_P2Y
  if p2_dir_x = 255 then p2_dir_x = 1
__PC_P2Y
  ; Reverse P2 Y direction
  if p2_dir_y = 1 then p2_dir_y = 255 : goto __PC_Separate
  if p2_dir_y = 255 then p2_dir_y = 1

__PC_Separate
  ; Separate ships to prevent sticking
  ; Move P1 left and P2 right
  if player0x < player1x then player0x = player0x - 2 : player1x = player1x + 2
  if player0x >= player1x then player0x = player0x + 2 : player1x = player1x - 2

  ; Reset frame counters
  p1_frame_x = p1_speed_x : p1_frame_y = p1_speed_y
  p2_frame_x = p2_speed_x : p2_frame_y = p2_speed_y

__No_Collision
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
  ;  Set Ball Velocity - SLOW version (1 pixel/frame, default speed)
  ;  temp_dir = 0-15 for direction
  ;***************************************************************
__Set_Ball_Velocity_Slow
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __BVS_0 __BVS_1 __BVS_2 __BVS_3 __BVS_4 __BVS_5 __BVS_6 __BVS_7 __BVS_8 __BVS_9 __BVS_10 __BVS_11 __BVS_12 __BVS_13 __BVS_14 __BVS_15

__BVS_0  ; North (up)
  ball_xvel = 0 : ball_yvel = 255 : return
__BVS_1  ; NNE
  ball_xvel = 1 : ball_yvel = 254 : return
__BVS_2  ; NE
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_3  ; ENE
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_4  ; East (right)
  ball_xvel = 1 : ball_yvel = 0 : return
__BVS_5  ; ESE
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_6  ; SE
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_7  ; SSE
  ball_xvel = 1 : ball_yvel = 2 : return
__BVS_8  ; South (down)
  ball_xvel = 0 : ball_yvel = 1 : return
__BVS_9  ; SSW
  ball_xvel = 255 : ball_yvel = 2 : return
__BVS_10  ; SW
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_11  ; WSW
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_12  ; West (left)
  ball_xvel = 255 : ball_yvel = 0 : return
__BVS_13  ; WNW
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_14  ; NW
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_15  ; NNW
  ball_xvel = 255 : ball_yvel = 254 : return


  ;***************************************************************
  ;  Helper subroutines for paddle collision
  ;***************************************************************
__Check_P1_Paddle
  temp_dir = p1_direction
  gosub __Ball_Bounce_P1
  return

__Check_P2_Paddle
  temp_dir = p2_direction
  gosub __Ball_Bounce_P2
  return


  ;***************************************************************
  ;  Ball Bounce off Paddles - Catch if button held, otherwise bounce
  ;  temp_dir contains paddle direction (0-15)
  ;  Direction 0=South, rotates counter-clockwise
  ;***************************************************************
__Ball_Bounce_P1
  ; Check if button held AND not in cooldown - CATCH
  if p1_state{0} && !p1_state{1} then ball_state = 1 : p1_catch_timer = 0 : return

  ; Otherwise BOUNCE
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __BB1_0 __BB1_1 __BB1_2 __BB1_3 __BB1_4 __BB1_5 __BB1_6 __BB1_7 __BB1_8 __BB1_9 __BB1_10 __BB1_11 __BB1_12 __BB1_13 __BB1_14 __BB1_15

__BB1_0  ; North (up)
  ball_xvel = 0 : ball_yvel = 254 : return
__BB1_1  ; NNE
  ball_xvel = 1 : ball_yvel = 252 : return
__BB1_2  ; NE
  ball_xvel = 1 : ball_yvel = 254 : return
__BB1_3  ; ENE
  ball_xvel = 2 : ball_yvel = 254 : return
__BB1_4  ; East (right)
  ball_xvel = 1 : ball_yvel = 0 : return
__BB1_5  ; ESE
  ball_xvel = 2 : ball_yvel = 2 : return
__BB1_6  ; SE
  ball_xvel = 1 : ball_yvel = 2 : return
__BB1_7  ; SSE
  ball_xvel = 1 : ball_yvel = 4 : return
__BB1_8  ; South (down)
  ball_xvel = 0 : ball_yvel = 2 : return
__BB1_9  ; SSW
  ball_xvel = 255 : ball_yvel = 4 : return
__BB1_10  ; SW
  ball_xvel = 255 : ball_yvel = 2 : return
__BB1_11  ; WSW
  ball_xvel = 254 : ball_yvel = 2 : return
__BB1_12  ; West (left)
  ball_xvel = 255 : ball_yvel = 0 : return
__BB1_13  ; WNW
  ball_xvel = 254 : ball_yvel = 254 : return
__BB1_14  ; NW
  ball_xvel = 255 : ball_yvel = 254 : return
__BB1_15  ; NNW
  ball_xvel = 255 : ball_yvel = 252 : return

__Ball_Bounce_P2
  ; Check if button held AND not in cooldown - CATCH
  if p2_state{0} && !p2_state{1} then ball_state = 2 : p2_catch_timer = 0 : return

  ; Otherwise BOUNCE
  temp_dir = (temp_dir + 8) & 15
  on temp_dir goto __BB2_0 __BB2_1 __BB2_2 __BB2_3 __BB2_4 __BB2_5 __BB2_6 __BB2_7 __BB2_8 __BB2_9 __BB2_10 __BB2_11 __BB2_12 __BB2_13 __BB2_14 __BB2_15

__BB2_0  ; North
  ball_xvel = 0 : ball_yvel = 254 : return
__BB2_1  ; NNE
  ball_xvel = 1 : ball_yvel = 252 : return
__BB2_2  ; NE
  ball_xvel = 1 : ball_yvel = 254 : return
__BB2_3  ; ENE
  ball_xvel = 2 : ball_yvel = 254 : return
__BB2_4  ; East
  ball_xvel = 1 : ball_yvel = 0 : return
__BB2_5  ; ESE
  ball_xvel = 2 : ball_yvel = 2 : return
__BB2_6  ; SE
  ball_xvel = 1 : ball_yvel = 2 : return
__BB2_7  ; SSE
  ball_xvel = 1 : ball_yvel = 4 : return
__BB2_8  ; South
  ball_xvel = 0 : ball_yvel = 2 : return
__BB2_9  ; SSW
  ball_xvel = 255 : ball_yvel = 4 : return
__BB2_10  ; SW
  ball_xvel = 255 : ball_yvel = 2 : return
__BB2_11  ; WSW
  ball_xvel = 254 : ball_yvel = 2 : return
__BB2_12  ; West
  ball_xvel = 255 : ball_yvel = 0 : return
__BB2_13  ; WNW
  ball_xvel = 254 : ball_yvel = 254 : return
__BB2_14  ; NW
  ball_xvel = 255 : ball_yvel = 254 : return
__BB2_15  ; NNW
  ball_xvel = 255 : ball_yvel = 252 : return


  ;***************************************************************
  ;  Brick Hit Detection - Determine which brick was hit and destroy it
  ;  Sprite layout (26 scanlines):
  ;    Lines 0-6:   Top brick (7 scanlines)
  ;    Lines 7-8:   Upper connector (2 scanlines)
  ;    Lines 9-16:  Middle (left brick + core + right brick, 8 scanlines)
  ;    Lines 17-18: Lower connector (2 scanlines)
  ;    Lines 19-25: Bottom brick (7 scanlines)
  ;
  ;  Brick bits: bit 0=top, bit 1=left, bit 2=right, bit 3=bottom
  ;***************************************************************
__P1_Brick_Hit
  ; Calculate relative Y position: bally - player0y
  ; Top brick: Y offset 0-6
  if bally < player0y + 7 then goto __P1_Top_Brick
  ; Middle section (left/right): Y offset 9-16
  if bally < player0y + 17 then goto __P1_Middle_Brick
  ; Bottom brick: Y offset 19-25
  if bally < player0y + 26 then goto __P1_Bottom_Brick
  ; Connector areas - just bounce
  goto __P1_Brick_Bounce

__P1_Top_Brick
  ; Check if brick intact - if not, CORE HIT!
  if !p1_bricks{0} then goto __P1_Core_Hit
  p1_bricks{0} = 0
  goto __P1_Brick_Bounce

__P1_Middle_Brick
  ; Determine left vs right based on X position
  ; Left brick: ballx < player0x + 8 (left half of sprite)
  if ballx < player0x + 8 then goto __P1_Left_Brick
  ; Right brick - check if destroyed (core hit)
  if !p1_bricks{2} then goto __P1_Core_Hit
  p1_bricks{2} = 0
  goto __P1_Brick_Bounce
__P1_Left_Brick
  if !p1_bricks{1} then goto __P1_Core_Hit
  p1_bricks{1} = 0
  goto __P1_Brick_Bounce

__P1_Bottom_Brick
  if !p1_bricks{3} then goto __P1_Core_Hit
  p1_bricks{3} = 0
  goto __P1_Brick_Bounce

__P1_Core_Hit
  ; Player 1 dies - Player 2 wins the round!
  p2_score = p2_score + 1        ; Award point to Player 2
  invincibility_timer = invincibility_duration  ; Start 3-second invincibility period
  player0x = 25 : player0y = 35  ; Reset P1 position
  p1_bricks = %00001111          ; Restore all P1 bricks
  p1_direction = 12              ; Reset to default direction
  p1_speed_x = 16 : p1_speed_y = 16  ; Reset to stopped
  p1_dir_x = 0 : p1_dir_y = 0
  ball_state = 0                 ; Free the ball if attached
  goto __P1_Brick_Bounce         ; Still bounce the ball

__P1_Brick_Bounce
  ; Bounce the ball back
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  return


__P2_Brick_Hit
  ; Calculate relative Y position: bally - player1y
  ; Top brick: Y offset 0-6
  if bally < player1y + 7 then goto __P2_Top_Brick
  ; Middle section (left/right): Y offset 9-16
  if bally < player1y + 17 then goto __P2_Middle_Brick
  ; Bottom brick: Y offset 19-25
  if bally < player1y + 26 then goto __P2_Bottom_Brick
  ; Connector areas - just bounce
  goto __P2_Brick_Bounce

__P2_Top_Brick
  ; Check if brick intact - if not, CORE HIT!
  if !p2_bricks{0} then goto __P2_Core_Hit
  p2_bricks{0} = 0
  goto __P2_Brick_Bounce

__P2_Middle_Brick
  ; Determine left vs right based on X position
  ; Left brick: ballx < player1x + 8 (left half of sprite)
  if ballx < player1x + 8 then goto __P2_Left_Brick
  ; Right brick - check if destroyed (core hit)
  if !p2_bricks{2} then goto __P2_Core_Hit
  p2_bricks{2} = 0
  goto __P2_Brick_Bounce
__P2_Left_Brick
  if !p2_bricks{1} then goto __P2_Core_Hit
  p2_bricks{1} = 0
  goto __P2_Brick_Bounce

__P2_Bottom_Brick
  if !p2_bricks{3} then goto __P2_Core_Hit
  p2_bricks{3} = 0
  goto __P2_Brick_Bounce

__P2_Core_Hit
  ; Player 2 dies - Player 1 wins the round!
  p1_score = p1_score + 1        ; Award point to Player 1
  invincibility_timer = invincibility_duration  ; Start 3-second invincibility period
  player1x = 117 : player1y = 35 ; Reset P2 position
  p2_bricks = %00001111          ; Restore all P2 bricks
  p2_direction = 4               ; Reset to default direction
  p2_speed_x = 16 : p2_speed_y = 16  ; Reset to stopped
  p2_dir_x = 0 : p2_dir_y = 0
  ball_state = 0                 ; Free the ball if attached
  goto __P2_Brick_Bounce         ; Still bounce the ball

__P2_Brick_Bounce
  ; Bounce the ball back
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  return


  ;***************************************************************
  ;  Ball Follow Player - Position ball around paddle based on direction
  ;  Ball positioned just outside paddle sprite radius
  ;***************************************************************
__Ball_Follow_P1
  temp_dir = p1_direction
  on temp_dir goto __BF1_0 __BF1_1 __BF1_2 __BF1_3 __BF1_4 __BF1_5 __BF1_6 __BF1_7 __BF1_8 __BF1_9 __BF1_10 __BF1_11 __BF1_12 __BF1_13 __BF1_14 __BF1_15

__BF1_0  ; South
  ballx = player0x + 4 : bally = player0y + 32 : return
__BF1_1  ; SSW
  ballx = player0x - 1 : bally = player0y + 28 : return
__BF1_2  ; SW
  ballx = player0x - 5 : bally = player0y + 25 : return
__BF1_3  ; WSW
  ballx = player0x - 8 : bally = player0y + 19 : return
__BF1_4  ; West
  ballx = player0x - 8 : bally = player0y + 12 : return
__BF1_5  ; WNW
  ballx = player0x - 8 : bally = player0y + 5 : return
__BF1_6  ; NW
  ballx = player0x - 5 : bally = player0y - 1 : return
__BF1_7  ; NNW
  ballx = player0x - 2 : bally = player0y - 5 : return
__BF1_8  ; North
  ballx = player0x + 4 : bally = player0y - 7 : return
__BF1_9  ; NNE
  ballx = player0x + 8 : bally = player0y - 5 : return
__BF1_10  ; NE
  ballx = player0x + 13 : bally = player0y - 1 : return
__BF1_11  ; ENE
  ballx = player0x + 16 : bally = player0y + 5 : return
__BF1_12  ; East
  ballx = player0x + 16 : bally = player0y + 12 : return
__BF1_13  ; ESE
  ballx = player0x + 16 : bally = player0y + 19 : return
__BF1_14  ; SE
  ballx = player0x + 13 : bally = player0y + 25 : return
__BF1_15  ; SSE
  ballx = player0x + 9 : bally = player0y + 28 : return

__Ball_Follow_P2
  temp_dir = p2_direction
  on temp_dir goto __BF2_0 __BF2_1 __BF2_2 __BF2_3 __BF2_4 __BF2_5 __BF2_6 __BF2_7 __BF2_8 __BF2_9 __BF2_10 __BF2_11 __BF2_12 __BF2_13 __BF2_14 __BF2_15

__BF2_0  ; South
  ballx = player1x + 4 : bally = player1y + 32 : return
__BF2_1  ; SSW
  ballx = player1x - 1 : bally = player1y + 28 : return
__BF2_2  ; SW
  ballx = player1x - 5 : bally = player1y + 25 : return
__BF2_3  ; WSW
  ballx = player1x - 8 : bally = player1y + 19 : return
__BF2_4  ; West
  ballx = player1x - 8 : bally = player1y + 12 : return
__BF2_5  ; WNW
  ballx = player1x - 8 : bally = player1y + 5 : return
__BF2_6  ; NW
  ballx = player1x - 5 : bally = player1y - 1 : return
__BF2_7  ; NNW
  ballx = player1x - 2 : bally = player1y - 5 : return
__BF2_8  ; North
  ballx = player1x + 4 : bally = player1y - 7 : return
__BF2_9  ; NNE
  ballx = player1x + 8 : bally = player1y - 5 : return
__BF2_10  ; NE
  ballx = player1x + 13 : bally = player1y - 1 : return
__BF2_11  ; ENE
  ballx = player1x + 16 : bally = player1y + 5 : return
__BF2_12  ; East
  ballx = player1x + 16 : bally = player1y + 12 : return
__BF2_13  ; ESE
  ballx = player1x + 16 : bally = player1y + 19 : return
__BF2_14  ; SE
  ballx = player1x + 13 : bally = player1y + 25 : return
__BF2_15  ; SSE
  ballx = player1x + 9 : bally = player1y + 28 : return


  ;***************************************************************
  ;  Launch Ball - Set to fast speed in paddle's facing direction
  ;***************************************************************
__P1_Launch_Ball
  ball_state = 0  ; Detach from P1
  temp_dir = p1_direction  ; Use paddle direction
  gosub __Set_Ball_Velocity  ; Set to FAST velocity
  ball_speed_timer = fast_ball_duration  ; Start fast mode timer
  return

__P2_Launch_Ball
  ball_state = 0  ; Detach from P2
  temp_dir = p2_direction  ; Use paddle direction
  gosub __Set_Ball_Velocity  ; Set to FAST velocity
  ball_speed_timer = fast_ball_duration  ; Start fast mode timer
  return

__P1_Auto_Launch
  gosub __P1_Launch_Ball
  p1_state{1} = 1  ; Set cooldown flag
  p1_catch_timer = catch_cooldown_time  ; Set cooldown duration
  return

__P2_Auto_Launch
  gosub __P2_Launch_Ball
  p2_state{1} = 1  ; Set cooldown flag
  p2_catch_timer = catch_cooldown_time  ; Set cooldown duration
  return


  ;***************************************************************
  ;  Slow Ball Down - Reduce velocity from fast to slow
  ;***************************************************************
__Slow_Ball_Down
  ; Reduce each velocity component by half (fast → slow)
  if ball_xvel > 128 then goto __SBD_NegX
  ; Positive X velocity
  if ball_xvel > 1 then ball_xvel = 1
  goto __SBD_Y
__SBD_NegX
  ; Negative X velocity
  if ball_xvel < 255 then ball_xvel = 255
__SBD_Y
  if ball_yvel > 128 then goto __SBD_NegY
  ; Positive Y velocity
  if ball_yvel > 1 then ball_yvel = 1
  goto __SBD_Done
__SBD_NegY
  ; Negative Y velocity
  if ball_yvel < 255 then ball_yvel = 255
__SBD_Done
  ball_speed_timer = 0
  return


  ;***************************************************************
  ;  Round Reset - Start new round after invincibility period
  ;  Resets both players, ball, and bricks
  ;***************************************************************
__Round_Reset
  ; Reset Player 1
  player0x = 25 : player0y = 35
  p1_bricks = %00001111
  p1_direction = 12
  p1_speed_x = 16 : p1_speed_y = 16
  p1_dir_x = 0 : p1_dir_y = 0
  p1_frame_x = p1_speed_x : p1_frame_y = p1_speed_y

  ; Reset Player 2
  player1x = 117 : player1y = 35
  p2_bricks = %00001111
  p2_direction = 4
  p2_speed_x = 16 : p2_speed_y = 16
  p2_dir_x = 0 : p2_dir_y = 0
  p2_frame_x = p2_speed_x : p2_frame_y = p2_speed_y

  ; Reset ball to center
  ballx = 80 : bally = 88
  ball_state = 0
  temp_dir = (rand & 15)
  gosub __Set_Ball_Velocity_Slow

  ; Reset timers
  ball_speed_timer = 0
  p1_catch_timer = 0 : p2_catch_timer = 0
  p1_state = 0 : p2_state = 0
  invincibility_timer = 0

  return


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
  player2x = player0x + 4 : player2y = player0y + 28
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
  player2x = player0x - 1 : player2y = player0y + 24
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
  player2x = player0x - 5 : player2y = player0y + 21
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
  player2x = player0x - 8 : player2y = player0y + 15
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
  player2x = player0x - 8 : player2y = player0y + 8
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
  player2x = player0x - 8 : player2y = player0y + 1
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
  player2x = player0x - 5 : player2y = player0y - 5
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
  player2x = player0x - 2 : player2y = player0y - 9
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
  player2x = player0x + 4 : player2y = player0y - 11
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
  player2x = player0x + 8 : player2y = player0y - 9
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
  player2x = player0x + 13 : player2y = player0y - 5
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
  player2x = player0x + 16 : player2y = player0y + 1
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
  player2x = player0x + 16 : player2y = player0y + 8
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
  player2x = player0x + 16 : player2y = player0y + 15
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
  player2x = player0x + 13 : player2y = player0y + 21
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
  player2x = player0x + 9 : player2y = player0y + 24
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
  player3x = player1x + 4 : player3y = player1y + 28
  return

; Direction 1: SSW (same as P1)
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
  player3x = player1x - 1 : player3y = player1y + 24
  return

; Direction 2: SW (same as P1)
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
  player3x = player1x - 5 : player3y = player1y + 21
  return

; Direction 3: WSW (same as P1)
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
  player3x = player1x - 8 : player3y = player1y + 15
  return

; Direction 4: West (same as P1)
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
  player3x = player1x - 8 : player3y = player1y + 8
  return

; Direction 5: WNW (same as P1)
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
  player3x = player1x - 8 : player3y = player1y + 1
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
  player3x = player1x - 6 : player3y = player1y - 5
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
  player3x = player1x - 3 : player3y = player1y - 9
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
  player3x = player1x + 3 : player3y = player1y - 11
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
  player3x = player1x + 7 : player3y = player1y - 9
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
  player3x = player1x + 12 : player3y = player1y - 5
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
  player3x = player1x + 15 : player3y = player1y + 1
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
  player3x = player1x + 15 : player3y = player1y + 8
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
  player3x = player1x + 15 : player3y = player1y + 15
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
  player3x = player1x + 12 : player3y = player1y + 21
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
  player3x = player1x + 8 : player3y = player1y + 24
  return


  ;***************************************************************
  ;  Update Ship Sprites Based on Brick State
  ;  Brick bits: bit 0=top, bit 1=left, bit 2=right, bit 3=bottom
  ;  State 0-15 represents all combinations of brick destruction
  ;  %00000000 = destroyed brick scanlines (transparent)
  ;***************************************************************
__Update_P1_Ship_Sprite
  ; p1_bricks contains 4 bits representing brick state
  ; Use lower 4 bits as state index (0-15)
  temp_dir = p1_bricks & %00001111
  on temp_dir goto __P1S_0 __P1S_1 __P1S_2 __P1S_3 __P1S_4 __P1S_5 __P1S_6 __P1S_7 __P1S_8 __P1S_9 __P1S_10 __P1S_11 __P1S_12 __P1S_13 __P1S_14 __P1S_15

; State 0: All bricks destroyed
__P1S_0
  player0:
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000011
  %11000011
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000011
  %11000011
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 15: All bricks intact (default)
__P1S_15
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
  return

; For other states, show partial destruction
; Due to code size constraints, we'll use a simplified approach:
; Just return for now - full 16-state sprites can be added later if needed
__P1S_1
__P1S_2
__P1S_3
__P1S_4
__P1S_5
__P1S_6
__P1S_7
__P1S_8
__P1S_9
__P1S_10
__P1S_11
__P1S_12
__P1S_13
__P1S_14
  ; For now, use default sprite (state 15)
  goto __P1S_15


__Update_P2_Ship_Sprite
  ; p2_bricks contains 4 bits representing brick state
  temp_dir = p2_bricks & %00001111
  on temp_dir goto __P2S_0 __P2S_1 __P2S_2 __P2S_3 __P2S_4 __P2S_5 __P2S_6 __P2S_7 __P2S_8 __P2S_9 __P2S_10 __P2S_11 __P2S_12 __P2S_13 __P2S_14 __P2S_15

; State 0: All bricks destroyed
__P2S_0
  player1:
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000011
  %11000011
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000011
  %11000011
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 15: All bricks intact (default)
__P2S_15
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
  return

; Simplified states - use default for now
__P2S_1
__P2S_2
__P2S_3
__P2S_4
__P2S_5
__P2S_6
__P2S_7
__P2S_8
__P2S_9
__P2S_10
__P2S_11
__P2S_12
__P2S_13
__P2S_14
  goto __P2S_15


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
