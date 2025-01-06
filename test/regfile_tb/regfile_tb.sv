/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module regfile_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"
  import maverickOne_pkg::NUM_REGS;
  import maverickOne_pkg::XLEN;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int AW = $clog2(NUM_REGS);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [AW-1:0] addr_t;
  typedef logic [XLEN-1:0] data_t;
  typedef logic [NUM_REGS-1:0] num_reg_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic           arst_ni = 1;

  // RTL inputs
  addr_t          wr_unlock_addr_i;
  data_t          wr_unlock_data_i;
  logic           wr_unlock_en_i;
  logic           wr_lock_en_i;
  addr_t          wr_lock_addr_i;

  addr_t          rs1_addr_i;
  addr_t          rs2_addr_i;
  addr_t          rs3_addr_i;

  // RTL outputs
  num_reg_t       locks_o;
  data_t          rs1_data_o;
  data_t          rs2_data_o;
  data_t          rs3_data_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  data_t          ref_mem          [NUM_REGS];
  num_reg_t       tb_locks;
  num_reg_t       tb_locks_2;
  logic           lock_violation;
  logic     [3:1] read_error;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  regfile #() u_regfile (
      .arst_ni,
      .clk_i,
      .wr_unlock_addr_i,
      .wr_unlock_data_i,
      .wr_unlock_en_i,
      .wr_lock_en_i,
      .wr_lock_addr_i,
      .rs1_addr_i,
      .rs2_addr_i,
      .rs3_addr_i,
      .locks_o,
      .rs1_data_o,
      .rs2_data_o,
      .rs3_data_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task static apply_reset();
    #100ns;
    result_print(locks_o === 'x, "Locks not defined before reset");
    arst_ni <= 0;
    foreach (ref_mem[i]) ref_mem[i] <= '0;
    tb_locks <= '0;
    #100ns;
    result_print(locks_o === '1, "Locks active during reset");
    arst_ni <= 1;
    #100ns;
    result_print(locks_o === '0, "Locks cleared after reset");
  endtask

  task automatic start_random_drive();
    fork
      begin
        forever begin
          @(posedge clk_i);
          wr_lock_en_i <= $urandom;
          wr_lock_addr_i <= $urandom;

          wr_unlock_en_i <= $urandom;
          wr_unlock_addr_i <= $urandom;
          wr_unlock_data_i <= $urandom;

          rs1_addr_i <= $urandom;
          rs2_addr_i <= $urandom;
          rs3_addr_i <= $urandom;
        end
      end
    join_none
  endtask  // random drive task

  `define REGFILE_TB_RS_READ_CHECK(__IDX__)                                                       \
    if (tb_locks[rs``__IDX__``_addr_i]                                                            \
     && (rs``__IDX__``_data_o !== wr_unlock_data_i)) begin                                        \
      read_error[``__IDX__``] = '1;                                                               \
      $display(`"\033[1;31m[%0t] EXPECTED BYPASS\033[0m\nWR  : 0x%x\nRS``__IDX__`` : 0x%x\n`",    \
                $realtime, wr_unlock_data_i, rs``__IDX__``_data_o);                               \
    end else if (tb_locks[rs``__IDX__``_addr_i] == 0                                              \
          && (rs``__IDX__``_data_o !== ref_mem[rs``__IDX__``_addr_i])) begin                      \
      read_error[``__IDX__``] = '1;                                                               \
      $display(`"\033[1;31m[%0t] MEM_READ\033[0m\nTB  : 0x%x\nRS``__IDX__`` : 0x%x\n`",           \
                $realtime, ref_mem[rs``__IDX__``_addr_i], rs``__IDX__``_data_o);                  \
    end                                                                                           \


  task automatic start_in_out_monitor();
    lock_violation <= '0;
    read_error     <= '0;
    fork
      begin
        forever begin
          @(posedge clk_i);
          tb_locks_2 = tb_locks;
          if (wr_unlock_en_i) tb_locks_2[wr_unlock_addr_i] = '0;
          if (tb_locks_2 !== locks_o) begin
            lock_violation = '1;
            $display("\033[1;31m[%0t] LOCKS VIOLATION\033[0m\nTB  : 0b%b\nRTL : 0b%b\n", $realtime,
                     tb_locks_2, locks_o);
          end
          `REGFILE_TB_RS_READ_CHECK(1)
          `REGFILE_TB_RS_READ_CHECK(2)
          `REGFILE_TB_RS_READ_CHECK(3)
          if (wr_unlock_en_i && wr_unlock_addr_i != 0) begin
            ref_mem[wr_unlock_addr_i]  = wr_unlock_data_i;
            tb_locks[wr_unlock_addr_i] = '0;
          end
          if (wr_lock_en_i && (wr_lock_addr_i != 0)) tb_locks[wr_lock_addr_i] = '1;
        end
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    apply_reset();
    start_clk_i();
    start_random_drive();
    start_in_out_monitor();
  end

  initial begin
    repeat (1000000) @(posedge clk_i);
    result_print(!lock_violation, "Lock Violation Check");
    result_print(!read_error[1], "Rs1 Read Error Check");
    result_print(!read_error[2], "Rs2 Read Error Check");
    result_print(!read_error[3], "Rs3 Read Error Check");
    $finish;
  end

endmodule
