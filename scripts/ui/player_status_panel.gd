class_name PlayerStatusPanel
extends Node

## Manages player status panel updates for combat UI
## Handles left, right, and your character panels with consistent styling

signal debuff_clicked(debuff_name: String, character: Character)
signal debuff_selection_completed()
signal active_relic_clicked(relic_id: String, character: Character)

var game_manager: Node
var left_head_image: TextureRect  # Head image is the drop target
var left_player_labels: VBoxContainer  # Labels positioned above head
var left_status_container: HBoxContainer  # Status effects (separate from labels)
var right_head_image: TextureRect  # Head image is the drop target
var right_player_labels: VBoxContainer  # Labels positioned above head
var right_status_container: HBoxContainer  # Status effects (separate from labels)
var your_character_panel: Panel
# Card scene preload commented out - no longer showing card previews for teammates
# var card_scene = preload("res://scenes/card_visual.tscn")

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
var selected_debuff_names: Array[String] = []  # Track which debuffs were selected for server sync

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
	"wet": "wet",
	"venom": "venom",
	"bleed": "bleed",
	"feeble": "feeble",
	"doll_dissolve": "doll_dissolve",
	"doll_suffering": "doll_suffering",
	"doll_burden": "doll_burden",
	"burden": "burden",
	"dissolve": "dissolve"
}

# Doll debuff background colors for visual distinction
const DOLL_COLORS: Dictionary = {
	"doll_dissolve": Color(0.6, 0.3, 0.7),   # Purple
	"doll_suffering": Color(0.8, 0.4, 0.2),  # Orange
	"doll_burden": Color(0.3, 0.5, 0.8),     # Blue
}

func setup(gm: Node, left_img: TextureRect, left_labels: VBoxContainer, left_status: HBoxContainer, right_img: TextureRect, right_labels: VBoxContainer, right_status: HBoxContainer, your: Panel):
	game_manager = gm
	left_head_image = left_img
	left_player_labels = left_labels
	left_status_container = left_status
	right_head_image = right_img
	right_player_labels = right_labels
	right_status_container = right_status
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
		# Use status_effects dictionary directly (Object.get() doesn't work with computed properties)
		var amount = character.status_effects.get(prop_name, 0)
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
				# Check if this is a doll debuff that needs colored circle background
				if effect_name in DOLL_COLORS:
					# Create label with colored circle background for doll debuffs
					var effect_label = Label.new()
					effect_label.text = "%s%d" % [symbol, amount]
					effect_label.tooltip_text = display_name
					effect_label.add_theme_font_size_override("font_size", font_size)
					effect_label.mouse_filter = Control.MOUSE_FILTER_PASS

					# Add colored circular background using StyleBoxFlat
					var bg_style = StyleBoxFlat.new()
					bg_style.bg_color = DOLL_COLORS[effect_name]
					bg_style.corner_radius_top_left = 12
					bg_style.corner_radius_top_right = 12
					bg_style.corner_radius_bottom_left = 12
					bg_style.corner_radius_bottom_right = 12
					bg_style.content_margin_left = 4
					bg_style.content_margin_right = 4
					bg_style.content_margin_top = 2
					bg_style.content_margin_bottom = 2
					effect_label.add_theme_stylebox_override("normal", bg_style)

					container.add_child(effect_label)
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
	if is_protected:
		var protected_label = Label.new()
		protected_label.text = "😇"
		protected_label.tooltip_text = "Protected by ally"
		protected_label.add_theme_font_size_override("font_size", font_size)
		protected_label.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(protected_label)

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
	parts.append("venom:" + str(character.venom))
	parts.append("doll_dissolve:" + str(character.doll_dissolve))
	parts.append("doll_suffering:" + str(character.doll_suffering))
	parts.append("doll_burden:" + str(character.doll_burden))
	parts.append("burden:" + str(character.burden))
	parts.append("dissolve:" + str(character.dissolve))
	parts.append("aura:" + str(character.current_aura))
	# Include incoming damage calculation
	var incoming = _get_incoming_icons(player_index)
	parts.append("incoming:" + incoming)
	# Include protected state so UI updates when protection changes
	parts.append("protected:" + str(game_manager.protected_by.has(player_index)))
	# Include active relic uses so UI updates when relics are used
	parts.append("relic_uses:" + str(character.relic_uses_remaining))
	return "|".join(parts)

## Force clear signature cache and update all panels
func force_refresh():
	_panel_signatures.clear()
	update_all()

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
		_update_other_panel(left_head_image, left_player_labels, left_status_container, left_char, other_indices[0])
	else:
		# No left player (< 2 players total)
		left_head_image.visible = false
		left_player_labels.visible = false
		left_status_container.visible = false

	# Right player (second "other")
	if other_indices.size() > 1:
		var right_char = game_manager.players[other_indices[1]]
		_update_other_panel(right_head_image, right_player_labels, right_status_container, right_char, other_indices[1])
	else:
		# No right player (< 3 players total)
		right_head_image.visible = false
		right_player_labels.visible = false
		right_status_container.visible = false

	# Your character (bottom)
	_update_your_panel(my_character)

## Update other player panel (left or right)
## Now uses separate head image (drop target), labels container, and status container
func _update_other_panel(head_image: TextureRect, labels: VBoxContainer, status_container: HBoxContainer, character: Character, player_index: int):
	head_image.visible = true
	labels.visible = true
	status_container.visible = true

	# Connect click handler for targeting on head image (disconnect first to avoid duplicates)
	if not head_image.gui_input.is_connected(_on_panel_clicked):
		head_image.gui_input.connect(_on_panel_clicked.bind(character))

	# Check if panel state has changed (skip update if unchanged to prevent tearing)
	var panel_key = "other_" + str(player_index)
	var new_signature = _get_panel_signature(character, player_index, "", "")
	if _panel_signatures.get(panel_key, "") == new_signature:
		return  # No changes, skip update
	_panel_signatures[panel_key] = new_signature

	# Update name, HP (using labels container)
	var name_label = labels.get_node("NameLabel")
	var hp_label = labels.get_node("HPLabel")

	# Name without icons
	name_label.text = character.character_name

	# Build HP display with shield, stamina, aura, and incoming damage
	var hp_text = "HP: %d/%d" % [character.current_health, character.max_health]
	if character.shield > 0:
		hp_text += " | Shield: %d" % character.shield

	# Add stamina/aura inline
	hp_text += " | S: %d/%d" % [character.current_stamina, character.max_stamina]
	if character.max_aura > 0:
		hp_text += " | A: %d" % character.current_aura

	# Add incoming attack icons
	var incoming_icons = _get_incoming_icons(player_index)
	if incoming_icons != "":
		hp_text += incoming_icons

	hp_label.text = hp_text

	# Add status effects display with individual hoverable labels (using separate container)
	var is_protected = game_manager.protected_by.has(player_index)
	_populate_status_container(status_container, character, 14, is_protected)

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
	_populate_status_container(status_container, character, 18, is_protected)

	# Add active relic buttons
	var active_relic_container = _get_or_create_active_relic_container(your_character_panel)
	_populate_active_relic_container(active_relic_container, character)

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

	# Get fresh predicted dead enemies
	var predicted_dead: Array[int] = []
	if game_manager and game_manager.has_method("get_predicted_dead_enemies"):
		predicted_dead = game_manager.get_predicted_dead_enemies()

	for enemy_idx in cached_enemy_intents:
		# Skip enemies that are predicted to die from queued player attacks
		if enemy_idx in predicted_dead:
			continue

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

	# Get fresh predicted dead enemies (recalculates based on current queued cards)
	var predicted_dead: Array[int] = []
	if game_manager and game_manager.has_method("get_predicted_dead_enemies"):
		predicted_dead = game_manager.get_predicted_dead_enemies()

	for enemy_idx in cached_enemy_intents:
		# Skip enemies that are predicted to die from queued player attacks
		if enemy_idx in predicted_dead:
			continue

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

## Get or create active relic container for your character panel (bottom)
func _get_or_create_active_relic_container(panel: Panel) -> HBoxContainer:
	var hbox = panel.get_node("HBoxContainer")
	var container_name = "ActiveRelicContainer"

	if hbox.has_node(container_name):
		return hbox.get_node(container_name)

	# Create new container after StatusEffectContainer
	var container = HBoxContainer.new()
	container.name = container_name
	container.add_theme_constant_override("separation", 8)

	# Insert after StatusEffectContainer
	var status_container = _get_or_create_your_status_container(panel)
	var status_index = status_container.get_index()
	hbox.add_child(container)
	hbox.move_child(container, status_index + 1)

	return container

## Populate active relic buttons in the UI
func _populate_active_relic_container(container: HBoxContainer, character: Character):
	# Clear existing children
	for child in container.get_children():
		child.queue_free()

	# Get active-use relics owned by this character
	var active_relics = character.get_active_use_relics()

	for relic_id in active_relics:
		var relic = RelicRegistry.get_relic(relic_id)
		if relic.is_empty():
			continue

		var can_use = character.can_use_relic(relic_id)
		var uses_remaining = character.relic_uses_remaining.get(relic_id, 0)

		# Create button for active relic
		var relic_button = Button.new()
		relic_button.text = relic.get("display_name", relic_id) + " (" + str(uses_remaining) + ")"
		relic_button.tooltip_text = relic.get("description", "")
		relic_button.add_theme_font_size_override("font_size", 14)
		relic_button.custom_minimum_size = Vector2(120, 30)

		if can_use:
			# Active and usable - gold styling
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.4, 0.3, 0.1)  # Dark gold
			style.border_color = Color(1.0, 0.8, 0.2)  # Gold border
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.corner_radius_top_left = 4
			style.corner_radius_top_right = 4
			style.corner_radius_bottom_left = 4
			style.corner_radius_bottom_right = 4
			relic_button.add_theme_stylebox_override("normal", style)

			# Hover style
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = Color(0.5, 0.4, 0.15)  # Brighter gold
			hover_style.border_color = Color(1.0, 1.0, 0.4)  # Bright gold
			hover_style.border_width_left = 2
			hover_style.border_width_right = 2
			hover_style.border_width_top = 2
			hover_style.border_width_bottom = 2
			hover_style.corner_radius_top_left = 4
			hover_style.corner_radius_top_right = 4
			hover_style.corner_radius_bottom_left = 4
			hover_style.corner_radius_bottom_right = 4
			relic_button.add_theme_stylebox_override("hover", hover_style)

			relic_button.pressed.connect(_on_active_relic_clicked.bind(relic_id, character))
		else:
			# Used up - grayed out
			relic_button.disabled = true
			relic_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

		container.add_child(relic_button)

## Handle active relic button click
func _on_active_relic_clicked(relic_id: String, character: Character):
	print("[ACTIVE RELIC] ", character.character_name, " clicked ", relic_id)
	active_relic_clicked.emit(relic_id, character)

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
	selected_debuff_names.clear()

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
		# Use status_effects dictionary directly (Object.get() doesn't work with computed properties)
		var current_value = character.status_effects.get(debuff_name, 0)
		if current_value > 0:
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

	# Remove the debuff locally (visual feedback - server will confirm via broadcast)
	character.set(debuff_name, 0)
	debuff_selection_remaining -= 1
	selected_debuff_names.append(debuff_name)
	print("[DEBUFF SELECT] Removed ", debuff_name, " from ", character.character_name, " - ", debuff_selection_remaining, " remaining")

	debuff_clicked.emit(debuff_name, character)

	# Check if done (no more removals OR no more debuffs)
	if debuff_selection_remaining <= 0 or _count_removable_debuffs(character) == 0:
		end_debuff_selection()
	else:
		# Refresh to update remaining debuffs
		_panel_signatures.clear()
		update_all()
