  ; ============================================================
  ; NEBULORDS - PROPER PXE SCORE DISPLAY IMPLEMENTATION
  ; ============================================================
  ; This shows how to properly use the built-in score display
  ; in the PXE kernel for 2-player scoring
  ;
  ; The built-in 'score' variable automatically displays at the
  ; top of the screen in PXE, just like the standard kernel!
  ; ============================================================

  set kernel PXE

  ; ============================================================
  ; Score Variable Setup
  ; ============================================================
  ; The built-in 'score' variable holds 6 BCD digits (3 bytes)
  ; Format: score+2 score+1 score+0 = XX XX XX (6 digits)
  ;
  ; For 2-player games, we can use:
  ; - Left 3 digits (score+2, score+1 high nibble) for Player 1
  ; - Right 3 digits (score+1 low nibble, score+0) for Player 2
  ;
  ; OR use separate bytes:
  ; - score+2 = Player 1 score (0-99)
  ; - score+0 = Player 2 score (0-99)
  ; - score+1 = separator/unused

  ; Split score into byte-sized pieces for easy manipulation
  dim p1_score_digit = score+2     ; Leftmost 2 digits (Player 1)
  dim p2_score_digit = score       ; Rightmost 2 digits (Player 2)
  dim score_middle = score+1       ; Middle 2 digits (unused/separator)

  ; Initialize scores to 00 00 00
  p1_score_digit = 0
  score_middle = 0
  p2_score_digit = 0

  ; ============================================================
  ; Optional: Custom Score Colors
  ; ============================================================
  ; You can define scorecolors: blocks to customize the color
  ; of each score digit. See ex_dpc_collision.bas lines 1363-1546
  ; for examples.

  ; Example scorecolors (one for each digit):
  ; __ScoreColors_P1
  ;   scorecolors:
  ;   $0E  ; Light blue
  ;   $0C
  ;   $0A
  ;   $0A
  ;   $08
  ;   $08
  ;   $06
  ;   $06
  ; end

__Main_Loop

  ; ============================================================
  ; Award Points (BCD format!)
  ; ============================================================
  ; IMPORTANT: Scores are in BCD (Binary Coded Decimal)
  ; Each byte holds 2 decimal digits: $23 = 23 (not 35!)
  ;
  ; To add 1 point in BCD:
  ; - Add $01
  ; - If low nibble > 9, adjust to next 10s place
  ;
  ; The easy way: use sed (BCD adjust after addition)

  ; Example: Award 1 point to Player 1
  if joy0fire then gosub __Award_P1_Point

  ; Example: Award 1 point to Player 2
  if joy1fire then gosub __Award_P2_Point

  drawscreen
  goto __Main_Loop


  ; ============================================================
  ; Award Point Subroutines (with BCD math)
  ; ============================================================
__Award_P1_Point
  ; Add 1 to P1 score (BCD)
  ; Simple method for scores 0-99:
  temp1 = p1_score_digit & $0F  ; Get ones digit
  if temp1 = 9 then p1_score_digit = p1_score_digit + 7  ; Skip A-F
  p1_score_digit = p1_score_digit + 1
  return

__Award_P2_Point
  ; Add 1 to P2 score (BCD)
  temp1 = p2_score_digit & $0F  ; Get ones digit
  if temp1 = 9 then p2_score_digit = p2_score_digit + 7  ; Skip A-F
  p2_score_digit = p2_score_digit + 1
  return


  ; ============================================================
  ; NOTES:
  ; ============================================================
  ; 1. The score displays automatically at the top of the screen
  ; 2. No need to manually draw anything with pfpixel!
  ; 3. BCD math is needed when incrementing scores
  ; 4. Each byte can hold values 0-99 ($00-$99 in BCD)
  ; 5. You can use scorecolors: to customize digit colors
  ; 6. Format: score+2 score+1 score+0 = XX XX XX
  ;
  ; For Nebulords, I recommend:
  ; - Display format: "P1  P2" (2 digits each with separator)
  ; - score+2 = P1 score (00-99)
  ; - score+1 = $00 (separator/blank)
  ; - score+0 = P2 score (00-99)
  ; ============================================================
