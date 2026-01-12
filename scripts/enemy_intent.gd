class_name EnemyIntent
extends RefCounted

## Enemy Intent - represents what an enemy plans to do next turn
## Calculated at round start to give players tactical information

enum IntentType {
	ATTACK,   # ⚔ Red - dealing damage
	SHIELD,   # 🛡 Cyan - gaining shield/armor
	DEBUFF,   # 🌀 Purple - applying negative effects
	BUFF,     # 🔥 Orange - buffing themselves
	MIXED     # Multiple intent types combined
}

# Core intent data
var intent_type: IntentType = IntentType.ATTACK
var damage_amount: int = 0
var shield_amount: int = 0

# Target information
var targets: Array[int] = []  # Player indices (-1 = random single target)
var is_aoe: bool = false

# Status effects being applied
var debuffs: Dictionary = {}  # effect_name -> amount (e.g., {"poison": 3, "weakness": 2})
var buffs: Dictionary = {}    # effect_name -> amount (e.g., {"strength": 2})

# Which enemy this intent belongs to
var enemy_index: int = -1

## Determines the primary intent type based on aggregated effects
func calculate_intent_type() -> void:
	var has_damage = damage_amount > 0
	var has_shield = shield_amount > 0
	var has_debuff = not debuffs.is_empty()
	var has_buff = not buffs.is_empty()

	var count = 0
	if has_damage: count += 1
	if has_shield: count += 1
	if has_debuff: count += 1
	if has_buff: count += 1

	if count > 1:
		intent_type = IntentType.MIXED
	elif has_damage:
		intent_type = IntentType.ATTACK
	elif has_shield:
		intent_type = IntentType.SHIELD
	elif has_debuff:
		intent_type = IntentType.DEBUFF
	elif has_buff:
		intent_type = IntentType.BUFF
	else:
		# Default to attack if nothing detected (shouldn't happen)
		intent_type = IntentType.ATTACK

## Returns the icon character for this intent type
func get_icon() -> String:
	match intent_type:
		IntentType.ATTACK:
			return "⚔"
		IntentType.SHIELD:
			return "🛡"
		IntentType.DEBUFF:
			return "🌀"
		IntentType.BUFF:
			return "🔥"
		IntentType.MIXED:
			return "⚔"  # Show attack icon for mixed (damage is most important to know)
	return "?"

## Returns the color for this intent type
func get_color() -> Color:
	match intent_type:
		IntentType.ATTACK:
			return Color.RED
		IntentType.SHIELD:
			return Color.CYAN
		IntentType.DEBUFF:
			return Color.PURPLE
		IntentType.BUFF:
			return Color.ORANGE
		IntentType.MIXED:
			return Color.RED  # Red for mixed since damage is priority
	return Color.WHITE

## Serialize for network transmission
func serialize() -> Dictionary:
	return {
		"intent_type": intent_type,
		"damage_amount": damage_amount,
		"shield_amount": shield_amount,
		"targets": targets,
		"is_aoe": is_aoe,
		"debuffs": debuffs,
		"buffs": buffs,
		"enemy_index": enemy_index
	}

## Deserialize from network data
static func deserialize(data: Dictionary) -> EnemyIntent:
	var intent = EnemyIntent.new()
	intent.intent_type = data.get("intent_type", IntentType.ATTACK) as IntentType
	intent.damage_amount = data.get("damage_amount", 0)
	intent.shield_amount = data.get("shield_amount", 0)
	intent.is_aoe = data.get("is_aoe", false)
	intent.debuffs = data.get("debuffs", {})
	intent.buffs = data.get("buffs", {})
	intent.enemy_index = data.get("enemy_index", -1)

	# Handle targets array - needs type conversion
	var raw_targets = data.get("targets", [])
	intent.targets.clear()  # Use clear() since targets is already typed Array[int]
	for t in raw_targets:
		intent.targets.append(int(t))

	return intent

## Get a display string for debugging
func get_debug_string() -> String:
	var parts = []
	parts.append("Enemy %d: %s" % [enemy_index, IntentType.keys()[intent_type]])
	if damage_amount > 0:
		parts.append("DMG:%d" % damage_amount)
	if shield_amount > 0:
		parts.append("SHD:%d" % shield_amount)
	if not debuffs.is_empty():
		parts.append("Debuffs:%s" % str(debuffs))
	if not buffs.is_empty():
		parts.append("Buffs:%s" % str(buffs))
	parts.append("Targets:%s%s" % [str(targets), " (AOE)" if is_aoe else ""])
	return " | ".join(parts)
