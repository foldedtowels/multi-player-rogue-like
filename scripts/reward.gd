extends Control

## Reward scene - displays after defeating minions or bosses
## Uses modular RewardManager for privacy-aware reward selection
##
## Minion rewards: Each player chooses heal (30%) OR card
## Boss rewards: Each player chooses revive OR card, THEN chooses a relic

var game_manager: Node
var card_db: Node
var hero_db: Node
var wizard: Node2D
var reward_manager: RewardManager

# Reward state
var reward_phase: int = 0  ## 0 = card/heal phase, 1 = relic phase (boss only)
var encounter_type: int = 0  ## Tracks whether this was a minion or boss encounter
var chosen_player_index: int = 0

# UI Elements
@onready var wizard_container: Control = $WizardContainer
@onready var continue_button: Button = $ContinueButton
var main_panel: RewardDisplayPanel  # For heal/card/revive choices
var relic_panel: RewardDisplayPanel  # For relic choices (boss only)
var skip_button: Button

func _ready():
	game_manager = get_node("/root/GameManager")
	card_db = get_node("/root/CardDatabase")
	hero_db = get_node("/root/HeroDatabase")

	# Determine what type of encounter just ended
	encounter_type = game_manager.last_completed_encounter

	# Check for total party kill - shouldn't happen but guard against it
	var any_alive = false
	for player in game_manager.players:
		if player.is_alive():
			any_alive = true
			break
	if not any_alive:
		print("[REWARD] All players dead - transitioning to defeat screen")
		get_tree().change_scene_to_file("res://scenes/defeat.tscn")
		return

	# Create reward panels programmatically
	main_panel = RewardDisplayPanel.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.offset_left = -400
	main_panel.offset_top = -150
	main_panel.offset_right = 400
	main_panel.offset_bottom = 150
	main_panel.custom_minimum_size = Vector2(800, 300)
	add_child(main_panel)

	relic_panel = RewardDisplayPanel.new()
	relic_panel.set_anchors_preset(Control.PRESET_CENTER)
	relic_panel.offset_left = -400
	relic_panel.offset_top = -150
	relic_panel.offset_right = 400
	relic_panel.offset_bottom = 150
	relic_panel.custom_minimum_size = Vector2(800, 300)
	add_child(relic_panel)

	# Create skip button
	skip_button = Button.new()
	skip_button.text = "Skip (Auto-select first choice)"
	skip_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	skip_button.position = Vector2(-150, -80)
	skip_button.custom_minimum_size = Vector2(300, 50)
	skip_button.visible = false
	skip_button.pressed.connect(_on_skip_pressed)
	add_child(skip_button)

	# Create wizard visual
	wizard = Node2D.new()
	wizard.set_script(load("res://scripts/wizard_visual.gd"))
	wizard.position = Vector2(400, 400)
	wizard_container.add_child(wizard)

	# Create reward manager
	reward_manager = RewardManager.new()
	add_child(reward_manager)

	# Connect signals
	continue_button.pressed.connect(_on_continue_pressed)
	reward_manager.all_players_ready.connect(_on_all_rewards_complete)
	reward_manager.private_choice_made.connect(_on_private_choice_made)

	# Setup UI
	continue_button.visible = false
	main_panel.visible = false
	relic_panel.visible = false

	# Start reward sequence based on encounter type
	await get_tree().create_timer(GameConstants.WIZARD_INTRO_DELAY).timeout

	if encounter_type == GameManager.EncounterType.MINION:
		start_minion_reward()
	else:
		start_boss_reward()

# =============================================================================
# MINION REWARDS - Heal 30% OR Card
# =============================================================================

func start_minion_reward():
	reward_phase = 0
	wizard.say("The beasts are vanquished!\n\nChoose your boon: heal your wounds or gain new power!")

	await get_tree().create_timer(GameConstants.WIZARD_COMMON_CHOICE_DELAY).timeout

	var choices_per_player = _generate_minion_choices()
	reward_manager.show_private_rewards(choices_per_player, main_panel)
	skip_button.visible = true

func _generate_minion_choices() -> Dictionary:
	var choices = {}

	for player_idx in range(game_manager.players.size()):
		var player = game_manager.players[player_idx]

		# Skip dead players - they don't get rewards
		if not player.is_alive():
			continue

		var player_choices: Array[RewardChoice] = []

		# Option 1: Heal (30% of max health for minion rewards)
		var heal_choice = RewardChoice.new()
		heal_choice.choice_type = RewardChoice.ChoiceType.HEAL
		heal_choice.heal_amount = int(player.max_health * GameConstants.MINION_REWARD_HEAL_PERCENTAGE)
		heal_choice.display_name = "Heal"
		heal_choice.description = "Restore %d HP (30%%)" % heal_choice.heal_amount
		player_choices.append(heal_choice)

		# Options 2-4: Cards from reward deck
		var card_pool = _get_card_pool_for_player(player)
		card_pool.shuffle()

		var num_cards = min(GameConstants.REWARD_COMMON_CARD_CHOICES, card_pool.size())
		for i in range(num_cards):
			var card_choice = RewardChoice.new()
			card_choice.choice_type = RewardChoice.ChoiceType.CARD
			card_choice.card_data = card_pool[i]
			card_choice.display_name = card_pool[i].card_name
			card_choice.description = card_pool[i].description
			player_choices.append(card_choice)

		choices[player_idx] = player_choices

	return choices

# =============================================================================
# BOSS REWARDS - Revive OR Card, then Relic
# =============================================================================

func start_boss_reward():
	reward_phase = 0
	var any_dead = _any_players_dead()

	if any_dead:
		wizard.say("The mighty foe has fallen!\n\nRevive your allies or gain new power! Then, claim a powerful artifact!")
	else:
		wizard.say("The mighty foe has fallen!\n\nChoose a powerful card! Then, claim a mighty artifact!")

	await get_tree().create_timer(GameConstants.WIZARD_COMMON_CHOICE_DELAY).timeout

	var choices_per_player = _generate_boss_card_choices()
	reward_manager.show_private_rewards(choices_per_player, main_panel)
	skip_button.visible = true

func _generate_boss_card_choices() -> Dictionary:
	var choices = {}
	var any_dead = _any_players_dead()

	for player_idx in range(game_manager.players.size()):
		var player = game_manager.players[player_idx]

		# Skip dead players - they don't get to choose (but can be revived)
		if not player.is_alive():
			continue

		var player_choices: Array[RewardChoice] = []

		# Option 1: Revive all dead teammates (only if someone is dead)
		if any_dead:
			var revive_choice = RewardChoice.new()
			revive_choice.choice_type = RewardChoice.ChoiceType.BUFF
			revive_choice.buff_type = "revive_all"
			revive_choice.display_name = "Revive Allies"
			revive_choice.description = "Revive all dead teammates at FULL HP"
			player_choices.append(revive_choice)

		# Options: Cards from reward deck
		var card_pool = _get_card_pool_for_player(player)
		card_pool.shuffle()

		var num_cards = min(GameConstants.REWARD_COMMON_CARD_CHOICES, card_pool.size())
		for i in range(num_cards):
			var card_choice = RewardChoice.new()
			card_choice.choice_type = RewardChoice.ChoiceType.CARD
			card_choice.card_data = card_pool[i]
			card_choice.display_name = card_pool[i].card_name
			card_choice.description = card_pool[i].description
			player_choices.append(card_choice)

		choices[player_idx] = player_choices

	return choices

func start_relic_reward():
	reward_phase = 1
	wizard.say("Now, claim your artifact! Choose wisely...")

	await get_tree().create_timer(2.0).timeout

	var choices_per_player = _generate_relic_choices()

	# Check if any players have relic choices
	if choices_per_player.is_empty():
		print("[REWARD] No relic choices available - skipping relic phase")
		_show_continue_button()
		return

	reward_manager.show_private_rewards(choices_per_player, relic_panel)
	skip_button.visible = true

func _generate_relic_choices() -> Dictionary:
	var choices = {}

	for player_idx in range(game_manager.players.size()):
		var player = game_manager.players[player_idx]

		# Skip dead players
		if not player.is_alive():
			continue

		var player_choices: Array[RewardChoice] = []

		# Get available relics for this player (character-specific + universal)
		var available_relics = _get_available_relics_for_player(player)
		available_relics.shuffle()

		# Offer up to 3 relics
		var num_relics = min(GameConstants.REWARD_RELIC_CHOICES, available_relics.size())
		for i in range(num_relics):
			var relic_id = available_relics[i]
			var relic_choice = RewardChoice.new()
			relic_choice.choice_type = RewardChoice.ChoiceType.RELIC
			relic_choice.relic_id = relic_id
			relic_choice.display_name = RelicRegistry.get_display_name(relic_id)
			relic_choice.description = RelicRegistry.get_description(relic_id)
			player_choices.append(relic_choice)

		if not player_choices.is_empty():
			choices[player_idx] = player_choices

	return choices

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _get_card_pool_for_player(player: Character) -> Array[Card]:
	var card_pool: Array[Card] = []

	# Check if this hero has a custom reward deck
	if player.hero_id != "" and hero_db.has_reward_deck(player.hero_id):
		card_pool = hero_db.get_reward_deck(player.hero_id)
		print("[REWARD] Using hero-specific reward deck for ", player.character_name)
	else:
		# Fallback to generic common cards
		card_pool = card_db.get_common_cards()
		print("[REWARD] Using generic common pool for ", player.character_name)

	return card_pool

func _get_available_relics_for_player(player: Character) -> Array[String]:
	var available: Array[String] = []

	# Get universal relics
	var universal = RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.UNIVERSAL)
	for relic_id in universal:
		if not player.has_relic(relic_id):
			available.append(relic_id)

	# Get character-specific relics based on hero_id/character_name
	var char_name = player.character_name.to_lower()
	var hero_id = player.hero_id.to_lower() if player.hero_id else ""

	if "fabio" in char_name or "fabio" in hero_id:
		var fabio_relics = RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.FABIO)
		for relic_id in fabio_relics:
			if not player.has_relic(relic_id):
				available.append(relic_id)
	elif "kevin" in char_name or "kevin" in hero_id:
		var kevin_relics = RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.KEVIN)
		for relic_id in kevin_relics:
			if not player.has_relic(relic_id):
				available.append(relic_id)
	elif "enrique" in char_name or "enrique" in hero_id:
		var enrique_relics = RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.ENRIQUE)
		for relic_id in enrique_relics:
			if not player.has_relic(relic_id):
				available.append(relic_id)

	return available

func _any_players_dead() -> bool:
	for player in game_manager.players:
		if not player.is_alive():
			return true
	return false

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_all_rewards_complete():
	print("[REWARD] All rewards complete for phase ", reward_phase)

	main_panel.visible = false
	relic_panel.visible = false
	skip_button.visible = false

	# For boss encounters, move to relic phase after card phase
	if encounter_type != GameManager.EncounterType.MINION and reward_phase == 0:
		await get_tree().create_timer(1.0).timeout
		start_relic_reward()
	else:
		# All phases complete
		wizard.say("Your choices are made! Steel yourselves...\nThe next challenge awaits!")
		await get_tree().create_timer(2.0).timeout
		_show_continue_button()

func _show_continue_button():
	if multiplayer.is_server():
		continue_button.visible = true
	else:
		continue_button.text = "Waiting for host to continue..."
		continue_button.disabled = true
		continue_button.visible = true

func _on_private_choice_made(player_index: int, choice: RewardChoice):
	print("[REWARD] Private choice made by player ", player_index)

	# Hide panels for this player immediately
	main_panel.visible = false
	relic_panel.visible = false
	skip_button.visible = false

	# Send choice to server for processing
	if multiplayer.is_server():
		_apply_and_check_private_choice(player_index, choice)
	else:
		rpc_id(1, "server_receive_private_choice", player_index, choice.serialize())

@rpc("any_peer", "call_remote", "reliable")
func server_receive_private_choice(player_index: int, choice_data: Dictionary):
	var choice = RewardChoice.deserialize(choice_data)
	_apply_and_check_private_choice(player_index, choice)

func _apply_and_check_private_choice(player_index: int, choice: RewardChoice):
	# Apply the choice
	reward_manager.apply_private_choice(player_index, choice)

	# Broadcast updated ready status to all clients
	var ready_indices = Array(reward_manager._players_ready.keys())
	rpc("client_update_ready_status", ready_indices)

	# Check if all players are ready (server only)
	if reward_manager.check_all_players_ready():
		rpc("client_all_players_ready")

@rpc("any_peer", "call_local", "reliable")
func client_update_ready_status(ready_indices: Array):
	reward_manager.update_ready_status(ready_indices)

@rpc("any_peer", "call_local", "reliable")
func client_all_players_ready():
	reward_manager.notify_all_players_ready()

func _on_continue_pressed():
	if not multiplayer.is_server():
		return

	var boss_idx = game_manager.boss_index

	# Initialize next combat encounter
	if boss_idx < 5:
		game_manager.initialize_combat_encounter.rpc(GameManager.EncounterType.MINION, boss_idx)
	else:
		print("[REWARD] All bosses defeated! Victory!")
		# TODO: Transition to victory screen
		return

	await get_tree().create_timer(0.5).timeout

	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.change_scene_synchronized.rpc("res://scenes/combat.tscn")

func _on_skip_pressed():
	skip_button.visible = false
	var my_index = game_manager.local_player_index

	if reward_phase == 0:
		# Card/heal/revive phase
		var choices: Dictionary
		if encounter_type == GameManager.EncounterType.MINION:
			choices = _generate_minion_choices()
		else:
			choices = _generate_boss_card_choices()

		if choices.has(my_index) and choices[my_index].size() > 0:
			_on_private_choice_made(my_index, choices[my_index][0])
	else:
		# Relic phase
		var choices = _generate_relic_choices()
		if choices.has(my_index) and choices[my_index].size() > 0:
			_on_private_choice_made(my_index, choices[my_index][0])
