   ;===================================================================================
   ; 8-way Scrolling PXE Tutorial - Major update
   ;-----------------------------------------------------------------------------------
   ; Setup a large playfield 120 columns by 132 rows: 3x3 continuous map, 9 playfields
   ; player0 stays in the center, the joystick controls 8-way scrolling
   ; Fire drops a "Beacon" onto the  wrap-around map 
   ;----- updates----------------------------------------------------------------------
   ; - Protect against illegal joystick positions/singals
   ; - Simplify keeping the last Player0 direction
   ; - pfscroll values depending on direction to make scroll look consistant
   ; - Title screen that scrolls and uses the Playfield-to-48_Sprite PXE function
   ; - Place the "Beacon" on the large map and display it on the screen when in sight
   ; - math to calulate when the beacon is visble and when it is in the wrap-around area
   ; - Update some sounds
   ;------------------------------------------------------------------------------------
   ; Oct 31 2025 by Michael Bachman (Artisan Retro Games)
   ;====================================================================================

   ;=================================================================================
   ;  This program uses the PXE ELF kernel.
   set kernel PXE
   ;set tv ntsc-- NOT necessary as PXE will automatically detect NTSC or PAL and use the right color palette

    
   ;===================================================================================
   ; PF_MODE - Control the plafield and color drawing, painting and scroll features
   ;-----------------------------------------------------------------------------------
   ; PFMode = 0 : basiaclly reproduces DPC+
   ; for DPC+, DF4FRANCINC and 6 now use the same value as DF0-3.  
   ; Use 0 = 256 for the full 176 scan lines
   ;-----------------------------------------------------------------------------------
   ; All other modes, use PFSCROLL Direction, Amount, Columns
   ; Where Direction is UP/DOWN/RIGHT or LEFT
   ; Columns 0-14 are playfield. 
   ; This totorial used Column0 for all playfield control -- See below vvvvvv
   ;-----------------------------------------------------------------------------------
   ; PF_MODE format = cbfo vpww
   ;===================================================================================
   ; c: Playfield Colors Control
   ;   0: Playfield Colors uses PF_FRAC_INC_PFCLR, PF_WRITE_OFFSET_PFCOL, PF_VER_SCROLL_LO_PFCOL & PF_VER_SCROLL_HI_PFCOL
   ;   1: Playfield f,o, and v settings are applied to playfield colors
   ;
   ; b: Background Colors Control
   ;   0: Background Colors usesPF_FRAC_INC_BKCLR, PF_WRITE_OFFSET_BKCOL, PF_VER_SCROLL_LO_BKCOL & PF_VER_SCROLL_HI_BKCOL
   ;   1: Playfield f,o, and v settings are applied to background colors
   ;
   ; f: Fractional Increment Control
   ;   0: Each playfield column has its own PF_FRAC_INC
   ;   1: PF_FRAC_INC is applied to all columns
   ;
   ; o: Write Offset Control
   ;   0: Each playfield column has its own PF_WRITE_OFFSET
   ;   1: PF_WRITE_OFFSET is applied to all columns
   ;
   ; v: Vertical Scroll Control
   ;   0: Each playfield column has its own PF_VER_SCROLL_LO and PF_VER_SCROLL_HI
   ;   1: PF_VER_SCROLL is applied to all columns
   ;
   ; p: PFSCROLL mode
   ;   0: Scroll resolution matches FRACINC registers and pfscroll changes write offsets,
   ;   1-Fine grain. -128 to +127 scanlines
   ;
   ; ww: Playfield (PF) Width.  
   ;   0: 32 column playfield with sides set to PF0. No horizontal scrolling. Primarily for backwards compatability with DPC+ kernel.
   ;   1: 40  columns, 1 Full playfield,  160 Pixels wide, 5 FracInc resisters  (0-4) (each 8 bits wide)
   ;   2: 80  columns, 2 full playfields, 320 Pixels wide, 10 FracInc resisters (0-9)
   ;   3: 120 columns, 3 full playfields, 480 Pixels wide, 15 FracInc resisters (0-14)
   ;===================================================================================================
   PF_MODE = %11111111   ; Playfield uses Column 0 FRAC_INC, V_SCROLL, and WRITE_OFFSET, Fine scroll, 120 pixel wide playfield
      
   DF0FRACINC = 64      ; 176 / (256/FRACINC) so 44 rows per screen (BTW, you do not need have this statement before every drawscreen as you do in DPC+)
   
   const pfscore =1     ; Enable the score
   const font = hex     ; Use the HEX font so we can display vert and horz position in the score digits
    
   ;==== Variable and Bit defines ======
   dim Player0_Direction = A  ; 0-7 for the 8 directions
   dim Frame_Counter     = B
   
   dim Beacon_X          = C  ; Map position of the beacon, when dropped
   dim Beacon_Y          = D  ; In Row and Column units, not pixels
   
   dim Map_Right_Position  = W
   dim Map_Left_Position   = X
   dim Map_Top_Position    = Y
   dim Map_Bottom_Position = Z
    
   dim Upper_Characters = score
   dim Middle_Characters =score+1
   dim Lower_Characters = score+2
   
   ; ==== Color Definitions ===========
   ;  just an easy way to test and replace colors
   dim  _Sky_Color_0 = $04
   dim  _Sky_Color_1 = $02
   dim  _Sky_Color_2 = $04
   dim  _Sky_Color_3 = $06

   ;===== Run the Title Screen, using a playfield-to-46-sprite PXE command =====
   ; - it will run for 3 seconds = 180 for 180 frames
   ; - it will scroll up for the first 80 frames
   gosub __Display_Title
  
   
   ;===== Setup the playfield and Sprite data
   gosub __Setup_Playfield
   
   gosub __Setup_Sprites

   ;========= Missile used as a Map Beacon ===========
   ; Dropped at the Ship position by pressing fire 
   missile1height = 8 : COLUM1 = $44 : _NUSIZ1 = $20
   missile1y = 200  ; Place the "beacon" out of sight until dropped by pressing fire
   Beacon_X = 200   ; Column places the beacon off the map
  
  ;============== MAIN LOOP =================================
  ;----------------------------------------------------------
  ; Scroll the Space
  ; Loopback the map if going beyond the bottom or top edge
  ;==========================================================
__Main_Loop

  ;=== Scroll and set player0 direction =======================================
  ; Change pfscroll values to make all directions look and feel like they are moving at the same speed
  Player0_Direction = 0
  if joy0right then pfscroll left   : Player0_Direction = Player0_Direction + 1 ; the adder = 1 is implied if not explic1tly stated
  if joy0left  then pfscroll right  : Player0_Direction = Player0_Direction + 2
  if Player0_Direction > 0 then goto __Scroll_UD_Fine                           ; On diagonals, only scroll 1 scanline up or down
  if joy0down then pfscroll up 2    : Player0_Direction = Player0_Direction + 4 ; when it up or down only, scroll 2
  if joy0up   then pfscroll down 2  : Player0_Direction = Player0_Direction + 8 
  goto __Done_Scrolling
__Scroll_UD_Fine
  if joy0down then pfscroll up     : Player0_Direction = Player0_Direction + 4
  if joy0up   then pfscroll down   : Player0_Direction = Player0_Direction + 8
__Done_Scrolling

  ;==== Get the right player0 Sprite ==========================================
  if Player0_Direction > 10 then Player0_Direction = 0 ; To protect against a broken joystick that would allow impossible directions. You still need to include a few impossible directions below, like 3 and 7
  on Player0_Direction gosub __NEUTRAL __RIGHT __LEFT __NEUTRAL __DOWN __DOWNRIGHT __DOWNLEFT __NEUTRAL __UP __UPRIGHT __UPLEFT
  ;=== If you have bB+PXE >= 1.9 then you can comment the 2 line above out and use the line below...it is a new PXE joystick function!
  ;JOY0_DIR gosub __NEUTRAL __RIGHT __UPRIGHT __UP __UPLEFT __UPLEFT __DOWNLEFT __DOWN __DOWNRIGHT


  ;=== Calualte the vertical top position of the map on-screen ==============================================================
  ; PF_VER_SCROLL_LO overflows every 64th row (4*64 = 256)
  Map_Top_Position = PF_VER_SCROLL_LO/4  
  if PF_VER_SCROLL_HI = 1 then Map_Top_Position = Map_Top_Position + 64  ; It overflowed, so add 64
  if PF_VER_SCROLL_HI = 2 then Map_Top_Position = Map_Top_Position + 128 ; It overflowed, so add 64
  if PF_VER_SCROLL_HI = 3 then Map_Top_Position = Map_Top_Position + 176 ; It overflowed, so add 64 (this happend when fine mode scroll off the top, the 0,0 position)
__GOT_VERT_POSITION

  ;=== Create a wrap around mpa in the vertical movement ==================================  
  ; This happenes automatically if you have a 256 tall map and automatically horizontally...
  ; But for smaller maps, you need to duplicate the first screen and concatinate it at the end, then reset the PF VER SCROLL functions upon exiting the top or bottom
  if Map_Top_Position > 220 then  PF_VER_SCROLL_LO = 14 : PF_VER_SCROLL_HI = 2 : goto __Map_Reset    ; Scriolled off the top edge of the map, reset to bottom
  if Map_Top_Position > 131 then  PF_VER_SCROLL_LO = 0 : PF_VER_SCROLL_HI = 0 : Map_Top_Position = 0 ; scrolled of the bottom of the map..reset to top.
__Map_Reset 

  ;=== Calulate the Map's horizontal left edge position ====
  Map_Left_Position = PF_HOR_SCROLL_LO/4  
  if PF_HOR_SCROLL_HI = 1 then Map_Left_Position = Map_Left_Position + 64  ; It overflowed, so add 64
 
  ;==== If the Fire is pressed, drop a Box at the ships position in the map ====
  if joy0fire then Beacon_X = Map_Left_Position + ((player0x+4)/4)  :  Beacon_Y = Map_Top_Position + ((player0y+4)/4) 
  if Beacon_X > 119 then Beacon_X = Beacon_X - 119 ; Overflow correction

  ;================================================================
  ;  Place the Beacon On Screen - when appropriate
  ;----------------------------------------------------------------
  ; A lot of math to deal with the wrap-around map
  ; Much of it can be removed it the map is not allowed to wrap
  ; Still a few small bugs where screen 3 and 0 overlap vertivally
  ; It needs a Vertical Split Screen section..go ahead and write it
  ;================================================================
  missile1y = 200 ; Assume the Beacon is off the screen
  Map_Bottom_Position = Map_Top_Position + 43

  ;==== Check if the Y position of the Beacon is on the visual screen at this time ====
__Check_Ypos
  if Beacon_Y < Map_Top_Position || Beacon_Y > Map_Bottom_Position then goto __Not_On_Screen ; Beacon is not mapped onto this vertical portion of the visible screen
__Ypos_On_Screen
  missile1y = (Beacon_Y - Map_Top_Position)*4;
  goto __Check_Xpos

  ;==== Check if the X position of the Beacon is on the visual screen at this time ====
__Check_Xpos
  if Map_Left_Position >80 then goto __Horz_Split_Screen                    
  Map_Right_Position = Map_Left_Position+39                                                    ; Calulate the right side of the visible screen
  if Beacon_X < Map_Left_Position || Beacon_X > Map_Right_Position then goto __Not_On_Screen   ; Beacon is not mapped onto this  horizonral portion of the visible screen
__Xpos_On_Screen
  missile1x = (Beacon_X - Map_Left_Position)*4
  ;missile1y = (Beacon_Y - Map_Top_Position)*4;
  goto __Beacon_Is_Placed

  ;==== Part of the screen is at the end of the map and some is at the start. This is the horizontal map wrap-around ====
__Horz_Split_Screen
  Map_Right_Position = (Map_Left_Position + 39)                                  ; Split screen, so somewhere in the middle, the column #s likely start over again
  if Map_Right_Position > 119 then Map_Right_Position = Map_Right_Position - 120 ; The right portion of the screen is athe the beginning of the map
  if Beacon_X > 39  && Beacon_X < 80                 then goto __Not_On_Screen   ; It must be between 80-119 or 0-39 to be in the split screen
  if Beacon_X <= 40 && Beacon_X > Map_Right_Position then goto __Not_On_Screen   ; Not in the right half of the split screen
  if Beacon_X >= 80 && Beacon_X < Map_Left_Position  then goto __Not_On_Screen   ; Not in the left half of the split screen
  ;=== OK, the beacon is somewhere in the horixontal split screen area ===
__Xpos_On_Split_Screen
  if Beacon_X >= 80 then missile1x = (Beacon_X - Map_Left_Position)*4            ; Becaon is on the left side of the split
  if Beacon_X < 40 then missile1x = ((39 -Map_Right_Position) + Beacon_X)*4      ; Becaon is on the right side of the split
  ;missile1y = (Beacon_Y - Map_Top_Position)*4;
  goto __Beacon_Is_Placed

__Beacon_Is_Placed
__Not_On_Screen

  ;=== forced "masking" so the ball does not bleed-over to the other side of the screen.  Not needed with masked Spites ===
  if missile1x > 155 || missile1x < 4 then missile1y = 200 

  ;==== Show the vertical (or horizontal) position, just for fun =====
  Lower_Characters  = Beacon_Y             ; Beacon_X        
  Middle_Characters = Map_Bottom_Position  ; Map_Right_Position   
  Upper_Characters  = Map_Top_Position     ; Map_Left_Position  

  drawscreen

  Frame_Counter  = Frame_Counter  + 1
  
  ;==== Standbu and Collison with a rock Sound! ===============
  AUDF0 = 10 : AUDC0 = 8 : AUDV0 = 2
  if SWCHA = $FF then AUDF0 = 30
  if collision(player0, playfield) then AUDV0 = 6 : AUDC0 = 3

  ;=== Beacon On Screen Sound ========================
  temp4 = Frame_Counter & $17
  AUDC1 = 4 : AUDF1 = 4 : AUDV1 = 0
  if temp4 < 5 then AUDV1 = temp4 
  if missile1y = 200 then AUDV1 = 0 ; Beacon is not on the screen

  goto __Main_Loop

;==========================================================================================================================
;================ END OF MAIN LOOP ========================================================================================
;==========================================================================================================================
  
__Setup_Playfield

  ; Set the playfield to the upper left starting position
  PF_VER_SCROLL_LO = 0 : PF_VER_SCROLL_HI = 0
  PF_HOR_SCROLL_LO = 0 : PF_HOR_SCROLL_HI = 0
  simple48 = 0 ; turn of the playfield-to-sprite function
  
;============= Large Playfield ===========================================================================================
; 120 colums wide = 480 pixels.   The right edge pixel is at location; PF_HOZ_SCROLL_HI = 1, PF_HOZ_SCROLL_LO = 223
; 120 rows high = 480 scanlines.  The Lower edge pixel is at location, PF_VER_SCROLL_HI = 1, PF_VER_SCROLL_LO = 223
; |----------- Screen 0 -----------------||----------- Screen 2 -----------------||----------- Screen 3 -----------------|
; |----------- HORZ_HI=0 ----------------------------------------||----------- HORZ_HI=1 --------------------------------|
  playfield:
  ........................................................................................................................
  ........XXXXX.XX........................................................................................................
  ....XXXXXXXXX.XXX.......................................................................................XXXXX...........
  ...XXXXXXXXXXXXXXX..................................................................................XXXXXXXXXXX.........
  ...XXXXXXXX.XXXXXXX...............................................................................XX.XXXXXXXX.XX........
  ..XXXXXXXX.X.XXXXXX.............................................XXXXXXXXXXX.....................XXXXXXXXXXXXXXX.........
  ..XX.XXXXXX.XXXXXX.............................................XXXXXXXXXXXXXXX....................XXXXX.XXXXXX.XX.......
  ..X.XXXXXXXXXXXXXX...........................................XXXXXXXXXXXXXXXXXX....................XXX.XXXXXXXXXX.......
  ..XXX.XXXXXXXXXXX...........................................XXXXXXXXX.XXXXXXXXX.....................XXXX.XXXXXXXX.......
  ..XX.XXXXXXXX.XX.............................................XXXXX.XXXXXXXX.XXX.................XX..XX.XXXXXXXX.........
  ..XXXXXXXXXXXXXX..............................................XXXXXXXXXX..XXXX.................XXXX.XXXXXXXXXXXX........
  ...XXXXXXXXXX.X.................................................X.XXXXXXXXXXXX................XXXXX..XXXXXXXXXXX........
  ....XXXXXXXXXXX.................................................XXXXXXXXXXXX...................xXX...XXXXXXXXXXX........
  .....XXX..XXXXX...................................................XXXXXX.XX.......................XXXXXXXXXXXXXX........
  ......XX...XXX.....................................................XXXXXX........................XXXX.XXXXXXXXXXX.......
  .................................XX................................XXX..X.......................XX.XXXXXXXXXXXXXX.......
  ...............................XXXXX.............................................................XXXXXXXXXXXXXXXX.......
  ...........................XXXXXXXXX.............................................................XXXXXXXXX.XXXX.........
  ..........................XXXXXXXXXXX.............................................................XXXX.XXXXXXXXX........
  ..........................XXXXXXXX.XX..............................................................XX.XXXX.XXXX.........
  .........................XXXXXXXX.X.X................................................................XXXX.XXXX..........
  .........................XX.XXXXXX.XX.................................................................XXXXXXX...........
  .........................X.XXXXXXXXXX..................................................................XXXXXX...........
  .........................XXX.XXXXXXXX...................................................................X.XX............
  .........................XX.XXXXXXXX....................................................................................
  .........................XXXXXXXXXXXX...................................................................................
  .........................XXXXXXXXXXX..........................XX........................................................
  ..........................XXXXXXXXXXX.......................XXXXXXX.....................................................
  ..........................XXXXXXXXXXX.....................XXXXXXXXXXX...................................................
  ...........................XXXXXXXXXXX...................XXXXXXXXX.XXX..................................................
  ...........................XXXXXXXXXXX...................XXXXXXXXXX.XX..................................................
  ...........................XXXXXXXXXXX...................XXXXXXXXXXXXX..................................................
  ...........................XXXXX.XXXX....................XXXXXXXXX.XXX..................................................
  ...........................XXXXXXXXX.....................XXXXXXXX.XXXX..................................................
  ...........................XXXX.XX........................XXXXXXXXXXX...........................XXXXXXX.................
  ............................XX.XX...........................XXXXXXX............................XX.XXXXXX................
  ............................XXXXX............................X.XXX............................XXXXXXXXXXX...............
  .............................XXX................................X.............................XXXXXX.XXXX...............
  ..............................X................................................................XX.XXXXXX................
  .................................................................................................XXXXXX.................
  ........................................................................................................................
  ........................................................................................................................
  ........................................................................................................................
  .............XXXXXX.....................................................................................................
  ...........XXXXXXXX.XXXX................................................................................................ ; end of screen 1
  ........XXXXXXXXXXXXXXXX.................................................................XXX............................ ; start of screen 2
  ........XXXX..XXXXXX.XXXX...............................................................XXXXX...........................
  ..........XXXXXXXX.X.X..............................................................XXXXXXXXX..XX.......................
  ...........XXXXXXXXXXX.............................................................XXXXXXXXXXX.XXXX.....................
  ...................................................................................XXXXXXXX.XXXXXXX..................... 
  ..................................................................................XXXXXXXX.X.XXXXXXXX................... 
  ..................................................................................XX.XXXXXX.XXXXXXX.XX..................
  .................................................................................XX.XXXXXXXXXXXXXX.XXX..................
  ................................................................................XXXXX.XXXXXXXXXXXXXXX...................
  ...............................................................................XXXXX.XXXXXXXXXXXXXXXXXX................. 
  .........................................XX...................................XXXXXXXXXXXXXXXX.XXXXXXX..................
  .......................................XXXXXXX.................................XXXXXXXXXXXXXX.XXXXXXX...................
  .....................................XXXXXXXXXXX................................XX.XXXXXXXXXXX.XXXXX....................
  ....................................XXXXXXXXX.XXX................................XXXXXXXXXXXXXXXXXX.....................
  ....................................XXXXXXXXXX.XX...............................XXXXXXXXXXXXXXX.XXX.....................
  ....................................XXXXXXXXXXXXX................................XXXXXXXXXXXXXX..XX.....................
  ....................................XXXXXXXXX.XXX................................XXXXXXXXXXXXXX..XX.....................
  ....................................XXXXXXXX.XXXX.................................XXXXXXX.XXXX....X..................... 
  .....................................XXXXXXXXXXX...................................XXXXXXXXXX...........................
  ...........XXX.........................XXXXXXX......................................XXXX.XX.............................  
  ..........XXXXX.........................X.XXX........................................XX.XX..............................
  ......XXXXXXXXX............................X.........................................XXXXX.............................. 
  .....XXXXXXXXXXX......................................................................XXX............................... 
  .....XXXXXXXX.XX.......................................................................X................................
  ....XXXXXXXX.X.X........................................................................................................ 
  ....XX.XXXXXX.XX........................................................................................................
  ....X.XXXXXXXXXX........................................................................................................
  ....XXX.XXXXXXXX........................................................................................................
  ....XX.XXXXXXXX.........................................................................................................
  ....XXXXXXXXXXXX........................................................................................................
  ....XXXXXXXXXXX.................................XXXX....................................................................
  .....XXXXXXXXXXX...............................XXXXXX...................................................................
  .....XXXXXXXXXXX.............................XXX.XXXXX.................................................................. 
  ......XXXXXXXXXXX........................XXXXXXXXXXXXXXXX............................................................... 
  ......XXXXXXXXX.......................XXXXXXXXXXXXXXXXXXXXX.............................................................
  ......XXXX.XX..........................XX.XXXXXXXXXXXXXX.XXX............................................................ 
  .......XX.XX.........................XX.XXXXXXXXXXXXXXXXX.XXXX..........................................................
  .......XXXXX........................XXXXXXXXXXXXXXXXXXXXXXXXX........................................................... 
  ........XXX.............................XXXXXXXXXXXXXXXX.XXX............................................................
  .........X.............................XXXXXXXXXXXXXXXX.XXXX............................................................
  ........................................XXXXXXX.XXXXXXXXXXX......................................XX.....................
  .........................................X.XXXXXX.XXXXXXX......................................XXXXXXX..................
  ............................................XXXXX..X.XXX.....................................XXXXXXXXXXX................
  ............................................XXX.XXXXXXX.....................................XXXXXXXXX.XXX............... ; end of screen 2
  ..............................................XXXXXX........................................XXXXXXXXXX.XX............... ; start of screen 3
  ............................................................................................XXXXXXXXXXXXX............... 
  ............................................................................................XXXXXXXXX.XXX............... 
  ............................................................................................XXXXXXXX.XXXX............... 
  .............................................................................................XXXXXXXXXXX................
  ...............................................................................................XXXXXXX..................
  ................................................................................................X.XXX...................
  ...................................................................................................X.................... ; added lined below to give a full 3 screens
  ........................................................................................................................
  ........................................................................................................................
  ..............................XXXXXXXXXXXXX......XXXXX.....................XXXXX......XXXXXXXXXXXXXXX...................
  .............................XXXXXXXXXXXXXXX.....XXXXXX...................XXXXXX.....XXXXXXXXXXXXXXXX...................
  ............................XXXXXXXXXXXXXXXXX....XXXXXXX.................XXXXXXX....XXXXXXXXXXXXXXXXX...................
  ............................XXXXXXXXXXXXXXXXX.....XXXXXXX...............XXXXXXX.....XXXXXXXXXXXXXXXXX...................
  ............................XXXXXXXXXXXXXXXXX......XXXXXXX.............XXXXXXX......XXXXXXXXXXXXXXXXX...................
  ............................XXXXX.......XXXXX.......XXXXXXX...........XXXXXXX.......XXXXX...............................
  ............................XXXXX.......XXXXX........XXXXXXX.........XXXXXXX........XXXXX...............................
  ............................XXXXX.......XXXXX.........XXXXXXX.......XXXXXXX.........XXXXX...............................
  ............................XXXXX.......XXXXX..........XXXXXXX.....XXXXXXX..........XXXXX...............................
  ............................XXXXX.......XXXXX...........XXXXXXX...XXXXXXX...........XXXXX...............................
  ............................XXXXX.......XXXXX............XXXXXXX.XXXXXXX............XXXXX...............................
  ............................XXXXX...XXXXXXXXX.............XXXXX.XXXXXXX.............XXXXX...............................
  ............................XXXXX...XXXXXXXXX..............XXX.XXXXXXX..............XXXXXXXXXXXXXX......................
  ............................XXXXX...XXXXXXXXX...............X.XXXXXXX...............XXXXXXXXXXXXXX......................
  ............................XXXXX...XXXXXXXXX................XXXXXXX................XXXXXXXXXXXXXX......................
  ............................XXXXX...XXXXXXXX................XXXXXXX.................XXXXXXXXXXXXXX......................
  ............................XXXXX...XXXXXXX................XXXXXXX.X................XXXXXXXXXXXXXX......................
  ............................XXXXX.........................XXXXXXX.XXX...............XXXXXXXXXXXXXX......................
  ............................XXXXX........................XXXXXXX.XXXXX..............XXXXX...............................
  ............................XXXXX.......................XXXXXXX.XXXXXXX.............XXXXX...............................
  ............................XXXXX......................XXXXXXX...XXXXXXX............XXXXX...............................
  ............................XXXXX.....................XXXXXXX.....XXXXXXX...........XXXXX...............................
  ............................XXXXX....................XXXXXXX.......XXXXXXX..........XXXXX...............................
  ............................XXXXX...................XXXXXXX.........XXXXXXX.........XXXXX...............................
  ............................XXXXX..................XXXXXXX...........XXXXXXX........XXXXXXXXXXXXXXXXX...................
  ............................XXXXX.................XXXXXXX.............XXXXXXX.......XXXXXXXXXXXXXXXXX...................
  ............................XXXXX................XXXXXXX...............XXXXXXX......XXXXXXXXXXXXXXXXX...................
  ............................XXXXX................XXXXXX.................XXXXXX.......XXXXXXXXXXXXXXXX...................
  ............................XXXXX................XXXXX...................XXXXX........XXXXXXXXXXXXXXX...................
  ........................................................................................................................
  ........................................................................................................................
  ........................................................................................................................
  ........................................................................................................................; End of screen 3
  ........................................................................................................................; Start of screen 1 duplication
  ........XXXXX.XX........................................................................................................
  ....XXXXXXXXX.XXX.......................................................................................XXXXX...........
  ...XXXXXXXXXXXXXXX..................................................................................XXXXXXXXXXX.........
  ...XXXXXXXX.XXXXXXX...............................................................................XX.XXXXXXXX.XX........
  ..XXXXXXXX.X.XXXXXX.............................................XXXXXXXXXXX.....................XXXXXXXXXXXXXXX.........
  ..XX.XXXXXX.XXXXXX.............................................XXXXXXXXXXXXXXX....................XXXXX.XXXXXX.XX.......
  ..X.XXXXXXXXXXXXXX...........................................XXXXXXXXXXXXXXXXXX....................XXX.XXXXXXXXXX.......
  ..XXX.XXXXXXXXXXX...........................................XXXXXXXXX.XXXXXXXXX.....................XXXX.XXXXXXXX.......
  ..XX.XXXXXXXX.XX.............................................XXXXX.XXXXXXXX.XXX.................XX..XX.XXXXXXXX.........
  ..XXXXXXXXXXXXXX..............................................XXXXXXXXXX..XXXX.................XXXX.XXXXXXXXXXXX........
  ...XXXXXXXXXX.X.................................................X.XXXXXXXXXXXX................XXXXX..XXXXXXXXXXX........
  ....XXXXXXXXXXX.................................................XXXXXXXXXXXX...................xXX...XXXXXXXXXXX........
  .....XXX..XXXXX...................................................XXXXXX.XX.......................XXXXXXXXXXXXXX........
  ......XX...XXX.....................................................XXXXXX........................XXXX.XXXXXXXXXXX.......
  .................................XX................................XXX..X.......................XX.XXXXXXXXXXXXXX.......
  ...............................XXXXX.............................................................XXXXXXXXXXXXXXXX.......
  ...........................XXXXXXXXX.............................................................XXXXXXXXX.XXXX.........
  ..........................XXXXXXXXXXX.............................................................XXXX.XXXXXXXXX........
  ..........................XXXXXXXX.XX..............................................................XX.XXXX.XXXX.........
  .........................XXXXXXXX.X.X................................................................XXXX.XXXX..........
  .........................XX.XXXXXX.XX.................................................................XXXXXXX...........
  .........................X.XXXXXXXXXX..................................................................XXXXXX...........
  .........................XXX.XXXXXXXX...................................................................X.XX............
  .........................XX.XXXXXXXX....................................................................................
  .........................XXXXXXXXXXXX...................................................................................
  .........................XXXXXXXXXXX..........................XX........................................................
  ..........................XXXXXXXXXXX.......................XXXXXXX.....................................................
  ..........................XXXXXXXXXXX.....................XXXXXXXXXXX...................................................
  ...........................XXXXXXXXXXX...................XXXXXXXXX.XXX..................................................
  ...........................XXXXXXXXXXX...................XXXXXXXXXX.XX..................................................
  ...........................XXXXXXXXXXX...................XXXXXXXXXXXXX..................................................
  ...........................XXXXX.XXXX....................XXXXXXXXX.XXX..................................................
  ...........................XXXXXXXXX.....................XXXXXXXX.XXXX..................................................
  ...........................XXXX.XX........................XXXXXXXXXXX...........................XXXXXXX.................
  ............................XX.XX...........................XXXXXXX............................XX.XXXXXX................
  ............................XXXXX............................X.XXX............................XXXXXXXXXXX...............
  .............................XXX................................X.............................XXXXXX.XXXX...............
  ..............................X................................................................XX.XXXXXX................
  .................................................................................................XXXXXX.................
  ........................................................................................................................
  ........................................................................................................................
  ........................................................................................................................
  ........................................................................................................................
end

 
 pfcolors:
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_2
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_0
 _Sky_Color_2
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_2
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_3
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_2
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_2
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_2
 _Sky_Color_0
 _Sky_Color_2
 _Sky_Color_3
 $64
 $64
 $64
 $64
 $66
 $66
 $66
 $66
 $68
 $68
 $68
 $6A
 $6A
 $6A
 $6C
 $6C
 $6C
 $6A
 $6A
 $6A
 $6A
 $68
 $68
 $68
 $68
 $66
 $66
 $66
 $66
 _Sky_Color_3
 _Sky_Color_2
 _Sky_Color_3
 _Sky_Color_2
 _Sky_Color_0 ; Start of top screen duplicatio
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_0
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_1
 _Sky_Color_2
 _Sky_Color_1
 _Sky_Color_0
end
   return

   ;========== Sprites ===========================================================
__Setup_Sprites

   ;===== Initial Sprite Placement ====
   player0x  = 76    : player0y  = 80 ; center screen

   scorecolors: ; Colors are inverted top/bottom on the Score
   $F4
   $F6
   $F8
   $FA
   $FC
   $FE
   $FC
   $FA
end
   
   ;=== Sprite Graphic Definitions ====
   player0color:
   $8C
   $8C
   $8C
   $8A
   $8A
   $8A
   $8A
   $8A
   $88
   $88
   $88
   $88
   $86
   $86
   $86
   $86
end

__UP
   player0:
   %00011000
   %00011000
   %00111100
   %00111100
   %01100110
   %01100110
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11011011
   %11011011
   %10000001
   %10000001
end
__NEUTRAL   ; do not replace the spriet data player 0 keeps the last direction when the joystick is neatural
   return

__DOWN
   player0:
   %10000001
   %10000001
   %11011011
   %11011011
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %11111111
   %01100110
   %01100110
   %00111100
   %00111100
   %00011000
   %00011000
end
   return

__LEFT
   player0:
   %00011111
   %00011111
   %00111110
   %00111110
   %01111100
   %01111100
   %11011110
   %11011110
   %11011110
   %11011110
   %01111100
   %01111100
   %00111110
   %00111110
   %00011111
   %00011111
end
   return

__RIGHT
   player0:
   %11111000
   %11111000
   %01111100
   %01111100
   %00111110
   %00111110
   %01111011
   %01111011
   %01111011
   %01111011
   %00111110
   %00111110
   %01111100
   %01111100
   %11111000
   %11111000
end
   return

__UPRIGHT
   player0:
   %00000111
   %00000111
   %00111101
   %00111101
   %11111111
   %11111111
   %01111110
   %01111110
   %00011110
   %00011110
   %00101110
   %00101110
   %00001100
   %00001100
   %00000100
   %00000100
end
   return

__UPLEFT
   player0:
   %11100000
   %11100000
   %10111100
   %10111100
   %11111111
   %11111111
   %01111110
   %01111110
   %01111000
   %01111000
   %01110100
   %01110100
   %00110000
   %00110000
   %00100000
   %00100000
end  
   return

__DOWNLEFT
   player0:
   %00100000
   %00100000
   %00110000
   %00110000
   %01110100
   %01110100
   %01111000
   %01111000
   %01111110
   %01111110
   %11111111
   %11111111
   %10111100
   %10111100
   %11100000
   %11100000
end
   return

__DOWNRIGHT
   player0:
   %00000100
   %00000100
   %00001100
   %00001100
   %00101110
   %00101110
   %00011110
   %00011110
   %01111110
   %01111110
   %11111111
   %11111111
   %00111101
   %00111101
   %00000111
   %00000111
end
   return

  ;========================================================
  ; Title Screen
  ;--------------------------------------------------------
  ; - Create a 48 wide sprite from a playfield!
  ;========================================================
__Display_Title
   ;==== Animate the title, scroll up from the bottom ====
   for Frame_Counter = 0 to 180
     if Frame_Counter < 80 then PF_WRITE_OFFSET = 44 - (Frame_Counter/2) ;  We are using a 44 row screen, so start at the bottom and scroll up
     gosub __Title_Playfield
     drawscreen
   next
   return
 
__Title_Playfield  
  simple48 = 1 ; Set this to turn a 48 column playfield into a Sprite! 
  playfield:
  ........................................
  .....XXXXX......X...X....XXX....X...X...
  .....XX.XX......X...X...X...X...X...X...
  ......XXX...XX..X.X.X...XXXXX....XXXX...
  .....XX.XX......X.X.X...X...X.......X...
  .....XXXXX.......XXX....X...X....XXX....
  ........................................
  ........................................
  ..XXXXX...XXXX..xXXXX....XXXX...XX...XX.
  .XX......XX.....XX..XX..XX..XX..XX...XX.
  ..XXXX...XX.....XXXX....XX..XX..XX...XX.
  .....XX..XX.....XX..XX..XX..XX..XX...XX.
  .XXXXX....XXXX..XX..XX...XXXX...XXX..XXX
  ........................................
end
  pfcolors:
  $00
  $76
  $78
  $7A
  $78
  $76
  $00
  $00
  $36
  $38
  $3A
  $38
  $36
  $00
end
  return
