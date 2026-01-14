class_name CardHandDisplay
extends Node

## Manages card hand display during PLAYER_TURN phase
## Handles card clicks for preview and drag-and-drop targeting

var game_manager: Node
var hand_container: HBoxContainer
var turn_label: Label
var card_scene = preload("res://scenes/card_visual.tscn")

var awaiting_target: bool = false
var selected_card: Card = null

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

## Display hand cards during PLAYER_TURN phase
func _display_hand_cards():
	var my_index = game_manager.local_player_index

	# Clear existing cards
	for child in hand_container.get_children():
		child.queue_free()

	var my_character = game_manager.players[my_index]

	# NEW SYSTEM: Use current stamina (stamina is deducted when cards are played)
	# No more queued cards - cards play immediately via drag-and-drop
	var current_stamina = my_character.current_stamina

	# Display cards in hand
	for card in my_character.hand:
		var card_visual = card_scene.instantiate()
		hand_container.add_child(card_visual)

		card_visual.set_card(card)
		card_visual.set_card_owner(my_character)  # For dynamic description (damage/heal with buffs)

		# Cards are playable if enough stamina available
		var can_afford = (card.stamina_cost <= current_stamina)
		# Check if scared (blocks attack cards only)
		var is_scared_blocked = (my_character.scared > 0 and card.card_type == Card.CardType.ATTACK)
		card_visual.set_playable(can_afford and not is_scared_blocked)

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

	# Check if player has enough stamina
	if my_character.current_stamina < card.stamina_cost:
		print("[CARD_HAND] Not enough stamina to play card: ", card.card_name)
		return

	# Determine if this card can be auto-played (targetless)
	var can_auto_play = false
	var target: Character = null

	match card.target_type:
		Card.TargetType.SELF:
			can_auto_play = true
			target = my_character
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
			# SINGLE_ALLY, SINGLE_ENEMY, ANY require manual targeting
			can_auto_play = false

	if can_auto_play and target != null:
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
