#!/bin/bash

################################################################################
# FUNCTIONS
################################################################################

ci_simulate () {
  start_time=$(date +%s)
  echo -n -e " $(date +%x\ %H:%M:%S) - \033[1;33mSIMULATING $1 $2... \033[0m"
  make simulate TOP=$1 CONFIG=$2 > /dev/null
  end_time=$(date +%s)
  time_diff=$((end_time - start_time))
  echo -e "\033[1;32mDone!\033[0m ($time_diff seconds)"
  echo ""
}

################################################################################
# CLEANUP
################################################################################

start_time=$(date +%s)
clear
make print_logo
echo -n -e " $(date +%x\ %H:%M:%S) - \033[1;33mCLEANING UP TEMPORATY FILES... \033[0m"
make -s clean
end_time=$(date +%s)
time_diff=$((end_time - start_time))
echo -e "\033[1;32mDone!\033[0m ($time_diff seconds)"
echo ""

################################################################################
# SIMULATE
################################################################################

ci_simulate encoder_tb default
ci_simulate exe_m64_mult_tb default
ci_simulate fixed_priority_arbiter_tb default
ci_simulate instr_decoder_tb default
ci_simulate instr_launcher_tb default
ci_simulate pipeline_split_tb default
ci_simulate pipeline_tb default
ci_simulate priority_encoder_tb default
ci_simulate reg_gnt_ckr_tb default
ci_simulate regfile_tb default
ci_simulate rotating_xbar_tb default
ci_simulate round_robin_arbiter_tb default
ci_simulate xbar_tb default

################################################################################
# COLLECT & PRINT
################################################################################

rm -rf temp_ci_issues
touch temp_ci_issues

grep -s -r "\[1;31m\[FAIL\]" ./log | sed "s/.*\.log://g" >> temp_ci_issues
grep -s -r "ERROR:" ./log | sed "s/.*\.log://g" >> temp_ci_issues

echo -e ""
echo -e "\033[1;36m___________________________ CI REPORT ___________________________\033[0m"
grep -s -r "\[1;32m\[PASS\]" ./log | sed "s/.*\.log://g"
grep -s -r "\[1;31m\[FAIL\]" ./log | sed "s/.*\.log://g"
grep -s -r "WARNING:" ./log | sed "s/.*\.log://g"
grep -s -r "ERROR:" ./log | sed "s/.*\.log://g"

echo -e "\n"
echo -e "\033[1;36m____________________________ SUMMARY ____________________________\033[0m"
echo -n "PASS    : "
grep -s -r "\[1;32m\[PASS\]" ./log | sed "s/.*\.log://g" | wc -l
echo -n "FAIL    : "
grep -s -r "\[1;31m\[FAIL\]" ./log | sed "s/.*\.log://g" | wc -l
echo -n "WARNING : "
grep -s -r "WARNING:" ./log | sed "s/.*\.log://g" | wc -l
echo -n "ERROR   : "
grep -s -r "ERROR:" ./log | sed "s/.*\.log://g" | wc -l
echo -e ""
