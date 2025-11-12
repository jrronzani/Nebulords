   set romsize 8k

   ;***************************************************************
   ;  NEBULORDS - Warlords-style Space Combat
   ;  Version 33 - Improved player movement with pfread() collision
   ;  Uses proactive collision detection for smooth wall-sliding
   ;  Requires 8k ROM due to additional movement subroutines
   ;***************************************************************

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   ; Player 1
   dim p1_xpos = player0x.a
   dim p1_ypos = player0y.b
   dim p1_xspeed = c              ; Current frame X movement
   dim p1_yspeed = d              ; Current frame Y movement
   dim p1_paddle_dir = e          ; Last paddle direction (0-7)
   dim p1_state = f               ; bit 0=button held, bit 1=catch cooldown
   dim p1_timer = g               ; button hold timer

   ; Player 2
   dim p2_xpos = player1x.h
   dim p2_ypos = player1y.i
   dim p2_xspeed = j
   dim p2_yspeed = k
   dim p2_paddle_dir = l          ; Last paddle direction (0-7)
   dim p2_state = m               ; bit 0=button held, bit 1=catch cooldown
   dim p2_timer = n               ; button hold timer

   ; Ball (using simple integers)
   dim ball_xvel = o
   dim ball_yvel = p
   dim ball_state = q             ; bit 0=attached to p1, bit 1=attached to p2
   dim ball_speed_timer = r       ; countdown for high speed duration
   dim frame_toggle = s           ; for alternating frame collision detection

   ; Game state
   dim game_state = t             ; 0=playing, 1=death cooldown
   dim death_timer = u            ; countdown to reset
   dim p1_alive = v               ; 0=dead, 1=alive
   dim p2_alive = w               ; 0=dead, 1=alive
   dim hold_frames = x            ; Shared frame counter for half-second ticks (0-29)

   ; Constants
   const PLAYER_SPEED = 1         ; Pixels per frame
   const FAST_BALL_DURATION = 240 ; 4 seconds at 60fps


   ;***************************************************************
   ;  Initialize game
   ;***************************************************************
__Game_Init
   ; Start positions (opposite corners)
   p1_xpos = 40 : p1_ypos = 50
   p2_xpos = 120 : p2_ypos = 50

   ; Reset player colors
   COLUP0 = $96 : COLUP1 = $34

   ; Initial paddle directions (East and West)
   p1_paddle_dir = 2 : p2_paddle_dir = 6

   ; Both players alive and clear all states
   p1_alive = 1 : p2_alive = 1
   p1_state = 0 : p2_state = 0
   p1_timer = 0 : p2_timer = 0
   game_state = 0

   ; Ball spawns center, launches in random direction at normal speed
   ballx = 80 : bally = 45
   ballheight = 1
   ball_state = 0  ; Free (not attached)
   ball_speed_timer = 0

   ; Random initial direction (0-7 for 8 directions)
   temp1 = rand & 7
   gosub __Set_Ball_Direction_Simple



   ;***************************************************************
   ;  Define ship sprite (13 pixels tall, full shields)
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
   ;  Define playfield border
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
   ................................
end


__Main_Loop

   ;***************************************************************
   ;  Set colors
   ;***************************************************************
   COLUBK = $00 : COLUPF = $0E
   if p1_alive then COLUP0 = $96
   if p2_alive then COLUP1 = $34

   ;***************************************************************
   ;  Check for death and handle reset timer
   ;***************************************************************
   if game_state = 1 then goto __Death_Countdown

   ;***************************************************************
   ;  Handle Player 1 controls - X axis with pfread() collision
   ;***************************************************************
   ; Only process if alive
   if !p1_alive then goto __Skip_P1_Controls

   ; Check for RIGHT movement
   if joy0right then gosub __P1_Move_Right bank2

   ; Check for LEFT movement
   if joy0left then gosub __P1_Move_Left bank2

   ;***************************************************************
   ;  Handle Player 1 controls - Y axis with pfread() collision
   ;***************************************************************
   ; Check for UP movement
   if joy0up then gosub __P1_Move_Up bank2

   ; Check for DOWN movement
   if joy0down then gosub __P1_Move_Down bank2

   ; Button (catch/launch)
   if joy0fire then gosub __P1_Button_Held else gosub __P1_Button_Released

__Skip_P1_Controls

   ;***************************************************************
   ;  Handle Player 2 controls - X axis with pfread() collision
   ;***************************************************************
   if !p2_alive then goto __Skip_P2_Controls

   ; Check for RIGHT movement
   if joy1right then gosub __P2_Move_Right bank2

   ; Check for LEFT movement
   if joy1left then gosub __P2_Move_Left bank2

   ;***************************************************************
   ;  Handle Player 2 controls - Y axis with pfread() collision
   ;***************************************************************
   ; Check for UP movement
   if joy1up then gosub __P2_Move_Up bank2

   ; Check for DOWN movement
   if joy1down then gosub __P2_Move_Down bank2

   if joy1fire then gosub __P2_Button_Held else gosub __P2_Button_Released

__Skip_P2_Controls

__Death_Ball_Movement
   ;***************************************************************
   ;  Handle ball movement (using alternating frame collision detection)
   ;***************************************************************
   if ball_state{0} then gosub __Ball_Follow_P1 : goto __Skip_Ball_Move
   if ball_state{1} then gosub __Ball_Follow_P2 : goto __Skip_Ball_Move

   ; Ball is free - use alternating frame collision pattern
   frame_toggle = frame_toggle + 1
   temp1 = frame_toggle & 1
   if temp1 then goto __Ball_Odd_Frame

   ; Even frame: check Y collisions, move X
   if collision(ball,playfield) then ball_yvel = 0 - ball_yvel : bally = bally + ball_yvel
   ballx = ballx + ball_xvel

   ; Keep ball in bounds
   if ballx < 10 then ballx = 10 : ball_xvel = 0 - ball_xvel
   if ballx > 150 then ballx = 150 : ball_xvel = 0 - ball_xvel

   goto __Skip_Ball_Move

__Ball_Odd_Frame
   ; Odd frame: check X collisions, move Y
   if collision(ball,playfield) then ball_xvel = 0 - ball_xvel : ballx = ballx + ball_xvel
   bally = bally + ball_yvel

   ; Keep ball in bounds
   if bally < 10 then bally = 10 : ball_yvel = 0 - ball_yvel
   if bally > 85 then bally = 85 : ball_yvel = 0 - ball_yvel

__Skip_Ball_Move

   ;***************************************************************
   ;  Update ball speed timer - slow down after fast launch
   ;***************************************************************
   if ball_speed_timer > 0 then ball_speed_timer = ball_speed_timer - 1
   if ball_speed_timer = 1 then gosub __Slow_Ball_Down

   ;***************************************************************
   ;  Update paddle (missile) positions - track last direction
   ;***************************************************************
   if p1_alive then gosub __Update_P1_Paddle else gosub __Hide_P1_Paddle
   if p2_alive then gosub __Update_P2_Paddle else gosub __Hide_P2_Paddle

   ;***************************************************************
   ;  Collision detection
   ;***************************************************************
   ; Ball vs paddles (missiles) - ONLY if ball is completely free
   if ball_state = 0 then gosub __Check_Paddle_Collisions

   ; Ball vs player cores - 1-hit kill
   if ball_state = 0 && p1_alive && collision(ball,player0) then gosub __P1_Destroyed
   if ball_state = 0 && p2_alive && collision(ball,player1) then gosub __P2_Destroyed

   ; Player vs player collision (just stop for now)
   if collision(player0,player1) then p1_xspeed = 0 : p1_yspeed = 0 : p2_xspeed = 0 : p2_yspeed = 0

   ;***************************************************************
   ;  Update timers
   ;***************************************************************
   ; P1 cooldown timer
   if p1_state{1} then p1_timer = p1_timer - 1
   if p1_timer = 0 then p1_state{1} = 0

   ; P2 cooldown timer
   if p2_state{1} then p2_timer = p2_timer - 1
   if p2_timer = 0 then p2_state{1} = 0

   ballheight = 1
   drawscreen
   goto __Main_Loop


   ;***************************************************************
   ;  Death countdown - skip controls but keep ball/paddles active
   ;***************************************************************
__Death_Countdown
   death_timer = death_timer - 1
   if death_timer = 0 then goto __Game_Init
   ; Skip to ball movement (bypassing controls)
   goto __Death_Ball_Movement


   ;***************************************************************
   ;  SUBROUTINES
   ;***************************************************************

   ;***************************************************************
   ;  Player destruction
   ;***************************************************************
__P1_Destroyed
   p1_alive = 0
   player0x = 0 : player0y = 0  ; Move off screen
   ball_state = 0  ; Release ball if attached
   game_state = 1
   death_timer = 180  ; 3 second countdown
   return

__P2_Destroyed
   p2_alive = 0
   player1x = 0 : player1y = 0  ; Move off screen
   ball_state = 0  ; Release ball if attached
   game_state = 1
   death_timer = 180  ; 3 second countdown
   return


   ;***************************************************************
   ;  Button handling
   ;***************************************************************
__P1_Button_Held
   ; If ball is attached, count frames
   if ball_state{0} then hold_frames = hold_frames + 1

   ; Every 30 frames = 1 half-second, increment timer and reset counter
   if hold_frames >= 30 then hold_frames = 0 : p1_timer = p1_timer + 1

   ; Auto-launch after 10 half-seconds (5 seconds) - only if not in cooldown
   if p1_timer >= 10 && !p1_state{1} then gosub __P1_Auto_Launch

   p1_state{0} = 1  ; Button is held
   return

__P1_Button_Released
   ; Launch ball if attached
   if ball_state{0} then gosub __P1_Launch_Ball
   ; Always clear button state when released
   p1_state{0} = 0
   return

__P2_Button_Held
   ; If ball is attached, count frames
   if ball_state{1} then hold_frames = hold_frames + 1

   ; Every 30 frames = 1 half-second, increment timer and reset counter
   if hold_frames >= 30 then hold_frames = 0 : p2_timer = p2_timer + 1

   ; Auto-launch after 10 half-seconds (5 seconds) - only if not in cooldown
   if p2_timer >= 10 && !p2_state{1} then gosub __P2_Auto_Launch

   p2_state{0} = 1
   return

__P2_Button_Released
   if ball_state{1} then gosub __P2_Launch_Ball
   p2_state{0} = 0
   return


   ;***************************************************************
   ;  Launch ball - use current paddle direction
   ;***************************************************************
__P1_Launch_Ball
   ball_state = 0  ; Detach from P1
   temp1 = p1_paddle_dir  ; Use stored paddle direction
   gosub __Set_Ball_Direction_Fast
   ball_speed_timer = FAST_BALL_DURATION
   ; Set cooldown
   p1_state{1} = 1
   p1_timer = 30
   return

__P2_Launch_Ball
   ball_state = 0  ; Detach from P2
   temp1 = p2_paddle_dir  ; Use stored paddle direction
   gosub __Set_Ball_Direction_Fast
   ball_speed_timer = FAST_BALL_DURATION
   p2_state{1} = 1
   p2_timer = 30
   return

__P1_Auto_Launch
   gosub __P1_Launch_Ball
   p1_timer = 180   ; 3 second cooldown for auto-launch penalty
   return

__P2_Auto_Launch
   gosub __P2_Launch_Ball
   p2_timer = 180
   return


   ;***************************************************************
   ;  Slow ball down from fast (2) to normal (1) speed
   ;***************************************************************
__Slow_Ball_Down
   ; Reduce each velocity component by half
   if ball_xvel > 128 then ball_xvel = 255 : goto __SBD_Y  ; Was negative, make -1
   if ball_xvel > 0 then ball_xvel = 1  ; Was positive, make 1
__SBD_Y
   if ball_yvel > 128 then ball_yvel = 255 : goto __SBD_Done  ; Was negative, make -1
   if ball_yvel > 0 then ball_yvel = 1  ; Was positive, make 1
__SBD_Done
   ball_speed_timer = 0
   return


   ;***************************************************************
   ;  Set ball direction - Simple version for 8 directions
   ;  temp1 = 0-7 for direction, normal speed (1 pixel/frame)
   ;  0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SW, 6=W, 7=NW
   ;***************************************************************
__Set_Ball_Direction_Simple
   on temp1 goto __BDS0 __BDS1 __BDS2 __BDS3 __BDS4 __BDS5 __BDS6 __BDS7

__BDS0  ; North
   ball_xvel = 0 : ball_yvel = 255 : return  ; -1 in unsigned
__BDS1  ; NE
   ball_xvel = 1 : ball_yvel = 255 : return
__BDS2  ; East
   ball_xvel = 1 : ball_yvel = 0 : return
__BDS3  ; SE
   ball_xvel = 1 : ball_yvel = 1 : return
__BDS4  ; South
   ball_xvel = 0 : ball_yvel = 1 : return
__BDS5  ; SW
   ball_xvel = 255 : ball_yvel = 1 : return  ; -1 in unsigned
__BDS6  ; West
   ball_xvel = 255 : ball_yvel = 0 : return
__BDS7  ; NW
   ball_xvel = 255 : ball_yvel = 255 : return


   ;***************************************************************
   ;  Set ball direction - Fast version for launches (2 pixels/frame)
   ;  temp1 = 0-7 for direction
   ;***************************************************************
__Set_Ball_Direction_Fast
   on temp1 goto __BDF0 __BDF1 __BDF2 __BDF3 __BDF4 __BDF5 __BDF6 __BDF7

__BDF0  ; North
   ball_xvel = 0 : ball_yvel = 254 : return  ; -2 in unsigned
__BDF1  ; NE
   ball_xvel = 2 : ball_yvel = 254 : return
__BDF2  ; East
   ball_xvel = 2 : ball_yvel = 0 : return
__BDF3  ; SE
   ball_xvel = 2 : ball_yvel = 2 : return
__BDF4  ; South
   ball_xvel = 0 : ball_yvel = 2 : return
__BDF5  ; SW
   ball_xvel = 254 : ball_yvel = 2 : return  ; -2 in unsigned
__BDF6  ; West
   ball_xvel = 254 : ball_yvel = 0 : return
__BDF7  ; NW
   ball_xvel = 254 : ball_yvel = 254 : return


   ;***************************************************************
   ;  Ball follow player (when attached) - use stored paddle direction
   ;  Ball positioned +2 pixels beyond paddle for safety
   ;***************************************************************
__Ball_Follow_P1
   temp1 = p1_paddle_dir
   on temp1 goto __BP1_N __BP1_NE __BP1_E __BP1_SE __BP1_S __BP1_SW __BP1_W __BP1_NW

__BP1_N
   ballx = player0x + 10 : bally = player0y - 20 : return
__BP1_NE
   ballx = player0x + 21 : bally = player0y - 17 : return
__BP1_E
   ballx = player0x + 24 : bally = player0y - 6 : return
__BP1_SE
   ballx = player0x + 21 : bally = player0y + 5 : return
__BP1_S
   ballx = player0x + 10 : bally = player0y + 7 : return
__BP1_SW
   ballx = player0x - 3 : bally = player0y + 5 : return
__BP1_W
   ballx = player0x - 5 : bally = player0y - 6 : return
__BP1_NW
   ballx = player0x - 3 : bally = player0y - 17 : return

__Ball_Follow_P2
   temp1 = p2_paddle_dir
   on temp1 goto __BP2_N __BP2_NE __BP2_E __BP2_SE __BP2_S __BP2_SW __BP2_W __BP2_NW

__BP2_N
   ballx = player1x + 10 : bally = player1y - 20 : return
__BP2_NE
   ballx = player1x + 21 : bally = player1y - 17 : return
__BP2_E
   ballx = player1x + 24 : bally = player1y - 6 : return
__BP2_SE
   ballx = player1x + 21 : bally = player1y + 5 : return
__BP2_S
   ballx = player1x + 10 : bally = player1y + 7 : return
__BP2_SW
   ballx = player1x - 3 : bally = player1y + 5 : return
__BP2_W
   ballx = player1x - 5 : bally = player1y - 6 : return
__BP2_NW
   ballx = player1x - 3 : bally = player1y - 17 : return


   ;***************************************************************
   ;  Update paddle positions - track direction, use stored when no input
   ;  Paddle radius increased by 1 pixel from v25
   ;***************************************************************
__Update_P1_Paddle
   ; Check joystick and update direction if input detected
   ; Priority: diagonals first, then cardinals
   if joy0up && joy0right then p1_paddle_dir = 1 : goto __P1_Set_Pos
   if joy0down && joy0right then p1_paddle_dir = 3 : goto __P1_Set_Pos
   if joy0down && joy0left then p1_paddle_dir = 5 : goto __P1_Set_Pos
   if joy0up && joy0left then p1_paddle_dir = 7 : goto __P1_Set_Pos
   if joy0up then p1_paddle_dir = 0 : goto __P1_Set_Pos
   if joy0right then p1_paddle_dir = 2 : goto __P1_Set_Pos
   if joy0down then p1_paddle_dir = 4 : goto __P1_Set_Pos
   if joy0left then p1_paddle_dir = 6 : goto __P1_Set_Pos
   ; No input - use stored direction

__P1_Set_Pos
   temp1 = p1_paddle_dir
   on temp1 goto __MP1_N __MP1_NE __MP1_E __MP1_SE __MP1_S __MP1_SW __MP1_W __MP1_NW

__MP1_N
   missile0x = player0x + 6 : missile0y = player0y - 14 : goto __MP1_Done
__MP1_NE
   missile0x = player0x + 13 : missile0y = player0y - 11 : goto __MP1_Done
__MP1_E
   missile0x = player0x + 15 : missile0y = player0y - 4 : goto __MP1_Done
__MP1_SE
   missile0x = player0x + 13 : missile0y = player0y + 3 : goto __MP1_Done
__MP1_S
   missile0x = player0x + 6 : missile0y = player0y + 5 : goto __MP1_Done
__MP1_SW
   missile0x = player0x - 1 : missile0y = player0y + 3 : goto __MP1_Done
__MP1_W
   missile0x = player0x - 3 : missile0y = player0y - 4 : goto __MP1_Done
__MP1_NW
   missile0x = player0x - 1 : missile0y = player0y - 11 : goto __MP1_Done

__MP1_Done
   missile0height = 4
   NUSIZ0 = $35
   return

__Update_P2_Paddle
   ; Check joystick and update direction if input detected
   if joy1up && joy1right then p2_paddle_dir = 1 : goto __P2_Set_Pos
   if joy1down && joy1right then p2_paddle_dir = 3 : goto __P2_Set_Pos
   if joy1down && joy1left then p2_paddle_dir = 5 : goto __P2_Set_Pos
   if joy1up && joy1left then p2_paddle_dir = 7 : goto __P2_Set_Pos
   if joy1up then p2_paddle_dir = 0 : goto __P2_Set_Pos
   if joy1right then p2_paddle_dir = 2 : goto __P2_Set_Pos
   if joy1down then p2_paddle_dir = 4 : goto __P2_Set_Pos
   if joy1left then p2_paddle_dir = 6 : goto __P2_Set_Pos
   ; No input - use stored direction

__P2_Set_Pos
   temp1 = p2_paddle_dir
   on temp1 goto __MP2_N __MP2_NE __MP2_E __MP2_SE __MP2_S __MP2_SW __MP2_W __MP2_NW

__MP2_N
   missile1x = player1x + 6 : missile1y = player1y - 14 : goto __MP2_Done
__MP2_NE
   missile1x = player1x + 13 : missile1y = player1y - 11 : goto __MP2_Done
__MP2_E
   missile1x = player1x + 15 : missile1y = player1y - 4 : goto __MP2_Done
__MP2_SE
   missile1x = player1x + 13 : missile1y = player1y + 3 : goto __MP2_Done
__MP2_S
   missile1x = player1x + 6 : missile1y = player1y + 5 : goto __MP2_Done
__MP2_SW
   missile1x = player1x - 1 : missile1y = player1y + 3 : goto __MP2_Done
__MP2_W
   missile1x = player1x - 3 : missile1y = player1y - 4 : goto __MP2_Done
__MP2_NW
   missile1x = player1x - 1 : missile1y = player1y - 11 : goto __MP2_Done

__MP2_Done
   missile1height = 4
   NUSIZ1 = $35
   return

__Hide_P1_Paddle
   missile0height = 0
   missile0x = 0
   missile0y = 0
   return

__Hide_P2_Paddle
   missile1height = 0
   missile1x = 0
   missile1y = 0
   return


   ;***************************************************************
   ;  Collision handling
   ;***************************************************************


   ;***************************************************************
   ;  Check paddle collisions with ball
   ;***************************************************************
__Check_Paddle_Collisions
   ; Check P1 paddle (missile0)
   if p1_alive && collision(ball,missile0) then gosub __Ball_Hit_P1_Paddle

   ; Check P2 paddle (missile1)
   if p2_alive && collision(ball,missile1) then gosub __Ball_Hit_P2_Paddle
   return

__Ball_Hit_P1_Paddle
   ; Check if P1 is holding button and not in cooldown
   if p1_state{0} && !p1_state{1} then ball_state = 1 : p1_timer = 0 : hold_frames = 0 : return

   ; Otherwise bounce ball and push it away slightly
   ball_xvel = 0 - ball_xvel
   ball_yvel = 0 - ball_yvel
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return

__Ball_Hit_P2_Paddle
   ; Check if P2 is holding button and not in cooldown
   if p2_state{0} && !p2_state{1} then ball_state = 2 : p2_timer = 0 : hold_frames = 0 : return

   ; Otherwise bounce ball and push it away
   ball_xvel = 0 - ball_xvel
   ball_yvel = 0 - ball_yvel
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return


   bank 2


   ;***************************************************************
   ;  Player 1 Movement Subroutines (pfread collision)
   ;  Sprite: 8 pixels wide, 13 pixels tall
   ;  Bank 2 contains all movement subroutines to free up bank 1 space
   ;***************************************************************
__P1_Move_Right
   ; Check right edge of sprite (multiple Y points)
   temp1 = (player0x + 1) / 4        ; Right edge X coord
   temp2 = (player0y - 1) / 8        ; Top Y coord
   temp3 = (player0y - 7) / 8        ; Middle Y coord
   temp4 = (player0y - 13) / 8       ; Bottom Y coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp1 < 32 && temp2 < 12 then if pfread(temp1, temp2) then return
   if temp1 < 32 && temp3 < 12 then if pfread(temp1, temp3) then return
   if temp1 < 32 && temp4 < 12 then if pfread(temp1, temp4) then return

   ; Safe to move
   player0x = player0x + PLAYER_SPEED
   return

__P1_Move_Left
   ; Check left edge of sprite (multiple Y points)
   temp1 = (player0x - 1) / 4        ; Left edge X coord
   temp2 = (player0y - 1) / 8        ; Top Y coord
   temp3 = (player0y - 7) / 8        ; Middle Y coord
   temp4 = (player0y - 13) / 8       ; Bottom Y coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp1 < 32 && temp2 < 12 then if pfread(temp1, temp2) then return
   if temp1 < 32 && temp3 < 12 then if pfread(temp1, temp3) then return
   if temp1 < 32 && temp4 < 12 then if pfread(temp1, temp4) then return

   ; Safe to move
   player0x = player0x - PLAYER_SPEED
   return

__P1_Move_Up
   ; Check top edge of sprite (multiple X points)
   temp1 = (player0y - 1) / 8        ; Top edge Y coord
   temp2 = (player0x - 4) / 4        ; Left X coord
   temp3 = player0x / 4              ; Center X coord
   temp4 = (player0x + 4) / 4        ; Right X coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp2 < 32 && temp1 < 12 then if pfread(temp2, temp1) then return
   if temp3 < 32 && temp1 < 12 then if pfread(temp3, temp1) then return
   if temp4 < 32 && temp1 < 12 then if pfread(temp4, temp1) then return

   ; Safe to move
   player0y = player0y - PLAYER_SPEED
   return

__P1_Move_Down
   ; Check bottom edge of sprite (multiple X points)
   temp1 = (player0y - 13) / 8       ; Bottom edge Y coord
   temp2 = (player0x - 4) / 4        ; Left X coord
   temp3 = player0x / 4              ; Center X coord
   temp4 = (player0x + 4) / 4        ; Right X coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp2 < 32 && temp1 < 12 then if pfread(temp2, temp1) then return
   if temp3 < 32 && temp1 < 12 then if pfread(temp3, temp1) then return
   if temp4 < 32 && temp1 < 12 then if pfread(temp4, temp1) then return

   ; Safe to move
   player0y = player0y + PLAYER_SPEED
   return


   ;***************************************************************
   ;  Player 2 Movement Subroutines (pfread collision)
   ;  Sprite: 8 pixels wide, 13 pixels tall
   ;***************************************************************
__P2_Move_Right
   ; Check right edge of sprite (multiple Y points)
   temp1 = (player1x + 1) / 4        ; Right edge X coord
   temp2 = (player1y - 1) / 8        ; Top Y coord
   temp3 = (player1y - 7) / 8        ; Middle Y coord
   temp4 = (player1y - 13) / 8       ; Bottom Y coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp1 < 32 && temp2 < 12 then if pfread(temp1, temp2) then return
   if temp1 < 32 && temp3 < 12 then if pfread(temp1, temp3) then return
   if temp1 < 32 && temp4 < 12 then if pfread(temp1, temp4) then return

   ; Safe to move
   player1x = player1x + PLAYER_SPEED
   return

__P2_Move_Left
   ; Check left edge of sprite (multiple Y points)
   temp1 = (player1x - 1) / 4        ; Left edge X coord
   temp2 = (player1y - 1) / 8        ; Top Y coord
   temp3 = (player1y - 7) / 8        ; Middle Y coord
   temp4 = (player1y - 13) / 8       ; Bottom Y coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp1 < 32 && temp2 < 12 then if pfread(temp1, temp2) then return
   if temp1 < 32 && temp3 < 12 then if pfread(temp1, temp3) then return
   if temp1 < 32 && temp4 < 12 then if pfread(temp1, temp4) then return

   ; Safe to move
   player1x = player1x - PLAYER_SPEED
   return

__P2_Move_Up
   ; Check top edge of sprite (multiple X points)
   temp1 = (player1y - 1) / 8        ; Top edge Y coord
   temp2 = (player1x - 4) / 4        ; Left X coord
   temp3 = player1x / 4              ; Center X coord
   temp4 = (player1x + 4) / 4        ; Right X coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp2 < 32 && temp1 < 12 then if pfread(temp2, temp1) then return
   if temp3 < 32 && temp1 < 12 then if pfread(temp3, temp1) then return
   if temp4 < 32 && temp1 < 12 then if pfread(temp4, temp1) then return

   ; Safe to move
   player1y = player1y - PLAYER_SPEED
   return

__P2_Move_Down
   ; Check bottom edge of sprite (multiple X points)
   temp1 = (player1y - 13) / 8       ; Bottom edge Y coord
   temp2 = (player1x - 4) / 4        ; Left X coord
   temp3 = player1x / 4              ; Center X coord
   temp4 = (player1x + 4) / 4        ; Right X coord

   ; Skip movement if any point hits playfield (validate X and Y bounds)
   if temp2 < 32 && temp1 < 12 then if pfread(temp2, temp1) then return
   if temp3 < 32 && temp1 < 12 then if pfread(temp3, temp1) then return
   if temp4 < 32 && temp1 < 12 then if pfread(temp4, temp1) then return

   ; Safe to move
   player1y = player1y + PLAYER_SPEED
   return
