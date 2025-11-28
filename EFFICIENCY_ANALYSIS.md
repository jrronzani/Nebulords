# Nebulords Code Efficiency Analysis

## Executive Summary
Current v006 has **significant code duplication** that can be consolidated for:
- **ROM space savings** (critical for 16KB limit)
- **4-player scalability** (adding P3/P4 would duplicate code 4x!)
- **Maintainability** (bug fixes would need updating in multiple places)

---

## Duplication Found

### 1. ⭐ CRITICAL: Brick Hit Detection (~150 lines × 2 = 300 lines)
**Current:** Separate `__P1_Brick_Hit` and `__P2_Brick_Hit` functions

**Identical Logic:**
- Y-based section detection (top/middle/bottom)
- X-based brick selection (left/right)
- Brick destruction bit manipulation
- Core hit detection
- Bounce triggering

**Only Differences:**
- Player variable names (`player0x` vs `player1x`, `p1_bricks` vs `p2_bricks`)
- X offset for P2 hitbox (+2 pixels due to sprite positioning)
- Which sprite update function to call

**Consolidation Strategy:**
```basic
; Use temp variables to hold player-specific data
temp_player_x = player0x  ; or player1x
temp_player_y = player0y  ; or player1y
temp_bricks = p1_bricks   ; or p2_bricks
temp_offset = 0           ; or 2 for P2
temp_player_num = 0       ; 0=P1, 1=P2 for branching

gosub __Shared_Brick_Hit
```

**Savings:** ~140 lines (keeping small wrapper functions)

---

### 2. Launch Ball Functions (~12 lines)
**Current:**
```basic
__P1_Launch_Ball
  ball_state = 0
  temp_dir = p1_direction
  gosub __Set_Ball_Velocity
  ball_speed_timer = fast_ball_duration
  return

__P2_Launch_Ball
  ball_state = 0
  temp_dir = p2_direction
  gosub __Set_Ball_Velocity
  ball_speed_timer = fast_ball_duration
  return
```

**Consolidation:**
```basic
__Launch_Ball
  ; temp_dir already set by caller
  ball_state = 0
  gosub __Set_Ball_Velocity
  ball_speed_timer = fast_ball_duration
  return
```

**Savings:** ~6 lines

---

### 3. Auto-Launch Functions (~10 lines)
**Current:**
```basic
__P1_Auto_Launch
  gosub __P1_Launch_Ball
  p1_catch_timer = 0
  p1_state{1} = 1
  return

__P2_Auto_Launch
  gosub __P2_Launch_Ball
  p2_catch_timer = 0
  p2_state{1} = 1
  return
```

**Consolidation:**
```basic
__Auto_Launch
  ; temp_player_num set by caller (0=P1, 1=P2)
  temp_dir = p1_direction  ; or p2_direction based on temp_player_num
  gosub __Launch_Ball
  ; Clear catch timer and set cooldown based on temp_player_num
  return
```

**Savings:** ~5 lines

---

### 4. Brick Bounce (~14 lines)
**Current:**
```basic
__P1_Brick_Bounce
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  gosub __Update_P1_Ship_Sprite
  return

__P2_Brick_Bounce
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  gosub __Update_P2_Ship_Sprite
  return
```

**Consolidation:**
```basic
__Brick_Bounce
  ; Reverse ball velocity
  ball_xvel = 0 - ball_xvel
  ball_yvel = 0 - ball_yvel
  ; Push ball away (2x to prevent sticking)
  ballx = ballx + ball_xvel
  ballx = ballx + ball_xvel
  bally = bally + ball_yvel
  bally = bally + ball_yvel
  ; Update sprite based on temp_player_num
  if temp_player_num = 0 then gosub __Update_P1_Ship_Sprite
  if temp_player_num = 1 then gosub __Update_P2_Ship_Sprite
  return
```

**Savings:** ~7 lines

---

## Total Potential Savings
- **~158 lines** from current 2-player code
- **~316 lines** if/when adding 4-player mode (avoids duplicating 2 more times)

---

## 4-Player Scalability Impact

### Current Approach (Duplication):
- 2 players: ~300 lines of duplicated code
- 4 players: ~600 lines of duplicated code ❌

### Shared Approach:
- 2 players: ~160 lines (shared) + ~20 lines (player-specific wrappers)
- 4 players: ~160 lines (shared) + ~40 lines (player-specific wrappers)
- **Savings: 400+ lines!** ✅

---

## Implementation Priority

### Phase 1: Quick Wins (do now)
1. ✅ Sprite sharing (DONE in v006)
2. **Consolidate launch functions** (6 lines saved)
3. **Consolidate brick bounce** (7 lines saved)

### Phase 2: Major Refactor (before 4-player)
4. **Consolidate brick hit detection** (140 lines saved)
5. **Add P3/P4 with minimal code** (reuse shared functions)

---

## Game Mode Architecture

### Current State
- **1 Player vs Bot only** (hardcoded)

### Proposed: switchable.b (Game Select Switch)
```basic
; Game modes using switchable.b
; 0 = 1 Player vs Bot
; 1 = 2 Players vs Players
; (future) 2 = 4 Players vs Players
```

### Implementation:
```basic
if switchable.b then goto __P2_Human_Input
  gosub __AI_Update_P2  ; Bot mode
  goto __P2_Input_Done
__P2_Human_Input
  temp_paddle = Paddle1
  p2_direction = temp_paddle / 4
  if joy0left then p2_state{0} = 1 else p2_state{0} = 0
__P2_Input_Done
```

**Benefits:**
- No code duplication between bot/human
- Easy to add difficulty levels (switchbw.b = number of AI updates per frame)
- Scales to 4-player (3 bots, 2 bots+2 humans, 4 humans)

---

## Recommended Next Steps

1. **Test v006** (sprite sharing + last-man-standing)
2. **Implement game mode switching** (1P vs bot, 2P vs players)
3. **Consolidate launch/bounce functions** (quick wins)
4. **Test consolidated version**
5. **Plan 4-player expansion** (major brick hit refactor)
