ifneq (,)
.error This Makefile requires GNU Make.
endif

# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
.PHONY: help lint test pycodestyle pydocstyle black version files docs dist sdist bdist build checkbuild deploy autoformat clean


VERSION = 2.7
BINPATH = bin/
BINNAME = pwncat

FL_VERSION = 0.3
FL_IGNORES = .git/,.github/,$(BINNAME).egg-info,docs/$(BINNAME).api.html

UID := $(shell id -u)
GID := $(shell id -g)


# -------------------------------------------------------------------------------------------------
# Default Target
# -------------------------------------------------------------------------------------------------
help:
	@echo " ██▓███   █     █░ ███▄    █  ▄████▄   ▄▄▄      ▄▄▄█████▓"
	@echo "▓██░  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██▀ ▀█  ▒████▄    ▓  ██▒ ▓▒"
	@echo "▓██░ ██▓▒▒█░ █ ░█ ▓██  ▀█ ██▒▒▓█    ▄ ▒██  ▀█▄  ▒ ▓██░ ▒░"
	@echo "▒██▄█▓▒ ▒░█░ █ ░█ ▓██▒  ▐▌██▒▒▓▓▄ ▄██▒░██▄▄▄▄██ ░ ▓██▓ ░ "
	@echo "▒██▒ ░  ░░░██▒██▓ ▒██░   ▓██░▒ ▓███▀ ░ ▓█   ▓██▒  ▒██▒ ░ "
	@echo "▒▓▒░ ░  ░░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ░ ░▒ ▒  ░ ▒▒   ▓▒█░  ▒ ░░   "
	@echo "░▒ ░       ▒ ░ ░  ░ ░░   ░ ▒░  ░  ▒     ▒   ▒▒ ░    ░    "
	@echo "░░         ░   ░     ░   ░ ░ ░          ░   ▒     ░      "
	@echo "             ░             ░ ░ ░            ░  ░         "
	@echo "                             ░                           "
	@echo
	@echo "lint             Lint source code"
	@echo "test             Run integration tests"
	@echo "autoformat       Autoformat code according to Python black"
	@echo
	@echo "docs             Generate docs"
	@echo
	@echo "build            Build Python package"
	@echo "dist             Create source and binary distribution"
	@echo "sdist            Create source distribution"
	@echo "bdist            Create binary distribution"
	@echo "clean            Clean the Build"


# -------------------------------------------------------------------------------------------------
# Lint Targets
# -------------------------------------------------------------------------------------------------

lint: pycodestyle pydocstyle black version files


pycodestyle:
	@echo "--------------------------------------------------------------------------------"
	@echo " Check pydocstyle"
	@echo "--------------------------------------------------------------------------------"
	docker run --rm -v $(PWD):/data cytopia/pycodestyle --show-source --show-pep8 $(BINPATH)$(BINNAME)

pydocstyle:
	@echo "--------------------------------------------------------------------------------"
	@echo " Check pycodestyle"
	@echo "--------------------------------------------------------------------------------"
	docker run --rm -v $(PWD):/data cytopia/pydocstyle $(BINPATH)$(BINNAME)

black:
	@echo "--------------------------------------------------------------------------------"
	@echo " Check Python Black"
	@echo "--------------------------------------------------------------------------------"
	docker run --rm -v ${PWD}:/data cytopia/black -l 100 --check --diff $(BINPATH)$(BINNAME)

version:
	@echo "--------------------------------------------------------------------------------"
	@echo " Check version config"
	@echo "--------------------------------------------------------------------------------"
	@if [ "$$(grep version= setup.py | awk -F'"' '{print $$2}')" != "$$(grep 'VERSION ' $(BINPATH)$(BINNAME) | awk -F'"' '{print $$2}')" ]; then \
		echo "Version mismatch in setup.py and $(BINPATH)$(BINNAME)"; \
		exit 1; \
	fi

lint-files:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Lint files                                                           #"
	@echo "# -------------------------------------------------------------------- #"
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-cr --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-crlf --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-trailing-single-newline --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-trailing-space --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-utf8 --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-utf8-bom --text --ignore '$(FL_IGNORES)' --path .

lint-docs:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Lint docs                                                            #"
	@echo "# -------------------------------------------------------------------- #"
	@$(MAKE) --no-print-directory docs
	git diff --quiet || { echo "Build Changes"; git diff|cat; git status; false; }


# -------------------------------------------------------------------------------------------------
# Test Targets
# -------------------------------------------------------------------------------------------------

test:
	@echo "noop"


# -------------------------------------------------------------------------------------------------
# Documentation
# -------------------------------------------------------------------------------------------------
docs:
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data -w /data -e UID=$(UID) -e GID=${GID} python:3-alpine sh -c ' \
		pip install pdoc \
		&& pdoc --overwrite --external-links --html --html-dir docs/ $(BINPATH)/$(BINNAME) $(BINNAME) \
		&& mv docs/$(BINNAME).m.html docs/$(BINNAME).api.html \
		&& chown $${UID}:$${GID} docs/$(BINNAME).api.html'


# -------------------------------------------------------------------------------------------------
# Build Targets
# -------------------------------------------------------------------------------------------------

dist: sdist bdist

sdist:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py sdist

bdist:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py bdist_wheel --universal

build:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(VERSION)-alpine \
		python setup.py build

checkbuild:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install twine \
		&& twine check dist/*"


# -------------------------------------------------------------------------------------------------
# Publish Targets
# -------------------------------------------------------------------------------------------------

deploy:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(VERSION)-alpine \
		sh -c "pip install twine \
		&& twine upload dist/*"


# -------------------------------------------------------------------------------------------------
# Misc Targets
# -------------------------------------------------------------------------------------------------

autoformat:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		cytopia/black -l 100 $(BINPATH)$(BINNAME)
clean:
	-rm -rf $(BINNAME).egg-info/
	-rm -rf dist/
	-rm -rf build/
