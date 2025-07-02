.PHONY: help coverage clean

# Default target
help:
	@echo "Available commands:"
	@echo "  coverage  - Run forge coverage and generate HTML report"
	@echo "  medusa    - Run medusa"
	@echo "  echidna   - Run echidna"
	@echo "  clean     - Clean generated files"
	@echo "  help      - Show this help message"

# Run coverage and generate HTML report
coverage:
	forge coverage --no-match-coverage "(test|script)" --report lcov && genhtml lcov.info -o report --branch-coverage --ignore-errors inconsistent,corrupt && open report/index.html

# Run medusa
medusa:
	medusa fuzz --config test/external/crytic/medusa.json

# Run echidna
echidna:
	echidna --config test/external/echidna/echidna.json

# Clean generated files
clean:
	forge clean
	rm -r report/
	rm -f lcov.info 