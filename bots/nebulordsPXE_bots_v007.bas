  ;***************************************************************
  ;  NEBULORDS PXE - BOTS Version 007
  ;  Warlords-style Space Combat with Paddle Controls
  ;  4-PLAYER MODE: 1 Human vs 3 AI Bots
  ;
  ;  Based on: bots_v006 (Fix sprite display issues)
  ;
  ;  Changes from bots_v006:
  ;  - FIX: Add player4color and player5color for paddles
  ;  - FIX: Remove duplicate/conflicting sprite definitions
  ;  - FIX: Ensure paddle update functions are called in main loop
  ;  - FIX: P3/P4 collision detection
  ;***************************************************************
  ;  - ADD: Physics variables for P3 and P4
  ;  - ADD: AI variables for P3 and P4 (same smart system as P2)
  ;  - ADD: Ball catching for P3 and P4 (ball_state 3 and 4)
  ;  - SCALE: All collision, physics, and AI logic to 4 players
  ;
  ;  Player Layout:
  ;  P1 (Human):  Top Left,     Red,    player0 sprite
  ;  P2 (Bot):    Top Right,    Blue,   player1 sprite
  ;  P3 (Bot):    Bottom Left,  Orange, player4 sprite
  ;  P4 (Bot):    Bottom Right, Green,  player5 sprite
  ;
  ;  AI Behavior (All bots use v005 intelligence):
  ;  - 16-direction aiming for accuracy
  ;  - Smart shooting (aims at nearest opponent when holding ball)
  ;  - Random launch timing (2-4 seconds)
  ;  - 5% wander + ±1 noise (organic "swatting" feel)
  ;
  ;  Changes from v096:
  ;  - FIX: Score display properly shows _0000_ format with blank spaces
  ;  - FIX: Score awards now CAP at 9 (not wrap to 0)
  ;  - FIX: Score positioned at bottom of screen (pfscore = 2)
  ;  - FIX: Added scorecolors gradient for visibility
  ;
  ;  Changes from v095:
  ;  - OPTIMIZE: Consolidate timer updates in main loop (6 lines reduced to 4)
  ;  - ADD: 4-player score display format (_0000_ for P1-P4)
  ;  - CHANGE: Score variables now use score_byte0/1/2 format
  ;  - PREP: Score system ready for 4-player expansion
  ;
  ;  Changes from v094:
  ;  - OPTIMIZE: Move sprite updates OUT of main loop
  ;  - CHANGE: Sprites now update only when brick state changes
  ;  - ADD: Sprite updates in __P1_Brick_Bounce, __P2_Brick_Bounce, __Round_Reset
  ;  - REMOVE: Unconditional sprite updates from main loop (2 gosub calls removed)
  ;  - Architecture improvement: Conditional updates reduce unnecessary processing
  ;
  ;  Changes from v092:
  ;  - REFACTOR: Shared physics functions to reduce code duplication
  ;  - ADD: Load/Store context functions for player physics state
  ;  - CONSOLIDATE: Single thrust, acceleration, movement functions (not per-player)
  ;  - ADD: Temp variables for shared physics processing
  ;  - Code reduction: ~180 lines removed via function sharing
  ;
  ;  Changes from v077:
  ;  - FIX: Ball position 16 (North/top) extended 2 pixels (Y-15 to Y-17)
  ;  - FIX: Held ball immunity - players immune when ball held (prevents sword attacks)
  ;  - Ball only damages ships when free-floating (ball_state = 0)
  ;
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

  ; Enable PXE score display (pfscore = 2 for bottom display)
  const pfscore = 2
  const font = retroputer

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

  ; Player 3 (AI Bot) - Physics (7 vars per player)
  dim p3_direction = var17
  dim p3_speed_x = var18         ; Frames between X moves
  dim p3_speed_y = var19         ; Frames between Y moves
  dim p3_frame_x = var20         ; Frame counter for X movement
  dim p3_frame_y = var21         ; Frame counter for Y movement
  dim p3_dir_x = var22           ; X direction
  dim p3_dir_y = var23           ; Y direction

  ; Player 4 (AI Bot) - Physics (7 vars per player)
  dim p4_direction = var24
  dim p4_speed_x = var25         ; Frames between X moves
  dim p4_speed_y = var26         ; Frames between Y moves
  dim p4_frame_x = var27         ; Frame counter for X movement
  dim p4_frame_y = var28         ; Frame counter for Y movement
  dim p4_dir_x = var29           ; X direction
  dim p4_dir_y = var30           ; Y direction

  ; Shared
  dim accel_counter = p          ; Frame counter for acceleration delay

  ; Temp variables
  dim temp_paddle = q
  dim temp_dir = r

  ; Shared physics temp variables (for refactored functions)
  dim temp_speed_x = var7
  dim temp_speed_y = var8
  dim temp_frame_x = var9
  dim temp_frame_y = var10
  dim temp_dir_x = var11
  dim temp_dir_y = var12
  dim temp_player_num = var13        ; 0=P1, 1=P2

  ; Ball
  dim ball_xvel = s
  dim ball_yvel = t
  dim ball_state = u             ; 0=free, 1=P1, 2=P2, 3=P3, 4=P4
  dim ball_speed_timer = v       ; Countdown for fast mode duration
  dim p1_catch_timer = w         ; Countdown for auto-launch (counts up 0-240)
  dim p2_catch_timer = x         ; Countdown for auto-launch
  dim p1_state = y               ; bit 0=button held, bit 1=cooldown active
  dim p2_state = z               ; bit 0=button held, bit 1=cooldown active
  dim p3_catch_timer = var31     ; P3 catch timer
  dim p4_catch_timer = var32     ; P4 catch timer
  dim p3_state = var33           ; P3 AI state (for thrust/catch)
  dim p4_state = var34           ; P4 AI state (for thrust/catch)

  ; Brick/Shield state (PXE extra variables)
  dim p1_bricks = var0           ; bit 0=top, bit 1=left, bit 2=right, bit 3=bottom (1=intact)
  dim p2_bricks = var1           ; bit 0=top, bit 1=left, bit 2=right, bit 3=bottom (1=intact)
  dim p3_bricks = var2           ; P3 brick state
  dim p4_bricks = var3           ; P4 brick state

  ; REPLACED - SEE BELOW
  ;***************************************************************
  ;  SCORE SYSTEM - 4-Player Format (v098)
  ;  Format: score+2  score+1  score+0 = 6 BCD digits
  ;  Display: "_0000_" (blank, P1, P2, P3, P4, blank)
  ;
  ;  MATCHES test_4player_score_v3.bas EXACTLY:
  ;  score_byte0 = score+2 (displays leftmost)
  ;  score_byte1 = score+1 (displays middle)
  ;  score_byte2 = score (displays rightmost)
  ;
  ;  score = $A0: blank (upper nibble) + P1 score (lower nibble) = _0
  ;  score+1 = $00: P2 score (upper nibble) + P3 score (lower nibble) = 00
  ;  score+2 = $0A: P4 score (upper nibble) + blank (lower nibble) = 0_
  ;***************************************************************
  dim score_byte0 = score+2      ; P4 score (upper) + blank (lower) [displays leftmost]
  dim score_byte1 = score+1      ; P2 score (upper) + P3 score (lower) [displays middle]
  dim score_byte2 = score         ; Blank (upper) + P1 score (lower) [displays rightmost]
  dim invincibility_timer = var4 ; Countdown for invincibility
  dim p1_caught_dir = var5       ; P1 paddle direction when ball caught
  dim p2_caught_dir = var6       ; P2 paddle direction when ball caught
  dim p3_caught_dir = var35      ; P3 paddle direction when ball caught
  dim p4_caught_dir = var36      ; P4 paddle direction when ball caught

  ;***************************************************************
  ;  AI BOT VARIABLES - Player 2
  ;***************************************************************
  dim ai_p2_target_direction = var14 ; Where P2 AI wants to point (0-31)
  dim ai_p2_update_timer = var15     ; Countdown until next target update
  dim ai_p2_action_timer = var16     ; Countdown for action decisions

  ;***************************************************************
  ;  AI BOT VARIABLES - Player 3
  ;***************************************************************
  dim ai_p3_target_direction = var37 ; Where P3 AI wants to point (0-31)
  dim ai_p3_update_timer = var38     ; Countdown until next target update
  dim ai_p3_action_timer = var39     ; Countdown for action decisions

  ;***************************************************************
  ;  AI BOT VARIABLES - Player 4
  ;***************************************************************
  dim ai_p4_target_direction = var40 ; Where P4 AI wants to point (0-31)
  dim ai_p4_update_timer = var41     ; Countdown until next target update
  dim ai_p4_action_timer = var42     ; Countdown for action decisions
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

  ; Enable double-width sprites for ships (player0-3)
  NUSIZ0 = $05   ; P1 ship
  _NUSIZ1 = $05  ; P2 ship
  NUSIZ2 = $05   ; P3 ship
  NUSIZ3 = $05   ; P4 ship

  ; Single-width for paddles (player4-5)
  NUSIZ4 = $00   ; P1 paddle
  NUSIZ5 = $00   ; P2 paddle

  ; Initialize ship positions (4-player layout)
  player0x = 25 : player0y = 40    ; P1 ship: Top-left (red)
  player1x = 117 : player1y = 40   ; P2 ship: Top-right (blue)
  player2x = 25 : player2y = 136   ; P3 ship: Bottom-left (orange)
  player3x = 117 : player3y = 136  ; P4 ship: Bottom-right (green)

  ; Initialize ship directions
  p1_direction = 24  ; Facing right (toward center)
  p2_direction = 8   ; Facing left (toward center)
  p3_direction = 16  ; Facing up (toward center)
  p4_direction = 16  ; Facing up (toward center)

  ; Initialize P1 physics - start stationary
  p1_speed_x = 16 : p1_speed_y = 16
  p1_dir_x = 0 : p1_dir_y = 0
  p1_frame_x = p1_speed_x : p1_frame_y = p1_speed_y

  ; Initialize P2 physics - start stationary
  p2_speed_x = 16 : p2_speed_y = 16
  p2_dir_x = 0 : p2_dir_y = 0
  p2_frame_x = p2_speed_x : p2_frame_y = p2_speed_y

  ; Initialize P3 physics - start stationary
  p3_speed_x = 16 : p3_speed_y = 16
  p3_dir_x = 0 : p3_dir_y = 0
  p3_frame_x = p3_speed_x : p3_frame_y = p3_speed_y

  ; Initialize P4 physics - start stationary
  p4_speed_x = 16 : p4_speed_y = 16
  p4_dir_x = 0 : p4_dir_y = 0
  p4_frame_x = p4_speed_x : p4_frame_y = p4_speed_y

  ; Acceleration counter
  accel_counter = 0

  ; Initialize catching system (4 players)
  ball_state = 0             ; Ball starts free
  ball_speed_timer = 0       ; No fast mode at start
  p1_catch_timer = 0 : p2_catch_timer = 0 : p3_catch_timer = 0 : p4_catch_timer = 0
  p1_state = 0 : p2_state = 0 : p3_state = 0 : p4_state = 0

  ; Initialize brick states - all intact (bits 0-3 set)
  p1_bricks = %00001111      ; Top, Left, Right, Bottom all intact
  p2_bricks = %00001111      ; Top, Left, Right, Bottom all intact
  p3_bricks = %00001111      ; Top, Left, Right, Bottom all intact
  p4_bricks = %00001111      ; Top, Left, Right, Bottom all intact

  ; Initialize scores - 4-player format (v098): _0000_
  ; MATCHES test_4player_score_v3.bas EXACTLY
  ; score_byte2 = $A0 (sets score to $A0: blank + P1=0, displays leftmost as "_0")
  ; score_byte1 = $00 (sets score+1 to $00: P2=0 + P3=0, displays middle as "00")
  ; score_byte0 = $0A (sets score+2 to $0A: P4=0 + blank, displays rightmost as "0_")
  ; Display order: score (left), score+1 (middle), score+2 (right) = "_0000_"
  score_byte2 = $A0 : score_byte1 = $00 : score_byte0 = $0A
  invincibility_timer = 0    ; No invincibility at start

  ; Initialize AI bots (v005 difficulty - Best Bot)
  ; P2 AI (top-right)
  ai_p2_target_direction = 8    ; Start facing left (toward center)
  ai_p2_update_timer = 30       ; First update in 0.5 seconds
  ai_p2_action_timer = 15       ; First action check in 0.25 seconds

  ; P3 AI (bottom-left)
  ai_p3_target_direction = 16   ; Start facing up (toward center)
  ai_p3_update_timer = 30       ; First update in 0.5 seconds
  ai_p3_action_timer = 15       ; First action check in 0.25 seconds

  ; P4 AI (bottom-right)
  ai_p4_target_direction = 16   ; Start facing up (toward center)
  ai_p4_update_timer = 30       ; First update in 0.5 seconds
  ai_p4_action_timer = 15       ; First action check in 0.25 seconds

  ballx = 80 : bally = 88
  ballheight = 4

  temp_dir = (rand & 31)
  gosub __Set_Ball_Velocity_Slow  ; Use SLOW velocity at start

  gosub __Setup_Playfield

  ; Initialize ship sprites to show all bricks intact (v095 optimization)
  gosub __Update_P1_Ship_Sprite
  gosub __Update_P2_Ship_Sprite
  gosub __Update_P3_Ship_Sprite
  gosub __Update_P4_Ship_Sprite

  ;***************************************************************
  ;  Paddle Position Offset Tables (shared by both players)
  ;  32 directions (0-31) corresponding to paddle positions
  ;***************************************************************
   data _paddle_x_offsets
   4, 2, 255, 253, 251, 250, 248, 248
   248, 248, 248, 250, 251, 252, 254, 1
   4, 6, 8, 10, 13, 14, 16, 16
   16, 16, 16, 14, 13, 11, 9, 6
end

   data _paddle_y_offsets
   28, 26, 24, 22, 21, 18, 15, 12
   8, 4, 1, 254, 251, 249, 247, 246
   245, 246, 247, 249, 251, 254, 1, 4
   8, 12, 15, 18, 21, 22, 24, 26
end

  ;***************************************************************
  ;  Ball Position Offset Tables (shared by both players)
  ;  32 directions (0-31) for ball following paddle
  ;***************************************************************
   data _ball_x_offsets
   10, 6, 0, 252, 251, 249, 249, 249
   249, 249, 249, 251, 253, 252, 254, 3
   8, 11, 13, 17, 20, 22, 26, 26
   26, 26, 26, 22, 20, 15, 13, 8
end

   data _ball_y_offsets
   40, 36, 34, 30, 29, 24, 21, 17
   11, 6, 1, 253, 248, 244, 241, 240
   238, 241, 243, 245, 249, 253, 1, 6
   11, 17, 21, 25, 29, 32, 35, 37
end

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

  ; Player 2 sprite (P3 ship - bottom-left, orange)
  player2:
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

  player2color:
  $20
  $22
  $24
  $26
  $28
  $2a
  $2c
  $2e
  $20
  $22
  $24
  $26
  $28
  $2a
  $2c
  $2e
  $20
  $22
  $24
  $26
  $28
  $2a
  $2c
  $2e
  $20
  $22
end

  ; Player 3 sprite (P4 ship - bottom-right, green)
  player3:
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

  player3color:
  $C0
  $C2
  $C4
  $C6
  $C8
  $Ca
  $Cc
  $Ce
  $C0
  $C2
  $C4
  $C6
  $C8
  $Ca
  $Cc
  $Ce
  $C0
  $C2
  $C4
  $C6
  $C8
  $Ca
  $Cc
  $Ce
  $C0
  $C2
end

  ; Paddle colors - P1 paddle (red, same as v005 player2color)
  player4color:
  $98
  $9a
  $9c
  $9e
  $90
  $92
  $94
  $96
  $98
end

  ; Paddle colors - P2 paddle (blue, same as v005 player3color)
  player5color:
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

  ; Score color gradient (for 4-player score display)
  scorecolors:
    $F4
    $F6
    $F8
    $FA
    $FC
    $FE
    $FC
    $FA
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
  ;  AI Bot Updates for P2, P3, P4 (replace Paddle 1 input)
  ;***************************************************************
  gosub __AI_Update_P2  ; AI calculates direction and actions for P2
  gosub __AI_Update_P3  ; AI calculates direction and actions for P3
  gosub __AI_Update_P4  ; AI calculates direction and actions for P4

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

  ; P2 AI button tracking (AI sets p2_state{0} in __AI_Update_P2)
  ; RANDOM LAUNCH: Launch after 2-4 seconds (120-240 frames) randomly
  if ball_state = 2 && p2_catch_timer >= 120 && (rand & 1) = 0 then gosub __P2_Launch_Ball

  ; P3 AI button tracking and random launch
  if ball_state = 3 && p3_catch_timer >= 120 && (rand & 1) = 0 then gosub __P3_Launch_Ball

  ; P4 AI button tracking and random launch
  if ball_state = 4 && p4_catch_timer >= 120 && (rand & 1) = 0 then gosub __P4_Launch_Ball

  ;***************************************************************
  ;  Ball physics - FIRST (before ship moves, same moment in time)
  ;***************************************************************
  if ball_state = 1 then gosub __Ball_Follow_P1 : goto __Skip_Ball_Physics
  if ball_state = 2 then gosub __Ball_Follow_P2 : goto __Skip_Ball_Physics
  if ball_state = 3 then gosub __Ball_Follow_P3 : goto __Skip_Ball_Physics
  if ball_state = 4 then gosub __Ball_Follow_P4 : goto __Skip_Ball_Physics

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
  if player1y < 200 then if (bally + 4) >= player1y && bally <= (player1y + 26) then if (ballx + 2) >= (player1x + 2) && ballx <= (player1x + 18) then gosub __P2_Brick_Hit : goto __Skip_Brick_Collision
  ; P3 coordinate collision (shifted +2px for player4 sprite offset) - using inclusive bounds
  if player2y < 200 then if (bally + 4) >= player2y && bally <= (player2y + 26) then if (ballx + 2) >= (player2x + 2) && ballx <= (player2x + 18) then gosub __P3_Brick_Hit : goto __Skip_Brick_Collision
  ; P4 coordinate collision (shifted +2px for player5 sprite offset) - using inclusive bounds
  if player3y < 200 then if (bally + 4) >= player3y && bally <= (player3y + 26) then if (ballx + 2) >= (player3x + 2) && ballx <= (player3x + 18) then gosub __P4_Brick_Hit

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

  ; Check P1 paddle (player4)
  if ballx < player4x + 11 && ballx + 2 > player4x + 3 then if bally < player4y + 10 && bally + 4 > player4y - 1 then gosub __Check_P1_Paddle

  ; Check P2 paddle (player5)
  if ballx < player5x + 9 && ballx + 2 > player5x + 1 then if bally < player5y + 10 && bally + 4 > player5y - 1 then gosub __Check_P2_Paddle

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
  if joy0right && accel_counter = 0 then gosub __Load_P1_Context : temp_dir = p1_direction : gosub __Thrust : gosub __Store_P1_Context

  ; Player 2: AI bot sets p2_state{0} for thrust decisions
  if p2_state{0} && accel_counter = 0 then gosub __Load_P2_Context : temp_dir = p2_direction : gosub __Thrust : gosub __Store_P2_Context

  ; Player 3: AI bot sets p3_state{0} for thrust decisions
  if p3_state{0} && accel_counter = 0 then gosub __Load_P3_Context : temp_dir = p3_direction : gosub __Thrust : gosub __Store_P3_Context

  ; Player 4: AI bot sets p4_state{0} for thrust decisions
  if p4_state{0} && accel_counter = 0 then gosub __Load_P4_Context : temp_dir = p4_direction : gosub __Thrust : gosub __Store_P4_Context

  ; Apply frame-based movement (drift with momentum)
  gosub __Load_P1_Context
  gosub __Apply_Movement
  gosub __Store_P1_Context

  gosub __Load_P2_Context
  gosub __Apply_Movement
  gosub __Store_P2_Context

  gosub __Load_P3_Context
  gosub __Apply_Movement
  gosub __Store_P3_Context

  gosub __Load_P4_Context
  gosub __Apply_Movement
  gosub __Store_P4_Context

  ;***************************************************************
  ;  Wall Bounce for Players
  ;***************************************************************
  gosub __Load_P1_Context
  gosub __Wall_Bounce
  gosub __Store_P1_Context

  gosub __Load_P2_Context
  gosub __Wall_Bounce
  gosub __Store_P2_Context

  gosub __Load_P3_Context
  gosub __Wall_Bounce
  gosub __Store_P3_Context

  gosub __Load_P4_Context
  gosub __Wall_Bounce
  gosub __Store_P4_Context

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

  ; P1 catch timer and auto-launch (v096: consolidated)
  if ball_state = 1 then p1_catch_timer = p1_catch_timer + 1 : if p1_catch_timer >= auto_launch_time then gosub __P1_Auto_Launch

  ; P2 catch timer and auto-launch (v096: consolidated)
  if ball_state = 2 then p2_catch_timer = p2_catch_timer + 1 : if p2_catch_timer >= auto_launch_time then gosub __P2_Auto_Launch

  ; P3 catch timer and auto-launch
  if ball_state = 3 then p3_catch_timer = p3_catch_timer + 1 : if p3_catch_timer >= auto_launch_time then gosub __P3_Auto_Launch

  ; P4 catch timer and auto-launch
  if ball_state = 4 then p4_catch_timer = p4_catch_timer + 1 : if p4_catch_timer >= auto_launch_time then gosub __P4_Auto_Launch

  ; P1 cooldown timer (v096: consolidated)
  if p1_state{1} then p1_catch_timer = p1_catch_timer - 1 : if p1_catch_timer = 0 then p1_state{1} = 0

  ; P2 cooldown timer (v096: consolidated)
  if p2_state{1} then p2_catch_timer = p2_catch_timer - 1 : if p2_catch_timer = 0 then p2_state{1} = 0

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
  ;  Ship sprites - OPTIMIZED in v095
  ;  Sprites now update only when brick state changes (not every frame)
  ;  Updates happen in: __P1_Brick_Bounce, __P2_Brick_Bounce, __Round_Reset
  ;***************************************************************

  ; Draw score display in bottom playfield area
  ; Score displays automatically at top via built-in PXE score system!

  drawscreen
  goto __Main_Loop


  ;***************************************************************
  ;  THRUST PHYSICS SUBROUTINES
  ;***************************************************************

__Load_P1_Context
  ; Load Player 1 variables into temp context
  temp_speed_x = p1_speed_x
  temp_speed_y = p1_speed_y
  temp_frame_x = p1_frame_x
  temp_frame_y = p1_frame_y
  temp_dir_x = p1_dir_x
  temp_dir_y = p1_dir_y
  temp_player_num = 0
  return


__Load_P2_Context
  ; Load Player 2 variables into temp context
  temp_speed_x = p2_speed_x
  temp_speed_y = p2_speed_y
  temp_frame_x = p2_frame_x
  temp_frame_y = p2_frame_y
  temp_dir_x = p2_dir_x
  temp_dir_y = p2_dir_y
  temp_player_num = 1
  return


__Store_P1_Context
  ; Store temp context back to Player 1 variables
  p1_speed_x = temp_speed_x
  p1_speed_y = temp_speed_y
  p1_frame_x = temp_frame_x
  p1_frame_y = temp_frame_y
  p1_dir_x = temp_dir_x
  p1_dir_y = temp_dir_y
  return


__Store_P2_Context
  ; Store temp context back to Player 2 variables
  p2_speed_x = temp_speed_x
  p2_speed_y = temp_speed_y
  p2_frame_x = temp_frame_x
  p2_frame_y = temp_frame_y
  p2_dir_x = temp_dir_x
  p2_dir_y = temp_dir_y
  return


__Load_P3_Context
  ; Load Player 3 variables into temp context
  temp_speed_x = p3_speed_x
  temp_speed_y = p3_speed_y
  temp_frame_x = p3_frame_x
  temp_frame_y = p3_frame_y
  temp_dir_x = p3_dir_x
  temp_dir_y = p3_dir_y
  temp_player_num = 2
  return


__Store_P3_Context
  ; Store temp context back to Player 3 variables
  p3_speed_x = temp_speed_x
  p3_speed_y = temp_speed_y
  p3_frame_x = temp_frame_x
  p3_frame_y = temp_frame_y
  p3_dir_x = temp_dir_x
  p3_dir_y = temp_dir_y
  return


__Load_P4_Context
  ; Load Player 4 variables into temp context
  temp_speed_x = p4_speed_x
  temp_speed_y = p4_speed_y
  temp_frame_x = p4_frame_x
  temp_frame_y = p4_frame_y
  temp_dir_x = p4_dir_x
  temp_dir_y = p4_dir_y
  temp_player_num = 3
  return


__Store_P4_Context
  ; Store temp context back to Player 4 variables
  p4_speed_x = temp_speed_x
  p4_speed_y = temp_speed_y
  p4_frame_x = temp_frame_x
  p4_frame_y = temp_frame_y
  p4_dir_x = temp_dir_x
  p4_dir_y = temp_dir_y
  return


__Thrust
  ; SHARED thrust function - works on temp_* variables
  ; Apply thrust in direction temp_dir (0-31)
  ; Rotated by 16 to match paddle dial (0=South)
  temp_dir = (temp_dir + 16) & 31
  on temp_dir goto __T_0 __T_1 __T_2 __T_3 __T_4 __T_5 __T_6 __T_7 __T_8 __T_9 __T_10 __T_11 __T_12 __T_13 __T_14 __T_15 __T_16 __T_17 __T_18 __T_19 __T_20 __T_21 __T_22 __T_23 __T_24 __T_25 __T_26 __T_27 __T_28 __T_29 __T_30 __T_31

; 32-direction thrust: 0=N, 8=E, 16=S, 24=W
__T_0
  gosub __Accel_Up : return
__T_1
  gosub __Accel_Up : gosub __Accel_Right : return
__T_2
  gosub __Accel_Up : gosub __Accel_Right : return
__T_3
  gosub __Accel_Up : gosub __Accel_Right : return
__T_4
  gosub __Accel_Up : gosub __Accel_Right : return
__T_5
  gosub __Accel_Up : gosub __Accel_Right : return
__T_6
  gosub __Accel_Up : gosub __Accel_Right : return
__T_7
  gosub __Accel_Up : gosub __Accel_Right : return
__T_8
  gosub __Accel_Right : return
__T_9
  gosub __Accel_Down : gosub __Accel_Right : return
__T_10
  gosub __Accel_Down : gosub __Accel_Right : return
__T_11
  gosub __Accel_Down : gosub __Accel_Right : return
__T_12
  gosub __Accel_Down : gosub __Accel_Right : return
__T_13
  gosub __Accel_Down : gosub __Accel_Right : return
__T_14
  gosub __Accel_Down : gosub __Accel_Right : return
__T_15
  gosub __Accel_Down : gosub __Accel_Right : return
__T_16
  gosub __Accel_Down : return
__T_17
  gosub __Accel_Down : gosub __Accel_Left : return
__T_18
  gosub __Accel_Down : gosub __Accel_Left : return
__T_19
  gosub __Accel_Down : gosub __Accel_Left : return
__T_20
  gosub __Accel_Down : gosub __Accel_Left : return
__T_21
  gosub __Accel_Down : gosub __Accel_Left : return
__T_22
  gosub __Accel_Down : gosub __Accel_Left : return
__T_23
  gosub __Accel_Down : gosub __Accel_Left : return
__T_24
  gosub __Accel_Left : return
__T_25
  gosub __Accel_Up : gosub __Accel_Left : return
__T_26
  gosub __Accel_Up : gosub __Accel_Left : return
__T_27
  gosub __Accel_Up : gosub __Accel_Left : return
__T_28
  gosub __Accel_Up : gosub __Accel_Left : return
__T_29
  gosub __Accel_Up : gosub __Accel_Left : return
__T_30
  gosub __Accel_Up : gosub __Accel_Left : return
__T_31
  gosub __Accel_Up : gosub __Accel_Left : return


__Accel_Right
  ; SHARED function - works on temp_dir_x and temp_speed_x
  ; If moving left, decelerate (return on stop to prevent same-frame re-accel)
  if temp_dir_x = 255 then temp_speed_x = temp_speed_x + 2 : if temp_speed_x >= 16 then temp_dir_x = 0 : temp_speed_x = 16 : return
  ; If stopped or moving right, accelerate right
  if temp_dir_x = 0 then temp_dir_x = 1
  if temp_dir_x = 1 then if temp_speed_x > max_speed then temp_speed_x = temp_speed_x - 2
  return

__Accel_Left
  ; SHARED function - works on temp_dir_x and temp_speed_x
  ; If moving right, decelerate (return on stop to prevent same-frame re-accel)
  if temp_dir_x = 1 then temp_speed_x = temp_speed_x + 2 : if temp_speed_x >= 16 then temp_dir_x = 0 : temp_speed_x = 16 : return
  if temp_dir_x = 0 then temp_dir_x = 255
  if temp_dir_x = 255 then if temp_speed_x > max_speed then temp_speed_x = temp_speed_x - 2
  return

__Accel_Up
  ; SHARED function - works on temp_dir_y and temp_speed_y
  ; If moving down, decelerate (return on stop to prevent same-frame re-accel)
  if temp_dir_y = 1 then temp_speed_y = temp_speed_y + 2 : if temp_speed_y >= 16 then temp_dir_y = 0 : temp_speed_y = 16 : return
  if temp_dir_y = 0 then temp_dir_y = 255
  if temp_dir_y = 255 then if temp_speed_y > max_speed then temp_speed_y = temp_speed_y - 2
  return

__Accel_Down
  ; SHARED function - works on temp_dir_y and temp_speed_y
  ; If moving up, decelerate (return on stop to prevent same-frame re-accel)
  if temp_dir_y = 255 then temp_speed_y = temp_speed_y + 2 : if temp_speed_y >= 16 then temp_dir_y = 0 : temp_speed_y = 16 : return
  if temp_dir_y = 0 then temp_dir_y = 1
  if temp_dir_y = 1 then if temp_speed_y > max_speed then temp_speed_y = temp_speed_y - 2
  return


__Apply_Movement
  ; SHARED function - uses temp_player_num to determine which player sprite to move
  ; Skip movement if player is off-screen (killed)
  if temp_player_num = 0 then if player0y >= 150 then return
  if temp_player_num = 1 then if player1y >= 150 then return

  ; Apply X movement (frame-based velocity)
  if temp_dir_x <> 0 then temp_frame_x = temp_frame_x - 1
  if temp_frame_x = 0 then goto __Apply_Movement_X

__Apply_Movement_Y
  ; Apply Y movement (frame-based velocity) - DOUBLED for PXE
  if temp_dir_y <> 0 then temp_frame_y = temp_frame_y - 1
  if temp_frame_y = 0 then goto __Apply_Movement_Y_Move
  return

__Apply_Movement_X
  if temp_player_num = 0 then player0x = player0x + temp_dir_x : temp_frame_x = temp_speed_x : goto __Apply_Movement_Y
  player1x = player1x + temp_dir_x : temp_frame_x = temp_speed_x : goto __Apply_Movement_Y

__Apply_Movement_Y_Move
  if temp_player_num = 0 then player0y = player0y + temp_dir_y : player0y = player0y + temp_dir_y : temp_frame_y = temp_speed_y : return
  player1y = player1y + temp_dir_y : player1y = player1y + temp_dir_y : temp_frame_y = temp_speed_y : return


__Wall_Bounce
  ; SHARED function - uses temp_player_num to determine which player sprite
  ; Skip wall bounce if player is off-screen (killed)
  if temp_player_num = 0 then if player0y >= 150 then return
  if temp_player_num = 1 then if player1y >= 150 then return

  ; Check left wall
  if temp_player_num = 0 then if player0x < 3 then temp_dir_x = 1 : player0x = 3 : temp_frame_x = temp_speed_x
  if temp_player_num = 1 then if player1x < 3 then temp_dir_x = 1 : player1x = 3 : temp_frame_x = temp_speed_x

  ; Check right wall
  if temp_player_num = 0 then if player0x > 139 then temp_dir_x = 255 : player0x = 139 : temp_frame_x = temp_speed_x
  if temp_player_num = 1 then if player1x > 139 then temp_dir_x = 255 : player1x = 139 : temp_frame_x = temp_speed_x

  ; Check top wall
  if temp_player_num = 0 then if player0y < 8 then temp_dir_y = 1 : player0y = 8 : temp_frame_y = temp_speed_y
  if temp_player_num = 1 then if player1y < 8 then temp_dir_y = 1 : player1y = 8 : temp_frame_y = temp_speed_y

  ; Check bottom wall
  if temp_player_num = 0 then if player0y > 135 then temp_dir_y = 255 : player0y = 135 : temp_frame_y = temp_speed_y
  if temp_player_num = 1 then if player1y > 135 then temp_dir_y = 255 : player1y = 135 : temp_frame_y = temp_speed_y

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
  gosub __Award_P2_Point         ; Award point to Player 2 (BCD)
  ; Hide P1 ship sprite off-screen (player0)
  player0y = 200
  ; Hide P1 paddle off-screen (player4)
  player4y = 200
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
  ; Update P1 sprite to reflect brick destruction (v095 optimization)
  gosub __Update_P1_Ship_Sprite
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
  gosub __Award_P1_Point         ; Award point to Player 1 (BCD)
  ; Hide P2 ship sprite off-screen (player1)
  player1y = 200
  ; Hide P2 paddle off-screen (player5)
  player5y = 200
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
  ; Update P2 sprite to reflect brick destruction (v095 optimization)
  gosub __Update_P2_Ship_Sprite
  return


__P3_Brick_Hit
  ; P3 uses player4 (same +2 offset as player1/P2)
  if bally + 4 > player2y + 19 then goto __P3_Bottom_Area
  if bally > player2y + 6 then goto __P3_Middle_Area
  goto __P3_Top_Area

__P3_Top_Area
  if ballx + 2 <= player2x + 3 then goto __P3_Left_Area
  if ballx >= player2x + 16 then goto __P3_Right_Area
  if p3_bricks{0} then p3_bricks{0} = 0 : goto __P3_Brick_Bounce
  if bally + 4 < player2y + 8 then return
  if ballx + 2 > player2x + 7 then if ballx < player2x + 13 then goto __P3_Core_Hit
  return

__P3_Middle_Area
  if ballx + 2 <= player2x + 9 then goto __P3_Left_Area
  goto __P3_Right_Area

__P3_Left_Area
  if p3_bricks{2} then p3_bricks{2} = 0 : goto __P3_Brick_Bounce
  if ballx + 2 > player2x + 7 then goto __P3_Core_Hit
  return

__P3_Right_Area
  if p3_bricks{1} then p3_bricks{1} = 0 : goto __P3_Brick_Bounce
  if ballx < player2x + 13 then goto __P3_Core_Hit
  return

__P3_Bottom_Area
  if ballx + 2 <= player2x + 3 then goto __P3_Left_Area
  if ballx >= player2x + 16 then goto __P3_Right_Area
  if p3_bricks{3} then p3_bricks{3} = 0 : goto __P3_Brick_Bounce
  if bally > player2y + 17 then return
  if ballx + 2 > player2x + 7 then if ballx < player2x + 13 then goto __P3_Core_Hit
  return

__P3_Core_Hit
  gosub __Award_P1_Point  ; P1 gets point when P3 dies
  player2y = 200  ; Hide P3 ship
  invincibility_timer = invincibility_duration
  return

__P3_Brick_Bounce
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  gosub __Update_P3_Ship_Sprite
  return


__P4_Brick_Hit
  ; P4 uses player5 (same +2 offset as player1/P2)
  if bally + 4 > player3y + 19 then goto __P4_Bottom_Area
  if bally > player3y + 6 then goto __P4_Middle_Area
  goto __P4_Top_Area

__P4_Top_Area
  if ballx + 2 <= player3x + 3 then goto __P4_Left_Area
  if ballx >= player3x + 16 then goto __P4_Right_Area
  if p4_bricks{0} then p4_bricks{0} = 0 : goto __P4_Brick_Bounce
  if bally + 4 < player3y + 8 then return
  if ballx + 2 > player3x + 7 then if ballx < player3x + 13 then goto __P4_Core_Hit
  return

__P4_Middle_Area
  if ballx + 2 <= player3x + 9 then goto __P4_Left_Area
  goto __P4_Right_Area

__P4_Left_Area
  if p4_bricks{2} then p4_bricks{2} = 0 : goto __P4_Brick_Bounce
  if ballx + 2 > player3x + 7 then goto __P4_Core_Hit
  return

__P4_Right_Area
  if p4_bricks{1} then p4_bricks{1} = 0 : goto __P4_Brick_Bounce
  if ballx < player3x + 13 then goto __P4_Core_Hit
  return

__P4_Bottom_Area
  if ballx + 2 <= player3x + 3 then goto __P4_Left_Area
  if ballx >= player3x + 16 then goto __P4_Right_Area
  if p4_bricks{3} then p4_bricks{3} = 0 : goto __P4_Brick_Bounce
  if bally > player3y + 17 then return
  if ballx + 2 > player3x + 7 then if ballx < player3x + 13 then goto __P4_Core_Hit
  return

__P4_Core_Hit
  gosub __Award_P1_Point  ; P1 gets point when P4 dies
  player3y = 200  ; Hide P4 ship
  invincibility_timer = invincibility_duration
  return

__P4_Brick_Bounce
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  gosub __Update_P4_Ship_Sprite
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
  ballx = player0x + _ball_x_offsets[temp_dir]
  bally = player0y + _ball_y_offsets[temp_dir]
  return

__Ball_Follow_P2
  temp_dir = p2_direction
  ballx = player1x + _ball_x_offsets[temp_dir]
  bally = player1y + _ball_y_offsets[temp_dir]
  return

__Ball_Follow_P3
  temp_dir = p3_direction
  ballx = player2x + _ball_x_offsets[temp_dir]
  bally = player2y + _ball_y_offsets[temp_dir]
  return

__Ball_Follow_P4
  temp_dir = p4_direction
  ballx = player3x + _ball_x_offsets[temp_dir]
  bally = player3y + _ball_y_offsets[temp_dir]
  return

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

__P3_Launch_Ball
  ball_state = 0  ; Detach from P3
  temp_dir = p3_direction  ; Use paddle direction
  gosub __Set_Ball_Velocity  ; Set to FAST velocity
  ball_speed_timer = fast_ball_duration  ; Start fast mode timer
  return

__P4_Launch_Ball
  ball_state = 0  ; Detach from P4
  temp_dir = p4_direction  ; Use paddle direction
  gosub __Set_Ball_Velocity  ; Set to FAST velocity
  ball_speed_timer = fast_ball_duration  ; Start fast mode timer
  return

__P3_Auto_Launch
  gosub __P3_Launch_Ball
  p3_catch_timer = 0  ; Reset timer
  p3_state{1} = 1  ; Set cooldown flag
  return

__P4_Auto_Launch
  gosub __P4_Launch_Ball
  p4_catch_timer = 0  ; Reset timer
  p4_state{1} = 1  ; Set cooldown flag
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

  ; Update sprites to show all bricks intact (v095 optimization)
  gosub __Update_P1_Ship_Sprite
  gosub __Update_P2_Ship_Sprite

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
  ;  SCORE SYSTEM - 4-Player Award Functions (v098)
  ;  Scores display automatically at bottom via built-in PXE!
  ;  Format: _0000_ (blank, P1, P2, P3, P4, blank)
  ;
  ;  MATCHES test_4player_score_v3.bas EXACTLY:
  ;  Display order: score (left), score+1 (middle), score+2 (right)
  ;
  ;  P1 = Lower nibble of score_byte2 (score) → 2nd digit from left
  ;  P2 = Upper nibble of score_byte1 (score+1) → 3rd digit from left
  ;  P3 = Lower nibble of score_byte1 (score+1) → 4th digit from left (not yet used)
  ;  P4 = Upper nibble of score_byte0 (score+2) → 1st digit from left (not yet used)
  ;***************************************************************
__Award_P1_Point
  ; Increment P1 score (lower nibble of score_byte2, CAP at 9)
  temp1 = score_byte2 & $0F       ; Get P1 score (lower nibble)
  if temp1 < 9 then temp1 = temp1 + 1  ; Increment only if less than 9 (CAP at 9)
  score_byte2 = (score_byte2 & $F0) | temp1  ; Update P1 score, preserve blank
  return

__Award_P2_Point
  ; Increment P2 score (upper nibble of score_byte1, CAP at 9)
  temp1 = (score_byte1 & $F0)     ; Get P2 score (upper nibble)
  if (temp1 & $F0) < $90 then temp1 = temp1 + $10  ; Increment only if less than 9 (CAP at 9)
  score_byte1 = (score_byte1 & $0F) | temp1  ; Update P2 score, preserve P3 score
  return


  ;***************************************************************
  ;***************************************************************
  ;  AI BOT SYSTEM - Player 2
  ;  Simulates paddle-like movement with delay and imperfection
  ;***************************************************************
  ;***************************************************************

__AI_Update_P2
  ;***************************************************************
  ;  Update AI target direction with reaction delay and noise
  ;***************************************************************
  ; Tick down update timer
  ai_p2_update_timer = ai_p2_update_timer - 1
  if ai_p2_update_timer > 0 then goto __AI_Rotate_P2

  ; Timer expired - calculate new target direction
  ai_p2_update_timer = 30  ; Reset to 0.5 second reaction time (HARD: faster)

  ; 5% chance to wander (ignore ball) - keeps unpredictability
  if (rand & 31) < 2 then ai_p2_target_direction = (rand & 31) : goto __AI_Rotate_P2

  ; SMART SHOOTING: If holding ball, aim at PLAYER'S CORE (not ball!)
  if ball_state = 2 then temp1 = player0x - player1x : temp2 = player0y - player1y : goto __AI_Calculate_Direction

  ; Calculate direction to ball for tracking/catching
  temp1 = ballx - player1x  ; X distance to ball
  temp2 = bally - player1y  ; Y distance to ball

__AI_Calculate_Direction

  ; Determine primary direction based on largest distance
  if temp1 < 252 then temp1 = 0 - temp1  ; abs(temp1) for negative values
  if temp2 < 252 then temp2 = 0 - temp2  ; abs(temp2)

  ; Improved 16-direction calculation for better accuracy
  ; Paddle positions: 0=S, 8=W, 16=N, 24=E (bottom of dial = 0)
  ; Using ratio of X/Y distances for finer angle resolution

  ; Determine quadrant first, then refine within quadrant
  ai_p2_target_direction = 16  ; Default: North

  ; QUADRANT 1: Right + Down (SE)
  if ballx > player1x && bally > player1y then ai_p2_target_direction = 28
  if ballx > player1x && bally > player1y && temp1 > temp2 * 2 then ai_p2_target_direction = 26  ; More E than S
  if ballx > player1x && bally > player1y && temp2 > temp1 * 2 then ai_p2_target_direction = 30  ; More S than E

  ; QUADRANT 2: Right + Up (NE)
  if ballx > player1x && bally < player1y then ai_p2_target_direction = 20
  if ballx > player1x && bally < player1y && temp1 > temp2 * 2 then ai_p2_target_direction = 22  ; More E than N
  if ballx > player1x && bally < player1y && temp2 > temp1 * 2 then ai_p2_target_direction = 18  ; More N than E

  ; QUADRANT 3: Left + Down (SW)
  if ballx < player1x && bally > player1y then ai_p2_target_direction = 4
  if ballx < player1x && bally > player1y && temp1 > temp2 * 2 then ai_p2_target_direction = 6   ; More W than S
  if ballx < player1x && bally > player1y && temp2 > temp1 * 2 then ai_p2_target_direction = 2   ; More S than W

  ; QUADRANT 4: Left + Up (NW)
  if ballx < player1x && bally < player1y then ai_p2_target_direction = 12
  if ballx < player1x && bally < player1y && temp1 > temp2 * 2 then ai_p2_target_direction = 10  ; More W than N
  if ballx < player1x && bally < player1y && temp2 > temp1 * 2 then ai_p2_target_direction = 14  ; More N than W

  ; CARDINALS: Strongly one direction
  if ballx > player1x && temp1 > temp2 * 3 then ai_p2_target_direction = 24  ; E (mostly right)
  if ballx < player1x && temp1 > temp2 * 3 then ai_p2_target_direction = 8   ; W (mostly left)
  if bally > player1y && temp2 > temp1 * 3 then ai_p2_target_direction = 0   ; S (mostly down)
  if bally < player1y && temp2 > temp1 * 3 then ai_p2_target_direction = 16  ; N (mostly up)

  ; Add noise: ±1 position for good accuracy (HARD: less error)
  temp1 = (rand & 1)      ; Random 0 or 1
  if rand & 2 then temp1 = 0 - temp1  ; Make it negative 50% of time (±1)
  ai_p2_target_direction = ai_p2_target_direction + temp1
  if ai_p2_target_direction >= 32 then ai_p2_target_direction = ai_p2_target_direction - 32
  if ai_p2_target_direction < 0 then ai_p2_target_direction = ai_p2_target_direction + 32

__AI_Rotate_P2
  ;***************************************************************
  ;  Smoothly rotate current direction toward target
  ;***************************************************************
  ; If already at target, done
  if p2_direction = ai_p2_target_direction then goto __AI_Actions_P2

  ; Calculate rotation direction (clockwise or counter-clockwise)
  temp1 = ai_p2_target_direction - p2_direction
  if temp1 < 0 then temp1 = temp1 + 32  ; Normalize to 0-31

  ; Rotate 1 step toward target
  if temp1 <= 16 then p2_direction = p2_direction + 1  ; Clockwise
  if temp1 > 16 then p2_direction = p2_direction - 1   ; Counter-clockwise

  ; Wrap direction to 0-31 range (allows smooth rotation through South barrier)
  p2_direction = p2_direction & 31  ; Mask handles both overflow (32→0) and underflow (255→31)

__AI_Actions_P2
  ;***************************************************************
  ;  Distance-based thrust and catch decisions
  ;  FIX: Only thrust when aimed correctly (like human players!)
  ;***************************************************************
  ; Check if currently aimed close enough to target direction
  ; AI can only thrust in direction it's CURRENTLY facing (like humans)
  temp1 = p2_direction - ai_p2_target_direction
  if temp1 < 0 then temp1 = 0 - temp1     ; abs(temp1)
  if temp1 > 16 then temp1 = 32 - temp1   ; Handle wraparound (e.g., 30-2 = 28, but real distance is 4)

  ; If aimed more than ±3 positions off target, NO THRUST/CATCH allowed
  if temp1 > 3 then p2_state{0} = 0 : return  ; Not aimed correctly, can't act

  ; NOW check distance to ball for thrust/catch decisions
  temp1 = ballx - player1x
  if temp1 < 128 then temp1 = 0 - temp1  ; abs(temp1)
  temp2 = bally - player1y
  if temp2 < 128 then temp2 = 0 - temp2  ; abs(temp2)

  ; Approximate distance (Manhattan distance)
  temp1 = temp1 + temp2

  ; Thrust decision: Chase if far (>40px), evade if very close (<15px) - HARD: more aggressive
  if temp1 > 40 && (rand & 15) < 4 then p2_state{0} = 1 : return  ; 25% chance to thrust toward ball
  if temp1 < 15 && (rand & 15) < 5 then p2_state{0} = 1 : return  ; 31% chance to thrust (will evade)

  ; Catch decision: 50% chance when ball nearby (<20px) - HARD: better catching
  if ball_state = 0 && temp1 < 20 && (rand & 1) = 0 then p2_state{0} = 1 : return  ; Try to catch

  ; Default: No action this frame
  p2_state{0} = 0
  return


  ;***************************************************************
  ;  AI Update for Player 3 (Bottom-Left, Orange)
  ;***************************************************************
__AI_Update_P3
  ;***************************************************************
  ;  Update AI target direction with reaction delay and noise
  ;***************************************************************
  ; Tick down update timer
  ai_p3_update_timer = ai_p3_update_timer - 1
  if ai_p3_update_timer > 0 then goto __AI_Rotate_P3

  ; Timer expired - calculate new target direction
  ai_p3_update_timer = 30  ; Reset to 0.5 second reaction time

  ; 5% chance to wander (ignore ball) - keeps unpredictability
  if (rand & 31) < 2 then ai_p3_target_direction = (rand & 31) : goto __AI_Rotate_P3

  ; SMART SHOOTING: If holding ball, aim at PLAYER'S CORE (not ball!)
  if ball_state = 3 then temp1 = player0x - player2x : temp2 = player0y - player2y : goto __AI_Calculate_Direction_P3

  ; Calculate direction to ball for tracking/catching
  temp1 = ballx - player2x  ; X distance to ball
  temp2 = bally - player2y  ; Y distance to ball

__AI_Calculate_Direction_P3

  ; Determine primary direction based on largest distance
  if temp1 < 252 then temp1 = 0 - temp1  ; abs(temp1) for negative values
  if temp2 < 252 then temp2 = 0 - temp2  ; abs(temp2)

  ; Improved 16-direction calculation for better accuracy
  ai_p3_target_direction = 16  ; Default: North

  ; QUADRANT 1: Right + Down (SE)
  if ballx > player2x && bally > player2y then ai_p3_target_direction = 28
  if ballx > player2x && bally > player2y && temp1 > temp2 * 2 then ai_p3_target_direction = 26
  if ballx > player2x && bally > player2y && temp2 > temp1 * 2 then ai_p3_target_direction = 30

  ; QUADRANT 2: Right + Up (NE)
  if ballx > player2x && bally < player2y then ai_p3_target_direction = 20
  if ballx > player2x && bally < player2y && temp1 > temp2 * 2 then ai_p3_target_direction = 22
  if ballx > player2x && bally < player2y && temp2 > temp1 * 2 then ai_p3_target_direction = 18

  ; QUADRANT 3: Left + Down (SW)
  if ballx < player2x && bally > player2y then ai_p3_target_direction = 4
  if ballx < player2x && bally > player2y && temp1 > temp2 * 2 then ai_p3_target_direction = 6
  if ballx < player2x && bally > player2y && temp2 > temp1 * 2 then ai_p3_target_direction = 2

  ; QUADRANT 4: Left + Up (NW)
  if ballx < player2x && bally < player2y then ai_p3_target_direction = 12
  if ballx < player2x && bally < player2y && temp1 > temp2 * 2 then ai_p3_target_direction = 10
  if ballx < player2x && bally < player2y && temp2 > temp1 * 2 then ai_p3_target_direction = 14

  ; CARDINALS: Strongly one direction
  if ballx > player2x && temp1 > temp2 * 3 then ai_p3_target_direction = 24
  if ballx < player2x && temp1 > temp2 * 3 then ai_p3_target_direction = 8
  if bally > player2y && temp2 > temp1 * 3 then ai_p3_target_direction = 0
  if bally < player2y && temp2 > temp1 * 3 then ai_p3_target_direction = 16

  ; Add noise: ±1 position for good accuracy
  temp1 = (rand & 1)
  if rand & 2 then temp1 = 0 - temp1
  ai_p3_target_direction = ai_p3_target_direction + temp1
  if ai_p3_target_direction >= 32 then ai_p3_target_direction = ai_p3_target_direction - 32
  if ai_p3_target_direction < 0 then ai_p3_target_direction = ai_p3_target_direction + 32

__AI_Rotate_P3
  ; If already at target, done
  if p3_direction = ai_p3_target_direction then goto __AI_Actions_P3

  ; Calculate rotation direction
  temp1 = ai_p3_target_direction - p3_direction
  if temp1 < 0 then temp1 = temp1 + 32

  ; Rotate 1 step toward target
  if temp1 <= 16 then p3_direction = p3_direction + 1
  if temp1 > 16 then p3_direction = p3_direction - 1

  ; Wrap direction to 0-31 range
  p3_direction = p3_direction & 31

__AI_Actions_P3
  ; Check if currently aimed close enough to target direction
  temp1 = p3_direction - ai_p3_target_direction
  if temp1 < 0 then temp1 = 0 - temp1
  if temp1 > 16 then temp1 = 32 - temp1

  ; If aimed more than ±3 positions off target, NO THRUST/CATCH allowed
  if temp1 > 3 then p3_state{0} = 0 : return

  ; Check distance to ball for thrust/catch decisions
  temp1 = ballx - player2x
  if temp1 < 128 then temp1 = 0 - temp1
  temp2 = bally - player2y
  if temp2 < 128 then temp2 = 0 - temp2

  ; Approximate distance
  temp1 = temp1 + temp2

  ; Thrust decision
  if temp1 > 40 && (rand & 15) < 4 then p3_state{0} = 1 : return
  if temp1 < 15 && (rand & 15) < 5 then p3_state{0} = 1 : return

  ; Catch decision: 50% chance when ball nearby
  if ball_state = 0 && temp1 < 20 && (rand & 1) = 0 then p3_state{0} = 1 : return

  ; Default: No action this frame
  p3_state{0} = 0
  return


  ;***************************************************************
  ;  AI Update for Player 4 (Bottom-Right, Green)
  ;***************************************************************
__AI_Update_P4
  ;***************************************************************
  ;  Update AI target direction with reaction delay and noise
  ;***************************************************************
  ; Tick down update timer
  ai_p4_update_timer = ai_p4_update_timer - 1
  if ai_p4_update_timer > 0 then goto __AI_Rotate_P4

  ; Timer expired - calculate new target direction
  ai_p4_update_timer = 30  ; Reset to 0.5 second reaction time

  ; 5% chance to wander (ignore ball) - keeps unpredictability
  if (rand & 31) < 2 then ai_p4_target_direction = (rand & 31) : goto __AI_Rotate_P4

  ; SMART SHOOTING: If holding ball, aim at PLAYER'S CORE (not ball!)
  if ball_state = 4 then temp1 = player0x - player3x : temp2 = player0y - player3y : goto __AI_Calculate_Direction_P4

  ; Calculate direction to ball for tracking/catching
  temp1 = ballx - player3x  ; X distance to ball
  temp2 = bally - player3y  ; Y distance to ball

__AI_Calculate_Direction_P4

  ; Determine primary direction based on largest distance
  if temp1 < 252 then temp1 = 0 - temp1  ; abs(temp1) for negative values
  if temp2 < 252 then temp2 = 0 - temp2  ; abs(temp2)

  ; Improved 16-direction calculation for better accuracy
  ai_p4_target_direction = 16  ; Default: North

  ; QUADRANT 1: Right + Down (SE)
  if ballx > player3x && bally > player3y then ai_p4_target_direction = 28
  if ballx > player3x && bally > player3y && temp1 > temp2 * 2 then ai_p4_target_direction = 26
  if ballx > player3x && bally > player3y && temp2 > temp1 * 2 then ai_p4_target_direction = 30

  ; QUADRANT 2: Right + Up (NE)
  if ballx > player3x && bally < player3y then ai_p4_target_direction = 20
  if ballx > player3x && bally < player3y && temp1 > temp2 * 2 then ai_p4_target_direction = 22
  if ballx > player3x && bally < player3y && temp2 > temp1 * 2 then ai_p4_target_direction = 18

  ; QUADRANT 3: Left + Down (SW)
  if ballx < player3x && bally > player3y then ai_p4_target_direction = 4
  if ballx < player3x && bally > player3y && temp1 > temp2 * 2 then ai_p4_target_direction = 6
  if ballx < player3x && bally > player3y && temp2 > temp1 * 2 then ai_p4_target_direction = 2

  ; QUADRANT 4: Left + Up (NW)
  if ballx < player3x && bally < player3y then ai_p4_target_direction = 12
  if ballx < player3x && bally < player3y && temp1 > temp2 * 2 then ai_p4_target_direction = 10
  if ballx < player3x && bally < player3y && temp2 > temp1 * 2 then ai_p4_target_direction = 14

  ; CARDINALS: Strongly one direction
  if ballx > player3x && temp1 > temp2 * 3 then ai_p4_target_direction = 24
  if ballx < player3x && temp1 > temp2 * 3 then ai_p4_target_direction = 8
  if bally > player3y && temp2 > temp1 * 3 then ai_p4_target_direction = 0
  if bally < player3y && temp2 > temp1 * 3 then ai_p4_target_direction = 16

  ; Add noise: ±1 position for good accuracy
  temp1 = (rand & 1)
  if rand & 2 then temp1 = 0 - temp1
  ai_p4_target_direction = ai_p4_target_direction + temp1
  if ai_p4_target_direction >= 32 then ai_p4_target_direction = ai_p4_target_direction - 32
  if ai_p4_target_direction < 0 then ai_p4_target_direction = ai_p4_target_direction + 32

__AI_Rotate_P4
  ; If already at target, done
  if p4_direction = ai_p4_target_direction then goto __AI_Actions_P4

  ; Calculate rotation direction
  temp1 = ai_p4_target_direction - p4_direction
  if temp1 < 0 then temp1 = temp1 + 32

  ; Rotate 1 step toward target
  if temp1 <= 16 then p4_direction = p4_direction + 1
  if temp1 > 16 then p4_direction = p4_direction - 1

  ; Wrap direction to 0-31 range
  p4_direction = p4_direction & 31

__AI_Actions_P4
  ; Check if currently aimed close enough to target direction
  temp1 = p4_direction - ai_p4_target_direction
  if temp1 < 0 then temp1 = 0 - temp1
  if temp1 > 16 then temp1 = 32 - temp1

  ; If aimed more than ±3 positions off target, NO THRUST/CATCH allowed
  if temp1 > 3 then p4_state{0} = 0 : return

  ; Check distance to ball for thrust/catch decisions
  temp1 = ballx - player3x
  if temp1 < 128 then temp1 = 0 - temp1
  temp2 = bally - player3y
  if temp2 < 128 then temp2 = 0 - temp2

  ; Approximate distance
  temp1 = temp1 + temp2

  ; Thrust decision
  if temp1 > 40 && (rand & 15) < 4 then p4_state{0} = 1 : return
  if temp1 < 15 && (rand & 15) < 5 then p4_state{0} = 1 : return

  ; Catch decision: 50% chance when ball nearby
  if ball_state = 0 && temp1 < 20 && (rand & 1) = 0 then p4_state{0} = 1 : return

  ; Default: No action this frame
  p4_state{0} = 0
  return


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
  player4:
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
  player4x = player0x + _paddle_x_offsets[p1_direction]
  player4y = player0y + _paddle_y_offsets[p1_direction]
  return



  ;***************************************************************
  ;  Update Player 2 Paddle Position
  ;  temp_dir contains current direction (0-15)
  ;  Paddle dial: 0=South(bottom), 4=West, 8=North(top), 12=East
  ;  Same offsets as Player 1, same sprite
  ;***************************************************************
__Update_P2_Paddle
  player5:
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
  player5x = player1x + _paddle_x_offsets[p2_direction]
  player5y = player1y + _paddle_y_offsets[p2_direction]
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
  ;  Update P3 Ship Sprite (Player 4 in PXE)
  ;***************************************************************
__Update_P3_Ship_Sprite
  ; p3_bricks contains 4 bits representing brick state
  temp_dir = p3_bricks & %00001111
  on temp_dir goto __P3S_0 __P3S_1 __P3S_2 __P3S_3 __P3S_4 __P3S_5 __P3S_6 __P3S_7 __P3S_8 __P3S_9 __P3S_10 __P3S_11 __P3S_12 __P3S_13 __P3S_14 __P3S_15

; State 0: All bricks destroyed - core still visible
__P3S_0
  player2:
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000
  %00000000
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
__P3S_15
  player2:
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

; Other states (1-14) - minimal implementation for now
__P3S_1
__P3S_2
__P3S_3
__P3S_4
__P3S_5
__P3S_6
__P3S_7
__P3S_8
__P3S_9
__P3S_10
__P3S_11
__P3S_12
__P3S_13
__P3S_14
  ; Use state 15 (all bricks) as default for intermediate states
  goto __P3S_15


  ;***************************************************************
  ;  Update P4 Ship Sprite (Player 5 in PXE)
  ;***************************************************************
__Update_P4_Ship_Sprite
  ; p4_bricks contains 4 bits representing brick state
  temp_dir = p4_bricks & %00001111
  on temp_dir goto __P4S_0 __P4S_1 __P4S_2 __P4S_3 __P4S_4 __P4S_5 __P4S_6 __P4S_7 __P4S_8 __P4S_9 __P4S_10 __P4S_11 __P4S_12 __P4S_13 __P4S_14 __P4S_15

; State 0: All bricks destroyed - core still visible
__P4S_0
  player3:
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00000000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00011000
  %00000000
  %00000000
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
__P4S_15
  player3:
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

; Other states (1-14) - minimal implementation for now
__P4S_1
__P4S_2
__P4S_3
__P4S_4
__P4S_5
__P4S_6
__P4S_7
__P4S_8
__P4S_9
__P4S_10
__P4S_11
__P4S_12
__P4S_13
__P4S_14
  ; Use state 15 (all bricks) as default for intermediate states
  goto __P4S_15


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
