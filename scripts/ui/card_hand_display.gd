class_name CardHandDisplay
extends Node

## Manages card hand display for SELECTION and ACTION phases
## Handles card clicks, queuing, and phase transition animations

signal card_queued(card: Card)
signal queued_card_played(card: Card, target: Character)
signal ready_requested()

var game_manager: Node
var hand_container: HBoxContainer
var turn_label: Label
var card_scene = preload("res://scenes/card_visual.tscn")

var queued_cards: Array = []  # Local queue during SELECTION phase
var awaiting_target: bool = false
var selected_card: Card = null
var animating_phase_transition: bool = false

func setup(gm: Node, container: HBoxContainer, label: Label):
	game_manager = gm
	hand_container = container
	turn_label = label

## Update hand display based on current phase
func update_display():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	# During SELECTION phase: Show hand cards
	if game_manager.turn_phase == game_manager.TurnPhase.PLAYER_SELECTION:
		_display_hand_cards()

	# During ACTION phase: Refresh queued cards to sync with server state
	elif game_manager.turn_phase == game_manager.TurnPhase.PLAYER_ACTION:
		# Don't regenerate during animations
		if animating_phase_transition:
			return
		# Refresh display to match server's queued_cards (when other players play cards)
		_refresh_queued_cards_display()

## Display hand cards during SELECTION phase
func _display_hand_cards():
	var my_index = game_manager.local_player_index

	# Clear existing cards
	for child in hand_container.get_children():
		child.queue_free()

	var my_character = game_manager.players[my_index]

	# Calculate remaining energy after queued cards
	var queued_energy = 0
	for queued_card in queued_cards:
		queued_energy += queued_card.energy_cost
	var remaining_energy = my_character.max_energy - queued_energy

	# Display cards in hand
	for card in my_character.hand:
		var card_visual = card_scene.instantiate()
		hand_container.add_child(card_visual)

		card_visual.set_card(card)

		# Cards are clickable if enough energy remaining
		var can_afford = (card.energy_cost <= remaining_energy)
		card_visual.set_playable(can_afford)

		# Connect click signal
		if not card_visual.card_clicked.is_connected(_on_hand_card_clicked):
			card_visual.card_clicked.connect(_on_hand_card_clicked)

## Animate transition from SELECTION to ACTION phase
func animate_selection_to_action():
	var my_index = game_manager.local_player_index

	if animating_phase_transition:
		return

	animating_phase_transition = true

	# Step 1: Animate hand cards sliding down off screen
	var hand_cards = hand_container.get_children()
	for i in range(hand_cards.size()):
		var card_visual = hand_cards[i]
		var tween = card_visual.create_tween()
		tween.tween_property(card_visual, "position:y", card_visual.position.y + 400, 0.3).set_delay(i * 0.05)
		tween.tween_callback(card_visual.queue_free)

	# Step 2: Wait for hand to clear, then show queue
	await hand_container.get_tree().create_timer(0.5).timeout

	# Step 3: Display all queued cards (from all players) and animate them up
	_display_queued_cards()

	animating_phase_transition = false

## Display queued cards from all players during ACTION phase (with animations)
func _display_queued_cards():
	_show_queued_cards(true)

## Refresh queued cards display without animations (for syncing during action phase)
func _refresh_queued_cards_display():
	_show_queued_cards(false)

## Internal function to show queued cards with optional animations
func _show_queued_cards(animate: bool):
	var my_index = game_manager.local_player_index

	# Clear hand container (use queue_free() for safe deferred deletion)
	for child in hand_container.get_children():
		child.queue_free()

	# Collect all queued cards from all ALIVE players, organized by player
	var delay = 0.0
	for player_index in range(game_manager.players.size()):
		if not game_manager.queued_cards.has(player_index):
			continue

		# Skip dead players' queued cards
		var player = game_manager.players[player_index]
		if not player.is_alive():
			continue

		var player_queued = game_manager.queued_cards[player_index]
		var is_my_cards = (player_index == my_index)

		# Create card visuals for this player's queued cards
		for card in player_queued:
			var card_visual = card_scene.instantiate()
			hand_container.add_child(card_visual)

			card_visual.set_card(card)

			# Ensure card visual can receive mouse events
			card_visual.mouse_filter = Control.MOUSE_FILTER_STOP

			# Only your own queued cards are clickable
			card_visual.set_playable(is_my_cards)

			if is_my_cards:
				# Connect to queued card click handler
				card_visual.card_clicked.connect(_on_queued_card_clicked)

			# Tint other players' cards differently
			if not is_my_cards:
				card_visual.modulate = Color(0.7, 0.7, 0.7, 0.8)

			# Animate if requested
			if animate:
				# Use modulate for animation
				card_visual.modulate.a = 0.0

				# Animate card fading in
				var tween = card_visual.create_tween()
				tween.tween_property(card_visual, "modulate:a", 1.0 if is_my_cards else 0.8, 0.4).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
				delay += 0.05
			else:
				# No animation - just set final alpha
				card_visual.modulate.a = 1.0 if is_my_cards else 0.8

## Remove specific card visual from display
func remove_card_visual(card: Card):
	for child in hand_container.get_children():
		if child.has_method("set_card") and child.card_data and child.card_data.card_name == card.card_name:
			child.queue_free()
			return

## Handle hand card click during SELECTION phase
func _on_hand_card_clicked(card: Card):
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	var my_character = game_manager.players[my_index]

	# Check if card should play immediately (e.g., Draw cards)
	if card.plays_immediately:
		game_manager.play_card(my_character, card, my_character)
		return

	# Check total energy cost of queued cards + this card
	var total_cost = card.energy_cost
	for queued in queued_cards:
		total_cost += queued.energy_cost

	if total_cost > my_character.max_energy:
		return

	# Queue the card
	_queue_card(card)

## Handle queued card click during ACTION phase
func _on_queued_card_clicked(card: Card):
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	var my_character = game_manager.players[my_index]

	selected_card = card

	# Check if card needs targeting
	match card.target_type:
		Card.TargetType.SELF:
			# Play immediately on self
			game_manager.play_card(my_character, card, my_character)
			game_manager.remove_queued_card(my_index, card)
			remove_card_visual(card)
			selected_card = null
		Card.TargetType.ALL_ALLIES, Card.TargetType.ALL_ENEMIES:
			# Play immediately, no targeting needed
			var first_enemy = game_manager.enemies[0] if game_manager.enemies.size() > 0 else null
			if first_enemy:
				game_manager.play_card(my_character, card, first_enemy)
				game_manager.remove_queued_card(my_index, card)
				remove_card_visual(card)
			selected_card = null
		_:
			# Need to select a target
			awaiting_target = true
			turn_label.text = "Select target for %s..." % card.card_name

## Queue a card during SELECTION phase
func _queue_card(card: Card):
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	# Add to local queue
	queued_cards.append(card)

	# Remove card from hand (moved to queue)
	var my_character = game_manager.players[my_index]
	my_character.hand.erase(card)

	# Sync to server
	game_manager.sync_queued_card(my_index, card.serialize())

	# Emit signal to update displays
	card_queued.emit(card)

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
			# ACTION PHASE: Play the queued card with selected target
			if game_manager.turn_phase == game_manager.TurnPhase.PLAYER_ACTION:
				var my_character = game_manager.players[my_index]
				game_manager.play_card(my_character, selected_card, character)

				# Remove from queue
				game_manager.remove_queued_card(my_index, selected_card)
				remove_card_visual(selected_card)

				selected_card = null
				awaiting_target = false
				return true

	return false

## Clear queued cards (called when entering new SELECTION phase)
func clear_queued_cards():
	queued_cards.clear()

## Cancel any pending target selection
func cancel_target_selection():
	awaiting_target = false
	selected_card = null
