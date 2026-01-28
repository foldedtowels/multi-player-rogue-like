class_name TestReporter
## Output formatting for test results (console, JSON, XML)

enum Format { CONSOLE, JSON, XML }


## Main entry point - format and output results
static func report(suites: Array, format: Format = Format.CONSOLE) -> String:
	match format:
		Format.CONSOLE:
			return _format_console(suites)
		Format.JSON:
			return _format_json(suites)
		Format.XML:
			return _format_xml(suites)
	return ""


## Get summary statistics from suite results
static func get_summary(suites: Array) -> Dictionary:
	var passed = 0
	var failed = 0
	var skipped = 0
	var duration_ms = 0

	for suite in suites:
		for result in suite.results:
			if result.get("skipped", false):
				skipped += 1
			elif result.passed:
				passed += 1
			else:
				failed += 1
			duration_ms += result.duration_ms

	return {
		"passed": passed,
		"failed": failed,
		"skipped": skipped,
		"total": passed + failed + skipped,
		"duration_ms": duration_ms
	}


# ============================================
# CONSOLE FORMAT
# ============================================

static func _format_console(suites: Array) -> String:
	var output = ""
	var summary = get_summary(suites)

	output += "\n" + "=".repeat(60) + "\n"
	output += "  TEST RESULTS: %d/%d PASSED" % [summary.passed, summary.total]
	if summary.failed > 0:
		output += " (%d FAILED)" % summary.failed
	if summary.skipped > 0:
		output += " (%d SKIPPED)" % summary.skipped
	output += "\n"
	output += "  Duration: %dms\n" % summary.duration_ms
	output += "=".repeat(60) + "\n"

	# List failed tests
	if summary.failed > 0:
		output += "\n  FAILED TESTS:\n"
		for suite in suites:
			for result in suite.results:
				if not result.passed and not result.get("skipped", false):
					output += "    - [%s] %s\n" % [result.suite, result.name]
					output += "      %s\n" % result.message

	# Suite breakdown
	output += "\n  BREAKDOWN BY SUITE:\n"
	for suite in suites:
		var suite_passed = suite.results.filter(func(r): return r.passed).size()
		var suite_total = suite.results.size()
		var status = "PASS" if suite_passed == suite_total else "FAIL"
		output += "    [%s] %s: %d/%d\n" % [status, suite.suite_name, suite_passed, suite_total]

	print(output)
	return output


# ============================================
# JSON FORMAT
# ============================================

static func _format_json(suites: Array) -> String:
	var summary = get_summary(suites)

	var data = {
		"summary": summary,
		"suites": []
	}

	for suite in suites:
		var suite_data = {
			"name": suite.suite_name,
			"passed": suite.get_passed_count(),
			"failed": suite.get_failed_count(),
			"skipped": suite.get_skipped_count(),
			"duration_ms": suite.get_total_duration(),
			"tests": []
		}

		for result in suite.results:
			suite_data.tests.append({
				"name": result.name,
				"passed": result.passed,
				"skipped": result.get("skipped", false),
				"message": result.message,
				"duration_ms": result.duration_ms
			})

		data.suites.append(suite_data)

	var json = JSON.stringify(data, "  ")
	print(json)
	return json


# ============================================
# XML FORMAT (JUnit-compatible)
# ============================================

static func _format_xml(suites: Array) -> String:
	var summary = get_summary(suites)

	var xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
	xml += '<testsuites tests="%d" failures="%d" time="%.3f">\n' % [
		summary.total,
		summary.failed,
		summary.duration_ms / 1000.0
	]

	for suite in suites:
		var suite_passed = suite.get_passed_count()
		var suite_failed = suite.get_failed_count()
		var suite_time = suite.get_total_duration() / 1000.0

		xml += '  <testsuite name="%s" tests="%d" failures="%d" time="%.3f">\n' % [
			_xml_escape(suite.suite_name),
			suite.results.size(),
			suite_failed,
			suite_time
		]

		for result in suite.results:
			var test_time = result.duration_ms / 1000.0
			xml += '    <testcase name="%s" time="%.3f"' % [
				_xml_escape(result.name),
				test_time
			]

			if result.get("skipped", false):
				xml += '>\n      <skipped message="%s"/>\n    </testcase>\n' % _xml_escape(result.message)
			elif not result.passed:
				xml += '>\n      <failure message="%s"/>\n    </testcase>\n' % _xml_escape(result.message)
			else:
				xml += '/>\n'

		xml += '  </testsuite>\n'

	xml += '</testsuites>\n'

	print(xml)
	return xml


static func _xml_escape(text: String) -> String:
	return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


# ============================================
# LIVE OUTPUT HELPERS
# ============================================

## Print a test suite header
static func print_suite_header(suite_name: String) -> void:
	print("\n[SUITE] %s" % suite_name)


## Print a test pass
static func print_pass(test_name: String, duration_ms: int = 0) -> void:
	if duration_ms > 0:
		print("  PASS: %s (%dms)" % [test_name, duration_ms])
	else:
		print("  PASS: %s" % test_name)


## Print a test failure
static func print_fail(test_name: String, message: String) -> void:
	print("  FAIL: %s" % test_name)
	print("        %s" % message)


## Print a test skip
static func print_skip(test_name: String, reason: String) -> void:
	print("  SKIP: %s - %s" % [test_name, reason])


## Print a separator line
static func print_separator(char: String = "=", width: int = 60) -> void:
	print(char.repeat(width))


## Print test run header
static func print_header(title: String = "TEST SUITE") -> void:
	print("\n" + "=".repeat(60))
	print("           %s" % title)
	print("=".repeat(60))
