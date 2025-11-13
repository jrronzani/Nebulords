   set romsize 16k

   ;***************************************************************
   ;  NEBULORDS - Warlords-style Space Combat
   ;  Version 52 - Shield damage system with 4-direction shields
   ;  Based on v51 (tight OOB boundaries)
   ;
   ;  P2 starting position set to 108 for visual symmetry
   ;  Ball respawns at top center if out of bounds for 1 second
   ;  Shield system: N, E, S, W shields break on hit
   ;  Ball only kills player if shield already broken
   ;  Shields stored in p1_state/p2_state bits 2-5
   ;
   ;  Bank 1: Init, sprites, playfield, main loop, player controls
   ;  Bank 2: Ball physics and movement
   ;  Bank 3: Reserved for scoring system
   ;  Bank 4: Reserved for future levels/modes
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
   dim p1_state = f               ; bit0=button, bit1=cooldown, bit2-5=shields (N,E,S,W)
   dim p1_timer = g               ; button hold timer

   ; Player 2
   dim p2_xpos = player1x.h
   dim p2_ypos = player1y.i
   dim p2_xspeed = j
   dim p2_yspeed = k
   dim p2_paddle_dir = l          ; Last paddle direction (0-7)
   dim p2_state = m               ; bit0=button, bit1=cooldown, bit2-5=shields (N,E,S,W)
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

   ; Out-of-bounds system
   dim oob_timer = y              ; Frames ball has been out of bounds
   dim ball_warning = z           ; Warning flash timer (ball safe during this)

   ; Constants
   const PLAYER_SPEED = 1         ; Pixels per frame
   const FAST_BALL_DURATION = 240 ; 4 seconds at 60fps (launch)
   const BOUNCE_BOOST_DURATION = 3 ; 3 frames (bounce speed boost)
   const OOB_TIMEOUT = 60         ; 1 second at 60fps
   const WARNING_DURATION = 120   ; 2 seconds at 60fps


   ;***************************************************************
   ;  Initialize game
   ;***************************************************************
__Game_Init
   ; Start positions (opposite corners)
   p1_xpos = 40 : p1_ypos = 50
   p2_xpos = 108 : p2_ypos = 50

   ; Reset player colors
   COLUP0 = $96 : COLUP1 = $34

   ; Initial paddle directions (East and West)
   p1_paddle_dir = 2 : p2_paddle_dir = 6

   ; Both players alive and initialize shields
   p1_alive = 1 : p2_alive = 1
   p1_state = 60 : p2_state = 60  ; bits 2-5 set = all shields intact (%00111100)
   p1_timer = 0 : p2_timer = 0
   game_state = 0

   ; Ball spawns center, launches in random direction at normal speed
   ballx = 80 : bally = 45
   ballheight = 1
   ball_state = 0  ; Free (not attached)
   ball_speed_timer = 0
   oob_timer = 0
   ball_warning = 0

   ; Random initial direction (0-7 for 8 directions)
   temp1 = rand & 7
   gosub __Set_Ball_Direction_Simple bank2



   ;***************************************************************
   ;  Define ship sprite (13 pixels tall, full shields)
   ;
   ;  Shield Frame System (16 total frames needed):
   ;  Shield bits: bit2=North, bit3=East, bit4=South, bit5=West
   ;  Bits 2-5 shifted right 2 = frame number (0-15)
   ;  Frame 0 (%0000): All shields broken (exposed core)
   ;  Frame 15 (%1111): All shields intact (full armor)
   ;  Example: bits=%00111100 >> 2 = 15 (all shields)
   ;
   ;  TODO: Create 16 sprite frames showing different shield states
   ;  For now, this is placeholder frame 15 (all shields intact)
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

   if joy1fire then gosub __P2_Button_Held else gosub __P2_Button_Released

__Skip_P2_Controls

__Death_Ball_Movement
   ;***************************************************************
   ;  Handle ball movement (using alternating frame collision detection)
   ;***************************************************************
   if ball_state{0} then gosub __Ball_Follow_P1 bank2 : goto __Skip_Ball_Move
   if ball_state{1} then gosub __Ball_Follow_P2 bank2 : goto __Skip_Ball_Move

   ; Ball is free - use alternating frame collision pattern
   frame_toggle = frame_toggle + 1
   temp1 = frame_toggle & 1
   if temp1 then goto __Ball_Odd_Frame

   ; Even frame: check Y collisions, move X
   if collision(ball,playfield) then ball_yvel = 0 - ball_yvel : bally = bally + ball_yvel
   ballx = ballx + ball_xvel

   ; Keep ball in bounds (emergency snap-back only)
   if ballx < 5 then ballx = 5 : ball_xvel = 0 - ball_xvel
   if ballx > 155 then ballx = 155 : ball_xvel = 0 - ball_xvel

   goto __Skip_Ball_Move

__Ball_Odd_Frame
   ; Odd frame: check X collisions, move Y
   if collision(ball,playfield) then ball_xvel = 0 - ball_xvel : ballx = ballx + ball_xvel
   bally = bally + ball_yvel

   ; Keep ball in bounds (emergency snap-back only)
   if bally < 5 then bally = 5 : ball_yvel = 0 - ball_yvel
   if bally > 90 then bally = 90 : ball_yvel = 0 - ball_yvel

__Skip_Ball_Move

   ;***************************************************************
   ;  Out-of-bounds detection and reset system
   ;***************************************************************
   ; Check if ball is out of bounds (for ALL ball states - caught or free)
   if ball_warning = 0 then gosub __Check_OOB

   ; Handle warning flash timer
   if ball_warning > 0 then gosub __Warning_Flash

   ;***************************************************************
   ;  Update ball speed timer - slow down after fast launch
   ;***************************************************************
   if ball_speed_timer > 0 then ball_speed_timer = ball_speed_timer - 1
   if ball_speed_timer = 1 then gosub __Slow_Ball_Down bank2

   ;***************************************************************
   ;  Update paddle (missile) positions - track last direction
   ;***************************************************************
   if p1_alive then gosub __Update_P1_Paddle bank2 else gosub __Hide_P1_Paddle bank2
   if p2_alive then gosub __Update_P2_Paddle bank2 else gosub __Hide_P2_Paddle bank2

   ;***************************************************************
   ;  Collision detection
   ;***************************************************************
   ; Ball vs paddles (missiles) - ONLY if ball is completely free
   if ball_state = 0 && ball_warning = 0 then gosub __Check_Paddle_Collisions bank2

   ; Ball vs player cores - shield damage system (skip during warning flash)
   if ball_state = 0 && ball_warning = 0 && p1_alive && collision(ball,player0) then gosub __P1_Hit bank2
   if ball_state = 0 && ball_warning = 0 && p2_alive && collision(ball,player1) then gosub __P2_Hit bank2

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

   ; Set ball height (unless in warning flash mode)
   if ball_warning = 0 then ballheight = 1
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
   if p1_timer >= 10 && !p1_state{1} then gosub __P1_Auto_Launch bank2

   p1_state{0} = 1  ; Button is held
   return

__P1_Button_Released
   ; Launch ball if attached
   if ball_state{0} then gosub __P1_Launch_Ball bank2
   ; Always clear button state when released
   p1_state{0} = 0
   return

__P2_Button_Held
   ; If ball is attached, count frames
   if ball_state{1} then hold_frames = hold_frames + 1

   ; Every 30 frames = 1 half-second, increment timer and reset counter
   if hold_frames >= 30 then hold_frames = 0 : p2_timer = p2_timer + 1

   ; Auto-launch after 10 half-seconds (5 seconds) - only if not in cooldown
   if p2_timer >= 10 && !p2_state{1} then gosub __P2_Auto_Launch bank2

   p2_state{0} = 1
   return

__P2_Button_Released
   if ball_state{1} then gosub __P2_Launch_Ball bank2
   p2_state{0} = 0
   return


   ;***************************************************************
   ;  Out-of-bounds detection
   ;***************************************************************
__Check_OOB
   ; Check if ball is outside playfield boundaries
   ; Very aggressive side boundaries to eliminate safe bounce zone
   ; Top/bottom moved further in to catch balls in thick playfield walls
   if ballx < 20 then goto __Ball_OOB
   if ballx > 140 then goto __Ball_OOB
   if bally < 15 then goto __Ball_OOB
   if bally > 80 then goto __Ball_OOB

   ; Ball is in bounds - reset timer
   oob_timer = 0
   return

__Ball_OOB
   ; If ball is caught, release it immediately
   if ball_state{0} then ball_state = 0 : p1_state{1} = 1 : p1_timer = 30
   if ball_state{1} then ball_state = 0 : p2_state{1} = 1 : p2_timer = 30

   ; Ball is out of bounds - increment timer
   oob_timer = oob_timer + 1

   ; Check if been out for 1 second (60 frames)
   if oob_timer >= OOB_TIMEOUT then gosub __Respawn_Ball
   return

__Respawn_Ball
   ; Reset ball to top center with slow downward movement
   ballx = 80 : bally = 15
   ball_xvel = 0 : ball_yvel = 1
   ball_state = 0  ; Make sure it's free
   ball_speed_timer = 0
   ball_warning = WARNING_DURATION  ; Start 2-second warning flash
   oob_timer = 0
   return


   ;***************************************************************
   ;  Warning flash - blink ball during safe spawn period
   ;***************************************************************
__Warning_Flash
   ; Decrement warning timer
   ball_warning = ball_warning - 1

   ; Flash ball by alternating ballheight (2 frames on, 6 frames off)
   temp1 = ball_warning & 7  ; Get 0-7 (cycles every 8 frames)
   if temp1 < 2 then ballheight = 1 else ballheight = 0
   return


   bank 2


   ;***************************************************************
   ;  BANK 2: Ball physics, movement, and collision detection
   ;***************************************************************

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
   ballx = player0x + 26 : bally = player0y - 6 : return
__BP1_SE
   ballx = player0x + 21 : bally = player0y + 5 : return
__BP1_S
   ballx = player0x + 10 : bally = player0y + 7 : return
__BP1_SW
   ballx = player0x - 3 : bally = player0y + 5 : return
__BP1_W
   ballx = player0x - 7 : bally = player0y - 6 : return
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
   ballx = player1x + 26 : bally = player1y - 6 : return
__BP2_SE
   ballx = player1x + 21 : bally = player1y + 5 : return
__BP2_S
   ballx = player1x + 10 : bally = player1y + 7 : return
__BP2_SW
   ballx = player1x - 3 : bally = player1y + 5 : return
__BP2_W
   ballx = player1x - 7 : bally = player1y - 6 : return
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
   missile0x = player0x + 17 : missile0y = player0y - 4 : goto __MP1_Done
__MP1_SE
   missile0x = player0x + 13 : missile0y = player0y + 3 : goto __MP1_Done
__MP1_S
   missile0x = player0x + 6 : missile0y = player0y + 5 : goto __MP1_Done
__MP1_SW
   missile0x = player0x - 1 : missile0y = player0y + 3 : goto __MP1_Done
__MP1_W
   missile0x = player0x - 5 : missile0y = player0y - 4 : goto __MP1_Done
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
   missile1x = player1x + 17 : missile1y = player1y - 4 : goto __MP2_Done
__MP2_SE
   missile1x = player1x + 13 : missile1y = player1y + 3 : goto __MP2_Done
__MP2_S
   missile1x = player1x + 6 : missile1y = player1y + 5 : goto __MP2_Done
__MP2_SW
   missile1x = player1x - 1 : missile1y = player1y + 3 : goto __MP2_Done
__MP2_W
   missile1x = player1x - 5 : missile1y = player1y - 4 : goto __MP2_Done
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
   ; Check if P1 is holding button and not in cooldown - CATCH
   if p1_state{0} && !p1_state{1} then ball_state = 1 : p1_timer = 0 : hold_frames = 0 : return

   ; Otherwise BOUNCE in paddle's facing direction (absolute, not relative)
   ; Set velocity based on p1_paddle_dir with speed boost
   temp1 = p1_paddle_dir
   on temp1 goto __P1B_N __P1B_NE __P1B_E __P1B_SE __P1B_S __P1B_SW __P1B_W __P1B_NW

__P1B_N   ; North - bounce UP
   ball_xvel = 0 : ball_yvel = 254 : goto __P1B_Done
__P1B_NE  ; NE - bounce UP-RIGHT
   ball_xvel = 2 : ball_yvel = 254 : goto __P1B_Done
__P1B_E   ; East - bounce RIGHT
   ball_xvel = 2 : ball_yvel = 0 : goto __P1B_Done
__P1B_SE  ; SE - bounce DOWN-RIGHT
   ball_xvel = 2 : ball_yvel = 2 : goto __P1B_Done
__P1B_S   ; South - bounce DOWN
   ball_xvel = 0 : ball_yvel = 2 : goto __P1B_Done
__P1B_SW  ; SW - bounce DOWN-LEFT
   ball_xvel = 254 : ball_yvel = 2 : goto __P1B_Done
__P1B_W   ; West - bounce LEFT
   ball_xvel = 254 : ball_yvel = 0 : goto __P1B_Done
__P1B_NW  ; NW - bounce UP-LEFT
   ball_xvel = 254 : ball_yvel = 254 : goto __P1B_Done

__P1B_Done
   ; Only set bounce boost if not already in fast mode (preserve launch timer)
   if ball_speed_timer = 0 then ball_speed_timer = BOUNCE_BOOST_DURATION
   ; Push ball away with boosted velocity
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return

__Ball_Hit_P2_Paddle
   ; Check if P2 is holding button and not in cooldown - CATCH
   if p2_state{0} && !p2_state{1} then ball_state = 2 : p2_timer = 0 : hold_frames = 0 : return

   ; Otherwise BOUNCE in paddle's facing direction (absolute, not relative)
   ; Set velocity based on p2_paddle_dir with speed boost
   temp1 = p2_paddle_dir
   on temp1 goto __P2B_N __P2B_NE __P2B_E __P2B_SE __P2B_S __P2B_SW __P2B_W __P2B_NW

__P2B_N   ; North - bounce UP
   ball_xvel = 0 : ball_yvel = 254 : goto __P2B_Done
__P2B_NE  ; NE - bounce UP-RIGHT
   ball_xvel = 2 : ball_yvel = 254 : goto __P2B_Done
__P2B_E   ; East - bounce RIGHT
   ball_xvel = 2 : ball_yvel = 0 : goto __P2B_Done
__P2B_SE  ; SE - bounce DOWN-RIGHT
   ball_xvel = 2 : ball_yvel = 2 : goto __P2B_Done
__P2B_S   ; South - bounce DOWN
   ball_xvel = 0 : ball_yvel = 2 : goto __P2B_Done
__P2B_SW  ; SW - bounce DOWN-LEFT
   ball_xvel = 254 : ball_yvel = 2 : goto __P2B_Done
__P2B_W   ; West - bounce LEFT
   ball_xvel = 254 : ball_yvel = 0 : goto __P2B_Done
__P2B_NW  ; NW - bounce UP-LEFT
   ball_xvel = 254 : ball_yvel = 254 : goto __P2B_Done

__P2B_Done
   ; Only set bounce boost if not already in fast mode (preserve launch timer)
   if ball_speed_timer = 0 then ball_speed_timer = BOUNCE_BOOST_DURATION
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return


   ;***************************************************************
   ;  Shield damage system - P1 hit by ball
   ;***************************************************************
__P1_Hit
   ; Calculate relative position (ball - player)
   temp1 = ballx - player0x  ; dx
   temp2 = bally - player0y  ; dy

   ; Get absolute values for comparison
   temp3 = temp1
   if temp3 > 128 then temp3 = 256 - temp3  ; abs(dx)
   temp4 = temp2
   if temp4 > 128 then temp4 = 256 - temp4  ; abs(dy)

   ; Determine which shield was hit (primary axis wins)
   if temp4 > temp3 then goto __P1_Vertical_Hit

   ; Horizontal hit - East(1) or West(3)
   if temp1 > 128 then temp5 = 5 else temp5 = 3  ; bit5=W, bit3=E
   goto __P1_Check_Shield

__P1_Vertical_Hit
   ; Vertical hit - North(0) or South(2)
   if temp2 > 128 then temp5 = 2 else temp5 = 4  ; bit2=N, bit4=S

__P1_Check_Shield
   ; temp5 now contains shield bit position (2-5)
   ; Check if that shield bit is set
   temp6 = 1
   temp1 = temp5
__P1_Shift_Loop
   if temp1 = 0 then goto __P1_Shift_Done
   temp6 = temp6 + temp6  ; Shift left (multiply by 2)
   temp1 = temp1 - 1
   goto __P1_Shift_Loop

__P1_Shift_Done
   ; temp6 now has bitmask (4, 8, 16, or 32)
   ; Test if shield is intact
   temp1 = p1_state & temp6
   if temp1 then goto __P1_Shield_Break else goto __P1_Destroyed

__P1_Shield_Break
   ; Clear the shield bit
   temp6 = 255 - temp6  ; Invert mask
   p1_state = p1_state & temp6
   ; Bounce ball away based on hit direction (temp5)
   ; For now just reverse velocity
   ball_xvel = 0 - ball_xvel
   ball_yvel = 0 - ball_yvel
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return


   ;***************************************************************
   ;  Shield damage system - P2 hit by ball
   ;***************************************************************
__P2_Hit
   ; Calculate relative position (ball - player)
   temp1 = ballx - player1x  ; dx
   temp2 = bally - player1y  ; dy

   ; Get absolute values for comparison
   temp3 = temp1
   if temp3 > 128 then temp3 = 256 - temp3  ; abs(dx)
   temp4 = temp2
   if temp4 > 128 then temp4 = 256 - temp4  ; abs(dy)

   ; Determine which shield was hit (primary axis wins)
   if temp4 > temp3 then goto __P2_Vertical_Hit

   ; Horizontal hit - East(1) or West(3)
   if temp1 > 128 then temp5 = 5 else temp5 = 3  ; bit5=W, bit3=E
   goto __P2_Check_Shield

__P2_Vertical_Hit
   ; Vertical hit - North(0) or South(2)
   if temp2 > 128 then temp5 = 2 else temp5 = 4  ; bit2=N, bit4=S

__P2_Check_Shield
   ; temp5 now contains shield bit position (2-5)
   ; Check if that shield bit is set
   temp6 = 1
   temp1 = temp5
__P2_Shift_Loop
   if temp1 = 0 then goto __P2_Shift_Done
   temp6 = temp6 + temp6  ; Shift left (multiply by 2)
   temp1 = temp1 - 1
   goto __P2_Shift_Loop

__P2_Shift_Done
   ; temp6 now has bitmask (4, 8, 16, or 32)
   ; Test if shield is intact
   temp1 = p2_state & temp6
   if temp1 then goto __P2_Shield_Break else goto __P2_Destroyed

__P2_Shield_Break
   ; Clear the shield bit
   temp6 = 255 - temp6  ; Invert mask
   p2_state = p2_state & temp6
   ; Bounce ball away based on hit direction
   ball_xvel = 0 - ball_xvel
   ball_yvel = 0 - ball_yvel
   ballx = ballx + ball_xvel
   bally = bally + ball_yvel
   return



   bank 3


   ;***************************************************************
   ;  BANK 3: Reserved for scoring system
   ;***************************************************************
   ; Future: High scores, score display, pfscore bars




   bank 4


   ;***************************************************************
   ;  BANK 4: Reserved for future levels and game modes
   ;***************************************************************
   ; Future: Level data, mode selection, difficulty settings
