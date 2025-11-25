# Nebulords Development Status Summary

## Current Status - Nebulords Main Game

**Latest Version**: v094 (in versions/ folder)

**Optimization from v079B → v094**:
- ✅ **~180 lines of code removed** via shared physics functions
- ✅ **Refactored physics**: Single thrust/acceleration/movement functions (not duplicated per player)
- ✅ **Load/Store context functions** for player physics state
- ✅ **Temp variables** for shared physics processing
- **Result**: Much better positioned to avoid page boundary issues when adding 4-player support

**Current Player Support**: 2 players only
- Player 1: Paddle0 + joy0right (thrust button)
- Player 2: Paddle1 + joy0left (thrust button)

**Working Features**:
- ✅ Warlords-style space combat gameplay
- ✅ Paddle controls with 16-position rotation (17 divisions)
- ✅ Ball catching and launching mechanics
- ✅ Auto-launch after 4 seconds (240 frames)
- ✅ 4-brick destruction system per player (top, left, right, bottom)
- ✅ Core hitbox detection (player dies when core struck)
- ✅ Ship-to-ship collision with bounce physics
- ✅ Round-based gameplay with 3-second invincibility after round win
- ✅ Built-in PXE score display (BCD format, 6 digits)
  - Format: score+2 (P1) | score+1 (separator) | score+0 (P2)
  - BCD math: Each byte holds 00-99 ($00-$99 hex)
- ✅ Gradient sprite colors (blue P1, purple P2)
- ✅ Gradient score colors
- ✅ Physics system (8 speed steps, acceleration, momentum)
- ✅ Rectangular hitboxes (18×28 pixels, force field effect)

**Sprite Usage**:
- player0: P1 ship
- player1: P2 ship
- player2: P1 paddle (gradient color $98-$96 blue)
- player3: P2 paddle (gradient color $78-$76 purple)
- Additional sprites: Ball and brick states

---

## Current Status - Score Test Files

**Purpose**: Testing 4-player score display system before merging into main game

### test_4player_score_v3.bas (User's version on main branch)
- Working score display: `_0000_` format (blanks on outer digits)
- Dash indicator (player1 sprite) visible at Y=174 under scores
- Dash positions: X=64, 72, 80, 88 for 4 score digits
- **Colors**: Original colors ($46, $86, $26, $C6)

### test_4player_score_v4.bas (Latest with color fixes)
- Same functionality as v3
- **Colors corrected** to match Nebulords palette:
  - P1 (UP): $96 - bright blue (was $46 red/orange)
  - P2 (DOWN): $76 - purple (was $86 blue/purple mix)
  - P3 (LEFT): $26 - orange ✓
  - P4 (RIGHT): $C6 - green ✓

**Score System Details**:
```basic
const pfscore = 1
const font = retroputer
dim score_byte0 = score+2  ; Rightmost 2 digits
dim score_byte1 = score+1  ; Middle 2 digits
dim score_byte2 = score     ; Leftmost 2 digits
```

**Display Format**: `_0000_`
- Outer blanks: Space character ($A or decimal 10 in retroputer font)
- score_byte2 = $A0 → " 0"
- score_byte1 = $00 → "00"
- score_byte0 = $0A → "0 "

**Dash Indicator**:
- player1 sprite (2 pixels tall horizontal line)
- Y position: 174 (under score area)
- Dynamically changes X position and color via COLUP1
- Shows which player's score is active

**Controls** (joystick test mode):
- UP: Increment P1 score (low nibble of score_byte2)
- DOWN: Increment P2 score (high nibble of score_byte1)
- LEFT: Increment P3 score (low nibble of score_byte1)
- RIGHT: Increment P4 score (high nibble of score_byte0)
- Fire button: Forces joystick mode (required for directions to work)

---

## Known Issues & Blockers

### 1. 4-Player Paddle Support in PXE ⚠️ **BLOCKER**
**Status**: Awaiting community response on Atari Age forum

**Problem**:
- PXE kernel only exposes Paddle0 and Paddle1 variables
- Paddle2 and Paddle3 don't exist in PXE (Unknown Mnemonic errors)
- COLUP2 and COLUP3 don't exist in PXE
- `currentpaddle` method doesn't work in PXE (works in standard kernel only)

**Testing Done**:
- Direct access to Paddle2/Paddle3 variables: ❌ Failed
- currentpaddle cycling method: ❌ Failed (PXE doesn't support)
- Only Paddle0/Paddle1 confirmed working

**Question for Atari Age**:
- Does PXE support 4 paddle inputs?
- If yes, how to enable/access Paddle2 and Paddle3?
- If no, will this be added in a future PXE update?

### 2. Page Boundary Issues ⚠️ **CRITICAL**

**Background**:
- 6502 CPU groups memory into 256-byte pages
- Crossing page boundaries adds extra CPU cycle
- Display kernels require constant timing (can't tolerate extra cycles)
- Memory tables that span page boundaries cause timing issues

**Impact on Nebulords**:
- Encountered page boundary errors when attempting 4-player code in previous sessions
- Main loop is getting large and may cross boundaries
- Adding more features increases risk of boundary violations

---

## Still To Add

### Essential Features
1. **4-Player Support** (blocked - see above)
   - Need 4 paddle inputs working
   - Need 4 score tracking
   - Need 4 ship sprites with unique colors
   - Need 4 paddle sprites with unique colors

2. **Sound Effects**
   - Ball bounce (paddle, brick, wall)
   - Brick destruction
   - Core hit / player death
   - Round win

3. **Title Screen**
   - Game logo
   - Player selection (2P vs 4P mode?)
   - Start game prompt

4. **Multiple Levels**
   - Different playfield layouts?
   - Difficulty progression
   - Level transitions

### Score Integration (Future)
- Merge 4-player score display from test files into main game
- Replace current 2-player score system
- Add dash indicator for active player
- **Note**: Score updates don't happen every frame, could be moved out of main loop

---

## Technical Considerations

### Page Boundary Strategy

**Problem**: Main loop growing too large, risk of crossing 256-byte page boundaries

**Solutions to Consider**:

1. **Move infrequent code out of main loop**
   - Score updates (only on point scored, not every frame)
   - Round reset logic (only at round end)
   - Player death handling (rare event)
   - Sound triggers (event-based, not continuous)

2. **Use subroutines for large blocks**
   - Break complex logic into separate routines
   - Call only when needed (gosub/return)
   - Keeps main loop lean

3. **Careful variable placement**
   - Group related variables together
   - Use `dim` to alias score bytes properly
   - Minimize zero-page variable usage

4. **Code organization**
   - Keep time-critical code tight and sequential
   - Separate initialization from main loop
   - Use labels and sections for clarity

### Main Loop Current Structure (v094)
```
__Main_Loop:
  1. Ball collision checks (with paddles, bricks, core)
  2. Ball movement (16-position orbital system)
  3. Ship movement (paddle input, physics, bounds)
  4. Ship-to-ship collision
  5. Sprite updates
  6. drawscreen
  7. goto __Main_Loop
```

**What Could Move Out**:
- Score increment (call __Award_P1_Point / __Award_P2_Point only when needed)
- Round reset (call __Round_Reset only on death)
- Brick state changes (only on collision)
- Invincibility timer checks (only when active)

---

## Next Steps

### Immediate
1. ⏳ Wait for Atari Age response on 4-paddle support in PXE
2. Test v4 score display with corrected colors
3. Document which code sections can be moved out of main loop

### When 4-Paddle Support Confirmed
1. Update test file to use all 4 paddles instead of joystick
2. Test 4-paddle input with score increments
3. Begin planning 4-player Nebulords integration

### Before Score Integration
1. Refactor main loop to minimize page boundary risk
2. Move score updates to subroutines (not inline)
3. Profile code size and identify boundary crossings
4. Test with 4-player code to ensure no boundary violations

### Long Term
1. Add sound effects (after main gameplay solid)
2. Create title screen
3. Design multiple levels/difficulty modes
4. Polish and optimize

---

## Key Files

- `versions/nebulordsPXE_v094.bas` - Latest working 2-player game (optimized from v079B)
- `test_4player_score_v3.bas` - User's score test (original colors)
- `test_4player_score_v4.bas` - Score test with corrected Nebulords colors
- `8_Way Scrolling_Rev_B.bas` - Reference for PXE features
- `Playfield_Indexing.bas` - Reference for score display

---

## Questions/Decisions Needed

1. **2-player vs 4-player mode toggle?**
   - Or always 4-player with AI for empty slots?
   - Title screen selection?

2. **Score format for 4 players?**
   - Current test uses 1 digit per player (0-9)
   - Nebulords v079B uses 2 digits per player (00-99)
   - Trade-off: Digits vs screen space

3. **Sound priority?**
   - Which effects are most critical?
   - Can sound coexist with complex gameplay without timing issues?

4. **Page boundary tools?**
   - Does batari Basic have tools to check boundary crossings?
   - Can we force alignment of critical sections?

---

**Session End Date**: 2025-11-25
**Branch**: claude/adjust-ball-positions-01RJCViBHwAFhs5ZWxELWj21
