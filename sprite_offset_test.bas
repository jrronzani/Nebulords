  ;***************************************************************
  ;  PXE Virtual Sprite Coordinate Offset Test - Minimal Version
  ;***************************************************************

  set kernel PXE

  PF_MODE = $F1
  DF0FRACINC = 2

  gosub __Setup

__Main_Loop
  COLUBK = $84  ; Dark blue
  COLUP0 = $0E  ; White
  COLUP1 = $2E  ; Orange
  drawscreen
  goto __Main_Loop

__Setup
  ; Hardware sprites
  player0x = 80 : player0y = 10
  player1x = 80 : player1y = 20

  ; Virtual sprites
  player2x = 80 : player2y = 30
  player3x = 80 : player3y = 40
  player4x = 80 : player4y = 50
  player5x = 80 : player5y = 60
  player6x = 80 : player6y = 70
  player7x = 80 : player7y = 80
  player8x = 80 : player8y = 90
  player9x = 80 : player9y = 100
  player10x = 80 : player10y = 110
  player11x = 80 : player11y = 120
  player12x = 80 : player12y = 130
  player13x = 80 : player13y = 140
  player14x = 80 : player14y = 150
  player15x = 80 : player15y = 160
  player16x = 80 : player16y = 5

  ; Configure sizes
  NUSIZ0 = $00
  _NUSIZ1 = $00
  NUSIZ2 = $40
  NUSIZ3 = $40
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

  ; Ball
  ballheight = 4
  ballx = 80 : bally = 95
  return

  ; Sprite graphics
  player0:
  %11110000
  %11110000
  %11110000
  %11110000
end

  player0color:
  $0E
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
  $2E
  $2E
  $2E
  $2E
  $3E
  $3E
  $3E
  $3E
  $4E
  $4E
  $4E
  $4E
  $5E
  $5E
  $5E
  $5E
  $6E
  $6E
  $6E
  $6E
  $7E
  $7E
  $7E
  $7E
  $8E
  $8E
  $8E
  $8E
  $9E
  $9E
  $9E
  $9E
  $AE
  $AE
  $AE
  $AE
  $BE
  $BE
  $BE
  $BE
  $CE
  $CE
  $CE
  $CE
  $DE
  $DE
  $DE
  $DE
  $EE
  $EE
  $EE
  $EE
  $FE
  $FE
  $FE
  $FE
  $1C
  $1C
  $1C
  $1C
end
