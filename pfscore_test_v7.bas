   ;***************************************************************
   ;  PFSCORE TEST V7 - UI Layout for Nebulords
   ;
   ;  SCREEN LAYOUT (Top to Bottom):
   ;  1. PLAYFIELD (arena) - fills most of screen
   ;  2. BOTTOM: [P1 Health] [6-digit Score] [P2 Health]
   ;
   ;  NEW Score format: [P1:00-99][Level:01-10][P2:00-99]
   ;  Example: 050125 = P1=05, Level 01, P2=25
   ;
   ;  Features:
   ;  - Full-size box arena (11 rows)
   ;  - 6-digit score at bottom center
   ;  - P1 score in LEFT 2 digits
   ;  - Level in MIDDLE 2 digits
   ;  - P2 score in RIGHT 2 digits
   ;  - Health bars at bottom on left/right sides
   ;  - Level select via SELECT button (01-10)
   ;***************************************************************

   ;***************************************************************
   ;  Enable pfscore bars and set playfield row height
   ;***************************************************************
   const pfscore = 1
   const pfrowheight = 8

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   dim game_level = a             ; Current level (1-10)
   dim select_debounce = b        ; Debounce for SELECT button
   dim p1_lives = e               ; Player 1 lives (0-8)
   dim p2_lives = f               ; Player 2 lives (0-8)
   dim test_counter = g           ; Frame counter for demo

   ; Score byte aliases (BCD format) - NEW LAYOUT
   dim sc1 = score                ; Leftmost 2 digits (P1 score)
   dim sc2 = score+1              ; Middle 2 digits (Level 01-10)
   dim sc3 = score+2              ; Rightmost 2 digits (P2 score)

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
   ; Display format: [P1:00][Level:01][P2:00] = 000100
   sc1 = $00                      ; P1 score 00
   sc2 = $01                      ; Level 01
   sc3 = $00                      ; P2 score 00

   ; Initialize level to 1
   game_level = 1
   select_debounce = 0
   test_counter = 0

   ; Set colors
   COLUBK = $00                   ; Black background
   COLUPF = $0E                   ; White playfield/bars
   scorecolor = $0E               ; White score (important!)
   pfscorecolor = $0E             ; White bar color


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

   ; Convert level to BCD for display in MIDDLE digits
   if select_debounce = 1 then gosub __Update_Level_Display

   ;***************************************************************
   ;  Demo: Increment scores and drain lives every 2 seconds
   ;***************************************************************
   test_counter = test_counter + 1

   ; Every 120 frames (2 seconds)
   if test_counter >= 120 then test_counter = 0 : gosub __Demo_Update

   drawscreen
   goto __Main_Loop


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


__Demo_Update
   ; Increment both player scores in BCD
   ; P1 score (sc1) - LEFT 2 digits
   sc1 = sc1 + 1
   if (sc1 & $0F) > 9 then sc1 = sc1 + 6   ; Fix ones digit
   if sc1 > $99 then sc1 = 0               ; Wrap at 99

   ; P2 score (sc3) - RIGHT 2 digits
   sc3 = sc3 + 1
   if (sc3 & $0F) > 9 then sc3 = sc3 + 6   ; Fix ones digit
   if sc3 > $99 then sc3 = 0               ; Wrap at 99

   ; Drain P1 lives (left bar)
   if p1_lives > 0 then p1_lives = p1_lives - 1 : pfscore1 = pfscore1 / 2
   if p1_lives = 0 then p1_lives = 8 : pfscore1 = %11111111

   ; Drain P2 lives (right bar)
   if p2_lives > 0 then p2_lives = p2_lives - 1 : pfscore2 = pfscore2 / 2
   if p2_lives = 0 then p2_lives = 8 : pfscore2 = %11111111

   return
