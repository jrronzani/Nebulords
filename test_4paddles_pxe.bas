  ;***************************************************************
  ;  4-PADDLE TEST - PXE Kernel
  ;  Test reading all 4 paddles (0-3) in PXE kernel
  ;
  ;  Expected controls:
  ;  - Paddle 0 (Left port, left paddle): Controls player0 horizontally
  ;  - Paddle 1 (Left port, right paddle): Controls player1 horizontally
  ;  - Paddle 2 (Right port, left paddle): Controls player2 horizontally
  ;  - Paddle 3 (Right port, right paddle): Controls player3 horizontally
  ;
  ;  Buttons (for testing):
  ;  - Paddle 0 button = joy0right (moves player0 up)
  ;  - Paddle 1 button = joy0left (moves player1 up)
  ;  - Paddle 2 button = joy1right (moves player2 up)
  ;  - Paddle 3 button = joy1left (moves player3 up)
  ;***************************************************************

  set kernel PXE

  ; Set Playfield to full 40 pixel width
  PF_MODE = $fd
  PF_FRAC_INC = 0

  ; Configure paddle reading
  PaddleRange0 = 136
  PaddleRange1 = 136

  ;***************************************************************
  ;  Variables
  ;***************************************************************
  dim temp_paddle = a

  ;***************************************************************
  ;  Sprite Graphics (simple 8x8 blocks)
  ;***************************************************************
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

  ;***************************************************************
  ;  Sprite Colors (static - one value per line)
  ;***************************************************************
  player0color:
    $46
    $46
    $46
    $46
    $46
    $46
    $46
    $46
  end

  player1color:
    $86
    $86
    $86
    $86
    $86
    $86
    $86
    $86
  end

  player2color:
    $26
    $26
    $26
    $26
    $26
    $26
    $26
    $26
  end

  player3color:
    $C6
    $C6
    $C6
    $C6
    $C6
    $C6
    $C6
    $C6
  end

  ;***************************************************************
  ;  Initialize
  ;***************************************************************
  ; Position sprites vertically (evenly spaced)
  player0y = 20
  player1y = 60
  player2y = 100
  player3y = 140

  ; Center all sprites horizontally
  player0x = 70
  player1x = 70
  player2x = 70
  player3x = 70

  ;***************************************************************
  ;  Main Loop
  ;***************************************************************
__Main_Loop

  ;***************************************************************
  ;  Read Paddle 0 (standard PXE method)
  ;***************************************************************
  temp_paddle = Paddle0
  if temp_paddle < 136 then player0x = temp_paddle

  ; Button test: move up when pressed
  if joy0right then player0y = player0y - 1
  if player0y < 10 then player0y = 10

  ;***************************************************************
  ;  Read Paddle 1 (standard PXE method)
  ;***************************************************************
  temp_paddle = Paddle1
  if temp_paddle < 136 then player1x = temp_paddle

  ; Button test: move up when pressed
  if joy0left then player1y = player1y - 1
  if player1y < 10 then player1y = 10

  ;***************************************************************
  ;  Read Paddle 2 - TESTING IF THIS EXISTS IN PXE
  ;***************************************************************
  ; METHOD 1: Try direct read like Paddle0/Paddle1
  temp_paddle = Paddle2
  if temp_paddle < 136 then player2x = temp_paddle

  ; Button test: move up when pressed
  if joy1right then player2y = player2y - 1
  if player2y < 10 then player2y = 10

  ;***************************************************************
  ;  Read Paddle 3 - TESTING IF THIS EXISTS IN PXE
  ;***************************************************************
  ; METHOD 1: Try direct read
  temp_paddle = Paddle3
  if temp_paddle < 136 then player3x = temp_paddle

  ; Button test: move up when pressed
  if joy1left then player3y = player3y - 1
  if player3y < 10 then player3y = 10

  drawscreen
  goto __Main_Loop
