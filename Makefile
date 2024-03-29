# MAKEFILE
#
# @link https://secure.opsview.com/gerrit/#/admin/projects/plugin-lib-powershell
# ------------------------------------------------------------------------------

# Use bash as shell
SHELL=/bin/bash

# CVS path (path to the parent dir containing the project)
CVSPATH=https://secure.opsview.com/gerrit/#/admin/projects/

# Project owner
OWNER=ITRS Group Ltd

# Project vendor
VENDOR=ITRS Group Ltd

# Project name
PROJECT=plugin-lib-powershell

# Project version
VERSION=$(shell cat VERSION)

# Project release number (packaging build number)
RELEASE=$(shell cat RELEASE)

# Current directory and paths
CURRENTDIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
SCRIPTS_DIR = $(CURRENTDIR)PlugNpshell/
TEST_DIR=$(CURRENTDIR)Test
POWERSHELL_BIN=sudo /opt/opsview/powershell/pwsh

# --- MAKE TARGETS ---

# Display general help about this command
help:
	@echo ""
	@echo "$(PROJECT) Makefile."
	@echo "The following commands are available:"
	@echo ""
	@echo "    make qa       : Execute all tests and code linters"
	@echo ""

all: help

.PHONY: test-plugins
test-plugins:
	-${POWERSHELL_BIN} -Command Import-Module Pester -Force
	@for f in ${SCRIPTS_DIR}/*.ps1; do \
	    ${POWERSHELL_BIN} -Command Invoke-Pester $(TEST_DIR)/TestPlugNpshell.Tests.ps1 -CodeCoverage "$${f}"; done

.PHONY: test
test: test-plugins

.PHONY: script-analyzer-plugins
script-analyzer-plugins:
	-${POWERSHELL_BIN} -Command Import-Module PSScriptAnalyzer -Force
	@for f in ${SCRIPTS_DIR}/*.ps1; do \
	    ${POWERSHELL_BIN} -Command Invoke-ScriptAnalyzer "$${f}"; done


.PHONY: lint
lint: script-analyzer-plugins

.PHONY: qa
qa:	test lint
