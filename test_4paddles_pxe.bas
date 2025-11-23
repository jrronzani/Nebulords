  ;***************************************************************
  ;  2-PADDLE TEST - PXE Kernel
  ;  Test reading 2 paddles (0-1) in PXE kernel
  ;
  ;  Expected controls:
  ;  - Paddle 0 (Left port, left paddle): Controls player0 horizontally
  ;  - Paddle 1 (Left port, right paddle): Controls player1 horizontally
  ;
  ;  Buttons (for testing):
  ;  - Paddle 0 button = joy0right (moves player0 up)
  ;  - Paddle 1 button = joy0left (moves player1 up)
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

  ;***************************************************************
  ;  Initialize
  ;***************************************************************
__Game_Init
  ; Position sprites vertically
  player0y = 40
  player1y = 100

  ; Center all sprites horizontally
  player0x = 70
  player1x = 70

  drawscreen

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

  drawscreen
  goto __Main_Loop
