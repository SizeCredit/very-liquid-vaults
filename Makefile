.PHONY: help coverage clean

# Default target
help:
	@echo "Available commands:"
	@echo "  coverage          - Run forge coverage and generate HTML report"
	@echo "  sizes             - Run forge build sizes for src contracts"
	@echo "  medusa-stateful   - Run medusa for all contracts with stateful fuzzing"
	@echo "  echidna-stateful  - Run echidna for all contracts with stateful fuzzing"
	@echo "  medusa            - Run medusa for all contracts"
	@echo "  echidna           - Run echidna for all contracts"
	@echo "  clean             - Clean generated files"
	@echo "  help              - Show this help message"

# Run coverage and generate HTML report
coverage:
	forge coverage --no-match-coverage "(test|script)" --report lcov && genhtml lcov.info -o report --branch-coverage --ignore-errors inconsistent,inconsistent && open report/index.html

sizes:
	forge build --sizes --skip test --skip script

medusa-stateful:
	medusa fuzz

echidna-stateful:
	echidna --config echidna.yaml test/recon/CryticTester.t.sol --contract CryticTester

# Run medusa for all contracts in test/property/crytic
medusa:
	$(MAKE) medusa-stateful
	@for file in $(shell find test/property/crytic -type f -name '*.t.sol'); do \
		contract=$$(basename $$file .t.sol); \
		echo "Running medusa on $$file (contract: $$contract)"; \
		jq '.compilation.platformConfig.target = "'"$$file"'" | .fuzzing.targetContracts = ["'"$$contract"'"]' medusa.json > medusa.tmp.json && \
		mv medusa.tmp.json medusa.json; \
		medusa fuzz --config medusa.json; \
	done

# Run echidna for all contracts in test/property/crytic
echidna:
	$(MAKE) echidna-stateful
	@for file in $$(shell find test/property/crytic -type f -name '*.t.sol'); do \
		echo "Running echidna on $$file"; \
		contract=$$(basename $$file .t.sol); \
		echidna --config echidna.yaml $$file --contract $$contract; \
	done

# Clean generated files
clean:
	forge clean
	rm -r report/
	rm -f lcov.info 