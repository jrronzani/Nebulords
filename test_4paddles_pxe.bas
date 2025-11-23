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
  ;  - Paddle 0 button = joy0right (changes player0 color)
  ;  - Paddle 1 button = joy0left (changes player1 color)
  ;  - Paddle 2 button = joy1right (changes player2 color)
  ;  - Paddle 3 button = joy1left (changes player3 color)
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
  dim p0_color = a
  dim p1_color = b
  dim p2_color = c
  dim p3_color = d
  dim temp_paddle = e

  ;***************************************************************
  ;  Initialize
  ;***************************************************************
  p0_color = $46  ; Blue
  p1_color = $86  ; Purple
  p2_color = $26  ; Orange
  p3_color = $C6  ; Green

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
  ;  Main Loop
  ;***************************************************************
__Main_Loop

  ;***************************************************************
  ;  Read Paddle 0 (standard PXE method)
  ;***************************************************************
  temp_paddle = Paddle0
  if temp_paddle < 136 then player0x = temp_paddle

  ; Button test: change color when pressed
  if joy0right then p0_color = $0F else p0_color = $46

  ;***************************************************************
  ;  Read Paddle 1 (standard PXE method)
  ;***************************************************************
  temp_paddle = Paddle1
  if temp_paddle < 136 then player1x = temp_paddle

  ; Button test
  if joy0left then p1_color = $0F else p1_color = $86

  ;***************************************************************
  ;  Read Paddle 2 - TESTING IF THIS EXISTS IN PXE
  ;  Based on standard kernel docs, should work after drawscreen
  ;***************************************************************
  ; METHOD 1: Try direct read like Paddle0/Paddle1
  ; temp_paddle = Paddle2
  ; if temp_paddle < 136 then player2x = temp_paddle

  ; METHOD 2: Try currentpaddle approach (if PXE supports it)
  currentpaddle = 2
  drawscreen  ; Paddle gets read during drawscreen
  temp_paddle = paddle
  if temp_paddle < 136 then player2x = temp_paddle

  ; Button test
  if joy1right then p2_color = $0F else p2_color = $26

  ;***************************************************************
  ;  Read Paddle 3 - TESTING IF THIS EXISTS IN PXE
  ;***************************************************************
  ; METHOD 1: Try direct read
  ; temp_paddle = Paddle3
  ; if temp_paddle < 136 then player3x = temp_paddle

  ; METHOD 2: Try currentpaddle approach
  currentpaddle = 3
  drawscreen  ; Paddle gets read during drawscreen
  temp_paddle = paddle
  if temp_paddle < 136 then player3x = temp_paddle

  ; Button test
  if joy1left then p3_color = $0F else p3_color = $C6

  ;***************************************************************
  ;  Update sprite colors
  ;***************************************************************
  player0color:
    p0_color p0_color p0_color p0_color
    p0_color p0_color p0_color p0_color
  end

  player1color:
    p1_color p1_color p1_color p1_color
    p1_color p1_color p1_color p1_color
  end

  player2color:
    p2_color p2_color p2_color p2_color
    p2_color p2_color p2_color p2_color
  end

  player3color:
    p3_color p3_color p3_color p3_color
    p3_color p3_color p3_color p3_color
  end

  drawscreen
  goto __Main_Loop
