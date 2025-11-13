   ;***************************************************************
   ;  PFSCORE TEST V4 - UI Layout for Nebulords
   ;
   ;  6-DIGIT SCORE DISPLAY:
   ;  [Level: 01-10][P1 Score: 00-99][P2 Score: 00-99]
   ;  Example: 010525 = Level 01, P1=05, P2=25
   ;
   ;  Features:
   ;  - Box arena with walls
   ;  - 6-digit score at top (level + both player scores)
   ;  - pfscore bars show lives/health for each player
   ;  - Level select via SELECT button (01-10)
   ;***************************************************************

   ;***************************************************************
   ;  Enable pfscore bars
   ;***************************************************************
   const pfscore = 1

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   dim game_level = a             ; Current level (1-10)
   dim select_debounce = b        ; Debounce for SELECT button
   dim p1_lives = e               ; Player 1 lives (0-8)
   dim p2_lives = f               ; Player 2 lives (0-8)
   dim test_counter = g           ; Frame counter for demo

   ; Score byte aliases (BCD format)
   dim sc1 = score                ; Leftmost 2 digits (Level 01-10)
   dim sc2 = score+1              ; Middle 2 digits (P1 score)
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
   ; Display format: [Level:01][P1:00][P2:00] = 010000
   sc1 = $01                      ; Level 01
   sc2 = $00                      ; P1 score 00
   sc3 = $00                      ; P2 score 00

   ; Initialize level to 1
   game_level = 1
   select_debounce = 0
   test_counter = 0

   ; Set colors
   COLUBK = $00                   ; Black background
   COLUPF = $0E                   ; White playfield/bars
   pfscorecolor = $0E             ; White bar color


   ;***************************************************************
   ;  Playfield - Matches Nebulords arena
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
   ;  Level selection with SELECT button (cycles 01-10)
   ;***************************************************************
   if switchselect then select_debounce = select_debounce + 1 else select_debounce = 0

   if select_debounce = 1 then game_level = game_level + 1 : if game_level > 10 then game_level = 1

   ; Convert level to BCD for display
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
   ; Convert game_level (1-10) to BCD in sc1
   sc1 = 0
   if game_level >= 10 then sc1 = $10 : return
   if game_level = 9 then sc1 = $09 : return
   if game_level = 8 then sc1 = $08 : return
   if game_level = 7 then sc1 = $07 : return
   if game_level = 6 then sc1 = $06 : return
   if game_level = 5 then sc1 = $05 : return
   if game_level = 4 then sc1 = $04 : return
   if game_level = 3 then sc1 = $03 : return
   if game_level = 2 then sc1 = $02 : return
   if game_level = 1 then sc1 = $01 : return
   return


__Demo_Update
   ; Increment both player scores in BCD
   ; P1 score (sc2) - Middle 2 digits
   sc2 = sc2 + 1
   if (sc2 & $0F) > 9 then sc2 = sc2 + 6   ; Fix ones digit
   if sc2 > $99 then sc2 = 0               ; Wrap at 99

   ; P2 score (sc3) - Rightmost 2 digits
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
