class_name RewardChoice
extends Resource

## Generic reward type that can represent cards, heals, buffs, gold, relics, etc.
## Used by RewardManager to display and apply rewards in a modular way.

enum ChoiceType {
	CARD,         ## Add a card to player's deck
	HEAL,         ## Restore HP
	BUFF,         ## Permanent stat increase
	GOLD,         ## Currency (for future shop system)
	RELIC,        ## Permanent passive effect (for future)
	REMOVE_CARD   ## Remove a card from deck (for future)
}

@export var choice_type: ChoiceType = ChoiceType.CARD
@export var display_name: String = ""
@export var description: String = ""

# Type-specific data
@export var card_data: Card = null          ## If choice_type == CARD
@export var heal_amount: int = 0            ## If choice_type == HEAL
@export var buff_type: String = ""          ## If choice_type == BUFF (e.g., "max_stamina", "max_health")
@export var buff_amount: int = 0            ## Amount to increase buff by
@export var gold_amount: int = 0            ## If choice_type == GOLD
@export var relic_id: String = ""           ## If choice_type == RELIC

## Apply this reward to the specified player
func apply_to_player(player: Character):
	match choice_type:
		ChoiceType.CARD:
			if card_data:
				player.add_card_to_deck(card_data)
				player.starting_deck.append(card_data.duplicate())

		ChoiceType.HEAL:
			player.heal(heal_amount)

		ChoiceType.BUFF:
			if buff_type == "revive_all":
				_revive_all_teammates(player)
			else:
				_apply_buff(player, buff_type, buff_amount)

		ChoiceType.GOLD:
			# Future: player.gold += gold_amount
			pass

		ChoiceType.RELIC:
			if relic_id != "":
				player.add_relic(relic_id)
				RelicRegistry.apply_on_pickup(player, relic_id)
				print("[REWARD] ", player.character_name, " acquired relic: ", RelicRegistry.get_display_name(relic_id))

		ChoiceType.REMOVE_CARD:
			# Future feature
			pass

## Revive all dead teammates at full HP
func _revive_all_teammates(reviver: Character):
	var game_manager = Engine.get_main_loop().root.get_node_or_null("/root/GameManager")
	if not game_manager:
		push_warning("[RewardChoice] Could not find GameManager for revive")
		return

	for teammate in game_manager.players:
		if not teammate.is_alive():
			teammate.current_health = teammate.max_health
			print("[REVIVE] ", reviver.character_name, " revived ", teammate.character_name, " to full HP (", teammate.max_health, ")")

## Apply a buff to the player (permanent stat increase)
func _apply_buff(player: Character, type: String, amount: int):
	match type:
		"max_stamina":
			player.max_stamina += amount
			player.current_stamina = player.max_stamina
		"max_health":
			player.max_health += amount
			player.current_health = min(player.current_health + amount, player.max_health)
		"strength":
			player.strength += amount
		"armor":
			player.armor += amount
		_:
			push_warning("[RewardChoice] Unknown buff type: %s" % type)

## Serialize for network transmission
func serialize() -> Dictionary:
	return {
		"choice_type": choice_type,
		"display_name": display_name,
		"description": description,
		"card_data": card_data.serialize() if card_data else null,
		"heal_amount": heal_amount,
		"buff_type": buff_type,
		"buff_amount": buff_amount,
		"gold_amount": gold_amount,
		"relic_id": relic_id
	}

## Deserialize from network data
static func deserialize(data: Dictionary) -> RewardChoice:
	var choice = RewardChoice.new()
	choice.choice_type = data.choice_type
	choice.display_name = data.display_name
	choice.description = data.description
	choice.heal_amount = data.heal_amount
	choice.buff_type = data.buff_type
	choice.buff_amount = data.buff_amount
	choice.gold_amount = data.gold_amount
	choice.relic_id = data.get("relic_id", "")

	if data.card_data:
		choice.card_data = Card.deserialize(data.card_data)

	return choice
