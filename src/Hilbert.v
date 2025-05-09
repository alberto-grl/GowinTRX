/*
   Hilbert filter for Verilog
   Copyright (C) 2025 Alberto Garlassi I4NZX
   GPL v3
*/

module Hilbert (
 input  clk  ,
 input  data_ready  ,
 input  [31:0] Q_in,
 input  [31:0] I_in,
 output reg signed [31:0] Q_out,
 output reg signed [31:0] I_out
 );

integer TAPS;

integer TAPS_D;

parameter COEFF_WIDTH = 13;

parameter DATA_WIDTH = 32;

parameter N = 55;    // Number of filter taps, SHOULD BE ODD

parameter DELAY_TAPS = 28;
reg signed [COEFF_WIDTH-1:0] k[0:N/2-1];
reg signed [DATA_WIDTH-1:0] v_Q[0:N-1];
reg signed [DATA_WIDTH-1:0] v_I[0:DELAY_TAPS ];
reg signed [DATA_WIDTH + COEFF_WIDTH + 2:0] sum[0:N/2-1];
reg signed [DATA_WIDTH+5+COEFF_WIDTH:0] mac_result;
reg [7:0] tap_counter;


initial begin
   k[0] = 8 ;
   k[1] = 10 ;
   k[2] = 15 ;
   k[3] = 23 ;
   k[4] = 36 ;
   k[5] = 55 ;
   k[6] = 80 ;
   k[7] = 114 ;
   k[8] = 159 ;
   k[9] = 223 ;
   k[10] = 319 ;
   k[11] = 482 ;
   k[12] = 845 ;
   k[13] = 2599 ;
end


always @(posedge clk)
 begin
              if (tap_counter < N/4+1) begin
                 mac_result <= mac_result + (sum[tap_counter]);
                 tap_counter <= tap_counter + 1;
             end

   if ((data_ready) && (tap_counter >= N/4+1))
       begin
         // Output the result and reset MAC for the next sample
                 Q_out <= mac_result[DATA_WIDTH + COEFF_WIDTH-2:COEFF_WIDTH-1]; // Truncate to output width
                 I_out <= v_I[0];
                 mac_result <= 0;
                 tap_counter <= 0;

        sum[0] <= (v_Q[0] - v_Q[54]) * k[0] ;
        sum[1] <= (v_Q[2] - v_Q[52]) * k[1] ;
        sum[2] <= (v_Q[4] - v_Q[50]) * k[2] ;
        sum[3] <= (v_Q[6] - v_Q[48]) * k[3] ;
        sum[4] <= (v_Q[8] - v_Q[46]) * k[4] ;
        sum[5] <= (v_Q[10] - v_Q[44]) * k[5] ;
        sum[6] <= (v_Q[12] - v_Q[42]) * k[6] ;
        sum[7] <= (v_Q[14] - v_Q[40]) * k[7] ;
        sum[8] <= (v_Q[16] - v_Q[38]) * k[8] ;
        sum[9] <= (v_Q[18] - v_Q[36]) * k[9] ;
        sum[10] <= (v_Q[20] - v_Q[34]) * k[10] ;
        sum[11] <= (v_Q[22] - v_Q[32]) * k[11] ;
        sum[12] <= (v_Q[24] - v_Q[30]) * k[12] ;
        sum[13] <= (v_Q[26] - v_Q[28]) * k[13] ;

 for (TAPS = 0 ; TAPS < N-1; TAPS = TAPS + 1) begin
                    v_Q[TAPS] <= v_Q[TAPS+1];
                 end
                 v_Q[N-1] <= Q_in;

 for (TAPS_D = 0 ; TAPS_D < DELAY_TAPS; TAPS_D = TAPS_D + 1) begin
                    v_I[TAPS_D] <= v_I[TAPS_D+1];
                 end
                 v_I[DELAY_TAPS] <= I_in;

      end
   end
endmodule
