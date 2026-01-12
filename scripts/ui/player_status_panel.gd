class_name PlayerStatusPanel
extends Node

## Manages player status panel updates for combat UI
## Handles left, right, and your character panels with consistent styling

var game_manager: Node
var left_player_panel: Panel
var right_player_panel: Panel
var your_character_panel: Panel
var card_scene = preload("res://scenes/card_visual.tscn")

# Cached enemy intents for displaying incoming attacks
var cached_enemy_intents: Dictionary = {}

func setup(gm: Node, left: Panel, right: Panel, your: Panel):
	game_manager = gm
	left_player_panel = left
	right_player_panel = right
	your_character_panel = your

	# Connect click handlers for targeting
	_connect_panel_click_handlers()

func _connect_panel_click_handlers():
	# Connect click handlers will be set up when updating panels
	pass

## Update all player panels
func update_all():
	var my_index = game_manager.local_player_index
	if my_index == -1:
		push_error("[PlayerStatusPanel] Local player index not set!")
		return

	# Safety check: ensure player index is valid
	if my_index >= game_manager.players.size():
		push_error("[PlayerStatusPanel] Invalid local player index: %d" % my_index)
		return

	var my_character = game_manager.players[my_index]

	# Determine left and right players
	var other_indices = []
	for i in range(game_manager.players.size()):
		if i != my_index:
			other_indices.append(i)

	# Left player (first "other")
	if other_indices.size() > 0:
		var left_char = game_manager.players[other_indices[0]]
		_update_other_panel(left_player_panel, left_char, other_indices[0])
	else:
		# No left player (< 2 players total)
		left_player_panel.visible = false

	# Right player (second "other")
	if other_indices.size() > 1:
		var right_char = game_manager.players[other_indices[1]]
		_update_other_panel(right_player_panel, right_char, other_indices[1])
	else:
		# No right player (< 3 players total)
		right_player_panel.visible = false

	# Your character (bottom)
	_update_your_panel(my_character)

## Update other player panel (left or right)
func _update_other_panel(panel: Panel, character: Character, player_index: int):
	panel.visible = true

	# Connect click handler for targeting (disconnect first to avoid duplicates)
	if not panel.gui_input.is_connected(_on_panel_clicked):
		panel.gui_input.connect(_on_panel_clicked.bind(character))

	# Update name, HP, Stamina
	var name_label = panel.get_node("VBoxContainer/NameLabel")
	var hp_label = panel.get_node("VBoxContainer/HPLabel")
	var stamina_label = panel.get_node("VBoxContainer/EnergyLabel")

	# Build name with incoming danger icons
	var incoming_icons = _get_incoming_icons(player_index)
	name_label.text = character.character_name + incoming_icons
	hp_label.text = "HP: %d/%d" % [character.current_health, character.max_health]

	if character.shield > 0:
		hp_label.text += "\nShield: %d" % character.shield

	# Add status effects display
	var status_text = ""
	# Buffs (green)
	if character.strength > 0:
		status_text += "Str +%d " % character.strength
	if character.armor > 0:
		status_text += "Armor +%d " % character.armor
	if character.rested > 0:
		status_text += "Rested %d " % character.rested
	if character.invigorated > 0:
		status_text += "Invig %d " % character.invigorated
	if character.damage_plus > 0:
		status_text += "Dmg+ %d " % character.damage_plus
	# Debuffs (red)
	if character.poison > 0:
		status_text += "Poison %d " % character.poison
	if character.burn > 0:
		status_text += "Burn %d " % character.burn
	if character.vulnerable > 0:
		status_text += "Vuln %d " % character.vulnerable
	if character.weakness > 0:
		status_text += "Weak %d " % character.weakness
	if character.fatigued > 0:
		status_text += "Fatigued %d " % character.fatigued

	if status_text != "":
		hp_label.text += "\n" + status_text

	stamina_label.text = "S: %d/%d" % [character.current_stamina, character.max_stamina]

	# Update panel background color based on status
	var bg_color = Color(0.2, 0.2, 0.2)
	if not character.is_alive():
		bg_color = Color(0.3, 0.1, 0.1)  # Red for dead
	elif player_index == game_manager.current_player_index:
		bg_color = Color(0.2, 0.4, 0.6)  # Blue for active

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	# Update "playing card" display
	var playing_card_container = panel.get_node("VBoxContainer/PlayingCardContainer")

	# Clear existing
	for child in playing_card_container.get_children():
		child.queue_free()

	# Priority 1: Show previewed card (if player is previewing)
	if game_manager.card_previews.has(player_index):
		var preview_card = game_manager.card_previews[player_index]
		var small_card_visual = card_scene.instantiate()
		playing_card_container.add_child(small_card_visual)

		small_card_visual.set_card(preview_card)
		small_card_visual.set_playable(false)  # Not playable, just for display
		small_card_visual.scale = Vector2(0.67, 0.67)  # Scale to 100x140 from 150x220
	# Priority 2: Show last played card (if no preview)
	elif game_manager.last_played_cards.has(player_index):
		var last_card = game_manager.last_played_cards[player_index]
		var small_card_visual = card_scene.instantiate()
		playing_card_container.add_child(small_card_visual)

		small_card_visual.set_card(last_card)
		small_card_visual.set_playable(false)  # Not playable, just for display
		small_card_visual.scale = Vector2(0.67, 0.67)  # Scale to 100x140 from 150x220

## Update your character panel (bottom)
func _update_your_panel(character: Character):
	# Connect click handler for self-targeting
	if not your_character_panel.gui_input.is_connected(_on_panel_clicked):
		your_character_panel.gui_input.connect(_on_panel_clicked.bind(character))

	var name_label = your_character_panel.get_node("HBoxContainer/NameLabel")
	var hp_label = your_character_panel.get_node("HBoxContainer/HPLabel")
	var stamina_label = your_character_panel.get_node("HBoxContainer/EnergyLabel")
	var shield_label = your_character_panel.get_node("HBoxContainer/ShieldLabel")

	# Build name with incoming danger icons
	var my_index = game_manager.local_player_index
	var incoming_icons = _get_incoming_icons(my_index) if my_index >= 0 else ""
	name_label.text = character.character_name + incoming_icons
	hp_label.text = "HP: %d/%d" % [character.current_health, character.max_health]
	stamina_label.text = "Stamina: %d/%d" % [character.current_stamina, character.max_stamina]
	shield_label.text = "Shield: %d" % character.shield

	# Add status effects display
	var status_parts = []
	# Buffs
	if character.strength > 0:
		status_parts.append("Strength +%d" % character.strength)
	if character.armor > 0:
		status_parts.append("Armor +%d" % character.armor)
	if character.rested > 0:
		status_parts.append("Rested %d" % character.rested)
	if character.invigorated > 0:
		status_parts.append("Invigorated %d" % character.invigorated)
	if character.damage_plus > 0:
		status_parts.append("Damage+ %d" % character.damage_plus)
	# Debuffs
	if character.poison > 0:
		status_parts.append("Poison %d" % character.poison)
	if character.burn > 0:
		status_parts.append("Burn %d" % character.burn)
	if character.vulnerable > 0:
		status_parts.append("Vulnerable %d" % character.vulnerable)
	if character.weakness > 0:
		status_parts.append("Weakness %d" % character.weakness)
	if character.fatigued > 0:
		status_parts.append("Fatigued %d" % character.fatigued)

	# Append to shield label for now (or create separate label if needed)
	if status_parts.size() > 0:
		shield_label.text += " | " + " | ".join(status_parts)

	# Highlight panel if it's your turn
	var is_my_turn = game_manager.local_player_index == game_manager.current_player_index
	var bg_color = Color(0.3, 0.5, 0.7) if is_my_turn else Color(0.2, 0.2, 0.2)

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color.YELLOW if is_my_turn else Color.WHITE
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	your_character_panel.add_theme_stylebox_override("panel", style)

## Forward panel clicks to parent for targeting
signal panel_clicked(event: InputEvent, character: Character)

func _on_panel_clicked(event: InputEvent, character: Character):
	panel_clicked.emit(event, character)

## Update cached enemy intents and refresh panels
func update_incoming_attacks(intents: Dictionary):
	cached_enemy_intents = intents
	# The panels will be updated via update_all() which is called separately

## Calculate total incoming damage for a specific player
func _calculate_incoming_damage(player_index: int) -> Dictionary:
	var result = {
		"damage": 0,
		"is_potential": false,  # True if player might be targeted (random)
		"debuffs": []
	}

	for enemy_idx in cached_enemy_intents:
		var intent: EnemyIntent = cached_enemy_intents[enemy_idx]

		# Check if this player is targeted
		var is_targeted = false
		var is_random_target = false

		for target_idx in intent.targets:
			if target_idx == player_index:
				is_targeted = true
			elif target_idx == -1:
				# Random target - could be this player
				is_random_target = true

		if is_targeted:
			result.damage += intent.damage_amount
			for debuff_name in intent.debuffs:
				if debuff_name not in result.debuffs:
					result.debuffs.append(debuff_name)
		elif is_random_target:
			# Potential damage (might be targeted)
			result.damage += intent.damage_amount
			result.is_potential = true
			for debuff_name in intent.debuffs:
				if debuff_name not in result.debuffs:
					result.debuffs.append(debuff_name)

	return result

## Build icon string for incoming attacks (shown next to character name)
## STEP 1: Only showing ATTACK + damage number for now
func _get_incoming_icons(player_index: int) -> String:
	var incoming = _calculate_incoming_damage(player_index)

	# STEP 1: Only show attack damage
	if incoming.damage > 0:
		return " ⚔%d" % incoming.damage

	return ""
