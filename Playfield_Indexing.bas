  ;===================================================================================
  ;  Playfield Indexing PXE Tutorial 
  ;-----------------------------------------------------------------------------------
  ; Use the playfield offset and index register to do partial writes to the playfield
  ; - Us ethe joystick to move the PF character
  ; - Press fire to paint the background colors and independantly scroll it
  ; - Special variable to keep control the color behind the Score
  ;----- updates----------------------------------------------------------------------
  ;------------------------------------------------------------------------------------
  ; November 2 2025 by Michael Bachman (Artisan Retro Games)
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
  PF_MODE = %10111101  ; Playfield uses Column 0 FRAC_INC, V_SCROLL, and WRITE_OFFSET, Fine scroll, 40 column/single playfield, 
                       ; Playfield and Background colors have their own unique offsets and scroll
  
  DF0FRACINC = 0       ; full 176 scanline 
  
  const pfscore =1     ; Enable the score
  const font = hex     ; Use the HEX font 
   
  ;==== Variable and Bit defines ======
  dim Frame_Counter     = A
  dim Xpos              = B
  dim Ypos              = C 
  dim Character_Offset  = D
  
  dim Upper_Characters = score
  dim Middle_Characters =score+1
  dim Lower_Characters = score+2

  ;==== Get the Background Color Array adress ====
  const BKColor_Ptr_Lo = #<(BKCOLS)
  const BKColor_Ptr_Hi = #(>BKCOLS) & $0F

  ;==== Get the Playfield Color Array adress ====
  const PFColor_Ptr_Lo = #<(BKCOLS)
  const PFColor_Ptr_Hi = #(>BKCOLS) & $0F

 
  ;==== Set the score colors ===
  scorecolors:
  $54
  $56
  $58
  $5A
  $58
  $56
  $54
  $52
end
    
  ;==== Start in the center of the screen ==== 
  Ypos = 80 : Xpos = 32

  ;============== MAIN LOOP =================================
  ;----------------------------------------------------------
  ; Move around the castle
  ; By drawing onto the playfield
  ;==========================================================
__Main_Loop

  if joy0up    && Ypos > 7   then Ypos = Ypos -1
  if joy0down  && Ypos < 156 then Ypos = Ypos +1
  if joy0left  && Xpos > 0   then Xpos = Xpos -1
  if joy0right && Xpos < 64  then Xpos = Xpos +1

  ;==== Draw the "Castle" ====
  gosub __Main_Playfield 

  ;==== Paint the full 256 line background (or playfield) when the Fire is pressed, erase when not ====
  for var0 = 0 to 255
    ;== Set the location where to set the background color.
    PF_WRITE_OFFSET_BKCOL = var0
    ;==Set the correct pointer and push the color into the datastream
    DF0LOW = BKColor_Ptr_Lo
    DF0HI = BKColor_Ptr_Hi
    if joy0fire then DF0PUSH = var0 else DF0PUSH = $00
  next
  
  ;==== Scroll the background colors ====
  ; Note the scroll position is independant of drawing position (OFFSET)
  PF_VER_SCROLL_LO_BKCOL = PF_VER_SCROLL_LO_BKCOL -1
  
  ;==== Draw the "Man in the Castle" ====
  PF_WRITE_OFFSET = Ypos 
  PF_WRITE_INDEX = Xpos/16
  Character_Offset = (Xpos & $0E)/2
  ;=== there are 8 character "playfields" with 1 pixel offsets as the horixontal resolution is one Data Fetcher, which is 8 bits, 8 PF Pixels
  on Character_Offset gosub __Character_0 __Character_1 __Character_2 __Character_3 __Character_4 __Character_5 __Character_6 __Character_7
  
  ;=== Display some stuff on the SCORE just for fun ====
  Upper_Characters  = PF_VER_SCROLL_LO_BKCOL
  Middle_Characters = Ypos 
  Lower_Characters  = Xpos/16  

  ;=== PXE give you a variable to set the color behind the score ===
  Score_Background_Color = 0  

  drawscreen
  
  goto __Main_Loop 
   
 
__Character_0 
  ;=== This is the graphic that will be drawn onto the playfield ====
  ;It can be any width or height you want.  This one fits within one pillar of 8 columns (8_PF Pixels)
  playfield:
  ..XXXX..........
  .XXXXXX.........
  XX.XX.XX........
  XX.XX.XX........
  XXXXXXXX........
  XXXXXXXX........
  XXXXXXXX........
  XX.XX.XX........
  XXX..XXX........
  .XXXXXX.........
  ..XXXX..........
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return

__Character_1 
  ;=== These following graphics are offset by 1 PF pixel ====
  playfield:
  ...XXXX.........
  ..XXXXXX........
  .XX.XX.XX.......
  .XX.XX.XX.......
  .XXXXXXXX.......
  .XXXXXXXX.......
  .XXXXXXXX.......
  .XX.XX.XX.......
  .XXX..XXX.......
  ..XXXXXX........
  ...XXXX.........
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return  


__Character_2 
  playfield:
  ....XXXX........
  ...XXXXXX.......
  ..XX.XX.XX......
  ..XX.XX.XX......
  ..XXXXXXXX......
  ..XXXXXXXX......
  ..XXXXXXXX......
  ..XX.XX.XX......
  ..XXX..XXX......
  ...XXXXXX.......
  ....XXXX........
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return

__Character_3 
  playfield:
  .....XXXX.......
  ....XXXXXX......
  ...XX.XX.XX.....
  ...XX.XX.XX.....
  ...XXXXXXXX.....
  ...XXXXXXXX.....
  ...XXXXXXXX.....
  ...XX.XX.XX.....
  ...XXX..XXX.....
  ....XXXXXX......
  .....XXXX.......
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return

__Character_4 
  playfield:
  ......XXXX......
  .....XXXXXX.....
  ....XX.XX.XX....
  ....XX.XX.XX....
  ....XXXXXXXX....
  ....XXXXXXXX....
  ....XXXXXXXX....
  ....XX.XX.XX....
  ....XXX..XXX....
  .....XXXXXX.....
  ......XXXX......
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return

__Character_5 
  playfield:
  .......XXXX.....
  ......XXXXXX....
  .....XX.XX.XX...
  .....XX.XX.XX...
  .....XXXXXXXX...
  .....XXXXXXXX...
  .....XXXXXXXX...
  .....XX.XX.XX...
  .....XXX..XXX...
  ......XXXXXX....
  .......XXXX.....
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return  

__Character_6 
  playfield:
  ........XXXX....
  .......XXXXXX...
  ......XX.XX.XX..
  ......XX.XX.XX..
  ......XXXXXXXX..
  ......XXXXXXXX..
  ......XXXXXXXX..
  ......XX.XX.XX..
  ......XXX..XXX..
  .......XXXXXX...
  ........XXXX....
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return

__Character_7 
  playfield:
  .........XXXX...
  ........XXXXXX..
  .......XX.XX.XX.
  .......XX.XX.XX.
  .......XXXXXXXX.
  .......XXXXXXXX.
  .......XXXXXXXX.
  .......XX.XX.XX.
  .......XXX..XXX.
  ........XXXXXX..
  .........XXXX...
end
  pfcolors:
  $D6
  $D6
  $D8
  $D8
  $DA
  $D8
  $D8
  $D6
  $D6
  $D4
  $D4
end
  return


;============================================
; Draw the playfield using a FOR loop!
;--------------------------------------------
__Main_Playfield
  ; Reset the index to star at the upper left
  ; Then draw the top of the "castle"
  PF_WRITE_INDEX = 0
  playfield:
  ..XX.XX.XX.XX.XX.XXXXXX.XX.XX.XX.XX.XX..
  ..XX.XX.XX.XX.XX.XXXXXX.XX.XX.XX.XX.XX..
  ..XX.XX.XX.XX.XX.XX..XX.XX.XX.XX.XX.XX..
  ..XX.XX.XX.XX.XX.XX..XX.XX.XX.XX.XX.XX..
  ..XX.XXXXX.XXXXX.XX..XX.XXXXX.XXXXX.XX..
  ..XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX..
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end
  pfcolors:
  $0C
  $0C
  $0C
  $0A
  $0A
  $0A
  $08
  $08
end 

  ;=== A loop to draw the next 160 scanlines ==============
  ; You can doi this in PXE becasue it is running on the ARM
  ;---------------------------------------------------------
  for var0 = 7 to 167
    PF_WRITE_OFFSET = var0
    playfield:
    X......................................X
end
  pfcolors:
  $08
end
  next

  ;=== And finsh by drawing the base of the "castle"====
  playfield:
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  .X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end 
  pfcolors:
  $08
  $08
  $08
  $08
  $06
  $06
  $04
  $04 
  $00 
end
  return


  