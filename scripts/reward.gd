extends Control

var game_manager: Node
var card_db: Node
var wizard: Node2D
var card_scene = preload("res://scenes/card_visual.tscn")

# Reward state
var reward_phase: int = 0  # 0 = rare card phase, 1 = common card/heal phase
var chosen_player_index: int = 0
var rare_choices: Array[Card] = []
var common_choices_per_player: Array[Array] = [[], [], []]
var players_ready: int = 0

# UI Elements
@onready var wizard_container: Control = $WizardContainer
@onready var rare_card_container: HBoxContainer = $RareRewardPanel/CardContainer
@onready var rare_panel: Panel = $RareRewardPanel
@onready var rare_title: Label = $RareRewardPanel/TitleLabel

@onready var common_panel: Panel = $CommonRewardPanel
@onready var common_title: Label = $CommonRewardPanel/TitleLabel
@onready var player1_choice: VBoxContainer = $CommonRewardPanel/PlayerChoices/Player1Choice
@onready var player2_choice: VBoxContainer = $CommonRewardPanel/PlayerChoices/Player2Choice
@onready var player3_choice: VBoxContainer = $CommonRewardPanel/PlayerChoices/Player3Choice

@onready var continue_button: Button = $ContinueButton

func _ready():
	game_manager = get_node("/root/GameManager")
	card_db = get_node("/root/CardDatabase")

	# Create wizard visual
	wizard = Node2D.new()
	wizard.set_script(load("res://scripts/wizard_visual.gd"))
	wizard.position = Vector2(400, 400)
	wizard_container.add_child(wizard)

	# Setup UI
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.visible = false
	rare_panel.visible = false
	common_panel.visible = false

	# Start reward sequence
	await get_tree().create_timer(0.5).timeout
	start_rare_reward()

func start_rare_reward():
	reward_phase = 0
	chosen_player_index = randi() % 3
	var chosen_player = game_manager.players[chosen_player_index]

	wizard.say("Greetings, brave heroes! You have bested the beast!\n\n%s, step forward. I have powerful magic for you..." % chosen_player.character_name)

	await get_tree().create_timer(3.0).timeout

	# Generate 3 random rare cards
	var rare_pool = card_db.get_rare_cards()
	rare_pool.shuffle()
	rare_choices = [rare_pool[0], rare_pool[1], rare_pool[2]]

	# Display rare cards
	rare_panel.visible = true
	rare_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow cards to receive clicks
	rare_title.text = "%s - Choose ONE Rare Card" % chosen_player.character_name

	for i in range(3):
		var card_visual = card_scene.instantiate()
		rare_card_container.add_child(card_visual)
		card_visual.set_card(rare_choices[i])
		card_visual.set_playable(true)
		card_visual.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure card receives mouse events
		card_visual.card_clicked.connect(_on_rare_card_selected.bind(i))

func _on_rare_card_selected(card_index: int):
	var chosen_card = rare_choices[card_index]
	var chosen_player = game_manager.players[chosen_player_index]

	# Add card to player's deck
	chosen_player.add_card_to_deck(chosen_card)
	chosen_player.starting_deck.append(chosen_card.duplicate())

	wizard.say("Excellent choice! The power of %s is now yours!" % chosen_card.card_name)

	# Clear rare card UI
	for child in rare_card_container.get_children():
		child.queue_free()
	rare_panel.visible = false

	await get_tree().create_timer(2.0).timeout
	start_common_reward()

func start_common_reward():
	reward_phase = 1
	wizard.say("Now, all of you may choose:\nRestore half your health, OR take a useful card!\n\nChoose wisely!")

	await get_tree().create_timer(3.0).timeout

	common_panel.visible = true
	common_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow cards to receive clicks
	common_title.text = "All Players - Choose Heal or Card"

	# Generate choices for each player
	var player_choices = [player1_choice, player2_choice, player3_choice]

	for i in range(3):
		var player = game_manager.players[i]
		var choice_container = player_choices[i]

		# Player name label
		var name_label = choice_container.get_node("NameLabel") as Label
		name_label.text = player.character_name

		# Heal button
		var heal_button = choice_container.get_node("HealButton") as Button
		var heal_amount = int(player.max_health * 0.5)
		heal_button.text = "Heal %d HP" % heal_amount
		heal_button.pressed.connect(_on_heal_selected.bind(i))

		# Generate 3 random common cards
		var common_pool = card_db.get_common_cards()
		common_pool.shuffle()
		common_choices_per_player[i] = [common_pool[0], common_pool[1], common_pool[2]]

		# Card buttons container
		var cards_container = choice_container.get_node("CardsContainer") as HBoxContainer
		cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow cards to receive clicks

		for j in range(3):
			var card_visual = card_scene.instantiate()
			cards_container.add_child(card_visual)
			card_visual.set_card(common_choices_per_player[i][j])
			card_visual.set_playable(true)
			card_visual.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure card receives mouse events
			card_visual.custom_minimum_size = Vector2(150, 200)  # Smaller cards
			card_visual.card_clicked.connect(_on_common_card_selected.bind(i, j))

func _on_heal_selected(player_index: int):
	var player = game_manager.players[player_index]
	var heal_amount = int(player.max_health * 0.5)
	player.heal(heal_amount)

	wizard.say("%s chooses restoration! Wise decision." % player.character_name)

	# Disable this player's choices
	disable_player_choices(player_index)
	players_ready += 1
	check_all_ready()

func _on_common_card_selected(player_index: int, card_index: int):
	var chosen_card = common_choices_per_player[player_index][card_index]
	var player = game_manager.players[player_index]

	# Add card to player's deck
	player.add_card_to_deck(chosen_card)
	player.starting_deck.append(chosen_card.duplicate())

	wizard.say("%s takes %s! A fine addition to your arsenal." % [player.character_name, chosen_card.card_name])

	# Disable this player's choices
	disable_player_choices(player_index)
	players_ready += 1
	check_all_ready()

func disable_player_choices(player_index: int):
	var player_choices = [player1_choice, player2_choice, player3_choice]
	var choice_container = player_choices[player_index]

	# Disable heal button
	var heal_button = choice_container.get_node("HealButton") as Button
	heal_button.disabled = true

	# Disable card selection
	var cards_container = choice_container.get_node("CardsContainer") as HBoxContainer
	for child in cards_container.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func check_all_ready():
	if players_ready >= 3:
		wizard.say("Your choices are made! Steel yourselves...\nThe next challenge awaits!")

		await get_tree().create_timer(2.0).timeout
		continue_button.visible = true

func _on_continue_pressed():
	# Start next boss encounter and load combat scene
	game_manager.start_boss_encounter()
	game_manager.start_player_turn(0)
	get_tree().change_scene_to_file("res://scenes/combat.tscn")
