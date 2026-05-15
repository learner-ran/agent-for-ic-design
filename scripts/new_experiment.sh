#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: scripts/new_experiment.sh <NNN_name> <module_name>" >&2
  echo "Example: scripts/new_experiment.sh 002_sync_fifo sync_fifo" >&2
  exit 1
fi

EXP="$1"
MOD="$2"
BASE="experiments/${EXP}"

mkdir -p "${BASE}/requirements" "${BASE}/spec" "${BASE}/plan" "${BASE}/rtl" "${BASE}/tb" "${BASE}/sva" "${BASE}/logs" "${BASE}/reports" "${BASE}/scripts" "${BASE}/sim"
cp templates/requirement_template.md "${BASE}/requirements/user_requirement.md"
cp templates/experiment_report_template.md "${BASE}/reports/${MOD}_experiment_report.md"

cat > "${BASE}/spec/README.md" <<EOF2
# Spec Directory / Spec 目录

Recommended flow / 推荐流程:
1. Fill or describe requirements in ../requirements/user_requirement.md, or provide the requirement in Codex chat.
2. Use requirement-to-spec to generate ${MOD}_spec.draft.md.
3. Review and revise the draft.
4. Freeze the approved spec as ${MOD}_spec.md.
5. Continue with spec-planner and create ../plan/${MOD}_rtl_plan.md.
6. Generate RTL/DV artifacts only after the plan is approved or explicitly accepted.
EOF2

cat > "${BASE}/plan/README.md" <<EOF2
# Plan Directory / Plan 目录

This directory stores RTL implementation plans generated from frozen specs.

Expected artifact / 预期产物:
- ${MOD}_rtl_plan.md

Rules / 规则:
- Do not generate RTL/TB/SVA before a plan exists.
- Keep blocking ambiguities visible until the user resolves or explicitly accepts them.
EOF2

cat > "${BASE}/Makefile" <<'EOF2'
VCS ?= vcs
VCS_FLAGS ?= -full64 -sverilog -debug_access+all -timescale=1ns/1ps
TOP ?= tb_PLACEHOLDER
RTL ?= rtl/PLACEHOLDER.sv
TB ?= tb/tb_PLACEHOLDER.sv
SIM_DIR ?= sim
LOG_DIR ?= logs

.PHONY: sim lint verdi clean

sim:
	mkdir -p $(SIM_DIR) $(LOG_DIR)
	$(VCS) $(VCS_FLAGS) $(RTL) $(TB) -o $(SIM_DIR)/simv -l $(LOG_DIR)/vcs_compile.log
	./$(SIM_DIR)/simv -l $(LOG_DIR)/sim.log

lint:
	@echo "TODO: add project lint command"

verdi:
	verdi -sv $(RTL) $(TB) &

clean:
	rm -rf $(SIM_DIR) csrc simv* *.log *.vpd *.fsdb novas.* ucli.key DVEfiles
EOF2

sed -i "s/PLACEHOLDER/${MOD}/g" "${BASE}/Makefile"

echo "Created ${BASE}"
echo "Next: describe the vague requirement in ${BASE}/requirements/user_requirement.md, then ask Codex to use requirement-to-spec."
