  ;***************************************************************
  ;  PXE Virtual Sprite Coordinate Offset Test
  ;
  ;  Purpose: Empirically test if virtual sprites have X/Y coordinate offsets
  ;
  ;  Test Setup:
  ;  - All sprites set to same X coordinate (80)
  ;  - 4x4 pixel sprites, different colors
  ;  - Spaced 5 scanlines apart (4 sprite + 1 gap)
  ;  - If all align vertically, no X offset bug
  ;  - If any stick out left/right, note which sprite number
  ;***************************************************************

  set kernel PXE

  ; Set colors
  COLUBK = $00  ; Black background
  COLUPF = $0E  ; White ball
  COLUP0 = $2E  ; Orange missile0
  COLUP1 = $4E  ; Red missile1

  ; Set all sprites to same X position
  ; Y positions spaced 5 scanlines apart (4px sprite + 1px gap)
  player0x = 80  : player0y = 10
  player1x = 80  : player1y = 15
  player2x = 80  : player2y = 20
  player3x = 80  : player3y = 25
  player4x = 80  : player4y = 30
  player5x = 80  : player5y = 35
  player6x = 80  : player6y = 40
  player7x = 80  : player7y = 45
  player8x = 80  : player8y = 50
  player9x = 80  : player9y = 55
  player10x = 80 : player10y = 60
  player11x = 80 : player11y = 65
  player12x = 80 : player12y = 70
  player13x = 80 : player13y = 75
  player14x = 80 : player14y = 80
  player15x = 80 : player15y = 85
  player16x = 80 : player16y = 90

  ; Configure sprite sizes - normal single sprites with masking for virtual
  NUSIZ0 = $30   ; player0 normal + missile0 quad width
  _NUSIZ1 = $30  ; player1 normal + missile1 quad width
  NUSIZ2 = $40   ; player2 with masking
  NUSIZ3 = $40   ; player3 with masking
  NUSIZ4 = $40
  NUSIZ5 = $40
  NUSIZ6 = $40
  NUSIZ7 = $40
  NUSIZ8 = $40
  NUSIZ9 = $40
  NUSIZ10 = $40
  NUSIZ11 = $40
  NUSIZ12 = $40
  NUSIZ13 = $40
  NUSIZ14 = $40
  NUSIZ15 = $40
  NUSIZ16 = $40

  ; Put ball at bottom (4 pixels wide for visibility)
  ballheight = 4
  ballx = 80 : bally = 100

  ; Put missiles at bottom (quad width via NUSIZ above)
  missile0height = 4
  missile0x = 80 : missile0y = 110

  missile1height = 4
  missile1x = 80 : missile1y = 120

__Main_Loop
  drawscreen
  goto __Main_Loop

  ; 4x4 pixel sprites
  player0:
  %11110000
  %11110000
  %11110000
  %11110000
end
  player0color:
  $0E  ; White
  $0E
  $0E
  $0E
end

  player1:
  %11110000
  %11110000
  %11110000
  %11110000
end
  player1color:
  $1E
  $1E
  $1E
  $1E
end

  player2-16:
  %11110000
  %11110000
  %11110000
  %11110000
end

  player2-16color:
  $2E  ; player2 orange
  $2E
  $2E
  $2E
  $3E  ; player3 red-orange
  $3E
  $3E
  $3E
  $4E  ; player4 red
  $4E
  $4E
  $4E
  $5E  ; player5 purple-red
  $5E
  $5E
  $5E
  $6E  ; player6 purple
  $6E
  $6E
  $6E
  $7E  ; player7 blue-purple
  $7E
  $7E
  $7E
  $8E  ; player8 blue
  $8E
  $8E
  $8E
  $9E  ; player9 cyan
  $9E
  $9E
  $9E
  $AE  ; player10 teal
  $AE
  $AE
  $AE
  $BE  ; player11 green-cyan
  $BE
  $BE
  $BE
  $CE  ; player12 green
  $CE
  $CE
  $CE
  $DE  ; player13 yellow-green
  $DE
  $DE
  $DE
  $EE  ; player14 light green
  $EE
  $EE
  $EE
  $FE  ; player15 light yellow
  $FE
  $FE
  $FE
  $1C  ; player16 dark yellow
  $1C
  $1C
  $1C
end
