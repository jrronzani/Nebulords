  set kernel PXE

  const pfscore = 1
  const font = hex

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

  scorecolors:
  $0E
  $0C
  $0A
  $0A
  $08
  $08
  $06
  $06
end
