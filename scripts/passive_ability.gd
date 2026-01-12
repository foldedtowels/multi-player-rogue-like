extends Resource
class_name PassiveAbility
## Resource class representing a character's passive ability
##
## Passive abilities are special powers unique to each character that trigger
## automatically or on-demand during combat.

enum TriggerType {
	ON_DEMAND,        # Player activates manually (e.g., Fabio's choice)
	START_OF_TURN,    # Triggers at start of character's turn
	END_OF_TURN,      # Triggers at end of character's turn
	ON_DAMAGE_TAKEN,  # Triggers when character takes damage
	ON_DAMAGE_DEALT,  # Triggers when character deals damage
	ON_CARD_PLAYED,   # Triggers when character plays a card
	ON_KILL           # Triggers when character kills an enemy
}

enum EffectType {
	DEAL_DAMAGE,      # Deal damage to target
	HEAL,             # Heal target
	DRAW_CARDS,       # Draw X cards
	GAIN_SHIELD,      # Gain shield
	APPLY_BUFF,       # Apply a buff/status effect
	APPLY_DEBUFF,     # Apply a debuff/status effect
	GAIN_STAMINA,     # Gain stamina
	CHOICE            # Present player with multiple choices (Fabio)
}

@export var ability_id: String = ""
@export var ability_name: String = ""
@export var description: String = ""
@export var trigger_type: TriggerType = TriggerType.ON_DEMAND
@export var effect_type: EffectType = EffectType.CHOICE
@export var uses_per_turn: int = 1  # -1 for unlimited
@export var stamina_cost: int = 0   # 0 for free

# Effect parameters (used based on effect_type)
@export var damage_amount: int = 0
@export var heal_amount: int = 0
@export var shield_amount: int = 0
@export var cards_to_draw: int = 0
@export var stamina_gain: int = 0

# For CHOICE effect_type: array of choices
# Each choice is a dictionary with keys: "name", "effect_type", "value", "target"
var choices: Array[Dictionary] = []
