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
   dim p1_score = c               ; Player 1 score (0-99)
   dim p2_score = d               ; Player 2 score (0-99)
   dim p1_lives = e               ; Player 1 lives (0-8)
   dim p2_lives = f               ; Player 2 lives (0-8)
   dim test_counter = g           ; Frame counter for demo

   ;***************************************************************
   ;  Initialize
   ;***************************************************************
__Init
   ; Start with full lives (8 bars each)
   p1_lives = 8
   p2_lives = 8
   pfscore1 = %11111111           ; Left bar full (P1 lives)
   pfscore2 = %11111111           ; Right bar full (P2 lives)

   ; Start scores at 0
   p1_score = 0
   p2_score = 0
   score = 0

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

   ;***************************************************************
   ;  Build score display:
   ;  Format: [Mode: 1 digit][P1: 2 digits][P2: 2 digits]
   ;  Example: 10203 = Mode 1, P1=02, P2=03
   ;***************************************************************
   score = (game_mode * $10000) + (p1_score * $100) + p2_score

   ;***************************************************************
   ;  Demo: Increment scores and drain lives every 2 seconds
   ;***************************************************************
   test_counter = test_counter + 1

   ; Every 120 frames (2 seconds)
   if test_counter >= 120 then test_counter = 0 : gosub __Demo_Update

   drawscreen
   goto __Main_Loop


__Demo_Update
   ; Increment both player scores
   p1_score = p1_score + 1
   p2_score = p2_score + 1

   ; Wrap scores at 99
   if p1_score > 99 then p1_score = 0
   if p2_score > 99 then p2_score = 0

   ; Drain P1 lives (left bar)
   if p1_lives > 0 then p1_lives = p1_lives - 1 : pfscore1 = pfscore1 / 2
   if p1_lives = 0 then p1_lives = 8 : pfscore1 = %11111111

   ; Drain P2 lives (right bar)
   if p2_lives > 0 then p2_lives = p2_lives - 1 : pfscore2 = pfscore2 / 2
   if p2_lives = 0 then p2_lives = 8 : pfscore2 = %11111111

   return
