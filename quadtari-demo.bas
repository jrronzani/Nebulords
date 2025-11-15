  ; PXE DEMO - Quadtari support
  ; The Quadtari adapter allows 4 joystick controllers to be connected to a single console.
  ; Special thanks to Nathan Tolbert for making Quadtari support in PXE possible.
  ; Visit https://www.bitethechili.com/quadtari/ for more information and to purchase a Quadtari adapter.

  ; Tell bB to use the PXE kernel
  set kernel PXE

  const font = hex

  ; put unused objects off screen
  missile0y = 200
  missile1y = 200
  bally = 200

  ; Set the colors of players 1-4 so we can tell them apart
  player1color:
  $14
  $16
  $18
  $1a
  $1c
end

  player2color:
  $34
  $36
  $38
  $3a
  $3c
end

  player3color:
  $54
  $56
  $58
  $5a
  $5c
end

  player4color:
  $74
  $76
  $78
  $7a
  $7c
end

  ; Spread out the initial positions to make them all visible
  player1x = 30
  player1y = 30

  player2x = 50
  player2y = 50

  player3x = 70
  player3y = 70

  player4x = 90
  player4y = 90

  ; Enable automatic horizontal masking so sprites can go offscreen smoothly
  ; Setting nusiz to %01xxxxxx ($40) tells PXE to automatically mask players1-16
  _NUSIZ1 = $40 ; 1 copy
  NUSIZ2 = $41 ; 2 copy close
  NUSIZ3 = $42 ; 2 copy medium
  NUSIZ4 = $43 ; 3 copy close


__Main_Loop

  ; adjust position and sprite for all 4 joysticks
   if joy0up then player1y = player1y - 1 
   if joy0down then player1y = player1y + 1
   if joy0left then player1x = player1x - 1
   if joy0right then player1x = player1x + 1
   if joy0fire then gosub ___p1fire
   if !joy0fire then gosub ___p1nofire

   if joy1up then player2y = player2y - 1 
   if joy1down then player2y = player2y + 1
   if joy1left then player2x = player2x - 1
   if joy1right then player2x = player2x + 1
   if joy1fire then gosub ___p2fire
   if !joy1fire then gosub ___p2nofire

   if joy2up then player3y = player3y - 1 
   if joy2down then player3y = player3y + 1
   if joy2left then player3x = player3x - 1
   if joy2right then player3x = player3x + 1
   if joy2fire then gosub ___p3fire
   if !joy2fire then gosub ___p3nofire

   if joy3up then player4y = player4y - 1 
   if joy3down then player4y = player4y + 1
   if joy3left then player4x = player4x - 1
   if joy3right then player4x = player4x + 1
   if joy3fire then gosub ___p4fire
   if !joy3fire then gosub ___p4nofire

  drawscreen
  goto __Main_Loop

  ; sub routines to set the sprites
___p1fire
  player1:
  $ff
  $ff
  $ff
  $ff
  $ff
end
  return

___p1nofire
  player1:
  $ff
  $c3
  $c3
  $c3
  $ff
end
  return

___p2fire
  player2:
  $ff
  $ff
  $ff
  $ff
  $ff
end
  return

___p2nofire
  player2:
  $ff
  $c3
  $c3
  $c3
  $ff
end
  return

___p3fire
  player3:
  $ff
  $ff
  $ff
  $ff
  $ff
end
  return

___p3nofire
  player3:
  $ff
  $c3
  $c3
  $c3
  $ff
end
  return

___p4fire
  player4:
  $ff
  $ff
  $ff
  $ff
  $ff
end
  return

___p4nofire
  player4:
  $ff
  $c3
  $c3
  $c3
  $ff
end
  return
