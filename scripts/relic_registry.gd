extends Node
## RelicRegistry is an autoload - access via RelicRegistry global

## Central registry for all relics in the game.
## Relics provide persistent passive bonuses that trigger at various points.
## Follows the StatusEffectRegistry pattern for consistency.
##
## ============================================
## RELIC TRIGGER TYPES
## ============================================
## ON_PICKUP: Immediate when acquired (e.g., Coffee Soda +10 max HP)
## FIGHT_START: Beginning of combat (e.g., Nipple Protectors +2 armor)
## TURN_START: Each turn start (e.g., BackPack draw 1)
## TURN_END: Each turn end (e.g., Radiating Apple -1 HP)
## ON_DAMAGE_DEALT: After dealing damage (e.g., Second Wind)
## ON_CARD_PLAYED: After playing a card (e.g., Rage Meter)
## ON_HEAL: When healing occurs (e.g., Grandma's Cookies)
## ON_DEBUFF_APPLIED: When debuff applied to enemy (e.g., Water Stone)
## ON_BREW: Kevin's brew action (e.g., Wooden Cauldron)
## FIGHT_END: After victory (e.g., Restorative Locket)
## PASSIVE_MODIFIER: Always active during calculations
##
## ============================================
## HOW TO ADD A NEW RELIC
## ============================================
## 1. Add relic to RELICS dictionary below
## 2. Add trigger logic in the appropriate apply_* function
## 3. For PASSIVE_MODIFIER relics, add to calculate_* functions
## ============================================

enum TriggerType {
	ON_PICKUP,        # Immediate when acquired
	FIGHT_START,      # Beginning of combat
	TURN_START,       # Each turn start
	TURN_END,         # Each turn end
	ON_DAMAGE_DEALT,  # After dealing damage
	ON_CARD_PLAYED,   # After playing a card
	ON_HEAL,          # When healing occurs
	ON_DEBUFF_APPLIED,# When debuff applied to enemy
	ON_BREW,          # Kevin's brew action
	FIGHT_END,        # After victory
	PASSIVE_MODIFIER, # Always active during calculations
	ACTIVE_USE        # Player-activated with click (e.g., Revive Relic)
}

enum RelicCategory { UNIVERSAL, KEVIN, FABIO, ENRIQUE }

const RELICS: Dictionary = {
	# ============================================
	# UNIVERSAL RELICS (12)
	# ============================================
	"backpack": {
		"display_name": "BackPack",
		"description": "Draw 1 extra card at turn start",
		"trigger": TriggerType.TURN_START,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"draw_cards": 1}
	},
	"second_wind": {
		"display_name": "Second Wind",
		"description": "Gain 1 stamina when dealing 10+ damage",
		"trigger": TriggerType.ON_DAMAGE_DEALT,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"damage_threshold": 10, "gain_stamina": 1}
	},
	"copying_machine": {
		"display_name": "Copying Machine",
		"description": "Multi-hit cards attack one additional time",
		"trigger": TriggerType.PASSIVE_MODIFIER,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"extra_multi_hit": 1}
	},
	"cracked_gem": {
		"display_name": "Cracked Gem",
		"description": "Gain 1 stamina on first turn only",
		"trigger": TriggerType.TURN_START,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"gain_stamina": 1, "first_turn_only": true}
	},
	"restorative_locket": {
		"display_name": "Restorative Locket",
		"description": "Heal 10 after victory",
		"trigger": TriggerType.FIGHT_END,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"heal": 10}
	},
	"nipple_protectors": {
		"display_name": "Nipple Protectors",
		"description": "Gain 2 armor at fight start",
		"trigger": TriggerType.FIGHT_START,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"apply_armor": 2}
	},
	"grandmas_cookies": {
		"display_name": "Grandma's Cookies",
		"description": "+5 to all healing",
		"trigger": TriggerType.ON_HEAL,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"heal_bonus": 5}
	},
	"coffee_soda": {
		"display_name": "Coffee Soda",
		"description": "+10 max HP and heal 10 on pickup",
		"trigger": TriggerType.ON_PICKUP,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"max_hp_bonus": 10, "heal": 10}
	},
	"power_ring": {
		"display_name": "Power Ring",
		"description": "Gain 1 Strength at fight start",
		"trigger": TriggerType.FIGHT_START,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"apply_strength": 1}
	},
	"rage_meter": {
		"display_name": "Rage Meter",
		"description": "Gain 1 stamina on every 3rd card played per turn",
		"trigger": TriggerType.ON_CARD_PLAYED,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"cards_to_trigger": 3, "gain_stamina": 1}
	},
	"blood_crystal": {
		"display_name": "Blood Crystal",
		"description": "+1 stamina at turn start, start fight with 4 bleed",
		"trigger": TriggerType.TURN_START,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"gain_stamina": 1},
		"fight_start_effect": {"apply_bleed": 4}
	},
	"radiating_apple": {
		"display_name": "Radiating Apple",
		"description": "+1 stamina at turn start, take 1 damage at turn end",
		"trigger": TriggerType.TURN_START,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"gain_stamina": 1},
		"turn_end_effect": {"take_damage": 1}
	},
	"revive_relic": {
		"display_name": "Revive Relic",
		"description": "Click to revive 1 dead teammate (once per fight)",
		"trigger": TriggerType.ACTIVE_USE,
		"category": RelicCategory.UNIVERSAL,
		"effect": {"revive_teammate": true, "uses_per_fight": 1}
	},

	# ============================================
	# KEVIN RELICS (3)
	# ============================================
	"water_stone": {
		"display_name": "Water Stone",
		"description": "When enemy gains Wet, gain additional Wet",
		"trigger": TriggerType.ON_DEBUFF_APPLIED,
		"category": RelicCategory.KEVIN,
		"effect": {"double_wet": true}
	},
	"familiar_bracelet": {
		"display_name": "Familiar Bracelet",
		"description": "Non-spell, non-alc cards deal +2 damage",
		"trigger": TriggerType.PASSIVE_MODIFIER,
		"category": RelicCategory.KEVIN,
		"effect": {"damage_bonus": 2, "exclude_types": ["SPELL", "ALC"]}
	},
	"wooden_cauldron": {
		"display_name": "Wooden Cauldron",
		"description": "Draw 1 card after brewing",
		"trigger": TriggerType.ON_BREW,
		"category": RelicCategory.KEVIN,
		"effect": {"draw_cards": 1}
	},

	# ============================================
	# FABIO RELICS (3)
	# ============================================
	"brass_knuckles": {
		"display_name": "Brass Knuckles",
		"description": "Gain 1 Strength at fight start",
		"trigger": TriggerType.FIGHT_START,
		"category": RelicCategory.FABIO,
		"effect": {"apply_strength": 1}
	},
	"dragon_scale_cream": {
		"display_name": "Dragon Scale Cream",
		"description": "Gain 2 Armor at fight start",
		"trigger": TriggerType.FIGHT_START,
		"category": RelicCategory.FABIO,
		"effect": {"apply_armor": 2}
	},
	"forearm_trainer": {
		"display_name": "Forearm Trainer",
		"description": "2+ stamina attacks cost 1 less",
		"trigger": TriggerType.PASSIVE_MODIFIER,
		"category": RelicCategory.FABIO,
		"effect": {"cost_reduction": 1, "min_cost": 2, "card_type": "ATTACK"}
	},

	# ============================================
	# ENRIQUE RELICS (3)
	# ============================================
	"prayer_book": {
		"display_name": "Prayer Book",
		"description": "+4 aura at fight start",
		"trigger": TriggerType.FIGHT_START,
		"category": RelicCategory.ENRIQUE,
		"effect": {"apply_aura": 4}
	},
	"gentle_hands": {
		"display_name": "Gentle Hands",
		"description": "+5 healing to allies",
		"trigger": TriggerType.ON_HEAL,
		"category": RelicCategory.ENRIQUE,
		"effect": {"ally_heal_bonus": 5}
	},
	"shining_feather": {
		"display_name": "Shining Feather",
		"description": "If 5+ aura at turn end, gain 5 shield",
		"trigger": TriggerType.TURN_END,
		"category": RelicCategory.ENRIQUE,
		"effect": {"aura_threshold": 5, "gain_shield": 5}
	},
	"electrified_idol": {
		"display_name": "Electrified Idol",
		"description": "Deal 5 damage to random enemy when healing ally",
		"trigger": TriggerType.ON_HEAL,
		"category": RelicCategory.ENRIQUE,
		"effect": {"damage_random_enemy": 5, "ally_only": true}
	}
}


# ============================================
# STATIC ACCESSORS
# ============================================

static func get_relic(relic_id: String) -> Dictionary:
	return RELICS.get(relic_id, {})


static func get_all_relic_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in RELICS.keys():
		ids.append(id)
	return ids


static func get_relics_for_category(category: RelicCategory) -> Array[String]:
	var ids: Array[String] = []
	for id in RELICS.keys():
		if RELICS[id].category == category:
			ids.append(id)
	return ids


static func get_display_name(relic_id: String) -> String:
	return RELICS.get(relic_id, {}).get("display_name", relic_id.capitalize())


static func get_description(relic_id: String) -> String:
	return RELICS.get(relic_id, {}).get("description", "")


static func is_active_use_relic(relic_id: String) -> bool:
	var relic = get_relic(relic_id)
	return relic.get("trigger") == TriggerType.ACTIVE_USE


static func get_uses_per_fight(relic_id: String) -> int:
	var relic = get_relic(relic_id)
	return relic.get("effect", {}).get("uses_per_fight", 1)


# ============================================
# TRIGGER APPLICATION FUNCTIONS
# ============================================

## Apply ON_PICKUP relic effects (when relic is first acquired)
static func apply_on_pickup(character: Character, relic_id: String) -> void:
	var relic = get_relic(relic_id)
	if relic.is_empty():
		return

	var effect = relic.get("effect", {})

	# Max HP bonus
	if effect.has("max_hp_bonus"):
		character.max_health += effect.max_hp_bonus
		print("[RELIC] ", character.character_name, " gained +", effect.max_hp_bonus, " max HP from ", relic.display_name)

	# Immediate heal
	if effect.has("heal"):
		character.heal(effect.heal)
		print("[RELIC] ", character.character_name, " healed ", effect.heal, " from ", relic.display_name)


## Apply FIGHT_START relic effects for all players
static func apply_fight_start(players: Array[Character], game_manager: Node = null) -> void:
	for player in players:
		_apply_fight_start_for_character(player, game_manager)


## Apply FIGHT_START relic effects for a single character
static func _apply_fight_start_for_character(character: Character, game_manager: Node = null) -> void:
	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty():
			continue

		# Check for fight_start_effect (e.g., Blood Crystal applies bleed)
		var fight_start_effect = relic.get("fight_start_effect", {})
		if not fight_start_effect.is_empty():
			_apply_effect_dict(character, fight_start_effect, relic.display_name)

		# Check for main trigger FIGHT_START
		if relic.get("trigger") != TriggerType.FIGHT_START:
			continue

		var effect = relic.get("effect", {})
		_apply_effect_dict(character, effect, relic.display_name)


## Apply TURN_START relic effects
static func apply_turn_start(character: Character, round_number: int) -> void:
	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.TURN_START:
			continue

		var effect = relic.get("effect", {})

		# Check first_turn_only condition (Cracked Gem)
		if effect.get("first_turn_only", false) and round_number > 1:
			continue

		# Draw cards
		if effect.has("draw_cards"):
			character.draw_cards(effect.draw_cards)
			print("[RELIC] ", character.character_name, " drew ", effect.draw_cards, " card(s) from ", relic.display_name)

		# Gain stamina
		if effect.has("gain_stamina"):
			character.add_stamina(effect.gain_stamina)
			print("[RELIC] ", character.character_name, " gained ", effect.gain_stamina, " stamina from ", relic.display_name)


## Apply TURN_END relic effects
static func apply_turn_end(character: Character) -> void:
	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty():
			continue

		# Check for turn_end_effect (e.g., Radiating Apple)
		var turn_end_effect = relic.get("turn_end_effect", {})
		if not turn_end_effect.is_empty():
			if turn_end_effect.has("take_damage"):
				character.take_damage(turn_end_effect.take_damage, true)  # Piercing
				print("[RELIC] ", character.character_name, " took ", turn_end_effect.take_damage, " damage from ", relic.display_name)

		# Check for main trigger TURN_END
		if relic.get("trigger") != TriggerType.TURN_END:
			continue

		var effect = relic.get("effect", {})

		# Shining Feather: conditional shield
		if effect.has("aura_threshold") and effect.has("gain_shield"):
			if character.current_aura >= effect.aura_threshold:
				character.gain_shield(effect.gain_shield)
				print("[RELIC] ", character.character_name, " gained ", effect.gain_shield, " shield from ", relic.display_name, " (", character.current_aura, " aura)")


## Apply FIGHT_END relic effects
static func apply_fight_end(players: Array[Character]) -> void:
	for player in players:
		for relic_id in player.relics.keys():
			if not player.relics[relic_id]:
				continue

			var relic = get_relic(relic_id)
			if relic.is_empty() or relic.get("trigger") != TriggerType.FIGHT_END:
				continue

			var effect = relic.get("effect", {})

			# Heal
			if effect.has("heal"):
				player.heal(effect.heal)
				print("[RELIC] ", player.character_name, " healed ", effect.heal, " from ", relic.display_name)


## Apply ON_DAMAGE_DEALT relic effects
## Returns bonus stamina gained (for UI feedback)
static func apply_on_damage_dealt(character: Character, damage_dealt: int) -> int:
	var stamina_gained = 0

	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.ON_DAMAGE_DEALT:
			continue

		var effect = relic.get("effect", {})

		# Second Wind: Gain stamina when dealing 10+ damage
		if effect.has("damage_threshold") and effect.has("gain_stamina"):
			if damage_dealt >= effect.damage_threshold:
				character.add_stamina(effect.gain_stamina)
				stamina_gained += effect.gain_stamina
				print("[RELIC] ", character.character_name, " gained ", effect.gain_stamina, " stamina from ", relic.display_name, " (dealt ", damage_dealt, " damage)")

	return stamina_gained


## Apply ON_CARD_PLAYED relic effects
## Tracks cards_played_this_turn on character for Rage Meter
static func apply_on_card_played(character: Character) -> void:
	character.cards_played_this_turn += 1

	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.ON_CARD_PLAYED:
			continue

		var effect = relic.get("effect", {})

		# Rage Meter: Every Nth card grants stamina
		if effect.has("cards_to_trigger") and effect.has("gain_stamina"):
			if character.cards_played_this_turn % effect.cards_to_trigger == 0:
				character.add_stamina(effect.gain_stamina)
				print("[RELIC] ", character.character_name, " gained ", effect.gain_stamina, " stamina from ", relic.display_name, " (", character.cards_played_this_turn, " cards played)")


## Calculate heal bonus from relics (for ON_HEAL trigger)
## Returns additional heal amount to add
static func calculate_heal_bonus(caster: Character, target: Character, base_heal: int, enemies: Array[Character], rng: RandomNumberGenerator) -> int:
	var bonus = 0
	var is_ally = (target != caster)

	for relic_id in caster.relics.keys():
		if not caster.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.ON_HEAL:
			continue

		var effect = relic.get("effect", {})

		# Grandma's Cookies: +5 to all healing
		if effect.has("heal_bonus"):
			bonus += effect.heal_bonus

		# Gentle Hands: +5 healing to allies only
		if effect.has("ally_heal_bonus") and is_ally:
			bonus += effect.ally_heal_bonus

		# Electrified Idol: Deal damage to random enemy when healing ally
		if effect.has("damage_random_enemy") and is_ally:
			if not effect.get("ally_only", false) or is_ally:
				var alive_enemies = enemies.filter(func(e): return e.is_alive())
				if alive_enemies.size() > 0:
					var random_enemy = alive_enemies[rng.randi() % alive_enemies.size()]
					random_enemy.take_damage(effect.damage_random_enemy, true)  # Piercing
					print("[RELIC] ", caster.character_name, "'s ", relic.display_name, " dealt ", effect.damage_random_enemy, " damage to ", random_enemy.character_name)

	return bonus


## Apply ON_DEBUFF_APPLIED relic effects (Water Stone doubles wet)
## Returns additional wet to apply
static func apply_on_debuff_applied(caster: Character, debuff_name: String, amount: int) -> int:
	var extra = 0

	for relic_id in caster.relics.keys():
		if not caster.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.ON_DEBUFF_APPLIED:
			continue

		var effect = relic.get("effect", {})

		# Water Stone: Double wet application
		if effect.get("double_wet", false) and debuff_name == "wet":
			extra = amount  # Double it
			print("[RELIC] ", caster.character_name, "'s Water Stone doubles Wet: +", extra)

	return extra


## Apply ON_BREW relic effects (Wooden Cauldron)
static func apply_on_brew(character: Character) -> void:
	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.ON_BREW:
			continue

		var effect = relic.get("effect", {})

		# Draw cards
		if effect.has("draw_cards"):
			character.draw_cards(effect.draw_cards)
			print("[RELIC] ", character.character_name, " drew ", effect.draw_cards, " card(s) from ", relic.display_name)


# ============================================
# PASSIVE MODIFIER FUNCTIONS
# ============================================

## Calculate multi-hit bonus from relics (Copying Machine)
static func get_extra_multi_hit(character: Character) -> int:
	var extra = 0

	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.PASSIVE_MODIFIER:
			continue

		var effect = relic.get("effect", {})
		if effect.has("extra_multi_hit"):
			extra += effect.extra_multi_hit

	return extra


## Calculate damage bonus from relics (Familiar Bracelet)
## card_type is Card.CardType enum, is_spell checks element, is_alc checks is_alc flag
static func get_damage_bonus(character: Character, card: Object) -> int:
	var bonus = 0

	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.PASSIVE_MODIFIER:
			continue

		var effect = relic.get("effect", {})

		if effect.has("damage_bonus"):
			var exclude_types = effect.get("exclude_types", [])
			var excluded = false

			# Check exclusions
			if "SPELL" in exclude_types and card.element != 0:  # ElementType.NONE = 0
				excluded = true
			if "ALC" in exclude_types and card.is_alc:
				excluded = true

			if not excluded:
				bonus += effect.damage_bonus

	return bonus


## Calculate cost reduction from relics (Forearm Trainer)
static func get_cost_reduction(character: Character, card: Object) -> int:
	var reduction = 0

	for relic_id in character.relics.keys():
		if not character.relics[relic_id]:
			continue

		var relic = get_relic(relic_id)
		if relic.is_empty() or relic.get("trigger") != TriggerType.PASSIVE_MODIFIER:
			continue

		var effect = relic.get("effect", {})

		if effect.has("cost_reduction") and effect.has("min_cost"):
			# Check card type requirement
			if effect.has("card_type"):
				if effect.card_type == "ATTACK" and card.card_type != 0:  # CardType.ATTACK = 0
					continue

			# Check minimum cost requirement
			if card.stamina_cost >= effect.min_cost:
				reduction += effect.cost_reduction

	return reduction


# ============================================
# HELPER FUNCTIONS
# ============================================

## Apply effect dictionary to character
static func _apply_effect_dict(character: Character, effect: Dictionary, relic_name: String) -> void:
	# Armor
	if effect.has("apply_armor"):
		character.armor += effect.apply_armor
		print("[RELIC] ", character.character_name, " gained ", effect.apply_armor, " armor from ", relic_name)

	# Strength
	if effect.has("apply_strength"):
		character.strength += effect.apply_strength
		print("[RELIC] ", character.character_name, " gained ", effect.apply_strength, " strength from ", relic_name)

	# Bleed (self-applied, e.g., Blood Crystal)
	if effect.has("apply_bleed"):
		character.bleed += effect.apply_bleed
		print("[RELIC] ", character.character_name, " gained ", effect.apply_bleed, " bleed from ", relic_name)

	# Aura (Enrique)
	if effect.has("apply_aura"):
		character.add_aura(effect.apply_aura)
		print("[RELIC] ", character.character_name, " gained ", effect.apply_aura, " aura from ", relic_name)
