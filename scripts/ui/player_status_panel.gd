class_name PlayerStatusPanel
extends Node

## Manages player status panel updates for combat UI
## Handles left, right, and your character panels with consistent styling

signal debuff_clicked(debuff_name: String, character: Character)
signal debuff_selection_completed()

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

# Debuff selection mode state
var debuff_selection_active: bool = false
var debuff_selection_target: Character = null
var debuff_selection_remaining: int = 0
var debuff_selection_card_name: String = ""

# Status effect name to property mapping (for looking up values on Character)
const STATUS_EFFECT_PROPERTIES: Dictionary = {
	"strength": "strength",
	"armor": "armor",
	"rested": "rested",
	"invigorated": "invigorated",
	"damage_plus": "damage_plus",
	"ring_of_fire": "ring_of_fire",
	"played_twice": "played_twice",
	"invincible": "invincible",
	"poison": "poison",
	"burn": "burn",
	"vulnerable": "vulnerable",
	"weakness": "weakness",
	"fatigued": "fatigued",
	"hinder": "hinder",
	"scared": "scared",
	"decay": "decay",
	"exhausted": "exhausted",
	"wet": "wet"
}

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

## Populate a container with individual status effect labels (each with tooltip)
## font_size: font size for the labels
## is_protected: whether this character is protected by an ally
func _populate_status_container(container: HBoxContainer, character: Character, font_size: int, is_protected: bool):
	# Clear existing children
	for child in container.get_children():
		child.queue_free()

	# Check if this character is the debuff selection target
	var is_selection_target = debuff_selection_active and character == debuff_selection_target

	# Add instruction label if in selection mode for this character
	if is_selection_target:
		var instruction_label = Label.new()
		instruction_label.text = "Click debuff (%d):" % debuff_selection_remaining
		instruction_label.add_theme_font_size_override("font_size", font_size - 2)
		instruction_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Yellow
		instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(instruction_label)

	# Add labels for each active status effect
	for effect_name in STATUS_EFFECT_PROPERTIES.keys():
		var prop_name = STATUS_EFFECT_PROPERTIES[effect_name]
		var amount = character.get(prop_name)
		if amount > 0:
			var symbol = StatusEffectRegistry.get_symbol(effect_name)
			var display_name = StatusEffectRegistry.get_display_name(effect_name)

			# Check if this is a removable debuff during selection mode
			var is_debuff = StatusEffectRegistry.is_debuff(effect_name)
			var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
			var is_permanent = effect_data.get("permanent", false)
			var is_clickable = is_selection_target and is_debuff and not is_permanent

			if is_clickable:
				# Create a Button for clickable debuffs
				var debuff_button = Button.new()

				# Non-stacking effects (scared, invincible) don't show a number
				if effect_name in ["scared", "invincible"]:
					debuff_button.text = symbol
				else:
					debuff_button.text = "%s%d" % [symbol, amount]

				debuff_button.tooltip_text = "Click to remove: " + display_name
				debuff_button.add_theme_font_size_override("font_size", font_size)
				debuff_button.flat = true  # No default button background

				# Style for clickable debuff - highlighted border
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.6, 0.2, 0.2, 0.7)  # Red background
				style.border_color = Color(1.0, 0.8, 0.2)  # Gold border
				style.border_width_left = 2
				style.border_width_right = 2
				style.border_width_top = 2
				style.border_width_bottom = 2
				style.corner_radius_top_left = 4
				style.corner_radius_top_right = 4
				style.corner_radius_bottom_left = 4
				style.corner_radius_bottom_right = 4
				style.content_margin_left = 4
				style.content_margin_right = 4
				style.content_margin_top = 2
				style.content_margin_bottom = 2
				debuff_button.add_theme_stylebox_override("normal", style)

				# Hover style
				var hover_style = StyleBoxFlat.new()
				hover_style.bg_color = Color(0.8, 0.3, 0.3, 0.9)  # Brighter red
				hover_style.border_color = Color(1.0, 1.0, 0.4)  # Bright gold
				hover_style.border_width_left = 2
				hover_style.border_width_right = 2
				hover_style.border_width_top = 2
				hover_style.border_width_bottom = 2
				hover_style.corner_radius_top_left = 4
				hover_style.corner_radius_top_right = 4
				hover_style.corner_radius_bottom_left = 4
				hover_style.corner_radius_bottom_right = 4
				hover_style.content_margin_left = 4
				hover_style.content_margin_right = 4
				hover_style.content_margin_top = 2
				hover_style.content_margin_bottom = 2
				debuff_button.add_theme_stylebox_override("hover", hover_style)

				# Connect click handler
				debuff_button.pressed.connect(_on_debuff_label_clicked.bind(effect_name, character))

				container.add_child(debuff_button)
			else:
				# Regular label for non-clickable effects
				var effect_label = Label.new()

				# Non-stacking effects (scared, invincible) don't show a number
				if effect_name in ["scared", "invincible"]:
					effect_label.text = symbol
				else:
					effect_label.text = "%s%d" % [symbol, amount]

				effect_label.tooltip_text = display_name
				effect_label.add_theme_font_size_override("font_size", font_size)
				effect_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow tooltip to show

				# Gray out permanent debuffs during selection mode
				if is_selection_target and is_permanent:
					effect_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
					effect_label.tooltip_text = display_name + " (cannot be removed)"

				container.add_child(effect_label)

	# Add protected status (not in registry - it's a game state)
	print("[PROTECTOR DEBUG] _populate_status_container called with is_protected=", is_protected, " for character: ", character.character_name)
	if is_protected:
		print("[PROTECTOR DEBUG] Adding protected icon 😇 to ", character.character_name)
		var protected_label = Label.new()
		protected_label.text = "😇"
		protected_label.tooltip_text = "Protected by ally"
		protected_label.add_theme_font_size_override("font_size", font_size)
		protected_label.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(protected_label)

## Get or create status container for other player panels (left/right)
func _get_or_create_other_status_container(panel: Panel) -> HBoxContainer:
	var vbox = panel.get_node("VBoxContainer")
	var container_name = "StatusEffectContainer"

	if vbox.has_node(container_name):
		return vbox.get_node(container_name)

	# Create new container after HPLabel
	var container = HBoxContainer.new()
	container.name = container_name
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 5)

	# Insert after HPLabel (index 1, since NameLabel is index 0)
	var hp_label_index = vbox.get_node("HPLabel").get_index()
	vbox.add_child(container)
	vbox.move_child(container, hp_label_index + 1)

	return container

## Get or create status container for your character panel (bottom)
func _get_or_create_your_status_container(panel: Panel) -> HBoxContainer:
	var hbox = panel.get_node("HBoxContainer")
	var container_name = "StatusEffectContainer"

	if hbox.has_node(container_name):
		return hbox.get_node(container_name)

	# Create new container after ShieldLabel
	var container = HBoxContainer.new()
	container.name = container_name
	container.add_theme_constant_override("separation", 8)

	# Insert after ShieldLabel
	var shield_label_index = hbox.get_node("ShieldLabel").get_index()
	hbox.add_child(container)
	hbox.move_child(container, shield_label_index + 1)

	return container

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
	# Include protected state so UI updates when protection changes
	parts.append("protected:" + str(game_manager.protected_by.has(player_index)))
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

	# Add status effects display with individual hoverable labels
	var status_container = _get_or_create_other_status_container(panel)
	var is_protected = game_manager.protected_by.has(player_index)
	print("[PROTECTOR DEBUG] _update_other_player_panel: player_index=", player_index, " protected_by=", game_manager.protected_by, " is_protected=", is_protected)
	_populate_status_container(status_container, character, 14, is_protected)

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

	# Add status effects display with individual hoverable labels
	var status_container = _get_or_create_your_status_container(your_character_panel)
	var is_protected = game_manager.protected_by.has(my_index)
	print("[PROTECTOR DEBUG] _update_your_panel: my_index=", my_index, " protected_by=", game_manager.protected_by, " is_protected=", is_protected)
	_populate_status_container(status_container, character, 18, is_protected)

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

## Start debuff selection mode - makes debuff labels clickable
## Returns true if target has removable debuffs, false otherwise
func start_debuff_selection(target: Character, count: int, card_name: String) -> bool:
	# Check if target has any removable debuffs
	var removable = _count_removable_debuffs(target)
	if removable == 0:
		print("[DEBUFF SELECT] No removable debuffs on ", target.character_name)
		return false

	debuff_selection_active = true
	debuff_selection_target = target
	debuff_selection_remaining = min(count, removable)  # Can't remove more than exist
	debuff_selection_card_name = card_name

	print("[DEBUFF SELECT] Started selection for ", target.character_name, " - can remove ", debuff_selection_remaining, " debuffs")

	# Force panel refresh to make labels clickable
	_panel_signatures.clear()
	update_all()

	return true

## End debuff selection mode
func end_debuff_selection():
	debuff_selection_active = false
	debuff_selection_target = null
	debuff_selection_remaining = 0
	debuff_selection_card_name = ""

	# Force panel refresh to restore normal labels
	_panel_signatures.clear()
	update_all()

	debuff_selection_completed.emit()

## Count removable (non-permanent) debuffs on a character
func _count_removable_debuffs(character: Character) -> int:
	var count = 0
	for debuff_name in StatusEffectRegistry.get_debuff_effect_names():
		var current_value = character.get(debuff_name)
		if current_value != null and current_value > 0:
			var effect_data = StatusEffectRegistry.get_effect_data(debuff_name)
			if not effect_data.get("permanent", false):
				count += 1
	return count

## Handle a debuff being clicked during selection mode
func _on_debuff_label_clicked(debuff_name: String, character: Character):
	if not debuff_selection_active:
		return
	if character != debuff_selection_target:
		return
	if debuff_selection_remaining <= 0:
		return

	# Check if this debuff is permanent (shouldn't be clickable, but safety check)
	var effect_data = StatusEffectRegistry.get_effect_data(debuff_name)
	if effect_data.get("permanent", false):
		return

	# Remove the debuff
	character.set(debuff_name, 0)
	debuff_selection_remaining -= 1
	print("[DEBUFF SELECT] Removed ", debuff_name, " from ", character.character_name, " - ", debuff_selection_remaining, " remaining")

	debuff_clicked.emit(debuff_name, character)

	# Check if done (no more removals OR no more debuffs)
	if debuff_selection_remaining <= 0 or _count_removable_debuffs(character) == 0:
		end_debuff_selection()
	else:
		# Refresh to update remaining debuffs
		_panel_signatures.clear()
		update_all()
