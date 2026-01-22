extends Resource
class_name Card

enum CardType {
	ATTACK,
	SPELL,
	BUFF,
	DEBUFF,
	HEAL,
	SUMMON,
	COUNTER
}

enum TargetType {
	SELF,
	SINGLE_ALLY,
	ALL_ALLIES,
	OTHER_ALLIES,   # All allies except caster
	SINGLE_ENEMY,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	ANY,
	CCW_PLAYER,     # Targets the player with CCW marker (rotates each turn)
	HIGHEST_HP,     # Targets the player with highest current HP
	LOWEST_HP,      # Targets the player with lowest current HP
	LOWEST_HP_ALLY, # Lowest HP ally (excluding self)
	RANDOM_ALLY,    # Random ally (excluding self)
	MOST_WET,       # Player with most Wet stacks
	MOST_DEBUFFS,   # Player with most total debuff stacks
	TARGET_BY_NAME  # Target specific player by character name (uses target_player_name)
}

enum ElementType {
	NONE,
	FIRE,
	WATER,
	EARTH
}

@export var card_name: String
@export var description: String
@export var card_type: CardType
@export var target_type: TargetType
@export var stamina_cost: int
@export var damage: int = 0
@export var heal_amount: int = 0
@export var heal_per_wet_removed: int = 0  # Bonus heal per Wet stack on enemies
@export var shield_amount: int = 0
@export var draw_cards: int = 0
@export var is_upgraded: bool = false

# v2 Card System - allows player to choose between two effects during play
@export var has_v2: bool = false
@export var v2_card_id: String = ""  # ID to look up v2 variant from CardDatabase
@export var context_sensitive_v2: bool = false  # If true, drop target determines version (no modal)
var v2_card: Card = null  # Local reference (not serialized over network)

# Status effects
# IMPORTANT: These "apply_X" properties MUST match StatusEffectRegistry effect names exactly.
# Example: Registry has "poison" -> Card needs "apply_poison"
# If you add a new effect to the registry, you MUST also:
#   1. Add the @export var apply_<effect_name> here
#   2. Add it to serialize() method below
#   3. Add it to deserialize() method below
# Missing any of these causes SILENT FAILURES - the effect won't apply but no error shown.
# See StatusEffectRegistry.gd for full instructions.
@export var apply_poison: int = 0
@export var apply_burn: int = 0
@export var apply_weakness: int = 0
@export var apply_vulnerable: int = 0
@export var apply_strength: int = 0
@export var apply_armor: int = 0

# Phase 1 status effects (Fabio)
@export var apply_rested: int = 0          # Buff: +1 Stamina at start of turn, then remove
@export var apply_invigorated: int = 0     # Buff: Gain 2 DamagePlus, removed at end of turn
@export var apply_damage_plus: int = 0     # Buff: Strength for one turn only
@export var apply_fatigued: int = 0        # Debuff: -1 Stamina next turn, removed after 2 turns
@export var apply_exhausted: int = 0      # Debuff: Cannot play cards this turn
@export var apply_decay: int = 0          # Debuff: Cannot heal this turn
@export var apply_hinder: int = 0         # Debuff: -X strength until next attack turn
@export var apply_scared: int = 0         # Debuff: Cannot play attacks next turn
@export var apply_venom: int = 0          # Debuff: At 3 stacks, deal 20 damage and reset
@export var apply_bleed: int = 0          # DOT: Deal X damage per turn, decay by 1
@export var apply_feeble: int = 0         # Debuff: Permanent -1 damage per stack (reverse strength)
@export var apply_burden: int = 0         # Debuff: Draw X fewer cards at turn start
@export var apply_dissolve: int = 0       # Debuff: Take X damage per card played

# Mute's Doll debuffs (Boss 4)
@export var apply_doll_dissolve: int = 0  # Debuff: Take 1 damage per stack per card played
@export var apply_doll_suffering: int = 0 # Debuff: Take 5 damage per stack at end of turn
@export var apply_doll_burden: int = 0    # Debuff: Draw 1 less card per stack
@export var apply_random_doll: int = 0    # Apply random Doll debuff (Instantiation)
@export var exhaust_target_deck: int = 0  # Exhaust X cards from target's deck (Hex: Acquisition)

# Special mechanics
@export var piercing: bool = false  # Ignores armor
@export var lifesteal: bool = false
@export var multi_hit: int = 1  # Number of times to apply effect
@export var aoe_damage: bool = false
@export var plays_immediately: bool = false  # Plays when selected in SELECTION phase (e.g., Draw cards)

# Delayed damage system (e.g., Jumping Strike)
@export var is_delayed_damage: bool = false  # If true, damage is applied next turn
@export var delay_condition: String = ""  # Condition: "no_damage_taken" - check caster took 0 damage
@export var delayed_damage_amount: int = 0  # Damage to deal next turn if condition met

# Card retention system (e.g., Dig a Hole)
@export var grants_card_retain: bool = false  # If true, opens card selection to retain a card

# Target swap system (e.g., Protector)
@export var swaps_enemy_target: bool = false  # If true, redirects enemy attacks from target to caster

# Boss intent reveal (e.g., Hunter's Instinct)
@export var reveals_boss_intent: bool = false  # If true, reveals what the boss will play next turn

# Card generation
@export var generate_cards: Array[String] = []  # Names of cards to add to hand
@export var scry_amount: int = 0  # Look at top X cards of deck

# Discard effects
@export var caster_discards_random: int = 0  # Caster discards X random cards from hand

# Conditional damage
@export var bonus_damage_if_wounded: int = 0  # Extra damage if target below 50% HP
@export var bonus_damage_per_debuff: int = 0  # Extra damage per debuff stack on target
@export var damage_threshold_check: int = 0  # If target took >= this damage this turn
@export var damage_threshold_modifier: int = 0  # Apply this modifier (negative reduces damage)

# Stamina effects
@export var stamina_gain: int = 0  # Stamina granted to caster when played

# Element/Alchemy system (Kevin)
@export var element: ElementType = ElementType.NONE  # Element for Spell cards
@export var ingredient_list: Array[String] = []  # Required elements to brew (for Alc cards)
@export var is_alc: bool = false  # If true, this is an Alc card (goes to Satchel, returns after play)

# Wet mechanic (Kevin)
@export var apply_wet: int = 0  # Apply X stacks of Wet to target
@export var bonus_damage_per_wet: int = 0  # Extra damage per Wet stack on target
@export var remove_all_wet: bool = false  # Remove all Wet from target

# Ring Of Fire (Kevin)
@export var apply_ring_of_fire: int = 0  # Apply Ring of Fire buff (reflects damage)

# Spell discard mechanics (Kevin)
@export var discard_spell_requirement: int = 0  # Must discard X spells to play this card (fixed count)
@export var min_spell_discard: int = 0  # Minimum spells to discard (0 = optional)
@export var max_spell_discard: int = 0  # Maximum spells to discard (-1 = unlimited, 0 = use discard_spell_requirement)
@export var discard_all_spells: bool = false  # Discard all spell cards in hand
@export var damage_per_spell_discarded: int = 0  # Bonus damage per spell discarded
@export var random_spell_discard: bool = false  # If true, randomly discard spells instead of showing modal

# Spell search/tutor (Kevin)
@export var choose_spell_from_deck: int = 0  # Search deck for X spells, add to hand

# All players effects (Kevin)
@export var all_players_shield: int = 0  # Grant X shield to all players

# Target stamina grant (Kevin)
@export var target_stamina_gain: int = 0  # Grant X stamina to target

# Target debuff removal (Kevin)
@export var remove_target_debuffs: int = 0  # Remove X debuffs from target

# Enrique's Aura system
@export var aura_cost: int = 0  # Aura cost to play this card
@export var aura_cost_all: bool = false  # If true, costs ALL aura (spends everything)
@export var aura_gain: int = 0  # Aura granted to caster when played
@export var damage_per_aura_spent: int = 0  # Bonus damage per aura spent (for "all aura" cards like Expulsion)

# Enrique's buff effects
@export var grants_played_twice: bool = false  # Grant target "played twice" buff (Divine Reflection)
@export var grants_invincible: bool = false  # Grant target "invincible" buff (Divine Barrier)

# D6 damage (Prayer Beads)
@export var damage_is_d6: bool = false  # If true, damage is random 1-6 (replaces base damage)

# All players draw cards (Guy with Beard)
@export var all_players_draw: int = 0  # All players draw X cards

# Summoning system (Spider-Queen, etc.)
@export var summon_minion_tag: String = ""  # Tag to filter summonable minions (e.g., "spiderling")
@export var summon_count: int = 0           # Number of minions to summon

# Target by name system (for TARGET_BY_NAME target type)
@export var target_player_name: String = ""  # Character name to target (e.g., "Fabio")

# Enemy ally targeting effects
@export var all_allies_shield: int = 0       # Grant X shield to all allies (enemy-side Giant Shield)
@export var remove_self_debuffs: bool = false # Remove all debuffs from caster (Fighter's Spirit)
@export var remove_target_buffs: bool = false # Remove all buffs from target (Corrupted Incense)

# Self-applied debuffs (cost/downside of powerful cards)
@export var caster_bleed: int = 0            # Apply bleed to caster
@export var caster_feeble: int = 0           # Apply feeble to caster

# Exhaust mechanic - card removed from game after use
@export var exhausts: bool = false           # Card is removed from deck after playing (doesn't go to discard)

# Runtime-only unique ID for queued card instances (invisible to player, not saved to disk)
# Used to distinguish between identical cards in the queue (e.g., two Fire Strike cards)
var queue_instance_id: int = 0

## Get description with dynamic damage values based on caster's buffs/debuffs
## Used for card display to show actual damage that will be dealt
func get_full_description(caster = null) -> String:
	if caster == null or card_type != CardType.ATTACK or damage <= 0:
		return description

	var calculated_damage = CardEffectEngine.calculate_damage(self, caster, null)
	var result = description

	# Replace base damage with calculated damage in description
	# Handle "Deal X damage" pattern
	result = result.replace("Deal %d damage" % damage, "Deal %d damage" % calculated_damage)

	# Handle multi-hit: "X damage each" or "X damage X times"
	if multi_hit > 1:
		result = result.replace("%d damage each" % damage, "%d damage each" % calculated_damage)
		result = result.replace("%d damage %d times" % [damage, multi_hit], "%d damage %d times" % [calculated_damage, multi_hit])
		# Handle "(X total)" pattern for multi-hit cards
		var base_total = damage * multi_hit
		var calculated_total = calculated_damage * multi_hit
		result = result.replace("(%d total)" % base_total, "(%d total)" % calculated_total)

	return result

func can_afford(current_stamina: int, current_aura: int = 0) -> bool:
	# Check stamina
	if current_stamina < stamina_cost:
		return false

	# Check aura
	if aura_cost_all:
		# "All aura" cards require at least 1 aura
		if current_aura < 1:
			return false
	elif aura_cost > 0:
		if current_aura < aura_cost:
			return false

	return true

# Network serialization
func serialize() -> Dictionary:
	return {
		"card_name": card_name,
		"description": description,
		"card_type": card_type,
		"target_type": target_type,
		"stamina_cost": stamina_cost,
		"damage": damage,
		"heal_amount": heal_amount,
		"heal_per_wet_removed": heal_per_wet_removed,
		"shield_amount": shield_amount,
		"draw_cards": draw_cards,
		"is_upgraded": is_upgraded,
		"apply_poison": apply_poison,
		"apply_burn": apply_burn,
		"apply_weakness": apply_weakness,
		"apply_vulnerable": apply_vulnerable,
		"apply_strength": apply_strength,
		"apply_armor": apply_armor,
		"apply_rested": apply_rested,
		"apply_invigorated": apply_invigorated,
		"apply_damage_plus": apply_damage_plus,
		"apply_fatigued": apply_fatigued,
		"apply_exhausted": apply_exhausted,
		"apply_decay": apply_decay,
		"apply_hinder": apply_hinder,
		"apply_scared": apply_scared,
		"apply_venom": apply_venom,
		"apply_bleed": apply_bleed,
		"apply_feeble": apply_feeble,
		"apply_burden": apply_burden,
		"apply_dissolve": apply_dissolve,
		"apply_doll_dissolve": apply_doll_dissolve,
		"apply_doll_suffering": apply_doll_suffering,
		"apply_doll_burden": apply_doll_burden,
		"apply_random_doll": apply_random_doll,
		"exhaust_target_deck": exhaust_target_deck,
		"piercing": piercing,
		"lifesteal": lifesteal,
		"multi_hit": multi_hit,
		"aoe_damage": aoe_damage,
		"plays_immediately": plays_immediately,
		"generate_cards": generate_cards,
		"scry_amount": scry_amount,
		"queue_instance_id": queue_instance_id,
		"has_v2": has_v2,
		"v2_card_id": v2_card_id,
		"context_sensitive_v2": context_sensitive_v2,
		"is_delayed_damage": is_delayed_damage,
		"delay_condition": delay_condition,
		"delayed_damage_amount": delayed_damage_amount,
		"grants_card_retain": grants_card_retain,
		"swaps_enemy_target": swaps_enemy_target,
		"reveals_boss_intent": reveals_boss_intent,
		"caster_discards_random": caster_discards_random,
		"bonus_damage_if_wounded": bonus_damage_if_wounded,
		"bonus_damage_per_debuff": bonus_damage_per_debuff,
		"damage_threshold_check": damage_threshold_check,
		"damage_threshold_modifier": damage_threshold_modifier,
		"stamina_gain": stamina_gain,
		"element": element,
		"ingredient_list": ingredient_list,
		"is_alc": is_alc,
		"apply_wet": apply_wet,
		"bonus_damage_per_wet": bonus_damage_per_wet,
		"remove_all_wet": remove_all_wet,
		"apply_ring_of_fire": apply_ring_of_fire,
		"discard_spell_requirement": discard_spell_requirement,
		"min_spell_discard": min_spell_discard,
		"max_spell_discard": max_spell_discard,
		"discard_all_spells": discard_all_spells,
		"damage_per_spell_discarded": damage_per_spell_discarded,
		"random_spell_discard": random_spell_discard,
		"choose_spell_from_deck": choose_spell_from_deck,
		"all_players_shield": all_players_shield,
		"target_stamina_gain": target_stamina_gain,
		"remove_target_debuffs": remove_target_debuffs,
		"aura_cost": aura_cost,
		"aura_cost_all": aura_cost_all,
		"aura_gain": aura_gain,
		"damage_per_aura_spent": damage_per_aura_spent,
		"grants_played_twice": grants_played_twice,
		"grants_invincible": grants_invincible,
		"damage_is_d6": damage_is_d6,
		"all_players_draw": all_players_draw,
		"summon_minion_tag": summon_minion_tag,
		"summon_count": summon_count,
		"target_player_name": target_player_name,
		"all_allies_shield": all_allies_shield,
		"remove_self_debuffs": remove_self_debuffs,
		"remove_target_buffs": remove_target_buffs,
		"caster_bleed": caster_bleed,
		"caster_feeble": caster_feeble,
		"exhausts": exhausts
	}

static func deserialize(data: Dictionary) -> Card:
	var card = Card.new()
	card.card_name = data.card_name
	card.description = data.description
	card.card_type = data.card_type as CardType
	card.target_type = data.target_type as TargetType
	card.stamina_cost = data.get("stamina_cost", data.get("energy_cost", 0))  # Support old saves with energy_cost
	card.damage = data.damage
	card.heal_amount = data.heal_amount
	card.heal_per_wet_removed = data.get("heal_per_wet_removed", 0)
	card.shield_amount = data.shield_amount
	card.draw_cards = data.draw_cards
	card.is_upgraded = data.is_upgraded
	card.apply_poison = data.apply_poison
	card.apply_burn = data.apply_burn
	card.apply_weakness = data.apply_weakness
	card.apply_vulnerable = data.apply_vulnerable
	card.apply_strength = data.apply_strength
	card.apply_armor = data.apply_armor
	card.apply_rested = data.get("apply_rested", 0)
	card.apply_invigorated = data.get("apply_invigorated", 0)
	card.apply_damage_plus = data.get("apply_damage_plus", 0)
	card.apply_fatigued = data.get("apply_fatigued", 0)
	card.apply_exhausted = data.get("apply_exhausted", 0)
	card.apply_decay = data.get("apply_decay", 0)
	card.apply_hinder = data.get("apply_hinder", 0)
	card.apply_scared = data.get("apply_scared", 0)
	card.apply_venom = data.get("apply_venom", 0)
	card.apply_bleed = data.get("apply_bleed", 0)
	card.apply_feeble = data.get("apply_feeble", 0)
	card.apply_burden = data.get("apply_burden", 0)
	card.apply_dissolve = data.get("apply_dissolve", 0)
	card.apply_doll_dissolve = data.get("apply_doll_dissolve", 0)
	card.apply_doll_suffering = data.get("apply_doll_suffering", 0)
	card.apply_doll_burden = data.get("apply_doll_burden", 0)
	card.apply_random_doll = data.get("apply_random_doll", 0)
	card.exhaust_target_deck = data.get("exhaust_target_deck", 0)
	card.piercing = data.piercing
	card.lifesteal = data.lifesteal
	card.multi_hit = data.multi_hit
	card.aoe_damage = data.aoe_damage
	card.plays_immediately = data.get("plays_immediately", false)  # Default to false for old cards
	card.generate_cards = data.generate_cards
	card.scry_amount = data.scry_amount
	card.queue_instance_id = data.get("queue_instance_id", 0)  # Default to 0 for old cards
	card.has_v2 = data.get("has_v2", false)  # Default to false for old cards
	card.v2_card_id = data.get("v2_card_id", "")
	card.context_sensitive_v2 = data.get("context_sensitive_v2", false)
	card.is_delayed_damage = data.get("is_delayed_damage", false)
	card.delay_condition = data.get("delay_condition", "")
	card.delayed_damage_amount = data.get("delayed_damage_amount", 0)
	card.grants_card_retain = data.get("grants_card_retain", false)
	card.swaps_enemy_target = data.get("swaps_enemy_target", false)
	card.reveals_boss_intent = data.get("reveals_boss_intent", false)
	card.caster_discards_random = data.get("caster_discards_random", 0)
	card.bonus_damage_if_wounded = data.get("bonus_damage_if_wounded", 0)
	card.bonus_damage_per_debuff = data.get("bonus_damage_per_debuff", 0)
	card.damage_threshold_check = data.get("damage_threshold_check", 0)
	card.damage_threshold_modifier = data.get("damage_threshold_modifier", 0)
	card.stamina_gain = data.get("stamina_gain", 0)
	card.element = data.get("element", ElementType.NONE) as ElementType
	card.ingredient_list = data.get("ingredient_list", [])
	card.is_alc = data.get("is_alc", false)
	card.apply_wet = data.get("apply_wet", 0)
	card.bonus_damage_per_wet = data.get("bonus_damage_per_wet", 0)
	card.remove_all_wet = data.get("remove_all_wet", false)
	card.apply_ring_of_fire = data.get("apply_ring_of_fire", 0)
	card.discard_spell_requirement = data.get("discard_spell_requirement", 0)
	card.min_spell_discard = data.get("min_spell_discard", 0)
	card.max_spell_discard = data.get("max_spell_discard", 0)
	card.discard_all_spells = data.get("discard_all_spells", false)
	card.damage_per_spell_discarded = data.get("damage_per_spell_discarded", 0)
	card.random_spell_discard = data.get("random_spell_discard", false)
	card.choose_spell_from_deck = data.get("choose_spell_from_deck", 0)
	card.all_players_shield = data.get("all_players_shield", 0)
	card.target_stamina_gain = data.get("target_stamina_gain", 0)
	card.remove_target_debuffs = data.get("remove_target_debuffs", 0)
	card.aura_cost = data.get("aura_cost", 0)
	card.aura_cost_all = data.get("aura_cost_all", false)
	card.aura_gain = data.get("aura_gain", 0)
	card.damage_per_aura_spent = data.get("damage_per_aura_spent", 0)
	card.grants_played_twice = data.get("grants_played_twice", false)
	card.grants_invincible = data.get("grants_invincible", false)
	card.damage_is_d6 = data.get("damage_is_d6", false)
	card.all_players_draw = data.get("all_players_draw", 0)
	card.summon_minion_tag = data.get("summon_minion_tag", "")
	card.summon_count = data.get("summon_count", 0)
	card.target_player_name = data.get("target_player_name", "")
	card.all_allies_shield = data.get("all_allies_shield", 0)
	card.remove_self_debuffs = data.get("remove_self_debuffs", false)
	card.remove_target_buffs = data.get("remove_target_buffs", false)
	card.caster_bleed = data.get("caster_bleed", 0)
	card.caster_feeble = data.get("caster_feeble", 0)
	card.exhausts = data.get("exhausts", false)
	return card
