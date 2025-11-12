   ;***************************************************************
   ;  PFSCORE TEST - Shows BOTH bars and numeric scores
   ;  BARS: P1 bar (left) fills up, P2 bar (right) drains
   ;  NUMERIC SCORE: P1 (left digits) and P2 (right digits) at top
   ;***************************************************************

   ;***************************************************************
   ;  Enable pfscore bars
   ;***************************************************************
   const pfscore = 1

   ;***************************************************************
   ;  Variable declarations
   ;***************************************************************
   dim p1_counter = a             ; Frame counter for P1 (0-59)
   dim p2_counter = b             ; Frame counter for P2 (0-119)

   ;***************************************************************
   ;  Initialize
   ;***************************************************************
__Init
   ; Start with empty left bar, full right bar
   pfscore1 = %00000000           ; Left bar empty
   pfscore2 = %11111111           ; Right bar full

   ; Start numeric score at 0
   score = 0

   ; Reset counters
   p1_counter = 0
   p2_counter = 0

   ; Set colors
   COLUBK = $00                   ; Black background
   COLUPF = $0E                   ; White bars
   pfscorecolor = $0E             ; White bar color


   ;***************************************************************
   ;  Simple playfield (just a box)
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
   ;  Increment P1 counter (1 second = 60 frames)
   ;  Fills LEFT bar and increments LEFT score digits
   ;***************************************************************
   p1_counter = p1_counter + 1
   if p1_counter >= 60 then p1_counter = 0 : pfscore1 = pfscore1 * 2 | 1 : score = score + $10

   ;***************************************************************
   ;  Increment P2 counter (2 seconds = 120 frames)
   ;  Drains RIGHT bar and increments RIGHT score digits
   ;***************************************************************
   p2_counter = p2_counter + 1
   if p2_counter >= 120 then p2_counter = 0 : pfscore2 = pfscore2 / 2 : score = score + 1

   ;***************************************************************
   ;  Reset when bars are full/empty or score overflows
   ;***************************************************************
   if pfscore1 >= 255 then pfscore1 = 0
   if pfscore2 = 0 then pfscore2 = 255
   if score >= $100 then score = 0

   drawscreen
   goto __Main_Loop
