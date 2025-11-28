# v014 Scoring Fix - True Last-Man-Standing

## Problem
Current code awards points immediately when ANY player dies. In 4-player mode, this would give 3 points to the survivor (one for each kill).

## Solution
Only award a point when **exactly 1 player is left alive**.

---

## Changes to Apply

### 1. Add New Function (add after `__Award_P2_Point`)

```basic
  ;***************************************************************
  ;  Check Last Man Standing - Award point only if 1 player alive
  ;  Counts alive players (Y < 100) and awards point to survivor
  ;  Scalable for 4-player mode
  ;***************************************************************
__Check_Last_Man_Standing
  ; Count alive players
  temp1 = 0
  if player0y < 100 then temp1 = temp1 + 1
  if player1y < 100 then temp1 = temp1 + 1
  ; Future: Add player2y and player3y checks for 4-player

  ; Only award point if exactly 1 player alive
  if temp1 <> 1 then return

  ; ONE player left - find who and award point
  if player0y < 100 then gosub __Award_P1_Point
  if player1y < 100 then gosub __Award_P2_Point
  ; Future: Add player2y → __Award_P3_Point
  ; Future: Add player3y → __Award_P4_Point
  return
```

### 2. Update `__P1_Core_Hit` Function

**FIND:**
```basic
__P1_Core_Hit
  ; Player 1 dies - Player 2 is last man standing
  ; Award point to P2 immediately (last-man-standing)
  gosub __Award_P2_Point
  ; Hide P1 ship sprite off-screen (player0)
  player0y = 200
```

**REPLACE WITH:**
```basic
__P1_Core_Hit
  ; Player 1 dies - check if last man standing
  ; Hide P1 ship sprite off-screen (player0)
  player0y = 200
  ; Hide P1 paddle off-screen (player2)
  player2y = 200
  ; Check if only 1 player left alive (true last-man-standing)
  gosub __Check_Last_Man_Standing
  ; Start 3-second countdown before round reset
```

### 3. Update `__P2_Core_Hit` Function

**FIND:**
```basic
__P2_Core_Hit
  ; Player 2 dies - Player 1 is last man standing
  ; Award point to P1 immediately (last-man-standing)
  gosub __Award_P1_Point
  ; Hide P2 ship sprite off-screen (player1)
  player1y = 200
```

**REPLACE WITH:**
```basic
__P2_Core_Hit
  ; Player 2 dies - check if last man standing
  ; Hide P2 ship sprite off-screen (player1)
  player1y = 200
  ; Hide P2 paddle off-screen (player3)
  player3y = 200
  ; Check if only 1 player left alive (true last-man-standing)
  gosub __Check_Last_Man_Standing
  ; Start 3-second countdown before round reset
```

---

## How It Works

### 2-Player Mode (Current):
1. P1 dies → player0y = 200
2. Count alive: player0y (200) = dead, player1y (40) = alive → count = 1
3. **Only 1 alive** → Award point to P1
4. Score updates immediately ✅

### 4-Player Mode (Future):
1. P1 dies → player0y = 200
2. Count alive: P2, P3, P4 still alive → count = 3
3. **More than 1 alive** → Don't award yet
4. P2 dies → count = 2 → Don't award yet
5. P3 dies → count = 1 → **NOW award point to P4** ✅

---

## Why This Is Better

✅ **Immediate feedback** - Score shows as soon as last man standing determined
✅ **Scales to 4-player** - Just add P3/P4 checks in the count section
✅ **True last-man-standing** - Only survivor gets 1 point, not 1 per kill
✅ **Modular** - Easy to understand and expand

---

## Testing

**2-Player Mode:**
- P1 kills P2 → P1 gets 1 point immediately ✅
- P2 kills P1 → P2 gets 1 point immediately ✅

**4-Player Mode (when implemented):**
- P1 kills P2, P3, P4 → P1 gets 1 point (not 3) ✅
- Deaths 1 & 2 → No points awarded
- Death 3 (last player dies) → Survivor gets 1 point ✅
