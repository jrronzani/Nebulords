   ;***************************************************************
   ;  NEBULORDS - Warlords-style Space Combat
   ;  Version 17 - Bug fixes for paddle positioning, ball shooting, and core hits
   ;***************************************************************

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   ; Player 1
   dim p1_xpos = player0x.a
   dim p1_ypos = player0y.b
   dim p1_xspeed = c          ; Current frame X movement
   dim p1_yspeed = d          ; Current frame Y movement
   dim p1_direction = e       ; 0-15 (16 directions) - remembers last move direction
   dim p1_shields = f         ; bit flags for shield state (future)
   dim p1_state = g           ; bit 0=button held, bit 1=catch cooldown
   dim p1_timer = h           ; button hold timer
   dim p1_alive = var0        ; 0=dead, 1=alive

   ; Player 2
   dim p2_xpos = player1x.i
   dim p2_ypos = player1y.j
   dim p2_xspeed = k
   dim p2_yspeed = l
   dim p2_direction = m       ; 0-15
   dim p2_shields = n         ; bit flags (future)
   dim p2_state = o           ; bit 0=button held, bit 1=catch cooldown
   dim p2_timer = p           ; button hold timer
   dim p2_alive = var1        ; 0=dead, 1=alive

   ; Ball (using simple integers, not fixed-point)
   dim ball_xvel = q
   dim ball_yvel = r
   dim ball_state = s         ; bit 0=attached to p1, bit 1=attached to p2
   dim ball_speed_timer = t   ; countdown for high speed duration
   dim ball_launch_dir = var2 ; locked direction when ball is launched
   dim frame_toggle = u       ; for alternating frame collision detection

   ; Constants
   const PLAYER_SPEED = 1     ; Pixels per frame (easy to change!)
   const FAST_BALL_DURATION = 180  ; 3 seconds at 60fps


   ;***************************************************************
   ;  Initialize game
   ;***************************************************************
   ; Start positions (opposite corners)
   p1_xpos = 40 : p1_ypos = 50
   p2_xpos = 120 : p2_ypos = 50

   ; Initial directions (East and West)
   p1_direction = 4  ; East
   p2_direction = 12 ; West

   ; Full shields
   p1_shields = 15 : p2_shields = 15

   ; Both players alive
   p1_alive = 1 : p2_alive = 1

   ; Ball spawns center, launches in random direction at normal speed
   ballx = 80 : bally = 45
   ballheight = 1
   ball_state = 0  ; Free (not attached)
   ball_speed_timer = 0
   ball_launch_dir = 0

   ; Random initial direction (simple integer velocities)
   temp1 = rand & 7  ; 0-7 for 8 directions
   gosub __Set_Ball_Direction_Simple



   ;***************************************************************
   ;  Define ship sprite (12 pixels tall, full shields)
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
   if p1_alive then gosub __Update_P1_Paddle
   if p2_alive then gosub __Update_P2_Paddle

   ;***************************************************************
   ;  Collision detection
   ;***************************************************************
   ; Ball vs paddles (missiles) - ONLY if ball is completely free
   if ball_state = 0 then gosub __Check_Paddle_Collisions

   ; Ball vs player cores - 1-hit kill
   if ball_state = 0 && p1_alive && collision(ball,player0) then p1_alive = 0 : player0x = 0 : player0y = 0
   if ball_state = 0 && p2_alive && collision(ball,player1) then p2_alive = 0 : player1x = 0 : player1y = 0

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
   ;  SUBROUTINES
   ;***************************************************************

   ;***************************************************************
   ;  Update paddle direction based on current movement
   ;***************************************************************
__Update_P1_Direction
   ; Determine direction from xspeed and yspeed
   ; North/South
   if !p1_xspeed && p1_yspeed < 0 then p1_direction = 0 : return  ; N
   if !p1_xspeed && p1_yspeed > 0 then p1_direction = 8 : return  ; S

   ; East/West
   if p1_xspeed > 0 && !p1_yspeed then p1_direction = 4 : return  ; E
   if p1_xspeed < 0 && !p1_yspeed then p1_direction = 12 : return ; W

   ; Diagonals
   if p1_xspeed > 0 && p1_yspeed < 0 then p1_direction = 2 : return  ; NE
   if p1_xspeed > 0 && p1_yspeed > 0 then p1_direction = 6 : return  ; SE
   if p1_xspeed < 0 && p1_yspeed > 0 then p1_direction = 10 : return ; SW
   if p1_xspeed < 0 && p1_yspeed < 0 then p1_direction = 14 : return ; NW
   return

__Update_P2_Direction
   if !p2_xspeed && p2_yspeed < 0 then p2_direction = 0 : return
   if !p2_xspeed && p2_yspeed > 0 then p2_direction = 8 : return
   if p2_xspeed > 0 && !p2_yspeed then p2_direction = 4 : return
   if p2_xspeed < 0 && !p2_yspeed then p2_direction = 12 : return
   if p2_xspeed > 0 && p2_yspeed < 0 then p2_direction = 2 : return
   if p2_xspeed > 0 && p2_yspeed > 0 then p2_direction = 6 : return
   if p2_xspeed < 0 && p2_yspeed > 0 then p2_direction = 10 : return
   if p2_xspeed < 0 && p2_yspeed < 0 then p2_direction = 14 : return
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
   if ball_state{0} then gosub __P1_Launch_Ball
   p1_state{0} = 0  ; Button not held
   p1_timer = 0
   return

__P2_Button_Held
   if ball_state{1} then p2_timer = p2_timer + 1
   if p2_timer > 120 then gosub __P2_Auto_Launch
   p2_state{0} = 1
   return

__P2_Button_Released
   if ball_state{1} then gosub __P2_Launch_Ball
   p2_state{0} = 0
   p2_timer = 0
   return


   ;***************************************************************
   ;  Launch ball - locks direction and sets high speed timer
   ;***************************************************************
__P1_Launch_Ball
   ball_state = 0  ; Detach from P1
   ball_launch_dir = p1_direction  ; Lock the launch direction
   temp1 = ball_launch_dir
   gosub __Set_Ball_Direction_Fast
   ball_speed_timer = FAST_BALL_DURATION  ; Start fast ball timer
   ; Set brief cooldown so ball doesn't immediately re-collide with P1
   p1_state{1} = 1
   p1_timer = 10  ; Brief 10-frame invincibility
   return

__P2_Launch_Ball
   ball_state = 0  ; Detach from P2
   ball_launch_dir = p2_direction  ; Lock the launch direction
   temp1 = ball_launch_dir
   gosub __Set_Ball_Direction_Fast
   ball_speed_timer = FAST_BALL_DURATION  ; Start fast ball timer
   p2_state{1} = 1
   p2_timer = 10
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
   if ball_xvel > 0 then ball_xvel = 1
   if ball_xvel < 0 then ball_xvel = 255  ; -1 in unsigned
   if ball_yvel > 0 then ball_yvel = 1
   if ball_yvel < 0 then ball_yvel = 255  ; -1 in unsigned
   ball_speed_timer = 0
   return


   ;***************************************************************
   ;  Set ball direction - Simple version for 8 directions
   ;  temp1 = 0-7 for direction, normal speed (1 pixel/frame)
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
   ;  temp1 = direction (0-15, but mapped to 8 directions)
   ;***************************************************************
__Set_Ball_Direction_Fast
   ; Map 16 directions to 8 (use cardinal and diagonals only)
   temp2 = temp1 / 2
   on temp2 goto __BDF0 __BDF1 __BDF2 __BDF3 __BDF4 __BDF5 __BDF6 __BDF7

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
   ;  Ball follow player (when attached)
   ;***************************************************************
__Ball_Follow_P1
   ; Position ball at paddle location
   temp1 = p1_direction
   gosub __Get_Offset_Position
   ballx = player0x + temp2
   bally = player0y + temp3
   return

__Ball_Follow_P2
   temp1 = p2_direction
   gosub __Get_Offset_Position
   ballx = player1x + temp2
   bally = player1y + temp3
   return


   ;***************************************************************
   ;  Get offset position for paddle/ball (returns temp2=x, temp3=y)
   ;  Positions paddle ~8 pixels from ship center in 8 directions
   ;***************************************************************
__Get_Offset_Position
   on temp1 goto __OP0 __OP1 __OP2 __OP3 __OP4 __OP5 __OP6 __OP7 __OP8 __OP9 __OP10 __OP11 __OP12 __OP13 __OP14 __OP15

__OP0  ; North (up)
   temp2 = 0 : temp3 = 248 : return  ; (0, -8)
__OP1  ; NNE
   temp2 = 4 : temp3 = 250 : return  ; (4, -6)
__OP2  ; NE (up-right)
   temp2 = 6 : temp3 = 250 : return  ; (6, -6)
__OP3  ; ENE
   temp2 = 7 : temp3 = 252 : return  ; (7, -4)
__OP4  ; East (right)
   temp2 = 8 : temp3 = 0 : return    ; (8, 0)
__OP5  ; ESE
   temp2 = 7 : temp3 = 4 : return    ; (7, 4)
__OP6  ; SE (down-right)
   temp2 = 6 : temp3 = 6 : return    ; (6, 6)
__OP7  ; SSE
   temp2 = 4 : temp3 = 6 : return    ; (4, 6)
__OP8  ; South (down)
   temp2 = 0 : temp3 = 8 : return    ; (0, 8)
__OP9  ; SSW
   temp2 = 252 : temp3 = 6 : return  ; (-4, 6)
__OP10 ; SW (down-left)
   temp2 = 250 : temp3 = 6 : return  ; (-6, 6)
__OP11 ; WSW
   temp2 = 249 : temp3 = 4 : return  ; (-7, 4)
__OP12 ; West (left)
   temp2 = 248 : temp3 = 0 : return  ; (-8, 0)
__OP13 ; WNW
   temp2 = 249 : temp3 = 252 : return ; (-7, -4)
__OP14 ; NW (up-left)
   temp2 = 250 : temp3 = 250 : return ; (-6, -6)
__OP15 ; NNW
   temp2 = 252 : temp3 = 250 : return ; (-4, -6)


   ;***************************************************************
   ;  Update paddle positions (using missiles)
   ;***************************************************************
__Update_P1_Paddle
   temp1 = p1_direction
   gosub __Get_Offset_Position

   ; Position missile0 at paddle location
   missile0x = player0x + temp2
   missile0y = player0y + temp3
   missile0height = 4
   NUSIZ0 = $35
   return

__Update_P2_Paddle
   temp1 = p2_direction
   gosub __Get_Offset_Position

   ; Position missile1 at paddle location
   missile1x = player1x + temp2
   missile1y = player1y + temp3
   missile1height = 4
   NUSIZ1 = $35
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
