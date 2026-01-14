extends SceneTree

## Run this script to export all hardcoded cards to CSV
## Usage: godot --headless --script scripts/tests/export_cards_to_csv.gd

func _init():
	print("=== Card Export Tool ===")

	# Create card database instance and populate it
	var card_db_script = load("res://scripts/card_database.gd")
	var card_db = card_db_script.new()

	# Disable CSV loading during export (we want hardcoded cards only)
	card_db.csv_path = ""
	card_db._create_all_cards()

	print("Loaded " + str(card_db.all_cards.size()) + " cards from hardcoded definitions")

	# Export to CSV
	var output_path = "res://csvs/cards.csv"
	var success = CSVCardLoader.export_cards_to_csv(card_db.all_cards, output_path)

	if success:
		print("SUCCESS: Exported cards to " + output_path)
	else:
		print("FAILED: Could not export cards")

	quit()
