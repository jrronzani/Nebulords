  set kernel PXE

  const pfscore = 1
  const font = retroputer

  PF_MODE = $fd
  PF_FRAC_INC = 0

  dim score_byte0 = score+2
  dim score_byte1 = score+1
  dim score_byte2 = score
  dim dash_x = b
  dim dash_color = c

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

  player1:
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
  player1x = 60 : player1y = 85

  score_byte2 = $A0
  score_byte1 = $00
  score_byte0 = $0A

  dash_x = 60
  dash_color = $46

  drawscreen
  goto __Main_Loop

__Main_Loop

  if joy0fire then rem force joystick mode

  if joy0up then score_byte2 = (score_byte2 & $F0) | ((score_byte2 + 1) & $0F) : player0y = player0y - 1 : if (score_byte2 & $0F) > 9 then score_byte2 = (score_byte2 & $F0) : dash_x = 60 : dash_color = $46
  if joy0down then score_byte1 = (score_byte1 + $10) | (score_byte1 & $0F) : player0y = player0y + 1 : if (score_byte1 & $F0) > $90 then score_byte1 = (score_byte1 & $0F) : dash_x = 68 : dash_color = $86
  if joy0left then score_byte1 = (score_byte1 & $F0) | ((score_byte1 + 1) & $0F) : player0x = player0x - 1 : if (score_byte1 & $0F) > 9 then score_byte1 = (score_byte1 & $F0) : dash_x = 76 : dash_color = $26
  if joy0right then score_byte0 = (score_byte0 + $10) | (score_byte0 & $0F) : player0x = player0x + 1 : if (score_byte0 & $F0) > $90 then score_byte0 = (score_byte0 & $0F) : dash_x = 84 : dash_color = $C6

  player1x = dash_x
  COLUP1 = dash_color

  drawscreen
  goto __Main_Loop
