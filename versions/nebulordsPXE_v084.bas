  ;***************************************************************
  ;  NEBULORDS PXE - Version 084
  ;  Warlords-style Space Combat with Paddle Controls
  ;
  ;  Changes from v079:
  ;  - ADD: Win tracking with data table score display (minimal code)
  ;  - ADD: pfscore bars using lookup table instead of if statements
  ;  - First to 3 wins ends the game
  ;  - Optimized for small code size to avoid bank boundary issues
  ;
  ;  Changes from v077:
  ;  - FIX: Ball position 16 (North/top) extended 2 pixels (Y-15 to Y-17)
  ;  - FIX: Held ball immunity - players immune when ball held (prevents sword attacks)
  ;  - Ball only damages ships when free-floating (ball_state = 0)
  ;
  ;  Changes from v074:
  ;  - ADD: Built-in PXE score display system (BCD format)
  ;  - ADD: __Award_P1_Point and __Award_P2_Point subroutines with BCD math
  ;  - ADD: scorecolors blocks for gradient score display (P1 blue, P2 purple)
  ;  - REORGANIZE: Code structure with section headers for easy navigation
  ;  - REORGANIZE: Coordinate reference table showing all paddle/ball offsets
  ;  - Score format: score+2 (P1) | score+1 (separator) | score+0 (P2)
  ;  - BCD math: Each byte holds 00-99 in decimal ($00-$99 hex)
  ;
  ;  Changes from v061:
  ;  - FIX: Ball collision checked BEFORE ship movement (same moment in time)
  ;  - FIX: Removed unused ship_collision_cooldown and brick_immunity variables
  ;  - Reordered main loop: ball collision -> ball move -> ship movement
  ;
  ;  Changes from v048:
  ;  - FIX: Players only die when CORE is struck, not when all 4 bricks destroyed
  ;  - FIX: Ball no longer passes through exposed core after brick destroyed
  ;  - FIX: Ball no longer passes through ships after paddle bounce
  ;  - ADD: Core exposure checks for all 4 brick types when destroyed
  ;  - ADD: 2-frame collision cooldown after paddle bounce to prevent penetration
  ;  - Removed all "if p1_bricks = 0" auto-death checks from brick handlers
  ;  - Core is only deadly when ball directly hits the core hitbox
  ;
  ;  Changes from v047:
  ;  - FIX: Diagonal brick sprites corrected - only states 13/11 needed swapping
  ;  - FIX: States 12/10, 5/3, 4/2 reverted to original graphics
  ;  - Diagonal combinations now show correct brick patterns
  ;  - Only single-brick states (13=right destroyed, 11=left destroyed) are swapped
  ;
  ;  Changes from v046:
  ;  - FIX: Left/right brick sprites flipped - hitting left now destroys left
  ;  - FIX: Killed players stay off-screen - disabled wall bounce when Y >= 150
  ;  - FIX: Killed players disabled - no movement or controls when off-screen
  ;  - ADD: Paddle gradient colors - paddles now match ship sprite gradients
  ;  - All brick bit assignments swapped (bit 1 = right, bit 2 = left)
  ;  - All sprite states updated to match new bit assignments
  ;
  ;  Changes from v045:
  ;  - FIX: Multi-brick destruction sprites - all 16 states now implemented
  ;  - FIX: Cross-player collision bug - only one player hit per frame
  ;  - FIX: Core hitbox expanded (+1px sides, +2px top/bottom)
  ;  - FIX: P2 hitboxes shifted +2 pixels right for proper alignment
  ;  - ADD: Complete sprite states for all brick combinations (states 1-6, 8-10, 12)
  ;  - IMPROVE: Core hitbox now 6 pixels wide, harder to miss
  ;  - IMPROVE: Brick sprites show accurate multi-brick destruction
  ;
  ;  Changes from v044:
  ;  - FIX: Left/right brick sprites show correct graphics (removed core pixels)
  ;  - FIX: Dead players moved to Y=200 instead of 0,0 (properly off-screen)
  ;  - FIX: Core hit handlers simplified - round reset handled by __Round_Reset
  ;  - FIX: Hitbox glitch fixed - invincibility timer re-enabled
  ;  - FIX: Collision detection disabled for off-screen players (Y >= 100)
  ;  - ADD: Core hitbox (5th hitbox) - center area now directly triggers death
  ;  - IMPROVE: Middle section split into 3 zones: left brick, core, right brick
  ;
  ;  Changes from v042:
  ;  - FIX: Correct Y coordinate brick hitboxes (Y axis inverted, origin bottom-left)
  ;  - FIX: Push ball away after brick bounce to prevent sticking
  ;  - FIX: Destroyed brick hitboxes now disabled (ball passes through)
  ;  - ENABLE: Core hit detection destroys player sprite and paddle
  ;  - All brick types (top/left/right/bottom) have working hitboxes
  ;
  ;  Changes from v041:
  ;  - CRITICAL FIX: Removed double rotation bug in deflections
  ;  - Deflections now correctly match paddle direction
  ;  - FIX: South ball position lowered additional 4px (final adjustment)
  ;
  ;  Changes from v036:
  ;  - FIX: Southern ball positions lowered (1-3px) for better visual alignment
  ;  - FIX: Paddle collision only checked when ball_state = 0 (prevents re-catch after launch)
  ;
  ;  Changes from v035:
  ;  - FIX: Ball position offset adjusted (+2x, +2y) for better alignment
  ;  - FIX: Auto-launch now frees the ball (stops following paddle mid-flight)
  ;  - Auto-launch timer extended from 3 to 4 seconds (180→240 frames)
  ;
  ;  Changes from v034:
  ;  - FIX: Ball now positions correctly relative to paddle when caught
  ;  - Ball offsets match v051 pattern (+2 pixels beyond paddle)
  ;  - Brick collision and game restart temporarily disabled for testing
  ;
  ;  Changes from v033:
  ;  - SCORE TRACKING: Track wins for each player
  ;  - ROUND END DETECTION: When player dies, opponent wins the round
  ;  - INVINCIBILITY PERIOD: 3-second period after round win (players can move but can't be hit)
  ;  - Round resets after invincibility expires
  ;
  ;  Complete feature set from v030-v035:
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
  set score_graphics on

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
  const auto_launch_time = 240   ; 4 seconds at 60fps (auto-launch delay)
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
  dim p1_wins = var2             ; P1 win counter (0-3)
  dim p2_wins = var3             ; P2 win counter (0-3)

  ; REPLACED - SEE BELOW
  ;***************************************************************
  ;  SCORE SYSTEM - Using built-in PXE score display!
  ;  Format: score+2  score+1  score+0 = 6 BCD digits
  ;  Display: "P1  P2" where P1=score+2, P2=score+0
  ;***************************************************************
  dim p1_score = score+2         ; Player 1 score (00-99 in BCD)
  dim score_separator = score+1  ; Middle bytes (kept at $00 for spacing)
  dim p2_score = score           ; Player 2 score (00-99 in BCD)
  dim invincibility_timer = var4 ; Countdown for invincibility
  dim p1_caught_dir = var5       ; P1 paddle direction when ball caught
  dim p2_caught_dir = var6       ; P2 paddle direction when ball caught
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW
  ; REPLACED - SEE BELOW

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

  player0x = 25 : player0y = 40
  player1x = 117 : player1y = 40

  p1_direction = 24
  p2_direction = 8

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

  ; Initialize scores and round state (BCD format: $00 = 00 in decimal)
  p1_score = $00 : p2_score = $00 : score_separator = $00
  invincibility_timer = 0    ; No invincibility at start
  p1_wins = 0 : p2_wins = 0  ; Win counters

  ballx = 80 : bally = 88
  ballheight = 4

  temp_dir = (rand & 31)
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

  ; Paddle colors - brightest first, gradient, brightest last
  player2color:
  $98
  $9a
  $9c
  $9e
  $90
  $92
  $94
  $96
  $98  ; Brightest blue at end
end

  player3color:
  $78
  $7a
  $7c
  $7e
  $70
  $72
  $74
  $76
  $78
end


  ;***************************************************************
  ;  MAIN LOOP
  ;***************************************************************
__Main_Loop

  ;***************************************************************
  ;  Read Paddle 0 for Player 1 direction
  ;***************************************************************
  temp_paddle = Paddle0
  p1_direction = temp_paddle / 4
  if p1_direction >= 32 then p1_direction = 0

  ;***************************************************************
  ;  Read Paddle 1 for Player 2 direction
  ;***************************************************************
  temp_paddle = Paddle1
  p2_direction = temp_paddle / 4
  if p2_direction >= 32 then p2_direction = 0

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
  ;  Ball physics - FIRST (before ship moves, same moment in time)
  ;***************************************************************
  if ball_state = 1 then gosub __Ball_Follow_P1 : goto __Skip_Ball_Physics
  if ball_state = 2 then gosub __Ball_Follow_P2 : goto __Skip_Ball_Physics

  ;***************************************************************
  ;  Ball/Ship Collision Detection - Brick breaking
  ;  Check BEFORE either ball or ship moves (same moment in time)
  ;  Ship sprite: 16x26, Ball: 2x4
  ;***************************************************************
  ; IMMUNITY: Players immune to ball when held (prevents "sword" attacks)
  if ball_state > 0 then goto __Skip_Brick_Collision
  ; DISABLED: if invincibility_timer > 0 then goto __Skip_Brick_Collision

  ; P1 coordinate collision: exact sprite bounds (16x26) - using inclusive bounds
  if player0y < 200 then if (bally + 4) >= player0y && bally <= (player0y + 26) then if (ballx + 2) >= player0x && ballx <= (player0x + 16) then gosub __P1_Brick_Hit : goto __Skip_Brick_Collision
  ; P2 coordinate collision (shifted +2px for player1 sprite offset) - using inclusive bounds
  if player1y < 200 then if (bally + 4) >= player1y && bally <= (player1y + 26) then if (ballx + 2) >= (player1x + 2) && ballx <= (player1x + 18) then gosub __P2_Brick_Hit

__Skip_Brick_Collision

  ; Ball moves AFTER collision check
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel

  ; Wall bounces for ball
  if ballx < 4 then ballx = 4 : ball_xvel = 0 - ball_xvel
  if ballx > 155 then ballx = 155 : ball_xvel = 0 - ball_xvel
  if bally < 8 then bally = 8 : ball_yvel = 0 - ball_yvel
  if bally > 157 then bally = 157 : ball_yvel = 0 - ball_yvel

  ;***************************************************************
  ;  Ball/Paddle Collision Detection (after ball moved)
  ;***************************************************************
  if ball_state > 0 then goto __Skip_Paddle_Collision

  ; Check P1 paddle (player2)
  if ballx < player2x + 11 && ballx + 2 > player2x + 3 then if bally < player2y + 10 && bally + 4 > player2y - 1 then gosub __Check_P1_Paddle

  ; Check P2 paddle (player3)
  if ballx < player3x + 9 && ballx + 2 > player3x + 1 then if bally < player3y + 10 && bally + 4 > player3y - 1 then gosub __Check_P2_Paddle

__Skip_Paddle_Collision

__Skip_Ball_Physics

  ;***************************************************************
  ;  Ship Physics - AFTER ball collision (ship hasn't moved yet when ball checked)
  ;***************************************************************
  ;  Acceleration counter - only accelerate every N frames
  accel_counter = accel_counter + 1
  if accel_counter >= accel_delay then accel_counter = 0

  ; Thrust Physics - Apply when button held
  ; Player 1: Paddle 0 button is joy0right
  if joy0right && accel_counter = 0 then temp_dir = p1_direction : gosub __P1_Thrust

  ; Player 2: Paddle 1 button is joy0left
  if joy0left && accel_counter = 0 then temp_dir = p2_direction : gosub __P2_Thrust

  ; Apply frame-based movement (drift with momentum)
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
  ;  Update timers
  ;***************************************************************
  ; Fast ball timer - slow down when expires
  if ball_speed_timer > 0 then ball_speed_timer = ball_speed_timer - 1
  if ball_speed_timer = 1 then gosub __Slow_Ball_Down

  ; P1 catch timer and auto-launch
  if ball_state = 1 then p1_catch_timer = p1_catch_timer + 1
  if ball_state = 1 && p1_catch_timer >= auto_launch_time then gosub __P1_Auto_Launch

  ; P2 catch timer and auto-launch
  if ball_state = 2 then p2_catch_timer = p2_catch_timer + 1
  if ball_state = 2 && p2_catch_timer >= auto_launch_time then gosub __P2_Auto_Launch

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
  ;  Now supports full 32 positions for smooth paddle control
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

  ; Draw score display in bottom playfield area
  ; Score displays automatically at top via built-in PXE score system!

  drawscreen
  goto __Main_Loop


  ;***************************************************************
  ;  THRUST PHYSICS SUBROUTINES
  ;***************************************************************

__P1_Thrust
  ; Apply thrust in direction temp_dir (0-31)
  ; Rotated by 16 to match paddle dial (0=South)
  temp_dir = (temp_dir + 16) & 31
  on temp_dir goto __P1T_0 __P1T_1 __P1T_2 __P1T_3 __P1T_4 __P1T_5 __P1T_6 __P1T_7 __P1T_8 __P1T_9 __P1T_10 __P1T_11 __P1T_12 __P1T_13 __P1T_14 __P1T_15 __P1T_16 __P1T_17 __P1T_18 __P1T_19 __P1T_20 __P1T_21 __P1T_22 __P1T_23 __P1T_24 __P1T_25 __P1T_26 __P1T_27 __P1T_28 __P1T_29 __P1T_30 __P1T_31

; 32-direction thrust: 0=N, 8=E, 16=S, 24=W
__P1T_0
  gosub __P1_Accel_Up : return
__P1T_1
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_2
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_3
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_4
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_5
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_6
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_7
  gosub __P1_Accel_Up : gosub __P1_Accel_Right : return
__P1T_8
  gosub __P1_Accel_Right : return
__P1T_9
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_10
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_11
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_12
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_13
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_14
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_15
  gosub __P1_Accel_Down : gosub __P1_Accel_Right : return
__P1T_16
  gosub __P1_Accel_Down : return
__P1T_17
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_18
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_19
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_20
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_21
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_22
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_23
  gosub __P1_Accel_Down : gosub __P1_Accel_Left : return
__P1T_24
  gosub __P1_Accel_Left : return
__P1T_25
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
__P1T_26
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
__P1T_27
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
__P1T_28
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
__P1T_29
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
__P1T_30
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return
__P1T_31
  gosub __P1_Accel_Up : gosub __P1_Accel_Left : return


__P1_Accel_Right
  ; If moving left, decelerate (return on stop to prevent same-frame re-accel)
  if p1_dir_x = 255 then p1_speed_x = p1_speed_x + 2 : if p1_speed_x >= 16 then p1_dir_x = 0 : p1_speed_x = 16 : return
  ; If stopped or moving right, accelerate right
  if p1_dir_x = 0 then p1_dir_x = 1
  if p1_dir_x = 1 then if p1_speed_x > max_speed then p1_speed_x = p1_speed_x - 2
  return

__P1_Accel_Left
  ; If moving right, decelerate (return on stop to prevent same-frame re-accel)
  if p1_dir_x = 1 then p1_speed_x = p1_speed_x + 2 : if p1_speed_x >= 16 then p1_dir_x = 0 : p1_speed_x = 16 : return
  ; If stopped or moving left, accelerate left
  if p1_dir_x = 0 then p1_dir_x = 255
  if p1_dir_x = 255 then if p1_speed_x > max_speed then p1_speed_x = p1_speed_x - 2
  return

__P1_Accel_Up
  ; If moving down, decelerate (return on stop to prevent same-frame re-accel)
  if p1_dir_y = 1 then p1_speed_y = p1_speed_y + 2 : if p1_speed_y >= 16 then p1_dir_y = 0 : p1_speed_y = 16 : return
  ; If stopped or moving up, accelerate up
  if p1_dir_y = 0 then p1_dir_y = 255
  if p1_dir_y = 255 then if p1_speed_y > max_speed then p1_speed_y = p1_speed_y - 2
  return

__P1_Accel_Down
  ; If moving up, decelerate (return on stop to prevent same-frame re-accel)
  if p1_dir_y = 255 then p1_speed_y = p1_speed_y + 2 : if p1_speed_y >= 16 then p1_dir_y = 0 : p1_speed_y = 16 : return
  ; If stopped or moving down, accelerate down
  if p1_dir_y = 0 then p1_dir_y = 1
  if p1_dir_y = 1 then if p1_speed_y > max_speed then p1_speed_y = p1_speed_y - 2
  return


__P2_Thrust
  ; Apply thrust in direction temp_dir (0-31)
  temp_dir = (temp_dir + 16) & 31
  on temp_dir goto __P2T_0 __P2T_1 __P2T_2 __P2T_3 __P2T_4 __P2T_5 __P2T_6 __P2T_7 __P2T_8 __P2T_9 __P2T_10 __P2T_11 __P2T_12 __P2T_13 __P2T_14 __P2T_15 __P2T_16 __P2T_17 __P2T_18 __P2T_19 __P2T_20 __P2T_21 __P2T_22 __P2T_23 __P2T_24 __P2T_25 __P2T_26 __P2T_27 __P2T_28 __P2T_29 __P2T_30 __P2T_31

; 32-direction thrust: 0=N, 8=E, 16=S, 24=W
__P2T_0
  gosub __P2_Accel_Up : return
__P2T_1
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_2
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_3
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_4
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_5
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_6
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_7
  gosub __P2_Accel_Up : gosub __P2_Accel_Right : return
__P2T_8
  gosub __P2_Accel_Right : return
__P2T_9
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_10
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_11
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_12
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_13
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_14
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_15
  gosub __P2_Accel_Down : gosub __P2_Accel_Right : return
__P2T_16
  gosub __P2_Accel_Down : return
__P2T_17
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_18
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_19
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_20
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_21
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_22
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_23
  gosub __P2_Accel_Down : gosub __P2_Accel_Left : return
__P2T_24
  gosub __P2_Accel_Left : return
__P2T_25
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_26
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_27
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_28
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_29
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_30
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return
__P2T_31
  gosub __P2_Accel_Up : gosub __P2_Accel_Left : return


__P2_Accel_Right
  ; If moving left, decelerate (return on stop to prevent same-frame re-accel)
  if p2_dir_x = 255 then p2_speed_x = p2_speed_x + 2 : if p2_speed_x >= 16 then p2_dir_x = 0 : p2_speed_x = 16 : return
  if p2_dir_x = 0 then p2_dir_x = 1
  if p2_dir_x = 1 then if p2_speed_x > max_speed then p2_speed_x = p2_speed_x - 2
  return

__P2_Accel_Left
  ; If moving right, decelerate (return on stop to prevent same-frame re-accel)
  if p2_dir_x = 1 then p2_speed_x = p2_speed_x + 2 : if p2_speed_x >= 16 then p2_dir_x = 0 : p2_speed_x = 16 : return
  if p2_dir_x = 0 then p2_dir_x = 255
  if p2_dir_x = 255 then if p2_speed_x > max_speed then p2_speed_x = p2_speed_x - 2
  return

__P2_Accel_Up
  ; If moving down, decelerate (return on stop to prevent same-frame re-accel)
  if p2_dir_y = 1 then p2_speed_y = p2_speed_y + 2 : if p2_speed_y >= 16 then p2_dir_y = 0 : p2_speed_y = 16 : return
  if p2_dir_y = 0 then p2_dir_y = 255
  if p2_dir_y = 255 then if p2_speed_y > max_speed then p2_speed_y = p2_speed_y - 2
  return

__P2_Accel_Down
  ; If moving up, decelerate (return on stop to prevent same-frame re-accel)
  if p2_dir_y = 255 then p2_speed_y = p2_speed_y + 2 : if p2_speed_y >= 16 then p2_dir_y = 0 : p2_speed_y = 16 : return
  if p2_dir_y = 0 then p2_dir_y = 1
  if p2_dir_y = 1 then if p2_speed_y > max_speed then p2_speed_y = p2_speed_y - 2
  return


__P1_Apply_Movement
  ; Skip movement if player is off-screen (killed)
  if player0y >= 150 then return

  ; Apply X movement (frame-based velocity)
  if p1_dir_x <> 0 then p1_frame_x = p1_frame_x - 1
  if p1_frame_x = 0 then player0x = player0x + p1_dir_x : p1_frame_x = p1_speed_x

  ; Apply Y movement (frame-based velocity) - DOUBLED for PXE
  if p1_dir_y <> 0 then p1_frame_y = p1_frame_y - 1
  if p1_frame_y = 0 then player0y = player0y + p1_dir_y : player0y = player0y + p1_dir_y : p1_frame_y = p1_speed_y

  return


__P2_Apply_Movement
  ; Skip movement if player is off-screen (killed)
  if player1y >= 150 then return

  ; Apply X movement
  if p2_dir_x <> 0 then p2_frame_x = p2_frame_x - 1
  if p2_frame_x = 0 then player1x = player1x + p2_dir_x : p2_frame_x = p2_speed_x

  ; Apply Y movement - DOUBLED for PXE
  if p2_dir_y <> 0 then p2_frame_y = p2_frame_y - 1
  if p2_frame_y = 0 then player1y = player1y + p2_dir_y : player1y = player1y + p2_dir_y : p2_frame_y = p2_speed_y

  return


__P1_Wall_Bounce
  ; Skip wall bounce if player is off-screen (killed)
  if player0y >= 150 then return

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
  ; Skip wall bounce if player is off-screen (killed)
  if player1y >= 150 then return

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
  ; 32-direction fast ball: 0=N, 8=E, 16=S, 24=W
  temp_dir = (temp_dir + 16) & 31
  on temp_dir goto __BV_0 __BV_1 __BV_2 __BV_3 __BV_4 __BV_5 __BV_6 __BV_7 __BV_8 __BV_9 __BV_10 __BV_11 __BV_12 __BV_13 __BV_14 __BV_15 __BV_16 __BV_17 __BV_18 __BV_19 __BV_20 __BV_21 __BV_22 __BV_23 __BV_24 __BV_25 __BV_26 __BV_27 __BV_28 __BV_29 __BV_30 __BV_31

__BV_0
  ball_xvel = 0 : ball_yvel = 253 : return
__BV_1
  ball_xvel = 1 : ball_yvel = 253 : return
__BV_2
  ball_xvel = 1 : ball_yvel = 253 : return
__BV_3
  ball_xvel = 2 : ball_yvel = 254 : return
__BV_4
  ball_xvel = 2 : ball_yvel = 254 : return
__BV_5
  ball_xvel = 2 : ball_yvel = 254 : return
__BV_6
  ball_xvel = 2 : ball_yvel = 255 : return
__BV_7
  ball_xvel = 3 : ball_yvel = 255 : return
__BV_8
  ball_xvel = 3 : ball_yvel = 0 : return
__BV_9
  ball_xvel = 3 : ball_yvel = 1 : return
__BV_10
  ball_xvel = 2 : ball_yvel = 1 : return
__BV_11
  ball_xvel = 2 : ball_yvel = 2 : return
__BV_12
  ball_xvel = 2 : ball_yvel = 2 : return
__BV_13
  ball_xvel = 2 : ball_yvel = 2 : return
__BV_14
  ball_xvel = 1 : ball_yvel = 3 : return
__BV_15
  ball_xvel = 1 : ball_yvel = 3 : return
__BV_16
  ball_xvel = 0 : ball_yvel = 3 : return
__BV_17
  ball_xvel = 255 : ball_yvel = 3 : return
__BV_18
  ball_xvel = 255 : ball_yvel = 3 : return
__BV_19
  ball_xvel = 254 : ball_yvel = 2 : return
__BV_20
  ball_xvel = 254 : ball_yvel = 2 : return
__BV_21
  ball_xvel = 254 : ball_yvel = 2 : return
__BV_22
  ball_xvel = 254 : ball_yvel = 1 : return
__BV_23
  ball_xvel = 253 : ball_yvel = 1 : return
__BV_24
  ball_xvel = 253 : ball_yvel = 0 : return
__BV_25
  ball_xvel = 253 : ball_yvel = 255 : return
__BV_26
  ball_xvel = 254 : ball_yvel = 255 : return
__BV_27
  ball_xvel = 254 : ball_yvel = 254 : return
__BV_28
  ball_xvel = 254 : ball_yvel = 254 : return
__BV_29
  ball_xvel = 254 : ball_yvel = 254 : return
__BV_30
  ball_xvel = 255 : ball_yvel = 253 : return
__BV_31
  ball_xvel = 255 : ball_yvel = 253 : return


  ;***************************************************************
  ;  Set Ball Velocity - SLOW version (1 pixel/frame, default speed)
  ;  temp_dir = 0-31 for direction
  ;***************************************************************
__Set_Ball_Velocity_Slow
  temp_dir = (temp_dir + 16) & 31
  on temp_dir goto __BVS_0 __BVS_1 __BVS_2 __BVS_3 __BVS_4 __BVS_5 __BVS_6 __BVS_7 __BVS_8 __BVS_9 __BVS_10 __BVS_11 __BVS_12 __BVS_13 __BVS_14 __BVS_15 __BVS_16 __BVS_17 __BVS_18 __BVS_19 __BVS_20 __BVS_21 __BVS_22 __BVS_23 __BVS_24 __BVS_25 __BVS_26 __BVS_27 __BVS_28 __BVS_29 __BVS_30 __BVS_31

__BVS_0
  ball_xvel = 0 : ball_yvel = 255 : return
__BVS_1
  ball_xvel = 1 : ball_yvel = 254 : return
__BVS_2
  ball_xvel = 1 : ball_yvel = 254 : return
__BVS_3
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_4
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_5
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_6
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_7
  ball_xvel = 1 : ball_yvel = 255 : return
__BVS_8
  ball_xvel = 1 : ball_yvel = 0 : return
__BVS_9
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_10
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_11
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_12
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_13
  ball_xvel = 1 : ball_yvel = 1 : return
__BVS_14
  ball_xvel = 1 : ball_yvel = 2 : return
__BVS_15
  ball_xvel = 1 : ball_yvel = 2 : return
__BVS_16
  ball_xvel = 0 : ball_yvel = 1 : return
__BVS_17
  ball_xvel = 255 : ball_yvel = 2 : return
__BVS_18
  ball_xvel = 255 : ball_yvel = 2 : return
__BVS_19
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_20
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_21
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_22
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_23
  ball_xvel = 255 : ball_yvel = 1 : return
__BVS_24
  ball_xvel = 255 : ball_yvel = 0 : return
__BVS_25
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_26
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_27
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_28
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_29
  ball_xvel = 255 : ball_yvel = 255 : return
__BVS_30
  ball_xvel = 255 : ball_yvel = 254 : return
__BVS_31
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
  if p1_state{0} && !p1_state{1} then ball_state = 1 : p1_catch_timer = 0 : p1_caught_dir = p1_direction : return

  ; Otherwise BOUNCE - maintain current ball speed (temp_dir already set to paddle direction)
  if ball_speed_timer > 0 then gosub __Set_Ball_Velocity : return
  gosub __Set_Ball_Velocity_Slow
  return

__Ball_Bounce_P2
  ; Check if button held AND not in cooldown - CATCH
  if p2_state{0} && !p2_state{1} then ball_state = 2 : p2_catch_timer = 0 : p2_caught_dir = p2_direction : return

  ; Otherwise BOUNCE - maintain current ball speed (temp_dir already set to paddle direction)
  if ball_speed_timer > 0 then gosub __Set_Ball_Velocity : return
  gosub __Set_Ball_Velocity_Slow
  return


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
  ; BRICK DETECTION - ball must actually overlap brick/core area
  ; Core is center 6x10 pixels (X: 5-10, Y: 8-17 relative to sprite)
  ; Bricks surround core: top (Y 0-7), bottom (Y 18-25), left (X 0-4), right (X 11-15)

  ; Y determines top/middle/bottom section (middle expanded +1 up/down)
  if bally + 4 > player0y + 19 then goto __P1_Bottom_Area
  if bally > player0y + 6 then goto __P1_Middle_Area
  goto __P1_Top_Area

__P1_Top_Area
  ; Top brick narrowed - redirect corners to side bricks
  if ballx + 2 <= player0x + 1 then goto __P1_Left_Area
  if ballx >= player0x + 14 then goto __P1_Right_Area
  ; Top brick - if exists, destroy and bounce
  if p1_bricks{0} then p1_bricks{0} = 0 : goto __P1_Brick_Bounce
  ; Top brick destroyed - core only hit if ball X in center AND ball entering core Y
  if bally + 4 < player0y + 8 then return
  if ballx + 2 > player0x + 5 then if ballx < player0x + 11 then goto __P1_Core_Hit
  return

__P1_Middle_Area
  ; X determines left or right side
  if ballx + 2 <= player0x + 7 then goto __P1_Left_Area
  goto __P1_Right_Area

__P1_Left_Area
  ; Left brick - if exists, destroy and bounce
  if p1_bricks{2} then p1_bricks{2} = 0 : goto __P1_Brick_Bounce
  ; Left brick destroyed - core only if ball overlaps core X range
  if ballx + 2 > player0x + 5 then goto __P1_Core_Hit
  return

__P1_Right_Area
  ; Right brick - if exists, destroy and bounce
  if p1_bricks{1} then p1_bricks{1} = 0 : goto __P1_Brick_Bounce
  ; Right brick destroyed - core only if ball overlaps core X range
  if ballx < player0x + 11 then goto __P1_Core_Hit
  return

__P1_Bottom_Area
  ; Bottom brick narrowed - redirect corners to side bricks
  if ballx + 2 <= player0x + 1 then goto __P1_Left_Area
  if ballx >= player0x + 14 then goto __P1_Right_Area
  ; Bottom brick - if exists, destroy and bounce
  if p1_bricks{3} then p1_bricks{3} = 0 : goto __P1_Brick_Bounce
  ; Bottom brick destroyed - core only hit if ball X in center AND ball entering core Y
  if bally > player0y + 17 then return
  if ballx + 2 > player0x + 5 then if ballx < player0x + 11 then goto __P1_Core_Hit
  return

__P1_Core_Hit
  ; Player 1 dies - Player 2 wins the round!
  p2_wins = p2_wins + 1
  if p2_wins = 3 then goto __Game_Over
  ; Hide P1 ship sprite off-screen (player0)
  player0y = 200
  ; Hide P1 paddle off-screen (player2)
  player2y = 200
  ; Start 3-second countdown before round reset
  invincibility_timer = invincibility_duration
  ; Round will reset automatically via __Round_Reset when timer expires
  return

__P1_Brick_Bounce
  ; Bounce the ball back
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ; Push ball away to prevent sticking
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  return


__P2_Brick_Hit

  ; BRICK DETECTION - ball must actually overlap brick/core area
  ; Core is center 6x10 pixels (X: 7-12, Y: 8-17 relative to sprite, +2 offset for P2)
  ; Bricks surround core: top (Y 0-7), bottom (Y 18-25), left (X 2-6), right (X 13-17)

  ; Y determines top/middle/bottom section (middle expanded +1 up/down)
  if bally + 4 > player1y + 19 then goto __P2_Bottom_Area
  if bally > player1y + 6 then goto __P2_Middle_Area
  goto __P2_Top_Area

__P2_Top_Area
  ; Top brick narrowed - redirect corners to side bricks (+2 offset for P2)
  if ballx + 2 <= player1x + 3 then goto __P2_Left_Area
  if ballx >= player1x + 16 then goto __P2_Right_Area
  ; Top brick - if exists, destroy and bounce
  if p2_bricks{0} then p2_bricks{0} = 0 : goto __P2_Brick_Bounce
  ; Top brick destroyed - core only hit if ball X in center AND ball entering core Y
  if bally + 4 < player1y + 8 then return
  if ballx + 2 > player1x + 7 then if ballx < player1x + 13 then goto __P2_Core_Hit
  return

__P2_Middle_Area
  ; X determines left or right side (+2 offset for P2)
  if ballx + 2 <= player1x + 9 then goto __P2_Left_Area
  goto __P2_Right_Area

__P2_Left_Area
  ; Left brick - if exists, destroy and bounce
  if p2_bricks{2} then p2_bricks{2} = 0 : goto __P2_Brick_Bounce
  ; Left brick destroyed - core only if ball overlaps core X range
  if ballx + 2 > player1x + 7 then goto __P2_Core_Hit
  return

__P2_Right_Area
  ; Right brick - if exists, destroy and bounce
  if p2_bricks{1} then p2_bricks{1} = 0 : goto __P2_Brick_Bounce
  ; Right brick destroyed - core only if ball overlaps core X range
  if ballx < player1x + 13 then goto __P2_Core_Hit
  return

__P2_Bottom_Area
  ; Bottom brick narrowed - redirect corners to side bricks (+2 offset for P2)
  if ballx + 2 <= player1x + 3 then goto __P2_Left_Area
  if ballx >= player1x + 16 then goto __P2_Right_Area
  ; Bottom brick - if exists, destroy and bounce
  if p2_bricks{3} then p2_bricks{3} = 0 : goto __P2_Brick_Bounce
  ; Bottom brick destroyed - core only hit if ball X in center AND ball entering core Y
  if bally > player1y + 17 then return
  if ballx + 2 > player1x + 7 then if ballx < player1x + 13 then goto __P2_Core_Hit
  return

__P2_Core_Hit
  ; Player 2 dies - Player 1 wins the round!
  p1_wins = p1_wins + 1
  if p1_wins = 3 then goto __Game_Over
  ; Hide P2 ship sprite off-screen (player1)
  player1y = 200
  ; Hide P2 paddle off-screen (player3)
  player3y = 200
  ; Start 3-second countdown before round reset
  invincibility_timer = invincibility_duration
  ; Round will reset automatically via __Round_Reset when timer expires
  return

__P2_Brick_Bounce
  ; Bounce the ball back
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ; Push ball away to prevent sticking
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  return


  ;***************************************************************
  ;#######################################################################
  ;#######################################################################
  ;
  ;  SECTION: BALL FOLLOW POSITIONING COORDINATE DATA
  ;  All P1 and P2 ball follow positions with X/Y offsets
  ;  Easy to copy between players - just change player0 to player1
  ;
  ;#######################################################################
  ;#######################################################################
  ;  Ball Follow Player - Position ball around paddle based on direction
  ;  Ball positioned just outside paddle sprite radius
  ;***************************************************************
__Ball_Follow_P1
  temp_dir = p1_direction
  on temp_dir goto __BF1_0 __BF1_1 __BF1_2 __BF1_3 __BF1_4 __BF1_5 __BF1_6 __BF1_7 __BF1_8 __BF1_9 __BF1_10 __BF1_11 __BF1_12 __BF1_13 __BF1_14 __BF1_15 __BF1_16 __BF1_17 __BF1_18 __BF1_19 __BF1_20 __BF1_21 __BF1_22 __BF1_23 __BF1_24 __BF1_25 __BF1_26 __BF1_27 __BF1_28 __BF1_29 __BF1_30 __BF1_31

__BF1_0  ; Position 0: paddle (+4, +26)
  ballx = player0x + 10 : bally = player0y + 40 : return
__BF1_1  ; Position 1: paddle (+2, +25)
  ballx = player0x + 6 : bally = player0y + 36 : return
__BF1_2  ; Position 2: paddle (-1, +24)
  ballx = player0x + 0 : bally = player0y + 34 : return
__BF1_3  ; Position 3: paddle (-3, +22)
  ballx = player0x - 4 : bally = player0y + 30 : return
__BF1_4  ; Position 4: paddle (-4, +21)
  ballx = player0x - 5 : bally = player0y + 29 : return
__BF1_5  ; Position 5: paddle (-5, +18)
  ballx = player0x - 7 : bally = player0y + 24 : return
__BF1_6  ; Position 6: paddle (-6, +15)
  ballx = player0x - 7 : bally = player0y + 21 : return
__BF1_7  ; Position 7: paddle (-7, +12)
  ballx = player0x - 7 : bally = player0y + 17 : return
__BF1_8  ; Position 8: paddle (-7, +8)
  ballx = player0x - 7 : bally = player0y + 11 : return
__BF1_9  ; Position 9: paddle (-7, +4)
  ballx = player0x - 7 : bally = player0y + 6 : return
__BF1_10  ; Position 10: paddle (-6, +0)
  ballx = player0x - 7 : bally = player0y + 1 : return
__BF1_11  ; Position 11: paddle (-5, -2)
  ballx = player0x - 5 : bally = player0y - 3 : return
__BF1_12  ; Position 12: paddle (-4, -4)
  ballx = player0x - 3 : bally = player0y - 8 : return
__BF1_13  ; Position 13: paddle (-3, -6)
  ballx = player0x - 4 : bally = player0y - 12 : return
__BF1_14  ; Position 14: paddle (-1, -9)
  ballx = player0x - 2 : bally = player0y - 15 : return
__BF1_15  ; Position 15: paddle (+1, -10)
  ballx = player0x + 3 : bally = player0y - 16 : return
__BF1_16  ; Position 16: paddle (+4, -11)
  ballx = player0x + 8 : bally = player0y - 18 : return
__BF1_17  ; Position 17: paddle (+6, -10)
  ballx = player0x + 11 : bally = player0y - 15 : return
__BF1_18  ; Position 18: paddle (+8, -9)
  ballx = player0x + 13 : bally = player0y - 13 : return
__BF1_19  ; Position 19: paddle (+10, -7)
  ballx = player0x + 17 : bally = player0y - 11 : return
__BF1_20  ; Position 20: paddle (+13, -5)
  ballx = player0x + 20 : bally = player0y - 7 : return
__BF1_21  ; Position 21: paddle (+14, -2)
  ballx = player0x + 22 : bally = player0y - 3 : return
__BF1_22  ; Position 22: paddle (+16, +1)
  ballx = player0x + 26 : bally = player0y + 1 : return
__BF1_23  ; Position 23: paddle (+16, +4)
  ballx = player0x + 26 : bally = player0y + 6 : return
__BF1_24  ; Position 24: paddle (+16, +8)
  ballx = player0x + 26 : bally = player0y + 11 : return
__BF1_25  ; Position 25: paddle (+16, +12)
  ballx = player0x + 26 : bally = player0y + 17 : return
__BF1_26  ; Position 26: paddle (+15, +15)
  ballx = player0x + 26 : bally = player0y + 21 : return
__BF1_27  ; Position 27: paddle (+14, +18)
  ballx = player0x + 22 : bally = player0y + 25 : return
__BF1_28  ; Position 28: paddle (+13, +21)
  ballx = player0x + 20 : bally = player0y + 29 : return
__BF1_29  ; Position 29: paddle (+11, +22)
  ballx = player0x + 15 : bally = player0y + 32 : return
__BF1_30  ; Position 30: paddle (+9, +24)
  ballx = player0x + 13 : bally = player0y + 35 : return
__BF1_31  ; Position 31: paddle (+6, +25)
  ballx = player0x + 8 : bally = player0y + 37 : return

__Ball_Follow_P2
  temp_dir = p2_direction
  on temp_dir goto __BF2_0 __BF2_1 __BF2_2 __BF2_3 __BF2_4 __BF2_5 __BF2_6 __BF2_7 __BF2_8 __BF2_9 __BF2_10 __BF2_11 __BF2_12 __BF2_13 __BF2_14 __BF2_15 __BF2_16 __BF2_17 __BF2_18 __BF2_19 __BF2_20 __BF2_21 __BF2_22 __BF2_23 __BF2_24 __BF2_25 __BF2_26 __BF2_27 __BF2_28 __BF2_29 __BF2_30 __BF2_31

__BF1_0  ; Position 0: paddle (+4, +26)
  ballx = player1x + 10 : bally = player1y + 40 : return
__BF1_1  ; Position 1: paddle (+2, +25)
  ballx = player1x + 6 : bally = player1y + 36 : return
__BF1_2  ; Position 2: paddle (-1, +24)
  ballx = player1x + 0 : bally = player1y + 34 : return
__BF1_3  ; Position 3: paddle (-3, +22)
  ballx = player1x - 4 : bally = player1y + 30 : return
__BF1_4  ; Position 4: paddle (-4, +21)
  ballx = player1x - 5 : bally = player1y + 29 : return
__BF1_5  ; Position 5: paddle (-5, +18)
  ballx = player1x - 7 : bally = player1y + 24 : return
__BF1_6  ; Position 6: paddle (-6, +15)
  ballx = player1x - 7 : bally = player1y + 21 : return
__BF1_7  ; Position 7: paddle (-7, +12)
  ballx = player1x - 7 : bally = player1y + 17 : return
__BF1_8  ; Position 8: paddle (-7, +8)
  ballx = player1x - 7 : bally = player1y + 11 : return
__BF1_9  ; Position 9: paddle (-7, +4)
  ballx = player1x - 7 : bally = player1y + 6 : return
__BF1_10  ; Position 10: paddle (-6, +0)
  ballx = player1x - 7 : bally = player1y + 1 : return
__BF1_11  ; Position 11: paddle (-5, -2)
  ballx = player1x - 5 : bally = player1y - 3 : return
__BF1_12  ; Position 12: paddle (-4, -4)
  ballx = player1x - 3 : bally = player1y - 8 : return
__BF1_13  ; Position 13: paddle (-3, -6)
  ballx = player1x - 4 : bally = player1y - 12 : return
__BF1_14  ; Position 14: paddle (-1, -9)
  ballx = player1x - 2 : bally = player1y - 15 : return
__BF1_15  ; Position 15: paddle (+1, -10)
  ballx = player1x + 3 : bally = player1y - 16 : return
__BF1_16  ; Position 16: paddle (+4, -11)
  ballx = player1x + 8 : bally = player1y - 18 : return
__BF1_17  ; Position 17: paddle (+6, -10)
  ballx = player1x + 11 : bally = player1y - 15 : return
__BF1_18  ; Position 18: paddle (+8, -9)
  ballx = player1x + 13 : bally = player1y - 13 : return
__BF1_19  ; Position 19: paddle (+10, -7)
  ballx = player1x + 17 : bally = player1y - 11 : return
__BF1_20  ; Position 20: paddle (+13, -5)
  ballx = player1x + 20 : bally = player1y - 7 : return
__BF1_21  ; Position 21: paddle (+14, -2)
  ballx = player1x + 22 : bally = player1y - 3 : return
__BF1_22  ; Position 22: paddle (+16, +1)
  ballx = player1x + 26 : bally = player1y + 1 : return
__BF1_23  ; Position 23: paddle (+16, +4)
  ballx = player1x + 26 : bally = player1y + 6 : return
__BF1_24  ; Position 24: paddle (+16, +8)
  ballx = player1x + 26 : bally = player1y + 11 : return
__BF1_25  ; Position 25: paddle (+16, +12)
  ballx = player1x + 26 : bally = player1y + 17 : return
__BF1_26  ; Position 26: paddle (+15, +15)
  ballx = player1x + 26 : bally = player1y + 21 : return
__BF1_27  ; Position 27: paddle (+14, +18)
  ballx = player1x + 22 : bally = player1y + 25 : return
__BF1_28  ; Position 28: paddle (+13, +21)
  ballx = player1x + 20 : bally = player1y + 29 : return
__BF1_29  ; Position 29: paddle (+11, +22)
  ballx = player1x + 15 : bally = player1y + 32 : return
__BF1_30  ; Position 30: paddle (+9, +24)
  ballx = player1x + 13 : bally = player1y + 35 : return
__BF1_31  ; Position 31: paddle (+6, +25)
  ballx = player1x + 8 : bally = player1y + 37 : return


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
  p1_catch_timer = 0  ; Reset timer (important to prevent repeated calls)
  p1_state{1} = 1  ; Set cooldown flag
  return

__P2_Auto_Launch
  gosub __P2_Launch_Ball
  p2_catch_timer = 0  ; Reset timer (important to prevent repeated calls)
  p2_state{1} = 1  ; Set cooldown flag
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
  player0x = 25 : player0y = 40
  p1_bricks = %00001111
  p1_direction = 24
  p1_speed_x = 16 : p1_speed_y = 16
  p1_dir_x = 0 : p1_dir_y = 0
  p1_frame_x = p1_speed_x : p1_frame_y = p1_speed_y

  ; Reset Player 2
  player1x = 117 : player1y = 40
  p2_bricks = %00001111
  p2_direction = 8
  p2_speed_x = 16 : p2_speed_y = 16
  p2_dir_x = 0 : p2_dir_y = 0
  p2_frame_x = p2_speed_x : p2_frame_y = p2_speed_y

  ; Reset ball to center
  ballx = 80 : bally = 88
  ball_state = 0
  temp_dir = (rand & 31)
  gosub __Set_Ball_Velocity_Slow

  ; Reset timers
  ball_speed_timer = 0
  p1_catch_timer = 0 : p2_catch_timer = 0
  p1_state = 0 : p2_state = 0
  invincibility_timer = 0

  return


  ;***************************************************************
  ;***************************************************************
  ;  SCORE SYSTEM - BCD Award Functions
  ;  Scores display automatically at top via built-in PXE!
  ;  Format: P1 (blue) | separator | P2 (purple)
  ;***************************************************************
__Award_P1_Point
  ; Increment P1 score (BCD: 00-99)
  temp1 = p1_score & $0F          ; Get ones digit
  if temp1 = 9 then p1_score = p1_score + 7  ; Skip $0A-$0F in BCD
  p1_score = p1_score + 1
  return

__Award_P2_Point
  ; Increment P2 score (BCD: 00-99)
  temp1 = p2_score & $0F          ; Get ones digit
  if temp1 = 9 then p2_score = p2_score + 7  ; Skip $0A-$0F in BCD
  p2_score = p2_score + 1
  return

__Game_Over
  ; Game over - someone reached 3 wins
  ; For now, just freeze the game (could add reset later)
  goto __Game_Over


  ;#######################################################################
  ;#######################################################################
  ;
  ;  SECTION: COORDINATE REFERENCE - PADDLE & BALL POSITIONS
  ;  Quick reference for all X/Y offsets (32 positions each)
  ;  To edit: Find the position number, note offsets, then search
  ;  for that position in the subroutines below to modify
  ;
  ;#######################################################################
  ;#######################################################################
  ;
  ;  P1 PADDLE OFFSETS (relative to player0x/player0y):
  ;  Pos  0: X+4  Y+28  |  Pos  1: X+2  Y+26  |  Pos  2: X-1  Y+24  |  Pos  3: X-3  Y+22
  ;  Pos  4: X-5  Y+21  |  Pos  5: X-6  Y+18  |  Pos  6: X-8  Y+15  |  Pos  7: X-8  Y+12
  ;  Pos  8: X-8  Y+8   |  Pos  9: X-8  Y+4   |  Pos 10: X-8  Y+1   |  Pos 11: X-6  Y-2
  ;  Pos 12: X-5  Y-5   |  Pos 13: X-4  Y-7   |  Pos 14: X-2  Y-9   |  Pos 15: X+1  Y-10
  ;  Pos 16: X+4  Y-11  |  Pos 17: X+6  Y-10  |  Pos 18: X+8  Y-9   |  Pos 19: X+10 Y-7
  ;  Pos 20: X+13 Y-5   |  Pos 21: X+14 Y-2   |  Pos 22: X+16 Y+1   |  Pos 23: X+16 Y+4
  ;  Pos 24: X+16 Y+8   |  Pos 25: X+16 Y+12  |  Pos 26: X+16 Y+15  |  Pos 27: X+14 Y+18
  ;  Pos 28: X+13 Y+21  |  Pos 29: X+11 Y+22  |  Pos 30: X+9  Y+24  |  Pos 31: X+6  Y+26
  ;
  ;  P1 BALL FOLLOW OFFSETS (relative to player0x/player0y) - SMOOTHED:
  ;  Pos  0: X+10 Y+40  |  Pos  1: X+6  Y+36  |  Pos  2: X+0  Y+34  |  Pos  3: X-4  Y+30
  ;  Pos  4: X-5  Y+29  |  Pos  5: X-7  Y+24  |  Pos  6: X-7  Y+21  |  Pos  7: X-7  Y+17
  ;  Pos  8: X-7  Y+11  |  Pos  9: X-7  Y+6   |  Pos 10: X-7  Y+1   |  Pos 11: X-5  Y-3
  ;  Pos 12: X-3  Y-8   |  Pos 13: X-4  Y-12  |  Pos 14: X-2  Y-15  |  Pos 15: X+3  Y-16
  ;  Pos 16: X+8  Y-18  |  Pos 17: X+11 Y-15  |  Pos 18: X+13 Y-13  |  Pos 19: X+17 Y-11
  ;  Pos 20: X+20 Y-7   |  Pos 21: X+22 Y-3   |  Pos 22: X+26 Y+1   |  Pos 23: X+26 Y+6
  ;  Pos 24: X+26 Y+11  |  Pos 25: X+26 Y+17  |  Pos 26: X+26 Y+21  |  Pos 27: X+22 Y+25
  ;  Pos 28: X+20 Y+29  |  Pos 29: X+15 Y+32  |  Pos 30: X+13 Y+35  |  Pos 31: X+8  Y+37
  ;
  ;  P2 PADDLE OFFSETS (relative to player1x/player1y):
  ;  Same as P1 - just copy P1 section and replace player0 with player1
  ;
  ;  P2 BALL FOLLOW OFFSETS (relative to player1x/player1y):
  ;  Same as P1 - just copy P1 section and replace player0 with player1
  ;
  ;#######################################################################
  ;#######################################################################
  ;
  ;  SECTION: PADDLE POSITIONING SUBROUTINES
  ;  All P1 and P2 paddle positions with graphics and coordinates
  ;  Easy to copy between players - just change player0 to player1
  ;
  ;#######################################################################
  ;#######################################################################
  ;***************************************************************
  ;  Update Player 1 Paddle Position
  ;  temp_dir contains current direction (0-31)
  ;  Paddle dial: 0=South(bottom), 8=West, 16=North(top), 24=East
  ;  User manually set cardinal positions, interpolated intermediate
  ;  All positions use same sprite (rounded bar)
  ;***************************************************************
__Update_P1_Paddle
  on temp_dir goto __P1P_0 __P1P_1 __P1P_2 __P1P_3 __P1P_4 __P1P_5 __P1P_6 __P1P_7 __P1P_8 __P1P_9 __P1P_10 __P1P_11 __P1P_12 __P1P_13 __P1P_14 __P1P_15 __P1P_16 __P1P_17 __P1P_18 __P1P_19 __P1P_20 __P1P_21 __P1P_22 __P1P_23 __P1P_24 __P1P_25 __P1P_26 __P1P_27 __P1P_28 __P1P_29 __P1P_30 __P1P_31

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

; Direction 1: Midpoint 0→1
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
  player2x = player0x + 2 : player2y = player0y + 26
  return

; Direction 2: Original position
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
  player2x = player0x - 1 : player2y = player0y + 24
  return

; Direction 3: Midpoint 2→4
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
  player2x = player0x - 3 : player2y = player0y + 22
  return

; Direction 4: Original position
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
  player2x = player0x - 5 : player2y = player0y + 21
  return

; Direction 5: Midpoint 4→6
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
  player2x = player0x - 6 : player2y = player0y + 18
  return

; Direction 6: Original position
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
  player2x = player0x - 8 : player2y = player0y + 15
  return

; Direction 7: Midpoint 6→8
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
  player2x = player0x - 8 : player2y = player0y + 12
  return

; Direction 8: Original position (West)
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
  player2x = player0x - 8 : player2y = player0y + 8
  return

; Direction 9: Midpoint 8→10
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
  player2x = player0x - 8 : player2y = player0y + 4
  return

; Direction 10: Original position
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
  player2x = player0x - 8 : player2y = player0y + 1
  return

; Direction 11: Midpoint 10→12
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
  player2x = player0x - 6 : player2y = player0y - 2
  return

; Direction 12: Original position
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
  player2x = player0x - 5 : player2y = player0y - 5
  return

; Direction 13: Midpoint 12→14
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
  player2x = player0x - 4 : player2y = player0y - 7
  return

; Direction 14: Original position
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
  player2x = player0x - 2 : player2y = player0y - 9
  return

; Direction 15: Midpoint 14→16
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
  player2x = player0x + 1 : player2y = player0y - 10
  return

; Direction 16: Original position (North)
__P1P_16
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
; Direction 17: Midpoint 16→18
__P1P_17
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
  player2x = player0x + 6 : player2y = player0y - 10
  return
; Direction 18: Original position
__P1P_18
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
; Direction 19: Midpoint 18→20
__P1P_19
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
  player2x = player0x + 10 : player2y = player0y - 7
  return
; Direction 20: Original position
__P1P_20
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
; Direction 21: Midpoint 20→22
__P1P_21
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
  player2x = player0x + 14 : player2y = player0y - 2
  return
; Direction 22: Original position
__P1P_22
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
; Direction 23: Midpoint 22→24
__P1P_23
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
  player2x = player0x + 16 : player2y = player0y + 4
  return
; Direction 24: Original position (East)
__P1P_24
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
; Direction 25: Midpoint 24→26
__P1P_25
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
  player2x = player0x + 16 : player2y = player0y + 12
  return
; Direction 26: Original position
__P1P_26
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
; Direction 27: Midpoint 26→28
__P1P_27
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
  player2x = player0x + 14 : player2y = player0y + 18
  return
; Direction 28: Original position
__P1P_28
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
; Direction 29: Midpoint 28→30
__P1P_29
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
  player2x = player0x + 11 : player2y = player0y + 22
  return
; Direction 30: Original position
__P1P_30
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
; Direction 31: Midpoint 30→0
__P1P_31
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
  player2x = player0x + 6 : player2y = player0y + 26
  return


  ;***************************************************************
  ;  Update Player 2 Paddle Position
  ;  temp_dir contains current direction (0-15)
  ;  Paddle dial: 0=South(bottom), 4=West, 8=North(top), 12=East
  ;  Same offsets as Player 1, same sprite
  ;***************************************************************
__Update_P2_Paddle
  on temp_dir goto __P2P_0 __P2P_1 __P2P_2 __P2P_3 __P2P_4 __P2P_5 __P2P_6 __P2P_7 __P2P_8 __P2P_9 __P2P_10 __P2P_11 __P2P_12 __P2P_13 __P2P_14 __P2P_15 __P2P_16 __P2P_17 __P2P_18 __P2P_19 __P2P_20 __P2P_21 __P2P_22 __P2P_23 __P2P_24 __P2P_25 __P2P_26 __P2P_27 __P2P_28 __P2P_29 __P2P_30 __P2P_31

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

; Direction 1: Midpoint 0→2
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
  player3x = player1x + 2 : player3y = player1y + 26
  return

; Direction 2: Original position
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
  player3x = player1x - 1 : player3y = player1y + 24
  return

; Direction 3: Midpoint 2→4
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
  player3x = player1x - 3 : player3y = player1y + 22
  return

; Direction 4: Original position
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
  player3x = player1x - 5 : player3y = player1y + 21
  return

; Direction 5: Midpoint 4→6
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
  player3x = player1x - 6 : player3y = player1y + 18
  return

; Direction 6: Original position
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
  player3x = player1x - 8 : player3y = player1y + 15
  return

; Direction 7: Midpoint 6→8
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
  player3x = player1x - 8 : player3y = player1y + 12
  return

; Direction 8: Original position (West)
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
  player3x = player1x - 8 : player3y = player1y + 8
  return

; Direction 9: Midpoint 8→10
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
  player3x = player1x - 8 : player3y = player1y + 4
  return

; Direction 10: Original position
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
  player3x = player1x - 8 : player3y = player1y + 1
  return

; Direction 11: Midpoint 10→12
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
  player3x = player1x - 6 : player3y = player1y - 2
  return

; Direction 12: Original position
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
  player3x = player1x - 5 : player3y = player1y - 5
  return

; Direction 13: Midpoint 12→14
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
  player3x = player1x - 4 : player3y = player1y - 7
  return

; Direction 14: Original position
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
  player3x = player1x - 2 : player3y = player1y - 9
  return

; Direction 15: Midpoint 14→16
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
  player3x = player1x + 1 : player3y = player1y - 10
  return

; Direction 16: Original position (North)
__P2P_16
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
  player3x = player1x + 4 : player3y = player1y - 11
  return
; Direction 17: Midpoint 16→18
__P2P_17
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
  player3x = player1x + 6 : player3y = player1y - 10
  return
; Direction 18: Original position
__P2P_18
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
  player3x = player1x + 8 : player3y = player1y - 9
  return
; Direction 19: Midpoint 18→20
__P2P_19
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
  player3x = player1x + 10 : player3y = player1y - 7
  return
; Direction 20: Original position
__P2P_20
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
  player3x = player1x + 13 : player3y = player1y - 5
  return
; Direction 21: Midpoint 20→22
__P2P_21
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
  player3x = player1x + 14 : player3y = player1y - 2
  return
; Direction 22: Original position
__P2P_22
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
  player3x = player1x + 16 : player3y = player1y + 1
  return
; Direction 23: Midpoint 22→24
__P2P_23
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
  player3x = player1x + 16 : player3y = player1y + 4
  return
; Direction 24: Original position (East)
__P2P_24
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
  player3x = player1x + 16 : player3y = player1y + 8
  return
; Direction 25: Midpoint 24→26
__P2P_25
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
  player3x = player1x + 16 : player3y = player1y + 12
  return
; Direction 26: Original position
__P2P_26
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
  player3x = player1x + 16 : player3y = player1y + 15
  return
; Direction 27: Midpoint 26→28
__P2P_27
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
  player3x = player1x + 14 : player3y = player1y + 18
  return
; Direction 28: Original position
__P2P_28
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
  player3x = player1x + 13 : player3y = player1y + 21
  return
; Direction 29: Midpoint 28→30
__P2P_29
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
  player3x = player1x + 11 : player3y = player1y + 22
  return
; Direction 30: Original position
__P2P_30
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
  player3x = player1x + 9 : player3y = player1y + 24
  return
; Direction 31: Midpoint 30→0
__P2P_31
  player3:
  %011110
  %111111
  ;#######################################################################
  ;#######################################################################
  ;
  ;  SECTION: SHIP SPRITE GRAPHICS (Animation Frames)
  ;  All ship destruction states for P1 and P2
  ;  16 states each showing progressive brick destruction
  ;
  ;#######################################################################
  ;#######################################################################
  %111111
  %111111
  %111111
  %111111
  %111111
  %111111
  %011110
end
  player3x = player1x + 6 : player3y = player1y + 26
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

; State 0: All bricks destroyed - core still visible
__P1S_0
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000  ; Upper connector (both sides gone)
  %00000000
  %00011000  ; Core visible (both left/right destroyed)
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (both sides gone)
  %00000000
  %00000000  ; Bottom brick destroyed
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
; State 14: Top brick destroyed (%1110)
__P1S_14
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

; State 13: Right brick destroyed (%1101 - bit 1 clear after swap)
__P1S_13
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000000  ; Upper connector (right side gone)
  %11000000
  %11011000  ; Left intact, right brick gone
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (right side gone)
  %11000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 11: Left brick destroyed (%1011 - bit 2 clear after swap)
__P1S_11
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000011  ; Upper connector (left side gone)
  %00000011
  %00011011  ; Left brick gone, right intact
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (left side gone)
  %00000011
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 7: Bottom brick destroyed (%0111)
__P1S_7
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000011  ; Upper connector
  %11000011
  %11011011  ; Middle section intact
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011  ; Lower connector
  %11000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; Multi-brick destroyed states
; State 12: Left AND bottom intact (%1100 - top/right destroyed, bit 2 set after swap)
__P1S_12
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000000  ; Upper connector (left gone)
  %11000000
  %11011000  ; Left destroyed, right intact
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (left gone)
  %11000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 10: Right AND bottom intact (%1010 - top/left destroyed, bit 1 set after swap)
__P1S_10
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000011  ; Upper connector (right gone)
  %00000011
  %00011011  ; Left intact, right destroyed
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (right gone)
  %00000011
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 9: Top AND bottom intact (%1001 - left/right destroyed)
__P1S_9
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000000  ; Upper connector (both sides gone)
  %00000000
  %00011000  ; Both left/right destroyed (core only)
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (both sides gone)
  %00000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 8: Only bottom intact (%1000 - top/left/right destroyed)
__P1S_8
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000  ; Upper connector (all gone)
  %00000000
  %00011000  ; Core only
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (all gone)
  %00000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 6: Left AND right intact (%0110 - top/bottom destroyed)
__P1S_6
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000011  ; Upper connector
  %11000011
  %11011011  ; Both left/right intact
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011  ; Lower connector
  %11000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 5: Top AND left intact (%0101 - right/bottom destroyed, bit 2 set after swap)
__P1S_5
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000000  ; Upper connector (left gone)
  %11000000
  %11011000  ; Left destroyed, right intact
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (left gone)
  %11000000
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 4: Only left intact (%0100 - top/right/bottom destroyed, bit 2 set after swap)
__P1S_4
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000000  ; Upper connector (left gone)
  %11000000
  %11011000  ; Left destroyed, right intact
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (left gone)
  %11000000
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 3: Top AND right intact (%0011 - left/bottom destroyed, bit 1 set after swap)
__P1S_3
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000011  ; Upper connector (right gone)
  %00000011
  %00011011  ; Left intact, right destroyed
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (right gone)
  %00000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 2: Only right intact (%0010 - top/left/bottom destroyed, bit 1 set after swap)
__P1S_2
  player0:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000011  ; Upper connector (right gone)
  %00000011
  %00011011  ; Left intact, right destroyed
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (right gone)
  %00000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 1: Only top intact (%0001 - left/right/bottom destroyed)
__P1S_1
  player0:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000000  ; Upper connector (both sides gone)
  %00000000
  %00011000  ; Core only (both left/right destroyed)
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (both sides gone)
  %00000000
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return


__Update_P2_Ship_Sprite
  ; p2_bricks contains 4 bits representing brick state
  temp_dir = p2_bricks & %00001111
  on temp_dir goto __P2S_0 __P2S_1 __P2S_2 __P2S_3 __P2S_4 __P2S_5 __P2S_6 __P2S_7 __P2S_8 __P2S_9 __P2S_10 __P2S_11 __P2S_12 __P2S_13 __P2S_14 __P2S_15

; State 0: All bricks destroyed - core still visible
__P2S_0
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000  ; Upper connector (both sides gone)
  %00000000
  %00011000  ; Core visible (both left/right destroyed)
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (both sides gone)
  %00000000
  %00000000  ; Bottom brick destroyed
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

; State 14: Top brick destroyed (%1110)
__P2S_14
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

; Other states - use default for now
; State 13: Right brick destroyed (%1101)
__P2S_13
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000000  ; Upper connector (right side gone)
  %11000000
  %11011000  ; Left intact, right brick gone
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (right side gone)
  %11000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 11: Left brick destroyed (%1011)
__P2S_11
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000011  ; Upper connector (left side gone)
  %00000011
  %00011011  ; Left brick gone, right intact
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (left side gone)
  %00000011
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 7: Bottom brick destroyed (%0111)
__P2S_7
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000011  ; Upper connector
  %11000011
  %11011011  ; Middle section intact
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011  ; Lower connector
  %11000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; Multi-brick destroyed states
; State 12: Left AND bottom intact (%1100 - top/right destroyed)
__P2S_12
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000000  ; Upper connector (left gone)
  %11000000
  %11011000  ; Left destroyed, right intact
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (left gone)
  %11000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 10: Right AND bottom intact (%1010 - top/left destroyed)
__P2S_10
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000011  ; Upper connector (right gone)
  %00000011
  %00011011  ; Left intact, right destroyed
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (right gone)
  %00000011
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 9: Top AND bottom intact (%1001 - left/right destroyed)
__P2S_9
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000000  ; Upper connector (both sides gone)
  %00000000
  %00011000  ; Both left/right destroyed (core only)
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (both sides gone)
  %00000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 8: Only bottom intact (%1000 - top/left/right destroyed)
__P2S_8
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000  ; Upper connector (all gone)
  %00000000
  %00011000  ; Core only
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (all gone)
  %00000000
  %00111100  ; Bottom brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
end
  return

; State 6: Left AND right intact (%0110 - top/bottom destroyed)
__P2S_6
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000011  ; Upper connector
  %11000011
  %11011011  ; Both left/right intact
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11011011
  %11000011  ; Lower connector
  %11000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 5: Top AND left intact (%0101 - right/bottom destroyed)
__P2S_5
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %11000000  ; Upper connector (left gone)
  %11000000
  %11011000  ; Left destroyed, right intact
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (left gone)
  %11000000
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 4: Only left intact (%0100 - top/right/bottom destroyed)
__P2S_4
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %11000000  ; Upper connector (left gone)
  %11000000
  %11011000  ; Left destroyed, right intact
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11011000
  %11000000  ; Lower connector (left gone)
  %11000000
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 3: Top AND right intact (%0011 - left/bottom destroyed)
__P2S_3
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000011  ; Upper connector (right gone)
  %00000011
  %00011011  ; Left intact, right destroyed
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (right gone)
  %00000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 2: Only right intact (%0010 - top/left/bottom destroyed)
__P2S_2
  player1:
  %00000000  ; Top brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000011  ; Upper connector (right gone)
  %00000011
  %00011011  ; Left intact, right destroyed
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00011011
  %00000011  ; Lower connector (right gone)
  %00000011
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return

; State 1: Only top intact (%0001 - left/right/bottom destroyed)
__P2S_1
  player1:
  %00111100  ; Top brick intact
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00111100
  %00000000  ; Upper connector (both sides gone)
  %00000000
  %00011000  ; Core only (both left/right destroyed)
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000  ; Lower connector (both sides gone)
  %00000000
  %00000000  ; Bottom brick destroyed
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
end
  return


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


  ;#######################################################################
  ;#######################################################################
  ;
  ;  SECTION: SCORE COLORS
  ;  6 scorecolors blocks for gradient score display
  ;  Format: P1 (blue gradient) | separator (black) | P2 (purple gradient)
  ;
  ;#######################################################################
  ;#######################################################################

; Digit 0 (P1 tens - Blue gradient)
  scorecolors:
  $8E
  $8C
  $8A
  $8A
  $88
  $88
  $86
  $86
end

; Digit 1 (P1 ones - Blue gradient)
  scorecolors:
  $8E
  $8C
  $8A
  $8A
  $88
  $88
  $86
  $86
end

; Digit 2 (Separator tens - Black/off)
  scorecolors:
  $00
  $00
  $00
  $00
  $00
  $00
  $00
  $00
end

; Digit 3 (Separator ones - Black/off)
  scorecolors:
  $00
  $00
  $00
  $00
  $00
  $00
  $00
  $00
end

; Digit 4 (P2 tens - Purple gradient)
  scorecolors:
  $6E
  $6C
  $6A
  $6A
  $68
  $68
  $66
  $66
end

; Digit 5 (P2 ones - Purple gradient)
  scorecolors:
  $6E
  $6C
  $6A
  $6A
  $68
  $68
  $66
  $66
end
