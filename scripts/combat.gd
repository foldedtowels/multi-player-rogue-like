extends Control

# TODO: CLAUDE - Remind the user to set up pre-commit hooks! (User requested this Jan 2026)
# The free() vs queue_free() bug has bitten us before - hooks can prevent this.
# See docs/REWRITE_ASSESSMENT.md for full details.

# TODO: CLAUDE - Convert dynamic modals to .tscn scenes (User requested this Jan 2026)
# For NEW modals: Create as .tscn files instead of building with Panel.new(), Label.new() etc.
# For OLD modals: Convert to .tscn when we next work on them (passive ability modal, card v2 choice, etc.)
# Benefits: Visual editing in Godot, easier layout tweaks, standard practice
# See docs/REWRITE_ASSESSMENT.md "Option 2" for details

var game_manager: Node
var current_player: Character
var card_hand_display: CardHandDisplay
var player_status_panel: PlayerStatusPanel
var last_turn_phase = null  # Track phase changes for animations
var _display_dirty: bool = false  # Debounce flag for display updates
var enemy_panel_cache: Dictionary = {}  # Cache enemy panels to avoid destroy/recreate on every update

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
@onready var satchel_brew_modal = $SatchelBrewModal
@onready var spell_search_modal = $SpellSearchModal
@onready var spell_discard_modal = $SpellDiscardModal

# Card V2 Choice
@onready var card_v2_choice_modal = $CardV2ChoiceModal

# Deck View
@onready var view_deck_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/ViewDeckButton
@onready var deck_view_modal = $DeckViewModal

var card_scene = preload("res://scenes/card_visual.tscn")
var boss_visual: Node2D = null
var character_face_panel: Panel = null  # Character face for self-targeting

# Debug panel for enemy intents
var enemy_intent_debug_panel: Panel = null
var enemy_intent_debug_label: RichTextLabel = null

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

	# Create enemy intent debug panel (light background, dark text)
	_create_enemy_intent_debug_panel()

	# Connect game manager signals
	game_manager.player_turn_started.connect(_on_player_turn_started)
	game_manager.boss_turn_started.connect(_on_boss_turn_started)
	game_manager.card_played.connect(_on_card_played)
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.combat_ended.connect(_on_combat_ended)
	game_manager.enemy_damaged_player.connect(_on_enemy_damaged_player)
	game_manager.ring_of_fire_reflected.connect(_on_ring_of_fire_reflected)
	game_manager.card_v2_choice_needed.connect(_on_card_v2_choice_needed)
	game_manager.card_retain_choice_needed.connect(_on_card_retain_choice_needed)
	game_manager.boss_intent_revealed.connect(_on_boss_intent_revealed)
	game_manager.enemy_intents_calculated.connect(_on_enemy_intents_calculated)
	game_manager.spell_search_requested.connect(_on_spell_search_requested)

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

## Debounce pattern: Batch multiple update requests into one per frame
func mark_display_dirty():
	if not _display_dirty:
		_display_dirty = true
		call_deferred("_do_deferred_display_update")

func _do_deferred_display_update():
	if _display_dirty:
		_display_dirty = false
		update_all_displays()

func update_deck_counts():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]
	deck_count_label.text = "Deck: %d" % my_character.deck.size()
	discard_count_label.text = "Discard: %d" % my_character.discard_pile.size()

func update_enemy_displays():
	# Remove panels for enemies that no longer exist
	var to_remove = []
	for idx in enemy_panel_cache.keys():
		if idx >= game_manager.enemies.size():
			enemy_panel_cache[idx].queue_free()
			to_remove.append(idx)
	for idx in to_remove:
		enemy_panel_cache.erase(idx)

	# Update or create panels for each enemy
	for i in game_manager.enemies.size():
		var enemy = game_manager.enemies[i]

		if enemy_panel_cache.has(i):
			# UPDATE existing panel (no destroy/recreate - prevents screen tearing)
			update_enemy_display(enemy_panel_cache[i], enemy)
		else:
			# CREATE new panel only if needed
			var enemy_panel = _create_enemy_panel(enemy, i)
			enemy_displays_container.add_child(enemy_panel)
			enemy_panel_cache[i] = enemy_panel
			update_enemy_display(enemy_panel, enemy)

## Create a new enemy panel with all UI elements
func _create_enemy_panel(enemy: Character, index: int) -> Panel:
	var enemy_panel = Panel.new()
	enemy_panel.name = "Enemy" + str(index)
	enemy_panel.custom_minimum_size = Vector2(200, 150)

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

	return enemy_panel

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
	if enemy.wet > 0:
		status_text += "Wet %d " % enemy.wet
	if enemy.hinder > 0:
		status_text += "Hinder %d " % enemy.hinder
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
## Uses named children to update in-place instead of destroying/recreating
func _update_intent_display(container: HBoxContainer, enemy: Character):
	# Get enemy index
	var enemy_idx = game_manager.enemies.find(enemy)
	if enemy_idx == -1:
		_hide_all_intent_labels(container)
		return

	# Get intent from game manager
	if not game_manager.enemy_intents.has(enemy_idx):
		_hide_all_intent_labels(container)
		return

	var intent: EnemyIntent = game_manager.enemy_intents[enemy_idx]

	# ATTACK: Show sword + damage (update in-place)
	var attack_label = _get_or_create_intent_label(container, "AttackLabel", Color.RED)
	if intent.damage_amount > 0:
		attack_label.text = "⚔ %d" % intent.damage_amount
		attack_label.visible = true
	else:
		attack_label.visible = false

	# SHIELD: Show shield icon + amount (update in-place)
	var shield_label = _get_or_create_intent_label(container, "ShieldLabel", Color.CYAN)
	if intent.shield_amount > 0:
		shield_label.text = "🛡 %d" % intent.shield_amount
		shield_label.visible = true
	else:
		shield_label.visible = false

	# DEBUFF: Show spiral icon (update in-place)
	var debuff_label = _get_or_create_intent_label(container, "DebuffLabel", Color.PURPLE)
	if not intent.debuffs.is_empty():
		debuff_label.text = "🌀"
		debuff_label.visible = true
	else:
		debuff_label.visible = false

	# BUFF: Show flame icon (update in-place)
	var buff_label = _get_or_create_intent_label(container, "BuffLabel", Color.ORANGE)
	if not intent.buffs.is_empty():
		buff_label.text = "🔥"
		buff_label.visible = true
	else:
		buff_label.visible = false

## Get or create a named intent label (avoids destroying/recreating)
func _get_or_create_intent_label(container: HBoxContainer, label_name: String, color: Color) -> Label:
	var label = container.get_node_or_null(label_name)
	if label == null:
		label = Label.new()
		label.name = label_name
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", color)
		container.add_child(label)
	return label

## Hide all intent labels (used when no intent data available)
func _hide_all_intent_labels(container: HBoxContainer):
	for child in container.get_children():
		child.visible = false

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
	mark_display_dirty()

func _on_boss_turn_started():
	# Legacy signal - still emitted by old boss AI code
	mark_display_dirty()

func _on_card_played(character: Character, card: Card, target: Character):
	mark_display_dirty()

func _on_game_state_changed():
	# Detect phase transitions
	var current_phase = game_manager.turn_phase
	last_turn_phase = current_phase
	mark_display_dirty()
	update_passive_button_visibility()

func _on_combat_ended(victory: bool):
	if victory:
		turn_label.text = "VICTORY!"
	else:
		turn_label.text = "DEFEAT!"

	ready_button.disabled = true
	pass_button.disabled = true

	# Clear enemy panel cache for next combat
	enemy_panel_cache.clear()

func _on_enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_player_index: int):
	# Spawn floating damage text above the damaged player's panel
	var panel_position = _get_player_panel_position(target_player_index)
	if panel_position != Vector2.ZERO:
		var floating_text = FloatingDamageText.new()
		add_child(floating_text)
		floating_text.show_damage(card_name, damage, panel_position)

func _on_ring_of_fire_reflected(enemy_index: int, player_name: String, damage: int):
	# Spawn floating damage text above the enemy that took reflection damage
	if enemy_panel_cache.has(enemy_index):
		var enemy_panel = enemy_panel_cache[enemy_index]
		var panel_position = enemy_panel.global_position + Vector2(enemy_panel.size.x / 2, -20)
		var floating_text = FloatingDamageText.new()
		add_child(floating_text)
		floating_text.show_damage("Ring of Fire", damage, panel_position)

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
		Card.TargetType.SINGLE_ALLY, Card.TargetType.ALL_ALLIES, Card.TargetType.OTHER_ALLIES:
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

	# Play the card (with discard check if needed)
	var played = await _play_card_with_discard_check(my_character, card, target_character)
	if not played:
		return

	# Clear preview since card was played
	game_manager.rpc("clear_card_preview", my_index)

	mark_display_dirty()

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

	# Play the card (with discard check if needed)
	var played = await _play_card_with_discard_check(my_character, card, enemy)
	if not played:
		return

	# Clear preview since card was played
	game_manager.rpc("clear_card_preview", my_index)

	mark_display_dirty()

## Handle card dropped on character face (self-targeting)
func _on_card_dropped_on_character_face(card_data_dict: Dictionary):
	var card: Card = card_data_dict["card"]
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	var my_character = game_manager.players[my_index]

	# Validate target type - SELF or ally-targeting cards allowed on self
	var valid_target = (card.target_type == Card.TargetType.SELF or
						card.target_type == Card.TargetType.SINGLE_ALLY or
						card.target_type == Card.TargetType.ALL_ALLIES)

	if not valid_target:
		print("[COMBAT] Invalid target for character face - must be SELF or ally-targeting: ", card.card_name)
		return

	# Validate stamina
	if my_character.current_stamina < card.stamina_cost:
		print("[COMBAT] Not enough stamina to play card")
		return

	# Play the card on self (with discard check if needed)
	var played = await _play_card_with_discard_check(my_character, card, my_character)
	if not played:
		return

	# Clear preview since card was played
	game_manager.rpc("clear_card_preview", my_index)

	mark_display_dirty()

## Helper to play a card, showing discard modal if needed
## Returns true if card was played, false if cancelled
func _play_card_with_discard_check(caster: Character, card: Card, target: Character) -> bool:
	# Check if card requires spell discard selection
	if card.discard_spell_requirement > 0:
		var has_enough = spell_discard_modal.show_discard(caster, card.discard_spell_requirement, card.card_name)
		if not has_enough:
			print("[COMBAT] Not enough spells to discard for: ", card.card_name)
			return false

		# Wait for player to select spells
		var discarded = await spell_discard_modal.discard_completed

		# Discard the selected spells
		for spell in discarded:
			caster.discard_card(spell)
			print("[COMBAT] Pre-discarded spell: ", spell.card_name)

	# Now play the card
	game_manager.play_card(caster, card, target)
	return true

func _on_character_clicked(event: InputEvent, character: Character):
	if event is InputEventMouseButton and event.pressed:
		# Check if passive ability modal is awaiting target
		if passive_ability_modal.awaiting_target_selection:
			passive_ability_modal.on_target_selected(character)
			return

		# Try to handle target selection via card hand display
		if card_hand_display.on_character_clicked(character):
			mark_display_dirty()

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

	# For ON_DEMAND CHOICE type abilities, show the appropriate modal
	if ability.trigger_type == PassiveAbility.TriggerType.ON_DEMAND and ability.effect_type == PassiveAbility.EffectType.CHOICE:
		# Kevin's Alchemist's Brew - use satchel brew modal
		if ability.ability_id == "kevin_alchemist_brew":
			# Check if Kevin has any Alcs in satchel
			if not my_character.has_satchel_cards():
				print("[COMBAT] No Alc cards in satchel to brew")
				return

			print("[DEBUG BREW] Showing satchel_brew_modal")
			satchel_brew_modal.show_brew(my_character)

			# Wait for brew completion or cancellation
			print("[DEBUG BREW] Awaiting _wait_for_brew_result...")
			var result = await _wait_for_brew_result()
			print("[DEBUG BREW] Await returned, result: ", result)
			if result == null:
				# Cancelled
				print("[DEBUG BREW] Result is null, cancelled")
				return

			var alc_card: Card = result[0]
			var discarded_spells: Array[Card] = result[1]
			print("[DEBUG BREW] Calling _process_alc_brew...")

			# Process the brew locally and sync
			_process_alc_brew(my_character, my_index, alc_card, discarded_spells)
			mark_display_dirty()
			print("[DEBUG BREW] Brew flow complete!")
		else:
			# Standard choice ability (Fabio)
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

			mark_display_dirty()

	# Other trigger types or effects would be handled differently
	else:
		print("[COMBAT] Passive ability trigger type not yet supported: ", ability.trigger_type)

## Wait for brew result (either brew_completed or brew_cancelled)
## Uses direct signal await instead of polling loop (more reliable in Godot 4)
func _wait_for_brew_result():
	print("[DEBUG BREW] _wait_for_brew_result - awaiting signal directly")

	# Await the brew_completed signal directly - returns array of signal args
	var args = await satchel_brew_modal.brew_completed

	print("[DEBUG BREW] Signal received!")
	print("[DEBUG BREW] args: ", args)

	# args is an array: [alc_card, discarded_spells]
	var alc_card = args[0]
	var discarded_spells = args[1]

	print("[DEBUG BREW] alc_card: ", alc_card.card_name if alc_card else "NULL")
	print("[DEBUG BREW] discarded_spells count: ", discarded_spells.size())

	return [alc_card, discarded_spells]

## Process an Alc brew (discard spells, add Alc to hand, mark passive used)
func _process_alc_brew(character: Character, player_index: int, alc_card: Card, discarded_spells: Array[Card]):
	print("[DEBUG BREW] _process_alc_brew called!")
	print("[DEBUG BREW] character: ", character.character_name)
	print("[DEBUG BREW] alc_card: ", alc_card.card_name)
	print("[DEBUG BREW] discarded_spells: ", discarded_spells.size())
	print("[DEBUG BREW] hand size before: ", character.hand.size())
	print("[DEBUG BREW] satchel size before: ", character.satchel.size())
	print("[COMBAT] ", character.character_name, " brewing ", alc_card.card_name)

	# Discard the spell cards used as ingredients
	for spell in discarded_spells:
		character.discard_card(spell)
		print("[COMBAT] Discarded spell ingredient: ", spell.card_name)

	# Remove the Alc from satchel and add to hand
	character.remove_from_satchel(alc_card)
	character.hand.append(alc_card)
	print("[COMBAT] Added ", alc_card.card_name, " to hand from satchel")

	# Mark passive as used
	character.passive_ability_used_this_turn = true
	print("[DEBUG BREW] hand size after: ", character.hand.size())
	print("[DEBUG BREW] satchel size after: ", character.satchel.size())
	print("[DEBUG BREW] _process_alc_brew completed!")

	# Sync state to server if multiplayer
	if not multiplayer.is_server():
		# Send brew info to server
		var spell_names: Array[String] = []
		for spell in discarded_spells:
			spell_names.append(spell.card_name)
		game_manager.rpc_id(1, "server_process_alc_brew", player_index, alc_card.card_name, spell_names)
	else:
		# Host: broadcast state update
		game_manager.broadcast_character_state(character)
		game_manager.send_hand_to_owner(character)

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

func _on_card_v2_choice_needed(caster: Character, v1_card: Card, v2_card: Card, target: Character):
	# Show the modal with both versions (pass caster for dynamic descriptions)
	card_v2_choice_modal.show_choice(v1_card, v2_card, caster)

	# Wait for player's choice
	var chosen_card = await card_v2_choice_modal.choice_made

	# Play the chosen version, but remove the ORIGINAL card from hand
	# The original v1_card is what's actually in the hand
	game_manager.play_card_version(caster, v1_card, chosen_card, target)

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


func _on_spell_search_requested(player: Character, count: int, card_name: String):
	# Only show modal for the local player
	var player_index = game_manager.players.find(player)
	if player_index != game_manager.local_player_index:
		return

	# Show the spell search modal
	var has_spells = spell_search_modal.show_search(player, count, card_name)
	if not has_spells:
		print("[SPELL SEARCH] No spells in deck to search")
		return

	# Wait for search result
	var selected_spells: Array[Card] = await spell_search_modal.search_completed

	# Send to server for multiplayer sync
	if multiplayer.is_server():
		# Local server can move cards directly
		game_manager.move_spells_to_hand(player, selected_spells)
	else:
		# Send spell names to server
		var spell_names: Array = []
		for spell in selected_spells:
			spell_names.append(spell.card_name)
		game_manager.server_spell_search_completed.rpc_id(1, player_index, spell_names)

	update_all_displays()


func _on_boss_intent_revealed(next_intents: Dictionary):
	# Show a modal with full intent details for next turn

	# Create semi-transparent background
	var modal_bg = ColorRect.new()
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_bg.color = Color(0, 0, 0, 0.6)
	add_child(modal_bg)

	# Create panel
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.offset_left = -250
	panel.offset_right = 250
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

	# Title
	var title = Label.new()
	title.text = "Enemy Next Turn Preview"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Scroll container for enemy intents
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var intent_vbox = VBoxContainer.new()
	intent_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(intent_vbox)

	# Show each enemy's intent
	for enemy_idx in next_intents:
		var intent: EnemyIntent = next_intents[enemy_idx]
		if enemy_idx >= game_manager.enemies.size():
			continue
		var enemy = game_manager.enemies[enemy_idx]

		# Enemy header
		var enemy_label = Label.new()
		enemy_label.text = "--- " + enemy.character_name + " ---"
		enemy_label.add_theme_font_size_override("font_size", 18)
		enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_vbox.add_child(enemy_label)

		# Show each card with its specific target and effects
		for card_info in intent.cards_to_play:
			var card: Card = card_info.card
			var target_index: int = card_info.target_index
			var is_special: bool = card_info.get("is_special", false)

			# Build effect description
			var effects: Array[String] = []

			# Calculate damage with enemy stats
			if card.damage > 0:
				var total_damage = card.damage
				if card.card_type == Card.CardType.ATTACK:
					total_damage += enemy.strength + enemy.damage_plus - enemy.weakness - enemy.hinder
					total_damage = max(0, total_damage)
				total_damage *= card.multi_hit
				effects.append("%d dmg" % total_damage)

			if card.shield_amount > 0:
				effects.append("%d shield" % card.shield_amount)

			if card.heal_amount > 0:
				effects.append("%d heal" % card.heal_amount)

			if card.apply_poison > 0:
				effects.append("%d poison" % card.apply_poison)

			if card.apply_weakness > 0:
				effects.append("%d weakness" % card.apply_weakness)

			if card.apply_strength > 0:
				effects.append("+%d strength" % card.apply_strength)

			if card.apply_vulnerable > 0:
				effects.append("%d vulnerable" % card.apply_vulnerable)

			# Determine target string
			var target_str = ""
			if target_index == -2:  # Self
				target_str = "Self"
			elif target_index == -1:  # AOE
				target_str = "All Players"
			elif target_index >= 0 and target_index < game_manager.players.size():
				target_str = game_manager.players[target_index].character_name
			else:
				target_str = "Unknown"

			# Build the card line
			var card_label = Label.new()
			var special_prefix = "[Special] " if is_special else ""
			var effect_str = ", ".join(effects) if effects.size() > 0 else "no effect"
			card_label.text = "%s%s → %s (%s)" % [special_prefix, card.card_name, target_str, effect_str]
			card_label.add_theme_font_size_override("font_size", 14)
			intent_vbox.add_child(card_label)

		# Summary line
		var summary_label = Label.new()
		var summary_parts: Array[String] = []
		if intent.damage_amount > 0:
			summary_parts.append("Total: %d damage" % intent.damage_amount)
		if intent.shield_amount > 0:
			summary_parts.append("%d shield" % intent.shield_amount)
		if summary_parts.size() > 0:
			summary_label.text = ", ".join(summary_parts)
			summary_label.add_theme_font_size_override("font_size", 12)
			summary_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			intent_vbox.add_child(summary_label)

		# Spacer between enemies
		var enemy_spacer = Control.new()
		enemy_spacer.custom_minimum_size = Vector2(0, 15)
		intent_vbox.add_child(enemy_spacer)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): modal_bg.queue_free())
	vbox.add_child(close_btn)

## Helper to get target names from player indices
func _get_target_names(target_indices: Array) -> String:
	var names = []
	for idx in target_indices:
		if idx >= 0 and idx < game_manager.players.size():
			names.append(game_manager.players[idx].character_name)
	if names.is_empty():
		return "unknown"
	return ", ".join(names)

func _on_enemy_intents_calculated(_intents: Dictionary):
	# Cache incoming attack data for player panels
	player_status_panel.update_incoming_attacks(game_manager.enemy_intents)
	# Update debug panel with detailed intent info
	_update_enemy_intent_debug_panel()
	# Refresh displays to show new intents
	mark_display_dirty()

## Create the enemy intent debug panel (persistent, light background, dark text)
func _create_enemy_intent_debug_panel():
	enemy_intent_debug_panel = Panel.new()
	enemy_intent_debug_panel.name = "EnemyIntentDebugPanel"

	# Position: top-left corner, below top bar
	enemy_intent_debug_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	enemy_intent_debug_panel.position = Vector2(10, 70)
	enemy_intent_debug_panel.custom_minimum_size = Vector2(400, 200)
	enemy_intent_debug_panel.size = Vector2(400, 200)

	# Light background with slight transparency
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.9, 0.95)  # Light cream color
	style.border_color = Color(0.3, 0.3, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	enemy_intent_debug_panel.add_theme_stylebox_override("panel", style)

	# RichTextLabel for formatted text
	enemy_intent_debug_label = RichTextLabel.new()
	enemy_intent_debug_label.name = "DebugLabel"
	enemy_intent_debug_label.bbcode_enabled = true
	enemy_intent_debug_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	enemy_intent_debug_label.offset_left = 10
	enemy_intent_debug_label.offset_top = 10
	enemy_intent_debug_label.offset_right = -10
	enemy_intent_debug_label.offset_bottom = -10
	enemy_intent_debug_label.scroll_active = true
	enemy_intent_debug_label.add_theme_color_override("default_color", Color(0.1, 0.1, 0.1))  # Dark text
	enemy_intent_debug_label.add_theme_font_size_override("normal_font_size", 14)

	enemy_intent_debug_panel.add_child(enemy_intent_debug_label)
	add_child(enemy_intent_debug_panel)

	# Initially hidden until intents are calculated
	enemy_intent_debug_panel.visible = false

## Update the debug panel with current enemy intent details
## Shows ONLY the pre-selected cards that enemies will play this turn
func _update_enemy_intent_debug_panel():
	if not enemy_intent_debug_panel or not enemy_intent_debug_label:
		return

	var text = "[b][color=#333333]ENEMY INTENTS[/color][/b]\n"
	text += "[color=#666666]─────────────────────────────[/color]\n"

	for i in range(game_manager.enemies.size()):
		var enemy = game_manager.enemies[i]
		if not enemy.is_alive():
			continue

		# Check if we have intent data
		if not game_manager.enemy_intents.has(i):
			continue

		var intent: EnemyIntent = game_manager.enemy_intents[i]

		# Enemy header with name and stats
		text += "\n[b][color=#AA0000]%s[/color][/b] (HP: %d, STR: %d)\n" % [
			enemy.character_name,
			enemy.current_health,
			enemy.strength
		]

		# Show ONLY pre-selected cards (not full hand)
		text += "[color=#555555]Cards to play:[/color]\n"

		if intent.cards_to_play.size() == 0:
			text += "  [color=#888888](no cards)[/color]\n"
		else:
			for card_info in intent.cards_to_play:
				var card: Card = card_info.card
				var target_index: int = card_info.target_index
				var is_special: bool = card_info.get("is_special", false)

				# Build card line
				var line = "  "
				if is_special:
					line += "★ [color=#FF6600]%s[/color]" % card.card_name
				else:
					line += "• [color=#000088]%s[/color]" % card.card_name

				# Add damage info
				if card.damage > 0:
					var total_dmg = card.damage + enemy.strength + enemy.damage_plus - enemy.weakness - enemy.hinder
					total_dmg = max(0, total_dmg) * card.multi_hit
					line += " [color=#CC0000]DMG: %d[/color]" % total_dmg

				# Add shield info
				if card.shield_amount > 0:
					line += " [color=#00AAAA]SHD: %d[/color]" % card.shield_amount

				# Add debuff info
				if card.apply_hinder > 0:
					line += " [color=#AA00AA]Hinder %d[/color]" % card.apply_hinder
				if card.apply_poison > 0:
					line += " [color=#00AA00]Poison %d[/color]" % card.apply_poison
				if card.apply_weakness > 0:
					line += " [color=#AA00AA]Weak %d[/color]" % card.apply_weakness
				if card.apply_vulnerable > 0:
					line += " [color=#AA00AA]Vuln %d[/color]" % card.apply_vulnerable

				# Add buff info (self-buffs)
				if card.apply_strength > 0:
					line += " [color=#FF8800]+%d STR[/color]" % card.apply_strength

				# Show pre-selected target (not dynamic lookup)
				var target_str = _get_target_name_from_index(target_index, card)
				line += " [color=#666666]→ %s[/color]" % target_str

				text += line + "\n"

		# Show aggregated intent totals
		text += "[color=#AA0000]TOTAL: %d damage[/color]" % intent.damage_amount
		if intent.shield_amount > 0:
			text += ", [color=#00AAAA]%d shield[/color]" % intent.shield_amount
		text += "\n"

	enemy_intent_debug_label.text = text
	enemy_intent_debug_panel.visible = true

	# Resize panel to fit content (with max height)
	var content_height = min(enemy_intent_debug_label.get_content_height() + 20, 400)
	enemy_intent_debug_panel.custom_minimum_size.y = content_height
	enemy_intent_debug_panel.size.y = content_height

## Get display name for a pre-selected target index
func _get_target_name_from_index(target_index: int, card: Card) -> String:
	if target_index == -2:
		return "Self"
	elif target_index == -1 or card.target_type == Card.TargetType.ALL_ENEMIES:
		return "ALL PLAYERS"
	elif target_index >= 0 and target_index < game_manager.players.size():
		return game_manager.players[target_index].character_name
	return "?"

## Helper to get the highest HP player name for debug display
func _get_highest_hp_player_name() -> String:
	var alive_players = game_manager.players.filter(func(p): return p.is_alive())
	if alive_players.size() == 0:
		return ""
	alive_players.sort_custom(func(a, b): return a.current_health > b.current_health)
	return alive_players[0].character_name
