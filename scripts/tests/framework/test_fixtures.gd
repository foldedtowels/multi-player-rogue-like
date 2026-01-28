class_name TestFixtures
## Utility functions for setting up test scenarios
## Provides consistent character creation and combat setup

# ============================================
# CHARACTER CREATION
# ============================================

## Create a generic test player
static func player(char_name: String, hp: int = 100, stamina: int = 10) -> Character:
	var p = Character.new()
	p.character_name = char_name
	p.max_health = hp
	p.current_health = hp
	p.max_stamina = stamina
	p.current_stamina = stamina
	p.starting_stamina = stamina
	return p


## Create Fabio (Warrior) for testing
static func fabio(hp: int = 50, stamina: int = 3) -> Character:
	var p = Character.new()
	p.character_name = "Fabio"
	p.hero_id = "fabio"
	p.max_health = hp
	p.current_health = hp
	p.max_stamina = stamina
	p.current_stamina = stamina
	p.starting_stamina = stamina
	return p


## Create Kevin (Alchemist) for testing
static func kevin(hp: int = 40, stamina: int = 3) -> Character:
	var p = Character.new()
	p.character_name = "Kevin"
	p.hero_id = "kevin"
	p.max_health = hp
	p.current_health = hp
	p.max_stamina = stamina
	p.current_stamina = stamina
	p.starting_stamina = stamina
	return p


## Create Enrique (Cleric) for testing with aura
static func enrique(hp: int = 30, stamina: int = 3, aura: int = 5) -> Character:
	var p = Character.new()
	p.character_name = "Enrique"
	p.hero_id = "enrique"
	p.max_health = hp
	p.current_health = hp
	p.max_stamina = stamina
	p.current_stamina = stamina
	p.starting_stamina = stamina
	p.max_aura = aura
	p.current_aura = aura
	p.starting_aura = aura
	return p


## Create a test enemy
static func enemy(char_name: String, hp: int = 100) -> Character:
	var e = Character.new()
	e.character_name = char_name
	e.max_health = hp
	e.current_health = hp
	return e


## Create a boss for testing
static func boss(boss_name: String, hp: int = 100) -> Character:
	var b = Character.new()
	b.character_name = boss_name
	b.max_health = hp
	b.current_health = hp
	b.character_role = Character.CharacterRole.BOSS
	return b


## Create a minion for testing
static func minion(minion_name: String, hp: int = 50) -> Character:
	var m = Character.new()
	m.character_name = minion_name
	m.max_health = hp
	m.current_health = hp
	m.character_role = Character.CharacterRole.MINION
	m.is_minion = true
	return m


# ============================================
# COMBAT SETUP
# ============================================

## Set up combat state in GameManager
static func combat(gm: Node, players: Array, enemies: Array) -> void:
	# Clear existing state
	gm.players.clear()
	gm.enemies.clear()
	gm.protected_by.clear()
	gm.delayed_effects.clear()
	gm.queued_cards.clear()

	# Add characters
	for p in players:
		gm.players.append(p)
	for e in enemies:
		gm.enemies.append(e)

	# Set state
	gm.local_player_index = 0
	gm.current_state = gm.GameState.COMBAT
	gm.turn_phase = gm.TurnPhase.PLAYER_TURN
	gm.round_number = 1


## Set up multiplayer combat with N players and M enemies
static func multiplayer_combat(gm: Node, player_count: int, enemy_count: int) -> Array:
	var players: Array = []
	var enemies: Array = []

	for i in range(player_count):
		var names = ["Fabio", "Kevin", "Enrique", "Player4"]
		var p = player(names[i % names.size()], 100, 10)
		players.append(p)

	for i in range(enemy_count):
		var e = enemy("Enemy%d" % (i + 1), 100)
		enemies.append(e)

	combat(gm, players, enemies)
	return [players, enemies]


# ============================================
# CARD MANIPULATION
# ============================================

## Give a card to a character's hand
static func give_card(char: Character, card_id: String, card_db: Node) -> Card:
	var card = card_db.get_card(card_id)
	if card:
		var dup = card.duplicate()
		char.hand.append(dup)
		return dup
	return null


## Give multiple cards to a character's hand
static func give_cards(char: Character, card_ids: Array, card_db: Node) -> Array[Card]:
	var cards: Array[Card] = []
	for card_id in card_ids:
		var card = give_card(char, card_id, card_db)
		if card:
			cards.append(card)
	return cards


## Set a character's entire hand
static func set_hand(char: Character, card_ids: Array, card_db: Node) -> void:
	char.hand.clear()
	give_cards(char, card_ids, card_db)


## Give a card to deck
static func give_card_to_deck(char: Character, card_id: String, card_db: Node) -> Card:
	var card = card_db.get_card(card_id)
	if card:
		var dup = card.duplicate()
		char.deck.append(dup)
		return dup
	return null


## Create a simple attack card for testing
static func make_attack_card(name: String, damage: int, cost: int = 1) -> Card:
	var card = Card.new()
	card.card_name = name
	card.damage = damage
	card.stamina_cost = cost
	card.card_type = Card.CardType.ATTACK
	card.target_type = Card.TargetType.SINGLE_ENEMY
	return card


## Create a simple buff card for testing
static func make_buff_card(name: String, shield: int = 0, heal: int = 0, cost: int = 1) -> Card:
	var card = Card.new()
	card.card_name = name
	card.shield = shield
	card.heal = heal
	card.stamina_cost = cost
	card.card_type = Card.CardType.BUFF
	card.target_type = Card.TargetType.SELF
	return card


# ============================================
# STATUS EFFECTS
# ============================================

## Apply a buff to a character
static func apply_buff(char: Character, buff_name: String, stacks: int) -> void:
	match buff_name:
		"strength": char.strength = stacks
		"armor": char.armor = stacks
		"rested": char.rested = stacks
		"invigorated": char.invigorated = stacks
		"damage_plus": char.damage_plus = stacks
		"played_twice": char.played_twice = stacks
		"invincible": char.invincible = stacks
		"ring_of_fire": char.ring_of_fire = stacks
		_: push_warning("Unknown buff: " + buff_name)


## Apply a debuff to a character
static func apply_debuff(char: Character, debuff_name: String, stacks: int) -> void:
	match debuff_name:
		"poison": char.poison = stacks
		"bleed": char.bleed = stacks
		"burn": char.burn = stacks
		"feeble": char.feeble = stacks
		"weakness": char.weakness = stacks
		"vulnerable": char.vulnerable = stacks
		"hinder": char.hinder = stacks
		"scared": char.scared = stacks
		"wet": char.wet = stacks
		"fatigued": char.fatigued = stacks
		"exhausted": char.exhausted = stacks
		"decay": char.decay = stacks
		"venom": char.venom = stacks
		"burden": char.burden = stacks
		"dissolve": char.dissolve = stacks
		"doll_dissolve": char.doll_dissolve = stacks
		"doll_suffering": char.doll_suffering = stacks
		"doll_burden": char.doll_burden = stacks
		_: push_warning("Unknown debuff: " + debuff_name)


## Apply multiple buffs at once
static func apply_buffs(char: Character, buffs: Dictionary) -> void:
	for buff_name in buffs:
		apply_buff(char, buff_name, buffs[buff_name])


## Apply multiple debuffs at once
static func apply_debuffs(char: Character, debuffs: Dictionary) -> void:
	for debuff_name in debuffs:
		apply_debuff(char, debuff_name, debuffs[debuff_name])


## Clear all status effects from a character
static func clear_effects(char: Character) -> void:
	char.status_effects.clear()
	char.shield = 0


## Count total debuff stacks on a character
static func count_debuffs(char: Character) -> int:
	var count = 0
	count += char.poison
	count += char.bleed
	count += char.burn
	count += char.feeble
	count += char.weakness
	count += char.vulnerable
	count += char.hinder
	count += char.scared
	count += char.wet
	count += char.fatigued
	count += char.exhausted
	count += char.decay
	count += char.venom
	count += char.burden
	count += char.dissolve
	return count


# ============================================
# RELICS
# ============================================

## Give a relic to a character
static func give_relic(char: Character, relic_id: String) -> void:
	char.add_relic(relic_id)


## Give multiple relics to a character
static func give_relics(char: Character, relic_ids: Array) -> void:
	for relic_id in relic_ids:
		give_relic(char, relic_id)


## Apply ON_PICKUP effect for a relic
## Note: Tests needing ON_PICKUP effect should call RelicRegistry directly
static func apply_relic_pickup(char: Character, relic_id: String) -> void:
	give_relic(char, relic_id)
	# ON_PICKUP must be called from test directly: RelicRegistry.apply_on_pickup(char, relic_id)


# ============================================
# TURN SIMULATION
# ============================================

## Simulate start of turn
static func start_turn(gm: Node) -> void:
	gm.round_number += 1
	for player in gm.players:
		if player.is_alive():
			player.start_turn()


## Simulate end of turn for all characters
static func end_turn(gm: Node) -> void:
	for player in gm.players:
		if player.is_alive():
			player.end_turn(gm.round_number)
	for enemy in gm.enemies:
		if enemy.is_alive():
			enemy.end_turn(gm.round_number)


## Advance multiple turns
static func advance_turns(gm: Node, count: int) -> void:
	for i in range(count):
		end_turn(gm)
		start_turn(gm)


# ============================================
# STATE HELPERS
# ============================================

## Damage a character to wounded state (<50% HP)
static func wound(char: Character) -> void:
	char.current_health = int(char.max_health * 0.4)  # 40% HP


## Kill a character
static func kill(char: Character) -> void:
	char.current_health = 0


## Revive a character with specified HP
static func revive(char: Character, hp: int = -1) -> void:
	if hp < 0:
		hp = int(char.max_health * 0.5)  # Default to 50%
	char.current_health = hp


## Set character to exact HP
static func set_hp(char: Character, hp: int) -> void:
	char.current_health = hp


## Set character to exact stamina
static func set_stamina(char: Character, stamina: int) -> void:
	char.current_stamina = stamina


## Set character to exact aura (Enrique)
static func set_aura(char: Character, aura: int) -> void:
	char.current_aura = aura


## Give shield to character
static func give_shield(char: Character, amount: int) -> void:
	char.shield = amount


## Reset character to clean state
static func reset(char: Character) -> void:
	char.current_health = char.max_health
	char.current_stamina = char.max_stamina
	char.shield = 0
	char.status_effects.clear()
	char.hand.clear()
	char.deck.clear()
	char.discard_pile.clear()


## Verify character has no status effects
static func is_clean(char: Character) -> bool:
	if char.shield != 0: return false
	if count_debuffs(char) > 0: return false
	if char.strength != 0: return false
	if char.armor != 0: return false
	if char.rested != 0: return false
	if char.invigorated != 0: return false
	if char.damage_plus != 0: return false
	return true
