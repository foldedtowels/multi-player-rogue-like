extends Node

var card_db: Node
var boss_cards_created: bool = false

func _ready():
	card_db = get_node("/root/CardDatabase")

# Boss-specific cards
func create_boss_cards():
	if boss_cards_created:
		return
	boss_cards_created = true
	# === CORRUPTED TREANT CARDS ===
	var root_lash = Card.new()
	root_lash.card_name = "Root Lash"
	root_lash.description = "Whip with thorny roots."
	root_lash.card_type = Card.CardType.ATTACK
	root_lash.target_type = Card.TargetType.RANDOM_ENEMY
	root_lash.energy_cost = 1
	root_lash.damage = 8
	card_db.all_cards["root_lash"] = root_lash

	var bark_armor = Card.new()
	bark_armor.card_name = "Bark Armor"
	bark_armor.description = "Harden bark for protection."
	bark_armor.card_type = Card.CardType.BUFF
	bark_armor.target_type = Card.TargetType.SELF
	bark_armor.energy_cost = 1
	bark_armor.shield_amount = 10
	card_db.all_cards["bark_armor"] = bark_armor

	var natures_wrath = Card.new()
	natures_wrath.card_name = "Nature's Wrath"
	natures_wrath.description = "Channel corrupted nature energy."
	natures_wrath.card_type = Card.CardType.ATTACK
	natures_wrath.target_type = Card.TargetType.ALL_ENEMIES
	natures_wrath.energy_cost = 2
	natures_wrath.damage = 6
	natures_wrath.aoe_damage = true
	card_db.all_cards["natures_wrath"] = natures_wrath

	# === FLAME WARLORD CARDS ===
	var battle_axe = Card.new()
	battle_axe.card_name = "Battle Axe"
	battle_axe.description = "Heavy strike with flaming weapon."
	battle_axe.card_type = Card.CardType.ATTACK
	battle_axe.target_type = Card.TargetType.RANDOM_ENEMY
	battle_axe.energy_cost = 1
	battle_axe.damage = 12
	card_db.all_cards["battle_axe"] = battle_axe

	var war_cry = Card.new()
	war_cry.card_name = "War Cry"
	war_cry.description = "Rally strength for the next assault."
	war_cry.card_type = Card.CardType.BUFF
	war_cry.target_type = Card.TargetType.SELF
	war_cry.energy_cost = 1
	war_cry.apply_strength = 3
	card_db.all_cards["war_cry"] = war_cry

	var inferno_wave = Card.new()
	inferno_wave.card_name = "Inferno Wave"
	inferno_wave.description = "Massive fire blast."
	inferno_wave.card_type = Card.CardType.ATTACK
	inferno_wave.target_type = Card.TargetType.ALL_ENEMIES
	inferno_wave.energy_cost = 2
	inferno_wave.damage = 10
	inferno_wave.apply_burn = 3
	inferno_wave.aoe_damage = true
	card_db.all_cards["inferno_wave"] = inferno_wave

	var flame_shield = Card.new()
	flame_shield.card_name = "Flame Shield"
	flame_shield.description = "Barrier of living fire."
	flame_shield.card_type = Card.CardType.BUFF
	flame_shield.target_type = Card.TargetType.SELF
	flame_shield.energy_cost = 1
	flame_shield.shield_amount = 15
	card_db.all_cards["flame_shield"] = flame_shield

	# === LICH SUMMONER CARDS ===
	var death_coil = Card.new()
	death_coil.card_name = "Death Coil"
	death_coil.description = "Drain life from enemies."
	death_coil.card_type = Card.CardType.ATTACK
	death_coil.target_type = Card.TargetType.RANDOM_ENEMY
	death_coil.energy_cost = 1
	death_coil.damage = 10
	death_coil.lifesteal = true
	card_db.all_cards["death_coil"] = death_coil

	var plague_cloud = Card.new()
	plague_cloud.card_name = "Plague Cloud"
	plague_cloud.description = "Spread disease to all foes."
	plague_cloud.card_type = Card.CardType.DEBUFF
	plague_cloud.target_type = Card.TargetType.ALL_ENEMIES
	plague_cloud.energy_cost = 2
	plague_cloud.apply_poison = 4
	plague_cloud.damage = 5
	plague_cloud.aoe_damage = true
	card_db.all_cards["plague_cloud"] = plague_cloud

	var bone_shield = Card.new()
	bone_shield.card_name = "Bone Shield"
	bone_shield.description = "Summon protective bones."
	bone_shield.card_type = Card.CardType.BUFF
	bone_shield.target_type = Card.TargetType.SELF
	bone_shield.energy_cost = 1
	bone_shield.shield_amount = 12
	bone_shield.apply_armor = 2
	card_db.all_cards["bone_shield"] = bone_shield

	var dark_ritual = Card.new()
	dark_ritual.card_name = "Dark Ritual"
	dark_ritual.description = "Sacrifice life for power."
	dark_ritual.card_type = Card.CardType.BUFF
	dark_ritual.target_type = Card.TargetType.SELF
	dark_ritual.energy_cost = 1
	dark_ritual.apply_strength = 4
	dark_ritual.heal_amount = -8
	card_db.all_cards["dark_ritual"] = dark_ritual

	var soul_drain = Card.new()
	soul_drain.card_name = "Soul Drain"
	soul_drain.description = "Consume enemy essence."
	soul_drain.card_type = Card.CardType.ATTACK
	soul_drain.target_type = Card.TargetType.RANDOM_ENEMY
	soul_drain.energy_cost = 2
	soul_drain.damage = 15
	soul_drain.lifesteal = true
	soul_drain.apply_weakness = 2
	card_db.all_cards["soul_drain"] = soul_drain

	# === STORM DRAGON CARDS ===
	var dragon_bite = Card.new()
	dragon_bite.card_name = "Dragon Bite"
	dragon_bite.description = "Crushing jaws."
	dragon_bite.card_type = Card.CardType.ATTACK
	dragon_bite.target_type = Card.TargetType.RANDOM_ENEMY
	dragon_bite.energy_cost = 1
	dragon_bite.damage = 16
	card_db.all_cards["dragon_bite"] = dragon_bite

	var lightning_breath = Card.new()
	lightning_breath.card_name = "Lightning Breath"
	lightning_breath.description = "Devastating electrical discharge."
	lightning_breath.card_type = Card.CardType.ATTACK
	lightning_breath.target_type = Card.TargetType.ALL_ENEMIES
	lightning_breath.energy_cost = 2
	lightning_breath.damage = 14
	lightning_breath.apply_vulnerable = 2
	lightning_breath.aoe_damage = true
	card_db.all_cards["lightning_breath"] = lightning_breath

	var wing_buffet = Card.new()
	wing_buffet.card_name = "Wing Buffet"
	wing_buffet.description = "Powerful wind blast."
	wing_buffet.card_type = Card.CardType.ATTACK
	wing_buffet.target_type = Card.TargetType.ALL_ENEMIES
	wing_buffet.energy_cost = 2
	wing_buffet.damage = 10
	wing_buffet.apply_weakness = 2
	wing_buffet.aoe_damage = true
	card_db.all_cards["wing_buffet"] = wing_buffet

	var dragon_scales = Card.new()
	dragon_scales.card_name = "Dragon Scales"
	dragon_scales.description = "Impenetrable armor."
	dragon_scales.card_type = Card.CardType.BUFF
	dragon_scales.target_type = Card.TargetType.SELF
	dragon_scales.energy_cost = 1
	dragon_scales.shield_amount = 20
	dragon_scales.apply_armor = 3
	card_db.all_cards["dragon_scales"] = dragon_scales

	var thunderstorm = Card.new()
	thunderstorm.card_name = "Thunderstorm"
	thunderstorm.description = "Call down devastating lightning."
	thunderstorm.card_type = Card.CardType.ATTACK
	thunderstorm.target_type = Card.TargetType.ALL_ENEMIES
	thunderstorm.energy_cost = 3
	thunderstorm.damage = 18
	thunderstorm.aoe_damage = true
	card_db.all_cards["thunderstorm"] = thunderstorm

	# === VOID TITAN CARDS ===
	var void_slam = Card.new()
	void_slam.card_name = "Void Slam"
	void_slam.description = "Reality-shattering blow."
	void_slam.card_type = Card.CardType.ATTACK
	void_slam.target_type = Card.TargetType.RANDOM_ENEMY
	void_slam.energy_cost = 1
	void_slam.damage = 20
	void_slam.piercing = true
	card_db.all_cards["void_slam"] = void_slam

	var cosmic_beam = Card.new()
	cosmic_beam.card_name = "Cosmic Beam"
	cosmic_beam.description = "Annihilating energy blast."
	cosmic_beam.card_type = Card.CardType.ATTACK
	cosmic_beam.target_type = Card.TargetType.ALL_ENEMIES
	cosmic_beam.energy_cost = 2
	cosmic_beam.damage = 16
	cosmic_beam.piercing = true
	cosmic_beam.aoe_damage = true
	card_db.all_cards["cosmic_beam"] = cosmic_beam

	var void_armor = Card.new()
	void_armor.card_name = "Void Armor"
	void_armor.description = "Shield of nothingness."
	void_armor.card_type = Card.CardType.BUFF
	void_armor.target_type = Card.TargetType.SELF
	void_armor.energy_cost = 1
	void_armor.shield_amount = 25
	void_armor.apply_armor = 5
	card_db.all_cards["void_armor"] = void_armor

	var reality_tear = Card.new()
	reality_tear.card_name = "Reality Tear"
	reality_tear.description = "Rip through existence itself."
	reality_tear.card_type = Card.CardType.ATTACK
	reality_tear.target_type = Card.TargetType.ALL_ENEMIES
	reality_tear.energy_cost = 3
	reality_tear.damage = 22
	reality_tear.apply_vulnerable = 3
	reality_tear.piercing = true
	reality_tear.aoe_damage = true
	card_db.all_cards["reality_tear"] = reality_tear

	var entropy = Card.new()
	entropy.card_name = "Entropy"
	entropy.description = "Spread chaos and decay."
	entropy.card_type = Card.CardType.DEBUFF
	entropy.target_type = Card.TargetType.ALL_ENEMIES
	entropy.energy_cost = 2
	entropy.apply_poison = 5
	entropy.apply_burn = 5
	entropy.apply_weakness = 2
	card_db.all_cards["entropy"] = entropy

func create_corrupted_treant() -> Character:
	var boss = Character.new()
	boss.character_name = "Corrupted Treant"
	boss.description = "Ancient guardian twisted by dark magic."
	boss.max_health = 200
	boss.current_health = 200
	boss.starting_energy = 2
	boss.max_energy = 2
	boss.current_energy = 2

	var deck: Array[Card] = []
	for i in 6:
		deck.append(card_db.get_card("root_lash"))
	for i in 4:
		deck.append(card_db.get_card("bark_armor"))
	for i in 3:
		deck.append(card_db.get_card("natures_wrath"))

	boss.starting_deck = deck
	boss.reset_deck()  # Initialize deck now that starting_deck is populated
	return boss

func create_flame_warlord() -> Character:
	var boss = Character.new()
	boss.character_name = "Flame Warlord"
	boss.description = "Brutal warrior engulfed in eternal flames."
	boss.max_health = 280
	boss.current_health = 280
	boss.starting_energy = 3
	boss.max_energy = 3
	boss.current_energy = 3

	var deck: Array[Card] = []
	for i in 5:
		deck.append(card_db.get_card("battle_axe"))
	for i in 3:
		deck.append(card_db.get_card("war_cry"))
	for i in 4:
		deck.append(card_db.get_card("inferno_wave"))
	for i in 3:
		deck.append(card_db.get_card("flame_shield"))

	boss.starting_deck = deck
	boss.reset_deck()  # Initialize deck now that starting_deck is populated
	return boss

func create_lich_summoner() -> Character:
	var boss = Character.new()
	boss.character_name = "Lich Summoner"
	boss.description = "Undead necromancer who commands death itself."
	boss.max_health = 350
	boss.current_health = 350
	boss.starting_energy = 3
	boss.max_energy = 3
	boss.current_energy = 3

	var deck: Array[Card] = []
	for i in 4:
		deck.append(card_db.get_card("death_coil"))
	for i in 4:
		deck.append(card_db.get_card("plague_cloud"))
	for i in 3:
		deck.append(card_db.get_card("bone_shield"))
	for i in 2:
		deck.append(card_db.get_card("dark_ritual"))
	for i in 3:
		deck.append(card_db.get_card("soul_drain"))

	boss.starting_deck = deck
	boss.reset_deck()  # Initialize deck now that starting_deck is populated
	return boss

func create_storm_dragon() -> Character:
	var boss = Character.new()
	boss.character_name = "Storm Dragon"
	boss.description = "Ancient wyrm that commands lightning and thunder."
	boss.max_health = 450
	boss.current_health = 450
	boss.starting_energy = 4
	boss.max_energy = 4
	boss.current_energy = 4

	var deck: Array[Card] = []
	for i in 4:
		deck.append(card_db.get_card("dragon_bite"))
	for i in 4:
		deck.append(card_db.get_card("lightning_breath"))
	for i in 3:
		deck.append(card_db.get_card("wing_buffet"))
	for i in 3:
		deck.append(card_db.get_card("dragon_scales"))
	for i in 2:
		deck.append(card_db.get_card("thunderstorm"))

	boss.starting_deck = deck
	boss.reset_deck()  # Initialize deck now that starting_deck is populated
	return boss

func create_void_titan() -> Character:
	var boss = Character.new()
	boss.character_name = "Void Titan"
	boss.description = "Cosmic horror from beyond reality."
	boss.max_health = 600
	boss.current_health = 600
	boss.starting_energy = 4
	boss.max_energy = 4
	boss.current_energy = 4

	var deck: Array[Card] = []
	for i in 5:
		deck.append(card_db.get_card("void_slam"))
	for i in 4:
		deck.append(card_db.get_card("cosmic_beam"))
	for i in 3:
		deck.append(card_db.get_card("void_armor"))
	for i in 3:
		deck.append(card_db.get_card("reality_tear"))
	for i in 2:
		deck.append(card_db.get_card("entropy"))

	boss.starting_deck = deck
	boss.reset_deck()  # Initialize deck now that starting_deck is populated
	return boss

func get_boss(index: int) -> Character:
	create_boss_cards()
	match index:
		0: return create_corrupted_treant()
		1: return create_flame_warlord()
		2: return create_lich_summoner()
		3: return create_storm_dragon()
		4: return create_void_titan()
	return null

func get_all_bosses() -> Array[Character]:
	create_boss_cards()
	var bosses: Array[Character] = []
	bosses.append(create_corrupted_treant())
	bosses.append(create_flame_warlord())
	bosses.append(create_lich_summoner())
	bosses.append(create_storm_dragon())
	bosses.append(create_void_titan())
	return bosses
