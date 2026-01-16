# Bug Fixes - January 9, 2026

## Session 1: Phase 1 Implementation

### Bug #1: generate_cards Type Error ✅ FIXED
**Error Message**:
```
Invalid assignment of property or key 'generate_cards' with value of type 'Array' on a base object of type 'Resource (Card)'.
```

**Location**: `scripts/card_database.gd:739` (pyroclasm card)

**Root Cause**:
- Card class has typed property: `@export var generate_cards: Array[String] = []`
- Code was assigning untyped array literal: `["ember", "ember"]`
- Godot 4 enforces strict typing - can't assign untyped to typed

**Fix**:
```gdscript
# Before (WRONG):
all_cards["pyroclasm"].generate_cards = ["ember", "ember"]

# After (CORRECT):
var pyroclasm_embers: Array[String] = ["ember", "ember"]
all_cards["pyroclasm"].generate_cards = pyroclasm_embers
```

**Status**: ✅ Fixed

---

### Bug #2: energy_cost References After Rename ✅ FIXED
**Error Message**:
```
Invalid assignment of property or key 'energy_cost' with value of type 'int' on a base object of type 'Resource (Card)'.
```

**Location**: Multiple files
- `scripts/boss_database.gd:29`
- `scripts/data/bosses_data.gd` (22 occurrences)
- `scripts/minion_database.gd:72`

**Root Cause**:
- Phase 0 renamed `energy_cost` → `stamina_cost` globally
- Boss and minion database loaders were missed in the initial rename
- Boss card data still used old `energy_cost` property names

**Fix**:

**boss_database.gd**:
```gdscript
# Before (WRONG):
card.energy_cost = data.energy_cost

# After (CORRECT):
card.stamina_cost = data.get("stamina_cost", data.get("energy_cost", 0))  # Support old data
```

**bosses_data.gd**:
```gdscript
# Before (WRONG):
"energy_cost": 1,

# After (CORRECT):
"stamina_cost": 1,
```
Applied to all 22 boss card definitions

**minion_database.gd**:
```gdscript
# Before (WRONG):
card.energy_cost = data.cost

# After (CORRECT):
card.stamina_cost = data.cost
```

**Status**: ✅ Fixed

---

## Prevention Strategies

### 1. Use Global Search Before Renaming
When renaming a widely-used property, search ALL files first:
```bash
grep -r "old_property_name" scripts/ --include="*.gd"
```

### 2. Check Data Files Too
Don't forget to search data files (`*_data.gd`) - they often have string-based property names

### 3. Add Backward Compatibility
Use `.get()` with fallbacks when renaming:
```gdscript
new_value = data.get("new_name", data.get("old_name", default))
```

### 4. Test All Game Modes
After a rename:
- Character selection (loads hero/boss data)
- Combat with players (uses card system)
- Combat with bosses (uses boss cards)
- Combat with minions (uses minion cards)

---

## Lessons Learned

1. **Typed arrays are strict in Godot 4**
   - Can't assign `["a", "b"]` to `Array[String]`
   - Must use typed intermediate variable

2. **Global renames need careful verification**
   - Used replace_all in 36+ files for Energy → Stamina
   - Missed 3 files: boss_database.gd, bosses_data.gd, minion_database.gd
   - Should have done grep verification before marking complete

3. **Data files are easy to miss**
   - `*_data.gd` files often use string keys for dictionaries
   - Harder to catch with code-based searching
   - Need manual inspection of data definitions

---

## Testing Verification

After fixes, verify:
- [ ] Game launches without errors
- [ ] Character selection loads all heroes
- [ ] Can start combat
- [ ] Boss cards load correctly
- [ ] Minion fights work
- [ ] No more `energy_cost` errors in console

---

**Total Bugs Fixed**: 2
**Files Modified**: 4
**Time to Fix**: ~10 minutes
**Prevention**: Better global search + data file inspection
