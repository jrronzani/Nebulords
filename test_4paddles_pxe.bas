  set kernel PXE

  PF_MODE = $fd
  PF_FRAC_INC = 0
  PaddleRange0 = 136
  PaddleRange1 = 136

  dim temp_paddle = a

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

  player2:
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
end

  player3:
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
  %11111111
end

__Game_Init
  COLUBK = $00
  COLUPF = $0E
  COLUP0 = $46
  COLUP1 = $86
  COLUP2 = $26
  COLUP3 = $C6

  player0x = 70 : player0y = 20
  player1x = 70 : player1y = 60
  player2x = 70 : player2y = 100
  player3x = 70 : player3y = 140

  drawscreen
  goto __Main_Loop

__Main_Loop

  temp_paddle = Paddle0
  if temp_paddle < 136 then player0x = temp_paddle

  temp_paddle = Paddle1
  if temp_paddle < 136 then player1x = temp_paddle

  temp_paddle = Paddle2
  if temp_paddle < 136 then player2x = temp_paddle

  temp_paddle = Paddle3
  if temp_paddle < 136 then player3x = temp_paddle

  if joy0right then player0y = player0y - 1
  if joy0left then player1y = player1y - 1
  if joy1right then player2y = player2y - 1
  if joy1left then player3y = player3y - 1

  drawscreen
  goto __Main_Loop
