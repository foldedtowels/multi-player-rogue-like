extends RefCounted
class_name EnemyAI

## Enemy AI Module
## Handles all enemy intent calculation and target selection.
## Extracted from GameManager to improve maintainability.

# References injected by GameManager
var players: Array[Character]
var enemies: Array[Character]
var rng: RandomNumberGenerator
var ccw_target_index: int = -1

# Signals for GameManager to forward
signal boss_intent_revealed(next_turn_intents: Dictionary)


## Calculate intents for all alive enemies
## Returns: Dictionary[enemy_index, EnemyIntent]
func calculate_all_intents() -> Dictionary:
	var intents: Dictionary = {}

	for i in range(enemies.size()):
		var enemy = enemies[i]
		if not enemy.is_alive():
			continue

		var intent = calculate_single_intent(enemy, i)
		intents[i] = intent

	return intents


## Calculate intents using locked hands/targets (for Hunter's Instinct follow-up)
func calculate_intents_from_locked(locked_enemy_hands: Dictionary, locked_card_targets: Dictionary) -> Dictionary:
	var intents: Dictionary = {}

	for enemy_idx in locked_card_targets:
		if enemy_idx >= enemies.size():
			continue
		var enemy = enemies[enemy_idx]
		if not enemy.is_alive():
			continue

		# Enemy hand was already set from locked_enemy_hands
		var hand: Array[Card] = []
		for card in enemy.hand:
			hand.append(card)
		var targets = locked_card_targets[enemy_idx]

		# Build intent with locked cards/targets but CURRENT damage calculation
		var intent = _build_intent_from_locked(enemy, enemy_idx, hand, targets)
		intents[enemy_idx] = intent

	return intents


## Calculate intent for a single enemy
func calculate_single_intent(enemy: Character, enemy_idx: int) -> EnemyIntent:
	var intent = EnemyIntent.new()
	intent.enemy_index = enemy_idx

	# Use actual hand (from pre-draw at round start)
	var hand = get_enemy_hand(enemy)

	# Pre-select which cards enemy will play (respects cards_per_turn limit)
	var simulated_stamina = enemy.max_stamina
	var cards_played = 0
	var max_cards = enemy.main_deck_cards_per_turn  # -1 = unlimited

	for card in hand:
		# Check card limit
		if max_cards > 0 and cards_played >= max_cards:
			break

		if card.stamina_cost > simulated_stamina:
			continue

		simulated_stamina -= card.stamina_cost
		cards_played += 1

		# Determine target for this card NOW (pre-selection)
		var target_index = determine_card_target(enemy, card)

		# Store the card and its target for later execution
		intent.cards_to_play.append({
			"card": card,
			"target_index": target_index,
			"is_special": false
		})

		# Aggregate effects for intent display
		_aggregate_card_effects(intent, card, enemy, target_index)

	# Handle special deck (based on special_chance)
	if enemy.special_deck.size() > 0 and rng.randf() < enemy.special_chance:
		var special_card = enemy.special_deck[rng.randi() % enemy.special_deck.size()].duplicate()
		var special_target_index = determine_card_target(enemy, special_card)

		intent.cards_to_play.append({
			"card": special_card,
			"target_index": special_target_index,
			"is_special": true
		})

		_aggregate_card_effects(intent, special_card, enemy, special_target_index)

	# Calculate intent type based on aggregated effects
	intent.calculate_intent_type()

	return intent


## Calculate intent using a specific hand (for Hunter's Instinct preview)
func calculate_intent_with_hand(enemy: Character, enemy_idx: int, hand: Array[Card]) -> EnemyIntent:
	var intent = EnemyIntent.new()
	intent.enemy_index = enemy_idx

	var simulated_stamina = enemy.max_stamina
	var cards_played = 0
	var max_cards = enemy.main_deck_cards_per_turn

	for card in hand:
		if max_cards > 0 and cards_played >= max_cards:
			break

		if card.stamina_cost > simulated_stamina:
			continue

		simulated_stamina -= card.stamina_cost
		cards_played += 1

		var target_index = determine_card_target(enemy, card)

		intent.cards_to_play.append({
			"card": card,
			"target_index": target_index,
			"is_special": false
		})

		_aggregate_card_effects(intent, card, enemy, target_index)

	# Handle special deck
	if enemy.special_deck.size() > 0 and rng.randf() < enemy.special_chance:
		var special_card = enemy.special_deck[rng.randi() % enemy.special_deck.size()].duplicate()
		var special_target_index = determine_card_target(enemy, special_card)

		intent.cards_to_play.append({
			"card": special_card,
			"target_index": special_target_index,
			"is_special": true
		})

		_aggregate_card_effects(intent, special_card, enemy, special_target_index)

	intent.calculate_intent_type()
	return intent


## Determine target index for enemy card (pre-selection at round start)
## Returns: -2 = self, -1 = AOE, 0+ = player index
func determine_card_target(enemy: Character, card: Card) -> int:
	match card.target_type:
		Card.TargetType.SELF:
			return -2  # Special marker for self-target

		Card.TargetType.ALL_ENEMIES:
			return -1  # Special marker for AOE

		Card.TargetType.CCW_PLAYER:
			var alive = players.filter(func(p): return p.is_alive())
			if ccw_target_index >= 0 and ccw_target_index < alive.size():
				return players.find(alive[ccw_target_index])
			return 0

		Card.TargetType.HIGHEST_HP:
			var alive = players.filter(func(p): return p.is_alive())
			if alive.size() > 0:
				alive.sort_custom(func(a, b): return a.current_health > b.current_health)
				return players.find(alive[0])
			return 0

		Card.TargetType.LOWEST_HP:
			var alive = players.filter(func(p): return p.is_alive())
			if alive.size() > 0:
				alive.sort_custom(func(a, b): return a.current_health < b.current_health)
				return players.find(alive[0])
			return 0

		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			var alive = players.filter(func(p): return p.is_alive())
			if alive.size() > 0:
				var target = alive[rng.randi() % alive.size()]
				return players.find(target)
			return 0

		_:
			return 0  # Default to first player


## Get enemy's current hand (or simulate if empty)
func get_enemy_hand(enemy: Character) -> Array[Card]:
	if enemy.hand.size() > 0:
		return enemy.hand.duplicate()

	# Fallback: simulate drawing if no hand
	var hand: Array[Card] = []
	var temp_deck = enemy.deck.duplicate()

	if temp_deck.size() < 5:
		var temp_discard = enemy.discard_pile.duplicate()
		temp_discard.shuffle()
		temp_deck.append_array(temp_discard)

	for j in range(min(5, temp_deck.size())):
		hand.append(temp_deck[j])

	return hand


## Simulate what cards an enemy would draw next turn (for Hunter's Instinct)
func simulate_next_turn_hand(enemy: Character) -> Array[Card]:
	var hand: Array[Card] = []

	# Create temporary deck combining deck + discard
	var temp_deck: Array[Card] = []
	temp_deck.append_array(enemy.deck.duplicate())

	# Current hand cards will go to discard, then shuffle back
	var temp_discard: Array[Card] = []
	temp_discard.append_array(enemy.discard_pile.duplicate())
	temp_discard.append_array(enemy.hand.duplicate())

	if temp_deck.size() < 5:
		temp_discard.shuffle()
		temp_deck.append_array(temp_discard)

	for j in range(min(5, temp_deck.size())):
		hand.append(temp_deck[j])

	return hand


## Reveal enemies' next turn intents (Hunter's Instinct)
## Returns: {intents, hands, targets} for locking
func reveal_next_turn_intents() -> Dictionary:
	var next_turn_intents: Dictionary = {}
	var next_turn_hands: Dictionary = {}
	var next_turn_targets: Dictionary = {}

	for i in range(enemies.size()):
		var enemy = enemies[i]
		if not enemy.is_alive():
			continue

		# Simulate what cards enemy would draw next turn
		var simulated_hand = simulate_next_turn_hand(enemy)
		next_turn_hands[i] = simulated_hand.duplicate()

		# Calculate intent with that simulated hand
		var intent = calculate_intent_with_hand(enemy, i, simulated_hand)
		next_turn_intents[i] = intent

		# Store target selections for locking
		var targets: Array = []
		for card_info in intent.cards_to_play:
			targets.append({
				"target_index": card_info.target_index,
				"is_special": card_info.get("is_special", false)
			})
		next_turn_targets[i] = targets

	boss_intent_revealed.emit(next_turn_intents)

	return {
		"intents": next_turn_intents,
		"hands": next_turn_hands,
		"targets": next_turn_targets
	}


## Build intent from locked hands/targets, recalculating damage with current stats
func _build_intent_from_locked(enemy: Character, enemy_idx: int, hand: Array[Card], locked_targets: Array) -> EnemyIntent:
	var intent = EnemyIntent.new()
	intent.enemy_index = enemy_idx

	var simulated_stamina = enemy.max_stamina
	var card_idx = 0
	var cards_played = 0
	var max_cards = enemy.main_deck_cards_per_turn

	for card in hand:
		if max_cards > 0 and cards_played >= max_cards:
			break

		if card.stamina_cost > simulated_stamina:
			card_idx += 1
			continue

		simulated_stamina -= card.stamina_cost
		cards_played += 1

		# Get locked target or determine dynamically (fallback)
		var target_index = -1
		var is_special = false

		if card_idx < locked_targets.size() and not locked_targets[card_idx].get("is_special", false):
			target_index = locked_targets[card_idx].target_index
			is_special = false
		else:
			target_index = determine_card_target(enemy, card)

		intent.cards_to_play.append({
			"card": card,
			"target_index": target_index,
			"is_special": is_special
		})

		# Aggregate effects - RECALCULATES damage with CURRENT enemy stats
		_aggregate_card_effects(intent, card, enemy, target_index)
		card_idx += 1

	# Handle special cards from locked_targets
	for target_info in locked_targets:
		if target_info.get("is_special", false) and enemy.special_deck.size() > 0:
			var special_card = enemy.special_deck[rng.randi() % enemy.special_deck.size()].duplicate()
			intent.cards_to_play.append({
				"card": special_card,
				"target_index": target_info.target_index,
				"is_special": true
			})
			_aggregate_card_effects(intent, special_card, enemy, target_info.target_index)

	intent.calculate_intent_type()
	return intent


## Aggregate card effects into intent for display
func _aggregate_card_effects(intent: EnemyIntent, card: Card, enemy: Character, target_index: int = -1):
	# Track targets based on pre-selected target_index
	if target_index == -2:
		pass  # Self-target - don't add to player targets
	elif target_index == -1:
		# AOE - targets all players
		intent.is_aoe = true
		for i in range(players.size()):
			if players[i].is_alive() and i not in intent.targets:
				intent.targets.append(i)
	elif target_index >= 0:
		if target_index not in intent.targets:
			intent.targets.append(target_index)

	# Calculate damage using unified formula
	if card.damage > 0:
		var total_damage = CardEffectEngine.calculate_damage(card, enemy, null)
		total_damage *= card.multi_hit
		intent.damage_amount += total_damage

		# Track per-target damage for accurate UI display
		if target_index == -2:
			pass  # Self-target - no damage to players
		elif target_index == -1:
			# AOE - add damage to all alive players
			for i in range(players.size()):
				if players[i].is_alive():
					if not intent.damage_per_target.has(i):
						intent.damage_per_target[i] = 0
					intent.damage_per_target[i] += total_damage
		elif target_index >= 0:
			if not intent.damage_per_target.has(target_index):
				intent.damage_per_target[target_index] = 0
			intent.damage_per_target[target_index] += total_damage

	# Shield
	if card.shield_amount > 0:
		intent.shield_amount += card.shield_amount

	# Debuffs applied to targets
	if card.apply_poison > 0:
		intent.debuffs["poison"] = intent.debuffs.get("poison", 0) + card.apply_poison
	if card.apply_burn > 0:
		intent.debuffs["burn"] = intent.debuffs.get("burn", 0) + card.apply_burn
	if card.apply_weakness > 0:
		intent.debuffs["weakness"] = intent.debuffs.get("weakness", 0) + card.apply_weakness
	if card.apply_vulnerable > 0:
		intent.debuffs["vulnerable"] = intent.debuffs.get("vulnerable", 0) + card.apply_vulnerable
	if card.apply_fatigued > 0:
		intent.debuffs["fatigued"] = intent.debuffs.get("fatigued", 0) + card.apply_fatigued
	if card.apply_hinder > 0:
		intent.debuffs["hinder"] = intent.debuffs.get("hinder", 0) + card.apply_hinder
	if card.apply_scared > 0:
		intent.debuffs["scared"] = intent.debuffs.get("scared", 0) + card.apply_scared

	# Buffs (self-applied by enemy)
	if card.apply_strength > 0:
		intent.buffs["strength"] = intent.buffs.get("strength", 0) + card.apply_strength
	if card.apply_armor > 0:
		intent.buffs["armor"] = intent.buffs.get("armor", 0) + card.apply_armor
