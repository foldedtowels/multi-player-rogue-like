extends RefCounted
class_name CardEffectEngine

## Card Effect Engine
## Handles all card effect application with registry-based architecture.
## Extracted from GameManager to improve maintainability and testability.

# References injected by GameManager
var players: Array[Character]
var enemies: Array[Character]
var protected_by: Dictionary  # target_idx -> protector_idx
var delayed_effects: Array
var round_number: int
var card_db: Node
var rng: RandomNumberGenerator

# Signals forwarded through GameManager
signal enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_player_index: int)
signal ring_of_fire_reflected(enemy_index: int, player_name: String, damage: int)  # For floating text on enemy
signal card_retain_choice_needed(player_index: int, expires_after_round: int)
signal boss_intent_reveal_requested()
signal enemy_damage_stats_changed()  # Emitted when weakness/hinder/strength applied to enemy
signal spell_search_requested(player: Character, count: int, card_name: String)  # For Reformulate-style cards

# Status effect categories for registry-based application
const DEBUFF_EFFECTS: Array[String] = ["poison", "burn", "vulnerable", "weakness", "fatigued", "hinder", "scared", "wet"]
const BUFF_EFFECTS: Array[String] = ["strength", "armor", "rested", "invigorated", "damage_plus", "ring_of_fire"]
const SELF_DEBUFF_EFFECTS: Array[String] = ["exhausted", "decay", "fatigued"]


## Calculate damage for a card (unified formula used by both effect application and previews)
## This is the SINGLE SOURCE OF TRUTH for damage calculation.
static func calculate_damage(card: Card, caster: Character, target: Character = null) -> int:
	var total_damage = card.damage

	if card.card_type == Card.CardType.ATTACK:
		# Add attack modifiers
		total_damage += caster.strength
		total_damage += caster.damage_plus

		# Subtract attack penalties
		total_damage -= caster.weakness
		total_damage -= caster.hinder

		# Bonus damage if target is wounded (below 50% HP)
		if card.bonus_damage_if_wounded > 0 and target != null:
			var hp_percent = float(target.current_health) / float(target.max_health)
			if hp_percent < 0.5:
				total_damage += card.bonus_damage_if_wounded

		# Bonus damage per debuff stack on target
		if card.bonus_damage_per_debuff > 0 and target != null:
			var debuff_stacks = target.get_total_debuff_stacks()
			total_damage += card.bonus_damage_per_debuff * debuff_stacks

		# Bonus damage per Wet stack on target (Kevin's Alchemy)
		if card.bonus_damage_per_wet > 0 and target != null:
			total_damage += card.bonus_damage_per_wet * target.wet

		total_damage = max(0, total_damage)

	return total_damage


## Calculate total damage including multi-hit
static func calculate_total_damage(card: Card, caster: Character, target: Character = null) -> int:
	return calculate_damage(card, caster, target) * card.multi_hit


## Apply all effects from a card to target(s)
## Returns array of affected characters for state broadcasting
func apply_effects(caster: Character, card: Card, target: Character) -> Array[Character]:
	print("[CARD] ", caster.character_name, " plays ", card.card_name, " (heal:", card.heal_amount, " decay:", card.apply_decay, ")")

	# Handle spell discard mechanics BEFORE damage calculation (for Accumulation-style cards)
	var spells_discarded_count = _process_spell_discards(caster, card)

	# Resolve targets based on card target type
	var targets = _resolve_targets(caster, card, target)
	var affected: Array[Character] = []

	# Apply effects to each target
	for t in targets:
		if not t.is_alive():
			continue

		affected.append(t)

		# Determine relationship between caster and target
		var is_ally = _is_ally(caster, t)
		var is_enemy = _is_enemy(caster, t)

		# Apply effect categories
		_apply_damage(caster, card, t, is_enemy, spells_discarded_count)
		_apply_delayed_damage(caster, card, t, is_enemy)
		_apply_healing(caster, card, t, is_ally)
		_apply_shield(caster, card, t, is_ally, is_enemy)
		_apply_debuffs(caster, card, t, is_enemy)
		_apply_buffs(caster, card, t, is_ally)
		_apply_card_draw(card, t)
		_apply_card_generation(caster, card, t)
		_apply_card_retention(caster, card, t)
		_apply_enemy_target_swap(caster, card, t, is_ally)
		_apply_boss_intent_reveal(caster, card, t)
		_apply_target_stamina_gain(card, t, is_ally)
		_apply_remove_target_debuffs(card, t, is_ally)

		# Remove all wet from enemies and track affected for sync
		var wet_removed_enemies = _apply_remove_all_wet(card, t, is_enemy)
		for wet_enemy in wet_removed_enemies:
			if not affected.has(wet_enemy):
				affected.append(wet_enemy)

	# Apply caster-only effects (processed once, not per-target)
	_apply_self_debuffs(caster, card)
	_apply_caster_discard(caster, card)
	_apply_stamina_gain(caster, card)
	_apply_all_players_shield(caster, card)
	_apply_spell_search(caster, card)

	return affected


## Resolve targets based on card target type
func _resolve_targets(caster: Character, card: Card, target: Character) -> Array[Character]:
	var targets: Array[Character] = []

	match card.target_type:
		Card.TargetType.SELF:
			targets.append(caster)

		Card.TargetType.SINGLE_ALLY:
			targets.append(target)

		Card.TargetType.ALL_ALLIES:
			if enemies.has(caster):
				targets = enemies.duplicate()
			else:
				targets = players.duplicate()

		Card.TargetType.OTHER_ALLIES:
			if enemies.has(caster):
				for e in enemies:
					if e != caster:
						targets.append(e)
			else:
				for p in players:
					if p != caster:
						targets.append(p)

		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY, Card.TargetType.CCW_PLAYER, Card.TargetType.HIGHEST_HP, Card.TargetType.LOWEST_HP:
			targets.append(target)

		Card.TargetType.ALL_ENEMIES:
			if enemies.has(caster):
				targets = players.duplicate()
			else:
				targets = enemies.filter(func(e): return e.is_alive())

	return targets


func _is_ally(caster: Character, target: Character) -> bool:
	return (players.has(caster) and players.has(target)) or \
		   (enemies.has(caster) and enemies.has(target))


func _is_enemy(caster: Character, target: Character) -> bool:
	return (players.has(caster) and enemies.has(target)) or \
		   (enemies.has(caster) and players.has(target))


## Get actual target after protection redirect
func get_redirected_target(target: Character) -> Character:
	if not players.has(target):
		return target  # Only players can be protected

	var target_idx = players.find(target)
	if protected_by.has(target_idx):
		var protector_idx = protected_by[target_idx]
		if protector_idx >= 0 and protector_idx < players.size():
			var protector = players[protector_idx]
			if protector.is_alive() and protector != target:
				return protector
	return target


## Process delayed effects from previous turn (e.g., Jumping Strike)
func process_delayed_effects() -> Array[Character]:
	var affected: Array[Character] = []

	if delayed_effects.is_empty():
		return affected

	for effect in delayed_effects:
		var caster_idx = effect.caster_idx
		var target_idx = effect.target_idx
		var damage = effect.damage
		var condition = effect.condition
		var piercing = effect.get("piercing", false)

		# Validate indices
		if caster_idx < 0 or caster_idx >= players.size():
			continue
		if target_idx < 0 or target_idx >= enemies.size():
			continue

		var caster = players[caster_idx]
		var target = enemies[target_idx]

		# Check if both are still alive
		if not caster.is_alive() or not target.is_alive():
			continue

		# Check condition
		var condition_met = true
		match condition:
			"no_damage_taken":
				condition_met = caster.damage_taken_this_turn == 0
			"":
				condition_met = true

		if condition_met:
			target.take_damage(damage, piercing)
			affected.append(target)

	# Clear processed effects
	delayed_effects.clear()
	return affected


# =============================================================================
# EFFECT APPLICATION METHODS
# =============================================================================

func _apply_damage(caster: Character, card: Card, target: Character, is_enemy: bool, spells_discarded: int = 0) -> void:
	# Allow cards with damage_per_spell_discarded even if base damage is 0 (Accumulation)
	if (card.damage <= 0 and card.damage_per_spell_discarded <= 0) or not is_enemy:
		return

	# Protection redirect: enemy attacking protected player
	var damage_target = target
	if enemies.has(caster) and players.has(target):
		damage_target = get_redirected_target(target)

	for i in card.multi_hit:
		var total_damage = CardEffectEngine.calculate_damage(card, caster, damage_target)

		# Add bonus damage per spell discarded (Accumulation mechanic)
		if card.damage_per_spell_discarded > 0 and spells_discarded > 0:
			var spell_bonus = spells_discarded * card.damage_per_spell_discarded
			total_damage += spell_bonus
			print("[SPELL DISCARD] Bonus damage from ", spells_discarded, " spells: +", spell_bonus)
		var damage_dealt = damage_target.take_damage(total_damage, card.piercing)

		# Ring Of Fire reflection: if target has ring_of_fire buff, deal damage back to attacker
		# Triggers on any attack hit, regardless of whether damage penetrated shield
		if total_damage > 0 and damage_target.ring_of_fire > 0:
			var effect_data = StatusEffectRegistry.get_effect_data("ring_of_fire")
			var reflect_amount = effect_data.get("reflect_damage", 3)
			caster.take_damage(reflect_amount, true)  # Piercing damage
			print("[RING OF FIRE] ", damage_target.character_name, " reflected ", reflect_amount, " damage back to ", caster.character_name)

			# Signal for floating text if enemy was hit by reflection
			if enemies.has(caster):
				var enemy_index = enemies.find(caster)
				ring_of_fire_reflected.emit(enemy_index, damage_target.character_name, reflect_amount)

		# Signal if enemy damaged a player
		if enemies.has(caster) and players.has(damage_target):
			var target_player_index = players.find(damage_target)
			if target_player_index >= 0:
				enemy_damaged_player.emit(caster.character_name, card.card_name, damage_dealt, target_player_index)

		# Lifesteal
		if card.lifesteal:
			caster.heal(damage_dealt)


func _apply_delayed_damage(caster: Character, card: Card, target: Character, is_enemy: bool) -> void:
	if not card.is_delayed_damage or card.delayed_damage_amount <= 0 or not is_enemy:
		return

	var caster_idx = players.find(caster)
	var target_idx = enemies.find(target)
	if caster_idx >= 0 and target_idx >= 0:
		var delayed = {
			"caster_idx": caster_idx,
			"target_idx": target_idx,
			"damage": card.delayed_damage_amount,
			"condition": card.delay_condition,
			"source_card": card.card_name,
			"piercing": card.piercing
		}
		delayed_effects.append(delayed)


func _apply_healing(caster: Character, card: Card, target: Character, is_ally: bool) -> void:
	if not is_ally:
		return

	var heal_value = card.heal_amount

	# Bonus healing from Wet stacks on enemies (before they get removed)
	if card.heal_per_wet_removed > 0:
		var total_wet = 0
		for enemy in enemies:
			total_wet += enemy.wet
		if total_wet > 0:
			var wet_bonus = card.heal_per_wet_removed * total_wet
			heal_value += wet_bonus
			print("[HEAL] Bonus from ", total_wet, " Wet stacks: +", wet_bonus)

	# No healing to apply
	if heal_value <= 0:
		return

	# Decay reduces healing
	if caster.decay > 0:
		var reduction = caster.decay * 5
		heal_value = max(0, heal_value - reduction)
		print("[HEAL] Caster decay reduces healing: ", card.heal_amount, " -> ", heal_value)
	elif target.decay > 0 and target != caster:
		var reduction = target.decay * 5
		heal_value = max(0, heal_value - reduction)
		print("[HEAL] Target decay reduces healing: ", card.heal_amount, " -> ", heal_value)

	print("[HEAL] ", caster.character_name, " heals ", target.character_name, " for ", heal_value, " (card: ", card.card_name, ")")
	target.heal(heal_value, true)  # Decay already applied


func _apply_shield(caster: Character, card: Card, target: Character, is_ally: bool, is_enemy: bool) -> void:
	if card.shield_amount <= 0:
		return

	if is_enemy:
		# Attacking an enemy - shield yourself (e.g., "Duel Purpose")
		caster.gain_shield(card.shield_amount)
	elif is_ally:
		# Buffing an ally - shield them
		target.gain_shield(card.shield_amount)


func _apply_debuffs(caster: Character, card: Card, target: Character, is_enemy: bool) -> void:
	if not is_enemy:
		return

	# Protection redirect for debuffs
	var debuff_target = target
	if enemies.has(caster) and players.has(target):
		debuff_target = get_redirected_target(target)

	# Track if we applied damage-affecting debuffs to an enemy
	var applied_damage_debuff_to_enemy = false

	# Registry-based debuff application
	for effect_name in DEBUFF_EFFECTS:
		var amount = card.get("apply_" + effect_name)
		if amount != null and amount > 0:
			# Direct property access for debuffs (they're stored as properties)
			var current = debuff_target.get(effect_name)
			if current != null:
				debuff_target.set(effect_name, current + amount)

				# Check if player applied damage-affecting debuff to enemy
				if players.has(caster) and enemies.has(debuff_target):
					if effect_name in ["weakness", "hinder"]:
						applied_damage_debuff_to_enemy = true

	# Emit signal to recalculate enemy intents if damage stats changed
	if applied_damage_debuff_to_enemy:
		enemy_damage_stats_changed.emit()


func _apply_buffs(caster: Character, card: Card, target: Character, is_ally: bool) -> void:
	if not is_ally:
		return

	# Registry-based buff application
	for effect_name in BUFF_EFFECTS:
		var amount = card.get("apply_" + effect_name)
		if amount != null and amount > 0:
			var current = target.get(effect_name)
			if current != null:
				target.set(effect_name, current + amount)

				# Special case: invigorated grants damage_plus
				if effect_name == "invigorated":
					target.damage_plus += amount * 2


func _apply_self_debuffs(caster: Character, card: Card) -> void:
	# Self-debuffs always apply to caster regardless of card target
	for effect_name in SELF_DEBUFF_EFFECTS:
		var amount = card.get("apply_" + effect_name)
		if amount != null and amount > 0:
			var current = caster.get(effect_name)
			if current != null:
				caster.set(effect_name, current + amount)
				if effect_name == "exhausted":
					print("[EXHAUST] Applied ", amount, " to ", caster.character_name, " (total: ", caster.exhausted, ")")
				elif effect_name == "decay":
					print("[DECAY] ", caster.character_name, " gained ", amount, " decay (total: ", caster.decay, ")")


func _apply_card_draw(card: Card, target: Character) -> void:
	if card.draw_cards > 0:
		target.draw_cards(card.draw_cards)


func _apply_card_generation(caster: Character, card: Card, target: Character) -> void:
	if card.generate_cards.size() <= 0 or target != caster:
		return

	for card_name in card.generate_cards:
		var token_card = card_db.get_card(card_name)
		if token_card:
			if target.hand.size() < GameConstants.MAX_HAND_SIZE:
				target.hand.append(token_card)
			else:
				target.discard_pile.append(token_card)


func _apply_card_retention(caster: Character, card: Card, target: Character) -> void:
	if not card.grants_card_retain or target != caster:
		return

	var caster_idx = players.find(caster)
	if caster_idx >= 0:
		var expires_after = round_number + 1
		card_retain_choice_needed.emit(caster_idx, expires_after)


func _apply_enemy_target_swap(caster: Character, card: Card, target: Character, is_ally: bool) -> void:
	if not card.swaps_enemy_target or not is_ally or target == caster:
		return

	var target_idx = players.find(target)
	var caster_idx = players.find(caster)
	if target_idx >= 0 and caster_idx >= 0:
		protected_by[target_idx] = caster_idx


func _apply_boss_intent_reveal(caster: Character, card: Card, target: Character) -> void:
	if card.reveals_boss_intent and target == caster:
		boss_intent_reveal_requested.emit()


func _apply_caster_discard(caster: Character, card: Card) -> void:
	if card.caster_discards_random <= 0 or caster.hand.size() <= 0:
		return

	var discard_count = min(card.caster_discards_random, caster.hand.size())
	for i in range(discard_count):
		if caster.hand.size() > 0:
			var rand_idx = rng.randi() % caster.hand.size()
			var discarded = caster.hand[rand_idx]
			caster.hand.remove_at(rand_idx)
			caster.discard_pile.append(discarded)


func _apply_stamina_gain(caster: Character, card: Card) -> void:
	if card.stamina_gain > 0:
		caster.current_stamina += card.stamina_gain


func _apply_all_players_shield(caster: Character, card: Card) -> void:
	if card.all_players_shield <= 0:
		return

	# Only apply if caster is a player
	if not players.has(caster):
		return

	for player in players:
		if player.is_alive():
			player.gain_shield(card.all_players_shield)
			print("[SHIELD] All players shield: ", player.character_name, " gains ", card.all_players_shield, " shield")


func _apply_target_stamina_gain(card: Card, target: Character, is_ally: bool) -> void:
	if card.target_stamina_gain <= 0 or not is_ally:
		return

	target.current_stamina += card.target_stamina_gain
	print("[STAMINA] ", target.character_name, " gains ", card.target_stamina_gain, " stamina from card effect")


func _apply_remove_target_debuffs(card: Card, target: Character, is_ally: bool) -> void:
	if card.remove_target_debuffs <= 0 or not is_ally:
		return

	var removed_count = 0
	var debuffs_to_check = ["poison", "burn", "vulnerable", "weakness", "fatigued", "hinder", "scared", "wet"]

	for debuff in debuffs_to_check:
		if removed_count >= card.remove_target_debuffs:
			break

		var current_value = target.get(debuff)
		if current_value != null and current_value > 0:
			# Check if this is a permanent debuff (like decay)
			var effect_data = StatusEffectRegistry.get_effect_data(debuff)
			if effect_data.get("permanent", false):
				continue  # Skip permanent debuffs

			target.set(debuff, 0)
			removed_count += 1
			print("[DEBUFF] Removed ", debuff, " from ", target.character_name)


func _apply_remove_all_wet(card: Card, target: Character, is_enemy: bool) -> Array[Character]:
	var wet_removed_from: Array[Character] = []
	if not card.remove_all_wet:
		return wet_removed_from

	# Remove wet from ALL enemies (not just target)
	for enemy in enemies:
		if enemy.wet > 0:
			print("[WET] Removed all ", enemy.wet, " Wet stacks from ", enemy.character_name)
			enemy.wet = 0
			wet_removed_from.append(enemy)

	return wet_removed_from


## Process spell discard mechanics (for cards like Accumulation)
## Returns number of spells discarded (for damage_per_spell_discarded calculation)
func _process_spell_discards(caster: Character, card: Card) -> int:
	var spells_discarded = 0

	# discard_spell_requirement: Spells were already discarded by UI before card was queued
	# Just return the count for damage calculation
	if card.discard_spell_requirement > 0:
		spells_discarded = card.discard_spell_requirement
		print("[SPELL DISCARD] Using pre-discarded count: ", spells_discarded)

	# discard_all_spells: Automatically discard all Spell cards in hand
	if card.discard_all_spells:
		var spells_to_discard: Array[Card] = []
		for hand_card in caster.hand:
			if hand_card.card_type == Card.CardType.SPELL:
				spells_to_discard.append(hand_card)

		for spell in spells_to_discard:
			caster.hand.erase(spell)
			caster.discard_pile.append(spell)
			spells_discarded += 1
			print("[SPELL DISCARD] ", caster.character_name, " discarded spell: ", spell.card_name)

		if spells_discarded > 0:
			print("[SPELL DISCARD] Total spells discarded: ", spells_discarded)

	return spells_discarded


func _apply_spell_search(caster: Character, card: Card) -> void:
	if card.choose_spell_from_deck <= 0:
		return

	# Only trigger for players
	if not players.has(caster):
		return

	# Emit signal for UI to handle the search modal
	# The actual card transfer happens when the modal completes
	spell_search_requested.emit(caster, card.choose_spell_from_deck, card.card_name)
	print("[SPELL SEARCH] ", caster.character_name, " can search deck for ", card.choose_spell_from_deck, " spell(s)")
