extends SceneTree
## Command-line test runner - runs all card tests and exits

func _init():
	# Wait for autoloads to initialize
	await process_frame
	await process_frame

	print("\n[TEST RUNNER] Starting card tests...\n")

	# Get autoloads
	var game_manager = root.get_node_or_null("/root/GameManager")
	var card_db = root.get_node_or_null("/root/CardDatabase")
	var boss_db = root.get_node_or_null("/root/BossDatabase")

	if not game_manager or not card_db or not boss_db:
		print("[TEST RUNNER] ERROR: Autoloads not found!")
		print("  GameManager: ", game_manager != null)
		print("  CardDatabase: ", card_db != null)
		print("  BossDatabase: ", boss_db != null)
		quit(1)
		return

	# Create and run test runner
	var runner = CardTestRunner.new()
	root.add_child(runner)

	var result = runner.run_all_tests()

	# Exit with appropriate code
	var exit_code = 0 if result.passed == result.total else 1
	print("\n[TEST RUNNER] Exiting with code: ", exit_code)
	quit(exit_code)
