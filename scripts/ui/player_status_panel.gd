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

# Cache for StyleBoxFlat objects to prevent creating new ones each update
var _style_cache: Dictionary = {}

# Cache to detect when panel state has actually changed
var _panel_signatures: Dictionary = {}

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

## Get or create a cached StyleBoxFlat for the given color
func _get_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var cache_key = "%s_%s_%d" % [bg_color.to_html(), border_color.to_html(), border_width]
	if not _style_cache.has(cache_key):
		var style = StyleBoxFlat.new()
		style.bg_color = bg_color
		style.border_color = border_color
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		_style_cache[cache_key] = style
	return _style_cache[cache_key]

## Generate a signature for the panel state to detect changes
func _get_panel_signature(character: Character, player_index: int, preview_card_name: String, last_played_card_name: String) -> String:
	var parts: Array[String] = []
	parts.append(character.character_name)
	parts.append("hp:" + str(character.current_health))
	parts.append("maxhp:" + str(character.max_health))
	parts.append("shield:" + str(character.shield))
	parts.append("stam:" + str(character.current_stamina))
	parts.append("maxstam:" + str(character.max_stamina))
	parts.append("alive:" + str(character.is_alive()))
	parts.append("curr:" + str(game_manager.current_player_index == player_index))
	parts.append("preview:" + preview_card_name)
	parts.append("lastplayed:" + last_played_card_name)
	# Add ALL status effects to signature (so UI updates when any effect changes)
	parts.append("str:" + str(character.strength))
	parts.append("armor:" + str(character.armor))
	parts.append("poison:" + str(character.poison))
	parts.append("burn:" + str(character.burn))
	parts.append("vuln:" + str(character.vulnerable))
	parts.append("weak:" + str(character.weakness))
	parts.append("fatigued:" + str(character.fatigued))
	parts.append("hinder:" + str(character.hinder))
	parts.append("rested:" + str(character.rested))
	parts.append("invig:" + str(character.invigorated))
	parts.append("dmgplus:" + str(character.damage_plus))
	parts.append("exh:" + str(character.exhausted))
	parts.append("scared:" + str(character.scared))
	parts.append("decay:" + str(character.decay))
	parts.append("rof:" + str(character.ring_of_fire))
	parts.append("wet:" + str(character.wet))
	parts.append("played_twice:" + str(character.played_twice))
	parts.append("invincible:" + str(character.invincible))
	parts.append("aura:" + str(character.current_aura))
	# Include incoming damage calculation
	var incoming = _get_incoming_icons(player_index)
	parts.append("incoming:" + incoming)
	return "|".join(parts)

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

	# Get preview/last played card names for signature
	var preview_card_name = ""
	var last_played_card_name = ""
	if game_manager.card_previews.has(player_index):
		preview_card_name = game_manager.card_previews[player_index].card_name
	if game_manager.last_played_cards.has(player_index):
		last_played_card_name = game_manager.last_played_cards[player_index].card_name

	# Check if panel state has changed (skip update if unchanged to prevent tearing)
	var panel_key = "other_" + str(player_index)
	var new_signature = _get_panel_signature(character, player_index, preview_card_name, last_played_card_name)
	if _panel_signatures.get(panel_key, "") == new_signature:
		return  # No changes, skip update
	_panel_signatures[panel_key] = new_signature

	# Update name, HP, Stamina
	var name_label = panel.get_node("VBoxContainer/NameLabel")
	var hp_label = panel.get_node("VBoxContainer/HPLabel")
	var stamina_label = panel.get_node("VBoxContainer/EnergyLabel")

	# Name without icons
	name_label.text = character.character_name
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
	if character.ring_of_fire > 0:
		status_text += "RoF %d " % character.ring_of_fire
	if character.played_twice > 0:
		status_text += "x2 %d " % character.played_twice
	if character.invincible > 0:
		status_text += "Invincible "
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
	if character.hinder > 0:
		status_text += "Hinder %d " % character.hinder
	if character.scared > 0:
		status_text += "SCARED "
	if character.decay > 0:
		status_text += "Decay %d " % character.decay
	if character.exhausted > 0:
		status_text += "Exh %d " % character.exhausted
	if character.wet > 0:
		status_text += "Wet %d " % character.wet
	# Check if this player is protected by another player
	if game_manager.protected_by.has(player_index):
		status_text += "🛡PROTECTED "

	if status_text != "":
		hp_label.text += "\n" + status_text

	stamina_label.text = "S: %d/%d" % [character.current_stamina, character.max_stamina]

	# Show Aura for characters that have it (Enrique)
	if character.max_aura > 0:
		stamina_label.text += " | A: %d" % character.current_aura

	# Add incoming attack icons below stamina
	var incoming_icons = _get_incoming_icons(player_index)
	if incoming_icons != "":
		stamina_label.text += "\n" + incoming_icons

	# Update panel background color based on status (use cached StyleBoxFlat)
	var bg_color = Color(0.2, 0.2, 0.2)
	if not character.is_alive():
		bg_color = Color(0.3, 0.1, 0.1)  # Red for dead
	elif player_index == game_manager.current_player_index:
		bg_color = Color(0.2, 0.4, 0.6)  # Blue for active

	var style = _get_panel_style(bg_color, Color.WHITE, 2)
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
		small_card_visual.set_card_owner(character)  # For card background color
		small_card_visual.set_playable(false)  # Not playable, just for display
		small_card_visual.scale = Vector2(0.67, 0.67)  # Scale to 100x140 from 150x220
	# Priority 2: Show last played card (if no preview)
	elif game_manager.last_played_cards.has(player_index):
		var last_card = game_manager.last_played_cards[player_index]
		var small_card_visual = card_scene.instantiate()
		playing_card_container.add_child(small_card_visual)

		small_card_visual.set_card(last_card)
		small_card_visual.set_card_owner(character)  # For card background color
		small_card_visual.set_playable(false)  # Not playable, just for display
		small_card_visual.scale = Vector2(0.67, 0.67)  # Scale to 100x140 from 150x220

## Update your character panel (bottom)
func _update_your_panel(character: Character):
	# Connect click handler for self-targeting
	if not your_character_panel.gui_input.is_connected(_on_panel_clicked):
		your_character_panel.gui_input.connect(_on_panel_clicked.bind(character))

	var my_index = game_manager.local_player_index

	# Check if panel state has changed (skip update if unchanged to prevent tearing)
	var panel_key = "your_" + str(my_index)
	var new_signature = _get_panel_signature(character, my_index, "", "")
	if _panel_signatures.get(panel_key, "") == new_signature:
		return  # No changes, skip update
	_panel_signatures[panel_key] = new_signature

	var name_label = your_character_panel.get_node("HBoxContainer/NameLabel")
	var hp_label = your_character_panel.get_node("HBoxContainer/HPLabel")
	var stamina_label = your_character_panel.get_node("HBoxContainer/EnergyLabel")
	var shield_label = your_character_panel.get_node("HBoxContainer/ShieldLabel")

	# Name without icons (icons go after stamina)
	name_label.text = character.character_name
	hp_label.text = "HP: %d/%d" % [character.current_health, character.max_health]
	stamina_label.text = "Stamina: %d/%d" % [character.current_stamina, character.max_stamina]

	# Show Aura for characters that have it (Enrique)
	if character.max_aura > 0:
		stamina_label.text += " | Aura: %d" % character.current_aura

	# Add incoming attack icons after stamina
	var incoming_icons = _get_incoming_icons(my_index) if my_index >= 0 else ""
	if incoming_icons != "":
		stamina_label.text += " " + incoming_icons

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
	if character.ring_of_fire > 0:
		status_parts.append("Ring of Fire %d" % character.ring_of_fire)
	if character.played_twice > 0:
		status_parts.append("Played Twice x%d" % character.played_twice)
	if character.invincible > 0:
		status_parts.append("Invincible")
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
	if character.hinder > 0:
		status_parts.append("Hinder %d" % character.hinder)
	if character.scared > 0:
		status_parts.append("SCARED")
	if character.decay > 0:
		status_parts.append("Decay %d" % character.decay)
	if character.exhausted > 0:
		status_parts.append("Exhausted %d" % character.exhausted)
	if character.wet > 0:
		status_parts.append("Wet %d" % character.wet)
	# Check if this player is protected by another player
	if game_manager.protected_by.has(my_index):
		status_parts.append("🛡PROTECTED")

	# Append to shield label for now (or create separate label if needed)
	if status_parts.size() > 0:
		shield_label.text += " | " + " | ".join(status_parts)

	# Highlight panel if it's your turn (use cached StyleBoxFlat)
	var is_my_turn = game_manager.local_player_index == game_manager.current_player_index
	var bg_color = Color(0.3, 0.5, 0.7) if is_my_turn else Color(0.2, 0.2, 0.2)
	var border_color = Color.YELLOW if is_my_turn else Color.WHITE

	var style = _get_panel_style(bg_color, border_color, 3)
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
func _get_incoming_icons(player_index: int) -> String:
	var confirmed_damage = 0  # From AOE or specific targeting
	var has_random_attacks = false  # Random attacks incoming (can't predict exact damage)
	var confirmed_debuffs = false  # Will definitely receive debuffs (AOE)
	var random_debuffs = false     # Might receive debuffs (random target)

	for enemy_idx in cached_enemy_intents:
		var intent: EnemyIntent = cached_enemy_intents[enemy_idx]

		# Use per-target damage for accurate display
		if intent.damage_per_target.has(player_index):
			confirmed_damage += intent.damage_per_target[player_index]

		# Check if this player is targeted for debuffs
		for target_idx in intent.targets:
			if target_idx == player_index:
				if not intent.debuffs.is_empty():
					confirmed_debuffs = true
				break
			elif target_idx == -1:
				# Random target - can't predict who gets hit
				if intent.damage_amount > 0 and not intent.damage_per_target.has(player_index):
					has_random_attacks = true
				if not intent.debuffs.is_empty():
					random_debuffs = true
				break

	var result = ""

	# Show confirmed damage (AOE) with bullseye and amount
	if confirmed_damage > 0:
		result += " 🎯%d" % confirmed_damage
	# Show random attacks indicator (no number - damage unpredictable)
	if has_random_attacks:
		result += " ⚔?"

	# Show debuff icon - confirmed or with ? for random
	if confirmed_debuffs:
		result += " 🌀"
	elif random_debuffs:
		result += " 🌀?"

	return result
