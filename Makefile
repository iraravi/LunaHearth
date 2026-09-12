.PHONY: bootstrap project build test lint docs-check

bootstrap:
	@./scripts/bootstrap.sh

project:
	xcodegen generate

build:
	./scripts/verify.sh build

test:
	./scripts/verify.sh test

lint:
	@./scripts/lint.sh

docs-check:
	@./scripts/docs-check.sh
