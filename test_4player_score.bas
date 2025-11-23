  set kernel PXE

  PF_MODE = $fd
  PF_FRAC_INC = 0

__Game_Init
  COLUBK = $00
  COLUPF = $0E

  score+2 = $00
  score+1 = $00
  score+0 = $00

  drawscreen
  goto __Main_Loop

__Main_Loop

  if joy0right then score+2 = (score+2 + 1) & $0F
  if joy0left then score+1 = (score+1 + $10) & $F0 | (score+1 & $0F)
  if joy1right then score+1 = (score+1 & $F0) | ((score+1 + 1) & $0F)
  if joy1left then score+0 = (score+0 + $10) & $F0 | (score+0 & $0F)

  drawscreen
  goto __Main_Loop

; Digit 0 - Blank
  scorecolors:
  $00
  $00
  $00
  $00
  $00
  $00
  $00
  $00
end

; Digit 1 - P1 (Blue)
  scorecolors:
  $4E
  $4C
  $4A
  $4A
  $48
  $48
  $46
  $46
end

; Digit 2 - P2 (Purple)
  scorecolors:
  $8E
  $8C
  $8A
  $8A
  $88
  $88
  $86
  $86
end

; Digit 3 - P3 (Orange)
  scorecolors:
  $2E
  $2C
  $2A
  $2A
  $28
  $28
  $26
  $26
end

; Digit 4 - P4 (Green)
  scorecolors:
  $CE
  $CC
  $CA
  $CA
  $C8
  $C8
  $C6
  $C6
end

; Digit 5 - Blank
  scorecolors:
  $00
  $00
  $00
  $00
  $00
  $00
  $00
  $00
end
