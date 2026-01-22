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

## Create a test player with Aura support (for Enrique)
static func create_enrique_player(hp: int = 100, stamina: int = 10, aura: int = 5) -> Character:
	var player = Character.new()
	player.character_name = "Enrique"
	player.hero_id = "enrique"
	player.max_health = hp
	player.current_health = hp
	player.max_stamina = stamina
	player.current_stamina = stamina
	player.starting_stamina = stamina
	player.max_aura = aura
	player.current_aura = aura
	player.starting_aura = aura
	return player

## Create a test player with Satchel support (for Kevin)
static func create_kevin_player(hp: int = 100, stamina: int = 10) -> Character:
	var player = Character.new()
	player.character_name = "Kevin"
	player.hero_id = "kevin"
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

## Apply a single debuff to a character
static func apply_debuff(character: Character, debuff_name: String, stacks: int = 1):
	match debuff_name:
		"poison": character.poison = stacks
		"bleed": character.bleed = stacks
		"feeble": character.feeble = stacks
		"burn": character.burn = stacks
		"weakness": character.weakness = stacks
		"vulnerable": character.vulnerable = stacks
		"hinder": character.hinder = stacks
		"scared": character.scared = stacks
		"wet": character.wet = stacks
		"fatigued": character.fatigued = stacks
		"exhausted": character.exhausted = stacks
		"decay": character.decay = stacks
		_: push_warning("Unknown debuff: " + debuff_name)

## Apply multiple debuffs at once (dictionary: debuff_name -> stacks)
static func apply_debuffs(character: Character, debuffs: Dictionary):
	for debuff_name in debuffs:
		apply_debuff(character, debuff_name, debuffs[debuff_name])

## Apply a single buff to a character
static func apply_buff(character: Character, buff_name: String, stacks: int = 1):
	match buff_name:
		"strength": character.strength = stacks
		"armor": character.armor = stacks
		"rested": character.rested = stacks
		"invigorated": character.invigorated = stacks
		"damage_plus": character.damage_plus = stacks
		"played_twice": character.played_twice = stacks
		"invincible": character.invincible = stacks
		"ring_of_fire": character.ring_of_fire = stacks
		_: push_warning("Unknown buff: " + buff_name)

## Count total debuffs on a character (for bonus_damage_per_debuff tests)
static func count_debuffs(character: Character) -> int:
	var count = 0
	count += character.poison
	count += character.bleed
	count += character.feeble
	count += character.burn
	count += character.weakness
	count += character.vulnerable
	count += character.hinder
	count += character.scared
	count += character.wet
	count += character.fatigued
	count += character.exhausted
	count += character.decay
	return count

## Verify character has no status effects (for clean state testing)
static func verify_clean_state(character: Character) -> bool:
	if character.shield != 0: return false
	if count_debuffs(character) > 0: return false
	if character.strength != 0: return false
	if character.armor != 0: return false
	if character.rested != 0: return false
	if character.invigorated != 0: return false
	if character.damage_plus != 0: return false
	return true

## Create a boss character for testing
static func create_test_boss(boss_name: String, hp: int = 100) -> Character:
	var boss = Character.new()
	boss.character_name = boss_name
	boss.max_health = hp
	boss.current_health = hp
	boss.character_role = Character.CharacterRole.BOSS
	return boss

## Create a minion character for testing
static func create_test_minion(minion_name: String, hp: int = 50) -> Character:
	var minion = Character.new()
	minion.character_name = minion_name
	minion.max_health = hp
	minion.current_health = hp
	minion.character_role = Character.CharacterRole.MINION
	minion.is_minion = true
	return minion

## Set up combat with multiple players and enemies
static func setup_combat_multi(gm: Node, players: Array, enemies: Array):
	setup_combat(gm, players, enemies)

## Check if a character is below 50% HP (for wounded bonus tests)
static func is_wounded(character: Character) -> bool:
	return character.current_health < (character.max_health / 2.0)

## Damage a character to put them below 50% HP
static func make_wounded(character: Character):
	character.current_health = int(character.max_health * 0.4)  # 40% HP
