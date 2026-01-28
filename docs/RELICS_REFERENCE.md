# Relics Reference

> **Last Updated**: 2026-01-22
> When adding or modifying relics, update this file to keep documentation in sync.

---

## Table of Contents

- [Universal Relics](#universal-relics)
- [Fabio Relics](#fabio-relics)
- [Kevin Relics](#kevin-relics)
- [Enrique Relics](#enrique-relics)
- [Trigger Types Reference](#trigger-types-reference)

---

## Universal Relics

Available to all heroes.

| Relic | Trigger | Effect |
|-------|---------|--------|
| **BackPack** | Turn Start | Draw 1 extra card at the start of each turn |
| **Second Wind** | On Damage Dealt | Gain 1 Stamina when dealing 10+ damage in a single hit |
| **Copying Machine** | Passive | Multi-hit cards attack one additional time |
| **Cracked Gem** | Turn Start | Gain 1 Stamina on the first turn of combat only |
| **Restorative Locket** | Fight End | Heal 10 HP after winning a fight |
| **Nipple Protectors** | Fight Start | Gain 2 Armor at the start of combat |
| **Grandma's Cookies** | On Heal | All healing effects increased by +5 |
| **Coffee Soda** | On Pickup | Gain +10 max HP and heal 10 HP when acquired |
| **Power Ring** | Fight Start | Gain 1 Strength at the start of combat |
| **Rage Meter** | On Card Played | Gain 1 Stamina on every 3rd card played per turn |
| **Blood Crystal** | Turn Start + Fight Start | +1 Stamina at turn start, but start each fight with 4 Bleed |
| **Radiating Apple** | Turn Start + Turn End | +1 Stamina at turn start, take 1 damage at turn end |
| **Revive Relic** | Active Use | Click to revive 1 dead teammate (once per fight) |

---

## Fabio Relics

Warrior-specific relics.

| Relic | Trigger | Effect |
|-------|---------|--------|
| **Brass Knuckles** | Fight Start | Gain 1 Strength at the start of combat |
| **Dragon Scale Cream** | Fight Start | Gain 2 Armor at the start of combat |
| **Forearm Trainer** | Passive | Attack cards costing 2+ Stamina cost 1 less |

---

## Kevin Relics

Alchemist-specific relics.

| Relic | Trigger | Effect |
|-------|---------|--------|
| **Water Stone** | On Debuff Applied | When enemy gains Wet, they gain additional Wet stacks |
| **Familiar Bracelet** | Passive | Non-spell, non-Alc cards deal +2 damage |
| **Wooden Cauldron** | On Brew | Draw 1 card after brewing an Alc card |

---

## Enrique Relics

Cleric-specific relics.

| Relic | Trigger | Effect |
|-------|---------|--------|
| **Prayer Book** | Fight Start | Gain +4 Aura at the start of combat |
| **Gentle Hands** | On Heal | +5 additional healing when healing allies |
| **Shining Feather** | Turn End | If you have 5+ Aura at turn end, gain 5 Shield |
| **Electrified Idol** | On Heal | Deal 5 damage to a random enemy when healing an ally |

---

## Trigger Types Reference

| Trigger | When It Fires |
|---------|---------------|
| **ON_PICKUP** | Immediately when the relic is acquired |
| **FIGHT_START** | At the beginning of each combat encounter |
| **TURN_START** | At the start of each of the player's turns |
| **TURN_END** | At the end of each of the player's turns |
| **ON_DAMAGE_DEALT** | After the player deals damage with a card |
| **ON_CARD_PLAYED** | After any card is played |
| **ON_HEAL** | When healing is applied to any target |
| **ON_DEBUFF_APPLIED** | When a debuff is applied to an enemy |
| **ON_BREW** | When Kevin brews an Alc card (Kevin only) |
| **FIGHT_END** | After a combat encounter is won |
| **PASSIVE_MODIFIER** | Always active during damage/cost calculations |
| **ACTIVE_USE** | Player clicks the relic to activate it |

---

## Relic Categories

| Category | Description |
|----------|-------------|
| **UNIVERSAL** | Available to all heroes in reward pools |
| **FABIO** | Only offered to Fabio |
| **KEVIN** | Only offered to Kevin |
| **ENRIQUE** | Only offered to Enrique |

---

## File Location

All relic definitions are in: `scripts/relic_registry.gd`
