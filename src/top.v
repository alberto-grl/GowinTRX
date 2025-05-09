/*
Standalone test of NCO for FPGARX
*/

// IP Express reference : https://www.latticesemi.com/-/media/LatticeSemi/Documents/UserManuals/EI2/FPGA-IPUG-02032-1-0-Arithmetic-Modules.ashx?document_id=52235

`define BIT_1_ADC


module top 
  (
   	output [7:0] MYLED,
	output TX,
	//output clk_adc,
	output TX_NCO,
	
`ifdef BIT_1_ADC
	input  RFIn_p,
    input  RFIn_n,
	output RFOut,
`endif
	input XIn,
	output MOSI_I,
	input MISO_I,
	output SCK_I,
	output SSEL_I,
	output MOSI_Q,
	input MISO_Q,
	output SCK_Q,
	output SSEL_Q,
	output PWMOut
	);


// LVDS Input Buffer
TLVDS_IBUF  lvds_ibuf (
  .I(RFIn_p),
  .IB(RFIn_n),
  .O(RFIn)
);


`ifndef BIT_1_ADC
reg signed[9:0] RFIn;
`endif

wire signed[9:0] LOSine;
wire signed[9:0] LOCosine;
reg signed[63:0] phase_inc_carrGen;
reg signed[63:0] phase_inc_carrGen1;
wire signed[9:0] LOSine_test_gen;
wire signed[9:0] LOCosine_test_gen;
reg signed[63:0] phase_inc_testGen;
reg signed[63:0] phase_inc_testGen1;
//end signed
wire [63:0] phase_accum;
wire [63:0] phase_accum_test_gen;
reg clk_adc;  //60 MHz to ADC, mixer, CIC
//wire osc_clk; //120 MHz from PLL, to NCO
wire CIC_out_clkI;  // 60 MHz / CIC decimation, eg. 234375 Hz
wire CIC_out_clkQ;
reg [7:0] CICGain;
reg signed [19:0] MixerOutI;
reg signed [19:0] MixerOutQ;	
reg [1:0] clk_adc_counter;
wire [127:0] Registers_I; //will store 8 registers 16 bit wide. 16 * 8 = 128   
wire [127:0] Registers_Q; //will store 8 registers 16 bit wide. 16 * 8 = 128   
wire [31:0] MOSI_Val_I;	
wire [31:0] MOSI_Val_Q;
reg StartSPI_I;
wire [31:0] data_out_I;
reg StartSPI_Q;
wire [31:0] data_out_Q;
reg RFInR;
reg RFInR1;
wire signed [31:0] I_out;
wire signed [31:0] Q_out;
reg signed [31:0] audio_out;





// inc = 2^64 * Fout / Fclock
// Python: print(hex(pow(2,64) * 1359000 // 64000000))



`ifdef BIT_1_ADC
  always @(posedge osc_clk)
    begin 
      RFInR1 <= RFIn;
      RFInR <= RFInR1;	
    end

  assign RFOut = RFInR1;

  always @(posedge osc_clk)
    begin
      if (RFInR == 1'b 0)
        begin
          MixerOutI <= LOSine <<< 10;
          MixerOutQ <= LOCosine <<< 10;
        end
      else
        begin
          MixerOutI <= -LOSine <<< 10;
          MixerOutQ <= -LOCosine <<< 10;				
        end
    end
`endif 

CIC  #(.WIDTH(80), .DECIMATION_RATIO(4096)) CIC_I (
.clk (osc_clk),
.Gain (CICGain[7:0]),
.d_in (MixerOutI[19:0]),
.d_out (MOSI_Val_I),
.d_clk (CIC_out_clkI)
);  


CIC  #(.WIDTH(80), .DECIMATION_RATIO(4096)) CIC_Q (
.clk (osc_clk),
.Gain (CICGain[7:0]),
.d_in (MixerOutQ[19:0]),
.d_out (MOSI_Val_Q),
.d_clk (CIC_out_clkQ)
);  


SinCos SinCos1 (
.Clock (osc_clk),
.ClkEn (1'b 1),
.Reset (1'b 0),
.Theta (phase_accum[63:54]),
.Sine (LOSine),
.Cosine (LOCosine)
);


SinCos SinCos_test_gen (
.Clock (osc_clk),
.ClkEn (1'b 1),
.Reset (1'b 0),
.Theta (phase_accum_test_gen[63:54]),
.Sine (LOSine_test_gen),
.Cosine (LOCosine_test_gen)
);

nco_sig	 ncoGen (
.clk (osc_clk /*clk_adc*/),
.phase_inc_carr ( phase_inc_carrGen1),
.phase_accum (phase_accum)
//.sin_out (sinGen),
//.cos_out (cosGen)
);


nco_sig nco_test_gen  (
.clk (osc_clk),
.phase_inc_carr ( phase_inc_testGen1),
.phase_accum (phase_accum_test_gen)
);

`ifndef BIT_1_ADC
/*
Multiplier MixerI  (
	.Clock (osc_clk),
    .ClkEn (1'b1),
    .Aclr (1'b 0),
    .DataA (-LOSine[9:0]),
//	.DataA (511),
    .DataB (RFIn[9:0]),
	// .DataB (10'b1),
    .Result (MixerOutI[19:0])
);
*/
  Gowin_MULT MixerI(
        .dout(MixerOutI[19:0]), //output [19:0] dout
        .a(LOSine[9:0]), //input [9:0] a
        .b(RFIn[9:0]), //input [9:0] b
        .ce(1), //input ce
        .clk(osc_clk), //input clk
        .reset(0) //input reset
        );
/*
Multiplier MixerQ  (
	.Clock (osc_clk),
    .ClkEn (1'b1),
    .Aclr (1'b 0),
    .DataA (LOCosine[9:0]),
    .DataB (RFIn[9:0]),
    .Result (MixerOutQ[19:0])
);
*/
  Gowin_MULT1 MixerQ(
        .dout(MixerOutQ[19:0]), //output [19:0] dout
        .a(LOCosine[9:0]/, //input [9:0] a
        .b(RFIn[9:0]), //input [9:0] b
        .ce(1), //input ce
        .clk(osc_clk), //input clk
        .reset(0) //input reset
        );
`endif


Hilbert Hilbert (
.clk (osc_clk),
.I_in (MOSI_Val_Q[31:0]),
.Q_in (MOSI_Val_I[31:0]),
.data_ready (CIC_out_clkI),
.I_out (I_out[31:0]),
.Q_out (Q_out[31:0])
);


/*
Lattice


PLL PLL1 (
.CLKI (XIn),.CLKOP (osc_clk)
);

	  
PLL_TX PLL2 (
//.CLKI (phase_accum[63]),.CLKOP (TX)
.CLKI (phase_accum[63]),.CLKOP (TX)
);	  
*/	  
	  

// osc_clk 64.8 MHz
    Gowin_rPLL PLL1(
        .clkout(osc_clk), //output clkout
        .clkin(XIn) //input clkin
    );



assign MYLED[7:6] = 1; //phase_inc_carrGen[63:61];
assign MYLED[5] = data_out_Q[0]; //MISO_Q;
assign MYLED[4] = data_out_I[0]; //MISO_I;_out_I
assign MYLED[3] =  1; //osc_clk;
assign MYLED[2] = LOSine[4]; //clk_adc;
assign MYLED[1] = LOSine[9];// CIC_outQ[7];
assign MYLED[0] = 1; //CIC_out_clkQ ;
//assign TX = phase_accum[63];
assign TX_NCO = phase_accum[43];


always @ (posedge (osc_clk /*clk_adc*/))
	begin
	phase_inc_testGen1 <= phase_inc_testGen;	
	phase_inc_carrGen1 <= phase_inc_carrGen;
	`ifndef BIT_1_ADC
	RFIn <=  (LOSine_test_gen); // >>> sign extends when registers are signed
	`endif
	clk_adc_counter <= clk_adc_counter+ 2'b1;
	clk_adc <= clk_adc_counter[0];
	CICGain <= 1;  //2 is full out with maximum in. Higher values increase gain
	audio_out <= Q_out + I_out;  // audio_out <= Q_out - I_Out for USB
//    audio_out <= MOSI_Val_Q;
  
// inc = 2^64 * Fout / Fclock
// Python: print(hex(pow(2,64) * 1359000 // 64800000))
 // phase_inc_carrGen <= 64'h 800000000000000; // 2 MHz
 //  phase_inc_carrGen <= Registers_I[63:0];

//	          phase_inc_carrGen <= 64'h 1c4ccccccccccccc; // 7075 KHz 
//			  phase_inc_carrGen <= 64'h 1c4c49ba5e353f7c; // 7074.5 KHz
//		      phase_inc_carrGen <= 64'h 1ba781948b0fcd6e; // 7000 kHz	@64.8 MHz
//			  phase_inc_carrGen <= 64'h 1c2786c226809d49; // 7038.6 KH	(WSPR2)	
			  phase_inc_carrGen <= 64'h 1bf258bf258bf258; // 7074 kHz (FT8) @64.8 MHz
//			  phase_inc_carrGen <= 64'h 384bc6a7ef9db22d; // 14074 kHz (FT8)

	          phase_inc_testGen <= 64'h 1ba8847ce7186625; // 7001 KHz @64.8 MHz
//	          phase_inc_testGen <= 64'h 102e85c0898b7; // 1 KHz @64.8
//		      phase_inc_carrGen <= 64'h 538ef34d6a161; // 5.1 KHz
//			  phase_inc_carrGen <= 64'h 624dd2f1a9fbe; // 6 KHz
  end


always @(posedge osc_clk )
begin
		if (CIC_out_clkI) 
			begin
				StartSPI_I <= 1'b1;
			end
			else
			begin
				StartSPI_I <= 1'b0;
			end

end
		

always @(posedge osc_clk )
begin
		if (CIC_out_clkQ) 
			begin
				StartSPI_Q <= 1'b1;
			end
			else
			begin
				StartSPI_Q <= 1'b0;
			end
end

SPI_Master SPI_Master_I (
.osc_clk (osc_clk ),  
//.rst (rst),
//.data_in ({22'b0, LOSine[9:0]}),
//.data_in ({22'b0, RFIn[9:0]}),
//.data_in ({12'b0, MixerOutI[19:0]}),
.data_in (I_out),
//.data_in (32'b 10101010101010101010101010101011),
.data_out (data_out_I),
.StartSPI (StartSPI_I),
.SCK (SCK_I),
.MOSI (MOSI_I),
.MISO (MISO_I),
.SSEL (SSEL_I),
.Registers (Registers_I)
);

SPI_Master SPI_Master_Q (
.osc_clk (osc_clk),  
//.rst (rst),
.data_in (Q_out), 
.data_out (data_out_Q),
.StartSPI (StartSPI_Q),
.SCK (SCK_Q),
.MOSI (MOSI_Q),
.MISO (MISO_Q),
.SSEL (SSEL_Q),
.Registers (Registers_Q)
);

PWM PWM1 (
.clk (osc_clk),
//.DataIn (IIR_out), //(CIC_out),
//.DataIn (DemodOut), //(IIR_out),
//.DataIn (MOSI_Val_I[31:20]),
.DataIn (audio_out[31:20]),
//.DataIn (LOSine_test_gen),
.PWMOut (PWMOut)
);

endmodule
