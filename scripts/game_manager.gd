extends Node

signal player_turn_started(player_index: int)
signal boss_turn_started()
signal card_played(character: Character, card: Card, target: Character)
signal combat_ended(victory: bool)
signal game_state_changed()

enum GameState {
	CHARACTER_SELECTION,
	COMBAT,
	REWARD,
	GAME_OVER,
	VICTORY
}

var current_state: GameState = GameState.CHARACTER_SELECTION
var players: Array[Character] = []
var current_boss: Character
var boss_index: int = 0
var current_player_index: int = 0
var round_number: int = 1

var hero_db: Node
var boss_db: Node

func _ready():
	hero_db = get_node("/root/HeroDatabase")
	boss_db = get_node("/root/BossDatabase")

func start_new_game():
	players.clear()
	boss_index = 0
	current_state = GameState.CHARACTER_SELECTION
	game_state_changed.emit()

func select_heroes(hero_indices: Array):
	players.clear()
	var all_heroes = hero_db.get_all_heroes()

	for idx in hero_indices:
		if idx >= 0 and idx < all_heroes.size():
			# Duplicate the hero to avoid shared state
			var hero_copy = all_heroes[idx].duplicate_character()
			players.append(hero_copy)

	if players.size() == 3:
		start_boss_encounter()

func start_boss_encounter():
	current_boss = boss_db.get_boss(boss_index)
	if current_boss == null:
		# All bosses defeated!
		current_state = GameState.VICTORY
		game_state_changed.emit()
		return

	# Reset player debuffs between bosses
	for player in players:
		player.reset_debuffs()

	current_state = GameState.COMBAT
	round_number = 1
	current_player_index = 0

	# Characters are already initialized via their constructors
	# Don't call _init() manually - it's automatically called by Character.new()

	# Don't start turn here - let combat scene do it after _ready()

func start_player_turn(player_index: int):
	if player_index >= players.size():
		# All players have gone, now boss turn
		start_boss_turn()
		return

	current_player_index = player_index
	var player = players[player_index]

	if not player.is_alive():
		# Skip dead players
		print("[Game] Skipping turn for dead player: ", player.character_name)
		end_player_turn()
		return

	player.start_turn()
	player_turn_started.emit(player_index)

func end_player_turn():
	var player = players[current_player_index]
	player.end_turn()

	# Move to next player
	start_player_turn(current_player_index + 1)

func start_boss_turn():
	if not current_boss.is_alive():
		# Boss defeated!
		boss_defeated()
		return

	current_boss.start_turn()
	boss_turn_started.emit()

	# AI: Boss plays cards automatically
	await get_tree().create_timer(1.0).timeout
	play_boss_turn()

func play_boss_turn():
	# Simple AI: Play cards until out of energy
	var boss_hand = current_boss.hand.duplicate()

	for card in boss_hand:
		if not card.can_afford(current_boss.current_energy):
			continue

		var target = select_boss_target(card)
		if target:
			play_card(current_boss, card, target)
			await get_tree().create_timer(0.5).timeout

	end_boss_turn()

func select_boss_target(card: Card) -> Character:
	match card.target_type:
		Card.TargetType.SELF:
			return current_boss
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			# Target random alive player
			var alive_players = players.filter(func(p): return p.is_alive())
			if alive_players.size() > 0:
				return alive_players[randi() % alive_players.size()]
		Card.TargetType.ALL_ENEMIES:
			return players[0]  # Will be handled as AoE

	return null

func end_boss_turn():
	current_boss.end_turn()
	round_number += 1

	# Check if all players are dead
	var alive_count = 0
	for player in players:
		if player.is_alive():
			alive_count += 1

	if alive_count == 0:
		game_over()
		return

	# Start next round
	current_player_index = 0
	start_player_turn(0)

func play_card(caster: Character, card: Card, target: Character):
	if not caster.play_card(card):
		return

	card_played.emit(caster, card, target)

	# Apply card effects
	apply_card_effects(caster, card, target)

	game_state_changed.emit()

func apply_card_effects(caster: Character, card: Card, target: Character):
	# Determine targets based on target type
	var targets: Array[Character] = []

	match card.target_type:
		Card.TargetType.SELF:
			targets.append(caster)
		Card.TargetType.SINGLE_ALLY:
			targets.append(target)
		Card.TargetType.ALL_ALLIES:
			if caster == current_boss:
				targets.append(current_boss)
			else:
				targets = players.duplicate()
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			targets.append(target)
		Card.TargetType.ALL_ENEMIES:
			if caster == current_boss:
				targets = players.duplicate()
			else:
				targets.append(current_boss)

	# Apply effects to all targets
	for t in targets:
		if not t.is_alive():
			continue

		# Damage
		if card.damage > 0:
			for i in card.multi_hit:
				# Apply strength bonus to attack damage
				var total_damage = card.damage
				if card.card_type == Card.CardType.ATTACK:
					total_damage += caster.strength

				var damage_dealt = t.take_damage(total_damage, card.piercing)

				# Lifesteal
				if card.lifesteal:
					caster.heal(damage_dealt)

		# Healing
		if card.heal_amount > 0:
			t.heal(card.heal_amount)

		# Shield
		if card.shield_amount > 0:
			t.gain_shield(card.shield_amount)

		# Status effects
		if card.apply_poison > 0:
			t.poison += card.apply_poison
		if card.apply_burn > 0:
			t.burn += card.apply_burn
		if card.apply_strength > 0:
			t.strength += card.apply_strength
		if card.apply_vulnerable > 0:
			t.vulnerable += card.apply_vulnerable
		if card.apply_weakness > 0:
			t.weakness += card.apply_weakness
		if card.apply_armor > 0:
			t.armor += card.apply_armor

		# Card draw
		if card.draw_cards > 0 and (t == caster):
			t.draw_cards(card.draw_cards)

func boss_defeated():
	current_state = GameState.REWARD
	boss_index += 1

	await get_tree().create_timer(2.0).timeout

	if boss_index >= 5:
		victory()
	else:
		# Load reward scene
		get_tree().change_scene_to_file("res://scenes/reward.tscn")

func game_over():
	current_state = GameState.GAME_OVER
	combat_ended.emit(false)
	game_state_changed.emit()

func victory():
	current_state = GameState.VICTORY
	combat_ended.emit(true)
	game_state_changed.emit()
