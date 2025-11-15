  ;===========================================================================================
  ;  Starfield Qlitch  PXE Tutorial - POWERLINE game
  ;-------------------------------------------------------------------------------------------
  ; Use the "Starfield Glitch" to create a flying slanted playfield that flys by
  ; - Use the L/R joystick to move fight character along the "PowerLine"
  ; - use U/D on the joystick to control the speed
  ; - Press fire to shoot
  ; - The ball will be used for the qlitch
  ;----- How it works----------------------------------------------------------------------------
  ; The Glitch is enabled by setting bit0 of the ball or missile horizontal move offset register
  ; Set the object height and starting y position  to set how much of the screen will be used
  ; y pos = 0 and height = 177 will cover the whole screen
  ; then you move that object's x register with each succesive drawscreen command
  ; each position adder will cause different effects, you can make the qlich different directions
  ; - you can use HMBL HMM0 or HMM1
  ; - Setting the Horz Offset to $81 will just casue a straight line
  ; _ Settings $71 and lower create wide spaced "stars"
  ; - settings $91 and above create close spaced "stars" eventually forming diagonal lines (as in this game)
  ; - changing the object width will clength the dots.
  ;;------------------------------------------------------------------------------------------------
  ; November 4 2025 by Michael Bachman (Artisan Retro Games)
  ;====================================================================================
  ;=================================================================================
  ;  This program uses the PXE ELF kernel.
  set kernel PXE
  ;set tv ntsc-- NOT necessary as PXE will automatically detect NTSC or PAL and use the right color palette
   
  ;===================================================================================
  ; PF_MODE - Control the playfield and color drawing, painting and scroll features
  ;-----------------------------------------------------------------------------------
  ; format = cbfo vpww
  ;===================================================================================
  PF_MODE = %00111101  ; Playfield uses Column 0 FRAC_INC, V_SCROLL, and WRITE_OFFSET, Fine scroll, 40 column/single playfield, 
                       ; Playfield and Background colors have their own unique offsets and scroll
  
  DF0FRACINC = 0       ; full 176 scanline 
  
  const pfscore =1     ; Enable the score
  const font = hex     ; Use the HEX font 
   
  ;==== Variable and Bit defines ======
  dim Frame_Counter     = A
  dim Ship_Direction    = B  ; Could just be a bit...but hey, we have variables a-z and var0-var60 now!
  dim PowerLine_Adder   = C  ; The actual amount to move
  dim Ship_Xpos         = player0x
  dim Ship_Ypos         = player0y 
  dim Thrust_Xpos       = player1x
  dim Thrust_Ypos       = player1y 
  dim Thrust_Length     = player1height  
  dim Thrust            = D  ; You need a seperate variable becasue everythine a sprite data shape is called, the sprite length is reset to full size
  dim Shot_Direction    = E
    
  dim Upper_Characters = score
  dim Middle_Characters =score+1
  dim Lower_Characters = score+2

  ;==== Get the Background Color Array adress ====
  const BKColor_Ptr_Lo = #<(BKCOLS)
  const BKColor_Ptr_Hi = #(>BKCOLS) & $0F

  ;==== Get the Playfield Color Array adress ====
  const PFColor_Ptr_Lo = #<(BKCOLS)
  const PFColor_Ptr_Hi = #(>BKCOLS) & $0F

  const FORWARD = 1
  const REVERSE = 0

  ;==== Set the score colors ===
  scorecolors:
  $04
  $06
  $08
  $0A
  $0A
  $08
  $06
  $04
end
    
  ;==== Start in the center of the screen ==== 
  Ship_Ypos = 100 : Ship_Xpos = 90

  ;==== Setup the Powerline gitch ====
  bally = 0 : ballx =20 
  CTRLPF = $31 ; 8 wide ball
  ballheight = 177 ; full screen
  ;==== Setup the Electric Noise glitch ====
  missile0y = 0 : missile0x = 20
  NUSIZ0 = $00 ; 1 pixel wide missile
  missile0height = 177 ; full screen
  
  ;==== Setup the Ship's firepower ====
  missile1y = 200
  missile1height = 4
  _NUSIZ1 = $10 ; 2 pixel wide missile
  COLUM1 = $44


  gosub  __Setup_Playfield

  gosub __Setup_Sprite

__Loop_Forever 
  if !joy0fire then goto __Loop_Forever
  

  ;============== MAIN LOOP =================================
  ;----------------------------------------------------------
  ; Move around the castle
  ; By drawing onto the playfield
  ;==========================================================
__Main_Loop


  if Frame_Counter & $07 >0 then goto __Skip_PowerLine_Update
    ;==== Speed up or slow down and reverse the ground underneath ====
    if joy0up   then PowerLine_Adder = PowerLine_Adder + 1 : Thrust = Thrust + 1 : goto __Moving
    if joy0down then PowerLine_Adder = PowerLine_Adder - 1 : Thrust = Thrust + 1 : goto __Moving
    ;== Joystick u/d in nuetral, coast back to 0 speed ====
    if PowerLine_Adder >0  && PowerLine_Adder <19 then PowerLine_Adder = PowerLine_Adder - 1
    if PowerLine_Adder >237  && PowerLine_Adder <=255 then PowerLine_Adder = PowerLine_Adder + 1
    if Thrust > 0 then Thrust = Thrust - 1
__Moving   
    if PowerLine_Adder = 19 then PowerLine_Adder = 18   ; limit the max speed forward
    if PowerLine_Adder = 237 then PowerLine_Adder = 238 ; limit the max speed reverse
    if Thrust > 9 then Thrust = 9                       ; Limit the thrust length

__Skip_PowerLine_Update

  ;==== Scroll the background colors using the PXE playfield coclor scroll register ====
  if PowerLine_Adder > 13 then PF_VER_SCROLL_LO_PFCOL = PF_VER_SCROLL_LO_PFCOL +1
  if PowerLine_Adder < 13 then PF_VER_SCROLL_LO_PFCOL = PF_VER_SCROLL_LO_PFCOL -1
  if PowerLine_Adder = 0  then PF_VER_SCROLL_LO_PFCOL = PF_VER_SCROLL_LO_PFCOL -2

  ;==== Move the ship "left and right" ====
  if joy0right && Ship_Xpos < 140  then Ship_Xpos = Ship_Xpos + 2 : Ship_Ypos = Ship_Ypos - 1
  if joy0left  && Ship_Xpos > 20  then Ship_Xpos = Ship_Xpos - 2 : Ship_Ypos = Ship_Ypos + 1 
   

  ;==== Flip the ship when reversing ====
  ;==== More Thrust as Speed increases ====
  if joy0up   then Thrust_Xpos = Ship_Xpos + 3 : Thrust_Ypos = Ship_Ypos + 17 : gosub __Forward 
  if joy0down then Thrust_Xpos = Ship_Xpos - (Thrust_Length/2) + 1 : Thrust_Ypos = Ship_Ypos - Thrust_Length + 2   : gosub __Reverse
  if !joy0up && !joy0down then Thrust_Ypos = 200 : Thrust_Length = 0 : gosub __Still 
  Thrust_Length = Thrust ; You must update a sprite's length after every new call to its data as calling its data reset the length to full

  ;=== Fire a shot ===
  if joy0fire && missile1y = 200 && Ship_Direction = FORWARD then missile1y = Ship_Ypos      : missile1x = Ship_Xpos + 1 : Shot_Direction = Ship_Direction
  if joy0fire && missile1y = 200 && Ship_Direction = REVERSE then missile1y = Ship_Ypos + 18 : missile1x = Ship_Xpos + 7 : Shot_Direction = Ship_Direction
  if missile1y <> 200 && Shot_Direction = FORWARD then missile1y = missile1y - 2 : missile1x = missile1x - 1
  if missile1y <> 200 && Shot_Direction = REVERSE then missile1y = missile1y + 2 : missile1x = missile1x + 1
  if missile1y < 2   then missile1y = 200 ; gone offscreen top
  if missile1y > 174 then missile1y = 200 ; gone offscreen bottom
  if missile1x < 2   then missile1y = 200 ; gone offscreen left
  if missile1x > 158 then missile1y = 200 ; gone offscreen left
  temp4 = Frame_Counter & $0F
  COLUM1 = $08 + (temp4*16) ; color cycle the shot

  ;=== Display some stuff on the SCORE just for fun ====
  Upper_Characters  = ballx
  Middle_Characters = 00
  Lower_Characters  = PowerLine_Adder

  ;=== PXE give you a variable to set the color behind the score ===
  Score_Background_Color = $02  

  ;======= Move the Glitches ========
  ;=== The Power Line - the ball ====
  HMBL = $A1 
  ballx = ballx + PowerLine_Adder
  ;=== The electric Noise - missile0 ====
  temp4 = rand & $70 ; Create the Noise pattern
  HMM0 = temp4 + 1  
  missile0x = missile0x + PowerLine_Adder
  temp4 = rand & $07 ; Create the Noise level
  COLUM0 = $02 + temp4

  ;=== There are points you need to reset to avoid a jump in the Power Line movement ===
  if ballx >$9C && PowerLine_Adder <$80 then ballx = 0
  if ballx >$9C && PowerLine_Adder >$80 then ballx = $9C
 
  drawscreen

  Frame_Counter = Frame_Counter + 1

  ;=========== SOUNDS ==================
  ;--------  Movement-----------
  temp4 = rand &07
  if temp4 > Thrust+2 then temp4 = Thrust+2 ; the background noise level will change with the Thrust
  AUDV0 = Frame_Counter & temp4
  temp4 = 15
  AUDC0 = temp4
  if PowerLine_Adder < 20 then AUDF0 = 31 - PowerLine_Adder else AUDF0 = 30 - (255-PowerLine_Adder)
  if PowerLine_Adder = 0 then AUDF0 = 31 

  ;------ Shot -------
  if missile1y = 200 then goto __Skip_Shot_Sound
  temp4 = Frame_Counter & $0F
  if temp4 <8 then AUDV1 = temp4 else AUDV1 = 15-temp4
  AUDF1 = 4; AUDV1*2
  AUDC1 = 3
  goto __Got_Sound_1
__Skip_Shot_Sound

  ;---- Engine ---
  AUDC1 = 15 
  AUDV1 = Thrust/2
  AUDF1 = 4 + (rand & $07)

__Got_Sound_1
 
  ;==== All done, go back to the top ====
  goto __Main_Loop 


__Setup_Sprite
  ;=== Thrust ====
 
  
  ;==== The Ship ====
  player0color:
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
  $06
end
__Forward
  player0:
  %10000000
  %11000000
  %11100000
  %11110000
  %10011000
  %10111100
  %11111110
  %11111111
  %11111111
  %11111110
  %11111100
  %11111000
  %11111000
  %11111100
  %11111100
  %11011100
  %10011000
  %10010000
end
  player1:
  %01100000
  %00100000
  %00110000
  %00110000
  %00110000
  %00010000
  %00010000
  %00001000
  %00000000
end
  player1color:
  $36
  $2A
  $3E
  $1A
  $1C
  $1E
  $1C
  $1E
  $00
end 
  Ship_Direction = FORWARD
__Still 
  return

__Reverse 
  player0: 
  %00001001
  %00011001
  %00111011
  %00111111
  %00111111
  %00011111
  %00011111
  %00111111
  %01111111
  %11111111
  %11111111
  %01111111
  %00111101
  %00011001
  %00001111
  %00000111
  %00000011
  %00000001 
end
  player1:
  %00000000
  %00010000
  %00001000
  %00001100
  %00001100
  %00001100
  %00000100
  %00000110
end 
  player1color:
  $1E
  $1C 
  $1E
  $1C
  $1A
  $3E
  $2A
  $36
  $00
end
  Ship_Direction = REVERSE
  return


__Setup_Playfield

    PF_FRAC_INC_0     = 64   ; 4 scanlines for each playfield row, 44 rows
    PF_FRAC_INC_PFCOL = 64
    PF_FRAC_INC_BKCOL = 64

   ;=== playfield colors  are a 256 color gradient ====
	pfcolors:
	$9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C
    $9E
	$9C
	$9A
	$98
	$96
	$98
	$9A
	$9C    ;255
end
   ; A patchs to add the 256th color
	COLUPF = $9E

  return