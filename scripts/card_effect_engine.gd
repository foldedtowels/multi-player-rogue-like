extends RefCounted
class_name CardEffectEngine

## Card Effect Engine
## Handles all card effect application with registry-based architecture.
## Extracted from GameManager to improve maintainability and testability.
##
## ============================================
## HOW STATUS EFFECTS ARE APPLIED
## ============================================
## This engine uses StatusEffectRegistry to dynamically apply effects.
## It looks up card properties like "apply_poison" using:
##
##   var amount = card.get("apply_" + effect_name)
##
## This means:
##   1. If StatusEffectRegistry has "poison", this looks for card.apply_poison
##   2. If the Card class doesn't have that property, get() returns null
##   3. The effect silently fails to apply - NO ERROR IS SHOWN
##
## ADDING NEW EFFECTS:
## If you add a special side effect (like invigorated -> damage_plus),
## add handling in _apply_buffs() or _apply_debuffs() after the registry loop.
## See the "invigorated" special case around line 445.
##
## See StatusEffectRegistry.gd for the full checklist of files to update.
## ============================================

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
signal boss_intent_reveal_requested(player_index: int)
signal enemy_damage_stats_changed()  # Emitted when weakness/hinder/strength applied to enemy
signal spell_search_requested(player: Character, count: int, card_name: String)  # For Reformulate-style cards
signal minion_summoned(summoner: Character, minion_tag: String, summon_count: int)  # Mid-combat minion summoning

# Status effect categories - now fetched from StatusEffectRegistry for modularity


## Calculate damage for a card (unified formula used by both effect application and previews)
## This is the SINGLE SOURCE OF TRUTH for damage calculation.
## aura_spent is used for "All Aura" cards like Expulsion that deal damage per aura spent
static func calculate_damage(card: Card, caster: Character, target: Character = null, aura_spent: int = 0) -> int:
	var total_damage = card.damage

	# D6 damage (Prayer Beads): replace base damage with random 1-6
	if card.damage_is_d6:
		# Note: For UI preview, we show average (3.5 -> 4). For actual damage, use random.
		# This static method is used for preview, so we show average.
		total_damage = 4  # Average of D6

	if card.card_type == Card.CardType.ATTACK:
		# Add attack modifiers
		total_damage += caster.strength
		total_damage += caster.damage_plus

		# Subtract attack penalties
		total_damage -= caster.weakness
		total_damage -= caster.hinder
		total_damage -= caster.feeble

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

		# Bonus damage per Aura spent (Enrique's Expulsion - "All Aura" cards)
		if card.damage_per_aura_spent > 0 and aura_spent > 0:
			total_damage += card.damage_per_aura_spent * aura_spent

		# Conditional damage based on caster's damage taken this turn
		# (e.g., Angwy Punch: +5 if caster took 1+ damage, Vulnerable Approach: -10 if caster took 10+)
		if card.damage_threshold_check > 0 and caster != null:
			if caster.damage_taken_this_turn >= card.damage_threshold_check:
				total_damage += card.damage_threshold_modifier

		# Relic damage bonus (Familiar Bracelet: +2 to non-spell, non-alc cards)
		total_damage += RelicRegistry.get_damage_bonus(caster, card)

		total_damage = max(0, total_damage)

	return total_damage


## Calculate total damage including multi-hit
static func calculate_total_damage(card: Card, caster: Character, target: Character = null) -> int:
	return calculate_damage(card, caster, target) * card.multi_hit


## Apply all effects from a card to target(s)
## Returns array of affected characters for state broadcasting
## aura_spent is the amount of aura that was spent to play this card (for damage_per_aura_spent)
func apply_effects(caster: Character, card: Card, target: Character, aura_spent: int = 0) -> Array[Character]:
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
		_apply_damage(caster, card, t, is_enemy, spells_discarded_count, aura_spent)
		_apply_delayed_damage(caster, card, t, is_enemy)
		_apply_healing(caster, card, t, is_ally)
		_apply_shield(caster, card, t, is_ally, is_enemy)
		_apply_debuffs(caster, card, t, is_enemy)
		_apply_remove_target_buffs(caster, card, t, is_enemy)  # Corrupted Incense
		_apply_buffs(caster, card, t, is_ally)
		_apply_enrique_buffs(caster, card, t, is_ally)  # Enrique's played_twice and invincible
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
	_apply_aura_gain(caster, card)  # Enrique's aura gain
	_apply_all_players_shield(caster, card)
	_apply_all_allies_shield(caster, card)  # Enemy ally shield (Giant Shield)
	_apply_remove_self_debuffs(caster, card)  # Fighter's Spirit
	_apply_caster_self_debuffs(caster, card)  # Self-applied debuffs (bleed, feeble)
	var all_draw_affected = _apply_all_players_draw(caster, card)  # Enrique's Guy with Beard
	for p in all_draw_affected:
		if not affected.has(p):
			affected.append(p)
	_apply_spell_search(caster, card)
	_apply_summon(caster, card)

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

		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY, Card.TargetType.CCW_PLAYER, Card.TargetType.HIGHEST_HP, Card.TargetType.LOWEST_HP, Card.TargetType.MOST_WET, Card.TargetType.TARGET_BY_NAME:
			targets.append(target)

		Card.TargetType.ALL_ENEMIES:
			if enemies.has(caster):
				targets = players.duplicate()
			else:
				targets = enemies.filter(func(e): return e.is_alive())

		Card.TargetType.LOWEST_HP_ALLY, Card.TargetType.RANDOM_ALLY:
			# Target is already pre-selected by enemy_ai.gd
			if target != null:
				targets.append(target)
			else:
				# Fallback: select lowest HP ally (excluding self)
				var allies: Array[Character] = []
				if enemies.has(caster):
					allies.assign(enemies.filter(func(e): return e.is_alive() and e != caster))
				else:
					allies.assign(players.filter(func(p): return p.is_alive() and p != caster))
				if allies.size() > 0:
					allies.sort_custom(func(a, b): return a.current_health < b.current_health)
					targets.append(allies[0])

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

func _apply_damage(caster: Character, card: Card, target: Character, is_enemy: bool, spells_discarded: int = 0, aura_spent: int = 0) -> void:
	# Allow cards with damage_per_spell_discarded, damage_per_aura_spent, or bonus_damage_per_wet even if base damage is 0
	var has_conditional_damage = card.damage_per_spell_discarded > 0 or card.damage_per_aura_spent > 0 or card.bonus_damage_per_wet > 0
	if (card.damage <= 0 and not has_conditional_damage and not card.damage_is_d6) or not is_enemy:
		return

	# Protection redirect: enemy attacking protected player
	var damage_target = target
	if enemies.has(caster) and players.has(target):
		damage_target = get_redirected_target(target)

	# Calculate multi-hit count including Copying Machine relic bonus
	var total_hits = card.multi_hit
	if players.has(caster) and card.multi_hit > 1:
		total_hits += RelicRegistry.get_extra_multi_hit(caster)

	for i in total_hits:
		# Handle D6 damage (Prayer Beads): roll 1-6
		var base_damage = card.damage
		if card.damage_is_d6:
			base_damage = rng.randi_range(1, 6)
			print("[D6 DAMAGE] Rolled: ", base_damage)

		# Calculate total damage with buffs/debuffs
		var total_damage = base_damage
		if card.card_type == Card.CardType.ATTACK:
			total_damage += caster.strength + caster.damage_plus
			total_damage -= caster.weakness + caster.hinder + caster.feeble

			# Apply PASSIVE_MODIFIER relic damage bonus (Familiar Bracelet)
			if players.has(caster):
				total_damage += RelicRegistry.get_damage_bonus(caster, card)
			if card.bonus_damage_if_wounded > 0:
				var hp_percent = float(damage_target.current_health) / float(damage_target.max_health)
				if hp_percent < 0.5:
					total_damage += card.bonus_damage_if_wounded
			if card.bonus_damage_per_debuff > 0:
				total_damage += card.bonus_damage_per_debuff * damage_target.get_total_debuff_stacks()
			if card.bonus_damage_per_wet > 0:
				total_damage += card.bonus_damage_per_wet * damage_target.wet
			if card.damage_per_aura_spent > 0 and aura_spent > 0:
				var aura_bonus = aura_spent * card.damage_per_aura_spent
				total_damage += aura_bonus
				print("[AURA DAMAGE] Bonus damage from ", aura_spent, " aura: +", aura_bonus)
			# Conditional damage based on caster's damage taken this turn
			print("[DAMAGE] Card: ", card.card_name, " threshold_check: ", card.damage_threshold_check, " threshold_mod: ", card.damage_threshold_modifier)
			if card.damage_threshold_check > 0:
				if caster.damage_taken_this_turn >= card.damage_threshold_check:
					total_damage += card.damage_threshold_modifier
					print("[CONDITIONAL DAMAGE] Caster took ", caster.damage_taken_this_turn, " damage this turn (threshold: ", card.damage_threshold_check, "), modifier: ", card.damage_threshold_modifier)
			total_damage = max(0, total_damage)
			print("[DAMAGE CALC] ", card.card_name, ": base=", base_damage, " str=", caster.strength, " dmg+=", caster.damage_plus, " weak=", caster.weakness, " hinder=", caster.hinder, " feeble=", caster.feeble, " total=", total_damage)

		# Add bonus damage per spell discarded (Accumulation mechanic)
		if card.damage_per_spell_discarded > 0 and spells_discarded > 0:
			var spell_bonus = spells_discarded * card.damage_per_spell_discarded
			total_damage += spell_bonus
			print("[SPELL DISCARD] Bonus damage from ", spells_discarded, " spells: +", spell_bonus)
		var damage_dealt = damage_target.take_damage(total_damage, card.piercing)
		print("[DAMAGE DEALT] ", damage_target.character_name, " took ", damage_dealt, " damage (total_damage=", total_damage, ")")

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

		# ON_DAMAGE_DEALT relic effects (player dealing damage to enemy)
		if players.has(caster) and enemies.has(damage_target) and damage_dealt > 0:
			RelicRegistry.apply_on_damage_dealt(caster, damage_dealt)


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

	# Apply ON_HEAL relic effects (Grandma's Cookies, Gentle Hands, Electrified Idol)
	# Only for player casters
	if players.has(caster):
		var relic_bonus = RelicRegistry.calculate_heal_bonus(caster, target, heal_value, enemies, rng)
		if relic_bonus > 0:
			heal_value += relic_bonus
			print("[RELIC] Heal bonus from relics: +", relic_bonus)

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
	for effect_name in StatusEffectRegistry.get_debuff_effect_names():
		# Skip self-applicable debuffs (like exhausted, fatigued) - those are applied to caster, not target
		var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
		if effect_data.get("self_applicable", false):
			continue

		var amount = card.get("apply_" + effect_name)
		if amount != null and amount > 0:
			# Apply ON_DEBUFF_APPLIED relic effects (Water Stone doubles wet)
			if players.has(caster):
				var extra = RelicRegistry.apply_on_debuff_applied(caster, effect_name, amount)
				amount += extra

			# Direct property access for debuffs (they're stored as properties)
			var current = debuff_target.get(effect_name)
			if current != null:
				debuff_target.set(effect_name, current + amount)

				# Check if player applied damage-affecting debuff to enemy
				if players.has(caster) and enemies.has(debuff_target):
					if effect_name in ["weakness", "hinder"]:
						applied_damage_debuff_to_enemy = true

	# Random Doll debuff (Mute's Instantiation)
	if card.apply_random_doll > 0:
		var doll_types = ["doll_dissolve", "doll_suffering", "doll_burden"]
		var random_doll = doll_types[rng.randi() % doll_types.size()]
		var current = debuff_target.status_effects.get(random_doll, 0)
		debuff_target.set_effect_amount(random_doll, current + card.apply_random_doll)
		print("[RANDOM DOLL] Applied ", card.apply_random_doll, " ", random_doll, " to ", debuff_target.character_name)

	# Exhaust from target's deck (Mute's Hex: Acquisition)
	if card.exhaust_target_deck > 0:
		_apply_exhaust_target_deck(card, debuff_target)

	# Emit signal to recalculate enemy intents if damage stats changed
	if applied_damage_debuff_to_enemy:
		enemy_damage_stats_changed.emit()


func _apply_buffs(caster: Character, card: Card, target: Character, is_ally: bool) -> void:
	if not is_ally:
		return

	# Registry-based buff application
	for effect_name in StatusEffectRegistry.get_buff_effect_names():
		var amount = card.get("apply_" + effect_name)
		if amount != null and amount > 0:
			var current = target.get(effect_name)
			print("[BUFF APPLY] ", target.character_name, " ", effect_name, ": ", current, " + ", amount)
			if current != null:
				target.set(effect_name, current + amount)

				# Special case: invigorated grants damage_plus
				if effect_name == "invigorated":
					target.damage_plus += amount * 2


func _apply_self_debuffs(caster: Character, card: Card) -> void:
	# Self-debuffs always apply to caster regardless of card target
	for effect_name in StatusEffectRegistry.get_self_debuff_effect_names():
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
		var player_idx = players.find(caster)
		boss_intent_reveal_requested.emit(player_idx)


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


func _apply_all_allies_shield(caster: Character, card: Card) -> void:
	if card.all_allies_shield <= 0:
		return

	# Get caster's allies (enemies if caster is enemy, players if caster is player)
	var allies: Array[Character] = []
	if enemies.has(caster):
		allies.assign(enemies.filter(func(e): return e.is_alive()))
	else:
		allies.assign(players.filter(func(p): return p.is_alive()))

	for ally in allies:
		ally.gain_shield(card.all_allies_shield)
		print("[SHIELD] All allies shield: ", ally.character_name, " gains ", card.all_allies_shield, " shield")


func _apply_remove_self_debuffs(caster: Character, card: Card) -> void:
	if not card.remove_self_debuffs:
		return

	var debuffs_removed = 0
	for effect_name in StatusEffectRegistry.get_debuff_effect_names():
		var current_value = caster.get(effect_name)
		if current_value != null and current_value > 0:
			# Check if this is a permanent debuff
			var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
			if effect_data.get("permanent", false):
				continue  # Skip permanent debuffs

			caster.set(effect_name, 0)
			debuffs_removed += 1
			print("[DEBUFF CLEAR] Removed ", effect_name, " from ", caster.character_name)

	if debuffs_removed > 0:
		print("[FIGHTER'S SPIRIT] ", caster.character_name, " cleared ", debuffs_removed, " debuff(s)")


func _apply_remove_target_buffs(caster: Character, card: Card, target: Character, is_enemy: bool) -> void:
	if not card.remove_target_buffs or not is_enemy:
		return

	var buffs_removed = 0
	for effect_name in StatusEffectRegistry.get_buff_effect_names():
		var current_value = target.get(effect_name)
		if current_value != null and current_value > 0:
			target.set(effect_name, 0)
			buffs_removed += 1
			print("[BUFF STRIP] Removed ", effect_name, " from ", target.character_name)

	if buffs_removed > 0:
		print("[CORRUPTED INCENSE] ", caster.character_name, " stripped ", buffs_removed, " buff(s) from ", target.character_name)


func _apply_caster_self_debuffs(caster: Character, card: Card) -> void:
	# Apply bleed to caster (card downside)
	if card.caster_bleed > 0:
		caster.bleed += card.caster_bleed
		print("[SELF BLEED] ", caster.character_name, " applies ", card.caster_bleed, " bleed to self")

	# Apply feeble to caster (card downside)
	if card.caster_feeble > 0:
		caster.feeble += card.caster_feeble
		print("[SELF FEEBLE] ", caster.character_name, " applies ", card.caster_feeble, " feeble to self")


func _apply_target_stamina_gain(card: Card, target: Character, is_ally: bool) -> void:
	if card.target_stamina_gain <= 0 or not is_ally:
		return

	target.current_stamina += card.target_stamina_gain
	print("[STAMINA] ", target.character_name, " gains ", card.target_stamina_gain, " stamina from card effect")


func _apply_remove_target_debuffs(card: Card, target: Character, is_ally: bool) -> void:
	if card.remove_target_debuffs <= 0 or not is_ally:
		return

	var removed_count = 0
	var debuffs_to_check = StatusEffectRegistry.get_debuff_effect_names()

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

	# Variable spell discard (Repurpose): Spells were already discarded by UI before card was queued
	# Check for stored meta value from combat.gd
	if card.has_meta("spells_discarded_this_play"):
		spells_discarded = card.get_meta("spells_discarded_this_play")
		card.remove_meta("spells_discarded_this_play")  # Clean up
		print("[SPELL DISCARD] Using variable discard count: ", spells_discarded)
		return spells_discarded

	# discard_spell_requirement: Spells were already discarded by UI before card was queued
	# Just return the count for damage calculation
	if card.discard_spell_requirement > 0:
		spells_discarded = card.discard_spell_requirement
		print("[SPELL DISCARD] Using pre-discarded count: ", spells_discarded)

	# discard_all_spells: Automatically discard all Spell cards in hand
	# Note: Kevin's "spells" are cards with an element (FIRE, WATER, EARTH), not card_type SPELL
	if card.discard_all_spells:
		var spells_to_discard: Array[Card] = []
		for hand_card in caster.hand:
			if hand_card.element != Card.ElementType.NONE:
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


# =============================================================================
# ENRIQUE'S AURA & DIVINE EFFECTS
# =============================================================================

func _apply_aura_gain(caster: Character, card: Card) -> void:
	if card.aura_gain <= 0:
		return

	# Only apply if caster has aura system enabled
	if caster.max_aura <= 0:
		return

	caster.add_aura(card.aura_gain)


func _apply_enrique_buffs(caster: Character, card: Card, target: Character, is_ally: bool) -> void:
	if not is_ally:
		return

	# Grant "Played Twice" buff (Divine Reflection)
	if card.grants_played_twice:
		target.played_twice += 1
		print("[PLAYED TWICE] ", target.character_name, " gains Played Twice buff")

	# Grant "Invincible" buff (Divine Barrier)
	if card.grants_invincible:
		target.invincible += 1
		print("[INVINCIBLE] ", target.character_name, " gains Invincible buff")


func _apply_all_players_draw(caster: Character, card: Card) -> Array[Character]:
	var draw_affected: Array[Character] = []
	if card.all_players_draw <= 0:
		return draw_affected

	print("[DEBUG] _apply_all_players_draw - players.size(): ", players.size())

	# Only apply if caster is a player
	if not players.has(caster):
		print("[DEBUG] Caster not in players array!")
		return draw_affected

	for player in players:
		print("[DEBUG] Player in array: ", player.character_name, " alive: ", player.is_alive())
		if player.is_alive():
			player.draw_cards(card.all_players_draw)
			draw_affected.append(player)
			print("[DRAW] All players draw: ", player.character_name, " draws ", card.all_players_draw, " card(s)")

	return draw_affected


## Apply summon effects (Spider-Queen's Spawn Spiderling, etc.)
func _apply_summon(caster: Character, card: Card) -> void:
	if card.summon_minion_tag == "" or card.summon_count <= 0:
		return

	# Emit signal for each summon requested
	# GameManager will handle the actual creation and track count limits
	minion_summoned.emit(caster, card.summon_minion_tag, card.summon_count)
	print("[SUMMON] ", caster.character_name, " summons ", card.summon_count, " minion(s) with tag: ", card.summon_minion_tag)


## Exhaust cards from target's deck (Mute's Hex: Acquisition)
func _apply_exhaust_target_deck(card: Card, target: Character) -> void:
	for i in card.exhaust_target_deck:
		# First try to exhaust from deck
		if target.deck.size() > 0:
			var exhausted_card = target.deck.pop_front()
			target.exhaust_pile.append(exhausted_card)
			print("[HEX] Exhausted ", exhausted_card.card_name, " from ", target.character_name, "'s deck")
		# If deck is empty, try discard pile
		elif target.discard_pile.size() > 0:
			var exhausted_card = target.discard_pile.pop_front()
			target.exhaust_pile.append(exhausted_card)
			print("[HEX] Exhausted ", exhausted_card.card_name, " from ", target.character_name, "'s discard pile")
		else:
			print("[HEX] No cards to exhaust from ", target.character_name)
