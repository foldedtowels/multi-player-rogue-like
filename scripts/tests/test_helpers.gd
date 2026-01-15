class_name TestHelpers
## Utility functions for setting up automated test scenarios

## Create a test player character with specified stats
static func create_test_player(char_name: String, hp: int = 100, stamina: int = 10) -> Character:
	var player = Character.new()
	player.character_name = char_name
	player.max_health = hp
	player.current_health = hp
	player.max_stamina = stamina
	player.current_stamina = stamina
	player.starting_stamina = stamina
	return player

## Create a test enemy character with specified stats
static func create_test_enemy(char_name: String, hp: int = 100) -> Character:
	var enemy = Character.new()
	enemy.character_name = char_name
	enemy.max_health = hp
	enemy.current_health = hp
	return enemy

## Set up combat state in GameManager without UI
static func setup_combat(gm: Node, test_players: Array, test_enemies: Array):
	# Clear existing state
	gm.players.clear()
	gm.enemies.clear()
	gm.protected_by.clear()
	gm.delayed_effects.clear()
	gm.queued_cards.clear()

	# Add characters
	for p in test_players:
		gm.players.append(p)
	for e in test_enemies:
		gm.enemies.append(e)

	# Set state
	gm.local_player_index = 0
	gm.current_state = gm.GameState.COMBAT
	gm.turn_phase = gm.TurnPhase.PLAYER_TURN
	gm.round_number = 1

## Give a card to a player's hand (duplicates to avoid shared state)
static func give_card(player: Character, card: Card):
	if card:
		player.hand.append(card.duplicate())

## Simulate end of turn for all characters (status decay, etc.)
static func simulate_end_turn(gm: Node):
	for player in gm.players:
		if player.is_alive():
			player.end_turn(gm.round_number)
	for enemy in gm.enemies:
		if enemy.is_alive():
			enemy.end_turn(gm.round_number)

## Simulate start of new turn (stamina reset, status application)
static func simulate_start_turn(gm: Node):
	gm.round_number += 1
	for player in gm.players:
		if player.is_alive():
			player.start_turn()

## Reset a character to clean state (no status effects)
static func reset_character(character: Character):
	character.current_health = character.max_health
	character.current_stamina = character.max_stamina
	character.shield = 0
	character.status_effects.clear()
	character.hand.clear()
	character.deck.clear()
	character.discard_pile.clear()
