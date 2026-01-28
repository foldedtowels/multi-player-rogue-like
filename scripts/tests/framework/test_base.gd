class_name TestBase
extends RefCounted
## Base class for all test suites
## Provides test discovery, execution, and assertion handling

const TestAssertions = preload("res://scripts/tests/framework/test_assertions.gd")
const TestFixtures = preload("res://scripts/tests/framework/test_fixtures.gd")

# Test result structure: {name, passed, message, duration_ms, error}
var results: Array[Dictionary] = []
var current_test: String = ""
var suite_name: String = "Unnamed Suite"
var verbose: bool = false
var fail_fast: bool = false
var _failed: bool = false
var _start_time: int = 0

# Autoload references - set by subclasses in _init
var game_manager: Node
var card_db: Node
var boss_db: Node


func _init():
	pass


## Override in subclasses to set up suite-level state
func before_all() -> void:
	pass


## Override in subclasses to tear down suite-level state
func after_all() -> void:
	pass


## Override in subclasses to set up per-test state
func before_each() -> void:
	pass


## Override in subclasses to tear down per-test state
func after_each() -> void:
	pass


## Run all tests in this suite (methods starting with _test_)
func run_all() -> Array[Dictionary]:
	results.clear()
	_failed = false

	print("\n[SUITE] %s" % suite_name)
	before_all()

	var methods = _get_test_methods()
	for method_name in methods:
		if fail_fast and _failed:
			_skip_test(method_name, "Skipped due to fail-fast")
			continue

		run_test(method_name)

	after_all()
	return results


## Run a specific test by method name
func run_test(method_name: String) -> Dictionary:
	current_test = method_name
	_start_time = Time.get_ticks_msec()

	before_each()

	var result = {
		"name": method_name,
		"suite": suite_name,
		"passed": true,
		"message": "",
		"duration_ms": 0,
		"assertions": []
	}

	# Call the test method
	if has_method(method_name):
		call(method_name)
	else:
		result.passed = false
		result.message = "Method not found: %s" % method_name

	result.duration_ms = Time.get_ticks_msec() - _start_time

	# Check if any assertions failed
	for assertion in result.assertions:
		if not assertion.passed:
			result.passed = false
			result.message = assertion.message
			break

	after_each()

	# Record result
	if result.passed:
		_print_pass(method_name, result.duration_ms)
	else:
		_print_fail(method_name, result.message)
		_failed = true

	results.append(result)
	return result


## Get all test method names (methods starting with _test_)
func _get_test_methods() -> Array[String]:
	var methods: Array[String] = []
	var method_list = get_method_list()

	for method in method_list:
		var name = method.name
		if name.begins_with("_test_"):
			methods.append(name)

	methods.sort()
	return methods


## Skip a test
func _skip_test(method_name: String, reason: String) -> void:
	results.append({
		"name": method_name,
		"suite": suite_name,
		"passed": true,  # Skipped tests count as passed
		"skipped": true,
		"message": reason,
		"duration_ms": 0,
		"assertions": []
	})
	print("  SKIP: %s - %s" % [method_name, reason])


# ============================================
# ASSERTION METHODS
# ============================================
# These wrap TestAssertions and record results

func assert_eq(actual, expected, msg: String = "") -> bool:
	var result = TestAssertions.eq(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_ne(actual, expected, msg: String = "") -> bool:
	var result = TestAssertions.ne(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_gt(actual: float, expected: float, msg: String = "") -> bool:
	var result = TestAssertions.gt(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_gte(actual: float, expected: float, msg: String = "") -> bool:
	var result = TestAssertions.gte(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_lt(actual: float, expected: float, msg: String = "") -> bool:
	var result = TestAssertions.lt(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_lte(actual: float, expected: float, msg: String = "") -> bool:
	var result = TestAssertions.lte(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_true(condition: bool, msg: String = "") -> bool:
	var result = TestAssertions.is_true(condition, msg)
	_record_assertion(result)
	return result.passed


func assert_false(condition: bool, msg: String = "") -> bool:
	var result = TestAssertions.is_false(condition, msg)
	_record_assertion(result)
	return result.passed


func assert_null(value, msg: String = "") -> bool:
	var result = TestAssertions.is_null(value, msg)
	_record_assertion(result)
	return result.passed


func assert_not_null(value, msg: String = "") -> bool:
	var result = TestAssertions.not_null(value, msg)
	_record_assertion(result)
	return result.passed


func assert_contains(array: Array, item, msg: String = "") -> bool:
	var result = TestAssertions.contains(array, item, msg)
	_record_assertion(result)
	return result.passed


func assert_not_contains(array: Array, item, msg: String = "") -> bool:
	var result = TestAssertions.not_contains(array, item, msg)
	_record_assertion(result)
	return result.passed


func assert_has_key(dict: Dictionary, key, msg: String = "") -> bool:
	var result = TestAssertions.has_key(dict, key, msg)
	_record_assertion(result)
	return result.passed


func assert_in_range(value: float, min_val: float, max_val: float, msg: String = "") -> bool:
	var result = TestAssertions.in_range(value, min_val, max_val, msg)
	_record_assertion(result)
	return result.passed


func assert_array_eq(actual: Array, expected: Array, msg: String = "") -> bool:
	var result = TestAssertions.array_eq(actual, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_array_size(array: Array, expected_size: int, msg: String = "") -> bool:
	var result = TestAssertions.array_size(array, expected_size, msg)
	_record_assertion(result)
	return result.passed


# Game-specific assertions
func assert_health(char, hp: int, msg: String = "") -> bool:
	var result = TestAssertions.health_is(char, hp, msg)
	_record_assertion(result)
	return result.passed


func assert_health_between(char, min_hp: int, max_hp: int, msg: String = "") -> bool:
	var result = TestAssertions.health_between(char, min_hp, max_hp, msg)
	_record_assertion(result)
	return result.passed


func assert_shield(char, amount: int, msg: String = "") -> bool:
	var result = TestAssertions.shield_is(char, amount, msg)
	_record_assertion(result)
	return result.passed


func assert_stamina(char, amount: int, msg: String = "") -> bool:
	var result = TestAssertions.stamina_is(char, amount, msg)
	_record_assertion(result)
	return result.passed


func assert_aura(char, amount: int, msg: String = "") -> bool:
	var result = TestAssertions.aura_is(char, amount, msg)
	_record_assertion(result)
	return result.passed


func assert_buff(char, buff_name: String, stacks: int = -1, msg: String = "") -> bool:
	var result = TestAssertions.has_buff(char, buff_name, stacks, msg)
	_record_assertion(result)
	return result.passed


func assert_debuff(char, debuff_name: String, stacks: int = -1, msg: String = "") -> bool:
	var result = TestAssertions.has_debuff(char, debuff_name, stacks, msg)
	_record_assertion(result)
	return result.passed


func assert_no_buff(char, buff_name: String, msg: String = "") -> bool:
	var result = TestAssertions.no_buff(char, buff_name, msg)
	_record_assertion(result)
	return result.passed


func assert_no_debuff(char, debuff_name: String, msg: String = "") -> bool:
	var result = TestAssertions.no_debuff(char, debuff_name, msg)
	_record_assertion(result)
	return result.passed


func assert_alive(char, msg: String = "") -> bool:
	var result = TestAssertions.is_alive(char, msg)
	_record_assertion(result)
	return result.passed


func assert_dead(char, msg: String = "") -> bool:
	var result = TestAssertions.is_dead(char, msg)
	_record_assertion(result)
	return result.passed


func assert_wounded(char, msg: String = "") -> bool:
	var result = TestAssertions.is_wounded(char, msg)
	_record_assertion(result)
	return result.passed


func assert_has_relic(char, relic_id: String, msg: String = "") -> bool:
	var result = TestAssertions.has_relic(char, relic_id, msg)
	_record_assertion(result)
	return result.passed


func assert_hand_size(char, expected: int, msg: String = "") -> bool:
	var result = TestAssertions.hand_size(char, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_deck_size(char, expected: int, msg: String = "") -> bool:
	var result = TestAssertions.deck_size(char, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_card_cost(card, expected: int, msg: String = "") -> bool:
	var result = TestAssertions.card_cost(card, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_card_damage(card, expected: int, msg: String = "") -> bool:
	var result = TestAssertions.card_damage(card, expected, msg)
	_record_assertion(result)
	return result.passed


func assert_card_type(card, expected_type, msg: String = "") -> bool:
	var result = TestAssertions.card_type_is(card, expected_type, msg)
	_record_assertion(result)
	return result.passed


func assert_card_property(card, property: String, expected_value = null, msg: String = "") -> bool:
	var result = TestAssertions.card_has_property(card, property, expected_value, msg)
	_record_assertion(result)
	return result.passed


# ============================================
# INTERNAL HELPERS
# ============================================

func _record_assertion(result: Dictionary) -> void:
	# Find current test result and add assertion
	if results.size() > 0:
		var current = results[-1]
		if current.name == current_test:
			current.assertions.append(result)
			return

	# If no current test, this is a direct assertion
	if not result.passed:
		print("  FAIL: %s" % result.message)


func _print_pass(test_name: String, duration_ms: int) -> void:
	if verbose:
		print("  PASS: %s (%dms)" % [test_name, duration_ms])
	else:
		print("  PASS: %s" % test_name)


func _print_fail(test_name: String, message: String) -> void:
	print("  FAIL: %s" % test_name)
	print("        %s" % message)


# ============================================
# UTILITY METHODS
# ============================================

## Get passed test count
func get_passed_count() -> int:
	return results.filter(func(r): return r.passed).size()


## Get failed test count
func get_failed_count() -> int:
	return results.filter(func(r): return not r.passed).size()


## Get skipped test count
func get_skipped_count() -> int:
	return results.filter(func(r): return r.get("skipped", false)).size()


## Get total test count
func get_total_count() -> int:
	return results.size()


## Get total duration in ms
func get_total_duration() -> int:
	var total = 0
	for r in results:
		total += r.duration_ms
	return total
