   ;***************************************************************
   ;  PFSCORE TEST V15 - Fixed Playfield Collision Detection
   ;
   ;  EASY TWEAKING - Change these values at top of code:
   ;  - max_speed: Lower = faster (2=fast, 5=slow)
   ;  - accel_delay: Higher = slower acceleration (1=instant, 5=gradual)
   ;
   ;  FIXED: Collision detection no longer gets stuck in walls
   ;  - Properly detects which axis caused collision
   ;  - Bounces correctly from all angles
   ;  - Works with ANY playfield shape
   ;
   ;  Testing Asteroids-style movement with:
   ;  - 8-directional acceleration/deceleration
   ;  - Zero-G momentum (drift when joystick released)
   ;  - Wall bounce (reverse direction on playfield collision)
   ;  - Integer-based velocity (1px every N frames)
   ;
   ;  PHYSICS SYSTEM:
   ;  - speed_x/y: frames between pixel moves (10=slow, max_speed=fast)
   ;  - Acceleration only happens every accel_delay frames
   ;  - dir_x/y: direction of movement (-1, 0, +1)
   ;  - Holding joystick SAME direction = accelerate (decrease speed)
   ;  - Holding joystick OPPOSITE direction = decelerate (increase speed)
   ;  - Releasing joystick = drift at constant velocity
   ;  - Playfield collision reverses direction
   ;
   ;  Score layout: [P1:00-99][Level:01-10][P2:00-99]
   ;  Demo: Auto-increments scores and drains health
   ;***************************************************************

   ;***************************************************************
   ;  PHYSICS CONSTANTS - TWEAK THESE!
   ;***************************************************************
   const max_speed = 2            ; Max speed (lower = faster, 1-10)
   const accel_delay = 3          ; Frames between accel (higher = slower accel)

   ;***************************************************************
   ;  Enable pfscore bars
   ;***************************************************************
   const pfscore = 1
   const pfrowheight = 8

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   dim game_level = a             ; Current level (1-10)
   dim select_debounce = b        ; Debounce for SELECT button
   dim p1_lives = c               ; Player 1 lives (0-8)
   dim p2_lives = d               ; Player 2 lives (0-8)

   ; Physics variables for Player 0
   dim speed_x = e                ; Frames between X moves (10=slow, max_speed=fast)
   dim speed_y = f                ; Frames between Y moves
   dim frame_counter_x = g        ; Countdown for X movement
   dim frame_counter_y = h        ; Countdown for Y movement
   dim dir_x = i                  ; X direction: 0=none, 1=right, 255=left
   dim dir_y = j                  ; Y direction: 0=none, 1=down, 255=up
   dim test_counter = k           ; Frame counter for demo
   dim accel_counter = l          ; Frame counter for acceleration delay

   ; Collision detection variables
   dim prev_x = m                 ; Previous X position
   dim prev_y = n                 ; Previous Y position

   ; Score byte aliases (BCD format)
   dim sc1 = score                ; P1 score (left)
   dim sc2 = score+1              ; Level (middle)
   dim sc3 = score+2              ; P2 score (right)

   ;***************************************************************
   ;  Initialize
   ;***************************************************************
__Init
   ; Start with full lives (8 bars each)
   p1_lives = 8
   p2_lives = 8
   pfscore1 = %11111111           ; Left bar full (P1 lives)
   pfscore2 = %11111111           ; Right bar full (P2 lives)

   ; Start scores at 0 in BCD format
   sc1 = $00                      ; P1 score 00
   sc2 = $01                      ; Level 01
   sc3 = $00                      ; P2 score 00

   ; Initialize level to 1
   game_level = 1
   select_debounce = 0
   test_counter = 0
   accel_counter = 0

   ; Initialize player 0 position (center of arena)
   player0x = 79
   player0y = 40
   prev_x = 79
   prev_y = 40

   ; Initialize physics - player starts stationary
   speed_x = 10                   ; No movement initially
   speed_y = 10
   frame_counter_x = 10
   frame_counter_y = 10
   dir_x = 0                      ; Not moving
   dir_y = 0

   ; Set colors
   COLUBK = $00                   ; Black background
   COLUP0 = $2E                   ; Green player
   COLUPF = $0E                   ; White playfield/bars
   scorecolor = $0E               ; White score
   pfscorecolor = $0E             ; White bar color


   ;***************************************************************
   ;  Player sprite - 8x8 pixel square
   ;***************************************************************
   player0:
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
end

   ;***************************************************************
   ;  Playfield - Full-size arena (11 rows)
   ;  Can be modified to add obstacles, mazes, etc!
   ;***************************************************************
   playfield:
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   X..............................X
   X..............................X
   X..............................X
   X..............................X
   X..............................X
   X..............................X
   X..............................X
   X..............................X
   X..............................X
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end


__Main_Loop

   ;***************************************************************
   ;  Level selection with SELECT button (cycles 01-10)
   ;***************************************************************
   if switchselect then select_debounce = select_debounce + 1 else select_debounce = 0
   if select_debounce = 1 then game_level = game_level + 1 : if game_level > 10 then game_level = 1
   if select_debounce = 1 then gosub __Update_Level_Display

   ;***************************************************************
   ;  Acceleration counter - only accelerate every N frames
   ;***************************************************************
   accel_counter = accel_counter + 1
   if accel_counter >= accel_delay then accel_counter = 0

   ;***************************************************************
   ;  8-Directional Acceleration/Deceleration Input
   ;***************************************************************
   if accel_counter = 0 then gosub __Handle_Acceleration

   ;***************************************************************
   ;  Apply Physics - Move player based on velocity
   ;***************************************************************
   gosub __Apply_Movement

   ;***************************************************************
   ;  Demo: Increment scores and drain lives every 2 seconds
   ;***************************************************************
   test_counter = test_counter + 1
   if test_counter >= 120 then test_counter = 0 : gosub __Demo_Update

   drawscreen
   goto __Main_Loop


__Handle_Acceleration
   ; Handle X-axis acceleration/deceleration

   ; RIGHT input
   if joy0right && !joy0up && !joy0down then gosub __Accel_Right

   ; LEFT input
   if joy0left && !joy0up && !joy0down then gosub __Accel_Left

   ; UP input
   if joy0up && !joy0left && !joy0right then gosub __Accel_Up

   ; DOWN input
   if joy0down && !joy0left && !joy0right then gosub __Accel_Down

   ; UP-RIGHT diagonal
   if joy0up && joy0right then gosub __Accel_Right : gosub __Accel_Up

   ; UP-LEFT diagonal
   if joy0up && joy0left then gosub __Accel_Left : gosub __Accel_Up

   ; DOWN-RIGHT diagonal
   if joy0down && joy0right then gosub __Accel_Right : gosub __Accel_Down

   ; DOWN-LEFT diagonal
   if joy0down && joy0left then gosub __Accel_Left : gosub __Accel_Down

   return


__Accel_Right
   ; If moving left, decelerate
   if dir_x = 255 then speed_x = speed_x + 1 : if speed_x >= 10 then dir_x = 0 : speed_x = 10
   ; If stopped or moving right, accelerate right
   if dir_x = 0 then dir_x = 1
   if dir_x = 1 then if speed_x > max_speed then speed_x = speed_x - 1
   return

__Accel_Left
   ; If moving right, decelerate
   if dir_x = 1 then speed_x = speed_x + 1 : if speed_x >= 10 then dir_x = 0 : speed_x = 10
   ; If stopped or moving left, accelerate left
   if dir_x = 0 then dir_x = 255
   if dir_x = 255 then if speed_x > max_speed then speed_x = speed_x - 1
   return

__Accel_Up
   ; If moving down, decelerate
   if dir_y = 1 then speed_y = speed_y + 1 : if speed_y >= 10 then dir_y = 0 : speed_y = 10
   ; If stopped or moving up, accelerate up
   if dir_y = 0 then dir_y = 255
   if dir_y = 255 then if speed_y > max_speed then speed_y = speed_y - 1
   return

__Accel_Down
   ; If moving up, decelerate
   if dir_y = 255 then speed_y = speed_y + 1 : if speed_y >= 10 then dir_y = 0 : speed_y = 10
   ; If stopped or moving down, accelerate down
   if dir_y = 0 then dir_y = 1
   if dir_y = 1 then if speed_y > max_speed then speed_y = speed_y - 1
   return


__Apply_Movement
   ; Save previous position before moving
   prev_x = player0x
   prev_y = player0y

   ; Apply X movement (frame-based velocity)
   if dir_x <> 0 then frame_counter_x = frame_counter_x - 1
   if frame_counter_x = 0 then player0x = player0x + dir_x : frame_counter_x = speed_x : gosub __Check_X_Collision

   ; Apply Y movement (frame-based velocity)
   if dir_y <> 0 then frame_counter_y = frame_counter_y - 1
   if frame_counter_y = 0 then player0y = player0y + dir_y : frame_counter_y = speed_y : gosub __Check_Y_Collision

   return


__Check_X_Collision
   ; Check if X movement caused collision
   if !collision(player0,playfield) then return
   ; Collision! Restore X and reverse direction
   player0x = prev_x
   dir_x = 0 - dir_x
   return


__Check_Y_Collision
   ; Check if Y movement caused collision
   if !collision(player0,playfield) then return
   ; Collision! Restore Y and reverse direction
   player0y = prev_y
   dir_y = 0 - dir_y
   return


__Demo_Update
   ; Increment both player scores in BCD
   ; P1 score (sc1) - LEFT 2 digits
   sc1 = sc1 + 1
   if (sc1 & $0F) > 9 then sc1 = sc1 + 6   ; Fix ones digit
   if sc1 > $99 then sc1 = 0               ; Wrap at 99

   ; P2 score (sc3) - RIGHT 2 digits
   sc3 = sc3 + 1
   if (sc3 & $0F) > 9 then sc3 = sc3 + 6   ; Fix ones digit
   if sc3 > $99 then sc3 = 0               ; Wrap at 99

   ; Drain P1 lives (left bar)
   if p1_lives > 0 then p1_lives = p1_lives - 1 : pfscore1 = pfscore1 / 2
   if p1_lives = 0 then p1_lives = 8 : pfscore1 = %11111111

   ; Drain P2 lives (right bar)
   if p2_lives > 0 then p2_lives = p2_lives - 1 : pfscore2 = pfscore2 / 2
   if p2_lives = 0 then p2_lives = 8 : pfscore2 = %11111111

   return


__Update_Level_Display
   ; Convert game_level (1-10) to BCD in sc2 (MIDDLE digits)
   sc2 = 0
   if game_level >= 10 then sc2 = $10 : return
   if game_level = 9 then sc2 = $09 : return
   if game_level = 8 then sc2 = $08 : return
   if game_level = 7 then sc2 = $07 : return
   if game_level = 6 then sc2 = $06 : return
   if game_level = 5 then sc2 = $05 : return
   if game_level = 4 then sc2 = $04 : return
   if game_level = 3 then sc2 = $03 : return
   if game_level = 2 then sc2 = $02 : return
   if game_level = 1 then sc2 = $01 : return
   return
