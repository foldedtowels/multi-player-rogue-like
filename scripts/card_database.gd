extends Node
## Central repository for all player and boss cards
##
## This autoload singleton creates and manages all cards in the game.
## Cards are defined using the create_card() factory function with parameters:
##
## create_card(name, description, card_type, target_type, cost, dmg, heal, shield, draw)
##
## PARAMETER GUIDE:
## - name: Display name shown on the card
## - description: Flavor text explaining what the card does
## - card_type: ATTACK | SPELL | BUFF | DEBUFF | HEAL
## - target_type: SELF | SINGLE_ALLY | SINGLE_ENEMY | RANDOM_ENEMY | ALL_ALLIES | ALL_ENEMIES
## - cost: Energy required to play the card (0-5 typically)
## - dmg: Base damage dealt to target(s) (0 if non-damaging)
## - heal: HP restored to target (0 if no healing, negative to damage self)
## - shield: Temporary HP gained (0 if no shield)
## - draw: Number of cards drawn when played (0 if no card draw)
##
## EXAMPLE:
## create_card("Lightning Bolt", "Fast damage", ATTACK, SINGLE_ENEMY, 1, 12, 0, 0, 0)
##                                                                     ↑  ↑↑  ↑   ↑  ↑
##                                                                  cost |  |   |   |
##                                                                    damage |   |   |
##                                                                       healing |   |
##                                                                          shield   |
##                                                                              card draw
##
## ADVANCED PROPERTIES (set after create_card):
## - aoe_damage: true = hits all targets instead of just one
## - apply_burn: Apply burn status (damage per turn)
## - apply_poison: Apply poison status (damage per turn, decays)
## - apply_strength: Increase attack damage
## - apply_vulnerable: Increase damage taken
## - apply_weakness: Reduce damage dealt
## - apply_armor: Permanent damage reduction
## - lifesteal: true = heal for damage dealt
## - piercing: true = ignores shield and armor

var all_cards = {}

func _ready():
	_create_all_cards()

func _create_all_cards():
	# === FLAME WIELDER CARDS (Red - Burn/Aggro) ===
	all_cards["lightning_bolt"] = create_card(
		"Lightning Bolt",
		"The classic red spell. Fast and deadly.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 12, 0, 0, 0
	)

	all_cards["shock"] = create_card(
		"Shock",
		"A quick jolt of energy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 8, 0, 0, 0
	)

	all_cards["fireball"] = create_card(
		"Fireball",
		"Explosive power that hits everything.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 15, 0, 0, 0
	)
	all_cards["fireball"].aoe_damage = true

	all_cards["flame_slash"] = create_card(
		"Flame Slash",
		"Searing blade of fire.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 10, 0, 0, 0
	)

	all_cards["burning_hands"] = create_card(
		"Burning Hands",
		"Touch of flame that keeps burning.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 8, 0, 0, 0
	)
	all_cards["burning_hands"].apply_burn = 5

	all_cards["volcanic_strike"] = create_card(
		"Volcanic Strike",
		"Mighty blow that pierces defenses.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 16, 0, 0, 0
	)
	all_cards["volcanic_strike"].piercing = true

	all_cards["flame_barrier"] = create_card(
		"Flame Barrier",
		"Protective wall of fire.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 8, 0
	)

	all_cards["ignite"] = create_card(
		"Ignite",
		"Set the world ablaze.",
		Card.CardType.DEBUFF,
		Card.TargetType.ALL_ENEMIES,
		2, 0, 0, 0, 0
	)
	all_cards["ignite"].apply_burn = 3

	# === LIFE WEAVER CARDS (White/Green - Healing/Buffs) ===
	all_cards["healing_salve"] = create_card(
		"Healing Salve",
		"Gentle restoration of life.",
		Card.CardType.HEAL,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 15, 0, 0
	)

	all_cards["divine_light"] = create_card(
		"Divine Light",
		"Radiant healing for all allies.",
		Card.CardType.HEAL,
		Card.TargetType.ALL_ALLIES,
		2, 0, 10, 0, 0
	)

	all_cards["holy_strike"] = create_card(
		"Holy Strike",
		"Righteous punishment.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 10, 0, 0, 0
	)

	all_cards["guardian_shield"] = create_card(
		"Guardian Shield",
		"Protection from harm.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 12, 0
	)

	all_cards["pacify"] = create_card(
		"Pacify",
		"Weaken the enemy's resolve.",
		Card.CardType.DEBUFF,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0
	)
	all_cards["pacify"].apply_weakness = 2

	all_cards["blessing"] = create_card(
		"Blessing",
		"Empower an ally with divine strength.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 0, 0
	)
	all_cards["blessing"].apply_strength = 3

	all_cards["mass_heal"] = create_card(
		"Mass Heal",
		"Powerful restoration for the party.",
		Card.CardType.HEAL,
		Card.TargetType.ALL_ALLIES,
		3, 0, 20, 0, 0
	)

	all_cards["smite"] = create_card(
		"Smite",
		"Holy wrath pierces all defenses.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 14, 0, 0, 0
	)
	all_cards["smite"].piercing = true

	# === SHADOW ASSASSIN CARDS (Black - Removal/Drain) ===
	all_cards["doom_blade"] = create_card(
		"Doom Blade",
		"Strike from the shadows.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 18, 0, 0, 0
	)

	all_cards["drain_life"] = create_card(
		"Drain Life",
		"Steal vitality from your foe.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 12, 0, 0, 0
	)
	all_cards["drain_life"].lifesteal = true

	all_cards["poison_strike"] = create_card(
		"Poison Strike",
		"Venomous blade that lingers.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 6, 0, 0, 0
	)
	all_cards["poison_strike"].apply_poison = 4

	all_cards["shadow_step"] = create_card(
		"Shadow Step",
		"Strike twice from the darkness.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 7, 0, 0, 1
	)
	all_cards["shadow_step"].multi_hit = 2

	all_cards["dark_pact"] = create_card(
		"Dark Pact",
		"Sacrifice health for power.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, -5, 0, 2
	)
	all_cards["dark_pact"].apply_strength = 4

	all_cards["corrupt"] = create_card(
		"Corrupt",
		"Spread decay to all enemies.",
		Card.CardType.DEBUFF,
		Card.TargetType.ALL_ENEMIES,
		2, 0, 0, 0, 0
	)
	all_cards["corrupt"].apply_poison = 3

	all_cards["assassination"] = create_card(
		"Assassination",
		"Silent kill that bypasses armor.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 25, 0, 0, 0
	)
	all_cards["assassination"].piercing = true

	all_cards["vampiric_touch"] = create_card(
		"Vampiric Touch",
		"Drain life force continuously.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 10, 0, 0, 0
	)
	all_cards["vampiric_touch"].lifesteal = true
	all_cards["vampiric_touch"].apply_poison = 2

	# === STORM CALLER CARDS (Blue - Control/Draw) ===
	all_cards["counterspell"] = create_card(
		"Counterspell",
		"Shield yourself and draw insight.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 10, 1
	)

	all_cards["divination"] = create_card(
		"Divination",
		"Peer into the future.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		2, 0, 0, 0, 2
	)

	all_cards["lightning_strike"] = create_card(
		"Lightning Strike",
		"Call down the storm.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 11, 0, 0, 0
	)

	all_cards["frost_bolt"] = create_card(
		"Frost Bolt",
		"Freeze and weaken your enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 10, 0, 0, 0
	)
	all_cards["frost_bolt"].apply_vulnerable = 2

	all_cards["arcane_intellect"] = create_card(
		"Arcane Intellect",
		"Deep study yields knowledge.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		1, 0, 0, 0, 2
	)

	all_cards["chain_lightning"] = create_card(
		"Chain Lightning",
		"Electricity arcs between foes.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 8, 0, 0, 0
	)
	all_cards["chain_lightning"].multi_hit = 2

	all_cards["storm_surge"] = create_card(
		"Storm Surge",
		"Unleash the tempest.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 12, 0, 0, 0
	)
	all_cards["storm_surge"].aoe_damage = true

	all_cards["mana_shield"] = create_card(
		"Mana Shield",
		"Convert energy into protection.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 15, 0
	)

	# === BEAST TAMER CARDS (Green - Creatures/Growth) ===
	all_cards["giant_growth"] = create_card(
		"Giant Growth",
		"Empower yourself with primal strength.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	all_cards["giant_growth"].apply_strength = 4

	all_cards["wild_strike"] = create_card(
		"Wild Strike",
		"Savage, relentless attack.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 9, 0, 0, 0
	)

	all_cards["regrowth"] = create_card(
		"Regrowth",
		"Nature's healing embrace.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		1, 0, 12, 0, 0
	)

	all_cards["bear_claws"] = create_card(
		"Bear Claws",
		"Tear into your enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 14, 0, 0, 0
	)

	all_cards["natures_lore"] = create_card(
		"Nature's Lore",
		"Commune with the wild.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		1, 0, 0, 0, 1
	)
	all_cards["natures_lore"].apply_armor = 2

	all_cards["primal_rage"] = create_card(
		"Primal Rage",
		"Unleash the beast within.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 0, 0
	)
	all_cards["primal_rage"].apply_strength = 5
	all_cards["primal_rage"].apply_vulnerable = 1

	all_cards["stampede"] = create_card(
		"Stampede",
		"Overwhelming force crushes all.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 16, 0, 0, 0
	)
	all_cards["stampede"].aoe_damage = true

	all_cards["regenerate"] = create_card(
		"Regenerate",
		"Rapid cellular restoration.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		2, 0, 18, 0, 0
	)

	# === CHRONO MAGE CARDS (Blue/White - Tempo/Time) ===
	all_cards["time_warp"] = create_card(
		"Time Warp",
		"Bend time to your will.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		3, 0, 0, 0, 3
	)

	all_cards["blink"] = create_card(
		"Blink",
		"Phase out of danger.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 10, 1
	)

	all_cards["temporal_bolt"] = create_card(
		"Temporal Bolt",
		"Strike with the force of time.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 12, 0, 0, 0
	)

	all_cards["rewind"] = create_card(
		"Rewind",
		"Turn back the clock.",
		Card.CardType.HEAL,
		Card.TargetType.SINGLE_ALLY,
		2, 0, 14, 0, 1
	)

	all_cards["haste"] = create_card(
		"Haste",
		"Accelerate your actions.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 2
	)

	all_cards["slow"] = create_card(
		"Slow",
		"Reduce enemy efficiency.",
		Card.CardType.DEBUFF,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0
	)
	all_cards["slow"].apply_weakness = 3

	all_cards["chrono_blast"] = create_card(
		"Chrono Blast",
		"Temporal energy explosion.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 14, 0, 0, 0
	)
	all_cards["chrono_blast"].aoe_damage = true

	all_cards["moment_of_clarity"] = create_card(
		"Moment of Clarity",
		"Perfect insight and protection.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 12, 2
	)

## Factory function for creating cards with basic stats
##
## @param name: Card display name
## @param desc: Description text shown on card
## @param type: Card type (ATTACK, SPELL, BUFF, DEBUFF, HEAL)
## @param target: Who can be targeted (SELF, SINGLE_ENEMY, ALL_ENEMIES, etc.)
## @param cost: Energy required to play (0-5 typically)
## @param dmg: Base damage dealt (0 if no damage)
## @param heal: HP restored (0 if no healing, can be negative for self-harm)
## @param shield: Temporary HP gained (0 if no shield)
## @param draw: Cards drawn when played (0 if no card draw)
## @returns: New Card instance with properties set
##
## NOTE: For advanced effects (burn, poison, lifesteal, etc.), set properties
##       on the returned Card object after calling this function.
func create_card(name: String, desc: String, type: Card.CardType, target: Card.TargetType,
				 cost: int, dmg: int, heal: int, shield: int, draw: int) -> Card:
	var card = Card.new()
	card.card_name = name
	card.description = desc
	card.card_type = type
	card.target_type = target
	card.energy_cost = cost
	card.damage = dmg
	card.heal_amount = heal
	card.shield_amount = shield
	card.draw_cards = draw
	return card

func get_card(card_id: String) -> Card:
	if all_cards.has(card_id):
		return all_cards[card_id].duplicate()
	else:
		push_error("Card not found: " + card_id)
		return null

# === REWARD CARD POOLS ===

func create_reward_cards():
	# RARE CARDS (Powerful rewards for single player)
	all_cards["apocalypse"] = create_card(
		"Apocalypse",
		"Destroy everything. Deals massive damage to all enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		4, 30, 0, 0, 0
	)
	all_cards["apocalypse"].aoe_damage = true

	all_cards["divine_intervention"] = create_card(
		"Divine Intervention",
		"Fully heal and gain massive shield.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		3, 0, 50, 30, 0
	)

	all_cards["berserker_rage"] = create_card(
		"Berserker Rage",
		"Gain massive strength. Unleash fury!",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 0, 0
	)
	all_cards["berserker_rage"].apply_strength = 5

	all_cards["meteor_swarm"] = create_card(
		"Meteor Swarm",
		"Rain fire from the heavens! Multi-hit AoE.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 12, 0, 0, 0
	)
	all_cards["meteor_swarm"].multi_hit = 3
	all_cards["meteor_swarm"].aoe_damage = true

	all_cards["time_stop"] = create_card(
		"Time Stop",
		"Draw 5 cards instantly.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		2, 0, 0, 0, 5
	)

	all_cards["life_drain"] = create_card(
		"Life Drain",
		"Massive damage that heals you.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 25, 0, 0, 0
	)
	all_cards["life_drain"].lifesteal = true

	all_cards["annihilation"] = create_card(
		"Annihilation",
		"Pierce all defenses. Pure destruction.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 35, 0, 0, 0
	)
	all_cards["annihilation"].piercing = true

	all_cards["omnipotence"] = create_card(
		"Omnipotence",
		"Gain strength, armor, and draw cards.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		3, 0, 0, 15, 3
	)
	all_cards["omnipotence"].apply_strength = 3
	all_cards["omnipotence"].apply_armor = 3

	# COMMON CARDS (Decent rewards for all players)
	all_cards["steel_strike"] = create_card(
		"Steel Strike",
		"Solid attack with good damage.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 16, 0, 0, 0
	)

	all_cards["healing_potion"] = create_card(
		"Healing Potion",
		"Restore health quickly.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		1, 0, 15, 0, 0
	)

	all_cards["fortify"] = create_card(
		"Fortify",
		"Gain good shield.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 12, 0
	)

	all_cards["power_strike"] = create_card(
		"Power Strike",
		"Heavy single target damage.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 18, 0, 0, 0
	)

	all_cards["battle_focus"] = create_card(
		"Battle Focus",
		"Gain strength and draw a card.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 0, 1
	)
	all_cards["battle_focus"].apply_strength = 2

	all_cards["cleave"] = create_card(
		"Cleave",
		"Hit all enemies for decent damage.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		2, 10, 0, 0, 0
	)
	all_cards["cleave"].aoe_damage = true

	all_cards["rejuvenation"] = create_card(
		"Rejuvenation",
		"Heal and gain shield.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		2, 0, 12, 8, 0
	)

	all_cards["iron_will"] = create_card(
		"Iron Will",
		"Solid shield and armor.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 10, 0
	)
	all_cards["iron_will"].apply_armor = 2

	all_cards["quick_strike"] = create_card(
		"Quick Strike",
		"Fast, efficient damage.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 12, 0, 0, 0
	)

	all_cards["tactical_advantage"] = create_card(
		"Tactical Advantage",
		"Draw 2 cards.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		1, 0, 0, 0, 2
	)

func get_rare_cards() -> Array[Card]:
	create_reward_cards()
	var rare_pool: Array[Card] = []
	rare_pool.append(all_cards["apocalypse"].duplicate())
	rare_pool.append(all_cards["divine_intervention"].duplicate())
	rare_pool.append(all_cards["berserker_rage"].duplicate())
	rare_pool.append(all_cards["meteor_swarm"].duplicate())
	rare_pool.append(all_cards["time_stop"].duplicate())
	rare_pool.append(all_cards["life_drain"].duplicate())
	rare_pool.append(all_cards["annihilation"].duplicate())
	rare_pool.append(all_cards["omnipotence"].duplicate())
	return rare_pool

func get_common_cards() -> Array[Card]:
	create_reward_cards()
	var common_pool: Array[Card] = []
	common_pool.append(all_cards["steel_strike"].duplicate())
	common_pool.append(all_cards["healing_potion"].duplicate())
	common_pool.append(all_cards["fortify"].duplicate())
	common_pool.append(all_cards["power_strike"].duplicate())
	common_pool.append(all_cards["battle_focus"].duplicate())
	common_pool.append(all_cards["cleave"].duplicate())
	common_pool.append(all_cards["rejuvenation"].duplicate())
	common_pool.append(all_cards["iron_will"].duplicate())
	common_pool.append(all_cards["quick_strike"].duplicate())
	common_pool.append(all_cards["tactical_advantage"].duplicate())
	return common_pool
