   ;***************************************************************
   ;  PFSCORE TEST V2 - UI Layout for Nebulords
   ;
   ;  Matches Nebulords playfield structure:
   ;  - Box arena with walls
   ;  - Score at top with pfscore bars
   ;  - Mode select via SELECT button
   ;
   ;  UI LAYOUT:
   ;  [MODE] [P1 SCORE] [P2 SCORE]
   ;     1       00         00
   ;
   ;  pfscore bars show lives/health for each player
   ;***************************************************************

   ;***************************************************************
   ;  Enable pfscore bars
   ;***************************************************************
   const pfscore = 1

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   dim game_mode = a              ; Current game mode (1-10)
   dim select_debounce = b        ; Debounce for SELECT button
   dim p1_lives = e               ; Player 1 lives (0-8)
   dim p2_lives = f               ; Player 2 lives (0-8)
   dim test_counter = g           ; Frame counter for demo

   ; Score byte aliases (BCD format)
   dim sc1 = score                ; Leftmost 2 digits
   dim sc2 = score+1              ; Middle 2 digits (P1)
   dim sc3 = score+2              ; Rightmost 2 digits (P2)

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
   ; Display format: [0][Mode] [P1:00] [P2:00]
   sc1 = $01                      ; Left: 0 and mode 1
   sc2 = $00                      ; Middle: P1 score 00
   sc3 = $00                      ; Right: P2 score 00

   ; Initialize mode to 1
   game_mode = 1
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
   ;  Mode selection with SELECT button (cycles 1-10)
   ;***************************************************************
   if switchselect then select_debounce = select_debounce + 1 else select_debounce = 0
   if select_debounce = 1 then game_mode = game_mode + 1 : if game_mode > 10 then game_mode = 1
   if select_debounce = 1 then sc1 = game_mode

   ;***************************************************************
   ;  Score display is updated in the demo routine
   ;  Format: [0][Mode] [P1: 2 digits] [P2: 2 digits]
   ;  sc1 = mode (0-9 in lower nibble)
   ;  sc2 = P1 score (BCD)
   ;  sc3 = P2 score (BCD)
   ;***************************************************************

   ;***************************************************************
   ;  Demo: Increment scores and drain lives every 2 seconds
   ;***************************************************************
   test_counter = test_counter + 1

   ; Every 120 frames (2 seconds)
   if test_counter >= 120 then test_counter = 0 : gosub __Demo_Update

   drawscreen
   goto __Main_Loop


__Demo_Update
   ; Increment both player scores in BCD
   ; P1 score (sc2)
   sc2 = sc2 + 1
   if (sc2 & $0F) > 9 then sc2 = sc2 + 6   ; Fix ones digit
   if sc2 > $99 then sc2 = 0               ; Wrap at 99

   ; P2 score (sc3)
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
