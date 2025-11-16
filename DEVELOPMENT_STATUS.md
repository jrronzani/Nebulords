# 🚀 NEBULORDS PXE - DEVELOPMENT STATUS

**Project Status:** Phase 3 Complete ✅ Paddle Sprites Implemented
**Current Milestone:** v015 - Paddle Sprites with 16-Direction Rotation
**Latest Version:** `versions/nebulordsPXE_v015.bas` (on branch `claude/add-paddle-sprites-*`)

---

## What Works

✅ 2-player paddle directional control (16 directions)
✅ Button-activated movement (joy0right/joy0left for paddle buttons)
✅ Double-width sprites (NUSIZ0 = $05, _NUSIZ1 = $05)
✅ 26-scanline tall sprites with gradient colors
✅ Doubled Y velocities for PXE's 176-line screen
✅ Ball physics with proper boundaries
✅ PRECISE collision boundaries (user corrected final pixel alignment in v014)
✅ Rainbow gradient playfield colors
✅ 8-scanline thick borders (proportional to block width)
✅ **Rotating paddle sprites (player2/player3) - NEW in v015!**
✅ **16-direction paddle positioning around ship perimeter - NEW in v015!**
✅ **7 unique rotation frames for smooth animation - NEW in v015!**

---

## File Structure

```
/versions/
  nebulordsPXE_v001.bas - v014.bas (all development versions)

/ (root)
  nebulords - main game v051.bas (original standard kernel version)
  nebulords - score and physics movement tests v013.bas
  nebulords - paddle test with ball v001.bas
  (various example files: 17_Sprites_PXE.bas, paddle-scrolls-pf.bas, etc.)
```

**Working Branch:** main (v014 is here)

---

## Critical Technical Knowledge - PXE Kernel Specifics

### 1. Virtual Sprites (like DPC+)
```basic
NUSIZ0 = $05      ; player0 uses standard TIA register
_NUSIZ1 = $05     ; player1 uses UNDERSCORE (virtual sprite!)
NUSIZ2 = $05      ; player2-9 use regular names
```

### 2. Screen Dimensions
- **176 scanlines** (double standard kernel's ~88)
- Requires **2x Y velocities** to match perceived speed
- **40 pixels wide** playfield (PF_MODE = $fd)

### 3. Paddle Button Syntax
```basic
joy0right = Paddle 0 button (NOT joy0fire!)
joy0left = Paddle 1 button (NOT joy1fire!)
joy1right = Paddle 2 button
joy1left = Paddle 3 button
```
⚠️ **Using joy0fire/joy1fire breaks paddle mode!**

### 4. Sprite Positioning
- `player0x/y` = top-left corner of sprite
- With NUSIZ $05: sprite is **16 pixels wide**
- Sprite height = number of scanlines defined

### 5. Current Boundaries (from v014)
**User verified these are pixel-perfect:**
- Players: 26 scanlines × 16 pixels
- Ball: 4 scanlines × 1 pixel
- Left/Right/Top/Bottom boundaries in v014

---

## Development History - Key Milestones

- **v001-v003:** Foundation - Paddle controls, 16-direction movement, symmetric South mapping
- **v004-v007:** Ball physics added - BROKE paddle control (wrong button syntax)
- **v008-v010:** Fixed paddle buttons (joy0right/left), restored functionality
- **v011:** Doubled Y velocities, added NUSIZ doubling, expanded sprites to 26 lines
- **v012:** User tweaked visuals - gradient colors, thicker borders, corner positioning
- **v013:** AI calculated flush boundaries (slightly off)
- **v014:** User corrected boundaries - PIXEL PERFECT ✅
- **v015:** Paddle sprites with 16-direction rotation - Phase 3 Complete! ✅

---

## Next Development Phases (In Order)

### Phase 3: Paddle Sprites ✅ **COMPLETE**
- ✅ Added paddle graphics as separate sprites (player2/player3)
- ✅ Rotated paddles around player ship perimeter based on direction
- ✅ Created 7 unique rotation frames
- ✅ Implemented 16 rotation positions with doubled Y offsets for PXE
- Uses inline sprite definitions (batari Basic requirement)

### Phase 4: Thrust Physics & Collisions 🎯 **← NEXT PHASE**
- Implement thrust-based movement (not instant velocity)
- Player-on-player collision detection
- Player-on-playfield collision with hitboxes (larger than sprites)
- Use hardware collision registers: `collision(player0,playfield)`
- Players should bounce off playfield walls and other players

### Phase 5: Ball Mechanics
- Ball catching (when ball touches paddle)
- Ball launching (with velocity based on paddle direction)
- Launch makes ball go faster for a limited time
- Time limit for ball holding
  - Holding too long auto launches ball and eliminates ability to catch for a limited time (Can still deflect)
- Ball-player collision detection
- Ball wrap-through for holes in playfield

### Phase 6: Brick Breaking & Destruction
- Breakable brick obstacles in playfield
- Hitbox system for precise brick detection
- Core destruction mechanics
- Zone-based collision for complex shapes

### Phase 7: Scoring & HUD
- Score display (may use pfscore bars)
- Lives/health indicators
- Level indicators

### Phase 8: 4-Player Support
- Add player2 and player3 (NUSIZ2, NUSIZ3)

### Phase 9: Level System
- Different obstacle layouts

---

## Important Design Decisions

- **Blocky sprite aesthetic** - Intentional Warlords brick style
- **Paddle as directional dial** - Not positional control
- Both paddle extremes = South (0 and 16 → 0)
- Future: Hitboxes larger than sprites for better gameplay
- Future: Holes in playfield for ball wrap-around

---

## Known Issues / Future Considerations

- **Collision system:** Currently simple boundaries, needs hardware collision registers + zone mapping for complex shapes
- **Playfield holes:** Need zone checks to allow ball pass-through
- **Rotation graphics:** Will need 16 paddle rotation frames or clever sprite tricks
- **4-player rendering:** PXE supports 9+ sprites, should be feasible

---

## Key Files to Reference

### For PXE examples:
- `17_Sprites_PXE.bas` - Sprite management, NUSIZ usage
- `paddle-scrolls-pf.bas` - Paddle reading
- `pxe_full_playfield.bas` - Full 40×176 playfield with colors

### For game mechanics:
- `nebulords - main game v051.bas` - Original collision/physics logic
- `nebulords - score and physics movement tests v013.bas` - Advanced physics

### Documentation:
- `batari Basic Commands.txt` - Full command reference

---

## Starting the Next Session

**First task:** Review v014 boundaries and begin Phase 3 - Paddle Sprites

**Recommended approach:**
1. Create rotation lookup table (16 positions)
2. Position paddle relative to player sprite center
3. Test rotation visual accuracy

---

*Last Updated: v015 - Phase 3 Complete (Paddle Sprites)*
