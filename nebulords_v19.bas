   ;***************************************************************
   ;  NEBULORDS - Warlords-style Space Combat
   ;  Version 19 - 8-Direction Movement + 8-Position Discrete Paddle Placement
   ;  Joystick = 8-direction movement, Paddle uses discrete coordinates
   ;***************************************************************

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   ; Player 1
   dim p1_xpos = player0x.a
   dim p1_ypos = player0y.b
   dim p1_xspeed = c              ; Current frame X movement
   dim p1_yspeed = d              ; Current frame Y movement
   dim p1_direction = e           ; 0-7 for 8 directions - remembers last move direction
   dim p1_shields = f             ; bit flags for shield state (future)
   dim p1_state = g               ; bit 0=button held, bit 1=catch cooldown
   dim p1_timer = h               ; button hold timer

   ; Player 2
   dim p2_xpos = player1x.i
   dim p2_ypos = player1y.j
   dim p2_xspeed = k
   dim p2_yspeed = l
   dim p2_direction = m           ; 0-7
   dim p2_shields = n             ; bit flags (future)
   dim p2_state = o               ; bit 0=button held, bit 1=catch cooldown
   dim p2_timer = p               ; button hold timer

   ; Ball (using simple integers)
   dim ball_xvel = q
   dim ball_yvel = r
   dim ball_state = s             ; bit 0=attached to p1, bit 1=attached to p2
   dim ball_speed_timer = t       ; countdown for high speed duration
   dim frame_toggle = u           ; for alternating frame collision detection

   ; Game state
   dim game_state = var0          ; 0=playing, 1=death cooldown
   dim death_timer = var1         ; countdown to reset
   dim p1_alive = var2            ; 0=dead, 1=alive
   dim p2_alive = var3            ; 0=dead, 1=alive

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

   ; Initial directions (East and West)
   p1_direction = 2  ; East
   p2_direction = 6  ; West

   ; Reset player colors
   COLUP0 = $96 : COLUP1 = $34

   ; Full shields
   p1_shields = 15 : p2_shields = 15

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
   COLUBK = $00 : COLUPF = $0E : COLUP0 = $96 : COLUP1 = $34

   ;***************************************************************
   ;  Check for death and handle reset timer
   ;***************************************************************
   if game_state = 1 then goto __Death_Countdown

   ;***************************************************************
   ;  Handle Player 1 controls - X axis first
   ;***************************************************************
   ; Only process if alive
   if !p1_alive then goto __Skip_P1_Controls

   ; Handle X collision bounce
   if p1_xspeed && collision(player0, playfield) then p1_xspeed = 0 - p1_xspeed : player0x = player0x + p1_xspeed

   ; Reset speed
   p1_xspeed = 0

   ; Check joystick for X movement
   if joy0right then p1_xspeed = PLAYER_SPEED
   if joy0left then p1_xspeed = 0 - PLAYER_SPEED

   ; Apply X movement
   player0x = player0x + p1_xspeed

   ;***************************************************************
   ;  Handle Player 1 controls - Y axis
   ;***************************************************************
   ; Handle Y collision bounce
   if p1_yspeed && collision(player0, playfield) then p1_yspeed = 0 - p1_yspeed : player0y = player0y + p1_yspeed

   ; Reset speed
   p1_yspeed = 0

   ; Check joystick for Y movement
   if joy0down then p1_yspeed = PLAYER_SPEED
   if joy0up then p1_yspeed = 0 - PLAYER_SPEED

   ; Apply Y movement
   player0y = player0y + p1_yspeed

   ; Update paddle direction based on movement
   if p1_xspeed || p1_yspeed then gosub __Update_P1_Direction

   ; Button (catch/launch)
   if joy0fire then gosub __P1_Button_Held else gosub __P1_Button_Released

__Skip_P1_Controls

   ;***************************************************************
   ;  Handle Player 2 controls - X axis
   ;***************************************************************
   if !p2_alive then goto __Skip_P2_Controls

   if p2_xspeed && collision(player1, playfield) then p2_xspeed = 0 - p2_xspeed : player1x = player1x + p2_xspeed
   p2_xspeed = 0
   if joy1right then p2_xspeed = PLAYER_SPEED
   if joy1left then p2_xspeed = 0 - PLAYER_SPEED
   player1x = player1x + p2_xspeed

   ;***************************************************************
   ;  Handle Player 2 controls - Y axis
   ;***************************************************************
   if p2_yspeed && collision(player1, playfield) then p2_yspeed = 0 - p2_yspeed : player1y = player1y + p2_yspeed
   p2_yspeed = 0
   if joy1down then p2_yspeed = PLAYER_SPEED
   if joy1up then p2_yspeed = 0 - PLAYER_SPEED
   player1y = player1y + p2_yspeed

   ; Update paddle direction
   if p2_xspeed || p2_yspeed then gosub __Update_P2_Direction

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
   ;  Update paddle (missile) positions
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
   player0x = 0 : player0y = 0  ; Move to corner
   COLUP0 = 0  ; Make invisible by setting color to background
   ball_state = 0  ; Release ball if attached
   game_state = 1
   death_timer = 180  ; 3 second countdown
   return

__P2_Destroyed
   p2_alive = 0
   player1x = 0 : player1y = 0  ; Move to corner
   COLUP1 = 0  ; Make invisible by setting color to background
   ball_state = 0  ; Release ball if attached
   game_state = 1
   death_timer = 180  ; 3 second countdown
   return


   ;***************************************************************
   ;  Update paddle direction based on current movement (8 directions)
   ;***************************************************************
__Update_P1_Direction
   ; Determine direction from xspeed and yspeed (0-7)
   ; North/South
   if !p1_xspeed && p1_yspeed < 0 then p1_direction = 0 : return  ; N
   if !p1_xspeed && p1_yspeed > 0 then p1_direction = 4 : return  ; S

   ; East/West
   if p1_xspeed > 0 && !p1_yspeed then p1_direction = 2 : return  ; E
   if p1_xspeed < 0 && !p1_yspeed then p1_direction = 6 : return  ; W

   ; Diagonals
   if p1_xspeed > 0 && p1_yspeed < 0 then p1_direction = 1 : return  ; NE
   if p1_xspeed > 0 && p1_yspeed > 0 then p1_direction = 3 : return  ; SE
   if p1_xspeed < 0 && p1_yspeed > 0 then p1_direction = 5 : return  ; SW
   if p1_xspeed < 0 && p1_yspeed < 0 then p1_direction = 7 : return  ; NW
   return

__Update_P2_Direction
   if !p2_xspeed && p2_yspeed < 0 then p2_direction = 0 : return
   if !p2_xspeed && p2_yspeed > 0 then p2_direction = 4 : return
   if p2_xspeed > 0 && !p2_yspeed then p2_direction = 2 : return
   if p2_xspeed < 0 && !p2_yspeed then p2_direction = 6 : return
   if p2_xspeed > 0 && p2_yspeed < 0 then p2_direction = 1 : return
   if p2_xspeed > 0 && p2_yspeed > 0 then p2_direction = 3 : return
   if p2_xspeed < 0 && p2_yspeed > 0 then p2_direction = 5 : return
   if p2_xspeed < 0 && p2_yspeed < 0 then p2_direction = 7 : return
   return


   ;***************************************************************
   ;  Button handling
   ;***************************************************************
__P1_Button_Held
   ; If ball is attached, increment timer
   if ball_state{0} then p1_timer = p1_timer + 1

   ; Check for max hold
   if p1_timer > 120 then gosub __P1_Auto_Launch

   p1_state{0} = 1  ; Button is held
   return

__P1_Button_Released
   ; Launch ball if attached
   if ball_state{0} then gosub __P1_Launch_Ball : goto __P1BR_Done
   ; Only clear timer if ball was not attached (no launch)
   p1_timer = 0
__P1BR_Done
   p1_state{0} = 0  ; Button not held
   return

__P2_Button_Held
   if ball_state{1} then p2_timer = p2_timer + 1
   if p2_timer > 120 then gosub __P2_Auto_Launch
   p2_state{0} = 1
   return

__P2_Button_Released
   if ball_state{1} then gosub __P2_Launch_Ball : goto __P2BR_Done
   ; Only clear timer if ball was not attached (no launch)
   p2_timer = 0
__P2BR_Done
   p2_state{0} = 0
   return


   ;***************************************************************
   ;  Launch ball - sets direction and high speed timer
   ;***************************************************************
__P1_Launch_Ball
   ball_state = 0  ; Detach from P1
   temp1 = p1_direction  ; Use current paddle direction
   gosub __Set_Ball_Direction_Fast
   ball_speed_timer = FAST_BALL_DURATION  ; Start fast ball timer
   ; Set cooldown so ball doesn't immediately re-collide with P1
   p1_state{1} = 1
   p1_timer = 30  ; 30-frame cooldown after launch
   return

__P2_Launch_Ball
   ball_state = 0  ; Detach from P2
   temp1 = p2_direction  ; Use current paddle direction
   gosub __Set_Ball_Direction_Fast
   ball_speed_timer = FAST_BALL_DURATION  ; Start fast ball timer
   p2_state{1} = 1
   p2_timer = 30  ; 30-frame cooldown after launch
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
   ;  Ball follow player (when attached) - 8 positions
   ;***************************************************************
__Ball_Follow_P1
   ; Position ball at one of 8 positions around ship
   temp1 = p1_direction
   on temp1 goto __BP1_N __BP1_NE __BP1_E __BP1_SE __BP1_S __BP1_SW __BP1_W __BP1_NW

__BP1_N
   ballx = player0x + 4 : bally = player0y - 8 : return
__BP1_NE
   ballx = player0x + 8 : bally = player0y - 6 : return
__BP1_E
   ballx = player0x + 10 : bally = player0y : return
__BP1_SE
   ballx = player0x + 8 : bally = player0y + 6 : return
__BP1_S
   ballx = player0x + 4 : bally = player0y + 8 : return
__BP1_SW
   ballx = player0x - 4 : bally = player0y + 6 : return
__BP1_W
   ballx = player0x - 6 : bally = player0y : return
__BP1_NW
   ballx = player0x - 4 : bally = player0y - 6 : return

__Ball_Follow_P2
   temp1 = p2_direction
   on temp1 goto __BP2_N __BP2_NE __BP2_E __BP2_SE __BP2_S __BP2_SW __BP2_W __BP2_NW

__BP2_N
   ballx = player1x + 4 : bally = player1y - 8 : return
__BP2_NE
   ballx = player1x + 8 : bally = player1y - 6 : return
__BP2_E
   ballx = player1x + 10 : bally = player1y : return
__BP2_SE
   ballx = player1x + 8 : bally = player1y + 6 : return
__BP2_S
   ballx = player1x + 4 : bally = player1y + 8 : return
__BP2_SW
   ballx = player1x - 4 : bally = player1y + 6 : return
__BP2_W
   ballx = player1x - 6 : bally = player1y : return
__BP2_NW
   ballx = player1x - 4 : bally = player1y - 6 : return


   ;***************************************************************
   ;  Update paddle positions - 8 discrete positions
   ;***************************************************************
__Update_P1_Paddle
   ; Position missile at one of 8 positions around ship
   temp1 = p1_direction
   on temp1 goto __MP1_N __MP1_NE __MP1_E __MP1_SE __MP1_S __MP1_SW __MP1_W __MP1_NW

__MP1_N
   missile0x = player0x + 4 : missile0y = player0y - 8 : goto __MP1_Done
__MP1_NE
   missile0x = player0x + 8 : missile0y = player0y - 6 : goto __MP1_Done
__MP1_E
   missile0x = player0x + 10 : missile0y = player0y : goto __MP1_Done
__MP1_SE
   missile0x = player0x + 8 : missile0y = player0y + 6 : goto __MP1_Done
__MP1_S
   missile0x = player0x + 4 : missile0y = player0y + 8 : goto __MP1_Done
__MP1_SW
   missile0x = player0x - 4 : missile0y = player0y + 6 : goto __MP1_Done
__MP1_W
   missile0x = player0x - 6 : missile0y = player0y : goto __MP1_Done
__MP1_NW
   missile0x = player0x - 4 : missile0y = player0y - 6 : goto __MP1_Done

__MP1_Done
   missile0height = 4
   NUSIZ0 = $35
   return

__Update_P2_Paddle
   ; Position missile at one of 8 positions around ship
   temp1 = p2_direction
   on temp1 goto __MP2_N __MP2_NE __MP2_E __MP2_SE __MP2_S __MP2_SW __MP2_W __MP2_NW

__MP2_N
   missile1x = player1x + 4 : missile1y = player1y - 8 : goto __MP2_Done
__MP2_NE
   missile1x = player1x + 8 : missile1y = player1y - 6 : goto __MP2_Done
__MP2_E
   missile1x = player1x + 10 : missile1y = player1y : goto __MP2_Done
__MP2_SE
   missile1x = player1x + 8 : missile1y = player1y + 6 : goto __MP2_Done
__MP2_S
   missile1x = player1x + 4 : missile1y = player1y + 8 : goto __MP2_Done
__MP2_SW
   missile1x = player1x - 4 : missile1y = player1y + 6 : goto __MP2_Done
__MP2_W
   missile1x = player1x - 6 : missile1y = player1y : goto __MP2_Done
__MP2_NW
   missile1x = player1x - 4 : missile1y = player1y - 6 : goto __MP2_Done

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
   if p1_state{0} && !p1_state{1} then ball_state = 1 : p1_timer = 0 : return

   ; Otherwise bounce ball and push it away slightly
   ball_xvel = 0 - ball_xvel
   ball_yvel = 0 - ball_yvel
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return

__Ball_Hit_P2_Paddle
   ; Check if P2 is holding button and not in cooldown
   if p2_state{0} && !p2_state{1} then ball_state = 2 : p2_timer = 0 : return

   ; Otherwise bounce ball and push it away
   ball_xvel = 0 - ball_xvel
   ball_yvel = 0 - ball_yvel
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return
