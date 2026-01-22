extends Resource
class_name Character

# Audio signals - for AudioManager to connect to (COMMENTED OUT - not ready yet)
#signal damage_taken(amount: int, character: Character)
#signal healed(amount: int, character: Character)
#signal shield_gained(amount: int, character: Character)
#signal status_effect_applied(effect_name: String, amount: int, character: Character)

@export var character_name: String
@export var description: String
@export var max_health: int = 100
@export var starting_stamina: int = 3
@export var starting_aura: int = 0  # Enrique's second resource (0 for non-Enrique heroes)
@export var starting_deck: Array[Card] = []

# Hero template ID (e.g., "fabio", "flame_wielder") - used for reward deck lookups
var hero_id: String = ""

# Character stats
var current_health: int
var current_stamina: int
var max_stamina: int
var current_aura: int = 0  # Enrique's second resource (runtime)
var max_aura: int = 0  # Max aura capacity
var shield: int = 0
var damage_taken_this_turn: int = 0  # Tracks damage taken this turn (for Jumping Strike condition)

# ============================================
# RELIC SYSTEM
# ============================================
# Relics provide persistent passive bonuses that trigger at various points.
# Stored as dictionary: relic_id -> bool (true if owned)
var relics: Dictionary = {}
var cards_played_this_turn: int = 0  # For Rage Meter relic tracking
var relic_uses_remaining: Dictionary = {}  # For ACTIVE_USE relics: {"revive_relic": 1, ...}

## Check if character has a relic
func has_relic(relic_id: String) -> bool:
	return relics.get(relic_id, false)

## Add a relic to character
func add_relic(relic_id: String) -> void:
	relics[relic_id] = true
	# Initialize uses for active relics
	if RelicRegistry.is_active_use_relic(relic_id):
		relic_uses_remaining[relic_id] = RelicRegistry.get_uses_per_fight(relic_id)

## Remove a relic from character
func remove_relic(relic_id: String) -> void:
	relics.erase(relic_id)
	relic_uses_remaining.erase(relic_id)

## Reset active relic uses at fight start
func reset_relic_uses() -> void:
	relic_uses_remaining.clear()
	for relic_id in relics.keys():
		if relics[relic_id] and RelicRegistry.is_active_use_relic(relic_id):
			relic_uses_remaining[relic_id] = RelicRegistry.get_uses_per_fight(relic_id)
			print("[RELIC] Reset ", relic_id, " uses to ", relic_uses_remaining[relic_id], " for ", character_name)

## Check if an active relic can be used
func can_use_relic(relic_id: String) -> bool:
	if not has_relic(relic_id):
		return false
	if not RelicRegistry.is_active_use_relic(relic_id):
		return false
	return relic_uses_remaining.get(relic_id, 0) > 0

## Use an active relic (decrement uses)
func use_relic(relic_id: String) -> void:
	if relic_uses_remaining.has(relic_id) and relic_uses_remaining[relic_id] > 0:
		relic_uses_remaining[relic_id] -= 1
		print("[RELIC] ", character_name, " used ", relic_id, " (", relic_uses_remaining[relic_id], " uses remaining)")

## Get active-use relics that this character owns
func get_active_use_relics() -> Array[String]:
	var active_relics: Array[String] = []
	for relic_id in relics.keys():
		if relics[relic_id] and RelicRegistry.is_active_use_relic(relic_id):
			active_relics.append(relic_id)
	return active_relics

# ============================================
# MODULAR STATUS EFFECT SYSTEM
# ============================================
# All status effects stored in a single dictionary for easy iteration and extension.
# Individual properties below provide backward compatibility with existing code.
#
# ADDING A NEW STATUS EFFECT:
# If you add a new effect to StatusEffectRegistry, you MUST also add a property
# accessor here following this pattern:
#
#   var new_effect: int:
#       get: return get_effect_amount("new_effect")
#       set(value): set_effect_amount("new_effect", value)
#
# This allows code to use character.new_effect = 5 instead of
# character.set_effect_amount("new_effect", 5), maintaining backward compatibility.
#
# See StatusEffectRegistry.gd for the full checklist of files to update.
# ============================================
var status_effects: Dictionary = {}

# Backward-compatible property accessors (read/write to status_effects dictionary)
var poison: int:
	get: return get_effect_amount("poison")
	set(value): set_effect_amount("poison", value)
var burn: int:
	get: return get_effect_amount("burn")
	set(value): set_effect_amount("burn", value)
var strength: int:
	get: return get_effect_amount("strength")
	set(value):
		var old = get_effect_amount("strength")
		set_effect_amount("strength", value)
		if old != value:
			print("[STRENGTH DEBUG] ", character_name, ": ", old, " -> ", value)
			print_stack()  # Shows call stack to identify caller
var vulnerable: int:
	get: return get_effect_amount("vulnerable")
	set(value): set_effect_amount("vulnerable", value)
var weakness: int:
	get: return get_effect_amount("weakness")
	set(value): set_effect_amount("weakness", value)
var armor: int:
	get: return get_effect_amount("armor")
	set(value): set_effect_amount("armor", value)
var rested: int:
	get: return get_effect_amount("rested")
	set(value): set_effect_amount("rested", value)
var invigorated: int:
	get: return get_effect_amount("invigorated")
	set(value): set_effect_amount("invigorated", value)
var damage_plus: int:
	get: return get_effect_amount("damage_plus")
	set(value): set_effect_amount("damage_plus", value)
var fatigued: int:
	get: return get_effect_amount("fatigued")
	set(value): set_effect_amount("fatigued", value)
var exhausted: int:
	get: return get_effect_amount("exhausted")
	set(value): set_effect_amount("exhausted", value)
var decay: int:
	get: return get_effect_amount("decay")
	set(value): set_effect_amount("decay", value)
var hinder: int:
	get: return get_effect_amount("hinder")
	set(value): set_effect_amount("hinder", value)
var scared: int:
	get: return get_effect_amount("scared")
	set(value): set_effect_amount("scared", value)

# Kevin's Alchemy status effects
var wet: int:
	get: return get_effect_amount("wet")
	set(value): set_effect_amount("wet", value)
var ring_of_fire: int:
	get: return get_effect_amount("ring_of_fire")
	set(value): set_effect_amount("ring_of_fire", value)

# Enemy-applied status effects
var venom: int:
	get: return get_effect_amount("venom")
	set(value): set_effect_amount("venom", value)
var bleed: int:
	get: return get_effect_amount("bleed")
	set(value): set_effect_amount("bleed", value)
var feeble: int:
	get: return get_effect_amount("feeble")
	set(value): set_effect_amount("feeble", value)

# Enrique's status effects
var played_twice: int:
	get: return get_effect_amount("played_twice")
	set(value): set_effect_amount("played_twice", value)
var invincible: int:
	get: return get_effect_amount("invincible")
	set(value): set_effect_amount("invincible", value)

# New character debuffs
var burden: int:
	get: return get_effect_amount("burden")
	set(value): set_effect_amount("burden", value)
var dissolve: int:
	get: return get_effect_amount("dissolve")
	set(value): set_effect_amount("dissolve", value)

# Mute's Doll debuffs (Boss 4)
var doll_dissolve: int:
	get: return get_effect_amount("doll_dissolve")
	set(value): set_effect_amount("doll_dissolve", value)
var doll_suffering: int:
	get: return get_effect_amount("doll_suffering")
	set(value): set_effect_amount("doll_suffering", value)
var doll_burden: int:
	get: return get_effect_amount("doll_burden")
	set(value): set_effect_amount("doll_burden", value)

# Passive ability system
var passive_ability_id: String = ""
var passive_ability_used_this_turn: bool = false

# Deck management
var deck: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []
var exhaust_pile: Array[Card] = []

# Special deck system (for minions/bosses with chance-based extra cards)
var special_deck: Array[Card] = []
var special_chance: float = 0.0  # Probability of playing a special card each turn
var main_deck_cards_per_turn: int = -1  # -1 = unlimited (greedy), positive = limit per turn
var extra_main_deck_chance: float = 0.0  # Chance for 2nd main deck card
var special_deck_double_chance: float = 0.0  # Chance for 2nd special card

# Card retention system (e.g., Dig a Hole)
# Maps card_name -> expires_after_round (the round number when retention expires)
var retained_cards: Dictionary = {}

# Satchel system (Kevin's Alchemy)
# Static pool of Alc cards - no shuffling/cycling, cards return here after use
var satchel: Array[Card] = []

# Character role
enum CharacterRole { PLAYER, MINION, BOSS }
var character_role: CharacterRole = CharacterRole.PLAYER
var is_minion: bool = false

# Mid-combat summoning system
var was_summoned: bool = false  # True if this minion was summoned during combat
var minion_id: String = ""      # ID for network sync and reference

# Network ownership
var network_owner_id: int = -1  # Which peer owns this character

func _init():
	current_health = max_health
	max_stamina = starting_stamina
	current_stamina = max_stamina
	max_aura = starting_aura
	current_aura = 0  # Aura starts at 0, gained at start of turn via passive
	# Don't call reset_deck() here - starting_deck isn't populated yet!
	# HeroDatabase/BossDatabase will call reset_deck() after setting starting_deck

func reset_deck():
	deck = starting_deck.duplicate()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	# Shuffling handled by game_manager when needed
	deck.shuffle()

func draw_card() -> Card:
	# Check hand size limit against game constant
	if hand.size() >= GameConstants.MAX_HAND_SIZE:
		print("[Character] Hand full, cannot draw more cards")
		return null

	if deck.is_empty():
		if discard_pile.is_empty():
			return null
		deck = discard_pile.duplicate()
		discard_pile.clear()
		# Shuffling handled by built-in shuffle (deterministic via seed)
		deck.shuffle()

	var card = deck.pop_front()
	hand.append(card)
	return card

func draw_cards(amount: int):
	for i in amount:
		var drawn = draw_card()

func discard_card(card: Card):
	# Find card by name since it might be a different instance
	var card_to_remove: Card = null
	for c in hand:
		if c.card_name == card.card_name:
			card_to_remove = c
			break

	if card_to_remove:
		hand.erase(card_to_remove)
		discard_pile.append(card_to_remove)
	else:
		push_warning("[DISCARD] Card not found in hand: " + card.card_name)

func exhaust_card(card: Card):
	# Find card by name since it might be a different instance
	var card_to_remove: Card = null
	for c in hand:
		if c.card_name == card.card_name:
			card_to_remove = c
			break

	if card_to_remove:
		hand.erase(card_to_remove)
		exhaust_pile.append(card_to_remove)
	else:
		push_warning("[EXHAUST] Card not found in hand: " + card.card_name)

## Calculate effective stamina cost for a card, including relic reductions
func get_effective_stamina_cost(card: Card) -> int:
	var base_cost = card.stamina_cost
	var reduction = RelicRegistry.get_cost_reduction(self, card)
	return max(0, base_cost - reduction)

func play_card(card: Card):
	var effective_cost = get_effective_stamina_cost(card)
	# Use effective cost for can_afford check
	var can_play = current_stamina >= effective_cost
	if card.aura_cost_all and current_aura < 1:
		can_play = false
	elif card.aura_cost > 0 and current_aura < card.aura_cost:
		can_play = false
	if can_play:
		current_stamina -= effective_cost

		# Deduct aura cost
		if card.aura_cost_all:
			# "All aura" cards spend everything
			var aura_spent = current_aura
			current_aura = 0
			print("[AURA] ", character_name, " spent ALL aura (", aura_spent, ") for ", card.card_name)
		elif card.aura_cost > 0:
			current_aura -= card.aura_cost
			print("[AURA] ", character_name, " spent ", card.aura_cost, " aura for ", card.card_name, " (now ", current_aura, "/", max_aura, ")")

		# Dissolve: Take X damage per card played (piercing)
		if dissolve > 0:
			print("[DISSOLVE] ", character_name, " takes ", dissolve, " piercing damage for playing ", card.card_name)
			take_damage(dissolve, true)  # Piercing damage

		# Doll: Dissolve: Take 1 damage per stack per card played (piercing)
		if doll_dissolve > 0:
			print("[DOLL:DISSOLVE] ", character_name, " takes ", doll_dissolve, " piercing damage for playing ", card.card_name)
			take_damage(doll_dissolve, true)  # Piercing damage

		# CRITICAL FIX: Find and remove card by name, not by reference
		# When card is deserialized from RPC, it's a new instance and hand.erase() won't find it
		var card_to_remove: Card = null
		for c in hand:
			if c.card_name == card.card_name:
				card_to_remove = c
				break

		if card_to_remove:
			hand.erase(card_to_remove)
			# Alc cards return to satchel instead of discard pile
			if card_to_remove.is_alc:
				satchel.append(card_to_remove)
				print("[CHARACTER] ", character_name, " returned Alc '", card_to_remove.card_name, "' to satchel")
			# Exhaust cards are removed from game (go to exhaust pile)
			elif card_to_remove.exhausts:
				exhaust_pile.append(card_to_remove)
				print("[CHARACTER] ", character_name, " exhausted '", card_to_remove.card_name, "' (removed from game)")
			else:
				discard_pile.append(card_to_remove)
		else:
			# Card not in hand - might already have been removed or is invalid
			print("[CHARACTER] Warning: Tried to play card '", card.card_name, "' but it's not in hand")

		return true
	return false

func take_damage(amount: int, is_piercing: bool = false):
	# Validate input
	if amount < 0:
		push_warning("Negative damage attempted: " + str(amount))
		return 0

	# Invincible prevents all damage
	if invincible > 0:
		print("[INVINCIBLE] ", character_name, " took no damage (Invincible)")
		return 0

	var actual_damage = amount

	# Apply vulnerable status effect damage multiplier
	if vulnerable > 0:
		actual_damage = int(actual_damage * GameConstants.VULNERABLE_DAMAGE_MULTIPLIER)

	if not is_piercing and shield > 0:
		var shield_absorbed = min(shield, actual_damage)
		shield -= shield_absorbed
		actual_damage -= shield_absorbed

	if armor > 0 and not is_piercing:
		actual_damage = max(0, actual_damage - armor)

	current_health -= actual_damage
	current_health = max(0, current_health)  # Prevent negative health

	# Track damage for conditional effects (e.g., Jumping Strike)
	damage_taken_this_turn += actual_damage

	# Emit signal for audio hooks (COMMENTED OUT - not ready yet)
	#if actual_damage > 0:
	#	damage_taken.emit(actual_damage, self)

	return actual_damage

func heal(amount: int, decay_already_applied: bool = false):
	if amount < 0:
		push_warning("Negative heal attempted: " + str(amount))
		return
	var actual_heal = amount
	# Decay reduces healing received by 5 per stack (unless already handled by caller)
	if not decay_already_applied and decay > 0:
		var decay_reduction = decay * 5
		actual_heal = max(0, amount - decay_reduction)
		print("[HEAL] ", character_name, " has ", decay, " decay - healing reduced: ", amount, " -> ", actual_heal)
	var old_health = current_health
	current_health = min(current_health + actual_heal, max_health)
	var amount_healed = current_health - old_health
	print("[HEAL] ", character_name, " healed: ", old_health, " -> ", current_health, " (+", amount_healed, ")")

	# Emit signal for audio hooks (COMMENTED OUT - not ready yet)
	#if amount_healed > 0:
	#	healed.emit(amount_healed, self)

func gain_shield(amount: int):
	if amount < 0:
		push_warning("Negative shield attempted: " + str(amount))
		return
	var old_shield = shield
	shield += amount
	# Cap shield to prevent infinite stacking exploits
	shield = min(shield, GameConstants.SHIELD_CAP)
	var actual_gain = shield - old_shield

	# Emit signal for audio hooks (COMMENTED OUT - not ready yet)
	#if actual_gain > 0:
	#	shield_gained.emit(actual_gain, self)

func start_turn():
	current_stamina = max_stamina

	# Apply Enrique's passive aura gain (gain 1 aura at start of turn)
	if passive_ability_id == "enrique_aura_generation" and max_aura > 0:
		current_aura += 1
		print("[AURA] ", character_name, " gained 1 Aura from passive (now ", current_aura, ")")

	# Reset shield at start of turn (not end) - shield lasts until your next turn
	shield = 0

	# Reset passive ability usage
	passive_ability_used_this_turn = false

	# Reset damage tracking for new turn (used by Jumping Strike condition)
	damage_taken_this_turn = 0

	# Reset cards played counter for relic tracking (Rage Meter)
	cards_played_this_turn = 0

	apply_status_effects()

	# Apply TURN_START relic effects (stamina, extra draws)
	var game_manager = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if game_manager == null:
		# Try getting from scene tree (for when not registered as singleton)
		var tree = Engine.get_main_loop()
		if tree and tree.root:
			game_manager = tree.root.get_node_or_null("/root/GameManager")
	var round_num = 1
	if game_manager:
		round_num = game_manager.round_number
	RelicRegistry.apply_turn_start(self, round_num)

	# Draw cards (reduced by Doll: Burden)
	var cards_to_draw = 5
	print("[TURN START] ", character_name, " doll_burden=", doll_burden, " status_effects=", status_effects)
	if doll_burden > 0:
		cards_to_draw = max(0, 5 - doll_burden)
		print("[DOLL:BURDEN] ", character_name, " draws ", cards_to_draw, " cards (reduced by ", doll_burden, ")")
	draw_cards(cards_to_draw)

func add_stamina(amount: int):
	current_stamina += amount
	current_stamina = clamp(current_stamina, 0, max_stamina + 5)  # Allow slight overflow

func add_aura(amount: int):
	current_aura += amount
	current_aura = max(current_aura, 0)  # Just prevent negative
	print("[AURA] ", character_name, " gained ", amount, " Aura (now ", current_aura, ")")

func end_turn(current_round: int = 0):
	# Check for expired card retentions
	var expired_retentions: Array[String] = []
	for card_name in retained_cards.keys():
		if retained_cards[card_name] <= current_round:
			expired_retentions.append(card_name)
			print("[RETAIN] ", character_name, "'s retention on ", card_name, " expired")
	for card_name in expired_retentions:
		retained_cards.erase(card_name)

	# Discard hand, but skip retained cards and return Alcs to satchel
	var cards_to_discard: Array[Card] = []
	var alcs_to_return: Array[Card] = []
	for card in hand:
		if retained_cards.has(card.card_name):
			print("[RETAIN] ", character_name, " keeps ", card.card_name, " in hand (retained until round ", retained_cards[card.card_name], ")")
		elif card.is_alc:
			alcs_to_return.append(card)
		else:
			cards_to_discard.append(card)

	# Return Alc cards to satchel
	for card in alcs_to_return:
		return_to_satchel(card)

	for card in cards_to_discard:
		discard_card(card)

	# NOTE: Shield is NOT reset here - it persists until start of next turn
	# (Reset moved to start_turn())

	# Process end-of-turn effects using registry
	process_turn_end_effects()

	# Apply TURN_END relic effects (Radiating Apple damage, Shining Feather shield)
	RelicRegistry.apply_turn_end(self)

func apply_status_effects():
	# Process start-of-turn effects using registry
	process_turn_start_effects()

## Registry-based turn start processing
func process_turn_start_effects():
	# Check for venom threshold trigger (before other processing)
	var venom_amount = get_effect_amount("venom")
	if venom_amount >= 3:
		take_damage(20, true)  # 20 piercing damage
		set_effect_amount("venom", 0)
		print("[VENOM] ", character_name, " triggered at 3 stacks, took 20 damage")

	# Get a copy of keys since we might modify the dictionary
	var effect_names = status_effects.keys().duplicate()

	for effect_name in effect_names:
		var amount = status_effects.get(effect_name, 0)
		if amount <= 0:
			continue

		var effect_data = StatusEffectRegistry.get_effect_data(effect_name)

		# DOT effects: deal damage equal to stacks
		if effect_data.get("deals_damage", false):
			take_damage(amount, effect_data.get("piercing", false))

			# Apply per-turn decay for DOT effects (e.g., poison decays, burn doesn't)
			if effect_data.get("decay") == StatusEffectRegistry.DecayType.PER_TURN:
				var decay_amount = effect_data.get("decay_amount", 1)
				set_effect_amount(effect_name, amount - decay_amount)

		# Stamina modifiers at turn start (rested, fatigued)
		if effect_data.get("apply_at") == "turn_start" and effect_data.has("stamina_modifier"):
			var base_modifier = effect_data.stamina_modifier
			# Check if modifier is per stack or flat
			var stamina_change: int
			if effect_data.get("per_stack", true):  # Default to per-stack for backward compat
				stamina_change = amount * base_modifier
			else:
				stamina_change = base_modifier  # Flat modifier regardless of stacks

			if stamina_change > 0:
				add_stamina(stamina_change)
			else:
				current_stamina = max(0, current_stamina + stamina_change)

		# Remove AFTER_TURN_START effects after they've applied (e.g., rested grants stamina then is removed)
		if effect_data.get("decay") == StatusEffectRegistry.DecayType.AFTER_TURN_START:
			clear_effect(effect_name)

## Registry-based turn end processing
func process_turn_end_effects():
	# Burden: Take 5 damage per stack at end of turn (piercing)
	if burden > 0:
		var burden_damage = burden * 5
		print("[BURDEN] ", character_name, " takes ", burden_damage, " damage from ", burden, " burden stacks")
		take_damage(burden_damage, true)  # Piercing damage

	# Doll: Suffering: Take 5 damage per stack at end of turn (piercing)
	if doll_suffering > 0:
		var suffering_damage = doll_suffering * 5
		print("[DOLL:SUFFERING] ", character_name, " takes ", suffering_damage, " damage from ", doll_suffering, " doll_suffering stacks")
		take_damage(suffering_damage, true)  # Piercing damage

	var effects_to_remove: Array[String] = []

	for effect_name in status_effects.keys():
		var amount = status_effects.get(effect_name, 0)
		if amount <= 0:
			continue

		var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
		var decay_type = effect_data.get("decay", StatusEffectRegistry.DecayType.NONE)

		match decay_type:
			StatusEffectRegistry.DecayType.PER_TURN:
				# Decrement by decay amount (but not DOT effects - those decay at turn start)
				if not effect_data.get("deals_damage", false):
					var decay_amount = effect_data.get("decay_amount", 1)
					var new_amount = amount - decay_amount
					if effect_name == "exhausted":
						print("[EXHAUST] Decay: ", character_name, " ", amount, " -> ", new_amount)
					if new_amount <= 0:
						effects_to_remove.append(effect_name)
					else:
						status_effects[effect_name] = new_amount
			StatusEffectRegistry.DecayType.END_OF_TURN:
				# Remove completely at end of turn
				effects_to_remove.append(effect_name)
			StatusEffectRegistry.DecayType.AFTER_TURN_START:
				# Persists through turn end - will be removed at next turn start after applying
				pass
			# NONE: permanent effects, don't decay

	for effect_name in effects_to_remove:
		status_effects.erase(effect_name)

## Decay END_OF_ENEMY_TURN effects (called after all enemies have attacked)
func decay_end_of_enemy_turn_effects():
	var effects_to_remove: Array[String] = []

	for effect_name in status_effects.keys():
		var amount = status_effects.get(effect_name, 0)
		if amount <= 0:
			continue

		var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
		var decay_type = effect_data.get("decay", StatusEffectRegistry.DecayType.NONE)

		if decay_type == StatusEffectRegistry.DecayType.END_OF_ENEMY_TURN:
			effects_to_remove.append(effect_name)
			print("[STATUS] ", character_name, " ", effect_data.get("display_name", effect_name), " expired after enemy turn")

	for effect_name in effects_to_remove:
		status_effects.erase(effect_name)

func is_alive() -> bool:
	return current_health > 0


## Revive a dead character with specified health (default: 50% max HP)
func revive(health_amount: int = -1) -> void:
	if health_amount < 0:
		health_amount = max_health / 2  # Default: 50% HP
	current_health = health_amount
	print("[REVIVE] ", character_name, " revived with ", health_amount, " HP")


# ============================================
# STATUS EFFECT HELPER METHODS
# ============================================

## Get the current amount of a status effect (0 if not present)
func get_effect_amount(effect_name: String) -> int:
	return status_effects.get(effect_name, 0)

## Set the amount of a status effect (removes if <= 0)
func set_effect_amount(effect_name: String, value: int):
	if value <= 0:
		status_effects.erase(effect_name)
	else:
		status_effects[effect_name] = value

## Get total debuff stacks on this character (for bonus damage calculations)
func get_total_debuff_stacks() -> int:
	var total = 0
	for effect_name in status_effects.keys():
		if StatusEffectRegistry.is_debuff(effect_name):
			total += status_effects[effect_name]
	return total

## Apply (add) an amount of status effect, handling immediate grants
func apply_effect(effect_name: String, amount: int):
	if amount <= 0:
		return

	var current = get_effect_amount(effect_name)
	set_effect_amount(effect_name, current + amount)

	# Emit signal for audio hooks (COMMENTED OUT - not ready yet)
	#status_effect_applied.emit(effect_name, amount, self)

	# Handle immediate grants (e.g., invigorated -> damage_plus)
	var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
	if effect_data.has("grants_on_apply"):
		var grant = effect_data.grants_on_apply
		apply_effect(grant.effect, int(amount * grant.multiplier))

## Check if character has a status effect
func has_effect(effect_name: String) -> bool:
	return get_effect_amount(effect_name) > 0

## Remove a status effect completely
func clear_effect(effect_name: String):
	status_effects.erase(effect_name)

## Clear all status effects
func clear_all_effects():
	status_effects.clear()

## Get status display string for UI
func get_status_display_string(use_short_names: bool = true) -> String:
	return StatusEffectRegistry.get_status_display_string(status_effects, use_short_names)

## Get status display array for detailed UI rendering
func get_status_display_array() -> Array[Dictionary]:
	return StatusEffectRegistry.get_status_display_array(status_effects)


# ============================================
# CARD RETENTION METHODS
# ============================================

## Retain a card in hand until the end of the specified round
func retain_card(card_name: String, expires_after_round: int):
	retained_cards[card_name] = expires_after_round
	print("[RETAIN] ", character_name, " retains ", card_name, " until end of round ", expires_after_round)

## Check if a card is currently retained
func is_card_retained(card_name: String) -> bool:
	return retained_cards.has(card_name)

## Clear retention for a card (e.g., when played)
func clear_card_retention(card_name: String):
	retained_cards.erase(card_name)

## Clear all card retentions
func clear_all_retentions():
	retained_cards.clear()


# ============================================
# SATCHEL METHODS (Kevin's Alchemy)
# ============================================

## Add a card to the satchel
func add_to_satchel(card: Card):
	satchel.append(card)
	print("[SATCHEL] ", character_name, " added ", card.card_name, " to satchel")

## Remove a card from the satchel (when brewing)
func remove_from_satchel(card: Card):
	# Find by name since it might be a different instance
	for i in range(satchel.size()):
		if satchel[i].card_name == card.card_name:
			satchel.remove_at(i)
			print("[SATCHEL] ", character_name, " removed ", card.card_name, " from satchel")
			return
	push_warning("[SATCHEL] Card not found in satchel: " + card.card_name)

## Return an Alc card to the satchel (after being played or at end of turn)
func return_to_satchel(card: Card):
	hand.erase(card)
	satchel.append(card)
	print("[SATCHEL] ", character_name, " returned ", card.card_name, " to satchel")

## Get all Alc cards currently in the satchel
func get_satchel_cards() -> Array[Card]:
	return satchel

## Check if satchel has any cards
func has_satchel_cards() -> bool:
	return satchel.size() > 0


func reset_debuffs():
	# Reset all debuffs between bosses (keep buffs like strength/armor)
	poison = 0
	burn = 0
	vulnerable = 0
	weakness = 0
	exhausted = 0
	decay = 0
	hinder = 0
	wet = 0
	venom = 0
	# Mute's Doll debuffs
	doll_dissolve = 0
	doll_suffering = 0
	doll_burden = 0

func add_card_to_deck(card: Card):
	deck.append(card)

func duplicate_character() -> Character:
	var new_char = Character.new()
	new_char.hero_id = hero_id  # Copy hero template ID for reward deck lookups
	new_char.character_name = character_name
	new_char.description = description
	new_char.max_health = max_health
	new_char.current_health = max_health  # Initialize current_health to match max_health
	new_char.starting_stamina = starting_stamina
	new_char.max_stamina = starting_stamina
	new_char.current_stamina = starting_stamina

	# Copy aura properties (Enrique's second resource)
	new_char.starting_aura = starting_aura
	new_char.max_aura = starting_aura
	new_char.current_aura = 0  # Aura starts at 0, gained from passive

	# Copy passive ability
	new_char.passive_ability_id = passive_ability_id

	# Copy relics (persistent passive bonuses)
	new_char.relics = relics.duplicate()

	# Copy enemy-specific properties
	new_char.special_chance = special_chance
	new_char.main_deck_cards_per_turn = main_deck_cards_per_turn
	new_char.extra_main_deck_chance = extra_main_deck_chance
	new_char.special_deck_double_chance = special_deck_double_chance

	# Deep copy special deck
	var special_copy: Array[Card] = []
	for card in special_deck:
		special_copy.append(card.duplicate())
	new_char.special_deck = special_copy

	# Deep copy satchel (Kevin's Alchemy)
	var satchel_copy: Array[Card] = []
	for card in satchel:
		satchel_copy.append(card.duplicate())
	new_char.satchel = satchel_copy

	# Deep copy the starting deck
	var deck_copy: Array[Card] = []
	for card in starting_deck:
		deck_copy.append(card.duplicate())
	new_char.starting_deck = deck_copy
	new_char.reset_deck()  # Initialize deck now that starting_deck is populated

	return new_char

# Network synchronization - data only, RPCs handled by GameManager
func get_state_dict() -> Dictionary:
	return {
		"hero_id": hero_id,  # Hero template ID for reward deck lookups
		"character_name": character_name,
		"current_health": current_health,
		"max_health": max_health,
		"current_stamina": current_stamina,
		"max_stamina": max_stamina,
		"current_aura": current_aura,
		"max_aura": max_aura,
		"shield": shield,
		"damage_taken_this_turn": damage_taken_this_turn,
		"cards_played_this_turn": cards_played_this_turn,
		# NEW: Send all effects as single dictionary
		"status_effects": status_effects.duplicate(),
		# Relics (persistent passive bonuses)
		"relics": relics.duplicate(),
		"relic_uses_remaining": relic_uses_remaining.duplicate(),
		# BACKWARD COMPAT: Also send individual fields for older clients
		"poison": poison,
		"burn": burn,
		"strength": strength,
		"vulnerable": vulnerable,
		"weakness": weakness,
		"armor": armor,
		"rested": rested,
		"invigorated": invigorated,
		"damage_plus": damage_plus,
		"fatigued": fatigued,
		"exhausted": exhausted,
		"decay": decay,
		"passive_ability_id": passive_ability_id,
		"passive_ability_used_this_turn": passive_ability_used_this_turn,
		"retained_cards": retained_cards.duplicate(),
		"satchel": _serialize_satchel(),
		"was_summoned": was_summoned,
		"minion_id": minion_id
	}

func _serialize_satchel() -> Array[Dictionary]:
	var satchel_data: Array[Dictionary] = []
	for card in satchel:
		satchel_data.append(card.serialize())
	return satchel_data

func apply_state_dict(state: Dictionary):
	hero_id = state.get("hero_id", "")  # Load hero template ID
	character_name = state.character_name
	current_health = state.current_health
	max_health = state.max_health
	current_stamina = state.current_stamina
	max_stamina = state.max_stamina
	current_aura = state.get("current_aura", 0)
	max_aura = state.get("max_aura", 0)
	shield = state.shield
	damage_taken_this_turn = state.get("damage_taken_this_turn", 0)
	cards_played_this_turn = state.get("cards_played_this_turn", 0)

	# Load relics
	relics = state.get("relics", {}).duplicate()
	relic_uses_remaining = state.get("relic_uses_remaining", {}).duplicate()

	# NEW: Load from status_effects dictionary if present
	if state.has("status_effects"):
		status_effects = state.status_effects.duplicate()
	else:
		# BACKWARD COMPAT: Load from individual fields
		status_effects.clear()
		set_effect_amount("poison", state.get("poison", 0))
		set_effect_amount("burn", state.get("burn", 0))
		set_effect_amount("strength", state.get("strength", 0))
		set_effect_amount("vulnerable", state.get("vulnerable", 0))
		set_effect_amount("weakness", state.get("weakness", 0))
		set_effect_amount("armor", state.get("armor", 0))
		set_effect_amount("rested", state.get("rested", 0))
		set_effect_amount("invigorated", state.get("invigorated", 0))
		set_effect_amount("damage_plus", state.get("damage_plus", 0))
		set_effect_amount("fatigued", state.get("fatigued", 0))
		set_effect_amount("exhausted", state.get("exhausted", 0))
		set_effect_amount("decay", state.get("decay", 0))

	passive_ability_id = state.get("passive_ability_id", "")
	passive_ability_used_this_turn = state.get("passive_ability_used_this_turn", false)
	retained_cards = state.get("retained_cards", {}).duplicate()
	_deserialize_satchel(state.get("satchel", []))
	was_summoned = state.get("was_summoned", false)
	minion_id = state.get("minion_id", "")

func _deserialize_satchel(satchel_data: Array):
	satchel.clear()
	for card_dict in satchel_data:
		satchel.append(Card.deserialize(card_dict))

func get_hand_dict() -> Array[Dictionary]:
	var hand_data: Array[Dictionary] = []
	for card in hand:
		hand_data.append(card.serialize())
	return hand_data

func apply_hand_dict(hand_data: Array):
	hand.clear()
	for card_dict in hand_data:
		hand.append(Card.deserialize(card_dict))
