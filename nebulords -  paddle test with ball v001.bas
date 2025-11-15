   set kernel_options no_blank_lines readpaddle

   ;***************************************************************
   ;  NEBULORDS - 4 Direction Defense + Precise Ball Aiming
   ;***************************************************************

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   dim p1_rotation = a
   dim p2_rotation = b
   dim p1_direction = c
   dim p2_direction = d
   dim p1_xpos = player0x.e
   dim p1_ypos = player0y.f


   ;***************************************************************
   ;  Set colors and playfield color
   ;***************************************************************
   COLUBK = $00 : COLUPF = $0E : COLUP0 = $96 : COLUP1 = $34

   ;***************************************************************
   ;  Initialize Player 1 position (using 8.8 fixed point)
   ;***************************************************************
   p1_xpos = 50.0 : p1_ypos = 60.0


   ;***************************************************************
   ;  Define default sprites OUTSIDE loop
   ;***************************************************************
   player0:
   %00011000
   %00111100
   %01111110
   %11111111
   %11111111
   %01111110
   %00111100
   %00111100
end

   player1:
   %00011000
   %00111100
   %01111110
   %11111111
   %11111111
   %01111110
   %00111100
   %00111100
end


   ;***************************************************************
   ;  Define playfield border
   ;***************************************************************
   playfield:
   ................................
   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
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
   ;  Handle movement - thrust on paddle button
   ;  Paddle 0 button = joy0right
   ;***************************************************************
   if joy0right then gosub __P1_Thrust

   ;***************************************************************
   ;  Set ship positions (P1 uses fixed point, P2 is static)
   ;***************************************************************
   COLUP0 = $96 : COLUP1 = $34
   player1x = 110 : player1y = 60

   ;***************************************************************
   ;  Read paddle 0 for ball position (0-77)
   ;***************************************************************
   currentpaddle = 0
   drawscreen
   p1_rotation = paddle

   ;***************************************************************
   ;  Read paddle 1
   ;***************************************************************
   currentpaddle = 1
   p2_rotation = paddle

   ;***************************************************************
   ;  Position ball around Player 0 - CORRECTED
   ;  Origin: BOTTOM-LEFT of sprite
   ;  Y-axis: INVERTED (lower Y = higher on screen)
   ;  Center of 8x8 sprite: approximately x+4, y+4 from bottom-left
   ;***************************************************************
   temp1 = p1_rotation / 4
   if temp1 > 15 then temp1 = 15
   
   on temp1 goto __Ball_0 __Ball_1 __Ball_2 __Ball_3 __Ball_4 __Ball_5 __Ball_6 __Ball_7 __Ball_8 __Ball_9 __Ball_10 __Ball_11 __Ball_12 __Ball_13 __Ball_14 __Ball_15

__Ball_0
   ballx = player0x + 4 : bally = player0y - 10
   ballheight = 1
   goto __Main_Loop

__Ball_1
   ballx = player0x + 6 : bally = player0y - 9
   ballheight = 1
   goto __Main_Loop

__Ball_2
   ballx = player0x + 8 : bally = player0y - 7
   ballheight = 1
   goto __Main_Loop

__Ball_3
   ballx = player0x + 9 : bally = player0y - 5
   ballheight = 1
   goto __Main_Loop

__Ball_4
   ballx = player0x + 10 : bally = player0y - 3
   ballheight = 1
   goto __Main_Loop

__Ball_5
   ballx = player0x + 9 : bally = player0y - 1
   ballheight = 1
   goto __Main_Loop

__Ball_6
   ballx = player0x + 8 : bally = player0y + 0
   ballheight = 1
   goto __Main_Loop

__Ball_7
   ballx = player0x + 6 : bally = player0y + 1
   ballheight = 1
   goto __Main_Loop

__Ball_8
   ballx = player0x + 4 : bally = player0y + 2
   ballheight = 1
   goto __Main_Loop

__Ball_9
   ballx = player0x + 2 : bally = player0y + 1
   ballheight = 1
   goto __Main_Loop

__Ball_10
   ballx = player0x : bally = player0y + 0
   ballheight = 1
   goto __Main_Loop

__Ball_11
   ballx = player0x - 1 : bally = player0y - 1
   ballheight = 1
   goto __Main_Loop

__Ball_12
   ballx = player0x - 1 : bally = player0y - 3
   ballheight = 1
   goto __Main_Loop

__Ball_13
   ballx = player0x : bally = player0y - 5
   ballheight = 1
   goto __Main_Loop

__Ball_14
   ballx = player0x + 1 : bally = player0y - 7
   ballheight = 1
   goto __Main_Loop

__Ball_15
   ballx = player0x + 3 : bally = player0y - 9
   ballheight = 1
   goto __Main_Loop


   ;***************************************************************
   ;  SUBROUTINE: Player 1 Thrust
   ;  Move in the direction the ball is pointing
   ;  Remember: Y is inverted (subtract Y to go UP)
   ;***************************************************************
__P1_Thrust
   if temp1 = 0 then p1_ypos = p1_ypos - 0.5
   if temp1 = 1 then p1_xpos = p1_xpos + 0.3 : p1_ypos = p1_ypos - 0.4
   if temp1 = 2 then p1_xpos = p1_xpos + 0.4 : p1_ypos = p1_ypos - 0.3
   if temp1 = 3 then p1_xpos = p1_xpos + 0.5 : p1_ypos = p1_ypos - 0.1
   if temp1 = 4 then p1_xpos = p1_xpos + 0.5 : p1_ypos = p1_ypos + 0.1
   if temp1 = 5 then p1_xpos = p1_xpos + 0.4 : p1_ypos = p1_ypos + 0.3
   if temp1 = 6 then p1_xpos = p1_xpos + 0.3 : p1_ypos = p1_ypos + 0.4
   if temp1 = 7 then p1_xpos = p1_xpos + 0.1 : p1_ypos = p1_ypos + 0.5
   if temp1 = 8 then p1_xpos = p1_xpos - 0.1 : p1_ypos = p1_ypos + 0.5
   if temp1 = 9 then p1_xpos = p1_xpos - 0.3 : p1_ypos = p1_ypos + 0.4
   if temp1 = 10 then p1_xpos = p1_xpos - 0.4 : p1_ypos = p1_ypos + 0.3
   if temp1 = 11 then p1_xpos = p1_xpos - 0.5 : p1_ypos = p1_ypos + 0.1
   if temp1 = 12 then p1_xpos = p1_xpos - 0.5 : p1_ypos = p1_ypos - 0.1
   if temp1 = 13 then p1_xpos = p1_xpos - 0.4 : p1_ypos = p1_ypos - 0.3
   if temp1 = 14 then p1_xpos = p1_xpos - 0.3 : p1_ypos = p1_ypos - 0.4
   if temp1 = 15 then p1_xpos = p1_xpos - 0.1 : p1_ypos = p1_ypos - 0.5
   return
