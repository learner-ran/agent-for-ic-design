module int8_dot_acc #(
  parameter int unsigned LEN_WIDTH = 16,
  parameter int unsigned ACC_WIDTH = 32
) (
  input  logic                         clk_i,
  input  logic                         rst_ni,

  input  logic                         start_valid_i,
  output logic                         start_ready_o,
  input  logic [LEN_WIDTH-1:0]         cfg_len_i,

  input  logic signed [7:0]            act_i,
  input  logic signed [7:0]            weight_i,
  input  logic                         in_valid_i,
  output logic                         in_ready_o,

  output logic                         out_valid_o,
  input  logic                         out_ready_i,
  output logic signed [ACC_WIDTH-1:0]  result_o,

  output logic                         busy_o,
  output logic                         done_o
);

  typedef enum logic [1:0] {
    STATE_IDLE  = 2'b00,
    STATE_ACCUM = 2'b01,
    STATE_OUT   = 2'b10
  } state_e;

  state_e state_q, state_d;

  logic [LEN_WIDTH-1:0]        len_q, len_d;
  logic [LEN_WIDTH-1:0]        count_q, count_d;
  logic signed [ACC_WIDTH-1:0] acc_q, acc_d;
  logic signed [ACC_WIDTH-1:0] result_q, result_d;
  logic                        done_q, done_d;

  logic                        start_fire;
  logic                        in_fire;
  logic                        out_fire;
  logic                        final_input;

  logic signed [15:0]          act_s16;
  logic signed [15:0]          weight_s16;
  logic signed [15:0]          product_s16;
  logic signed [ACC_WIDTH-1:0] product_ext_s32;
  logic signed [ACC_WIDTH-1:0] sum_next;

  assign start_ready_o = (state_q == STATE_IDLE) && (cfg_len_i != '0);
  assign in_ready_o    = (state_q == STATE_ACCUM);
  assign out_valid_o   = (state_q == STATE_OUT);
  assign busy_o        = (state_q != STATE_IDLE);
  assign result_o      = result_q;
  assign done_o        = done_q;

  assign start_fire = start_valid_i && start_ready_o;
  assign in_fire    = in_valid_i && in_ready_o;
  assign out_fire   = out_valid_o && out_ready_i;

  assign final_input = (count_q == (len_q - {{(LEN_WIDTH-1){1'b0}}, 1'b1}));

  assign act_s16         = {{8{act_i[7]}}, act_i};
  assign weight_s16      = {{8{weight_i[7]}}, weight_i};
  assign product_s16     = act_s16 * weight_s16;
  assign product_ext_s32 = {{(ACC_WIDTH-16){product_s16[15]}}, product_s16};
  assign sum_next        = acc_q + product_ext_s32;

  always_comb begin
    state_d  = state_q;
    len_d    = len_q;
    count_d  = count_q;
    acc_d    = acc_q;
    result_d = result_q;
    done_d   = 1'b0;

    unique case (state_q)
      STATE_IDLE: begin
        if (start_fire) begin
          state_d = STATE_ACCUM;
          len_d   = cfg_len_i;
          count_d = '0;
          acc_d   = '0;
        end
      end

      STATE_ACCUM: begin
        if (in_fire) begin
          acc_d = sum_next;
          if (final_input) begin
            state_d  = STATE_OUT;
            result_d = sum_next;
          end else begin
            count_d = count_q + {{(LEN_WIDTH-1){1'b0}}, 1'b1};
          end
        end
      end

      STATE_OUT: begin
        if (out_fire) begin
          state_d = STATE_IDLE;
          len_d   = '0;
          count_d = '0;
          done_d  = 1'b1;
        end
      end

      default: begin
        state_d = STATE_IDLE;
        len_d   = '0;
        count_d = '0;
        acc_d   = '0;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q  <= STATE_IDLE;
      len_q    <= '0;
      count_q  <= '0;
      acc_q    <= '0;
      result_q <= '0;
      done_q   <= 1'b0;
    end else begin
      state_q  <= state_d;
      len_q    <= len_d;
      count_q  <= count_d;
      acc_q    <= acc_d;
      result_q <= result_d;
      done_q   <= done_d;
    end
  end

endmodule
