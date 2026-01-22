extends Control

var card_data: Card
var is_playable: bool = false
var is_hovered: bool = false
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.3  # 300ms for double-click

# Owner character for dynamic description calculations (damage/heal with buffs)
var owner_character = null

# Texture references
const BG_FABIO = preload("res://assets/temp cards/Fabio.png")
const BG_KEVIN = preload("res://assets/temp cards/Kevin.png")
const BG_DEFAULT = preload("res://assets/temp cards/Enrique.png")
const CARD_TEXT_BOX = preload("res://assets/temp cards/card text box.png")
const STAMINA_CIRCLE = preload("res://assets/temp cards/Stamina.png")
const STAMINA_NUMS = [
	preload("res://assets/temp cards/0 stamina.png"),
	preload("res://assets/temp cards/1 stamina.png"),
	preload("res://assets/temp cards/2 stamina.png"),
	preload("res://assets/temp cards/3 stamina.png")
]
const AURA_CIRCLE = preload("res://assets/temp cards/Aura.png")
const AURA_NUMS = [
	preload("res://assets/temp cards/0 Aura.png"),
	preload("res://assets/temp cards/1 Aura.png"),
	preload("res://assets/temp cards/2 Aura.png"),
	preload("res://assets/temp cards/3 Aura.png")
]
const AURA_X = preload("res://assets/temp cards/X Aura.png")
const TYPE_BOX_ATTACK = preload("res://assets/temp cards/attack text box.png")
const TYPE_BOX_SKILL = preload("res://assets/temp cards/Skill text box.png")
const TYPE_TEXT_ATTACK = preload("res://assets/temp cards/Attack.png")
const TYPE_TEXT_SKILL = preload("res://assets/temp cards/Skill.png")
const ELEM_FIRE = preload("res://assets/temp cards/Fire.png")
const ELEM_WATER = preload("res://assets/temp cards/Water.png")
const ELEM_EARTH = preload("res://assets/temp cards/Earth.png")

# Node references
@onready var background: TextureRect = $Background
@onready var card_text_box: TextureRect = $CardTextBox
@onready var stamina_circle: TextureRect = $StaminaCircle
@onready var stamina_number: TextureRect = $StaminaCircle/StaminaNumber
@onready var aura_circle: TextureRect = $AuraCircle
@onready var aura_number: TextureRect = $AuraCircle/AuraNumber
@onready var element_icon: TextureRect = $ElementIcon
@onready var type_box: TextureRect = $TypeBox
@onready var type_text: TextureRect = $TypeBox/TypeText
@onready var name_label: Label = $NameLabel
@onready var description_label: RichTextLabel = $DescriptionLabel

signal card_clicked(card: Card)
signal card_double_clicked(card: Card)
signal card_hovered(card: Card)
signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)

# Status effect emoji symbols for inline display in card descriptions
const STATUS_SYMBOLS = {
	"Poison": "☠️Poison",
	"Burn": "🔥Burn",
	"Strength": "💪Strength",
	"Vulnerable": "💔Vulnerable",
	"Weakness": "😵Weakness",
	"Wet": "💧Wet",
	"Scared": "😨Scared",
	"Hinder": "🚫Hinder",
	"Shield": "🛡️Shield",
	"Armor": "🛡️Armor",
	"Rested": "😌Rested",
	"Invigorated": "⚡Invigorated",
	"Fatigued": "😴Fatigued",
	"Exhausted": "🥵Exhausted",
	"Decay": "💀Decay",
	"Venom": "🐍Venom"
}

func _format_description_with_symbols(description: String) -> String:
	var result = description
	for keyword in STATUS_SYMBOLS:
		# Use [url] tag for hoverable meta - stores the effect name in lowercase
		var symbol_with_meta = "[url=%s]%s[/url]" % [keyword.to_lower(), STATUS_SYMBOLS[keyword]]
		result = result.replace(keyword, symbol_with_meta)
	return result

## Generate a human-readable tooltip description for a status effect
func _get_effect_tooltip(effect_name: String) -> String:
	var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
	if effect_data.is_empty():
		return effect_name.capitalize()

	var display_name = effect_data.get("display_name", effect_name.capitalize())
	var desc_parts = []

	# Describe effect based on its properties
	if effect_data.get("deals_damage", false):
		if effect_data.get("piercing", false):
			desc_parts.append("Deals piercing damage equal to stacks")
		else:
			desc_parts.append("Deals damage equal to stacks")

	if effect_data.has("attack_modifier"):
		var mod = effect_data.attack_modifier
		if mod > 0:
			desc_parts.append("+%d damage per stack" % mod)
		else:
			desc_parts.append("%d damage per stack" % mod)

	if effect_data.has("damage_reduction"):
		desc_parts.append("-%d damage taken per stack" % effect_data.damage_reduction)

	if effect_data.has("damage_taken_multiplier"):
		var mult = effect_data.damage_taken_multiplier
		var percent = int((mult - 1.0) * 100)
		desc_parts.append("+%d%% damage taken" % percent)

	if effect_data.has("stamina_modifier"):
		var mod = effect_data.stamina_modifier
		if mod > 0:
			desc_parts.append("+%d stamina next turn" % mod)
		else:
			desc_parts.append("%d stamina next turn" % mod)

	if effect_data.get("blocks_card_play", false):
		desc_parts.append("Cannot play cards")

	if effect_data.get("blocks_attacks", false):
		desc_parts.append("Cannot play attack cards")

	if effect_data.get("blocks_healing", false):
		desc_parts.append("Cannot be healed")

	if effect_data.get("permanent", false):
		desc_parts.append("Cannot be removed")

	# Decay info
	var decay_type = effect_data.get("decay", StatusEffectRegistry.DecayType.NONE)
	match decay_type:
		StatusEffectRegistry.DecayType.PER_TURN:
			var amount = effect_data.get("decay_amount", 1)
			desc_parts.append("Loses %d stack(s) per turn" % amount)
		StatusEffectRegistry.DecayType.END_OF_TURN:
			desc_parts.append("Removed at end of turn")
		StatusEffectRegistry.DecayType.END_OF_ENEMY_TURN:
			desc_parts.append("Removed after enemy turn")

	if desc_parts.is_empty():
		return display_name

	return display_name + ": " + ". ".join(desc_parts)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	# Connect RichTextLabel meta hover signals for status effect tooltips
	description_label.meta_hover_started.connect(_on_status_hover_started)
	description_label.meta_hover_ended.connect(_on_status_hover_ended)

	# Set all child elements to pass clicks through to this Control
	# Exception: description_label needs MOUSE_FILTER_PASS for tooltips
	for child in get_children():
		if child is Control:
			if child == description_label:
				child.mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Also handle nested children
			for subchild in child.get_children():
				if subchild is Control:
					subchild.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_card(card: Card):
	card_data = card
	update_display()

func set_card_owner(character):
	owner_character = character
	update_display()

func update_display():
	if not card_data:
		return

	# Set background based on owner hero
	var hero_id = ""
	if owner_character and owner_character.hero_id:
		hero_id = owner_character.hero_id

	match hero_id:
		"fabio":
			background.texture = BG_FABIO
		"kevin":
			background.texture = BG_KEVIN
		_:
			background.texture = BG_DEFAULT

	# Card text box (cream background for text)
	card_text_box.texture = CARD_TEXT_BOX

	# Stamina circle and number
	stamina_circle.texture = STAMINA_CIRCLE
	var effective_cost = card_data.stamina_cost
	if owner_character:
		effective_cost -= RelicRegistry.get_cost_reduction(owner_character, card_data)
		effective_cost = max(0, effective_cost)

	var display_cost = clampi(effective_cost, 0, 3)
	stamina_number.texture = STAMINA_NUMS[display_cost]

	# Tint green if cost was reduced by relic
	if effective_cost < card_data.stamina_cost:
		stamina_number.modulate = Color(0.5, 1.0, 0.5)
	else:
		stamina_number.modulate = Color.WHITE

	# Aura circle and number (only show if card has aura cost)
	if card_data.aura_cost > 0 or card_data.aura_cost_all:
		aura_circle.visible = true
		aura_circle.texture = AURA_CIRCLE
		if card_data.aura_cost_all:
			aura_number.texture = AURA_X
		else:
			var aura_cost = clampi(card_data.aura_cost, 0, 3)
			aura_number.texture = AURA_NUMS[aura_cost]
	else:
		aura_circle.visible = false

	# Type box and text based on card type
	var is_attack = card_data.card_type == Card.CardType.ATTACK
	type_box.texture = TYPE_BOX_ATTACK if is_attack else TYPE_BOX_SKILL
	type_text.texture = TYPE_TEXT_ATTACK if is_attack else TYPE_TEXT_SKILL

	# Element icon (Kevin's spells only)
	if card_data.element != Card.ElementType.NONE:
		element_icon.visible = true
		match card_data.element:
			Card.ElementType.FIRE:
				element_icon.texture = ELEM_FIRE
			Card.ElementType.WATER:
				element_icon.texture = ELEM_WATER
			Card.ElementType.EARTH:
				element_icon.texture = ELEM_EARTH
	else:
		element_icon.visible = false

	# Text labels
	name_label.text = card_data.card_name
	# Pass owner for dynamic description (damage/heal adjusted by buffs/debuffs)
	# Format description with status effect symbols (e.g., "Apply 4 ☠️Poison")
	var raw_description = card_data.get_full_description(owner_character)

	# Add damage modifier indicator for attack cards
	if owner_character and card_data.card_type == Card.CardType.ATTACK and card_data.damage > 0:
		var base_damage = card_data.damage
		var calc_damage = CardEffectEngine.calculate_damage(card_data, owner_character, null)
		if calc_damage > base_damage:
			# Buffed - add green up arrow indicator
			raw_description = raw_description.replace(
				"Deal %d damage" % calc_damage,
				"Deal %d▲ damage" % calc_damage
			)
			# Also handle multi-hit patterns
			if card_data.multi_hit > 1:
				raw_description = raw_description.replace(
					"%d damage each" % calc_damage,
					"%d▲ damage each" % calc_damage
				)
		elif calc_damage < base_damage:
			# Debuffed - add red down arrow indicator
			raw_description = raw_description.replace(
				"Deal %d damage" % calc_damage,
				"Deal %d▼ damage" % calc_damage
			)
			# Also handle multi-hit patterns
			if card_data.multi_hit > 1:
				raw_description = raw_description.replace(
					"%d damage each" % calc_damage,
					"%d▼ damage each" % calc_damage
				)

	# RichTextLabel with BBCode - wrap in [center] for horizontal centering
	description_label.text = "[center]" + _format_description_with_symbols(raw_description) + "[/center]"

	# Update visual state based on playability
	update_card_color()

func update_card_color():
	if not is_playable:
		# Gray out when unplayable
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

	if is_hovered and is_playable:
		modulate = modulate.lightened(0.15)

func set_playable(playable: bool):
	is_playable = playable
	update_card_color()

func _on_mouse_entered():
	is_hovered = true
	if is_playable:
		scale = Vector2(1.1, 1.1)
		z_index = 10
		card_hovered.emit(card_data)
	update_card_color()

func _on_mouse_exited():
	is_hovered = false
	scale = Vector2(1.0, 1.0)
	z_index = 0
	update_card_color()

func _on_status_hover_started(meta: Variant) -> void:
	var effect_name = str(meta)
	description_label.tooltip_text = _get_effect_tooltip(effect_name)

func _on_status_hover_ended(_meta: Variant) -> void:
	description_label.tooltip_text = ""

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_playable:
				# Check for double-click
				var current_time = Time.get_ticks_msec() / 1000.0
				var time_since_last_click = current_time - last_click_time

				if time_since_last_click < DOUBLE_CLICK_TIME:
					# Double-click detected!
					card_double_clicked.emit(card_data)
					last_click_time = 0.0  # Reset to prevent triple-click from triggering
				else:
					# Single click (might become double-click)
					card_clicked.emit(card_data)
					last_click_time = current_time

## Drag-and-drop support
func _get_drag_data(at_position: Vector2):
	if not is_playable or not card_data:
		return null

	# Emit drag started signal
	card_drag_started.emit(card_data)

	# Create ghost preview (semi-transparent copy of card)
	var preview = Control.new()
	var ghost_card = duplicate() as Control
	ghost_card.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
	preview.add_child(ghost_card)

	set_drag_preview(preview)

	# Return card data as drag data
	return {"card": card_data, "source": self}

## Called when drag ends (whether successful drop or cancelled)
func _notification(what: int):
	if what == NOTIFICATION_DRAG_END:
		card_drag_ended.emit(card_data)
