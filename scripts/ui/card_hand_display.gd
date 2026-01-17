class_name CardHandDisplay
extends Node

## Manages card hand display during PLAYER_TURN phase
## Handles card clicks for preview and drag-and-drop targeting

signal card_play_requested(caster: Character, card: Card, target: Character)  # For cards needing special handling (modals)

var game_manager: Node
var hand_container: HBoxContainer
var turn_label: Label
var card_scene = preload("res://scenes/card_visual.tscn")

var awaiting_target: bool = false
var selected_card: Card = null

# Cache to detect when hand has actually changed (prevents unnecessary rebuilds)
var _cached_hand_signature: String = ""

func setup(gm: Node, container: HBoxContainer, label: Label):
	game_manager = gm
	hand_container = container
	turn_label = label

## Update hand display based on current phase
func update_display():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	# During PLAYER_TURN phase: Show hand cards
	if game_manager.turn_phase == game_manager.TurnPhase.PLAYER_TURN:
		_display_hand_cards()

## Generate a signature string that represents the current hand state
func _get_hand_signature(character: Character) -> String:
	var parts: Array[String] = []
	for card in character.hand:
		parts.append(card.card_name)
	# Include stamina and status effects that affect playability
	parts.append("stam:" + str(character.current_stamina))
	parts.append("scared:" + str(character.scared))
	parts.append("exh:" + str(character.exhausted))
	return "|".join(parts)

## Display hand cards during PLAYER_TURN phase
func _display_hand_cards():
	var my_index = game_manager.local_player_index
	var my_character = game_manager.players[my_index]

	# Check if hand has actually changed (skip rebuild if unchanged)
	var new_signature = _get_hand_signature(my_character)
	if new_signature == _cached_hand_signature:
		return  # No changes, skip rebuild to prevent tearing
	_cached_hand_signature = new_signature

	# Clear existing cards
	for child in hand_container.get_children():
		child.queue_free()

	# NEW SYSTEM: Use current stamina (stamina is deducted when cards are played)
	# No more queued cards - cards play immediately via drag-and-drop
	var current_stamina = my_character.current_stamina
	var current_aura = my_character.current_aura  # Enrique's second resource

	# Display cards in hand
	for card in my_character.hand:
		var card_visual = card_scene.instantiate()
		hand_container.add_child(card_visual)

		card_visual.set_card(card)
		card_visual.set_card_owner(my_character)  # For dynamic description (damage/heal with buffs)

		# Cards are playable if enough stamina AND aura available
		var can_afford_card = card.can_afford(current_stamina, current_aura)
		# Check if scared (blocks attack cards only)
		var is_scared_blocked = (my_character.scared > 0 and card.card_type == Card.CardType.ATTACK)
		# Check if exhausted (blocks all cards)
		var is_exhausted = my_character.exhausted > 0
		# Check if card requires spell discard and player has enough spells
		# Note: Kevin's "spells" are cards with an element (FIRE, WATER, EARTH), not card_type SPELL
		var has_enough_spells = true
		if card.discard_spell_requirement > 0:
			var spell_count = 0
			for hand_card in my_character.hand:
				if hand_card.element != Card.ElementType.NONE and hand_card != card:
					spell_count += 1
			has_enough_spells = spell_count >= card.discard_spell_requirement
		card_visual.set_playable(can_afford_card and not is_scared_blocked and not is_exhausted and has_enough_spells)

		# Connect click signals
		if not card_visual.card_clicked.is_connected(_on_hand_card_clicked):
			card_visual.card_clicked.connect(_on_hand_card_clicked)
		if not card_visual.card_double_clicked.is_connected(_on_hand_card_double_clicked):
			card_visual.card_double_clicked.connect(_on_hand_card_double_clicked)

## Handle hand card click during PLAYER_TURN phase
func _on_hand_card_clicked(card: Card):
	# Clicking shows preview to other players
	var my_index = game_manager.local_player_index

	if my_index == -1:
		return

	# Update preview for this player
	game_manager.preview_card(my_index, card)

## Handle hand card double-click - auto-play targetless cards
func _on_hand_card_double_clicked(card: Card):
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]

	# Check if player can afford the card (stamina + aura)
	if not card.can_afford(my_character.current_stamina, my_character.current_aura):
		print("[CARD_HAND] Cannot afford card: ", card.card_name)
		return

	# Check if exhausted (blocks all cards)
	if my_character.exhausted > 0:
		print("[CARD_HAND] Cannot play while exhausted: ", card.card_name)
		return

	# Check if scared (blocks attack cards only)
	if my_character.scared > 0 and card.card_type == Card.CardType.ATTACK:
		print("[CARD_HAND] Cannot play attack while scared: ", card.card_name)
		return

	# Cards that require spell discard need the modal - can't auto-play
	if card.discard_spell_requirement > 0:
		print("[CARD_HAND] Card requires spell discard modal - use drag-and-drop: ", card.card_name)
		return

	# Determine if this card can be auto-played (targetless)
	var can_auto_play = false
	var target: Character = null

	match card.target_type:
		Card.TargetType.SELF:
			can_auto_play = true
			target = my_character
		Card.TargetType.SINGLE_ALLY:
			# Context-sensitive v2 cards auto-play v1 on self
			if card.has_v2 and card.context_sensitive_v2:
				can_auto_play = true
				target = my_character
				print("[CARD_HAND] Double-click auto-playing context-sensitive v2 card as v1 on self: ", card.card_name)
				game_manager.play_card_version(my_character, card, card, target)
				return
		Card.TargetType.ALL_ALLIES:
			can_auto_play = true
			target = my_character  # Target doesn't matter for ALL_ALLIES
		Card.TargetType.OTHER_ALLIES:
			can_auto_play = true
			target = my_character  # Target doesn't matter for OTHER_ALLIES
		Card.TargetType.ALL_ENEMIES:
			can_auto_play = true
			# Target doesn't matter for ALL_ENEMIES, but pick first alive enemy
			var alive_enemies = game_manager.enemies.filter(func(e): return e.is_alive())
			if alive_enemies.size() > 0:
				target = alive_enemies[0]
		Card.TargetType.RANDOM_ENEMY:
			can_auto_play = true
			# Pick a random alive enemy
			var alive_enemies = game_manager.enemies.filter(func(e): return e.is_alive())
			if alive_enemies.size() > 0:
				target = alive_enemies[randi() % alive_enemies.size()]
		_:
			# SINGLE_ENEMY, ANY require manual targeting
			can_auto_play = false

	if can_auto_play and target != null:
		# Check if card needs special handling (debuff removal, etc.)
		# Emit signal so combat.gd can handle modals properly
		if card.remove_target_debuffs > 0:
			print("[CARD_HAND] Double-click requesting play with modal: ", card.card_name)
			card_play_requested.emit(my_character, card, target)
		else:
			print("[CARD_HAND] Double-click auto-playing: ", card.card_name, " on ", target.character_name)
			game_manager.play_card(my_character, card, target)
	else:
		print("[CARD_HAND] Card requires manual targeting: ", card.card_name)

## Handle target selection for cards that need it
func on_character_clicked(character: Character) -> bool:
	if not awaiting_target or not selected_card:
		return false

	# Validate target
	var valid_target = false

	match selected_card.target_type:
		Card.TargetType.SINGLE_ALLY:
			valid_target = game_manager.players.has(character)
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			valid_target = game_manager.enemies.has(character)

	if valid_target:
		var my_index = game_manager.local_player_index
		if my_index >= 0 and my_index < game_manager.players.size():
			# PLAYER_TURN: Play the card with selected target
			if game_manager.turn_phase == game_manager.TurnPhase.PLAYER_TURN:
				var my_character = game_manager.players[my_index]
				game_manager.play_card(my_character, selected_card, character)

				selected_card = null
				awaiting_target = false
				return true

	return false

## Cancel any pending target selection
func cancel_target_selection():
	awaiting_target = false
	selected_card = null
