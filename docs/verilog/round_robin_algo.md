# 一种round_robin算法实现

```verilog

module roundrobin
#(
  parameter RB_WIDTH = 4
)
(
  input wire clk,
  input wire rst_n,
  input wire [RB_WIDTH - 1 : 0] request,
  output wire [RB_WIDTH - 1 : 0] gnt,
)
  reg [RB_WIDTH - 1 : 0] state;

  wire [2*RB_WIDTH - 1 : 0] d_req = {req, req};
  wire [2*RB_WIDTH - 1 : 0] d_gnt;

  assign d_gnt = d_req & ~(d_req - state);
  assign gnt = d_gnt[RB_WIDTH - 1 : 0] | d_gnt[2*RB_WIDTH - 1 : RB_WIDTH];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 1;
    end else if (|req) begin
      if (state[RB_WIDTH - 1]) begin
        state <= 1;
      end
      state <= state << 1;
    end
  end
endmodule
```
