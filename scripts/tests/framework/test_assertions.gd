class_name TestAssertions
## Centralized assertion library for all test suites
## Provides consistent assertion methods with detailed failure messages

## Result dictionary structure for all assertions
## {"passed": bool, "message": String, "expected": Variant, "actual": Variant}

static func eq(actual, expected, msg: String = "") -> Dictionary:
	var passed = actual == expected
	var message = msg if msg else "Expected equality"
	if not passed:
		message = "%s - Expected: %s, Actual: %s" % [message, str(expected), str(actual)]
	return {"passed": passed, "message": message, "expected": expected, "actual": actual}


static func ne(actual, expected, msg: String = "") -> Dictionary:
	var passed = actual != expected
	var message = msg if msg else "Expected inequality"
	if not passed:
		message = "%s - Values should not be equal: %s" % [message, str(actual)]
	return {"passed": passed, "message": message, "expected": "!= " + str(expected), "actual": actual}


static func gt(actual: float, expected: float, msg: String = "") -> Dictionary:
	var passed = actual > expected
	var message = msg if msg else "Expected greater than"
	if not passed:
		message = "%s - Expected %s > %s" % [message, str(actual), str(expected)]
	return {"passed": passed, "message": message, "expected": "> " + str(expected), "actual": actual}


static func gte(actual: float, expected: float, msg: String = "") -> Dictionary:
	var passed = actual >= expected
	var message = msg if msg else "Expected greater than or equal"
	if not passed:
		message = "%s - Expected %s >= %s" % [message, str(actual), str(expected)]
	return {"passed": passed, "message": message, "expected": ">= " + str(expected), "actual": actual}


static func lt(actual: float, expected: float, msg: String = "") -> Dictionary:
	var passed = actual < expected
	var message = msg if msg else "Expected less than"
	if not passed:
		message = "%s - Expected %s < %s" % [message, str(actual), str(expected)]
	return {"passed": passed, "message": message, "expected": "< " + str(expected), "actual": actual}


static func lte(actual: float, expected: float, msg: String = "") -> Dictionary:
	var passed = actual <= expected
	var message = msg if msg else "Expected less than or equal"
	if not passed:
		message = "%s - Expected %s <= %s" % [message, str(actual), str(expected)]
	return {"passed": passed, "message": message, "expected": "<= " + str(expected), "actual": actual}


static func is_true(condition: bool, msg: String = "") -> Dictionary:
	var message = msg if msg else "Expected true"
	if not condition:
		message = "%s - Got false" % message
	return {"passed": condition, "message": message, "expected": true, "actual": condition}


static func is_false(condition: bool, msg: String = "") -> Dictionary:
	var passed = not condition
	var message = msg if msg else "Expected false"
	if not passed:
		message = "%s - Got true" % message
	return {"passed": passed, "message": message, "expected": false, "actual": condition}


static func is_null(value, msg: String = "") -> Dictionary:
	var passed = value == null
	var message = msg if msg else "Expected null"
	if not passed:
		message = "%s - Got: %s" % [message, str(value)]
	return {"passed": passed, "message": message, "expected": null, "actual": value}


static func not_null(value, msg: String = "") -> Dictionary:
	var passed = value != null
	var message = msg if msg else "Expected not null"
	if not passed:
		message = "%s - Got null" % message
	return {"passed": passed, "message": message, "expected": "!= null", "actual": value}


static func contains(array: Array, item, msg: String = "") -> Dictionary:
	var passed = item in array
	var message = msg if msg else "Expected array to contain item"
	if not passed:
		message = "%s - Item %s not found in array" % [message, str(item)]
	return {"passed": passed, "message": message, "expected": "contains " + str(item), "actual": array}


static func not_contains(array: Array, item, msg: String = "") -> Dictionary:
	var passed = item not in array
	var message = msg if msg else "Expected array to not contain item"
	if not passed:
		message = "%s - Item %s found in array" % [message, str(item)]
	return {"passed": passed, "message": message, "expected": "!contains " + str(item), "actual": array}


static func has_key(dict: Dictionary, key, msg: String = "") -> Dictionary:
	var passed = dict.has(key)
	var message = msg if msg else "Expected dictionary to have key"
	if not passed:
		message = "%s - Key '%s' not found" % [message, str(key)]
	return {"passed": passed, "message": message, "expected": "has key " + str(key), "actual": dict.keys()}


static func in_range(value: float, min_val: float, max_val: float, msg: String = "") -> Dictionary:
	var passed = value >= min_val and value <= max_val
	var message = msg if msg else "Expected value in range"
	if not passed:
		message = "%s - %s not in range [%s, %s]" % [message, str(value), str(min_val), str(max_val)]
	return {"passed": passed, "message": message, "expected": "[%s, %s]" % [min_val, max_val], "actual": value}


static func array_eq(actual: Array, expected: Array, msg: String = "") -> Dictionary:
	var passed = actual.size() == expected.size()
	if passed:
		for i in range(actual.size()):
			if actual[i] != expected[i]:
				passed = false
				break
	var message = msg if msg else "Expected arrays to be equal"
	if not passed:
		message = "%s - Arrays differ" % message
	return {"passed": passed, "message": message, "expected": expected, "actual": actual}


static func array_size(array: Array, expected_size: int, msg: String = "") -> Dictionary:
	var passed = array.size() == expected_size
	var message = msg if msg else "Expected array size"
	if not passed:
		message = "%s - Expected size %d, got %d" % [message, expected_size, array.size()]
	return {"passed": passed, "message": message, "expected": expected_size, "actual": array.size()}


# ============================================
# GAME-SPECIFIC ASSERTIONS
# ============================================

static func health_is(char, hp: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s health check" % char.character_name
	return eq(char.current_health, hp, message)


static func health_between(char, min_hp: int, max_hp: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s health in range" % char.character_name
	return in_range(char.current_health, min_hp, max_hp, message)


static func shield_is(char, amount: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s shield check" % char.character_name
	return eq(char.shield, amount, message)


static func stamina_is(char, amount: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s stamina check" % char.character_name
	return eq(char.current_stamina, amount, message)


static func aura_is(char, amount: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s aura check" % char.character_name
	return eq(char.current_aura, amount, message)


static func has_buff(char, buff_name: String, stacks: int = -1, msg: String = "") -> Dictionary:
	var actual_stacks = char.get_effect_amount(buff_name) if char.has_method("get_effect_amount") else char.get(buff_name)
	var message = msg if msg else "%s has buff %s" % [char.character_name, buff_name]

	if stacks == -1:
		# Just check if buff exists (> 0)
		var passed = actual_stacks > 0
		if not passed:
			message = "%s - Expected %s > 0, got %d" % [message, buff_name, actual_stacks]
		return {"passed": passed, "message": message, "expected": "> 0", "actual": actual_stacks}
	else:
		# Check exact stacks
		return eq(actual_stacks, stacks, message)


static func has_debuff(char, debuff_name: String, stacks: int = -1, msg: String = "") -> Dictionary:
	return has_buff(char, debuff_name, stacks, msg)  # Same logic for both


static func no_buff(char, buff_name: String, msg: String = "") -> Dictionary:
	var actual_stacks = char.get_effect_amount(buff_name) if char.has_method("get_effect_amount") else char.get(buff_name)
	var message = msg if msg else "%s has no buff %s" % [char.character_name, buff_name]
	var passed = actual_stacks == 0
	if not passed:
		message = "%s - Expected 0, got %d" % [message, actual_stacks]
	return {"passed": passed, "message": message, "expected": 0, "actual": actual_stacks}


static func no_debuff(char, debuff_name: String, msg: String = "") -> Dictionary:
	return no_buff(char, debuff_name, msg)


static func is_alive(char, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s is alive" % char.character_name
	var passed = char.is_alive() if char.has_method("is_alive") else char.current_health > 0
	if not passed:
		message = "%s - Character is dead (HP: %d)" % [message, char.current_health]
	return {"passed": passed, "message": message, "expected": "alive", "actual": "dead" if not passed else "alive"}


static func is_dead(char, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s is dead" % char.character_name
	var alive = char.is_alive() if char.has_method("is_alive") else char.current_health > 0
	var passed = not alive
	if not passed:
		message = "%s - Character is alive (HP: %d)" % [message, char.current_health]
	return {"passed": passed, "message": message, "expected": "dead", "actual": "alive" if alive else "dead"}


static func is_wounded(char, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s is wounded (<50%% HP)" % char.character_name
	var passed = char.current_health < (char.max_health / 2.0)
	if not passed:
		message = "%s - HP %d/%d (>= 50%%)" % [message, char.current_health, char.max_health]
	return {"passed": passed, "message": message, "expected": "< 50% HP", "actual": "%d/%d" % [char.current_health, char.max_health]}


static func has_relic(char, relic_id: String, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s has relic %s" % [char.character_name, relic_id]
	var passed = char.has_relic(relic_id) if char.has_method("has_relic") else char.relics.get(relic_id, false)
	if not passed:
		message = "%s - Relic not found" % message
	return {"passed": passed, "message": message, "expected": relic_id, "actual": char.relics.keys()}


static func hand_size(char, expected: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s hand size" % char.character_name
	return eq(char.hand.size(), expected, message)


static func deck_size(char, expected: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s deck size" % char.character_name
	return eq(char.deck.size(), expected, message)


static func discard_size(char, expected: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s discard pile size" % char.character_name
	return eq(char.discard_pile.size(), expected, message)


# Card property assertions
static func card_cost(card, expected: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s stamina cost" % card.card_name
	return eq(card.stamina_cost, expected, message)


static func card_damage(card, expected: int, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s damage" % card.card_name
	return eq(card.damage, expected, message)


static func card_type_is(card, expected_type, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s card type" % card.card_name
	return eq(card.card_type, expected_type, message)


static func card_has_property(card, property: String, expected_value = null, msg: String = "") -> Dictionary:
	var message = msg if msg else "%s has property %s" % [card.card_name, property]
	var actual = card.get(property)
	if expected_value == null:
		# Just check property exists and is truthy
		var passed = actual != null and actual != false and actual != 0
		if not passed:
			message = "%s - Property is falsy: %s" % [message, str(actual)]
		return {"passed": passed, "message": message, "expected": "truthy", "actual": actual}
	else:
		return eq(actual, expected_value, message)
