extends Node

var card_db: Node

func _ready():
	card_db = get_node("/root/CardDatabase")

func _add_card_to_deck(deck: Array[Card], card_id: String):
	var card = card_db.get_card(card_id)
	if card:
		deck.append(card)
	else:
		push_warning("Failed to add card to deck: " + card_id)

func create_flame_wielder() -> Character:
	var hero = Character.new()
	hero.character_name = "Pyra, Flame Wielder"
	hero.description = "Master of fire magic, dealing devastating burn damage."
	hero.max_health = 90
	hero.starting_energy = 3

	# Starting deck - 20 cards (aggro burn deck)
	var deck: Array[Card] = []
	deck.append(card_db.get_card("lightning_bolt"))
	deck.append(card_db.get_card("lightning_bolt"))
	deck.append(card_db.get_card("shock"))
	deck.append(card_db.get_card("shock"))
	deck.append(card_db.get_card("shock"))
	deck.append(card_db.get_card("flame_slash"))
	deck.append(card_db.get_card("flame_slash"))
	deck.append(card_db.get_card("burning_hands"))
	deck.append(card_db.get_card("burning_hands"))
	deck.append(card_db.get_card("volcanic_strike"))
	deck.append(card_db.get_card("flame_barrier"))
	deck.append(card_db.get_card("flame_barrier"))
	deck.append(card_db.get_card("ignite"))
	deck.append(card_db.get_card("fireball"))

	print("[HeroDatabase] Pyra deck built with ", deck.size(), " cards")
	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	print("[HeroDatabase] After reset_deck, Pyra deck has ", hero.deck.size(), " cards")
	return hero

func create_life_weaver() -> Character:
	var hero = Character.new()
	hero.character_name = "Selene, Life Weaver"
	hero.description = "Divine healer and protector of allies."
	hero.max_health = 110
	hero.starting_energy = 3

	var deck: Array[Card] = []
	deck.append(card_db.get_card("healing_salve"))
	deck.append(card_db.get_card("healing_salve"))
	deck.append(card_db.get_card("healing_salve"))
	deck.append(card_db.get_card("divine_light"))
	deck.append(card_db.get_card("divine_light"))
	deck.append(card_db.get_card("holy_strike"))
	deck.append(card_db.get_card("holy_strike"))
	deck.append(card_db.get_card("guardian_shield"))
	deck.append(card_db.get_card("guardian_shield"))
	deck.append(card_db.get_card("guardian_shield"))
	deck.append(card_db.get_card("pacify"))
	deck.append(card_db.get_card("blessing"))
	deck.append(card_db.get_card("blessing"))
	deck.append(card_db.get_card("mass_heal"))
	deck.append(card_db.get_card("smite"))

	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	return hero

func create_shadow_assassin() -> Character:
	var hero = Character.new()
	hero.character_name = "Nyx, Shadow Assassin"
	hero.description = "Silent killer who drains life and spreads poison."
	hero.max_health = 85
	hero.starting_energy = 3

	var deck: Array[Card] = []
	deck.append(card_db.get_card("doom_blade"))
	deck.append(card_db.get_card("doom_blade"))
	deck.append(card_db.get_card("drain_life"))
	deck.append(card_db.get_card("drain_life"))
	deck.append(card_db.get_card("poison_strike"))
	deck.append(card_db.get_card("poison_strike"))
	deck.append(card_db.get_card("poison_strike"))
	deck.append(card_db.get_card("shadow_step"))
	deck.append(card_db.get_card("shadow_step"))
	deck.append(card_db.get_card("dark_pact"))
	deck.append(card_db.get_card("corrupt"))
	deck.append(card_db.get_card("corrupt"))
	deck.append(card_db.get_card("assassination"))
	deck.append(card_db.get_card("vampiric_touch"))

	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	return hero

func create_storm_caller() -> Character:
	var hero = Character.new()
	hero.character_name = "Zephyr, Storm Caller"
	hero.description = "Lightning mage who controls the battlefield with spells."
	hero.max_health = 95
	hero.starting_energy = 3

	var deck: Array[Card] = []
	deck.append(card_db.get_card("lightning_strike"))
	deck.append(card_db.get_card("lightning_strike"))
	deck.append(card_db.get_card("lightning_strike"))
	deck.append(card_db.get_card("frost_bolt"))
	deck.append(card_db.get_card("frost_bolt"))
	deck.append(card_db.get_card("chain_lightning"))
	deck.append(card_db.get_card("chain_lightning"))
	deck.append(card_db.get_card("arcane_intellect"))
	deck.append(card_db.get_card("arcane_intellect"))
	deck.append(card_db.get_card("divination"))
	deck.append(card_db.get_card("counterspell"))
	deck.append(card_db.get_card("mana_shield"))
	deck.append(card_db.get_card("mana_shield"))
	deck.append(card_db.get_card("storm_surge"))

	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	return hero

func create_beast_tamer() -> Character:
	var hero = Character.new()
	hero.character_name = "Thorne, Beast Tamer"
	hero.description = "Primal warrior who channels nature's fury."
	hero.max_health = 120
	hero.starting_energy = 3

	var deck: Array[Card] = []
	deck.append(card_db.get_card("wild_strike"))
	deck.append(card_db.get_card("wild_strike"))
	deck.append(card_db.get_card("wild_strike"))
	deck.append(card_db.get_card("bear_claws"))
	deck.append(card_db.get_card("bear_claws"))
	deck.append(card_db.get_card("giant_growth"))
	deck.append(card_db.get_card("giant_growth"))
	deck.append(card_db.get_card("regrowth"))
	deck.append(card_db.get_card("regrowth"))
	deck.append(card_db.get_card("natures_lore"))
	deck.append(card_db.get_card("primal_rage"))
	deck.append(card_db.get_card("stampede"))
	deck.append(card_db.get_card("regenerate"))
	deck.append(card_db.get_card("regenerate"))

	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	return hero

func create_chrono_mage() -> Character:
	var hero = Character.new()
	hero.character_name = "Kairos, Chrono Mage"
	hero.description = "Time manipulator with unmatched card advantage."
	hero.max_health = 100
	hero.starting_energy = 3

	var deck: Array[Card] = []
	deck.append(card_db.get_card("temporal_bolt"))
	deck.append(card_db.get_card("temporal_bolt"))
	deck.append(card_db.get_card("temporal_bolt"))
	deck.append(card_db.get_card("blink"))
	deck.append(card_db.get_card("blink"))
	deck.append(card_db.get_card("rewind"))
	deck.append(card_db.get_card("rewind"))
	deck.append(card_db.get_card("haste"))
	deck.append(card_db.get_card("haste"))
	deck.append(card_db.get_card("slow"))
	deck.append(card_db.get_card("slow"))
	deck.append(card_db.get_card("time_warp"))
	deck.append(card_db.get_card("chrono_blast"))
	deck.append(card_db.get_card("moment_of_clarity"))

	hero.starting_deck = deck
	hero.reset_deck()  # Initialize deck now that starting_deck is populated
	return hero

func get_all_heroes() -> Array[Character]:
	var heroes: Array[Character] = []
	heroes.append(create_flame_wielder())
	heroes.append(create_life_weaver())
	heroes.append(create_shadow_assassin())
	heroes.append(create_storm_caller())
	heroes.append(create_beast_tamer())
	heroes.append(create_chrono_mage())
	return heroes
