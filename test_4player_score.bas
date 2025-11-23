  set kernel PXE

  const pfscore = 1
  const font = hex

  PF_MODE = $fd
  PF_FRAC_INC = 0

  dim score_byte0 = score+2
  dim score_byte1 = score+1
  dim score_byte2 = score

  player0:
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
end

  scorecolors:
  $F4
  $F6
  $F8
  $FA
  $FC
  $FE
  $FC
  $FA
end

__Game_Init
  COLUBK = $00
  COLUPF = $0E
  COLUP0 = $46

  player0x = 70 : player0y = 80

  score_byte0 = $03
  score_byte1 = $25
  score_byte2 = $70

  drawscreen
  goto __Main_Loop

__Main_Loop

  if joy0right then score_byte0 = (score_byte0 + 1) & $0F
  if joy0left then score_byte1 = (score_byte1 + $10) & $F0 | (score_byte1 & $0F)
  if joy1right then score_byte1 = (score_byte1 & $F0) | ((score_byte1 + 1) & $0F)
  if joy1left then score_byte2 = (score_byte2 + $10) & $F0 | (score_byte2 & $0F)

  drawscreen
  goto __Main_Loop
