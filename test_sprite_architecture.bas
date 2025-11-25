  ;***************************************************************
  ;  SPRITE ARCHITECTURE TEST
  ;  Testing shared sprite frames with independent animation speeds
  ;
  ;  Goal: 4 sprites (player0-3) cycling through 4 arrow directions
  ;        at different speeds (1fps, 5fps, 10fps, 20fps)
  ;
  ;  Testing:
  ;  1. Can sprite frames be defined outside main loop?
  ;  2. Can we use conditional updates efficiently?
  ;  3. What's the cleanest architecture for independent states?
  ;***************************************************************

  set kernel PXE

  ;***************************************************************
  ;  Variables
  ;***************************************************************
  ; Animation state for each player (0-3 = Up, Right, Down, Left)
  dim p0_frame = a
  dim p1_frame = b
  dim p2_frame = c
  dim p3_frame = d

  ; Frame counters for animation timing
  dim p0_counter = e
  dim p1_counter = f
  dim p2_counter = g
  dim p3_counter = h

  ; Speed thresholds (frames to wait before advancing animation)
  const p0_speed = 60  ; 1fps (60 frames at 60fps)
  const p1_speed = 12  ; 5fps (12 frames)
  const p2_speed = 6   ; 10fps (6 frames)
  const p3_speed = 3   ; 20fps (3 frames)

  ; Temp variable for sprite updates
  dim temp_frame = i

  ;***************************************************************
  ;  Initialize
  ;***************************************************************
  COLUBK = $00

  ; Position 4 sprites vertically
  player0x = 40 : player0y = 20
  player1x = 70 : player1y = 20
  player2x = 100 : player2y = 20
  player3x = 130 : player3y = 20

  ; Initialize animation frames (all start at Up)
  p0_frame = 0
  p1_frame = 0
  p2_frame = 0
  p3_frame = 0

  ; Initialize counters
  p0_counter = 0
  p1_counter = 0
  p2_counter = 0
  p3_counter = 0

  ; Set sprite colors (different for each)
  player0color:
    $96
    $96
    $96
    $96
    $96
    $96
    $96
    $96
  end

  player1color:
    $26
    $26
    $26
    $26
    $26
    $26
    $26
    $26
  end

  player2color:
    $C6
    $C6
    $C6
    $C6
    $C6
    $C6
    $C6
    $C6
  end

  player3color:
    $76
    $76
    $76
    $76
    $76
    $76
    $76
    $76
  end

  ;***************************************************************
  ;  MAIN LOOP
  ;***************************************************************
__Main_Loop

  ; Update animation counters
  p0_counter = p0_counter + 1
  p1_counter = p1_counter + 1
  p2_counter = p2_counter + 1
  p3_counter = p3_counter + 1

  ; Check if each player needs frame advance
  if p0_counter >= p0_speed then gosub __Advance_P0_Frame
  if p1_counter >= p1_speed then gosub __Advance_P1_Frame
  if p2_counter >= p2_speed then gosub __Advance_P2_Frame
  if p3_counter >= p3_speed then gosub __Advance_P3_Frame

  ; Update sprite graphics based on current frame
  ; ARCHITECTURE TEST: Are these in main loop or subroutines?
  gosub __Update_P0_Sprite
  gosub __Update_P1_Sprite
  gosub __Update_P2_Sprite
  gosub __Update_P3_Sprite

  drawscreen
  goto __Main_Loop


  ;***************************************************************
  ;  FRAME ADVANCE SUBROUTINES
  ;  Called only when animation speed threshold reached
  ;***************************************************************
__Advance_P0_Frame
  p0_counter = 0
  p0_frame = p0_frame + 1
  if p0_frame > 3 then p0_frame = 0
  return

__Advance_P1_Frame
  p1_counter = 0
  p1_frame = p1_frame + 1
  if p1_frame > 3 then p1_frame = 0
  return

__Advance_P2_Frame
  p2_counter = 0
  p2_frame = p2_frame + 1
  if p2_frame > 3 then p2_frame = 0
  return

__Advance_P3_Frame
  p3_counter = 0
  p3_frame = p3_frame + 1
  if p3_frame > 3 then p3_frame = 0
  return


  ;***************************************************************
  ;  SPRITE UPDATE SUBROUTINES
  ;  ARCHITECTURE TEST: Can these be moved outside main loop?
  ;  For now, called from main loop but as subroutines
  ;***************************************************************
__Update_P0_Sprite
  ; Use on goto to select sprite based on frame
  on p0_frame goto __P0_Frame_0 __P0_Frame_1 __P0_Frame_2 __P0_Frame_3

__P0_Frame_0:  ; Arrow Up
  player0:
    %00011000
    %00111100
    %01111110
    %11011011
    %00011000
    %00011000
    %00011000
    %00000000
  end
  return

__P0_Frame_1:  ; Arrow Right
  player0:
    %00000000
    %00011000
    %00001100
    %11111110
    %11111110
    %00001100
    %00011000
    %00000000
  end
  return

__P0_Frame_2:  ; Arrow Down
  player0:
    %00000000
    %00011000
    %00011000
    %00011000
    %11011011
    %01111110
    %00111100
    %00011000
  end
  return

__P0_Frame_3:  ; Arrow Left
  player0:
    %00000000
    %00011000
    %00110000
    %01111111
    %01111111
    %00110000
    %00011000
    %00000000
  end
  return


__Update_P1_Sprite
  on p1_frame goto __P1_Frame_0 __P1_Frame_1 __P1_Frame_2 __P1_Frame_3

__P1_Frame_0:  ; Arrow Up (same pattern as P0)
  player1:
    %00011000
    %00111100
    %01111110
    %11011011
    %00011000
    %00011000
    %00011000
    %00000000
  end
  return

__P1_Frame_1:  ; Arrow Right
  player1:
    %00000000
    %00011000
    %00001100
    %11111110
    %11111110
    %00001100
    %00011000
    %00000000
  end
  return

__P1_Frame_2:  ; Arrow Down
  player1:
    %00000000
    %00011000
    %00011000
    %00011000
    %11011011
    %01111110
    %00111100
    %00011000
  end
  return

__P1_Frame_3:  ; Arrow Left
  player1:
    %00000000
    %00011000
    %00110000
    %01111111
    %01111111
    %00110000
    %00011000
    %00000000
  end
  return


__Update_P2_Sprite
  on p2_frame goto __P2_Frame_0 __P2_Frame_1 __P2_Frame_2 __P2_Frame_3

__P2_Frame_0:  ; Arrow Up
  player2:
    %00011000
    %00111100
    %01111110
    %11011011
    %00011000
    %00011000
    %00011000
    %00000000
  end
  return

__P2_Frame_1:  ; Arrow Right
  player2:
    %00000000
    %00011000
    %00001100
    %11111110
    %11111110
    %00001100
    %00011000
    %00000000
  end
  return

__P2_Frame_2:  ; Arrow Down
  player2:
    %00000000
    %00011000
    %00011000
    %00011000
    %11011011
    %01111110
    %00111100
    %00011000
  end
  return

__P2_Frame_3:  ; Arrow Left
  player2:
    %00000000
    %00011000
    %00110000
    %01111111
    %01111111
    %00110000
    %00011000
    %00000000
  end
  return


__Update_P3_Sprite
  on p3_frame goto __P3_Frame_0 __P3_Frame_1 __P3_Frame_2 __P3_Frame_3

__P3_Frame_0:  ; Arrow Up
  player3:
    %00011000
    %00111100
    %01111110
    %11011011
    %00011000
    %00011000
    %00011000
    %00000000
  end
  return

__P3_Frame_1:  ; Arrow Right
  player3:
    %00000000
    %00011000
    %00001100
    %11111110
    %11111110
    %00001100
    %00011000
    %00000000
  end
  return

__P3_Frame_2:  ; Arrow Down
  player3:
    %00000000
    %00011000
    %00011000
    %00011000
    %11011011
    %01111110
    %00111100
    %00011000
  end
  return

__P3_Frame_3:  ; Arrow Left
  player3:
    %00000000
    %00011000
    %00110000
    %01111111
    %01111111
    %00110000
    %00011000
    %00000000
  end
  return
