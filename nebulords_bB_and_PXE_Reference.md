# Nebulords batari Basic & PXE Kernel Reference

**Purpose:** This document contains critical information about batari Basic syntax, PXE kernel quirks, and patterns specific to the Nebulords project. Read this at the start of any session to avoid repeating mistakes.

---

## Table of Contents
1. [batari Basic Critical Syntax Rules](#batari-basic-critical-syntax-rules)
2. [PXE Kernel Specifics](#pxe-kernel-specifics)
3. [PXE Virtual Sprite Coordinate Offset Bug](#pxe-virtual-sprite-coordinate-offset-bug)
4. [Working Patterns from v051](#working-patterns-from-v051)
5. [Common Mistakes - NEVER REPEAT](#common-mistakes---never-repeat)
6. [Best Practices for Nebulords](#best-practices-for-nebulords)

---

## batari Basic Critical Syntax Rules

### Control Flow
```basic
; Single statement if-then
if condition then statement

; Jump to label
if condition then goto label

; Jump table (0-indexed)
on variable goto label1 label2 label3

; Subroutine call (MAX 3 nested levels - only 6 bytes stack!)
gosub label
return

; NEVER do this - causes issues:
if condition then gosub label : other_statement
```

### Labels and Indentation
- Labels must **NOT** be indented
- All statements **MUST** be indented
- Convention in this codebase: `__Label_Name` (double underscore)

### Variables
- Only **26 variables available: a-z**
- `dim name = letter` - Create readable alias
- Can alias same memory: `dim p1_xpos = player0x.a`
- **Bit access:** `variable{bit}` (e.g., `p1_state{0}` for bit 0)
- All variables are **unsigned 8-bit (0-255)**
- Negative values: 255 = -1, 254 = -2, 253 = -3, etc. (two's complement)

### PXE Extra Variables
- `var0` through `var75` - **76 extra variables** available in PXE kernel
- Critical for complex games like Nebulords
- Example: `dim p1_bricks = var0`

### Stack Limitations
- **Only 6 bytes of stack space** for gosub calls
- Each gosub uses 2 bytes
- **Maximum 3 nested gosub calls allowed**
- Exceeding this will cause crashes

---

## PXE Kernel Specifics

### Sprite System

#### Hardware Sprites (Support collision())
- `player0, player1` - Hardware sprites
- `missile0, missile1` - Hardware missiles
- `ball` - Hardware ball
- **ONLY these support the `collision()` function!**

#### Virtual Sprites (NO collision() support!)
- `player2` through `player16` - Virtual sprites (software-rendered)
- Repositioned copies of player1 sprite
- **CANNOT use collision() - will cause compilation errors!**
- Must use coordinate-based bounding box collision detection

### NUSIZ (Sprite Sizing and Configuration)
```basic
; Hardware sprites
NUSIZ0      ; player0 configuration
_NUSIZ1     ; player1 configuration (note underscore!)

; Virtual sprites
NUSIZ2-NUSIZ16  ; player2-16 configuration

; Common values:
$00  ; Normal single sprite
$05  ; Double width
$07  ; Quad width
$40  ; Enable horizontal masking (prevents wrap-around)
$41  ; 2 copies close + masking
$42  ; 2 copies medium + masking
$43  ; 3 copies close + masking

; Bit 3 = reflection (flip horizontally)
; Bit 6 = PXE masking (prevents edge wrap)
```

### Collision Detection

#### Hardware Collision
```basic
; Works with hardware sprites only
if collision(ball, player0) then gosub __P1_Hit
if collision(ball, missile0) then gosub __Paddle_Hit
if collision(player0, player1) then gosub __Ship_Collision
```

#### Coordinate-Based Collision (Virtual Sprites)
```basic
; Ball: 2x4 pixels, Paddle: 6x9 pixels
; Bounding box overlap check:
if ballx < player2x + 6 && ballx + 2 > player2x then
  if bally < player2y + 9 && bally + 4 > player2y then
    gosub __Check_P1_Paddle
```

**Formula:**
```
if obj1_x < obj2_x + obj2_width && obj1_x + obj1_width > obj2_x then
  if obj1_y < obj2_y + obj2_height && obj1_y + obj1_height > obj2_y then
    ; Collision detected
```

---

## PXE Virtual Sprite Coordinate Offset Bug

**OBSERVED BUG:** In Nebulords, `player3` renders **2 pixels to the LEFT** of where its X coordinate indicates. It's unclear if this affects other virtual sprites.

### What We Know
- `player2` (P1 paddle) - renders at exact coordinate ✓
- `player3` (P2 paddle) - renders 2 pixels LEFT of coordinate ✗
- Both are virtual sprites with identical positioning code
- Both use same sprite graphics and offsets from parent ships

### Evidence from Nebulords
In v038, player 2's paddle (player3) had "ghost collisions" - the ball was hitting the paddle 2 pixels to the left of where it visually appeared.

**P1 paddle (player2) hitbox:**
```basic
; v038-v041: Works correctly at exact coordinate
if ballx < player2x + 6 && ballx + 2 > player2x
```

**P2 paddle (player3) hitbox:**
```basic
; v038 (BROKEN): Ghost collisions 2px to the left of visual sprite
if ballx < player3x + 6 && ballx + 2 > player3x

; v039+ (FIXED): Shift hitbox +2px right to match visual position
if ballx < player3x + 8 && ballx + 2 > player3x + 2
```

### Workaround Applied
When using `player3` specifically:
1. **Visual positioning:** Use coordinate as-is (sprite renders 2px left)
2. **Collision detection:** Add +2 to X coordinate bounds to compensate

```basic
; player3 collision with +2 offset applied to both bounds
hitbox_left = player3x + 2
hitbox_right = player3x + width + 2
```

### Unknown - Needs Testing
- Does this affect player5, player7, player9, etc.?
- Is it ALL odd virtual sprites or just player3?
- Is it always exactly 2 pixels?
- Does it affect Y coordinates?
- Do player4, player6, player8, etc. work correctly like player2?

**Test file created:** `/home/user/Nebulords/sprite_offset_test.bas` - displays all 17 sprites + ball + missiles at same X coordinate to empirically determine offset pattern.

---

## Working Patterns from v051

### Ball Speed System
```basic
; Fast launch (2 px/frame)
__P1_Launch_Ball
  ball_state = 0  ; Detach from player
  temp1 = p1_paddle_dir
  gosub __Set_Ball_Direction_Fast
  ball_speed_timer = FAST_BALL_DURATION  ; 240 frames = 4 seconds
  return

; Slow down when timer expires
if ball_speed_timer > 0 then ball_speed_timer = ball_speed_timer - 1
if ball_speed_timer = 1 then gosub __Slow_Ball_Down

__Slow_Ball_Down
  ; Reduce each velocity component by half
  if ball_xvel > 128 then ball_xvel = 255 : goto __SBD_Y  ; Was negative, make -1
  if ball_xvel > 0 then ball_xvel = 1  ; Was positive, make 1
__SBD_Y
  if ball_yvel > 128 then ball_yvel = 255 : goto __SBD_Done
  if ball_yvel > 0 then ball_yvel = 1
__SBD_Done
  ball_speed_timer = 0
  return
```

### Paddle Deflection (Correct Pattern)
```basic
__Ball_Hit_P1_Paddle
  ; CATCH if button held AND not in cooldown
  if p1_state{0} && !p1_state{1} then ball_state = 1 : p1_timer = 0 : return

  ; BOUNCE - set velocity based on paddle direction
  temp1 = p1_paddle_dir
  on temp1 goto __P1B_N __P1B_NE __P1B_E __P1B_SE __P1B_S __P1B_SW __P1B_W __P1B_NW

__P1B_N
  ball_xvel = 0 : ball_yvel = 254 : goto __P1B_Done
__P1B_NE
  ball_xvel = 2 : ball_yvel = 254 : goto __P1B_Done
; ... (other directions)

__P1B_Done
  ; Preserve launch speed - only boost if not already fast
  if ball_speed_timer = 0 then ball_speed_timer = BOUNCE_BOOST_DURATION
  return
```

**CRITICAL:** When deflecting, check `ball_speed_timer` to maintain current speed:
```basic
; In Nebulords PXE (v041 pattern):
__Ball_Bounce_P1
  if p1_state{0} && !p1_state{1} then ball_state = 1 : return

  ; Use fast or slow velocity table based on timer
  if ball_speed_timer > 0 then gosub __Set_Ball_Velocity : return
  gosub __Set_Ball_Velocity_Slow
  return
```

### Auto-Launch Pattern (CRITICAL!)

**v051 (8-direction) correct pattern:**
```basic
; Increment timer ONLY when ball attached
if ball_state{0} then hold_frames = hold_frames + 1

; Every 30 frames = 0.5 seconds
if hold_frames >= 30 then hold_frames = 0 : p1_timer = p1_timer + 1

; Auto-launch after 10 half-seconds (5 seconds)
; MUST check ball_state AND cooldown
if p1_timer >= 10 && !p1_state{1} then gosub __P1_Auto_Launch

__P1_Auto_Launch
  gosub __P1_Launch_Ball
  p1_timer = 180  ; 3 second penalty cooldown
  return
```

**Nebulords PXE (16-direction) pattern:**
```basic
; Timer increments every frame while ball attached
if ball_state = 1 then p1_catch_timer = p1_catch_timer + 1

; Auto-launch check MUST include ball_state
if ball_state = 1 && p1_catch_timer >= auto_launch_time then gosub __P1_Auto_Launch

; Cooldown timer decrements
if p1_state{1} then p1_catch_timer = p1_catch_timer - 1
if p1_catch_timer = 0 then p1_state{1} = 0
```

### Direction System

**v051 (8 directions):**
- 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SW, 6=W, 7=NW

**Nebulords PXE (16 directions):**
- 0=South (bottom of dial), rotates counter-clockwise
- 4=West, 8=North, 12=East
- Provides finer control for paddle aiming

### Direction Rotation for Velocity Tables
```basic
; Game uses direction 0-15 where 0=South
; Velocity tables expect 0=North
; Rotate by 8 positions to convert:
temp_dir = (temp_dir + 8) & 15
on temp_dir goto __BV_0 __BV_1 ... __BV_15
```

**CRITICAL:** Only rotate ONCE! If you rotate in the bounce handler AND in the velocity setter, you'll get the opposite direction (double rotation bug).

---

## Common Mistakes - NEVER REPEAT

### ❌ Mistake 1: Using collision() with Virtual Sprites
```basic
; WRONG - Will not compile!
if collision(ball, player2) then gosub __Check_P1_Paddle
```

**Fix:** Use coordinate-based detection:
```basic
; CORRECT
if ballx < player2x + 6 && ballx + 2 > player2x then
  if bally < player2y + 9 && bally + 4 > player2y then
    gosub __Check_P1_Paddle
```

### ❌ Mistake 2: Missing ball_state Check in Auto-Launch
```basic
; WRONG - Causes ball to follow paddle after auto-launch!
if p1_catch_timer >= auto_launch_time then gosub __P1_Auto_Launch
```

**Why this breaks:**
1. After auto-launch: ball_state = 0, p1_catch_timer = 0, p1_state{1} = 1
2. Cooldown decrements: p1_catch_timer = 0 - 1 = 255 (underflow!)
3. Check passes: `if 255 >= 240` → TRUE every frame
4. __P1_Launch_Ball called every frame, reading current paddle direction
5. Ball velocity updates every frame = "telepathic control"

**Fix:**
```basic
; CORRECT
if ball_state = 1 && p1_catch_timer >= auto_launch_time then gosub __P1_Auto_Launch
```

### ❌ Mistake 3: Not Preserving Ball Speed on Deflection
```basic
; WRONG - Always resets to slow speed
__Ball_Bounce_P1
  temp_dir = (temp_dir + 8) & 15
  gosub __Set_Ball_Velocity_Slow  ; Always slow!
  return
```

**Fix:**
```basic
; CORRECT - Check timer and use appropriate table
__Ball_Bounce_P1
  if ball_speed_timer > 0 then gosub __Set_Ball_Velocity : return
  gosub __Set_Ball_Velocity_Slow
  return
```

### ❌ Mistake 4: Double Rotation in Deflections (v040 Bug)
```basic
; WRONG - Rotates direction TWICE
__Ball_Bounce_P1
  temp_dir = (temp_dir + 8) & 15      ; Rotation #1
  gosub __Set_Ball_Velocity

__Set_Ball_Velocity
  temp_dir = (temp_dir + 8) & 15      ; Rotation #2 - DOUBLE!
  on temp_dir goto ...
```

**Result:** Ball bounces in opposite direction of paddle facing!

**Fix (v041):**
```basic
; CORRECT - Only rotate once in __Set_Ball_Velocity
__Ball_Bounce_P1
  ; temp_dir already contains paddle direction
  if ball_speed_timer > 0 then gosub __Set_Ball_Velocity : return
  gosub __Set_Ball_Velocity_Slow
  return
```

### ❌ Mistake 5: Inconsistent Launch Speeds
```basic
; WRONG - Diagonal (2,2) = 2.83 speed, but cardinal (1,0) = 1.0 speed
ball_xvel = 1 : ball_yvel = 0  ; East = 1.0 speed
ball_xvel = 2 : ball_yvel = 2  ; SE = 2.83 speed (much faster!)
```

**Fix:** Balance velocities across all directions to similar total speeds.

---

## Best Practices for Nebulords

### 1. Always Check v051 Reference
- `/home/user/Nebulords/nebulords - main game v051 - out of bounds ball respawn.bas`
- Working 16k implementation with proper patterns
- Uses missile0/missile1 for paddles (hardware sprites)
- 8-direction system (simpler than PXE's 16-direction)

### 2. Test Auto-Launch Thoroughly
- Most complex feature, easy to break
- Watch for ball following paddle after auto-launch
- Verify ball_state checks in all timer logic

### 3. Preserve ball_speed_timer
- Critical for fast/slow ball mechanics
- Deflections must check timer and use correct velocity table
- Don't accidentally reset timer during normal gameplay

### 4. Use on...goto for Direction Tables
```basic
; Clean, efficient pattern for 16 directions
temp_dir = p1_direction
on temp_dir goto __Label_0 __Label_1 ... __Label_15
```

### 5. Comment Velocity Values with Actual Speeds
```basic
__BV_0  ; North - (0, -3) = 3.0 px/frame
  ball_xvel = 0 : ball_yvel = 253 : return
__BV_1  ; NNE - (1, -3) = 3.16 px/frame
  ball_xvel = 1 : ball_yvel = 253 : return
```

### 6. Virtual Sprite Collision = Coordinates ONLY
- Never use collision() with player2-16
- Always use bounding box overlap checks
- Account for sprite dimensions and offsets

### 7. Understand PXE Virtual Sprite Layout
- player2 = P1 paddle (virtual sprite)
- player3 = P2 paddle (virtual sprite)
- player0 = P1 ship (hardware)
- player1 = P2 ship (hardware)
- Ball can use collision() with player0/player1 only

### 8. Version Numbering Convention
- v0XX = Major feature/fix versions
- Keep working versions in `/versions/` directory
- Update header comments with changes from previous version

---

## Quick Reference: Sprite Dimensions

### Ships (player0, player1)
- Visual: 16×26 pixels (double-width)
- NUSIZ = $05 (double width)

### Paddles (player2, player3)
- Visual: 6×9 pixels (single-width virtual sprites)
- NUSIZ2/NUSIZ3 = $00

### Ball
- 2×4 pixels
- ballheight = 1 (4 scanlines)

### Hitbox Expansions (v040)
- Paddle hitbox: 8×11 pixels (expanded +1px each side)
- Helps prevent ball passing through

---

## Debugging Checklist

When ball behavior is wrong:

1. **Ball follows paddle after launch?**
   - Check auto-launch timer logic
   - Verify ball_state check in auto-launch condition
   - Look for timer underflow (0 - 1 = 255)

2. **Ball bounces wrong direction?**
   - Count direction rotations (should only rotate ONCE)
   - Verify temp_dir value at velocity assignment
   - Check if using correct direction system (0=South vs 0=North)

3. **Ball speed changes on deflection?**
   - Check if deflection preserves ball_speed_timer
   - Verify using correct velocity table (fast vs slow)

4. **Ball passes through paddle?**
   - Expand hitbox (+1px on all sides)
   - Check coordinate-based collision math
   - Verify ball_state check prevents collision when attached

5. **Compilation errors with collision()?**
   - Make sure only using player0, player1, missile0, missile1, ball
   - Never use player2-16 with collision()

---

## File Structure Reference

```
/home/user/Nebulords/
├── nebulords - main game v051 - out of bounds ball respawn.bas  (Reference implementation)
├── versions/
│   ├── nebulordsPXE_v032.bas  (First PXE attempt, collision() errors)
│   ├── nebulordsPXE_v033.bas  (Same collision() errors)
│   ├── nebulordsPXE_v034.bas  (Ball positioning issues)
│   ├── nebulordsPXE_v035.bas  (Fixed collision with bounding boxes)
│   ├── nebulordsPXE_v036.bas  (Position adjustments)
│   ├── nebulordsPXE_v037.bas  (Southern position tweaks)
│   ├── nebulordsPXE_v038.bas  (Fixed auto-launch underflow bug)
│   ├── nebulordsPXE_v039.bas  (Normalized deflect speeds, fixed P2 hitbox)
│   ├── nebulordsPXE_v040.bas  (Adjusted launch speeds, maintained deflect speed)
│   └── nebulordsPXE_v041.bas  (Fixed double rotation bug in deflections)
└── nebulords_bB_and_PXE_Reference.md  (This document)
```

---

## Version History Critical Bugs

| Version | Bug | Fix |
|---------|-----|-----|
| v032-v034 | collision() with player2/3 compilation errors | Use coordinate-based detection (v035) |
| v034-v037 | Ball follows paddle after auto-launch | Add ball_state check to auto-launch condition (v038) |
| v039 | Deflections always reset to slow speed | Check ball_speed_timer, use appropriate table (v040) |
| v040 | Deflections bounce opposite direction | Remove double rotation, rotate only once (v041) |

---

*Last Updated: Session ending 2025-11-17*
*Session Token Count: ~71,000 / 200,000 used*
