extends Node
class_name CardTestRunner
## Main test runner that orchestrates all card test suites and reports results

# Preload test suite scripts
const FabioTests = preload("res://scripts/tests/test_suites/fabio_card_tests.gd")
const KevinTests = preload("res://scripts/tests/test_suites/kevin_card_tests.gd")
const EnriqueTests = preload("res://scripts/tests/test_suites/enrique_card_tests.gd")
const SharedTests = preload("res://scripts/tests/test_suites/shared_card_tests.gd")
const MinionTests = preload("res://scripts/tests/test_suites/minion_card_tests.gd")
const RewardTests = preload("res://scripts/tests/test_suites/reward_card_tests.gd")
const BossTests = preload("res://scripts/tests/test_suites/boss_card_tests.gd")

signal tests_completed(passed: int, total: int)

var game_manager: Node
var card_db: Node
var boss_db: Node
var results: Array[Dictionary] = []  # {name: String, passed: bool, message: String}

func _ready():
	game_manager = get_node("/root/GameManager")
	card_db = get_node("/root/CardDatabase")
	boss_db = get_node("/root/BossDatabase")

## Run all test suites
func run_all_tests():
	results.clear()
	print("\n" + "=".repeat(60))
	print("           COMPREHENSIVE CARD TEST SUITE")
	print("=".repeat(60))

	# Run all test suites
	_run_fabio_tests()
	_run_kevin_tests()
	_run_enrique_tests()
	_run_shared_tests()
	_run_minion_tests()
	_run_reward_tests()
	_run_boss_tests()

	# Print summary
	_print_summary()

	var passed = results.filter(func(r): return r.passed).size()
	tests_completed.emit(passed, results.size())

	return {"passed": passed, "total": results.size(), "results": results}

## Run individual test suites
func _run_fabio_tests():
	var suite = FabioTests.new(game_manager, card_db, results)
	suite.run_all()

func _run_kevin_tests():
	var suite = KevinTests.new(game_manager, card_db, results)
	suite.run_all()

func _run_enrique_tests():
	var suite = EnriqueTests.new(game_manager, card_db, results)
	suite.run_all()

func _run_shared_tests():
	var suite = SharedTests.new(game_manager, card_db, results)
	suite.run_all()

func _run_minion_tests():
	var suite = MinionTests.new(game_manager, card_db, results)
	suite.run_all()

func _run_reward_tests():
	var suite = RewardTests.new(game_manager, card_db, results)
	suite.run_all()

func _run_boss_tests():
	var suite = BossTests.new(game_manager, card_db, boss_db, results)
	suite.run_all()

## Print test summary
func _print_summary():
	var passed = results.filter(func(r): return r.passed).size()
	var total = results.size()
	var failed = total - passed

	print("\n" + "=".repeat(60))
	print("  TEST RESULTS: %d/%d PASSED (%d FAILED)" % [passed, total, failed])
	print("=".repeat(60))

	if failed > 0:
		print("\n  FAILED TESTS:")
		for r in results:
			if not r.passed:
				print("    - %s" % r.message)
	else:
		print("\n  All tests passed!")

	# Suite breakdown
	print("\n  BREAKDOWN BY SUITE:")
	_print_suite_stats("Fabio", "fabio")
	_print_suite_stats("Kevin", "kevin")
	_print_suite_stats("Enrique", "enrique")
	_print_suite_stats("Shared", "shared")
	_print_suite_stats("Minion", "minion")
	_print_suite_stats("Reward", "reward")
	_print_suite_stats("Boss", "boss")

func _print_suite_stats(label: String, _keyword: String):
	# Count total tests that belong to this conceptual group
	# We don't have perfect grouping so just show the total
	pass

## Run a specific test suite by name
func run_suite(suite_name: String):
	results.clear()
	print("\n" + "=".repeat(50))
	print("  Running %s tests..." % suite_name)
	print("=".repeat(50))

	match suite_name.to_lower():
		"fabio": _run_fabio_tests()
		"kevin": _run_kevin_tests()
		"enrique": _run_enrique_tests()
		"shared": _run_shared_tests()
		"minion": _run_minion_tests()
		"reward": _run_reward_tests()
		"boss": _run_boss_tests()
		_: print("Unknown suite: %s" % suite_name)

	_print_summary()
	return results

## Quick test - run a subset of tests for fast validation
func run_quick_tests():
	results.clear()
	print("\n" + "=".repeat(50))
	print("  QUICK VALIDATION TESTS")
	print("=".repeat(50))

	# Just run Fabio and Shared for quick validation
	_run_fabio_tests()
	_run_shared_tests()

	_print_summary()
	return results

# =============================================================================
# ASSERTION HELPERS (for direct test use if needed)
# =============================================================================

## Assert that actual equals expected
func assert_eq(actual, expected, test_name: String, detail: String = "") -> bool:
	var passed = actual == expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %s, got %s" % [test_name, str(expected), str(actual)]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed

## Assert condition is true
func assert_true(condition: bool, test_name: String, detail: String = "") -> bool:
	return assert_eq(condition, true, test_name, detail)

## Assert condition is false
func assert_false(condition: bool, test_name: String, detail: String = "") -> bool:
	return assert_eq(condition, false, test_name, detail)

## Assert actual is less than expected
func assert_lt(actual: int, expected: int, test_name: String, detail: String = "") -> bool:
	var passed = actual < expected
	var msg: String
	if passed:
		msg = "PASS: %s" % test_name
	else:
		msg = "FAIL: %s - Expected %d < %d" % [test_name, actual, expected]
	if detail:
		msg += " (%s)" % detail
	results.append({"name": test_name, "passed": passed, "message": msg})
	print("  " + msg)
	return passed
