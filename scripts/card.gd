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
	SINGLE_ENEMY,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	ANY
}

@export var card_name: String
@export var description: String
@export var card_type: CardType
@export var target_type: TargetType
@export var stamina_cost: int
@export var damage: int = 0
@export var heal_amount: int = 0
@export var shield_amount: int = 0
@export var draw_cards: int = 0
@export var is_upgraded: bool = false

# v2 Card System - allows player to choose between two effects during play
@export var has_v2: bool = false
var v2_card: Card = null  # Reference to the v2 variant (set at runtime, not exported)

# Status effects
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

# Runtime-only unique ID for queued card instances (invisible to player, not saved to disk)
# Used to distinguish between identical cards in the queue (e.g., two Fire Strike cards)
var queue_instance_id: int = 0

func get_full_description() -> String:
	var desc = description + "\n\n"

	if damage > 0:
		desc += "Deal %d damage" % damage
		if multi_hit > 1:
			desc += " %d times" % multi_hit
		if piercing:
			desc += " (Piercing)"
		desc += "\n"

	if heal_amount > 0:
		desc += "Heal %d HP\n" % heal_amount

	if shield_amount > 0:
		desc += "Gain %d Shield\n" % shield_amount

	if draw_cards > 0:
		desc += "Draw %d card(s)\n" % draw_cards

	if apply_poison > 0:
		desc += "Apply %d Poison\n" % apply_poison

	if apply_burn > 0:
		desc += "Apply %d Burn\n" % apply_burn

	if apply_strength > 0:
		desc += "Gain %d Strength\n" % apply_strength

	if apply_vulnerable > 0:
		desc += "Apply %d Vulnerable\n" % apply_vulnerable

	if apply_rested > 0:
		desc += "Gain %d Rested\n" % apply_rested

	if apply_invigorated > 0:
		desc += "Gain %d Invigorated\n" % apply_invigorated

	if apply_damage_plus > 0:
		desc += "Gain %d Damage Plus\n" % apply_damage_plus

	if apply_fatigued > 0:
		desc += "Apply %d Fatigued\n" % apply_fatigued

	if apply_exhausted > 0:
		desc += "Apply Exhausted (cannot play more cards)\n"

	if apply_decay > 0:
		desc += "Apply Decay (cannot heal this turn)\n"

	return desc

func can_afford(current_stamina: int) -> bool:
	return current_stamina >= stamina_cost

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
		"piercing": piercing,
		"lifesteal": lifesteal,
		"multi_hit": multi_hit,
		"aoe_damage": aoe_damage,
		"plays_immediately": plays_immediately,
		"generate_cards": generate_cards,
		"scry_amount": scry_amount,
		"queue_instance_id": queue_instance_id,
		"has_v2": has_v2,
		"is_delayed_damage": is_delayed_damage,
		"delay_condition": delay_condition,
		"delayed_damage_amount": delayed_damage_amount,
		"grants_card_retain": grants_card_retain,
		"swaps_enemy_target": swaps_enemy_target,
		"reveals_boss_intent": reveals_boss_intent
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
	card.piercing = data.piercing
	card.lifesteal = data.lifesteal
	card.multi_hit = data.multi_hit
	card.aoe_damage = data.aoe_damage
	card.plays_immediately = data.get("plays_immediately", false)  # Default to false for old cards
	card.generate_cards = data.generate_cards
	card.scry_amount = data.scry_amount
	card.queue_instance_id = data.get("queue_instance_id", 0)  # Default to 0 for old cards
	card.has_v2 = data.get("has_v2", false)  # Default to false for old cards
	card.is_delayed_damage = data.get("is_delayed_damage", false)
	card.delay_condition = data.get("delay_condition", "")
	card.delayed_damage_amount = data.get("delayed_damage_amount", 0)
	card.grants_card_retain = data.get("grants_card_retain", false)
	card.swaps_enemy_target = data.get("swaps_enemy_target", false)
	card.reveals_boss_intent = data.get("reveals_boss_intent", false)
	return card
