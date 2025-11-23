;==============================================
;
; 		 StarGiraf - A Jeff Minter Jam game for Atari 2600
;
; 			by Dr. Ludos (2025)
;
;	Get all my other games:
;			http://drludos.itch.io/
;	Support my work and get access to betas and prototypes:
;			http://www.patreon.com/drludos
;
; 	Made in batariBasic thanks to the wonderful documentation and examples from RandomTerrain:
;	http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#gettingstarted
;
;	The code uses RandomTerrain's notation: _variableAlias / __label 
;
;	The sound effects come from RevEng wonderful SFX library, adapter to batariBasic by Karl G. 
;	https://forums.atariage.com/topic/348849-revengs-sound-collection-in-bb/
;
;==============================================
   
   
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++[ BANK 1 ]+++++++++++++++++++++++++++++++++++
;++ This bank contains the init code (and also the DPC kernel code, filling almost the whole bank) ++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;	bank 1

	; Set Kernel options
	set kernel DPC+
	set tv ntsc
	;set smartbranching on
	;set optimization inlinerand 
	;set kernel_options collision(playfield,player1)
	
	

;============================================
;======= VARIABLES & ALIASES (DIMs) ============
;============================================ 

	; Player variables
	dim _playerX = player0x ; Player X position
	dim _playerY = player0y ; Player Y position
	dim _shotX = a ; X aiming direction (used to apply initial speed to bullet when fired)
	dim _playerAnim = b ; player ticks counter for animation

	; Bullet variables
	dim _bullet0SpeedX = c ; bullet 0 X movement (0: inactive / <>0 : speed X value)
	dim _bullet1SpeedX = d ; bullet 1 X movement (0: inactive / <>0 : speed X value)
	dim _bulletDelay = e ; Delay to wait before being able to fire the next bullet
	
	; Foes variables
	dim _foeAnim = f ; variable used to track animation frames used to animate the foes
	dim _foe1 = g; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe2 = h; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe3 = i; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe4 = j; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe5 = k; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe6 = l; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe7 = m; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe8 = n; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	dim _foe9 = o; general purpose variable used for the player1 foe (life, direction, etc.). If > 0 the foe is active, else if it's = 0 then the foe is inactive
	
	; Misc variables
	dim _msgAnim = p ; variable used to track animation frames used to animate the on screen messages
	dim _bgAnim = q ; variable used to track animation frames used to animate background color (the red fading effect when hit)
	dim _lives = r ; Current player lives
	dim _invincible = s ; if > 0 then player is invincible! (e.g. after losing a life)
	
	
	
	; BACKEND variables (uses the var0-var9 extra variables of the DPC+ kernel)
	dim _pressed = var0 ; used to track whether a button is currently pressed or not, using individual bits: {0} : Fire / {1} : Left / {2} : Right / {3} : Up / {4} : Down / {5} : Game Select Switch (Pause) / {6} : Game Reset Switch
	dim _isPaused = var1 ; if 1 the game is paused, else it's running normaly
	dim _ticks = var2 ; variable counting the frames (0-255)
	dim _ticks2 = var3 ; variable alternating between 0 and 1 to be able to move / animate "every 2 frames"
	dim _ticks3 = var4 ; variable alternating between 0 and 1 to be able to move / animate "every 3 frames"
	
	; Sound & Music (both channels)
	dim _sfx0note = var5 ; Current note index in the note data table (see _SFX0 data table)
	dim _sfx1note = var6 ; Current note index in the note data table (see _SFX1 data table)
	
	; SFX samples "first note indexes" shortcuts (from the "notes" tables "_SFX0" and "_SFX1", one for each channel)
	; Channel 0 (gameplay)
	const _SFX_shoot = 0
	; Channel 1 (gameplay)
	const _SFX_killfoe= 0
	const _SFX_hitplayer= 100
	; Channel 0 (game over)
	const _SFX_falling= 0
	; Channel 1 (game over)
	const _SFX_dead= 0
	; NB: the game over sounds (falling and game over beeps) have their own dedicated table, as their requires more than half of the 256 bytes each!
 
	; Converts 6 digit score to 3 sets of two digits. Thanks to RandomTerrain: http://www.randomterrain.com/atari-2600-memories-batari-basic-commands.html#score
	; How to check the digits:
	; 100 thousands digit .. _scoreA & $F0 (X0 00 00)
	; 10 thousands digit ... _scoreA & $0F (0X 00 00)
	; Thousands digit ...... _scoreB & $F0 (00 X0 00)
	; Hundreds digit ....... _scoreB & $0F (00 0X 00)
	; Tens digit ........... _scoreC & $F0 (00 00 X0)
	; Ones digit ........... _scoreC & $0F (00 00 0X)
	dim _scoreA = score
	dim _scoreB = score+1
	dim _scoreC = score+2




;================================
;====== PROGRAM INIT ============
;================================

__INIT

	; set debug cyclescore
	
	; dim mincycles = z
	; mincycles = 255 

	; Set no button as "pressed" by default
	_pressed = 0
	
	; Go to the title screen to start the game
	goto __TITLE bank3
	
;=============================
;====== VBLANK ROUTINE ========
;=============================
	vblank
	
	; Set up Ball to move repeatedly (each HMOVE) to draw the Starfield, replicating the TIA bug using the DPC+ (and thus compatible on all TIA revisions)
	; Big thanks to RevEng for creating and sharing this trick, see the full details here: https://forums.atariage.com/topic/258938-bb-starfield-effect/
	HMBL=$70
	
	; go back to the previous code, it's important to have this line here, else the game won't display anything (freezing)
	return otherbank
   
   
   
   
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++[ BANK 2 ]++++++++++++++++++++++++++++++++
;++ This bank contains the gameplay code alongside the gameplay audio playing routines and sound data
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

   bank 2
   temp1=temp1



;=============================
;====== MAIN LOOP ============
;=============================
__MAIN


	; ==== STARFIELD ===
	
	; First, move the ball to draw the starfield (every 4 frames so it scrolls slowly)
	if _ticks & 3 = 0 then ballx=ballx+15
	
	; For the starfield effect, the ball position needs to ranges from 0-159. 
	; ** If it is 0 and decreases (i.e 255 or less as it's a 8bit variables that loops), then set it to 159 
	if ballx>200 then ballx=ballx+160
	; ** If it is 159 and increases, set it to 0
	if ballx>159 then ballx=ballx-160

	; Scrolls the playfield colors too to makes to start colors move, in the opposite direction of their move (stars move down, colors move up)
	if _ticks & 7 =  0 then pfscroll 1 4 4

	/* DISABLED FOR NOW AS IT'S BUGGY WITH THE STARFIELD / color scroll CODE, and no time to fix it before jam ends (but no big issue, this is not central to the gameplay code)
	; ==== PAUSE / UNPAUSE ===
	; Do it after the scrolling code, as this one also happens during the vblank code, and thus cannot be paused and be done fully to avoid graphical glitches (such as new lines not created during a scrolling)
	
	; If the reset switch is pressed and wasn't pressed previously, switch the isPaused value (use a XOR to make alternate between 0 and 1)
	if switchselect && !_pressed{5} then _pressed{5} = 1 : _isPaused = _isPaused ^ %00000001
	
	; Release the pause button if not pressed
	if !switchselect then _pressed{5} = 0
	
	; if the game is paused, mute the sound on both channels and then skip the whole frame
	if _isPaused <> 0 then AUDV0 = 0 : AUDV1 = 0 : goto __ENDFRAME
	
	*/


	; ==== TICKS COUNTERS ===

	; Frame counter (0-239, so 4 seconds in total)
	_ticks=_ticks+1
	if _ticks > 239 then _ticks = 0
	
	/* DISABLED BECAUSE NOT USED IN THE CURRENT GAME STATE
	; Every 2 frames (use a XOR to make alternate between 0 and 1)
	_ticks2 = _ticks2 ^ %00000001
	
	; Every 3 frames (use a XOR to make alternate between 0 and 1 and then increase it)
	_ticks3 = _ticks3 ^ %00000001
	_ticks3 = _ticks3+1
	if _ticks3 > 2 then _ticks3 = 0
	*/

	; ==== BULLET 0 MOVEMENT ===

	; Set missile 0 width and player width
	NUSIZ0=$25

	; If bullet isn't active, we skip this part
	if _bullet0SpeedX = 0 then goto __SKIP_BULLET0
	
	; move in X
	missile0x=missile0x+_bullet0SpeedX
	
	; if out of bounds, reset missile (only need to test if X > 160 as if it goes below 0 for left border it'll loop back to 255)
	if missile0x > 160 then _bullet0SpeedX=0 : missile0y=200

__SKIP_BULLET0	


	; ==== BULLET 1 MOVEMENT ===

	; Set missile 1 width and player width. Do it with all the virtual sprite variables, else it won't work in this DPC+ kernel
	_NUSIZ1 = _NUSIZ1 | $20 
	NUSIZ2 = NUSIZ2 | $20
	NUSIZ3 = NUSIZ3 | $20
	NUSIZ4 = NUSIZ4 | $20
	NUSIZ5 = NUSIZ5 | $20
	NUSIZ6 = NUSIZ6 | $20
	NUSIZ7 = NUSIZ7 | $20
	NUSIZ8 = NUSIZ8 | $20
	NUSIZ9 = NUSIZ9 | $20

	; If bullet isn't active, we skip this part
	if _bullet1SpeedX = 0 then goto __SKIP_BULLET1
	
	; move in X
	missile1x=missile1x+_bullet1SpeedX
	
	; if out of bounds, reset missile (only need to test if X > 160 as if it goes below 0 for left border it'll loop back to 255)
	if missile1x > 160 then _bullet1SpeedX=0 : missile1y=200

__SKIP_BULLET1

	
	

	; ==== PLAYER ===
	
	; PLAYER MOVEMENT AND AIMING
	; Change player aiming / moving direction with joystick
	
	; Move Left
	if joy0left then _shotX=-5 : _playerX = _playerX - 2
	
	; Move Right
	if joy0right then _shotX=5 : _playerX = _playerX + 2

	; Sprite flipping (if needed)
	; If the shot direction is left we flip the sprite, else it'll stay in normal flipping state (we must do it each frame because score drawing routine reset this register)
	if _shotX = -5 then REFP0=8 else REFP0=0

	; Move Up
	if joy0up then _playerY = _playerY - 2
	
	; Move Down
	if joy0down then _playerY = _playerY + 2

	; Prevent Player from exiting the screen
	; Left border (below 0 => 255 and below)
	if _playerX > 200 then _playerX = 0
	; Right border
	if _playerX > 142 then _playerX = 142
	; Top border (below 0 => 255 and below)
	if _playerY > 200 then _playerY = 0
	; Bottom border
	if _playerY > 160 then _playerY = 160
	
	; Clip the player sprite height dynamically so it doesn't overflow when moving down (it's 176 pixels tall in total, quite a long neck!)
	player0height=180-_playerY

	; Fire bullet if button is pressed down (and if the bullets are "ready", see subroutine)
	if joy0fire && _bulletDelay=0 then gosub __SHOOT
	
	; If the bullet cooldown delay isn't 0, decrease it
	if _bulletDelay > 0 then _bulletDelay = _bulletDelay-1


	; ==== FOES SPAWNING ===

	; Generate a new foe every X ticks
	if (_ticks&63) = 0 then gosub __SPAWN_FOE


	; ==== FOES MOVEMENT ===
	; Skip all the foe code blocks except the ones currently active for animation / movement 
	; A foe is inactive if it's variable is 0, else the value is used differently for each foe type


	; FOE 1 (RAZOR BLADE - variable used for direction)
	if _foe1 = 0 then goto __SKIP_FOE_1
	
	; Move back and forth horizontally
	player1x=player1x+_foe1
	
	; Change moving direction when reaching bounds
	if player1x > 200 then player1x=0 : _foe1=-_foe1
	if player1x > 151 then player1x=151 : _foe1=-_foe1
	
	; Collision with bullets : kill the foe!
	; Bullet 0
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile0y + 6) > player1y && missile0y < (player1y + 8) && (missile0x + 8) > player1x && missile0x < (player1x + 8) then goto __FOE_1_BULLET0HIT
	goto __SKIP_FOE_1_BULLET0HIT
__FOE_1_BULLET0HIT
		; Disable the foe
		_foe1=0
		player1y=200 
		; Disable the bullet
		_bullet0SpeedX=0
		missile0y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_1_BULLET0HIT	
	
	; Bullet 1
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile1y + 6) > player1y && missile1y < (player1y + 8) && (missile1x + 8) > player1x && missile1x < (player1x + 8) then goto __FOE_1_BULLET1HIT	
	goto __SKIP_FOE_1_BULLET1HIT
__FOE_1_BULLET1HIT	
		; Disable the foe
		_foe1=0
		player1y=200
		; Disable the bullet
		_bullet1SpeedX=0
		missile1y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_1_BULLET1HIT

	; If collision with player, disable the foe, remove 1 player life, and update display counter (game over of no more lives will be checked at the end of the frame)
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (player0y + player0height) > player1y && player0y < (player1y + 8) && (player0x + 8) > player1x && player0x+2 < player1x then goto __FOE_1_PLAYERHIT
	goto __SKIP_FOE_1_PLAYERHIT
__FOE_1_PLAYERHIT
	; Disable the foe
	_foe1=0
	player1y=200
	; Player lose lives
	_lives = _lives - 1
	; Play SFX
	_sfx1note=_SFX_hitplayer
	; make the screen flash red
	_bgAnim = 6
	; update lives DISPLAY
	gosub __UPDATE_LIVES
__SKIP_FOE_1_PLAYERHIT

__SKIP_FOE_1




	; FOE 2 (RAZOR BLADE - variable used for direction)
	if _foe2 = 0 then goto __SKIP_FOE_2
	
	; Move back and forth horizontally
	player2x=player2x+_foe2
	
	; Change moving direction when reaching bounds
	if player2x > 200 then player2x=0 : _foe2=-_foe2
	if player2x > 151 then player2x=151 : _foe2=-_foe2
	
	; Collision with bullets : kill the foe!
	; Bullet 0
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile0y + 6) > player2y && missile0y < (player2y + 8) && (missile0x + 8) > player2x && missile0x < (player2x + 8) then goto __FOE_2_BULLET0HIT
	goto __SKIP_FOE_2_BULLET0HIT
__FOE_2_BULLET0HIT
		; Disable the foe
		_foe2=0
		player2y=200 
		; Disable the bullet
		_bullet0SpeedX=0
		missile0y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_2_BULLET0HIT	
	
	; Bullet 1
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile1y + 6) > player2y && missile1y < (player2y + 8) && (missile1x + 8) > player2x && missile1x < (player2x + 8) then goto __FOE_2_BULLET1HIT	
	goto __SKIP_FOE_2_BULLET1HIT
__FOE_2_BULLET1HIT	
		; Disable the foe
		_foe2=0
		player2y=200
		; Disable the bullet
		_bullet1SpeedX=0
		missile1y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_2_BULLET1HIT

	; If collision with player, disable the foe, remove 1 player life, and update display counter (game over of no more lives will be checked at the end of the frame)
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (player0y + player0height) > player2y && player0y < (player2y + 8) && (player0x + 8) > player2x && player0x+2 < player2x then goto __FOE_2_PLAYERHIT
	goto __SKIP_FOE_2_PLAYERHIT
__FOE_2_PLAYERHIT
	; Disable the foe
	_foe2=0
	player2y=200
	; Player lose lives
	_lives = _lives - 1
	; Play SFX
	_sfx1note=_SFX_hitplayer
	; make the screen flash red
	_bgAnim = 6
	; update lives DISPLAY
	gosub __UPDATE_LIVES
__SKIP_FOE_2_PLAYERHIT

__SKIP_FOE_2




	; FOE 3 (RAZOR BLADE - variable used for direction)
	if _foe3 = 0 then goto __SKIP_FOE_3
	
	; Move back and forth horizontally
	player3x=player3x+_foe3
	
	; Change moving direction when reaching bounds
	if player3x > 200 then player3x=0 : _foe3=-_foe3
	if player3x > 151 then player3x=151 : _foe3=-_foe3
	
	; Collision with bullets : kill the foe!
	; Bullet 0
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile0y + 6) > player3y && missile0y < (player3y + 8) && (missile0x + 8) > player3x && missile0x < (player3x + 8) then goto __FOE_3_BULLET0HIT
	goto __SKIP_FOE_3_BULLET0HIT
__FOE_3_BULLET0HIT
		; Disable the foe
		_foe3=0
		player3y=200 
		; Disable the bullet
		_bullet0SpeedX=0
		missile0y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_3_BULLET0HIT	
	
	; Bullet 1
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile1y + 6) > player3y && missile1y < (player3y + 8) && (missile1x + 8) > player3x && missile1x < (player3x + 8) then goto __FOE_3_BULLET1HIT	
	goto __SKIP_FOE_3_BULLET1HIT
__FOE_3_BULLET1HIT	
		; Disable the foe
		_foe3=0
		player3y=200
		; Disable the bullet
		_bullet1SpeedX=0
		missile1y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_3_BULLET1HIT

	; If collision with player, disable the foe, remove 1 player life, and update display counter (game over of no more lives will be checked at the end of the frame)
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (player0y + player0height) > player3y && player0y < (player3y + 8) && (player0x + 8) > player3x && player0x+2 < player3x then goto __FOE_3_PLAYERHIT
	goto __SKIP_FOE_3_PLAYERHIT
__FOE_3_PLAYERHIT
	; Disable the foe
	_foe3=0
	player3y=200
	; Player lose lives
	_lives = _lives - 1
	; Play SFX
	_sfx1note=_SFX_hitplayer
	; make the screen flash red
	_bgAnim = 6
	; update lives DISPLAY
	gosub __UPDATE_LIVES
__SKIP_FOE_3_PLAYERHIT

__SKIP_FOE_3




	; FOE 4 (RAZOR BLADE - variable used for direction)
	if _foe4 = 0 then goto __SKIP_FOE_4
	
	; Move back and forth horizontally
	player4x=player4x+_foe4
	
	; Change moving direction when reaching bounds
	if player4x > 200 then player4x=0 : _foe4=-_foe4
	if player4x > 151 then player4x=151 : _foe4=-_foe4
	
	; Collision with bullets : kill the foe!
	; Bullet 0
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile0y + 6) > player4y && missile0y < (player4y + 8) && (missile0x + 8) > player4x && missile0x < (player4x + 8) then goto __FOE_4_BULLET0HIT
	goto __SKIP_FOE_4_BULLET0HIT
__FOE_4_BULLET0HIT
		; Disable the foe
		_foe4=0
		player4y=200 
		; Disable the bullet
		_bullet0SpeedX=0
		missile0y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_4_BULLET0HIT	
	
	; Bullet 1
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (missile1y + 6) > player4y && missile1y < (player4y + 8) && (missile1x + 8) > player4x && missile1x < (player4x + 8) then goto __FOE_4_BULLET1HIT	
	goto __SKIP_FOE_4_BULLET1HIT
__FOE_4_BULLET1HIT	
		; Disable the foe
		_foe4=0
		player4y=200
		; Disable the bullet
		_bullet1SpeedX=0
		missile1y=200
		; Earn score
		score = score + 100
		; Play SFX
		_sfx1note=_SFX_killfoe
		; Display onscreen message
		gosub __SHOW_MSG
__SKIP_FOE_4_BULLET1HIT

	; If collision with player, disable the foe, remove 1 player life, and update display counter (game over of no more lives will be checked at the end of the frame)
	; Compute a AABB collision (as hardware collision is not 100% reliable and a bit messy with virtual sprites)
	if (player0y + player0height) > player4y && player0y < (player4y + 8) && (player0x + 8) > player4x && player0x+2 < player4x then goto __FOE_4_PLAYERHIT
	goto __SKIP_FOE_4_PLAYERHIT
__FOE_4_PLAYERHIT
	; Disable the foe
	_foe4=0
	player4y=200
	; Player lose lives
	_lives = _lives - 1
	; Play SFX
	_sfx1note=_SFX_hitplayer
	; make the screen flash red
	_bgAnim = 6
	; update lives DISPLAY
	gosub __UPDATE_LIVES
__SKIP_FOE_4_PLAYERHIT

__SKIP_FOE_4


	; ==== FOES  ANIMATION ===

	; For now, all the foes share the same animation frames and are updated simultaneously

	; Increase foe animation counter 
	_foeAnim=_foeAnim+1
	; Makes it loop (4 frames * 2 ticks per frame = 8 ticks in total)
	if _foeAnim = 8 then _foeAnim = 0
	
	; Anim frame 1
	if _foeAnim=0 then player1-9:
	%00100000
        %00110000
        %00010011
        %00011110
        %01111000
        %11001000
        %00001100
        %00000100
end

	; Anim frame 2
	if _foeAnim=2 then player1-9:
	%00000000
        %01100010
        %00110110
        %00011100
        %00111000
        %01101100
        %01000110
        %00000000
end

	; Anim frame 3
	if _foeAnim=4 then player1-9:
	%00000100
        %01000110
        %11101100
        %00111000
        %00011100
        %00110111
        %01100010
        %00100000
end

	; Anim frame 4
	if _foeAnim=6 then player1-9:
	%00010000
        %00011000
        %00011000
        %01111111
        %11111110
        %00011000
        %00011000
        %00001000
end


	
	



	;-= PLAY SFX (CHANNEL 0 - reserved for the "shoot" sound as it's almost always on) =-
	
	; If no sound is active on this channel, skip the whole section
	if _sfx0note = 255 then goto __SKIP_sfx0

	; if the current sound is the last one of a sound effect (tone == 255), we mute the channel and end the sound playing (and skip the section)
	if _SFX0[_sfx0note] = 255 then _sfx0note = 255 : AUDV0 = 0 : goto __SKIP_sfx0
   
	; Else, we simply set the current sound params !
	; There are stored in the data table in this order: Volume, Control, Frequency (duration is always 1 frame per entry, so they are repeated if a note lasts several frames)
	
	; First get the params into temp variables
	; Frequency = _sfx0note
	; Control = _sfx0note+1
	temp5 = _sfx0note+1
	; Volume = _sfx0note+2 
	temp4 = _sfx0note+2
	
	; Then apply the sound params to the registers to play sound!
	; We do these in this order and without any other instructions between them so the sound isn't distorted (slowed down, etc.)
	AUDV0 = _SFX0[_sfx0note]
	AUDC0 = _SFX0[temp5] 
	AUDF0 = _SFX0[temp4] 
	
	; And then, move pointer to the next note
	_sfx0note = _sfx0note+3

__SKIP_sfx0


	;-= PLAY SFX (CHANNEL 1 - for all the other sound effects) =-
	
	; If no sound is active on this channel, skip the whole section
	if _sfx1note = 255 then goto __SKIP_sfx1
		
	; if the current sound is the last one of a sound effect (tone == 255), we mute the channel and end the sound playing (and skip the section)
	if _SFX1[_sfx1note] = 255 then _sfx1note = 255 : AUDV1 = 0 : goto __SKIP_sfx1
   
	; Else, we simply set the current sound params !
	; There are stored in the data table in this order: Volume, Control, Frequency (duration is always 1 frame per entry, so they are repeated if a note lasts several frames)
	
	; First get the params into temp variables
	; Frequency = _sfx1note
	; Control = _sfx1note+1
	temp5 = _sfx1note+1
	; Volume = _sfx1note+2 
	temp4 = _sfx1note+2
	
	; Then apply the sound params to the registers to play sound!
	; We do these in this order and without any other instructions between them so the sound isn't distorted (slowed down, etc.)
	AUDV1 = _SFX1[_sfx1note]
	AUDC1 = _SFX1[temp5]
	AUDF1 = _SFX1[temp4]
	
	; And then, move pointer to the next note
	_sfx1note = _sfx1note+3

__SKIP_sfx1


	;-= BG COLOR ANIMATION =-

	; if we must animate the BG color (a fade), we do it now using a subroutine, and then decrese the BG animation frame counter
	if _bgAnim > 0 then gosub __BG_ANIM_COLOR bank3 : _bgAnim = _bgAnim - 1



	;-= GAME OVER  =-

	; If the player a has no more lives (or even below 0 if it was hit by several foes at the same time), it's game over!
	if _lives = 0 || _lives > 200 then goto __GAMEOVER bank3

	
	;-= BACKEND =-
__ENDFRAME

	; Restore pfscore colors to display lives counter
	pfscorecolor = $1E

	; Playfield message animation

	; Refresh playfield sizes variables (everyframe to have a stable playfield drawing)
	DF0FRACINC=_msgAnimSteps[_msgAnim]
	DF1FRACINC=_msgAnimSteps[_msgAnim]
	DF2FRACINC=_msgAnimSteps[_msgAnim]
	DF3FRACINC=_msgAnimSteps[_msgAnim]
	DF4FRACINC=32
	DF6FRACINC=0

	; Update screen graphics
	drawscreen

	; Animate the playfield message if needed (animation > 0)
	if _msgAnim > 0 then _msgAnim=_msgAnim-1
		
		
	; Reset the game back to title screen
	if switchreset then _pressed{6} = 1 : goto __TITLE bank3
	
	
	
	; Restore player idle animation (in case it was changed to "shooting" during previous frames, do it after a few frames of the bulletdelay cooldown counter)
	if _bulletDelay = 8 then player0:
	%01010000
	%01010000
	%01010000
	%01111000
	%01111000
	%11101110
	%11101110
	%11111111
	%11111111
	%11111100
	%11111100
	%11111110
	%11111110
	%01111000
	%01111000
	%01110000
	%01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
end
	
	
	
	; endless mainloop
	goto __MAIN





;====== FIRE BULLET (subroutine) ============
__SHOOT
	
	; Can't shoot if bullet 0 is already moving
	if _bullet0SpeedX <> 0 then goto __NO_BULLET0
	
	; Else shoot bullet 0 from our current position
	missile0x=_playerX+4
	missile0y=_playerY+6
	_bullet0SpeedX=_shotX
	; Add some cooldown delay before next shot!
	_bulletDelay=12
	
	; Play SFX
	_sfx0note=_SFX_shoot
	
	; Store the current player height (to apply it to the new animation frame)
	temp6=player0height
	
	; Set player "shooting" animation frame
	player0:
	%01010000
	%01010000
	%01010000
	%01111000
	%01111000
	%11101110
	%11101110
	%11111111
	%11111111
	%11111100
	%11111100
	%11111100
	%11111100
	%01111110
	%01111110
	%01111000
	%01111000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
end

	; And apply the previous player0height so the player sprite still fits the screen perfectly
	player0height=temp6

	; Avoid firing bullet 1 too as we just shot bullet 0 !
	goto __NO_BULLET1
	
__NO_BULLET0	
	
	; Can't shoot if bullet 1 is already moving, so we can exit subroutine as no bullets are availble right now!
	if _bullet1SpeedX <> 0 then return thisbank
	
	; Else shoot bullet 1 from our current position
	missile1x=_playerX+4
	missile1y=_playerY+8
	_bullet1SpeedX=_shotX
	; Add some cooldown delay before next shot!
	_bulletDelay = 12

	; Store the current player height (to apply it to the new animation frame)
	temp6=player0height
	
	; Set player "shooting" animation frame
	player0:
	%01010000
	%01010000
	%01010000
	%01111000
	%01111000
	%11101110
	%11101110
	%11111111
	%11111111
	%11111100
	%11111100
	%11111100
	%11111100
	%01111110
	%01111110
	%01111000
	%01111000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
end

	; And apply the previous player0height so the player sprite still fits the screen perfectly
	player0height=temp6

	; Play SFX
	_sfx0note=_SFX_shoot

__NO_BULLET1
	
	; End subroutine (in case it didn't end already!)
	return thisbank





;====== SPAWN FOE (subroutine) ============
__SPAWN_FOE


	; FOE 1 - RAZOR BLADE (variable = X speed)

	; if the foe is already active, don't spawn it again
	if _foe1 <> 0 then goto __SKIP_SPAWN_FOE1
	
	; Position the foe on a random Y position 4-172 by step of 14 pixels to avoid virtual sprites flickering)
	; First generate a random number between 0 and 11 (0-7 + 0-3 + 0-1)
	player1y = (rand&7) + (rand&3) + (rand&1)
	; Then multiply it by the minimal Y step we need to avoid flickering (14 pixels height for a 8 pixels tall sprite)
	player1y = player1y*14 + 4
	
	; Set the X position to be either left or right, and set the initial movement direction (1 or -1) accordingly
	if (rand&1) = 0 then player1x=151 : _foe1=-1 else player1x=0 : _foe1=1
	
	; Increase foe speed after a certain score
	if _scoreB > $10 then _foe1=_foe1*2
	
	; A new foe has been spawned, so end subroutine now to avoid spawning 2 foes at the same time
	return thisbank
	
__SKIP_SPAWN_FOE1


	; FOE 2 - RAZOR BLADE (variable = X speed)

	; if the foe is already active, don't spawn it again
	if _foe2 <> 0 then goto __SKIP_SPAWN_FOE2
	
	; Position the foe on a random Y position 4-172 by step of 14 pixels to avoid virtual sprites flickering)
	; first generate a random number between 0 and 11 (0-7 + 0-3 + 0-1)
	player2y = (rand&7) + (rand&3) + (rand&1)
	; Then multiply it by the minimal Y step we need to avoid flickering (14 pixels height for a 8 pixels tall sprite)
	player2y = player2y*14 + 4
	
	; Set the X position to be either left or right, and set the initial movement direction (1 or -1) accordingly
	if (rand&1) = 0 then player2x=151 : _foe2=-1 else player2x=0 : _foe2=1
	
	; Increase foe speed after a certain score
	if _scoreB > $30 then _foe2=_foe2*2
	
	; A new foe has been spawned, so end subroutine now to avoid spawning 2 foes at the same time
	return thisbank
	
__SKIP_SPAWN_FOE2


	; FOE 3 - RAZOR BLADE (variable = X speed)

	; if the foe is already active, don't spawn it again
	if _foe3 <> 0 then goto __SKIP_SPAWN_FOE3
	
	; Position the foe on a random Y position 4-172 by step of 14 pixels to avoid virtual sprites flickering)
	; first generate a random number between 0 and 11 (0-7 + 0-3 + 0-1)
	player3y =  (rand&7) + (rand&3) + (rand&1)
	; Then multiply it by the minimal Y step we need to avoid flickering (14 pixels height for a 8 pixels tall sprite)
	player3y = player3y*14 + 4
	
	; Set the X position to be either left or right, and set the initial movement direction (1 or -1) accordingly
	if (rand&1) = 0 then player3x=151 : _foe3=-1 else player3x=0 : _foe3=1
	
	; A new foe has been spawned, so end subroutine now to avoid spawning 2 foes at the same time
	return thisbank
	
__SKIP_SPAWN_FOE3


	; FOE 4 - RAZOR BLADE (variable = X speed)

	; if the foe is already active, don't spawn it again
	if _foe4 <> 0 then goto __SKIP_SPAWN_FOE4
	
	; Position the foe on a random Y position 4-172 by step of 14 pixels to avoid virtual sprites flickering)
	; first generate a random number between 0 and 11 (0-7 + 0-3 + 0-1)
	player4y = (rand&7) + (rand&3) + (rand&1)
	; Then multiply it by the minimal Y step we need to avoid flickering (14 pixels height for a 8 pixels tall sprite)
	player4y = player4y*14 + 4
	
	; Set the X position to be either left or right, and set the initial movement direction (1 or -1) accordingly
	if (rand&1) = 0 then player4x=151 : _foe4=-1 else player4x=0 : _foe4=1
	
	; Increase foe speed after a certain score
	if _scoreB > $60 then _foe4=_foe4*2
	
	; A new foe has been spawned, so end subroutine now to avoid spawning 2 foes at the same time
	return thisbank
	
__SKIP_SPAWN_FOE4

	; If we reach here, we can't spawn anything as all foes are active

	; End subroutine
	return thisbank











;====== DISPLAY ONSCREEN MESSAGES (subroutine) ============
__SHOW_MSG

	; If a message is already display, cancel the current call
	if _msgAnim > 0 then goto __SKIP_MSG
	
	; Then, display an onscreen message based on current score (it uses BCD notation, so $99 means 99)
	if _scoreB = $01 || _scoreB = $50 then goto __MSG_YEAH
	if _scoreB = $05 || _scoreB = $60 then goto __MSG_EATTHIS
	if _scoreB = $10 || _scoreB = $70 then goto __MSG_YOUBEAST
	if _scoreB = $20 || _scoreB = $80 then goto __MSG_PERFECT
	if _scoreB = $30 || _scoreB = $90 then goto __MSG_MINTED
	if _scoreB = $40 || _scoreB = $00 then goto __MSG_YAKRULES
	
	; If we didn't reach a score warranting a message, we don't display any
	goto __SKIP_MSG


__MSG_YEAH
	; Define playfield message:
	playfield:
	.................................
	........X.X.XXX.XXX.X.X.X........
	........X.X.X...X.X.X.X.X........
	........XXX.XX..XXX.XXX.X........
	.........X..X...X.X.X.X..........
	.........X..XXX.X.X.X.X.X........
end	
	; Initialise the frame counter to animate the message display
	_msgAnim = 107
	
	; End the subroutine as we have displayed message
	goto __SKIP_MSG


__MSG_EATTHIS
	; Define playfield message:
	playfield:
	................................
	...XXX.XXX.XXX..XXX.X.X.X.XXX...
	...X...X.X..X....X..X.X.X.X.....
	...XX..XXX..X....X..XXX.X.XXX...
	...X...X.X..X....X..X.X.X...X...
	...XXX.X.X..X....X..X.X.X.XXX...
end	
	; Initialise the frame counter to animate the message display
	_msgAnim = 107
	
	; End the subroutine as we have displayed message
	goto __SKIP_MSG


__MSG_PERFECT
	; Define playfield message:
	playfield:
	................................
	...XXX.XXX.XXX.XXX.XXX.XXX.XXX..
	...X.X.X...X.X.X...X...X....X...
	...XXX.XX..XX..XX..XX..X....X...
	...X...X...X.X.X...X...X....X...
	...X...XXX.X.X.X...XXX.XXX..X...
end	
	; Initialise the frame counter to animate the message display
	_msgAnim = 107
	
	; End the subroutine as we have displayed message
	goto __SKIP_MSG


__MSG_YAKRULES
	; Define playfield message:
	playfield:
	................................
	X.X.XXX.X.X..XXX.X.X.X...XXX.XXX
	X.X.X.X.X.X..X.X.X.X.X...X...X..
	XXX.XXX.XX...XX..X.X.X...XX..XXX
	.X..X.X.X.X..X.X.X.X.X...X.....X
	.X..X.X.X.X..X.X.XXX.XXX.XXX.XXX
end	
	; Initialise the frame counter to animate the message display
	_msgAnim = 107
	
	; End the subroutine as we have displayed message
	goto __SKIP_MSG


__MSG_YOUBEAST
	; Define playfield message:
	playfield:
	................................
	X.X.XXX.X.X..XXX.XXX.XXX.XXX.XXX
	X.X.X.X.X.X..X.X.X...X.X.X....X.
	XXX.X.X.X.X..XX..XX..XXX.XXX..X.
	.X..X.X.X.X..X.X.X...X.X...X..X.
	.X..XXX.XXX..XXX.XXX.X.X.XXX..X.
end	
	; Initialise the frame counter to animate the message display
	_msgAnim = 107
	
	; End the subroutine as we have displayed message
	goto __SKIP_MSG


__MSG_MINTED
	; Define playfield message: EAT THIS
	playfield:
	................................
	...X...X.X.X..X.XXX.XXX.XX..X...
	...XX.XX.X.XX.X..X..X...X.X.X...
	...X.X.X.X.X.XX..X..XX..X.X.X...
	...X...X.X.X..X..X..X...X.X.....
	...X...X.X.X..X..X..XXX.XX..X...
end	
	; Initialise the frame counter to animate the message display
	_msgAnim = 107
	
	; End the subroutine as we have displayed message
	goto __SKIP_MSG




__SKIP_MSG

	; End subroutine
	return thisbank






;====== UPDATE LIVES COUNTER (subroutine) ============
__UPDATE_LIVES
	; Update the scorebar display to match the current number of player lives	
	if _lives = 4 then pfscore1 = %10101010
	if _lives = 3 then pfscore1 = %10101000
	if _lives = 2 then pfscore1 = %10100000
	if _lives = 1 then pfscore1 = %10000000
	if _lives = 0 then pfscore1 = %00000000

	; End subroutine
	return







;=============================
;====== DATA TABLES ===========
;=============================

	; Text messages animation steps (FracInc value to make them grow / shrink) - 108 frames
	data _msgAnimSteps
	0,5,12,18,23,27,30,32,33,34,33,
	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,
	32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,
	32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
end



;===========================================
;===== SOUND EFFECTS (CHANNEL 0 & 1) ==========
;===========================================

; CHANNEL 0 (firing SFX)
; Notes for all the sound effects (Volume, Control, Frequency)
	data _SFX0
	$e, $4, $07 ; SFX: SHOOT
	$e, $4, $0a
	$e, $4, $0c
	$f, $4, $09
	$e, $4, $0a
	$1, $4, $07
	$0, $4, $09
	255
end

; CHANNEL 1 (killing foes and getting hit by foes SFX)
; Notes for all the sound effects (Volume, Control, Frequency)
	data _SFX1
	$f, $7, $19 ; SFX: KILL_FOE
	$f, $7, $13
	$f, $6, $1a
	$f, $1, $1a
	$f, $7, $17
	$f, $c, $10
	$f, $7, $14
	$f, $7, $04
	$f, $7, $0e
	$f, $1, $1b
	$f, $1, $1b
	$f, $7, $1e
	$f, $7, $12
	$f, $6, $09
	$f, $f, $17
	$f, $6, $11
	$b, $7, $09
	$e, $7, $09
	$b, $f, $0b
	$c, $f, $0e
	$9, $7, $1a
	$9, $f, $13
	$b, $f, $14
	$7, $e, $0c
	$7, $7, $18
	$7, $7, $19
	$6, $f, $0b
	$7, $7, $1a
	$3, $7, $1a
	$3, $7, $1f
	$6, $6, $18
	$4, $6, $17
	$4, $6, $14
	$1, $7, $15
	255
	$2, $6, $00 ; SFX: HIT_PLAYER
	$1, $6, $00
	$9, $4, $0f
	$a, $6, $00
	$b, $c, $04
	$b, $4, $0f
	$9, $4, $12
	$b, $4, $0c
	$f, $4, $15
	$f, $4, $15
	$e, $c, $03
	$f, $4, $0c
	$f, $c, $0c
	$b, $4, $0d
	$7, $c, $04
	$5, $6, $00
	$4, $6, $00
	$3, $6, $00
	$2, $6, $00
	255
end

















;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++[ BANK 3 ]++++++++++++++++++++++++++++++++
;++ This bank contains the game title and game over screens code alongside the game over / dying audio playing routines and sound data
;++ And also some gameplay routine that weren't fitting on bank2
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	bank 3
	temp1=temp1




;====== BG COLOR ANIMATION (subroutine) ============
__BG_ANIM_COLOR

	; Set the right bg color according to its animation variable
	; This is a fade from red to black (default value) used to flash screen when hit
	; Anim Step 6
	if _bgAnim <> 6 then goto __SKIP_BG_ANIM_COLOR_6
	bkcolors:
	$38
end
__SKIP_BG_ANIM_COLOR_6
	; Anim Step 5
	if _bgAnim <> 5 then goto __SKIP_BG_ANIM_COLOR_5
	bkcolors:
	$36
end
__SKIP_BG_ANIM_COLOR_5
	; Anim Step 4
	if _bgAnim <> 4 then goto __SKIP_BG_ANIM_COLOR_4
	bkcolors:
	$34
end
__SKIP_BG_ANIM_COLOR_4
	; Anim Step 3
	if _bgAnim <> 3 then goto __SKIP_BG_ANIM_COLOR_3
	bkcolors:
	$32
end
__SKIP_BG_ANIM_COLOR_3
	; Anim Step 2
	if _bgAnim <> 2 then goto __SKIP_BG_ANIM_COLOR_2
	bkcolors:
	$30
end
__SKIP_BG_ANIM_COLOR_2
	; Anim Step 1
	if _bgAnim <> 1 then goto __SKIP_BG_ANIM_COLOR_1
	bkcolors:
	$00
end
__SKIP_BG_ANIM_COLOR_1

	; End subroutine
	return





;===========================================
;====== GAMEPLAY START / RESTART ============
;===========================================
__START
	
	; Clears all normal variables. Don't do it for Z, as it's not used in the code as we got enough variables left and was assigned to cycle counting during debugging phase
	; N.B.: We don't need to clear / reset the dimmed variables then, as we do it here for all the variables using their actual names (and not the dimmed ones)
	a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
	j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
	s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0
	; z = 0
	var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
	var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0
	
	; Clear the pause variable
	_isPaused = 0
		
	; Clear the "pressed" variable used to track menu keypresses too (and limit them)
	_pressed=0
	
	; Reset the ticks counters
	_ticks=0
	_ticks2=0
	_ticks3=0
	
	; Mute volume of both sound channels.
	AUDV0 = 0 
	AUDV1 = 0
	
	; Reset sound player pointers (note = 255 means muted)
	_sfx0note=255
	_sfx1note=255
	
	; Reset score and set its color and its font
	score = 0
	
	; Set score counter background color
	pfscorecolor = $00
	
	
	; Set score counter colors
	scorecolors:
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
end 

	; Set the starting number of player lives
	_lives = 3
	; Display lives at the left of the screen using pfscore bars
	const pfscore = 1
	pfscorecolor=$9A
	pfscore1 = %10101000
	pfscore2 = %00000000 ; set this one to "empty" as we won't use it


	; Init Player (the player position variables use the sprite coordinate directly, it's easier to dim them for code readability)
	_playerX=80
	_playerY=130
	_shotX=3
	_playerAnim=0
	
	; Init bullets
	_bulletDelay=1 ; Don't set it to 0 to prevent player from shooting immediatedly in case he held down the button from game over screen
	
	; Init Bullet 0 (missile0)
	missile0x=160
	missile0y=200
	_bullet0SpeedX=0
	
	; Init Bullet 1 (missile1)
	missile1x=160
	missile1y=200
	_bullet1SpeedX=0
	
	; Init foes
	_foeAnim=0
	
	; Reset all the foes positions
	player1x=0 : player1y = 200
	player2x=0 : player2y = 200
	player3x=0 : player3y = 200
	player4x=0 : player4y = 200
	player5x=0 : player5y = 200
	player6x=0 : player6y = 200
	player7x=0 : player7y = 200
	player8x=0 : player8y = 200
	player9x=0 : player9y = 200
	
	
	; Init ball used to draw the starfield
	; Init size (1x1)
	CTRLPF = $01
	; Set drawing start positions
	ballx=0
	bally=0
	; Define maximum height to define the height of the starfield (if more than that, there is a graphic glitch when scrolling just above the score counters)
	ballheight=177
	
	; Init text message (displayed using playfield)
	_msgAnim=0
	
	;Set Background color to default and reset its animation variable
	_bgAnim=0
	; Set colors to default value
	bkcolors:
	$00
end	

	
	; === GRAPHICS DATA ===
	
	; missile 0 size (2x2)
	NUSIZ0=$25
	missile0height=4
	COLUM0=$1C

	; missile 1 size (2x2)
	NUSIZ1=$20
	_NUSIZ1=$20
	missile1height=4
	COLUM1=$1C
	
	; Player (player0)
	player0:
	%01010000
	%01010000
	%01010000
	%01111000
	%01111000
	%11101110
	%11101110
	%11111111
	%11111111
	%11111100
	%11111100
	%11111110
	%11111110
	%01111000
	%01111000
	%01110000
	%01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
        %01110000
end

	; Set player colors
	player0color:
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
end

	; Foes (player1-9)
	player1-9:
	%00100000
	%00100000
        %00110000
        %00110000
        %00010011
        %00010011
        %00011110
        %00011110
        %01111000
        %01111000
        %11001000
        %11001000
        %00001100
        %00001100
        %00000100
        %00000100
end	

	; Set foes colors
	player1-9color:
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
	$0E
end

	player2color:
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
	$5E
end

	player3color:
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
	$BA
end

	player4color:
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
	$2A
end

	; Clear the playfield to erase any messages
	pfclear
	
	
	
	; Start the main game loop
	goto __MAIN bank2






;=============================
;====== GAME OVER ============
;=============================

__GAMEOVER
	; The game over state is divided in two phases : first the "dying" animation (girafe going down), that the player can't skip (needed to realize that you lost)
	; and then the "Game Over message" looping endlessly, where the player can restart the game by pressing the reset button

	; Start playing the "falling to death" sound, overriding any previously active sfx on channel 0 
	; NB: the SFX playing routine during game over block is different from the gameplay loop one, and uses notes from a different table located in bank3, like the Game Over routine itself
	_sfx0note=_SFX_falling
	; And mute the channel 1 as we won't use it for a while
	AUDV1 = 0
	_sfx1note=255
	
	; Cancel any previous message animation
	_msgAnim=0
	
	; Hides the missiles
	_bullet0SpeedX=0
	missile0y=200
	_bullet1SpeedX=0
	missile1y=200
	
	; Set a delay to wait before being able to press the restart button, that will also be used to track the death / game over animation frames
	_bulletDelay=120

	; Store the original player X position for the death animation (to make it flip horizontally nicely with the approriate X offset)
	_shotX = _playerX

	

	;-= GAME OVER LOOP =-	
__GAMEOVER_LOOP

	; Keep scrolling the playfield colors even if the stars are no longer moving, so it's still a bit "trippy" to watch the game :)
	if _ticks & 7 =  0 then pfscroll 1 4 4
	
	; Frame counter (0-239, so 4 seconds in total)
	_ticks=_ticks+1
	if _ticks > 239 then _ticks = 0
	
	; if we must animate the BG color (a fade), we do it now using a subroutine
	if _bgAnim > 0 then gosub __BG_ANIM_COLOR bank3 : _bgAnim = _bgAnim - 1

	;-= DEATH ANIMATION =-

	; If the player haven't reached the ground yet then make it go down faster and faster (oh, gravity)
	temp6=(120-_bulletDelay)/4
	if player0y < 177 then player0y = player0y + temp6 : player0height=200-_playerY
	
	; Flip the player every 4 frames (divide frame stepper by 8 and look if it's below or over the half)
	if (_bulletDelay&7) <=3 then REFP0=8 : _playerX=_shotX-6 else REFP0=0 : _playerX=_shotX
	
	; After the death, display the game over message using the message fade in / out animation system
	if _bulletDelay = 70 then _msgAnim = 33 : playfield:
	................................
	................................
	................................
	................................
	................................
	..XXX.XXX.X...X.XXX.............
	..X...X.X.XX.XX.X...............
	..X.X.XXX.X.X.X.XX..............
	..X.X.X.X.X...X.X...............
	..XXX.X.X.X...X.XXX.............
	................................
	................................
	................................
	...............XXX.X.X.XXX.XXX..
	...............X.X.X.X.X...X.X..
	...............X.X.X.X.XX..XX...
	...............X.X.X.X.X...X.X..
	...............XXX..X..XXX.X.X..
end	
	
	; Play the gameover message sound after a while too (on channel 1)
	if _bulletDelay = 50 then _sfx1note=_SFX_dead
	
	
	;-= RESTART =-

	; If the wait counter isn't over, we can't restart yet and must sit and watch the game over animation until the end! 
	if _bulletDelay <> 0 then goto __SKIP_RESTART_BUTTONS
	
	; RESTART GAME BY PRESSING BUTTON
	; If the button is pressed, unless it was already pressed, restart the game
	if joy0fire && !_pressed{0} then goto __START bank3
		
	; RESET SWITCH
	; Go back to title screen
	if switchreset then _pressed{6} = 1 : goto __TITLE bank3

	; Reset the button restrainer variables if needed
	if !joy0fire then _pressed{0} = 0

__SKIP_RESTART_BUTTONS

	; Decrease the second half of the wait counter delay if needed (to make player wait a bit before being able to restart)
	if _bulletDelay > 0 then _bulletDelay = _bulletDelay - 1
	
	; Restore NUSIZ0 so player sprite still look normal (double width)
	NUSIZ0=$25
	
	; Refresh playfield sizes variable (everyframe to have a stable playfield drawing)
	DF0FRACINC=_msgGameOverSteps[_msgAnim]
	DF1FRACINC=_msgGameOverSteps[_msgAnim]
	DF2FRACINC=_msgGameOverSteps[_msgAnim]
	DF3FRACINC=_msgGameOverSteps[_msgAnim]
	DF4FRACINC=128
	DF6FRACINC=0
		
	; Update screen graphics
	drawscreen
	
	; Animate the playfield message if needed (animation > 0)
	if _msgAnim > 1 then _msgAnim=_msgAnim-1
	
	; Continue playing the game over sound (using the dedicated SFX routine for game over)
	gosub __SFX_gameover
	
	; If we are done waiting (delay = 1), as it's our one before last waiting loop iteration, because we'll stay a 0 after that), we set up the restart menu options
	; Skip this section if we are not done waiting yet
	if _bulletDelay <> 1 then goto __SKIP_SETUP_GAMEOVER_MENU
	
	; Force the fire button as "pressed" to force player to release it to make a choice, it case it was held down for a the whole game over sequence
	_pressed{0} = 1
	
__SKIP_SETUP_GAMEOVER_MENU		

	; Go back to the endless game over loop
	 goto __GAMEOVER_LOOP	



;=============================
;====== DATA TABLES ===========
;=============================

	; Game Over message animation steps (FracInc value to make them grow / shrink) - 34 frames
	data _msgGameOverSteps
	0,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
end


;====== PLAY GAME OVER SFX (subroutine) ============
; This subroutine is solely used to play SFX during the game over state, from bank3 (hence the use of return thisbank!)
__SFX_gameover
	
	;-= PLAY SFX (CHANNEL 0 - for the dying sound) =-
	
	; If no sound is active on this channel, skip the whole section
	if _sfx0note = 255 then goto __SKIP_sfx0gameover
		
	; if the current sound is the last one of a sound effect (tone == 255), we mute the channel and end the sound playing (and skip the section)
	if _SFX0_gameover[_sfx0note] = 255 then _sfx0note = 255 : AUDV0 = 0 : goto __SKIP_sfx0gameover
   
	; Else, we simply set the current sound params !
	; There are stored in the data table in this order: Volume, Control, Frequency  (duration is always 1 frame per entry, so they are repeated if a note lasts several frames)
	
	; First get the params into temp variables
	; Frequency = _sfx0note
	; Control = _sfx0note+1
	temp5 = _sfx0note+1
	; Volume = _sfx0note+2 
	temp4 = _sfx0note+2
	
	; Then apply the sound params to the registers to play sound!
	; We do these in this order and without any other instructions between them so the sound isn't distorted (slowed down, etc.)
	AUDV0 = _SFX0_gameover[_sfx0note]
	AUDC0 = _SFX0_gameover[temp5] 
	AUDF0 = _SFX0_gameover[temp4] 
	
	; And then, move pointer to the next note
	_sfx0note = _sfx0note+3

__SKIP_sfx0gameover


	;-= PLAY SFX (CHANNEL 1 - for the game over message sound) =-
	
	; If no sound is active on this channel, skip the whole section
	if _sfx1note = 255 then goto __SKIP_sfx1gameover
		
	; if the current sound is the last one of a sound effect (tone == 255), we mute the channel and end the sound playing (and skip the section)
	if _SFX1_gameover[_sfx1note] = 255 then _sfx1note = 255 : AUDV1 = 0 : goto __SKIP_sfx1gameover
   
	; Else, we simply set the current sound params !
	; There are stored in the data table in this order: Volume, Control, Frequency (duration is always 1 frame per entry, so they are repeated if a note lasts several frames)
	
	; First get the params into temp variables
	; Frequency = _sfx1note
	; Control = _sfx1note+1
	temp5 = _sfx1note+1
	; Volume = _sfx1note+2 
	temp4 = _sfx1note+2
	
	; Then apply the sound params to the registers to play sound!
	; We do these in this order and without any other instructions between them so the sound isn't distorted (slowed down, etc.)
	AUDV1 = _SFX1_gameover[_sfx1note]
	AUDC1 = _SFX1_gameover[temp5]
	AUDF1 = _SFX1_gameover[temp4]
	
	; And then, move pointer to the next note
	_sfx1note = _sfx1note+3
	
__SKIP_sfx1gameover

	; End subroutine
	return thisbank


;===========================================
;====== SOUND EFFECTS (CHANNEL 0) ============
;===========================================

	; Notes for the Game Over falling to death sound effect (Volume, Control, Frequency)
	data _SFX0_gameover
	$0, $4, $0f ; SFX: FALLING
	$3, $c, $03
	$4, $4, $0c
	$b, $4, $0c
	$b, $4, $0c
	$a, $4, $0d
	$f, $4, $0d
	$f, $c, $04
	$f, $c, $04
	$a, $c, $04
	$f, $6, $00
	$b, $4, $0f
	$8, $4, $10
	$c, $6, $00
	$f, $c, $04
	$d, $c, $04
	$8, $4, $0d
	$c, $c, $04
	$b, $c, $05
	$7, $c, $05
	$6, $c, $06
	$c, $4, $12
	$f, $4, $12
	$f, $4, $12
	$f, $4, $10
	$f, $4, $10
	$9, $4, $10
	$7, $4, $13
	$7, $4, $13
	$b, $4, $15
	$f, $c, $06
	$f, $4, $13
	$f, $4, $13
	$8, $4, $12
	$c, $c, $05
	$7, $c, $05
	$6, $4, $16
	$5, $4, $16
	$2, $c, $07
	$5, $c, $07
	$8, $4, $15
	$f, $4, $15
	$b, $4, $15
	$7, $4, $13
	$6, $4, $16
	$4, $4, $16
	$6, $4, $18
	$5, $4, $19
	$2, $4, $1b
	$1, $4, $18
	$2, $4, $16
	$6, $4, $16
	$1, $c, $06
	$5, $4, $16
	$1, $4, $16
	$1, $4, $1c
	255
end


	; Notes for the Game Over message sound effect (Volume, Control, Frequency)
	data _SFX1_gameover
	$a, $6, $18 ; SFX: GAME OVER
	$a, $6, $18
	$a, $6, $18
	$a, $6, $18
	$a, $6, $18
	$a, $6, $18
	$a, $6, $18
	$a, $6, $18
	$a, $6, $18
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$a, $6, $08
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $18
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$5, $6, $08
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$0, $0, $01
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $18
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	$2, $6, $08
	255
end




;=============================
;====== TITLE SCREEN ==========
;=============================
__TITLE
	; Set up the menu screen (we land here directly if we hit the reset switch on the console from the game)
	
	; Mute volume of both sound channels.
	AUDV0 = 0 
	AUDV1 = 0
	
	; Reset sound player pointers (note = 255 means muted)
	_sfx0note=255
	_sfx1note=255
	
	; Reset score and set its color and its font
	score = 0
	
	; Set score counter background color
	pfscorecolor = $00
	
	; Set score counter colors to black to hide it on the title screen
	scorecolors:
	$00
	$00
	$00
	$00
	$00
	$00
	$00
	$00
end 
	
	; Hide player sprites and missiles
	player0y=200 : player0height=10 ; reduce playerheight so it doesn't wrap it back on top of the screen, as it's 176 pixels tall
	player1y=200
	player2y=200
	player3y=200
	player4y=200
	player5y=200
	player6y=200
	player7y=200
	player8y=200
	player9y=200
	missile0y=200
	missile1y=200
	
	; Init ball used to draw the starfield
	; Init size (1x1)
	CTRLPF = $01
	; Set drawing start positions
	ballx=0
	bally=0
	; Define maximum height to define the height of the starfield (if more than that, there is a graphic glitch when scrolling just above the score counters)
	ballheight=177
	
	; Set colors to default value
	bkcolors:
	$00
end	

	; Initialize the Playfield (set size, resolution, and clear it entirely)
	
	; Define the playfield
	playfield:
	................................
	................................
	................................
	.XX.XXX..X..XX...XX.X.XX...X...X
	XXX.XXX.XXX.XXX.XXX.X.XXX.XXX.XX
	XXX.XXX.XXX.XXX.XXX.X.XXX.XXX.XX
	XXX.XXX.XXX.XXX.XXX.X.XXX.XXX.XX
	X....X..X.X.X.X.X...X.X.X.X.X.X.
	X....X..X.X.X.X.X...X.X.X.X.X.X.
	X....X..X.X.X.X.X...X.X.X.X.X.X.
	X....X..X.X.X.X.X...X.X.X.X.X.X.
	X....X..X.X.X.X.X...X.X.X.X.X.X.
	XXX..X..XXX.XX..X...X.XX..XXX.XX
	XXX..X..XXX.XX..X...X.XX..XXX.XX
	..X..X..X.X.X.X.X.X.X.X.X.X.X.X.
	..X..X..X.X.X.X.X.X.X.X.X.X.X.X.
	..X..X..X.X.X.X.X.X.X.X.X.X.X.X.
	..X..X..X.X.X.X.X.X.X.X.X.X.X.X.
	..X..X..X.X.X.X.X.X.X.X.X.X.X.X.
	XXX..X..X.X.X.X.XXX.X.X.X.X.X.X.
	XXX..X..X.X.X.X.XXX.X.X.X.X.X.X.
	XXX..X..X.X.X.X.XXX.X.X.X.X.X.X.
	XXX..X..X.X.X.X.XXX.X.X.X.X.X.X.
	XX...X..X.X.X.X..XX.X.X.X.X.X.X.
	................................
	................................
	................................
	................................
	................................
	................................
	.X...XX...XX.XX...XX..XX..XX.XXX
	X.X..X.X.X...X.X.X...X...X....X.
	XXX..XX..XX..XX..XX..XX..X....X.
	X.X..X...X...X.X.X...X...X....X.
	X.X..X....XX.X.X.X....XX..XX..X.
	................................
	.......XX...XX..X...XX.XXX......
	.......X.X.X...X.X.X....X.......
	.......XX..XX..XXX.XXX..X.......
	.......X.X.X...X.X...X..X.......
	.......XX...XX.X.X.XX...X.......
	................................
	.XX..X..XX....XX.XX...X...XX..XX
	X...X.X.X.X..X...X.X.X.X.X...X..
	XX..X.X.XX...XXX.XX..XXX.X...XX.
	X...X.X.X.X....X.X...X.X.X...X..
	X....X..X.X..XX..X...X.X..XX..XX
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	................................
	..XX..XX....X...X.X.XX...X...XX.
	..X.X.X.X...X...X.X.X.X.X.X.X...
	..X.X.XX....X...X.X.X.X.X.X.XXX.
	..X.X.X.X...X...X.X.X.X.X.X...X.
	..XX..X.X.X.XXX..X..XX...X..XX..
end

	; Define the playfield colors (a 256 color gradient, as it'll scroll endlessly)
	pfcolors:
	$0E
	$0E
	$0C
	$0C
	$0A
	$0A
	$08
	$08
	$06
	$06
	$1E
	$1E
	$1C
	$1C
	$1A
	$1A
	$18
	$18
	$16
	$16
	$2E
	$2E
	$2C
	$2C
	$2A
	$2A
	$28
	$28
	$26
	$26
	$3E
	$3E
	$3C
	$3C
	$3A
	$3A
	$38
	$38
	$36
	$36
	$4E
	$4E
	$4C
	$4C
	$4A
	$4A
	$48
	$48
	$46
	$46
	$5E
	$5E
	$5C
	$5C
	$5A
	$5A
	$58
	$58
	$56
	$56
	$6E
	$6E
	$6C
	$6C
	$6A
	$6A
	$68
	$68
	$66
	$66
	$7E
	$7E
	$7C
	$7C
	$7A
	$7A
	$78
	$78
	$76
	$76
	$9E
	$9E
	$9C
	$9C
	$9A
	$9A
	$98
	$98
	$96
	$96
	$AE
	$AE
	$AC
	$AC
	$AA
	$AA
	$A8
	$A8
	$A6
	$A6
	$BE
	$BE
	$BC
	$BC
	$BA
	$BA
	$B8
	$B8
	$B6
	$B6
	$CE
	$CE
	$CC
	$CC
	$CA
	$CA
	$C8
	$C8
	$C6
	$C6
	$DE
	$DE
	$DC
	$DC
	$DA
	$DA
	$D8
	$D8
	$D6
	$D6
	$EE
	$EE
	$EC
	$EC
	$EA
	$EA
	$E8
	$E8
	$E6
	$E6
	$3E
	$3E
	$3C
	$3C
	$3A
	$3A
	$38
	$38
	$36
	$36
	$4E
	$4E
	$4C
	$4C
	$4A
	$4A
	$48
	$48
	$46
	$46
	$5E
	$5E
	$5C
	$5C
	$5A
	$5A
	$58
	$58
	$56
	$56
	$6E
	$6E
	$6C
	$6C
	$6A
	$6A
	$68
	$68
	$66
	$66
	$0E
	$0E
	$0C
	$0C
	$0A
	$0A
	$08
	$08
	$06
	$06
	$1E
	$1E
	$1C
	$1C
	$1A
	$1A
	$18
	$18
	$16
	$16
	$2E
	$2E
	$2C
	$2C
	$2A
	$2A
	$28
	$28
	$26
	$26
	$3E
	$3E
	$3C
	$3C
	$3A
	$3A
	$38
	$38
	$36
	$36
	$4E
	$4E
	$4C
	$4C
	$4A
	$4A
	$48
	$48
	$46
	$46
	$5E
	$5E
	$5C
	$5C
	$5A
	$5A
	$58
	$58
	$56
	$56
	$6E
	$6E
	$6C
	$6C
	$6A
	$6A
	$68
	$68
	$66
	$66
	$7E
	$7E
	$7C
	$7C
	$7A
end

	;Defining a base playfield color seems to patch the "hole" missing in the pfcolor (255 entry defined, but 256 needed for a smooth scrolling wrap!)
	;So I simply used the last entry of the list, that should appear twice but only once could be entered
	COLUPF = $7A

	; Use Player0 and 1 to display a "push fire !" blinking message
	; left part
	player0:
        %11101010
        %11101010
	%10101010
	%10101010
	%11101010
	%11101010
	%10001010
	%10001010
	%10001110
	%10001110
	%00000000
	%00000000
	%11101011
	%11101011
	%10001010
	%10001010
	%11101011
	%11101011
	%10001010
	%10001010
	%10001010       
	%10001010       
end	
	; right part
	player1:
	%11101010
	%11101010
	%10001010
	%10001010
	%11101110
	%11101110
	%00101010
	%00101010
	%11101010
	%11101010
        %00000000	
        %00000000	
	%00111010
	%00111010
	%10100010
	%10100010
	%00111010
	%00111010
	%10100000
	%10100000
	%10111010
	%10111010
end

	; Position them on screen on X axis (but hide them in Y for now)
	player0x=63
	player0y=200
	player1x=79
	player1y=200
	
	; Set player colors too
	player0color:
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
end	

	player1color:
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
	$1E
end

	; Reset ticks counter (used for animations on this title screen)
	;_ticks=0 
	_ticks=224

	; Set up a title fade animation on beginning on the game
	_msgAnim=33
	
	; Title screen loop
__TITLE_LOOP

	; Keep scrolls the playfield colors even if the stars are no longer moving, so it's still a bit "trippy"
	if _ticks & 7 =  0 then pfscroll 1 4 4
	
	; Frame counter (0-239, so 4 seconds in total)
	_ticks=_ticks+1
	if _ticks > 239 then _ticks = 0
	
	; Restore players double size (as they are used to display starting message)
	NUSIZ0 = $05
	_NUSIZ1 = $05
	
	; Make the "push fire" message blink every 16 frames (divide frame stepper by 32 and look if it's below or over the half) to put it onscreen or offscreen
	if (_ticks&31) < 16 then player0y=200 : player1y=200 else player0y=120 : player1y=120
	
	; Set playfield size (22 rows that are 8 scanlines high, so a 32x32 screen resolution for playfield)
	; Refresh playfield sizes variable (everyframe to have a stable playfield drawing)
	DF0FRACINC=_msgTitleSteps[_msgAnim]
	DF1FRACINC=_msgTitleSteps[_msgAnim]
	DF2FRACINC=_msgTitleSteps[_msgAnim]
	DF3FRACINC=_msgTitleSteps[_msgAnim]
	DF4FRACINC=128
	DF6FRACINC=0

	; Update screen graphics and sound playing
	drawscreen
	
	; Animate the playfield message if needed (animation > 0), and reset ticks counter to prevent the "push fire" message to appear
	if _msgAnim > 1 then _msgAnim=_msgAnim-1 : _ticks=0
	
	; Go to the menu if the button is pressed, unless it was already pressed
	if joy0fire && !_pressed{0} then _pressed{0}=1 : goto __START
	
	; Reset the game back to title screen
	if switchreset && !_pressed{6} then _pressed{6} = 1 : goto __TITLE
	
	; Release unpressed buttons
	if !joy0fire then _pressed{0} = 0
	if !joy0left then _pressed{1} = 0
	if !joy0right then _pressed{2} = 0
	if !joy0up then _pressed{3} = 0
	if !joy0down then _pressed{4} = 0
	if !switchselect then _pressed{5} = 0
	if !switchreset then _pressed{6} = 0
	
	; Endless title screen loop
	goto __TITLE_LOOP


;=============================
;====== DATA TABLES ===========
;=============================

	; Title message animation steps (FracInc value to make them grow / shrink) - 34 frames
	data _msgTitleSteps
	0,128,124,120,116,112,108,104,100,96,92,88,84,80,76,72,68,64,60,56,52,48,44,40,36,32,28,24,20,16,12,8,4,0
end


 ;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++[ BANK 4 ]++++++++++++++++++++++++++++++++
;++ This bank contains 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	bank 4
	temp1=temp1

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++[ BANK 5 ]++++++++++++++++++++++++++++++++
;++ This bank contains 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	bank 5
	temp1=temp1


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++[ BANK 6 ]++++++++++++++++++++++++++++++++
;++ This bank contains 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	bank 6
	temp1=temp1