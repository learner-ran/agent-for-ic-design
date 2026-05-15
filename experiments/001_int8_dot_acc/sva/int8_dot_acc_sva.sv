module int8_dot_acc_sva #(
  parameter int unsigned LEN_WIDTH = 16,
  parameter int unsigned ACC_WIDTH = 32
) (
  input logic                        clk_i,
  input logic                        rst_ni,
  input logic                        start_valid_i,
  input logic                        start_ready_o,
  input logic [LEN_WIDTH-1:0]        cfg_len_i,
  input logic                        in_valid_i,
  input logic                        in_ready_o,
  input logic                        out_valid_o,
  input logic                        out_ready_i,
  input logic signed [ACC_WIDTH-1:0] result_o,
  input logic                        busy_o,
  input logic                        done_o
);

  property p_result_stable_when_stalled;
    @(posedge clk_i) disable iff (!rst_ni)
      (out_valid_o && !out_ready_i) |=> (out_valid_o && busy_o && (result_o == $past(result_o)));
  endproperty

  property p_done_one_cycle;
    @(posedge clk_i) disable iff (!rst_ni)
      done_o |=> !done_o;
  endproperty

  property p_no_start_ready_when_busy;
    @(posedge clk_i) disable iff (!rst_ni)
      busy_o |-> !start_ready_o;
  endproperty

  property p_zero_length_not_ready;
    @(posedge clk_i) disable iff (!rst_ni)
      (cfg_len_i == '0) |-> !start_ready_o;
  endproperty

  property p_input_ready_only_when_busy;
    @(posedge clk_i) disable iff (!rst_ni)
      in_ready_o |-> (busy_o && !out_valid_o);
  endproperty

  property p_done_after_output_phase;
    @(posedge clk_i) disable iff (!rst_ni)
      done_o |-> (!busy_o && !out_valid_o);
  endproperty

  assert property (p_result_stable_when_stalled)
    else $error("result_o changed or output state dropped while output was stalled");
  assert property (p_done_one_cycle)
    else $error("done_o remained high for more than one cycle");
  assert property (p_no_start_ready_when_busy)
    else $error("start_ready_o asserted while busy_o was high");
  assert property (p_zero_length_not_ready)
    else $error("start_ready_o asserted for cfg_len_i == 0");
  assert property (p_input_ready_only_when_busy)
    else $error("in_ready_o asserted outside accumulation");
  assert property (p_done_after_output_phase)
    else $error("done_o asserted before the module returned to idle");

endmodule

bind int8_dot_acc int8_dot_acc_sva #(
  .LEN_WIDTH(LEN_WIDTH),
  .ACC_WIDTH(ACC_WIDTH)
) u_int8_dot_acc_sva (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .start_valid_i(start_valid_i),
  .start_ready_o(start_ready_o),
  .cfg_len_i(cfg_len_i),
  .in_valid_i(in_valid_i),
  .in_ready_o(in_ready_o),
  .out_valid_o(out_valid_o),
  .out_ready_i(out_ready_i),
  .result_o(result_o),
  .busy_o(busy_o),
  .done_o(done_o)
);

