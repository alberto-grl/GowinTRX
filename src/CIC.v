// https://www.embedded.com/design/configurable-systems/4006446/Understanding-cascaded-integrator-comb-filters
// https://github.com/ericgineer/CIC/blob/master/CIC.v
// https://westcoastdsp.wordpress.com/tag/cic-filter/
// https://www.dsprelated.com/thread/907/cic-filter
// http://home.mit.bme.hu/~kollar/papers/cic.pdf

/*
For a Q-stage CIC decimation-by-D filter (diff delay = 1) overflow errors are avoided if the number of integrator and comb register bit widths is at least

    register bit widths = number of bits in x(n) + {Qlog2(D)}

where x(n) is the input to the CIC filter, and {k} means that if k is not an integer, round it up to the next larger integer. For example, if a Q = 3-stage CIC decimation filter accepts one-bit binary input words from a sigma-delta A/D converter and the decimation factor is D = 64, binary overflow errors are avoided if the three integrator and three comb registers’ bit widths are no less than
register bit widths = 1 + {3 log2(D)} = 1 + 3 6 = 19 bits.
(Rick Lyons)


	5 stadi, decimation 16384 (14 bit) 1 + 5 * 14 = 71 
	5 stadi, 20 bit input, decimation 256 (8 bit) 20 + 5 * 8 = 60 

*/


module CIC 
  (input wire clk,
   input wire [7:0]		Gain,
   input wire signed [19:0]  d_in,
   output reg signed [31:0]  d_out,
   output reg 				 d_clk);

  parameter WIDTH = 80; //was 70
  parameter DECIMATION_RATIO = 4096;  //was 1024

  reg signed [WIDTH-1:0] d_tmp, d_d_tmp;
  reg signed [WIDTH-1:0]  d_out1;

  // Integrator stage registers

  reg signed [WIDTH-1:0] d1, d1_x;
  reg signed [WIDTH-1:0] d2;
  reg signed [WIDTH-1:0] d3;
  reg signed [WIDTH-1:0] d4;
  reg signed [WIDTH-1:0] d5;

  // Comb stage registers

  reg signed [WIDTH-1:0] d6, d_d6;
  reg signed [WIDTH-1:0] d7, d_d7;
  reg signed [WIDTH-1:0] d8, d_d8;
  reg signed [WIDTH-1:0] d9, d_d9;
  reg signed [WIDTH-1:0] d10;

  reg [15:0] count;

  reg v_comb;  // Valid signal for comb section running at output rate

  reg d_clk_tmp;


  always @(posedge clk)
    begin

d1_x <=  $signed(d_in);  // <<< (WIDTH-20);
      // Integrator section
      d1 <= (d1_x) + d1;

      d2 <= d1 + d2;

      d3 <= d2 + d3;

      d4 <= d3 + d4;

      d5 <= d4 + d5;

      // Decimation

      if (count == DECIMATION_RATIO - 1)
        begin
          count <= 16'b0;
          d_tmp <= d5;
          d_clk_tmp <= 1'b1;
          v_comb <= 1'b1;
        end else if (count == DECIMATION_RATIO >> 1)
          begin
			d_clk_tmp <= 1'b0;
            count <= count + 16'd1;
            v_comb <= 1'b0;
          end else
            begin
			  d_clk_tmp <= 1'b0;
              count <= count + 16'd1;
              v_comb <= 1'b0;
            end
    end

  always @(posedge clk)  // Comb section running at output rate
    begin
      d_clk <= d_clk_tmp;


      if (v_comb)
        begin
          // Comb section
          d_d_tmp <= d_tmp;

          d6 <= d_tmp - d_d_tmp;
          d_d6 <= d6;

          d7 <= d6 - d_d6;
          d_d7 <= d7;

          d8 <= d7 - d_d7;
          d_d8 <= d8;

          d9 <= d8 - d_d8;
          d_d9 <= d9;

          d10 <= d9 - d_d9;
// d_out1 <= (d10 >>> (WIDTH - 32 - Gain));
//		  d_out <= d_out1[32:1];
d_out <= (d10 >>> (WIDTH - 32 - Gain));
//d_out <= d_out1[69:38];
end
    end		
	
endmodule