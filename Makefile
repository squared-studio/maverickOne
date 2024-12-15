#########################################################################################
##                                                                                     ##
##    Description : A single Makefile for Xilinx Vivado Simulation in this reposity    ##
##    Author      : Foez Ahmed (https://github.com/foez-ahmed)                         ##
##                                                                                     ##
#########################################################################################

#########################################################################################
# HELP
#########################################################################################

.PHONY: help
help:
	@clear;
	@clear;
	@make -s print_logo
	@echo -e "\033[4;36mGNUmake options:\033[0m"
	@echo -e "\033[1;32mmake help\033[0m shows these message"
	@echo -e "\033[1;32mmake soft_clean\033[0m clears out builds"
	@echo -e "\033[1;32mmake clean\033[0m clears out builds and logs"
	@echo -e "\033[1;32mmake tb TOP=<top_module_name>\033[0m open new or existing testbench top"
	@echo -e "\033[1;32mmake rtl RTL=<module_name>\033[0m open new or existing rtl design"
	@echo -e "\033[1;32mmake schematic RTL=<module_name>\033[0m to generate vivado schematic of the design"
	@echo -e "\033[1;32mmake simulate TOP=<top_module_name>\033[0m to run simulate with cli"
	@echo -e "\033[1;32mmake gui_simulate TOP=<top_module_name>\033[0m to run simulate with gui"
	@echo -e "\033[1;32mmake wave\033[0m open dump.vcd from last simulation"
	@echo -e "\033[1;32mmake lint\033[0m for linting"
	@echo -e "\033[1;32mmake rtl_init_sim RTL=<module_name>\033[0m to run initial simulate of the rtl"
	@echo -e "\033[1;32mmake sta RTL=<module_name>\033[0m to run static timing analysis @ 100MHz clk_i"
	@echo -e "\033[1;32mmake update_doc_list\033[0m to update the documents"

#########################################################################################
# VARIABLES
#########################################################################################

ROOT := $(shell realpath .)
COMP_LIB := $(shell find $(ROOT)/source -name "*.sv")
INC_DIR := -i $(ROOT)/include

ifneq ($(TOP), )
  COMP_LIB += $(shell find $(ROOT)/test/$(TOP) -name "*.sv")
  INC_DIR += -i $(ROOT)/test/$(TOP)
endif

CONFIG ?= default

USER_NAME := $(shell git config user.name)
GIT_ID := https:\/\/github.com\/$(shell git config credential.username)

VCD ?= 0

XVLOG_DEFS += --define SIMULATION

ifeq ($(VCD),1)
XVLOG_DEFS += --define ENABLE_DUMPFILE
endif

#########################################################################################
# FILES
#########################################################################################

build:
	@mkdir -p build
	@echo "*" > build/.gitignore
	@git add build > /dev/null 2>&1

log:
	@mkdir -p log
	@echo "*" > log/.gitignore
	@git add log > /dev/null 2>&1

submodules/sv-genesis/tb_model.sv:
	@git submodule update --init --recursive --depth 1

submodules/sv-genesis/rtl_model.sv:
	@git submodule update --init --recursive --depth 1

.PHONY: tb
tb: test/$(TOP)/$(TOP).sv test/$(TOP) submodules/sv-genesis/tb_model.sv test/$(TOP)/xsim_$(CONFIG)_cfg
	@code test/$(TOP)/$(TOP).sv

test/$(TOP):
	@mkdir -p test/$(TOP)

test/$(TOP)/$(TOP).sv:
	@mkdir -p test/$(TOP)
	@cat submodules/sv-genesis/tb_model.sv \
	| sed "s/Author : name (email)/Author : $(USER_NAME) ($(GIT_ID))/g" \
	| sed "s/module tb_model;/module $(TOP);/g" \
	| sed "s/squared-studio/DSInnovators/g" \
	| sed "s/sv-genesis/maverickOne/g" \
	> test/$(TOP)/$(TOP).sv

test/$(TOP)/xsim_$(CONFIG)_cfg:
	@touch test/$(TOP)/xsim_$(CONFIG)_cfg

.PHONY: rtl
rtl: source/$(RTL).sv submodules/sv-genesis/rtl_model.sv
	@code source/$(RTL).sv

source/$(RTL).sv:
	@cat submodules/sv-genesis/rtl_model.sv \
	| sed "s/Author : name (email)/Author : $(USER_NAME) ($(GIT_ID))/g" \
	| sed "s/module rtl_model/module $(RTL)/g" \
	| sed "s/squared-studio/DSInnovators/g" \
	| sed "s/sv-genesis/maverickOne/g" \
	> source/$(RTL).sv

#########################################################################################
# VIVADO
#########################################################################################

.PHONY: simulate
simulate: print_logo soft_clean xvlog xelab xsim print_logo

.PHONY: gui_simulate
gui_simulate: print_logo soft_clean xvlog xelab gui_xsim print_logo

.PHONY: rtl_init_sim 
rtl_init_sim: print_logo soft_clean xvlog init_xelab init_xsim print_logo

define compile
  $(eval SUB_LIB := $(shell echo "$(wordlist 1, 25,$(COMPILE_LIB))"))
  cd build; xvlog $(INC_DIR) -sv $(SUB_LIB) --nolog $(XVLOG_DEFS) | tee -a ../log/$(TOP)_$(CONFIG).log
  $(eval COMPILE_LIB := $(wordlist 26, $(words $(COMPILE_LIB)), $(COMPILE_LIB)))
  $(if $(COMPILE_LIB), $(call compile))
endef

.PHONY: xvlog
xvlog:
	@rm -rf log/$(TOP)_$(CONFIG).log
	@$(eval COMPILE_LIB := $(COMP_LIB))
	@$(call compile)

.PHONY: xelab
xelab:
ifeq ($(TOP), )
	@$(error TOP not set)
else
	@cd build; xelab $(TOP) -s $(TOP) --debug wave --nolog | tee -a ../log/$(TOP)_$(CONFIG).log
endif

.PHONY: init_xelab
init_xelab:
ifeq ($(RTL), )
	@$(error RTL not set)
else
	@cd build; xelab $(RTL) -s $(RTL) --nolog
endif

.PHONY: xsim
xsim: test/$(TOP)/xsim_$(CONFIG)_cfg
ifeq ($(TOP), )
	@$(error TOP not set)
else
	@echo -n "$(TOP) $(CONFIG)" > build/config
	@cd build; xsim $(TOP) --runall --nolog | tee -a ../log/$(TOP)_$(CONFIG).log
endif

.PHONY: gui_xsim
gui_xsim: test/$(TOP)/xsim_$(CONFIG)_cfg
ifeq ($(TOP), )
	@$(error TOP not set)
else
	@echo -n "$(TOP) $(CONFIG)" > build/config
	@cd build; xsim $(TOP) --gui --nolog
endif

.PHONY: init_xsim
init_xsim:
ifeq ($(RTL), )
	@$(error RTL not set)
else
	@cd build; xsim $(RTL) --runall --nolog
endif

define make_clk_i_100_MHz
	echo "create_clock -name clk_i -period 10.000 [get_ports clk_i]" > TIMING_REPORTS_$(RTL)/clk_i.xdc
endef

.PHONY: schematic
schematic: generate_flist
	@rm -rf SCHEMATIC_$(RTL)
	@mkdir -p SCHEMATIC_$(RTL)
	@echo "create_project top" > SCHEMATIC_$(RTL)/$(RTL).tcl
	@echo "set_property include_dirs ../include [current_fileset]" >> SCHEMATIC_$(RTL)/$(RTL).tcl
	@$(foreach word, $(shell cat build/flist), echo "add_files $(word)" >> SCHEMATIC_$(RTL)/$(RTL).tcl;)
	@echo "set_property top $(RTL) [current_fileset]" >> SCHEMATIC_$(RTL)/$(RTL).tcl
	@echo "start_gui" >> SCHEMATIC_$(RTL)/$(RTL).tcl
	@echo "synth_design -top $(RTL) -lint" >> SCHEMATIC_$(RTL)/$(RTL).tcl
	@echo "synth_design -rtl -rtl_skip_mlo -name rtl_1" >> SCHEMATIC_$(RTL)/$(RTL).tcl
	@cd build; vivado -mode tcl -source ../SCHEMATIC_$(RTL)/$(RTL).tcl
	@make -s soft_clean

.PHONY: sta
sta: generate_flist
	@rm -rf TIMING_REPORTS_$(RTL)
	@mkdir -p TIMING_REPORTS_$(RTL)
	@$(call make_clk_i_100_MHz)
	@echo "create_project top" > TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "set_property include_dirs ../include [current_fileset]" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "add_files ../TIMING_REPORTS_$(RTL)/clk_i.xdc" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@$(foreach word, $(shell cat build/flist), echo "add_files $(word)" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl;)
	@echo "set_property top $(RTL) [current_fileset]" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "synth_design -top $(RTL) -part xc7z020clg484-1" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "report_methodology -file ../TIMING_REPORTS_$(RTL)/methodology_report.rpt" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "report_timing_summary -file ../TIMING_REPORTS_$(RTL)/timing_summary.rpt" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "report_timing -delay_type max -path_type full -max_paths 100 -file ../TIMING_REPORTS_$(RTL)/detailed_timing_max.rpt" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "report_timing -delay_type min -path_type full -max_paths 100 -file ../TIMING_REPORTS_$(RTL)/detailed_timing_min.rpt" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "report_clock_interaction -file ../TIMING_REPORTS_$(RTL)/clock_interaction.rpt" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "report_timing -delay_type max -slack_lesser_than 0 -max_paths 100 -file ../TIMING_REPORTS_$(RTL)/failing_paths.rpt" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@echo "exit" >> TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@cd build; vivado -mode batch -source ../TIMING_REPORTS_$(RTL)/$(RTL).tcl
	@make -s soft_clean

.PHONY: generate_flist
generate_flist: list_modules
	@$(eval _TMP := )
	@$(foreach word,$(shell cat build/list),                                          \
		$(if $(filter $(word),$(_TMP)),                                                 \
			: ,                                                                           \
			$(eval _TMP += $(word))                                                       \
				find source -name "$(word).sv" >> build/flist                               \
		);                                                                              \
	)
	@sed "s/^source/..\/source/g" -i build/flist

.PHONY: list_modules
list_modules: soft_clean
	@$(eval COMPILE_LIB := $(COMP_LIB))
	@$(call compile)
	@cd build; xelab $(RTL) -s $(RTL)
	@cat build/xelab.log | grep -E "work" > build/list
	@sed -i "s/.*work\.//gi" build/list;
	@sed -i "s/(.*//gi" build/list;
	@sed -i "s/_default.*//gi" build/list;

#########################################################################################
# GTKWAVE
#########################################################################################

build/dump.vcd:
	@make simulate TOP=$(TOP) VCD=1

.PHONY: wave
wave: build/dump.vcd
	@gtkwave build/dump.vcd


#########################################################################################
# VERIBLE
#########################################################################################

.PHONY: lint
lint:
	@rm -rf temp_lint_error
	@$(eval list := $(shell find -name "*.sv"))
	@- $(foreach file, $(list), verible-verilog-lint.exe $(file) >> temp_lint_error 2>&1;)
	@cat temp_lint_error

#########################################################################################
# DOCUMENTER
#########################################################################################

.PHONY: gen_doc
gen_doc:
	@echo "Creating document for $(FILE)"
	@mkdir -p document/rtl
	@python submodules/documenter/sv_documenter.py $(FILE) document/rtl
	@sed -i "s/.*${LINE_1}.*/<br>**${LINE_1}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@sed -i "s/.*${LINE_2}.*/<br>**${LINE_2}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@sed -i "s/.*${LINE_3}.*/<br>**${LINE_3}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@sed -i "s/.*${LINE_4}.*/<br>**${LINE_4}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@echo "[\`$(shell basename $(FILE) | sed 's/\.sv//g')\`]($(shell basename $(FILE) | sed 's/\.sv//g').md)" >> document/rtl/modules.md

.PHONY: update_doc_list
update_doc_list: submodules/documenter/sv_documenter.py
	@rm -rf document/rtl/*.md
	@rm -rf document/rtl/*_top.svg
	@$(eval RTL_LIST = $(shell find source -name "*.sv"))
	@echo "# List of Modules" > document/rtl/modules.md
	@$(foreach file, $(RTL_LIST), make -s gen_doc FILE=$(file);)
	@git add document/rtl > /dev/null 2>&1

submodules/documenter/sv_documenter.py:
	@git submodule update --init --recursive --depth 1

#########################################################################################
# RTL CHANGE LOG
#########################################################################################

source_change_logs:
	@touch source_change_logs

.PHONY: update_source_commit
update_source_commit: source_change_logs
	@sed -e "s/^$(RTL) .*//g" -i source_change_logs
	@git log -1 source/$(RTL).sv | grep -E "^commit " | sed "s/^commit /$(RTL) /g" \
		>> source_change_logs
	@$(eval RTLs = $(shell find source -name "*.sv" | sed "s/.*\///g" | sed "s/\.sv//g"))
	@rm -rf temp_source_change_logs
	@- $(foreach file, $(RTLs), grep -s -r -w "$(file)" source_change_logs >> temp_source_change_logs;)
	@mv temp_source_change_logs source_change_logs

.PHONY: pending_source_reviews
pending_source_reviews:
	@rm -rf temp_source_commit_diffs
	@touch temp_source_commit_diffs
	@$(eval RTLs = $(shell find source -name "*.sv" | sed "s/.*\///g" | sed "s/\.sv//g"))
	@$(foreach file, $(RTLs), $(call source_commit_diff,$(file));)
	@cat temp_source_commit_diffs

define source_commit_diff
	$(eval hash := $(shell git log -1 $(shell find source -name "$(1).sv") | grep -e "^commit " | sed "s/^commit /$(1) /g"))
	grep -r "$(hash)" source_change_logs > /dev/null 2>&1 || echo "$(hash)" >> temp_source_commit_diffs
endef

#########################################################################################
# MISCELLANEOUS
#########################################################################################

.PHONY: print_logo
print_logo:
	@echo "";
	@echo "";
	@echo -e "\033[1;34m  ____  ____ ___                             _      \033[0m\033[1;39m Since 2001 \033[0m";
	@echo -e "\033[1;34m |  _ \/ ___|_ _|_ __  _ __   _____   ____ _| |_ ___  _ __ ___  \033[0m";
	@echo -e "\033[1;34m | | | \___ \| || '_ \| '_ \ / _ \ \ / / _' | __/ _ \| '__/ __| \033[0m";
	@echo -e "\033[1;34m | |_| |___) | || | | | | | | (_) \ V / (_| | || (_) | |  \__ \ \033[0m";
	@echo -e "\033[1;34m |____/|____/___|_| |_|_| |_|\___/ \_/ \__,_|\__\___/|_|  |___/ \033[0m";
	@echo -e "\033[1;39m ______________ Dynamic Solution Innovators Ltd. ______________ \033[0m";
	@echo -e "";

.PHONY: soft_clean
soft_clean:
	@rm -rf build
	@make -s build

.PHONY: clean
clean: soft_clean
	@rm -rf log
	@make -s log
	@rm -rf $(shell find -name "temp_*")
	@$(foreach word, $(shell cat .gitignore), rm -rf $(shell find $(shell realpath .) -name "$(word)");)

LINE_1 := This file is part of DSInnovators:maverickOne
LINE_2 := Copyright (c) $(shell date +%Y) DSInnovators
LINE_3 := Licensed under the MIT License
LINE_4 := See LICENSE file in the project root for full license information

.PHONY: copyright_check
copyright_check:
	@rm -rf temp_copyright_issues
	@$(eval LIST := $(shell find -name "*.svh" | sed "s/\/.*submodules\/.*//g"))
	@$(foreach file, $(LIST), $(call copyright_check_file,$(file));)
	@$(eval LIST := $(shell find -name "*.sv" | sed "s/\/.*submodules\/.*//g"))
	@$(foreach file, $(LIST), $(call copyright_check_file,$(file));)
	@touch temp_copyright_issues
	@cat temp_copyright_issues

define copyright_check_file
	(grep -ir "author" $(1) > /dev/null 2>&1) || (echo "$(1) >> \"Author : Name (email)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_1)" $(1) > /dev/null 2>&1) || (echo "$(1) >> \"$(LINE_1)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_2)" $(1) > /dev/null 2>&1) || (echo "$(1) >> \"$(LINE_2)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_3)" $(1) > /dev/null 2>&1) || (echo "$(1) >> \"$(LINE_3)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_4)" $(1) > /dev/null 2>&1) || (echo "$(1) >> \"$(LINE_4)\"" >> temp_copyright_issues)
endef
