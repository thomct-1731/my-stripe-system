SHELL:=/bin/bash
###################
# For Terraform
###################
#Set ENV & SERVICE
.PHONY: set_env
set_env:
ifndef e
$(error Error: ENV is undefined, please add to your command `e=dev or e=stg or e=prod or e=...`)
endif

.PHONY: check_env
check_env: set_env
ifeq ($(filter %$(e)/,$(shell ls -d terraform/envs/*/)),)
$(error Error: ENV defined is "$(e)" but not exists)
else
$(info ENV: "$(e)")
endif

.PHONY: set_service
set_service:
ifndef s
s := SERVICE
endif

.PHONY: check_service
check_service: check_env set_service
		@if [ "$s" = "SERVICE" ]; then \
			echo 'Error: SERVICE is required but no definition was found, still default value: "$(s)"' && \
			exit 1; \
		else \
			for service in $$(ls -d terraform/envs/$(e)/*/ | cut -d . -f2 | cut -d / -f1); do \
				if [ "$s" = $$service ]; then \
					echo 'SERVICE: "$(s)"'; \
				elif echo $$(ls -d terraform/envs/$(e)/*/ | cut -d . -f2 | cut -d / -f1) | grep -qFw "$s"; then \
					continue; \
				else \
					echo 'Error: SERVICE defined is "$(s)" but not exists' && \
					exit 1; \
				fi \
			done \
		fi \

.PHONY: set_target
set_target:
ifndef t
t := module.TARGET
endif

.PHONY: check_target
check_target: check_env check_service set_target
		@if [ "$t" = "module.TARGET" ]; then \
			echo 'Error: TARGET is required but no definition was found, still default value: "$(t)"' && \
			exit 1; \
		else \
			echo 'TARGET: "$(t)"'; \
		fi \

.PHONY: set_other_target
set_other_target:
ifndef ot
ot := OTHER_TARGET
endif

.PHONY: check_other_target
check_other_target: check_env check_service check_target set_other_target
		@if [ "$(ot)" = "OTHER_TARGET" ]; then \
			echo 'Error: OTHER TARGET is required but no definition was found, still default value: "$(ot)"' && \
			exit 1; \
		else \
			echo 'OTHER TARGET: "$(ot)"'; \
		fi \


#Symlink: When creating new service
.PHONY: symlink
symlink: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && VAR="_variables.tf" && \
	target_link=$(shell pwd)/terraform/envs/$(e)/_variables.tf && \
	symlink_path=$$service_path$$VAR && \
	if [ -L "$$symlink_path" ]; then \
		echo "Symlink already exists for: \"$$service_path\""; \
	else \
		ln -sfn "$$target_link" "$$symlink_path" && \
		if ! grep -qx "$$symlink_path" .gitignore; then \
			echo "$$symlink_path" >> .gitignore && \
			echo "Added symlink to .gitignore: $$symlink_path"; \
		else \
			echo "Symlink path already in .gitignore"; \
		fi && \
		echo "Created symlink for: $$service_path"; \
	fi

.PHONY: symlink_all
symlink_all: check_env
	@service_path=$$(ls -d terraform/envs/$(e)/*/) && VAR="_variables.tf" && \
	for service in $$service_path; do \
		target_link=$(shell pwd)/terraform/envs/$(e)/_variables.tf && \
		symlink_path=$$service$$VAR && \
		if [ -L "$$symlink_path" ]; then \
			echo "Symlink already exists for: \"$$service\""; \
		else \
			ln -sfn "$$target_link" "$$symlink_path" && \
			if ! grep -qx "$$symlink_path" .gitignore; then \
				echo "$$symlink_path" >> .gitignore && \
				echo "Added symlink to .gitignore: $$symlink_path"; \
			else \
				echo "Symlink path already in .gitignore"; \
			fi && \
			echo "Created symlink for: $$service"; \
		fi; \
	done

#Unsymlink: When deleting service
.PHONY: unsymlink
unsymlink: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && VAR="_variables.tf" && \
	if grep -rw ".gitignore" -e "$$service_path$$VAR"; then \
		sed -i $$(grep -rnw ".gitignore" -e "$$service_path$$VAR"  | cut -c -1)d .gitignore && \
		rm -rf $$service_path$$VAR && \
		echo Unsymlink variables.tf for: \"$$service_path\"; \
	else \
		echo "This variables.tf already unsymlinked"; \
	fi \

.PHONY: unsymlink_all
unsymlink_all: check_env
	@service_path=$$(ls -d terraform/envs/$(e)/*/) && VAR="_variables.tf" && \
	for service in $$service_path; do \
		if grep -rw ".gitignore" -e "$$service$$VAR"; then \
			sed -i $$(grep -rnw ".gitignore" -e "$$service$$VAR"  | cut -c -1)d .gitignore && \
			rm -rf $$service$$VAR && \
			echo Unsymlink variables.tf for: \"$$service\"; \
		else \
			echo "This variables.tf already unsymlinked"; \
		fi \
	done


#Init commands
.PHONY: init
init: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting init: \"$$service_path\" && \
	terraform -chdir=$$service_path init

.PHONY: init_upgrade
init_upgrade: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting init upgrade: \"$$service_path\" && \
	terraform -chdir=$$service_path init --upgrade

.PHONY: init_migrate
init_migrate: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting init migrate-state: \"$$service_path\" && \
	terraform -chdir=$$service_path init -migrate-state

.PHONY: init_all
init_all: check_env
	@service_path=$$(ls -d terraform/envs/$(e)/*/) && \
	for service in $$service_path; do \
		echo Excuting init: \"$$service\" && \
		terraform -chdir=$$service init; \
	done


#Plan/Apply commands
.PHONY: plan
plan: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting plan: \"$$service_path\" && \
	terraform -chdir=$$service_path plan --var-file=../terraform.$(e).tfvars

.PHONY: plan_target
plan_target: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting plan: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path plan --var-file=../terraform.$(e).tfvars --target '$(t)'

.PHONY: plan_all
plan_all: check_env
	@service_path=$$(ls -d terraform/envs/$(e)/*/) && \
	for service in $$service_path; do \
		echo Excuting plan: \"$$service\" && \
		terraform -chdir=$$service plan --var-file=../terraform.$(e).tfvars; \
	done

.PHONY: apply
apply: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting apply: \"$$service_path\" && \
	terraform -chdir=$$service_path apply --var-file=../terraform.$(e).tfvars

.PHONY: apply_target
apply_target: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting apply: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path apply --var-file=../terraform.$(e).tfvars --target '$(t)'

.PHONY: apply_all
apply_all: check_env
	@service_path=$$(ls -d terraform/envs/$(e)/*/) && \
	for service in $$service_path; do \
		echo Excuting apply: \"$$service\" && \
		terraform -chdir=$$service apply --var-file=../terraform.$(e).tfvars; \
	done


#Plan/Destroy commands
.PHONY: plan_destroy
plan_destroy: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting plan destroy: \"$$service_path\" && \
	terraform -chdir=$$service_path plan --var-file=../terraform.$(e).tfvars -destroy

.PHONY: plan_destroy_target
plan_destroy_target: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting plan destroy: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path plan --var-file=../terraform.$(e).tfvars --target '$(t)' -destroy

.PHONY: plan_destroy_all
plan_destroy_all: check_env
	@service_path=$$(ls -dr terraform/envs/$(e)/*/) && \
	for service in $$service_path; do \
		echo Excuting plan destroy: \"$$service\" && \
		terraform -chdir=$$service plan --var-file=../terraform.$(e).tfvars -destroy; \
	done

.PHONY: destroy
destroy: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting destroy: \"$$service_path\" && \
	terraform -chdir=$$service_path destroy --var-file=../terraform.$(e).tfvars

.PHONY: destroy_target
destroy_target: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting destroy: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path destroy --var-file=../terraform.$(e).tfvars --target '$(t)'

.PHONY: destroy_all
destroy_all: check_env
	@service_path=$$(ls -dr terraform/envs/$(e)/*/) && \
	for service in $$service_path; do \
		echo Excuting destroy: \"$$service\" && \
		terraform -chdir=$$service destroy --var-file=../terraform.$(e).tfvars; \
	done


#Other commands
##Recreate resource
.PHONY: taint
taint: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting taint resource: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path taint '$(t)'

.PHONY: untaint
untaint: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting untaint resource: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path untaint '$(t)'

##State of resource
.PHONY: state_list
state_list: check_env check_service
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting state list resource: \"$$service_path\" && \
	terraform -chdir=$$service_path state list

.PHONY: state_show
state_show: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting state show resource: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path state show '$(t)'

.PHONY: state_import
state_import: check_env check_service check_target check_other_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting state import resource: \"$$service_path\" from target: \'$(t)\' to: $(ot) && \
	terraform -chdir=$$service_path import --var-file=../terraform.$(e).tfvars '$(t)' '$(ot)'

.PHONY: state_rm
state_rm: check_env check_service check_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting state delete resource: \"$$service_path\" with target: \'$(t)\' && \
	terraform -chdir=$$service_path state rm '$(t)'

.PHONY: state_mv
state_mv: check_env check_service check_target check_other_target
	@service_path=$$(ls -d terraform/envs/$(e)/*/ | grep $(s) | head -n 1) && echo Excuting state move resource: \"$$service_path\" from target: \'$(t)\' to: \'$(ot)\' && \
	terraform -chdir=$$service_path state mv '$(t)' '$(ot)'
