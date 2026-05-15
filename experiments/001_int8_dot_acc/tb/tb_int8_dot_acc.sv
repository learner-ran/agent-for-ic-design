`timescale 1ns/1ps

module tb_int8_dot_acc;

  localparam int unsigned LEN_WIDTH = 18;
  localparam int unsigned ACC_WIDTH = 32;
  localparam int unsigned MAX_LEN   = 131072;

  logic                        clk_i;
  logic                        rst_ni;
  logic                        start_valid_i;
  logic                        start_ready_o;
  logic [LEN_WIDTH-1:0]        cfg_len_i;
  logic signed [7:0]           act_i;
  logic signed [7:0]           weight_i;
  logic                        in_valid_i;
  logic                        in_ready_o;
  logic                        out_valid_o;
  logic                        out_ready_i;
  logic signed [ACC_WIDTH-1:0] result_o;
  logic                        busy_o;
  logic                        done_o;

  logic signed [7:0]           act_vec    [0:MAX_LEN-1];
  logic signed [7:0]           weight_vec [0:MAX_LEN-1];

  int unsigned                 error_count;
  int unsigned                 seed;

  int8_dot_acc #(
    .LEN_WIDTH(LEN_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
  ) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_valid_i(start_valid_i),
    .start_ready_o(start_ready_o),
    .cfg_len_i(cfg_len_i),
    .act_i(act_i),
    .weight_i(weight_i),
    .in_valid_i(in_valid_i),
    .in_ready_o(in_ready_o),
    .out_valid_o(out_valid_o),
    .out_ready_i(out_ready_i),
    .result_o(result_o),
    .busy_o(busy_o),
    .done_o(done_o)
  );

  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  task automatic fail(input string msg);
    begin
      error_count++;
      $error("%0t FAIL: %s", $time, msg);
      $fatal(1);
    end
  endtask

  task automatic check(input bit cond, input string msg);
    begin
      if (!cond) begin
        fail(msg);
      end
    end
  endtask

  task automatic settle_comb;
    begin
      #1;
    end
  endtask

  function automatic logic signed [ACC_WIDTH-1:0] product_s32(
    input logic signed [7:0] act,
    input logic signed [7:0] weight
  );
    logic signed [15:0] act_s16;
    logic signed [15:0] weight_s16;
    logic signed [15:0] product_s16;
    begin
      act_s16     = {{8{act[7]}}, act};
      weight_s16  = {{8{weight[7]}}, weight};
      product_s16 = act_s16 * weight_s16;
      product_s32 = {{(ACC_WIDTH-16){product_s16[15]}}, product_s16};
    end
  endfunction

  function automatic logic signed [ACC_WIDTH-1:0] expected_sum(input int unsigned len);
    logic signed [ACC_WIDTH-1:0] sum;
    int unsigned                 i;
    begin
      sum = '0;
      for (i = 0; i < len; i++) begin
        sum = sum + product_s32(act_vec[i], weight_vec[i]);
      end
      expected_sum = sum;
    end
  endfunction

  task automatic drive_idle_inputs;
    begin
      start_valid_i = 1'b0;
      cfg_len_i     = '0;
      act_i         = '0;
      weight_i      = '0;
      in_valid_i    = 1'b0;
      out_ready_i   = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
      drive_idle_inputs();
      rst_ni = 1'b0;
      repeat (4) @(posedge clk_i);
      @(negedge clk_i);
      rst_ni = 1'b1;
      @(negedge clk_i);
      check(!busy_o, "busy_o should be low after reset");
      check(!done_o, "done_o should be low after reset");
      check(!in_ready_o, "in_ready_o should be low after reset");
      check(!out_valid_o, "out_valid_o should be low after reset");
      check(result_o == '0, "result_o should reset to zero");
    end
  endtask

  task automatic start_transaction(input int unsigned len);
    begin
      @(negedge clk_i);
      cfg_len_i     = len[LEN_WIDTH-1:0];
      start_valid_i = 1'b1;
      settle_comb();
      check(start_ready_o, "start_ready_o should accept legal nonzero length in idle");
      @(negedge clk_i);
      start_valid_i = 1'b0;
      cfg_len_i     = '0;
      check(busy_o, "busy_o should assert after start_fire");
      check(in_ready_o, "in_ready_o should assert in ACCUM");
      check(!out_valid_o, "out_valid_o should be low during ACCUM");
    end
  endtask

  task automatic send_pair(input int unsigned idx, input int unsigned gap_cycles);
    int unsigned gap;
    begin
      for (gap = 0; gap < gap_cycles; gap++) begin
      @(negedge clk_i);
        in_valid_i = 1'b0;
        act_i      = $signed(8'h55);
        weight_i   = $signed(8'haa);
        settle_comb();
        check(in_ready_o, "in_ready_o should remain high through upstream input stalls");
      end

      @(negedge clk_i);
      in_valid_i = 1'b1;
      act_i      = act_vec[idx];
      weight_i   = weight_vec[idx];
      settle_comb();
      check(in_ready_o, "in_ready_o should be high when sending an input pair");
      @(negedge clk_i);
      in_valid_i = 1'b0;
      act_i      = '0;
      weight_i   = '0;
    end
  endtask

  task automatic collect_result(
    input logic signed [ACC_WIDTH-1:0] expected,
    input int unsigned                 stall_cycles
  );
    int unsigned timeout;
    int unsigned stall_idx;
    logic signed [ACC_WIDTH-1:0] held_result;
    begin
      timeout = 0;
      while (!out_valid_o && timeout < 20) begin
        @(negedge clk_i);
        timeout++;
      end
      check(out_valid_o, "out_valid_o did not assert after final input pair");
      check(busy_o, "busy_o should remain high while result is pending");
      check(result_o == expected, "result_o mismatch before output fire");

      out_ready_i = 1'b0;
      held_result = result_o;
      for (stall_idx = 0; stall_idx < stall_cycles; stall_idx++) begin
        @(negedge clk_i);
        check(out_valid_o, "out_valid_o dropped during output backpressure");
        check(busy_o, "busy_o dropped during output backpressure");
        check(result_o == held_result, "result_o changed during output backpressure");
        check(!done_o, "done_o asserted before out_fire");
      end

      @(negedge clk_i);
      out_ready_i = 1'b1;
      @(negedge clk_i);
      out_ready_i = 1'b0;
      check(done_o, "done_o should pulse after out_fire");
      check(!busy_o, "busy_o should clear after out_fire");
      check(!out_valid_o, "out_valid_o should clear after out_fire");

      @(negedge clk_i);
      check(!done_o, "done_o should be a one-cycle pulse");
    end
  endtask

  task automatic run_transaction(
    input int unsigned len,
    input int unsigned input_gap_mod,
    input int unsigned output_stall_cycles
  );
    logic signed [ACC_WIDTH-1:0] expected;
    int unsigned                 i;
    int unsigned                 gap;
    begin
      expected = expected_sum(len);
      start_transaction(len);
      for (i = 0; i < len; i++) begin
        gap = (input_gap_mod == 0) ? 0 : (i % input_gap_mod);
        send_pair(i, gap);
      end
      collect_result(expected, output_stall_cycles);
    end
  endtask

  task automatic test_zero_length_rejected;
    begin
      @(negedge clk_i);
      cfg_len_i     = '0;
      start_valid_i = 1'b1;
      settle_comb();
      check(!start_ready_o, "zero-length command should not be ready");
      @(negedge clk_i);
      check(!busy_o, "zero-length command should not enter busy");
      check(!out_valid_o, "zero-length command should not produce output");
      start_valid_i = 1'b0;
    end
  endtask

  task automatic test_ignored_controls;
    begin
      @(negedge clk_i);
      in_valid_i = 1'b1;
      act_i      = 8'sd7;
      weight_i   = -8'sd3;
      settle_comb();
      check(!in_ready_o, "input before start should not be ready");
      @(negedge clk_i);
      in_valid_i = 1'b0;

      act_vec[0]    = 8'sd2;
      weight_vec[0] = 8'sd4;
      act_vec[1]    = -8'sd5;
      weight_vec[1] = 8'sd3;

      start_transaction(2);
      @(negedge clk_i);
      start_valid_i = 1'b1;
      cfg_len_i     = 18'd1;
      settle_comb();
      check(!start_ready_o, "start while busy should not be ready");
      start_valid_i = 1'b0;
      cfg_len_i     = '0;
      send_pair(0, 0);
      send_pair(1, 0);

      @(negedge clk_i);
      in_valid_i = 1'b1;
      act_i      = 8'sd99;
      weight_i   = 8'sd99;
      settle_comb();
      check(!in_ready_o, "input during OUT should not be ready");
      collect_result(expected_sum(2), 1);
      in_valid_i = 1'b0;
    end
  endtask

  task automatic fill_constant(
    input int unsigned      len,
    input logic signed [7:0] act,
    input logic signed [7:0] weight
  );
    int unsigned i;
    begin
      for (i = 0; i < len; i++) begin
        act_vec[i]    = act;
        weight_vec[i] = weight;
      end
    end
  endtask

  task automatic fill_random(input int unsigned len);
    int unsigned i;
    begin
      for (i = 0; i < len; i++) begin
        act_vec[i]    = $urandom_range(0, 255);
        weight_vec[i] = $urandom_range(0, 255);
      end
    end
  endtask

  initial begin
    error_count = 0;
    seed        = 32'h1a2b_3c4d;
    void'($urandom(seed));
    $display("INFO: tb_int8_dot_acc seed=0x%08x", seed);

    rst_ni = 1'b1;
    drive_idle_inputs();
    reset_dut();

    test_zero_length_rejected();

    fill_constant(1, 8'sh80, 8'sh80);
    run_transaction(1, 0, 0);

    act_vec[0]    = 8'sd3;
    weight_vec[0] = -8'sd4;
    act_vec[1]    = -8'sd5;
    weight_vec[1] = -8'sd6;
    act_vec[2]    = 8'sd127;
    weight_vec[2] = 8'sd2;
    act_vec[3]    = 8'sh80;
    weight_vec[3] = 8'sd127;
    run_transaction(4, 2, 3);

    test_ignored_controls();

    fill_constant(MAX_LEN, 8'sh80, 8'sh80);
    run_transaction(MAX_LEN, 0, 1);

    repeat (30) begin
      int unsigned len;
      int unsigned gap_mod;
      int unsigned stall_cycles;
      len          = $urandom_range(1, 64);
      gap_mod      = $urandom_range(0, 4);
      stall_cycles = $urandom_range(0, 5);
      fill_random(len);
      run_transaction(len, gap_mod, stall_cycles);
    end

    $display("PASS: tb_int8_dot_acc completed with %0d errors", error_count);
    $finish;
  end

endmodule
