extends Control
## Modal for activating Fabio's "Warrior's Choice" passive ability
##
## Shows 3 choices during action phase:
## 1. Deal 2 damage to boss
## 2. Draw 1 card
## 3. Give 3 shield to ally

signal choice_made(choice_index: int, target: Character)
signal awaiting_target(choice_index: int, valid_targets: Array[Character])

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ModalPanel/VBoxContainer/DescriptionLabel
@onready var choice_container: VBoxContainer = $ModalPanel/VBoxContainer/ChoiceContainer

@onready var damage_button: Button = $ModalPanel/VBoxContainer/ChoiceContainer/DamageButton
@onready var draw_button: Button = $ModalPanel/VBoxContainer/ChoiceContainer/DrawButton
@onready var shield_button: Button = $ModalPanel/VBoxContainer/ChoiceContainer/ShieldButton
@onready var cancel_button: Button = $ModalPanel/VBoxContainer/CancelButton

var character: Character = null
var boss_target: Character = null
var ally_targets: Array[Character] = []
var enemy_targets: Array[Character] = []

var awaiting_target_selection: bool = false
var pending_choice_index: int = -1

func _ready():
	# Hide initially
	visible = false

	# Connect button signals
	damage_button.pressed.connect(_on_damage_button_pressed)
	draw_button.pressed.connect(_on_draw_button_pressed)
	shield_button.pressed.connect(_on_shield_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

## Show the passive ability modal
func show_choice(char: Character, enemies: Array[Character], allies: Array[Character]):
	character = char
	enemy_targets = enemies.filter(func(e): return e.is_alive())
	ally_targets = allies.filter(func(a): return a.is_alive())

	# Set title
	title_label.text = "Warrior's Choice"
	description_label.text = "Choose one action (once per turn):"

	# Enable/disable buttons based on availability
	damage_button.disabled = enemy_targets.is_empty()
	shield_button.disabled = ally_targets.is_empty()

	# Reset target selection state
	awaiting_target_selection = false
	pending_choice_index = -1

	# Show modal
	visible = true

## Choice 1: Deal 2 damage to enemy
func _on_damage_button_pressed():
	# If only one enemy, automatically target them
	if enemy_targets.size() == 1:
		choice_made.emit(0, enemy_targets[0])
		visible = false
	else:
		# Multiple enemies - need target selection
		pending_choice_index = 0
		awaiting_target_selection = true
		visible = false
		awaiting_target.emit(0, enemy_targets)

## Choice 2: Draw 1 card (self-target, no selection needed)
func _on_draw_button_pressed():
	choice_made.emit(1, character)
	visible = false

## Choice 3: Give 3 shield to ally
func _on_shield_button_pressed():
	# If only one ally, automatically target them
	if ally_targets.size() == 1:
		choice_made.emit(2, ally_targets[0])
		visible = false
	else:
		# Multiple allies - need target selection
		pending_choice_index = 2
		awaiting_target_selection = true
		visible = false
		awaiting_target.emit(2, ally_targets)

## Called when target is selected from combat UI
func on_target_selected(target: Character):
	if awaiting_target_selection and pending_choice_index >= 0:
		choice_made.emit(pending_choice_index, target)
		awaiting_target_selection = false
		pending_choice_index = -1

## Cancel passive activation
func _on_cancel_button_pressed():
	awaiting_target_selection = false
	pending_choice_index = -1
	visible = false
