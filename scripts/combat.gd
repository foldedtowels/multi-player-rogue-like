extends Control

var game_manager: Node
var current_player: Character
var card_hand_display: CardHandDisplay
var player_status_panel: PlayerStatusPanel
var last_turn_phase = null  # Track phase changes for animations

# UI References - New multiplayer layout
@onready var left_player_panel: Panel = $MainArea/LeftPlayerPanel
@onready var right_player_panel: Panel = $MainArea/RightPlayerPanel
@onready var your_character_panel: Panel = $BottomArea/YourCharacterPanel
@onready var enemy_displays_container: HBoxContainer = $MainArea/CenterArea/EnemyDisplays
@onready var hand_container: HBoxContainer = $BottomArea/HandPanel/HandContainer
@onready var deck_count_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/DeckCountLabel
@onready var discard_count_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/DiscardCountLabel
@onready var phase_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/PhaseLabel
@onready var ready_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/ReadyButton
@onready var pass_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/PassButton
@onready var ready_status_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/ReadyStatusLabel
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var stamina_label: Label = $TopBar/EnergyLabel
@onready var round_label: Label = $TopBar/RoundLabel

# Passive Ability
@onready var passive_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/PassiveButton
@onready var passive_ability_modal = $PassiveAbilityModal

# Card V2 Choice
@onready var card_v2_choice_modal = $CardV2ChoiceModal

# Deck View
@onready var view_deck_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/ViewDeckButton
@onready var deck_view_modal = $DeckViewModal

var card_scene = preload("res://scenes/card_visual.tscn")
var boss_visual: Node2D = null
var character_face_panel: Panel = null  # Character face for self-targeting

func _ready():
	game_manager = get_node("/root/GameManager")

	# Create card hand display component
	card_hand_display = CardHandDisplay.new()
	add_child(card_hand_display)
	card_hand_display.setup(game_manager, hand_container, turn_label)

	# Create player status panel component
	player_status_panel = PlayerStatusPanel.new()
	add_child(player_status_panel)
	player_status_panel.setup(game_manager, left_player_panel, right_player_panel, your_character_panel)
	player_status_panel.panel_clicked.connect(_on_character_clicked)

	# Add animated background
	create_animated_background()

	# Connect game manager signals
	game_manager.player_turn_started.connect(_on_player_turn_started)
	game_manager.boss_turn_started.connect(_on_boss_turn_started)
	game_manager.card_played.connect(_on_card_played)
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.combat_ended.connect(_on_combat_ended)
	game_manager.enemy_damaged_player.connect(_on_enemy_damaged_player)
	game_manager.card_v2_choice_needed.connect(_on_card_v2_choice_needed)
	game_manager.card_retain_choice_needed.connect(_on_card_retain_choice_needed)
	game_manager.boss_intent_revealed.connect(_on_boss_intent_revealed)
	game_manager.enemy_intents_calculated.connect(_on_enemy_intents_calculated)

	# Connect button signals
	ready_button.pressed.connect(_on_ready_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	passive_button.pressed.connect(_on_passive_pressed)
	view_deck_button.pressed.connect(_on_view_deck_pressed)

	# Connect passive ability modal signals
	passive_ability_modal.awaiting_target.connect(_on_passive_awaiting_target)

	# Mouse events will properly propagate to cards now that we removed MOUSE_FILTER_IGNORE
	# The correct hierarchy: HandPanel (STOP) -> HandContainer (STOP) -> CardVisual (STOP)
	# CardVisual's child elements (Background, VBoxContainer, labels) have IGNORE set in card_visual.gd

	# Setup player panels as drop targets (BEFORE displaying cards)
	_setup_drop_zones()

	# Start the first round with simultaneous selection phase
	if game_manager.current_state == game_manager.GameState.COMBAT:
		game_manager.start_round()

	# Update displays AFTER round is properly initialized
	update_all_displays()

func _setup_drop_zones():
	# Make player panels accept card drops
	left_player_panel.set_script(preload("res://scripts/ui/drop_target_panel.gd"))
	right_player_panel.set_script(preload("res://scripts/ui/drop_target_panel.gd"))
	your_character_panel.set_script(preload("res://scripts/ui/drop_target_panel.gd"))

	# Make HBoxContainers pass drops through to parent panels
	var your_hbox = your_character_panel.get_node("HBoxContainer")
	your_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var left_vbox = left_player_panel.get_node("VBoxContainer")
	left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var right_vbox = right_player_panel.get_node("VBoxContainer")
	right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect drop signals
	left_player_panel.card_dropped.connect(_on_card_dropped_on_player_panel.bind(left_player_panel))
	right_player_panel.card_dropped.connect(_on_card_dropped_on_player_panel.bind(right_player_panel))
	your_character_panel.card_dropped.connect(_on_card_dropped_on_player_panel.bind(your_character_panel))

	# Create character face for self-targeting
	_create_character_face()

func _create_character_face():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		print("[COMBAT] Cannot create character face - invalid index: ", my_index)
		return

	var my_character = game_manager.players[my_index]

	# Create face panel
	character_face_panel = Panel.new()
	character_face_panel.custom_minimum_size = Vector2(80, 80)

	# Get HBoxContainer from YourCharacterPanel
	var hbox = your_character_panel.get_node("HBoxContainer")

	# Add face panel at the beginning (before NameLabel)
	hbox.add_child(character_face_panel)
	hbox.move_child(character_face_panel, 0)  # Move to first position

	# Create colored background based on character
	var color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to parent

	# Map character names to colors
	var face_color = Color(0.5, 0.5, 0.5)  # Default gray
	if "Pyra" in my_character.character_name:
		face_color = Color(0.9, 0.3, 0.1)  # Red/Orange for Pyra
	elif "Selene" in my_character.character_name:
		face_color = Color(0.2, 0.6, 0.9)  # Light Blue for Selene
	elif "Nyx" in my_character.character_name:
		face_color = Color(0.6, 0.2, 0.8)  # Purple for Nyx

	color_rect.color = face_color
	character_face_panel.add_child(color_rect)

	# Add border styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.WHITE
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	character_face_panel.add_theme_stylebox_override("panel", style)

	# Make face panel accept drops
	character_face_panel.set_script(preload("res://scripts/ui/drop_target_panel.gd"))
	character_face_panel.card_dropped.connect(_on_card_dropped_on_character_face)

func create_animated_background():
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.set_script(load("res://scripts/animated_background.gd"))
	add_child(bg)
	move_child(bg, 0)  # Move to back

func update_all_displays():
	player_status_panel.update_all()
	update_enemy_displays()
	card_hand_display.update_display()
	update_deck_counts()
	update_turn_display()
	update_button_states()

func update_deck_counts():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]
	deck_count_label.text = "Deck: %d" % my_character.deck.size()
	discard_count_label.text = "Discard: %d" % my_character.discard_pile.size()

func update_enemy_displays():
	# Clear existing enemy UI
	for child in enemy_displays_container.get_children():
		child.queue_free()

	# Create UI for each enemy
	for i in game_manager.enemies.size():
		var enemy = game_manager.enemies[i]
		var enemy_panel = Panel.new()
		enemy_panel.name = "Enemy" + str(i)
		enemy_panel.custom_minimum_size = Vector2(200, 150)
		enemy_displays_container.add_child(enemy_panel)

		# Add VBoxContainer for labels
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 10
		vbox.offset_top = 10
		vbox.offset_right = -10
		vbox.offset_bottom = -10
		vbox.add_theme_constant_override("separation", 5)
		enemy_panel.add_child(vbox)

		# Add labels
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(name_label)

		var hp_label = Label.new()
		hp_label.name = "HPLabel"
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(hp_label)

		var status_label = Label.new()
		status_label.name = "StatusLabel"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(status_label)

		# Intent row for displaying enemy intentions
		var intent_container = HBoxContainer.new()
		intent_container.name = "IntentContainer"
		intent_container.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(intent_container)

		# Connect click handler
		enemy_panel.gui_input.connect(_on_character_clicked.bind(enemy))

		# Make enemy panel accept card drops
		enemy_panel.set_script(preload("res://scripts/ui/drop_target_panel.gd"))
		enemy_panel.card_dropped.connect(_on_card_dropped_on_enemy_panel.bind(enemy))

		# Update display
		update_enemy_display(enemy_panel, enemy)

func update_enemy_display(display: Panel, enemy: Character):
	var name_label = display.get_node("VBoxContainer/NameLabel")
	var hp_label = display.get_node("VBoxContainer/HPLabel")
	var status_label = display.get_node("VBoxContainer/StatusLabel")
	var intent_container = display.get_node("VBoxContainer/IntentContainer")

	name_label.text = enemy.character_name
	hp_label.text = "HP: %d/%d" % [enemy.current_health, enemy.max_health]

	if enemy.shield > 0:
		hp_label.text += "\nShield: %d" % enemy.shield

	# Status effects
	var status_text = ""
	# Buffs
	if enemy.strength > 0:
		status_text += "Str +%d " % enemy.strength
	if enemy.armor > 0:
		status_text += "Armor +%d " % enemy.armor
	if enemy.rested > 0:
		status_text += "Rested %d " % enemy.rested
	if enemy.invigorated > 0:
		status_text += "Invig %d " % enemy.invigorated
	if enemy.damage_plus > 0:
		status_text += "Dmg+ %d " % enemy.damage_plus
	# Debuffs
	if enemy.poison > 0:
		status_text += "Poison %d " % enemy.poison
	if enemy.burn > 0:
		status_text += "Burn %d " % enemy.burn
	if enemy.vulnerable > 0:
		status_text += "Vuln %d " % enemy.vulnerable
	if enemy.weakness > 0:
		status_text += "Weak %d " % enemy.weakness
	if enemy.fatigued > 0:
		status_text += "Fatigued %d " % enemy.fatigued
	status_label.text = status_text

	# Display enemy intent
	_update_intent_display(intent_container, enemy)

	# Background color
	var bg_color = Color(0.4, 0.2, 0.2) if not enemy.is_alive() else Color(0.3, 0.1, 0.1)
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0.8, 0.2, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	display.add_theme_stylebox_override("panel", style)

## Update the intent display in the enemy panel
## STEP 1: Only showing ATTACK + damage number for now
func _update_intent_display(container: HBoxContainer, enemy: Character):
	# Clear existing intent display
	for child in container.get_children():
		child.queue_free()

	# Get enemy index
	var enemy_idx = game_manager.enemies.find(enemy)
	if enemy_idx == -1:
		return

	# Get intent from game manager
	if not game_manager.enemy_intents.has(enemy_idx):
		return

	var intent: EnemyIntent = game_manager.enemy_intents[enemy_idx]

	# STEP 1: Only show attack damage
	if intent.damage_amount > 0:
		var attack_label = Label.new()
		attack_label.text = "⚔ %d" % intent.damage_amount
		attack_label.add_theme_font_size_override("font_size", 20)
		attack_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(attack_label)

func update_turn_display():
	var my_index = game_manager.local_player_index
	if my_index >= 0 and my_index < game_manager.players.size():
		var my_character = game_manager.players[my_index]
		stamina_label.text = "Stamina: %d/%d" % [my_character.current_stamina, my_character.max_stamina]

	round_label.text = "Round: %d" % game_manager.round_number

	# Update turn label based on phase
	match game_manager.turn_phase:
		game_manager.TurnPhase.PLAYER_TURN:
			turn_label.text = "Your Turn"
		game_manager.TurnPhase.ENEMY_TURN:
			turn_label.text = "Enemy Turn"

func update_button_states():
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	# Update based on current turn phase
	match game_manager.turn_phase:
		game_manager.TurnPhase.PLAYER_TURN:
			phase_label.text = "Your Turn"
			ready_button.visible = true
			ready_button.text = "End Turn"
			pass_button.visible = false

			# Disable "End Turn" if already done
			var i_am_done = game_manager.players_done_acting.has(my_index)
			ready_button.disabled = i_am_done

			# Show done status
			var done_count = game_manager.players_done_acting.size()
			var total_alive = 0
			for player in game_manager.players:
				if player.is_alive():
					total_alive += 1
			ready_status_label.text = "Done: %d/%d" % [done_count, total_alive]

		game_manager.TurnPhase.ENEMY_TURN:
			phase_label.text = "Enemy Turn"
			ready_button.visible = false
			pass_button.visible = false
			ready_status_label.text = "Enemies Acting..."

func _on_player_turn_started(player_index: int):
	# Legacy signal - still emitted by old boss AI code
	# Just update displays for now
	update_all_displays()

func _on_boss_turn_started():
	# Legacy signal - still emitted by old boss AI code
	# Just update displays for now
	update_all_displays()

func _on_card_played(character: Character, card: Card, target: Character):
	update_all_displays()

func _on_game_state_changed():
	# Detect phase transitions
	var current_phase = game_manager.turn_phase
	last_turn_phase = current_phase
	update_all_displays()
	update_passive_button_visibility()

func _on_combat_ended(victory: bool):
	if victory:
		turn_label.text = "VICTORY!"
	else:
		turn_label.text = "DEFEAT!"

	ready_button.disabled = true
	pass_button.disabled = true

func _on_enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_player_index: int):
	# Spawn floating damage text above the damaged player's panel
	var panel_position = _get_player_panel_position(target_player_index)
	if panel_position != Vector2.ZERO:
		var floating_text = FloatingDamageText.new()
		add_child(floating_text)
		floating_text.show_damage(card_name, damage, panel_position)

func _get_player_panel_position(player_index: int) -> Vector2:
	# Determine which panel corresponds to this player index
	var my_index = game_manager.local_player_index

	# Get panel based on player relationship
	var panel: Panel = null

	if player_index == my_index:
		# This is your character
		panel = your_character_panel
	else:
		# Determine if this is left or right player
		var other_indices = []
		for i in range(game_manager.players.size()):
			if i != my_index:
				other_indices.append(i)

		if other_indices.size() > 0 and player_index == other_indices[0]:
			# Left player
			panel = left_player_panel
		elif other_indices.size() > 1 and player_index == other_indices[1]:
			# Right player
			panel = right_player_panel

	# Return position above the panel center
	if panel:
		return panel.global_position + Vector2(panel.size.x / 2, -20)
	else:
		return Vector2.ZERO

## Handle card dropped on player panel (drag-and-drop)
func _on_card_dropped_on_player_panel(card_data_dict: Dictionary, panel: Panel):
	var card: Card = card_data_dict["card"]
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	var my_character = game_manager.players[my_index]

	# Determine which character this panel represents
	var target_character: Character = null

	if panel == your_character_panel:
		# Dropped on own panel
		target_character = my_character
	elif panel == left_player_panel:
		# Dropped on left player
		var other_indices = []
		for i in range(game_manager.players.size()):
			if i != my_index:
				other_indices.append(i)
		if other_indices.size() > 0:
			target_character = game_manager.players[other_indices[0]]
	elif panel == right_player_panel:
		# Dropped on right player
		var other_indices = []
		for i in range(game_manager.players.size()):
			if i != my_index:
				other_indices.append(i)
		if other_indices.size() > 1:
			target_character = game_manager.players[other_indices[1]]

	if not target_character:
		return

	# Validate target type
	var valid_target = false
	match card.target_type:
		Card.TargetType.SELF:
			valid_target = (target_character == my_character)
		Card.TargetType.SINGLE_ALLY, Card.TargetType.ALL_ALLIES:
			valid_target = game_manager.players.has(target_character)
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.ALL_ENEMIES:
			valid_target = false  # Can't drop on player panel for enemy-target cards

	if not valid_target:
		print("[COMBAT] Invalid target for card: ", card.card_name)
		return

	# Validate stamina
	if my_character.current_stamina < card.stamina_cost:
		print("[COMBAT] Not enough stamina to play card")
		return

	# Play the card
	game_manager.play_card(my_character, card, target_character)

	# Clear preview since card was played
	game_manager.rpc("clear_card_preview", my_index)

	update_all_displays()

## Handle card dropped on enemy panel (drag-and-drop)
func _on_card_dropped_on_enemy_panel(card_data_dict: Dictionary, enemy: Character):
	var card: Card = card_data_dict["card"]
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	var my_character = game_manager.players[my_index]

	# Validate target type
	var valid_target = false
	match card.target_type:
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.ALL_ENEMIES, Card.TargetType.RANDOM_ENEMY:
			valid_target = game_manager.enemies.has(enemy)
		_:
			valid_target = false  # Can't drop ally-target cards on enemies

	if not valid_target:
		print("[COMBAT] Invalid target for card: ", card.card_name)
		return

	# Validate stamina
	if my_character.current_stamina < card.stamina_cost:
		print("[COMBAT] Not enough stamina to play card")
		return

	# Play the card
	game_manager.play_card(my_character, card, enemy)

	# Clear preview since card was played
	game_manager.rpc("clear_card_preview", my_index)

	update_all_displays()

## Handle card dropped on character face (self-targeting)
func _on_card_dropped_on_character_face(card_data_dict: Dictionary):
	var card: Card = card_data_dict["card"]
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	var my_character = game_manager.players[my_index]

	# Validate target type - only SELF cards allowed
	var valid_target = (card.target_type == Card.TargetType.SELF)

	if not valid_target:
		print("[COMBAT] Invalid target for character face - only SELF cards allowed: ", card.card_name)
		return

	# Validate stamina
	if my_character.current_stamina < card.stamina_cost:
		print("[COMBAT] Not enough stamina to play card")
		return

	# Play the card on self
	game_manager.play_card(my_character, card, my_character)

	# Clear preview since card was played
	game_manager.rpc("clear_card_preview", my_index)

	update_all_displays()

func _on_character_clicked(event: InputEvent, character: Character):
	if event is InputEventMouseButton and event.pressed:
		# Check if passive ability modal is awaiting target
		if passive_ability_modal.awaiting_target_selection:
			passive_ability_modal.on_target_selected(character)
			return

		# Try to handle target selection via card hand display
		if card_hand_display.on_character_clicked(character):
			update_all_displays()

func _on_ready_pressed():
	# Player ends their turn
	game_manager.player_done()
	card_hand_display.cancel_target_selection()
	update_button_states()

func _on_pass_pressed():
	# Player finishes their actions
	game_manager.player_done()
	card_hand_display.cancel_target_selection()
	update_button_states()

func _on_view_deck_pressed():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]
	deck_view_modal.show_deck(my_character)

func _on_passive_pressed():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]

	# Get the passive ability
	var ability = PassiveAbilityManager.get_ability(my_character.passive_ability_id)
	if not ability:
		print("[COMBAT] No passive ability found for: ", my_character.passive_ability_id)
		return

	# Check stamina cost
	if my_character.current_stamina < ability.stamina_cost:
		print("[COMBAT] Not enough stamina for passive ability")
		return

	# For ON_DEMAND CHOICE type abilities, show the modal
	if ability.trigger_type == PassiveAbility.TriggerType.ON_DEMAND and ability.effect_type == PassiveAbility.EffectType.CHOICE:
		passive_ability_modal.show_choice(my_character, game_manager.enemies, game_manager.players)
		var choice_result = await passive_ability_modal.choice_made

		# choice_result = [choice_index: int, target: Character]
		var choice_index = choice_result[0]
		var target = choice_result[1]

		# Send to server for processing
		if multiplayer.is_server():
			game_manager.apply_passive_ability(my_character, ability, choice_index, target)
		else:
			game_manager.rpc_id(1, "server_apply_passive_ability", my_index, ability.ability_id, choice_index, game_manager.get_character_network_id(target))

		update_all_displays()

	# Other trigger types or effects would be handled differently
	else:
		print("[COMBAT] Passive ability trigger type not yet supported: ", ability.trigger_type)

func _on_passive_awaiting_target(choice_index: int, valid_targets: Array[Character]):
	# Update turn label to instruct player
	var choice_name = ["Deal Damage", "Draw Card", "Give Shield"][choice_index]
	turn_label.text = "Select a target for: " + choice_name

func update_passive_button_visibility():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		passive_button.visible = false
		return

	var my_character = game_manager.players[my_index]

	# Only show during PLAYER_TURN phase
	if game_manager.turn_phase != game_manager.TurnPhase.PLAYER_TURN:
		passive_button.visible = false
		return

	# Only show if character has a passive ability
	if my_character.passive_ability_id.is_empty():
		passive_button.visible = false
		return

	# Check if already used this turn (based on uses_per_turn)
	var ability = PassiveAbilityManager.get_ability(my_character.passive_ability_id)
	if ability and ability.uses_per_turn > 0 and my_character.passive_ability_used_this_turn:
		passive_button.disabled = true
		passive_button.text = "Passive Used"
	else:
		passive_button.disabled = false
		passive_button.text = "Passive Ability"

	passive_button.visible = true

func _on_card_v2_choice_needed(caster: Character, card: Card, target: Character):
	# Show the modal with both versions
	card_v2_choice_modal.show_choice(card, card.v2_card)

	# Wait for player's choice
	var chosen_card = await card_v2_choice_modal.choice_made

	# Play the chosen version
	game_manager.play_card_version(caster, chosen_card, target)

func _on_card_retain_choice_needed(player_index: int, expires_after_round: int):
	# Only show modal for the local player
	if player_index != game_manager.local_player_index:
		return

	var player = game_manager.players[player_index]

	# Get cards that can be retained (exclude Dig a Hole itself since it was just played)
	var retainable_cards: Array[Card] = []
	for card in player.hand:
		if card.card_name != "Dig a Hole":
			retainable_cards.append(card)

	if retainable_cards.is_empty():
		print("[RETAIN] No cards to retain")
		return

	# Show card selection modal
	_show_card_retain_modal(player_index, retainable_cards, expires_after_round)

func _show_card_retain_modal(player_index: int, cards: Array[Card], expires_after_round: int):
	# Create modal UI dynamically
	var modal_bg = ColorRect.new()
	modal_bg.color = Color(0, 0, 0, 0.7)
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(700, 400)
	panel.offset_left = -350
	panel.offset_right = 350
	panel.offset_top = -200
	panel.offset_bottom = 200
	modal_bg.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Select a card to retain (until end of round " + str(expires_after_round) + ")"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var card_container = HBoxContainer.new()
	card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(card_container)

	# Add cards to the modal
	for card in cards:
		var card_visual = card_scene.instantiate()
		card_visual.custom_minimum_size = Vector2(120, 160)
		card_container.add_child(card_visual)
		card_visual.set_card(card)
		card_visual.set_playable(true)

		# Make card clickable for selection
		var button = Button.new()
		button.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.modulate = Color(1, 1, 1, 0)  # Invisible but clickable
		card_visual.add_child(button)
		button.pressed.connect(func():
			# Apply retention
			game_manager.apply_card_retention(player_index, card.card_name, expires_after_round)
			# Remove modal
			modal_bg.queue_free()
		)

	# Add cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel (No Retention)"
	cancel_btn.custom_minimum_size = Vector2(200, 40)
	vbox.add_child(cancel_btn)
	cancel_btn.pressed.connect(func():
		modal_bg.queue_free()
	)

func _on_boss_intent_revealed(card_names: Array[String]):
	# Show a notification with the boss's next turn cards
	var cards_text = ", ".join(card_names)

	# Create a simple notification panel
	var notification = Panel.new()
	notification.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification.custom_minimum_size = Vector2(400, 100)
	notification.offset_top = 80
	notification.offset_left = -200
	notification.offset_right = 200
	notification.offset_bottom = 180
	add_child(notification)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	notification.add_child(vbox)

	var title = Label.new()
	title.text = "Boss Intent Revealed!"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var cards_label = Label.new()
	cards_label.text = "Next turn: " + cards_text
	cards_label.add_theme_font_size_override("font_size", 14)
	cards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(cards_label)

	# Auto-hide after 5 seconds
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

func _on_enemy_intents_calculated(_intents: Dictionary):
	# Refresh enemy displays to show new intents
	# Also update player panels to show incoming attack warnings
	update_all_displays()
	player_status_panel.update_incoming_attacks(game_manager.enemy_intents)
