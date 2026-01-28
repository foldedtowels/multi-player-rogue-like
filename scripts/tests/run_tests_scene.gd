extends Node
## Scene-based CLI Test Runner - Comprehensive test suite for Deck Masters
##
## Usage:
##   godot --headless scenes/test_runner.tscn
##   godot --headless scenes/test_runner.tscn -- --suite=cards/fabio
##   godot --headless scenes/test_runner.tscn -- --format=json
##   godot --headless scenes/test_runner.tscn -- --verbose --fail-fast

# Preload test framework
const TestBase = preload("res://scripts/tests/framework/test_base.gd")
const TestAssertions = preload("res://scripts/tests/framework/test_assertions.gd")
const TestFixtures = preload("res://scripts/tests/framework/test_fixtures.gd")
const TestReporter = preload("res://scripts/tests/framework/test_reporter.gd")

# Preload card test suites
const FabioCardsTest = preload("res://scripts/tests/suites/cards/fabio_cards_test.gd")
const KevinCardsTest = preload("res://scripts/tests/suites/cards/kevin_cards_test.gd")
const EnriqueCardsTest = preload("res://scripts/tests/suites/cards/enrique_cards_test.gd")
const SharedCardsTest = preload("res://scripts/tests/suites/cards/shared_cards_test.gd")
const RewardCardsTest = preload("res://scripts/tests/suites/cards/reward_cards_test.gd")
const EnemyCardsTest = preload("res://scripts/tests/suites/cards/enemy_cards_test.gd")

# Preload relic test suites
const UniversalRelicsTest = preload("res://scripts/tests/suites/relics/universal_relics_test.gd")
const FabioRelicsTest = preload("res://scripts/tests/suites/relics/fabio_relics_test.gd")
const KevinRelicsTest = preload("res://scripts/tests/suites/relics/kevin_relics_test.gd")
const EnriqueRelicsTest = preload("res://scripts/tests/suites/relics/enrique_relics_test.gd")

# Preload status effect test suites
const DotEffectsTest = preload("res://scripts/tests/suites/status_effects/dot_effects_test.gd")
const BuffEffectsTest = preload("res://scripts/tests/suites/status_effects/buff_effects_test.gd")
const DebuffEffectsTest = preload("res://scripts/tests/suites/status_effects/debuff_effects_test.gd")
const SpecialEffectsTest = preload("res://scripts/tests/suites/status_effects/special_effects_test.gd")

# Preload interaction test suites
const CardRelicTest = preload("res://scripts/tests/suites/interactions/card_relic_test.gd")
const CardStatusTest = preload("res://scripts/tests/suites/interactions/card_status_test.gd")
const EdgeCasesTest = preload("res://scripts/tests/suites/interactions/edge_cases_test.gd")

# Preload multiplayer test suites
const StateSyncTest = preload("res://scripts/tests/suites/multiplayer/state_sync_test.gd")
const ProtectionTest = preload("res://scripts/tests/suites/multiplayer/protection_test.gd")

# CLI options
var suite_filter: String = "all"
var test_filter: String = ""
var output_format: String = "console"
var verbose: bool = false
var fail_fast: bool = false

# Autoload references
var game_manager: Node
var card_db: Node
var boss_db: Node

# All test suites
var suites: Array = []


func _ready():
	# Parse CLI arguments
	_parse_arguments()

	# Print header
	_print_header()

	# Get autoloads
	game_manager = get_node_or_null("/root/GameManager")
	card_db = get_node_or_null("/root/CardDatabase")
	boss_db = get_node_or_null("/root/BossDatabase")

	if not game_manager or not card_db:
		print("[ERROR] Autoloads not found!")
		print("  GameManager: ", game_manager != null)
		print("  CardDatabase: ", card_db != null)
		print("  BossDatabase: ", boss_db != null)
		get_tree().quit(1)
		return

	# Load and run test suites
	_load_suites()
	_run_all_suites()

	# Report results
	var summary = TestReporter.get_summary(suites)
	TestReporter.report(suites, _get_format_enum())

	# Exit with appropriate code
	var exit_code = 0 if summary.failed == 0 else 1
	print("\n[TEST RUNNER] Exiting with code: ", exit_code)
	get_tree().quit(exit_code)


func _parse_arguments():
	var args = OS.get_cmdline_args()

	for arg in args:
		if arg.begins_with("--suite="):
			suite_filter = arg.substr(8)
		elif arg.begins_with("--test="):
			test_filter = arg.substr(7)
		elif arg.begins_with("--format="):
			output_format = arg.substr(9)
		elif arg == "--verbose":
			verbose = true
		elif arg == "--fail-fast":
			fail_fast = true
		elif arg == "--help":
			_print_help()
			get_tree().quit(0)


func _print_help():
	print("""
Deck Masters Test Runner

Usage:
  godot --headless scenes/test_runner.tscn [options]

Options:
  --suite=NAME      Run specific suite (e.g., cards/fabio, relics, status_effects)
  --test=NAME       Run specific test by name
  --format=FORMAT   Output format: console (default), json, xml
  --verbose         Show all test output
  --fail-fast       Stop on first failure
  --help            Show this help

Suites:
  all               Run all tests (default)
  cards             All card tests
  cards/fabio       Fabio card tests
  cards/kevin       Kevin card tests
  cards/enrique     Enrique card tests
  cards/shared      Shared card tests
  cards/reward      Reward card tests
  cards/enemy       Enemy/boss card tests
  relics            All relic tests
  status_effects    All status effect tests
  interactions      All interaction tests
  multiplayer       All multiplayer tests

Examples:
  # Run all tests
  godot --headless scenes/test_runner.tscn

  # Run only Fabio card tests
  godot --headless scenes/test_runner.tscn -- --suite=cards/fabio

  # Run with JSON output for CI
  godot --headless scenes/test_runner.tscn -- --format=json

  # Run with verbose output and stop on first failure
  godot --headless scenes/test_runner.tscn -- --verbose --fail-fast
""")


func _print_header():
	print("\n" + "=".repeat(60))
	print("     DECK MASTERS - COMPREHENSIVE TEST SUITE")
	print("=".repeat(60))
	print("  Suite filter: ", suite_filter)
	if test_filter:
		print("  Test filter: ", test_filter)
	print("  Format: ", output_format)
	print("  Verbose: ", verbose)
	print("  Fail-fast: ", fail_fast)
	print("=".repeat(60))


func _load_suites():
	suites.clear()

	var should_run = func(category: String) -> bool:
		if suite_filter == "all":
			return true
		if suite_filter == category:
			return true
		if suite_filter.begins_with(category + "/"):
			return true
		if category.begins_with(suite_filter):
			return true
		return false

	# Card suites
	if should_run.call("cards"):
		if suite_filter == "all" or suite_filter == "cards" or suite_filter == "cards/fabio":
			suites.append(FabioCardsTest.new(game_manager, card_db))
		if suite_filter == "all" or suite_filter == "cards" or suite_filter == "cards/kevin":
			suites.append(KevinCardsTest.new(game_manager, card_db))
		if suite_filter == "all" or suite_filter == "cards" or suite_filter == "cards/enrique":
			suites.append(EnriqueCardsTest.new(game_manager, card_db))
		if suite_filter == "all" or suite_filter == "cards" or suite_filter == "cards/shared":
			suites.append(SharedCardsTest.new(game_manager, card_db))
		if suite_filter == "all" or suite_filter == "cards" or suite_filter == "cards/reward":
			suites.append(RewardCardsTest.new(game_manager, card_db))
		if suite_filter == "all" or suite_filter == "cards" or suite_filter == "cards/enemy":
			suites.append(EnemyCardsTest.new(game_manager, card_db, boss_db))

	# Relic suites
	if should_run.call("relics"):
		suites.append(UniversalRelicsTest.new(game_manager, card_db))
		suites.append(FabioRelicsTest.new(game_manager, card_db))
		suites.append(KevinRelicsTest.new(game_manager, card_db))
		suites.append(EnriqueRelicsTest.new(game_manager, card_db))

	# Status effect suites
	if should_run.call("status_effects"):
		suites.append(DotEffectsTest.new(game_manager, card_db))
		suites.append(BuffEffectsTest.new(game_manager, card_db))
		suites.append(DebuffEffectsTest.new(game_manager, card_db))
		suites.append(SpecialEffectsTest.new(game_manager, card_db))

	# Interaction suites
	if should_run.call("interactions"):
		suites.append(CardRelicTest.new(game_manager, card_db))
		suites.append(CardStatusTest.new(game_manager, card_db))
		suites.append(EdgeCasesTest.new(game_manager, card_db))

	# Multiplayer suites
	if should_run.call("multiplayer"):
		suites.append(StateSyncTest.new(game_manager, card_db))
		suites.append(ProtectionTest.new(game_manager, card_db))

	print("\n[TEST RUNNER] Loaded ", suites.size(), " test suites")


func _run_all_suites():
	for suite in suites:
		suite.verbose = verbose
		suite.fail_fast = fail_fast
		suite.run_all()


func _get_format_enum() -> int:
	match output_format:
		"json":
			return TestReporter.Format.JSON
		"xml":
			return TestReporter.Format.XML
		_:
			return TestReporter.Format.CONSOLE
