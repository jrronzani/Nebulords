  ;***************************************************************
  ;  SPRITE ARCHITECTURE TEST V2 - OPTIMIZED
  ;  Only update sprites when frames CHANGE (not every frame)
  ;
  ;  Optimization: Move sprite updates OUT of main loop
  ;  Updates only happen in frame advance functions
  ;
  ;  This mirrors Nebulords optimization: Only update ship sprites
  ;  when brick state changes (not every frame)
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

  ; Speed thresholds
  const p0_speed = 60  ; 1fps
  const p1_speed = 12  ; 5fps
  const p2_speed = 6   ; 10fps
  const p3_speed = 3   ; 20fps

  ;***************************************************************
  ;  Initialize
  ;***************************************************************
  COLUBK = $00

  ; Position 4 sprites
  player0x = 40 : player0y = 20
  player1x = 70 : player1y = 20
  player2x = 100 : player2y = 20
  player3x = 130 : player3y = 20

  ; Initialize frames
  p0_frame = 0
  p1_frame = 0
  p2_frame = 0
  p3_frame = 0

  ; Initialize counters
  p0_counter = 0
  p1_counter = 0
  p2_counter = 0
  p3_counter = 0

  ; Set initial sprites (all arrows pointing up)
  gosub __Set_P0_Sprite
  gosub __Set_P1_Sprite
  gosub __Set_P2_Sprite
  gosub __Set_P3_Sprite

  ; Set sprite colors
  player0color:
    $96,$96,$96,$96,$96,$96,$96,$96
end

  player1color:
    $26,$26,$26,$26,$26,$26,$26,$26
end

  player2color:
    $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
end

  player3color:
    $76,$76,$76,$76,$76,$76,$76,$76
end

  ;***************************************************************
  ;  MAIN LOOP - OPTIMIZED
  ;  Sprite updates ONLY happen when frames change
  ;***************************************************************
__Main_Loop

  ; Update counters
  p0_counter = p0_counter + 1
  p1_counter = p1_counter + 1
  p2_counter = p2_counter + 1
  p3_counter = p3_counter + 1

  ; Advance frames when threshold reached
  ; Sprite update happens INSIDE these functions
  if p0_counter >= p0_speed then gosub __Advance_P0_Frame
  if p1_counter >= p1_speed then gosub __Advance_P1_Frame
  if p2_counter >= p2_speed then gosub __Advance_P2_Frame
  if p3_counter >= p3_speed then gosub __Advance_P3_Frame

  ; NO SPRITE UPDATES HERE!
  ; This is the key architectural difference

  drawscreen
  goto __Main_Loop


  ;***************************************************************
  ;  FRAME ADVANCE + SPRITE UPDATE (COMBINED)
  ;  Only updates sprite when frame actually changes
  ;***************************************************************
__Advance_P0_Frame
  p0_counter = 0
  p0_frame = p0_frame + 1
  if p0_frame > 3 then p0_frame = 0
  gosub __Set_P0_Sprite  ; Update sprite immediately after frame change
  return

__Advance_P1_Frame
  p1_counter = 0
  p1_frame = p1_frame + 1
  if p1_frame > 3 then p1_frame = 0
  gosub __Set_P1_Sprite
  return

__Advance_P2_Frame
  p2_counter = 0
  p2_frame = p2_frame + 1
  if p2_frame > 3 then p2_frame = 0
  gosub __Set_P2_Sprite
  return

__Advance_P3_Frame
  p3_counter = 0
  p3_frame = p3_frame + 1
  if p3_frame > 3 then p3_frame = 0
  gosub __Set_P3_Sprite
  return


  ;***************************************************************
  ;  SPRITE SETTERS - OUTSIDE MAIN LOOP
  ;  Called only when frame state changes
  ;***************************************************************
__Set_P0_Sprite
  on p0_frame goto __P0_F0 __P0_F1 __P0_F2 __P0_F3

__P0_F0  ; Up
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

__P0_F1  ; Right
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

__P0_F2  ; Down
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

__P0_F3  ; Left
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


__Set_P1_Sprite
  on p1_frame goto __P1_F0 __P1_F1 __P1_F2 __P1_F3

__P1_F0
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

__P1_F1
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

__P1_F2
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

__P1_F3
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


__Set_P2_Sprite
  on p2_frame goto __P2_F0 __P2_F1 __P2_F2 __P2_F3

__P2_F0
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

__P2_F1
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

__P2_F2
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

__P2_F3
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


__Set_P3_Sprite
  on p3_frame goto __P3_F0 __P3_F1 __P3_F2 __P3_F3

__P3_F0
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

__P3_F1
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

__P3_F2
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

__P3_F3
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
