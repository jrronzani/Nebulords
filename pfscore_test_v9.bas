   ;***************************************************************
   ;  PFSCORE TEST V9 - Zero-G Physics Test
   ;
   ;  Testing Asteroids-style movement with:
   ;  - 8-directional acceleration
   ;  - Zero-G momentum (drift when joystick released)
   ;  - Wall bounce (reverse direction like Pong)
   ;  - Integer-based velocity (1px every N frames)
   ;
   ;  PHYSICS SYSTEM:
   ;  - speed_x/y: frames between pixel moves (10=slow, 1=fast)
   ;  - dir_x/y: direction of movement (-1, 0, +1)
   ;  - Holding joystick decreases speed (accelerates)
   ;  - Releasing joystick = drift at constant velocity
   ;  - Wall collision reverses direction
   ;
   ;  Score layout: [P1:00-99][Level:01-10][P2:00-99]
   ;***************************************************************

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
   dim speed_x = e                ; Frames between X moves (10=slow, 1=fast)
   dim speed_y = f                ; Frames between Y moves
   dim frame_counter_x = g        ; Countdown for X movement
   dim frame_counter_y = h        ; Countdown for Y movement
   dim dir_x = i                  ; X direction: 0=none, 1=right, 255=left
   dim dir_y = j                  ; Y direction: 0=none, 1=down, 255=up

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

   ; Initialize player 0 position (center of arena)
   player0x = 79
   player0y = 40

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
   ;  8-Directional Acceleration Input
   ;***************************************************************
   gosub __Handle_Acceleration

   ;***************************************************************
   ;  Apply Physics - Move player based on velocity
   ;***************************************************************
   gosub __Apply_Movement

   ;***************************************************************
   ;  Check Wall Collisions and Bounce
   ;***************************************************************
   gosub __Check_Wall_Bounce

   drawscreen
   goto __Main_Loop


__Handle_Acceleration
   ; Check all 8 directions and apply acceleration

   ; RIGHT (joy0right only)
   if joy0right && !joy0up && !joy0down then dir_x = 1 : if speed_x > 1 then speed_x = speed_x - 1

   ; LEFT (joy0left only)
   if joy0left && !joy0up && !joy0down then dir_x = 255 : if speed_x > 1 then speed_x = speed_x - 1

   ; DOWN (joy0down only)
   if joy0down && !joy0left && !joy0right then dir_y = 1 : if speed_y > 1 then speed_y = speed_y - 1

   ; UP (joy0up only)
   if joy0up && !joy0left && !joy0right then dir_y = 255 : if speed_y > 1 then speed_y = speed_y - 1

   ; UP-RIGHT diagonal
   if joy0up && joy0right then dir_x = 1 : dir_y = 255 : if speed_x > 1 then speed_x = speed_x - 1
   if joy0up && joy0right then if speed_y > 1 then speed_y = speed_y - 1

   ; UP-LEFT diagonal
   if joy0up && joy0left then dir_x = 255 : dir_y = 255 : if speed_x > 1 then speed_x = speed_x - 1
   if joy0up && joy0left then if speed_y > 1 then speed_y = speed_y - 1

   ; DOWN-RIGHT diagonal
   if joy0down && joy0right then dir_x = 1 : dir_y = 1 : if speed_x > 1 then speed_x = speed_x - 1
   if joy0down && joy0right then if speed_y > 1 then speed_y = speed_y - 1

   ; DOWN-LEFT diagonal
   if joy0down && joy0left then dir_x = 255 : dir_y = 1 : if speed_x > 1 then speed_x = speed_x - 1
   if joy0down && joy0left then if speed_y > 1 then speed_y = speed_y - 1

   return


__Apply_Movement
   ; Apply X movement (frame-based velocity)
   if dir_x <> 0 then frame_counter_x = frame_counter_x - 1
   if frame_counter_x = 0 then player0x = player0x + dir_x : frame_counter_x = speed_x

   ; Apply Y movement (frame-based velocity)
   if dir_y <> 0 then frame_counter_y = frame_counter_y - 1
   if frame_counter_y = 0 then player0y = player0y + dir_y : frame_counter_y = speed_y

   return


__Check_Wall_Bounce
   ; Check left wall (x < 12)
   if player0x < 12 then dir_x = 1 : player0x = 12 : frame_counter_x = speed_x

   ; Check right wall (x > 147)
   if player0x > 147 then dir_x = 255 : player0x = 147 : frame_counter_x = speed_x

   ; Check top wall (y < 12)
   if player0y < 12 then dir_y = 1 : player0y = 12 : frame_counter_y = speed_y

   ; Check bottom wall (y > 75)
   if player0y > 75 then dir_y = 255 : player0y = 75 : frame_counter_y = speed_y

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
