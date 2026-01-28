# Status Effects Reference

> **Last Updated**: 2026-01-22
> **Maintainer Note**: When adding or modifying status effects, update this file to keep documentation in sync.
> See TODO comment in `scripts/status_effect_registry.gd` for reminder.

---

## Table of Contents

- [Damage Over Time (DOT) Effects](#damage-over-time-dot-effects)
- [Permanent Buffs](#permanent-buffs)
- [Decaying Debuffs](#decaying-debuffs)
- [Single-Turn Buffs](#single-turn-buffs)
- [Single-Turn Debuffs](#single-turn-debuffs)
- [Kevin's Alchemy Effects](#kevins-alchemy-effects)
- [Enrique's Divine Effects](#enriques-divine-effects)
- [Mute's Doll Debuffs](#mutes-doll-debuffs)
- [Decay Types Reference](#decay-types-reference)

---

## Damage Over Time (DOT) Effects

These effects deal damage each turn. All DOT damage is **piercing** (ignores Shield).

| Effect | Symbol | Decay | Description |
|--------|--------|-------|-------------|
| **Poison** | ☠️ | -1/turn | Take damage equal to stacks at turn end. Loses 1 stack per turn |
| **Bleed** | 🩸 | -1/turn | Take damage equal to stacks at turn end. Loses 1 stack per turn |
| **Burn** | 🔥 | None | Take damage equal to stacks at turn end. Does NOT decay |

---

## Permanent Buffs

These effects persist for the entire fight unless removed.

| Effect | Symbol | Modifier | Description |
|--------|--------|----------|-------------|
| **Strength** | 💪 | +1 damage/stack | Increases all attack damage permanently |
| **Armor** | 🛡️ | -1 damage taken/stack | Reduces all incoming damage permanently |

---

## Decaying Debuffs

These effects lose stacks over time.

| Effect | Symbol | Decay | Modifier | Description |
|--------|--------|-------|----------|-------------|
| **Vulnerable** | 💔 | -1/turn | 1.5x damage taken | Take 50% more damage from all sources |
| **Weakness** | 😵 | -1/turn | -1 damage/stack | Deal less damage with attacks |
| **Fatigued** | 😴 | After turn start | -1 stamina/stack | Lose stamina at start of next turn, then removed |
| **Hinder** | 🚫 | End of turn | -1 damage/stack | Deal less damage. Completely removed at turn end |
| **Feeble** | 🦴 | None (permanent) | -1 damage/stack | Permanent weakness. Must be removed by cards |

---

## Single-Turn Buffs

These effects provide temporary bonuses and reset at turn end.

| Effect | Symbol | Decay | Modifier | Description |
|--------|--------|-------|----------|-------------|
| **Rested** | 😌 | After turn start | +1 stamina/stack | Gain extra stamina at turn start, then removed |
| **Invigorated** | ⚡ | End of turn | Grants Damage+ | When applied, grants 2 Damage+ per stack. Removed at turn end |
| **Damage+** | ⚔️ | End of turn | +1 damage/stack | Temporary attack damage boost |

---

## Single-Turn Debuffs

These effects apply negative conditions that reset.

| Effect | Symbol | Decay | Description |
|--------|--------|-------|-------------|
| **Exhausted** | 🥵 | -1/turn | Cannot play cards while active. Self-applicable (applied to caster) |
| **Scared** | 😨 | End of turn | Cannot play ATTACK cards. Removed at turn end |
| **Decay** | 💀 | None (permanent) | Reduces healing received by 5 per stack. Cannot be removed. Self-applicable |

---

## Kevin's Alchemy Effects

Special effects tied to Kevin's elemental system.

| Effect | Symbol | Decay | Description |
|--------|--------|-------|-------------|
| **Wet** | 💧 | None | Stackable debuff. Increases Lightning Storm damage. Must be removed by cards |
| **Ring of Fire** | 💍 | End of enemy turn | When hit, deal 3 damage back to attacker. Persists through enemy attacks |

---

## Enrique's Divine Effects

Special effects tied to Enrique's support abilities.

| Effect | Symbol | Decay | Description |
|--------|--------|-------|-------------|
| **Played Twice** | 🔁 | Consumed | Next card played triggers twice. Consumed after one use |
| **Invincible** | ✨ | End of enemy turn | Take no damage this turn. Lasts until enemy turn ends |

---

## Mute's Doll Debuffs

Special curse effects from Boss 4 (Mute). All are permanent until removed.

| Effect | Symbol | Decay | Description |
|--------|--------|-------|-------------|
| **Doll: Dissolve** | 🎭 | None | Take 1 damage per stack for each card played |
| **Doll: Suffering** | 🎭 | None | Take 5 damage per stack at end of turn |
| **Doll: Burden** | 🎭 | None | Draw 1 less card per stack each turn |

---

## Other Debuffs

| Effect | Symbol | Decay | Description |
|--------|--------|-------|-------------|
| **Venom** | 🐍 | None | Stacks up. At 3 stacks, deals 20 damage and resets |
| **Burden** | ⚓ | None | Take 5 damage per stack at end of turn |
| **Dissolve** | 🧪 | None | Take damage for each card played |

---

## Decay Types Reference

| Decay Type | When It Happens |
|------------|-----------------|
| **NONE** | Effect persists until manually removed or fight ends |
| **PER_TURN** | Loses `decay_amount` stacks at start of each turn |
| **END_OF_TURN** | Completely removed when the turn ends |
| **AFTER_TURN_START** | Effect applies at turn start, then is removed |
| **END_OF_ENEMY_TURN** | Persists through player turn and enemy attacks, removed after enemies finish |

---

## Effect Types

| Type | Description |
|------|-------------|
| **BUFF** | Positive effect applied to self or allies |
| **DEBUFF** | Negative effect applied to enemies (or self as cost) |
| **DOT** | Damage Over Time - deals damage each turn |

---

## Self-Applicable Effects

These debuffs are applied to the **caster** rather than the target. They serve as card costs or drawbacks.

- **Exhausted** - Cannot play cards (from Frenzy!)
- **Fatigued** - Lose stamina next turn (from Bulk Up, Story of Jacob)
- **Decay** - Reduced healing (from Medkit, Healing Aura)

---

## File Location

All status effect definitions: `scripts/status_effect_registry.gd`
