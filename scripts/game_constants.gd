class_name GameConstants
## Central repository for all game balance constants and magic numbers
##
## This file extracts all hardcoded values from across the codebase into one
## maintainable location. Change values here to rebalance the entire game.

# =============================================================================
# HAND AND DECK MANAGEMENT
# =============================================================================

## Maximum number of cards a player can hold in their hand at once
## Attempting to draw beyond this limit will fail
const MAX_HAND_SIZE: int = 10

## Maximum shield a character can have
## This prevents infinite shield stacking exploits
const SHIELD_CAP: int = 999

# =============================================================================
# STATUS EFFECT MULTIPLIERS
# =============================================================================

## Damage multiplier for vulnerable status effect
## Vulnerable increases damage taken by 50% (1.0 + 0.5 = 1.5x)
const VULNERABLE_DAMAGE_MULTIPLIER: float = 1.5

## Amount by which status effects decay each turn
## Most status effects (vulnerable, weakness) decrease by this amount at turn end
const STATUS_DECAY_AMOUNT: int = 1

## Amount by which poison decreases after applying damage
## Poison deals damage, then reduces by this amount
const POISON_DECAY_AMOUNT: int = 1

# =============================================================================
# BOSS HEALTH PROGRESSION
# =============================================================================

## Health pools for each boss encounter
## Bosses scale in difficulty from 200 HP (boss 0) to 600 HP (boss 4)
## Dictionary maps boss index to max HP
const BOSS_HP_SCALING: Dictionary = {
	0: 200,  # Corrupted Treant - Entry level boss
	1: 280,  # Flame Warlord - 40% health increase
	2: 350,  # Lich Summoner - 25% health increase
	3: 450,  # Storm Dragon - 29% health increase
	4: 600   # Void Titan - 33% health increase (final boss)
}

## Stamina available to bosses per turn
## Bosses gain more stamina in later encounters
const BOSS_STAMINA_SCALING: Dictionary = {
	0: 2,  # Corrupted Treant
	1: 3,  # Flame Warlord
	2: 3,  # Lich Summoner
	3: 4,  # Storm Dragon
	4: 4   # Void Titan
}

# =============================================================================
# HERO BALANCE
# =============================================================================

## Health pools for each hero archetype
const HERO_MAX_HEALTH: Dictionary = {
	"flame_wielder": 90,    # Glass cannon - low HP, high damage
	"life_weaver": 110,     # Healer - highest HP
	"shadow_assassin": 85,  # Lowest HP - relies on drains
	"storm_caller": 95,     # Mid-range mage
	"beast_tamer": 120,     # Tank - highest HP
	"chrono_mage": 100      # Balanced time mage
}

## Starting stamina for all heroes
## Currently uniform, but extracted for future per-hero tuning
const HERO_STARTING_STAMINA: int = 3

# =============================================================================
# REWARD SYSTEM
# =============================================================================

## Percentage of max HP restored by "heal" option in reward screen
## Set to 0.5 for 50% heal
const REWARD_HEAL_PERCENTAGE: float = 0.5

## Number of rare card choices offered to one random player
const REWARD_RARE_CARD_CHOICES: int = 3

## Number of common card choices offered to each player
const REWARD_COMMON_CARD_CHOICES: int = 3

# =============================================================================
# COMBAT TIMING
# =============================================================================

## Delay in seconds before boss turn starts (for visual clarity)
const BOSS_TURN_START_DELAY: float = 1.0

## Delay in seconds between boss card plays (for visual tracking)
const BOSS_CARD_PLAY_DELAY: float = 0.5

## Delay in seconds before transitioning to reward screen after boss defeat
const BOSS_DEFEAT_TRANSITION_DELAY: float = 2.0

## Delay in seconds before wizard starts speaking in reward screen
const WIZARD_INTRO_DELAY: float = 0.5

## Delay in seconds wizard speaks before showing rare cards
const WIZARD_RARE_CARD_DELAY: float = 3.0

## Delay in seconds wizard speaks before showing common choices
const WIZARD_COMMON_CHOICE_DELAY: float = 3.0
