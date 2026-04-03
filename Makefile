.PHONY: install install-global validate clean clean-global

PACK_NAME := speckit
VERSION := $(shell grep '^version:' manifest.yaml | sed 's/version: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/')
LOCAL_DIR := .awf/workflow-packs/$(PACK_NAME)
GLOBAL_DIR := $(HOME)/.local/share/awf/workflow-packs/$(PACK_NAME)
STATE_JSON = '{"name":"$(PACK_NAME)","enabled":true,"source_data":{"repository":"awf-project/awf-workflow-$(PACK_NAME)","version":"$(VERSION)","installed_at":"$(shell date -Iseconds)","updated_at":"$(shell date -Iseconds)"}}'

install:
	@mkdir -p $(LOCAL_DIR)
	cp -r manifest.yaml workflows prompts scripts $(LOCAL_DIR)/
	@echo $(STATE_JSON) > $(LOCAL_DIR)/state.json
	@echo "Installed to $(LOCAL_DIR)"

install-global:
	@mkdir -p $(GLOBAL_DIR)
	cp -r manifest.yaml workflows prompts scripts $(GLOBAL_DIR)/
	@echo $(STATE_JSON) > $(GLOBAL_DIR)/state.json
	@echo "Installed to $(GLOBAL_DIR)"

validate:
	@grep -q '^name: $(PACK_NAME)$$' manifest.yaml
	@for w in init constitution specify clarify plan tasks analyze checklist implement taskstoissues; do \
		test -f workflows/$$w.yaml || (echo "MISSING: workflows/$$w.yaml" && exit 1); \
	done
	@echo "OK: all 10 workflows present"

clean:
	@rm -rf $(LOCAL_DIR)
	@echo "Removed $(LOCAL_DIR)"

clean-global:
	@rm -rf $(GLOBAL_DIR)
	@echo "Removed $(GLOBAL_DIR)"
