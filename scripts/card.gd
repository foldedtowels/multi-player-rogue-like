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
@export var energy_cost: int
@export var damage: int = 0
@export var heal_amount: int = 0
@export var shield_amount: int = 0
@export var draw_cards: int = 0
@export var is_upgraded: bool = false

# Status effects
@export var apply_poison: int = 0
@export var apply_burn: int = 0
@export var apply_weakness: int = 0
@export var apply_vulnerable: int = 0
@export var apply_strength: int = 0
@export var apply_armor: int = 0

# Special mechanics
@export var piercing: bool = false  # Ignores armor
@export var lifesteal: bool = false
@export var multi_hit: int = 1  # Number of times to apply effect
@export var aoe_damage: bool = false

# Card generation
@export var generate_cards: Array[String] = []  # Names of cards to add to hand
@export var scry_amount: int = 0  # Look at top X cards of deck

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

	return desc

func can_afford(current_energy: int) -> bool:
	return current_energy >= energy_cost
