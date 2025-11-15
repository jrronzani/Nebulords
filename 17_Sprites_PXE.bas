   ;=======================================================================
   ; 17 Sprites PXE Tutorial
   ;-----------------------------------------------------------------------
   ; Setup and display all 17 sprites, player0 + 16 virtual sprites 
   ; Display all sprite formats. single/double/quad/close/wide/1/2/3
   ;=======================================================================
   ; The top  8 virtual sprites DO NOT have masking.  
   ; Scroll left and right to see the effect.  
   ; They bleed over to the other side and jump when the Xpos goes too high
   ;------------------------------------------------------------------------
   ; The lower 8 virtual sprites HAVE PXE masking on (bit 6 of NUSIZ)  
   ; Only set bit 6, bit 7 must be 0 (normal DPC+ masking is not effective) 
   ; They do not show up on the other side and the position does not jump!!
   ;------------------------------------------------------------------------
   ; You will note no flickering of the virtual sprites in this demo
   ; Virtual sprites only need 3 scan lines to prvent flicker
   ; Only the section of the sprite that overlap will fliker
   ; Not the whole sprite.
   ; Sprites 8-15 can move up/down to see the flicker algorithm at work
   ;------------------------------------------------------------------------
   ; Note that Player0 DOES NOT have masking capabilities.
   ; Press and hold FIRE to move Player0
   ;------------------------------------------------------------------------
   ; Oct 19 2025 by Michael Bachman (Artisan Retro Games)
   ;========================================================================

   ;========================================================================
   ;  This program uses the PXE ELF kernel.
   set kernel PXE
   ;set tv ntsc-- NOT necessary as PXE will automatically detect NTSC or PAL and yus the right color palette
   
   PF_MODE = $F1   ; Playfield/color resolution set by DX0FRACINC, screen is 40 columns (160 pixels) wide: more about this in other templates
   DF0FRACINC = 2  ; 2 rows (BTW, you do not need have this statement before every drawscreen as you do in DPC+)

   ;==== Variable and Bit defines ======
   dim X_pos = X
   dim Y_pos = Y

   dim Player0_Direction_Bit0         = A 
   dim Virtual_Sprites_Direction_Bit1 = A 
   
   ;===== Setup the playfield and Sprite data
   gosub __Setup_Playfield
   
   gosub __Setup_Sprites

  
  ;============== MAIN LOOP ================
  ;-----------------------------------------
  ; Move the Virual sprites to show masking
  ;=========================================
__Main_Loop

   if joy0fire then goto __Move_Player0
   ;===Move the virtual Sprites
   if joy0left  then X_pos = X_pos - 1 : Virtual_Sprites_Direction_Bit1{1} = 1
   if joy0right then X_pos = X_pos + 1 : Virtual_Sprites_Direction_Bit1{1} = 0
   if joy0up    then Y_pos = Y_pos - 1  
   if joy0down  then Y_pos = Y_pos + 1
     
   player1x  = X_pos
   player2x  = X_pos
   player3x  = X_pos
   player4x  = X_pos
   player5x  = X_pos
   player6x  = X_pos
   player7x  = X_pos
   player8x  = X_pos
   player9x  = X_pos : player9y  = Y_pos      ; These will move up and down as well as left and right
   player10x = X_pos : player10y = Y_pos + 11
   player11x = X_pos : player11y = Y_pos + 22
   player12x = X_pos : player12y = Y_pos + 33
   player13x = X_pos : player13y = Y_pos + 44
   player14x = X_pos : player14y = Y_pos + 55
   player15x = X_pos : player15y = Y_pos + 66
   player16x = X_pos : player16y = Y_pos + 77

   if Virtual_Sprites_Direction_Bit1{1} then goto __Face_Left
   _NUSIZ1{3}  = 0
   NUSIZ2{3}  = 0
   NUSIZ3{3}  = 0
   NUSIZ4{3}  = 0
   NUSIZ5{3}  = 0
   NUSIZ6{3}  = 0
   NUSIZ7{3}  = 0
   NUSIZ8{3}  = 0
   NUSIZ9{3}  = 0
   NUSIZ10{3} = 0
   NUSIZ11{3} = 0
   NUSIZ12{3} = 0
   NUSIZ13{3} = 0
   NUSIZ14{3} = 0
   NUSIZ15{3} = 0
   NUSIZ16{3} = 0
   goto __Done_With_Movement

__Face_Left
   _NUSIZ1{3}  = 1
   NUSIZ2{3}  = 1
   NUSIZ3{3}  = 1
   NUSIZ4{3}  = 1
   NUSIZ5{3}  = 1
   NUSIZ6{3}  = 1
   NUSIZ7{3}  = 1
   NUSIZ8{3}  = 1
   NUSIZ9{3}  = 1
   NUSIZ10{3} = 1
   NUSIZ11{3} = 1
   NUSIZ12{3} = 1
   NUSIZ13{3} = 1
   NUSIZ14{3} = 1
   NUSIZ15{3} = 1
   NUSIZ16{3} = 1
   goto __Done_With_Movement

  ;==== When the fire button is down, move player0 on-screen..with bounding limits
__Move_Player0
   if joy0left  && player0x > 1   then player0x = player0x - 1 : Player0_Direction_Bit0{0} = 1
   if joy0right && player0x < 152 then player0x = player0x + 1 : Player0_Direction_Bit0{0} = 0
   if joy0up    && player0y > 1   then player0y = player0y - 1  
   if joy0down  && player0y < 167 then player0y = player0y + 1
   ;==== use the ball to close off the face behind the eyes.
   bally = player0y+2
   if Player0_Direction_Bit0{0} then ballx = player0x + 8 else ballx = player0x + 1 
   
__Done_With_Movement 

   ; ==== Player0 reflection must be updated before every drawscreen...no needed for the virtual sprites.  Those stick.
   if Player0_Direction_Bit0{0} then REFP0 = 8  else REFP0 = 0 

   drawscreen

   goto __Main_Loop

   ;========= Playfield ===========================================================
   ; The playfield (blank) is set only so the ball will be colored to match Player0
__Setup_Playfield
   playfield:
   .......................................
   .......................................
end
   pfcolors:
   $9A
   $9A
end

   ;========== Sprites ===========================================================
__Setup_Sprites

   ;===== Set the size, spacing and number of each sprite =====
   NUSIZ0  = $00
   _NUSIZ1 = $00 ; 1 Sprite  
   NUSIZ2  = $01 ; 2 copies close spaced
   NUSIZ3  = $02 ; 2 copies medium spaced
   NUSIZ4  = $04 ; 2 copies wide spaced
   NUSIZ5  = $03 ; 3 copies close spaced
   NUSIZ6  = $06 ; 3 copies medium spaced
   NUSIZ7  = $05 ; Double size sprite
   NUSIZ8  = $07 ; Quad size sprite
   NUSIZ9  = $40 ; 1 sprite with left and right side masking
   ; === The following Sprites have Masking turn on=======================
   NUSIZ10 = $41 ; 2 copies close spaced with left and right side masking
   NUSIZ11 = $42 ; 2 copies Medium spaced with left and right side masking
   NUSIZ12 = $44 ; 2 copies wide spaced with left and right side masking
   NUSIZ13 = $43 ; 3 copies close spaced with left and right side masking
   NUSIZ14 = $46 ; 3 copies Medium spaced with left and right side masking
   NUSIZ15 = $45 ; Double size sprite with left and right side masking
   NUSIZ16 = $47 ; Quad size sprite with left and right side masking

   ;===== Initial Sprite Placement ====
   X_pos = 20 : Y_pos = 91
   player0x  = 76    : player0y  = 80 ; center screen
   ballheight = 3 : ballx = player0x+1 : bally = player0y+2
   ;----Virtual Sprites ---------
   player1x  = X_pos : player1y  = 03  ;
   player2x  = X_pos : player2y  = 14  ; Spaced by 11 scanlines for an 8 high sprite = no flicker
   player3x  = X_pos : player3y  = 25
   player4x  = X_pos : player4y  = 36
   player5x  = X_pos : player5y  = 47
   player6x  = X_pos : player6y  = 58
   player7x  = X_pos : player7y  = 69
   player8x  = X_pos : player8y  = 80
   player9x  = X_pos : player9y  = Y_pos 
   player10x = X_pos : player10y = Y_pos + 11
   player11x = X_pos : player11y = Y_pos + 22
   player12x = X_pos : player12y = Y_pos + 33
   player13x = X_pos : player13y = Y_pos + 44
   player14x = X_pos : player14y = Y_pos + 55
   player15x = X_pos : player15y = Y_pos + 66
   player16x = X_pos : player16y = Y_pos + 77
 
   ;=== Sprite Graphic Definitions ====
   player0:
   %11111111
   %11111111
   %00110011
   %00100010
   %00110011
   %11111111
   %11111111
   %01100110
   %01110111
end
   player0color:
   $9A
   $9A
   $0E
   $0E
   $0C
   $9A
   $98
   $96
   $94
end
   player1-16:
   %11111111
   %10000001
   %00011011
   %00010010
   %00011011
   %10000001
   %11111111
   %00110110
end
   player1-8color:
   $4A
   $4C
   $0E
   $0C
   $0A
   $48
   $46
   $44
end
   player9-16color:
   $DA
   $DC
   $0E
   $0C
   $0A
   $D8
   $D6
   $D4
end
   return