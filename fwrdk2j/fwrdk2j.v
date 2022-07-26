// Working: Forward Kinematics
//			x = x_1 + x_2; 	y = y_1 + y_2;
//			x_1 = 11*cos(theta1) ; x_2 = 12*cos(theta_sum)
//			y_1 = 11*sin(theta1) ; y_2 = 12*sin(theta_sum)
//
//
//
//
//

`timescale 1ns/1ps

`define BIT_WIDTH 32
`define FRACTIONS 15
module fwrdk2j (theta1,theta2,x,y);
	input [`BIT_WIDTH-1:0] theta1,theta2;
	output [`BIT_WIDTH-1:0] x,y;
	
	wire [`BIT_WIDTH-1:0] theta_sum;
	wire [`BIT_WIDTH-1:0] x_1, x_2, y_1, y_2;
	wire [`BIT_WIDTH-1:0] cos_1, cos_2, sin_1, sin_2;
	wire overflow_flag;
	reg [`BIT_WIDTH-1:0] const_1, const_2;
	//assign const_1 = `BIT_WIDTH'b00000000000001011000000000000000;
	//assign const_2 = `BIT_WIDTH'b00000000000001100000000000000000;
	
	qadd #(`FRACTIONS,`BIT_WIDTH) theta_adder(.a(theta1), .b(theta2), .c(theta_sum));
   	cos_lut U0 (theta_sum,cos_2);
   	sin_lut U1 (theta_sum,sin_2);
   	cos_lut U2 (theta1,cos_1);
   	sin_lut U3 (theta1,sin_1);
   	qmult #(`FRACTIONS,`BIT_WIDTH) x1_multiplier(.i_multiplicand(`BIT_WIDTH'b00000000000001011000000000000000),
                                                .i_multiplier(cos_1), .o_result(x_1), .ovr(overflow_flag)); 
   	qmult #(`FRACTIONS,`BIT_WIDTH) x2_multiplier(.i_multiplicand(`BIT_WIDTH'b00000000000001100000000000000000),
						     .i_multiplier(cos_2), .o_result(x_2), .ovr(overflow_flag)); 
		
	qadd #(`FRACTIONS,`BIT_WIDTH) x_adder(.a(x_1), .b(x_2), .c(x));
	qmult #(`FRACTIONS,`BIT_WIDTH) y1_multiplier(.i_multiplicand(`BIT_WIDTH'b00000000000001011000000000000000),
							     .i_multiplier(sin_1), .o_result(y_1), .ovr(overflow_flag)); 
	qmult #(`FRACTIONS,`BIT_WIDTH) y2_multiplier(.i_multiplicand(`BIT_WIDTH'b00000000000001100000000000000000),
							     .i_multiplier(sin_2), .o_result(y_2), .ovr(overflow_flag)); 
	qadd #(`FRACTIONS,`BIT_WIDTH) y_adder(.a(y_1), .b(y_2), .c(y));
	//end

endmodule


module qadd #(parameter Q = 15, N = 32)
	(
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] c
    );

reg [N-1:0] res;

assign c = res;

always @(a,b) begin
	// both negative or both positive
	if(a[N-1] == b[N-1]) begin						//	Since they have the same sign, absolute magnitude increases
		res[N-2:0] = a[N-2:0] + b[N-2:0];		//		So we just add the two numbers
		res[N-1] = a[N-1];							//		and set the sign appropriately...  Doesn't matter which one we use, 
															//		they both have the same sign
															//	Do the sign last, on the off-chance there was an overflow...  
		end												//		Not doing any error checking on this...
	//	one of them is negative...
	else if(a[N-1] == 0 && b[N-1] == 1) begin		//	subtract a-b
		if( a[N-2:0] > b[N-2:0] ) begin					//	if a is greater than b,
			res[N-2:0] = a[N-2:0] - b[N-2:0];			//		then just subtract b from a
			res[N-1] = 0;										//		and manually set the sign to positive
			end
		else begin												//	if a is less than b,
			res[N-2:0] = b[N-2:0] - a[N-2:0];			//		we'll actually subtract a from b to avoid a 2's complement answer
			if (res[N-2:0] == 0)
				res[N-1] = 0;										//		I don't like negative zero....
			else
				res[N-1] = 1;										//		and manually set the sign to negative
			end
		end
	else begin												//	subtract b-a (a negative, b positive)
		if( a[N-2:0] > b[N-2:0] ) begin					//	if a is greater than b,
			res[N-2:0] = a[N-2:0] - b[N-2:0];			//		we'll actually subtract b from a to avoid a 2's complement answer
			if (res[N-2:0] == 0)
				res[N-1] = 0;										//		I don't like negative zero....
			else
				res[N-1] = 1;										//		and manually set the sign to negative
			end
		else begin												//	if a is less than b,
			res[N-2:0] = b[N-2:0] - a[N-2:0];			//		then just subtract a from b
			res[N-1] = 0;										//		and manually set the sign to positive
			end
		end
	end
endmodule

module qmult #(parameter Q=15, N=32)
	(i_multiplicand,i_multiplier,o_result,ovr);
	 input	[N-1:0]	i_multiplicand;
	 input	[N-1:0]	i_multiplier;
	 output	[N-1:0]	o_result;
	 //	The underlying assumption, here, is that both fixed-point values are of the same length (N,Q)
	 //		Because of this, the results will be of length N+N = 2N bits....
	 //		This also simplifies the hand-back of results, as the binimal point 
	 //		will always be in the same location...
	output reg ovr;
	wire [2*N-1:0] r_result;		//	Multiplication by 2 values of N bits requires a register that is N+N = 2N deep...
	wire [N-1:0] r_RetVal;
	
//--------------------------------------------------------------------------------
	assign o_result = r_RetVal;	//Only handing back the same number of bits as we received...with fixed point in same location...
	assign r_RetVal[N-1] = i_multiplicand[N-1] ^ i_multiplier[N-1];
	assign r_RetVal[N-2:0] = r_result[N-2+Q:Q];
//---------------------------------------------------------------------------------

        always @(r_result) begin	
		if (r_result[2*N-2:N-1+Q] > 0)	
			ovr = 1'b1;
		else
			ovr = 1'b0;
		
	end

	Multiplier_31_0_3000 mul0 (r_result, {1'b0,i_multiplicand[N-2:0]}, {1'b0,i_multiplier[N-2:0]});
	

endmodule

/*----------------------------------------------------------------------------
  Copyright (c) 2004 Aoki laboratory. All rights reserved.

  Top module: Multiplier_31_0_3000

  Number system: 2's complement
  Multiplicand length: 32
  Multiplier length: 32
  Partial product generation: Simple PPG
  Partial product accumulation: Wallace tree
  Final stage addition: Kogge-Stone adder
----------------------------------------------------------------------------*/

module TCDECON_31_0(TOP, R, I);
  output [30:0] R;
  output [31:31] TOP;
  input [31:0] I;
  assign TOP[31] = I[31];
  assign R[0] = I[0];
  assign R[1] = I[1];
  assign R[2] = I[2];
  assign R[3] = I[3];
  assign R[4] = I[4];
  assign R[5] = I[5];
  assign R[6] = I[6];
  assign R[7] = I[7];
  assign R[8] = I[8];
  assign R[9] = I[9];
  assign R[10] = I[10];
  assign R[11] = I[11];
  assign R[12] = I[12];
  assign R[13] = I[13];
  assign R[14] = I[14];
  assign R[15] = I[15];
  assign R[16] = I[16];
  assign R[17] = I[17];
  assign R[18] = I[18];
  assign R[19] = I[19];
  assign R[20] = I[20];
  assign R[21] = I[21];
  assign R[22] = I[22];
  assign R[23] = I[23];
  assign R[24] = I[24];
  assign R[25] = I[25];
  assign R[26] = I[26];
  assign R[27] = I[27];
  assign R[28] = I[28];
  assign R[29] = I[29];
  assign R[30] = I[30];
endmodule

module UB1BPPG_0_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_0(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_31(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_1(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_32(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_2(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_33(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_3(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_34(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_4(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_35(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_5(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_36(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_6(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_37(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_7(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_38(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_8(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_39(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_9(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_40(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_10(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_41(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_11(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_42(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_12(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_43(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_13(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_44(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_14(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_45(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_15(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_46(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_16(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_47(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_17(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_48(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_18(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_49(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_19(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_50(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_20(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_51(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_21(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_52(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_22(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_53(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_23(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_54(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_24(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_55(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_25(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_56(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_26(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_57(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_27(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_58(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_28(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_59(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_29(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_60(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UB1BPPG_0_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_1_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_2_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_3_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_4_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_5_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_6_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_7_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_8_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_9_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_10_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_11_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_12_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_13_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_14_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_15_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_16_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_17_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_18_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_19_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_20_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_21_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_22_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_23_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_24_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_25_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_26_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_27_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_28_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_29_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UB1BPPG_30_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NU1BPPG_31_30(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUBUB1CON_61(O, I);
  output O;
  input I;
  assign O = ~ I;
endmodule

module UN1BPPG_0_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_1_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_2_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_3_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_4_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_5_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_6_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_7_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_8_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_9_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_10_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_11_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_12_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_13_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_14_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_15_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_16_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_17_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_18_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_19_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_20_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_21_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_22_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_23_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_24_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_25_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_26_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_27_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_28_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_29_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UN1BPPG_30_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module NUB1BPPG_31_31(O, IN1, IN2);
  output O;
  input IN1;
  input IN2;
  assign O = IN1 & IN2;
endmodule

module UBOne_32(O);
  output O;
  assign O = 1;
endmodule

module UB1DCON_32(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_0(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_1(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_2(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_3(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_4(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_5(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_6(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_7(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_8(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_9(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_10(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_11(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_12(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_13(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_14(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_15(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_16(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_17(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_18(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_19(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_20(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_21(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_22(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_23(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_24(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_25(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_26(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_27(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_28(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_29(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_30(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_31(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_1(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_2(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_3(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_4(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_5(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_6(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_7(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_8(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_9(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_10(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_11(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_12(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_13(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_14(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_15(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_16(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_17(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_18(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_19(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_20(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_21(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_22(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_23(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_24(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_25(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_26(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_27(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_28(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_29(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_30(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_31(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_32(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UB1DCON_33(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_4(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_33(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_34(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_35(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_36(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_7(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_35(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_36(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_37(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_38(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_39(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_10(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_38(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_39(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_40(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_41(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_42(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_2(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_34(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_35(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_6(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_37(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_39(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_11(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_41(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_42(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UB1DCON_43(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_14(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_43(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_44(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_45(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_46(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_17(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_45(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_46(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_47(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_48(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_49(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_20(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_48(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_49(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_50(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_51(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_52(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_23(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_51(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_52(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_53(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_54(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_55(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_26(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_54(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_55(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_56(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_57(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_58(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_29(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_57(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_58(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_59(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_60(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_61(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_3(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_36(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_37(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_38(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_9(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_42(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_43(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_15(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_47(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_48(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_19(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_50(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_52(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_24(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_56(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_57(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_28(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_59(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_61(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_5(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_40(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_41(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_13(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_46(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_47(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_21(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_53(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_54(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_27(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_58(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_62(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_8(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_44(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_45(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_18(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_49(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_30(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBFA_60(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_61(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBFA_62(C, S, X, Y, Z);
  output C;
  output S;
  input X;
  input Y;
  input Z;
  assign C = ( X & Y ) | ( Y & Z ) | ( Z & X );
  assign S = X ^ Y ^ Z;
endmodule

module UBHA_12(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_50(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_51(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_53(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_25(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_56(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_62(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_63(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_16(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_55(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UB1DCON_59(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UB1DCON_60(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBHA_22(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBHA_63(C, S, X, Y);
  output C;
  output S;
  input X;
  input Y;
  assign C = X & Y;
  assign S = X ^ Y;
endmodule

module UBZero_64_64(O);
  output [64:64] O;
  assign O[64] = 0;
endmodule

module GPGenerator(Go, Po, A, B);
  output Go;
  output Po;
  input A;
  input B;
  assign Go = A & B;
  assign Po = A ^ B;
endmodule

module CarryOperator(Go, Po, Gi1, Pi1, Gi2, Pi2);
  output Go;
  output Po;
  input Gi1;
  input Gi2;
  input Pi1;
  input Pi2;
  assign Go = Gi1 | ( Gi2 & Pi1 );
  assign Po = Pi1 & Pi2;
endmodule

module UBPriKSA_64_9(S, X, Y, Cin);
  output [65:9] S;
  input Cin;
  input [64:9] X;
  input [64:9] Y;
  wire [64:9] G0;
  wire [64:9] G1;
  wire [64:9] G2;
  wire [64:9] G3;
  wire [64:9] G4;
  wire [64:9] G5;
  wire [64:9] G6;
  wire [64:9] P0;
  wire [64:9] P1;
  wire [64:9] P2;
  wire [64:9] P3;
  wire [64:9] P4;
  wire [64:9] P5;
  wire [64:9] P6;
  assign P1[9] = P0[9];
  assign G1[9] = G0[9];
  assign P2[9] = P1[9];
  assign G2[9] = G1[9];
  assign P2[10] = P1[10];
  assign G2[10] = G1[10];
  assign P3[9] = P2[9];
  assign G3[9] = G2[9];
  assign P3[10] = P2[10];
  assign G3[10] = G2[10];
  assign P3[11] = P2[11];
  assign G3[11] = G2[11];
  assign P3[12] = P2[12];
  assign G3[12] = G2[12];
  assign P4[9] = P3[9];
  assign G4[9] = G3[9];
  assign P4[10] = P3[10];
  assign G4[10] = G3[10];
  assign P4[11] = P3[11];
  assign G4[11] = G3[11];
  assign P4[12] = P3[12];
  assign G4[12] = G3[12];
  assign P4[13] = P3[13];
  assign G4[13] = G3[13];
  assign P4[14] = P3[14];
  assign G4[14] = G3[14];
  assign P4[15] = P3[15];
  assign G4[15] = G3[15];
  assign P4[16] = P3[16];
  assign G4[16] = G3[16];
  assign P5[9] = P4[9];
  assign G5[9] = G4[9];
  assign P5[10] = P4[10];
  assign G5[10] = G4[10];
  assign P5[11] = P4[11];
  assign G5[11] = G4[11];
  assign P5[12] = P4[12];
  assign G5[12] = G4[12];
  assign P5[13] = P4[13];
  assign G5[13] = G4[13];
  assign P5[14] = P4[14];
  assign G5[14] = G4[14];
  assign P5[15] = P4[15];
  assign G5[15] = G4[15];
  assign P5[16] = P4[16];
  assign G5[16] = G4[16];
  assign P5[17] = P4[17];
  assign G5[17] = G4[17];
  assign P5[18] = P4[18];
  assign G5[18] = G4[18];
  assign P5[19] = P4[19];
  assign G5[19] = G4[19];
  assign P5[20] = P4[20];
  assign G5[20] = G4[20];
  assign P5[21] = P4[21];
  assign G5[21] = G4[21];
  assign P5[22] = P4[22];
  assign G5[22] = G4[22];
  assign P5[23] = P4[23];
  assign G5[23] = G4[23];
  assign P5[24] = P4[24];
  assign G5[24] = G4[24];
  assign P6[9] = P5[9];
  assign G6[9] = G5[9];
  assign P6[10] = P5[10];
  assign G6[10] = G5[10];
  assign P6[11] = P5[11];
  assign G6[11] = G5[11];
  assign P6[12] = P5[12];
  assign G6[12] = G5[12];
  assign P6[13] = P5[13];
  assign G6[13] = G5[13];
  assign P6[14] = P5[14];
  assign G6[14] = G5[14];
  assign P6[15] = P5[15];
  assign G6[15] = G5[15];
  assign P6[16] = P5[16];
  assign G6[16] = G5[16];
  assign P6[17] = P5[17];
  assign G6[17] = G5[17];
  assign P6[18] = P5[18];
  assign G6[18] = G5[18];
  assign P6[19] = P5[19];
  assign G6[19] = G5[19];
  assign P6[20] = P5[20];
  assign G6[20] = G5[20];
  assign P6[21] = P5[21];
  assign G6[21] = G5[21];
  assign P6[22] = P5[22];
  assign G6[22] = G5[22];
  assign P6[23] = P5[23];
  assign G6[23] = G5[23];
  assign P6[24] = P5[24];
  assign G6[24] = G5[24];
  assign P6[25] = P5[25];
  assign G6[25] = G5[25];
  assign P6[26] = P5[26];
  assign G6[26] = G5[26];
  assign P6[27] = P5[27];
  assign G6[27] = G5[27];
  assign P6[28] = P5[28];
  assign G6[28] = G5[28];
  assign P6[29] = P5[29];
  assign G6[29] = G5[29];
  assign P6[30] = P5[30];
  assign G6[30] = G5[30];
  assign P6[31] = P5[31];
  assign G6[31] = G5[31];
  assign P6[32] = P5[32];
  assign G6[32] = G5[32];
  assign P6[33] = P5[33];
  assign G6[33] = G5[33];
  assign P6[34] = P5[34];
  assign G6[34] = G5[34];
  assign P6[35] = P5[35];
  assign G6[35] = G5[35];
  assign P6[36] = P5[36];
  assign G6[36] = G5[36];
  assign P6[37] = P5[37];
  assign G6[37] = G5[37];
  assign P6[38] = P5[38];
  assign G6[38] = G5[38];
  assign P6[39] = P5[39];
  assign G6[39] = G5[39];
  assign P6[40] = P5[40];
  assign G6[40] = G5[40];
  assign S[9] = Cin ^ P0[9];
  assign S[10] = ( G6[9] | ( P6[9] & Cin ) ) ^ P0[10];
  assign S[11] = ( G6[10] | ( P6[10] & Cin ) ) ^ P0[11];
  assign S[12] = ( G6[11] | ( P6[11] & Cin ) ) ^ P0[12];
  assign S[13] = ( G6[12] | ( P6[12] & Cin ) ) ^ P0[13];
  assign S[14] = ( G6[13] | ( P6[13] & Cin ) ) ^ P0[14];
  assign S[15] = ( G6[14] | ( P6[14] & Cin ) ) ^ P0[15];
  assign S[16] = ( G6[15] | ( P6[15] & Cin ) ) ^ P0[16];
  assign S[17] = ( G6[16] | ( P6[16] & Cin ) ) ^ P0[17];
  assign S[18] = ( G6[17] | ( P6[17] & Cin ) ) ^ P0[18];
  assign S[19] = ( G6[18] | ( P6[18] & Cin ) ) ^ P0[19];
  assign S[20] = ( G6[19] | ( P6[19] & Cin ) ) ^ P0[20];
  assign S[21] = ( G6[20] | ( P6[20] & Cin ) ) ^ P0[21];
  assign S[22] = ( G6[21] | ( P6[21] & Cin ) ) ^ P0[22];
  assign S[23] = ( G6[22] | ( P6[22] & Cin ) ) ^ P0[23];
  assign S[24] = ( G6[23] | ( P6[23] & Cin ) ) ^ P0[24];
  assign S[25] = ( G6[24] | ( P6[24] & Cin ) ) ^ P0[25];
  assign S[26] = ( G6[25] | ( P6[25] & Cin ) ) ^ P0[26];
  assign S[27] = ( G6[26] | ( P6[26] & Cin ) ) ^ P0[27];
  assign S[28] = ( G6[27] | ( P6[27] & Cin ) ) ^ P0[28];
  assign S[29] = ( G6[28] | ( P6[28] & Cin ) ) ^ P0[29];
  assign S[30] = ( G6[29] | ( P6[29] & Cin ) ) ^ P0[30];
  assign S[31] = ( G6[30] | ( P6[30] & Cin ) ) ^ P0[31];
  assign S[32] = ( G6[31] | ( P6[31] & Cin ) ) ^ P0[32];
  assign S[33] = ( G6[32] | ( P6[32] & Cin ) ) ^ P0[33];
  assign S[34] = ( G6[33] | ( P6[33] & Cin ) ) ^ P0[34];
  assign S[35] = ( G6[34] | ( P6[34] & Cin ) ) ^ P0[35];
  assign S[36] = ( G6[35] | ( P6[35] & Cin ) ) ^ P0[36];
  assign S[37] = ( G6[36] | ( P6[36] & Cin ) ) ^ P0[37];
  assign S[38] = ( G6[37] | ( P6[37] & Cin ) ) ^ P0[38];
  assign S[39] = ( G6[38] | ( P6[38] & Cin ) ) ^ P0[39];
  assign S[40] = ( G6[39] | ( P6[39] & Cin ) ) ^ P0[40];
  assign S[41] = ( G6[40] | ( P6[40] & Cin ) ) ^ P0[41];
  assign S[42] = ( G6[41] | ( P6[41] & Cin ) ) ^ P0[42];
  assign S[43] = ( G6[42] | ( P6[42] & Cin ) ) ^ P0[43];
  assign S[44] = ( G6[43] | ( P6[43] & Cin ) ) ^ P0[44];
  assign S[45] = ( G6[44] | ( P6[44] & Cin ) ) ^ P0[45];
  assign S[46] = ( G6[45] | ( P6[45] & Cin ) ) ^ P0[46];
  assign S[47] = ( G6[46] | ( P6[46] & Cin ) ) ^ P0[47];
  assign S[48] = ( G6[47] | ( P6[47] & Cin ) ) ^ P0[48];
  assign S[49] = ( G6[48] | ( P6[48] & Cin ) ) ^ P0[49];
  assign S[50] = ( G6[49] | ( P6[49] & Cin ) ) ^ P0[50];
  assign S[51] = ( G6[50] | ( P6[50] & Cin ) ) ^ P0[51];
  assign S[52] = ( G6[51] | ( P6[51] & Cin ) ) ^ P0[52];
  assign S[53] = ( G6[52] | ( P6[52] & Cin ) ) ^ P0[53];
  assign S[54] = ( G6[53] | ( P6[53] & Cin ) ) ^ P0[54];
  assign S[55] = ( G6[54] | ( P6[54] & Cin ) ) ^ P0[55];
  assign S[56] = ( G6[55] | ( P6[55] & Cin ) ) ^ P0[56];
  assign S[57] = ( G6[56] | ( P6[56] & Cin ) ) ^ P0[57];
  assign S[58] = ( G6[57] | ( P6[57] & Cin ) ) ^ P0[58];
  assign S[59] = ( G6[58] | ( P6[58] & Cin ) ) ^ P0[59];
  assign S[60] = ( G6[59] | ( P6[59] & Cin ) ) ^ P0[60];
  assign S[61] = ( G6[60] | ( P6[60] & Cin ) ) ^ P0[61];
  assign S[62] = ( G6[61] | ( P6[61] & Cin ) ) ^ P0[62];
  assign S[63] = ( G6[62] | ( P6[62] & Cin ) ) ^ P0[63];
  assign S[64] = ( G6[63] | ( P6[63] & Cin ) ) ^ P0[64];
  assign S[65] = G6[64] | ( P6[64] & Cin );
  GPGenerator U0 (G0[9], P0[9], X[9], Y[9]);
  GPGenerator U1 (G0[10], P0[10], X[10], Y[10]);
  GPGenerator U2 (G0[11], P0[11], X[11], Y[11]);
  GPGenerator U3 (G0[12], P0[12], X[12], Y[12]);
  GPGenerator U4 (G0[13], P0[13], X[13], Y[13]);
  GPGenerator U5 (G0[14], P0[14], X[14], Y[14]);
  GPGenerator U6 (G0[15], P0[15], X[15], Y[15]);
  GPGenerator U7 (G0[16], P0[16], X[16], Y[16]);
  GPGenerator U8 (G0[17], P0[17], X[17], Y[17]);
  GPGenerator U9 (G0[18], P0[18], X[18], Y[18]);
  GPGenerator U10 (G0[19], P0[19], X[19], Y[19]);
  GPGenerator U11 (G0[20], P0[20], X[20], Y[20]);
  GPGenerator U12 (G0[21], P0[21], X[21], Y[21]);
  GPGenerator U13 (G0[22], P0[22], X[22], Y[22]);
  GPGenerator U14 (G0[23], P0[23], X[23], Y[23]);
  GPGenerator U15 (G0[24], P0[24], X[24], Y[24]);
  GPGenerator U16 (G0[25], P0[25], X[25], Y[25]);
  GPGenerator U17 (G0[26], P0[26], X[26], Y[26]);
  GPGenerator U18 (G0[27], P0[27], X[27], Y[27]);
  GPGenerator U19 (G0[28], P0[28], X[28], Y[28]);
  GPGenerator U20 (G0[29], P0[29], X[29], Y[29]);
  GPGenerator U21 (G0[30], P0[30], X[30], Y[30]);
  GPGenerator U22 (G0[31], P0[31], X[31], Y[31]);
  GPGenerator U23 (G0[32], P0[32], X[32], Y[32]);
  GPGenerator U24 (G0[33], P0[33], X[33], Y[33]);
  GPGenerator U25 (G0[34], P0[34], X[34], Y[34]);
  GPGenerator U26 (G0[35], P0[35], X[35], Y[35]);
  GPGenerator U27 (G0[36], P0[36], X[36], Y[36]);
  GPGenerator U28 (G0[37], P0[37], X[37], Y[37]);
  GPGenerator U29 (G0[38], P0[38], X[38], Y[38]);
  GPGenerator U30 (G0[39], P0[39], X[39], Y[39]);
  GPGenerator U31 (G0[40], P0[40], X[40], Y[40]);
  GPGenerator U32 (G0[41], P0[41], X[41], Y[41]);
  GPGenerator U33 (G0[42], P0[42], X[42], Y[42]);
  GPGenerator U34 (G0[43], P0[43], X[43], Y[43]);
  GPGenerator U35 (G0[44], P0[44], X[44], Y[44]);
  GPGenerator U36 (G0[45], P0[45], X[45], Y[45]);
  GPGenerator U37 (G0[46], P0[46], X[46], Y[46]);
  GPGenerator U38 (G0[47], P0[47], X[47], Y[47]);
  GPGenerator U39 (G0[48], P0[48], X[48], Y[48]);
  GPGenerator U40 (G0[49], P0[49], X[49], Y[49]);
  GPGenerator U41 (G0[50], P0[50], X[50], Y[50]);
  GPGenerator U42 (G0[51], P0[51], X[51], Y[51]);
  GPGenerator U43 (G0[52], P0[52], X[52], Y[52]);
  GPGenerator U44 (G0[53], P0[53], X[53], Y[53]);
  GPGenerator U45 (G0[54], P0[54], X[54], Y[54]);
  GPGenerator U46 (G0[55], P0[55], X[55], Y[55]);
  GPGenerator U47 (G0[56], P0[56], X[56], Y[56]);
  GPGenerator U48 (G0[57], P0[57], X[57], Y[57]);
  GPGenerator U49 (G0[58], P0[58], X[58], Y[58]);
  GPGenerator U50 (G0[59], P0[59], X[59], Y[59]);
  GPGenerator U51 (G0[60], P0[60], X[60], Y[60]);
  GPGenerator U52 (G0[61], P0[61], X[61], Y[61]);
  GPGenerator U53 (G0[62], P0[62], X[62], Y[62]);
  GPGenerator U54 (G0[63], P0[63], X[63], Y[63]);
  GPGenerator U55 (G0[64], P0[64], X[64], Y[64]);
  CarryOperator U56 (G1[10], P1[10], G0[10], P0[10], G0[9], P0[9]);
  CarryOperator U57 (G1[11], P1[11], G0[11], P0[11], G0[10], P0[10]);
  CarryOperator U58 (G1[12], P1[12], G0[12], P0[12], G0[11], P0[11]);
  CarryOperator U59 (G1[13], P1[13], G0[13], P0[13], G0[12], P0[12]);
  CarryOperator U60 (G1[14], P1[14], G0[14], P0[14], G0[13], P0[13]);
  CarryOperator U61 (G1[15], P1[15], G0[15], P0[15], G0[14], P0[14]);
  CarryOperator U62 (G1[16], P1[16], G0[16], P0[16], G0[15], P0[15]);
  CarryOperator U63 (G1[17], P1[17], G0[17], P0[17], G0[16], P0[16]);
  CarryOperator U64 (G1[18], P1[18], G0[18], P0[18], G0[17], P0[17]);
  CarryOperator U65 (G1[19], P1[19], G0[19], P0[19], G0[18], P0[18]);
  CarryOperator U66 (G1[20], P1[20], G0[20], P0[20], G0[19], P0[19]);
  CarryOperator U67 (G1[21], P1[21], G0[21], P0[21], G0[20], P0[20]);
  CarryOperator U68 (G1[22], P1[22], G0[22], P0[22], G0[21], P0[21]);
  CarryOperator U69 (G1[23], P1[23], G0[23], P0[23], G0[22], P0[22]);
  CarryOperator U70 (G1[24], P1[24], G0[24], P0[24], G0[23], P0[23]);
  CarryOperator U71 (G1[25], P1[25], G0[25], P0[25], G0[24], P0[24]);
  CarryOperator U72 (G1[26], P1[26], G0[26], P0[26], G0[25], P0[25]);
  CarryOperator U73 (G1[27], P1[27], G0[27], P0[27], G0[26], P0[26]);
  CarryOperator U74 (G1[28], P1[28], G0[28], P0[28], G0[27], P0[27]);
  CarryOperator U75 (G1[29], P1[29], G0[29], P0[29], G0[28], P0[28]);
  CarryOperator U76 (G1[30], P1[30], G0[30], P0[30], G0[29], P0[29]);
  CarryOperator U77 (G1[31], P1[31], G0[31], P0[31], G0[30], P0[30]);
  CarryOperator U78 (G1[32], P1[32], G0[32], P0[32], G0[31], P0[31]);
  CarryOperator U79 (G1[33], P1[33], G0[33], P0[33], G0[32], P0[32]);
  CarryOperator U80 (G1[34], P1[34], G0[34], P0[34], G0[33], P0[33]);
  CarryOperator U81 (G1[35], P1[35], G0[35], P0[35], G0[34], P0[34]);
  CarryOperator U82 (G1[36], P1[36], G0[36], P0[36], G0[35], P0[35]);
  CarryOperator U83 (G1[37], P1[37], G0[37], P0[37], G0[36], P0[36]);
  CarryOperator U84 (G1[38], P1[38], G0[38], P0[38], G0[37], P0[37]);
  CarryOperator U85 (G1[39], P1[39], G0[39], P0[39], G0[38], P0[38]);
  CarryOperator U86 (G1[40], P1[40], G0[40], P0[40], G0[39], P0[39]);
  CarryOperator U87 (G1[41], P1[41], G0[41], P0[41], G0[40], P0[40]);
  CarryOperator U88 (G1[42], P1[42], G0[42], P0[42], G0[41], P0[41]);
  CarryOperator U89 (G1[43], P1[43], G0[43], P0[43], G0[42], P0[42]);
  CarryOperator U90 (G1[44], P1[44], G0[44], P0[44], G0[43], P0[43]);
  CarryOperator U91 (G1[45], P1[45], G0[45], P0[45], G0[44], P0[44]);
  CarryOperator U92 (G1[46], P1[46], G0[46], P0[46], G0[45], P0[45]);
  CarryOperator U93 (G1[47], P1[47], G0[47], P0[47], G0[46], P0[46]);
  CarryOperator U94 (G1[48], P1[48], G0[48], P0[48], G0[47], P0[47]);
  CarryOperator U95 (G1[49], P1[49], G0[49], P0[49], G0[48], P0[48]);
  CarryOperator U96 (G1[50], P1[50], G0[50], P0[50], G0[49], P0[49]);
  CarryOperator U97 (G1[51], P1[51], G0[51], P0[51], G0[50], P0[50]);
  CarryOperator U98 (G1[52], P1[52], G0[52], P0[52], G0[51], P0[51]);
  CarryOperator U99 (G1[53], P1[53], G0[53], P0[53], G0[52], P0[52]);
  CarryOperator U100 (G1[54], P1[54], G0[54], P0[54], G0[53], P0[53]);
  CarryOperator U101 (G1[55], P1[55], G0[55], P0[55], G0[54], P0[54]);
  CarryOperator U102 (G1[56], P1[56], G0[56], P0[56], G0[55], P0[55]);
  CarryOperator U103 (G1[57], P1[57], G0[57], P0[57], G0[56], P0[56]);
  CarryOperator U104 (G1[58], P1[58], G0[58], P0[58], G0[57], P0[57]);
  CarryOperator U105 (G1[59], P1[59], G0[59], P0[59], G0[58], P0[58]);
  CarryOperator U106 (G1[60], P1[60], G0[60], P0[60], G0[59], P0[59]);
  CarryOperator U107 (G1[61], P1[61], G0[61], P0[61], G0[60], P0[60]);
  CarryOperator U108 (G1[62], P1[62], G0[62], P0[62], G0[61], P0[61]);
  CarryOperator U109 (G1[63], P1[63], G0[63], P0[63], G0[62], P0[62]);
  CarryOperator U110 (G1[64], P1[64], G0[64], P0[64], G0[63], P0[63]);
  CarryOperator U111 (G2[11], P2[11], G1[11], P1[11], G1[9], P1[9]);
  CarryOperator U112 (G2[12], P2[12], G1[12], P1[12], G1[10], P1[10]);
  CarryOperator U113 (G2[13], P2[13], G1[13], P1[13], G1[11], P1[11]);
  CarryOperator U114 (G2[14], P2[14], G1[14], P1[14], G1[12], P1[12]);
  CarryOperator U115 (G2[15], P2[15], G1[15], P1[15], G1[13], P1[13]);
  CarryOperator U116 (G2[16], P2[16], G1[16], P1[16], G1[14], P1[14]);
  CarryOperator U117 (G2[17], P2[17], G1[17], P1[17], G1[15], P1[15]);
  CarryOperator U118 (G2[18], P2[18], G1[18], P1[18], G1[16], P1[16]);
  CarryOperator U119 (G2[19], P2[19], G1[19], P1[19], G1[17], P1[17]);
  CarryOperator U120 (G2[20], P2[20], G1[20], P1[20], G1[18], P1[18]);
  CarryOperator U121 (G2[21], P2[21], G1[21], P1[21], G1[19], P1[19]);
  CarryOperator U122 (G2[22], P2[22], G1[22], P1[22], G1[20], P1[20]);
  CarryOperator U123 (G2[23], P2[23], G1[23], P1[23], G1[21], P1[21]);
  CarryOperator U124 (G2[24], P2[24], G1[24], P1[24], G1[22], P1[22]);
  CarryOperator U125 (G2[25], P2[25], G1[25], P1[25], G1[23], P1[23]);
  CarryOperator U126 (G2[26], P2[26], G1[26], P1[26], G1[24], P1[24]);
  CarryOperator U127 (G2[27], P2[27], G1[27], P1[27], G1[25], P1[25]);
  CarryOperator U128 (G2[28], P2[28], G1[28], P1[28], G1[26], P1[26]);
  CarryOperator U129 (G2[29], P2[29], G1[29], P1[29], G1[27], P1[27]);
  CarryOperator U130 (G2[30], P2[30], G1[30], P1[30], G1[28], P1[28]);
  CarryOperator U131 (G2[31], P2[31], G1[31], P1[31], G1[29], P1[29]);
  CarryOperator U132 (G2[32], P2[32], G1[32], P1[32], G1[30], P1[30]);
  CarryOperator U133 (G2[33], P2[33], G1[33], P1[33], G1[31], P1[31]);
  CarryOperator U134 (G2[34], P2[34], G1[34], P1[34], G1[32], P1[32]);
  CarryOperator U135 (G2[35], P2[35], G1[35], P1[35], G1[33], P1[33]);
  CarryOperator U136 (G2[36], P2[36], G1[36], P1[36], G1[34], P1[34]);
  CarryOperator U137 (G2[37], P2[37], G1[37], P1[37], G1[35], P1[35]);
  CarryOperator U138 (G2[38], P2[38], G1[38], P1[38], G1[36], P1[36]);
  CarryOperator U139 (G2[39], P2[39], G1[39], P1[39], G1[37], P1[37]);
  CarryOperator U140 (G2[40], P2[40], G1[40], P1[40], G1[38], P1[38]);
  CarryOperator U141 (G2[41], P2[41], G1[41], P1[41], G1[39], P1[39]);
  CarryOperator U142 (G2[42], P2[42], G1[42], P1[42], G1[40], P1[40]);
  CarryOperator U143 (G2[43], P2[43], G1[43], P1[43], G1[41], P1[41]);
  CarryOperator U144 (G2[44], P2[44], G1[44], P1[44], G1[42], P1[42]);
  CarryOperator U145 (G2[45], P2[45], G1[45], P1[45], G1[43], P1[43]);
  CarryOperator U146 (G2[46], P2[46], G1[46], P1[46], G1[44], P1[44]);
  CarryOperator U147 (G2[47], P2[47], G1[47], P1[47], G1[45], P1[45]);
  CarryOperator U148 (G2[48], P2[48], G1[48], P1[48], G1[46], P1[46]);
  CarryOperator U149 (G2[49], P2[49], G1[49], P1[49], G1[47], P1[47]);
  CarryOperator U150 (G2[50], P2[50], G1[50], P1[50], G1[48], P1[48]);
  CarryOperator U151 (G2[51], P2[51], G1[51], P1[51], G1[49], P1[49]);
  CarryOperator U152 (G2[52], P2[52], G1[52], P1[52], G1[50], P1[50]);
  CarryOperator U153 (G2[53], P2[53], G1[53], P1[53], G1[51], P1[51]);
  CarryOperator U154 (G2[54], P2[54], G1[54], P1[54], G1[52], P1[52]);
  CarryOperator U155 (G2[55], P2[55], G1[55], P1[55], G1[53], P1[53]);
  CarryOperator U156 (G2[56], P2[56], G1[56], P1[56], G1[54], P1[54]);
  CarryOperator U157 (G2[57], P2[57], G1[57], P1[57], G1[55], P1[55]);
  CarryOperator U158 (G2[58], P2[58], G1[58], P1[58], G1[56], P1[56]);
  CarryOperator U159 (G2[59], P2[59], G1[59], P1[59], G1[57], P1[57]);
  CarryOperator U160 (G2[60], P2[60], G1[60], P1[60], G1[58], P1[58]);
  CarryOperator U161 (G2[61], P2[61], G1[61], P1[61], G1[59], P1[59]);
  CarryOperator U162 (G2[62], P2[62], G1[62], P1[62], G1[60], P1[60]);
  CarryOperator U163 (G2[63], P2[63], G1[63], P1[63], G1[61], P1[61]);
  CarryOperator U164 (G2[64], P2[64], G1[64], P1[64], G1[62], P1[62]);
  CarryOperator U165 (G3[13], P3[13], G2[13], P2[13], G2[9], P2[9]);
  CarryOperator U166 (G3[14], P3[14], G2[14], P2[14], G2[10], P2[10]);
  CarryOperator U167 (G3[15], P3[15], G2[15], P2[15], G2[11], P2[11]);
  CarryOperator U168 (G3[16], P3[16], G2[16], P2[16], G2[12], P2[12]);
  CarryOperator U169 (G3[17], P3[17], G2[17], P2[17], G2[13], P2[13]);
  CarryOperator U170 (G3[18], P3[18], G2[18], P2[18], G2[14], P2[14]);
  CarryOperator U171 (G3[19], P3[19], G2[19], P2[19], G2[15], P2[15]);
  CarryOperator U172 (G3[20], P3[20], G2[20], P2[20], G2[16], P2[16]);
  CarryOperator U173 (G3[21], P3[21], G2[21], P2[21], G2[17], P2[17]);
  CarryOperator U174 (G3[22], P3[22], G2[22], P2[22], G2[18], P2[18]);
  CarryOperator U175 (G3[23], P3[23], G2[23], P2[23], G2[19], P2[19]);
  CarryOperator U176 (G3[24], P3[24], G2[24], P2[24], G2[20], P2[20]);
  CarryOperator U177 (G3[25], P3[25], G2[25], P2[25], G2[21], P2[21]);
  CarryOperator U178 (G3[26], P3[26], G2[26], P2[26], G2[22], P2[22]);
  CarryOperator U179 (G3[27], P3[27], G2[27], P2[27], G2[23], P2[23]);
  CarryOperator U180 (G3[28], P3[28], G2[28], P2[28], G2[24], P2[24]);
  CarryOperator U181 (G3[29], P3[29], G2[29], P2[29], G2[25], P2[25]);
  CarryOperator U182 (G3[30], P3[30], G2[30], P2[30], G2[26], P2[26]);
  CarryOperator U183 (G3[31], P3[31], G2[31], P2[31], G2[27], P2[27]);
  CarryOperator U184 (G3[32], P3[32], G2[32], P2[32], G2[28], P2[28]);
  CarryOperator U185 (G3[33], P3[33], G2[33], P2[33], G2[29], P2[29]);
  CarryOperator U186 (G3[34], P3[34], G2[34], P2[34], G2[30], P2[30]);
  CarryOperator U187 (G3[35], P3[35], G2[35], P2[35], G2[31], P2[31]);
  CarryOperator U188 (G3[36], P3[36], G2[36], P2[36], G2[32], P2[32]);
  CarryOperator U189 (G3[37], P3[37], G2[37], P2[37], G2[33], P2[33]);
  CarryOperator U190 (G3[38], P3[38], G2[38], P2[38], G2[34], P2[34]);
  CarryOperator U191 (G3[39], P3[39], G2[39], P2[39], G2[35], P2[35]);
  CarryOperator U192 (G3[40], P3[40], G2[40], P2[40], G2[36], P2[36]);
  CarryOperator U193 (G3[41], P3[41], G2[41], P2[41], G2[37], P2[37]);
  CarryOperator U194 (G3[42], P3[42], G2[42], P2[42], G2[38], P2[38]);
  CarryOperator U195 (G3[43], P3[43], G2[43], P2[43], G2[39], P2[39]);
  CarryOperator U196 (G3[44], P3[44], G2[44], P2[44], G2[40], P2[40]);
  CarryOperator U197 (G3[45], P3[45], G2[45], P2[45], G2[41], P2[41]);
  CarryOperator U198 (G3[46], P3[46], G2[46], P2[46], G2[42], P2[42]);
  CarryOperator U199 (G3[47], P3[47], G2[47], P2[47], G2[43], P2[43]);
  CarryOperator U200 (G3[48], P3[48], G2[48], P2[48], G2[44], P2[44]);
  CarryOperator U201 (G3[49], P3[49], G2[49], P2[49], G2[45], P2[45]);
  CarryOperator U202 (G3[50], P3[50], G2[50], P2[50], G2[46], P2[46]);
  CarryOperator U203 (G3[51], P3[51], G2[51], P2[51], G2[47], P2[47]);
  CarryOperator U204 (G3[52], P3[52], G2[52], P2[52], G2[48], P2[48]);
  CarryOperator U205 (G3[53], P3[53], G2[53], P2[53], G2[49], P2[49]);
  CarryOperator U206 (G3[54], P3[54], G2[54], P2[54], G2[50], P2[50]);
  CarryOperator U207 (G3[55], P3[55], G2[55], P2[55], G2[51], P2[51]);
  CarryOperator U208 (G3[56], P3[56], G2[56], P2[56], G2[52], P2[52]);
  CarryOperator U209 (G3[57], P3[57], G2[57], P2[57], G2[53], P2[53]);
  CarryOperator U210 (G3[58], P3[58], G2[58], P2[58], G2[54], P2[54]);
  CarryOperator U211 (G3[59], P3[59], G2[59], P2[59], G2[55], P2[55]);
  CarryOperator U212 (G3[60], P3[60], G2[60], P2[60], G2[56], P2[56]);
  CarryOperator U213 (G3[61], P3[61], G2[61], P2[61], G2[57], P2[57]);
  CarryOperator U214 (G3[62], P3[62], G2[62], P2[62], G2[58], P2[58]);
  CarryOperator U215 (G3[63], P3[63], G2[63], P2[63], G2[59], P2[59]);
  CarryOperator U216 (G3[64], P3[64], G2[64], P2[64], G2[60], P2[60]);
  CarryOperator U217 (G4[17], P4[17], G3[17], P3[17], G3[9], P3[9]);
  CarryOperator U218 (G4[18], P4[18], G3[18], P3[18], G3[10], P3[10]);
  CarryOperator U219 (G4[19], P4[19], G3[19], P3[19], G3[11], P3[11]);
  CarryOperator U220 (G4[20], P4[20], G3[20], P3[20], G3[12], P3[12]);
  CarryOperator U221 (G4[21], P4[21], G3[21], P3[21], G3[13], P3[13]);
  CarryOperator U222 (G4[22], P4[22], G3[22], P3[22], G3[14], P3[14]);
  CarryOperator U223 (G4[23], P4[23], G3[23], P3[23], G3[15], P3[15]);
  CarryOperator U224 (G4[24], P4[24], G3[24], P3[24], G3[16], P3[16]);
  CarryOperator U225 (G4[25], P4[25], G3[25], P3[25], G3[17], P3[17]);
  CarryOperator U226 (G4[26], P4[26], G3[26], P3[26], G3[18], P3[18]);
  CarryOperator U227 (G4[27], P4[27], G3[27], P3[27], G3[19], P3[19]);
  CarryOperator U228 (G4[28], P4[28], G3[28], P3[28], G3[20], P3[20]);
  CarryOperator U229 (G4[29], P4[29], G3[29], P3[29], G3[21], P3[21]);
  CarryOperator U230 (G4[30], P4[30], G3[30], P3[30], G3[22], P3[22]);
  CarryOperator U231 (G4[31], P4[31], G3[31], P3[31], G3[23], P3[23]);
  CarryOperator U232 (G4[32], P4[32], G3[32], P3[32], G3[24], P3[24]);
  CarryOperator U233 (G4[33], P4[33], G3[33], P3[33], G3[25], P3[25]);
  CarryOperator U234 (G4[34], P4[34], G3[34], P3[34], G3[26], P3[26]);
  CarryOperator U235 (G4[35], P4[35], G3[35], P3[35], G3[27], P3[27]);
  CarryOperator U236 (G4[36], P4[36], G3[36], P3[36], G3[28], P3[28]);
  CarryOperator U237 (G4[37], P4[37], G3[37], P3[37], G3[29], P3[29]);
  CarryOperator U238 (G4[38], P4[38], G3[38], P3[38], G3[30], P3[30]);
  CarryOperator U239 (G4[39], P4[39], G3[39], P3[39], G3[31], P3[31]);
  CarryOperator U240 (G4[40], P4[40], G3[40], P3[40], G3[32], P3[32]);
  CarryOperator U241 (G4[41], P4[41], G3[41], P3[41], G3[33], P3[33]);
  CarryOperator U242 (G4[42], P4[42], G3[42], P3[42], G3[34], P3[34]);
  CarryOperator U243 (G4[43], P4[43], G3[43], P3[43], G3[35], P3[35]);
  CarryOperator U244 (G4[44], P4[44], G3[44], P3[44], G3[36], P3[36]);
  CarryOperator U245 (G4[45], P4[45], G3[45], P3[45], G3[37], P3[37]);
  CarryOperator U246 (G4[46], P4[46], G3[46], P3[46], G3[38], P3[38]);
  CarryOperator U247 (G4[47], P4[47], G3[47], P3[47], G3[39], P3[39]);
  CarryOperator U248 (G4[48], P4[48], G3[48], P3[48], G3[40], P3[40]);
  CarryOperator U249 (G4[49], P4[49], G3[49], P3[49], G3[41], P3[41]);
  CarryOperator U250 (G4[50], P4[50], G3[50], P3[50], G3[42], P3[42]);
  CarryOperator U251 (G4[51], P4[51], G3[51], P3[51], G3[43], P3[43]);
  CarryOperator U252 (G4[52], P4[52], G3[52], P3[52], G3[44], P3[44]);
  CarryOperator U253 (G4[53], P4[53], G3[53], P3[53], G3[45], P3[45]);
  CarryOperator U254 (G4[54], P4[54], G3[54], P3[54], G3[46], P3[46]);
  CarryOperator U255 (G4[55], P4[55], G3[55], P3[55], G3[47], P3[47]);
  CarryOperator U256 (G4[56], P4[56], G3[56], P3[56], G3[48], P3[48]);
  CarryOperator U257 (G4[57], P4[57], G3[57], P3[57], G3[49], P3[49]);
  CarryOperator U258 (G4[58], P4[58], G3[58], P3[58], G3[50], P3[50]);
  CarryOperator U259 (G4[59], P4[59], G3[59], P3[59], G3[51], P3[51]);
  CarryOperator U260 (G4[60], P4[60], G3[60], P3[60], G3[52], P3[52]);
  CarryOperator U261 (G4[61], P4[61], G3[61], P3[61], G3[53], P3[53]);
  CarryOperator U262 (G4[62], P4[62], G3[62], P3[62], G3[54], P3[54]);
  CarryOperator U263 (G4[63], P4[63], G3[63], P3[63], G3[55], P3[55]);
  CarryOperator U264 (G4[64], P4[64], G3[64], P3[64], G3[56], P3[56]);
  CarryOperator U265 (G5[25], P5[25], G4[25], P4[25], G4[9], P4[9]);
  CarryOperator U266 (G5[26], P5[26], G4[26], P4[26], G4[10], P4[10]);
  CarryOperator U267 (G5[27], P5[27], G4[27], P4[27], G4[11], P4[11]);
  CarryOperator U268 (G5[28], P5[28], G4[28], P4[28], G4[12], P4[12]);
  CarryOperator U269 (G5[29], P5[29], G4[29], P4[29], G4[13], P4[13]);
  CarryOperator U270 (G5[30], P5[30], G4[30], P4[30], G4[14], P4[14]);
  CarryOperator U271 (G5[31], P5[31], G4[31], P4[31], G4[15], P4[15]);
  CarryOperator U272 (G5[32], P5[32], G4[32], P4[32], G4[16], P4[16]);
  CarryOperator U273 (G5[33], P5[33], G4[33], P4[33], G4[17], P4[17]);
  CarryOperator U274 (G5[34], P5[34], G4[34], P4[34], G4[18], P4[18]);
  CarryOperator U275 (G5[35], P5[35], G4[35], P4[35], G4[19], P4[19]);
  CarryOperator U276 (G5[36], P5[36], G4[36], P4[36], G4[20], P4[20]);
  CarryOperator U277 (G5[37], P5[37], G4[37], P4[37], G4[21], P4[21]);
  CarryOperator U278 (G5[38], P5[38], G4[38], P4[38], G4[22], P4[22]);
  CarryOperator U279 (G5[39], P5[39], G4[39], P4[39], G4[23], P4[23]);
  CarryOperator U280 (G5[40], P5[40], G4[40], P4[40], G4[24], P4[24]);
  CarryOperator U281 (G5[41], P5[41], G4[41], P4[41], G4[25], P4[25]);
  CarryOperator U282 (G5[42], P5[42], G4[42], P4[42], G4[26], P4[26]);
  CarryOperator U283 (G5[43], P5[43], G4[43], P4[43], G4[27], P4[27]);
  CarryOperator U284 (G5[44], P5[44], G4[44], P4[44], G4[28], P4[28]);
  CarryOperator U285 (G5[45], P5[45], G4[45], P4[45], G4[29], P4[29]);
  CarryOperator U286 (G5[46], P5[46], G4[46], P4[46], G4[30], P4[30]);
  CarryOperator U287 (G5[47], P5[47], G4[47], P4[47], G4[31], P4[31]);
  CarryOperator U288 (G5[48], P5[48], G4[48], P4[48], G4[32], P4[32]);
  CarryOperator U289 (G5[49], P5[49], G4[49], P4[49], G4[33], P4[33]);
  CarryOperator U290 (G5[50], P5[50], G4[50], P4[50], G4[34], P4[34]);
  CarryOperator U291 (G5[51], P5[51], G4[51], P4[51], G4[35], P4[35]);
  CarryOperator U292 (G5[52], P5[52], G4[52], P4[52], G4[36], P4[36]);
  CarryOperator U293 (G5[53], P5[53], G4[53], P4[53], G4[37], P4[37]);
  CarryOperator U294 (G5[54], P5[54], G4[54], P4[54], G4[38], P4[38]);
  CarryOperator U295 (G5[55], P5[55], G4[55], P4[55], G4[39], P4[39]);
  CarryOperator U296 (G5[56], P5[56], G4[56], P4[56], G4[40], P4[40]);
  CarryOperator U297 (G5[57], P5[57], G4[57], P4[57], G4[41], P4[41]);
  CarryOperator U298 (G5[58], P5[58], G4[58], P4[58], G4[42], P4[42]);
  CarryOperator U299 (G5[59], P5[59], G4[59], P4[59], G4[43], P4[43]);
  CarryOperator U300 (G5[60], P5[60], G4[60], P4[60], G4[44], P4[44]);
  CarryOperator U301 (G5[61], P5[61], G4[61], P4[61], G4[45], P4[45]);
  CarryOperator U302 (G5[62], P5[62], G4[62], P4[62], G4[46], P4[46]);
  CarryOperator U303 (G5[63], P5[63], G4[63], P4[63], G4[47], P4[47]);
  CarryOperator U304 (G5[64], P5[64], G4[64], P4[64], G4[48], P4[48]);
  CarryOperator U305 (G6[41], P6[41], G5[41], P5[41], G5[9], P5[9]);
  CarryOperator U306 (G6[42], P6[42], G5[42], P5[42], G5[10], P5[10]);
  CarryOperator U307 (G6[43], P6[43], G5[43], P5[43], G5[11], P5[11]);
  CarryOperator U308 (G6[44], P6[44], G5[44], P5[44], G5[12], P5[12]);
  CarryOperator U309 (G6[45], P6[45], G5[45], P5[45], G5[13], P5[13]);
  CarryOperator U310 (G6[46], P6[46], G5[46], P5[46], G5[14], P5[14]);
  CarryOperator U311 (G6[47], P6[47], G5[47], P5[47], G5[15], P5[15]);
  CarryOperator U312 (G6[48], P6[48], G5[48], P5[48], G5[16], P5[16]);
  CarryOperator U313 (G6[49], P6[49], G5[49], P5[49], G5[17], P5[17]);
  CarryOperator U314 (G6[50], P6[50], G5[50], P5[50], G5[18], P5[18]);
  CarryOperator U315 (G6[51], P6[51], G5[51], P5[51], G5[19], P5[19]);
  CarryOperator U316 (G6[52], P6[52], G5[52], P5[52], G5[20], P5[20]);
  CarryOperator U317 (G6[53], P6[53], G5[53], P5[53], G5[21], P5[21]);
  CarryOperator U318 (G6[54], P6[54], G5[54], P5[54], G5[22], P5[22]);
  CarryOperator U319 (G6[55], P6[55], G5[55], P5[55], G5[23], P5[23]);
  CarryOperator U320 (G6[56], P6[56], G5[56], P5[56], G5[24], P5[24]);
  CarryOperator U321 (G6[57], P6[57], G5[57], P5[57], G5[25], P5[25]);
  CarryOperator U322 (G6[58], P6[58], G5[58], P5[58], G5[26], P5[26]);
  CarryOperator U323 (G6[59], P6[59], G5[59], P5[59], G5[27], P5[27]);
  CarryOperator U324 (G6[60], P6[60], G5[60], P5[60], G5[28], P5[28]);
  CarryOperator U325 (G6[61], P6[61], G5[61], P5[61], G5[29], P5[29]);
  CarryOperator U326 (G6[62], P6[62], G5[62], P5[62], G5[30], P5[30]);
  CarryOperator U327 (G6[63], P6[63], G5[63], P5[63], G5[31], P5[31]);
  CarryOperator U328 (G6[64], P6[64], G5[64], P5[64], G5[32], P5[32]);
endmodule

module UBZero_9_9(O);
  output [9:9] O;
  assign O[9] = 0;
endmodule

module UBTC1CON66_0(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_1(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_2(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_3(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_4(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_5(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_6(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_7(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_8(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_9(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_10(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_11(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_12(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_13(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_14(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_15(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_16(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_17(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_18(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_19(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_20(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_21(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_22(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_23(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_24(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_25(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_26(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_27(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_28(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_29(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_30(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_31(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_32(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_33(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_34(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_35(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_36(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_37(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_38(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_39(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_40(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_41(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_42(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_43(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_44(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_45(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_46(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_47(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_48(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_49(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_50(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_51(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_52(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_53(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_54(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_55(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_56(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_57(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_58(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_59(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_60(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_61(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTC1CON66_62(O, I);
  output O;
  input I;
  assign O = I;
endmodule

module UBTCTCONV_65_63(O, I);
  output [66:63] O;
  input [65:63] I;
  assign O[63] = ~ I[63];
  assign O[64] = ~ I[64] ^ ( I[63] );
  assign O[65] = ~ I[65] ^ ( I[64] | I[63] );
  assign O[66] = ~ ( I[65] | I[64] | I[63] );
endmodule

module Multiplier_31_0_3000(P, IN1, IN2);

  output [63:0] P;
  input [31:0] IN1;
  input [31:0] IN2;
  wire [66:0] W;
  assign P[0] = W[0];
  assign P[1] = W[1];
  assign P[2] = W[2];
  assign P[3] = W[3];
  assign P[4] = W[4];
  assign P[5] = W[5];
  assign P[6] = W[6];
  assign P[7] = W[7];
  assign P[8] = W[8];
  assign P[9] = W[9];
  assign P[10] = W[10];
  assign P[11] = W[11];
  assign P[12] = W[12];
  assign P[13] = W[13];
  assign P[14] = W[14];
  assign P[15] = W[15];
  assign P[16] = W[16];
  assign P[17] = W[17];
  assign P[18] = W[18];
  assign P[19] = W[19];
  assign P[20] = W[20];
  assign P[21] = W[21];
  assign P[22] = W[22];
  assign P[23] = W[23];
  assign P[24] = W[24];
  assign P[25] = W[25];
  assign P[26] = W[26];
  assign P[27] = W[27];
  assign P[28] = W[28];
  assign P[29] = W[29];
  assign P[30] = W[30];
  assign P[31] = W[31];
  assign P[32] = W[32];
  assign P[33] = W[33];
  assign P[34] = W[34];
  assign P[35] = W[35];
  assign P[36] = W[36];
  assign P[37] = W[37];
  assign P[38] = W[38];
  assign P[39] = W[39];
  assign P[40] = W[40];
  assign P[41] = W[41];
  assign P[42] = W[42];
  assign P[43] = W[43];
  assign P[44] = W[44];
  assign P[45] = W[45];
  assign P[46] = W[46];
  assign P[47] = W[47];
  assign P[48] = W[48];
  assign P[49] = W[49];
  assign P[50] = W[50];
  assign P[51] = W[51];
  assign P[52] = W[52];
  assign P[53] = W[53];
  assign P[54] = W[54];
  assign P[55] = W[55];
  assign P[56] = W[56];
  assign P[57] = W[57];
  assign P[58] = W[58];
  assign P[59] = W[59];
  assign P[60] = W[60];
  assign P[61] = W[61];
  assign P[62] = W[62];
  assign P[63] = W[63];
  MultTC_STD_WAL_KS000 U0 (W, IN1, IN2);
endmodule

module CSA_32_0_32_1_33_000 (C, S, X, Y, Z);
  output [33:2] C;
  output [33:0] S;
  input [32:0] X;
  input [32:1] Y;
  input [33:2] Z;
  UB1DCON_0 U0 (S[0], X[0]);
  UBHA_1 U1 (C[2], S[1], Y[1], X[1]);
  PureCSA_32_2 U2 (C[33:3], S[32:2], Z[32:2], Y[32:2], X[32:2]);
  UB1DCON_33 U3 (S[33], Z[33]);
endmodule

module CSA_33_0_33_2_36_000 (C, S, X, Y, Z);
  output [34:3] C;
  output [36:0] S;
  input [33:0] X;
  input [33:2] Y;
  input [36:3] Z;
  UBCON_1_0 U0 (S[1:0], X[1:0]);
  UBHA_2 U1 (C[3], S[2], Y[2], X[2]);
  PureCSA_33_3 U2 (C[34:4], S[33:3], Z[33:3], Y[33:3], X[33:3]);
  UBCON_36_34 U3 (S[36:34], Z[36:34]);
endmodule

module CSA_34_3_35_4_36_000 (C, S, X, Y, Z);
  output [36:5] C;
  output [36:3] S;
  input [34:3] X;
  input [35:4] Y;
  input [36:5] Z;
  UB1DCON_3 U0 (S[3], X[3]);
  UBHA_4 U1 (C[5], S[4], Y[4], X[4]);
  PureCSA_34_5 U2 (C[35:6], S[34:5], Z[34:5], Y[34:5], X[34:5]);
  UBHA_35 U3 (C[36], S[35], Z[35], Y[35]);
  UB1DCON_36 U4 (S[36], Z[36]);
endmodule

module CSA_36_0_34_3_39_000 (C, S, X, Y, Z);
  output [37:4] C;
  output [39:0] S;
  input [36:0] X;
  input [34:3] Y;
  input [39:5] Z;
  UBCON_2_0 U0 (S[2:0], X[2:0]);
  PureCSHA_4_3 U1 (C[5:4], S[4:3], Y[4:3], X[4:3]);
  PureCSA_34_5 U2 (C[35:6], S[34:5], Z[34:5], Y[34:5], X[34:5]);
  PureCSHA_36_35 U3 (C[37:36], S[36:35], Z[36:35], X[36:35]);
  UBCON_39_37 U4 (S[39:37], Z[39:37]);
endmodule

module CSA_36_5_39_6_39_000 (C, S, X, Y, Z);
  output [40:7] C;
  output [39:5] S;
  input [36:5] X;
  input [39:6] Y;
  input [39:8] Z;
  UB1DCON_5 U0 (S[5], X[5]);
  PureCSHA_7_6 U1 (C[8:7], S[7:6], Y[7:6], X[7:6]);
  PureCSA_36_8 U2 (C[37:9], S[36:8], Z[36:8], Y[36:8], X[36:8]);
  PureCSHA_39_37 U3 (C[40:38], S[39:37], Z[39:37], Y[39:37]);
endmodule

module CSA_37_6_38_7_39_000 (C, S, X, Y, Z);
  output [39:8] C;
  output [39:6] S;
  input [37:6] X;
  input [38:7] Y;
  input [39:8] Z;
  UB1DCON_6 U0 (S[6], X[6]);
  UBHA_7 U1 (C[8], S[7], Y[7], X[7]);
  PureCSA_37_8 U2 (C[38:9], S[37:8], Z[37:8], Y[37:8], X[37:8]);
  UBHA_38 U3 (C[39], S[38], Z[38], Y[38]);
  UB1DCON_39 U4 (S[39], Z[39]);
endmodule

module CSA_39_0_37_4_43_000 (C, S, X, Y, Z);
  output [40:5] C;
  output [43:0] S;
  input [39:0] X;
  input [37:4] Y;
  input [43:7] Z;
  UBCON_3_0 U0 (S[3:0], X[3:0]);
  PureCSHA_6_4 U1 (C[7:5], S[6:4], Y[6:4], X[6:4]);
  PureCSA_37_7 U2 (C[38:8], S[37:7], Z[37:7], Y[37:7], X[37:7]);
  PureCSHA_39_38 U3 (C[40:39], S[39:38], Z[39:38], X[39:38]);
  UBCON_43_40 U4 (S[43:40], Z[43:40]);
endmodule

module CSA_40_7_43_9_43_000 (C, S, X, Y, Z);
  output [44:10] C;
  output [43:7] S;
  input [40:7] X;
  input [43:9] Y;
  input [43:12] Z;
  UBCON_8_7 U0 (S[8:7], X[8:7]);
  PureCSHA_11_9 U1 (C[12:10], S[11:9], Y[11:9], X[11:9]);
  PureCSA_40_12 U2 (C[41:13], S[40:12], Z[40:12], Y[40:12], X[40:12]);
  PureCSHA_43_41 U3 (C[44:42], S[43:41], Z[43:41], Y[43:41]);
endmodule

module CSA_40_9_41_10_42000 (C, S, X, Y, Z);
  output [42:11] C;
  output [42:9] S;
  input [40:9] X;
  input [41:10] Y;
  input [42:11] Z;
  UB1DCON_9 U0 (S[9], X[9]);
  UBHA_10 U1 (C[11], S[10], Y[10], X[10]);
  PureCSA_40_11 U2 (C[41:12], S[40:11], Z[40:11], Y[40:11], X[40:11]);
  UBHA_41 U3 (C[42], S[41], Z[41], Y[41]);
  UB1DCON_42 U4 (S[42], Z[42]);
endmodule

module CSA_42_9_42_11_43000 (C, S, X, Y, Z);
  output [43:12] C;
  output [43:9] S;
  input [42:9] X;
  input [42:11] Y;
  input [43:12] Z;
  UBCON_10_9 U0 (S[10:9], X[10:9]);
  UBHA_11 U1 (C[12], S[11], Y[11], X[11]);
  PureCSA_42_12 U2 (C[43:13], S[42:12], Z[42:12], Y[42:12], X[42:12]);
  UB1DCON_43 U3 (S[43], Z[43]);
endmodule

module CSA_43_0_40_5_49_000 (C, S, X, Y, Z);
  output [44:6] C;
  output [49:0] S;
  input [43:0] X;
  input [40:5] Y;
  input [49:10] Z;
  UBCON_4_0 U0 (S[4:0], X[4:0]);
  PureCSHA_9_5 U1 (C[10:6], S[9:5], Y[9:5], X[9:5]);
  PureCSA_40_10 U2 (C[41:11], S[40:10], Z[40:10], Y[40:10], X[40:10]);
  PureCSHA_43_41 U3 (C[44:42], S[43:41], Z[43:41], X[43:41]);
  UBCON_49_44 U4 (S[49:44], Z[49:44]);
endmodule

module CSA_44_10_49_13_4000 (C, S, X, Y, Z);
  output [48:14] C;
  output [49:10] S;
  input [44:10] X;
  input [49:13] Y;
  input [47:16] Z;
  UBCON_12_10 U0 (S[12:10], X[12:10]);
  PureCSHA_15_13 U1 (C[16:14], S[15:13], Y[15:13], X[15:13]);
  PureCSA_44_16 U2 (C[45:17], S[44:16], Z[44:16], Y[44:16], X[44:16]);
  PureCSHA_47_45 U3 (C[48:46], S[47:45], Y[47:45], Z[47:45]);
  UBCON_49_48 U4 (S[49:48], Y[49:48]);
endmodule

module CSA_44_13_45_14_4000 (C, S, X, Y, Z);
  output [46:15] C;
  output [46:13] S;
  input [44:13] X;
  input [45:14] Y;
  input [46:15] Z;
  UB1DCON_13 U0 (S[13], X[13]);
  UBHA_14 U1 (C[15], S[14], Y[14], X[14]);
  PureCSA_44_15 U2 (C[45:16], S[44:15], Z[44:15], Y[44:15], X[44:15]);
  UBHA_45 U3 (C[46], S[45], Z[45], Y[45]);
  UB1DCON_46 U4 (S[46], Z[46]);
endmodule

module CSA_46_13_46_15_4000 (C, S, X, Y, Z);
  output [47:16] C;
  output [49:13] S;
  input [46:13] X;
  input [46:15] Y;
  input [49:16] Z;
  UBCON_14_13 U0 (S[14:13], X[14:13]);
  UBHA_15 U1 (C[16], S[15], Y[15], X[15]);
  PureCSA_46_16 U2 (C[47:17], S[46:16], Z[46:16], Y[46:16], X[46:16]);
  UBCON_49_47 U3 (S[49:47], Z[49:47]);
endmodule

module CSA_47_16_48_17_4000 (C, S, X, Y, Z);
  output [49:18] C;
  output [49:16] S;
  input [47:16] X;
  input [48:17] Y;
  input [49:18] Z;
  UB1DCON_16 U0 (S[16], X[16]);
  UBHA_17 U1 (C[18], S[17], Y[17], X[17]);
  PureCSA_47_18 U2 (C[48:19], S[47:18], Z[47:18], Y[47:18], X[47:18]);
  UBHA_48 U3 (C[49], S[48], Z[48], Y[48]);
  UB1DCON_49 U4 (S[49], Z[49]);
endmodule

module CSA_48_14_58_18_5000 (C, S, X, Y, Z);
  output [55:19] C;
  output [58:14] S;
  input [48:14] X;
  input [58:18] Y;
  input [54:21] Z;
  UBCON_17_14 U0 (S[17:14], X[17:14]);
  PureCSHA_20_18 U1 (C[21:19], S[20:18], Y[20:18], X[20:18]);
  PureCSA_48_21 U2 (C[49:22], S[48:21], Z[48:21], Y[48:21], X[48:21]);
  PureCSHA_54_49 U3 (C[55:50], S[54:49], Y[54:49], Z[54:49]);
  UBCON_58_55 U4 (S[58:55], Y[58:55]);
endmodule

module CSA_49_0_44_6_58_000 (C, S, X, Y, Z);
  output [50:7] C;
  output [58:0] S;
  input [49:0] X;
  input [44:6] Y;
  input [58:14] Z;
  UBCON_5_0 U0 (S[5:0], X[5:0]);
  PureCSHA_13_6 U1 (C[14:7], S[13:6], Y[13:6], X[13:6]);
  PureCSA_44_14 U2 (C[45:15], S[44:14], Z[44:14], Y[44:14], X[44:14]);
  PureCSHA_49_45 U3 (C[50:46], S[49:45], Z[49:45], X[49:45]);
  UBCON_58_50 U4 (S[58:50], Z[58:50]);
endmodule

module CSA_49_18_52_19_5000 (C, S, X, Y, Z);
  output [53:20] C;
  output [52:18] S;
  input [49:18] X;
  input [52:19] Y;
  input [52:21] Z;
  UB1DCON_18 U0 (S[18], X[18]);
  PureCSHA_20_19 U1 (C[21:20], S[20:19], Y[20:19], X[20:19]);
  PureCSA_49_21 U2 (C[50:22], S[49:21], Z[49:21], Y[49:21], X[49:21]);
  PureCSHA_52_50 U3 (C[53:51], S[52:50], Z[52:50], Y[52:50]);
endmodule

module CSA_50_19_51_20_5000 (C, S, X, Y, Z);
  output [52:21] C;
  output [52:19] S;
  input [50:19] X;
  input [51:20] Y;
  input [52:21] Z;
  UB1DCON_19 U0 (S[19], X[19]);
  UBHA_20 U1 (C[21], S[20], Y[20], X[20]);
  PureCSA_50_21 U2 (C[51:22], S[50:21], Z[50:21], Y[50:21], X[50:21]);
  UBHA_51 U3 (C[52], S[51], Z[51], Y[51]);
  UB1DCON_52 U4 (S[52], Z[52]);
endmodule

module CSA_52_18_53_20_5000 (C, S, X, Y, Z);
  output [54:21] C;
  output [58:18] S;
  input [52:18] X;
  input [53:20] Y;
  input [58:22] Z;
  UBCON_19_18 U0 (S[19:18], X[19:18]);
  PureCSHA_21_20 U1 (C[22:21], S[21:20], Y[21:20], X[21:20]);
  PureCSA_52_22 U2 (C[53:23], S[52:22], Z[52:22], Y[52:22], X[52:22]);
  UBHA_53 U3 (C[54], S[53], Z[53], Y[53]);
  UBCON_58_54 U4 (S[58:54], Z[58:54]);
endmodule

module CSA_53_22_54_23_5000 (C, S, X, Y, Z);
  output [55:24] C;
  output [55:22] S;
  input [53:22] X;
  input [54:23] Y;
  input [55:24] Z;
  UB1DCON_22 U0 (S[22], X[22]);
  UBHA_23 U1 (C[24], S[23], Y[23], X[23]);
  PureCSA_53_24 U2 (C[54:25], S[53:24], Z[53:24], Y[53:24], X[53:24]);
  UBHA_54 U3 (C[55], S[54], Z[54], Y[54]);
  UB1DCON_55 U4 (S[55], Z[55]);
endmodule

module CSA_55_19_62_25_6000 (C, S, X, Y, Z);
  output [63:26] C;
  output [63:19] S;
  input [55:19] X;
  input [62:25] Y;
  input [63:29] Z;
  UBCON_24_19 U0 (S[24:19], X[24:19]);
  PureCSHA_28_25 U1 (C[29:26], S[28:25], Y[28:25], X[28:25]);
  PureCSA_55_29 U2 (C[56:30], S[55:29], Z[55:29], Y[55:29], X[55:29]);
  PureCSHA_62_56 U3 (C[63:57], S[62:56], Z[62:56], Y[62:56]);
  UB1DCON_63 U4 (S[63], Z[63]);
endmodule

module CSA_55_22_55_24_5000 (C, S, X, Y, Z);
  output [56:25] C;
  output [58:22] S;
  input [55:22] X;
  input [55:24] Y;
  input [58:25] Z;
  UBCON_23_22 U0 (S[23:22], X[23:22]);
  UBHA_24 U1 (C[25], S[24], Y[24], X[24]);
  PureCSA_55_25 U2 (C[56:26], S[55:25], Z[55:25], Y[55:25], X[55:25]);
  UBCON_58_56 U3 (S[58:56], Z[58:56]);
endmodule

module CSA_56_25_57_26_5000 (C, S, X, Y, Z);
  output [58:27] C;
  output [58:25] S;
  input [56:25] X;
  input [57:26] Y;
  input [58:27] Z;
  UB1DCON_25 U0 (S[25], X[25]);
  UBHA_26 U1 (C[27], S[26], Y[26], X[26]);
  PureCSA_56_27 U2 (C[57:28], S[56:27], Z[56:27], Y[56:27], X[56:27]);
  UBHA_57 U3 (C[58], S[57], Z[57], Y[57]);
  UB1DCON_58 U4 (S[58], Z[58]);
endmodule

module CSA_56_25_61_27_6000 (C, S, X, Y, Z);
  output [62:28] C;
  output [62:25] S;
  input [56:25] X;
  input [61:27] Y;
  input [62:29] Z;
  UBCON_26_25 U0 (S[26:25], X[26:25]);
  PureCSHA_28_27 U1 (C[29:28], S[28:27], Y[28:27], X[28:27]);
  PureCSA_56_29 U2 (C[57:30], S[56:29], Z[56:29], Y[56:29], X[56:29]);
  PureCSHA_61_57 U3 (C[62:58], S[61:57], Z[61:57], Y[61:57]);
  UB1DCON_62 U4 (S[62], Z[62]);
endmodule

module CSA_58_0_50_7_63_000 (C, S, X, Y, Z);
  output [59:8] C;
  output [63:0] S;
  input [58:0] X;
  input [50:7] Y;
  input [63:19] Z;
  UBCON_6_0 U0 (S[6:0], X[6:0]);
  PureCSHA_18_7 U1 (C[19:8], S[18:7], Y[18:7], X[18:7]);
  PureCSA_50_19 U2 (C[51:20], S[50:19], Z[50:19], Y[50:19], X[50:19]);
  PureCSHA_58_51 U3 (C[59:52], S[58:51], Z[58:51], X[58:51]);
  UBCON_63_59 U4 (S[63:59], Z[63:59]);
endmodule

module CSA_58_27_61_28_6000 (C, S, X, Y, Z);
  output [62:29] C;
  output [61:27] S;
  input [58:27] X;
  input [61:28] Y;
  input [61:30] Z;
  UB1DCON_27 U0 (S[27], X[27]);
  PureCSHA_29_28 U1 (C[30:29], S[29:28], Y[29:28], X[29:28]);
  PureCSA_58_30 U2 (C[59:31], S[58:30], Z[58:30], Y[58:30], X[58:30]);
  PureCSHA_61_59 U3 (C[62:60], S[61:59], Z[61:59], Y[61:59]);
endmodule

module CSA_59_28_60_29_6000 (C, S, X, Y, Z);
  output [61:30] C;
  output [61:28] S;
  input [59:28] X;
  input [60:29] Y;
  input [61:30] Z;
  UB1DCON_28 U0 (S[28], X[28]);
  UBHA_29 U1 (C[30], S[29], Y[29], X[29]);
  PureCSA_59_30 U2 (C[60:31], S[59:30], Z[59:30], Y[59:30], X[59:30]);
  UBHA_60 U3 (C[61], S[60], Z[60], Y[60]);
  UB1DCON_61 U4 (S[61], Z[61]);
endmodule

module CSA_62_25_62_28_6000 (C, S, X, Y, Z);
  output [63:29] C;
  output [62:25] S;
  input [62:25] X;
  input [62:28] Y;
  input [62:31] Z;
  UBCON_27_25 U0 (S[27:25], X[27:25]);
  PureCSHA_30_28 U1 (C[31:29], S[30:28], Y[30:28], X[30:28]);
  PureCSA_62_31 U2 (C[63:32], S[62:31], Z[62:31], Y[62:31], X[62:31]);
endmodule

module CSA_63_0_59_8_63_000 (C, S, X, Y, Z);
  output [64:9] C;
  output [63:0] S;
  input [63:0] X;
  input [59:8] Y;
  input [63:26] Z;
  UBCON_7_0 U0 (S[7:0], X[7:0]);
  PureCSHA_25_8 U1 (C[26:9], S[25:8], Y[25:8], X[25:8]);
  PureCSA_59_26 U2 (C[60:27], S[59:26], Z[59:26], Y[59:26], X[59:26]);
  PureCSHA_63_60 U3 (C[64:61], S[63:60], Z[63:60], X[63:60]);
endmodule

module MultTC_STD_WAL_KS000 (P, IN1, IN2);

  output [66:0] P;
  input [31:0] IN1;
  input [31:0] IN2;
  wire [32:0] PP0;
  wire [32:1] PP1;
  wire [41:10] PP10;
  wire [42:11] PP11;
  wire [43:12] PP12;
  wire [44:13] PP13;
  wire [45:14] PP14;
  wire [46:15] PP15;
  wire [47:16] PP16;
  wire [48:17] PP17;
  wire [49:18] PP18;
  wire [50:19] PP19;
  wire [33:2] PP2;
  wire [51:20] PP20;
  wire [52:21] PP21;
  wire [53:22] PP22;
  wire [54:23] PP23;
  wire [55:24] PP24;
  wire [56:25] PP25;
  wire [57:26] PP26;
  wire [58:27] PP27;
  wire [59:28] PP28;
  wire [60:29] PP29;
  wire [34:3] PP3;
  wire [61:30] PP30;
  wire [62:31] PP31;
  wire [35:4] PP4;
  wire [36:5] PP5;
  wire [37:6] PP6;
  wire [38:7] PP7;
  wire [39:8] PP8;
  wire [40:9] PP9;
  wire [65:0] P_UB;
  wire [64:9] S1;
  wire [63:0] S2;

  TCPPG_31_0_31_0 U0 (PP0, PP1, PP2, PP3, PP4, PP5, PP6, PP7, PP8, PP9, PP10, PP11, PP12, PP13, PP14, PP15, PP16, PP17, PP18, PP19, PP20, PP21, PP22, PP23, PP24, PP25, PP26, PP27, PP28, PP29, PP30, PP31, IN1, IN2);
  WLCTR_32_0_32_1_3000 U1 (S1, S2, PP0, PP1, PP2, PP3, PP4, PP5, PP6, PP7, PP8, PP9, PP10, PP11, PP12, PP13, PP14, PP15, PP16, PP17, PP18, PP19, PP20, PP21, PP22, PP23, PP24, PP25, PP26, PP27, PP28, PP29, PP30, PP31);

  UBKSA_64_9_63_0 U2 (P_UB, S1, S2);
  UBTCCONV63_65_0 U3 (P, P_UB);
endmodule

module NUBUBCON_61_31 (O, I);
  output [61:31] O;
  input [61:31] I;
  NUBUB1CON_31 U0 (O[31], I[31]);
  NUBUB1CON_32 U1 (O[32], I[32]);
  NUBUB1CON_33 U2 (O[33], I[33]);
  NUBUB1CON_34 U3 (O[34], I[34]);
  NUBUB1CON_35 U4 (O[35], I[35]);
  NUBUB1CON_36 U5 (O[36], I[36]);
  NUBUB1CON_37 U6 (O[37], I[37]);
  NUBUB1CON_38 U7 (O[38], I[38]);
  NUBUB1CON_39 U8 (O[39], I[39]);
  NUBUB1CON_40 U9 (O[40], I[40]);
  NUBUB1CON_41 U10 (O[41], I[41]);
  NUBUB1CON_42 U11 (O[42], I[42]);
  NUBUB1CON_43 U12 (O[43], I[43]);
  NUBUB1CON_44 U13 (O[44], I[44]);
  NUBUB1CON_45 U14 (O[45], I[45]);
  NUBUB1CON_46 U15 (O[46], I[46]);
  NUBUB1CON_47 U16 (O[47], I[47]);
  NUBUB1CON_48 U17 (O[48], I[48]);
  NUBUB1CON_49 U18 (O[49], I[49]);
  NUBUB1CON_50 U19 (O[50], I[50]);
  NUBUB1CON_51 U20 (O[51], I[51]);
  NUBUB1CON_52 U21 (O[52], I[52]);
  NUBUB1CON_53 U22 (O[53], I[53]);
  NUBUB1CON_54 U23 (O[54], I[54]);
  NUBUB1CON_55 U24 (O[55], I[55]);
  NUBUB1CON_56 U25 (O[56], I[56]);
  NUBUB1CON_57 U26 (O[57], I[57]);
  NUBUB1CON_58 U27 (O[58], I[58]);
  NUBUB1CON_59 U28 (O[59], I[59]);
  NUBUB1CON_60 U29 (O[60], I[60]);
  NUBUB1CON_61 U30 (O[61], I[61]);
endmodule

module PureCSA_32_2 (C, S, X, Y, Z);
  output [33:3] C;
  output [32:2] S;
  input [32:2] X;
  input [32:2] Y;
  input [32:2] Z;
  UBFA_2 U0 (C[3], S[2], X[2], Y[2], Z[2]);
  UBFA_3 U1 (C[4], S[3], X[3], Y[3], Z[3]);
  UBFA_4 U2 (C[5], S[4], X[4], Y[4], Z[4]);
  UBFA_5 U3 (C[6], S[5], X[5], Y[5], Z[5]);
  UBFA_6 U4 (C[7], S[6], X[6], Y[6], Z[6]);
  UBFA_7 U5 (C[8], S[7], X[7], Y[7], Z[7]);
  UBFA_8 U6 (C[9], S[8], X[8], Y[8], Z[8]);
  UBFA_9 U7 (C[10], S[9], X[9], Y[9], Z[9]);
  UBFA_10 U8 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U9 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U10 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U11 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U12 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U13 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U14 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U15 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U16 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U17 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U18 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U19 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U20 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U21 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U22 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U23 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U24 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U25 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U26 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U27 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U28 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U29 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U30 (C[33], S[32], X[32], Y[32], Z[32]);
endmodule

module PureCSA_33_3 (C, S, X, Y, Z);
  output [34:4] C;
  output [33:3] S;
  input [33:3] X;
  input [33:3] Y;
  input [33:3] Z;
  UBFA_3 U0 (C[4], S[3], X[3], Y[3], Z[3]);
  UBFA_4 U1 (C[5], S[4], X[4], Y[4], Z[4]);
  UBFA_5 U2 (C[6], S[5], X[5], Y[5], Z[5]);
  UBFA_6 U3 (C[7], S[6], X[6], Y[6], Z[6]);
  UBFA_7 U4 (C[8], S[7], X[7], Y[7], Z[7]);
  UBFA_8 U5 (C[9], S[8], X[8], Y[8], Z[8]);
  UBFA_9 U6 (C[10], S[9], X[9], Y[9], Z[9]);
  UBFA_10 U7 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U8 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U9 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U10 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U11 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U12 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U13 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U14 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U15 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U16 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U17 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U18 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U19 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U20 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U21 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U22 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U23 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U24 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U25 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U26 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U27 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U28 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U29 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U30 (C[34], S[33], X[33], Y[33], Z[33]);
endmodule

module PureCSA_34_5 (C, S, X, Y, Z);
  output [35:6] C;
  output [34:5] S;
  input [34:5] X;
  input [34:5] Y;
  input [34:5] Z;
  UBFA_5 U0 (C[6], S[5], X[5], Y[5], Z[5]);
  UBFA_6 U1 (C[7], S[6], X[6], Y[6], Z[6]);
  UBFA_7 U2 (C[8], S[7], X[7], Y[7], Z[7]);
  UBFA_8 U3 (C[9], S[8], X[8], Y[8], Z[8]);
  UBFA_9 U4 (C[10], S[9], X[9], Y[9], Z[9]);
  UBFA_10 U5 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U6 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U7 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U8 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U9 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U10 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U11 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U12 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U13 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U14 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U15 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U16 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U17 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U18 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U19 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U20 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U21 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U22 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U23 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U24 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U25 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U26 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U27 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U28 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U29 (C[35], S[34], X[34], Y[34], Z[34]);
endmodule

module PureCSA_36_8 (C, S, X, Y, Z);
  output [37:9] C;
  output [36:8] S;
  input [36:8] X;
  input [36:8] Y;
  input [36:8] Z;
  UBFA_8 U0 (C[9], S[8], X[8], Y[8], Z[8]);
  UBFA_9 U1 (C[10], S[9], X[9], Y[9], Z[9]);
  UBFA_10 U2 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U3 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U4 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U5 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U6 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U7 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U8 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U9 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U10 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U11 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U12 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U13 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U14 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U15 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U16 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U17 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U18 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U19 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U20 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U21 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U22 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U23 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U24 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U25 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U26 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U27 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U28 (C[37], S[36], X[36], Y[36], Z[36]);
endmodule

module PureCSA_37_7 (C, S, X, Y, Z);
  output [38:8] C;
  output [37:7] S;
  input [37:7] X;
  input [37:7] Y;
  input [37:7] Z;
  UBFA_7 U0 (C[8], S[7], X[7], Y[7], Z[7]);
  UBFA_8 U1 (C[9], S[8], X[8], Y[8], Z[8]);
  UBFA_9 U2 (C[10], S[9], X[9], Y[9], Z[9]);
  UBFA_10 U3 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U4 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U5 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U6 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U7 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U8 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U9 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U10 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U11 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U12 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U13 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U14 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U15 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U16 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U17 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U18 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U19 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U20 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U21 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U22 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U23 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U24 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U25 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U26 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U27 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U28 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U29 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U30 (C[38], S[37], X[37], Y[37], Z[37]);
endmodule

module PureCSA_37_8 (C, S, X, Y, Z);
  output [38:9] C;
  output [37:8] S;
  input [37:8] X;
  input [37:8] Y;
  input [37:8] Z;
  UBFA_8 U0 (C[9], S[8], X[8], Y[8], Z[8]);
  UBFA_9 U1 (C[10], S[9], X[9], Y[9], Z[9]);
  UBFA_10 U2 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U3 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U4 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U5 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U6 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U7 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U8 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U9 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U10 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U11 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U12 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U13 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U14 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U15 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U16 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U17 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U18 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U19 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U20 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U21 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U22 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U23 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U24 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U25 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U26 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U27 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U28 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U29 (C[38], S[37], X[37], Y[37], Z[37]);
endmodule

module PureCSA_40_10 (C, S, X, Y, Z);
  output [41:11] C;
  output [40:10] S;
  input [40:10] X;
  input [40:10] Y;
  input [40:10] Z;
  UBFA_10 U0 (C[11], S[10], X[10], Y[10], Z[10]);
  UBFA_11 U1 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U2 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U3 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U4 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U5 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U6 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U7 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U8 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U9 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U10 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U11 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U12 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U13 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U14 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U15 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U16 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U17 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U18 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U19 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U20 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U21 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U22 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U23 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U24 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U25 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U26 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U27 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U28 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U29 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U30 (C[41], S[40], X[40], Y[40], Z[40]);
endmodule

module PureCSA_40_11 (C, S, X, Y, Z);
  output [41:12] C;
  output [40:11] S;
  input [40:11] X;
  input [40:11] Y;
  input [40:11] Z;
  UBFA_11 U0 (C[12], S[11], X[11], Y[11], Z[11]);
  UBFA_12 U1 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U2 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U3 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U4 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U5 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U6 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U7 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U8 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U9 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U10 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U11 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U12 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U13 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U14 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U15 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U16 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U17 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U18 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U19 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U20 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U21 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U22 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U23 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U24 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U25 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U26 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U27 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U28 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U29 (C[41], S[40], X[40], Y[40], Z[40]);
endmodule

module PureCSA_40_12 (C, S, X, Y, Z);
  output [41:13] C;
  output [40:12] S;
  input [40:12] X;
  input [40:12] Y;
  input [40:12] Z;
  UBFA_12 U0 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U1 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U2 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U3 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U4 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U5 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U6 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U7 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U8 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U9 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U10 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U11 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U12 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U13 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U14 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U15 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U16 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U17 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U18 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U19 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U20 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U21 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U22 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U23 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U24 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U25 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U26 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U27 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U28 (C[41], S[40], X[40], Y[40], Z[40]);
endmodule

module PureCSA_42_12 (C, S, X, Y, Z);
  output [43:13] C;
  output [42:12] S;
  input [42:12] X;
  input [42:12] Y;
  input [42:12] Z;
  UBFA_12 U0 (C[13], S[12], X[12], Y[12], Z[12]);
  UBFA_13 U1 (C[14], S[13], X[13], Y[13], Z[13]);
  UBFA_14 U2 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U3 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U4 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U5 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U6 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U7 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U8 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U9 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U10 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U11 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U12 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U13 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U14 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U15 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U16 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U17 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U18 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U19 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U20 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U21 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U22 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U23 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U24 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U25 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U26 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U27 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U28 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U29 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U30 (C[43], S[42], X[42], Y[42], Z[42]);
endmodule

module PureCSA_44_14 (C, S, X, Y, Z);
  output [45:15] C;
  output [44:14] S;
  input [44:14] X;
  input [44:14] Y;
  input [44:14] Z;
  UBFA_14 U0 (C[15], S[14], X[14], Y[14], Z[14]);
  UBFA_15 U1 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U2 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U3 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U4 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U5 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U6 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U7 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U8 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U9 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U10 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U11 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U12 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U13 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U14 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U15 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U16 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U17 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U18 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U19 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U20 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U21 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U22 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U23 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U24 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U25 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U26 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U27 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U28 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U29 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U30 (C[45], S[44], X[44], Y[44], Z[44]);
endmodule

module PureCSA_44_15 (C, S, X, Y, Z);
  output [45:16] C;
  output [44:15] S;
  input [44:15] X;
  input [44:15] Y;
  input [44:15] Z;
  UBFA_15 U0 (C[16], S[15], X[15], Y[15], Z[15]);
  UBFA_16 U1 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U2 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U3 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U4 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U5 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U6 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U7 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U8 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U9 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U10 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U11 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U12 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U13 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U14 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U15 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U16 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U17 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U18 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U19 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U20 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U21 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U22 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U23 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U24 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U25 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U26 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U27 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U28 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U29 (C[45], S[44], X[44], Y[44], Z[44]);
endmodule

module PureCSA_44_16 (C, S, X, Y, Z);
  output [45:17] C;
  output [44:16] S;
  input [44:16] X;
  input [44:16] Y;
  input [44:16] Z;
  UBFA_16 U0 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U1 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U2 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U3 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U4 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U5 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U6 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U7 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U8 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U9 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U10 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U11 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U12 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U13 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U14 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U15 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U16 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U17 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U18 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U19 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U20 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U21 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U22 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U23 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U24 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U25 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U26 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U27 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U28 (C[45], S[44], X[44], Y[44], Z[44]);
endmodule

module PureCSA_46_16 (C, S, X, Y, Z);
  output [47:17] C;
  output [46:16] S;
  input [46:16] X;
  input [46:16] Y;
  input [46:16] Z;
  UBFA_16 U0 (C[17], S[16], X[16], Y[16], Z[16]);
  UBFA_17 U1 (C[18], S[17], X[17], Y[17], Z[17]);
  UBFA_18 U2 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U3 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U4 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U5 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U6 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U7 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U8 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U9 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U10 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U11 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U12 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U13 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U14 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U15 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U16 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U17 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U18 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U19 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U20 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U21 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U22 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U23 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U24 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U25 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U26 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U27 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U28 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U29 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U30 (C[47], S[46], X[46], Y[46], Z[46]);
endmodule

module PureCSA_47_18 (C, S, X, Y, Z);
  output [48:19] C;
  output [47:18] S;
  input [47:18] X;
  input [47:18] Y;
  input [47:18] Z;
  UBFA_18 U0 (C[19], S[18], X[18], Y[18], Z[18]);
  UBFA_19 U1 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U2 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U3 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U4 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U5 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U6 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U7 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U8 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U9 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U10 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U11 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U12 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U13 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U14 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U15 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U16 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U17 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U18 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U19 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U20 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U21 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U22 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U23 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U24 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U25 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U26 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U27 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U28 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U29 (C[48], S[47], X[47], Y[47], Z[47]);
endmodule

module PureCSA_48_21 (C, S, X, Y, Z);
  output [49:22] C;
  output [48:21] S;
  input [48:21] X;
  input [48:21] Y;
  input [48:21] Z;
  UBFA_21 U0 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U1 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U2 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U3 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U4 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U5 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U6 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U7 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U8 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U9 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U10 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U11 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U12 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U13 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U14 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U15 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U16 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U17 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U18 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U19 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U20 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U21 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U22 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U23 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U24 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U25 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U26 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U27 (C[49], S[48], X[48], Y[48], Z[48]);
endmodule

module PureCSA_49_21 (C, S, X, Y, Z);
  output [50:22] C;
  output [49:21] S;
  input [49:21] X;
  input [49:21] Y;
  input [49:21] Z;
  UBFA_21 U0 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U1 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U2 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U3 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U4 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U5 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U6 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U7 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U8 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U9 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U10 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U11 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U12 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U13 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U14 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U15 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U16 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U17 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U18 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U19 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U20 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U21 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U22 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U23 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U24 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U25 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U26 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U27 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U28 (C[50], S[49], X[49], Y[49], Z[49]);
endmodule

module PureCSA_50_19 (C, S, X, Y, Z);
  output [51:20] C;
  output [50:19] S;
  input [50:19] X;
  input [50:19] Y;
  input [50:19] Z;
  UBFA_19 U0 (C[20], S[19], X[19], Y[19], Z[19]);
  UBFA_20 U1 (C[21], S[20], X[20], Y[20], Z[20]);
  UBFA_21 U2 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U3 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U4 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U5 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U6 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U7 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U8 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U9 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U10 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U11 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U12 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U13 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U14 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U15 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U16 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U17 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U18 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U19 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U20 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U21 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U22 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U23 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U24 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U25 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U26 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U27 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U28 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U29 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U30 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U31 (C[51], S[50], X[50], Y[50], Z[50]);
endmodule

module PureCSA_50_21 (C, S, X, Y, Z);
  output [51:22] C;
  output [50:21] S;
  input [50:21] X;
  input [50:21] Y;
  input [50:21] Z;
  UBFA_21 U0 (C[22], S[21], X[21], Y[21], Z[21]);
  UBFA_22 U1 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U2 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U3 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U4 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U5 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U6 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U7 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U8 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U9 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U10 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U11 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U12 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U13 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U14 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U15 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U16 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U17 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U18 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U19 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U20 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U21 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U22 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U23 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U24 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U25 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U26 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U27 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U28 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U29 (C[51], S[50], X[50], Y[50], Z[50]);
endmodule

module PureCSA_52_22 (C, S, X, Y, Z);
  output [53:23] C;
  output [52:22] S;
  input [52:22] X;
  input [52:22] Y;
  input [52:22] Z;
  UBFA_22 U0 (C[23], S[22], X[22], Y[22], Z[22]);
  UBFA_23 U1 (C[24], S[23], X[23], Y[23], Z[23]);
  UBFA_24 U2 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U3 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U4 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U5 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U6 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U7 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U8 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U9 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U10 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U11 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U12 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U13 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U14 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U15 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U16 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U17 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U18 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U19 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U20 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U21 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U22 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U23 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U24 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U25 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U26 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U27 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U28 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U29 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U30 (C[53], S[52], X[52], Y[52], Z[52]);
endmodule

module PureCSA_53_24 (C, S, X, Y, Z);
  output [54:25] C;
  output [53:24] S;
  input [53:24] X;
  input [53:24] Y;
  input [53:24] Z;
  UBFA_24 U0 (C[25], S[24], X[24], Y[24], Z[24]);
  UBFA_25 U1 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U2 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U3 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U4 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U5 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U6 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U7 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U8 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U9 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U10 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U11 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U12 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U13 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U14 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U15 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U16 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U17 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U18 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U19 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U20 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U21 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U22 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U23 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U24 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U25 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U26 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U27 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U28 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U29 (C[54], S[53], X[53], Y[53], Z[53]);
endmodule

module PureCSA_55_25 (C, S, X, Y, Z);
  output [56:26] C;
  output [55:25] S;
  input [55:25] X;
  input [55:25] Y;
  input [55:25] Z;
  UBFA_25 U0 (C[26], S[25], X[25], Y[25], Z[25]);
  UBFA_26 U1 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U2 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U3 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U4 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U5 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U6 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U7 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U8 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U9 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U10 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U11 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U12 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U13 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U14 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U15 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U16 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U17 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U18 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U19 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U20 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U21 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U22 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U23 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U24 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U25 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U26 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U27 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U28 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U29 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U30 (C[56], S[55], X[55], Y[55], Z[55]);
endmodule

module PureCSA_55_29 (C, S, X, Y, Z);
  output [56:30] C;
  output [55:29] S;
  input [55:29] X;
  input [55:29] Y;
  input [55:29] Z;
  UBFA_29 U0 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U1 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U2 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U3 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U4 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U5 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U6 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U7 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U8 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U9 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U10 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U11 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U12 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U13 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U14 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U15 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U16 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U17 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U18 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U19 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U20 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U21 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U22 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U23 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U24 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U25 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U26 (C[56], S[55], X[55], Y[55], Z[55]);
endmodule

module PureCSA_56_27 (C, S, X, Y, Z);
  output [57:28] C;
  output [56:27] S;
  input [56:27] X;
  input [56:27] Y;
  input [56:27] Z;
  UBFA_27 U0 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U1 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U2 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U3 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U4 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U5 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U6 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U7 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U8 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U9 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U10 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U11 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U12 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U13 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U14 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U15 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U16 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U17 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U18 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U19 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U20 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U21 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U22 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U23 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U24 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U25 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U26 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U27 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U28 (C[56], S[55], X[55], Y[55], Z[55]);
  UBFA_56 U29 (C[57], S[56], X[56], Y[56], Z[56]);
endmodule

module PureCSA_56_29 (C, S, X, Y, Z);
  output [57:30] C;
  output [56:29] S;
  input [56:29] X;
  input [56:29] Y;
  input [56:29] Z;
  UBFA_29 U0 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U1 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U2 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U3 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U4 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U5 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U6 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U7 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U8 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U9 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U10 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U11 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U12 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U13 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U14 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U15 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U16 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U17 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U18 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U19 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U20 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U21 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U22 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U23 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U24 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U25 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U26 (C[56], S[55], X[55], Y[55], Z[55]);
  UBFA_56 U27 (C[57], S[56], X[56], Y[56], Z[56]);
endmodule

module PureCSA_58_30 (C, S, X, Y, Z);
  output [59:31] C;
  output [58:30] S;
  input [58:30] X;
  input [58:30] Y;
  input [58:30] Z;
  UBFA_30 U0 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U1 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U2 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U3 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U4 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U5 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U6 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U7 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U8 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U9 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U10 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U11 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U12 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U13 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U14 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U15 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U16 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U17 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U18 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U19 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U20 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U21 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U22 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U23 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U24 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U25 (C[56], S[55], X[55], Y[55], Z[55]);
  UBFA_56 U26 (C[57], S[56], X[56], Y[56], Z[56]);
  UBFA_57 U27 (C[58], S[57], X[57], Y[57], Z[57]);
  UBFA_58 U28 (C[59], S[58], X[58], Y[58], Z[58]);
endmodule

module PureCSA_59_26 (C, S, X, Y, Z);
  output [60:27] C;
  output [59:26] S;
  input [59:26] X;
  input [59:26] Y;
  input [59:26] Z;
  UBFA_26 U0 (C[27], S[26], X[26], Y[26], Z[26]);
  UBFA_27 U1 (C[28], S[27], X[27], Y[27], Z[27]);
  UBFA_28 U2 (C[29], S[28], X[28], Y[28], Z[28]);
  UBFA_29 U3 (C[30], S[29], X[29], Y[29], Z[29]);
  UBFA_30 U4 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U5 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U6 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U7 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U8 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U9 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U10 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U11 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U12 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U13 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U14 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U15 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U16 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U17 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U18 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U19 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U20 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U21 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U22 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U23 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U24 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U25 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U26 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U27 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U28 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U29 (C[56], S[55], X[55], Y[55], Z[55]);
  UBFA_56 U30 (C[57], S[56], X[56], Y[56], Z[56]);
  UBFA_57 U31 (C[58], S[57], X[57], Y[57], Z[57]);
  UBFA_58 U32 (C[59], S[58], X[58], Y[58], Z[58]);
  UBFA_59 U33 (C[60], S[59], X[59], Y[59], Z[59]);
endmodule

module PureCSA_59_30 (C, S, X, Y, Z);
  output [60:31] C;
  output [59:30] S;
  input [59:30] X;
  input [59:30] Y;
  input [59:30] Z;
  UBFA_30 U0 (C[31], S[30], X[30], Y[30], Z[30]);
  UBFA_31 U1 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U2 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U3 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U4 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U5 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U6 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U7 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U8 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U9 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U10 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U11 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U12 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U13 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U14 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U15 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U16 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U17 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U18 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U19 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U20 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U21 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U22 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U23 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U24 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U25 (C[56], S[55], X[55], Y[55], Z[55]);
  UBFA_56 U26 (C[57], S[56], X[56], Y[56], Z[56]);
  UBFA_57 U27 (C[58], S[57], X[57], Y[57], Z[57]);
  UBFA_58 U28 (C[59], S[58], X[58], Y[58], Z[58]);
  UBFA_59 U29 (C[60], S[59], X[59], Y[59], Z[59]);
endmodule

module PureCSA_62_31 (C, S, X, Y, Z);
  output [63:32] C;
  output [62:31] S;
  input [62:31] X;
  input [62:31] Y;
  input [62:31] Z;
  UBFA_31 U0 (C[32], S[31], X[31], Y[31], Z[31]);
  UBFA_32 U1 (C[33], S[32], X[32], Y[32], Z[32]);
  UBFA_33 U2 (C[34], S[33], X[33], Y[33], Z[33]);
  UBFA_34 U3 (C[35], S[34], X[34], Y[34], Z[34]);
  UBFA_35 U4 (C[36], S[35], X[35], Y[35], Z[35]);
  UBFA_36 U5 (C[37], S[36], X[36], Y[36], Z[36]);
  UBFA_37 U6 (C[38], S[37], X[37], Y[37], Z[37]);
  UBFA_38 U7 (C[39], S[38], X[38], Y[38], Z[38]);
  UBFA_39 U8 (C[40], S[39], X[39], Y[39], Z[39]);
  UBFA_40 U9 (C[41], S[40], X[40], Y[40], Z[40]);
  UBFA_41 U10 (C[42], S[41], X[41], Y[41], Z[41]);
  UBFA_42 U11 (C[43], S[42], X[42], Y[42], Z[42]);
  UBFA_43 U12 (C[44], S[43], X[43], Y[43], Z[43]);
  UBFA_44 U13 (C[45], S[44], X[44], Y[44], Z[44]);
  UBFA_45 U14 (C[46], S[45], X[45], Y[45], Z[45]);
  UBFA_46 U15 (C[47], S[46], X[46], Y[46], Z[46]);
  UBFA_47 U16 (C[48], S[47], X[47], Y[47], Z[47]);
  UBFA_48 U17 (C[49], S[48], X[48], Y[48], Z[48]);
  UBFA_49 U18 (C[50], S[49], X[49], Y[49], Z[49]);
  UBFA_50 U19 (C[51], S[50], X[50], Y[50], Z[50]);
  UBFA_51 U20 (C[52], S[51], X[51], Y[51], Z[51]);
  UBFA_52 U21 (C[53], S[52], X[52], Y[52], Z[52]);
  UBFA_53 U22 (C[54], S[53], X[53], Y[53], Z[53]);
  UBFA_54 U23 (C[55], S[54], X[54], Y[54], Z[54]);
  UBFA_55 U24 (C[56], S[55], X[55], Y[55], Z[55]);
  UBFA_56 U25 (C[57], S[56], X[56], Y[56], Z[56]);
  UBFA_57 U26 (C[58], S[57], X[57], Y[57], Z[57]);
  UBFA_58 U27 (C[59], S[58], X[58], Y[58], Z[58]);
  UBFA_59 U28 (C[60], S[59], X[59], Y[59], Z[59]);
  UBFA_60 U29 (C[61], S[60], X[60], Y[60], Z[60]);
  UBFA_61 U30 (C[62], S[61], X[61], Y[61], Z[61]);
  UBFA_62 U31 (C[63], S[62], X[62], Y[62], Z[62]);
endmodule

module PureCSHA_11_9 (C, S, X, Y);
  output [12:10] C;
  output [11:9] S;
  input [11:9] X;
  input [11:9] Y;
  UBHA_9 U0 (C[10], S[9], X[9], Y[9]);
  UBHA_10 U1 (C[11], S[10], X[10], Y[10]);
  UBHA_11 U2 (C[12], S[11], X[11], Y[11]);
endmodule

module PureCSHA_13_6 (C, S, X, Y);
  output [14:7] C;
  output [13:6] S;
  input [13:6] X;
  input [13:6] Y;
  UBHA_6 U0 (C[7], S[6], X[6], Y[6]);
  UBHA_7 U1 (C[8], S[7], X[7], Y[7]);
  UBHA_8 U2 (C[9], S[8], X[8], Y[8]);
  UBHA_9 U3 (C[10], S[9], X[9], Y[9]);
  UBHA_10 U4 (C[11], S[10], X[10], Y[10]);
  UBHA_11 U5 (C[12], S[11], X[11], Y[11]);
  UBHA_12 U6 (C[13], S[12], X[12], Y[12]);
  UBHA_13 U7 (C[14], S[13], X[13], Y[13]);
endmodule

module PureCSHA_15_13 (C, S, X, Y);
  output [16:14] C;
  output [15:13] S;
  input [15:13] X;
  input [15:13] Y;
  UBHA_13 U0 (C[14], S[13], X[13], Y[13]);
  UBHA_14 U1 (C[15], S[14], X[14], Y[14]);
  UBHA_15 U2 (C[16], S[15], X[15], Y[15]);
endmodule

module PureCSHA_18_7 (C, S, X, Y);
  output [19:8] C;
  output [18:7] S;
  input [18:7] X;
  input [18:7] Y;
  UBHA_7 U0 (C[8], S[7], X[7], Y[7]);
  UBHA_8 U1 (C[9], S[8], X[8], Y[8]);
  UBHA_9 U2 (C[10], S[9], X[9], Y[9]);
  UBHA_10 U3 (C[11], S[10], X[10], Y[10]);
  UBHA_11 U4 (C[12], S[11], X[11], Y[11]);
  UBHA_12 U5 (C[13], S[12], X[12], Y[12]);
  UBHA_13 U6 (C[14], S[13], X[13], Y[13]);
  UBHA_14 U7 (C[15], S[14], X[14], Y[14]);
  UBHA_15 U8 (C[16], S[15], X[15], Y[15]);
  UBHA_16 U9 (C[17], S[16], X[16], Y[16]);
  UBHA_17 U10 (C[18], S[17], X[17], Y[17]);
  UBHA_18 U11 (C[19], S[18], X[18], Y[18]);
endmodule

module PureCSHA_20_18 (C, S, X, Y);
  output [21:19] C;
  output [20:18] S;
  input [20:18] X;
  input [20:18] Y;
  UBHA_18 U0 (C[19], S[18], X[18], Y[18]);
  UBHA_19 U1 (C[20], S[19], X[19], Y[19]);
  UBHA_20 U2 (C[21], S[20], X[20], Y[20]);
endmodule

module PureCSHA_20_19 (C, S, X, Y);
  output [21:20] C;
  output [20:19] S;
  input [20:19] X;
  input [20:19] Y;
  UBHA_19 U0 (C[20], S[19], X[19], Y[19]);
  UBHA_20 U1 (C[21], S[20], X[20], Y[20]);
endmodule

module PureCSHA_21_20 (C, S, X, Y);
  output [22:21] C;
  output [21:20] S;
  input [21:20] X;
  input [21:20] Y;
  UBHA_20 U0 (C[21], S[20], X[20], Y[20]);
  UBHA_21 U1 (C[22], S[21], X[21], Y[21]);
endmodule

module PureCSHA_25_8 (C, S, X, Y);
  output [26:9] C;
  output [25:8] S;
  input [25:8] X;
  input [25:8] Y;
  UBHA_8 U0 (C[9], S[8], X[8], Y[8]);
  UBHA_9 U1 (C[10], S[9], X[9], Y[9]);
  UBHA_10 U2 (C[11], S[10], X[10], Y[10]);
  UBHA_11 U3 (C[12], S[11], X[11], Y[11]);
  UBHA_12 U4 (C[13], S[12], X[12], Y[12]);
  UBHA_13 U5 (C[14], S[13], X[13], Y[13]);
  UBHA_14 U6 (C[15], S[14], X[14], Y[14]);
  UBHA_15 U7 (C[16], S[15], X[15], Y[15]);
  UBHA_16 U8 (C[17], S[16], X[16], Y[16]);
  UBHA_17 U9 (C[18], S[17], X[17], Y[17]);
  UBHA_18 U10 (C[19], S[18], X[18], Y[18]);
  UBHA_19 U11 (C[20], S[19], X[19], Y[19]);
  UBHA_20 U12 (C[21], S[20], X[20], Y[20]);
  UBHA_21 U13 (C[22], S[21], X[21], Y[21]);
  UBHA_22 U14 (C[23], S[22], X[22], Y[22]);
  UBHA_23 U15 (C[24], S[23], X[23], Y[23]);
  UBHA_24 U16 (C[25], S[24], X[24], Y[24]);
  UBHA_25 U17 (C[26], S[25], X[25], Y[25]);
endmodule

module PureCSHA_28_25 (C, S, X, Y);
  output [29:26] C;
  output [28:25] S;
  input [28:25] X;
  input [28:25] Y;
  UBHA_25 U0 (C[26], S[25], X[25], Y[25]);
  UBHA_26 U1 (C[27], S[26], X[26], Y[26]);
  UBHA_27 U2 (C[28], S[27], X[27], Y[27]);
  UBHA_28 U3 (C[29], S[28], X[28], Y[28]);
endmodule

module PureCSHA_28_27 (C, S, X, Y);
  output [29:28] C;
  output [28:27] S;
  input [28:27] X;
  input [28:27] Y;
  UBHA_27 U0 (C[28], S[27], X[27], Y[27]);
  UBHA_28 U1 (C[29], S[28], X[28], Y[28]);
endmodule

module PureCSHA_29_28 (C, S, X, Y);
  output [30:29] C;
  output [29:28] S;
  input [29:28] X;
  input [29:28] Y;
  UBHA_28 U0 (C[29], S[28], X[28], Y[28]);
  UBHA_29 U1 (C[30], S[29], X[29], Y[29]);
endmodule

module PureCSHA_30_28 (C, S, X, Y);
  output [31:29] C;
  output [30:28] S;
  input [30:28] X;
  input [30:28] Y;
  UBHA_28 U0 (C[29], S[28], X[28], Y[28]);
  UBHA_29 U1 (C[30], S[29], X[29], Y[29]);
  UBHA_30 U2 (C[31], S[30], X[30], Y[30]);
endmodule

module PureCSHA_36_35 (C, S, X, Y);
  output [37:36] C;
  output [36:35] S;
  input [36:35] X;
  input [36:35] Y;
  UBHA_35 U0 (C[36], S[35], X[35], Y[35]);
  UBHA_36 U1 (C[37], S[36], X[36], Y[36]);
endmodule

module PureCSHA_39_37 (C, S, X, Y);
  output [40:38] C;
  output [39:37] S;
  input [39:37] X;
  input [39:37] Y;
  UBHA_37 U0 (C[38], S[37], X[37], Y[37]);
  UBHA_38 U1 (C[39], S[38], X[38], Y[38]);
  UBHA_39 U2 (C[40], S[39], X[39], Y[39]);
endmodule

module PureCSHA_39_38 (C, S, X, Y);
  output [40:39] C;
  output [39:38] S;
  input [39:38] X;
  input [39:38] Y;
  UBHA_38 U0 (C[39], S[38], X[38], Y[38]);
  UBHA_39 U1 (C[40], S[39], X[39], Y[39]);
endmodule

module PureCSHA_43_41 (C, S, X, Y);
  output [44:42] C;
  output [43:41] S;
  input [43:41] X;
  input [43:41] Y;
  UBHA_41 U0 (C[42], S[41], X[41], Y[41]);
  UBHA_42 U1 (C[43], S[42], X[42], Y[42]);
  UBHA_43 U2 (C[44], S[43], X[43], Y[43]);
endmodule

module PureCSHA_47_45 (C, S, X, Y);
  output [48:46] C;
  output [47:45] S;
  input [47:45] X;
  input [47:45] Y;
  UBHA_45 U0 (C[46], S[45], X[45], Y[45]);
  UBHA_46 U1 (C[47], S[46], X[46], Y[46]);
  UBHA_47 U2 (C[48], S[47], X[47], Y[47]);
endmodule

module PureCSHA_49_45 (C, S, X, Y);
  output [50:46] C;
  output [49:45] S;
  input [49:45] X;
  input [49:45] Y;
  UBHA_45 U0 (C[46], S[45], X[45], Y[45]);
  UBHA_46 U1 (C[47], S[46], X[46], Y[46]);
  UBHA_47 U2 (C[48], S[47], X[47], Y[47]);
  UBHA_48 U3 (C[49], S[48], X[48], Y[48]);
  UBHA_49 U4 (C[50], S[49], X[49], Y[49]);
endmodule

module PureCSHA_4_3 (C, S, X, Y);
  output [5:4] C;
  output [4:3] S;
  input [4:3] X;
  input [4:3] Y;
  UBHA_3 U0 (C[4], S[3], X[3], Y[3]);
  UBHA_4 U1 (C[5], S[4], X[4], Y[4]);
endmodule

module PureCSHA_52_50 (C, S, X, Y);
  output [53:51] C;
  output [52:50] S;
  input [52:50] X;
  input [52:50] Y;
  UBHA_50 U0 (C[51], S[50], X[50], Y[50]);
  UBHA_51 U1 (C[52], S[51], X[51], Y[51]);
  UBHA_52 U2 (C[53], S[52], X[52], Y[52]);
endmodule

module PureCSHA_54_49 (C, S, X, Y);
  output [55:50] C;
  output [54:49] S;
  input [54:49] X;
  input [54:49] Y;
  UBHA_49 U0 (C[50], S[49], X[49], Y[49]);
  UBHA_50 U1 (C[51], S[50], X[50], Y[50]);
  UBHA_51 U2 (C[52], S[51], X[51], Y[51]);
  UBHA_52 U3 (C[53], S[52], X[52], Y[52]);
  UBHA_53 U4 (C[54], S[53], X[53], Y[53]);
  UBHA_54 U5 (C[55], S[54], X[54], Y[54]);
endmodule

module PureCSHA_58_51 (C, S, X, Y);
  output [59:52] C;
  output [58:51] S;
  input [58:51] X;
  input [58:51] Y;
  UBHA_51 U0 (C[52], S[51], X[51], Y[51]);
  UBHA_52 U1 (C[53], S[52], X[52], Y[52]);
  UBHA_53 U2 (C[54], S[53], X[53], Y[53]);
  UBHA_54 U3 (C[55], S[54], X[54], Y[54]);
  UBHA_55 U4 (C[56], S[55], X[55], Y[55]);
  UBHA_56 U5 (C[57], S[56], X[56], Y[56]);
  UBHA_57 U6 (C[58], S[57], X[57], Y[57]);
  UBHA_58 U7 (C[59], S[58], X[58], Y[58]);
endmodule

module PureCSHA_61_57 (C, S, X, Y);
  output [62:58] C;
  output [61:57] S;
  input [61:57] X;
  input [61:57] Y;
  UBHA_57 U0 (C[58], S[57], X[57], Y[57]);
  UBHA_58 U1 (C[59], S[58], X[58], Y[58]);
  UBHA_59 U2 (C[60], S[59], X[59], Y[59]);
  UBHA_60 U3 (C[61], S[60], X[60], Y[60]);
  UBHA_61 U4 (C[62], S[61], X[61], Y[61]);
endmodule

module PureCSHA_61_59 (C, S, X, Y);
  output [62:60] C;
  output [61:59] S;
  input [61:59] X;
  input [61:59] Y;
  UBHA_59 U0 (C[60], S[59], X[59], Y[59]);
  UBHA_60 U1 (C[61], S[60], X[60], Y[60]);
  UBHA_61 U2 (C[62], S[61], X[61], Y[61]);
endmodule

module PureCSHA_62_56 (C, S, X, Y);
  output [63:57] C;
  output [62:56] S;
  input [62:56] X;
  input [62:56] Y;
  UBHA_56 U0 (C[57], S[56], X[56], Y[56]);
  UBHA_57 U1 (C[58], S[57], X[57], Y[57]);
  UBHA_58 U2 (C[59], S[58], X[58], Y[58]);
  UBHA_59 U3 (C[60], S[59], X[59], Y[59]);
  UBHA_60 U4 (C[61], S[60], X[60], Y[60]);
  UBHA_61 U5 (C[62], S[61], X[61], Y[61]);
  UBHA_62 U6 (C[63], S[62], X[62], Y[62]);
endmodule

module PureCSHA_63_60 (C, S, X, Y);
  output [64:61] C;
  output [63:60] S;
  input [63:60] X;
  input [63:60] Y;
  UBHA_60 U0 (C[61], S[60], X[60], Y[60]);
  UBHA_61 U1 (C[62], S[61], X[61], Y[61]);
  UBHA_62 U2 (C[63], S[62], X[62], Y[62]);
  UBHA_63 U3 (C[64], S[63], X[63], Y[63]);
endmodule

module PureCSHA_6_4 (C, S, X, Y);
  output [7:5] C;
  output [6:4] S;
  input [6:4] X;
  input [6:4] Y;
  UBHA_4 U0 (C[5], S[4], X[4], Y[4]);
  UBHA_5 U1 (C[6], S[5], X[5], Y[5]);
  UBHA_6 U2 (C[7], S[6], X[6], Y[6]);
endmodule

module PureCSHA_7_6 (C, S, X, Y);
  output [8:7] C;
  output [7:6] S;
  input [7:6] X;
  input [7:6] Y;
  UBHA_6 U0 (C[7], S[6], X[6], Y[6]);
  UBHA_7 U1 (C[8], S[7], X[7], Y[7]);
endmodule

module PureCSHA_9_5 (C, S, X, Y);
  output [10:6] C;
  output [9:5] S;
  input [9:5] X;
  input [9:5] Y;
  UBHA_5 U0 (C[6], S[5], X[5], Y[5]);
  UBHA_6 U1 (C[7], S[6], X[6], Y[6]);
  UBHA_7 U2 (C[8], S[7], X[7], Y[7]);
  UBHA_8 U3 (C[9], S[8], X[8], Y[8]);
  UBHA_9 U4 (C[10], S[9], X[9], Y[9]);
endmodule

module TCNVPPG_31_0_31 (O, IN1, IN2);
  output [62:31] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire [61:31] NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UN1BPPG_0_31 U1 (NEG[31], IN1P[0], IN2);
  UN1BPPG_1_31 U2 (NEG[32], IN1P[1], IN2);
  UN1BPPG_2_31 U3 (NEG[33], IN1P[2], IN2);
  UN1BPPG_3_31 U4 (NEG[34], IN1P[3], IN2);
  UN1BPPG_4_31 U5 (NEG[35], IN1P[4], IN2);
  UN1BPPG_5_31 U6 (NEG[36], IN1P[5], IN2);
  UN1BPPG_6_31 U7 (NEG[37], IN1P[6], IN2);
  UN1BPPG_7_31 U8 (NEG[38], IN1P[7], IN2);
  UN1BPPG_8_31 U9 (NEG[39], IN1P[8], IN2);
  UN1BPPG_9_31 U10 (NEG[40], IN1P[9], IN2);
  UN1BPPG_10_31 U11 (NEG[41], IN1P[10], IN2);
  UN1BPPG_11_31 U12 (NEG[42], IN1P[11], IN2);
  UN1BPPG_12_31 U13 (NEG[43], IN1P[12], IN2);
  UN1BPPG_13_31 U14 (NEG[44], IN1P[13], IN2);
  UN1BPPG_14_31 U15 (NEG[45], IN1P[14], IN2);
  UN1BPPG_15_31 U16 (NEG[46], IN1P[15], IN2);
  UN1BPPG_16_31 U17 (NEG[47], IN1P[16], IN2);
  UN1BPPG_17_31 U18 (NEG[48], IN1P[17], IN2);
  UN1BPPG_18_31 U19 (NEG[49], IN1P[18], IN2);
  UN1BPPG_19_31 U20 (NEG[50], IN1P[19], IN2);
  UN1BPPG_20_31 U21 (NEG[51], IN1P[20], IN2);
  UN1BPPG_21_31 U22 (NEG[52], IN1P[21], IN2);
  UN1BPPG_22_31 U23 (NEG[53], IN1P[22], IN2);
  UN1BPPG_23_31 U24 (NEG[54], IN1P[23], IN2);
  UN1BPPG_24_31 U25 (NEG[55], IN1P[24], IN2);
  UN1BPPG_25_31 U26 (NEG[56], IN1P[25], IN2);
  UN1BPPG_26_31 U27 (NEG[57], IN1P[26], IN2);
  UN1BPPG_27_31 U28 (NEG[58], IN1P[27], IN2);
  UN1BPPG_28_31 U29 (NEG[59], IN1P[28], IN2);
  UN1BPPG_29_31 U30 (NEG[60], IN1P[29], IN2);
  UN1BPPG_30_31 U31 (NEG[61], IN1P[30], IN2);
  NUB1BPPG_31_31 U32 (O[62], IN1N, IN2);
  NUBUBCON_61_31 U33 (O[61:31], NEG);
endmodule

module TCPPG_31_0_31_0 (PP0, PP1, PP2, PP3, PP4, PP5, PP6, PP7, PP8, PP9, PP10, PP11, PP12, PP13, PP14, PP15, PP16, PP17, PP18, PP19, PP20, PP21, PP22, PP23, PP24, PP25, PP26, PP27, PP28, PP29, PP30, PP31, IN1, IN2);
  output [32:0] PP0;
  output [32:1] PP1;
  output [41:10] PP10;
  output [42:11] PP11;
  output [43:12] PP12;
  output [44:13] PP13;
  output [45:14] PP14;
  output [46:15] PP15;
  output [47:16] PP16;
  output [48:17] PP17;
  output [49:18] PP18;
  output [50:19] PP19;
  output [33:2] PP2;
  output [51:20] PP20;
  output [52:21] PP21;
  output [53:22] PP22;
  output [54:23] PP23;
  output [55:24] PP24;
  output [56:25] PP25;
  output [57:26] PP26;
  output [58:27] PP27;
  output [59:28] PP28;
  output [60:29] PP29;
  output [34:3] PP3;
  output [61:30] PP30;
  output [62:31] PP31;
  output [35:4] PP4;
  output [36:5] PP5;
  output [37:6] PP6;
  output [38:7] PP7;
  output [39:8] PP8;
  output [40:9] PP9;
  input [31:0] IN1;
  input [31:0] IN2;
  wire BIAS;
  wire [30:0] IN2R;
  wire IN2T;
  wire [31:0] W;
  TCDECON_31_0 U0 (IN2T, IN2R, IN2);
  TCUVPPG_31_0_0 U1 (W, IN1, IN2R[0]);
  TCUVPPG_31_0_1 U2 (PP1, IN1, IN2R[1]);
  TCUVPPG_31_0_2 U3 (PP2, IN1, IN2R[2]);
  TCUVPPG_31_0_3 U4 (PP3, IN1, IN2R[3]);
  TCUVPPG_31_0_4 U5 (PP4, IN1, IN2R[4]);
  TCUVPPG_31_0_5 U6 (PP5, IN1, IN2R[5]);
  TCUVPPG_31_0_6 U7 (PP6, IN1, IN2R[6]);
  TCUVPPG_31_0_7 U8 (PP7, IN1, IN2R[7]);
  TCUVPPG_31_0_8 U9 (PP8, IN1, IN2R[8]);
  TCUVPPG_31_0_9 U10 (PP9, IN1, IN2R[9]);
  TCUVPPG_31_0_10 U11 (PP10, IN1, IN2R[10]);
  TCUVPPG_31_0_11 U12 (PP11, IN1, IN2R[11]);
  TCUVPPG_31_0_12 U13 (PP12, IN1, IN2R[12]);
  TCUVPPG_31_0_13 U14 (PP13, IN1, IN2R[13]);
  TCUVPPG_31_0_14 U15 (PP14, IN1, IN2R[14]);
  TCUVPPG_31_0_15 U16 (PP15, IN1, IN2R[15]);
  TCUVPPG_31_0_16 U17 (PP16, IN1, IN2R[16]);
  TCUVPPG_31_0_17 U18 (PP17, IN1, IN2R[17]);
  TCUVPPG_31_0_18 U19 (PP18, IN1, IN2R[18]);
  TCUVPPG_31_0_19 U20 (PP19, IN1, IN2R[19]);
  TCUVPPG_31_0_20 U21 (PP20, IN1, IN2R[20]);
  TCUVPPG_31_0_21 U22 (PP21, IN1, IN2R[21]);
  TCUVPPG_31_0_22 U23 (PP22, IN1, IN2R[22]);
  TCUVPPG_31_0_23 U24 (PP23, IN1, IN2R[23]);
  TCUVPPG_31_0_24 U25 (PP24, IN1, IN2R[24]);
  TCUVPPG_31_0_25 U26 (PP25, IN1, IN2R[25]);
  TCUVPPG_31_0_26 U27 (PP26, IN1, IN2R[26]);
  TCUVPPG_31_0_27 U28 (PP27, IN1, IN2R[27]);
  TCUVPPG_31_0_28 U29 (PP28, IN1, IN2R[28]);
  TCUVPPG_31_0_29 U30 (PP29, IN1, IN2R[29]);
  TCUVPPG_31_0_30 U31 (PP30, IN1, IN2R[30]);
  TCNVPPG_31_0_31 U32 (PP31, IN1, IN2T);
  UBOne_32 U33 (BIAS);
  UBCMBIN_32_32_31_000 U34 (PP0, BIAS, W);
endmodule

module TCUVPPG_31_0_0 (O, IN1, IN2);
  output [31:0] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_0 U1 (O[0], IN1P[0], IN2);
  UB1BPPG_1_0 U2 (O[1], IN1P[1], IN2);
  UB1BPPG_2_0 U3 (O[2], IN1P[2], IN2);
  UB1BPPG_3_0 U4 (O[3], IN1P[3], IN2);
  UB1BPPG_4_0 U5 (O[4], IN1P[4], IN2);
  UB1BPPG_5_0 U6 (O[5], IN1P[5], IN2);
  UB1BPPG_6_0 U7 (O[6], IN1P[6], IN2);
  UB1BPPG_7_0 U8 (O[7], IN1P[7], IN2);
  UB1BPPG_8_0 U9 (O[8], IN1P[8], IN2);
  UB1BPPG_9_0 U10 (O[9], IN1P[9], IN2);
  UB1BPPG_10_0 U11 (O[10], IN1P[10], IN2);
  UB1BPPG_11_0 U12 (O[11], IN1P[11], IN2);
  UB1BPPG_12_0 U13 (O[12], IN1P[12], IN2);
  UB1BPPG_13_0 U14 (O[13], IN1P[13], IN2);
  UB1BPPG_14_0 U15 (O[14], IN1P[14], IN2);
  UB1BPPG_15_0 U16 (O[15], IN1P[15], IN2);
  UB1BPPG_16_0 U17 (O[16], IN1P[16], IN2);
  UB1BPPG_17_0 U18 (O[17], IN1P[17], IN2);
  UB1BPPG_18_0 U19 (O[18], IN1P[18], IN2);
  UB1BPPG_19_0 U20 (O[19], IN1P[19], IN2);
  UB1BPPG_20_0 U21 (O[20], IN1P[20], IN2);
  UB1BPPG_21_0 U22 (O[21], IN1P[21], IN2);
  UB1BPPG_22_0 U23 (O[22], IN1P[22], IN2);
  UB1BPPG_23_0 U24 (O[23], IN1P[23], IN2);
  UB1BPPG_24_0 U25 (O[24], IN1P[24], IN2);
  UB1BPPG_25_0 U26 (O[25], IN1P[25], IN2);
  UB1BPPG_26_0 U27 (O[26], IN1P[26], IN2);
  UB1BPPG_27_0 U28 (O[27], IN1P[27], IN2);
  UB1BPPG_28_0 U29 (O[28], IN1P[28], IN2);
  UB1BPPG_29_0 U30 (O[29], IN1P[29], IN2);
  UB1BPPG_30_0 U31 (O[30], IN1P[30], IN2);
  NU1BPPG_31_0 U32 (NEG, IN1N, IN2);
  NUBUB1CON_31 U33 (O[31], NEG);
endmodule

module TCUVPPG_31_0_1 (O, IN1, IN2);
  output [32:1] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_1 U1 (O[1], IN1P[0], IN2);
  UB1BPPG_1_1 U2 (O[2], IN1P[1], IN2);
  UB1BPPG_2_1 U3 (O[3], IN1P[2], IN2);
  UB1BPPG_3_1 U4 (O[4], IN1P[3], IN2);
  UB1BPPG_4_1 U5 (O[5], IN1P[4], IN2);
  UB1BPPG_5_1 U6 (O[6], IN1P[5], IN2);
  UB1BPPG_6_1 U7 (O[7], IN1P[6], IN2);
  UB1BPPG_7_1 U8 (O[8], IN1P[7], IN2);
  UB1BPPG_8_1 U9 (O[9], IN1P[8], IN2);
  UB1BPPG_9_1 U10 (O[10], IN1P[9], IN2);
  UB1BPPG_10_1 U11 (O[11], IN1P[10], IN2);
  UB1BPPG_11_1 U12 (O[12], IN1P[11], IN2);
  UB1BPPG_12_1 U13 (O[13], IN1P[12], IN2);
  UB1BPPG_13_1 U14 (O[14], IN1P[13], IN2);
  UB1BPPG_14_1 U15 (O[15], IN1P[14], IN2);
  UB1BPPG_15_1 U16 (O[16], IN1P[15], IN2);
  UB1BPPG_16_1 U17 (O[17], IN1P[16], IN2);
  UB1BPPG_17_1 U18 (O[18], IN1P[17], IN2);
  UB1BPPG_18_1 U19 (O[19], IN1P[18], IN2);
  UB1BPPG_19_1 U20 (O[20], IN1P[19], IN2);
  UB1BPPG_20_1 U21 (O[21], IN1P[20], IN2);
  UB1BPPG_21_1 U22 (O[22], IN1P[21], IN2);
  UB1BPPG_22_1 U23 (O[23], IN1P[22], IN2);
  UB1BPPG_23_1 U24 (O[24], IN1P[23], IN2);
  UB1BPPG_24_1 U25 (O[25], IN1P[24], IN2);
  UB1BPPG_25_1 U26 (O[26], IN1P[25], IN2);
  UB1BPPG_26_1 U27 (O[27], IN1P[26], IN2);
  UB1BPPG_27_1 U28 (O[28], IN1P[27], IN2);
  UB1BPPG_28_1 U29 (O[29], IN1P[28], IN2);
  UB1BPPG_29_1 U30 (O[30], IN1P[29], IN2);
  UB1BPPG_30_1 U31 (O[31], IN1P[30], IN2);
  NU1BPPG_31_1 U32 (NEG, IN1N, IN2);
  NUBUB1CON_32 U33 (O[32], NEG);
endmodule

module TCUVPPG_31_0_10 (O, IN1, IN2);
  output [41:10] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_10 U1 (O[10], IN1P[0], IN2);
  UB1BPPG_1_10 U2 (O[11], IN1P[1], IN2);
  UB1BPPG_2_10 U3 (O[12], IN1P[2], IN2);
  UB1BPPG_3_10 U4 (O[13], IN1P[3], IN2);
  UB1BPPG_4_10 U5 (O[14], IN1P[4], IN2);
  UB1BPPG_5_10 U6 (O[15], IN1P[5], IN2);
  UB1BPPG_6_10 U7 (O[16], IN1P[6], IN2);
  UB1BPPG_7_10 U8 (O[17], IN1P[7], IN2);
  UB1BPPG_8_10 U9 (O[18], IN1P[8], IN2);
  UB1BPPG_9_10 U10 (O[19], IN1P[9], IN2);
  UB1BPPG_10_10 U11 (O[20], IN1P[10], IN2);
  UB1BPPG_11_10 U12 (O[21], IN1P[11], IN2);
  UB1BPPG_12_10 U13 (O[22], IN1P[12], IN2);
  UB1BPPG_13_10 U14 (O[23], IN1P[13], IN2);
  UB1BPPG_14_10 U15 (O[24], IN1P[14], IN2);
  UB1BPPG_15_10 U16 (O[25], IN1P[15], IN2);
  UB1BPPG_16_10 U17 (O[26], IN1P[16], IN2);
  UB1BPPG_17_10 U18 (O[27], IN1P[17], IN2);
  UB1BPPG_18_10 U19 (O[28], IN1P[18], IN2);
  UB1BPPG_19_10 U20 (O[29], IN1P[19], IN2);
  UB1BPPG_20_10 U21 (O[30], IN1P[20], IN2);
  UB1BPPG_21_10 U22 (O[31], IN1P[21], IN2);
  UB1BPPG_22_10 U23 (O[32], IN1P[22], IN2);
  UB1BPPG_23_10 U24 (O[33], IN1P[23], IN2);
  UB1BPPG_24_10 U25 (O[34], IN1P[24], IN2);
  UB1BPPG_25_10 U26 (O[35], IN1P[25], IN2);
  UB1BPPG_26_10 U27 (O[36], IN1P[26], IN2);
  UB1BPPG_27_10 U28 (O[37], IN1P[27], IN2);
  UB1BPPG_28_10 U29 (O[38], IN1P[28], IN2);
  UB1BPPG_29_10 U30 (O[39], IN1P[29], IN2);
  UB1BPPG_30_10 U31 (O[40], IN1P[30], IN2);
  NU1BPPG_31_10 U32 (NEG, IN1N, IN2);
  NUBUB1CON_41 U33 (O[41], NEG);
endmodule

module TCUVPPG_31_0_11 (O, IN1, IN2);
  output [42:11] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_11 U1 (O[11], IN1P[0], IN2);
  UB1BPPG_1_11 U2 (O[12], IN1P[1], IN2);
  UB1BPPG_2_11 U3 (O[13], IN1P[2], IN2);
  UB1BPPG_3_11 U4 (O[14], IN1P[3], IN2);
  UB1BPPG_4_11 U5 (O[15], IN1P[4], IN2);
  UB1BPPG_5_11 U6 (O[16], IN1P[5], IN2);
  UB1BPPG_6_11 U7 (O[17], IN1P[6], IN2);
  UB1BPPG_7_11 U8 (O[18], IN1P[7], IN2);
  UB1BPPG_8_11 U9 (O[19], IN1P[8], IN2);
  UB1BPPG_9_11 U10 (O[20], IN1P[9], IN2);
  UB1BPPG_10_11 U11 (O[21], IN1P[10], IN2);
  UB1BPPG_11_11 U12 (O[22], IN1P[11], IN2);
  UB1BPPG_12_11 U13 (O[23], IN1P[12], IN2);
  UB1BPPG_13_11 U14 (O[24], IN1P[13], IN2);
  UB1BPPG_14_11 U15 (O[25], IN1P[14], IN2);
  UB1BPPG_15_11 U16 (O[26], IN1P[15], IN2);
  UB1BPPG_16_11 U17 (O[27], IN1P[16], IN2);
  UB1BPPG_17_11 U18 (O[28], IN1P[17], IN2);
  UB1BPPG_18_11 U19 (O[29], IN1P[18], IN2);
  UB1BPPG_19_11 U20 (O[30], IN1P[19], IN2);
  UB1BPPG_20_11 U21 (O[31], IN1P[20], IN2);
  UB1BPPG_21_11 U22 (O[32], IN1P[21], IN2);
  UB1BPPG_22_11 U23 (O[33], IN1P[22], IN2);
  UB1BPPG_23_11 U24 (O[34], IN1P[23], IN2);
  UB1BPPG_24_11 U25 (O[35], IN1P[24], IN2);
  UB1BPPG_25_11 U26 (O[36], IN1P[25], IN2);
  UB1BPPG_26_11 U27 (O[37], IN1P[26], IN2);
  UB1BPPG_27_11 U28 (O[38], IN1P[27], IN2);
  UB1BPPG_28_11 U29 (O[39], IN1P[28], IN2);
  UB1BPPG_29_11 U30 (O[40], IN1P[29], IN2);
  UB1BPPG_30_11 U31 (O[41], IN1P[30], IN2);
  NU1BPPG_31_11 U32 (NEG, IN1N, IN2);
  NUBUB1CON_42 U33 (O[42], NEG);
endmodule

module TCUVPPG_31_0_12 (O, IN1, IN2);
  output [43:12] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_12 U1 (O[12], IN1P[0], IN2);
  UB1BPPG_1_12 U2 (O[13], IN1P[1], IN2);
  UB1BPPG_2_12 U3 (O[14], IN1P[2], IN2);
  UB1BPPG_3_12 U4 (O[15], IN1P[3], IN2);
  UB1BPPG_4_12 U5 (O[16], IN1P[4], IN2);
  UB1BPPG_5_12 U6 (O[17], IN1P[5], IN2);
  UB1BPPG_6_12 U7 (O[18], IN1P[6], IN2);
  UB1BPPG_7_12 U8 (O[19], IN1P[7], IN2);
  UB1BPPG_8_12 U9 (O[20], IN1P[8], IN2);
  UB1BPPG_9_12 U10 (O[21], IN1P[9], IN2);
  UB1BPPG_10_12 U11 (O[22], IN1P[10], IN2);
  UB1BPPG_11_12 U12 (O[23], IN1P[11], IN2);
  UB1BPPG_12_12 U13 (O[24], IN1P[12], IN2);
  UB1BPPG_13_12 U14 (O[25], IN1P[13], IN2);
  UB1BPPG_14_12 U15 (O[26], IN1P[14], IN2);
  UB1BPPG_15_12 U16 (O[27], IN1P[15], IN2);
  UB1BPPG_16_12 U17 (O[28], IN1P[16], IN2);
  UB1BPPG_17_12 U18 (O[29], IN1P[17], IN2);
  UB1BPPG_18_12 U19 (O[30], IN1P[18], IN2);
  UB1BPPG_19_12 U20 (O[31], IN1P[19], IN2);
  UB1BPPG_20_12 U21 (O[32], IN1P[20], IN2);
  UB1BPPG_21_12 U22 (O[33], IN1P[21], IN2);
  UB1BPPG_22_12 U23 (O[34], IN1P[22], IN2);
  UB1BPPG_23_12 U24 (O[35], IN1P[23], IN2);
  UB1BPPG_24_12 U25 (O[36], IN1P[24], IN2);
  UB1BPPG_25_12 U26 (O[37], IN1P[25], IN2);
  UB1BPPG_26_12 U27 (O[38], IN1P[26], IN2);
  UB1BPPG_27_12 U28 (O[39], IN1P[27], IN2);
  UB1BPPG_28_12 U29 (O[40], IN1P[28], IN2);
  UB1BPPG_29_12 U30 (O[41], IN1P[29], IN2);
  UB1BPPG_30_12 U31 (O[42], IN1P[30], IN2);
  NU1BPPG_31_12 U32 (NEG, IN1N, IN2);
  NUBUB1CON_43 U33 (O[43], NEG);
endmodule

module TCUVPPG_31_0_13 (O, IN1, IN2);
  output [44:13] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_13 U1 (O[13], IN1P[0], IN2);
  UB1BPPG_1_13 U2 (O[14], IN1P[1], IN2);
  UB1BPPG_2_13 U3 (O[15], IN1P[2], IN2);
  UB1BPPG_3_13 U4 (O[16], IN1P[3], IN2);
  UB1BPPG_4_13 U5 (O[17], IN1P[4], IN2);
  UB1BPPG_5_13 U6 (O[18], IN1P[5], IN2);
  UB1BPPG_6_13 U7 (O[19], IN1P[6], IN2);
  UB1BPPG_7_13 U8 (O[20], IN1P[7], IN2);
  UB1BPPG_8_13 U9 (O[21], IN1P[8], IN2);
  UB1BPPG_9_13 U10 (O[22], IN1P[9], IN2);
  UB1BPPG_10_13 U11 (O[23], IN1P[10], IN2);
  UB1BPPG_11_13 U12 (O[24], IN1P[11], IN2);
  UB1BPPG_12_13 U13 (O[25], IN1P[12], IN2);
  UB1BPPG_13_13 U14 (O[26], IN1P[13], IN2);
  UB1BPPG_14_13 U15 (O[27], IN1P[14], IN2);
  UB1BPPG_15_13 U16 (O[28], IN1P[15], IN2);
  UB1BPPG_16_13 U17 (O[29], IN1P[16], IN2);
  UB1BPPG_17_13 U18 (O[30], IN1P[17], IN2);
  UB1BPPG_18_13 U19 (O[31], IN1P[18], IN2);
  UB1BPPG_19_13 U20 (O[32], IN1P[19], IN2);
  UB1BPPG_20_13 U21 (O[33], IN1P[20], IN2);
  UB1BPPG_21_13 U22 (O[34], IN1P[21], IN2);
  UB1BPPG_22_13 U23 (O[35], IN1P[22], IN2);
  UB1BPPG_23_13 U24 (O[36], IN1P[23], IN2);
  UB1BPPG_24_13 U25 (O[37], IN1P[24], IN2);
  UB1BPPG_25_13 U26 (O[38], IN1P[25], IN2);
  UB1BPPG_26_13 U27 (O[39], IN1P[26], IN2);
  UB1BPPG_27_13 U28 (O[40], IN1P[27], IN2);
  UB1BPPG_28_13 U29 (O[41], IN1P[28], IN2);
  UB1BPPG_29_13 U30 (O[42], IN1P[29], IN2);
  UB1BPPG_30_13 U31 (O[43], IN1P[30], IN2);
  NU1BPPG_31_13 U32 (NEG, IN1N, IN2);
  NUBUB1CON_44 U33 (O[44], NEG);
endmodule

module TCUVPPG_31_0_14 (O, IN1, IN2);
  output [45:14] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_14 U1 (O[14], IN1P[0], IN2);
  UB1BPPG_1_14 U2 (O[15], IN1P[1], IN2);
  UB1BPPG_2_14 U3 (O[16], IN1P[2], IN2);
  UB1BPPG_3_14 U4 (O[17], IN1P[3], IN2);
  UB1BPPG_4_14 U5 (O[18], IN1P[4], IN2);
  UB1BPPG_5_14 U6 (O[19], IN1P[5], IN2);
  UB1BPPG_6_14 U7 (O[20], IN1P[6], IN2);
  UB1BPPG_7_14 U8 (O[21], IN1P[7], IN2);
  UB1BPPG_8_14 U9 (O[22], IN1P[8], IN2);
  UB1BPPG_9_14 U10 (O[23], IN1P[9], IN2);
  UB1BPPG_10_14 U11 (O[24], IN1P[10], IN2);
  UB1BPPG_11_14 U12 (O[25], IN1P[11], IN2);
  UB1BPPG_12_14 U13 (O[26], IN1P[12], IN2);
  UB1BPPG_13_14 U14 (O[27], IN1P[13], IN2);
  UB1BPPG_14_14 U15 (O[28], IN1P[14], IN2);
  UB1BPPG_15_14 U16 (O[29], IN1P[15], IN2);
  UB1BPPG_16_14 U17 (O[30], IN1P[16], IN2);
  UB1BPPG_17_14 U18 (O[31], IN1P[17], IN2);
  UB1BPPG_18_14 U19 (O[32], IN1P[18], IN2);
  UB1BPPG_19_14 U20 (O[33], IN1P[19], IN2);
  UB1BPPG_20_14 U21 (O[34], IN1P[20], IN2);
  UB1BPPG_21_14 U22 (O[35], IN1P[21], IN2);
  UB1BPPG_22_14 U23 (O[36], IN1P[22], IN2);
  UB1BPPG_23_14 U24 (O[37], IN1P[23], IN2);
  UB1BPPG_24_14 U25 (O[38], IN1P[24], IN2);
  UB1BPPG_25_14 U26 (O[39], IN1P[25], IN2);
  UB1BPPG_26_14 U27 (O[40], IN1P[26], IN2);
  UB1BPPG_27_14 U28 (O[41], IN1P[27], IN2);
  UB1BPPG_28_14 U29 (O[42], IN1P[28], IN2);
  UB1BPPG_29_14 U30 (O[43], IN1P[29], IN2);
  UB1BPPG_30_14 U31 (O[44], IN1P[30], IN2);
  NU1BPPG_31_14 U32 (NEG, IN1N, IN2);
  NUBUB1CON_45 U33 (O[45], NEG);
endmodule

module TCUVPPG_31_0_15 (O, IN1, IN2);
  output [46:15] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_15 U1 (O[15], IN1P[0], IN2);
  UB1BPPG_1_15 U2 (O[16], IN1P[1], IN2);
  UB1BPPG_2_15 U3 (O[17], IN1P[2], IN2);
  UB1BPPG_3_15 U4 (O[18], IN1P[3], IN2);
  UB1BPPG_4_15 U5 (O[19], IN1P[4], IN2);
  UB1BPPG_5_15 U6 (O[20], IN1P[5], IN2);
  UB1BPPG_6_15 U7 (O[21], IN1P[6], IN2);
  UB1BPPG_7_15 U8 (O[22], IN1P[7], IN2);
  UB1BPPG_8_15 U9 (O[23], IN1P[8], IN2);
  UB1BPPG_9_15 U10 (O[24], IN1P[9], IN2);
  UB1BPPG_10_15 U11 (O[25], IN1P[10], IN2);
  UB1BPPG_11_15 U12 (O[26], IN1P[11], IN2);
  UB1BPPG_12_15 U13 (O[27], IN1P[12], IN2);
  UB1BPPG_13_15 U14 (O[28], IN1P[13], IN2);
  UB1BPPG_14_15 U15 (O[29], IN1P[14], IN2);
  UB1BPPG_15_15 U16 (O[30], IN1P[15], IN2);
  UB1BPPG_16_15 U17 (O[31], IN1P[16], IN2);
  UB1BPPG_17_15 U18 (O[32], IN1P[17], IN2);
  UB1BPPG_18_15 U19 (O[33], IN1P[18], IN2);
  UB1BPPG_19_15 U20 (O[34], IN1P[19], IN2);
  UB1BPPG_20_15 U21 (O[35], IN1P[20], IN2);
  UB1BPPG_21_15 U22 (O[36], IN1P[21], IN2);
  UB1BPPG_22_15 U23 (O[37], IN1P[22], IN2);
  UB1BPPG_23_15 U24 (O[38], IN1P[23], IN2);
  UB1BPPG_24_15 U25 (O[39], IN1P[24], IN2);
  UB1BPPG_25_15 U26 (O[40], IN1P[25], IN2);
  UB1BPPG_26_15 U27 (O[41], IN1P[26], IN2);
  UB1BPPG_27_15 U28 (O[42], IN1P[27], IN2);
  UB1BPPG_28_15 U29 (O[43], IN1P[28], IN2);
  UB1BPPG_29_15 U30 (O[44], IN1P[29], IN2);
  UB1BPPG_30_15 U31 (O[45], IN1P[30], IN2);
  NU1BPPG_31_15 U32 (NEG, IN1N, IN2);
  NUBUB1CON_46 U33 (O[46], NEG);
endmodule

module TCUVPPG_31_0_16 (O, IN1, IN2);
  output [47:16] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_16 U1 (O[16], IN1P[0], IN2);
  UB1BPPG_1_16 U2 (O[17], IN1P[1], IN2);
  UB1BPPG_2_16 U3 (O[18], IN1P[2], IN2);
  UB1BPPG_3_16 U4 (O[19], IN1P[3], IN2);
  UB1BPPG_4_16 U5 (O[20], IN1P[4], IN2);
  UB1BPPG_5_16 U6 (O[21], IN1P[5], IN2);
  UB1BPPG_6_16 U7 (O[22], IN1P[6], IN2);
  UB1BPPG_7_16 U8 (O[23], IN1P[7], IN2);
  UB1BPPG_8_16 U9 (O[24], IN1P[8], IN2);
  UB1BPPG_9_16 U10 (O[25], IN1P[9], IN2);
  UB1BPPG_10_16 U11 (O[26], IN1P[10], IN2);
  UB1BPPG_11_16 U12 (O[27], IN1P[11], IN2);
  UB1BPPG_12_16 U13 (O[28], IN1P[12], IN2);
  UB1BPPG_13_16 U14 (O[29], IN1P[13], IN2);
  UB1BPPG_14_16 U15 (O[30], IN1P[14], IN2);
  UB1BPPG_15_16 U16 (O[31], IN1P[15], IN2);
  UB1BPPG_16_16 U17 (O[32], IN1P[16], IN2);
  UB1BPPG_17_16 U18 (O[33], IN1P[17], IN2);
  UB1BPPG_18_16 U19 (O[34], IN1P[18], IN2);
  UB1BPPG_19_16 U20 (O[35], IN1P[19], IN2);
  UB1BPPG_20_16 U21 (O[36], IN1P[20], IN2);
  UB1BPPG_21_16 U22 (O[37], IN1P[21], IN2);
  UB1BPPG_22_16 U23 (O[38], IN1P[22], IN2);
  UB1BPPG_23_16 U24 (O[39], IN1P[23], IN2);
  UB1BPPG_24_16 U25 (O[40], IN1P[24], IN2);
  UB1BPPG_25_16 U26 (O[41], IN1P[25], IN2);
  UB1BPPG_26_16 U27 (O[42], IN1P[26], IN2);
  UB1BPPG_27_16 U28 (O[43], IN1P[27], IN2);
  UB1BPPG_28_16 U29 (O[44], IN1P[28], IN2);
  UB1BPPG_29_16 U30 (O[45], IN1P[29], IN2);
  UB1BPPG_30_16 U31 (O[46], IN1P[30], IN2);
  NU1BPPG_31_16 U32 (NEG, IN1N, IN2);
  NUBUB1CON_47 U33 (O[47], NEG);
endmodule

module TCUVPPG_31_0_17 (O, IN1, IN2);
  output [48:17] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_17 U1 (O[17], IN1P[0], IN2);
  UB1BPPG_1_17 U2 (O[18], IN1P[1], IN2);
  UB1BPPG_2_17 U3 (O[19], IN1P[2], IN2);
  UB1BPPG_3_17 U4 (O[20], IN1P[3], IN2);
  UB1BPPG_4_17 U5 (O[21], IN1P[4], IN2);
  UB1BPPG_5_17 U6 (O[22], IN1P[5], IN2);
  UB1BPPG_6_17 U7 (O[23], IN1P[6], IN2);
  UB1BPPG_7_17 U8 (O[24], IN1P[7], IN2);
  UB1BPPG_8_17 U9 (O[25], IN1P[8], IN2);
  UB1BPPG_9_17 U10 (O[26], IN1P[9], IN2);
  UB1BPPG_10_17 U11 (O[27], IN1P[10], IN2);
  UB1BPPG_11_17 U12 (O[28], IN1P[11], IN2);
  UB1BPPG_12_17 U13 (O[29], IN1P[12], IN2);
  UB1BPPG_13_17 U14 (O[30], IN1P[13], IN2);
  UB1BPPG_14_17 U15 (O[31], IN1P[14], IN2);
  UB1BPPG_15_17 U16 (O[32], IN1P[15], IN2);
  UB1BPPG_16_17 U17 (O[33], IN1P[16], IN2);
  UB1BPPG_17_17 U18 (O[34], IN1P[17], IN2);
  UB1BPPG_18_17 U19 (O[35], IN1P[18], IN2);
  UB1BPPG_19_17 U20 (O[36], IN1P[19], IN2);
  UB1BPPG_20_17 U21 (O[37], IN1P[20], IN2);
  UB1BPPG_21_17 U22 (O[38], IN1P[21], IN2);
  UB1BPPG_22_17 U23 (O[39], IN1P[22], IN2);
  UB1BPPG_23_17 U24 (O[40], IN1P[23], IN2);
  UB1BPPG_24_17 U25 (O[41], IN1P[24], IN2);
  UB1BPPG_25_17 U26 (O[42], IN1P[25], IN2);
  UB1BPPG_26_17 U27 (O[43], IN1P[26], IN2);
  UB1BPPG_27_17 U28 (O[44], IN1P[27], IN2);
  UB1BPPG_28_17 U29 (O[45], IN1P[28], IN2);
  UB1BPPG_29_17 U30 (O[46], IN1P[29], IN2);
  UB1BPPG_30_17 U31 (O[47], IN1P[30], IN2);
  NU1BPPG_31_17 U32 (NEG, IN1N, IN2);
  NUBUB1CON_48 U33 (O[48], NEG);
endmodule

module TCUVPPG_31_0_18 (O, IN1, IN2);
  output [49:18] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_18 U1 (O[18], IN1P[0], IN2);
  UB1BPPG_1_18 U2 (O[19], IN1P[1], IN2);
  UB1BPPG_2_18 U3 (O[20], IN1P[2], IN2);
  UB1BPPG_3_18 U4 (O[21], IN1P[3], IN2);
  UB1BPPG_4_18 U5 (O[22], IN1P[4], IN2);
  UB1BPPG_5_18 U6 (O[23], IN1P[5], IN2);
  UB1BPPG_6_18 U7 (O[24], IN1P[6], IN2);
  UB1BPPG_7_18 U8 (O[25], IN1P[7], IN2);
  UB1BPPG_8_18 U9 (O[26], IN1P[8], IN2);
  UB1BPPG_9_18 U10 (O[27], IN1P[9], IN2);
  UB1BPPG_10_18 U11 (O[28], IN1P[10], IN2);
  UB1BPPG_11_18 U12 (O[29], IN1P[11], IN2);
  UB1BPPG_12_18 U13 (O[30], IN1P[12], IN2);
  UB1BPPG_13_18 U14 (O[31], IN1P[13], IN2);
  UB1BPPG_14_18 U15 (O[32], IN1P[14], IN2);
  UB1BPPG_15_18 U16 (O[33], IN1P[15], IN2);
  UB1BPPG_16_18 U17 (O[34], IN1P[16], IN2);
  UB1BPPG_17_18 U18 (O[35], IN1P[17], IN2);
  UB1BPPG_18_18 U19 (O[36], IN1P[18], IN2);
  UB1BPPG_19_18 U20 (O[37], IN1P[19], IN2);
  UB1BPPG_20_18 U21 (O[38], IN1P[20], IN2);
  UB1BPPG_21_18 U22 (O[39], IN1P[21], IN2);
  UB1BPPG_22_18 U23 (O[40], IN1P[22], IN2);
  UB1BPPG_23_18 U24 (O[41], IN1P[23], IN2);
  UB1BPPG_24_18 U25 (O[42], IN1P[24], IN2);
  UB1BPPG_25_18 U26 (O[43], IN1P[25], IN2);
  UB1BPPG_26_18 U27 (O[44], IN1P[26], IN2);
  UB1BPPG_27_18 U28 (O[45], IN1P[27], IN2);
  UB1BPPG_28_18 U29 (O[46], IN1P[28], IN2);
  UB1BPPG_29_18 U30 (O[47], IN1P[29], IN2);
  UB1BPPG_30_18 U31 (O[48], IN1P[30], IN2);
  NU1BPPG_31_18 U32 (NEG, IN1N, IN2);
  NUBUB1CON_49 U33 (O[49], NEG);
endmodule

module TCUVPPG_31_0_19 (O, IN1, IN2);
  output [50:19] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_19 U1 (O[19], IN1P[0], IN2);
  UB1BPPG_1_19 U2 (O[20], IN1P[1], IN2);
  UB1BPPG_2_19 U3 (O[21], IN1P[2], IN2);
  UB1BPPG_3_19 U4 (O[22], IN1P[3], IN2);
  UB1BPPG_4_19 U5 (O[23], IN1P[4], IN2);
  UB1BPPG_5_19 U6 (O[24], IN1P[5], IN2);
  UB1BPPG_6_19 U7 (O[25], IN1P[6], IN2);
  UB1BPPG_7_19 U8 (O[26], IN1P[7], IN2);
  UB1BPPG_8_19 U9 (O[27], IN1P[8], IN2);
  UB1BPPG_9_19 U10 (O[28], IN1P[9], IN2);
  UB1BPPG_10_19 U11 (O[29], IN1P[10], IN2);
  UB1BPPG_11_19 U12 (O[30], IN1P[11], IN2);
  UB1BPPG_12_19 U13 (O[31], IN1P[12], IN2);
  UB1BPPG_13_19 U14 (O[32], IN1P[13], IN2);
  UB1BPPG_14_19 U15 (O[33], IN1P[14], IN2);
  UB1BPPG_15_19 U16 (O[34], IN1P[15], IN2);
  UB1BPPG_16_19 U17 (O[35], IN1P[16], IN2);
  UB1BPPG_17_19 U18 (O[36], IN1P[17], IN2);
  UB1BPPG_18_19 U19 (O[37], IN1P[18], IN2);
  UB1BPPG_19_19 U20 (O[38], IN1P[19], IN2);
  UB1BPPG_20_19 U21 (O[39], IN1P[20], IN2);
  UB1BPPG_21_19 U22 (O[40], IN1P[21], IN2);
  UB1BPPG_22_19 U23 (O[41], IN1P[22], IN2);
  UB1BPPG_23_19 U24 (O[42], IN1P[23], IN2);
  UB1BPPG_24_19 U25 (O[43], IN1P[24], IN2);
  UB1BPPG_25_19 U26 (O[44], IN1P[25], IN2);
  UB1BPPG_26_19 U27 (O[45], IN1P[26], IN2);
  UB1BPPG_27_19 U28 (O[46], IN1P[27], IN2);
  UB1BPPG_28_19 U29 (O[47], IN1P[28], IN2);
  UB1BPPG_29_19 U30 (O[48], IN1P[29], IN2);
  UB1BPPG_30_19 U31 (O[49], IN1P[30], IN2);
  NU1BPPG_31_19 U32 (NEG, IN1N, IN2);
  NUBUB1CON_50 U33 (O[50], NEG);
endmodule

module TCUVPPG_31_0_2 (O, IN1, IN2);
  output [33:2] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_2 U1 (O[2], IN1P[0], IN2);
  UB1BPPG_1_2 U2 (O[3], IN1P[1], IN2);
  UB1BPPG_2_2 U3 (O[4], IN1P[2], IN2);
  UB1BPPG_3_2 U4 (O[5], IN1P[3], IN2);
  UB1BPPG_4_2 U5 (O[6], IN1P[4], IN2);
  UB1BPPG_5_2 U6 (O[7], IN1P[5], IN2);
  UB1BPPG_6_2 U7 (O[8], IN1P[6], IN2);
  UB1BPPG_7_2 U8 (O[9], IN1P[7], IN2);
  UB1BPPG_8_2 U9 (O[10], IN1P[8], IN2);
  UB1BPPG_9_2 U10 (O[11], IN1P[9], IN2);
  UB1BPPG_10_2 U11 (O[12], IN1P[10], IN2);
  UB1BPPG_11_2 U12 (O[13], IN1P[11], IN2);
  UB1BPPG_12_2 U13 (O[14], IN1P[12], IN2);
  UB1BPPG_13_2 U14 (O[15], IN1P[13], IN2);
  UB1BPPG_14_2 U15 (O[16], IN1P[14], IN2);
  UB1BPPG_15_2 U16 (O[17], IN1P[15], IN2);
  UB1BPPG_16_2 U17 (O[18], IN1P[16], IN2);
  UB1BPPG_17_2 U18 (O[19], IN1P[17], IN2);
  UB1BPPG_18_2 U19 (O[20], IN1P[18], IN2);
  UB1BPPG_19_2 U20 (O[21], IN1P[19], IN2);
  UB1BPPG_20_2 U21 (O[22], IN1P[20], IN2);
  UB1BPPG_21_2 U22 (O[23], IN1P[21], IN2);
  UB1BPPG_22_2 U23 (O[24], IN1P[22], IN2);
  UB1BPPG_23_2 U24 (O[25], IN1P[23], IN2);
  UB1BPPG_24_2 U25 (O[26], IN1P[24], IN2);
  UB1BPPG_25_2 U26 (O[27], IN1P[25], IN2);
  UB1BPPG_26_2 U27 (O[28], IN1P[26], IN2);
  UB1BPPG_27_2 U28 (O[29], IN1P[27], IN2);
  UB1BPPG_28_2 U29 (O[30], IN1P[28], IN2);
  UB1BPPG_29_2 U30 (O[31], IN1P[29], IN2);
  UB1BPPG_30_2 U31 (O[32], IN1P[30], IN2);
  NU1BPPG_31_2 U32 (NEG, IN1N, IN2);
  NUBUB1CON_33 U33 (O[33], NEG);
endmodule

module TCUVPPG_31_0_20 (O, IN1, IN2);
  output [51:20] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_20 U1 (O[20], IN1P[0], IN2);
  UB1BPPG_1_20 U2 (O[21], IN1P[1], IN2);
  UB1BPPG_2_20 U3 (O[22], IN1P[2], IN2);
  UB1BPPG_3_20 U4 (O[23], IN1P[3], IN2);
  UB1BPPG_4_20 U5 (O[24], IN1P[4], IN2);
  UB1BPPG_5_20 U6 (O[25], IN1P[5], IN2);
  UB1BPPG_6_20 U7 (O[26], IN1P[6], IN2);
  UB1BPPG_7_20 U8 (O[27], IN1P[7], IN2);
  UB1BPPG_8_20 U9 (O[28], IN1P[8], IN2);
  UB1BPPG_9_20 U10 (O[29], IN1P[9], IN2);
  UB1BPPG_10_20 U11 (O[30], IN1P[10], IN2);
  UB1BPPG_11_20 U12 (O[31], IN1P[11], IN2);
  UB1BPPG_12_20 U13 (O[32], IN1P[12], IN2);
  UB1BPPG_13_20 U14 (O[33], IN1P[13], IN2);
  UB1BPPG_14_20 U15 (O[34], IN1P[14], IN2);
  UB1BPPG_15_20 U16 (O[35], IN1P[15], IN2);
  UB1BPPG_16_20 U17 (O[36], IN1P[16], IN2);
  UB1BPPG_17_20 U18 (O[37], IN1P[17], IN2);
  UB1BPPG_18_20 U19 (O[38], IN1P[18], IN2);
  UB1BPPG_19_20 U20 (O[39], IN1P[19], IN2);
  UB1BPPG_20_20 U21 (O[40], IN1P[20], IN2);
  UB1BPPG_21_20 U22 (O[41], IN1P[21], IN2);
  UB1BPPG_22_20 U23 (O[42], IN1P[22], IN2);
  UB1BPPG_23_20 U24 (O[43], IN1P[23], IN2);
  UB1BPPG_24_20 U25 (O[44], IN1P[24], IN2);
  UB1BPPG_25_20 U26 (O[45], IN1P[25], IN2);
  UB1BPPG_26_20 U27 (O[46], IN1P[26], IN2);
  UB1BPPG_27_20 U28 (O[47], IN1P[27], IN2);
  UB1BPPG_28_20 U29 (O[48], IN1P[28], IN2);
  UB1BPPG_29_20 U30 (O[49], IN1P[29], IN2);
  UB1BPPG_30_20 U31 (O[50], IN1P[30], IN2);
  NU1BPPG_31_20 U32 (NEG, IN1N, IN2);
  NUBUB1CON_51 U33 (O[51], NEG);
endmodule

module TCUVPPG_31_0_21 (O, IN1, IN2);
  output [52:21] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_21 U1 (O[21], IN1P[0], IN2);
  UB1BPPG_1_21 U2 (O[22], IN1P[1], IN2);
  UB1BPPG_2_21 U3 (O[23], IN1P[2], IN2);
  UB1BPPG_3_21 U4 (O[24], IN1P[3], IN2);
  UB1BPPG_4_21 U5 (O[25], IN1P[4], IN2);
  UB1BPPG_5_21 U6 (O[26], IN1P[5], IN2);
  UB1BPPG_6_21 U7 (O[27], IN1P[6], IN2);
  UB1BPPG_7_21 U8 (O[28], IN1P[7], IN2);
  UB1BPPG_8_21 U9 (O[29], IN1P[8], IN2);
  UB1BPPG_9_21 U10 (O[30], IN1P[9], IN2);
  UB1BPPG_10_21 U11 (O[31], IN1P[10], IN2);
  UB1BPPG_11_21 U12 (O[32], IN1P[11], IN2);
  UB1BPPG_12_21 U13 (O[33], IN1P[12], IN2);
  UB1BPPG_13_21 U14 (O[34], IN1P[13], IN2);
  UB1BPPG_14_21 U15 (O[35], IN1P[14], IN2);
  UB1BPPG_15_21 U16 (O[36], IN1P[15], IN2);
  UB1BPPG_16_21 U17 (O[37], IN1P[16], IN2);
  UB1BPPG_17_21 U18 (O[38], IN1P[17], IN2);
  UB1BPPG_18_21 U19 (O[39], IN1P[18], IN2);
  UB1BPPG_19_21 U20 (O[40], IN1P[19], IN2);
  UB1BPPG_20_21 U21 (O[41], IN1P[20], IN2);
  UB1BPPG_21_21 U22 (O[42], IN1P[21], IN2);
  UB1BPPG_22_21 U23 (O[43], IN1P[22], IN2);
  UB1BPPG_23_21 U24 (O[44], IN1P[23], IN2);
  UB1BPPG_24_21 U25 (O[45], IN1P[24], IN2);
  UB1BPPG_25_21 U26 (O[46], IN1P[25], IN2);
  UB1BPPG_26_21 U27 (O[47], IN1P[26], IN2);
  UB1BPPG_27_21 U28 (O[48], IN1P[27], IN2);
  UB1BPPG_28_21 U29 (O[49], IN1P[28], IN2);
  UB1BPPG_29_21 U30 (O[50], IN1P[29], IN2);
  UB1BPPG_30_21 U31 (O[51], IN1P[30], IN2);
  NU1BPPG_31_21 U32 (NEG, IN1N, IN2);
  NUBUB1CON_52 U33 (O[52], NEG);
endmodule

module TCUVPPG_31_0_22 (O, IN1, IN2);
  output [53:22] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_22 U1 (O[22], IN1P[0], IN2);
  UB1BPPG_1_22 U2 (O[23], IN1P[1], IN2);
  UB1BPPG_2_22 U3 (O[24], IN1P[2], IN2);
  UB1BPPG_3_22 U4 (O[25], IN1P[3], IN2);
  UB1BPPG_4_22 U5 (O[26], IN1P[4], IN2);
  UB1BPPG_5_22 U6 (O[27], IN1P[5], IN2);
  UB1BPPG_6_22 U7 (O[28], IN1P[6], IN2);
  UB1BPPG_7_22 U8 (O[29], IN1P[7], IN2);
  UB1BPPG_8_22 U9 (O[30], IN1P[8], IN2);
  UB1BPPG_9_22 U10 (O[31], IN1P[9], IN2);
  UB1BPPG_10_22 U11 (O[32], IN1P[10], IN2);
  UB1BPPG_11_22 U12 (O[33], IN1P[11], IN2);
  UB1BPPG_12_22 U13 (O[34], IN1P[12], IN2);
  UB1BPPG_13_22 U14 (O[35], IN1P[13], IN2);
  UB1BPPG_14_22 U15 (O[36], IN1P[14], IN2);
  UB1BPPG_15_22 U16 (O[37], IN1P[15], IN2);
  UB1BPPG_16_22 U17 (O[38], IN1P[16], IN2);
  UB1BPPG_17_22 U18 (O[39], IN1P[17], IN2);
  UB1BPPG_18_22 U19 (O[40], IN1P[18], IN2);
  UB1BPPG_19_22 U20 (O[41], IN1P[19], IN2);
  UB1BPPG_20_22 U21 (O[42], IN1P[20], IN2);
  UB1BPPG_21_22 U22 (O[43], IN1P[21], IN2);
  UB1BPPG_22_22 U23 (O[44], IN1P[22], IN2);
  UB1BPPG_23_22 U24 (O[45], IN1P[23], IN2);
  UB1BPPG_24_22 U25 (O[46], IN1P[24], IN2);
  UB1BPPG_25_22 U26 (O[47], IN1P[25], IN2);
  UB1BPPG_26_22 U27 (O[48], IN1P[26], IN2);
  UB1BPPG_27_22 U28 (O[49], IN1P[27], IN2);
  UB1BPPG_28_22 U29 (O[50], IN1P[28], IN2);
  UB1BPPG_29_22 U30 (O[51], IN1P[29], IN2);
  UB1BPPG_30_22 U31 (O[52], IN1P[30], IN2);
  NU1BPPG_31_22 U32 (NEG, IN1N, IN2);
  NUBUB1CON_53 U33 (O[53], NEG);
endmodule

module TCUVPPG_31_0_23 (O, IN1, IN2);
  output [54:23] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_23 U1 (O[23], IN1P[0], IN2);
  UB1BPPG_1_23 U2 (O[24], IN1P[1], IN2);
  UB1BPPG_2_23 U3 (O[25], IN1P[2], IN2);
  UB1BPPG_3_23 U4 (O[26], IN1P[3], IN2);
  UB1BPPG_4_23 U5 (O[27], IN1P[4], IN2);
  UB1BPPG_5_23 U6 (O[28], IN1P[5], IN2);
  UB1BPPG_6_23 U7 (O[29], IN1P[6], IN2);
  UB1BPPG_7_23 U8 (O[30], IN1P[7], IN2);
  UB1BPPG_8_23 U9 (O[31], IN1P[8], IN2);
  UB1BPPG_9_23 U10 (O[32], IN1P[9], IN2);
  UB1BPPG_10_23 U11 (O[33], IN1P[10], IN2);
  UB1BPPG_11_23 U12 (O[34], IN1P[11], IN2);
  UB1BPPG_12_23 U13 (O[35], IN1P[12], IN2);
  UB1BPPG_13_23 U14 (O[36], IN1P[13], IN2);
  UB1BPPG_14_23 U15 (O[37], IN1P[14], IN2);
  UB1BPPG_15_23 U16 (O[38], IN1P[15], IN2);
  UB1BPPG_16_23 U17 (O[39], IN1P[16], IN2);
  UB1BPPG_17_23 U18 (O[40], IN1P[17], IN2);
  UB1BPPG_18_23 U19 (O[41], IN1P[18], IN2);
  UB1BPPG_19_23 U20 (O[42], IN1P[19], IN2);
  UB1BPPG_20_23 U21 (O[43], IN1P[20], IN2);
  UB1BPPG_21_23 U22 (O[44], IN1P[21], IN2);
  UB1BPPG_22_23 U23 (O[45], IN1P[22], IN2);
  UB1BPPG_23_23 U24 (O[46], IN1P[23], IN2);
  UB1BPPG_24_23 U25 (O[47], IN1P[24], IN2);
  UB1BPPG_25_23 U26 (O[48], IN1P[25], IN2);
  UB1BPPG_26_23 U27 (O[49], IN1P[26], IN2);
  UB1BPPG_27_23 U28 (O[50], IN1P[27], IN2);
  UB1BPPG_28_23 U29 (O[51], IN1P[28], IN2);
  UB1BPPG_29_23 U30 (O[52], IN1P[29], IN2);
  UB1BPPG_30_23 U31 (O[53], IN1P[30], IN2);
  NU1BPPG_31_23 U32 (NEG, IN1N, IN2);
  NUBUB1CON_54 U33 (O[54], NEG);
endmodule

module TCUVPPG_31_0_24 (O, IN1, IN2);
  output [55:24] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_24 U1 (O[24], IN1P[0], IN2);
  UB1BPPG_1_24 U2 (O[25], IN1P[1], IN2);
  UB1BPPG_2_24 U3 (O[26], IN1P[2], IN2);
  UB1BPPG_3_24 U4 (O[27], IN1P[3], IN2);
  UB1BPPG_4_24 U5 (O[28], IN1P[4], IN2);
  UB1BPPG_5_24 U6 (O[29], IN1P[5], IN2);
  UB1BPPG_6_24 U7 (O[30], IN1P[6], IN2);
  UB1BPPG_7_24 U8 (O[31], IN1P[7], IN2);
  UB1BPPG_8_24 U9 (O[32], IN1P[8], IN2);
  UB1BPPG_9_24 U10 (O[33], IN1P[9], IN2);
  UB1BPPG_10_24 U11 (O[34], IN1P[10], IN2);
  UB1BPPG_11_24 U12 (O[35], IN1P[11], IN2);
  UB1BPPG_12_24 U13 (O[36], IN1P[12], IN2);
  UB1BPPG_13_24 U14 (O[37], IN1P[13], IN2);
  UB1BPPG_14_24 U15 (O[38], IN1P[14], IN2);
  UB1BPPG_15_24 U16 (O[39], IN1P[15], IN2);
  UB1BPPG_16_24 U17 (O[40], IN1P[16], IN2);
  UB1BPPG_17_24 U18 (O[41], IN1P[17], IN2);
  UB1BPPG_18_24 U19 (O[42], IN1P[18], IN2);
  UB1BPPG_19_24 U20 (O[43], IN1P[19], IN2);
  UB1BPPG_20_24 U21 (O[44], IN1P[20], IN2);
  UB1BPPG_21_24 U22 (O[45], IN1P[21], IN2);
  UB1BPPG_22_24 U23 (O[46], IN1P[22], IN2);
  UB1BPPG_23_24 U24 (O[47], IN1P[23], IN2);
  UB1BPPG_24_24 U25 (O[48], IN1P[24], IN2);
  UB1BPPG_25_24 U26 (O[49], IN1P[25], IN2);
  UB1BPPG_26_24 U27 (O[50], IN1P[26], IN2);
  UB1BPPG_27_24 U28 (O[51], IN1P[27], IN2);
  UB1BPPG_28_24 U29 (O[52], IN1P[28], IN2);
  UB1BPPG_29_24 U30 (O[53], IN1P[29], IN2);
  UB1BPPG_30_24 U31 (O[54], IN1P[30], IN2);
  NU1BPPG_31_24 U32 (NEG, IN1N, IN2);
  NUBUB1CON_55 U33 (O[55], NEG);
endmodule

module TCUVPPG_31_0_25 (O, IN1, IN2);
  output [56:25] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_25 U1 (O[25], IN1P[0], IN2);
  UB1BPPG_1_25 U2 (O[26], IN1P[1], IN2);
  UB1BPPG_2_25 U3 (O[27], IN1P[2], IN2);
  UB1BPPG_3_25 U4 (O[28], IN1P[3], IN2);
  UB1BPPG_4_25 U5 (O[29], IN1P[4], IN2);
  UB1BPPG_5_25 U6 (O[30], IN1P[5], IN2);
  UB1BPPG_6_25 U7 (O[31], IN1P[6], IN2);
  UB1BPPG_7_25 U8 (O[32], IN1P[7], IN2);
  UB1BPPG_8_25 U9 (O[33], IN1P[8], IN2);
  UB1BPPG_9_25 U10 (O[34], IN1P[9], IN2);
  UB1BPPG_10_25 U11 (O[35], IN1P[10], IN2);
  UB1BPPG_11_25 U12 (O[36], IN1P[11], IN2);
  UB1BPPG_12_25 U13 (O[37], IN1P[12], IN2);
  UB1BPPG_13_25 U14 (O[38], IN1P[13], IN2);
  UB1BPPG_14_25 U15 (O[39], IN1P[14], IN2);
  UB1BPPG_15_25 U16 (O[40], IN1P[15], IN2);
  UB1BPPG_16_25 U17 (O[41], IN1P[16], IN2);
  UB1BPPG_17_25 U18 (O[42], IN1P[17], IN2);
  UB1BPPG_18_25 U19 (O[43], IN1P[18], IN2);
  UB1BPPG_19_25 U20 (O[44], IN1P[19], IN2);
  UB1BPPG_20_25 U21 (O[45], IN1P[20], IN2);
  UB1BPPG_21_25 U22 (O[46], IN1P[21], IN2);
  UB1BPPG_22_25 U23 (O[47], IN1P[22], IN2);
  UB1BPPG_23_25 U24 (O[48], IN1P[23], IN2);
  UB1BPPG_24_25 U25 (O[49], IN1P[24], IN2);
  UB1BPPG_25_25 U26 (O[50], IN1P[25], IN2);
  UB1BPPG_26_25 U27 (O[51], IN1P[26], IN2);
  UB1BPPG_27_25 U28 (O[52], IN1P[27], IN2);
  UB1BPPG_28_25 U29 (O[53], IN1P[28], IN2);
  UB1BPPG_29_25 U30 (O[54], IN1P[29], IN2);
  UB1BPPG_30_25 U31 (O[55], IN1P[30], IN2);
  NU1BPPG_31_25 U32 (NEG, IN1N, IN2);
  NUBUB1CON_56 U33 (O[56], NEG);
endmodule

module TCUVPPG_31_0_26 (O, IN1, IN2);
  output [57:26] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_26 U1 (O[26], IN1P[0], IN2);
  UB1BPPG_1_26 U2 (O[27], IN1P[1], IN2);
  UB1BPPG_2_26 U3 (O[28], IN1P[2], IN2);
  UB1BPPG_3_26 U4 (O[29], IN1P[3], IN2);
  UB1BPPG_4_26 U5 (O[30], IN1P[4], IN2);
  UB1BPPG_5_26 U6 (O[31], IN1P[5], IN2);
  UB1BPPG_6_26 U7 (O[32], IN1P[6], IN2);
  UB1BPPG_7_26 U8 (O[33], IN1P[7], IN2);
  UB1BPPG_8_26 U9 (O[34], IN1P[8], IN2);
  UB1BPPG_9_26 U10 (O[35], IN1P[9], IN2);
  UB1BPPG_10_26 U11 (O[36], IN1P[10], IN2);
  UB1BPPG_11_26 U12 (O[37], IN1P[11], IN2);
  UB1BPPG_12_26 U13 (O[38], IN1P[12], IN2);
  UB1BPPG_13_26 U14 (O[39], IN1P[13], IN2);
  UB1BPPG_14_26 U15 (O[40], IN1P[14], IN2);
  UB1BPPG_15_26 U16 (O[41], IN1P[15], IN2);
  UB1BPPG_16_26 U17 (O[42], IN1P[16], IN2);
  UB1BPPG_17_26 U18 (O[43], IN1P[17], IN2);
  UB1BPPG_18_26 U19 (O[44], IN1P[18], IN2);
  UB1BPPG_19_26 U20 (O[45], IN1P[19], IN2);
  UB1BPPG_20_26 U21 (O[46], IN1P[20], IN2);
  UB1BPPG_21_26 U22 (O[47], IN1P[21], IN2);
  UB1BPPG_22_26 U23 (O[48], IN1P[22], IN2);
  UB1BPPG_23_26 U24 (O[49], IN1P[23], IN2);
  UB1BPPG_24_26 U25 (O[50], IN1P[24], IN2);
  UB1BPPG_25_26 U26 (O[51], IN1P[25], IN2);
  UB1BPPG_26_26 U27 (O[52], IN1P[26], IN2);
  UB1BPPG_27_26 U28 (O[53], IN1P[27], IN2);
  UB1BPPG_28_26 U29 (O[54], IN1P[28], IN2);
  UB1BPPG_29_26 U30 (O[55], IN1P[29], IN2);
  UB1BPPG_30_26 U31 (O[56], IN1P[30], IN2);
  NU1BPPG_31_26 U32 (NEG, IN1N, IN2);
  NUBUB1CON_57 U33 (O[57], NEG);
endmodule

module TCUVPPG_31_0_27 (O, IN1, IN2);
  output [58:27] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_27 U1 (O[27], IN1P[0], IN2);
  UB1BPPG_1_27 U2 (O[28], IN1P[1], IN2);
  UB1BPPG_2_27 U3 (O[29], IN1P[2], IN2);
  UB1BPPG_3_27 U4 (O[30], IN1P[3], IN2);
  UB1BPPG_4_27 U5 (O[31], IN1P[4], IN2);
  UB1BPPG_5_27 U6 (O[32], IN1P[5], IN2);
  UB1BPPG_6_27 U7 (O[33], IN1P[6], IN2);
  UB1BPPG_7_27 U8 (O[34], IN1P[7], IN2);
  UB1BPPG_8_27 U9 (O[35], IN1P[8], IN2);
  UB1BPPG_9_27 U10 (O[36], IN1P[9], IN2);
  UB1BPPG_10_27 U11 (O[37], IN1P[10], IN2);
  UB1BPPG_11_27 U12 (O[38], IN1P[11], IN2);
  UB1BPPG_12_27 U13 (O[39], IN1P[12], IN2);
  UB1BPPG_13_27 U14 (O[40], IN1P[13], IN2);
  UB1BPPG_14_27 U15 (O[41], IN1P[14], IN2);
  UB1BPPG_15_27 U16 (O[42], IN1P[15], IN2);
  UB1BPPG_16_27 U17 (O[43], IN1P[16], IN2);
  UB1BPPG_17_27 U18 (O[44], IN1P[17], IN2);
  UB1BPPG_18_27 U19 (O[45], IN1P[18], IN2);
  UB1BPPG_19_27 U20 (O[46], IN1P[19], IN2);
  UB1BPPG_20_27 U21 (O[47], IN1P[20], IN2);
  UB1BPPG_21_27 U22 (O[48], IN1P[21], IN2);
  UB1BPPG_22_27 U23 (O[49], IN1P[22], IN2);
  UB1BPPG_23_27 U24 (O[50], IN1P[23], IN2);
  UB1BPPG_24_27 U25 (O[51], IN1P[24], IN2);
  UB1BPPG_25_27 U26 (O[52], IN1P[25], IN2);
  UB1BPPG_26_27 U27 (O[53], IN1P[26], IN2);
  UB1BPPG_27_27 U28 (O[54], IN1P[27], IN2);
  UB1BPPG_28_27 U29 (O[55], IN1P[28], IN2);
  UB1BPPG_29_27 U30 (O[56], IN1P[29], IN2);
  UB1BPPG_30_27 U31 (O[57], IN1P[30], IN2);
  NU1BPPG_31_27 U32 (NEG, IN1N, IN2);
  NUBUB1CON_58 U33 (O[58], NEG);
endmodule

module TCUVPPG_31_0_28 (O, IN1, IN2);
  output [59:28] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_28 U1 (O[28], IN1P[0], IN2);
  UB1BPPG_1_28 U2 (O[29], IN1P[1], IN2);
  UB1BPPG_2_28 U3 (O[30], IN1P[2], IN2);
  UB1BPPG_3_28 U4 (O[31], IN1P[3], IN2);
  UB1BPPG_4_28 U5 (O[32], IN1P[4], IN2);
  UB1BPPG_5_28 U6 (O[33], IN1P[5], IN2);
  UB1BPPG_6_28 U7 (O[34], IN1P[6], IN2);
  UB1BPPG_7_28 U8 (O[35], IN1P[7], IN2);
  UB1BPPG_8_28 U9 (O[36], IN1P[8], IN2);
  UB1BPPG_9_28 U10 (O[37], IN1P[9], IN2);
  UB1BPPG_10_28 U11 (O[38], IN1P[10], IN2);
  UB1BPPG_11_28 U12 (O[39], IN1P[11], IN2);
  UB1BPPG_12_28 U13 (O[40], IN1P[12], IN2);
  UB1BPPG_13_28 U14 (O[41], IN1P[13], IN2);
  UB1BPPG_14_28 U15 (O[42], IN1P[14], IN2);
  UB1BPPG_15_28 U16 (O[43], IN1P[15], IN2);
  UB1BPPG_16_28 U17 (O[44], IN1P[16], IN2);
  UB1BPPG_17_28 U18 (O[45], IN1P[17], IN2);
  UB1BPPG_18_28 U19 (O[46], IN1P[18], IN2);
  UB1BPPG_19_28 U20 (O[47], IN1P[19], IN2);
  UB1BPPG_20_28 U21 (O[48], IN1P[20], IN2);
  UB1BPPG_21_28 U22 (O[49], IN1P[21], IN2);
  UB1BPPG_22_28 U23 (O[50], IN1P[22], IN2);
  UB1BPPG_23_28 U24 (O[51], IN1P[23], IN2);
  UB1BPPG_24_28 U25 (O[52], IN1P[24], IN2);
  UB1BPPG_25_28 U26 (O[53], IN1P[25], IN2);
  UB1BPPG_26_28 U27 (O[54], IN1P[26], IN2);
  UB1BPPG_27_28 U28 (O[55], IN1P[27], IN2);
  UB1BPPG_28_28 U29 (O[56], IN1P[28], IN2);
  UB1BPPG_29_28 U30 (O[57], IN1P[29], IN2);
  UB1BPPG_30_28 U31 (O[58], IN1P[30], IN2);
  NU1BPPG_31_28 U32 (NEG, IN1N, IN2);
  NUBUB1CON_59 U33 (O[59], NEG);
endmodule

module TCUVPPG_31_0_29 (O, IN1, IN2);
  output [60:29] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_29 U1 (O[29], IN1P[0], IN2);
  UB1BPPG_1_29 U2 (O[30], IN1P[1], IN2);
  UB1BPPG_2_29 U3 (O[31], IN1P[2], IN2);
  UB1BPPG_3_29 U4 (O[32], IN1P[3], IN2);
  UB1BPPG_4_29 U5 (O[33], IN1P[4], IN2);
  UB1BPPG_5_29 U6 (O[34], IN1P[5], IN2);
  UB1BPPG_6_29 U7 (O[35], IN1P[6], IN2);
  UB1BPPG_7_29 U8 (O[36], IN1P[7], IN2);
  UB1BPPG_8_29 U9 (O[37], IN1P[8], IN2);
  UB1BPPG_9_29 U10 (O[38], IN1P[9], IN2);
  UB1BPPG_10_29 U11 (O[39], IN1P[10], IN2);
  UB1BPPG_11_29 U12 (O[40], IN1P[11], IN2);
  UB1BPPG_12_29 U13 (O[41], IN1P[12], IN2);
  UB1BPPG_13_29 U14 (O[42], IN1P[13], IN2);
  UB1BPPG_14_29 U15 (O[43], IN1P[14], IN2);
  UB1BPPG_15_29 U16 (O[44], IN1P[15], IN2);
  UB1BPPG_16_29 U17 (O[45], IN1P[16], IN2);
  UB1BPPG_17_29 U18 (O[46], IN1P[17], IN2);
  UB1BPPG_18_29 U19 (O[47], IN1P[18], IN2);
  UB1BPPG_19_29 U20 (O[48], IN1P[19], IN2);
  UB1BPPG_20_29 U21 (O[49], IN1P[20], IN2);
  UB1BPPG_21_29 U22 (O[50], IN1P[21], IN2);
  UB1BPPG_22_29 U23 (O[51], IN1P[22], IN2);
  UB1BPPG_23_29 U24 (O[52], IN1P[23], IN2);
  UB1BPPG_24_29 U25 (O[53], IN1P[24], IN2);
  UB1BPPG_25_29 U26 (O[54], IN1P[25], IN2);
  UB1BPPG_26_29 U27 (O[55], IN1P[26], IN2);
  UB1BPPG_27_29 U28 (O[56], IN1P[27], IN2);
  UB1BPPG_28_29 U29 (O[57], IN1P[28], IN2);
  UB1BPPG_29_29 U30 (O[58], IN1P[29], IN2);
  UB1BPPG_30_29 U31 (O[59], IN1P[30], IN2);
  NU1BPPG_31_29 U32 (NEG, IN1N, IN2);
  NUBUB1CON_60 U33 (O[60], NEG);
endmodule

module TCUVPPG_31_0_3 (O, IN1, IN2);
  output [34:3] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_3 U1 (O[3], IN1P[0], IN2);
  UB1BPPG_1_3 U2 (O[4], IN1P[1], IN2);
  UB1BPPG_2_3 U3 (O[5], IN1P[2], IN2);
  UB1BPPG_3_3 U4 (O[6], IN1P[3], IN2);
  UB1BPPG_4_3 U5 (O[7], IN1P[4], IN2);
  UB1BPPG_5_3 U6 (O[8], IN1P[5], IN2);
  UB1BPPG_6_3 U7 (O[9], IN1P[6], IN2);
  UB1BPPG_7_3 U8 (O[10], IN1P[7], IN2);
  UB1BPPG_8_3 U9 (O[11], IN1P[8], IN2);
  UB1BPPG_9_3 U10 (O[12], IN1P[9], IN2);
  UB1BPPG_10_3 U11 (O[13], IN1P[10], IN2);
  UB1BPPG_11_3 U12 (O[14], IN1P[11], IN2);
  UB1BPPG_12_3 U13 (O[15], IN1P[12], IN2);
  UB1BPPG_13_3 U14 (O[16], IN1P[13], IN2);
  UB1BPPG_14_3 U15 (O[17], IN1P[14], IN2);
  UB1BPPG_15_3 U16 (O[18], IN1P[15], IN2);
  UB1BPPG_16_3 U17 (O[19], IN1P[16], IN2);
  UB1BPPG_17_3 U18 (O[20], IN1P[17], IN2);
  UB1BPPG_18_3 U19 (O[21], IN1P[18], IN2);
  UB1BPPG_19_3 U20 (O[22], IN1P[19], IN2);
  UB1BPPG_20_3 U21 (O[23], IN1P[20], IN2);
  UB1BPPG_21_3 U22 (O[24], IN1P[21], IN2);
  UB1BPPG_22_3 U23 (O[25], IN1P[22], IN2);
  UB1BPPG_23_3 U24 (O[26], IN1P[23], IN2);
  UB1BPPG_24_3 U25 (O[27], IN1P[24], IN2);
  UB1BPPG_25_3 U26 (O[28], IN1P[25], IN2);
  UB1BPPG_26_3 U27 (O[29], IN1P[26], IN2);
  UB1BPPG_27_3 U28 (O[30], IN1P[27], IN2);
  UB1BPPG_28_3 U29 (O[31], IN1P[28], IN2);
  UB1BPPG_29_3 U30 (O[32], IN1P[29], IN2);
  UB1BPPG_30_3 U31 (O[33], IN1P[30], IN2);
  NU1BPPG_31_3 U32 (NEG, IN1N, IN2);
  NUBUB1CON_34 U33 (O[34], NEG);
endmodule

module TCUVPPG_31_0_30 (O, IN1, IN2);
  output [61:30] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_30 U1 (O[30], IN1P[0], IN2);
  UB1BPPG_1_30 U2 (O[31], IN1P[1], IN2);
  UB1BPPG_2_30 U3 (O[32], IN1P[2], IN2);
  UB1BPPG_3_30 U4 (O[33], IN1P[3], IN2);
  UB1BPPG_4_30 U5 (O[34], IN1P[4], IN2);
  UB1BPPG_5_30 U6 (O[35], IN1P[5], IN2);
  UB1BPPG_6_30 U7 (O[36], IN1P[6], IN2);
  UB1BPPG_7_30 U8 (O[37], IN1P[7], IN2);
  UB1BPPG_8_30 U9 (O[38], IN1P[8], IN2);
  UB1BPPG_9_30 U10 (O[39], IN1P[9], IN2);
  UB1BPPG_10_30 U11 (O[40], IN1P[10], IN2);
  UB1BPPG_11_30 U12 (O[41], IN1P[11], IN2);
  UB1BPPG_12_30 U13 (O[42], IN1P[12], IN2);
  UB1BPPG_13_30 U14 (O[43], IN1P[13], IN2);
  UB1BPPG_14_30 U15 (O[44], IN1P[14], IN2);
  UB1BPPG_15_30 U16 (O[45], IN1P[15], IN2);
  UB1BPPG_16_30 U17 (O[46], IN1P[16], IN2);
  UB1BPPG_17_30 U18 (O[47], IN1P[17], IN2);
  UB1BPPG_18_30 U19 (O[48], IN1P[18], IN2);
  UB1BPPG_19_30 U20 (O[49], IN1P[19], IN2);
  UB1BPPG_20_30 U21 (O[50], IN1P[20], IN2);
  UB1BPPG_21_30 U22 (O[51], IN1P[21], IN2);
  UB1BPPG_22_30 U23 (O[52], IN1P[22], IN2);
  UB1BPPG_23_30 U24 (O[53], IN1P[23], IN2);
  UB1BPPG_24_30 U25 (O[54], IN1P[24], IN2);
  UB1BPPG_25_30 U26 (O[55], IN1P[25], IN2);
  UB1BPPG_26_30 U27 (O[56], IN1P[26], IN2);
  UB1BPPG_27_30 U28 (O[57], IN1P[27], IN2);
  UB1BPPG_28_30 U29 (O[58], IN1P[28], IN2);
  UB1BPPG_29_30 U30 (O[59], IN1P[29], IN2);
  UB1BPPG_30_30 U31 (O[60], IN1P[30], IN2);
  NU1BPPG_31_30 U32 (NEG, IN1N, IN2);
  NUBUB1CON_61 U33 (O[61], NEG);
endmodule

module TCUVPPG_31_0_4 (O, IN1, IN2);
  output [35:4] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_4 U1 (O[4], IN1P[0], IN2);
  UB1BPPG_1_4 U2 (O[5], IN1P[1], IN2);
  UB1BPPG_2_4 U3 (O[6], IN1P[2], IN2);
  UB1BPPG_3_4 U4 (O[7], IN1P[3], IN2);
  UB1BPPG_4_4 U5 (O[8], IN1P[4], IN2);
  UB1BPPG_5_4 U6 (O[9], IN1P[5], IN2);
  UB1BPPG_6_4 U7 (O[10], IN1P[6], IN2);
  UB1BPPG_7_4 U8 (O[11], IN1P[7], IN2);
  UB1BPPG_8_4 U9 (O[12], IN1P[8], IN2);
  UB1BPPG_9_4 U10 (O[13], IN1P[9], IN2);
  UB1BPPG_10_4 U11 (O[14], IN1P[10], IN2);
  UB1BPPG_11_4 U12 (O[15], IN1P[11], IN2);
  UB1BPPG_12_4 U13 (O[16], IN1P[12], IN2);
  UB1BPPG_13_4 U14 (O[17], IN1P[13], IN2);
  UB1BPPG_14_4 U15 (O[18], IN1P[14], IN2);
  UB1BPPG_15_4 U16 (O[19], IN1P[15], IN2);
  UB1BPPG_16_4 U17 (O[20], IN1P[16], IN2);
  UB1BPPG_17_4 U18 (O[21], IN1P[17], IN2);
  UB1BPPG_18_4 U19 (O[22], IN1P[18], IN2);
  UB1BPPG_19_4 U20 (O[23], IN1P[19], IN2);
  UB1BPPG_20_4 U21 (O[24], IN1P[20], IN2);
  UB1BPPG_21_4 U22 (O[25], IN1P[21], IN2);
  UB1BPPG_22_4 U23 (O[26], IN1P[22], IN2);
  UB1BPPG_23_4 U24 (O[27], IN1P[23], IN2);
  UB1BPPG_24_4 U25 (O[28], IN1P[24], IN2);
  UB1BPPG_25_4 U26 (O[29], IN1P[25], IN2);
  UB1BPPG_26_4 U27 (O[30], IN1P[26], IN2);
  UB1BPPG_27_4 U28 (O[31], IN1P[27], IN2);
  UB1BPPG_28_4 U29 (O[32], IN1P[28], IN2);
  UB1BPPG_29_4 U30 (O[33], IN1P[29], IN2);
  UB1BPPG_30_4 U31 (O[34], IN1P[30], IN2);
  NU1BPPG_31_4 U32 (NEG, IN1N, IN2);
  NUBUB1CON_35 U33 (O[35], NEG);
endmodule

module TCUVPPG_31_0_5 (O, IN1, IN2);
  output [36:5] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_5 U1 (O[5], IN1P[0], IN2);
  UB1BPPG_1_5 U2 (O[6], IN1P[1], IN2);
  UB1BPPG_2_5 U3 (O[7], IN1P[2], IN2);
  UB1BPPG_3_5 U4 (O[8], IN1P[3], IN2);
  UB1BPPG_4_5 U5 (O[9], IN1P[4], IN2);
  UB1BPPG_5_5 U6 (O[10], IN1P[5], IN2);
  UB1BPPG_6_5 U7 (O[11], IN1P[6], IN2);
  UB1BPPG_7_5 U8 (O[12], IN1P[7], IN2);
  UB1BPPG_8_5 U9 (O[13], IN1P[8], IN2);
  UB1BPPG_9_5 U10 (O[14], IN1P[9], IN2);
  UB1BPPG_10_5 U11 (O[15], IN1P[10], IN2);
  UB1BPPG_11_5 U12 (O[16], IN1P[11], IN2);
  UB1BPPG_12_5 U13 (O[17], IN1P[12], IN2);
  UB1BPPG_13_5 U14 (O[18], IN1P[13], IN2);
  UB1BPPG_14_5 U15 (O[19], IN1P[14], IN2);
  UB1BPPG_15_5 U16 (O[20], IN1P[15], IN2);
  UB1BPPG_16_5 U17 (O[21], IN1P[16], IN2);
  UB1BPPG_17_5 U18 (O[22], IN1P[17], IN2);
  UB1BPPG_18_5 U19 (O[23], IN1P[18], IN2);
  UB1BPPG_19_5 U20 (O[24], IN1P[19], IN2);
  UB1BPPG_20_5 U21 (O[25], IN1P[20], IN2);
  UB1BPPG_21_5 U22 (O[26], IN1P[21], IN2);
  UB1BPPG_22_5 U23 (O[27], IN1P[22], IN2);
  UB1BPPG_23_5 U24 (O[28], IN1P[23], IN2);
  UB1BPPG_24_5 U25 (O[29], IN1P[24], IN2);
  UB1BPPG_25_5 U26 (O[30], IN1P[25], IN2);
  UB1BPPG_26_5 U27 (O[31], IN1P[26], IN2);
  UB1BPPG_27_5 U28 (O[32], IN1P[27], IN2);
  UB1BPPG_28_5 U29 (O[33], IN1P[28], IN2);
  UB1BPPG_29_5 U30 (O[34], IN1P[29], IN2);
  UB1BPPG_30_5 U31 (O[35], IN1P[30], IN2);
  NU1BPPG_31_5 U32 (NEG, IN1N, IN2);
  NUBUB1CON_36 U33 (O[36], NEG);
endmodule

module TCUVPPG_31_0_6 (O, IN1, IN2);
  output [37:6] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_6 U1 (O[6], IN1P[0], IN2);
  UB1BPPG_1_6 U2 (O[7], IN1P[1], IN2);
  UB1BPPG_2_6 U3 (O[8], IN1P[2], IN2);
  UB1BPPG_3_6 U4 (O[9], IN1P[3], IN2);
  UB1BPPG_4_6 U5 (O[10], IN1P[4], IN2);
  UB1BPPG_5_6 U6 (O[11], IN1P[5], IN2);
  UB1BPPG_6_6 U7 (O[12], IN1P[6], IN2);
  UB1BPPG_7_6 U8 (O[13], IN1P[7], IN2);
  UB1BPPG_8_6 U9 (O[14], IN1P[8], IN2);
  UB1BPPG_9_6 U10 (O[15], IN1P[9], IN2);
  UB1BPPG_10_6 U11 (O[16], IN1P[10], IN2);
  UB1BPPG_11_6 U12 (O[17], IN1P[11], IN2);
  UB1BPPG_12_6 U13 (O[18], IN1P[12], IN2);
  UB1BPPG_13_6 U14 (O[19], IN1P[13], IN2);
  UB1BPPG_14_6 U15 (O[20], IN1P[14], IN2);
  UB1BPPG_15_6 U16 (O[21], IN1P[15], IN2);
  UB1BPPG_16_6 U17 (O[22], IN1P[16], IN2);
  UB1BPPG_17_6 U18 (O[23], IN1P[17], IN2);
  UB1BPPG_18_6 U19 (O[24], IN1P[18], IN2);
  UB1BPPG_19_6 U20 (O[25], IN1P[19], IN2);
  UB1BPPG_20_6 U21 (O[26], IN1P[20], IN2);
  UB1BPPG_21_6 U22 (O[27], IN1P[21], IN2);
  UB1BPPG_22_6 U23 (O[28], IN1P[22], IN2);
  UB1BPPG_23_6 U24 (O[29], IN1P[23], IN2);
  UB1BPPG_24_6 U25 (O[30], IN1P[24], IN2);
  UB1BPPG_25_6 U26 (O[31], IN1P[25], IN2);
  UB1BPPG_26_6 U27 (O[32], IN1P[26], IN2);
  UB1BPPG_27_6 U28 (O[33], IN1P[27], IN2);
  UB1BPPG_28_6 U29 (O[34], IN1P[28], IN2);
  UB1BPPG_29_6 U30 (O[35], IN1P[29], IN2);
  UB1BPPG_30_6 U31 (O[36], IN1P[30], IN2);
  NU1BPPG_31_6 U32 (NEG, IN1N, IN2);
  NUBUB1CON_37 U33 (O[37], NEG);
endmodule

module TCUVPPG_31_0_7 (O, IN1, IN2);
  output [38:7] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_7 U1 (O[7], IN1P[0], IN2);
  UB1BPPG_1_7 U2 (O[8], IN1P[1], IN2);
  UB1BPPG_2_7 U3 (O[9], IN1P[2], IN2);
  UB1BPPG_3_7 U4 (O[10], IN1P[3], IN2);
  UB1BPPG_4_7 U5 (O[11], IN1P[4], IN2);
  UB1BPPG_5_7 U6 (O[12], IN1P[5], IN2);
  UB1BPPG_6_7 U7 (O[13], IN1P[6], IN2);
  UB1BPPG_7_7 U8 (O[14], IN1P[7], IN2);
  UB1BPPG_8_7 U9 (O[15], IN1P[8], IN2);
  UB1BPPG_9_7 U10 (O[16], IN1P[9], IN2);
  UB1BPPG_10_7 U11 (O[17], IN1P[10], IN2);
  UB1BPPG_11_7 U12 (O[18], IN1P[11], IN2);
  UB1BPPG_12_7 U13 (O[19], IN1P[12], IN2);
  UB1BPPG_13_7 U14 (O[20], IN1P[13], IN2);
  UB1BPPG_14_7 U15 (O[21], IN1P[14], IN2);
  UB1BPPG_15_7 U16 (O[22], IN1P[15], IN2);
  UB1BPPG_16_7 U17 (O[23], IN1P[16], IN2);
  UB1BPPG_17_7 U18 (O[24], IN1P[17], IN2);
  UB1BPPG_18_7 U19 (O[25], IN1P[18], IN2);
  UB1BPPG_19_7 U20 (O[26], IN1P[19], IN2);
  UB1BPPG_20_7 U21 (O[27], IN1P[20], IN2);
  UB1BPPG_21_7 U22 (O[28], IN1P[21], IN2);
  UB1BPPG_22_7 U23 (O[29], IN1P[22], IN2);
  UB1BPPG_23_7 U24 (O[30], IN1P[23], IN2);
  UB1BPPG_24_7 U25 (O[31], IN1P[24], IN2);
  UB1BPPG_25_7 U26 (O[32], IN1P[25], IN2);
  UB1BPPG_26_7 U27 (O[33], IN1P[26], IN2);
  UB1BPPG_27_7 U28 (O[34], IN1P[27], IN2);
  UB1BPPG_28_7 U29 (O[35], IN1P[28], IN2);
  UB1BPPG_29_7 U30 (O[36], IN1P[29], IN2);
  UB1BPPG_30_7 U31 (O[37], IN1P[30], IN2);
  NU1BPPG_31_7 U32 (NEG, IN1N, IN2);
  NUBUB1CON_38 U33 (O[38], NEG);
endmodule

module TCUVPPG_31_0_8 (O, IN1, IN2);
  output [39:8] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_8 U1 (O[8], IN1P[0], IN2);
  UB1BPPG_1_8 U2 (O[9], IN1P[1], IN2);
  UB1BPPG_2_8 U3 (O[10], IN1P[2], IN2);
  UB1BPPG_3_8 U4 (O[11], IN1P[3], IN2);
  UB1BPPG_4_8 U5 (O[12], IN1P[4], IN2);
  UB1BPPG_5_8 U6 (O[13], IN1P[5], IN2);
  UB1BPPG_6_8 U7 (O[14], IN1P[6], IN2);
  UB1BPPG_7_8 U8 (O[15], IN1P[7], IN2);
  UB1BPPG_8_8 U9 (O[16], IN1P[8], IN2);
  UB1BPPG_9_8 U10 (O[17], IN1P[9], IN2);
  UB1BPPG_10_8 U11 (O[18], IN1P[10], IN2);
  UB1BPPG_11_8 U12 (O[19], IN1P[11], IN2);
  UB1BPPG_12_8 U13 (O[20], IN1P[12], IN2);
  UB1BPPG_13_8 U14 (O[21], IN1P[13], IN2);
  UB1BPPG_14_8 U15 (O[22], IN1P[14], IN2);
  UB1BPPG_15_8 U16 (O[23], IN1P[15], IN2);
  UB1BPPG_16_8 U17 (O[24], IN1P[16], IN2);
  UB1BPPG_17_8 U18 (O[25], IN1P[17], IN2);
  UB1BPPG_18_8 U19 (O[26], IN1P[18], IN2);
  UB1BPPG_19_8 U20 (O[27], IN1P[19], IN2);
  UB1BPPG_20_8 U21 (O[28], IN1P[20], IN2);
  UB1BPPG_21_8 U22 (O[29], IN1P[21], IN2);
  UB1BPPG_22_8 U23 (O[30], IN1P[22], IN2);
  UB1BPPG_23_8 U24 (O[31], IN1P[23], IN2);
  UB1BPPG_24_8 U25 (O[32], IN1P[24], IN2);
  UB1BPPG_25_8 U26 (O[33], IN1P[25], IN2);
  UB1BPPG_26_8 U27 (O[34], IN1P[26], IN2);
  UB1BPPG_27_8 U28 (O[35], IN1P[27], IN2);
  UB1BPPG_28_8 U29 (O[36], IN1P[28], IN2);
  UB1BPPG_29_8 U30 (O[37], IN1P[29], IN2);
  UB1BPPG_30_8 U31 (O[38], IN1P[30], IN2);
  NU1BPPG_31_8 U32 (NEG, IN1N, IN2);
  NUBUB1CON_39 U33 (O[39], NEG);
endmodule

module TCUVPPG_31_0_9 (O, IN1, IN2);
  output [40:9] O;
  input [31:0] IN1;
  input IN2;
  wire IN1N;
  wire [30:0] IN1P;
  wire NEG;
  TCDECON_31_0 U0 (IN1N, IN1P, IN1);
  UB1BPPG_0_9 U1 (O[9], IN1P[0], IN2);
  UB1BPPG_1_9 U2 (O[10], IN1P[1], IN2);
  UB1BPPG_2_9 U3 (O[11], IN1P[2], IN2);
  UB1BPPG_3_9 U4 (O[12], IN1P[3], IN2);
  UB1BPPG_4_9 U5 (O[13], IN1P[4], IN2);
  UB1BPPG_5_9 U6 (O[14], IN1P[5], IN2);
  UB1BPPG_6_9 U7 (O[15], IN1P[6], IN2);
  UB1BPPG_7_9 U8 (O[16], IN1P[7], IN2);
  UB1BPPG_8_9 U9 (O[17], IN1P[8], IN2);
  UB1BPPG_9_9 U10 (O[18], IN1P[9], IN2);
  UB1BPPG_10_9 U11 (O[19], IN1P[10], IN2);
  UB1BPPG_11_9 U12 (O[20], IN1P[11], IN2);
  UB1BPPG_12_9 U13 (O[21], IN1P[12], IN2);
  UB1BPPG_13_9 U14 (O[22], IN1P[13], IN2);
  UB1BPPG_14_9 U15 (O[23], IN1P[14], IN2);
  UB1BPPG_15_9 U16 (O[24], IN1P[15], IN2);
  UB1BPPG_16_9 U17 (O[25], IN1P[16], IN2);
  UB1BPPG_17_9 U18 (O[26], IN1P[17], IN2);
  UB1BPPG_18_9 U19 (O[27], IN1P[18], IN2);
  UB1BPPG_19_9 U20 (O[28], IN1P[19], IN2);
  UB1BPPG_20_9 U21 (O[29], IN1P[20], IN2);
  UB1BPPG_21_9 U22 (O[30], IN1P[21], IN2);
  UB1BPPG_22_9 U23 (O[31], IN1P[22], IN2);
  UB1BPPG_23_9 U24 (O[32], IN1P[23], IN2);
  UB1BPPG_24_9 U25 (O[33], IN1P[24], IN2);
  UB1BPPG_25_9 U26 (O[34], IN1P[25], IN2);
  UB1BPPG_26_9 U27 (O[35], IN1P[26], IN2);
  UB1BPPG_27_9 U28 (O[36], IN1P[27], IN2);
  UB1BPPG_28_9 U29 (O[37], IN1P[28], IN2);
  UB1BPPG_29_9 U30 (O[38], IN1P[29], IN2);
  UB1BPPG_30_9 U31 (O[39], IN1P[30], IN2);
  NU1BPPG_31_9 U32 (NEG, IN1N, IN2);
  NUBUB1CON_40 U33 (O[40], NEG);
endmodule

module UBCMBIN_32_32_31_000 (O, IN0, IN1);
  output [32:0] O;
  input IN0;
  input [31:0] IN1;
  UB1DCON_32 U0 (O[32], IN0);
  UBCON_31_0 U1 (O[31:0], IN1);
endmodule

module UBCON_10_9 (O, I);
  output [10:9] O;
  input [10:9] I;
  UB1DCON_9 U0 (O[9], I[9]);
  UB1DCON_10 U1 (O[10], I[10]);
endmodule

module UBCON_12_10 (O, I);
  output [12:10] O;
  input [12:10] I;
  UB1DCON_10 U0 (O[10], I[10]);
  UB1DCON_11 U1 (O[11], I[11]);
  UB1DCON_12 U2 (O[12], I[12]);
endmodule

module UBCON_14_13 (O, I);
  output [14:13] O;
  input [14:13] I;
  UB1DCON_13 U0 (O[13], I[13]);
  UB1DCON_14 U1 (O[14], I[14]);
endmodule

module UBCON_17_14 (O, I);
  output [17:14] O;
  input [17:14] I;
  UB1DCON_14 U0 (O[14], I[14]);
  UB1DCON_15 U1 (O[15], I[15]);
  UB1DCON_16 U2 (O[16], I[16]);
  UB1DCON_17 U3 (O[17], I[17]);
endmodule

module UBCON_19_18 (O, I);
  output [19:18] O;
  input [19:18] I;
  UB1DCON_18 U0 (O[18], I[18]);
  UB1DCON_19 U1 (O[19], I[19]);
endmodule

module UBCON_1_0 (O, I);
  output [1:0] O;
  input [1:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
endmodule

module UBCON_23_22 (O, I);
  output [23:22] O;
  input [23:22] I;
  UB1DCON_22 U0 (O[22], I[22]);
  UB1DCON_23 U1 (O[23], I[23]);
endmodule

module UBCON_24_19 (O, I);
  output [24:19] O;
  input [24:19] I;
  UB1DCON_19 U0 (O[19], I[19]);
  UB1DCON_20 U1 (O[20], I[20]);
  UB1DCON_21 U2 (O[21], I[21]);
  UB1DCON_22 U3 (O[22], I[22]);
  UB1DCON_23 U4 (O[23], I[23]);
  UB1DCON_24 U5 (O[24], I[24]);
endmodule

module UBCON_26_25 (O, I);
  output [26:25] O;
  input [26:25] I;
  UB1DCON_25 U0 (O[25], I[25]);
  UB1DCON_26 U1 (O[26], I[26]);
endmodule

module UBCON_27_25 (O, I);
  output [27:25] O;
  input [27:25] I;
  UB1DCON_25 U0 (O[25], I[25]);
  UB1DCON_26 U1 (O[26], I[26]);
  UB1DCON_27 U2 (O[27], I[27]);
endmodule

module UBCON_2_0 (O, I);
  output [2:0] O;
  input [2:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
endmodule

module UBCON_31_0 (O, I);
  output [31:0] O;
  input [31:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
  UB1DCON_4 U4 (O[4], I[4]);
  UB1DCON_5 U5 (O[5], I[5]);
  UB1DCON_6 U6 (O[6], I[6]);
  UB1DCON_7 U7 (O[7], I[7]);
  UB1DCON_8 U8 (O[8], I[8]);
  UB1DCON_9 U9 (O[9], I[9]);
  UB1DCON_10 U10 (O[10], I[10]);
  UB1DCON_11 U11 (O[11], I[11]);
  UB1DCON_12 U12 (O[12], I[12]);
  UB1DCON_13 U13 (O[13], I[13]);
  UB1DCON_14 U14 (O[14], I[14]);
  UB1DCON_15 U15 (O[15], I[15]);
  UB1DCON_16 U16 (O[16], I[16]);
  UB1DCON_17 U17 (O[17], I[17]);
  UB1DCON_18 U18 (O[18], I[18]);
  UB1DCON_19 U19 (O[19], I[19]);
  UB1DCON_20 U20 (O[20], I[20]);
  UB1DCON_21 U21 (O[21], I[21]);
  UB1DCON_22 U22 (O[22], I[22]);
  UB1DCON_23 U23 (O[23], I[23]);
  UB1DCON_24 U24 (O[24], I[24]);
  UB1DCON_25 U25 (O[25], I[25]);
  UB1DCON_26 U26 (O[26], I[26]);
  UB1DCON_27 U27 (O[27], I[27]);
  UB1DCON_28 U28 (O[28], I[28]);
  UB1DCON_29 U29 (O[29], I[29]);
  UB1DCON_30 U30 (O[30], I[30]);
  UB1DCON_31 U31 (O[31], I[31]);
endmodule

module UBCON_36_34 (O, I);
  output [36:34] O;
  input [36:34] I;
  UB1DCON_34 U0 (O[34], I[34]);
  UB1DCON_35 U1 (O[35], I[35]);
  UB1DCON_36 U2 (O[36], I[36]);
endmodule

module UBCON_39_37 (O, I);
  output [39:37] O;
  input [39:37] I;
  UB1DCON_37 U0 (O[37], I[37]);
  UB1DCON_38 U1 (O[38], I[38]);
  UB1DCON_39 U2 (O[39], I[39]);
endmodule

module UBCON_3_0 (O, I);
  output [3:0] O;
  input [3:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
endmodule

module UBCON_43_40 (O, I);
  output [43:40] O;
  input [43:40] I;
  UB1DCON_40 U0 (O[40], I[40]);
  UB1DCON_41 U1 (O[41], I[41]);
  UB1DCON_42 U2 (O[42], I[42]);
  UB1DCON_43 U3 (O[43], I[43]);
endmodule

module UBCON_49_44 (O, I);
  output [49:44] O;
  input [49:44] I;
  UB1DCON_44 U0 (O[44], I[44]);
  UB1DCON_45 U1 (O[45], I[45]);
  UB1DCON_46 U2 (O[46], I[46]);
  UB1DCON_47 U3 (O[47], I[47]);
  UB1DCON_48 U4 (O[48], I[48]);
  UB1DCON_49 U5 (O[49], I[49]);
endmodule

module UBCON_49_47 (O, I);
  output [49:47] O;
  input [49:47] I;
  UB1DCON_47 U0 (O[47], I[47]);
  UB1DCON_48 U1 (O[48], I[48]);
  UB1DCON_49 U2 (O[49], I[49]);
endmodule

module UBCON_49_48 (O, I);
  output [49:48] O;
  input [49:48] I;
  UB1DCON_48 U0 (O[48], I[48]);
  UB1DCON_49 U1 (O[49], I[49]);
endmodule

module UBCON_4_0 (O, I);
  output [4:0] O;
  input [4:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
  UB1DCON_4 U4 (O[4], I[4]);
endmodule

module UBCON_58_50 (O, I);
  output [58:50] O;
  input [58:50] I;
  UB1DCON_50 U0 (O[50], I[50]);
  UB1DCON_51 U1 (O[51], I[51]);
  UB1DCON_52 U2 (O[52], I[52]);
  UB1DCON_53 U3 (O[53], I[53]);
  UB1DCON_54 U4 (O[54], I[54]);
  UB1DCON_55 U5 (O[55], I[55]);
  UB1DCON_56 U6 (O[56], I[56]);
  UB1DCON_57 U7 (O[57], I[57]);
  UB1DCON_58 U8 (O[58], I[58]);
endmodule

module UBCON_58_54 (O, I);
  output [58:54] O;
  input [58:54] I;
  UB1DCON_54 U0 (O[54], I[54]);
  UB1DCON_55 U1 (O[55], I[55]);
  UB1DCON_56 U2 (O[56], I[56]);
  UB1DCON_57 U3 (O[57], I[57]);
  UB1DCON_58 U4 (O[58], I[58]);
endmodule

module UBCON_58_55 (O, I);
  output [58:55] O;
  input [58:55] I;
  UB1DCON_55 U0 (O[55], I[55]);
  UB1DCON_56 U1 (O[56], I[56]);
  UB1DCON_57 U2 (O[57], I[57]);
  UB1DCON_58 U3 (O[58], I[58]);
endmodule

module UBCON_58_56 (O, I);
  output [58:56] O;
  input [58:56] I;
  UB1DCON_56 U0 (O[56], I[56]);
  UB1DCON_57 U1 (O[57], I[57]);
  UB1DCON_58 U2 (O[58], I[58]);
endmodule

module UBCON_5_0 (O, I);
  output [5:0] O;
  input [5:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
  UB1DCON_4 U4 (O[4], I[4]);
  UB1DCON_5 U5 (O[5], I[5]);
endmodule

module UBCON_63_59 (O, I);
  output [63:59] O;
  input [63:59] I;
  UB1DCON_59 U0 (O[59], I[59]);
  UB1DCON_60 U1 (O[60], I[60]);
  UB1DCON_61 U2 (O[61], I[61]);
  UB1DCON_62 U3 (O[62], I[62]);
  UB1DCON_63 U4 (O[63], I[63]);
endmodule

module UBCON_63_9 (O, I);
  output [63:9] O;
  input [63:9] I;
  UB1DCON_9 U0 (O[9], I[9]);
  UB1DCON_10 U1 (O[10], I[10]);
  UB1DCON_11 U2 (O[11], I[11]);
  UB1DCON_12 U3 (O[12], I[12]);
  UB1DCON_13 U4 (O[13], I[13]);
  UB1DCON_14 U5 (O[14], I[14]);
  UB1DCON_15 U6 (O[15], I[15]);
  UB1DCON_16 U7 (O[16], I[16]);
  UB1DCON_17 U8 (O[17], I[17]);
  UB1DCON_18 U9 (O[18], I[18]);
  UB1DCON_19 U10 (O[19], I[19]);
  UB1DCON_20 U11 (O[20], I[20]);
  UB1DCON_21 U12 (O[21], I[21]);
  UB1DCON_22 U13 (O[22], I[22]);
  UB1DCON_23 U14 (O[23], I[23]);
  UB1DCON_24 U15 (O[24], I[24]);
  UB1DCON_25 U16 (O[25], I[25]);
  UB1DCON_26 U17 (O[26], I[26]);
  UB1DCON_27 U18 (O[27], I[27]);
  UB1DCON_28 U19 (O[28], I[28]);
  UB1DCON_29 U20 (O[29], I[29]);
  UB1DCON_30 U21 (O[30], I[30]);
  UB1DCON_31 U22 (O[31], I[31]);
  UB1DCON_32 U23 (O[32], I[32]);
  UB1DCON_33 U24 (O[33], I[33]);
  UB1DCON_34 U25 (O[34], I[34]);
  UB1DCON_35 U26 (O[35], I[35]);
  UB1DCON_36 U27 (O[36], I[36]);
  UB1DCON_37 U28 (O[37], I[37]);
  UB1DCON_38 U29 (O[38], I[38]);
  UB1DCON_39 U30 (O[39], I[39]);
  UB1DCON_40 U31 (O[40], I[40]);
  UB1DCON_41 U32 (O[41], I[41]);
  UB1DCON_42 U33 (O[42], I[42]);
  UB1DCON_43 U34 (O[43], I[43]);
  UB1DCON_44 U35 (O[44], I[44]);
  UB1DCON_45 U36 (O[45], I[45]);
  UB1DCON_46 U37 (O[46], I[46]);
  UB1DCON_47 U38 (O[47], I[47]);
  UB1DCON_48 U39 (O[48], I[48]);
  UB1DCON_49 U40 (O[49], I[49]);
  UB1DCON_50 U41 (O[50], I[50]);
  UB1DCON_51 U42 (O[51], I[51]);
  UB1DCON_52 U43 (O[52], I[52]);
  UB1DCON_53 U44 (O[53], I[53]);
  UB1DCON_54 U45 (O[54], I[54]);
  UB1DCON_55 U46 (O[55], I[55]);
  UB1DCON_56 U47 (O[56], I[56]);
  UB1DCON_57 U48 (O[57], I[57]);
  UB1DCON_58 U49 (O[58], I[58]);
  UB1DCON_59 U50 (O[59], I[59]);
  UB1DCON_60 U51 (O[60], I[60]);
  UB1DCON_61 U52 (O[61], I[61]);
  UB1DCON_62 U53 (O[62], I[62]);
  UB1DCON_63 U54 (O[63], I[63]);
endmodule

module UBCON_6_0 (O, I);
  output [6:0] O;
  input [6:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
  UB1DCON_4 U4 (O[4], I[4]);
  UB1DCON_5 U5 (O[5], I[5]);
  UB1DCON_6 U6 (O[6], I[6]);
endmodule

module UBCON_7_0 (O, I);
  output [7:0] O;
  input [7:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
  UB1DCON_4 U4 (O[4], I[4]);
  UB1DCON_5 U5 (O[5], I[5]);
  UB1DCON_6 U6 (O[6], I[6]);
  UB1DCON_7 U7 (O[7], I[7]);
endmodule

module UBCON_8_0 (O, I);
  output [8:0] O;
  input [8:0] I;
  UB1DCON_0 U0 (O[0], I[0]);
  UB1DCON_1 U1 (O[1], I[1]);
  UB1DCON_2 U2 (O[2], I[2]);
  UB1DCON_3 U3 (O[3], I[3]);
  UB1DCON_4 U4 (O[4], I[4]);
  UB1DCON_5 U5 (O[5], I[5]);
  UB1DCON_6 U6 (O[6], I[6]);
  UB1DCON_7 U7 (O[7], I[7]);
  UB1DCON_8 U8 (O[8], I[8]);
endmodule

module UBCON_8_7 (O, I);
  output [8:7] O;
  input [8:7] I;
  UB1DCON_7 U0 (O[7], I[7]);
  UB1DCON_8 U1 (O[8], I[8]);
endmodule

module UBExtender_63_9_6000 (O, I);
  output [64:9] O;
  input [63:9] I;
  UBCON_63_9 U0 (O[63:9], I[63:9]);
  UBZero_64_64 U1 (O[64]);
endmodule

module UBKSA_64_9_63_0 (S, X, Y);
  output [65:0] S;
  input [64:9] X;
  input [63:0] Y;
  wire [64:9] Z;
  UBExtender_63_9_6000 U0 (Z[64:9], Y[63:9]);
  UBPureKSA_64_9 U1 (S[65:9], X[64:9], Z[64:9]);
  UBCON_8_0 U2 (S[8:0], Y[8:0]);
endmodule

module UBPureKSA_64_9 (S, X, Y);
  output [65:9] S;
  input [64:9] X;
  input [64:9] Y;
  wire C;
  UBPriKSA_64_9 U0 (S, X, Y, C);
  UBZero_9_9 U1 (C);
endmodule

module UBTCCONV63_65_0 (O, I);
  output [66:0] O;
  input [65:0] I;
  UBTC1CON66_0 U0 (O[0], I[0]);
  UBTC1CON66_1 U1 (O[1], I[1]);
  UBTC1CON66_2 U2 (O[2], I[2]);
  UBTC1CON66_3 U3 (O[3], I[3]);
  UBTC1CON66_4 U4 (O[4], I[4]);
  UBTC1CON66_5 U5 (O[5], I[5]);
  UBTC1CON66_6 U6 (O[6], I[6]);
  UBTC1CON66_7 U7 (O[7], I[7]);
  UBTC1CON66_8 U8 (O[8], I[8]);
  UBTC1CON66_9 U9 (O[9], I[9]);
  UBTC1CON66_10 U10 (O[10], I[10]);
  UBTC1CON66_11 U11 (O[11], I[11]);
  UBTC1CON66_12 U12 (O[12], I[12]);
  UBTC1CON66_13 U13 (O[13], I[13]);
  UBTC1CON66_14 U14 (O[14], I[14]);
  UBTC1CON66_15 U15 (O[15], I[15]);
  UBTC1CON66_16 U16 (O[16], I[16]);
  UBTC1CON66_17 U17 (O[17], I[17]);
  UBTC1CON66_18 U18 (O[18], I[18]);
  UBTC1CON66_19 U19 (O[19], I[19]);
  UBTC1CON66_20 U20 (O[20], I[20]);
  UBTC1CON66_21 U21 (O[21], I[21]);
  UBTC1CON66_22 U22 (O[22], I[22]);
  UBTC1CON66_23 U23 (O[23], I[23]);
  UBTC1CON66_24 U24 (O[24], I[24]);
  UBTC1CON66_25 U25 (O[25], I[25]);
  UBTC1CON66_26 U26 (O[26], I[26]);
  UBTC1CON66_27 U27 (O[27], I[27]);
  UBTC1CON66_28 U28 (O[28], I[28]);
  UBTC1CON66_29 U29 (O[29], I[29]);
  UBTC1CON66_30 U30 (O[30], I[30]);
  UBTC1CON66_31 U31 (O[31], I[31]);
  UBTC1CON66_32 U32 (O[32], I[32]);
  UBTC1CON66_33 U33 (O[33], I[33]);
  UBTC1CON66_34 U34 (O[34], I[34]);
  UBTC1CON66_35 U35 (O[35], I[35]);
  UBTC1CON66_36 U36 (O[36], I[36]);
  UBTC1CON66_37 U37 (O[37], I[37]);
  UBTC1CON66_38 U38 (O[38], I[38]);
  UBTC1CON66_39 U39 (O[39], I[39]);
  UBTC1CON66_40 U40 (O[40], I[40]);
  UBTC1CON66_41 U41 (O[41], I[41]);
  UBTC1CON66_42 U42 (O[42], I[42]);
  UBTC1CON66_43 U43 (O[43], I[43]);
  UBTC1CON66_44 U44 (O[44], I[44]);
  UBTC1CON66_45 U45 (O[45], I[45]);
  UBTC1CON66_46 U46 (O[46], I[46]);
  UBTC1CON66_47 U47 (O[47], I[47]);
  UBTC1CON66_48 U48 (O[48], I[48]);
  UBTC1CON66_49 U49 (O[49], I[49]);
  UBTC1CON66_50 U50 (O[50], I[50]);
  UBTC1CON66_51 U51 (O[51], I[51]);
  UBTC1CON66_52 U52 (O[52], I[52]);
  UBTC1CON66_53 U53 (O[53], I[53]);
  UBTC1CON66_54 U54 (O[54], I[54]);
  UBTC1CON66_55 U55 (O[55], I[55]);
  UBTC1CON66_56 U56 (O[56], I[56]);
  UBTC1CON66_57 U57 (O[57], I[57]);
  UBTC1CON66_58 U58 (O[58], I[58]);
  UBTC1CON66_59 U59 (O[59], I[59]);
  UBTC1CON66_60 U60 (O[60], I[60]);
  UBTC1CON66_61 U61 (O[61], I[61]);
  UBTC1CON66_62 U62 (O[62], I[62]);
  UBTCTCONV_65_63 U63 (O[66:63], I[65:63]);
endmodule

module WLCTR_32_0_32_1_3000 (S1, S2, PP0, PP1, PP2, PP3, PP4, PP5, PP6, PP7, PP8, PP9, PP10, PP11, PP12, PP13, PP14, PP15, PP16, PP17, PP18, PP19, PP20, PP21, PP22, PP23, PP24, PP25, PP26, PP27, PP28, PP29, PP30, PP31);
  output [64:9] S1;
  output [63:0] S2;
  input [32:0] PP0;
  input [32:1] PP1;
  input [41:10] PP10;
  input [42:11] PP11;
  input [43:12] PP12;
  input [44:13] PP13;
  input [45:14] PP14;
  input [46:15] PP15;
  input [47:16] PP16;
  input [48:17] PP17;
  input [49:18] PP18;
  input [50:19] PP19;
  input [33:2] PP2;
  input [51:20] PP20;
  input [52:21] PP21;
  input [53:22] PP22;
  input [54:23] PP23;
  input [55:24] PP24;
  input [56:25] PP25;
  input [57:26] PP26;
  input [58:27] PP27;
  input [59:28] PP28;
  input [60:29] PP29;
  input [34:3] PP3;
  input [61:30] PP30;
  input [62:31] PP31;
  input [35:4] PP4;
  input [36:5] PP5;
  input [37:6] PP6;
  input [38:7] PP7;
  input [39:8] PP8;
  input [40:9] PP9;
  wire [33:2] IC0;
  wire [36:5] IC1;
  wire [55:24] IC10;
  wire [58:27] IC11;
  wire [61:30] IC12;
  wire [37:4] IC13;
  wire [44:10] IC14;
  wire [47:16] IC15;
  wire [53:20] IC16;
  wire [56:25] IC17;
  wire [62:29] IC18;
  wire [40:5] IC19;
  wire [39:8] IC2;
  wire [48:14] IC20;
  wire [54:21] IC21;
  wire [62:28] IC22;
  wire [44:6] IC23;
  wire [55:19] IC24;
  wire [63:29] IC25;
  wire [50:7] IC26;
  wire [63:26] IC27;
  wire [59:8] IC28;
  wire [42:11] IC3;
  wire [34:3] IC4;
  wire [40:7] IC5;
  wire [43:12] IC6;
  wire [46:15] IC7;
  wire [49:18] IC8;
  wire [52:21] IC9;
  wire [33:0] IS0;
  wire [36:3] IS1;
  wire [55:22] IS10;
  wire [58:25] IS11;
  wire [61:28] IS12;
  wire [39:0] IS13;
  wire [43:7] IS14;
  wire [49:13] IS15;
  wire [52:18] IS16;
  wire [58:22] IS17;
  wire [61:27] IS18;
  wire [43:0] IS19;
  wire [39:6] IS2;
  wire [49:10] IS20;
  wire [58:18] IS21;
  wire [62:25] IS22;
  wire [49:0] IS23;
  wire [58:14] IS24;
  wire [62:25] IS25;
  wire [58:0] IS26;
  wire [63:19] IS27;
  wire [63:0] IS28;
  wire [42:9] IS3;
  wire [36:0] IS4;
  wire [39:5] IS5;
  wire [43:9] IS6;
  wire [46:13] IS7;
  wire [49:16] IS8;
  wire [52:19] IS9;
  CSA_32_0_32_1_33_000 U0 (IC0, IS0, PP0, PP1, PP2);
  CSA_34_3_35_4_36_000 U1 (IC1, IS1, PP3, PP4, PP5);
  CSA_37_6_38_7_39_000 U2 (IC2, IS2, PP6, PP7, PP8);
  CSA_40_9_41_10_42000 U3 (IC3, IS3, PP9, PP10, PP11);
  CSA_33_0_33_2_36_000 U4 (IC4, IS4, IS0, IC0, IS1);
  CSA_36_5_39_6_39_000 U5 (IC5, IS5, IC1, IS2, IC2);
  CSA_42_9_42_11_43000 U6 (IC6, IS6, IS3, IC3, PP12);
  CSA_44_13_45_14_4000 U7 (IC7, IS7, PP13, PP14, PP15);
  CSA_47_16_48_17_4000 U8 (IC8, IS8, PP16, PP17, PP18);
  CSA_50_19_51_20_5000 U9 (IC9, IS9, PP19, PP20, PP21);
  CSA_53_22_54_23_5000 U10 (IC10, IS10, PP22, PP23, PP24);
  CSA_56_25_57_26_5000 U11 (IC11, IS11, PP25, PP26, PP27);
  CSA_59_28_60_29_6000 U12 (IC12, IS12, PP28, PP29, PP30);
  CSA_36_0_34_3_39_000 U13 (IC13, IS13, IS4, IC4, IS5);
  CSA_40_7_43_9_43_000 U14 (IC14, IS14, IC5, IS6, IC6);
  CSA_46_13_46_15_4000 U15 (IC15, IS15, IS7, IC7, IS8);
  CSA_49_18_52_19_5000 U16 (IC16, IS16, IC8, IS9, IC9);
  CSA_55_22_55_24_5000 U17 (IC17, IS17, IS10, IC10, IS11);
  CSA_58_27_61_28_6000 U18 (IC18, IS18, IC11, IS12, IC12);
  CSA_39_0_37_4_43_000 U19 (IC19, IS19, IS13, IC13, IS14);
  CSA_44_10_49_13_4000 U20 (IC20, IS20, IC14, IS15, IC15);
  CSA_52_18_53_20_5000 U21 (IC21, IS21, IS16, IC16, IS17);
  CSA_56_25_61_27_6000 U22 (IC22, IS22, IC17, IS18, IC18);
  CSA_43_0_40_5_49_000 U23 (IC23, IS23, IS19, IC19, IS20);
  CSA_48_14_58_18_5000 U24 (IC24, IS24, IC20, IS21, IC21);
  CSA_62_25_62_28_6000 U25 (IC25, IS25, IS22, IC22, PP31);
  CSA_49_0_44_6_58_000 U26 (IC26, IS26, IS23, IC23, IS24);
  CSA_55_19_62_25_6000 U27 (IC27, IS27, IC24, IS25, IC25);
  CSA_58_0_50_7_63_000 U28 (IC28, IS28, IS26, IC26, IS27);
  CSA_63_0_59_8_63_000 U29 (S1, S2, IS28, IC28, IC27);
endmodule

module cos_lut(a, out);
	input  [31:0] a;
	output reg [31:0] out;
	wire   [10:0] index;

	always @(index)
	begin
		case(index)
			11'd0: out = 32'b00000000000000000111111111111111; // input=0.001953125, output=0.999998092652
			11'd1: out = 32'b00000000000000000111111111111111; // input=0.005859375, output=0.999982833911
			11'd2: out = 32'b00000000000000000111111111111110; // input=0.009765625, output=0.999952316663
			11'd3: out = 32'b00000000000000000111111111111101; // input=0.013671875, output=0.999906541373
			11'd4: out = 32'b00000000000000000111111111111011; // input=0.017578125, output=0.999845508739
			11'd5: out = 32'b00000000000000000111111111111000; // input=0.021484375, output=0.999769219693
			11'd6: out = 32'b00000000000000000111111111110101; // input=0.025390625, output=0.999677675398
			11'd7: out = 32'b00000000000000000111111111110010; // input=0.029296875, output=0.999570877252
			11'd8: out = 32'b00000000000000000111111111101110; // input=0.033203125, output=0.999448826885
			11'd9: out = 32'b00000000000000000111111111101001; // input=0.037109375, output=0.999311526157
			11'd10: out = 32'b00000000000000000111111111100100; // input=0.041015625, output=0.999158977166
			11'd11: out = 32'b00000000000000000111111111011111; // input=0.044921875, output=0.998991182238
			11'd12: out = 32'b00000000000000000111111111011001; // input=0.048828125, output=0.998808143933
			11'd13: out = 32'b00000000000000000111111111010010; // input=0.052734375, output=0.998609865045
			11'd14: out = 32'b00000000000000000111111111001011; // input=0.056640625, output=0.998396348599
			11'd15: out = 32'b00000000000000000111111111000100; // input=0.060546875, output=0.998167597854
			11'd16: out = 32'b00000000000000000111111110111100; // input=0.064453125, output=0.997923616299
			11'd17: out = 32'b00000000000000000111111110110011; // input=0.068359375, output=0.997664407657
			11'd18: out = 32'b00000000000000000111111110101010; // input=0.072265625, output=0.997389975884
			11'd19: out = 32'b00000000000000000111111110100001; // input=0.076171875, output=0.997100325166
			11'd20: out = 32'b00000000000000000111111110010111; // input=0.080078125, output=0.996795459925
			11'd21: out = 32'b00000000000000000111111110001101; // input=0.083984375, output=0.996475384812
			11'd22: out = 32'b00000000000000000111111110000010; // input=0.087890625, output=0.99614010471
			11'd23: out = 32'b00000000000000000111111101110110; // input=0.091796875, output=0.995789624735
			11'd24: out = 32'b00000000000000000111111101101010; // input=0.095703125, output=0.995423950236
			11'd25: out = 32'b00000000000000000111111101011110; // input=0.099609375, output=0.995043086793
			11'd26: out = 32'b00000000000000000111111101010001; // input=0.103515625, output=0.994647040216
			11'd27: out = 32'b00000000000000000111111101000011; // input=0.107421875, output=0.994235816549
			11'd28: out = 32'b00000000000000000111111100110101; // input=0.111328125, output=0.993809422066
			11'd29: out = 32'b00000000000000000111111100100111; // input=0.115234375, output=0.993367863275
			11'd30: out = 32'b00000000000000000111111100011000; // input=0.119140625, output=0.992911146912
			11'd31: out = 32'b00000000000000000111111100001000; // input=0.123046875, output=0.992439279947
			11'd32: out = 32'b00000000000000000111111011111000; // input=0.126953125, output=0.991952269579
			11'd33: out = 32'b00000000000000000111111011101000; // input=0.130859375, output=0.99145012324
			11'd34: out = 32'b00000000000000000111111011010111; // input=0.134765625, output=0.990932848592
			11'd35: out = 32'b00000000000000000111111011000101; // input=0.138671875, output=0.990400453528
			11'd36: out = 32'b00000000000000000111111010110100; // input=0.142578125, output=0.989852946172
			11'd37: out = 32'b00000000000000000111111010100001; // input=0.146484375, output=0.989290334878
			11'd38: out = 32'b00000000000000000111111010001110; // input=0.150390625, output=0.98871262823
			11'd39: out = 32'b00000000000000000111111001111011; // input=0.154296875, output=0.988119835044
			11'd40: out = 32'b00000000000000000111111001100111; // input=0.158203125, output=0.987511964365
			11'd41: out = 32'b00000000000000000111111001010010; // input=0.162109375, output=0.986889025468
			11'd42: out = 32'b00000000000000000111111000111101; // input=0.166015625, output=0.986251027859
			11'd43: out = 32'b00000000000000000111111000101000; // input=0.169921875, output=0.985597981273
			11'd44: out = 32'b00000000000000000111111000010010; // input=0.173828125, output=0.984929895674
			11'd45: out = 32'b00000000000000000111110111111100; // input=0.177734375, output=0.984246781257
			11'd46: out = 32'b00000000000000000111110111100101; // input=0.181640625, output=0.983548648445
			11'd47: out = 32'b00000000000000000111110111001110; // input=0.185546875, output=0.98283550789
			11'd48: out = 32'b00000000000000000111110110110110; // input=0.189453125, output=0.982107370475
			11'd49: out = 32'b00000000000000000111110110011101; // input=0.193359375, output=0.98136424731
			11'd50: out = 32'b00000000000000000111110110000101; // input=0.197265625, output=0.980606149734
			11'd51: out = 32'b00000000000000000111110101101011; // input=0.201171875, output=0.979833089314
			11'd52: out = 32'b00000000000000000111110101010001; // input=0.205078125, output=0.979045077847
			11'd53: out = 32'b00000000000000000111110100110111; // input=0.208984375, output=0.978242127357
			11'd54: out = 32'b00000000000000000111110100011100; // input=0.212890625, output=0.977424250095
			11'd55: out = 32'b00000000000000000111110100000001; // input=0.216796875, output=0.976591458542
			11'd56: out = 32'b00000000000000000111110011100101; // input=0.220703125, output=0.975743765405
			11'd57: out = 32'b00000000000000000111110011001001; // input=0.224609375, output=0.974881183619
			11'd58: out = 32'b00000000000000000111110010101100; // input=0.228515625, output=0.974003726345
			11'd59: out = 32'b00000000000000000111110010001111; // input=0.232421875, output=0.973111406972
			11'd60: out = 32'b00000000000000000111110001110001; // input=0.236328125, output=0.972204239117
			11'd61: out = 32'b00000000000000000111110001010011; // input=0.240234375, output=0.971282236621
			11'd62: out = 32'b00000000000000000111110000110100; // input=0.244140625, output=0.970345413553
			11'd63: out = 32'b00000000000000000111110000010101; // input=0.248046875, output=0.969393784208
			11'd64: out = 32'b00000000000000000111101111110101; // input=0.251953125, output=0.968427363107
			11'd65: out = 32'b00000000000000000111101111010101; // input=0.255859375, output=0.967446164995
			11'd66: out = 32'b00000000000000000111101110110101; // input=0.259765625, output=0.966450204846
			11'd67: out = 32'b00000000000000000111101110010100; // input=0.263671875, output=0.965439497855
			11'd68: out = 32'b00000000000000000111101101110010; // input=0.267578125, output=0.964414059445
			11'd69: out = 32'b00000000000000000111101101010000; // input=0.271484375, output=0.963373905264
			11'd70: out = 32'b00000000000000000111101100101101; // input=0.275390625, output=0.962319051181
			11'd71: out = 32'b00000000000000000111101100001010; // input=0.279296875, output=0.961249513295
			11'd72: out = 32'b00000000000000000111101011100111; // input=0.283203125, output=0.960165307923
			11'd73: out = 32'b00000000000000000111101011000011; // input=0.287109375, output=0.95906645161
			11'd74: out = 32'b00000000000000000111101010011110; // input=0.291015625, output=0.957952961123
			11'd75: out = 32'b00000000000000000111101001111001; // input=0.294921875, output=0.956824853452
			11'd76: out = 32'b00000000000000000111101001010100; // input=0.298828125, output=0.955682145811
			11'd77: out = 32'b00000000000000000111101000101110; // input=0.302734375, output=0.954524855637
			11'd78: out = 32'b00000000000000000111101000000111; // input=0.306640625, output=0.953353000587
			11'd79: out = 32'b00000000000000000111100111100001; // input=0.310546875, output=0.952166598544
			11'd80: out = 32'b00000000000000000111100110111001; // input=0.314453125, output=0.95096566761
			11'd81: out = 32'b00000000000000000111100110010001; // input=0.318359375, output=0.94975022611
			11'd82: out = 32'b00000000000000000111100101101001; // input=0.322265625, output=0.94852029259
			11'd83: out = 32'b00000000000000000111100101000000; // input=0.326171875, output=0.947275885817
			11'd84: out = 32'b00000000000000000111100100010111; // input=0.330078125, output=0.94601702478
			11'd85: out = 32'b00000000000000000111100011101101; // input=0.333984375, output=0.944743728687
			11'd86: out = 32'b00000000000000000111100011000011; // input=0.337890625, output=0.943456016966
			11'd87: out = 32'b00000000000000000111100010011000; // input=0.341796875, output=0.942153909268
			11'd88: out = 32'b00000000000000000111100001101101; // input=0.345703125, output=0.940837425461
			11'd89: out = 32'b00000000000000000111100001000010; // input=0.349609375, output=0.939506585632
			11'd90: out = 32'b00000000000000000111100000010110; // input=0.353515625, output=0.938161410088
			11'd91: out = 32'b00000000000000000111011111101001; // input=0.357421875, output=0.936801919355
			11'd92: out = 32'b00000000000000000111011110111100; // input=0.361328125, output=0.935428134178
			11'd93: out = 32'b00000000000000000111011110001111; // input=0.365234375, output=0.934040075518
			11'd94: out = 32'b00000000000000000111011101100001; // input=0.369140625, output=0.932637764556
			11'd95: out = 32'b00000000000000000111011100110010; // input=0.373046875, output=0.931221222689
			11'd96: out = 32'b00000000000000000111011100000011; // input=0.376953125, output=0.929790471532
			11'd97: out = 32'b00000000000000000111011011010100; // input=0.380859375, output=0.928345532916
			11'd98: out = 32'b00000000000000000111011010100100; // input=0.384765625, output=0.92688642889
			11'd99: out = 32'b00000000000000000111011001110100; // input=0.388671875, output=0.925413181717
			11'd100: out = 32'b00000000000000000111011001000011; // input=0.392578125, output=0.923925813877
			11'd101: out = 32'b00000000000000000111011000010010; // input=0.396484375, output=0.922424348067
			11'd102: out = 32'b00000000000000000111010111100000; // input=0.400390625, output=0.920908807195
			11'd103: out = 32'b00000000000000000111010110101110; // input=0.404296875, output=0.919379214389
			11'd104: out = 32'b00000000000000000111010101111100; // input=0.408203125, output=0.917835592986
			11'd105: out = 32'b00000000000000000111010101001001; // input=0.412109375, output=0.916277966542
			11'd106: out = 32'b00000000000000000111010100010101; // input=0.416015625, output=0.914706358823
			11'd107: out = 32'b00000000000000000111010011100001; // input=0.419921875, output=0.913120793811
			11'd108: out = 32'b00000000000000000111010010101101; // input=0.423828125, output=0.911521295699
			11'd109: out = 32'b00000000000000000111010001111000; // input=0.427734375, output=0.909907888893
			11'd110: out = 32'b00000000000000000111010001000011; // input=0.431640625, output=0.908280598013
			11'd111: out = 32'b00000000000000000111010000001101; // input=0.435546875, output=0.906639447888
			11'd112: out = 32'b00000000000000000111001111010111; // input=0.439453125, output=0.90498446356
			11'd113: out = 32'b00000000000000000111001110100000; // input=0.443359375, output=0.903315670283
			11'd114: out = 32'b00000000000000000111001101101001; // input=0.447265625, output=0.901633093521
			11'd115: out = 32'b00000000000000000111001100110001; // input=0.451171875, output=0.899936758946
			11'd116: out = 32'b00000000000000000111001011111001; // input=0.455078125, output=0.898226692444
			11'd117: out = 32'b00000000000000000111001011000001; // input=0.458984375, output=0.896502920108
			11'd118: out = 32'b00000000000000000111001010001000; // input=0.462890625, output=0.89476546824
			11'd119: out = 32'b00000000000000000111001001001110; // input=0.466796875, output=0.893014363352
			11'd120: out = 32'b00000000000000000111001000010100; // input=0.470703125, output=0.891249632163
			11'd121: out = 32'b00000000000000000111000111011010; // input=0.474609375, output=0.889471301602
			11'd122: out = 32'b00000000000000000111000110011111; // input=0.478515625, output=0.887679398803
			11'd123: out = 32'b00000000000000000111000101100100; // input=0.482421875, output=0.885873951108
			11'd124: out = 32'b00000000000000000111000100101001; // input=0.486328125, output=0.884054986067
			11'd125: out = 32'b00000000000000000111000011101101; // input=0.490234375, output=0.882222531435
			11'd126: out = 32'b00000000000000000111000010110000; // input=0.494140625, output=0.880376615172
			11'd127: out = 32'b00000000000000000111000001110011; // input=0.498046875, output=0.878517265445
			11'd128: out = 32'b00000000000000000111000000110110; // input=0.501953125, output=0.876644510625
			11'd129: out = 32'b00000000000000000110111111111000; // input=0.505859375, output=0.874758379289
			11'd130: out = 32'b00000000000000000110111110111010; // input=0.509765625, output=0.872858900216
			11'd131: out = 32'b00000000000000000110111101111011; // input=0.513671875, output=0.870946102391
			11'd132: out = 32'b00000000000000000110111100111100; // input=0.517578125, output=0.869020014999
			11'd133: out = 32'b00000000000000000110111011111100; // input=0.521484375, output=0.867080667431
			11'd134: out = 32'b00000000000000000110111010111101; // input=0.525390625, output=0.865128089279
			11'd135: out = 32'b00000000000000000110111001111100; // input=0.529296875, output=0.863162310337
			11'd136: out = 32'b00000000000000000110111000111011; // input=0.533203125, output=0.861183360599
			11'd137: out = 32'b00000000000000000110110111111010; // input=0.537109375, output=0.859191270264
			11'd138: out = 32'b00000000000000000110110110111000; // input=0.541015625, output=0.857186069726
			11'd139: out = 32'b00000000000000000110110101110110; // input=0.544921875, output=0.855167789584
			11'd140: out = 32'b00000000000000000110110100110100; // input=0.548828125, output=0.853136460634
			11'd141: out = 32'b00000000000000000110110011110001; // input=0.552734375, output=0.85109211387
			11'd142: out = 32'b00000000000000000110110010101101; // input=0.556640625, output=0.849034780489
			11'd143: out = 32'b00000000000000000110110001101001; // input=0.560546875, output=0.846964491881
			11'd144: out = 32'b00000000000000000110110000100101; // input=0.564453125, output=0.844881279637
			11'd145: out = 32'b00000000000000000110101111100000; // input=0.568359375, output=0.842785175544
			11'd146: out = 32'b00000000000000000110101110011011; // input=0.572265625, output=0.840676211586
			11'd147: out = 32'b00000000000000000110101101010110; // input=0.576171875, output=0.838554419944
			11'd148: out = 32'b00000000000000000110101100010000; // input=0.580078125, output=0.836419832992
			11'd149: out = 32'b00000000000000000110101011001001; // input=0.583984375, output=0.834272483304
			11'd150: out = 32'b00000000000000000110101010000011; // input=0.587890625, output=0.832112403643
			11'd151: out = 32'b00000000000000000110101000111011; // input=0.591796875, output=0.829939626972
			11'd152: out = 32'b00000000000000000110100111110100; // input=0.595703125, output=0.827754186442
			11'd153: out = 32'b00000000000000000110100110101100; // input=0.599609375, output=0.825556115402
			11'd154: out = 32'b00000000000000000110100101100011; // input=0.603515625, output=0.823345447392
			11'd155: out = 32'b00000000000000000110100100011011; // input=0.607421875, output=0.821122216143
			11'd156: out = 32'b00000000000000000110100011010001; // input=0.611328125, output=0.818886455579
			11'd157: out = 32'b00000000000000000110100010001000; // input=0.615234375, output=0.816638199815
			11'd158: out = 32'b00000000000000000110100000111110; // input=0.619140625, output=0.814377483157
			11'd159: out = 32'b00000000000000000110011111110011; // input=0.623046875, output=0.812104340101
			11'd160: out = 32'b00000000000000000110011110101000; // input=0.626953125, output=0.809818805332
			11'd161: out = 32'b00000000000000000110011101011101; // input=0.630859375, output=0.807520913724
			11'd162: out = 32'b00000000000000000110011100010001; // input=0.634765625, output=0.80521070034
			11'd163: out = 32'b00000000000000000110011011000101; // input=0.638671875, output=0.802888200432
			11'd164: out = 32'b00000000000000000110011001111001; // input=0.642578125, output=0.800553449438
			11'd165: out = 32'b00000000000000000110011000101100; // input=0.646484375, output=0.798206482983
			11'd166: out = 32'b00000000000000000110010111011110; // input=0.650390625, output=0.795847336879
			11'd167: out = 32'b00000000000000000110010110010001; // input=0.654296875, output=0.793476047124
			11'd168: out = 32'b00000000000000000110010101000011; // input=0.658203125, output=0.791092649901
			11'd169: out = 32'b00000000000000000110010011110100; // input=0.662109375, output=0.788697181577
			11'd170: out = 32'b00000000000000000110010010100101; // input=0.666015625, output=0.786289678704
			11'd171: out = 32'b00000000000000000110010001010110; // input=0.669921875, output=0.783870178019
			11'd172: out = 32'b00000000000000000110010000000110; // input=0.673828125, output=0.781438716439
			11'd173: out = 32'b00000000000000000110001110110110; // input=0.677734375, output=0.778995331066
			11'd174: out = 32'b00000000000000000110001101100110; // input=0.681640625, output=0.776540059182
			11'd175: out = 32'b00000000000000000110001100010101; // input=0.685546875, output=0.774072938252
			11'd176: out = 32'b00000000000000000110001011000100; // input=0.689453125, output=0.771594005922
			11'd177: out = 32'b00000000000000000110001001110010; // input=0.693359375, output=0.769103300017
			11'd178: out = 32'b00000000000000000110001000100000; // input=0.697265625, output=0.766600858541
			11'd179: out = 32'b00000000000000000110000111001110; // input=0.701171875, output=0.76408671968
			11'd180: out = 32'b00000000000000000110000101111011; // input=0.705078125, output=0.761560921795
			11'd181: out = 32'b00000000000000000110000100101000; // input=0.708984375, output=0.759023503428
			11'd182: out = 32'b00000000000000000110000011010100; // input=0.712890625, output=0.756474503295
			11'd183: out = 32'b00000000000000000110000010000000; // input=0.716796875, output=0.753913960293
			11'd184: out = 32'b00000000000000000110000000101100; // input=0.720703125, output=0.751341913491
			11'd185: out = 32'b00000000000000000101111111010111; // input=0.724609375, output=0.748758402136
			11'd186: out = 32'b00000000000000000101111110000010; // input=0.728515625, output=0.746163465649
			11'd187: out = 32'b00000000000000000101111100101101; // input=0.732421875, output=0.743557143625
			11'd188: out = 32'b00000000000000000101111011010111; // input=0.736328125, output=0.740939475835
			11'd189: out = 32'b00000000000000000101111010000001; // input=0.740234375, output=0.738310502219
			11'd190: out = 32'b00000000000000000101111000101010; // input=0.744140625, output=0.735670262894
			11'd191: out = 32'b00000000000000000101110111010100; // input=0.748046875, output=0.733018798145
			11'd192: out = 32'b00000000000000000101110101111100; // input=0.751953125, output=0.730356148432
			11'd193: out = 32'b00000000000000000101110100100101; // input=0.755859375, output=0.727682354382
			11'd194: out = 32'b00000000000000000101110011001101; // input=0.759765625, output=0.724997456795
			11'd195: out = 32'b00000000000000000101110001110100; // input=0.763671875, output=0.722301496639
			11'd196: out = 32'b00000000000000000101110000011100; // input=0.767578125, output=0.71959451505
			11'd197: out = 32'b00000000000000000101101111000011; // input=0.771484375, output=0.716876553335
			11'd198: out = 32'b00000000000000000101101101101001; // input=0.775390625, output=0.714147652965
			11'd199: out = 32'b00000000000000000101101100001111; // input=0.779296875, output=0.711407855581
			11'd200: out = 32'b00000000000000000101101010110101; // input=0.783203125, output=0.708657202988
			11'd201: out = 32'b00000000000000000101101001011011; // input=0.787109375, output=0.705895737158
			11'd202: out = 32'b00000000000000000101101000000000; // input=0.791015625, output=0.703123500228
			11'd203: out = 32'b00000000000000000101100110100101; // input=0.794921875, output=0.700340534498
			11'd204: out = 32'b00000000000000000101100101001001; // input=0.798828125, output=0.697546882433
			11'd205: out = 32'b00000000000000000101100011101101; // input=0.802734375, output=0.694742586661
			11'd206: out = 32'b00000000000000000101100010010001; // input=0.806640625, output=0.691927689972
			11'd207: out = 32'b00000000000000000101100000110101; // input=0.810546875, output=0.689102235318
			11'd208: out = 32'b00000000000000000101011111011000; // input=0.814453125, output=0.686266265812
			11'd209: out = 32'b00000000000000000101011101111010; // input=0.818359375, output=0.683419824726
			11'd210: out = 32'b00000000000000000101011100011101; // input=0.822265625, output=0.680562955495
			11'd211: out = 32'b00000000000000000101011010111111; // input=0.826171875, output=0.677695701711
			11'd212: out = 32'b00000000000000000101011001100000; // input=0.830078125, output=0.674818107123
			11'd213: out = 32'b00000000000000000101011000000010; // input=0.833984375, output=0.671930215642
			11'd214: out = 32'b00000000000000000101010110100011; // input=0.837890625, output=0.669032071333
			11'd215: out = 32'b00000000000000000101010101000100; // input=0.841796875, output=0.666123718417
			11'd216: out = 32'b00000000000000000101010011100100; // input=0.845703125, output=0.663205201273
			11'd217: out = 32'b00000000000000000101010010000100; // input=0.849609375, output=0.660276564433
			11'd218: out = 32'b00000000000000000101010000100100; // input=0.853515625, output=0.657337852585
			11'd219: out = 32'b00000000000000000101001111000011; // input=0.857421875, output=0.654389110571
			11'd220: out = 32'b00000000000000000101001101100010; // input=0.861328125, output=0.651430383384
			11'd221: out = 32'b00000000000000000101001100000001; // input=0.865234375, output=0.64846171617
			11'd222: out = 32'b00000000000000000101001010011111; // input=0.869140625, output=0.645483154229
			11'd223: out = 32'b00000000000000000101001000111101; // input=0.873046875, output=0.642494743009
			11'd224: out = 32'b00000000000000000101000111011011; // input=0.876953125, output=0.63949652811
			11'd225: out = 32'b00000000000000000101000101111000; // input=0.880859375, output=0.63648855528
			11'd226: out = 32'b00000000000000000101000100010110; // input=0.884765625, output=0.633470870418
			11'd227: out = 32'b00000000000000000101000010110010; // input=0.888671875, output=0.63044351957
			11'd228: out = 32'b00000000000000000101000001001111; // input=0.892578125, output=0.62740654893
			11'd229: out = 32'b00000000000000000100111111101011; // input=0.896484375, output=0.624360004837
			11'd230: out = 32'b00000000000000000100111110000111; // input=0.900390625, output=0.621303933779
			11'd231: out = 32'b00000000000000000100111100100010; // input=0.904296875, output=0.618238382388
			11'd232: out = 32'b00000000000000000100111010111110; // input=0.908203125, output=0.615163397439
			11'd233: out = 32'b00000000000000000100111001011001; // input=0.912109375, output=0.612079025854
			11'd234: out = 32'b00000000000000000100110111110011; // input=0.916015625, output=0.608985314696
			11'd235: out = 32'b00000000000000000100110110001110; // input=0.919921875, output=0.605882311171
			11'd236: out = 32'b00000000000000000100110100101000; // input=0.923828125, output=0.602770062628
			11'd237: out = 32'b00000000000000000100110011000001; // input=0.927734375, output=0.599648616555
			11'd238: out = 32'b00000000000000000100110001011011; // input=0.931640625, output=0.596518020582
			11'd239: out = 32'b00000000000000000100101111110100; // input=0.935546875, output=0.593378322478
			11'd240: out = 32'b00000000000000000100101110001101; // input=0.939453125, output=0.590229570151
			11'd241: out = 32'b00000000000000000100101100100101; // input=0.943359375, output=0.587071811646
			11'd242: out = 32'b00000000000000000100101010111101; // input=0.947265625, output=0.583905095149
			11'd243: out = 32'b00000000000000000100101001010101; // input=0.951171875, output=0.580729468977
			11'd244: out = 32'b00000000000000000100100111101101; // input=0.955078125, output=0.577544981589
			11'd245: out = 32'b00000000000000000100100110000100; // input=0.958984375, output=0.574351681575
			11'd246: out = 32'b00000000000000000100100100011011; // input=0.962890625, output=0.571149617661
			11'd247: out = 32'b00000000000000000100100010110010; // input=0.966796875, output=0.567938838706
			11'd248: out = 32'b00000000000000000100100001001001; // input=0.970703125, output=0.564719393703
			11'd249: out = 32'b00000000000000000100011111011111; // input=0.974609375, output=0.561491331777
			11'd250: out = 32'b00000000000000000100011101110101; // input=0.978515625, output=0.558254702185
			11'd251: out = 32'b00000000000000000100011100001011; // input=0.982421875, output=0.555009554312
			11'd252: out = 32'b00000000000000000100011010100000; // input=0.986328125, output=0.551755937677
			11'd253: out = 32'b00000000000000000100011000110101; // input=0.990234375, output=0.548493901924
			11'd254: out = 32'b00000000000000000100010111001010; // input=0.994140625, output=0.54522349683
			11'd255: out = 32'b00000000000000000100010101011110; // input=0.998046875, output=0.541944772296
			11'd256: out = 32'b00000000000000000100010011110011; // input=1.001953125, output=0.538657778351
			11'd257: out = 32'b00000000000000000100010010000111; // input=1.005859375, output=0.535362565152
			11'd258: out = 32'b00000000000000000100010000011011; // input=1.009765625, output=0.532059182978
			11'd259: out = 32'b00000000000000000100001110101110; // input=1.013671875, output=0.528747682236
			11'd260: out = 32'b00000000000000000100001101000001; // input=1.017578125, output=0.525428113455
			11'd261: out = 32'b00000000000000000100001011010100; // input=1.021484375, output=0.522100527287
			11'd262: out = 32'b00000000000000000100001001100111; // input=1.025390625, output=0.518764974507
			11'd263: out = 32'b00000000000000000100000111111001; // input=1.029296875, output=0.515421506013
			11'd264: out = 32'b00000000000000000100000110001100; // input=1.033203125, output=0.51207017282
			11'd265: out = 32'b00000000000000000100000100011101; // input=1.037109375, output=0.508711026066
			11'd266: out = 32'b00000000000000000100000010101111; // input=1.041015625, output=0.505344117008
			11'd267: out = 32'b00000000000000000100000001000001; // input=1.044921875, output=0.501969497021
			11'd268: out = 32'b00000000000000000011111111010010; // input=1.048828125, output=0.498587217597
			11'd269: out = 32'b00000000000000000011111101100011; // input=1.052734375, output=0.495197330345
			11'd270: out = 32'b00000000000000000011111011110011; // input=1.056640625, output=0.491799886991
			11'd271: out = 32'b00000000000000000011111010000100; // input=1.060546875, output=0.488394939376
			11'd272: out = 32'b00000000000000000011111000010100; // input=1.064453125, output=0.484982539455
			11'd273: out = 32'b00000000000000000011110110100100; // input=1.068359375, output=0.481562739297
			11'd274: out = 32'b00000000000000000011110100110100; // input=1.072265625, output=0.478135591084
			11'd275: out = 32'b00000000000000000011110011000011; // input=1.076171875, output=0.474701147111
			11'd276: out = 32'b00000000000000000011110001010010; // input=1.080078125, output=0.471259459782
			11'd277: out = 32'b00000000000000000011101111100001; // input=1.083984375, output=0.467810581613
			11'd278: out = 32'b00000000000000000011101101110000; // input=1.087890625, output=0.464354565231
			11'd279: out = 32'b00000000000000000011101011111110; // input=1.091796875, output=0.460891463369
			11'd280: out = 32'b00000000000000000011101010001101; // input=1.095703125, output=0.45742132887
			11'd281: out = 32'b00000000000000000011101000011011; // input=1.099609375, output=0.453944214685
			11'd282: out = 32'b00000000000000000011100110101001; // input=1.103515625, output=0.45046017387
			11'd283: out = 32'b00000000000000000011100100110110; // input=1.107421875, output=0.446969259586
			11'd284: out = 32'b00000000000000000011100011000100; // input=1.111328125, output=0.443471525102
			11'd285: out = 32'b00000000000000000011100001010001; // input=1.115234375, output=0.439967023787
			11'd286: out = 32'b00000000000000000011011111011110; // input=1.119140625, output=0.436455809118
			11'd287: out = 32'b00000000000000000011011101101011; // input=1.123046875, output=0.432937934669
			11'd288: out = 32'b00000000000000000011011011110111; // input=1.126953125, output=0.429413454121
			11'd289: out = 32'b00000000000000000011011010000011; // input=1.130859375, output=0.425882421251
			11'd290: out = 32'b00000000000000000011011000001111; // input=1.134765625, output=0.42234488994
			11'd291: out = 32'b00000000000000000011010110011011; // input=1.138671875, output=0.418800914165
			11'd292: out = 32'b00000000000000000011010100100111; // input=1.142578125, output=0.415250548003
			11'd293: out = 32'b00000000000000000011010010110010; // input=1.146484375, output=0.411693845629
			11'd294: out = 32'b00000000000000000011010000111110; // input=1.150390625, output=0.408130861314
			11'd295: out = 32'b00000000000000000011001111001001; // input=1.154296875, output=0.404561649424
			11'd296: out = 32'b00000000000000000011001101010100; // input=1.158203125, output=0.40098626442
			11'd297: out = 32'b00000000000000000011001011011110; // input=1.162109375, output=0.39740476086
			11'd298: out = 32'b00000000000000000011001001101001; // input=1.166015625, output=0.393817193392
			11'd299: out = 32'b00000000000000000011000111110011; // input=1.169921875, output=0.390223616758
			11'd300: out = 32'b00000000000000000011000101111101; // input=1.173828125, output=0.386624085792
			11'd301: out = 32'b00000000000000000011000100000111; // input=1.177734375, output=0.383018655418
			11'd302: out = 32'b00000000000000000011000010010000; // input=1.181640625, output=0.37940738065
			11'd303: out = 32'b00000000000000000011000000011010; // input=1.185546875, output=0.375790316593
			11'd304: out = 32'b00000000000000000010111110100011; // input=1.189453125, output=0.372167518438
			11'd305: out = 32'b00000000000000000010111100101100; // input=1.193359375, output=0.368539041464
			11'd306: out = 32'b00000000000000000010111010110101; // input=1.197265625, output=0.364904941038
			11'd307: out = 32'b00000000000000000010111000111110; // input=1.201171875, output=0.361265272612
			11'd308: out = 32'b00000000000000000010110111000110; // input=1.205078125, output=0.357620091721
			11'd309: out = 32'b00000000000000000010110101001111; // input=1.208984375, output=0.353969453989
			11'd310: out = 32'b00000000000000000010110011010111; // input=1.212890625, output=0.350313415118
			11'd311: out = 32'b00000000000000000010110001011111; // input=1.216796875, output=0.346652030895
			11'd312: out = 32'b00000000000000000010101111100111; // input=1.220703125, output=0.342985357189
			11'd313: out = 32'b00000000000000000010101101101111; // input=1.224609375, output=0.339313449948
			11'd314: out = 32'b00000000000000000010101011110110; // input=1.228515625, output=0.335636365202
			11'd315: out = 32'b00000000000000000010101001111101; // input=1.232421875, output=0.331954159057
			11'd316: out = 32'b00000000000000000010101000000101; // input=1.236328125, output=0.328266887701
			11'd317: out = 32'b00000000000000000010100110001100; // input=1.240234375, output=0.324574607395
			11'd318: out = 32'b00000000000000000010100100010011; // input=1.244140625, output=0.320877374481
			11'd319: out = 32'b00000000000000000010100010011001; // input=1.248046875, output=0.317175245372
			11'd320: out = 32'b00000000000000000010100000100000; // input=1.251953125, output=0.31346827656
			11'd321: out = 32'b00000000000000000010011110100110; // input=1.255859375, output=0.309756524607
			11'd322: out = 32'b00000000000000000010011100101100; // input=1.259765625, output=0.306040046151
			11'd323: out = 32'b00000000000000000010011010110010; // input=1.263671875, output=0.3023188979
			11'd324: out = 32'b00000000000000000010011000111000; // input=1.267578125, output=0.298593136635
			11'd325: out = 32'b00000000000000000010010110111110; // input=1.271484375, output=0.294862819205
			11'd326: out = 32'b00000000000000000010010101000100; // input=1.275390625, output=0.291128002532
			11'd327: out = 32'b00000000000000000010010011001001; // input=1.279296875, output=0.287388743604
			11'd328: out = 32'b00000000000000000010010001001110; // input=1.283203125, output=0.283645099478
			11'd329: out = 32'b00000000000000000010001111010100; // input=1.287109375, output=0.279897127276
			11'd330: out = 32'b00000000000000000010001101011001; // input=1.291015625, output=0.276144884188
			11'd331: out = 32'b00000000000000000010001011011110; // input=1.294921875, output=0.272388427469
			11'd332: out = 32'b00000000000000000010001001100010; // input=1.298828125, output=0.268627814438
			11'd333: out = 32'b00000000000000000010000111100111; // input=1.302734375, output=0.264863102477
			11'd334: out = 32'b00000000000000000010000101101100; // input=1.306640625, output=0.26109434903
			11'd335: out = 32'b00000000000000000010000011110000; // input=1.310546875, output=0.257321611606
			11'd336: out = 32'b00000000000000000010000001110100; // input=1.314453125, output=0.25354494777
			11'd337: out = 32'b00000000000000000001111111111000; // input=1.318359375, output=0.24976441515
			11'd338: out = 32'b00000000000000000001111101111100; // input=1.322265625, output=0.245980071432
			11'd339: out = 32'b00000000000000000001111100000000; // input=1.326171875, output=0.242191974361
			11'd340: out = 32'b00000000000000000001111010000100; // input=1.330078125, output=0.238400181739
			11'd341: out = 32'b00000000000000000001111000001000; // input=1.333984375, output=0.234604751423
			11'd342: out = 32'b00000000000000000001110110001011; // input=1.337890625, output=0.230805741327
			11'd343: out = 32'b00000000000000000001110100001110; // input=1.341796875, output=0.22700320942
			11'd344: out = 32'b00000000000000000001110010010010; // input=1.345703125, output=0.223197213723
			11'd345: out = 32'b00000000000000000001110000010101; // input=1.349609375, output=0.219387812311
			11'd346: out = 32'b00000000000000000001101110011000; // input=1.353515625, output=0.215575063311
			11'd347: out = 32'b00000000000000000001101100011011; // input=1.357421875, output=0.211759024901
			11'd348: out = 32'b00000000000000000001101010011110; // input=1.361328125, output=0.207939755308
			11'd349: out = 32'b00000000000000000001101000100001; // input=1.365234375, output=0.204117312811
			11'd350: out = 32'b00000000000000000001100110100011; // input=1.369140625, output=0.200291755735
			11'd351: out = 32'b00000000000000000001100100100110; // input=1.373046875, output=0.196463142453
			11'd352: out = 32'b00000000000000000001100010101000; // input=1.376953125, output=0.192631531385
			11'd353: out = 32'b00000000000000000001100000101010; // input=1.380859375, output=0.188796980997
			11'd354: out = 32'b00000000000000000001011110101101; // input=1.384765625, output=0.184959549799
			11'd355: out = 32'b00000000000000000001011100101111; // input=1.388671875, output=0.181119296346
			11'd356: out = 32'b00000000000000000001011010110001; // input=1.392578125, output=0.177276279236
			11'd357: out = 32'b00000000000000000001011000110011; // input=1.396484375, output=0.173430557107
			11'd358: out = 32'b00000000000000000001010110110101; // input=1.400390625, output=0.169582188642
			11'd359: out = 32'b00000000000000000001010100110111; // input=1.404296875, output=0.165731232561
			11'd360: out = 32'b00000000000000000001010010111000; // input=1.408203125, output=0.161877747625
			11'd361: out = 32'b00000000000000000001010000111010; // input=1.412109375, output=0.158021792634
			11'd362: out = 32'b00000000000000000001001110111100; // input=1.416015625, output=0.154163426425
			11'd363: out = 32'b00000000000000000001001100111101; // input=1.419921875, output=0.150302707872
			11'd364: out = 32'b00000000000000000001001010111111; // input=1.423828125, output=0.146439695884
			11'd365: out = 32'b00000000000000000001001001000000; // input=1.427734375, output=0.142574449407
			11'd366: out = 32'b00000000000000000001000111000001; // input=1.431640625, output=0.138707027419
			11'd367: out = 32'b00000000000000000001000101000010; // input=1.435546875, output=0.134837488933
			11'd368: out = 32'b00000000000000000001000011000011; // input=1.439453125, output=0.130965892992
			11'd369: out = 32'b00000000000000000001000001000101; // input=1.443359375, output=0.127092298673
			11'd370: out = 32'b00000000000000000000111111000110; // input=1.447265625, output=0.123216765082
			11'd371: out = 32'b00000000000000000000111101000111; // input=1.451171875, output=0.119339351355
			11'd372: out = 32'b00000000000000000000111011000111; // input=1.455078125, output=0.115460116656
			11'd373: out = 32'b00000000000000000000111001001000; // input=1.458984375, output=0.111579120177
			11'd374: out = 32'b00000000000000000000110111001001; // input=1.462890625, output=0.107696421139
			11'd375: out = 32'b00000000000000000000110101001010; // input=1.466796875, output=0.103812078785
			11'd376: out = 32'b00000000000000000000110011001010; // input=1.470703125, output=0.0999261523872
			11'd377: out = 32'b00000000000000000000110001001011; // input=1.474609375, output=0.0960387012391
			11'd378: out = 32'b00000000000000000000101111001100; // input=1.478515625, output=0.0921497846586
			11'd379: out = 32'b00000000000000000000101101001100; // input=1.482421875, output=0.0882594619857
			11'd380: out = 32'b00000000000000000000101011001101; // input=1.486328125, output=0.084367792582
			11'd381: out = 32'b00000000000000000000101001001101; // input=1.490234375, output=0.0804748358296
			11'd382: out = 32'b00000000000000000000100111001101; // input=1.494140625, output=0.0765806511302
			11'd383: out = 32'b00000000000000000000100101001110; // input=1.498046875, output=0.0726852979043
			11'd384: out = 32'b00000000000000000000100011001110; // input=1.501953125, output=0.0687888355902
			11'd385: out = 32'b00000000000000000000100001001110; // input=1.505859375, output=0.0648913236431
			11'd386: out = 32'b00000000000000000000011111001111; // input=1.509765625, output=0.0609928215342
			11'd387: out = 32'b00000000000000000000011101001111; // input=1.513671875, output=0.0570933887499
			11'd388: out = 32'b00000000000000000000011011001111; // input=1.517578125, output=0.0531930847907
			11'd389: out = 32'b00000000000000000000011001001111; // input=1.521484375, output=0.0492919691706
			11'd390: out = 32'b00000000000000000000010111001111; // input=1.525390625, output=0.0453901014156
			11'd391: out = 32'b00000000000000000000010101001111; // input=1.529296875, output=0.0414875410635
			11'd392: out = 32'b00000000000000000000010011010000; // input=1.533203125, output=0.0375843476626
			11'd393: out = 32'b00000000000000000000010001010000; // input=1.537109375, output=0.0336805807707
			11'd394: out = 32'b00000000000000000000001111010000; // input=1.541015625, output=0.0297762999547
			11'd395: out = 32'b00000000000000000000001101010000; // input=1.544921875, output=0.0258715647889
			11'd396: out = 32'b00000000000000000000001011010000; // input=1.548828125, output=0.0219664348549
			11'd397: out = 32'b00000000000000000000001001010000; // input=1.552734375, output=0.0180609697401
			11'd398: out = 32'b00000000000000000000000111010000; // input=1.556640625, output=0.0141552290372
			11'd399: out = 32'b00000000000000000000000101010000; // input=1.560546875, output=0.0102492723429
			11'd400: out = 32'b00000000000000000000000011010000; // input=1.564453125, output=0.00634315925725
			11'd401: out = 32'b00000000000000000000000001010000; // input=1.568359375, output=0.00243694938283
			11'd402: out = 32'b10000000000000000000000000110000; // input=1.572265625, output=-0.00146929767644
			11'd403: out = 32'b10000000000000000000000010110000; // input=1.576171875, output=-0.00537552231604
			11'd404: out = 32'b10000000000000000000000100110000; // input=1.580078125, output=-0.00928166493177
			11'd405: out = 32'b10000000000000000000000110110000; // input=1.583984375, output=-0.0131876659207
			11'd406: out = 32'b10000000000000000000001000110000; // input=1.587890625, output=-0.0170934656821
			11'd407: out = 32'b10000000000000000000001010110000; // input=1.591796875, output=-0.0209990046183
			11'd408: out = 32'b10000000000000000000001100110000; // input=1.595703125, output=-0.0249042231354
			11'd409: out = 32'b10000000000000000000001110110000; // input=1.599609375, output=-0.0288090616448
			11'd410: out = 32'b10000000000000000000010000110000; // input=1.603515625, output=-0.0327134605633
			11'd411: out = 32'b10000000000000000000010010110000; // input=1.607421875, output=-0.0366173603147
			11'd412: out = 32'b10000000000000000000010100110000; // input=1.611328125, output=-0.0405207013302
			11'd413: out = 32'b10000000000000000000010110110000; // input=1.615234375, output=-0.0444234240496
			11'd414: out = 32'b10000000000000000000011000110000; // input=1.619140625, output=-0.0483254689223
			11'd415: out = 32'b10000000000000000000011010101111; // input=1.623046875, output=-0.0522267764077
			11'd416: out = 32'b10000000000000000000011100101111; // input=1.626953125, output=-0.0561272869768
			11'd417: out = 32'b10000000000000000000011110101111; // input=1.630859375, output=-0.0600269411126
			11'd418: out = 32'b10000000000000000000100000101111; // input=1.634765625, output=-0.0639256793111
			11'd419: out = 32'b10000000000000000000100010101110; // input=1.638671875, output=-0.0678234420824
			11'd420: out = 32'b10000000000000000000100100101110; // input=1.642578125, output=-0.0717201699514
			11'd421: out = 32'b10000000000000000000100110101110; // input=1.646484375, output=-0.0756158034588
			11'd422: out = 32'b10000000000000000000101000101101; // input=1.650390625, output=-0.0795102831621
			11'd423: out = 32'b10000000000000000000101010101101; // input=1.654296875, output=-0.0834035496363
			11'd424: out = 32'b10000000000000000000101100101101; // input=1.658203125, output=-0.087295543475
			11'd425: out = 32'b10000000000000000000101110101100; // input=1.662109375, output=-0.0911862052911
			11'd426: out = 32'b10000000000000000000110000101011; // input=1.666015625, output=-0.0950754757179
			11'd427: out = 32'b10000000000000000000110010101011; // input=1.669921875, output=-0.0989632954099
			11'd428: out = 32'b10000000000000000000110100101010; // input=1.673828125, output=-0.102849605044
			11'd429: out = 32'b10000000000000000000110110101001; // input=1.677734375, output=-0.106734345319
			11'd430: out = 32'b10000000000000000000111000101001; // input=1.681640625, output=-0.11061745696
			11'd431: out = 32'b10000000000000000000111010101000; // input=1.685546875, output=-0.114498880714
			11'd432: out = 32'b10000000000000000000111100100111; // input=1.689453125, output=-0.118378557356
			11'd433: out = 32'b10000000000000000000111110100110; // input=1.693359375, output=-0.122256427688
			11'd434: out = 32'b10000000000000000001000000100101; // input=1.697265625, output=-0.126132432536
			11'd435: out = 32'b10000000000000000001000010100100; // input=1.701171875, output=-0.130006512759
			11'd436: out = 32'b10000000000000000001000100100011; // input=1.705078125, output=-0.133878609242
			11'd437: out = 32'b10000000000000000001000110100010; // input=1.708984375, output=-0.137748662903
			11'd438: out = 32'b10000000000000000001001000100000; // input=1.712890625, output=-0.141616614688
			11'd439: out = 32'b10000000000000000001001010011111; // input=1.716796875, output=-0.145482405578
			11'd440: out = 32'b10000000000000000001001100011110; // input=1.720703125, output=-0.149345976585
			11'd441: out = 32'b10000000000000000001001110011100; // input=1.724609375, output=-0.153207268757
			11'd442: out = 32'b10000000000000000001010000011011; // input=1.728515625, output=-0.157066223174
			11'd443: out = 32'b10000000000000000001010010011001; // input=1.732421875, output=-0.160922780954
			11'd444: out = 32'b10000000000000000001010100010111; // input=1.736328125, output=-0.164776883251
			11'd445: out = 32'b10000000000000000001010110010110; // input=1.740234375, output=-0.168628471254
			11'd446: out = 32'b10000000000000000001011000010100; // input=1.744140625, output=-0.172477486195
			11'd447: out = 32'b10000000000000000001011010010010; // input=1.748046875, output=-0.176323869342
			11'd448: out = 32'b10000000000000000001011100010000; // input=1.751953125, output=-0.180167562003
			11'd449: out = 32'b10000000000000000001011110001110; // input=1.755859375, output=-0.184008505529
			11'd450: out = 32'b10000000000000000001100000001011; // input=1.759765625, output=-0.187846641311
			11'd451: out = 32'b10000000000000000001100010001001; // input=1.763671875, output=-0.191681910785
			11'd452: out = 32'b10000000000000000001100100000111; // input=1.767578125, output=-0.195514255429
			11'd453: out = 32'b10000000000000000001100110000100; // input=1.771484375, output=-0.199343616766
			11'd454: out = 32'b10000000000000000001101000000001; // input=1.775390625, output=-0.203169936364
			11'd455: out = 32'b10000000000000000001101001111111; // input=1.779296875, output=-0.206993155839
			11'd456: out = 32'b10000000000000000001101011111100; // input=1.783203125, output=-0.210813216853
			11'd457: out = 32'b10000000000000000001101101111001; // input=1.787109375, output=-0.214630061117
			11'd458: out = 32'b10000000000000000001101111110110; // input=1.791015625, output=-0.218443630391
			11'd459: out = 32'b10000000000000000001110001110011; // input=1.794921875, output=-0.222253866483
			11'd460: out = 32'b10000000000000000001110011110000; // input=1.798828125, output=-0.226060711255
			11'd461: out = 32'b10000000000000000001110101101100; // input=1.802734375, output=-0.229864106618
			11'd462: out = 32'b10000000000000000001110111101001; // input=1.806640625, output=-0.233663994538
			11'd463: out = 32'b10000000000000000001111001100101; // input=1.810546875, output=-0.237460317033
			11'd464: out = 32'b10000000000000000001111011100001; // input=1.814453125, output=-0.241253016175
			11'd465: out = 32'b10000000000000000001111101011110; // input=1.818359375, output=-0.245042034094
			11'd466: out = 32'b10000000000000000001111111011010; // input=1.822265625, output=-0.248827312972
			11'd467: out = 32'b10000000000000000010000001010101; // input=1.826171875, output=-0.252608795052
			11'd468: out = 32'b10000000000000000010000011010001; // input=1.830078125, output=-0.256386422632
			11'd469: out = 32'b10000000000000000010000101001101; // input=1.833984375, output=-0.260160138071
			11'd470: out = 32'b10000000000000000010000111001000; // input=1.837890625, output=-0.263929883786
			11'd471: out = 32'b10000000000000000010001001000100; // input=1.841796875, output=-0.267695602256
			11'd472: out = 32'b10000000000000000010001010111111; // input=1.845703125, output=-0.271457236021
			11'd473: out = 32'b10000000000000000010001100111010; // input=1.849609375, output=-0.275214727682
			11'd474: out = 32'b10000000000000000010001110110101; // input=1.853515625, output=-0.278968019905
			11'd475: out = 32'b10000000000000000010010000110000; // input=1.857421875, output=-0.282717055419
			11'd476: out = 32'b10000000000000000010010010101011; // input=1.861328125, output=-0.286461777019
			11'd477: out = 32'b10000000000000000010010100100101; // input=1.865234375, output=-0.290202127564
			11'd478: out = 32'b10000000000000000010010110100000; // input=1.869140625, output=-0.293938049982
			11'd479: out = 32'b10000000000000000010011000011010; // input=1.873046875, output=-0.297669487267
			11'd480: out = 32'b10000000000000000010011010010100; // input=1.876953125, output=-0.301396382482
			11'd481: out = 32'b10000000000000000010011100001110; // input=1.880859375, output=-0.305118678759
			11'd482: out = 32'b10000000000000000010011110001000; // input=1.884765625, output=-0.308836319301
			11'd483: out = 32'b10000000000000000010100000000010; // input=1.888671875, output=-0.31254924738
			11'd484: out = 32'b10000000000000000010100001111011; // input=1.892578125, output=-0.316257406342
			11'd485: out = 32'b10000000000000000010100011110100; // input=1.896484375, output=-0.319960739605
			11'd486: out = 32'b10000000000000000010100101101110; // input=1.900390625, output=-0.323659190661
			11'd487: out = 32'b10000000000000000010100111100111; // input=1.904296875, output=-0.327352703076
			11'd488: out = 32'b10000000000000000010101001100000; // input=1.908203125, output=-0.331041220491
			11'd489: out = 32'b10000000000000000010101011011000; // input=1.912109375, output=-0.334724686625
			11'd490: out = 32'b10000000000000000010101101010001; // input=1.916015625, output=-0.338403045272
			11'd491: out = 32'b10000000000000000010101111001001; // input=1.919921875, output=-0.342076240304
			11'd492: out = 32'b10000000000000000010110001000001; // input=1.923828125, output=-0.345744215674
			11'd493: out = 32'b10000000000000000010110010111001; // input=1.927734375, output=-0.349406915413
			11'd494: out = 32'b10000000000000000010110100110001; // input=1.931640625, output=-0.353064283632
			11'd495: out = 32'b10000000000000000010110110101001; // input=1.935546875, output=-0.356716264525
			11'd496: out = 32'b10000000000000000010111000100000; // input=1.939453125, output=-0.360362802366
			11'd497: out = 32'b10000000000000000010111010011000; // input=1.943359375, output=-0.364003841514
			11'd498: out = 32'b10000000000000000010111100001111; // input=1.947265625, output=-0.367639326412
			11'd499: out = 32'b10000000000000000010111110000110; // input=1.951171875, output=-0.371269201585
			11'd500: out = 32'b10000000000000000010111111111101; // input=1.955078125, output=-0.374893411648
			11'd501: out = 32'b10000000000000000011000001110011; // input=1.958984375, output=-0.378511901298
			11'd502: out = 32'b10000000000000000011000011101001; // input=1.962890625, output=-0.382124615322
			11'd503: out = 32'b10000000000000000011000101100000; // input=1.966796875, output=-0.385731498595
			11'd504: out = 32'b10000000000000000011000111010110; // input=1.970703125, output=-0.38933249608
			11'd505: out = 32'b10000000000000000011001001001011; // input=1.974609375, output=-0.392927552829
			11'd506: out = 32'b10000000000000000011001011000001; // input=1.978515625, output=-0.396516613988
			11'd507: out = 32'b10000000000000000011001100110110; // input=1.982421875, output=-0.400099624791
			11'd508: out = 32'b10000000000000000011001110101100; // input=1.986328125, output=-0.403676530566
			11'd509: out = 32'b10000000000000000011010000100001; // input=1.990234375, output=-0.407247276734
			11'd510: out = 32'b10000000000000000011010010010101; // input=1.994140625, output=-0.41081180881
			11'd511: out = 32'b10000000000000000011010100001010; // input=1.998046875, output=-0.414370072403
			11'd512: out = 32'b10000000000000000011010101111110; // input=2.001953125, output=-0.417922013218
			11'd513: out = 32'b10000000000000000011010111110011; // input=2.005859375, output=-0.421467577057
			11'd514: out = 32'b10000000000000000011011001100111; // input=2.009765625, output=-0.42500670982
			11'd515: out = 32'b10000000000000000011011011011010; // input=2.013671875, output=-0.428539357504
			11'd516: out = 32'b10000000000000000011011101001110; // input=2.017578125, output=-0.432065466204
			11'd517: out = 32'b10000000000000000011011111000001; // input=2.021484375, output=-0.435584982116
			11'd518: out = 32'b10000000000000000011100000110100; // input=2.025390625, output=-0.439097851538
			11'd519: out = 32'b10000000000000000011100010100111; // input=2.029296875, output=-0.442604020867
			11'd520: out = 32'b10000000000000000011100100011010; // input=2.033203125, output=-0.446103436603
			11'd521: out = 32'b10000000000000000011100110001100; // input=2.037109375, output=-0.449596045349
			11'd522: out = 32'b10000000000000000011100111111111; // input=2.041015625, output=-0.453081793813
			11'd523: out = 32'b10000000000000000011101001110001; // input=2.044921875, output=-0.456560628806
			11'd524: out = 32'b10000000000000000011101011100010; // input=2.048828125, output=-0.460032497246
			11'd525: out = 32'b10000000000000000011101101010100; // input=2.052734375, output=-0.463497346155
			11'd526: out = 32'b10000000000000000011101111000101; // input=2.056640625, output=-0.466955122666
			11'd527: out = 32'b10000000000000000011110000110110; // input=2.060546875, output=-0.470405774016
			11'd528: out = 32'b10000000000000000011110010100111; // input=2.064453125, output=-0.473849247552
			11'd529: out = 32'b10000000000000000011110100011000; // input=2.068359375, output=-0.477285490732
			11'd530: out = 32'b10000000000000000011110110001000; // input=2.072265625, output=-0.480714451123
			11'd531: out = 32'b10000000000000000011110111111000; // input=2.076171875, output=-0.484136076402
			11'd532: out = 32'b10000000000000000011111001101000; // input=2.080078125, output=-0.487550314361
			11'd533: out = 32'b10000000000000000011111011011000; // input=2.083984375, output=-0.490957112901
			11'd534: out = 32'b10000000000000000011111101000111; // input=2.087890625, output=-0.49435642004
			11'd535: out = 32'b10000000000000000011111110110110; // input=2.091796875, output=-0.497748183909
			11'd536: out = 32'b10000000000000000100000000100101; // input=2.095703125, output=-0.501132352752
			11'd537: out = 32'b10000000000000000100000010010100; // input=2.099609375, output=-0.504508874933
			11'd538: out = 32'b10000000000000000100000100000010; // input=2.103515625, output=-0.507877698929
			11'd539: out = 32'b10000000000000000100000101110000; // input=2.107421875, output=-0.511238773335
			11'd540: out = 32'b10000000000000000100000111011110; // input=2.111328125, output=-0.514592046868
			11'd541: out = 32'b10000000000000000100001001001100; // input=2.115234375, output=-0.517937468358
			11'd542: out = 32'b10000000000000000100001010111001; // input=2.119140625, output=-0.52127498676
			11'd543: out = 32'b10000000000000000100001100100110; // input=2.123046875, output=-0.524604551148
			11'd544: out = 32'b10000000000000000100001110010011; // input=2.126953125, output=-0.527926110715
			11'd545: out = 32'b10000000000000000100010000000000; // input=2.130859375, output=-0.531239614779
			11'd546: out = 32'b10000000000000000100010001101100; // input=2.134765625, output=-0.53454501278
			11'd547: out = 32'b10000000000000000100010011011000; // input=2.138671875, output=-0.537842254283
			11'd548: out = 32'b10000000000000000100010101000100; // input=2.142578125, output=-0.541131288974
			11'd549: out = 32'b10000000000000000100010110101111; // input=2.146484375, output=-0.544412066667
			11'd550: out = 32'b10000000000000000100011000011011; // input=2.150390625, output=-0.547684537302
			11'd551: out = 32'b10000000000000000100011010000101; // input=2.154296875, output=-0.550948650945
			11'd552: out = 32'b10000000000000000100011011110000; // input=2.158203125, output=-0.554204357789
			11'd553: out = 32'b10000000000000000100011101011011; // input=2.162109375, output=-0.557451608157
			11'd554: out = 32'b10000000000000000100011111000101; // input=2.166015625, output=-0.560690352499
			11'd555: out = 32'b10000000000000000100100000101111; // input=2.169921875, output=-0.563920541396
			11'd556: out = 32'b10000000000000000100100010011000; // input=2.173828125, output=-0.567142125559
			11'd557: out = 32'b10000000000000000100100100000001; // input=2.177734375, output=-0.570355055831
			11'd558: out = 32'b10000000000000000100100101101010; // input=2.181640625, output=-0.573559283187
			11'd559: out = 32'b10000000000000000100100111010011; // input=2.185546875, output=-0.576754758734
			11'd560: out = 32'b10000000000000000100101000111100; // input=2.189453125, output=-0.579941433713
			11'd561: out = 32'b10000000000000000100101010100100; // input=2.193359375, output=-0.583119259499
			11'd562: out = 32'b10000000000000000100101100001011; // input=2.197265625, output=-0.586288187603
			11'd563: out = 32'b10000000000000000100101101110011; // input=2.201171875, output=-0.58944816967
			11'd564: out = 32'b10000000000000000100101111011010; // input=2.205078125, output=-0.592599157484
			11'd565: out = 32'b10000000000000000100110001000001; // input=2.208984375, output=-0.595741102963
			11'd566: out = 32'b10000000000000000100110010101000; // input=2.212890625, output=-0.598873958166
			11'd567: out = 32'b10000000000000000100110100001110; // input=2.216796875, output=-0.601997675289
			11'd568: out = 32'b10000000000000000100110101110100; // input=2.220703125, output=-0.605112206669
			11'd569: out = 32'b10000000000000000100110111011010; // input=2.224609375, output=-0.60821750478
			11'd570: out = 32'b10000000000000000100111001000000; // input=2.228515625, output=-0.611313522241
			11'd571: out = 32'b10000000000000000100111010100101; // input=2.232421875, output=-0.61440021181
			11'd572: out = 32'b10000000000000000100111100001010; // input=2.236328125, output=-0.617477526387
			11'd573: out = 32'b10000000000000000100111101101110; // input=2.240234375, output=-0.620545419017
			11'd574: out = 32'b10000000000000000100111111010010; // input=2.244140625, output=-0.623603842888
			11'd575: out = 32'b10000000000000000101000000110110; // input=2.248046875, output=-0.626652751331
			11'd576: out = 32'b10000000000000000101000010011010; // input=2.251953125, output=-0.629692097824
			11'd577: out = 32'b10000000000000000101000011111101; // input=2.255859375, output=-0.63272183599
			11'd578: out = 32'b10000000000000000101000101100000; // input=2.259765625, output=-0.635741919599
			11'd579: out = 32'b10000000000000000101000111000011; // input=2.263671875, output=-0.638752302569
			11'd580: out = 32'b10000000000000000101001000100101; // input=2.267578125, output=-0.641752938965
			11'd581: out = 32'b10000000000000000101001010000111; // input=2.271484375, output=-0.644743783001
			11'd582: out = 32'b10000000000000000101001011101001; // input=2.275390625, output=-0.647724789039
			11'd583: out = 32'b10000000000000000101001101001010; // input=2.279296875, output=-0.650695911595
			11'd584: out = 32'b10000000000000000101001110101011; // input=2.283203125, output=-0.653657105331
			11'd585: out = 32'b10000000000000000101010000001100; // input=2.287109375, output=-0.656608325064
			11'd586: out = 32'b10000000000000000101010001101100; // input=2.291015625, output=-0.659549525762
			11'd587: out = 32'b10000000000000000101010011001100; // input=2.294921875, output=-0.662480662545
			11'd588: out = 32'b10000000000000000101010100101100; // input=2.298828125, output=-0.665401690689
			11'd589: out = 32'b10000000000000000101010110001011; // input=2.302734375, output=-0.668312565622
			11'd590: out = 32'b10000000000000000101010111101010; // input=2.306640625, output=-0.671213242927
			11'd591: out = 32'b10000000000000000101011001001001; // input=2.310546875, output=-0.674103678343
			11'd592: out = 32'b10000000000000000101011010100111; // input=2.314453125, output=-0.676983827767
			11'd593: out = 32'b10000000000000000101011100000101; // input=2.318359375, output=-0.679853647251
			11'd594: out = 32'b10000000000000000101011101100011; // input=2.322265625, output=-0.682713093005
			11'd595: out = 32'b10000000000000000101011111000000; // input=2.326171875, output=-0.685562121397
			11'd596: out = 32'b10000000000000000101100000011110; // input=2.330078125, output=-0.688400688954
			11'd597: out = 32'b10000000000000000101100001111010; // input=2.333984375, output=-0.691228752363
			11'd598: out = 32'b10000000000000000101100011010111; // input=2.337890625, output=-0.694046268473
			11'd599: out = 32'b10000000000000000101100100110010; // input=2.341796875, output=-0.69685319429
			11'd600: out = 32'b10000000000000000101100110001110; // input=2.345703125, output=-0.699649486985
			11'd601: out = 32'b10000000000000000101100111101001; // input=2.349609375, output=-0.702435103889
			11'd602: out = 32'b10000000000000000101101001000100; // input=2.353515625, output=-0.705210002498
			11'd603: out = 32'b10000000000000000101101010011111; // input=2.357421875, output=-0.707974140471
			11'd604: out = 32'b10000000000000000101101011111001; // input=2.361328125, output=-0.710727475628
			11'd605: out = 32'b10000000000000000101101101010011; // input=2.365234375, output=-0.713469965959
			11'd606: out = 32'b10000000000000000101101110101100; // input=2.369140625, output=-0.716201569616
			11'd607: out = 32'b10000000000000000101110000000110; // input=2.373046875, output=-0.718922244918
			11'd608: out = 32'b10000000000000000101110001011110; // input=2.376953125, output=-0.721631950352
			11'd609: out = 32'b10000000000000000101110010110111; // input=2.380859375, output=-0.724330644569
			11'd610: out = 32'b10000000000000000101110100001111; // input=2.384765625, output=-0.727018286392
			11'd611: out = 32'b10000000000000000101110101100111; // input=2.388671875, output=-0.729694834811
			11'd612: out = 32'b10000000000000000101110110111110; // input=2.392578125, output=-0.732360248984
			11'd613: out = 32'b10000000000000000101111000010101; // input=2.396484375, output=-0.735014488241
			11'd614: out = 32'b10000000000000000101111001101100; // input=2.400390625, output=-0.737657512081
			11'd615: out = 32'b10000000000000000101111011000010; // input=2.404296875, output=-0.740289280175
			11'd616: out = 32'b10000000000000000101111100011000; // input=2.408203125, output=-0.742909752365
			11'd617: out = 32'b10000000000000000101111101101101; // input=2.412109375, output=-0.745518888667
			11'd618: out = 32'b10000000000000000101111111000010; // input=2.416015625, output=-0.748116649267
			11'd619: out = 32'b10000000000000000110000000010111; // input=2.419921875, output=-0.750702994528
			11'd620: out = 32'b10000000000000000110000001101011; // input=2.423828125, output=-0.753277884985
			11'd621: out = 32'b10000000000000000110000010111111; // input=2.427734375, output=-0.755841281348
			11'd622: out = 32'b10000000000000000110000100010011; // input=2.431640625, output=-0.758393144503
			11'd623: out = 32'b10000000000000000110000101100110; // input=2.435546875, output=-0.760933435512
			11'd624: out = 32'b10000000000000000110000110111001; // input=2.439453125, output=-0.763462115613
			11'd625: out = 32'b10000000000000000110001000001100; // input=2.443359375, output=-0.765979146221
			11'd626: out = 32'b10000000000000000110001001011110; // input=2.447265625, output=-0.76848448893
			11'd627: out = 32'b10000000000000000110001010101111; // input=2.451171875, output=-0.770978105511
			11'd628: out = 32'b10000000000000000110001100000001; // input=2.455078125, output=-0.773459957915
			11'd629: out = 32'b10000000000000000110001101010010; // input=2.458984375, output=-0.775930008271
			11'd630: out = 32'b10000000000000000110001110100010; // input=2.462890625, output=-0.77838821889
			11'd631: out = 32'b10000000000000000110001111110010; // input=2.466796875, output=-0.780834552263
			11'd632: out = 32'b10000000000000000110010001000010; // input=2.470703125, output=-0.783268971061
			11'd633: out = 32'b10000000000000000110010010010010; // input=2.474609375, output=-0.785691438138
			11'd634: out = 32'b10000000000000000110010011100001; // input=2.478515625, output=-0.78810191653
			11'd635: out = 32'b10000000000000000110010100101111; // input=2.482421875, output=-0.790500369457
			11'd636: out = 32'b10000000000000000110010101111101; // input=2.486328125, output=-0.792886760321
			11'd637: out = 32'b10000000000000000110010111001011; // input=2.490234375, output=-0.795261052708
			11'd638: out = 32'b10000000000000000110011000011001; // input=2.494140625, output=-0.797623210391
			11'd639: out = 32'b10000000000000000110011001100110; // input=2.498046875, output=-0.799973197324
			11'd640: out = 32'b10000000000000000110011010110010; // input=2.501953125, output=-0.802310977651
			11'd641: out = 32'b10000000000000000110011011111110; // input=2.505859375, output=-0.804636515699
			11'd642: out = 32'b10000000000000000110011101001010; // input=2.509765625, output=-0.806949775984
			11'd643: out = 32'b10000000000000000110011110010110; // input=2.513671875, output=-0.809250723208
			11'd644: out = 32'b10000000000000000110011111100001; // input=2.517578125, output=-0.811539322262
			11'd645: out = 32'b10000000000000000110100000101011; // input=2.521484375, output=-0.813815538224
			11'd646: out = 32'b10000000000000000110100001110101; // input=2.525390625, output=-0.816079336362
			11'd647: out = 32'b10000000000000000110100010111111; // input=2.529296875, output=-0.818330682134
			11'd648: out = 32'b10000000000000000110100100001000; // input=2.533203125, output=-0.820569541186
			11'd649: out = 32'b10000000000000000110100101010001; // input=2.537109375, output=-0.822795879357
			11'd650: out = 32'b10000000000000000110100110011010; // input=2.541015625, output=-0.825009662675
			11'd651: out = 32'b10000000000000000110100111100010; // input=2.544921875, output=-0.82721085736
			11'd652: out = 32'b10000000000000000110101000101010; // input=2.548828125, output=-0.829399429826
			11'd653: out = 32'b10000000000000000110101001110001; // input=2.552734375, output=-0.831575346677
			11'd654: out = 32'b10000000000000000110101010111000; // input=2.556640625, output=-0.833738574711
			11'd655: out = 32'b10000000000000000110101011111110; // input=2.560546875, output=-0.83588908092
			11'd656: out = 32'b10000000000000000110101101000100; // input=2.564453125, output=-0.83802683249
			11'd657: out = 32'b10000000000000000110101110001010; // input=2.568359375, output=-0.840151796802
			11'd658: out = 32'b10000000000000000110101111001111; // input=2.572265625, output=-0.842263941431
			11'd659: out = 32'b10000000000000000110110000010100; // input=2.576171875, output=-0.844363234149
			11'd660: out = 32'b10000000000000000110110001011000; // input=2.580078125, output=-0.846449642922
			11'd661: out = 32'b10000000000000000110110010011100; // input=2.583984375, output=-0.848523135916
			11'd662: out = 32'b10000000000000000110110011100000; // input=2.587890625, output=-0.85058368149
			11'd663: out = 32'b10000000000000000110110100100011; // input=2.591796875, output=-0.852631248204
			11'd664: out = 32'b10000000000000000110110101100110; // input=2.595703125, output=-0.854665804814
			11'd665: out = 32'b10000000000000000110110110101000; // input=2.599609375, output=-0.856687320275
			11'd666: out = 32'b10000000000000000110110111101010; // input=2.603515625, output=-0.858695763742
			11'd667: out = 32'b10000000000000000110111000101011; // input=2.607421875, output=-0.860691104568
			11'd668: out = 32'b10000000000000000110111001101100; // input=2.611328125, output=-0.862673312307
			11'd669: out = 32'b10000000000000000110111010101101; // input=2.615234375, output=-0.864642356712
			11'd670: out = 32'b10000000000000000110111011101101; // input=2.619140625, output=-0.866598207739
			11'd671: out = 32'b10000000000000000110111100101100; // input=2.623046875, output=-0.868540835543
			11'd672: out = 32'b10000000000000000110111101101100; // input=2.626953125, output=-0.870470210483
			11'd673: out = 32'b10000000000000000110111110101010; // input=2.630859375, output=-0.872386303118
			11'd674: out = 32'b10000000000000000110111111101001; // input=2.634765625, output=-0.874289084212
			11'd675: out = 32'b10000000000000000111000000100111; // input=2.638671875, output=-0.87617852473
			11'd676: out = 32'b10000000000000000111000001100100; // input=2.642578125, output=-0.878054595842
			11'd677: out = 32'b10000000000000000111000010100001; // input=2.646484375, output=-0.879917268921
			11'd678: out = 32'b10000000000000000111000011011110; // input=2.650390625, output=-0.881766515544
			11'd679: out = 32'b10000000000000000111000100011010; // input=2.654296875, output=-0.883602307496
			11'd680: out = 32'b10000000000000000111000101010110; // input=2.658203125, output=-0.885424616764
			11'd681: out = 32'b10000000000000000111000110010001; // input=2.662109375, output=-0.887233415541
			11'd682: out = 32'b10000000000000000111000111001100; // input=2.666015625, output=-0.889028676228
			11'd683: out = 32'b10000000000000000111001000000110; // input=2.669921875, output=-0.890810371432
			11'd684: out = 32'b10000000000000000111001001000000; // input=2.673828125, output=-0.892578473965
			11'd685: out = 32'b10000000000000000111001001111010; // input=2.677734375, output=-0.894332956848
			11'd686: out = 32'b10000000000000000111001010110011; // input=2.681640625, output=-0.896073793311
			11'd687: out = 32'b10000000000000000111001011101011; // input=2.685546875, output=-0.897800956791
			11'd688: out = 32'b10000000000000000111001100100011; // input=2.689453125, output=-0.899514420932
			11'd689: out = 32'b10000000000000000111001101011011; // input=2.693359375, output=-0.90121415959
			11'd690: out = 32'b10000000000000000111001110010010; // input=2.697265625, output=-0.902900146829
			11'd691: out = 32'b10000000000000000111001111001001; // input=2.701171875, output=-0.904572356923
			11'd692: out = 32'b10000000000000000111001111111111; // input=2.705078125, output=-0.906230764355
			11'd693: out = 32'b10000000000000000111010000110101; // input=2.708984375, output=-0.907875343821
			11'd694: out = 32'b10000000000000000111010001101011; // input=2.712890625, output=-0.909506070226
			11'd695: out = 32'b10000000000000000111010010100000; // input=2.716796875, output=-0.911122918687
			11'd696: out = 32'b10000000000000000111010011010100; // input=2.720703125, output=-0.912725864533
			11'd697: out = 32'b10000000000000000111010100001000; // input=2.724609375, output=-0.914314883306
			11'd698: out = 32'b10000000000000000111010100111100; // input=2.728515625, output=-0.915889950759
			11'd699: out = 32'b10000000000000000111010101101111; // input=2.732421875, output=-0.917451042858
			11'd700: out = 32'b10000000000000000111010110100010; // input=2.736328125, output=-0.918998135783
			11'd701: out = 32'b10000000000000000111010111010100; // input=2.740234375, output=-0.920531205927
			11'd702: out = 32'b10000000000000000111011000000110; // input=2.744140625, output=-0.922050229897
			11'd703: out = 32'b10000000000000000111011000110111; // input=2.748046875, output=-0.923555184515
			11'd704: out = 32'b10000000000000000111011001101000; // input=2.751953125, output=-0.925046046817
			11'd705: out = 32'b10000000000000000111011010011000; // input=2.755859375, output=-0.926522794055
			11'd706: out = 32'b10000000000000000111011011001000; // input=2.759765625, output=-0.927985403695
			11'd707: out = 32'b10000000000000000111011011111000; // input=2.763671875, output=-0.929433853419
			11'd708: out = 32'b10000000000000000111011100100111; // input=2.767578125, output=-0.930868121127
			11'd709: out = 32'b10000000000000000111011101010101; // input=2.771484375, output=-0.932288184932
			11'd710: out = 32'b10000000000000000111011110000011; // input=2.775390625, output=-0.933694023166
			11'd711: out = 32'b10000000000000000111011110110001; // input=2.779296875, output=-0.935085614378
			11'd712: out = 32'b10000000000000000111011111011110; // input=2.783203125, output=-0.936462937335
			11'd713: out = 32'b10000000000000000111100000001011; // input=2.787109375, output=-0.937825971019
			11'd714: out = 32'b10000000000000000111100000110111; // input=2.791015625, output=-0.939174694632
			11'd715: out = 32'b10000000000000000111100001100011; // input=2.794921875, output=-0.940509087596
			11'd716: out = 32'b10000000000000000111100010001110; // input=2.798828125, output=-0.941829129547
			11'd717: out = 32'b10000000000000000111100010111001; // input=2.802734375, output=-0.943134800345
			11'd718: out = 32'b10000000000000000111100011100011; // input=2.806640625, output=-0.944426080067
			11'd719: out = 32'b10000000000000000111100100001101; // input=2.810546875, output=-0.945702949008
			11'd720: out = 32'b10000000000000000111100100110110; // input=2.814453125, output=-0.946965387686
			11'd721: out = 32'b10000000000000000111100101011111; // input=2.818359375, output=-0.948213376837
			11'd722: out = 32'b10000000000000000111100110000111; // input=2.822265625, output=-0.949446897419
			11'd723: out = 32'b10000000000000000111100110101111; // input=2.826171875, output=-0.950665930609
			11'd724: out = 32'b10000000000000000111100111010111; // input=2.830078125, output=-0.951870457806
			11'd725: out = 32'b10000000000000000111100111111110; // input=2.833984375, output=-0.953060460632
			11'd726: out = 32'b10000000000000000111101000100100; // input=2.837890625, output=-0.954235920927
			11'd727: out = 32'b10000000000000000111101001001010; // input=2.841796875, output=-0.955396820757
			11'd728: out = 32'b10000000000000000111101001110000; // input=2.845703125, output=-0.956543142406
			11'd729: out = 32'b10000000000000000111101010010101; // input=2.849609375, output=-0.957674868384
			11'd730: out = 32'b10000000000000000111101010111010; // input=2.853515625, output=-0.958791981422
			11'd731: out = 32'b10000000000000000111101011011110; // input=2.857421875, output=-0.959894464473
			11'd732: out = 32'b10000000000000000111101100000001; // input=2.861328125, output=-0.960982300717
			11'd733: out = 32'b10000000000000000111101100100101; // input=2.865234375, output=-0.962055473552
			11'd734: out = 32'b10000000000000000111101101000111; // input=2.869140625, output=-0.963113966605
			11'd735: out = 32'b10000000000000000111101101101010; // input=2.873046875, output=-0.964157763723
			11'd736: out = 32'b10000000000000000111101110001011; // input=2.876953125, output=-0.965186848981
			11'd737: out = 32'b10000000000000000111101110101100; // input=2.880859375, output=-0.966201206674
			11'd738: out = 32'b10000000000000000111101111001101; // input=2.884765625, output=-0.967200821326
			11'd739: out = 32'b10000000000000000111101111101110; // input=2.888671875, output=-0.968185677683
			11'd740: out = 32'b10000000000000000111110000001101; // input=2.892578125, output=-0.969155760718
			11'd741: out = 32'b10000000000000000111110000101101; // input=2.896484375, output=-0.970111055629
			11'd742: out = 32'b10000000000000000111110001001011; // input=2.900390625, output=-0.971051547838
			11'd743: out = 32'b10000000000000000111110001101010; // input=2.904296875, output=-0.971977222996
			11'd744: out = 32'b10000000000000000111110010001000; // input=2.908203125, output=-0.972888066977
			11'd745: out = 32'b10000000000000000111110010100101; // input=2.912109375, output=-0.973784065883
			11'd746: out = 32'b10000000000000000111110011000010; // input=2.916015625, output=-0.974665206042
			11'd747: out = 32'b10000000000000000111110011011110; // input=2.919921875, output=-0.975531474009
			11'd748: out = 32'b10000000000000000111110011111010; // input=2.923828125, output=-0.976382856567
			11'd749: out = 32'b10000000000000000111110100010110; // input=2.927734375, output=-0.977219340723
			11'd750: out = 32'b10000000000000000111110100110000; // input=2.931640625, output=-0.978040913714
			11'd751: out = 32'b10000000000000000111110101001011; // input=2.935546875, output=-0.978847563005
			11'd752: out = 32'b10000000000000000111110101100101; // input=2.939453125, output=-0.979639276285
			11'd753: out = 32'b10000000000000000111110101111110; // input=2.943359375, output=-0.980416041476
			11'd754: out = 32'b10000000000000000111110110010111; // input=2.947265625, output=-0.981177846724
			11'd755: out = 32'b10000000000000000111110110110000; // input=2.951171875, output=-0.981924680406
			11'd756: out = 32'b10000000000000000111110111001000; // input=2.955078125, output=-0.982656531125
			11'd757: out = 32'b10000000000000000111110111011111; // input=2.958984375, output=-0.983373387714
			11'd758: out = 32'b10000000000000000111110111110110; // input=2.962890625, output=-0.984075239235
			11'd759: out = 32'b10000000000000000111111000001101; // input=2.966796875, output=-0.984762074979
			11'd760: out = 32'b10000000000000000111111000100011; // input=2.970703125, output=-0.985433884466
			11'd761: out = 32'b10000000000000000111111000111000; // input=2.974609375, output=-0.986090657443
			11'd762: out = 32'b10000000000000000111111001001101; // input=2.978515625, output=-0.986732383891
			11'd763: out = 32'b10000000000000000111111001100010; // input=2.982421875, output=-0.987359054016
			11'd764: out = 32'b10000000000000000111111001110110; // input=2.986328125, output=-0.987970658257
			11'd765: out = 32'b10000000000000000111111010001001; // input=2.990234375, output=-0.988567187281
			11'd766: out = 32'b10000000000000000111111010011100; // input=2.994140625, output=-0.989148631986
			11'd767: out = 32'b10000000000000000111111010101111; // input=2.998046875, output=-0.9897149835
			11'd768: out = 32'b10000000000000000111111011000001; // input=3.001953125, output=-0.990266233181
			11'd769: out = 32'b10000000000000000111111011010011; // input=3.005859375, output=-0.990802372617
			11'd770: out = 32'b10000000000000000111111011100100; // input=3.009765625, output=-0.991323393629
			11'd771: out = 32'b10000000000000000111111011110100; // input=3.013671875, output=-0.991829288265
			11'd772: out = 32'b10000000000000000111111100000100; // input=3.017578125, output=-0.992320048806
			11'd773: out = 32'b10000000000000000111111100010100; // input=3.021484375, output=-0.992795667765
			11'd774: out = 32'b10000000000000000111111100100011; // input=3.025390625, output=-0.993256137883
			11'd775: out = 32'b10000000000000000111111100110010; // input=3.029296875, output=-0.993701452134
			11'd776: out = 32'b10000000000000000111111101000000; // input=3.033203125, output=-0.994131603724
			11'd777: out = 32'b10000000000000000111111101001101; // input=3.037109375, output=-0.994546586089
			11'd778: out = 32'b10000000000000000111111101011010; // input=3.041015625, output=-0.994946392896
			11'd779: out = 32'b10000000000000000111111101100111; // input=3.044921875, output=-0.995331018046
			11'd780: out = 32'b10000000000000000111111101110011; // input=3.048828125, output=-0.995700455669
			11'd781: out = 32'b10000000000000000111111101111111; // input=3.052734375, output=-0.996054700128
			11'd782: out = 32'b10000000000000000111111110001010; // input=3.056640625, output=-0.996393746017
			11'd783: out = 32'b10000000000000000111111110010100; // input=3.060546875, output=-0.996717588164
			11'd784: out = 32'b10000000000000000111111110011111; // input=3.064453125, output=-0.997026221627
			11'd785: out = 32'b10000000000000000111111110101000; // input=3.068359375, output=-0.997319641697
			11'd786: out = 32'b10000000000000000111111110110001; // input=3.072265625, output=-0.997597843896
			11'd787: out = 32'b10000000000000000111111110111010; // input=3.076171875, output=-0.997860823979
			11'd788: out = 32'b10000000000000000111111111000010; // input=3.080078125, output=-0.998108577933
			11'd789: out = 32'b10000000000000000111111111001010; // input=3.083984375, output=-0.998341101979
			11'd790: out = 32'b10000000000000000111111111010001; // input=3.087890625, output=-0.998558392568
			11'd791: out = 32'b10000000000000000111111111010111; // input=3.091796875, output=-0.998760446384
			11'd792: out = 32'b10000000000000000111111111011110; // input=3.095703125, output=-0.998947260345
			11'd793: out = 32'b10000000000000000111111111100011; // input=3.099609375, output=-0.999118831599
			11'd794: out = 32'b10000000000000000111111111101000; // input=3.103515625, output=-0.99927515753
			11'd795: out = 32'b10000000000000000111111111101101; // input=3.107421875, output=-0.999416235751
			11'd796: out = 32'b10000000000000000111111111110001; // input=3.111328125, output=-0.99954206411
			11'd797: out = 32'b10000000000000000111111111110101; // input=3.115234375, output=-0.999652640687
			11'd798: out = 32'b10000000000000000111111111111000; // input=3.119140625, output=-0.999747963794
			11'd799: out = 32'b10000000000000000111111111111010; // input=3.123046875, output=-0.999828031977
			11'd800: out = 32'b10000000000000000111111111111100; // input=3.126953125, output=-0.999892844015
			11'd801: out = 32'b10000000000000000111111111111110; // input=3.130859375, output=-0.999942398918
			11'd802: out = 32'b10000000000000000111111111111111; // input=3.134765625, output=-0.999976695931
			11'd803: out = 32'b10000000000000000111111111111111; // input=3.138671875, output=-0.999995734529
			11'd804: out = 32'b10000000000000000111111111111111; // input=3.142578125, output=-0.999999514423
			11'd805: out = 32'b10000000000000000111111111111111; // input=3.146484375, output=-0.999988035555
			11'd806: out = 32'b10000000000000000111111111111111; // input=3.150390625, output=-0.999961298099
			11'd807: out = 32'b10000000000000000111111111111101; // input=3.154296875, output=-0.999919302465
			11'd808: out = 32'b10000000000000000111111111111011; // input=3.158203125, output=-0.999862049292
			11'd809: out = 32'b10000000000000000111111111111001; // input=3.162109375, output=-0.999789539454
			11'd810: out = 32'b10000000000000000111111111110110; // input=3.166015625, output=-0.999701774058
			11'd811: out = 32'b10000000000000000111111111110011; // input=3.169921875, output=-0.999598754443
			11'd812: out = 32'b10000000000000000111111111101111; // input=3.173828125, output=-0.999480482181
			11'd813: out = 32'b10000000000000000111111111101011; // input=3.177734375, output=-0.999346959076
			11'd814: out = 32'b10000000000000000111111111100110; // input=3.181640625, output=-0.999198187167
			11'd815: out = 32'b10000000000000000111111111100000; // input=3.185546875, output=-0.999034168722
			11'd816: out = 32'b10000000000000000111111111011010; // input=3.189453125, output=-0.998854906245
			11'd817: out = 32'b10000000000000000111111111010100; // input=3.193359375, output=-0.998660402471
			11'd818: out = 32'b10000000000000000111111111001101; // input=3.197265625, output=-0.998450660368
			11'd819: out = 32'b10000000000000000111111111000110; // input=3.201171875, output=-0.998225683137
			11'd820: out = 32'b10000000000000000111111110111110; // input=3.205078125, output=-0.997985474209
			11'd821: out = 32'b10000000000000000111111110110110; // input=3.208984375, output=-0.997730037251
			11'd822: out = 32'b10000000000000000111111110101101; // input=3.212890625, output=-0.997459376161
			11'd823: out = 32'b10000000000000000111111110100011; // input=3.216796875, output=-0.997173495067
			11'd824: out = 32'b10000000000000000111111110011010; // input=3.220703125, output=-0.996872398333
			11'd825: out = 32'b10000000000000000111111110001111; // input=3.224609375, output=-0.996556090553
			11'd826: out = 32'b10000000000000000111111110000100; // input=3.228515625, output=-0.996224576552
			11'd827: out = 32'b10000000000000000111111101111001; // input=3.232421875, output=-0.995877861391
			11'd828: out = 32'b10000000000000000111111101101101; // input=3.236328125, output=-0.995515950358
			11'd829: out = 32'b10000000000000000111111101100001; // input=3.240234375, output=-0.995138848977
			11'd830: out = 32'b10000000000000000111111101010100; // input=3.244140625, output=-0.994746563001
			11'd831: out = 32'b10000000000000000111111101000111; // input=3.248046875, output=-0.994339098417
			11'd832: out = 32'b10000000000000000111111100111001; // input=3.251953125, output=-0.993916461441
			11'd833: out = 32'b10000000000000000111111100101010; // input=3.255859375, output=-0.993478658524
			11'd834: out = 32'b10000000000000000111111100011011; // input=3.259765625, output=-0.993025696344
			11'd835: out = 32'b10000000000000000111111100001100; // input=3.263671875, output=-0.992557581813
			11'd836: out = 32'b10000000000000000111111011111100; // input=3.267578125, output=-0.992074322076
			11'd837: out = 32'b10000000000000000111111011101100; // input=3.271484375, output=-0.991575924504
			11'd838: out = 32'b10000000000000000111111011011011; // input=3.275390625, output=-0.991062396704
			11'd839: out = 32'b10000000000000000111111011001010; // input=3.279296875, output=-0.990533746511
			11'd840: out = 32'b10000000000000000111111010111000; // input=3.283203125, output=-0.989989981992
			11'd841: out = 32'b10000000000000000111111010100110; // input=3.287109375, output=-0.989431111444
			11'd842: out = 32'b10000000000000000111111010010011; // input=3.291015625, output=-0.988857143395
			11'd843: out = 32'b10000000000000000111111010000000; // input=3.294921875, output=-0.988268086602
			11'd844: out = 32'b10000000000000000111111001101100; // input=3.298828125, output=-0.987663950053
			11'd845: out = 32'b10000000000000000111111001010111; // input=3.302734375, output=-0.987044742969
			11'd846: out = 32'b10000000000000000111111001000011; // input=3.306640625, output=-0.986410474795
			11'd847: out = 32'b10000000000000000111111000101101; // input=3.310546875, output=-0.985761155212
			11'd848: out = 32'b10000000000000000111111000011000; // input=3.314453125, output=-0.985096794126
			11'd849: out = 32'b10000000000000000111111000000001; // input=3.318359375, output=-0.984417401675
			11'd850: out = 32'b10000000000000000111110111101011; // input=3.322265625, output=-0.983722988226
			11'd851: out = 32'b10000000000000000111110111010011; // input=3.326171875, output=-0.983013564374
			11'd852: out = 32'b10000000000000000111110110111100; // input=3.330078125, output=-0.982289140945
			11'd853: out = 32'b10000000000000000111110110100011; // input=3.333984375, output=-0.981549728992
			11'd854: out = 32'b10000000000000000111110110001011; // input=3.337890625, output=-0.980795339798
			11'd855: out = 32'b10000000000000000111110101110001; // input=3.341796875, output=-0.980025984873
			11'd856: out = 32'b10000000000000000111110101011000; // input=3.345703125, output=-0.979241675958
			11'd857: out = 32'b10000000000000000111110100111110; // input=3.349609375, output=-0.978442425019
			11'd858: out = 32'b10000000000000000111110100100011; // input=3.353515625, output=-0.977628244254
			11'd859: out = 32'b10000000000000000111110100001000; // input=3.357421875, output=-0.976799146083
			11'd860: out = 32'b10000000000000000111110011101100; // input=3.361328125, output=-0.97595514316
			11'd861: out = 32'b10000000000000000111110011010000; // input=3.365234375, output=-0.975096248362
			11'd862: out = 32'b10000000000000000111110010110011; // input=3.369140625, output=-0.974222474795
			11'd863: out = 32'b10000000000000000111110010010110; // input=3.373046875, output=-0.973333835791
			11'd864: out = 32'b10000000000000000111110001111001; // input=3.376953125, output=-0.972430344911
			11'd865: out = 32'b10000000000000000111110001011011; // input=3.380859375, output=-0.97151201594
			11'd866: out = 32'b10000000000000000111110000111100; // input=3.384765625, output=-0.970578862891
			11'd867: out = 32'b10000000000000000111110000011101; // input=3.388671875, output=-0.969630900003
			11'd868: out = 32'b10000000000000000111101111111101; // input=3.392578125, output=-0.96866814174
			11'd869: out = 32'b10000000000000000111101111011101; // input=3.396484375, output=-0.967690602793
			11'd870: out = 32'b10000000000000000111101110111101; // input=3.400390625, output=-0.966698298078
			11'd871: out = 32'b10000000000000000111101110011100; // input=3.404296875, output=-0.965691242737
			11'd872: out = 32'b10000000000000000111101101111010; // input=3.408203125, output=-0.964669452135
			11'd873: out = 32'b10000000000000000111101101011000; // input=3.412109375, output=-0.963632941864
			11'd874: out = 32'b10000000000000000111101100110110; // input=3.416015625, output=-0.96258172774
			11'd875: out = 32'b10000000000000000111101100010011; // input=3.419921875, output=-0.961515825803
			11'd876: out = 32'b10000000000000000111101011110000; // input=3.423828125, output=-0.960435252318
			11'd877: out = 32'b10000000000000000111101011001100; // input=3.427734375, output=-0.959340023773
			11'd878: out = 32'b10000000000000000111101010100111; // input=3.431640625, output=-0.958230156879
			11'd879: out = 32'b10000000000000000111101010000010; // input=3.435546875, output=-0.957105668571
			11'd880: out = 32'b10000000000000000111101001011101; // input=3.439453125, output=-0.955966576009
			11'd881: out = 32'b10000000000000000111101000110111; // input=3.443359375, output=-0.954812896573
			11'd882: out = 32'b10000000000000000111101000010001; // input=3.447265625, output=-0.953644647867
			11'd883: out = 32'b10000000000000000111100111101010; // input=3.451171875, output=-0.952461847717
			11'd884: out = 32'b10000000000000000111100111000011; // input=3.455078125, output=-0.951264514171
			11'd885: out = 32'b10000000000000000111100110011011; // input=3.458984375, output=-0.950052665499
			11'd886: out = 32'b10000000000000000111100101110011; // input=3.462890625, output=-0.948826320192
			11'd887: out = 32'b10000000000000000111100101001010; // input=3.466796875, output=-0.947585496963
			11'd888: out = 32'b10000000000000000111100100100001; // input=3.470703125, output=-0.946330214745
			11'd889: out = 32'b10000000000000000111100011111000; // input=3.474609375, output=-0.945060492692
			11'd890: out = 32'b10000000000000000111100011001110; // input=3.478515625, output=-0.943776350179
			11'd891: out = 32'b10000000000000000111100010100011; // input=3.482421875, output=-0.9424778068
			11'd892: out = 32'b10000000000000000111100001111000; // input=3.486328125, output=-0.94116488237
			11'd893: out = 32'b10000000000000000111100001001101; // input=3.490234375, output=-0.939837596921
			11'd894: out = 32'b10000000000000000111100000100001; // input=3.494140625, output=-0.938495970706
			11'd895: out = 32'b10000000000000000111011111110100; // input=3.498046875, output=-0.937140024198
			11'd896: out = 32'b10000000000000000111011111000111; // input=3.501953125, output=-0.935769778086
			11'd897: out = 32'b10000000000000000111011110011010; // input=3.505859375, output=-0.934385253279
			11'd898: out = 32'b10000000000000000111011101101100; // input=3.509765625, output=-0.932986470902
			11'd899: out = 32'b10000000000000000111011100111110; // input=3.513671875, output=-0.931573452299
			11'd900: out = 32'b10000000000000000111011100001111; // input=3.517578125, output=-0.930146219032
			11'd901: out = 32'b10000000000000000111011011100000; // input=3.521484375, output=-0.928704792878
			11'd902: out = 32'b10000000000000000111011010110000; // input=3.525390625, output=-0.927249195831
			11'd903: out = 32'b10000000000000000111011010000000; // input=3.529296875, output=-0.925779450103
			11'd904: out = 32'b10000000000000000111011001001111; // input=3.533203125, output=-0.924295578119
			11'd905: out = 32'b10000000000000000111011000011110; // input=3.537109375, output=-0.922797602521
			11'd906: out = 32'b10000000000000000111010111101101; // input=3.541015625, output=-0.921285546168
			11'd907: out = 32'b10000000000000000111010110111011; // input=3.544921875, output=-0.919759432131
			11'd908: out = 32'b10000000000000000111010110001000; // input=3.548828125, output=-0.918219283696
			11'd909: out = 32'b10000000000000000111010101010101; // input=3.552734375, output=-0.916665124365
			11'd910: out = 32'b10000000000000000111010100100010; // input=3.556640625, output=-0.915096977852
			11'd911: out = 32'b10000000000000000111010011101110; // input=3.560546875, output=-0.913514868085
			11'd912: out = 32'b10000000000000000111010010111010; // input=3.564453125, output=-0.911918819205
			11'd913: out = 32'b10000000000000000111010010000101; // input=3.568359375, output=-0.910308855566
			11'd914: out = 32'b10000000000000000111010001010000; // input=3.572265625, output=-0.908685001733
			11'd915: out = 32'b10000000000000000111010000011010; // input=3.576171875, output=-0.907047282486
			11'd916: out = 32'b10000000000000000111001111100100; // input=3.580078125, output=-0.905395722813
			11'd917: out = 32'b10000000000000000111001110101101; // input=3.583984375, output=-0.903730347915
			11'd918: out = 32'b10000000000000000111001101110110; // input=3.587890625, output=-0.902051183204
			11'd919: out = 32'b10000000000000000111001100111111; // input=3.591796875, output=-0.900358254301
			11'd920: out = 32'b10000000000000000111001100000111; // input=3.595703125, output=-0.89865158704
			11'd921: out = 32'b10000000000000000111001011001111; // input=3.599609375, output=-0.896931207461
			11'd922: out = 32'b10000000000000000111001010010110; // input=3.603515625, output=-0.895197141815
			11'd923: out = 32'b10000000000000000111001001011101; // input=3.607421875, output=-0.893449416562
			11'd924: out = 32'b10000000000000000111001000100011; // input=3.611328125, output=-0.89168805837
			11'd925: out = 32'b10000000000000000111000111101001; // input=3.615234375, output=-0.889913094116
			11'd926: out = 32'b10000000000000000111000110101110; // input=3.619140625, output=-0.888124550883
			11'd927: out = 32'b10000000000000000111000101110011; // input=3.623046875, output=-0.886322455962
			11'd928: out = 32'b10000000000000000111000100111000; // input=3.626953125, output=-0.88450683685
			11'd929: out = 32'b10000000000000000111000011111100; // input=3.630859375, output=-0.882677721253
			11'd930: out = 32'b10000000000000000111000010111111; // input=3.634765625, output=-0.880835137079
			11'd931: out = 32'b10000000000000000111000010000010; // input=3.638671875, output=-0.878979112445
			11'd932: out = 32'b10000000000000000111000001000101; // input=3.642578125, output=-0.877109675671
			11'd933: out = 32'b10000000000000000111000000000111; // input=3.646484375, output=-0.875226855283
			11'd934: out = 32'b10000000000000000110111111001001; // input=3.650390625, output=-0.87333068001
			11'd935: out = 32'b10000000000000000110111110001011; // input=3.654296875, output=-0.871421178785
			11'd936: out = 32'b10000000000000000110111101001100; // input=3.658203125, output=-0.869498380745
			11'd937: out = 32'b10000000000000000110111100001100; // input=3.662109375, output=-0.867562315229
			11'd938: out = 32'b10000000000000000110111011001100; // input=3.666015625, output=-0.86561301178
			11'd939: out = 32'b10000000000000000110111010001100; // input=3.669921875, output=-0.863650500142
			11'd940: out = 32'b10000000000000000110111001001011; // input=3.673828125, output=-0.861674810259
			11'd941: out = 32'b10000000000000000110111000001010; // input=3.677734375, output=-0.859685972279
			11'd942: out = 32'b10000000000000000110110111001001; // input=3.681640625, output=-0.857684016548
			11'd943: out = 32'b10000000000000000110110110000111; // input=3.685546875, output=-0.855668973615
			11'd944: out = 32'b10000000000000000110110101000100; // input=3.689453125, output=-0.853640874226
			11'd945: out = 32'b10000000000000000110110100000001; // input=3.693359375, output=-0.851599749328
			11'd946: out = 32'b10000000000000000110110010111110; // input=3.697265625, output=-0.849545630065
			11'd947: out = 32'b10000000000000000110110001111010; // input=3.701171875, output=-0.847478547781
			11'd948: out = 32'b10000000000000000110110000110110; // input=3.705078125, output=-0.845398534017
			11'd949: out = 32'b10000000000000000110101111110001; // input=3.708984375, output=-0.843305620512
			11'd950: out = 32'b10000000000000000110101110101100; // input=3.712890625, output=-0.8411998392
			11'd951: out = 32'b10000000000000000110101101100111; // input=3.716796875, output=-0.839081222214
			11'd952: out = 32'b10000000000000000110101100100001; // input=3.720703125, output=-0.83694980188
			11'd953: out = 32'b10000000000000000110101011011011; // input=3.724609375, output=-0.834805610723
			11'd954: out = 32'b10000000000000000110101010010100; // input=3.728515625, output=-0.832648681459
			11'd955: out = 32'b10000000000000000110101001001101; // input=3.732421875, output=-0.830479047
			11'd956: out = 32'b10000000000000000110101000000110; // input=3.736328125, output=-0.828296740453
			11'd957: out = 32'b10000000000000000110100110111110; // input=3.740234375, output=-0.826101795117
			11'd958: out = 32'b10000000000000000110100101110101; // input=3.744140625, output=-0.823894244484
			11'd959: out = 32'b10000000000000000110100100101101; // input=3.748046875, output=-0.821674122238
			11'd960: out = 32'b10000000000000000110100011100011; // input=3.751953125, output=-0.819441462256
			11'd961: out = 32'b10000000000000000110100010011010; // input=3.755859375, output=-0.817196298606
			11'd962: out = 32'b10000000000000000110100001010000; // input=3.759765625, output=-0.814938665546
			11'd963: out = 32'b10000000000000000110100000000110; // input=3.763671875, output=-0.812668597524
			11'd964: out = 32'b10000000000000000110011110111011; // input=3.767578125, output=-0.810386129179
			11'd965: out = 32'b10000000000000000110011101110000; // input=3.771484375, output=-0.808091295339
			11'd966: out = 32'b10000000000000000110011100100100; // input=3.775390625, output=-0.80578413102
			11'd967: out = 32'b10000000000000000110011011011000; // input=3.779296875, output=-0.803464671426
			11'd968: out = 32'b10000000000000000110011010001100; // input=3.783203125, output=-0.801132951951
			11'd969: out = 32'b10000000000000000110011000111111; // input=3.787109375, output=-0.798789008172
			11'd970: out = 32'b10000000000000000110010111110010; // input=3.791015625, output=-0.796432875855
			11'd971: out = 32'b10000000000000000110010110100100; // input=3.794921875, output=-0.794064590953
			11'd972: out = 32'b10000000000000000110010101010110; // input=3.798828125, output=-0.791684189602
			11'd973: out = 32'b10000000000000000110010100001000; // input=3.802734375, output=-0.789291708124
			11'd974: out = 32'b10000000000000000110010010111001; // input=3.806640625, output=-0.786887183026
			11'd975: out = 32'b10000000000000000110010001101010; // input=3.810546875, output=-0.784470650998
			11'd976: out = 32'b10000000000000000110010000011010; // input=3.814453125, output=-0.782042148913
			11'd977: out = 32'b10000000000000000110001111001010; // input=3.818359375, output=-0.779601713826
			11'd978: out = 32'b10000000000000000110001101111010; // input=3.822265625, output=-0.777149382977
			11'd979: out = 32'b10000000000000000110001100101001; // input=3.826171875, output=-0.774685193784
			11'd980: out = 32'b10000000000000000110001011011000; // input=3.830078125, output=-0.772209183849
			11'd981: out = 32'b10000000000000000110001010000110; // input=3.833984375, output=-0.769721390951
			11'd982: out = 32'b10000000000000000110001000110100; // input=3.837890625, output=-0.767221853052
			11'd983: out = 32'b10000000000000000110000111100010; // input=3.841796875, output=-0.764710608291
			11'd984: out = 32'b10000000000000000110000110001111; // input=3.845703125, output=-0.762187694988
			11'd985: out = 32'b10000000000000000110000100111100; // input=3.849609375, output=-0.759653151638
			11'd986: out = 32'b10000000000000000110000011101001; // input=3.853515625, output=-0.757107016915
			11'd987: out = 32'b10000000000000000110000010010101; // input=3.857421875, output=-0.754549329671
			11'd988: out = 32'b10000000000000000110000001000001; // input=3.861328125, output=-0.751980128932
			11'd989: out = 32'b10000000000000000101111111101100; // input=3.865234375, output=-0.749399453902
			11'd990: out = 32'b10000000000000000101111110010111; // input=3.869140625, output=-0.746807343958
			11'd991: out = 32'b10000000000000000101111101000010; // input=3.873046875, output=-0.744203838653
			11'd992: out = 32'b10000000000000000101111011101100; // input=3.876953125, output=-0.741588977713
			11'd993: out = 32'b10000000000000000101111010010110; // input=3.880859375, output=-0.738962801038
			11'd994: out = 32'b10000000000000000101111001000000; // input=3.884765625, output=-0.736325348699
			11'd995: out = 32'b10000000000000000101110111101001; // input=3.888671875, output=-0.733676660942
			11'd996: out = 32'b10000000000000000101110110010010; // input=3.892578125, output=-0.731016778181
			11'd997: out = 32'b10000000000000000101110100111010; // input=3.896484375, output=-0.728345741004
			11'd998: out = 32'b10000000000000000101110011100011; // input=3.900390625, output=-0.725663590167
			11'd999: out = 32'b10000000000000000101110010001010; // input=3.904296875, output=-0.722970366596
			11'd1000: out = 32'b10000000000000000101110000110010; // input=3.908203125, output=-0.720266111387
			11'd1001: out = 32'b10000000000000000101101111011001; // input=3.912109375, output=-0.717550865803
			11'd1002: out = 32'b10000000000000000101101101111111; // input=3.916015625, output=-0.714824671276
			11'd1003: out = 32'b10000000000000000101101100100110; // input=3.919921875, output=-0.712087569404
			11'd1004: out = 32'b10000000000000000101101011001100; // input=3.923828125, output=-0.709339601952
			11'd1005: out = 32'b10000000000000000101101001110001; // input=3.927734375, output=-0.70658081085
			11'd1006: out = 32'b10000000000000000101101000010110; // input=3.931640625, output=-0.703811238194
			11'd1007: out = 32'b10000000000000000101100110111011; // input=3.935546875, output=-0.701030926245
			11'd1008: out = 32'b10000000000000000101100101100000; // input=3.939453125, output=-0.698239917426
			11'd1009: out = 32'b10000000000000000101100100000100; // input=3.943359375, output=-0.695438254325
			11'd1010: out = 32'b10000000000000000101100010101000; // input=3.947265625, output=-0.692625979692
			11'd1011: out = 32'b10000000000000000101100001001011; // input=3.951171875, output=-0.689803136439
			11'd1012: out = 32'b10000000000000000101011111101111; // input=3.955078125, output=-0.686969767639
			11'd1013: out = 32'b10000000000000000101011110010001; // input=3.958984375, output=-0.684125916525
			11'd1014: out = 32'b10000000000000000101011100110100; // input=3.962890625, output=-0.681271626491
			11'd1015: out = 32'b10000000000000000101011011010110; // input=3.966796875, output=-0.678406941091
			11'd1016: out = 32'b10000000000000000101011001111000; // input=3.970703125, output=-0.675531904035
			11'd1017: out = 32'b10000000000000000101011000011001; // input=3.974609375, output=-0.672646559194
			11'd1018: out = 32'b10000000000000000101010110111010; // input=3.978515625, output=-0.669750950593
			11'd1019: out = 32'b10000000000000000101010101011011; // input=3.982421875, output=-0.666845122418
			11'd1020: out = 32'b10000000000000000101010011111100; // input=3.986328125, output=-0.663929119006
			11'd1021: out = 32'b10000000000000000101010010011100; // input=3.990234375, output=-0.661002984852
			11'd1022: out = 32'b10000000000000000101010000111100; // input=3.994140625, output=-0.658066764607
			11'd1023: out = 32'b10000000000000000101001111011011; // input=3.998046875, output=-0.655120503072
			11'd1024: out = 32'b00000000000000000111111111111111; // input=-0.001953125, output=0.999998092652
			11'd1025: out = 32'b00000000000000000111111111111111; // input=-0.005859375, output=0.999982833911
			11'd1026: out = 32'b00000000000000000111111111111110; // input=-0.009765625, output=0.999952316663
			11'd1027: out = 32'b00000000000000000111111111111101; // input=-0.013671875, output=0.999906541373
			11'd1028: out = 32'b00000000000000000111111111111011; // input=-0.017578125, output=0.999845508739
			11'd1029: out = 32'b00000000000000000111111111111000; // input=-0.021484375, output=0.999769219693
			11'd1030: out = 32'b00000000000000000111111111110101; // input=-0.025390625, output=0.999677675398
			11'd1031: out = 32'b00000000000000000111111111110010; // input=-0.029296875, output=0.999570877252
			11'd1032: out = 32'b00000000000000000111111111101110; // input=-0.033203125, output=0.999448826885
			11'd1033: out = 32'b00000000000000000111111111101001; // input=-0.037109375, output=0.999311526157
			11'd1034: out = 32'b00000000000000000111111111100100; // input=-0.041015625, output=0.999158977166
			11'd1035: out = 32'b00000000000000000111111111011111; // input=-0.044921875, output=0.998991182238
			11'd1036: out = 32'b00000000000000000111111111011001; // input=-0.048828125, output=0.998808143933
			11'd1037: out = 32'b00000000000000000111111111010010; // input=-0.052734375, output=0.998609865045
			11'd1038: out = 32'b00000000000000000111111111001011; // input=-0.056640625, output=0.998396348599
			11'd1039: out = 32'b00000000000000000111111111000100; // input=-0.060546875, output=0.998167597854
			11'd1040: out = 32'b00000000000000000111111110111100; // input=-0.064453125, output=0.997923616299
			11'd1041: out = 32'b00000000000000000111111110110011; // input=-0.068359375, output=0.997664407657
			11'd1042: out = 32'b00000000000000000111111110101010; // input=-0.072265625, output=0.997389975884
			11'd1043: out = 32'b00000000000000000111111110100001; // input=-0.076171875, output=0.997100325166
			11'd1044: out = 32'b00000000000000000111111110010111; // input=-0.080078125, output=0.996795459925
			11'd1045: out = 32'b00000000000000000111111110001101; // input=-0.083984375, output=0.996475384812
			11'd1046: out = 32'b00000000000000000111111110000010; // input=-0.087890625, output=0.99614010471
			11'd1047: out = 32'b00000000000000000111111101110110; // input=-0.091796875, output=0.995789624735
			11'd1048: out = 32'b00000000000000000111111101101010; // input=-0.095703125, output=0.995423950236
			11'd1049: out = 32'b00000000000000000111111101011110; // input=-0.099609375, output=0.995043086793
			11'd1050: out = 32'b00000000000000000111111101010001; // input=-0.103515625, output=0.994647040216
			11'd1051: out = 32'b00000000000000000111111101000011; // input=-0.107421875, output=0.994235816549
			11'd1052: out = 32'b00000000000000000111111100110101; // input=-0.111328125, output=0.993809422066
			11'd1053: out = 32'b00000000000000000111111100100111; // input=-0.115234375, output=0.993367863275
			11'd1054: out = 32'b00000000000000000111111100011000; // input=-0.119140625, output=0.992911146912
			11'd1055: out = 32'b00000000000000000111111100001000; // input=-0.123046875, output=0.992439279947
			11'd1056: out = 32'b00000000000000000111111011111000; // input=-0.126953125, output=0.991952269579
			11'd1057: out = 32'b00000000000000000111111011101000; // input=-0.130859375, output=0.99145012324
			11'd1058: out = 32'b00000000000000000111111011010111; // input=-0.134765625, output=0.990932848592
			11'd1059: out = 32'b00000000000000000111111011000101; // input=-0.138671875, output=0.990400453528
			11'd1060: out = 32'b00000000000000000111111010110100; // input=-0.142578125, output=0.989852946172
			11'd1061: out = 32'b00000000000000000111111010100001; // input=-0.146484375, output=0.989290334878
			11'd1062: out = 32'b00000000000000000111111010001110; // input=-0.150390625, output=0.98871262823
			11'd1063: out = 32'b00000000000000000111111001111011; // input=-0.154296875, output=0.988119835044
			11'd1064: out = 32'b00000000000000000111111001100111; // input=-0.158203125, output=0.987511964365
			11'd1065: out = 32'b00000000000000000111111001010010; // input=-0.162109375, output=0.986889025468
			11'd1066: out = 32'b00000000000000000111111000111101; // input=-0.166015625, output=0.986251027859
			11'd1067: out = 32'b00000000000000000111111000101000; // input=-0.169921875, output=0.985597981273
			11'd1068: out = 32'b00000000000000000111111000010010; // input=-0.173828125, output=0.984929895674
			11'd1069: out = 32'b00000000000000000111110111111100; // input=-0.177734375, output=0.984246781257
			11'd1070: out = 32'b00000000000000000111110111100101; // input=-0.181640625, output=0.983548648445
			11'd1071: out = 32'b00000000000000000111110111001110; // input=-0.185546875, output=0.98283550789
			11'd1072: out = 32'b00000000000000000111110110110110; // input=-0.189453125, output=0.982107370475
			11'd1073: out = 32'b00000000000000000111110110011101; // input=-0.193359375, output=0.98136424731
			11'd1074: out = 32'b00000000000000000111110110000101; // input=-0.197265625, output=0.980606149734
			11'd1075: out = 32'b00000000000000000111110101101011; // input=-0.201171875, output=0.979833089314
			11'd1076: out = 32'b00000000000000000111110101010001; // input=-0.205078125, output=0.979045077847
			11'd1077: out = 32'b00000000000000000111110100110111; // input=-0.208984375, output=0.978242127357
			11'd1078: out = 32'b00000000000000000111110100011100; // input=-0.212890625, output=0.977424250095
			11'd1079: out = 32'b00000000000000000111110100000001; // input=-0.216796875, output=0.976591458542
			11'd1080: out = 32'b00000000000000000111110011100101; // input=-0.220703125, output=0.975743765405
			11'd1081: out = 32'b00000000000000000111110011001001; // input=-0.224609375, output=0.974881183619
			11'd1082: out = 32'b00000000000000000111110010101100; // input=-0.228515625, output=0.974003726345
			11'd1083: out = 32'b00000000000000000111110010001111; // input=-0.232421875, output=0.973111406972
			11'd1084: out = 32'b00000000000000000111110001110001; // input=-0.236328125, output=0.972204239117
			11'd1085: out = 32'b00000000000000000111110001010011; // input=-0.240234375, output=0.971282236621
			11'd1086: out = 32'b00000000000000000111110000110100; // input=-0.244140625, output=0.970345413553
			11'd1087: out = 32'b00000000000000000111110000010101; // input=-0.248046875, output=0.969393784208
			11'd1088: out = 32'b00000000000000000111101111110101; // input=-0.251953125, output=0.968427363107
			11'd1089: out = 32'b00000000000000000111101111010101; // input=-0.255859375, output=0.967446164995
			11'd1090: out = 32'b00000000000000000111101110110101; // input=-0.259765625, output=0.966450204846
			11'd1091: out = 32'b00000000000000000111101110010100; // input=-0.263671875, output=0.965439497855
			11'd1092: out = 32'b00000000000000000111101101110010; // input=-0.267578125, output=0.964414059445
			11'd1093: out = 32'b00000000000000000111101101010000; // input=-0.271484375, output=0.963373905264
			11'd1094: out = 32'b00000000000000000111101100101101; // input=-0.275390625, output=0.962319051181
			11'd1095: out = 32'b00000000000000000111101100001010; // input=-0.279296875, output=0.961249513295
			11'd1096: out = 32'b00000000000000000111101011100111; // input=-0.283203125, output=0.960165307923
			11'd1097: out = 32'b00000000000000000111101011000011; // input=-0.287109375, output=0.95906645161
			11'd1098: out = 32'b00000000000000000111101010011110; // input=-0.291015625, output=0.957952961123
			11'd1099: out = 32'b00000000000000000111101001111001; // input=-0.294921875, output=0.956824853452
			11'd1100: out = 32'b00000000000000000111101001010100; // input=-0.298828125, output=0.955682145811
			11'd1101: out = 32'b00000000000000000111101000101110; // input=-0.302734375, output=0.954524855637
			11'd1102: out = 32'b00000000000000000111101000000111; // input=-0.306640625, output=0.953353000587
			11'd1103: out = 32'b00000000000000000111100111100001; // input=-0.310546875, output=0.952166598544
			11'd1104: out = 32'b00000000000000000111100110111001; // input=-0.314453125, output=0.95096566761
			11'd1105: out = 32'b00000000000000000111100110010001; // input=-0.318359375, output=0.94975022611
			11'd1106: out = 32'b00000000000000000111100101101001; // input=-0.322265625, output=0.94852029259
			11'd1107: out = 32'b00000000000000000111100101000000; // input=-0.326171875, output=0.947275885817
			11'd1108: out = 32'b00000000000000000111100100010111; // input=-0.330078125, output=0.94601702478
			11'd1109: out = 32'b00000000000000000111100011101101; // input=-0.333984375, output=0.944743728687
			11'd1110: out = 32'b00000000000000000111100011000011; // input=-0.337890625, output=0.943456016966
			11'd1111: out = 32'b00000000000000000111100010011000; // input=-0.341796875, output=0.942153909268
			11'd1112: out = 32'b00000000000000000111100001101101; // input=-0.345703125, output=0.940837425461
			11'd1113: out = 32'b00000000000000000111100001000010; // input=-0.349609375, output=0.939506585632
			11'd1114: out = 32'b00000000000000000111100000010110; // input=-0.353515625, output=0.938161410088
			11'd1115: out = 32'b00000000000000000111011111101001; // input=-0.357421875, output=0.936801919355
			11'd1116: out = 32'b00000000000000000111011110111100; // input=-0.361328125, output=0.935428134178
			11'd1117: out = 32'b00000000000000000111011110001111; // input=-0.365234375, output=0.934040075518
			11'd1118: out = 32'b00000000000000000111011101100001; // input=-0.369140625, output=0.932637764556
			11'd1119: out = 32'b00000000000000000111011100110010; // input=-0.373046875, output=0.931221222689
			11'd1120: out = 32'b00000000000000000111011100000011; // input=-0.376953125, output=0.929790471532
			11'd1121: out = 32'b00000000000000000111011011010100; // input=-0.380859375, output=0.928345532916
			11'd1122: out = 32'b00000000000000000111011010100100; // input=-0.384765625, output=0.92688642889
			11'd1123: out = 32'b00000000000000000111011001110100; // input=-0.388671875, output=0.925413181717
			11'd1124: out = 32'b00000000000000000111011001000011; // input=-0.392578125, output=0.923925813877
			11'd1125: out = 32'b00000000000000000111011000010010; // input=-0.396484375, output=0.922424348067
			11'd1126: out = 32'b00000000000000000111010111100000; // input=-0.400390625, output=0.920908807195
			11'd1127: out = 32'b00000000000000000111010110101110; // input=-0.404296875, output=0.919379214389
			11'd1128: out = 32'b00000000000000000111010101111100; // input=-0.408203125, output=0.917835592986
			11'd1129: out = 32'b00000000000000000111010101001001; // input=-0.412109375, output=0.916277966542
			11'd1130: out = 32'b00000000000000000111010100010101; // input=-0.416015625, output=0.914706358823
			11'd1131: out = 32'b00000000000000000111010011100001; // input=-0.419921875, output=0.913120793811
			11'd1132: out = 32'b00000000000000000111010010101101; // input=-0.423828125, output=0.911521295699
			11'd1133: out = 32'b00000000000000000111010001111000; // input=-0.427734375, output=0.909907888893
			11'd1134: out = 32'b00000000000000000111010001000011; // input=-0.431640625, output=0.908280598013
			11'd1135: out = 32'b00000000000000000111010000001101; // input=-0.435546875, output=0.906639447888
			11'd1136: out = 32'b00000000000000000111001111010111; // input=-0.439453125, output=0.90498446356
			11'd1137: out = 32'b00000000000000000111001110100000; // input=-0.443359375, output=0.903315670283
			11'd1138: out = 32'b00000000000000000111001101101001; // input=-0.447265625, output=0.901633093521
			11'd1139: out = 32'b00000000000000000111001100110001; // input=-0.451171875, output=0.899936758946
			11'd1140: out = 32'b00000000000000000111001011111001; // input=-0.455078125, output=0.898226692444
			11'd1141: out = 32'b00000000000000000111001011000001; // input=-0.458984375, output=0.896502920108
			11'd1142: out = 32'b00000000000000000111001010001000; // input=-0.462890625, output=0.89476546824
			11'd1143: out = 32'b00000000000000000111001001001110; // input=-0.466796875, output=0.893014363352
			11'd1144: out = 32'b00000000000000000111001000010100; // input=-0.470703125, output=0.891249632163
			11'd1145: out = 32'b00000000000000000111000111011010; // input=-0.474609375, output=0.889471301602
			11'd1146: out = 32'b00000000000000000111000110011111; // input=-0.478515625, output=0.887679398803
			11'd1147: out = 32'b00000000000000000111000101100100; // input=-0.482421875, output=0.885873951108
			11'd1148: out = 32'b00000000000000000111000100101001; // input=-0.486328125, output=0.884054986067
			11'd1149: out = 32'b00000000000000000111000011101101; // input=-0.490234375, output=0.882222531435
			11'd1150: out = 32'b00000000000000000111000010110000; // input=-0.494140625, output=0.880376615172
			11'd1151: out = 32'b00000000000000000111000001110011; // input=-0.498046875, output=0.878517265445
			11'd1152: out = 32'b00000000000000000111000000110110; // input=-0.501953125, output=0.876644510625
			11'd1153: out = 32'b00000000000000000110111111111000; // input=-0.505859375, output=0.874758379289
			11'd1154: out = 32'b00000000000000000110111110111010; // input=-0.509765625, output=0.872858900216
			11'd1155: out = 32'b00000000000000000110111101111011; // input=-0.513671875, output=0.870946102391
			11'd1156: out = 32'b00000000000000000110111100111100; // input=-0.517578125, output=0.869020014999
			11'd1157: out = 32'b00000000000000000110111011111100; // input=-0.521484375, output=0.867080667431
			11'd1158: out = 32'b00000000000000000110111010111101; // input=-0.525390625, output=0.865128089279
			11'd1159: out = 32'b00000000000000000110111001111100; // input=-0.529296875, output=0.863162310337
			11'd1160: out = 32'b00000000000000000110111000111011; // input=-0.533203125, output=0.861183360599
			11'd1161: out = 32'b00000000000000000110110111111010; // input=-0.537109375, output=0.859191270264
			11'd1162: out = 32'b00000000000000000110110110111000; // input=-0.541015625, output=0.857186069726
			11'd1163: out = 32'b00000000000000000110110101110110; // input=-0.544921875, output=0.855167789584
			11'd1164: out = 32'b00000000000000000110110100110100; // input=-0.548828125, output=0.853136460634
			11'd1165: out = 32'b00000000000000000110110011110001; // input=-0.552734375, output=0.85109211387
			11'd1166: out = 32'b00000000000000000110110010101101; // input=-0.556640625, output=0.849034780489
			11'd1167: out = 32'b00000000000000000110110001101001; // input=-0.560546875, output=0.846964491881
			11'd1168: out = 32'b00000000000000000110110000100101; // input=-0.564453125, output=0.844881279637
			11'd1169: out = 32'b00000000000000000110101111100000; // input=-0.568359375, output=0.842785175544
			11'd1170: out = 32'b00000000000000000110101110011011; // input=-0.572265625, output=0.840676211586
			11'd1171: out = 32'b00000000000000000110101101010110; // input=-0.576171875, output=0.838554419944
			11'd1172: out = 32'b00000000000000000110101100010000; // input=-0.580078125, output=0.836419832992
			11'd1173: out = 32'b00000000000000000110101011001001; // input=-0.583984375, output=0.834272483304
			11'd1174: out = 32'b00000000000000000110101010000011; // input=-0.587890625, output=0.832112403643
			11'd1175: out = 32'b00000000000000000110101000111011; // input=-0.591796875, output=0.829939626972
			11'd1176: out = 32'b00000000000000000110100111110100; // input=-0.595703125, output=0.827754186442
			11'd1177: out = 32'b00000000000000000110100110101100; // input=-0.599609375, output=0.825556115402
			11'd1178: out = 32'b00000000000000000110100101100011; // input=-0.603515625, output=0.823345447392
			11'd1179: out = 32'b00000000000000000110100100011011; // input=-0.607421875, output=0.821122216143
			11'd1180: out = 32'b00000000000000000110100011010001; // input=-0.611328125, output=0.818886455579
			11'd1181: out = 32'b00000000000000000110100010001000; // input=-0.615234375, output=0.816638199815
			11'd1182: out = 32'b00000000000000000110100000111110; // input=-0.619140625, output=0.814377483157
			11'd1183: out = 32'b00000000000000000110011111110011; // input=-0.623046875, output=0.812104340101
			11'd1184: out = 32'b00000000000000000110011110101000; // input=-0.626953125, output=0.809818805332
			11'd1185: out = 32'b00000000000000000110011101011101; // input=-0.630859375, output=0.807520913724
			11'd1186: out = 32'b00000000000000000110011100010001; // input=-0.634765625, output=0.80521070034
			11'd1187: out = 32'b00000000000000000110011011000101; // input=-0.638671875, output=0.802888200432
			11'd1188: out = 32'b00000000000000000110011001111001; // input=-0.642578125, output=0.800553449438
			11'd1189: out = 32'b00000000000000000110011000101100; // input=-0.646484375, output=0.798206482983
			11'd1190: out = 32'b00000000000000000110010111011110; // input=-0.650390625, output=0.795847336879
			11'd1191: out = 32'b00000000000000000110010110010001; // input=-0.654296875, output=0.793476047124
			11'd1192: out = 32'b00000000000000000110010101000011; // input=-0.658203125, output=0.791092649901
			11'd1193: out = 32'b00000000000000000110010011110100; // input=-0.662109375, output=0.788697181577
			11'd1194: out = 32'b00000000000000000110010010100101; // input=-0.666015625, output=0.786289678704
			11'd1195: out = 32'b00000000000000000110010001010110; // input=-0.669921875, output=0.783870178019
			11'd1196: out = 32'b00000000000000000110010000000110; // input=-0.673828125, output=0.781438716439
			11'd1197: out = 32'b00000000000000000110001110110110; // input=-0.677734375, output=0.778995331066
			11'd1198: out = 32'b00000000000000000110001101100110; // input=-0.681640625, output=0.776540059182
			11'd1199: out = 32'b00000000000000000110001100010101; // input=-0.685546875, output=0.774072938252
			11'd1200: out = 32'b00000000000000000110001011000100; // input=-0.689453125, output=0.771594005922
			11'd1201: out = 32'b00000000000000000110001001110010; // input=-0.693359375, output=0.769103300017
			11'd1202: out = 32'b00000000000000000110001000100000; // input=-0.697265625, output=0.766600858541
			11'd1203: out = 32'b00000000000000000110000111001110; // input=-0.701171875, output=0.76408671968
			11'd1204: out = 32'b00000000000000000110000101111011; // input=-0.705078125, output=0.761560921795
			11'd1205: out = 32'b00000000000000000110000100101000; // input=-0.708984375, output=0.759023503428
			11'd1206: out = 32'b00000000000000000110000011010100; // input=-0.712890625, output=0.756474503295
			11'd1207: out = 32'b00000000000000000110000010000000; // input=-0.716796875, output=0.753913960293
			11'd1208: out = 32'b00000000000000000110000000101100; // input=-0.720703125, output=0.751341913491
			11'd1209: out = 32'b00000000000000000101111111010111; // input=-0.724609375, output=0.748758402136
			11'd1210: out = 32'b00000000000000000101111110000010; // input=-0.728515625, output=0.746163465649
			11'd1211: out = 32'b00000000000000000101111100101101; // input=-0.732421875, output=0.743557143625
			11'd1212: out = 32'b00000000000000000101111011010111; // input=-0.736328125, output=0.740939475835
			11'd1213: out = 32'b00000000000000000101111010000001; // input=-0.740234375, output=0.738310502219
			11'd1214: out = 32'b00000000000000000101111000101010; // input=-0.744140625, output=0.735670262894
			11'd1215: out = 32'b00000000000000000101110111010100; // input=-0.748046875, output=0.733018798145
			11'd1216: out = 32'b00000000000000000101110101111100; // input=-0.751953125, output=0.730356148432
			11'd1217: out = 32'b00000000000000000101110100100101; // input=-0.755859375, output=0.727682354382
			11'd1218: out = 32'b00000000000000000101110011001101; // input=-0.759765625, output=0.724997456795
			11'd1219: out = 32'b00000000000000000101110001110100; // input=-0.763671875, output=0.722301496639
			11'd1220: out = 32'b00000000000000000101110000011100; // input=-0.767578125, output=0.71959451505
			11'd1221: out = 32'b00000000000000000101101111000011; // input=-0.771484375, output=0.716876553335
			11'd1222: out = 32'b00000000000000000101101101101001; // input=-0.775390625, output=0.714147652965
			11'd1223: out = 32'b00000000000000000101101100001111; // input=-0.779296875, output=0.711407855581
			11'd1224: out = 32'b00000000000000000101101010110101; // input=-0.783203125, output=0.708657202988
			11'd1225: out = 32'b00000000000000000101101001011011; // input=-0.787109375, output=0.705895737158
			11'd1226: out = 32'b00000000000000000101101000000000; // input=-0.791015625, output=0.703123500228
			11'd1227: out = 32'b00000000000000000101100110100101; // input=-0.794921875, output=0.700340534498
			11'd1228: out = 32'b00000000000000000101100101001001; // input=-0.798828125, output=0.697546882433
			11'd1229: out = 32'b00000000000000000101100011101101; // input=-0.802734375, output=0.694742586661
			11'd1230: out = 32'b00000000000000000101100010010001; // input=-0.806640625, output=0.691927689972
			11'd1231: out = 32'b00000000000000000101100000110101; // input=-0.810546875, output=0.689102235318
			11'd1232: out = 32'b00000000000000000101011111011000; // input=-0.814453125, output=0.686266265812
			11'd1233: out = 32'b00000000000000000101011101111010; // input=-0.818359375, output=0.683419824726
			11'd1234: out = 32'b00000000000000000101011100011101; // input=-0.822265625, output=0.680562955495
			11'd1235: out = 32'b00000000000000000101011010111111; // input=-0.826171875, output=0.677695701711
			11'd1236: out = 32'b00000000000000000101011001100000; // input=-0.830078125, output=0.674818107123
			11'd1237: out = 32'b00000000000000000101011000000010; // input=-0.833984375, output=0.671930215642
			11'd1238: out = 32'b00000000000000000101010110100011; // input=-0.837890625, output=0.669032071333
			11'd1239: out = 32'b00000000000000000101010101000100; // input=-0.841796875, output=0.666123718417
			11'd1240: out = 32'b00000000000000000101010011100100; // input=-0.845703125, output=0.663205201273
			11'd1241: out = 32'b00000000000000000101010010000100; // input=-0.849609375, output=0.660276564433
			11'd1242: out = 32'b00000000000000000101010000100100; // input=-0.853515625, output=0.657337852585
			11'd1243: out = 32'b00000000000000000101001111000011; // input=-0.857421875, output=0.654389110571
			11'd1244: out = 32'b00000000000000000101001101100010; // input=-0.861328125, output=0.651430383384
			11'd1245: out = 32'b00000000000000000101001100000001; // input=-0.865234375, output=0.64846171617
			11'd1246: out = 32'b00000000000000000101001010011111; // input=-0.869140625, output=0.645483154229
			11'd1247: out = 32'b00000000000000000101001000111101; // input=-0.873046875, output=0.642494743009
			11'd1248: out = 32'b00000000000000000101000111011011; // input=-0.876953125, output=0.63949652811
			11'd1249: out = 32'b00000000000000000101000101111000; // input=-0.880859375, output=0.63648855528
			11'd1250: out = 32'b00000000000000000101000100010110; // input=-0.884765625, output=0.633470870418
			11'd1251: out = 32'b00000000000000000101000010110010; // input=-0.888671875, output=0.63044351957
			11'd1252: out = 32'b00000000000000000101000001001111; // input=-0.892578125, output=0.62740654893
			11'd1253: out = 32'b00000000000000000100111111101011; // input=-0.896484375, output=0.624360004837
			11'd1254: out = 32'b00000000000000000100111110000111; // input=-0.900390625, output=0.621303933779
			11'd1255: out = 32'b00000000000000000100111100100010; // input=-0.904296875, output=0.618238382388
			11'd1256: out = 32'b00000000000000000100111010111110; // input=-0.908203125, output=0.615163397439
			11'd1257: out = 32'b00000000000000000100111001011001; // input=-0.912109375, output=0.612079025854
			11'd1258: out = 32'b00000000000000000100110111110011; // input=-0.916015625, output=0.608985314696
			11'd1259: out = 32'b00000000000000000100110110001110; // input=-0.919921875, output=0.605882311171
			11'd1260: out = 32'b00000000000000000100110100101000; // input=-0.923828125, output=0.602770062628
			11'd1261: out = 32'b00000000000000000100110011000001; // input=-0.927734375, output=0.599648616555
			11'd1262: out = 32'b00000000000000000100110001011011; // input=-0.931640625, output=0.596518020582
			11'd1263: out = 32'b00000000000000000100101111110100; // input=-0.935546875, output=0.593378322478
			11'd1264: out = 32'b00000000000000000100101110001101; // input=-0.939453125, output=0.590229570151
			11'd1265: out = 32'b00000000000000000100101100100101; // input=-0.943359375, output=0.587071811646
			11'd1266: out = 32'b00000000000000000100101010111101; // input=-0.947265625, output=0.583905095149
			11'd1267: out = 32'b00000000000000000100101001010101; // input=-0.951171875, output=0.580729468977
			11'd1268: out = 32'b00000000000000000100100111101101; // input=-0.955078125, output=0.577544981589
			11'd1269: out = 32'b00000000000000000100100110000100; // input=-0.958984375, output=0.574351681575
			11'd1270: out = 32'b00000000000000000100100100011011; // input=-0.962890625, output=0.571149617661
			11'd1271: out = 32'b00000000000000000100100010110010; // input=-0.966796875, output=0.567938838706
			11'd1272: out = 32'b00000000000000000100100001001001; // input=-0.970703125, output=0.564719393703
			11'd1273: out = 32'b00000000000000000100011111011111; // input=-0.974609375, output=0.561491331777
			11'd1274: out = 32'b00000000000000000100011101110101; // input=-0.978515625, output=0.558254702185
			11'd1275: out = 32'b00000000000000000100011100001011; // input=-0.982421875, output=0.555009554312
			11'd1276: out = 32'b00000000000000000100011010100000; // input=-0.986328125, output=0.551755937677
			11'd1277: out = 32'b00000000000000000100011000110101; // input=-0.990234375, output=0.548493901924
			11'd1278: out = 32'b00000000000000000100010111001010; // input=-0.994140625, output=0.54522349683
			11'd1279: out = 32'b00000000000000000100010101011110; // input=-0.998046875, output=0.541944772296
			11'd1280: out = 32'b00000000000000000100010011110011; // input=-1.001953125, output=0.538657778351
			11'd1281: out = 32'b00000000000000000100010010000111; // input=-1.005859375, output=0.535362565152
			11'd1282: out = 32'b00000000000000000100010000011011; // input=-1.009765625, output=0.532059182978
			11'd1283: out = 32'b00000000000000000100001110101110; // input=-1.013671875, output=0.528747682236
			11'd1284: out = 32'b00000000000000000100001101000001; // input=-1.017578125, output=0.525428113455
			11'd1285: out = 32'b00000000000000000100001011010100; // input=-1.021484375, output=0.522100527287
			11'd1286: out = 32'b00000000000000000100001001100111; // input=-1.025390625, output=0.518764974507
			11'd1287: out = 32'b00000000000000000100000111111001; // input=-1.029296875, output=0.515421506013
			11'd1288: out = 32'b00000000000000000100000110001100; // input=-1.033203125, output=0.51207017282
			11'd1289: out = 32'b00000000000000000100000100011101; // input=-1.037109375, output=0.508711026066
			11'd1290: out = 32'b00000000000000000100000010101111; // input=-1.041015625, output=0.505344117008
			11'd1291: out = 32'b00000000000000000100000001000001; // input=-1.044921875, output=0.501969497021
			11'd1292: out = 32'b00000000000000000011111111010010; // input=-1.048828125, output=0.498587217597
			11'd1293: out = 32'b00000000000000000011111101100011; // input=-1.052734375, output=0.495197330345
			11'd1294: out = 32'b00000000000000000011111011110011; // input=-1.056640625, output=0.491799886991
			11'd1295: out = 32'b00000000000000000011111010000100; // input=-1.060546875, output=0.488394939376
			11'd1296: out = 32'b00000000000000000011111000010100; // input=-1.064453125, output=0.484982539455
			11'd1297: out = 32'b00000000000000000011110110100100; // input=-1.068359375, output=0.481562739297
			11'd1298: out = 32'b00000000000000000011110100110100; // input=-1.072265625, output=0.478135591084
			11'd1299: out = 32'b00000000000000000011110011000011; // input=-1.076171875, output=0.474701147111
			11'd1300: out = 32'b00000000000000000011110001010010; // input=-1.080078125, output=0.471259459782
			11'd1301: out = 32'b00000000000000000011101111100001; // input=-1.083984375, output=0.467810581613
			11'd1302: out = 32'b00000000000000000011101101110000; // input=-1.087890625, output=0.464354565231
			11'd1303: out = 32'b00000000000000000011101011111110; // input=-1.091796875, output=0.460891463369
			11'd1304: out = 32'b00000000000000000011101010001101; // input=-1.095703125, output=0.45742132887
			11'd1305: out = 32'b00000000000000000011101000011011; // input=-1.099609375, output=0.453944214685
			11'd1306: out = 32'b00000000000000000011100110101001; // input=-1.103515625, output=0.45046017387
			11'd1307: out = 32'b00000000000000000011100100110110; // input=-1.107421875, output=0.446969259586
			11'd1308: out = 32'b00000000000000000011100011000100; // input=-1.111328125, output=0.443471525102
			11'd1309: out = 32'b00000000000000000011100001010001; // input=-1.115234375, output=0.439967023787
			11'd1310: out = 32'b00000000000000000011011111011110; // input=-1.119140625, output=0.436455809118
			11'd1311: out = 32'b00000000000000000011011101101011; // input=-1.123046875, output=0.432937934669
			11'd1312: out = 32'b00000000000000000011011011110111; // input=-1.126953125, output=0.429413454121
			11'd1313: out = 32'b00000000000000000011011010000011; // input=-1.130859375, output=0.425882421251
			11'd1314: out = 32'b00000000000000000011011000001111; // input=-1.134765625, output=0.42234488994
			11'd1315: out = 32'b00000000000000000011010110011011; // input=-1.138671875, output=0.418800914165
			11'd1316: out = 32'b00000000000000000011010100100111; // input=-1.142578125, output=0.415250548003
			11'd1317: out = 32'b00000000000000000011010010110010; // input=-1.146484375, output=0.411693845629
			11'd1318: out = 32'b00000000000000000011010000111110; // input=-1.150390625, output=0.408130861314
			11'd1319: out = 32'b00000000000000000011001111001001; // input=-1.154296875, output=0.404561649424
			11'd1320: out = 32'b00000000000000000011001101010100; // input=-1.158203125, output=0.40098626442
			11'd1321: out = 32'b00000000000000000011001011011110; // input=-1.162109375, output=0.39740476086
			11'd1322: out = 32'b00000000000000000011001001101001; // input=-1.166015625, output=0.393817193392
			11'd1323: out = 32'b00000000000000000011000111110011; // input=-1.169921875, output=0.390223616758
			11'd1324: out = 32'b00000000000000000011000101111101; // input=-1.173828125, output=0.386624085792
			11'd1325: out = 32'b00000000000000000011000100000111; // input=-1.177734375, output=0.383018655418
			11'd1326: out = 32'b00000000000000000011000010010000; // input=-1.181640625, output=0.37940738065
			11'd1327: out = 32'b00000000000000000011000000011010; // input=-1.185546875, output=0.375790316593
			11'd1328: out = 32'b00000000000000000010111110100011; // input=-1.189453125, output=0.372167518438
			11'd1329: out = 32'b00000000000000000010111100101100; // input=-1.193359375, output=0.368539041464
			11'd1330: out = 32'b00000000000000000010111010110101; // input=-1.197265625, output=0.364904941038
			11'd1331: out = 32'b00000000000000000010111000111110; // input=-1.201171875, output=0.361265272612
			11'd1332: out = 32'b00000000000000000010110111000110; // input=-1.205078125, output=0.357620091721
			11'd1333: out = 32'b00000000000000000010110101001111; // input=-1.208984375, output=0.353969453989
			11'd1334: out = 32'b00000000000000000010110011010111; // input=-1.212890625, output=0.350313415118
			11'd1335: out = 32'b00000000000000000010110001011111; // input=-1.216796875, output=0.346652030895
			11'd1336: out = 32'b00000000000000000010101111100111; // input=-1.220703125, output=0.342985357189
			11'd1337: out = 32'b00000000000000000010101101101111; // input=-1.224609375, output=0.339313449948
			11'd1338: out = 32'b00000000000000000010101011110110; // input=-1.228515625, output=0.335636365202
			11'd1339: out = 32'b00000000000000000010101001111101; // input=-1.232421875, output=0.331954159057
			11'd1340: out = 32'b00000000000000000010101000000101; // input=-1.236328125, output=0.328266887701
			11'd1341: out = 32'b00000000000000000010100110001100; // input=-1.240234375, output=0.324574607395
			11'd1342: out = 32'b00000000000000000010100100010011; // input=-1.244140625, output=0.320877374481
			11'd1343: out = 32'b00000000000000000010100010011001; // input=-1.248046875, output=0.317175245372
			11'd1344: out = 32'b00000000000000000010100000100000; // input=-1.251953125, output=0.31346827656
			11'd1345: out = 32'b00000000000000000010011110100110; // input=-1.255859375, output=0.309756524607
			11'd1346: out = 32'b00000000000000000010011100101100; // input=-1.259765625, output=0.306040046151
			11'd1347: out = 32'b00000000000000000010011010110010; // input=-1.263671875, output=0.3023188979
			11'd1348: out = 32'b00000000000000000010011000111000; // input=-1.267578125, output=0.298593136635
			11'd1349: out = 32'b00000000000000000010010110111110; // input=-1.271484375, output=0.294862819205
			11'd1350: out = 32'b00000000000000000010010101000100; // input=-1.275390625, output=0.291128002532
			11'd1351: out = 32'b00000000000000000010010011001001; // input=-1.279296875, output=0.287388743604
			11'd1352: out = 32'b00000000000000000010010001001110; // input=-1.283203125, output=0.283645099478
			11'd1353: out = 32'b00000000000000000010001111010100; // input=-1.287109375, output=0.279897127276
			11'd1354: out = 32'b00000000000000000010001101011001; // input=-1.291015625, output=0.276144884188
			11'd1355: out = 32'b00000000000000000010001011011110; // input=-1.294921875, output=0.272388427469
			11'd1356: out = 32'b00000000000000000010001001100010; // input=-1.298828125, output=0.268627814438
			11'd1357: out = 32'b00000000000000000010000111100111; // input=-1.302734375, output=0.264863102477
			11'd1358: out = 32'b00000000000000000010000101101100; // input=-1.306640625, output=0.26109434903
			11'd1359: out = 32'b00000000000000000010000011110000; // input=-1.310546875, output=0.257321611606
			11'd1360: out = 32'b00000000000000000010000001110100; // input=-1.314453125, output=0.25354494777
			11'd1361: out = 32'b00000000000000000001111111111000; // input=-1.318359375, output=0.24976441515
			11'd1362: out = 32'b00000000000000000001111101111100; // input=-1.322265625, output=0.245980071432
			11'd1363: out = 32'b00000000000000000001111100000000; // input=-1.326171875, output=0.242191974361
			11'd1364: out = 32'b00000000000000000001111010000100; // input=-1.330078125, output=0.238400181739
			11'd1365: out = 32'b00000000000000000001111000001000; // input=-1.333984375, output=0.234604751423
			11'd1366: out = 32'b00000000000000000001110110001011; // input=-1.337890625, output=0.230805741327
			11'd1367: out = 32'b00000000000000000001110100001110; // input=-1.341796875, output=0.22700320942
			11'd1368: out = 32'b00000000000000000001110010010010; // input=-1.345703125, output=0.223197213723
			11'd1369: out = 32'b00000000000000000001110000010101; // input=-1.349609375, output=0.219387812311
			11'd1370: out = 32'b00000000000000000001101110011000; // input=-1.353515625, output=0.215575063311
			11'd1371: out = 32'b00000000000000000001101100011011; // input=-1.357421875, output=0.211759024901
			11'd1372: out = 32'b00000000000000000001101010011110; // input=-1.361328125, output=0.207939755308
			11'd1373: out = 32'b00000000000000000001101000100001; // input=-1.365234375, output=0.204117312811
			11'd1374: out = 32'b00000000000000000001100110100011; // input=-1.369140625, output=0.200291755735
			11'd1375: out = 32'b00000000000000000001100100100110; // input=-1.373046875, output=0.196463142453
			11'd1376: out = 32'b00000000000000000001100010101000; // input=-1.376953125, output=0.192631531385
			11'd1377: out = 32'b00000000000000000001100000101010; // input=-1.380859375, output=0.188796980997
			11'd1378: out = 32'b00000000000000000001011110101101; // input=-1.384765625, output=0.184959549799
			11'd1379: out = 32'b00000000000000000001011100101111; // input=-1.388671875, output=0.181119296346
			11'd1380: out = 32'b00000000000000000001011010110001; // input=-1.392578125, output=0.177276279236
			11'd1381: out = 32'b00000000000000000001011000110011; // input=-1.396484375, output=0.173430557107
			11'd1382: out = 32'b00000000000000000001010110110101; // input=-1.400390625, output=0.169582188642
			11'd1383: out = 32'b00000000000000000001010100110111; // input=-1.404296875, output=0.165731232561
			11'd1384: out = 32'b00000000000000000001010010111000; // input=-1.408203125, output=0.161877747625
			11'd1385: out = 32'b00000000000000000001010000111010; // input=-1.412109375, output=0.158021792634
			11'd1386: out = 32'b00000000000000000001001110111100; // input=-1.416015625, output=0.154163426425
			11'd1387: out = 32'b00000000000000000001001100111101; // input=-1.419921875, output=0.150302707872
			11'd1388: out = 32'b00000000000000000001001010111111; // input=-1.423828125, output=0.146439695884
			11'd1389: out = 32'b00000000000000000001001001000000; // input=-1.427734375, output=0.142574449407
			11'd1390: out = 32'b00000000000000000001000111000001; // input=-1.431640625, output=0.138707027419
			11'd1391: out = 32'b00000000000000000001000101000010; // input=-1.435546875, output=0.134837488933
			11'd1392: out = 32'b00000000000000000001000011000011; // input=-1.439453125, output=0.130965892992
			11'd1393: out = 32'b00000000000000000001000001000101; // input=-1.443359375, output=0.127092298673
			11'd1394: out = 32'b00000000000000000000111111000110; // input=-1.447265625, output=0.123216765082
			11'd1395: out = 32'b00000000000000000000111101000111; // input=-1.451171875, output=0.119339351355
			11'd1396: out = 32'b00000000000000000000111011000111; // input=-1.455078125, output=0.115460116656
			11'd1397: out = 32'b00000000000000000000111001001000; // input=-1.458984375, output=0.111579120177
			11'd1398: out = 32'b00000000000000000000110111001001; // input=-1.462890625, output=0.107696421139
			11'd1399: out = 32'b00000000000000000000110101001010; // input=-1.466796875, output=0.103812078785
			11'd1400: out = 32'b00000000000000000000110011001010; // input=-1.470703125, output=0.0999261523872
			11'd1401: out = 32'b00000000000000000000110001001011; // input=-1.474609375, output=0.0960387012391
			11'd1402: out = 32'b00000000000000000000101111001100; // input=-1.478515625, output=0.0921497846586
			11'd1403: out = 32'b00000000000000000000101101001100; // input=-1.482421875, output=0.0882594619857
			11'd1404: out = 32'b00000000000000000000101011001101; // input=-1.486328125, output=0.084367792582
			11'd1405: out = 32'b00000000000000000000101001001101; // input=-1.490234375, output=0.0804748358296
			11'd1406: out = 32'b00000000000000000000100111001101; // input=-1.494140625, output=0.0765806511302
			11'd1407: out = 32'b00000000000000000000100101001110; // input=-1.498046875, output=0.0726852979043
			11'd1408: out = 32'b00000000000000000000100011001110; // input=-1.501953125, output=0.0687888355902
			11'd1409: out = 32'b00000000000000000000100001001110; // input=-1.505859375, output=0.0648913236431
			11'd1410: out = 32'b00000000000000000000011111001111; // input=-1.509765625, output=0.0609928215342
			11'd1411: out = 32'b00000000000000000000011101001111; // input=-1.513671875, output=0.0570933887499
			11'd1412: out = 32'b00000000000000000000011011001111; // input=-1.517578125, output=0.0531930847907
			11'd1413: out = 32'b00000000000000000000011001001111; // input=-1.521484375, output=0.0492919691706
			11'd1414: out = 32'b00000000000000000000010111001111; // input=-1.525390625, output=0.0453901014156
			11'd1415: out = 32'b00000000000000000000010101001111; // input=-1.529296875, output=0.0414875410635
			11'd1416: out = 32'b00000000000000000000010011010000; // input=-1.533203125, output=0.0375843476626
			11'd1417: out = 32'b00000000000000000000010001010000; // input=-1.537109375, output=0.0336805807707
			11'd1418: out = 32'b00000000000000000000001111010000; // input=-1.541015625, output=0.0297762999547
			11'd1419: out = 32'b00000000000000000000001101010000; // input=-1.544921875, output=0.0258715647889
			11'd1420: out = 32'b00000000000000000000001011010000; // input=-1.548828125, output=0.0219664348549
			11'd1421: out = 32'b00000000000000000000001001010000; // input=-1.552734375, output=0.0180609697401
			11'd1422: out = 32'b00000000000000000000000111010000; // input=-1.556640625, output=0.0141552290372
			11'd1423: out = 32'b00000000000000000000000101010000; // input=-1.560546875, output=0.0102492723429
			11'd1424: out = 32'b00000000000000000000000011010000; // input=-1.564453125, output=0.00634315925725
			11'd1425: out = 32'b00000000000000000000000001010000; // input=-1.568359375, output=0.00243694938283
			11'd1426: out = 32'b10000000000000000000000000110000; // input=-1.572265625, output=-0.00146929767644
			11'd1427: out = 32'b10000000000000000000000010110000; // input=-1.576171875, output=-0.00537552231604
			11'd1428: out = 32'b10000000000000000000000100110000; // input=-1.580078125, output=-0.00928166493177
			11'd1429: out = 32'b10000000000000000000000110110000; // input=-1.583984375, output=-0.0131876659207
			11'd1430: out = 32'b10000000000000000000001000110000; // input=-1.587890625, output=-0.0170934656821
			11'd1431: out = 32'b10000000000000000000001010110000; // input=-1.591796875, output=-0.0209990046183
			11'd1432: out = 32'b10000000000000000000001100110000; // input=-1.595703125, output=-0.0249042231354
			11'd1433: out = 32'b10000000000000000000001110110000; // input=-1.599609375, output=-0.0288090616448
			11'd1434: out = 32'b10000000000000000000010000110000; // input=-1.603515625, output=-0.0327134605633
			11'd1435: out = 32'b10000000000000000000010010110000; // input=-1.607421875, output=-0.0366173603147
			11'd1436: out = 32'b10000000000000000000010100110000; // input=-1.611328125, output=-0.0405207013302
			11'd1437: out = 32'b10000000000000000000010110110000; // input=-1.615234375, output=-0.0444234240496
			11'd1438: out = 32'b10000000000000000000011000110000; // input=-1.619140625, output=-0.0483254689223
			11'd1439: out = 32'b10000000000000000000011010101111; // input=-1.623046875, output=-0.0522267764077
			11'd1440: out = 32'b10000000000000000000011100101111; // input=-1.626953125, output=-0.0561272869768
			11'd1441: out = 32'b10000000000000000000011110101111; // input=-1.630859375, output=-0.0600269411126
			11'd1442: out = 32'b10000000000000000000100000101111; // input=-1.634765625, output=-0.0639256793111
			11'd1443: out = 32'b10000000000000000000100010101110; // input=-1.638671875, output=-0.0678234420824
			11'd1444: out = 32'b10000000000000000000100100101110; // input=-1.642578125, output=-0.0717201699514
			11'd1445: out = 32'b10000000000000000000100110101110; // input=-1.646484375, output=-0.0756158034588
			11'd1446: out = 32'b10000000000000000000101000101101; // input=-1.650390625, output=-0.0795102831621
			11'd1447: out = 32'b10000000000000000000101010101101; // input=-1.654296875, output=-0.0834035496363
			11'd1448: out = 32'b10000000000000000000101100101101; // input=-1.658203125, output=-0.087295543475
			11'd1449: out = 32'b10000000000000000000101110101100; // input=-1.662109375, output=-0.0911862052911
			11'd1450: out = 32'b10000000000000000000110000101011; // input=-1.666015625, output=-0.0950754757179
			11'd1451: out = 32'b10000000000000000000110010101011; // input=-1.669921875, output=-0.0989632954099
			11'd1452: out = 32'b10000000000000000000110100101010; // input=-1.673828125, output=-0.102849605044
			11'd1453: out = 32'b10000000000000000000110110101001; // input=-1.677734375, output=-0.106734345319
			11'd1454: out = 32'b10000000000000000000111000101001; // input=-1.681640625, output=-0.11061745696
			11'd1455: out = 32'b10000000000000000000111010101000; // input=-1.685546875, output=-0.114498880714
			11'd1456: out = 32'b10000000000000000000111100100111; // input=-1.689453125, output=-0.118378557356
			11'd1457: out = 32'b10000000000000000000111110100110; // input=-1.693359375, output=-0.122256427688
			11'd1458: out = 32'b10000000000000000001000000100101; // input=-1.697265625, output=-0.126132432536
			11'd1459: out = 32'b10000000000000000001000010100100; // input=-1.701171875, output=-0.130006512759
			11'd1460: out = 32'b10000000000000000001000100100011; // input=-1.705078125, output=-0.133878609242
			11'd1461: out = 32'b10000000000000000001000110100010; // input=-1.708984375, output=-0.137748662903
			11'd1462: out = 32'b10000000000000000001001000100000; // input=-1.712890625, output=-0.141616614688
			11'd1463: out = 32'b10000000000000000001001010011111; // input=-1.716796875, output=-0.145482405578
			11'd1464: out = 32'b10000000000000000001001100011110; // input=-1.720703125, output=-0.149345976585
			11'd1465: out = 32'b10000000000000000001001110011100; // input=-1.724609375, output=-0.153207268757
			11'd1466: out = 32'b10000000000000000001010000011011; // input=-1.728515625, output=-0.157066223174
			11'd1467: out = 32'b10000000000000000001010010011001; // input=-1.732421875, output=-0.160922780954
			11'd1468: out = 32'b10000000000000000001010100010111; // input=-1.736328125, output=-0.164776883251
			11'd1469: out = 32'b10000000000000000001010110010110; // input=-1.740234375, output=-0.168628471254
			11'd1470: out = 32'b10000000000000000001011000010100; // input=-1.744140625, output=-0.172477486195
			11'd1471: out = 32'b10000000000000000001011010010010; // input=-1.748046875, output=-0.176323869342
			11'd1472: out = 32'b10000000000000000001011100010000; // input=-1.751953125, output=-0.180167562003
			11'd1473: out = 32'b10000000000000000001011110001110; // input=-1.755859375, output=-0.184008505529
			11'd1474: out = 32'b10000000000000000001100000001011; // input=-1.759765625, output=-0.187846641311
			11'd1475: out = 32'b10000000000000000001100010001001; // input=-1.763671875, output=-0.191681910785
			11'd1476: out = 32'b10000000000000000001100100000111; // input=-1.767578125, output=-0.195514255429
			11'd1477: out = 32'b10000000000000000001100110000100; // input=-1.771484375, output=-0.199343616766
			11'd1478: out = 32'b10000000000000000001101000000001; // input=-1.775390625, output=-0.203169936364
			11'd1479: out = 32'b10000000000000000001101001111111; // input=-1.779296875, output=-0.206993155839
			11'd1480: out = 32'b10000000000000000001101011111100; // input=-1.783203125, output=-0.210813216853
			11'd1481: out = 32'b10000000000000000001101101111001; // input=-1.787109375, output=-0.214630061117
			11'd1482: out = 32'b10000000000000000001101111110110; // input=-1.791015625, output=-0.218443630391
			11'd1483: out = 32'b10000000000000000001110001110011; // input=-1.794921875, output=-0.222253866483
			11'd1484: out = 32'b10000000000000000001110011110000; // input=-1.798828125, output=-0.226060711255
			11'd1485: out = 32'b10000000000000000001110101101100; // input=-1.802734375, output=-0.229864106618
			11'd1486: out = 32'b10000000000000000001110111101001; // input=-1.806640625, output=-0.233663994538
			11'd1487: out = 32'b10000000000000000001111001100101; // input=-1.810546875, output=-0.237460317033
			11'd1488: out = 32'b10000000000000000001111011100001; // input=-1.814453125, output=-0.241253016175
			11'd1489: out = 32'b10000000000000000001111101011110; // input=-1.818359375, output=-0.245042034094
			11'd1490: out = 32'b10000000000000000001111111011010; // input=-1.822265625, output=-0.248827312972
			11'd1491: out = 32'b10000000000000000010000001010101; // input=-1.826171875, output=-0.252608795052
			11'd1492: out = 32'b10000000000000000010000011010001; // input=-1.830078125, output=-0.256386422632
			11'd1493: out = 32'b10000000000000000010000101001101; // input=-1.833984375, output=-0.260160138071
			11'd1494: out = 32'b10000000000000000010000111001000; // input=-1.837890625, output=-0.263929883786
			11'd1495: out = 32'b10000000000000000010001001000100; // input=-1.841796875, output=-0.267695602256
			11'd1496: out = 32'b10000000000000000010001010111111; // input=-1.845703125, output=-0.271457236021
			11'd1497: out = 32'b10000000000000000010001100111010; // input=-1.849609375, output=-0.275214727682
			11'd1498: out = 32'b10000000000000000010001110110101; // input=-1.853515625, output=-0.278968019905
			11'd1499: out = 32'b10000000000000000010010000110000; // input=-1.857421875, output=-0.282717055419
			11'd1500: out = 32'b10000000000000000010010010101011; // input=-1.861328125, output=-0.286461777019
			11'd1501: out = 32'b10000000000000000010010100100101; // input=-1.865234375, output=-0.290202127564
			11'd1502: out = 32'b10000000000000000010010110100000; // input=-1.869140625, output=-0.293938049982
			11'd1503: out = 32'b10000000000000000010011000011010; // input=-1.873046875, output=-0.297669487267
			11'd1504: out = 32'b10000000000000000010011010010100; // input=-1.876953125, output=-0.301396382482
			11'd1505: out = 32'b10000000000000000010011100001110; // input=-1.880859375, output=-0.305118678759
			11'd1506: out = 32'b10000000000000000010011110001000; // input=-1.884765625, output=-0.308836319301
			11'd1507: out = 32'b10000000000000000010100000000010; // input=-1.888671875, output=-0.31254924738
			11'd1508: out = 32'b10000000000000000010100001111011; // input=-1.892578125, output=-0.316257406342
			11'd1509: out = 32'b10000000000000000010100011110100; // input=-1.896484375, output=-0.319960739605
			11'd1510: out = 32'b10000000000000000010100101101110; // input=-1.900390625, output=-0.323659190661
			11'd1511: out = 32'b10000000000000000010100111100111; // input=-1.904296875, output=-0.327352703076
			11'd1512: out = 32'b10000000000000000010101001100000; // input=-1.908203125, output=-0.331041220491
			11'd1513: out = 32'b10000000000000000010101011011000; // input=-1.912109375, output=-0.334724686625
			11'd1514: out = 32'b10000000000000000010101101010001; // input=-1.916015625, output=-0.338403045272
			11'd1515: out = 32'b10000000000000000010101111001001; // input=-1.919921875, output=-0.342076240304
			11'd1516: out = 32'b10000000000000000010110001000001; // input=-1.923828125, output=-0.345744215674
			11'd1517: out = 32'b10000000000000000010110010111001; // input=-1.927734375, output=-0.349406915413
			11'd1518: out = 32'b10000000000000000010110100110001; // input=-1.931640625, output=-0.353064283632
			11'd1519: out = 32'b10000000000000000010110110101001; // input=-1.935546875, output=-0.356716264525
			11'd1520: out = 32'b10000000000000000010111000100000; // input=-1.939453125, output=-0.360362802366
			11'd1521: out = 32'b10000000000000000010111010011000; // input=-1.943359375, output=-0.364003841514
			11'd1522: out = 32'b10000000000000000010111100001111; // input=-1.947265625, output=-0.367639326412
			11'd1523: out = 32'b10000000000000000010111110000110; // input=-1.951171875, output=-0.371269201585
			11'd1524: out = 32'b10000000000000000010111111111101; // input=-1.955078125, output=-0.374893411648
			11'd1525: out = 32'b10000000000000000011000001110011; // input=-1.958984375, output=-0.378511901298
			11'd1526: out = 32'b10000000000000000011000011101001; // input=-1.962890625, output=-0.382124615322
			11'd1527: out = 32'b10000000000000000011000101100000; // input=-1.966796875, output=-0.385731498595
			11'd1528: out = 32'b10000000000000000011000111010110; // input=-1.970703125, output=-0.38933249608
			11'd1529: out = 32'b10000000000000000011001001001011; // input=-1.974609375, output=-0.392927552829
			11'd1530: out = 32'b10000000000000000011001011000001; // input=-1.978515625, output=-0.396516613988
			11'd1531: out = 32'b10000000000000000011001100110110; // input=-1.982421875, output=-0.400099624791
			11'd1532: out = 32'b10000000000000000011001110101100; // input=-1.986328125, output=-0.403676530566
			11'd1533: out = 32'b10000000000000000011010000100001; // input=-1.990234375, output=-0.407247276734
			11'd1534: out = 32'b10000000000000000011010010010101; // input=-1.994140625, output=-0.41081180881
			11'd1535: out = 32'b10000000000000000011010100001010; // input=-1.998046875, output=-0.414370072403
			11'd1536: out = 32'b10000000000000000011010101111110; // input=-2.001953125, output=-0.417922013218
			11'd1537: out = 32'b10000000000000000011010111110011; // input=-2.005859375, output=-0.421467577057
			11'd1538: out = 32'b10000000000000000011011001100111; // input=-2.009765625, output=-0.42500670982
			11'd1539: out = 32'b10000000000000000011011011011010; // input=-2.013671875, output=-0.428539357504
			11'd1540: out = 32'b10000000000000000011011101001110; // input=-2.017578125, output=-0.432065466204
			11'd1541: out = 32'b10000000000000000011011111000001; // input=-2.021484375, output=-0.435584982116
			11'd1542: out = 32'b10000000000000000011100000110100; // input=-2.025390625, output=-0.439097851538
			11'd1543: out = 32'b10000000000000000011100010100111; // input=-2.029296875, output=-0.442604020867
			11'd1544: out = 32'b10000000000000000011100100011010; // input=-2.033203125, output=-0.446103436603
			11'd1545: out = 32'b10000000000000000011100110001100; // input=-2.037109375, output=-0.449596045349
			11'd1546: out = 32'b10000000000000000011100111111111; // input=-2.041015625, output=-0.453081793813
			11'd1547: out = 32'b10000000000000000011101001110001; // input=-2.044921875, output=-0.456560628806
			11'd1548: out = 32'b10000000000000000011101011100010; // input=-2.048828125, output=-0.460032497246
			11'd1549: out = 32'b10000000000000000011101101010100; // input=-2.052734375, output=-0.463497346155
			11'd1550: out = 32'b10000000000000000011101111000101; // input=-2.056640625, output=-0.466955122666
			11'd1551: out = 32'b10000000000000000011110000110110; // input=-2.060546875, output=-0.470405774016
			11'd1552: out = 32'b10000000000000000011110010100111; // input=-2.064453125, output=-0.473849247552
			11'd1553: out = 32'b10000000000000000011110100011000; // input=-2.068359375, output=-0.477285490732
			11'd1554: out = 32'b10000000000000000011110110001000; // input=-2.072265625, output=-0.480714451123
			11'd1555: out = 32'b10000000000000000011110111111000; // input=-2.076171875, output=-0.484136076402
			11'd1556: out = 32'b10000000000000000011111001101000; // input=-2.080078125, output=-0.487550314361
			11'd1557: out = 32'b10000000000000000011111011011000; // input=-2.083984375, output=-0.490957112901
			11'd1558: out = 32'b10000000000000000011111101000111; // input=-2.087890625, output=-0.49435642004
			11'd1559: out = 32'b10000000000000000011111110110110; // input=-2.091796875, output=-0.497748183909
			11'd1560: out = 32'b10000000000000000100000000100101; // input=-2.095703125, output=-0.501132352752
			11'd1561: out = 32'b10000000000000000100000010010100; // input=-2.099609375, output=-0.504508874933
			11'd1562: out = 32'b10000000000000000100000100000010; // input=-2.103515625, output=-0.507877698929
			11'd1563: out = 32'b10000000000000000100000101110000; // input=-2.107421875, output=-0.511238773335
			11'd1564: out = 32'b10000000000000000100000111011110; // input=-2.111328125, output=-0.514592046868
			11'd1565: out = 32'b10000000000000000100001001001100; // input=-2.115234375, output=-0.517937468358
			11'd1566: out = 32'b10000000000000000100001010111001; // input=-2.119140625, output=-0.52127498676
			11'd1567: out = 32'b10000000000000000100001100100110; // input=-2.123046875, output=-0.524604551148
			11'd1568: out = 32'b10000000000000000100001110010011; // input=-2.126953125, output=-0.527926110715
			11'd1569: out = 32'b10000000000000000100010000000000; // input=-2.130859375, output=-0.531239614779
			11'd1570: out = 32'b10000000000000000100010001101100; // input=-2.134765625, output=-0.53454501278
			11'd1571: out = 32'b10000000000000000100010011011000; // input=-2.138671875, output=-0.537842254283
			11'd1572: out = 32'b10000000000000000100010101000100; // input=-2.142578125, output=-0.541131288974
			11'd1573: out = 32'b10000000000000000100010110101111; // input=-2.146484375, output=-0.544412066667
			11'd1574: out = 32'b10000000000000000100011000011011; // input=-2.150390625, output=-0.547684537302
			11'd1575: out = 32'b10000000000000000100011010000101; // input=-2.154296875, output=-0.550948650945
			11'd1576: out = 32'b10000000000000000100011011110000; // input=-2.158203125, output=-0.554204357789
			11'd1577: out = 32'b10000000000000000100011101011011; // input=-2.162109375, output=-0.557451608157
			11'd1578: out = 32'b10000000000000000100011111000101; // input=-2.166015625, output=-0.560690352499
			11'd1579: out = 32'b10000000000000000100100000101111; // input=-2.169921875, output=-0.563920541396
			11'd1580: out = 32'b10000000000000000100100010011000; // input=-2.173828125, output=-0.567142125559
			11'd1581: out = 32'b10000000000000000100100100000001; // input=-2.177734375, output=-0.570355055831
			11'd1582: out = 32'b10000000000000000100100101101010; // input=-2.181640625, output=-0.573559283187
			11'd1583: out = 32'b10000000000000000100100111010011; // input=-2.185546875, output=-0.576754758734
			11'd1584: out = 32'b10000000000000000100101000111100; // input=-2.189453125, output=-0.579941433713
			11'd1585: out = 32'b10000000000000000100101010100100; // input=-2.193359375, output=-0.583119259499
			11'd1586: out = 32'b10000000000000000100101100001011; // input=-2.197265625, output=-0.586288187603
			11'd1587: out = 32'b10000000000000000100101101110011; // input=-2.201171875, output=-0.58944816967
			11'd1588: out = 32'b10000000000000000100101111011010; // input=-2.205078125, output=-0.592599157484
			11'd1589: out = 32'b10000000000000000100110001000001; // input=-2.208984375, output=-0.595741102963
			11'd1590: out = 32'b10000000000000000100110010101000; // input=-2.212890625, output=-0.598873958166
			11'd1591: out = 32'b10000000000000000100110100001110; // input=-2.216796875, output=-0.601997675289
			11'd1592: out = 32'b10000000000000000100110101110100; // input=-2.220703125, output=-0.605112206669
			11'd1593: out = 32'b10000000000000000100110111011010; // input=-2.224609375, output=-0.60821750478
			11'd1594: out = 32'b10000000000000000100111001000000; // input=-2.228515625, output=-0.611313522241
			11'd1595: out = 32'b10000000000000000100111010100101; // input=-2.232421875, output=-0.61440021181
			11'd1596: out = 32'b10000000000000000100111100001010; // input=-2.236328125, output=-0.617477526387
			11'd1597: out = 32'b10000000000000000100111101101110; // input=-2.240234375, output=-0.620545419017
			11'd1598: out = 32'b10000000000000000100111111010010; // input=-2.244140625, output=-0.623603842888
			11'd1599: out = 32'b10000000000000000101000000110110; // input=-2.248046875, output=-0.626652751331
			11'd1600: out = 32'b10000000000000000101000010011010; // input=-2.251953125, output=-0.629692097824
			11'd1601: out = 32'b10000000000000000101000011111101; // input=-2.255859375, output=-0.63272183599
			11'd1602: out = 32'b10000000000000000101000101100000; // input=-2.259765625, output=-0.635741919599
			11'd1603: out = 32'b10000000000000000101000111000011; // input=-2.263671875, output=-0.638752302569
			11'd1604: out = 32'b10000000000000000101001000100101; // input=-2.267578125, output=-0.641752938965
			11'd1605: out = 32'b10000000000000000101001010000111; // input=-2.271484375, output=-0.644743783001
			11'd1606: out = 32'b10000000000000000101001011101001; // input=-2.275390625, output=-0.647724789039
			11'd1607: out = 32'b10000000000000000101001101001010; // input=-2.279296875, output=-0.650695911595
			11'd1608: out = 32'b10000000000000000101001110101011; // input=-2.283203125, output=-0.653657105331
			11'd1609: out = 32'b10000000000000000101010000001100; // input=-2.287109375, output=-0.656608325064
			11'd1610: out = 32'b10000000000000000101010001101100; // input=-2.291015625, output=-0.659549525762
			11'd1611: out = 32'b10000000000000000101010011001100; // input=-2.294921875, output=-0.662480662545
			11'd1612: out = 32'b10000000000000000101010100101100; // input=-2.298828125, output=-0.665401690689
			11'd1613: out = 32'b10000000000000000101010110001011; // input=-2.302734375, output=-0.668312565622
			11'd1614: out = 32'b10000000000000000101010111101010; // input=-2.306640625, output=-0.671213242927
			11'd1615: out = 32'b10000000000000000101011001001001; // input=-2.310546875, output=-0.674103678343
			11'd1616: out = 32'b10000000000000000101011010100111; // input=-2.314453125, output=-0.676983827767
			11'd1617: out = 32'b10000000000000000101011100000101; // input=-2.318359375, output=-0.679853647251
			11'd1618: out = 32'b10000000000000000101011101100011; // input=-2.322265625, output=-0.682713093005
			11'd1619: out = 32'b10000000000000000101011111000000; // input=-2.326171875, output=-0.685562121397
			11'd1620: out = 32'b10000000000000000101100000011110; // input=-2.330078125, output=-0.688400688954
			11'd1621: out = 32'b10000000000000000101100001111010; // input=-2.333984375, output=-0.691228752363
			11'd1622: out = 32'b10000000000000000101100011010111; // input=-2.337890625, output=-0.694046268473
			11'd1623: out = 32'b10000000000000000101100100110010; // input=-2.341796875, output=-0.69685319429
			11'd1624: out = 32'b10000000000000000101100110001110; // input=-2.345703125, output=-0.699649486985
			11'd1625: out = 32'b10000000000000000101100111101001; // input=-2.349609375, output=-0.702435103889
			11'd1626: out = 32'b10000000000000000101101001000100; // input=-2.353515625, output=-0.705210002498
			11'd1627: out = 32'b10000000000000000101101010011111; // input=-2.357421875, output=-0.707974140471
			11'd1628: out = 32'b10000000000000000101101011111001; // input=-2.361328125, output=-0.710727475628
			11'd1629: out = 32'b10000000000000000101101101010011; // input=-2.365234375, output=-0.713469965959
			11'd1630: out = 32'b10000000000000000101101110101100; // input=-2.369140625, output=-0.716201569616
			11'd1631: out = 32'b10000000000000000101110000000110; // input=-2.373046875, output=-0.718922244918
			11'd1632: out = 32'b10000000000000000101110001011110; // input=-2.376953125, output=-0.721631950352
			11'd1633: out = 32'b10000000000000000101110010110111; // input=-2.380859375, output=-0.724330644569
			11'd1634: out = 32'b10000000000000000101110100001111; // input=-2.384765625, output=-0.727018286392
			11'd1635: out = 32'b10000000000000000101110101100111; // input=-2.388671875, output=-0.729694834811
			11'd1636: out = 32'b10000000000000000101110110111110; // input=-2.392578125, output=-0.732360248984
			11'd1637: out = 32'b10000000000000000101111000010101; // input=-2.396484375, output=-0.735014488241
			11'd1638: out = 32'b10000000000000000101111001101100; // input=-2.400390625, output=-0.737657512081
			11'd1639: out = 32'b10000000000000000101111011000010; // input=-2.404296875, output=-0.740289280175
			11'd1640: out = 32'b10000000000000000101111100011000; // input=-2.408203125, output=-0.742909752365
			11'd1641: out = 32'b10000000000000000101111101101101; // input=-2.412109375, output=-0.745518888667
			11'd1642: out = 32'b10000000000000000101111111000010; // input=-2.416015625, output=-0.748116649267
			11'd1643: out = 32'b10000000000000000110000000010111; // input=-2.419921875, output=-0.750702994528
			11'd1644: out = 32'b10000000000000000110000001101011; // input=-2.423828125, output=-0.753277884985
			11'd1645: out = 32'b10000000000000000110000010111111; // input=-2.427734375, output=-0.755841281348
			11'd1646: out = 32'b10000000000000000110000100010011; // input=-2.431640625, output=-0.758393144503
			11'd1647: out = 32'b10000000000000000110000101100110; // input=-2.435546875, output=-0.760933435512
			11'd1648: out = 32'b10000000000000000110000110111001; // input=-2.439453125, output=-0.763462115613
			11'd1649: out = 32'b10000000000000000110001000001100; // input=-2.443359375, output=-0.765979146221
			11'd1650: out = 32'b10000000000000000110001001011110; // input=-2.447265625, output=-0.76848448893
			11'd1651: out = 32'b10000000000000000110001010101111; // input=-2.451171875, output=-0.770978105511
			11'd1652: out = 32'b10000000000000000110001100000001; // input=-2.455078125, output=-0.773459957915
			11'd1653: out = 32'b10000000000000000110001101010010; // input=-2.458984375, output=-0.775930008271
			11'd1654: out = 32'b10000000000000000110001110100010; // input=-2.462890625, output=-0.77838821889
			11'd1655: out = 32'b10000000000000000110001111110010; // input=-2.466796875, output=-0.780834552263
			11'd1656: out = 32'b10000000000000000110010001000010; // input=-2.470703125, output=-0.783268971061
			11'd1657: out = 32'b10000000000000000110010010010010; // input=-2.474609375, output=-0.785691438138
			11'd1658: out = 32'b10000000000000000110010011100001; // input=-2.478515625, output=-0.78810191653
			11'd1659: out = 32'b10000000000000000110010100101111; // input=-2.482421875, output=-0.790500369457
			11'd1660: out = 32'b10000000000000000110010101111101; // input=-2.486328125, output=-0.792886760321
			11'd1661: out = 32'b10000000000000000110010111001011; // input=-2.490234375, output=-0.795261052708
			11'd1662: out = 32'b10000000000000000110011000011001; // input=-2.494140625, output=-0.797623210391
			11'd1663: out = 32'b10000000000000000110011001100110; // input=-2.498046875, output=-0.799973197324
			11'd1664: out = 32'b10000000000000000110011010110010; // input=-2.501953125, output=-0.802310977651
			11'd1665: out = 32'b10000000000000000110011011111110; // input=-2.505859375, output=-0.804636515699
			11'd1666: out = 32'b10000000000000000110011101001010; // input=-2.509765625, output=-0.806949775984
			11'd1667: out = 32'b10000000000000000110011110010110; // input=-2.513671875, output=-0.809250723208
			11'd1668: out = 32'b10000000000000000110011111100001; // input=-2.517578125, output=-0.811539322262
			11'd1669: out = 32'b10000000000000000110100000101011; // input=-2.521484375, output=-0.813815538224
			11'd1670: out = 32'b10000000000000000110100001110101; // input=-2.525390625, output=-0.816079336362
			11'd1671: out = 32'b10000000000000000110100010111111; // input=-2.529296875, output=-0.818330682134
			11'd1672: out = 32'b10000000000000000110100100001000; // input=-2.533203125, output=-0.820569541186
			11'd1673: out = 32'b10000000000000000110100101010001; // input=-2.537109375, output=-0.822795879357
			11'd1674: out = 32'b10000000000000000110100110011010; // input=-2.541015625, output=-0.825009662675
			11'd1675: out = 32'b10000000000000000110100111100010; // input=-2.544921875, output=-0.82721085736
			11'd1676: out = 32'b10000000000000000110101000101010; // input=-2.548828125, output=-0.829399429826
			11'd1677: out = 32'b10000000000000000110101001110001; // input=-2.552734375, output=-0.831575346677
			11'd1678: out = 32'b10000000000000000110101010111000; // input=-2.556640625, output=-0.833738574711
			11'd1679: out = 32'b10000000000000000110101011111110; // input=-2.560546875, output=-0.83588908092
			11'd1680: out = 32'b10000000000000000110101101000100; // input=-2.564453125, output=-0.83802683249
			11'd1681: out = 32'b10000000000000000110101110001010; // input=-2.568359375, output=-0.840151796802
			11'd1682: out = 32'b10000000000000000110101111001111; // input=-2.572265625, output=-0.842263941431
			11'd1683: out = 32'b10000000000000000110110000010100; // input=-2.576171875, output=-0.844363234149
			11'd1684: out = 32'b10000000000000000110110001011000; // input=-2.580078125, output=-0.846449642922
			11'd1685: out = 32'b10000000000000000110110010011100; // input=-2.583984375, output=-0.848523135916
			11'd1686: out = 32'b10000000000000000110110011100000; // input=-2.587890625, output=-0.85058368149
			11'd1687: out = 32'b10000000000000000110110100100011; // input=-2.591796875, output=-0.852631248204
			11'd1688: out = 32'b10000000000000000110110101100110; // input=-2.595703125, output=-0.854665804814
			11'd1689: out = 32'b10000000000000000110110110101000; // input=-2.599609375, output=-0.856687320275
			11'd1690: out = 32'b10000000000000000110110111101010; // input=-2.603515625, output=-0.858695763742
			11'd1691: out = 32'b10000000000000000110111000101011; // input=-2.607421875, output=-0.860691104568
			11'd1692: out = 32'b10000000000000000110111001101100; // input=-2.611328125, output=-0.862673312307
			11'd1693: out = 32'b10000000000000000110111010101101; // input=-2.615234375, output=-0.864642356712
			11'd1694: out = 32'b10000000000000000110111011101101; // input=-2.619140625, output=-0.866598207739
			11'd1695: out = 32'b10000000000000000110111100101100; // input=-2.623046875, output=-0.868540835543
			11'd1696: out = 32'b10000000000000000110111101101100; // input=-2.626953125, output=-0.870470210483
			11'd1697: out = 32'b10000000000000000110111110101010; // input=-2.630859375, output=-0.872386303118
			11'd1698: out = 32'b10000000000000000110111111101001; // input=-2.634765625, output=-0.874289084212
			11'd1699: out = 32'b10000000000000000111000000100111; // input=-2.638671875, output=-0.87617852473
			11'd1700: out = 32'b10000000000000000111000001100100; // input=-2.642578125, output=-0.878054595842
			11'd1701: out = 32'b10000000000000000111000010100001; // input=-2.646484375, output=-0.879917268921
			11'd1702: out = 32'b10000000000000000111000011011110; // input=-2.650390625, output=-0.881766515544
			11'd1703: out = 32'b10000000000000000111000100011010; // input=-2.654296875, output=-0.883602307496
			11'd1704: out = 32'b10000000000000000111000101010110; // input=-2.658203125, output=-0.885424616764
			11'd1705: out = 32'b10000000000000000111000110010001; // input=-2.662109375, output=-0.887233415541
			11'd1706: out = 32'b10000000000000000111000111001100; // input=-2.666015625, output=-0.889028676228
			11'd1707: out = 32'b10000000000000000111001000000110; // input=-2.669921875, output=-0.890810371432
			11'd1708: out = 32'b10000000000000000111001001000000; // input=-2.673828125, output=-0.892578473965
			11'd1709: out = 32'b10000000000000000111001001111010; // input=-2.677734375, output=-0.894332956848
			11'd1710: out = 32'b10000000000000000111001010110011; // input=-2.681640625, output=-0.896073793311
			11'd1711: out = 32'b10000000000000000111001011101011; // input=-2.685546875, output=-0.897800956791
			11'd1712: out = 32'b10000000000000000111001100100011; // input=-2.689453125, output=-0.899514420932
			11'd1713: out = 32'b10000000000000000111001101011011; // input=-2.693359375, output=-0.90121415959
			11'd1714: out = 32'b10000000000000000111001110010010; // input=-2.697265625, output=-0.902900146829
			11'd1715: out = 32'b10000000000000000111001111001001; // input=-2.701171875, output=-0.904572356923
			11'd1716: out = 32'b10000000000000000111001111111111; // input=-2.705078125, output=-0.906230764355
			11'd1717: out = 32'b10000000000000000111010000110101; // input=-2.708984375, output=-0.907875343821
			11'd1718: out = 32'b10000000000000000111010001101011; // input=-2.712890625, output=-0.909506070226
			11'd1719: out = 32'b10000000000000000111010010100000; // input=-2.716796875, output=-0.911122918687
			11'd1720: out = 32'b10000000000000000111010011010100; // input=-2.720703125, output=-0.912725864533
			11'd1721: out = 32'b10000000000000000111010100001000; // input=-2.724609375, output=-0.914314883306
			11'd1722: out = 32'b10000000000000000111010100111100; // input=-2.728515625, output=-0.915889950759
			11'd1723: out = 32'b10000000000000000111010101101111; // input=-2.732421875, output=-0.917451042858
			11'd1724: out = 32'b10000000000000000111010110100010; // input=-2.736328125, output=-0.918998135783
			11'd1725: out = 32'b10000000000000000111010111010100; // input=-2.740234375, output=-0.920531205927
			11'd1726: out = 32'b10000000000000000111011000000110; // input=-2.744140625, output=-0.922050229897
			11'd1727: out = 32'b10000000000000000111011000110111; // input=-2.748046875, output=-0.923555184515
			11'd1728: out = 32'b10000000000000000111011001101000; // input=-2.751953125, output=-0.925046046817
			11'd1729: out = 32'b10000000000000000111011010011000; // input=-2.755859375, output=-0.926522794055
			11'd1730: out = 32'b10000000000000000111011011001000; // input=-2.759765625, output=-0.927985403695
			11'd1731: out = 32'b10000000000000000111011011111000; // input=-2.763671875, output=-0.929433853419
			11'd1732: out = 32'b10000000000000000111011100100111; // input=-2.767578125, output=-0.930868121127
			11'd1733: out = 32'b10000000000000000111011101010101; // input=-2.771484375, output=-0.932288184932
			11'd1734: out = 32'b10000000000000000111011110000011; // input=-2.775390625, output=-0.933694023166
			11'd1735: out = 32'b10000000000000000111011110110001; // input=-2.779296875, output=-0.935085614378
			11'd1736: out = 32'b10000000000000000111011111011110; // input=-2.783203125, output=-0.936462937335
			11'd1737: out = 32'b10000000000000000111100000001011; // input=-2.787109375, output=-0.937825971019
			11'd1738: out = 32'b10000000000000000111100000110111; // input=-2.791015625, output=-0.939174694632
			11'd1739: out = 32'b10000000000000000111100001100011; // input=-2.794921875, output=-0.940509087596
			11'd1740: out = 32'b10000000000000000111100010001110; // input=-2.798828125, output=-0.941829129547
			11'd1741: out = 32'b10000000000000000111100010111001; // input=-2.802734375, output=-0.943134800345
			11'd1742: out = 32'b10000000000000000111100011100011; // input=-2.806640625, output=-0.944426080067
			11'd1743: out = 32'b10000000000000000111100100001101; // input=-2.810546875, output=-0.945702949008
			11'd1744: out = 32'b10000000000000000111100100110110; // input=-2.814453125, output=-0.946965387686
			11'd1745: out = 32'b10000000000000000111100101011111; // input=-2.818359375, output=-0.948213376837
			11'd1746: out = 32'b10000000000000000111100110000111; // input=-2.822265625, output=-0.949446897419
			11'd1747: out = 32'b10000000000000000111100110101111; // input=-2.826171875, output=-0.950665930609
			11'd1748: out = 32'b10000000000000000111100111010111; // input=-2.830078125, output=-0.951870457806
			11'd1749: out = 32'b10000000000000000111100111111110; // input=-2.833984375, output=-0.953060460632
			11'd1750: out = 32'b10000000000000000111101000100100; // input=-2.837890625, output=-0.954235920927
			11'd1751: out = 32'b10000000000000000111101001001010; // input=-2.841796875, output=-0.955396820757
			11'd1752: out = 32'b10000000000000000111101001110000; // input=-2.845703125, output=-0.956543142406
			11'd1753: out = 32'b10000000000000000111101010010101; // input=-2.849609375, output=-0.957674868384
			11'd1754: out = 32'b10000000000000000111101010111010; // input=-2.853515625, output=-0.958791981422
			11'd1755: out = 32'b10000000000000000111101011011110; // input=-2.857421875, output=-0.959894464473
			11'd1756: out = 32'b10000000000000000111101100000001; // input=-2.861328125, output=-0.960982300717
			11'd1757: out = 32'b10000000000000000111101100100101; // input=-2.865234375, output=-0.962055473552
			11'd1758: out = 32'b10000000000000000111101101000111; // input=-2.869140625, output=-0.963113966605
			11'd1759: out = 32'b10000000000000000111101101101010; // input=-2.873046875, output=-0.964157763723
			11'd1760: out = 32'b10000000000000000111101110001011; // input=-2.876953125, output=-0.965186848981
			11'd1761: out = 32'b10000000000000000111101110101100; // input=-2.880859375, output=-0.966201206674
			11'd1762: out = 32'b10000000000000000111101111001101; // input=-2.884765625, output=-0.967200821326
			11'd1763: out = 32'b10000000000000000111101111101110; // input=-2.888671875, output=-0.968185677683
			11'd1764: out = 32'b10000000000000000111110000001101; // input=-2.892578125, output=-0.969155760718
			11'd1765: out = 32'b10000000000000000111110000101101; // input=-2.896484375, output=-0.970111055629
			11'd1766: out = 32'b10000000000000000111110001001011; // input=-2.900390625, output=-0.971051547838
			11'd1767: out = 32'b10000000000000000111110001101010; // input=-2.904296875, output=-0.971977222996
			11'd1768: out = 32'b10000000000000000111110010001000; // input=-2.908203125, output=-0.972888066977
			11'd1769: out = 32'b10000000000000000111110010100101; // input=-2.912109375, output=-0.973784065883
			11'd1770: out = 32'b10000000000000000111110011000010; // input=-2.916015625, output=-0.974665206042
			11'd1771: out = 32'b10000000000000000111110011011110; // input=-2.919921875, output=-0.975531474009
			11'd1772: out = 32'b10000000000000000111110011111010; // input=-2.923828125, output=-0.976382856567
			11'd1773: out = 32'b10000000000000000111110100010110; // input=-2.927734375, output=-0.977219340723
			11'd1774: out = 32'b10000000000000000111110100110000; // input=-2.931640625, output=-0.978040913714
			11'd1775: out = 32'b10000000000000000111110101001011; // input=-2.935546875, output=-0.978847563005
			11'd1776: out = 32'b10000000000000000111110101100101; // input=-2.939453125, output=-0.979639276285
			11'd1777: out = 32'b10000000000000000111110101111110; // input=-2.943359375, output=-0.980416041476
			11'd1778: out = 32'b10000000000000000111110110010111; // input=-2.947265625, output=-0.981177846724
			11'd1779: out = 32'b10000000000000000111110110110000; // input=-2.951171875, output=-0.981924680406
			11'd1780: out = 32'b10000000000000000111110111001000; // input=-2.955078125, output=-0.982656531125
			11'd1781: out = 32'b10000000000000000111110111011111; // input=-2.958984375, output=-0.983373387714
			11'd1782: out = 32'b10000000000000000111110111110110; // input=-2.962890625, output=-0.984075239235
			11'd1783: out = 32'b10000000000000000111111000001101; // input=-2.966796875, output=-0.984762074979
			11'd1784: out = 32'b10000000000000000111111000100011; // input=-2.970703125, output=-0.985433884466
			11'd1785: out = 32'b10000000000000000111111000111000; // input=-2.974609375, output=-0.986090657443
			11'd1786: out = 32'b10000000000000000111111001001101; // input=-2.978515625, output=-0.986732383891
			11'd1787: out = 32'b10000000000000000111111001100010; // input=-2.982421875, output=-0.987359054016
			11'd1788: out = 32'b10000000000000000111111001110110; // input=-2.986328125, output=-0.987970658257
			11'd1789: out = 32'b10000000000000000111111010001001; // input=-2.990234375, output=-0.988567187281
			11'd1790: out = 32'b10000000000000000111111010011100; // input=-2.994140625, output=-0.989148631986
			11'd1791: out = 32'b10000000000000000111111010101111; // input=-2.998046875, output=-0.9897149835
			11'd1792: out = 32'b10000000000000000111111011000001; // input=-3.001953125, output=-0.990266233181
			11'd1793: out = 32'b10000000000000000111111011010011; // input=-3.005859375, output=-0.990802372617
			11'd1794: out = 32'b10000000000000000111111011100100; // input=-3.009765625, output=-0.991323393629
			11'd1795: out = 32'b10000000000000000111111011110100; // input=-3.013671875, output=-0.991829288265
			11'd1796: out = 32'b10000000000000000111111100000100; // input=-3.017578125, output=-0.992320048806
			11'd1797: out = 32'b10000000000000000111111100010100; // input=-3.021484375, output=-0.992795667765
			11'd1798: out = 32'b10000000000000000111111100100011; // input=-3.025390625, output=-0.993256137883
			11'd1799: out = 32'b10000000000000000111111100110010; // input=-3.029296875, output=-0.993701452134
			11'd1800: out = 32'b10000000000000000111111101000000; // input=-3.033203125, output=-0.994131603724
			11'd1801: out = 32'b10000000000000000111111101001101; // input=-3.037109375, output=-0.994546586089
			11'd1802: out = 32'b10000000000000000111111101011010; // input=-3.041015625, output=-0.994946392896
			11'd1803: out = 32'b10000000000000000111111101100111; // input=-3.044921875, output=-0.995331018046
			11'd1804: out = 32'b10000000000000000111111101110011; // input=-3.048828125, output=-0.995700455669
			11'd1805: out = 32'b10000000000000000111111101111111; // input=-3.052734375, output=-0.996054700128
			11'd1806: out = 32'b10000000000000000111111110001010; // input=-3.056640625, output=-0.996393746017
			11'd1807: out = 32'b10000000000000000111111110010100; // input=-3.060546875, output=-0.996717588164
			11'd1808: out = 32'b10000000000000000111111110011111; // input=-3.064453125, output=-0.997026221627
			11'd1809: out = 32'b10000000000000000111111110101000; // input=-3.068359375, output=-0.997319641697
			11'd1810: out = 32'b10000000000000000111111110110001; // input=-3.072265625, output=-0.997597843896
			11'd1811: out = 32'b10000000000000000111111110111010; // input=-3.076171875, output=-0.997860823979
			11'd1812: out = 32'b10000000000000000111111111000010; // input=-3.080078125, output=-0.998108577933
			11'd1813: out = 32'b10000000000000000111111111001010; // input=-3.083984375, output=-0.998341101979
			11'd1814: out = 32'b10000000000000000111111111010001; // input=-3.087890625, output=-0.998558392568
			11'd1815: out = 32'b10000000000000000111111111010111; // input=-3.091796875, output=-0.998760446384
			11'd1816: out = 32'b10000000000000000111111111011110; // input=-3.095703125, output=-0.998947260345
			11'd1817: out = 32'b10000000000000000111111111100011; // input=-3.099609375, output=-0.999118831599
			11'd1818: out = 32'b10000000000000000111111111101000; // input=-3.103515625, output=-0.99927515753
			11'd1819: out = 32'b10000000000000000111111111101101; // input=-3.107421875, output=-0.999416235751
			11'd1820: out = 32'b10000000000000000111111111110001; // input=-3.111328125, output=-0.99954206411
			11'd1821: out = 32'b10000000000000000111111111110101; // input=-3.115234375, output=-0.999652640687
			11'd1822: out = 32'b10000000000000000111111111111000; // input=-3.119140625, output=-0.999747963794
			11'd1823: out = 32'b10000000000000000111111111111010; // input=-3.123046875, output=-0.999828031977
			11'd1824: out = 32'b10000000000000000111111111111100; // input=-3.126953125, output=-0.999892844015
			11'd1825: out = 32'b10000000000000000111111111111110; // input=-3.130859375, output=-0.999942398918
			11'd1826: out = 32'b10000000000000000111111111111111; // input=-3.134765625, output=-0.999976695931
			11'd1827: out = 32'b10000000000000000111111111111111; // input=-3.138671875, output=-0.999995734529
			11'd1828: out = 32'b10000000000000000111111111111111; // input=-3.142578125, output=-0.999999514423
			11'd1829: out = 32'b10000000000000000111111111111111; // input=-3.146484375, output=-0.999988035555
			11'd1830: out = 32'b10000000000000000111111111111111; // input=-3.150390625, output=-0.999961298099
			11'd1831: out = 32'b10000000000000000111111111111101; // input=-3.154296875, output=-0.999919302465
			11'd1832: out = 32'b10000000000000000111111111111011; // input=-3.158203125, output=-0.999862049292
			11'd1833: out = 32'b10000000000000000111111111111001; // input=-3.162109375, output=-0.999789539454
			11'd1834: out = 32'b10000000000000000111111111110110; // input=-3.166015625, output=-0.999701774058
			11'd1835: out = 32'b10000000000000000111111111110011; // input=-3.169921875, output=-0.999598754443
			11'd1836: out = 32'b10000000000000000111111111101111; // input=-3.173828125, output=-0.999480482181
			11'd1837: out = 32'b10000000000000000111111111101011; // input=-3.177734375, output=-0.999346959076
			11'd1838: out = 32'b10000000000000000111111111100110; // input=-3.181640625, output=-0.999198187167
			11'd1839: out = 32'b10000000000000000111111111100000; // input=-3.185546875, output=-0.999034168722
			11'd1840: out = 32'b10000000000000000111111111011010; // input=-3.189453125, output=-0.998854906245
			11'd1841: out = 32'b10000000000000000111111111010100; // input=-3.193359375, output=-0.998660402471
			11'd1842: out = 32'b10000000000000000111111111001101; // input=-3.197265625, output=-0.998450660368
			11'd1843: out = 32'b10000000000000000111111111000110; // input=-3.201171875, output=-0.998225683137
			11'd1844: out = 32'b10000000000000000111111110111110; // input=-3.205078125, output=-0.997985474209
			11'd1845: out = 32'b10000000000000000111111110110110; // input=-3.208984375, output=-0.997730037251
			11'd1846: out = 32'b10000000000000000111111110101101; // input=-3.212890625, output=-0.997459376161
			11'd1847: out = 32'b10000000000000000111111110100011; // input=-3.216796875, output=-0.997173495067
			11'd1848: out = 32'b10000000000000000111111110011010; // input=-3.220703125, output=-0.996872398333
			11'd1849: out = 32'b10000000000000000111111110001111; // input=-3.224609375, output=-0.996556090553
			11'd1850: out = 32'b10000000000000000111111110000100; // input=-3.228515625, output=-0.996224576552
			11'd1851: out = 32'b10000000000000000111111101111001; // input=-3.232421875, output=-0.995877861391
			11'd1852: out = 32'b10000000000000000111111101101101; // input=-3.236328125, output=-0.995515950358
			11'd1853: out = 32'b10000000000000000111111101100001; // input=-3.240234375, output=-0.995138848977
			11'd1854: out = 32'b10000000000000000111111101010100; // input=-3.244140625, output=-0.994746563001
			11'd1855: out = 32'b10000000000000000111111101000111; // input=-3.248046875, output=-0.994339098417
			11'd1856: out = 32'b10000000000000000111111100111001; // input=-3.251953125, output=-0.993916461441
			11'd1857: out = 32'b10000000000000000111111100101010; // input=-3.255859375, output=-0.993478658524
			11'd1858: out = 32'b10000000000000000111111100011011; // input=-3.259765625, output=-0.993025696344
			11'd1859: out = 32'b10000000000000000111111100001100; // input=-3.263671875, output=-0.992557581813
			11'd1860: out = 32'b10000000000000000111111011111100; // input=-3.267578125, output=-0.992074322076
			11'd1861: out = 32'b10000000000000000111111011101100; // input=-3.271484375, output=-0.991575924504
			11'd1862: out = 32'b10000000000000000111111011011011; // input=-3.275390625, output=-0.991062396704
			11'd1863: out = 32'b10000000000000000111111011001010; // input=-3.279296875, output=-0.990533746511
			11'd1864: out = 32'b10000000000000000111111010111000; // input=-3.283203125, output=-0.989989981992
			11'd1865: out = 32'b10000000000000000111111010100110; // input=-3.287109375, output=-0.989431111444
			11'd1866: out = 32'b10000000000000000111111010010011; // input=-3.291015625, output=-0.988857143395
			11'd1867: out = 32'b10000000000000000111111010000000; // input=-3.294921875, output=-0.988268086602
			11'd1868: out = 32'b10000000000000000111111001101100; // input=-3.298828125, output=-0.987663950053
			11'd1869: out = 32'b10000000000000000111111001010111; // input=-3.302734375, output=-0.987044742969
			11'd1870: out = 32'b10000000000000000111111001000011; // input=-3.306640625, output=-0.986410474795
			11'd1871: out = 32'b10000000000000000111111000101101; // input=-3.310546875, output=-0.985761155212
			11'd1872: out = 32'b10000000000000000111111000011000; // input=-3.314453125, output=-0.985096794126
			11'd1873: out = 32'b10000000000000000111111000000001; // input=-3.318359375, output=-0.984417401675
			11'd1874: out = 32'b10000000000000000111110111101011; // input=-3.322265625, output=-0.983722988226
			11'd1875: out = 32'b10000000000000000111110111010011; // input=-3.326171875, output=-0.983013564374
			11'd1876: out = 32'b10000000000000000111110110111100; // input=-3.330078125, output=-0.982289140945
			11'd1877: out = 32'b10000000000000000111110110100011; // input=-3.333984375, output=-0.981549728992
			11'd1878: out = 32'b10000000000000000111110110001011; // input=-3.337890625, output=-0.980795339798
			11'd1879: out = 32'b10000000000000000111110101110001; // input=-3.341796875, output=-0.980025984873
			11'd1880: out = 32'b10000000000000000111110101011000; // input=-3.345703125, output=-0.979241675958
			11'd1881: out = 32'b10000000000000000111110100111110; // input=-3.349609375, output=-0.978442425019
			11'd1882: out = 32'b10000000000000000111110100100011; // input=-3.353515625, output=-0.977628244254
			11'd1883: out = 32'b10000000000000000111110100001000; // input=-3.357421875, output=-0.976799146083
			11'd1884: out = 32'b10000000000000000111110011101100; // input=-3.361328125, output=-0.97595514316
			11'd1885: out = 32'b10000000000000000111110011010000; // input=-3.365234375, output=-0.975096248362
			11'd1886: out = 32'b10000000000000000111110010110011; // input=-3.369140625, output=-0.974222474795
			11'd1887: out = 32'b10000000000000000111110010010110; // input=-3.373046875, output=-0.973333835791
			11'd1888: out = 32'b10000000000000000111110001111001; // input=-3.376953125, output=-0.972430344911
			11'd1889: out = 32'b10000000000000000111110001011011; // input=-3.380859375, output=-0.97151201594
			11'd1890: out = 32'b10000000000000000111110000111100; // input=-3.384765625, output=-0.970578862891
			11'd1891: out = 32'b10000000000000000111110000011101; // input=-3.388671875, output=-0.969630900003
			11'd1892: out = 32'b10000000000000000111101111111101; // input=-3.392578125, output=-0.96866814174
			11'd1893: out = 32'b10000000000000000111101111011101; // input=-3.396484375, output=-0.967690602793
			11'd1894: out = 32'b10000000000000000111101110111101; // input=-3.400390625, output=-0.966698298078
			11'd1895: out = 32'b10000000000000000111101110011100; // input=-3.404296875, output=-0.965691242737
			11'd1896: out = 32'b10000000000000000111101101111010; // input=-3.408203125, output=-0.964669452135
			11'd1897: out = 32'b10000000000000000111101101011000; // input=-3.412109375, output=-0.963632941864
			11'd1898: out = 32'b10000000000000000111101100110110; // input=-3.416015625, output=-0.96258172774
			11'd1899: out = 32'b10000000000000000111101100010011; // input=-3.419921875, output=-0.961515825803
			11'd1900: out = 32'b10000000000000000111101011110000; // input=-3.423828125, output=-0.960435252318
			11'd1901: out = 32'b10000000000000000111101011001100; // input=-3.427734375, output=-0.959340023773
			11'd1902: out = 32'b10000000000000000111101010100111; // input=-3.431640625, output=-0.958230156879
			11'd1903: out = 32'b10000000000000000111101010000010; // input=-3.435546875, output=-0.957105668571
			11'd1904: out = 32'b10000000000000000111101001011101; // input=-3.439453125, output=-0.955966576009
			11'd1905: out = 32'b10000000000000000111101000110111; // input=-3.443359375, output=-0.954812896573
			11'd1906: out = 32'b10000000000000000111101000010001; // input=-3.447265625, output=-0.953644647867
			11'd1907: out = 32'b10000000000000000111100111101010; // input=-3.451171875, output=-0.952461847717
			11'd1908: out = 32'b10000000000000000111100111000011; // input=-3.455078125, output=-0.951264514171
			11'd1909: out = 32'b10000000000000000111100110011011; // input=-3.458984375, output=-0.950052665499
			11'd1910: out = 32'b10000000000000000111100101110011; // input=-3.462890625, output=-0.948826320192
			11'd1911: out = 32'b10000000000000000111100101001010; // input=-3.466796875, output=-0.947585496963
			11'd1912: out = 32'b10000000000000000111100100100001; // input=-3.470703125, output=-0.946330214745
			11'd1913: out = 32'b10000000000000000111100011111000; // input=-3.474609375, output=-0.945060492692
			11'd1914: out = 32'b10000000000000000111100011001110; // input=-3.478515625, output=-0.943776350179
			11'd1915: out = 32'b10000000000000000111100010100011; // input=-3.482421875, output=-0.9424778068
			11'd1916: out = 32'b10000000000000000111100001111000; // input=-3.486328125, output=-0.94116488237
			11'd1917: out = 32'b10000000000000000111100001001101; // input=-3.490234375, output=-0.939837596921
			11'd1918: out = 32'b10000000000000000111100000100001; // input=-3.494140625, output=-0.938495970706
			11'd1919: out = 32'b10000000000000000111011111110100; // input=-3.498046875, output=-0.937140024198
			11'd1920: out = 32'b10000000000000000111011111000111; // input=-3.501953125, output=-0.935769778086
			11'd1921: out = 32'b10000000000000000111011110011010; // input=-3.505859375, output=-0.934385253279
			11'd1922: out = 32'b10000000000000000111011101101100; // input=-3.509765625, output=-0.932986470902
			11'd1923: out = 32'b10000000000000000111011100111110; // input=-3.513671875, output=-0.931573452299
			11'd1924: out = 32'b10000000000000000111011100001111; // input=-3.517578125, output=-0.930146219032
			11'd1925: out = 32'b10000000000000000111011011100000; // input=-3.521484375, output=-0.928704792878
			11'd1926: out = 32'b10000000000000000111011010110000; // input=-3.525390625, output=-0.927249195831
			11'd1927: out = 32'b10000000000000000111011010000000; // input=-3.529296875, output=-0.925779450103
			11'd1928: out = 32'b10000000000000000111011001001111; // input=-3.533203125, output=-0.924295578119
			11'd1929: out = 32'b10000000000000000111011000011110; // input=-3.537109375, output=-0.922797602521
			11'd1930: out = 32'b10000000000000000111010111101101; // input=-3.541015625, output=-0.921285546168
			11'd1931: out = 32'b10000000000000000111010110111011; // input=-3.544921875, output=-0.919759432131
			11'd1932: out = 32'b10000000000000000111010110001000; // input=-3.548828125, output=-0.918219283696
			11'd1933: out = 32'b10000000000000000111010101010101; // input=-3.552734375, output=-0.916665124365
			11'd1934: out = 32'b10000000000000000111010100100010; // input=-3.556640625, output=-0.915096977852
			11'd1935: out = 32'b10000000000000000111010011101110; // input=-3.560546875, output=-0.913514868085
			11'd1936: out = 32'b10000000000000000111010010111010; // input=-3.564453125, output=-0.911918819205
			11'd1937: out = 32'b10000000000000000111010010000101; // input=-3.568359375, output=-0.910308855566
			11'd1938: out = 32'b10000000000000000111010001010000; // input=-3.572265625, output=-0.908685001733
			11'd1939: out = 32'b10000000000000000111010000011010; // input=-3.576171875, output=-0.907047282486
			11'd1940: out = 32'b10000000000000000111001111100100; // input=-3.580078125, output=-0.905395722813
			11'd1941: out = 32'b10000000000000000111001110101101; // input=-3.583984375, output=-0.903730347915
			11'd1942: out = 32'b10000000000000000111001101110110; // input=-3.587890625, output=-0.902051183204
			11'd1943: out = 32'b10000000000000000111001100111111; // input=-3.591796875, output=-0.900358254301
			11'd1944: out = 32'b10000000000000000111001100000111; // input=-3.595703125, output=-0.89865158704
			11'd1945: out = 32'b10000000000000000111001011001111; // input=-3.599609375, output=-0.896931207461
			11'd1946: out = 32'b10000000000000000111001010010110; // input=-3.603515625, output=-0.895197141815
			11'd1947: out = 32'b10000000000000000111001001011101; // input=-3.607421875, output=-0.893449416562
			11'd1948: out = 32'b10000000000000000111001000100011; // input=-3.611328125, output=-0.89168805837
			11'd1949: out = 32'b10000000000000000111000111101001; // input=-3.615234375, output=-0.889913094116
			11'd1950: out = 32'b10000000000000000111000110101110; // input=-3.619140625, output=-0.888124550883
			11'd1951: out = 32'b10000000000000000111000101110011; // input=-3.623046875, output=-0.886322455962
			11'd1952: out = 32'b10000000000000000111000100111000; // input=-3.626953125, output=-0.88450683685
			11'd1953: out = 32'b10000000000000000111000011111100; // input=-3.630859375, output=-0.882677721253
			11'd1954: out = 32'b10000000000000000111000010111111; // input=-3.634765625, output=-0.880835137079
			11'd1955: out = 32'b10000000000000000111000010000010; // input=-3.638671875, output=-0.878979112445
			11'd1956: out = 32'b10000000000000000111000001000101; // input=-3.642578125, output=-0.877109675671
			11'd1957: out = 32'b10000000000000000111000000000111; // input=-3.646484375, output=-0.875226855283
			11'd1958: out = 32'b10000000000000000110111111001001; // input=-3.650390625, output=-0.87333068001
			11'd1959: out = 32'b10000000000000000110111110001011; // input=-3.654296875, output=-0.871421178785
			11'd1960: out = 32'b10000000000000000110111101001100; // input=-3.658203125, output=-0.869498380745
			11'd1961: out = 32'b10000000000000000110111100001100; // input=-3.662109375, output=-0.867562315229
			11'd1962: out = 32'b10000000000000000110111011001100; // input=-3.666015625, output=-0.86561301178
			11'd1963: out = 32'b10000000000000000110111010001100; // input=-3.669921875, output=-0.863650500142
			11'd1964: out = 32'b10000000000000000110111001001011; // input=-3.673828125, output=-0.861674810259
			11'd1965: out = 32'b10000000000000000110111000001010; // input=-3.677734375, output=-0.859685972279
			11'd1966: out = 32'b10000000000000000110110111001001; // input=-3.681640625, output=-0.857684016548
			11'd1967: out = 32'b10000000000000000110110110000111; // input=-3.685546875, output=-0.855668973615
			11'd1968: out = 32'b10000000000000000110110101000100; // input=-3.689453125, output=-0.853640874226
			11'd1969: out = 32'b10000000000000000110110100000001; // input=-3.693359375, output=-0.851599749328
			11'd1970: out = 32'b10000000000000000110110010111110; // input=-3.697265625, output=-0.849545630065
			11'd1971: out = 32'b10000000000000000110110001111010; // input=-3.701171875, output=-0.847478547781
			11'd1972: out = 32'b10000000000000000110110000110110; // input=-3.705078125, output=-0.845398534017
			11'd1973: out = 32'b10000000000000000110101111110001; // input=-3.708984375, output=-0.843305620512
			11'd1974: out = 32'b10000000000000000110101110101100; // input=-3.712890625, output=-0.8411998392
			11'd1975: out = 32'b10000000000000000110101101100111; // input=-3.716796875, output=-0.839081222214
			11'd1976: out = 32'b10000000000000000110101100100001; // input=-3.720703125, output=-0.83694980188
			11'd1977: out = 32'b10000000000000000110101011011011; // input=-3.724609375, output=-0.834805610723
			11'd1978: out = 32'b10000000000000000110101010010100; // input=-3.728515625, output=-0.832648681459
			11'd1979: out = 32'b10000000000000000110101001001101; // input=-3.732421875, output=-0.830479047
			11'd1980: out = 32'b10000000000000000110101000000110; // input=-3.736328125, output=-0.828296740453
			11'd1981: out = 32'b10000000000000000110100110111110; // input=-3.740234375, output=-0.826101795117
			11'd1982: out = 32'b10000000000000000110100101110101; // input=-3.744140625, output=-0.823894244484
			11'd1983: out = 32'b10000000000000000110100100101101; // input=-3.748046875, output=-0.821674122238
			11'd1984: out = 32'b10000000000000000110100011100011; // input=-3.751953125, output=-0.819441462256
			11'd1985: out = 32'b10000000000000000110100010011010; // input=-3.755859375, output=-0.817196298606
			11'd1986: out = 32'b10000000000000000110100001010000; // input=-3.759765625, output=-0.814938665546
			11'd1987: out = 32'b10000000000000000110100000000110; // input=-3.763671875, output=-0.812668597524
			11'd1988: out = 32'b10000000000000000110011110111011; // input=-3.767578125, output=-0.810386129179
			11'd1989: out = 32'b10000000000000000110011101110000; // input=-3.771484375, output=-0.808091295339
			11'd1990: out = 32'b10000000000000000110011100100100; // input=-3.775390625, output=-0.80578413102
			11'd1991: out = 32'b10000000000000000110011011011000; // input=-3.779296875, output=-0.803464671426
			11'd1992: out = 32'b10000000000000000110011010001100; // input=-3.783203125, output=-0.801132951951
			11'd1993: out = 32'b10000000000000000110011000111111; // input=-3.787109375, output=-0.798789008172
			11'd1994: out = 32'b10000000000000000110010111110010; // input=-3.791015625, output=-0.796432875855
			11'd1995: out = 32'b10000000000000000110010110100100; // input=-3.794921875, output=-0.794064590953
			11'd1996: out = 32'b10000000000000000110010101010110; // input=-3.798828125, output=-0.791684189602
			11'd1997: out = 32'b10000000000000000110010100001000; // input=-3.802734375, output=-0.789291708124
			11'd1998: out = 32'b10000000000000000110010010111001; // input=-3.806640625, output=-0.786887183026
			11'd1999: out = 32'b10000000000000000110010001101010; // input=-3.810546875, output=-0.784470650998
			11'd2000: out = 32'b10000000000000000110010000011010; // input=-3.814453125, output=-0.782042148913
			11'd2001: out = 32'b10000000000000000110001111001010; // input=-3.818359375, output=-0.779601713826
			11'd2002: out = 32'b10000000000000000110001101111010; // input=-3.822265625, output=-0.777149382977
			11'd2003: out = 32'b10000000000000000110001100101001; // input=-3.826171875, output=-0.774685193784
			11'd2004: out = 32'b10000000000000000110001011011000; // input=-3.830078125, output=-0.772209183849
			11'd2005: out = 32'b10000000000000000110001010000110; // input=-3.833984375, output=-0.769721390951
			11'd2006: out = 32'b10000000000000000110001000110100; // input=-3.837890625, output=-0.767221853052
			11'd2007: out = 32'b10000000000000000110000111100010; // input=-3.841796875, output=-0.764710608291
			11'd2008: out = 32'b10000000000000000110000110001111; // input=-3.845703125, output=-0.762187694988
			11'd2009: out = 32'b10000000000000000110000100111100; // input=-3.849609375, output=-0.759653151638
			11'd2010: out = 32'b10000000000000000110000011101001; // input=-3.853515625, output=-0.757107016915
			11'd2011: out = 32'b10000000000000000110000010010101; // input=-3.857421875, output=-0.754549329671
			11'd2012: out = 32'b10000000000000000110000001000001; // input=-3.861328125, output=-0.751980128932
			11'd2013: out = 32'b10000000000000000101111111101100; // input=-3.865234375, output=-0.749399453902
			11'd2014: out = 32'b10000000000000000101111110010111; // input=-3.869140625, output=-0.746807343958
			11'd2015: out = 32'b10000000000000000101111101000010; // input=-3.873046875, output=-0.744203838653
			11'd2016: out = 32'b10000000000000000101111011101100; // input=-3.876953125, output=-0.741588977713
			11'd2017: out = 32'b10000000000000000101111010010110; // input=-3.880859375, output=-0.738962801038
			11'd2018: out = 32'b10000000000000000101111001000000; // input=-3.884765625, output=-0.736325348699
			11'd2019: out = 32'b10000000000000000101110111101001; // input=-3.888671875, output=-0.733676660942
			11'd2020: out = 32'b10000000000000000101110110010010; // input=-3.892578125, output=-0.731016778181
			11'd2021: out = 32'b10000000000000000101110100111010; // input=-3.896484375, output=-0.728345741004
			11'd2022: out = 32'b10000000000000000101110011100011; // input=-3.900390625, output=-0.725663590167
			11'd2023: out = 32'b10000000000000000101110010001010; // input=-3.904296875, output=-0.722970366596
			11'd2024: out = 32'b10000000000000000101110000110010; // input=-3.908203125, output=-0.720266111387
			11'd2025: out = 32'b10000000000000000101101111011001; // input=-3.912109375, output=-0.717550865803
			11'd2026: out = 32'b10000000000000000101101101111111; // input=-3.916015625, output=-0.714824671276
			11'd2027: out = 32'b10000000000000000101101100100110; // input=-3.919921875, output=-0.712087569404
			11'd2028: out = 32'b10000000000000000101101011001100; // input=-3.923828125, output=-0.709339601952
			11'd2029: out = 32'b10000000000000000101101001110001; // input=-3.927734375, output=-0.70658081085
			11'd2030: out = 32'b10000000000000000101101000010110; // input=-3.931640625, output=-0.703811238194
			11'd2031: out = 32'b10000000000000000101100110111011; // input=-3.935546875, output=-0.701030926245
			11'd2032: out = 32'b10000000000000000101100101100000; // input=-3.939453125, output=-0.698239917426
			11'd2033: out = 32'b10000000000000000101100100000100; // input=-3.943359375, output=-0.695438254325
			11'd2034: out = 32'b10000000000000000101100010101000; // input=-3.947265625, output=-0.692625979692
			11'd2035: out = 32'b10000000000000000101100001001011; // input=-3.951171875, output=-0.689803136439
			11'd2036: out = 32'b10000000000000000101011111101111; // input=-3.955078125, output=-0.686969767639
			11'd2037: out = 32'b10000000000000000101011110010001; // input=-3.958984375, output=-0.684125916525
			11'd2038: out = 32'b10000000000000000101011100110100; // input=-3.962890625, output=-0.681271626491
			11'd2039: out = 32'b10000000000000000101011011010110; // input=-3.966796875, output=-0.678406941091
			11'd2040: out = 32'b10000000000000000101011001111000; // input=-3.970703125, output=-0.675531904035
			11'd2041: out = 32'b10000000000000000101011000011001; // input=-3.974609375, output=-0.672646559194
			11'd2042: out = 32'b10000000000000000101010110111010; // input=-3.978515625, output=-0.669750950593
			11'd2043: out = 32'b10000000000000000101010101011011; // input=-3.982421875, output=-0.666845122418
			11'd2044: out = 32'b10000000000000000101010011111100; // input=-3.986328125, output=-0.663929119006
			11'd2045: out = 32'b10000000000000000101010010011100; // input=-3.990234375, output=-0.661002984852
			11'd2046: out = 32'b10000000000000000101010000111100; // input=-3.994140625, output=-0.658066764607
			11'd2047: out = 32'b10000000000000000101001111011011; // input=-3.998046875, output=-0.655120503072
		endcase
	end
	converter U0 (a, index);

endmodule

module sin_lut(a, out);
	input  [31:0] a;
	output reg [31:0] out;
	wire   [10:0] index;

	always @(index)
	begin
		case(index)
			11'd0: out = 32'b00000000000000000000000001000000; // input=0.001953125, output=0.00195312375824
			11'd1: out = 32'b00000000000000000000000011000000; // input=0.005859375, output=0.00585934147244
			11'd2: out = 32'b00000000000000000000000101000000; // input=0.009765625, output=0.00976546978031
			11'd3: out = 32'b00000000000000000000000111000000; // input=0.013671875, output=0.0136714490791
			11'd4: out = 32'b00000000000000000000001001000000; // input=0.017578125, output=0.0175772197684
			11'd5: out = 32'b00000000000000000000001011000000; // input=0.021484375, output=0.021482722251
			11'd6: out = 32'b00000000000000000000001101000000; // input=0.025390625, output=0.0253878969337
			11'd7: out = 32'b00000000000000000000001111000000; // input=0.029296875, output=0.0292926842283
			11'd8: out = 32'b00000000000000000000010001000000; // input=0.033203125, output=0.0331970245525
			11'd9: out = 32'b00000000000000000000010011000000; // input=0.037109375, output=0.0371008583311
			11'd10: out = 32'b00000000000000000000010101000000; // input=0.041015625, output=0.0410041259961
			11'd11: out = 32'b00000000000000000000010111000000; // input=0.044921875, output=0.0449067679887
			11'd12: out = 32'b00000000000000000000011000111111; // input=0.048828125, output=0.0488087247592
			11'd13: out = 32'b00000000000000000000011010111111; // input=0.052734375, output=0.0527099367686
			11'd14: out = 32'b00000000000000000000011100111111; // input=0.056640625, output=0.0566103444893
			11'd15: out = 32'b00000000000000000000011110111111; // input=0.060546875, output=0.0605098884057
			11'd16: out = 32'b00000000000000000000100000111111; // input=0.064453125, output=0.0644085090157
			11'd17: out = 32'b00000000000000000000100010111110; // input=0.068359375, output=0.0683061468311
			11'd18: out = 32'b00000000000000000000100100111110; // input=0.072265625, output=0.0722027423787
			11'd19: out = 32'b00000000000000000000100110111110; // input=0.076171875, output=0.0760982362014
			11'd20: out = 32'b00000000000000000000101000111101; // input=0.080078125, output=0.0799925688585
			11'd21: out = 32'b00000000000000000000101010111101; // input=0.083984375, output=0.0838856809275
			11'd22: out = 32'b00000000000000000000101100111100; // input=0.087890625, output=0.0877775130042
			11'd23: out = 32'b00000000000000000000101110111100; // input=0.091796875, output=0.091668005704
			11'd24: out = 32'b00000000000000000000110000111011; // input=0.095703125, output=0.0955570996629
			11'd25: out = 32'b00000000000000000000110010111011; // input=0.099609375, output=0.099444735538
			11'd26: out = 32'b00000000000000000000110100111010; // input=0.103515625, output=0.103330854009
			11'd27: out = 32'b00000000000000000000110110111001; // input=0.107421875, output=0.107215395778
			11'd28: out = 32'b00000000000000000000111000111000; // input=0.111328125, output=0.111098301572
			11'd29: out = 32'b00000000000000000000111010111000; // input=0.115234375, output=0.114979512142
			11'd30: out = 32'b00000000000000000000111100110111; // input=0.119140625, output=0.118858968267
			11'd31: out = 32'b00000000000000000000111110110110; // input=0.123046875, output=0.12273661075
			11'd32: out = 32'b00000000000000000001000000110101; // input=0.126953125, output=0.126612380424
			11'd33: out = 32'b00000000000000000001000010110100; // input=0.130859375, output=0.130486218148
			11'd34: out = 32'b00000000000000000001000100110011; // input=0.134765625, output=0.134358064813
			11'd35: out = 32'b00000000000000000001000110110001; // input=0.138671875, output=0.13822786134
			11'd36: out = 32'b00000000000000000001001000110000; // input=0.142578125, output=0.142095548679
			11'd37: out = 32'b00000000000000000001001010101111; // input=0.146484375, output=0.145961067815
			11'd38: out = 32'b00000000000000000001001100101101; // input=0.150390625, output=0.149824359765
			11'd39: out = 32'b00000000000000000001001110101100; // input=0.154296875, output=0.153685365579
			11'd40: out = 32'b00000000000000000001010000101010; // input=0.158203125, output=0.157544026344
			11'd41: out = 32'b00000000000000000001010010101001; // input=0.162109375, output=0.161400283181
			11'd42: out = 32'b00000000000000000001010100100111; // input=0.166015625, output=0.165254077248
			11'd43: out = 32'b00000000000000000001010110100101; // input=0.169921875, output=0.169105349741
			11'd44: out = 32'b00000000000000000001011000100011; // input=0.173828125, output=0.172954041894
			11'd45: out = 32'b00000000000000000001011010100001; // input=0.177734375, output=0.176800094982
			11'd46: out = 32'b00000000000000000001011100011111; // input=0.181640625, output=0.180643450318
			11'd47: out = 32'b00000000000000000001011110011101; // input=0.185546875, output=0.184484049257
			11'd48: out = 32'b00000000000000000001100000011011; // input=0.189453125, output=0.188321833196
			11'd49: out = 32'b00000000000000000001100010011001; // input=0.193359375, output=0.192156743576
			11'd50: out = 32'b00000000000000000001100100010110; // input=0.197265625, output=0.19598872188
			11'd51: out = 32'b00000000000000000001100110010100; // input=0.201171875, output=0.199817709638
			11'd52: out = 32'b00000000000000000001101000010001; // input=0.205078125, output=0.203643648423
			11'd53: out = 32'b00000000000000000001101010001110; // input=0.208984375, output=0.207466479857
			11'd54: out = 32'b00000000000000000001101100001011; // input=0.212890625, output=0.211286145607
			11'd55: out = 32'b00000000000000000001101110001000; // input=0.216796875, output=0.215102587391
			11'd56: out = 32'b00000000000000000001110000000101; // input=0.220703125, output=0.218915746974
			11'd57: out = 32'b00000000000000000001110010000010; // input=0.224609375, output=0.222725566172
			11'd58: out = 32'b00000000000000000001110011111111; // input=0.228515625, output=0.226531986852
			11'd59: out = 32'b00000000000000000001110101111100; // input=0.232421875, output=0.230334950932
			11'd60: out = 32'b00000000000000000001110111111000; // input=0.236328125, output=0.234134400385
			11'd61: out = 32'b00000000000000000001111001110100; // input=0.240234375, output=0.237930277234
			11'd62: out = 32'b00000000000000000001111011110001; // input=0.244140625, output=0.241722523561
			11'd63: out = 32'b00000000000000000001111101101101; // input=0.248046875, output=0.245511081499
			11'd64: out = 32'b00000000000000000001111111101001; // input=0.251953125, output=0.24929589324
			11'd65: out = 32'b00000000000000000010000001100101; // input=0.255859375, output=0.253076901032
			11'd66: out = 32'b00000000000000000010000011100001; // input=0.259765625, output=0.256854047182
			11'd67: out = 32'b00000000000000000010000101011100; // input=0.263671875, output=0.260627274056
			11'd68: out = 32'b00000000000000000010000111011000; // input=0.267578125, output=0.264396524078
			11'd69: out = 32'b00000000000000000010001001010011; // input=0.271484375, output=0.268161739734
			11'd70: out = 32'b00000000000000000010001011001110; // input=0.275390625, output=0.271922863572
			11'd71: out = 32'b00000000000000000010001101001001; // input=0.279296875, output=0.275679838202
			11'd72: out = 32'b00000000000000000010001111000100; // input=0.283203125, output=0.279432606296
			11'd73: out = 32'b00000000000000000010010000111111; // input=0.287109375, output=0.283181110593
			11'd74: out = 32'b00000000000000000010010010111010; // input=0.291015625, output=0.286925293895
			11'd75: out = 32'b00000000000000000010010100110101; // input=0.294921875, output=0.290665099069
			11'd76: out = 32'b00000000000000000010010110101111; // input=0.298828125, output=0.294400469052
			11'd77: out = 32'b00000000000000000010011000101001; // input=0.302734375, output=0.298131346846
			11'd78: out = 32'b00000000000000000010011010100011; // input=0.306640625, output=0.301857675522
			11'd79: out = 32'b00000000000000000010011100011101; // input=0.310546875, output=0.305579398221
			11'd80: out = 32'b00000000000000000010011110010111; // input=0.314453125, output=0.309296458155
			11'd81: out = 32'b00000000000000000010100000010001; // input=0.318359375, output=0.313008798605
			11'd82: out = 32'b00000000000000000010100010001010; // input=0.322265625, output=0.316716362927
			11'd83: out = 32'b00000000000000000010100100000011; // input=0.326171875, output=0.320419094546
			11'd84: out = 32'b00000000000000000010100101111101; // input=0.330078125, output=0.324116936964
			11'd85: out = 32'b00000000000000000010100111110110; // input=0.333984375, output=0.327809833756
			11'd86: out = 32'b00000000000000000010101001101111; // input=0.337890625, output=0.331497728574
			11'd87: out = 32'b00000000000000000010101011100111; // input=0.341796875, output=0.335180565144
			11'd88: out = 32'b00000000000000000010101101100000; // input=0.345703125, output=0.338858287271
			11'd89: out = 32'b00000000000000000010101111011000; // input=0.349609375, output=0.342530838838
			11'd90: out = 32'b00000000000000000010110001010000; // input=0.353515625, output=0.346198163805
			11'd91: out = 32'b00000000000000000010110011001000; // input=0.357421875, output=0.349860206215
			11'd92: out = 32'b00000000000000000010110101000000; // input=0.361328125, output=0.353516910188
			11'd93: out = 32'b00000000000000000010110110111000; // input=0.365234375, output=0.357168219928
			11'd94: out = 32'b00000000000000000010111000101111; // input=0.369140625, output=0.36081407972
			11'd95: out = 32'b00000000000000000010111010100110; // input=0.373046875, output=0.364454433933
			11'd96: out = 32'b00000000000000000010111100011110; // input=0.376953125, output=0.36808922702
			11'd97: out = 32'b00000000000000000010111110010100; // input=0.380859375, output=0.371718403519
			11'd98: out = 32'b00000000000000000011000000001011; // input=0.384765625, output=0.375341908052
			11'd99: out = 32'b00000000000000000011000010000010; // input=0.388671875, output=0.378959685329
			11'd100: out = 32'b00000000000000000011000011111000; // input=0.392578125, output=0.382571680148
			11'd101: out = 32'b00000000000000000011000101101110; // input=0.396484375, output=0.386177837393
			11'd102: out = 32'b00000000000000000011000111100100; // input=0.400390625, output=0.38977810204
			11'd103: out = 32'b00000000000000000011001001011010; // input=0.404296875, output=0.393372419153
			11'd104: out = 32'b00000000000000000011001011010000; // input=0.408203125, output=0.396960733886
			11'd105: out = 32'b00000000000000000011001101000101; // input=0.412109375, output=0.400542991487
			11'd106: out = 32'b00000000000000000011001110111010; // input=0.416015625, output=0.404119137295
			11'd107: out = 32'b00000000000000000011010000101111; // input=0.419921875, output=0.407689116742
			11'd108: out = 32'b00000000000000000011010010100100; // input=0.423828125, output=0.411252875354
			11'd109: out = 32'b00000000000000000011010100011001; // input=0.427734375, output=0.414810358754
			11'd110: out = 32'b00000000000000000011010110001101; // input=0.431640625, output=0.418361512658
			11'd111: out = 32'b00000000000000000011011000000001; // input=0.435546875, output=0.42190628288
			11'd112: out = 32'b00000000000000000011011001110101; // input=0.439453125, output=0.425444615332
			11'd113: out = 32'b00000000000000000011011011101001; // input=0.443359375, output=0.428976456021
			11'd114: out = 32'b00000000000000000011011101011100; // input=0.447265625, output=0.432501751058
			11'd115: out = 32'b00000000000000000011011111010000; // input=0.451171875, output=0.436020446651
			11'd116: out = 32'b00000000000000000011100001000011; // input=0.455078125, output=0.439532489107
			11'd117: out = 32'b00000000000000000011100010110101; // input=0.458984375, output=0.443037824839
			11'd118: out = 32'b00000000000000000011100100101000; // input=0.462890625, output=0.446536400359
			11'd119: out = 32'b00000000000000000011100110011011; // input=0.466796875, output=0.450028162283
			11'd120: out = 32'b00000000000000000011101000001101; // input=0.470703125, output=0.45351305733
			11'd121: out = 32'b00000000000000000011101001111111; // input=0.474609375, output=0.456991032326
			11'd122: out = 32'b00000000000000000011101011110000; // input=0.478515625, output=0.460462034202
			11'd123: out = 32'b00000000000000000011101101100010; // input=0.482421875, output=0.463926009993
			11'd124: out = 32'b00000000000000000011101111010011; // input=0.486328125, output=0.467382906844
			11'd125: out = 32'b00000000000000000011110001000100; // input=0.490234375, output=0.470832672007
			11'd126: out = 32'b00000000000000000011110010110101; // input=0.494140625, output=0.474275252843
			11'd127: out = 32'b00000000000000000011110100100110; // input=0.498046875, output=0.477710596821
			11'd128: out = 32'b00000000000000000011110110010110; // input=0.501953125, output=0.481138651524
			11'd129: out = 32'b00000000000000000011111000000110; // input=0.505859375, output=0.484559364643
			11'd130: out = 32'b00000000000000000011111001110110; // input=0.509765625, output=0.487972683983
			11'd131: out = 32'b00000000000000000011111011100101; // input=0.513671875, output=0.491378557459
			11'd132: out = 32'b00000000000000000011111101010101; // input=0.517578125, output=0.494776933103
			11'd133: out = 32'b00000000000000000011111111000100; // input=0.521484375, output=0.49816775906
			11'd134: out = 32'b00000000000000000100000000110011; // input=0.525390625, output=0.50155098359
			11'd135: out = 32'b00000000000000000100000010100001; // input=0.529296875, output=0.504926555069
			11'd136: out = 32'b00000000000000000100000100010000; // input=0.533203125, output=0.50829442199
			11'd137: out = 32'b00000000000000000100000101111110; // input=0.537109375, output=0.511654532964
			11'd138: out = 32'b00000000000000000100000111101100; // input=0.541015625, output=0.515006836719
			11'd139: out = 32'b00000000000000000100001001011001; // input=0.544921875, output=0.518351282103
			11'd140: out = 32'b00000000000000000100001011000111; // input=0.548828125, output=0.521687818084
			11'd141: out = 32'b00000000000000000100001100110100; // input=0.552734375, output=0.525016393751
			11'd142: out = 32'b00000000000000000100001110100001; // input=0.556640625, output=0.528336958314
			11'd143: out = 32'b00000000000000000100010000001101; // input=0.560546875, output=0.531649461105
			11'd144: out = 32'b00000000000000000100010001111001; // input=0.564453125, output=0.534953851579
			11'd145: out = 32'b00000000000000000100010011100101; // input=0.568359375, output=0.538250079316
			11'd146: out = 32'b00000000000000000100010101010001; // input=0.572265625, output=0.541538094019
			11'd147: out = 32'b00000000000000000100010110111101; // input=0.576171875, output=0.544817845516
			11'd148: out = 32'b00000000000000000100011000101000; // input=0.580078125, output=0.548089283764
			11'd149: out = 32'b00000000000000000100011010010011; // input=0.583984375, output=0.551352358843
			11'd150: out = 32'b00000000000000000100011011111101; // input=0.587890625, output=0.554607020964
			11'd151: out = 32'b00000000000000000100011101101000; // input=0.591796875, output=0.557853220464
			11'd152: out = 32'b00000000000000000100011111010010; // input=0.595703125, output=0.561090907811
			11'd153: out = 32'b00000000000000000100100000111100; // input=0.599609375, output=0.5643200336
			11'd154: out = 32'b00000000000000000100100010100101; // input=0.603515625, output=0.56754054856
			11'd155: out = 32'b00000000000000000100100100001110; // input=0.607421875, output=0.570752403549
			11'd156: out = 32'b00000000000000000100100101110111; // input=0.611328125, output=0.573955549559
			11'd157: out = 32'b00000000000000000100100111100000; // input=0.615234375, output=0.577149937714
			11'd158: out = 32'b00000000000000000100101001001000; // input=0.619140625, output=0.58033551927
			11'd159: out = 32'b00000000000000000100101010110001; // input=0.623046875, output=0.583512245621
			11'd160: out = 32'b00000000000000000100101100011000; // input=0.626953125, output=0.586680068292
			11'd161: out = 32'b00000000000000000100101110000000; // input=0.630859375, output=0.589838938948
			11'd162: out = 32'b00000000000000000100101111100111; // input=0.634765625, output=0.592988809387
			11'd163: out = 32'b00000000000000000100110001001110; // input=0.638671875, output=0.596129631546
			11'd164: out = 32'b00000000000000000100110010110101; // input=0.642578125, output=0.599261357501
			11'd165: out = 32'b00000000000000000100110100011011; // input=0.646484375, output=0.602383939464
			11'd166: out = 32'b00000000000000000100110110000001; // input=0.650390625, output=0.60549732979
			11'd167: out = 32'b00000000000000000100110111100111; // input=0.654296875, output=0.608601480971
			11'd168: out = 32'b00000000000000000100111001001100; // input=0.658203125, output=0.611696345643
			11'd169: out = 32'b00000000000000000100111010110001; // input=0.662109375, output=0.614781876581
			11'd170: out = 32'b00000000000000000100111100010110; // input=0.666015625, output=0.617858026704
			11'd171: out = 32'b00000000000000000100111101111010; // input=0.669921875, output=0.620924749074
			11'd172: out = 32'b00000000000000000100111111011111; // input=0.673828125, output=0.623981996896
			11'd173: out = 32'b00000000000000000101000001000011; // input=0.677734375, output=0.62702972352
			11'd174: out = 32'b00000000000000000101000010100110; // input=0.681640625, output=0.630067882443
			11'd175: out = 32'b00000000000000000101000100001001; // input=0.685546875, output=0.633096427304
			11'd176: out = 32'b00000000000000000101000101101100; // input=0.689453125, output=0.636115311893
			11'd177: out = 32'b00000000000000000101000111001111; // input=0.693359375, output=0.639124490145
			11'd178: out = 32'b00000000000000000101001000110001; // input=0.697265625, output=0.642123916144
			11'd179: out = 32'b00000000000000000101001010010011; // input=0.701171875, output=0.645113544122
			11'd180: out = 32'b00000000000000000101001011110101; // input=0.705078125, output=0.64809332846
			11'd181: out = 32'b00000000000000000101001101010110; // input=0.708984375, output=0.651063223692
			11'd182: out = 32'b00000000000000000101001110110111; // input=0.712890625, output=0.6540231845
			11'd183: out = 32'b00000000000000000101010000011000; // input=0.716796875, output=0.65697316572
			11'd184: out = 32'b00000000000000000101010001111000; // input=0.720703125, output=0.659913122336
			11'd185: out = 32'b00000000000000000101010011011000; // input=0.724609375, output=0.662843009491
			11'd186: out = 32'b00000000000000000101010100111000; // input=0.728515625, output=0.665762782477
			11'd187: out = 32'b00000000000000000101010110010111; // input=0.732421875, output=0.668672396741
			11'd188: out = 32'b00000000000000000101010111110110; // input=0.736328125, output=0.671571807888
			11'd189: out = 32'b00000000000000000101011001010101; // input=0.740234375, output=0.674460971675
			11'd190: out = 32'b00000000000000000101011010110011; // input=0.744140625, output=0.677339844018
			11'd191: out = 32'b00000000000000000101011100010001; // input=0.748046875, output=0.680208380988
			11'd192: out = 32'b00000000000000000101011101101111; // input=0.751953125, output=0.683066538814
			11'd193: out = 32'b00000000000000000101011111001100; // input=0.755859375, output=0.685914273886
			11'd194: out = 32'b00000000000000000101100000101001; // input=0.759765625, output=0.68875154275
			11'd195: out = 32'b00000000000000000101100010000110; // input=0.763671875, output=0.691578302113
			11'd196: out = 32'b00000000000000000101100011100010; // input=0.767578125, output=0.694394508842
			11'd197: out = 32'b00000000000000000101100100111110; // input=0.771484375, output=0.697200119965
			11'd198: out = 32'b00000000000000000101100110011001; // input=0.775390625, output=0.699995092672
			11'd199: out = 32'b00000000000000000101100111110101; // input=0.779296875, output=0.702779384315
			11'd200: out = 32'b00000000000000000101101001010000; // input=0.783203125, output=0.705552952409
			11'd201: out = 32'b00000000000000000101101010101010; // input=0.787109375, output=0.708315754633
			11'd202: out = 32'b00000000000000000101101100000100; // input=0.791015625, output=0.711067748831
			11'd203: out = 32'b00000000000000000101101101011110; // input=0.794921875, output=0.713808893009
			11'd204: out = 32'b00000000000000000101101110111000; // input=0.798828125, output=0.716539145342
			11'd205: out = 32'b00000000000000000101110000010001; // input=0.802734375, output=0.719258464169
			11'd206: out = 32'b00000000000000000101110001101001; // input=0.806640625, output=0.721966807997
			11'd207: out = 32'b00000000000000000101110011000010; // input=0.810546875, output=0.7246641355
			11'd208: out = 32'b00000000000000000101110100011010; // input=0.814453125, output=0.727350405519
			11'd209: out = 32'b00000000000000000101110101110001; // input=0.818359375, output=0.730025577067
			11'd210: out = 32'b00000000000000000101110111001001; // input=0.822265625, output=0.732689609322
			11'd211: out = 32'b00000000000000000101111000100000; // input=0.826171875, output=0.735342461635
			11'd212: out = 32'b00000000000000000101111001110110; // input=0.830078125, output=0.737984093527
			11'd213: out = 32'b00000000000000000101111011001100; // input=0.833984375, output=0.740614464689
			11'd214: out = 32'b00000000000000000101111100100010; // input=0.837890625, output=0.743233534986
			11'd215: out = 32'b00000000000000000101111101111000; // input=0.841796875, output=0.745841264454
			11'd216: out = 32'b00000000000000000101111111001101; // input=0.845703125, output=0.748437613302
			11'd217: out = 32'b00000000000000000110000000100010; // input=0.849609375, output=0.751022541912
			11'd218: out = 32'b00000000000000000110000001110110; // input=0.853515625, output=0.753596010843
			11'd219: out = 32'b00000000000000000110000011001010; // input=0.857421875, output=0.756157980826
			11'd220: out = 32'b00000000000000000110000100011101; // input=0.861328125, output=0.758708412768
			11'd221: out = 32'b00000000000000000110000101110001; // input=0.865234375, output=0.761247267753
			11'd222: out = 32'b00000000000000000110000111000011; // input=0.869140625, output=0.763774507042
			11'd223: out = 32'b00000000000000000110001000010110; // input=0.873046875, output=0.766290092071
			11'd224: out = 32'b00000000000000000110001001101000; // input=0.876953125, output=0.768793984456
			11'd225: out = 32'b00000000000000000110001010111010; // input=0.880859375, output=0.771286145991
			11'd226: out = 32'b00000000000000000110001100001011; // input=0.884765625, output=0.773766538648
			11'd227: out = 32'b00000000000000000110001101011100; // input=0.888671875, output=0.77623512458
			11'd228: out = 32'b00000000000000000110001110101100; // input=0.892578125, output=0.778691866119
			11'd229: out = 32'b00000000000000000110001111111100; // input=0.896484375, output=0.781136725778
			11'd230: out = 32'b00000000000000000110010001001100; // input=0.900390625, output=0.783569666252
			11'd231: out = 32'b00000000000000000110010010011011; // input=0.904296875, output=0.785990650417
			11'd232: out = 32'b00000000000000000110010011101010; // input=0.908203125, output=0.788399641331
			11'd233: out = 32'b00000000000000000110010100111001; // input=0.912109375, output=0.790796602237
			11'd234: out = 32'b00000000000000000110010110000111; // input=0.916015625, output=0.79318149656
			11'd235: out = 32'b00000000000000000110010111010101; // input=0.919921875, output=0.795554287909
			11'd236: out = 32'b00000000000000000110011000100010; // input=0.923828125, output=0.797914940078
			11'd237: out = 32'b00000000000000000110011001101111; // input=0.927734375, output=0.800263417047
			11'd238: out = 32'b00000000000000000110011010111100; // input=0.931640625, output=0.802599682981
			11'd239: out = 32'b00000000000000000110011100001000; // input=0.935546875, output=0.804923702231
			11'd240: out = 32'b00000000000000000110011101010011; // input=0.939453125, output=0.807235439336
			11'd241: out = 32'b00000000000000000110011110011111; // input=0.943359375, output=0.809534859021
			11'd242: out = 32'b00000000000000000110011111101010; // input=0.947265625, output=0.8118219262
			11'd243: out = 32'b00000000000000000110100000110100; // input=0.951171875, output=0.814096605976
			11'd244: out = 32'b00000000000000000110100001111110; // input=0.955078125, output=0.816358863639
			11'd245: out = 32'b00000000000000000110100011001000; // input=0.958984375, output=0.81860866467
			11'd246: out = 32'b00000000000000000110100100010001; // input=0.962890625, output=0.82084597474
			11'd247: out = 32'b00000000000000000110100101011010; // input=0.966796875, output=0.82307075971
			11'd248: out = 32'b00000000000000000110100110100011; // input=0.970703125, output=0.825282985633
			11'd249: out = 32'b00000000000000000110100111101011; // input=0.974609375, output=0.827482618753
			11'd250: out = 32'b00000000000000000110101000110011; // input=0.978515625, output=0.829669625507
			11'd251: out = 32'b00000000000000000110101001111010; // input=0.982421875, output=0.831843972523
			11'd252: out = 32'b00000000000000000110101011000001; // input=0.986328125, output=0.834005626623
			11'd253: out = 32'b00000000000000000110101100000111; // input=0.990234375, output=0.836154554823
			11'd254: out = 32'b00000000000000000110101101001101; // input=0.994140625, output=0.838290724334
			11'd255: out = 32'b00000000000000000110101110010011; // input=0.998046875, output=0.84041410256
			11'd256: out = 32'b00000000000000000110101111011000; // input=1.001953125, output=0.8425246571
			11'd257: out = 32'b00000000000000000110110000011101; // input=1.005859375, output=0.844622355751
			11'd258: out = 32'b00000000000000000110110001100001; // input=1.009765625, output=0.846707166504
			11'd259: out = 32'b00000000000000000110110010100101; // input=1.013671875, output=0.848779057547
			11'd260: out = 32'b00000000000000000110110011101000; // input=1.017578125, output=0.850837997266
			11'd261: out = 32'b00000000000000000110110100101011; // input=1.021484375, output=0.852883954244
			11'd262: out = 32'b00000000000000000110110101101110; // input=1.025390625, output=0.854916897262
			11'd263: out = 32'b00000000000000000110110110110000; // input=1.029296875, output=0.8569367953
			11'd264: out = 32'b00000000000000000110110111110010; // input=1.033203125, output=0.858943617537
			11'd265: out = 32'b00000000000000000110111000110011; // input=1.037109375, output=0.860937333352
			11'd266: out = 32'b00000000000000000110111001110100; // input=1.041015625, output=0.862917912321
			11'd267: out = 32'b00000000000000000110111010110101; // input=1.044921875, output=0.864885324225
			11'd268: out = 32'b00000000000000000110111011110101; // input=1.048828125, output=0.866839539044
			11'd269: out = 32'b00000000000000000110111100110100; // input=1.052734375, output=0.868780526957
			11'd270: out = 32'b00000000000000000110111101110011; // input=1.056640625, output=0.870708258348
			11'd271: out = 32'b00000000000000000110111110110010; // input=1.060546875, output=0.872622703803
			11'd272: out = 32'b00000000000000000110111111110000; // input=1.064453125, output=0.874523834109
			11'd273: out = 32'b00000000000000000111000000101110; // input=1.068359375, output=0.876411620257
			11'd274: out = 32'b00000000000000000111000001101100; // input=1.072265625, output=0.878286033441
			11'd275: out = 32'b00000000000000000111000010101001; // input=1.076171875, output=0.880147045062
			11'd276: out = 32'b00000000000000000111000011100101; // input=1.080078125, output=0.881994626722
			11'd277: out = 32'b00000000000000000111000100100001; // input=1.083984375, output=0.883828750229
			11'd278: out = 32'b00000000000000000111000101011101; // input=1.087890625, output=0.885649387596
			11'd279: out = 32'b00000000000000000111000110011000; // input=1.091796875, output=0.887456511044
			11'd280: out = 32'b00000000000000000111000111010011; // input=1.095703125, output=0.889250092997
			11'd281: out = 32'b00000000000000000111001000001101; // input=1.099609375, output=0.891030106087
			11'd282: out = 32'b00000000000000000111001001000111; // input=1.103515625, output=0.892796523155
			11'd283: out = 32'b00000000000000000111001010000001; // input=1.107421875, output=0.894549317246
			11'd284: out = 32'b00000000000000000111001010111010; // input=1.111328125, output=0.896288461615
			11'd285: out = 32'b00000000000000000111001011110010; // input=1.115234375, output=0.898013929725
			11'd286: out = 32'b00000000000000000111001100101010; // input=1.119140625, output=0.899725695247
			11'd287: out = 32'b00000000000000000111001101100010; // input=1.123046875, output=0.901423732062
			11'd288: out = 32'b00000000000000000111001110011001; // input=1.126953125, output=0.90310801426
			11'd289: out = 32'b00000000000000000111001111010000; // input=1.130859375, output=0.90477851614
			11'd290: out = 32'b00000000000000000111010000000110; // input=1.134765625, output=0.906435212214
			11'd291: out = 32'b00000000000000000111010000111100; // input=1.138671875, output=0.908078077202
			11'd292: out = 32'b00000000000000000111010001110001; // input=1.142578125, output=0.909707086035
			11'd293: out = 32'b00000000000000000111010010100110; // input=1.146484375, output=0.911322213858
			11'd294: out = 32'b00000000000000000111010011011011; // input=1.150390625, output=0.912923436025
			11'd295: out = 32'b00000000000000000111010100001111; // input=1.154296875, output=0.914510728103
			11'd296: out = 32'b00000000000000000111010101000010; // input=1.158203125, output=0.916084065873
			11'd297: out = 32'b00000000000000000111010101110101; // input=1.162109375, output=0.917643425327
			11'd298: out = 32'b00000000000000000111010110101000; // input=1.166015625, output=0.919188782671
			11'd299: out = 32'b00000000000000000111010111011010; // input=1.169921875, output=0.920720114326
			11'd300: out = 32'b00000000000000000111011000001100; // input=1.173828125, output=0.922237396924
			11'd301: out = 32'b00000000000000000111011000111101; // input=1.177734375, output=0.923740607315
			11'd302: out = 32'b00000000000000000111011001101110; // input=1.181640625, output=0.92522972256
			11'd303: out = 32'b00000000000000000111011010011110; // input=1.185546875, output=0.926704719938
			11'd304: out = 32'b00000000000000000111011011001110; // input=1.189453125, output=0.928165576942
			11'd305: out = 32'b00000000000000000111011011111110; // input=1.193359375, output=0.929612271281
			11'd306: out = 32'b00000000000000000111011100101100; // input=1.197265625, output=0.931044780881
			11'd307: out = 32'b00000000000000000111011101011011; // input=1.201171875, output=0.932463083883
			11'd308: out = 32'b00000000000000000111011110001001; // input=1.205078125, output=0.933867158646
			11'd309: out = 32'b00000000000000000111011110110111; // input=1.208984375, output=0.935256983744
			11'd310: out = 32'b00000000000000000111011111100100; // input=1.212890625, output=0.936632537972
			11'd311: out = 32'b00000000000000000111100000010000; // input=1.216796875, output=0.93799380034
			11'd312: out = 32'b00000000000000000111100000111100; // input=1.220703125, output=0.939340750076
			11'd313: out = 32'b00000000000000000111100001101000; // input=1.224609375, output=0.940673366629
			11'd314: out = 32'b00000000000000000111100010010011; // input=1.228515625, output=0.941991629663
			11'd315: out = 32'b00000000000000000111100010111110; // input=1.232421875, output=0.943295519063
			11'd316: out = 32'b00000000000000000111100011101000; // input=1.236328125, output=0.944585014935
			11'd317: out = 32'b00000000000000000111100100010010; // input=1.240234375, output=0.945860097601
			11'd318: out = 32'b00000000000000000111100100111011; // input=1.244140625, output=0.947120747606
			11'd319: out = 32'b00000000000000000111100101100100; // input=1.248046875, output=0.948366945714
			11'd320: out = 32'b00000000000000000111100110001100; // input=1.251953125, output=0.949598672909
			11'd321: out = 32'b00000000000000000111100110110100; // input=1.255859375, output=0.950815910397
			11'd322: out = 32'b00000000000000000111100111011100; // input=1.259765625, output=0.952018639603
			11'd323: out = 32'b00000000000000000111101000000011; // input=1.263671875, output=0.953206842177
			11'd324: out = 32'b00000000000000000111101000101001; // input=1.267578125, output=0.954380499987
			11'd325: out = 32'b00000000000000000111101001001111; // input=1.271484375, output=0.955539595124
			11'd326: out = 32'b00000000000000000111101001110101; // input=1.275390625, output=0.956684109903
			11'd327: out = 32'b00000000000000000111101010011010; // input=1.279296875, output=0.95781402686
			11'd328: out = 32'b00000000000000000111101010111110; // input=1.283203125, output=0.958929328753
			11'd329: out = 32'b00000000000000000111101011100010; // input=1.287109375, output=0.960029998564
			11'd330: out = 32'b00000000000000000111101100000110; // input=1.291015625, output=0.961116019499
			11'd331: out = 32'b00000000000000000111101100101001; // input=1.294921875, output=0.962187374985
			11'd332: out = 32'b00000000000000000111101101001100; // input=1.298828125, output=0.963244048676
			11'd333: out = 32'b00000000000000000111101101101110; // input=1.302734375, output=0.964286024448
			11'd334: out = 32'b00000000000000000111101110001111; // input=1.306640625, output=0.965313286402
			11'd335: out = 32'b00000000000000000111101110110001; // input=1.310546875, output=0.966325818863
			11'd336: out = 32'b00000000000000000111101111010001; // input=1.314453125, output=0.96732360638
			11'd337: out = 32'b00000000000000000111101111110001; // input=1.318359375, output=0.96830663373
			11'd338: out = 32'b00000000000000000111110000010001; // input=1.322265625, output=0.969274885911
			11'd339: out = 32'b00000000000000000111110000110000; // input=1.326171875, output=0.970228348151
			11'd340: out = 32'b00000000000000000111110001001111; // input=1.330078125, output=0.971167005899
			11'd341: out = 32'b00000000000000000111110001101101; // input=1.333984375, output=0.972090844834
			11'd342: out = 32'b00000000000000000111110010001011; // input=1.337890625, output=0.972999850858
			11'd343: out = 32'b00000000000000000111110010101001; // input=1.341796875, output=0.973894010102
			11'd344: out = 32'b00000000000000000111110011000101; // input=1.345703125, output=0.974773308922
			11'd345: out = 32'b00000000000000000111110011100010; // input=1.349609375, output=0.9756377339
			11'd346: out = 32'b00000000000000000111110011111110; // input=1.353515625, output=0.976487271847
			11'd347: out = 32'b00000000000000000111110100011001; // input=1.357421875, output=0.977321909799
			11'd348: out = 32'b00000000000000000111110100110100; // input=1.361328125, output=0.978141635021
			11'd349: out = 32'b00000000000000000111110101001110; // input=1.365234375, output=0.978946435006
			11'd350: out = 32'b00000000000000000111110101101000; // input=1.369140625, output=0.979736297472
			11'd351: out = 32'b00000000000000000111110110000001; // input=1.373046875, output=0.980511210368
			11'd352: out = 32'b00000000000000000111110110011010; // input=1.376953125, output=0.981271161869
			11'd353: out = 32'b00000000000000000111110110110011; // input=1.380859375, output=0.98201614038
			11'd354: out = 32'b00000000000000000111110111001011; // input=1.384765625, output=0.982746134532
			11'd355: out = 32'b00000000000000000111110111100010; // input=1.388671875, output=0.983461133188
			11'd356: out = 32'b00000000000000000111110111111001; // input=1.392578125, output=0.984161125436
			11'd357: out = 32'b00000000000000000111111000001111; // input=1.396484375, output=0.984846100597
			11'd358: out = 32'b00000000000000000111111000100101; // input=1.400390625, output=0.985516048218
			11'd359: out = 32'b00000000000000000111111000111011; // input=1.404296875, output=0.986170958077
			11'd360: out = 32'b00000000000000000111111001010000; // input=1.408203125, output=0.98681082018
			11'd361: out = 32'b00000000000000000111111001100100; // input=1.412109375, output=0.987435624764
			11'd362: out = 32'b00000000000000000111111001111000; // input=1.416015625, output=0.988045362295
			11'd363: out = 32'b00000000000000000111111010001100; // input=1.419921875, output=0.98864002347
			11'd364: out = 32'b00000000000000000111111010011111; // input=1.423828125, output=0.989219599214
			11'd365: out = 32'b00000000000000000111111010110001; // input=1.427734375, output=0.989784080684
			11'd366: out = 32'b00000000000000000111111011000011; // input=1.431640625, output=0.990333459267
			11'd367: out = 32'b00000000000000000111111011010101; // input=1.435546875, output=0.99086772658
			11'd368: out = 32'b00000000000000000111111011100110; // input=1.439453125, output=0.991386874471
			11'd369: out = 32'b00000000000000000111111011110110; // input=1.443359375, output=0.991890895017
			11'd370: out = 32'b00000000000000000111111100000110; // input=1.447265625, output=0.992379780529
			11'd371: out = 32'b00000000000000000111111100010110; // input=1.451171875, output=0.992853523546
			11'd372: out = 32'b00000000000000000111111100100101; // input=1.455078125, output=0.99331211684
			11'd373: out = 32'b00000000000000000111111100110011; // input=1.458984375, output=0.993755553414
			11'd374: out = 32'b00000000000000000111111101000001; // input=1.462890625, output=0.9941838265
			11'd375: out = 32'b00000000000000000111111101001111; // input=1.466796875, output=0.994596929564
			11'd376: out = 32'b00000000000000000111111101011100; // input=1.470703125, output=0.994994856303
			11'd377: out = 32'b00000000000000000111111101101001; // input=1.474609375, output=0.995377600644
			11'd378: out = 32'b00000000000000000111111101110101; // input=1.478515625, output=0.995745156748
			11'd379: out = 32'b00000000000000000111111110000000; // input=1.482421875, output=0.996097519006
			11'd380: out = 32'b00000000000000000111111110001011; // input=1.486328125, output=0.996434682041
			11'd381: out = 32'b00000000000000000111111110010110; // input=1.490234375, output=0.996756640709
			11'd382: out = 32'b00000000000000000111111110100000; // input=1.494140625, output=0.997063390097
			11'd383: out = 32'b00000000000000000111111110101001; // input=1.498046875, output=0.997354925525
			11'd384: out = 32'b00000000000000000111111110110010; // input=1.501953125, output=0.997631242543
			11'd385: out = 32'b00000000000000000111111110111011; // input=1.505859375, output=0.997892336936
			11'd386: out = 32'b00000000000000000111111111000011; // input=1.509765625, output=0.99813820472
			11'd387: out = 32'b00000000000000000111111111001011; // input=1.513671875, output=0.998368842143
			11'd388: out = 32'b00000000000000000111111111010010; // input=1.517578125, output=0.998584245685
			11'd389: out = 32'b00000000000000000111111111011000; // input=1.521484375, output=0.998784412061
			11'd390: out = 32'b00000000000000000111111111011110; // input=1.525390625, output=0.998969338215
			11'd391: out = 32'b00000000000000000111111111100100; // input=1.529296875, output=0.999139021326
			11'd392: out = 32'b00000000000000000111111111101001; // input=1.533203125, output=0.999293458805
			11'd393: out = 32'b00000000000000000111111111101101; // input=1.537109375, output=0.999432648295
			11'd394: out = 32'b00000000000000000111111111110001; // input=1.541015625, output=0.999556587673
			11'd395: out = 32'b00000000000000000111111111110101; // input=1.544921875, output=0.999665275047
			11'd396: out = 32'b00000000000000000111111111111000; // input=1.548828125, output=0.999758708759
			11'd397: out = 32'b00000000000000000111111111111011; // input=1.552734375, output=0.999836887383
			11'd398: out = 32'b00000000000000000111111111111101; // input=1.556640625, output=0.999899809726
			11'd399: out = 32'b00000000000000000111111111111110; // input=1.560546875, output=0.999947474829
			11'd400: out = 32'b00000000000000000111111111111111; // input=1.564453125, output=0.999979881963
			11'd401: out = 32'b00000000000000000111111111111111; // input=1.568359375, output=0.999997030634
			11'd402: out = 32'b00000000000000000111111111111111; // input=1.572265625, output=0.999998920582
			11'd403: out = 32'b00000000000000000111111111111111; // input=1.576171875, output=0.999985551776
			11'd404: out = 32'b00000000000000000111111111111111; // input=1.580078125, output=0.99995692442
			11'd405: out = 32'b00000000000000000111111111111101; // input=1.583984375, output=0.999913038953
			11'd406: out = 32'b00000000000000000111111111111011; // input=1.587890625, output=0.999853896042
			11'd407: out = 32'b00000000000000000111111111111001; // input=1.591796875, output=0.999779496592
			11'd408: out = 32'b00000000000000000111111111110110; // input=1.595703125, output=0.999689841736
			11'd409: out = 32'b00000000000000000111111111110010; // input=1.599609375, output=0.999584932843
			11'd410: out = 32'b00000000000000000111111111101110; // input=1.603515625, output=0.999464771514
			11'd411: out = 32'b00000000000000000111111111101010; // input=1.607421875, output=0.999329359583
			11'd412: out = 32'b00000000000000000111111111100101; // input=1.611328125, output=0.999178699114
			11'd413: out = 32'b00000000000000000111111111100000; // input=1.615234375, output=0.999012792408
			11'd414: out = 32'b00000000000000000111111111011010; // input=1.619140625, output=0.998831641997
			11'd415: out = 32'b00000000000000000111111111010011; // input=1.623046875, output=0.998635250643
			11'd416: out = 32'b00000000000000000111111111001100; // input=1.626953125, output=0.998423621343
			11'd417: out = 32'b00000000000000000111111111000101; // input=1.630859375, output=0.998196757328
			11'd418: out = 32'b00000000000000000111111110111101; // input=1.634765625, output=0.997954662059
			11'd419: out = 32'b00000000000000000111111110110101; // input=1.638671875, output=0.997697339229
			11'd420: out = 32'b00000000000000000111111110101100; // input=1.642578125, output=0.997424792765
			11'd421: out = 32'b00000000000000000111111110100010; // input=1.646484375, output=0.997137026826
			11'd422: out = 32'b00000000000000000111111110011000; // input=1.650390625, output=0.996834045803
			11'd423: out = 32'b00000000000000000111111110001110; // input=1.654296875, output=0.996515854318
			11'd424: out = 32'b00000000000000000111111110000011; // input=1.658203125, output=0.996182457228
			11'd425: out = 32'b00000000000000000111111101110111; // input=1.662109375, output=0.995833859619
			11'd426: out = 32'b00000000000000000111111101101100; // input=1.666015625, output=0.995470066811
			11'd427: out = 32'b00000000000000000111111101011111; // input=1.669921875, output=0.995091084354
			11'd428: out = 32'b00000000000000000111111101010010; // input=1.673828125, output=0.994696918032
			11'd429: out = 32'b00000000000000000111111101000101; // input=1.677734375, output=0.994287573858
			11'd430: out = 32'b00000000000000000111111100110111; // input=1.681640625, output=0.99386305808
			11'd431: out = 32'b00000000000000000111111100101000; // input=1.685546875, output=0.993423377174
			11'd432: out = 32'b00000000000000000111111100011010; // input=1.689453125, output=0.992968537849
			11'd433: out = 32'b00000000000000000111111100001010; // input=1.693359375, output=0.992498547046
			11'd434: out = 32'b00000000000000000111111011111010; // input=1.697265625, output=0.992013411937
			11'd435: out = 32'b00000000000000000111111011101010; // input=1.701171875, output=0.991513139923
			11'd436: out = 32'b00000000000000000111111011011001; // input=1.705078125, output=0.990997738639
			11'd437: out = 32'b00000000000000000111111011001000; // input=1.708984375, output=0.990467215948
			11'd438: out = 32'b00000000000000000111111010110110; // input=1.712890625, output=0.989921579947
			11'd439: out = 32'b00000000000000000111111010100011; // input=1.716796875, output=0.98936083896
			11'd440: out = 32'b00000000000000000111111010010001; // input=1.720703125, output=0.988785001544
			11'd441: out = 32'b00000000000000000111111001111101; // input=1.724609375, output=0.988194076485
			11'd442: out = 32'b00000000000000000111111001101001; // input=1.728515625, output=0.9875880728
			11'd443: out = 32'b00000000000000000111111001010101; // input=1.732421875, output=0.986966999737
			11'd444: out = 32'b00000000000000000111111001000000; // input=1.736328125, output=0.986330866772
			11'd445: out = 32'b00000000000000000111111000101011; // input=1.740234375, output=0.98567968361
			11'd446: out = 32'b00000000000000000111111000010101; // input=1.744140625, output=0.98501346019
			11'd447: out = 32'b00000000000000000111110111111111; // input=1.748046875, output=0.984332206676
			11'd448: out = 32'b00000000000000000111110111101000; // input=1.751953125, output=0.983635933464
			11'd449: out = 32'b00000000000000000111110111010000; // input=1.755859375, output=0.982924651178
			11'd450: out = 32'b00000000000000000111110110111001; // input=1.759765625, output=0.982198370671
			11'd451: out = 32'b00000000000000000111110110100000; // input=1.763671875, output=0.981457103025
			11'd452: out = 32'b00000000000000000111110110001000; // input=1.767578125, output=0.980700859551
			11'd453: out = 32'b00000000000000000111110101101110; // input=1.771484375, output=0.979929651789
			11'd454: out = 32'b00000000000000000111110101010101; // input=1.775390625, output=0.979143491506
			11'd455: out = 32'b00000000000000000111110100111010; // input=1.779296875, output=0.978342390698
			11'd456: out = 32'b00000000000000000111110100100000; // input=1.783203125, output=0.977526361588
			11'd457: out = 32'b00000000000000000111110100000100; // input=1.787109375, output=0.976695416629
			11'd458: out = 32'b00000000000000000111110011101001; // input=1.791015625, output=0.9758495685
			11'd459: out = 32'b00000000000000000111110011001100; // input=1.794921875, output=0.974988830107
			11'd460: out = 32'b00000000000000000111110010110000; // input=1.798828125, output=0.974113214584
			11'd461: out = 32'b00000000000000000111110010010011; // input=1.802734375, output=0.973222735292
			11'd462: out = 32'b00000000000000000111110001110101; // input=1.806640625, output=0.972317405818
			11'd463: out = 32'b00000000000000000111110001010111; // input=1.810546875, output=0.971397239977
			11'd464: out = 32'b00000000000000000111110000111000; // input=1.814453125, output=0.970462251809
			11'd465: out = 32'b00000000000000000111110000011001; // input=1.818359375, output=0.969512455581
			11'd466: out = 32'b00000000000000000111101111111001; // input=1.822265625, output=0.968547865786
			11'd467: out = 32'b00000000000000000111101111011001; // input=1.826171875, output=0.967568497142
			11'd468: out = 32'b00000000000000000111101110111001; // input=1.830078125, output=0.966574364594
			11'd469: out = 32'b00000000000000000111101110011000; // input=1.833984375, output=0.96556548331
			11'd470: out = 32'b00000000000000000111101101110110; // input=1.837890625, output=0.964541868684
			11'd471: out = 32'b00000000000000000111101101010100; // input=1.841796875, output=0.963503536336
			11'd472: out = 32'b00000000000000000111101100110010; // input=1.845703125, output=0.96245050211
			11'd473: out = 32'b00000000000000000111101100001111; // input=1.849609375, output=0.961382782073
			11'd474: out = 32'b00000000000000000111101011101011; // input=1.853515625, output=0.960300392518
			11'd475: out = 32'b00000000000000000111101011000111; // input=1.857421875, output=0.95920334996
			11'd476: out = 32'b00000000000000000111101010100011; // input=1.861328125, output=0.95809167114
			11'd477: out = 32'b00000000000000000111101001111110; // input=1.865234375, output=0.956965373019
			11'd478: out = 32'b00000000000000000111101001011000; // input=1.869140625, output=0.955824472784
			11'd479: out = 32'b00000000000000000111101000110011; // input=1.873046875, output=0.954668987843
			11'd480: out = 32'b00000000000000000111101000001100; // input=1.876953125, output=0.953498935829
			11'd481: out = 32'b00000000000000000111100111100101; // input=1.880859375, output=0.952314334593
			11'd482: out = 32'b00000000000000000111100110111110; // input=1.884765625, output=0.951115202213
			11'd483: out = 32'b00000000000000000111100110010110; // input=1.888671875, output=0.949901556985
			11'd484: out = 32'b00000000000000000111100101101110; // input=1.892578125, output=0.948673417428
			11'd485: out = 32'b00000000000000000111100101000101; // input=1.896484375, output=0.947430802281
			11'd486: out = 32'b00000000000000000111100100011100; // input=1.900390625, output=0.946173730507
			11'd487: out = 32'b00000000000000000111100011110011; // input=1.904296875, output=0.944902221285
			11'd488: out = 32'b00000000000000000111100011001000; // input=1.908203125, output=0.943616294018
			11'd489: out = 32'b00000000000000000111100010011110; // input=1.912109375, output=0.942315968327
			11'd490: out = 32'b00000000000000000111100001110011; // input=1.916015625, output=0.941001264054
			11'd491: out = 32'b00000000000000000111100001000111; // input=1.919921875, output=0.939672201259
			11'd492: out = 32'b00000000000000000111100000011011; // input=1.923828125, output=0.938328800223
			11'd493: out = 32'b00000000000000000111011111101111; // input=1.927734375, output=0.936971081444
			11'd494: out = 32'b00000000000000000111011111000010; // input=1.931640625, output=0.935599065638
			11'd495: out = 32'b00000000000000000111011110010100; // input=1.935546875, output=0.934212773742
			11'd496: out = 32'b00000000000000000111011101100110; // input=1.939453125, output=0.932812226909
			11'd497: out = 32'b00000000000000000111011100111000; // input=1.943359375, output=0.931397446509
			11'd498: out = 32'b00000000000000000111011100001001; // input=1.947265625, output=0.929968454129
			11'd499: out = 32'b00000000000000000111011011011010; // input=1.951171875, output=0.928525271575
			11'd500: out = 32'b00000000000000000111011010101010; // input=1.955078125, output=0.927067920868
			11'd501: out = 32'b00000000000000000111011001111010; // input=1.958984375, output=0.925596424245
			11'd502: out = 32'b00000000000000000111011001001001; // input=1.962890625, output=0.92411080416
			11'd503: out = 32'b00000000000000000111011000011000; // input=1.966796875, output=0.92261108328
			11'd504: out = 32'b00000000000000000111010111100111; // input=1.970703125, output=0.921097284491
			11'd505: out = 32'b00000000000000000111010110110100; // input=1.974609375, output=0.91956943089
			11'd506: out = 32'b00000000000000000111010110000010; // input=1.978515625, output=0.918027545791
			11'd507: out = 32'b00000000000000000111010101001111; // input=1.982421875, output=0.916471652721
			11'd508: out = 32'b00000000000000000111010100011100; // input=1.986328125, output=0.914901775422
			11'd509: out = 32'b00000000000000000111010011101000; // input=1.990234375, output=0.913317937847
			11'd510: out = 32'b00000000000000000111010010110011; // input=1.994140625, output=0.911720164164
			11'd511: out = 32'b00000000000000000111010001111110; // input=1.998046875, output=0.910108478752
			11'd512: out = 32'b00000000000000000111010001001001; // input=2.001953125, output=0.908482906206
			11'd513: out = 32'b00000000000000000111010000010011; // input=2.005859375, output=0.906843471327
			11'd514: out = 32'b00000000000000000111001111011101; // input=2.009765625, output=0.905190199134
			11'd515: out = 32'b00000000000000000111001110100111; // input=2.013671875, output=0.903523114851
			11'd516: out = 32'b00000000000000000111001101110000; // input=2.017578125, output=0.901842243918
			11'd517: out = 32'b00000000000000000111001100111000; // input=2.021484375, output=0.900147611981
			11'd518: out = 32'b00000000000000000111001100000000; // input=2.025390625, output=0.898439244899
			11'd519: out = 32'b00000000000000000111001011001000; // input=2.029296875, output=0.89671716874
			11'd520: out = 32'b00000000000000000111001010001111; // input=2.033203125, output=0.89498140978
			11'd521: out = 32'b00000000000000000111001001010101; // input=2.037109375, output=0.893231994505
			11'd522: out = 32'b00000000000000000111001000011100; // input=2.041015625, output=0.891468949608
			11'd523: out = 32'b00000000000000000111000111100001; // input=2.044921875, output=0.889692301992
			11'd524: out = 32'b00000000000000000111000110100111; // input=2.048828125, output=0.887902078767
			11'd525: out = 32'b00000000000000000111000101101100; // input=2.052734375, output=0.886098307248
			11'd526: out = 32'b00000000000000000111000100110000; // input=2.056640625, output=0.884281014959
			11'd527: out = 32'b00000000000000000111000011110100; // input=2.060546875, output=0.882450229629
			11'd528: out = 32'b00000000000000000111000010111000; // input=2.064453125, output=0.880605979195
			11'd529: out = 32'b00000000000000000111000001111011; // input=2.068359375, output=0.878748291797
			11'd530: out = 32'b00000000000000000111000000111110; // input=2.072265625, output=0.876877195782
			11'd531: out = 32'b00000000000000000111000000000000; // input=2.076171875, output=0.874992719699
			11'd532: out = 32'b00000000000000000110111111000010; // input=2.080078125, output=0.873094892304
			11'd533: out = 32'b00000000000000000110111110000011; // input=2.083984375, output=0.871183742555
			11'd534: out = 32'b00000000000000000110111101000100; // input=2.087890625, output=0.869259299614
			11'd535: out = 32'b00000000000000000110111100000100; // input=2.091796875, output=0.867321592845
			11'd536: out = 32'b00000000000000000110111011000100; // input=2.095703125, output=0.865370651816
			11'd537: out = 32'b00000000000000000110111010000100; // input=2.099609375, output=0.863406506296
			11'd538: out = 32'b00000000000000000110111001000011; // input=2.103515625, output=0.861429186254
			11'd539: out = 32'b00000000000000000110111000000010; // input=2.107421875, output=0.859438721864
			11'd540: out = 32'b00000000000000000110110111000000; // input=2.111328125, output=0.857435143495
			11'd541: out = 32'b00000000000000000110110101111110; // input=2.115234375, output=0.855418481721
			11'd542: out = 32'b00000000000000000110110100111100; // input=2.119140625, output=0.853388767314
			11'd543: out = 32'b00000000000000000110110011111001; // input=2.123046875, output=0.851346031244
			11'd544: out = 32'b00000000000000000110110010110110; // input=2.126953125, output=0.849290304681
			11'd545: out = 32'b00000000000000000110110001110010; // input=2.130859375, output=0.847221618993
			11'd546: out = 32'b00000000000000000110110000101110; // input=2.134765625, output=0.845140005746
			11'd547: out = 32'b00000000000000000110101111101001; // input=2.138671875, output=0.843045496701
			11'd548: out = 32'b00000000000000000110101110100100; // input=2.142578125, output=0.84093812382
			11'd549: out = 32'b00000000000000000110101101011110; // input=2.146484375, output=0.838817919257
			11'd550: out = 32'b00000000000000000110101100011000; // input=2.150390625, output=0.836684915366
			11'd551: out = 32'b00000000000000000110101011010010; // input=2.154296875, output=0.834539144691
			11'd552: out = 32'b00000000000000000110101010001011; // input=2.158203125, output=0.832380639976
			11'd553: out = 32'b00000000000000000110101001000100; // input=2.162109375, output=0.830209434157
			11'd554: out = 32'b00000000000000000110100111111101; // input=2.166015625, output=0.828025560363
			11'd555: out = 32'b00000000000000000110100110110101; // input=2.169921875, output=0.825829051918
			11'd556: out = 32'b00000000000000000110100101101100; // input=2.173828125, output=0.823619942338
			11'd557: out = 32'b00000000000000000110100100100100; // input=2.177734375, output=0.82139826533
			11'd558: out = 32'b00000000000000000110100011011010; // input=2.181640625, output=0.819164054796
			11'd559: out = 32'b00000000000000000110100010010001; // input=2.185546875, output=0.816917344826
			11'd560: out = 32'b00000000000000000110100001000111; // input=2.189453125, output=0.814658169702
			11'd561: out = 32'b00000000000000000110011111111100; // input=2.193359375, output=0.812386563897
			11'd562: out = 32'b00000000000000000110011110110001; // input=2.197265625, output=0.810102562073
			11'd563: out = 32'b00000000000000000110011101100110; // input=2.201171875, output=0.80780619908
			11'd564: out = 32'b00000000000000000110011100011011; // input=2.205078125, output=0.805497509959
			11'd565: out = 32'b00000000000000000110011011001110; // input=2.208984375, output=0.803176529936
			11'd566: out = 32'b00000000000000000110011010000010; // input=2.212890625, output=0.800843294428
			11'd567: out = 32'b00000000000000000110011000110101; // input=2.216796875, output=0.798497839037
			11'd568: out = 32'b00000000000000000110010111101000; // input=2.220703125, output=0.796140199551
			11'd569: out = 32'b00000000000000000110010110011010; // input=2.224609375, output=0.793770411945
			11'd570: out = 32'b00000000000000000110010101001100; // input=2.228515625, output=0.791388512379
			11'd571: out = 32'b00000000000000000110010011111110; // input=2.232421875, output=0.788994537198
			11'd572: out = 32'b00000000000000000110010010101111; // input=2.236328125, output=0.786588522931
			11'd573: out = 32'b00000000000000000110010001100000; // input=2.240234375, output=0.784170506291
			11'd574: out = 32'b00000000000000000110010000010000; // input=2.244140625, output=0.781740524174
			11'd575: out = 32'b00000000000000000110001111000000; // input=2.248046875, output=0.779298613658
			11'd576: out = 32'b00000000000000000110001101110000; // input=2.251953125, output=0.776844812005
			11'd577: out = 32'b00000000000000000110001100011111; // input=2.255859375, output=0.774379156655
			11'd578: out = 32'b00000000000000000110001011001110; // input=2.259765625, output=0.771901685232
			11'd579: out = 32'b00000000000000000110001001111100; // input=2.263671875, output=0.769412435539
			11'd580: out = 32'b00000000000000000110001000101010; // input=2.267578125, output=0.766911445559
			11'd581: out = 32'b00000000000000000110000111011000; // input=2.271484375, output=0.764398753454
			11'd582: out = 32'b00000000000000000110000110000101; // input=2.275390625, output=0.761874397564
			11'd583: out = 32'b00000000000000000110000100110010; // input=2.279296875, output=0.759338416409
			11'd584: out = 32'b00000000000000000110000011011111; // input=2.283203125, output=0.756790848683
			11'd585: out = 32'b00000000000000000110000010001011; // input=2.287109375, output=0.75423173326
			11'd586: out = 32'b00000000000000000110000000110110; // input=2.291015625, output=0.751661109189
			11'd587: out = 32'b00000000000000000101111111100010; // input=2.294921875, output=0.749079015694
			11'd588: out = 32'b00000000000000000101111110001101; // input=2.298828125, output=0.746485492175
			11'd589: out = 32'b00000000000000000101111100110111; // input=2.302734375, output=0.743880578206
			11'd590: out = 32'b00000000000000000101111011100010; // input=2.306640625, output=0.741264313535
			11'd591: out = 32'b00000000000000000101111010001100; // input=2.310546875, output=0.738636738082
			11'd592: out = 32'b00000000000000000101111000110101; // input=2.314453125, output=0.735997891941
			11'd593: out = 32'b00000000000000000101110111011110; // input=2.318359375, output=0.733347815378
			11'd594: out = 32'b00000000000000000101110110000111; // input=2.322265625, output=0.730686548829
			11'd595: out = 32'b00000000000000000101110100110000; // input=2.326171875, output=0.728014132903
			11'd596: out = 32'b00000000000000000101110011011000; // input=2.330078125, output=0.725330608377
			11'd597: out = 32'b00000000000000000101110001111111; // input=2.333984375, output=0.722636016198
			11'd598: out = 32'b00000000000000000101110000100111; // input=2.337890625, output=0.719930397482
			11'd599: out = 32'b00000000000000000101101111001110; // input=2.341796875, output=0.717213793515
			11'd600: out = 32'b00000000000000000101101101110100; // input=2.345703125, output=0.714486245747
			11'd601: out = 32'b00000000000000000101101100011011; // input=2.349609375, output=0.711747795798
			11'd602: out = 32'b00000000000000000101101011000000; // input=2.353515625, output=0.708998485454
			11'd603: out = 32'b00000000000000000101101001100110; // input=2.357421875, output=0.706238356665
			11'd604: out = 32'b00000000000000000101101000001011; // input=2.361328125, output=0.703467451548
			11'd605: out = 32'b00000000000000000101100110110000; // input=2.365234375, output=0.700685812383
			11'd606: out = 32'b00000000000000000101100101010101; // input=2.369140625, output=0.697893481614
			11'd607: out = 32'b00000000000000000101100011111001; // input=2.373046875, output=0.69509050185
			11'd608: out = 32'b00000000000000000101100010011101; // input=2.376953125, output=0.692276915859
			11'd609: out = 32'b00000000000000000101100001000000; // input=2.380859375, output=0.689452766575
			11'd610: out = 32'b00000000000000000101011111100011; // input=2.384765625, output=0.68661809709
			11'd611: out = 32'b00000000000000000101011110000110; // input=2.388671875, output=0.683772950657
			11'd612: out = 32'b00000000000000000101011100101000; // input=2.392578125, output=0.680917370691
			11'd613: out = 32'b00000000000000000101011011001010; // input=2.396484375, output=0.678051400763
			11'd614: out = 32'b00000000000000000101011001101100; // input=2.400390625, output=0.675175084605
			11'd615: out = 32'b00000000000000000101011000001110; // input=2.404296875, output=0.672288466105
			11'd616: out = 32'b00000000000000000101010110101111; // input=2.408203125, output=0.669391589311
			11'd617: out = 32'b00000000000000000101010101001111; // input=2.412109375, output=0.666484498425
			11'd618: out = 32'b00000000000000000101010011110000; // input=2.416015625, output=0.663567237806
			11'd619: out = 32'b00000000000000000101010010010000; // input=2.419921875, output=0.660639851967
			11'd620: out = 32'b00000000000000000101010000110000; // input=2.423828125, output=0.657702385576
			11'd621: out = 32'b00000000000000000101001111001111; // input=2.427734375, output=0.654754883457
			11'd622: out = 32'b00000000000000000101001101101110; // input=2.431640625, output=0.651797390583
			11'd623: out = 32'b00000000000000000101001100001101; // input=2.435546875, output=0.648829952083
			11'd624: out = 32'b00000000000000000101001010101011; // input=2.439453125, output=0.645852613236
			11'd625: out = 32'b00000000000000000101001001001001; // input=2.443359375, output=0.642865419473
			11'd626: out = 32'b00000000000000000101000111100111; // input=2.447265625, output=0.639868416375
			11'd627: out = 32'b00000000000000000101000110000101; // input=2.451171875, output=0.636861649672
			11'd628: out = 32'b00000000000000000101000100100010; // input=2.455078125, output=0.633845165244
			11'd629: out = 32'b00000000000000000101000010111111; // input=2.458984375, output=0.630819009118
			11'd630: out = 32'b00000000000000000101000001011011; // input=2.462890625, output=0.62778322747
			11'd631: out = 32'b00000000000000000100111111110111; // input=2.466796875, output=0.624737866623
			11'd632: out = 32'b00000000000000000100111110010011; // input=2.470703125, output=0.621682973045
			11'd633: out = 32'b00000000000000000100111100101111; // input=2.474609375, output=0.618618593349
			11'd634: out = 32'b00000000000000000100111011001010; // input=2.478515625, output=0.615544774295
			11'd635: out = 32'b00000000000000000100111001100101; // input=2.482421875, output=0.612461562784
			11'd636: out = 32'b00000000000000000100111000000000; // input=2.486328125, output=0.609369005864
			11'd637: out = 32'b00000000000000000100110110011010; // input=2.490234375, output=0.606267150722
			11'd638: out = 32'b00000000000000000100110100110100; // input=2.494140625, output=0.60315604469
			11'd639: out = 32'b00000000000000000100110011001110; // input=2.498046875, output=0.600035735239
			11'd640: out = 32'b00000000000000000100110001100111; // input=2.501953125, output=0.59690626998
			11'd641: out = 32'b00000000000000000100110000000001; // input=2.505859375, output=0.593767696666
			11'd642: out = 32'b00000000000000000100101110011001; // input=2.509765625, output=0.590620063188
			11'd643: out = 32'b00000000000000000100101100110010; // input=2.513671875, output=0.587463417574
			11'd644: out = 32'b00000000000000000100101011001010; // input=2.517578125, output=0.584297807991
			11'd645: out = 32'b00000000000000000100101001100010; // input=2.521484375, output=0.581123282743
			11'd646: out = 32'b00000000000000000100100111111010; // input=2.525390625, output=0.577939890268
			11'd647: out = 32'b00000000000000000100100110010001; // input=2.529296875, output=0.574747679141
			11'd648: out = 32'b00000000000000000100100100101000; // input=2.533203125, output=0.571546698072
			11'd649: out = 32'b00000000000000000100100010111111; // input=2.537109375, output=0.568336995904
			11'd650: out = 32'b00000000000000000100100001010110; // input=2.541015625, output=0.565118621612
			11'd651: out = 32'b00000000000000000100011111101100; // input=2.544921875, output=0.561891624306
			11'd652: out = 32'b00000000000000000100011110000010; // input=2.548828125, output=0.558656053224
			11'd653: out = 32'b00000000000000000100011100011000; // input=2.552734375, output=0.555411957739
			11'd654: out = 32'b00000000000000000100011010101101; // input=2.556640625, output=0.55215938735
			11'd655: out = 32'b00000000000000000100011001000010; // input=2.560546875, output=0.548898391689
			11'd656: out = 32'b00000000000000000100010111010111; // input=2.564453125, output=0.545629020513
			11'd657: out = 32'b00000000000000000100010101101100; // input=2.568359375, output=0.54235132371
			11'd658: out = 32'b00000000000000000100010100000000; // input=2.572265625, output=0.539065351293
			11'd659: out = 32'b00000000000000000100010010010100; // input=2.576171875, output=0.535771153402
			11'd660: out = 32'b00000000000000000100010000101000; // input=2.580078125, output=0.532468780302
			11'd661: out = 32'b00000000000000000100001110111011; // input=2.583984375, output=0.529158282384
			11'd662: out = 32'b00000000000000000100001101001111; // input=2.587890625, output=0.525839710162
			11'd663: out = 32'b00000000000000000100001011100010; // input=2.591796875, output=0.522513114272
			11'd664: out = 32'b00000000000000000100001001110100; // input=2.595703125, output=0.519178545475
			11'd665: out = 32'b00000000000000000100001000000111; // input=2.599609375, output=0.515836054653
			11'd666: out = 32'b00000000000000000100000110011001; // input=2.603515625, output=0.512485692806
			11'd667: out = 32'b00000000000000000100000100101011; // input=2.607421875, output=0.509127511059
			11'd668: out = 32'b00000000000000000100000010111101; // input=2.611328125, output=0.505761560652
			11'd669: out = 32'b00000000000000000100000001001110; // input=2.615234375, output=0.502387892946
			11'd670: out = 32'b00000000000000000011111111011111; // input=2.619140625, output=0.499006559419
			11'd671: out = 32'b00000000000000000011111101110000; // input=2.623046875, output=0.495617611666
			11'd672: out = 32'b00000000000000000011111100000001; // input=2.626953125, output=0.492221101398
			11'd673: out = 32'b00000000000000000011111010010010; // input=2.630859375, output=0.488817080442
			11'd674: out = 32'b00000000000000000011111000100010; // input=2.634765625, output=0.485405600738
			11'd675: out = 32'b00000000000000000011110110110010; // input=2.638671875, output=0.481986714342
			11'd676: out = 32'b00000000000000000011110101000001; // input=2.642578125, output=0.478560473421
			11'd677: out = 32'b00000000000000000011110011010001; // input=2.646484375, output=0.475126930257
			11'd678: out = 32'b00000000000000000011110001100000; // input=2.650390625, output=0.47168613724
			11'd679: out = 32'b00000000000000000011101111101111; // input=2.654296875, output=0.468238146873
			11'd680: out = 32'b00000000000000000011101101111110; // input=2.658203125, output=0.464783011769
			11'd681: out = 32'b00000000000000000011101100001101; // input=2.662109375, output=0.461320784647
			11'd682: out = 32'b00000000000000000011101010011011; // input=2.666015625, output=0.457851518337
			11'd683: out = 32'b00000000000000000011101000101001; // input=2.669921875, output=0.454375265777
			11'd684: out = 32'b00000000000000000011100110110111; // input=2.673828125, output=0.450892080009
			11'd685: out = 32'b00000000000000000011100101000100; // input=2.677734375, output=0.447402014183
			11'd686: out = 32'b00000000000000000011100011010010; // input=2.681640625, output=0.443905121553
			11'd687: out = 32'b00000000000000000011100001011111; // input=2.685546875, output=0.440401455476
			11'd688: out = 32'b00000000000000000011011111101100; // input=2.689453125, output=0.436891069416
			11'd689: out = 32'b00000000000000000011011101111001; // input=2.693359375, output=0.433374016935
			11'd690: out = 32'b00000000000000000011011100000101; // input=2.697265625, output=0.429850351699
			11'd691: out = 32'b00000000000000000011011010010010; // input=2.701171875, output=0.426320127476
			11'd692: out = 32'b00000000000000000011011000011110; // input=2.705078125, output=0.422783398133
			11'd693: out = 32'b00000000000000000011010110101010; // input=2.708984375, output=0.419240217635
			11'd694: out = 32'b00000000000000000011010100110101; // input=2.712890625, output=0.415690640047
			11'd695: out = 32'b00000000000000000011010011000001; // input=2.716796875, output=0.412134719532
			11'd696: out = 32'b00000000000000000011010001001100; // input=2.720703125, output=0.408572510347
			11'd697: out = 32'b00000000000000000011001111010111; // input=2.724609375, output=0.405004066849
			11'd698: out = 32'b00000000000000000011001101100010; // input=2.728515625, output=0.401429443487
			11'd699: out = 32'b00000000000000000011001011101101; // input=2.732421875, output=0.397848694806
			11'd700: out = 32'b00000000000000000011001001110111; // input=2.736328125, output=0.394261875443
			11'd701: out = 32'b00000000000000000011001000000001; // input=2.740234375, output=0.390669040129
			11'd702: out = 32'b00000000000000000011000110001100; // input=2.744140625, output=0.387070243686
			11'd703: out = 32'b00000000000000000011000100010101; // input=2.748046875, output=0.383465541027
			11'd704: out = 32'b00000000000000000011000010011111; // input=2.751953125, output=0.379854987156
			11'd705: out = 32'b00000000000000000011000000101001; // input=2.755859375, output=0.376238637166
			11'd706: out = 32'b00000000000000000010111110110010; // input=2.759765625, output=0.372616546236
			11'd707: out = 32'b00000000000000000010111100111011; // input=2.763671875, output=0.368988769637
			11'd708: out = 32'b00000000000000000010111011000100; // input=2.767578125, output=0.365355362723
			11'd709: out = 32'b00000000000000000010111001001101; // input=2.771484375, output=0.361716380935
			11'd710: out = 32'b00000000000000000010110111010101; // input=2.775390625, output=0.358071879801
			11'd711: out = 32'b00000000000000000010110101011110; // input=2.779296875, output=0.35442191493
			11'd712: out = 32'b00000000000000000010110011100110; // input=2.783203125, output=0.350766542017
			11'd713: out = 32'b00000000000000000010110001101110; // input=2.787109375, output=0.347105816838
			11'd714: out = 32'b00000000000000000010101111110110; // input=2.791015625, output=0.343439795251
			11'd715: out = 32'b00000000000000000010101101111110; // input=2.794921875, output=0.339768533196
			11'd716: out = 32'b00000000000000000010101100000101; // input=2.798828125, output=0.336092086691
			11'd717: out = 32'b00000000000000000010101010001100; // input=2.802734375, output=0.332410511834
			11'd718: out = 32'b00000000000000000010101000010100; // input=2.806640625, output=0.328723864801
			11'd719: out = 32'b00000000000000000010100110011011; // input=2.810546875, output=0.325032201847
			11'd720: out = 32'b00000000000000000010100100100010; // input=2.814453125, output=0.321335579302
			11'd721: out = 32'b00000000000000000010100010101000; // input=2.818359375, output=0.31763405357
			11'd722: out = 32'b00000000000000000010100000101111; // input=2.822265625, output=0.313927681134
			11'd723: out = 32'b00000000000000000010011110110101; // input=2.826171875, output=0.310216518548
			11'd724: out = 32'b00000000000000000010011100111011; // input=2.830078125, output=0.306500622439
			11'd725: out = 32'b00000000000000000010011011000001; // input=2.833984375, output=0.302780049508
			11'd726: out = 32'b00000000000000000010011001000111; // input=2.837890625, output=0.299054856526
			11'd727: out = 32'b00000000000000000010010111001101; // input=2.841796875, output=0.295325100335
			11'd728: out = 32'b00000000000000000010010101010011; // input=2.845703125, output=0.291590837846
			11'd729: out = 32'b00000000000000000010010011011000; // input=2.849609375, output=0.28785212604
			11'd730: out = 32'b00000000000000000010010001011110; // input=2.853515625, output=0.284109021964
			11'd731: out = 32'b00000000000000000010001111100011; // input=2.857421875, output=0.280361582734
			11'd732: out = 32'b00000000000000000010001101101000; // input=2.861328125, output=0.276609865532
			11'd733: out = 32'b00000000000000000010001011101101; // input=2.865234375, output=0.272853927603
			11'd734: out = 32'b00000000000000000010001001110010; // input=2.869140625, output=0.269093826259
			11'd735: out = 32'b00000000000000000010000111110110; // input=2.873046875, output=0.265329618874
			11'd736: out = 32'b00000000000000000010000101111011; // input=2.876953125, output=0.261561362886
			11'd737: out = 32'b00000000000000000010000011111111; // input=2.880859375, output=0.257789115793
			11'd738: out = 32'b00000000000000000010000010000011; // input=2.884765625, output=0.254012935156
			11'd739: out = 32'b00000000000000000010000000001000; // input=2.888671875, output=0.250232878593
			11'd740: out = 32'b00000000000000000001111110001100; // input=2.892578125, output=0.246449003785
			11'd741: out = 32'b00000000000000000001111100010000; // input=2.896484375, output=0.242661368468
			11'd742: out = 32'b00000000000000000001111010010011; // input=2.900390625, output=0.238870030437
			11'd743: out = 32'b00000000000000000001111000010111; // input=2.904296875, output=0.235075047543
			11'd744: out = 32'b00000000000000000001110110011010; // input=2.908203125, output=0.231276477694
			11'd745: out = 32'b00000000000000000001110100011110; // input=2.912109375, output=0.22747437885
			11'd746: out = 32'b00000000000000000001110010100001; // input=2.916015625, output=0.223668809027
			11'd747: out = 32'b00000000000000000001110000100100; // input=2.919921875, output=0.219859826292
			11'd748: out = 32'b00000000000000000001101110100111; // input=2.923828125, output=0.216047488768
			11'd749: out = 32'b00000000000000000001101100101010; // input=2.927734375, output=0.212231854624
			11'd750: out = 32'b00000000000000000001101010101101; // input=2.931640625, output=0.208412982084
			11'd751: out = 32'b00000000000000000001101000110000; // input=2.935546875, output=0.204590929418
			11'd752: out = 32'b00000000000000000001100110110011; // input=2.939453125, output=0.200765754946
			11'd753: out = 32'b00000000000000000001100100110101; // input=2.943359375, output=0.196937517036
			11'd754: out = 32'b00000000000000000001100010111000; // input=2.947265625, output=0.193106274101
			11'd755: out = 32'b00000000000000000001100000111010; // input=2.951171875, output=0.189272084602
			11'd756: out = 32'b00000000000000000001011110111100; // input=2.955078125, output=0.185435007044
			11'd757: out = 32'b00000000000000000001011100111111; // input=2.958984375, output=0.181595099977
			11'd758: out = 32'b00000000000000000001011011000001; // input=2.962890625, output=0.177752421991
			11'd759: out = 32'b00000000000000000001011001000011; // input=2.966796875, output=0.173907031722
			11'd760: out = 32'b00000000000000000001010111000100; // input=2.970703125, output=0.170058987846
			11'd761: out = 32'b00000000000000000001010101000110; // input=2.974609375, output=0.166208349078
			11'd762: out = 32'b00000000000000000001010011001000; // input=2.978515625, output=0.162355174176
			11'd763: out = 32'b00000000000000000001010001001010; // input=2.982421875, output=0.158499521934
			11'd764: out = 32'b00000000000000000001001111001011; // input=2.986328125, output=0.154641451184
			11'd765: out = 32'b00000000000000000001001101001101; // input=2.990234375, output=0.150781020795
			11'd766: out = 32'b00000000000000000001001011001110; // input=2.994140625, output=0.146918289674
			11'd767: out = 32'b00000000000000000001001001010000; // input=2.998046875, output=0.14305331676
			11'd768: out = 32'b00000000000000000001000111010001; // input=3.001953125, output=0.139186161029
			11'd769: out = 32'b00000000000000000001000101010010; // input=3.005859375, output=0.135316881489
			11'd770: out = 32'b00000000000000000001000011010011; // input=3.009765625, output=0.131445537179
			11'd771: out = 32'b00000000000000000001000001010100; // input=3.013671875, output=0.127572187172
			11'd772: out = 32'b00000000000000000000111111010101; // input=3.017578125, output=0.12369689057
			11'd773: out = 32'b00000000000000000000111101010110; // input=3.021484375, output=0.119819706506
			11'd774: out = 32'b00000000000000000000111011010111; // input=3.025390625, output=0.115940694141
			11'd775: out = 32'b00000000000000000000111001011000; // input=3.029296875, output=0.112059912663
			11'd776: out = 32'b00000000000000000000110111011001; // input=3.033203125, output=0.108177421289
			11'd777: out = 32'b00000000000000000000110101011001; // input=3.037109375, output=0.10429327926
			11'd778: out = 32'b00000000000000000000110011011010; // input=3.041015625, output=0.100407545845
			11'd779: out = 32'b00000000000000000000110001011011; // input=3.044921875, output=0.0965202803338
			11'd780: out = 32'b00000000000000000000101111011011; // input=3.048828125, output=0.0926315420419
			11'd781: out = 32'b00000000000000000000101101011100; // input=3.052734375, output=0.0887413903066
			11'd782: out = 32'b00000000000000000000101011011100; // input=3.056640625, output=0.0848498844869
			11'd783: out = 32'b00000000000000000000101001011101; // input=3.060546875, output=0.0809570839624
			11'd784: out = 32'b00000000000000000000100111011101; // input=3.064453125, output=0.0770630481324
			11'd785: out = 32'b00000000000000000000100101011110; // input=3.068359375, output=0.0731678364151
			11'd786: out = 32'b00000000000000000000100011011110; // input=3.072265625, output=0.0692715082466
			11'd787: out = 32'b00000000000000000000100001011110; // input=3.076171875, output=0.0653741230801
			11'd788: out = 32'b00000000000000000000011111011110; // input=3.080078125, output=0.061475740385
			11'd789: out = 32'b00000000000000000000011101011111; // input=3.083984375, output=0.0575764196456
			11'd790: out = 32'b00000000000000000000011011011111; // input=3.087890625, output=0.053676220361
			11'd791: out = 32'b00000000000000000000011001011111; // input=3.091796875, output=0.0497752020432
			11'd792: out = 32'b00000000000000000000010111011111; // input=3.095703125, output=0.0458734242172
			11'd793: out = 32'b00000000000000000000010101011111; // input=3.099609375, output=0.0419709464191
			11'd794: out = 32'b00000000000000000000010011011111; // input=3.103515625, output=0.038067828196
			11'd795: out = 32'b00000000000000000000010001011111; // input=3.107421875, output=0.0341641291047
			11'd796: out = 32'b00000000000000000000001111100000; // input=3.111328125, output=0.0302599087108
			11'd797: out = 32'b00000000000000000000001101100000; // input=3.115234375, output=0.0263552265879
			11'd798: out = 32'b00000000000000000000001011100000; // input=3.119140625, output=0.0224501423167
			11'd799: out = 32'b00000000000000000000001001100000; // input=3.123046875, output=0.018544715484
			11'd800: out = 32'b00000000000000000000000111100000; // input=3.126953125, output=0.0146390056817
			11'd801: out = 32'b00000000000000000000000101100000; // input=3.130859375, output=0.0107330725062
			11'd802: out = 32'b00000000000000000000000011100000; // input=3.134765625, output=0.0068269755572
			11'd803: out = 32'b00000000000000000000000001100000; // input=3.138671875, output=0.00292077443696
			11'd804: out = 32'b10000000000000000000000000100000; // input=3.142578125, output=-0.000985471250699
			11'd805: out = 32'b10000000000000000000000010100000; // input=3.146484375, output=-0.00489170190128
			11'd806: out = 32'b10000000000000000000000100100000; // input=3.150390625, output=-0.00879785791051
			11'd807: out = 32'b10000000000000000000000110100000; // input=3.154296875, output=-0.0127038796752
			11'd808: out = 32'b10000000000000000000001000100000; // input=3.158203125, output=-0.0166097075944
			11'd809: out = 32'b10000000000000000000001010100000; // input=3.162109375, output=-0.0205152820699
			11'd810: out = 32'b10000000000000000000001100100000; // input=3.166015625, output=-0.0244205435074
			11'd811: out = 32'b10000000000000000000001110100000; // input=3.169921875, output=-0.0283254323174
			11'd812: out = 32'b10000000000000000000010000100000; // input=3.173828125, output=-0.0322298889162
			11'd813: out = 32'b10000000000000000000010010100000; // input=3.177734375, output=-0.0361338537266
			11'd814: out = 32'b10000000000000000000010100100000; // input=3.181640625, output=-0.0400372671788
			11'd815: out = 32'b10000000000000000000010110100000; // input=3.185546875, output=-0.0439400697116
			11'd816: out = 32'b10000000000000000000011000100000; // input=3.189453125, output=-0.0478422017729
			11'd817: out = 32'b10000000000000000000011010100000; // input=3.193359375, output=-0.0517436038212
			11'd818: out = 32'b10000000000000000000011100011111; // input=3.197265625, output=-0.0556442163256
			11'd819: out = 32'b10000000000000000000011110011111; // input=3.201171875, output=-0.0595439797679
			11'd820: out = 32'b10000000000000000000100000011111; // input=3.205078125, output=-0.0634428346422
			11'd821: out = 32'b10000000000000000000100010011111; // input=3.208984375, output=-0.0673407214569
			11'd822: out = 32'b10000000000000000000100100011110; // input=3.212890625, output=-0.0712375807351
			11'd823: out = 32'b10000000000000000000100110011110; // input=3.216796875, output=-0.0751333530155
			11'd824: out = 32'b10000000000000000000101000011110; // input=3.220703125, output=-0.0790279788533
			11'd825: out = 32'b10000000000000000000101010011101; // input=3.224609375, output=-0.0829213988214
			11'd826: out = 32'b10000000000000000000101100011101; // input=3.228515625, output=-0.086813553511
			11'd827: out = 32'b10000000000000000000101110011100; // input=3.232421875, output=-0.0907043835325
			11'd828: out = 32'b10000000000000000000110000011100; // input=3.236328125, output=-0.0945938295168
			11'd829: out = 32'b10000000000000000000110010011011; // input=3.240234375, output=-0.0984818321156
			11'd830: out = 32'b10000000000000000000110100011010; // input=3.244140625, output=-0.102368332003
			11'd831: out = 32'b10000000000000000000110110011010; // input=3.248046875, output=-0.106253269875
			11'd832: out = 32'b10000000000000000000111000011001; // input=3.251953125, output=-0.110136586453
			11'd833: out = 32'b10000000000000000000111010011000; // input=3.255859375, output=-0.114018222483
			11'd834: out = 32'b10000000000000000000111100010111; // input=3.259765625, output=-0.117898118735
			11'd835: out = 32'b10000000000000000000111110010110; // input=3.263671875, output=-0.121776216006
			11'd836: out = 32'b10000000000000000001000000010101; // input=3.267578125, output=-0.125652455122
			11'd837: out = 32'b10000000000000000001000010010100; // input=3.271484375, output=-0.129526776936
			11'd838: out = 32'b10000000000000000001000100010011; // input=3.275390625, output=-0.133399122331
			11'd839: out = 32'b10000000000000000001000110010010; // input=3.279296875, output=-0.13726943222
			11'd840: out = 32'b10000000000000000001001000010001; // input=3.283203125, output=-0.141137647546
			11'd841: out = 32'b10000000000000000001001010001111; // input=3.287109375, output=-0.145003709285
			11'd842: out = 32'b10000000000000000001001100001110; // input=3.291015625, output=-0.148867558446
			11'd843: out = 32'b10000000000000000001001110001101; // input=3.294921875, output=-0.152729136071
			11'd844: out = 32'b10000000000000000001010000001011; // input=3.298828125, output=-0.156588383237
			11'd845: out = 32'b10000000000000000001010010001001; // input=3.302734375, output=-0.160445241058
			11'd846: out = 32'b10000000000000000001010100001000; // input=3.306640625, output=-0.164299650681
			11'd847: out = 32'b10000000000000000001010110000110; // input=3.310546875, output=-0.168151553294
			11'd848: out = 32'b10000000000000000001011000000100; // input=3.314453125, output=-0.172000890121
			11'd849: out = 32'b10000000000000000001011010000010; // input=3.318359375, output=-0.175847602426
			11'd850: out = 32'b10000000000000000001011100000000; // input=3.322265625, output=-0.179691631513
			11'd851: out = 32'b10000000000000000001011101111110; // input=3.326171875, output=-0.183532918727
			11'd852: out = 32'b10000000000000000001011111111100; // input=3.330078125, output=-0.187371405454
			11'd853: out = 32'b10000000000000000001100001111001; // input=3.333984375, output=-0.191207033124
			11'd854: out = 32'b10000000000000000001100011110111; // input=3.337890625, output=-0.19503974321
			11'd855: out = 32'b10000000000000000001100101110101; // input=3.341796875, output=-0.198869477229
			11'd856: out = 32'b10000000000000000001100111110010; // input=3.345703125, output=-0.202696176745
			11'd857: out = 32'b10000000000000000001101001101111; // input=3.349609375, output=-0.206519783367
			11'd858: out = 32'b10000000000000000001101011101100; // input=3.353515625, output=-0.210340238751
			11'd859: out = 32'b10000000000000000001101101101010; // input=3.357421875, output=-0.214157484602
			11'd860: out = 32'b10000000000000000001101111100110; // input=3.361328125, output=-0.217971462672
			11'd861: out = 32'b10000000000000000001110001100011; // input=3.365234375, output=-0.221782114767
			11'd862: out = 32'b10000000000000000001110011100000; // input=3.369140625, output=-0.225589382739
			11'd863: out = 32'b10000000000000000001110101011101; // input=3.373046875, output=-0.229393208495
			11'd864: out = 32'b10000000000000000001110111011001; // input=3.376953125, output=-0.233193533993
			11'd865: out = 32'b10000000000000000001111001010110; // input=3.380859375, output=-0.236990301245
			11'd866: out = 32'b10000000000000000001111011010010; // input=3.384765625, output=-0.240783452315
			11'd867: out = 32'b10000000000000000001111101001110; // input=3.388671875, output=-0.244572929327
			11'd868: out = 32'b10000000000000000001111111001010; // input=3.392578125, output=-0.248358674457
			11'd869: out = 32'b10000000000000000010000001000110; // input=3.396484375, output=-0.252140629939
			11'd870: out = 32'b10000000000000000010000011000010; // input=3.400390625, output=-0.255918738065
			11'd871: out = 32'b10000000000000000010000100111110; // input=3.404296875, output=-0.259692941186
			11'd872: out = 32'b10000000000000000010000110111001; // input=3.408203125, output=-0.263463181712
			11'd873: out = 32'b10000000000000000010001000110101; // input=3.412109375, output=-0.267229402115
			11'd874: out = 32'b10000000000000000010001010110000; // input=3.416015625, output=-0.270991544925
			11'd875: out = 32'b10000000000000000010001100101011; // input=3.419921875, output=-0.274749552738
			11'd876: out = 32'b10000000000000000010001110100110; // input=3.423828125, output=-0.27850336821
			11'd877: out = 32'b10000000000000000010010000100001; // input=3.427734375, output=-0.282252934064
			11'd878: out = 32'b10000000000000000010010010011100; // input=3.431640625, output=-0.285998193086
			11'd879: out = 32'b10000000000000000010010100010110; // input=3.435546875, output=-0.289739088127
			11'd880: out = 32'b10000000000000000010010110010001; // input=3.439453125, output=-0.293475562106
			11'd881: out = 32'b10000000000000000010011000001011; // input=3.443359375, output=-0.297207558008
			11'd882: out = 32'b10000000000000000010011010000101; // input=3.447265625, output=-0.30093501889
			11'd883: out = 32'b10000000000000000010011011111111; // input=3.451171875, output=-0.304657887873
			11'd884: out = 32'b10000000000000000010011101111001; // input=3.455078125, output=-0.308376108151
			11'd885: out = 32'b10000000000000000010011111110011; // input=3.458984375, output=-0.31208962299
			11'd886: out = 32'b10000000000000000010100001101100; // input=3.462890625, output=-0.315798375725
			11'd887: out = 32'b10000000000000000010100011100101; // input=3.466796875, output=-0.319502309765
			11'd888: out = 32'b10000000000000000010100101011111; // input=3.470703125, output=-0.323201368593
			11'd889: out = 32'b10000000000000000010100111011000; // input=3.474609375, output=-0.326895495766
			11'd890: out = 32'b10000000000000000010101001010001; // input=3.478515625, output=-0.330584634915
			11'd891: out = 32'b10000000000000000010101011001001; // input=3.482421875, output=-0.33426872975
			11'd892: out = 32'b10000000000000000010101101000010; // input=3.486328125, output=-0.337947724056
			11'd893: out = 32'b10000000000000000010101110111010; // input=3.490234375, output=-0.341621561694
			11'd894: out = 32'b10000000000000000010110000110010; // input=3.494140625, output=-0.345290186609
			11'd895: out = 32'b10000000000000000010110010101011; // input=3.498046875, output=-0.348953542819
			11'd896: out = 32'b10000000000000000010110100100010; // input=3.501953125, output=-0.352611574428
			11'd897: out = 32'b10000000000000000010110110011010; // input=3.505859375, output=-0.356264225619
			11'd898: out = 32'b10000000000000000010111000010010; // input=3.509765625, output=-0.359911440655
			11'd899: out = 32'b10000000000000000010111010001001; // input=3.513671875, output=-0.363553163886
			11'd900: out = 32'b10000000000000000010111100000000; // input=3.517578125, output=-0.367189339743
			11'd901: out = 32'b10000000000000000010111101110111; // input=3.521484375, output=-0.370819912742
			11'd902: out = 32'b10000000000000000010111111101110; // input=3.525390625, output=-0.374444827485
			11'd903: out = 32'b10000000000000000011000001100100; // input=3.529296875, output=-0.378064028661
			11'd904: out = 32'b10000000000000000011000011011011; // input=3.533203125, output=-0.381677461046
			11'd905: out = 32'b10000000000000000011000101010001; // input=3.537109375, output=-0.385285069501
			11'd906: out = 32'b10000000000000000011000111000111; // input=3.541015625, output=-0.388886798981
			11'd907: out = 32'b10000000000000000011001000111101; // input=3.544921875, output=-0.392482594526
			11'd908: out = 32'b10000000000000000011001010110011; // input=3.548828125, output=-0.39607240127
			11'd909: out = 32'b10000000000000000011001100101000; // input=3.552734375, output=-0.399656164437
			11'd910: out = 32'b10000000000000000011001110011101; // input=3.556640625, output=-0.403233829342
			11'd911: out = 32'b10000000000000000011010000010010; // input=3.560546875, output=-0.406805341395
			11'd912: out = 32'b10000000000000000011010010000111; // input=3.564453125, output=-0.410370646099
			11'd913: out = 32'b10000000000000000011010011111100; // input=3.568359375, output=-0.413929689052
			11'd914: out = 32'b10000000000000000011010101110000; // input=3.572265625, output=-0.417482415947
			11'd915: out = 32'b10000000000000000011010111100100; // input=3.576171875, output=-0.421028772574
			11'd916: out = 32'b10000000000000000011011001011000; // input=3.580078125, output=-0.42456870482
			11'd917: out = 32'b10000000000000000011011011001100; // input=3.583984375, output=-0.42810215867
			11'd918: out = 32'b10000000000000000011011101000000; // input=3.587890625, output=-0.431629080208
			11'd919: out = 32'b10000000000000000011011110110011; // input=3.591796875, output=-0.435149415617
			11'd920: out = 32'b10000000000000000011100000100110; // input=3.595703125, output=-0.438663111181
			11'd921: out = 32'b10000000000000000011100010011001; // input=3.599609375, output=-0.442170113286
			11'd922: out = 32'b10000000000000000011100100001100; // input=3.603515625, output=-0.445670368419
			11'd923: out = 32'b10000000000000000011100101111110; // input=3.607421875, output=-0.44916382317
			11'd924: out = 32'b10000000000000000011100111110000; // input=3.611328125, output=-0.452650424234
			11'd925: out = 32'b10000000000000000011101001100010; // input=3.615234375, output=-0.45613011841
			11'd926: out = 32'b10000000000000000011101011010100; // input=3.619140625, output=-0.459602852601
			11'd927: out = 32'b10000000000000000011101101000110; // input=3.623046875, output=-0.463068573818
			11'd928: out = 32'b10000000000000000011101110110111; // input=3.626953125, output=-0.466527229179
			11'd929: out = 32'b10000000000000000011110000101000; // input=3.630859375, output=-0.469978765908
			11'd930: out = 32'b10000000000000000011110010011001; // input=3.634765625, output=-0.473423131339
			11'd931: out = 32'b10000000000000000011110100001010; // input=3.638671875, output=-0.476860272915
			11'd932: out = 32'b10000000000000000011110101111010; // input=3.642578125, output=-0.480290138191
			11'd933: out = 32'b10000000000000000011110111101010; // input=3.646484375, output=-0.48371267483
			11'd934: out = 32'b10000000000000000011111001011010; // input=3.650390625, output=-0.487127830609
			11'd935: out = 32'b10000000000000000011111011001010; // input=3.654296875, output=-0.490535553416
			11'd936: out = 32'b10000000000000000011111100111001; // input=3.658203125, output=-0.493935791254
			11'd937: out = 32'b10000000000000000011111110101000; // input=3.662109375, output=-0.49732849224
			11'd938: out = 32'b10000000000000000100000000010111; // input=3.666015625, output=-0.500713604605
			11'd939: out = 32'b10000000000000000100000010000110; // input=3.669921875, output=-0.504091076697
			11'd940: out = 32'b10000000000000000100000011110100; // input=3.673828125, output=-0.507460856978
			11'd941: out = 32'b10000000000000000100000101100011; // input=3.677734375, output=-0.510822894032
			11'd942: out = 32'b10000000000000000100000111010001; // input=3.681640625, output=-0.514177136557
			11'd943: out = 32'b10000000000000000100001000111110; // input=3.685546875, output=-0.517523533371
			11'd944: out = 32'b10000000000000000100001010101100; // input=3.689453125, output=-0.520862033412
			11'd945: out = 32'b10000000000000000100001100011001; // input=3.693359375, output=-0.52419258574
			11'd946: out = 32'b10000000000000000100001110000110; // input=3.697265625, output=-0.527515139534
			11'd947: out = 32'b10000000000000000100001111110010; // input=3.701171875, output=-0.530829644096
			11'd948: out = 32'b10000000000000000100010001011111; // input=3.705078125, output=-0.534136048851
			11'd949: out = 32'b10000000000000000100010011001011; // input=3.708984375, output=-0.537434303347
			11'd950: out = 32'b10000000000000000100010100110110; // input=3.712890625, output=-0.540724357256
			11'd951: out = 32'b10000000000000000100010110100010; // input=3.716796875, output=-0.544006160377
			11'd952: out = 32'b10000000000000000100011000001101; // input=3.720703125, output=-0.547279662634
			11'd953: out = 32'b10000000000000000100011001111000; // input=3.724609375, output=-0.550544814076
			11'd954: out = 32'b10000000000000000100011011100011; // input=3.728515625, output=-0.553801564881
			11'd955: out = 32'b10000000000000000100011101001101; // input=3.732421875, output=-0.557049865356
			11'd956: out = 32'b10000000000000000100011110111000; // input=3.736328125, output=-0.560289665936
			11'd957: out = 32'b10000000000000000100100000100001; // input=3.740234375, output=-0.563520917184
			11'd958: out = 32'b10000000000000000100100010001011; // input=3.744140625, output=-0.566743569797
			11'd959: out = 32'b10000000000000000100100011110100; // input=3.748046875, output=-0.5699575746
			11'd960: out = 32'b10000000000000000100100101011101; // input=3.751953125, output=-0.573162882552
			11'd961: out = 32'b10000000000000000100100111000110; // input=3.755859375, output=-0.576359444743
			11'd962: out = 32'b10000000000000000100101000101111; // input=3.759765625, output=-0.579547212398
			11'd963: out = 32'b10000000000000000100101010010111; // input=3.763671875, output=-0.582726136876
			11'd964: out = 32'b10000000000000000100101011111111; // input=3.767578125, output=-0.58589616967
			11'd965: out = 32'b10000000000000000100101101100110; // input=3.771484375, output=-0.58905726241
			11'd966: out = 32'b10000000000000000100101111001110; // input=3.775390625, output=-0.59220936686
			11'd967: out = 32'b10000000000000000100110000110101; // input=3.779296875, output=-0.595352434924
			11'd968: out = 32'b10000000000000000100110010011011; // input=3.783203125, output=-0.598486418642
			11'd969: out = 32'b10000000000000000100110100000010; // input=3.787109375, output=-0.601611270194
			11'd970: out = 32'b10000000000000000100110101101000; // input=3.791015625, output=-0.604726941898
			11'd971: out = 32'b10000000000000000100110111001101; // input=3.794921875, output=-0.607833386213
			11'd972: out = 32'b10000000000000000100111000110011; // input=3.798828125, output=-0.610930555738
			11'd973: out = 32'b10000000000000000100111010011000; // input=3.802734375, output=-0.614018403215
			11'd974: out = 32'b10000000000000000100111011111101; // input=3.806640625, output=-0.617096881526
			11'd975: out = 32'b10000000000000000100111101100010; // input=3.810546875, output=-0.620165943698
			11'd976: out = 32'b10000000000000000100111111000110; // input=3.814453125, output=-0.623225542901
			11'd977: out = 32'b10000000000000000101000000101010; // input=3.818359375, output=-0.626275632449
			11'd978: out = 32'b10000000000000000101000010001101; // input=3.822265625, output=-0.629316165801
			11'd979: out = 32'b10000000000000000101000011110001; // input=3.826171875, output=-0.632347096563
			11'd980: out = 32'b10000000000000000101000101010100; // input=3.830078125, output=-0.635368378486
			11'd981: out = 32'b10000000000000000101000110110110; // input=3.833984375, output=-0.638379965469
			11'd982: out = 32'b10000000000000000101001000011001; // input=3.837890625, output=-0.64138181156
			11'd983: out = 32'b10000000000000000101001001111011; // input=3.841796875, output=-0.644373870953
			11'd984: out = 32'b10000000000000000101001011011101; // input=3.845703125, output=-0.647356097993
			11'd985: out = 32'b10000000000000000101001100111110; // input=3.849609375, output=-0.650328447176
			11'd986: out = 32'b10000000000000000101001110011111; // input=3.853515625, output=-0.653290873148
			11'd987: out = 32'b10000000000000000101010000000000; // input=3.857421875, output=-0.656243330704
			11'd988: out = 32'b10000000000000000101010001100000; // input=3.861328125, output=-0.659185774794
			11'd989: out = 32'b10000000000000000101010011000000; // input=3.865234375, output=-0.662118160521
			11'd990: out = 32'b10000000000000000101010100100000; // input=3.869140625, output=-0.665040443139
			11'd991: out = 32'b10000000000000000101010101111111; // input=3.873046875, output=-0.667952578058
			11'd992: out = 32'b10000000000000000101010111011111; // input=3.876953125, output=-0.670854520842
			11'd993: out = 32'b10000000000000000101011000111101; // input=3.880859375, output=-0.673746227212
			11'd994: out = 32'b10000000000000000101011010011100; // input=3.884765625, output=-0.676627653043
			11'd995: out = 32'b10000000000000000101011011111010; // input=3.888671875, output=-0.679498754369
			11'd996: out = 32'b10000000000000000101011101011000; // input=3.892578125, output=-0.68235948738
			11'd997: out = 32'b10000000000000000101011110110101; // input=3.896484375, output=-0.685209808425
			11'd998: out = 32'b10000000000000000101100000010010; // input=3.900390625, output=-0.688049674011
			11'd999: out = 32'b10000000000000000101100001101111; // input=3.904296875, output=-0.690879040805
			11'd1000: out = 32'b10000000000000000101100011001011; // input=3.908203125, output=-0.693697865636
			11'd1001: out = 32'b10000000000000000101100100100111; // input=3.912109375, output=-0.69650610549
			11'd1002: out = 32'b10000000000000000101100110000011; // input=3.916015625, output=-0.699303717518
			11'd1003: out = 32'b10000000000000000101100111011110; // input=3.919921875, output=-0.702090659032
			11'd1004: out = 32'b10000000000000000101101000111001; // input=3.923828125, output=-0.704866887506
			11'd1005: out = 32'b10000000000000000101101010010100; // input=3.927734375, output=-0.707632360579
			11'd1006: out = 32'b10000000000000000101101011101110; // input=3.931640625, output=-0.710387036053
			11'd1007: out = 32'b10000000000000000101101101001000; // input=3.935546875, output=-0.713130871894
			11'd1008: out = 32'b10000000000000000101101110100001; // input=3.939453125, output=-0.715863826236
			11'd1009: out = 32'b10000000000000000101101111111011; // input=3.943359375, output=-0.718585857376
			11'd1010: out = 32'b10000000000000000101110001010011; // input=3.947265625, output=-0.72129692378
			11'd1011: out = 32'b10000000000000000101110010101100; // input=3.951171875, output=-0.723996984081
			11'd1012: out = 32'b10000000000000000101110100000100; // input=3.955078125, output=-0.726685997079
			11'd1013: out = 32'b10000000000000000101110101011100; // input=3.958984375, output=-0.729363921742
			11'd1014: out = 32'b10000000000000000101110110110011; // input=3.962890625, output=-0.732030717209
			11'd1015: out = 32'b10000000000000000101111000001010; // input=3.966796875, output=-0.734686342788
			11'd1016: out = 32'b10000000000000000101111001100001; // input=3.970703125, output=-0.737330757958
			11'd1017: out = 32'b10000000000000000101111010110111; // input=3.974609375, output=-0.739963922367
			11'd1018: out = 32'b10000000000000000101111100001101; // input=3.978515625, output=-0.742585795837
			11'd1019: out = 32'b10000000000000000101111101100011; // input=3.982421875, output=-0.745196338362
			11'd1020: out = 32'b10000000000000000101111110111000; // input=3.986328125, output=-0.747795510107
			11'd1021: out = 32'b10000000000000000110000000001101; // input=3.990234375, output=-0.750383271413
			11'd1022: out = 32'b10000000000000000110000001100001; // input=3.994140625, output=-0.752959582793
			11'd1023: out = 32'b10000000000000000110000010110101; // input=3.998046875, output=-0.755524404937
			11'd1024: out = 32'b10000000000000000000000001000000; // input=-0.001953125, output=-0.00195312375824
			11'd1025: out = 32'b10000000000000000000000011000000; // input=-0.005859375, output=-0.00585934147244
			11'd1026: out = 32'b10000000000000000000000101000000; // input=-0.009765625, output=-0.00976546978031
			11'd1027: out = 32'b10000000000000000000000111000000; // input=-0.013671875, output=-0.0136714490791
			11'd1028: out = 32'b10000000000000000000001001000000; // input=-0.017578125, output=-0.0175772197684
			11'd1029: out = 32'b10000000000000000000001011000000; // input=-0.021484375, output=-0.021482722251
			11'd1030: out = 32'b10000000000000000000001101000000; // input=-0.025390625, output=-0.0253878969337
			11'd1031: out = 32'b10000000000000000000001111000000; // input=-0.029296875, output=-0.0292926842283
			11'd1032: out = 32'b10000000000000000000010001000000; // input=-0.033203125, output=-0.0331970245525
			11'd1033: out = 32'b10000000000000000000010011000000; // input=-0.037109375, output=-0.0371008583311
			11'd1034: out = 32'b10000000000000000000010101000000; // input=-0.041015625, output=-0.0410041259961
			11'd1035: out = 32'b10000000000000000000010111000000; // input=-0.044921875, output=-0.0449067679887
			11'd1036: out = 32'b10000000000000000000011000111111; // input=-0.048828125, output=-0.0488087247592
			11'd1037: out = 32'b10000000000000000000011010111111; // input=-0.052734375, output=-0.0527099367686
			11'd1038: out = 32'b10000000000000000000011100111111; // input=-0.056640625, output=-0.0566103444893
			11'd1039: out = 32'b10000000000000000000011110111111; // input=-0.060546875, output=-0.0605098884057
			11'd1040: out = 32'b10000000000000000000100000111111; // input=-0.064453125, output=-0.0644085090157
			11'd1041: out = 32'b10000000000000000000100010111110; // input=-0.068359375, output=-0.0683061468311
			11'd1042: out = 32'b10000000000000000000100100111110; // input=-0.072265625, output=-0.0722027423787
			11'd1043: out = 32'b10000000000000000000100110111110; // input=-0.076171875, output=-0.0760982362014
			11'd1044: out = 32'b10000000000000000000101000111101; // input=-0.080078125, output=-0.0799925688585
			11'd1045: out = 32'b10000000000000000000101010111101; // input=-0.083984375, output=-0.0838856809275
			11'd1046: out = 32'b10000000000000000000101100111100; // input=-0.087890625, output=-0.0877775130042
			11'd1047: out = 32'b10000000000000000000101110111100; // input=-0.091796875, output=-0.091668005704
			11'd1048: out = 32'b10000000000000000000110000111011; // input=-0.095703125, output=-0.0955570996629
			11'd1049: out = 32'b10000000000000000000110010111011; // input=-0.099609375, output=-0.099444735538
			11'd1050: out = 32'b10000000000000000000110100111010; // input=-0.103515625, output=-0.103330854009
			11'd1051: out = 32'b10000000000000000000110110111001; // input=-0.107421875, output=-0.107215395778
			11'd1052: out = 32'b10000000000000000000111000111000; // input=-0.111328125, output=-0.111098301572
			11'd1053: out = 32'b10000000000000000000111010111000; // input=-0.115234375, output=-0.114979512142
			11'd1054: out = 32'b10000000000000000000111100110111; // input=-0.119140625, output=-0.118858968267
			11'd1055: out = 32'b10000000000000000000111110110110; // input=-0.123046875, output=-0.12273661075
			11'd1056: out = 32'b10000000000000000001000000110101; // input=-0.126953125, output=-0.126612380424
			11'd1057: out = 32'b10000000000000000001000010110100; // input=-0.130859375, output=-0.130486218148
			11'd1058: out = 32'b10000000000000000001000100110011; // input=-0.134765625, output=-0.134358064813
			11'd1059: out = 32'b10000000000000000001000110110001; // input=-0.138671875, output=-0.13822786134
			11'd1060: out = 32'b10000000000000000001001000110000; // input=-0.142578125, output=-0.142095548679
			11'd1061: out = 32'b10000000000000000001001010101111; // input=-0.146484375, output=-0.145961067815
			11'd1062: out = 32'b10000000000000000001001100101101; // input=-0.150390625, output=-0.149824359765
			11'd1063: out = 32'b10000000000000000001001110101100; // input=-0.154296875, output=-0.153685365579
			11'd1064: out = 32'b10000000000000000001010000101010; // input=-0.158203125, output=-0.157544026344
			11'd1065: out = 32'b10000000000000000001010010101001; // input=-0.162109375, output=-0.161400283181
			11'd1066: out = 32'b10000000000000000001010100100111; // input=-0.166015625, output=-0.165254077248
			11'd1067: out = 32'b10000000000000000001010110100101; // input=-0.169921875, output=-0.169105349741
			11'd1068: out = 32'b10000000000000000001011000100011; // input=-0.173828125, output=-0.172954041894
			11'd1069: out = 32'b10000000000000000001011010100001; // input=-0.177734375, output=-0.176800094982
			11'd1070: out = 32'b10000000000000000001011100011111; // input=-0.181640625, output=-0.180643450318
			11'd1071: out = 32'b10000000000000000001011110011101; // input=-0.185546875, output=-0.184484049257
			11'd1072: out = 32'b10000000000000000001100000011011; // input=-0.189453125, output=-0.188321833196
			11'd1073: out = 32'b10000000000000000001100010011001; // input=-0.193359375, output=-0.192156743576
			11'd1074: out = 32'b10000000000000000001100100010110; // input=-0.197265625, output=-0.19598872188
			11'd1075: out = 32'b10000000000000000001100110010100; // input=-0.201171875, output=-0.199817709638
			11'd1076: out = 32'b10000000000000000001101000010001; // input=-0.205078125, output=-0.203643648423
			11'd1077: out = 32'b10000000000000000001101010001110; // input=-0.208984375, output=-0.207466479857
			11'd1078: out = 32'b10000000000000000001101100001011; // input=-0.212890625, output=-0.211286145607
			11'd1079: out = 32'b10000000000000000001101110001000; // input=-0.216796875, output=-0.215102587391
			11'd1080: out = 32'b10000000000000000001110000000101; // input=-0.220703125, output=-0.218915746974
			11'd1081: out = 32'b10000000000000000001110010000010; // input=-0.224609375, output=-0.222725566172
			11'd1082: out = 32'b10000000000000000001110011111111; // input=-0.228515625, output=-0.226531986852
			11'd1083: out = 32'b10000000000000000001110101111100; // input=-0.232421875, output=-0.230334950932
			11'd1084: out = 32'b10000000000000000001110111111000; // input=-0.236328125, output=-0.234134400385
			11'd1085: out = 32'b10000000000000000001111001110100; // input=-0.240234375, output=-0.237930277234
			11'd1086: out = 32'b10000000000000000001111011110001; // input=-0.244140625, output=-0.241722523561
			11'd1087: out = 32'b10000000000000000001111101101101; // input=-0.248046875, output=-0.245511081499
			11'd1088: out = 32'b10000000000000000001111111101001; // input=-0.251953125, output=-0.24929589324
			11'd1089: out = 32'b10000000000000000010000001100101; // input=-0.255859375, output=-0.253076901032
			11'd1090: out = 32'b10000000000000000010000011100001; // input=-0.259765625, output=-0.256854047182
			11'd1091: out = 32'b10000000000000000010000101011100; // input=-0.263671875, output=-0.260627274056
			11'd1092: out = 32'b10000000000000000010000111011000; // input=-0.267578125, output=-0.264396524078
			11'd1093: out = 32'b10000000000000000010001001010011; // input=-0.271484375, output=-0.268161739734
			11'd1094: out = 32'b10000000000000000010001011001110; // input=-0.275390625, output=-0.271922863572
			11'd1095: out = 32'b10000000000000000010001101001001; // input=-0.279296875, output=-0.275679838202
			11'd1096: out = 32'b10000000000000000010001111000100; // input=-0.283203125, output=-0.279432606296
			11'd1097: out = 32'b10000000000000000010010000111111; // input=-0.287109375, output=-0.283181110593
			11'd1098: out = 32'b10000000000000000010010010111010; // input=-0.291015625, output=-0.286925293895
			11'd1099: out = 32'b10000000000000000010010100110101; // input=-0.294921875, output=-0.290665099069
			11'd1100: out = 32'b10000000000000000010010110101111; // input=-0.298828125, output=-0.294400469052
			11'd1101: out = 32'b10000000000000000010011000101001; // input=-0.302734375, output=-0.298131346846
			11'd1102: out = 32'b10000000000000000010011010100011; // input=-0.306640625, output=-0.301857675522
			11'd1103: out = 32'b10000000000000000010011100011101; // input=-0.310546875, output=-0.305579398221
			11'd1104: out = 32'b10000000000000000010011110010111; // input=-0.314453125, output=-0.309296458155
			11'd1105: out = 32'b10000000000000000010100000010001; // input=-0.318359375, output=-0.313008798605
			11'd1106: out = 32'b10000000000000000010100010001010; // input=-0.322265625, output=-0.316716362927
			11'd1107: out = 32'b10000000000000000010100100000011; // input=-0.326171875, output=-0.320419094546
			11'd1108: out = 32'b10000000000000000010100101111101; // input=-0.330078125, output=-0.324116936964
			11'd1109: out = 32'b10000000000000000010100111110110; // input=-0.333984375, output=-0.327809833756
			11'd1110: out = 32'b10000000000000000010101001101111; // input=-0.337890625, output=-0.331497728574
			11'd1111: out = 32'b10000000000000000010101011100111; // input=-0.341796875, output=-0.335180565144
			11'd1112: out = 32'b10000000000000000010101101100000; // input=-0.345703125, output=-0.338858287271
			11'd1113: out = 32'b10000000000000000010101111011000; // input=-0.349609375, output=-0.342530838838
			11'd1114: out = 32'b10000000000000000010110001010000; // input=-0.353515625, output=-0.346198163805
			11'd1115: out = 32'b10000000000000000010110011001000; // input=-0.357421875, output=-0.349860206215
			11'd1116: out = 32'b10000000000000000010110101000000; // input=-0.361328125, output=-0.353516910188
			11'd1117: out = 32'b10000000000000000010110110111000; // input=-0.365234375, output=-0.357168219928
			11'd1118: out = 32'b10000000000000000010111000101111; // input=-0.369140625, output=-0.36081407972
			11'd1119: out = 32'b10000000000000000010111010100110; // input=-0.373046875, output=-0.364454433933
			11'd1120: out = 32'b10000000000000000010111100011110; // input=-0.376953125, output=-0.36808922702
			11'd1121: out = 32'b10000000000000000010111110010100; // input=-0.380859375, output=-0.371718403519
			11'd1122: out = 32'b10000000000000000011000000001011; // input=-0.384765625, output=-0.375341908052
			11'd1123: out = 32'b10000000000000000011000010000010; // input=-0.388671875, output=-0.378959685329
			11'd1124: out = 32'b10000000000000000011000011111000; // input=-0.392578125, output=-0.382571680148
			11'd1125: out = 32'b10000000000000000011000101101110; // input=-0.396484375, output=-0.386177837393
			11'd1126: out = 32'b10000000000000000011000111100100; // input=-0.400390625, output=-0.38977810204
			11'd1127: out = 32'b10000000000000000011001001011010; // input=-0.404296875, output=-0.393372419153
			11'd1128: out = 32'b10000000000000000011001011010000; // input=-0.408203125, output=-0.396960733886
			11'd1129: out = 32'b10000000000000000011001101000101; // input=-0.412109375, output=-0.400542991487
			11'd1130: out = 32'b10000000000000000011001110111010; // input=-0.416015625, output=-0.404119137295
			11'd1131: out = 32'b10000000000000000011010000101111; // input=-0.419921875, output=-0.407689116742
			11'd1132: out = 32'b10000000000000000011010010100100; // input=-0.423828125, output=-0.411252875354
			11'd1133: out = 32'b10000000000000000011010100011001; // input=-0.427734375, output=-0.414810358754
			11'd1134: out = 32'b10000000000000000011010110001101; // input=-0.431640625, output=-0.418361512658
			11'd1135: out = 32'b10000000000000000011011000000001; // input=-0.435546875, output=-0.42190628288
			11'd1136: out = 32'b10000000000000000011011001110101; // input=-0.439453125, output=-0.425444615332
			11'd1137: out = 32'b10000000000000000011011011101001; // input=-0.443359375, output=-0.428976456021
			11'd1138: out = 32'b10000000000000000011011101011100; // input=-0.447265625, output=-0.432501751058
			11'd1139: out = 32'b10000000000000000011011111010000; // input=-0.451171875, output=-0.436020446651
			11'd1140: out = 32'b10000000000000000011100001000011; // input=-0.455078125, output=-0.439532489107
			11'd1141: out = 32'b10000000000000000011100010110101; // input=-0.458984375, output=-0.443037824839
			11'd1142: out = 32'b10000000000000000011100100101000; // input=-0.462890625, output=-0.446536400359
			11'd1143: out = 32'b10000000000000000011100110011011; // input=-0.466796875, output=-0.450028162283
			11'd1144: out = 32'b10000000000000000011101000001101; // input=-0.470703125, output=-0.45351305733
			11'd1145: out = 32'b10000000000000000011101001111111; // input=-0.474609375, output=-0.456991032326
			11'd1146: out = 32'b10000000000000000011101011110000; // input=-0.478515625, output=-0.460462034202
			11'd1147: out = 32'b10000000000000000011101101100010; // input=-0.482421875, output=-0.463926009993
			11'd1148: out = 32'b10000000000000000011101111010011; // input=-0.486328125, output=-0.467382906844
			11'd1149: out = 32'b10000000000000000011110001000100; // input=-0.490234375, output=-0.470832672007
			11'd1150: out = 32'b10000000000000000011110010110101; // input=-0.494140625, output=-0.474275252843
			11'd1151: out = 32'b10000000000000000011110100100110; // input=-0.498046875, output=-0.477710596821
			11'd1152: out = 32'b10000000000000000011110110010110; // input=-0.501953125, output=-0.481138651524
			11'd1153: out = 32'b10000000000000000011111000000110; // input=-0.505859375, output=-0.484559364643
			11'd1154: out = 32'b10000000000000000011111001110110; // input=-0.509765625, output=-0.487972683983
			11'd1155: out = 32'b10000000000000000011111011100101; // input=-0.513671875, output=-0.491378557459
			11'd1156: out = 32'b10000000000000000011111101010101; // input=-0.517578125, output=-0.494776933103
			11'd1157: out = 32'b10000000000000000011111111000100; // input=-0.521484375, output=-0.49816775906
			11'd1158: out = 32'b10000000000000000100000000110011; // input=-0.525390625, output=-0.50155098359
			11'd1159: out = 32'b10000000000000000100000010100001; // input=-0.529296875, output=-0.504926555069
			11'd1160: out = 32'b10000000000000000100000100010000; // input=-0.533203125, output=-0.50829442199
			11'd1161: out = 32'b10000000000000000100000101111110; // input=-0.537109375, output=-0.511654532964
			11'd1162: out = 32'b10000000000000000100000111101100; // input=-0.541015625, output=-0.515006836719
			11'd1163: out = 32'b10000000000000000100001001011001; // input=-0.544921875, output=-0.518351282103
			11'd1164: out = 32'b10000000000000000100001011000111; // input=-0.548828125, output=-0.521687818084
			11'd1165: out = 32'b10000000000000000100001100110100; // input=-0.552734375, output=-0.525016393751
			11'd1166: out = 32'b10000000000000000100001110100001; // input=-0.556640625, output=-0.528336958314
			11'd1167: out = 32'b10000000000000000100010000001101; // input=-0.560546875, output=-0.531649461105
			11'd1168: out = 32'b10000000000000000100010001111001; // input=-0.564453125, output=-0.534953851579
			11'd1169: out = 32'b10000000000000000100010011100101; // input=-0.568359375, output=-0.538250079316
			11'd1170: out = 32'b10000000000000000100010101010001; // input=-0.572265625, output=-0.541538094019
			11'd1171: out = 32'b10000000000000000100010110111101; // input=-0.576171875, output=-0.544817845516
			11'd1172: out = 32'b10000000000000000100011000101000; // input=-0.580078125, output=-0.548089283764
			11'd1173: out = 32'b10000000000000000100011010010011; // input=-0.583984375, output=-0.551352358843
			11'd1174: out = 32'b10000000000000000100011011111101; // input=-0.587890625, output=-0.554607020964
			11'd1175: out = 32'b10000000000000000100011101101000; // input=-0.591796875, output=-0.557853220464
			11'd1176: out = 32'b10000000000000000100011111010010; // input=-0.595703125, output=-0.561090907811
			11'd1177: out = 32'b10000000000000000100100000111100; // input=-0.599609375, output=-0.5643200336
			11'd1178: out = 32'b10000000000000000100100010100101; // input=-0.603515625, output=-0.56754054856
			11'd1179: out = 32'b10000000000000000100100100001110; // input=-0.607421875, output=-0.570752403549
			11'd1180: out = 32'b10000000000000000100100101110111; // input=-0.611328125, output=-0.573955549559
			11'd1181: out = 32'b10000000000000000100100111100000; // input=-0.615234375, output=-0.577149937714
			11'd1182: out = 32'b10000000000000000100101001001000; // input=-0.619140625, output=-0.58033551927
			11'd1183: out = 32'b10000000000000000100101010110001; // input=-0.623046875, output=-0.583512245621
			11'd1184: out = 32'b10000000000000000100101100011000; // input=-0.626953125, output=-0.586680068292
			11'd1185: out = 32'b10000000000000000100101110000000; // input=-0.630859375, output=-0.589838938948
			11'd1186: out = 32'b10000000000000000100101111100111; // input=-0.634765625, output=-0.592988809387
			11'd1187: out = 32'b10000000000000000100110001001110; // input=-0.638671875, output=-0.596129631546
			11'd1188: out = 32'b10000000000000000100110010110101; // input=-0.642578125, output=-0.599261357501
			11'd1189: out = 32'b10000000000000000100110100011011; // input=-0.646484375, output=-0.602383939464
			11'd1190: out = 32'b10000000000000000100110110000001; // input=-0.650390625, output=-0.60549732979
			11'd1191: out = 32'b10000000000000000100110111100111; // input=-0.654296875, output=-0.608601480971
			11'd1192: out = 32'b10000000000000000100111001001100; // input=-0.658203125, output=-0.611696345643
			11'd1193: out = 32'b10000000000000000100111010110001; // input=-0.662109375, output=-0.614781876581
			11'd1194: out = 32'b10000000000000000100111100010110; // input=-0.666015625, output=-0.617858026704
			11'd1195: out = 32'b10000000000000000100111101111010; // input=-0.669921875, output=-0.620924749074
			11'd1196: out = 32'b10000000000000000100111111011111; // input=-0.673828125, output=-0.623981996896
			11'd1197: out = 32'b10000000000000000101000001000011; // input=-0.677734375, output=-0.62702972352
			11'd1198: out = 32'b10000000000000000101000010100110; // input=-0.681640625, output=-0.630067882443
			11'd1199: out = 32'b10000000000000000101000100001001; // input=-0.685546875, output=-0.633096427304
			11'd1200: out = 32'b10000000000000000101000101101100; // input=-0.689453125, output=-0.636115311893
			11'd1201: out = 32'b10000000000000000101000111001111; // input=-0.693359375, output=-0.639124490145
			11'd1202: out = 32'b10000000000000000101001000110001; // input=-0.697265625, output=-0.642123916144
			11'd1203: out = 32'b10000000000000000101001010010011; // input=-0.701171875, output=-0.645113544122
			11'd1204: out = 32'b10000000000000000101001011110101; // input=-0.705078125, output=-0.64809332846
			11'd1205: out = 32'b10000000000000000101001101010110; // input=-0.708984375, output=-0.651063223692
			11'd1206: out = 32'b10000000000000000101001110110111; // input=-0.712890625, output=-0.6540231845
			11'd1207: out = 32'b10000000000000000101010000011000; // input=-0.716796875, output=-0.65697316572
			11'd1208: out = 32'b10000000000000000101010001111000; // input=-0.720703125, output=-0.659913122336
			11'd1209: out = 32'b10000000000000000101010011011000; // input=-0.724609375, output=-0.662843009491
			11'd1210: out = 32'b10000000000000000101010100111000; // input=-0.728515625, output=-0.665762782477
			11'd1211: out = 32'b10000000000000000101010110010111; // input=-0.732421875, output=-0.668672396741
			11'd1212: out = 32'b10000000000000000101010111110110; // input=-0.736328125, output=-0.671571807888
			11'd1213: out = 32'b10000000000000000101011001010101; // input=-0.740234375, output=-0.674460971675
			11'd1214: out = 32'b10000000000000000101011010110011; // input=-0.744140625, output=-0.677339844018
			11'd1215: out = 32'b10000000000000000101011100010001; // input=-0.748046875, output=-0.680208380988
			11'd1216: out = 32'b10000000000000000101011101101111; // input=-0.751953125, output=-0.683066538814
			11'd1217: out = 32'b10000000000000000101011111001100; // input=-0.755859375, output=-0.685914273886
			11'd1218: out = 32'b10000000000000000101100000101001; // input=-0.759765625, output=-0.68875154275
			11'd1219: out = 32'b10000000000000000101100010000110; // input=-0.763671875, output=-0.691578302113
			11'd1220: out = 32'b10000000000000000101100011100010; // input=-0.767578125, output=-0.694394508842
			11'd1221: out = 32'b10000000000000000101100100111110; // input=-0.771484375, output=-0.697200119965
			11'd1222: out = 32'b10000000000000000101100110011001; // input=-0.775390625, output=-0.699995092672
			11'd1223: out = 32'b10000000000000000101100111110101; // input=-0.779296875, output=-0.702779384315
			11'd1224: out = 32'b10000000000000000101101001010000; // input=-0.783203125, output=-0.705552952409
			11'd1225: out = 32'b10000000000000000101101010101010; // input=-0.787109375, output=-0.708315754633
			11'd1226: out = 32'b10000000000000000101101100000100; // input=-0.791015625, output=-0.711067748831
			11'd1227: out = 32'b10000000000000000101101101011110; // input=-0.794921875, output=-0.713808893009
			11'd1228: out = 32'b10000000000000000101101110111000; // input=-0.798828125, output=-0.716539145342
			11'd1229: out = 32'b10000000000000000101110000010001; // input=-0.802734375, output=-0.719258464169
			11'd1230: out = 32'b10000000000000000101110001101001; // input=-0.806640625, output=-0.721966807997
			11'd1231: out = 32'b10000000000000000101110011000010; // input=-0.810546875, output=-0.7246641355
			11'd1232: out = 32'b10000000000000000101110100011010; // input=-0.814453125, output=-0.727350405519
			11'd1233: out = 32'b10000000000000000101110101110001; // input=-0.818359375, output=-0.730025577067
			11'd1234: out = 32'b10000000000000000101110111001001; // input=-0.822265625, output=-0.732689609322
			11'd1235: out = 32'b10000000000000000101111000100000; // input=-0.826171875, output=-0.735342461635
			11'd1236: out = 32'b10000000000000000101111001110110; // input=-0.830078125, output=-0.737984093527
			11'd1237: out = 32'b10000000000000000101111011001100; // input=-0.833984375, output=-0.740614464689
			11'd1238: out = 32'b10000000000000000101111100100010; // input=-0.837890625, output=-0.743233534986
			11'd1239: out = 32'b10000000000000000101111101111000; // input=-0.841796875, output=-0.745841264454
			11'd1240: out = 32'b10000000000000000101111111001101; // input=-0.845703125, output=-0.748437613302
			11'd1241: out = 32'b10000000000000000110000000100010; // input=-0.849609375, output=-0.751022541912
			11'd1242: out = 32'b10000000000000000110000001110110; // input=-0.853515625, output=-0.753596010843
			11'd1243: out = 32'b10000000000000000110000011001010; // input=-0.857421875, output=-0.756157980826
			11'd1244: out = 32'b10000000000000000110000100011101; // input=-0.861328125, output=-0.758708412768
			11'd1245: out = 32'b10000000000000000110000101110001; // input=-0.865234375, output=-0.761247267753
			11'd1246: out = 32'b10000000000000000110000111000011; // input=-0.869140625, output=-0.763774507042
			11'd1247: out = 32'b10000000000000000110001000010110; // input=-0.873046875, output=-0.766290092071
			11'd1248: out = 32'b10000000000000000110001001101000; // input=-0.876953125, output=-0.768793984456
			11'd1249: out = 32'b10000000000000000110001010111010; // input=-0.880859375, output=-0.771286145991
			11'd1250: out = 32'b10000000000000000110001100001011; // input=-0.884765625, output=-0.773766538648
			11'd1251: out = 32'b10000000000000000110001101011100; // input=-0.888671875, output=-0.77623512458
			11'd1252: out = 32'b10000000000000000110001110101100; // input=-0.892578125, output=-0.778691866119
			11'd1253: out = 32'b10000000000000000110001111111100; // input=-0.896484375, output=-0.781136725778
			11'd1254: out = 32'b10000000000000000110010001001100; // input=-0.900390625, output=-0.783569666252
			11'd1255: out = 32'b10000000000000000110010010011011; // input=-0.904296875, output=-0.785990650417
			11'd1256: out = 32'b10000000000000000110010011101010; // input=-0.908203125, output=-0.788399641331
			11'd1257: out = 32'b10000000000000000110010100111001; // input=-0.912109375, output=-0.790796602237
			11'd1258: out = 32'b10000000000000000110010110000111; // input=-0.916015625, output=-0.79318149656
			11'd1259: out = 32'b10000000000000000110010111010101; // input=-0.919921875, output=-0.795554287909
			11'd1260: out = 32'b10000000000000000110011000100010; // input=-0.923828125, output=-0.797914940078
			11'd1261: out = 32'b10000000000000000110011001101111; // input=-0.927734375, output=-0.800263417047
			11'd1262: out = 32'b10000000000000000110011010111100; // input=-0.931640625, output=-0.802599682981
			11'd1263: out = 32'b10000000000000000110011100001000; // input=-0.935546875, output=-0.804923702231
			11'd1264: out = 32'b10000000000000000110011101010011; // input=-0.939453125, output=-0.807235439336
			11'd1265: out = 32'b10000000000000000110011110011111; // input=-0.943359375, output=-0.809534859021
			11'd1266: out = 32'b10000000000000000110011111101010; // input=-0.947265625, output=-0.8118219262
			11'd1267: out = 32'b10000000000000000110100000110100; // input=-0.951171875, output=-0.814096605976
			11'd1268: out = 32'b10000000000000000110100001111110; // input=-0.955078125, output=-0.816358863639
			11'd1269: out = 32'b10000000000000000110100011001000; // input=-0.958984375, output=-0.81860866467
			11'd1270: out = 32'b10000000000000000110100100010001; // input=-0.962890625, output=-0.82084597474
			11'd1271: out = 32'b10000000000000000110100101011010; // input=-0.966796875, output=-0.82307075971
			11'd1272: out = 32'b10000000000000000110100110100011; // input=-0.970703125, output=-0.825282985633
			11'd1273: out = 32'b10000000000000000110100111101011; // input=-0.974609375, output=-0.827482618753
			11'd1274: out = 32'b10000000000000000110101000110011; // input=-0.978515625, output=-0.829669625507
			11'd1275: out = 32'b10000000000000000110101001111010; // input=-0.982421875, output=-0.831843972523
			11'd1276: out = 32'b10000000000000000110101011000001; // input=-0.986328125, output=-0.834005626623
			11'd1277: out = 32'b10000000000000000110101100000111; // input=-0.990234375, output=-0.836154554823
			11'd1278: out = 32'b10000000000000000110101101001101; // input=-0.994140625, output=-0.838290724334
			11'd1279: out = 32'b10000000000000000110101110010011; // input=-0.998046875, output=-0.84041410256
			11'd1280: out = 32'b10000000000000000110101111011000; // input=-1.001953125, output=-0.8425246571
			11'd1281: out = 32'b10000000000000000110110000011101; // input=-1.005859375, output=-0.844622355751
			11'd1282: out = 32'b10000000000000000110110001100001; // input=-1.009765625, output=-0.846707166504
			11'd1283: out = 32'b10000000000000000110110010100101; // input=-1.013671875, output=-0.848779057547
			11'd1284: out = 32'b10000000000000000110110011101000; // input=-1.017578125, output=-0.850837997266
			11'd1285: out = 32'b10000000000000000110110100101011; // input=-1.021484375, output=-0.852883954244
			11'd1286: out = 32'b10000000000000000110110101101110; // input=-1.025390625, output=-0.854916897262
			11'd1287: out = 32'b10000000000000000110110110110000; // input=-1.029296875, output=-0.8569367953
			11'd1288: out = 32'b10000000000000000110110111110010; // input=-1.033203125, output=-0.858943617537
			11'd1289: out = 32'b10000000000000000110111000110011; // input=-1.037109375, output=-0.860937333352
			11'd1290: out = 32'b10000000000000000110111001110100; // input=-1.041015625, output=-0.862917912321
			11'd1291: out = 32'b10000000000000000110111010110101; // input=-1.044921875, output=-0.864885324225
			11'd1292: out = 32'b10000000000000000110111011110101; // input=-1.048828125, output=-0.866839539044
			11'd1293: out = 32'b10000000000000000110111100110100; // input=-1.052734375, output=-0.868780526957
			11'd1294: out = 32'b10000000000000000110111101110011; // input=-1.056640625, output=-0.870708258348
			11'd1295: out = 32'b10000000000000000110111110110010; // input=-1.060546875, output=-0.872622703803
			11'd1296: out = 32'b10000000000000000110111111110000; // input=-1.064453125, output=-0.874523834109
			11'd1297: out = 32'b10000000000000000111000000101110; // input=-1.068359375, output=-0.876411620257
			11'd1298: out = 32'b10000000000000000111000001101100; // input=-1.072265625, output=-0.878286033441
			11'd1299: out = 32'b10000000000000000111000010101001; // input=-1.076171875, output=-0.880147045062
			11'd1300: out = 32'b10000000000000000111000011100101; // input=-1.080078125, output=-0.881994626722
			11'd1301: out = 32'b10000000000000000111000100100001; // input=-1.083984375, output=-0.883828750229
			11'd1302: out = 32'b10000000000000000111000101011101; // input=-1.087890625, output=-0.885649387596
			11'd1303: out = 32'b10000000000000000111000110011000; // input=-1.091796875, output=-0.887456511044
			11'd1304: out = 32'b10000000000000000111000111010011; // input=-1.095703125, output=-0.889250092997
			11'd1305: out = 32'b10000000000000000111001000001101; // input=-1.099609375, output=-0.891030106087
			11'd1306: out = 32'b10000000000000000111001001000111; // input=-1.103515625, output=-0.892796523155
			11'd1307: out = 32'b10000000000000000111001010000001; // input=-1.107421875, output=-0.894549317246
			11'd1308: out = 32'b10000000000000000111001010111010; // input=-1.111328125, output=-0.896288461615
			11'd1309: out = 32'b10000000000000000111001011110010; // input=-1.115234375, output=-0.898013929725
			11'd1310: out = 32'b10000000000000000111001100101010; // input=-1.119140625, output=-0.899725695247
			11'd1311: out = 32'b10000000000000000111001101100010; // input=-1.123046875, output=-0.901423732062
			11'd1312: out = 32'b10000000000000000111001110011001; // input=-1.126953125, output=-0.90310801426
			11'd1313: out = 32'b10000000000000000111001111010000; // input=-1.130859375, output=-0.90477851614
			11'd1314: out = 32'b10000000000000000111010000000110; // input=-1.134765625, output=-0.906435212214
			11'd1315: out = 32'b10000000000000000111010000111100; // input=-1.138671875, output=-0.908078077202
			11'd1316: out = 32'b10000000000000000111010001110001; // input=-1.142578125, output=-0.909707086035
			11'd1317: out = 32'b10000000000000000111010010100110; // input=-1.146484375, output=-0.911322213858
			11'd1318: out = 32'b10000000000000000111010011011011; // input=-1.150390625, output=-0.912923436025
			11'd1319: out = 32'b10000000000000000111010100001111; // input=-1.154296875, output=-0.914510728103
			11'd1320: out = 32'b10000000000000000111010101000010; // input=-1.158203125, output=-0.916084065873
			11'd1321: out = 32'b10000000000000000111010101110101; // input=-1.162109375, output=-0.917643425327
			11'd1322: out = 32'b10000000000000000111010110101000; // input=-1.166015625, output=-0.919188782671
			11'd1323: out = 32'b10000000000000000111010111011010; // input=-1.169921875, output=-0.920720114326
			11'd1324: out = 32'b10000000000000000111011000001100; // input=-1.173828125, output=-0.922237396924
			11'd1325: out = 32'b10000000000000000111011000111101; // input=-1.177734375, output=-0.923740607315
			11'd1326: out = 32'b10000000000000000111011001101110; // input=-1.181640625, output=-0.92522972256
			11'd1327: out = 32'b10000000000000000111011010011110; // input=-1.185546875, output=-0.926704719938
			11'd1328: out = 32'b10000000000000000111011011001110; // input=-1.189453125, output=-0.928165576942
			11'd1329: out = 32'b10000000000000000111011011111110; // input=-1.193359375, output=-0.929612271281
			11'd1330: out = 32'b10000000000000000111011100101100; // input=-1.197265625, output=-0.931044780881
			11'd1331: out = 32'b10000000000000000111011101011011; // input=-1.201171875, output=-0.932463083883
			11'd1332: out = 32'b10000000000000000111011110001001; // input=-1.205078125, output=-0.933867158646
			11'd1333: out = 32'b10000000000000000111011110110111; // input=-1.208984375, output=-0.935256983744
			11'd1334: out = 32'b10000000000000000111011111100100; // input=-1.212890625, output=-0.936632537972
			11'd1335: out = 32'b10000000000000000111100000010000; // input=-1.216796875, output=-0.93799380034
			11'd1336: out = 32'b10000000000000000111100000111100; // input=-1.220703125, output=-0.939340750076
			11'd1337: out = 32'b10000000000000000111100001101000; // input=-1.224609375, output=-0.940673366629
			11'd1338: out = 32'b10000000000000000111100010010011; // input=-1.228515625, output=-0.941991629663
			11'd1339: out = 32'b10000000000000000111100010111110; // input=-1.232421875, output=-0.943295519063
			11'd1340: out = 32'b10000000000000000111100011101000; // input=-1.236328125, output=-0.944585014935
			11'd1341: out = 32'b10000000000000000111100100010010; // input=-1.240234375, output=-0.945860097601
			11'd1342: out = 32'b10000000000000000111100100111011; // input=-1.244140625, output=-0.947120747606
			11'd1343: out = 32'b10000000000000000111100101100100; // input=-1.248046875, output=-0.948366945714
			11'd1344: out = 32'b10000000000000000111100110001100; // input=-1.251953125, output=-0.949598672909
			11'd1345: out = 32'b10000000000000000111100110110100; // input=-1.255859375, output=-0.950815910397
			11'd1346: out = 32'b10000000000000000111100111011100; // input=-1.259765625, output=-0.952018639603
			11'd1347: out = 32'b10000000000000000111101000000011; // input=-1.263671875, output=-0.953206842177
			11'd1348: out = 32'b10000000000000000111101000101001; // input=-1.267578125, output=-0.954380499987
			11'd1349: out = 32'b10000000000000000111101001001111; // input=-1.271484375, output=-0.955539595124
			11'd1350: out = 32'b10000000000000000111101001110101; // input=-1.275390625, output=-0.956684109903
			11'd1351: out = 32'b10000000000000000111101010011010; // input=-1.279296875, output=-0.95781402686
			11'd1352: out = 32'b10000000000000000111101010111110; // input=-1.283203125, output=-0.958929328753
			11'd1353: out = 32'b10000000000000000111101011100010; // input=-1.287109375, output=-0.960029998564
			11'd1354: out = 32'b10000000000000000111101100000110; // input=-1.291015625, output=-0.961116019499
			11'd1355: out = 32'b10000000000000000111101100101001; // input=-1.294921875, output=-0.962187374985
			11'd1356: out = 32'b10000000000000000111101101001100; // input=-1.298828125, output=-0.963244048676
			11'd1357: out = 32'b10000000000000000111101101101110; // input=-1.302734375, output=-0.964286024448
			11'd1358: out = 32'b10000000000000000111101110001111; // input=-1.306640625, output=-0.965313286402
			11'd1359: out = 32'b10000000000000000111101110110001; // input=-1.310546875, output=-0.966325818863
			11'd1360: out = 32'b10000000000000000111101111010001; // input=-1.314453125, output=-0.96732360638
			11'd1361: out = 32'b10000000000000000111101111110001; // input=-1.318359375, output=-0.96830663373
			11'd1362: out = 32'b10000000000000000111110000010001; // input=-1.322265625, output=-0.969274885911
			11'd1363: out = 32'b10000000000000000111110000110000; // input=-1.326171875, output=-0.970228348151
			11'd1364: out = 32'b10000000000000000111110001001111; // input=-1.330078125, output=-0.971167005899
			11'd1365: out = 32'b10000000000000000111110001101101; // input=-1.333984375, output=-0.972090844834
			11'd1366: out = 32'b10000000000000000111110010001011; // input=-1.337890625, output=-0.972999850858
			11'd1367: out = 32'b10000000000000000111110010101001; // input=-1.341796875, output=-0.973894010102
			11'd1368: out = 32'b10000000000000000111110011000101; // input=-1.345703125, output=-0.974773308922
			11'd1369: out = 32'b10000000000000000111110011100010; // input=-1.349609375, output=-0.9756377339
			11'd1370: out = 32'b10000000000000000111110011111110; // input=-1.353515625, output=-0.976487271847
			11'd1371: out = 32'b10000000000000000111110100011001; // input=-1.357421875, output=-0.977321909799
			11'd1372: out = 32'b10000000000000000111110100110100; // input=-1.361328125, output=-0.978141635021
			11'd1373: out = 32'b10000000000000000111110101001110; // input=-1.365234375, output=-0.978946435006
			11'd1374: out = 32'b10000000000000000111110101101000; // input=-1.369140625, output=-0.979736297472
			11'd1375: out = 32'b10000000000000000111110110000001; // input=-1.373046875, output=-0.980511210368
			11'd1376: out = 32'b10000000000000000111110110011010; // input=-1.376953125, output=-0.981271161869
			11'd1377: out = 32'b10000000000000000111110110110011; // input=-1.380859375, output=-0.98201614038
			11'd1378: out = 32'b10000000000000000111110111001011; // input=-1.384765625, output=-0.982746134532
			11'd1379: out = 32'b10000000000000000111110111100010; // input=-1.388671875, output=-0.983461133188
			11'd1380: out = 32'b10000000000000000111110111111001; // input=-1.392578125, output=-0.984161125436
			11'd1381: out = 32'b10000000000000000111111000001111; // input=-1.396484375, output=-0.984846100597
			11'd1382: out = 32'b10000000000000000111111000100101; // input=-1.400390625, output=-0.985516048218
			11'd1383: out = 32'b10000000000000000111111000111011; // input=-1.404296875, output=-0.986170958077
			11'd1384: out = 32'b10000000000000000111111001010000; // input=-1.408203125, output=-0.98681082018
			11'd1385: out = 32'b10000000000000000111111001100100; // input=-1.412109375, output=-0.987435624764
			11'd1386: out = 32'b10000000000000000111111001111000; // input=-1.416015625, output=-0.988045362295
			11'd1387: out = 32'b10000000000000000111111010001100; // input=-1.419921875, output=-0.98864002347
			11'd1388: out = 32'b10000000000000000111111010011111; // input=-1.423828125, output=-0.989219599214
			11'd1389: out = 32'b10000000000000000111111010110001; // input=-1.427734375, output=-0.989784080684
			11'd1390: out = 32'b10000000000000000111111011000011; // input=-1.431640625, output=-0.990333459267
			11'd1391: out = 32'b10000000000000000111111011010101; // input=-1.435546875, output=-0.99086772658
			11'd1392: out = 32'b10000000000000000111111011100110; // input=-1.439453125, output=-0.991386874471
			11'd1393: out = 32'b10000000000000000111111011110110; // input=-1.443359375, output=-0.991890895017
			11'd1394: out = 32'b10000000000000000111111100000110; // input=-1.447265625, output=-0.992379780529
			11'd1395: out = 32'b10000000000000000111111100010110; // input=-1.451171875, output=-0.992853523546
			11'd1396: out = 32'b10000000000000000111111100100101; // input=-1.455078125, output=-0.99331211684
			11'd1397: out = 32'b10000000000000000111111100110011; // input=-1.458984375, output=-0.993755553414
			11'd1398: out = 32'b10000000000000000111111101000001; // input=-1.462890625, output=-0.9941838265
			11'd1399: out = 32'b10000000000000000111111101001111; // input=-1.466796875, output=-0.994596929564
			11'd1400: out = 32'b10000000000000000111111101011100; // input=-1.470703125, output=-0.994994856303
			11'd1401: out = 32'b10000000000000000111111101101001; // input=-1.474609375, output=-0.995377600644
			11'd1402: out = 32'b10000000000000000111111101110101; // input=-1.478515625, output=-0.995745156748
			11'd1403: out = 32'b10000000000000000111111110000000; // input=-1.482421875, output=-0.996097519006
			11'd1404: out = 32'b10000000000000000111111110001011; // input=-1.486328125, output=-0.996434682041
			11'd1405: out = 32'b10000000000000000111111110010110; // input=-1.490234375, output=-0.996756640709
			11'd1406: out = 32'b10000000000000000111111110100000; // input=-1.494140625, output=-0.997063390097
			11'd1407: out = 32'b10000000000000000111111110101001; // input=-1.498046875, output=-0.997354925525
			11'd1408: out = 32'b10000000000000000111111110110010; // input=-1.501953125, output=-0.997631242543
			11'd1409: out = 32'b10000000000000000111111110111011; // input=-1.505859375, output=-0.997892336936
			11'd1410: out = 32'b10000000000000000111111111000011; // input=-1.509765625, output=-0.99813820472
			11'd1411: out = 32'b10000000000000000111111111001011; // input=-1.513671875, output=-0.998368842143
			11'd1412: out = 32'b10000000000000000111111111010010; // input=-1.517578125, output=-0.998584245685
			11'd1413: out = 32'b10000000000000000111111111011000; // input=-1.521484375, output=-0.998784412061
			11'd1414: out = 32'b10000000000000000111111111011110; // input=-1.525390625, output=-0.998969338215
			11'd1415: out = 32'b10000000000000000111111111100100; // input=-1.529296875, output=-0.999139021326
			11'd1416: out = 32'b10000000000000000111111111101001; // input=-1.533203125, output=-0.999293458805
			11'd1417: out = 32'b10000000000000000111111111101101; // input=-1.537109375, output=-0.999432648295
			11'd1418: out = 32'b10000000000000000111111111110001; // input=-1.541015625, output=-0.999556587673
			11'd1419: out = 32'b10000000000000000111111111110101; // input=-1.544921875, output=-0.999665275047
			11'd1420: out = 32'b10000000000000000111111111111000; // input=-1.548828125, output=-0.999758708759
			11'd1421: out = 32'b10000000000000000111111111111011; // input=-1.552734375, output=-0.999836887383
			11'd1422: out = 32'b10000000000000000111111111111101; // input=-1.556640625, output=-0.999899809726
			11'd1423: out = 32'b10000000000000000111111111111110; // input=-1.560546875, output=-0.999947474829
			11'd1424: out = 32'b10000000000000000111111111111111; // input=-1.564453125, output=-0.999979881963
			11'd1425: out = 32'b10000000000000000111111111111111; // input=-1.568359375, output=-0.999997030634
			11'd1426: out = 32'b10000000000000000111111111111111; // input=-1.572265625, output=-0.999998920582
			11'd1427: out = 32'b10000000000000000111111111111111; // input=-1.576171875, output=-0.999985551776
			11'd1428: out = 32'b10000000000000000111111111111111; // input=-1.580078125, output=-0.99995692442
			11'd1429: out = 32'b10000000000000000111111111111101; // input=-1.583984375, output=-0.999913038953
			11'd1430: out = 32'b10000000000000000111111111111011; // input=-1.587890625, output=-0.999853896042
			11'd1431: out = 32'b10000000000000000111111111111001; // input=-1.591796875, output=-0.999779496592
			11'd1432: out = 32'b10000000000000000111111111110110; // input=-1.595703125, output=-0.999689841736
			11'd1433: out = 32'b10000000000000000111111111110010; // input=-1.599609375, output=-0.999584932843
			11'd1434: out = 32'b10000000000000000111111111101110; // input=-1.603515625, output=-0.999464771514
			11'd1435: out = 32'b10000000000000000111111111101010; // input=-1.607421875, output=-0.999329359583
			11'd1436: out = 32'b10000000000000000111111111100101; // input=-1.611328125, output=-0.999178699114
			11'd1437: out = 32'b10000000000000000111111111100000; // input=-1.615234375, output=-0.999012792408
			11'd1438: out = 32'b10000000000000000111111111011010; // input=-1.619140625, output=-0.998831641997
			11'd1439: out = 32'b10000000000000000111111111010011; // input=-1.623046875, output=-0.998635250643
			11'd1440: out = 32'b10000000000000000111111111001100; // input=-1.626953125, output=-0.998423621343
			11'd1441: out = 32'b10000000000000000111111111000101; // input=-1.630859375, output=-0.998196757328
			11'd1442: out = 32'b10000000000000000111111110111101; // input=-1.634765625, output=-0.997954662059
			11'd1443: out = 32'b10000000000000000111111110110101; // input=-1.638671875, output=-0.997697339229
			11'd1444: out = 32'b10000000000000000111111110101100; // input=-1.642578125, output=-0.997424792765
			11'd1445: out = 32'b10000000000000000111111110100010; // input=-1.646484375, output=-0.997137026826
			11'd1446: out = 32'b10000000000000000111111110011000; // input=-1.650390625, output=-0.996834045803
			11'd1447: out = 32'b10000000000000000111111110001110; // input=-1.654296875, output=-0.996515854318
			11'd1448: out = 32'b10000000000000000111111110000011; // input=-1.658203125, output=-0.996182457228
			11'd1449: out = 32'b10000000000000000111111101110111; // input=-1.662109375, output=-0.995833859619
			11'd1450: out = 32'b10000000000000000111111101101100; // input=-1.666015625, output=-0.995470066811
			11'd1451: out = 32'b10000000000000000111111101011111; // input=-1.669921875, output=-0.995091084354
			11'd1452: out = 32'b10000000000000000111111101010010; // input=-1.673828125, output=-0.994696918032
			11'd1453: out = 32'b10000000000000000111111101000101; // input=-1.677734375, output=-0.994287573858
			11'd1454: out = 32'b10000000000000000111111100110111; // input=-1.681640625, output=-0.99386305808
			11'd1455: out = 32'b10000000000000000111111100101000; // input=-1.685546875, output=-0.993423377174
			11'd1456: out = 32'b10000000000000000111111100011010; // input=-1.689453125, output=-0.992968537849
			11'd1457: out = 32'b10000000000000000111111100001010; // input=-1.693359375, output=-0.992498547046
			11'd1458: out = 32'b10000000000000000111111011111010; // input=-1.697265625, output=-0.992013411937
			11'd1459: out = 32'b10000000000000000111111011101010; // input=-1.701171875, output=-0.991513139923
			11'd1460: out = 32'b10000000000000000111111011011001; // input=-1.705078125, output=-0.990997738639
			11'd1461: out = 32'b10000000000000000111111011001000; // input=-1.708984375, output=-0.990467215948
			11'd1462: out = 32'b10000000000000000111111010110110; // input=-1.712890625, output=-0.989921579947
			11'd1463: out = 32'b10000000000000000111111010100011; // input=-1.716796875, output=-0.98936083896
			11'd1464: out = 32'b10000000000000000111111010010001; // input=-1.720703125, output=-0.988785001544
			11'd1465: out = 32'b10000000000000000111111001111101; // input=-1.724609375, output=-0.988194076485
			11'd1466: out = 32'b10000000000000000111111001101001; // input=-1.728515625, output=-0.9875880728
			11'd1467: out = 32'b10000000000000000111111001010101; // input=-1.732421875, output=-0.986966999737
			11'd1468: out = 32'b10000000000000000111111001000000; // input=-1.736328125, output=-0.986330866772
			11'd1469: out = 32'b10000000000000000111111000101011; // input=-1.740234375, output=-0.98567968361
			11'd1470: out = 32'b10000000000000000111111000010101; // input=-1.744140625, output=-0.98501346019
			11'd1471: out = 32'b10000000000000000111110111111111; // input=-1.748046875, output=-0.984332206676
			11'd1472: out = 32'b10000000000000000111110111101000; // input=-1.751953125, output=-0.983635933464
			11'd1473: out = 32'b10000000000000000111110111010000; // input=-1.755859375, output=-0.982924651178
			11'd1474: out = 32'b10000000000000000111110110111001; // input=-1.759765625, output=-0.982198370671
			11'd1475: out = 32'b10000000000000000111110110100000; // input=-1.763671875, output=-0.981457103025
			11'd1476: out = 32'b10000000000000000111110110001000; // input=-1.767578125, output=-0.980700859551
			11'd1477: out = 32'b10000000000000000111110101101110; // input=-1.771484375, output=-0.979929651789
			11'd1478: out = 32'b10000000000000000111110101010101; // input=-1.775390625, output=-0.979143491506
			11'd1479: out = 32'b10000000000000000111110100111010; // input=-1.779296875, output=-0.978342390698
			11'd1480: out = 32'b10000000000000000111110100100000; // input=-1.783203125, output=-0.977526361588
			11'd1481: out = 32'b10000000000000000111110100000100; // input=-1.787109375, output=-0.976695416629
			11'd1482: out = 32'b10000000000000000111110011101001; // input=-1.791015625, output=-0.9758495685
			11'd1483: out = 32'b10000000000000000111110011001100; // input=-1.794921875, output=-0.974988830107
			11'd1484: out = 32'b10000000000000000111110010110000; // input=-1.798828125, output=-0.974113214584
			11'd1485: out = 32'b10000000000000000111110010010011; // input=-1.802734375, output=-0.973222735292
			11'd1486: out = 32'b10000000000000000111110001110101; // input=-1.806640625, output=-0.972317405818
			11'd1487: out = 32'b10000000000000000111110001010111; // input=-1.810546875, output=-0.971397239977
			11'd1488: out = 32'b10000000000000000111110000111000; // input=-1.814453125, output=-0.970462251809
			11'd1489: out = 32'b10000000000000000111110000011001; // input=-1.818359375, output=-0.969512455581
			11'd1490: out = 32'b10000000000000000111101111111001; // input=-1.822265625, output=-0.968547865786
			11'd1491: out = 32'b10000000000000000111101111011001; // input=-1.826171875, output=-0.967568497142
			11'd1492: out = 32'b10000000000000000111101110111001; // input=-1.830078125, output=-0.966574364594
			11'd1493: out = 32'b10000000000000000111101110011000; // input=-1.833984375, output=-0.96556548331
			11'd1494: out = 32'b10000000000000000111101101110110; // input=-1.837890625, output=-0.964541868684
			11'd1495: out = 32'b10000000000000000111101101010100; // input=-1.841796875, output=-0.963503536336
			11'd1496: out = 32'b10000000000000000111101100110010; // input=-1.845703125, output=-0.96245050211
			11'd1497: out = 32'b10000000000000000111101100001111; // input=-1.849609375, output=-0.961382782073
			11'd1498: out = 32'b10000000000000000111101011101011; // input=-1.853515625, output=-0.960300392518
			11'd1499: out = 32'b10000000000000000111101011000111; // input=-1.857421875, output=-0.95920334996
			11'd1500: out = 32'b10000000000000000111101010100011; // input=-1.861328125, output=-0.95809167114
			11'd1501: out = 32'b10000000000000000111101001111110; // input=-1.865234375, output=-0.956965373019
			11'd1502: out = 32'b10000000000000000111101001011000; // input=-1.869140625, output=-0.955824472784
			11'd1503: out = 32'b10000000000000000111101000110011; // input=-1.873046875, output=-0.954668987843
			11'd1504: out = 32'b10000000000000000111101000001100; // input=-1.876953125, output=-0.953498935829
			11'd1505: out = 32'b10000000000000000111100111100101; // input=-1.880859375, output=-0.952314334593
			11'd1506: out = 32'b10000000000000000111100110111110; // input=-1.884765625, output=-0.951115202213
			11'd1507: out = 32'b10000000000000000111100110010110; // input=-1.888671875, output=-0.949901556985
			11'd1508: out = 32'b10000000000000000111100101101110; // input=-1.892578125, output=-0.948673417428
			11'd1509: out = 32'b10000000000000000111100101000101; // input=-1.896484375, output=-0.947430802281
			11'd1510: out = 32'b10000000000000000111100100011100; // input=-1.900390625, output=-0.946173730507
			11'd1511: out = 32'b10000000000000000111100011110011; // input=-1.904296875, output=-0.944902221285
			11'd1512: out = 32'b10000000000000000111100011001000; // input=-1.908203125, output=-0.943616294018
			11'd1513: out = 32'b10000000000000000111100010011110; // input=-1.912109375, output=-0.942315968327
			11'd1514: out = 32'b10000000000000000111100001110011; // input=-1.916015625, output=-0.941001264054
			11'd1515: out = 32'b10000000000000000111100001000111; // input=-1.919921875, output=-0.939672201259
			11'd1516: out = 32'b10000000000000000111100000011011; // input=-1.923828125, output=-0.938328800223
			11'd1517: out = 32'b10000000000000000111011111101111; // input=-1.927734375, output=-0.936971081444
			11'd1518: out = 32'b10000000000000000111011111000010; // input=-1.931640625, output=-0.935599065638
			11'd1519: out = 32'b10000000000000000111011110010100; // input=-1.935546875, output=-0.934212773742
			11'd1520: out = 32'b10000000000000000111011101100110; // input=-1.939453125, output=-0.932812226909
			11'd1521: out = 32'b10000000000000000111011100111000; // input=-1.943359375, output=-0.931397446509
			11'd1522: out = 32'b10000000000000000111011100001001; // input=-1.947265625, output=-0.929968454129
			11'd1523: out = 32'b10000000000000000111011011011010; // input=-1.951171875, output=-0.928525271575
			11'd1524: out = 32'b10000000000000000111011010101010; // input=-1.955078125, output=-0.927067920868
			11'd1525: out = 32'b10000000000000000111011001111010; // input=-1.958984375, output=-0.925596424245
			11'd1526: out = 32'b10000000000000000111011001001001; // input=-1.962890625, output=-0.92411080416
			11'd1527: out = 32'b10000000000000000111011000011000; // input=-1.966796875, output=-0.92261108328
			11'd1528: out = 32'b10000000000000000111010111100111; // input=-1.970703125, output=-0.921097284491
			11'd1529: out = 32'b10000000000000000111010110110100; // input=-1.974609375, output=-0.91956943089
			11'd1530: out = 32'b10000000000000000111010110000010; // input=-1.978515625, output=-0.918027545791
			11'd1531: out = 32'b10000000000000000111010101001111; // input=-1.982421875, output=-0.916471652721
			11'd1532: out = 32'b10000000000000000111010100011100; // input=-1.986328125, output=-0.914901775422
			11'd1533: out = 32'b10000000000000000111010011101000; // input=-1.990234375, output=-0.913317937847
			11'd1534: out = 32'b10000000000000000111010010110011; // input=-1.994140625, output=-0.911720164164
			11'd1535: out = 32'b10000000000000000111010001111110; // input=-1.998046875, output=-0.910108478752
			11'd1536: out = 32'b10000000000000000111010001001001; // input=-2.001953125, output=-0.908482906206
			11'd1537: out = 32'b10000000000000000111010000010011; // input=-2.005859375, output=-0.906843471327
			11'd1538: out = 32'b10000000000000000111001111011101; // input=-2.009765625, output=-0.905190199134
			11'd1539: out = 32'b10000000000000000111001110100111; // input=-2.013671875, output=-0.903523114851
			11'd1540: out = 32'b10000000000000000111001101110000; // input=-2.017578125, output=-0.901842243918
			11'd1541: out = 32'b10000000000000000111001100111000; // input=-2.021484375, output=-0.900147611981
			11'd1542: out = 32'b10000000000000000111001100000000; // input=-2.025390625, output=-0.898439244899
			11'd1543: out = 32'b10000000000000000111001011001000; // input=-2.029296875, output=-0.89671716874
			11'd1544: out = 32'b10000000000000000111001010001111; // input=-2.033203125, output=-0.89498140978
			11'd1545: out = 32'b10000000000000000111001001010101; // input=-2.037109375, output=-0.893231994505
			11'd1546: out = 32'b10000000000000000111001000011100; // input=-2.041015625, output=-0.891468949608
			11'd1547: out = 32'b10000000000000000111000111100001; // input=-2.044921875, output=-0.889692301992
			11'd1548: out = 32'b10000000000000000111000110100111; // input=-2.048828125, output=-0.887902078767
			11'd1549: out = 32'b10000000000000000111000101101100; // input=-2.052734375, output=-0.886098307248
			11'd1550: out = 32'b10000000000000000111000100110000; // input=-2.056640625, output=-0.884281014959
			11'd1551: out = 32'b10000000000000000111000011110100; // input=-2.060546875, output=-0.882450229629
			11'd1552: out = 32'b10000000000000000111000010111000; // input=-2.064453125, output=-0.880605979195
			11'd1553: out = 32'b10000000000000000111000001111011; // input=-2.068359375, output=-0.878748291797
			11'd1554: out = 32'b10000000000000000111000000111110; // input=-2.072265625, output=-0.876877195782
			11'd1555: out = 32'b10000000000000000111000000000000; // input=-2.076171875, output=-0.874992719699
			11'd1556: out = 32'b10000000000000000110111111000010; // input=-2.080078125, output=-0.873094892304
			11'd1557: out = 32'b10000000000000000110111110000011; // input=-2.083984375, output=-0.871183742555
			11'd1558: out = 32'b10000000000000000110111101000100; // input=-2.087890625, output=-0.869259299614
			11'd1559: out = 32'b10000000000000000110111100000100; // input=-2.091796875, output=-0.867321592845
			11'd1560: out = 32'b10000000000000000110111011000100; // input=-2.095703125, output=-0.865370651816
			11'd1561: out = 32'b10000000000000000110111010000100; // input=-2.099609375, output=-0.863406506296
			11'd1562: out = 32'b10000000000000000110111001000011; // input=-2.103515625, output=-0.861429186254
			11'd1563: out = 32'b10000000000000000110111000000010; // input=-2.107421875, output=-0.859438721864
			11'd1564: out = 32'b10000000000000000110110111000000; // input=-2.111328125, output=-0.857435143495
			11'd1565: out = 32'b10000000000000000110110101111110; // input=-2.115234375, output=-0.855418481721
			11'd1566: out = 32'b10000000000000000110110100111100; // input=-2.119140625, output=-0.853388767314
			11'd1567: out = 32'b10000000000000000110110011111001; // input=-2.123046875, output=-0.851346031244
			11'd1568: out = 32'b10000000000000000110110010110110; // input=-2.126953125, output=-0.849290304681
			11'd1569: out = 32'b10000000000000000110110001110010; // input=-2.130859375, output=-0.847221618993
			11'd1570: out = 32'b10000000000000000110110000101110; // input=-2.134765625, output=-0.845140005746
			11'd1571: out = 32'b10000000000000000110101111101001; // input=-2.138671875, output=-0.843045496701
			11'd1572: out = 32'b10000000000000000110101110100100; // input=-2.142578125, output=-0.84093812382
			11'd1573: out = 32'b10000000000000000110101101011110; // input=-2.146484375, output=-0.838817919257
			11'd1574: out = 32'b10000000000000000110101100011000; // input=-2.150390625, output=-0.836684915366
			11'd1575: out = 32'b10000000000000000110101011010010; // input=-2.154296875, output=-0.834539144691
			11'd1576: out = 32'b10000000000000000110101010001011; // input=-2.158203125, output=-0.832380639976
			11'd1577: out = 32'b10000000000000000110101001000100; // input=-2.162109375, output=-0.830209434157
			11'd1578: out = 32'b10000000000000000110100111111101; // input=-2.166015625, output=-0.828025560363
			11'd1579: out = 32'b10000000000000000110100110110101; // input=-2.169921875, output=-0.825829051918
			11'd1580: out = 32'b10000000000000000110100101101100; // input=-2.173828125, output=-0.823619942338
			11'd1581: out = 32'b10000000000000000110100100100100; // input=-2.177734375, output=-0.82139826533
			11'd1582: out = 32'b10000000000000000110100011011010; // input=-2.181640625, output=-0.819164054796
			11'd1583: out = 32'b10000000000000000110100010010001; // input=-2.185546875, output=-0.816917344826
			11'd1584: out = 32'b10000000000000000110100001000111; // input=-2.189453125, output=-0.814658169702
			11'd1585: out = 32'b10000000000000000110011111111100; // input=-2.193359375, output=-0.812386563897
			11'd1586: out = 32'b10000000000000000110011110110001; // input=-2.197265625, output=-0.810102562073
			11'd1587: out = 32'b10000000000000000110011101100110; // input=-2.201171875, output=-0.80780619908
			11'd1588: out = 32'b10000000000000000110011100011011; // input=-2.205078125, output=-0.805497509959
			11'd1589: out = 32'b10000000000000000110011011001110; // input=-2.208984375, output=-0.803176529936
			11'd1590: out = 32'b10000000000000000110011010000010; // input=-2.212890625, output=-0.800843294428
			11'd1591: out = 32'b10000000000000000110011000110101; // input=-2.216796875, output=-0.798497839037
			11'd1592: out = 32'b10000000000000000110010111101000; // input=-2.220703125, output=-0.796140199551
			11'd1593: out = 32'b10000000000000000110010110011010; // input=-2.224609375, output=-0.793770411945
			11'd1594: out = 32'b10000000000000000110010101001100; // input=-2.228515625, output=-0.791388512379
			11'd1595: out = 32'b10000000000000000110010011111110; // input=-2.232421875, output=-0.788994537198
			11'd1596: out = 32'b10000000000000000110010010101111; // input=-2.236328125, output=-0.786588522931
			11'd1597: out = 32'b10000000000000000110010001100000; // input=-2.240234375, output=-0.784170506291
			11'd1598: out = 32'b10000000000000000110010000010000; // input=-2.244140625, output=-0.781740524174
			11'd1599: out = 32'b10000000000000000110001111000000; // input=-2.248046875, output=-0.779298613658
			11'd1600: out = 32'b10000000000000000110001101110000; // input=-2.251953125, output=-0.776844812005
			11'd1601: out = 32'b10000000000000000110001100011111; // input=-2.255859375, output=-0.774379156655
			11'd1602: out = 32'b10000000000000000110001011001110; // input=-2.259765625, output=-0.771901685232
			11'd1603: out = 32'b10000000000000000110001001111100; // input=-2.263671875, output=-0.769412435539
			11'd1604: out = 32'b10000000000000000110001000101010; // input=-2.267578125, output=-0.766911445559
			11'd1605: out = 32'b10000000000000000110000111011000; // input=-2.271484375, output=-0.764398753454
			11'd1606: out = 32'b10000000000000000110000110000101; // input=-2.275390625, output=-0.761874397564
			11'd1607: out = 32'b10000000000000000110000100110010; // input=-2.279296875, output=-0.759338416409
			11'd1608: out = 32'b10000000000000000110000011011111; // input=-2.283203125, output=-0.756790848683
			11'd1609: out = 32'b10000000000000000110000010001011; // input=-2.287109375, output=-0.75423173326
			11'd1610: out = 32'b10000000000000000110000000110110; // input=-2.291015625, output=-0.751661109189
			11'd1611: out = 32'b10000000000000000101111111100010; // input=-2.294921875, output=-0.749079015694
			11'd1612: out = 32'b10000000000000000101111110001101; // input=-2.298828125, output=-0.746485492175
			11'd1613: out = 32'b10000000000000000101111100110111; // input=-2.302734375, output=-0.743880578206
			11'd1614: out = 32'b10000000000000000101111011100010; // input=-2.306640625, output=-0.741264313535
			11'd1615: out = 32'b10000000000000000101111010001100; // input=-2.310546875, output=-0.738636738082
			11'd1616: out = 32'b10000000000000000101111000110101; // input=-2.314453125, output=-0.735997891941
			11'd1617: out = 32'b10000000000000000101110111011110; // input=-2.318359375, output=-0.733347815378
			11'd1618: out = 32'b10000000000000000101110110000111; // input=-2.322265625, output=-0.730686548829
			11'd1619: out = 32'b10000000000000000101110100110000; // input=-2.326171875, output=-0.728014132903
			11'd1620: out = 32'b10000000000000000101110011011000; // input=-2.330078125, output=-0.725330608377
			11'd1621: out = 32'b10000000000000000101110001111111; // input=-2.333984375, output=-0.722636016198
			11'd1622: out = 32'b10000000000000000101110000100111; // input=-2.337890625, output=-0.719930397482
			11'd1623: out = 32'b10000000000000000101101111001110; // input=-2.341796875, output=-0.717213793515
			11'd1624: out = 32'b10000000000000000101101101110100; // input=-2.345703125, output=-0.714486245747
			11'd1625: out = 32'b10000000000000000101101100011011; // input=-2.349609375, output=-0.711747795798
			11'd1626: out = 32'b10000000000000000101101011000000; // input=-2.353515625, output=-0.708998485454
			11'd1627: out = 32'b10000000000000000101101001100110; // input=-2.357421875, output=-0.706238356665
			11'd1628: out = 32'b10000000000000000101101000001011; // input=-2.361328125, output=-0.703467451548
			11'd1629: out = 32'b10000000000000000101100110110000; // input=-2.365234375, output=-0.700685812383
			11'd1630: out = 32'b10000000000000000101100101010101; // input=-2.369140625, output=-0.697893481614
			11'd1631: out = 32'b10000000000000000101100011111001; // input=-2.373046875, output=-0.69509050185
			11'd1632: out = 32'b10000000000000000101100010011101; // input=-2.376953125, output=-0.692276915859
			11'd1633: out = 32'b10000000000000000101100001000000; // input=-2.380859375, output=-0.689452766575
			11'd1634: out = 32'b10000000000000000101011111100011; // input=-2.384765625, output=-0.68661809709
			11'd1635: out = 32'b10000000000000000101011110000110; // input=-2.388671875, output=-0.683772950657
			11'd1636: out = 32'b10000000000000000101011100101000; // input=-2.392578125, output=-0.680917370691
			11'd1637: out = 32'b10000000000000000101011011001010; // input=-2.396484375, output=-0.678051400763
			11'd1638: out = 32'b10000000000000000101011001101100; // input=-2.400390625, output=-0.675175084605
			11'd1639: out = 32'b10000000000000000101011000001110; // input=-2.404296875, output=-0.672288466105
			11'd1640: out = 32'b10000000000000000101010110101111; // input=-2.408203125, output=-0.669391589311
			11'd1641: out = 32'b10000000000000000101010101001111; // input=-2.412109375, output=-0.666484498425
			11'd1642: out = 32'b10000000000000000101010011110000; // input=-2.416015625, output=-0.663567237806
			11'd1643: out = 32'b10000000000000000101010010010000; // input=-2.419921875, output=-0.660639851967
			11'd1644: out = 32'b10000000000000000101010000110000; // input=-2.423828125, output=-0.657702385576
			11'd1645: out = 32'b10000000000000000101001111001111; // input=-2.427734375, output=-0.654754883457
			11'd1646: out = 32'b10000000000000000101001101101110; // input=-2.431640625, output=-0.651797390583
			11'd1647: out = 32'b10000000000000000101001100001101; // input=-2.435546875, output=-0.648829952083
			11'd1648: out = 32'b10000000000000000101001010101011; // input=-2.439453125, output=-0.645852613236
			11'd1649: out = 32'b10000000000000000101001001001001; // input=-2.443359375, output=-0.642865419473
			11'd1650: out = 32'b10000000000000000101000111100111; // input=-2.447265625, output=-0.639868416375
			11'd1651: out = 32'b10000000000000000101000110000101; // input=-2.451171875, output=-0.636861649672
			11'd1652: out = 32'b10000000000000000101000100100010; // input=-2.455078125, output=-0.633845165244
			11'd1653: out = 32'b10000000000000000101000010111111; // input=-2.458984375, output=-0.630819009118
			11'd1654: out = 32'b10000000000000000101000001011011; // input=-2.462890625, output=-0.62778322747
			11'd1655: out = 32'b10000000000000000100111111110111; // input=-2.466796875, output=-0.624737866623
			11'd1656: out = 32'b10000000000000000100111110010011; // input=-2.470703125, output=-0.621682973045
			11'd1657: out = 32'b10000000000000000100111100101111; // input=-2.474609375, output=-0.618618593349
			11'd1658: out = 32'b10000000000000000100111011001010; // input=-2.478515625, output=-0.615544774295
			11'd1659: out = 32'b10000000000000000100111001100101; // input=-2.482421875, output=-0.612461562784
			11'd1660: out = 32'b10000000000000000100111000000000; // input=-2.486328125, output=-0.609369005864
			11'd1661: out = 32'b10000000000000000100110110011010; // input=-2.490234375, output=-0.606267150722
			11'd1662: out = 32'b10000000000000000100110100110100; // input=-2.494140625, output=-0.60315604469
			11'd1663: out = 32'b10000000000000000100110011001110; // input=-2.498046875, output=-0.600035735239
			11'd1664: out = 32'b10000000000000000100110001100111; // input=-2.501953125, output=-0.59690626998
			11'd1665: out = 32'b10000000000000000100110000000001; // input=-2.505859375, output=-0.593767696666
			11'd1666: out = 32'b10000000000000000100101110011001; // input=-2.509765625, output=-0.590620063188
			11'd1667: out = 32'b10000000000000000100101100110010; // input=-2.513671875, output=-0.587463417574
			11'd1668: out = 32'b10000000000000000100101011001010; // input=-2.517578125, output=-0.584297807991
			11'd1669: out = 32'b10000000000000000100101001100010; // input=-2.521484375, output=-0.581123282743
			11'd1670: out = 32'b10000000000000000100100111111010; // input=-2.525390625, output=-0.577939890268
			11'd1671: out = 32'b10000000000000000100100110010001; // input=-2.529296875, output=-0.574747679141
			11'd1672: out = 32'b10000000000000000100100100101000; // input=-2.533203125, output=-0.571546698072
			11'd1673: out = 32'b10000000000000000100100010111111; // input=-2.537109375, output=-0.568336995904
			11'd1674: out = 32'b10000000000000000100100001010110; // input=-2.541015625, output=-0.565118621612
			11'd1675: out = 32'b10000000000000000100011111101100; // input=-2.544921875, output=-0.561891624306
			11'd1676: out = 32'b10000000000000000100011110000010; // input=-2.548828125, output=-0.558656053224
			11'd1677: out = 32'b10000000000000000100011100011000; // input=-2.552734375, output=-0.555411957739
			11'd1678: out = 32'b10000000000000000100011010101101; // input=-2.556640625, output=-0.55215938735
			11'd1679: out = 32'b10000000000000000100011001000010; // input=-2.560546875, output=-0.548898391689
			11'd1680: out = 32'b10000000000000000100010111010111; // input=-2.564453125, output=-0.545629020513
			11'd1681: out = 32'b10000000000000000100010101101100; // input=-2.568359375, output=-0.54235132371
			11'd1682: out = 32'b10000000000000000100010100000000; // input=-2.572265625, output=-0.539065351293
			11'd1683: out = 32'b10000000000000000100010010010100; // input=-2.576171875, output=-0.535771153402
			11'd1684: out = 32'b10000000000000000100010000101000; // input=-2.580078125, output=-0.532468780302
			11'd1685: out = 32'b10000000000000000100001110111011; // input=-2.583984375, output=-0.529158282384
			11'd1686: out = 32'b10000000000000000100001101001111; // input=-2.587890625, output=-0.525839710162
			11'd1687: out = 32'b10000000000000000100001011100010; // input=-2.591796875, output=-0.522513114272
			11'd1688: out = 32'b10000000000000000100001001110100; // input=-2.595703125, output=-0.519178545475
			11'd1689: out = 32'b10000000000000000100001000000111; // input=-2.599609375, output=-0.515836054653
			11'd1690: out = 32'b10000000000000000100000110011001; // input=-2.603515625, output=-0.512485692806
			11'd1691: out = 32'b10000000000000000100000100101011; // input=-2.607421875, output=-0.509127511059
			11'd1692: out = 32'b10000000000000000100000010111101; // input=-2.611328125, output=-0.505761560652
			11'd1693: out = 32'b10000000000000000100000001001110; // input=-2.615234375, output=-0.502387892946
			11'd1694: out = 32'b10000000000000000011111111011111; // input=-2.619140625, output=-0.499006559419
			11'd1695: out = 32'b10000000000000000011111101110000; // input=-2.623046875, output=-0.495617611666
			11'd1696: out = 32'b10000000000000000011111100000001; // input=-2.626953125, output=-0.492221101398
			11'd1697: out = 32'b10000000000000000011111010010010; // input=-2.630859375, output=-0.488817080442
			11'd1698: out = 32'b10000000000000000011111000100010; // input=-2.634765625, output=-0.485405600738
			11'd1699: out = 32'b10000000000000000011110110110010; // input=-2.638671875, output=-0.481986714342
			11'd1700: out = 32'b10000000000000000011110101000001; // input=-2.642578125, output=-0.478560473421
			11'd1701: out = 32'b10000000000000000011110011010001; // input=-2.646484375, output=-0.475126930257
			11'd1702: out = 32'b10000000000000000011110001100000; // input=-2.650390625, output=-0.47168613724
			11'd1703: out = 32'b10000000000000000011101111101111; // input=-2.654296875, output=-0.468238146873
			11'd1704: out = 32'b10000000000000000011101101111110; // input=-2.658203125, output=-0.464783011769
			11'd1705: out = 32'b10000000000000000011101100001101; // input=-2.662109375, output=-0.461320784647
			11'd1706: out = 32'b10000000000000000011101010011011; // input=-2.666015625, output=-0.457851518337
			11'd1707: out = 32'b10000000000000000011101000101001; // input=-2.669921875, output=-0.454375265777
			11'd1708: out = 32'b10000000000000000011100110110111; // input=-2.673828125, output=-0.450892080009
			11'd1709: out = 32'b10000000000000000011100101000100; // input=-2.677734375, output=-0.447402014183
			11'd1710: out = 32'b10000000000000000011100011010010; // input=-2.681640625, output=-0.443905121553
			11'd1711: out = 32'b10000000000000000011100001011111; // input=-2.685546875, output=-0.440401455476
			11'd1712: out = 32'b10000000000000000011011111101100; // input=-2.689453125, output=-0.436891069416
			11'd1713: out = 32'b10000000000000000011011101111001; // input=-2.693359375, output=-0.433374016935
			11'd1714: out = 32'b10000000000000000011011100000101; // input=-2.697265625, output=-0.429850351699
			11'd1715: out = 32'b10000000000000000011011010010010; // input=-2.701171875, output=-0.426320127476
			11'd1716: out = 32'b10000000000000000011011000011110; // input=-2.705078125, output=-0.422783398133
			11'd1717: out = 32'b10000000000000000011010110101010; // input=-2.708984375, output=-0.419240217635
			11'd1718: out = 32'b10000000000000000011010100110101; // input=-2.712890625, output=-0.415690640047
			11'd1719: out = 32'b10000000000000000011010011000001; // input=-2.716796875, output=-0.412134719532
			11'd1720: out = 32'b10000000000000000011010001001100; // input=-2.720703125, output=-0.408572510347
			11'd1721: out = 32'b10000000000000000011001111010111; // input=-2.724609375, output=-0.405004066849
			11'd1722: out = 32'b10000000000000000011001101100010; // input=-2.728515625, output=-0.401429443487
			11'd1723: out = 32'b10000000000000000011001011101101; // input=-2.732421875, output=-0.397848694806
			11'd1724: out = 32'b10000000000000000011001001110111; // input=-2.736328125, output=-0.394261875443
			11'd1725: out = 32'b10000000000000000011001000000001; // input=-2.740234375, output=-0.390669040129
			11'd1726: out = 32'b10000000000000000011000110001100; // input=-2.744140625, output=-0.387070243686
			11'd1727: out = 32'b10000000000000000011000100010101; // input=-2.748046875, output=-0.383465541027
			11'd1728: out = 32'b10000000000000000011000010011111; // input=-2.751953125, output=-0.379854987156
			11'd1729: out = 32'b10000000000000000011000000101001; // input=-2.755859375, output=-0.376238637166
			11'd1730: out = 32'b10000000000000000010111110110010; // input=-2.759765625, output=-0.372616546236
			11'd1731: out = 32'b10000000000000000010111100111011; // input=-2.763671875, output=-0.368988769637
			11'd1732: out = 32'b10000000000000000010111011000100; // input=-2.767578125, output=-0.365355362723
			11'd1733: out = 32'b10000000000000000010111001001101; // input=-2.771484375, output=-0.361716380935
			11'd1734: out = 32'b10000000000000000010110111010101; // input=-2.775390625, output=-0.358071879801
			11'd1735: out = 32'b10000000000000000010110101011110; // input=-2.779296875, output=-0.35442191493
			11'd1736: out = 32'b10000000000000000010110011100110; // input=-2.783203125, output=-0.350766542017
			11'd1737: out = 32'b10000000000000000010110001101110; // input=-2.787109375, output=-0.347105816838
			11'd1738: out = 32'b10000000000000000010101111110110; // input=-2.791015625, output=-0.343439795251
			11'd1739: out = 32'b10000000000000000010101101111110; // input=-2.794921875, output=-0.339768533196
			11'd1740: out = 32'b10000000000000000010101100000101; // input=-2.798828125, output=-0.336092086691
			11'd1741: out = 32'b10000000000000000010101010001100; // input=-2.802734375, output=-0.332410511834
			11'd1742: out = 32'b10000000000000000010101000010100; // input=-2.806640625, output=-0.328723864801
			11'd1743: out = 32'b10000000000000000010100110011011; // input=-2.810546875, output=-0.325032201847
			11'd1744: out = 32'b10000000000000000010100100100010; // input=-2.814453125, output=-0.321335579302
			11'd1745: out = 32'b10000000000000000010100010101000; // input=-2.818359375, output=-0.31763405357
			11'd1746: out = 32'b10000000000000000010100000101111; // input=-2.822265625, output=-0.313927681134
			11'd1747: out = 32'b10000000000000000010011110110101; // input=-2.826171875, output=-0.310216518548
			11'd1748: out = 32'b10000000000000000010011100111011; // input=-2.830078125, output=-0.306500622439
			11'd1749: out = 32'b10000000000000000010011011000001; // input=-2.833984375, output=-0.302780049508
			11'd1750: out = 32'b10000000000000000010011001000111; // input=-2.837890625, output=-0.299054856526
			11'd1751: out = 32'b10000000000000000010010111001101; // input=-2.841796875, output=-0.295325100335
			11'd1752: out = 32'b10000000000000000010010101010011; // input=-2.845703125, output=-0.291590837846
			11'd1753: out = 32'b10000000000000000010010011011000; // input=-2.849609375, output=-0.28785212604
			11'd1754: out = 32'b10000000000000000010010001011110; // input=-2.853515625, output=-0.284109021964
			11'd1755: out = 32'b10000000000000000010001111100011; // input=-2.857421875, output=-0.280361582734
			11'd1756: out = 32'b10000000000000000010001101101000; // input=-2.861328125, output=-0.276609865532
			11'd1757: out = 32'b10000000000000000010001011101101; // input=-2.865234375, output=-0.272853927603
			11'd1758: out = 32'b10000000000000000010001001110010; // input=-2.869140625, output=-0.269093826259
			11'd1759: out = 32'b10000000000000000010000111110110; // input=-2.873046875, output=-0.265329618874
			11'd1760: out = 32'b10000000000000000010000101111011; // input=-2.876953125, output=-0.261561362886
			11'd1761: out = 32'b10000000000000000010000011111111; // input=-2.880859375, output=-0.257789115793
			11'd1762: out = 32'b10000000000000000010000010000011; // input=-2.884765625, output=-0.254012935156
			11'd1763: out = 32'b10000000000000000010000000001000; // input=-2.888671875, output=-0.250232878593
			11'd1764: out = 32'b10000000000000000001111110001100; // input=-2.892578125, output=-0.246449003785
			11'd1765: out = 32'b10000000000000000001111100010000; // input=-2.896484375, output=-0.242661368468
			11'd1766: out = 32'b10000000000000000001111010010011; // input=-2.900390625, output=-0.238870030437
			11'd1767: out = 32'b10000000000000000001111000010111; // input=-2.904296875, output=-0.235075047543
			11'd1768: out = 32'b10000000000000000001110110011010; // input=-2.908203125, output=-0.231276477694
			11'd1769: out = 32'b10000000000000000001110100011110; // input=-2.912109375, output=-0.22747437885
			11'd1770: out = 32'b10000000000000000001110010100001; // input=-2.916015625, output=-0.223668809027
			11'd1771: out = 32'b10000000000000000001110000100100; // input=-2.919921875, output=-0.219859826292
			11'd1772: out = 32'b10000000000000000001101110100111; // input=-2.923828125, output=-0.216047488768
			11'd1773: out = 32'b10000000000000000001101100101010; // input=-2.927734375, output=-0.212231854624
			11'd1774: out = 32'b10000000000000000001101010101101; // input=-2.931640625, output=-0.208412982084
			11'd1775: out = 32'b10000000000000000001101000110000; // input=-2.935546875, output=-0.204590929418
			11'd1776: out = 32'b10000000000000000001100110110011; // input=-2.939453125, output=-0.200765754946
			11'd1777: out = 32'b10000000000000000001100100110101; // input=-2.943359375, output=-0.196937517036
			11'd1778: out = 32'b10000000000000000001100010111000; // input=-2.947265625, output=-0.193106274101
			11'd1779: out = 32'b10000000000000000001100000111010; // input=-2.951171875, output=-0.189272084602
			11'd1780: out = 32'b10000000000000000001011110111100; // input=-2.955078125, output=-0.185435007044
			11'd1781: out = 32'b10000000000000000001011100111111; // input=-2.958984375, output=-0.181595099977
			11'd1782: out = 32'b10000000000000000001011011000001; // input=-2.962890625, output=-0.177752421991
			11'd1783: out = 32'b10000000000000000001011001000011; // input=-2.966796875, output=-0.173907031722
			11'd1784: out = 32'b10000000000000000001010111000100; // input=-2.970703125, output=-0.170058987846
			11'd1785: out = 32'b10000000000000000001010101000110; // input=-2.974609375, output=-0.166208349078
			11'd1786: out = 32'b10000000000000000001010011001000; // input=-2.978515625, output=-0.162355174176
			11'd1787: out = 32'b10000000000000000001010001001010; // input=-2.982421875, output=-0.158499521934
			11'd1788: out = 32'b10000000000000000001001111001011; // input=-2.986328125, output=-0.154641451184
			11'd1789: out = 32'b10000000000000000001001101001101; // input=-2.990234375, output=-0.150781020795
			11'd1790: out = 32'b10000000000000000001001011001110; // input=-2.994140625, output=-0.146918289674
			11'd1791: out = 32'b10000000000000000001001001010000; // input=-2.998046875, output=-0.14305331676
			11'd1792: out = 32'b10000000000000000001000111010001; // input=-3.001953125, output=-0.139186161029
			11'd1793: out = 32'b10000000000000000001000101010010; // input=-3.005859375, output=-0.135316881489
			11'd1794: out = 32'b10000000000000000001000011010011; // input=-3.009765625, output=-0.131445537179
			11'd1795: out = 32'b10000000000000000001000001010100; // input=-3.013671875, output=-0.127572187172
			11'd1796: out = 32'b10000000000000000000111111010101; // input=-3.017578125, output=-0.12369689057
			11'd1797: out = 32'b10000000000000000000111101010110; // input=-3.021484375, output=-0.119819706506
			11'd1798: out = 32'b10000000000000000000111011010111; // input=-3.025390625, output=-0.115940694141
			11'd1799: out = 32'b10000000000000000000111001011000; // input=-3.029296875, output=-0.112059912663
			11'd1800: out = 32'b10000000000000000000110111011001; // input=-3.033203125, output=-0.108177421289
			11'd1801: out = 32'b10000000000000000000110101011001; // input=-3.037109375, output=-0.10429327926
			11'd1802: out = 32'b10000000000000000000110011011010; // input=-3.041015625, output=-0.100407545845
			11'd1803: out = 32'b10000000000000000000110001011011; // input=-3.044921875, output=-0.0965202803338
			11'd1804: out = 32'b10000000000000000000101111011011; // input=-3.048828125, output=-0.0926315420419
			11'd1805: out = 32'b10000000000000000000101101011100; // input=-3.052734375, output=-0.0887413903066
			11'd1806: out = 32'b10000000000000000000101011011100; // input=-3.056640625, output=-0.0848498844869
			11'd1807: out = 32'b10000000000000000000101001011101; // input=-3.060546875, output=-0.0809570839624
			11'd1808: out = 32'b10000000000000000000100111011101; // input=-3.064453125, output=-0.0770630481324
			11'd1809: out = 32'b10000000000000000000100101011110; // input=-3.068359375, output=-0.0731678364151
			11'd1810: out = 32'b10000000000000000000100011011110; // input=-3.072265625, output=-0.0692715082466
			11'd1811: out = 32'b10000000000000000000100001011110; // input=-3.076171875, output=-0.0653741230801
			11'd1812: out = 32'b10000000000000000000011111011110; // input=-3.080078125, output=-0.061475740385
			11'd1813: out = 32'b10000000000000000000011101011111; // input=-3.083984375, output=-0.0575764196456
			11'd1814: out = 32'b10000000000000000000011011011111; // input=-3.087890625, output=-0.053676220361
			11'd1815: out = 32'b10000000000000000000011001011111; // input=-3.091796875, output=-0.0497752020432
			11'd1816: out = 32'b10000000000000000000010111011111; // input=-3.095703125, output=-0.0458734242172
			11'd1817: out = 32'b10000000000000000000010101011111; // input=-3.099609375, output=-0.0419709464191
			11'd1818: out = 32'b10000000000000000000010011011111; // input=-3.103515625, output=-0.038067828196
			11'd1819: out = 32'b10000000000000000000010001011111; // input=-3.107421875, output=-0.0341641291047
			11'd1820: out = 32'b10000000000000000000001111100000; // input=-3.111328125, output=-0.0302599087108
			11'd1821: out = 32'b10000000000000000000001101100000; // input=-3.115234375, output=-0.0263552265879
			11'd1822: out = 32'b10000000000000000000001011100000; // input=-3.119140625, output=-0.0224501423167
			11'd1823: out = 32'b10000000000000000000001001100000; // input=-3.123046875, output=-0.018544715484
			11'd1824: out = 32'b10000000000000000000000111100000; // input=-3.126953125, output=-0.0146390056817
			11'd1825: out = 32'b10000000000000000000000101100000; // input=-3.130859375, output=-0.0107330725062
			11'd1826: out = 32'b10000000000000000000000011100000; // input=-3.134765625, output=-0.0068269755572
			11'd1827: out = 32'b10000000000000000000000001100000; // input=-3.138671875, output=-0.00292077443696
			11'd1828: out = 32'b00000000000000000000000000100000; // input=-3.142578125, output=0.000985471250699
			11'd1829: out = 32'b00000000000000000000000010100000; // input=-3.146484375, output=0.00489170190128
			11'd1830: out = 32'b00000000000000000000000100100000; // input=-3.150390625, output=0.00879785791051
			11'd1831: out = 32'b00000000000000000000000110100000; // input=-3.154296875, output=0.0127038796752
			11'd1832: out = 32'b00000000000000000000001000100000; // input=-3.158203125, output=0.0166097075944
			11'd1833: out = 32'b00000000000000000000001010100000; // input=-3.162109375, output=0.0205152820699
			11'd1834: out = 32'b00000000000000000000001100100000; // input=-3.166015625, output=0.0244205435074
			11'd1835: out = 32'b00000000000000000000001110100000; // input=-3.169921875, output=0.0283254323174
			11'd1836: out = 32'b00000000000000000000010000100000; // input=-3.173828125, output=0.0322298889162
			11'd1837: out = 32'b00000000000000000000010010100000; // input=-3.177734375, output=0.0361338537266
			11'd1838: out = 32'b00000000000000000000010100100000; // input=-3.181640625, output=0.0400372671788
			11'd1839: out = 32'b00000000000000000000010110100000; // input=-3.185546875, output=0.0439400697116
			11'd1840: out = 32'b00000000000000000000011000100000; // input=-3.189453125, output=0.0478422017729
			11'd1841: out = 32'b00000000000000000000011010100000; // input=-3.193359375, output=0.0517436038212
			11'd1842: out = 32'b00000000000000000000011100011111; // input=-3.197265625, output=0.0556442163256
			11'd1843: out = 32'b00000000000000000000011110011111; // input=-3.201171875, output=0.0595439797679
			11'd1844: out = 32'b00000000000000000000100000011111; // input=-3.205078125, output=0.0634428346422
			11'd1845: out = 32'b00000000000000000000100010011111; // input=-3.208984375, output=0.0673407214569
			11'd1846: out = 32'b00000000000000000000100100011110; // input=-3.212890625, output=0.0712375807351
			11'd1847: out = 32'b00000000000000000000100110011110; // input=-3.216796875, output=0.0751333530155
			11'd1848: out = 32'b00000000000000000000101000011110; // input=-3.220703125, output=0.0790279788533
			11'd1849: out = 32'b00000000000000000000101010011101; // input=-3.224609375, output=0.0829213988214
			11'd1850: out = 32'b00000000000000000000101100011101; // input=-3.228515625, output=0.086813553511
			11'd1851: out = 32'b00000000000000000000101110011100; // input=-3.232421875, output=0.0907043835325
			11'd1852: out = 32'b00000000000000000000110000011100; // input=-3.236328125, output=0.0945938295168
			11'd1853: out = 32'b00000000000000000000110010011011; // input=-3.240234375, output=0.0984818321156
			11'd1854: out = 32'b00000000000000000000110100011010; // input=-3.244140625, output=0.102368332003
			11'd1855: out = 32'b00000000000000000000110110011010; // input=-3.248046875, output=0.106253269875
			11'd1856: out = 32'b00000000000000000000111000011001; // input=-3.251953125, output=0.110136586453
			11'd1857: out = 32'b00000000000000000000111010011000; // input=-3.255859375, output=0.114018222483
			11'd1858: out = 32'b00000000000000000000111100010111; // input=-3.259765625, output=0.117898118735
			11'd1859: out = 32'b00000000000000000000111110010110; // input=-3.263671875, output=0.121776216006
			11'd1860: out = 32'b00000000000000000001000000010101; // input=-3.267578125, output=0.125652455122
			11'd1861: out = 32'b00000000000000000001000010010100; // input=-3.271484375, output=0.129526776936
			11'd1862: out = 32'b00000000000000000001000100010011; // input=-3.275390625, output=0.133399122331
			11'd1863: out = 32'b00000000000000000001000110010010; // input=-3.279296875, output=0.13726943222
			11'd1864: out = 32'b00000000000000000001001000010001; // input=-3.283203125, output=0.141137647546
			11'd1865: out = 32'b00000000000000000001001010001111; // input=-3.287109375, output=0.145003709285
			11'd1866: out = 32'b00000000000000000001001100001110; // input=-3.291015625, output=0.148867558446
			11'd1867: out = 32'b00000000000000000001001110001101; // input=-3.294921875, output=0.152729136071
			11'd1868: out = 32'b00000000000000000001010000001011; // input=-3.298828125, output=0.156588383237
			11'd1869: out = 32'b00000000000000000001010010001001; // input=-3.302734375, output=0.160445241058
			11'd1870: out = 32'b00000000000000000001010100001000; // input=-3.306640625, output=0.164299650681
			11'd1871: out = 32'b00000000000000000001010110000110; // input=-3.310546875, output=0.168151553294
			11'd1872: out = 32'b00000000000000000001011000000100; // input=-3.314453125, output=0.172000890121
			11'd1873: out = 32'b00000000000000000001011010000010; // input=-3.318359375, output=0.175847602426
			11'd1874: out = 32'b00000000000000000001011100000000; // input=-3.322265625, output=0.179691631513
			11'd1875: out = 32'b00000000000000000001011101111110; // input=-3.326171875, output=0.183532918727
			11'd1876: out = 32'b00000000000000000001011111111100; // input=-3.330078125, output=0.187371405454
			11'd1877: out = 32'b00000000000000000001100001111001; // input=-3.333984375, output=0.191207033124
			11'd1878: out = 32'b00000000000000000001100011110111; // input=-3.337890625, output=0.19503974321
			11'd1879: out = 32'b00000000000000000001100101110101; // input=-3.341796875, output=0.198869477229
			11'd1880: out = 32'b00000000000000000001100111110010; // input=-3.345703125, output=0.202696176745
			11'd1881: out = 32'b00000000000000000001101001101111; // input=-3.349609375, output=0.206519783367
			11'd1882: out = 32'b00000000000000000001101011101100; // input=-3.353515625, output=0.210340238751
			11'd1883: out = 32'b00000000000000000001101101101010; // input=-3.357421875, output=0.214157484602
			11'd1884: out = 32'b00000000000000000001101111100110; // input=-3.361328125, output=0.217971462672
			11'd1885: out = 32'b00000000000000000001110001100011; // input=-3.365234375, output=0.221782114767
			11'd1886: out = 32'b00000000000000000001110011100000; // input=-3.369140625, output=0.225589382739
			11'd1887: out = 32'b00000000000000000001110101011101; // input=-3.373046875, output=0.229393208495
			11'd1888: out = 32'b00000000000000000001110111011001; // input=-3.376953125, output=0.233193533993
			11'd1889: out = 32'b00000000000000000001111001010110; // input=-3.380859375, output=0.236990301245
			11'd1890: out = 32'b00000000000000000001111011010010; // input=-3.384765625, output=0.240783452315
			11'd1891: out = 32'b00000000000000000001111101001110; // input=-3.388671875, output=0.244572929327
			11'd1892: out = 32'b00000000000000000001111111001010; // input=-3.392578125, output=0.248358674457
			11'd1893: out = 32'b00000000000000000010000001000110; // input=-3.396484375, output=0.252140629939
			11'd1894: out = 32'b00000000000000000010000011000010; // input=-3.400390625, output=0.255918738065
			11'd1895: out = 32'b00000000000000000010000100111110; // input=-3.404296875, output=0.259692941186
			11'd1896: out = 32'b00000000000000000010000110111001; // input=-3.408203125, output=0.263463181712
			11'd1897: out = 32'b00000000000000000010001000110101; // input=-3.412109375, output=0.267229402115
			11'd1898: out = 32'b00000000000000000010001010110000; // input=-3.416015625, output=0.270991544925
			11'd1899: out = 32'b00000000000000000010001100101011; // input=-3.419921875, output=0.274749552738
			11'd1900: out = 32'b00000000000000000010001110100110; // input=-3.423828125, output=0.27850336821
			11'd1901: out = 32'b00000000000000000010010000100001; // input=-3.427734375, output=0.282252934064
			11'd1902: out = 32'b00000000000000000010010010011100; // input=-3.431640625, output=0.285998193086
			11'd1903: out = 32'b00000000000000000010010100010110; // input=-3.435546875, output=0.289739088127
			11'd1904: out = 32'b00000000000000000010010110010001; // input=-3.439453125, output=0.293475562106
			11'd1905: out = 32'b00000000000000000010011000001011; // input=-3.443359375, output=0.297207558008
			11'd1906: out = 32'b00000000000000000010011010000101; // input=-3.447265625, output=0.30093501889
			11'd1907: out = 32'b00000000000000000010011011111111; // input=-3.451171875, output=0.304657887873
			11'd1908: out = 32'b00000000000000000010011101111001; // input=-3.455078125, output=0.308376108151
			11'd1909: out = 32'b00000000000000000010011111110011; // input=-3.458984375, output=0.31208962299
			11'd1910: out = 32'b00000000000000000010100001101100; // input=-3.462890625, output=0.315798375725
			11'd1911: out = 32'b00000000000000000010100011100101; // input=-3.466796875, output=0.319502309765
			11'd1912: out = 32'b00000000000000000010100101011111; // input=-3.470703125, output=0.323201368593
			11'd1913: out = 32'b00000000000000000010100111011000; // input=-3.474609375, output=0.326895495766
			11'd1914: out = 32'b00000000000000000010101001010001; // input=-3.478515625, output=0.330584634915
			11'd1915: out = 32'b00000000000000000010101011001001; // input=-3.482421875, output=0.33426872975
			11'd1916: out = 32'b00000000000000000010101101000010; // input=-3.486328125, output=0.337947724056
			11'd1917: out = 32'b00000000000000000010101110111010; // input=-3.490234375, output=0.341621561694
			11'd1918: out = 32'b00000000000000000010110000110010; // input=-3.494140625, output=0.345290186609
			11'd1919: out = 32'b00000000000000000010110010101011; // input=-3.498046875, output=0.348953542819
			11'd1920: out = 32'b00000000000000000010110100100010; // input=-3.501953125, output=0.352611574428
			11'd1921: out = 32'b00000000000000000010110110011010; // input=-3.505859375, output=0.356264225619
			11'd1922: out = 32'b00000000000000000010111000010010; // input=-3.509765625, output=0.359911440655
			11'd1923: out = 32'b00000000000000000010111010001001; // input=-3.513671875, output=0.363553163886
			11'd1924: out = 32'b00000000000000000010111100000000; // input=-3.517578125, output=0.367189339743
			11'd1925: out = 32'b00000000000000000010111101110111; // input=-3.521484375, output=0.370819912742
			11'd1926: out = 32'b00000000000000000010111111101110; // input=-3.525390625, output=0.374444827485
			11'd1927: out = 32'b00000000000000000011000001100100; // input=-3.529296875, output=0.378064028661
			11'd1928: out = 32'b00000000000000000011000011011011; // input=-3.533203125, output=0.381677461046
			11'd1929: out = 32'b00000000000000000011000101010001; // input=-3.537109375, output=0.385285069501
			11'd1930: out = 32'b00000000000000000011000111000111; // input=-3.541015625, output=0.388886798981
			11'd1931: out = 32'b00000000000000000011001000111101; // input=-3.544921875, output=0.392482594526
			11'd1932: out = 32'b00000000000000000011001010110011; // input=-3.548828125, output=0.39607240127
			11'd1933: out = 32'b00000000000000000011001100101000; // input=-3.552734375, output=0.399656164437
			11'd1934: out = 32'b00000000000000000011001110011101; // input=-3.556640625, output=0.403233829342
			11'd1935: out = 32'b00000000000000000011010000010010; // input=-3.560546875, output=0.406805341395
			11'd1936: out = 32'b00000000000000000011010010000111; // input=-3.564453125, output=0.410370646099
			11'd1937: out = 32'b00000000000000000011010011111100; // input=-3.568359375, output=0.413929689052
			11'd1938: out = 32'b00000000000000000011010101110000; // input=-3.572265625, output=0.417482415947
			11'd1939: out = 32'b00000000000000000011010111100100; // input=-3.576171875, output=0.421028772574
			11'd1940: out = 32'b00000000000000000011011001011000; // input=-3.580078125, output=0.42456870482
			11'd1941: out = 32'b00000000000000000011011011001100; // input=-3.583984375, output=0.42810215867
			11'd1942: out = 32'b00000000000000000011011101000000; // input=-3.587890625, output=0.431629080208
			11'd1943: out = 32'b00000000000000000011011110110011; // input=-3.591796875, output=0.435149415617
			11'd1944: out = 32'b00000000000000000011100000100110; // input=-3.595703125, output=0.438663111181
			11'd1945: out = 32'b00000000000000000011100010011001; // input=-3.599609375, output=0.442170113286
			11'd1946: out = 32'b00000000000000000011100100001100; // input=-3.603515625, output=0.445670368419
			11'd1947: out = 32'b00000000000000000011100101111110; // input=-3.607421875, output=0.44916382317
			11'd1948: out = 32'b00000000000000000011100111110000; // input=-3.611328125, output=0.452650424234
			11'd1949: out = 32'b00000000000000000011101001100010; // input=-3.615234375, output=0.45613011841
			11'd1950: out = 32'b00000000000000000011101011010100; // input=-3.619140625, output=0.459602852601
			11'd1951: out = 32'b00000000000000000011101101000110; // input=-3.623046875, output=0.463068573818
			11'd1952: out = 32'b00000000000000000011101110110111; // input=-3.626953125, output=0.466527229179
			11'd1953: out = 32'b00000000000000000011110000101000; // input=-3.630859375, output=0.469978765908
			11'd1954: out = 32'b00000000000000000011110010011001; // input=-3.634765625, output=0.473423131339
			11'd1955: out = 32'b00000000000000000011110100001010; // input=-3.638671875, output=0.476860272915
			11'd1956: out = 32'b00000000000000000011110101111010; // input=-3.642578125, output=0.480290138191
			11'd1957: out = 32'b00000000000000000011110111101010; // input=-3.646484375, output=0.48371267483
			11'd1958: out = 32'b00000000000000000011111001011010; // input=-3.650390625, output=0.487127830609
			11'd1959: out = 32'b00000000000000000011111011001010; // input=-3.654296875, output=0.490535553416
			11'd1960: out = 32'b00000000000000000011111100111001; // input=-3.658203125, output=0.493935791254
			11'd1961: out = 32'b00000000000000000011111110101000; // input=-3.662109375, output=0.49732849224
			11'd1962: out = 32'b00000000000000000100000000010111; // input=-3.666015625, output=0.500713604605
			11'd1963: out = 32'b00000000000000000100000010000110; // input=-3.669921875, output=0.504091076697
			11'd1964: out = 32'b00000000000000000100000011110100; // input=-3.673828125, output=0.507460856978
			11'd1965: out = 32'b00000000000000000100000101100011; // input=-3.677734375, output=0.510822894032
			11'd1966: out = 32'b00000000000000000100000111010001; // input=-3.681640625, output=0.514177136557
			11'd1967: out = 32'b00000000000000000100001000111110; // input=-3.685546875, output=0.517523533371
			11'd1968: out = 32'b00000000000000000100001010101100; // input=-3.689453125, output=0.520862033412
			11'd1969: out = 32'b00000000000000000100001100011001; // input=-3.693359375, output=0.52419258574
			11'd1970: out = 32'b00000000000000000100001110000110; // input=-3.697265625, output=0.527515139534
			11'd1971: out = 32'b00000000000000000100001111110010; // input=-3.701171875, output=0.530829644096
			11'd1972: out = 32'b00000000000000000100010001011111; // input=-3.705078125, output=0.534136048851
			11'd1973: out = 32'b00000000000000000100010011001011; // input=-3.708984375, output=0.537434303347
			11'd1974: out = 32'b00000000000000000100010100110110; // input=-3.712890625, output=0.540724357256
			11'd1975: out = 32'b00000000000000000100010110100010; // input=-3.716796875, output=0.544006160377
			11'd1976: out = 32'b00000000000000000100011000001101; // input=-3.720703125, output=0.547279662634
			11'd1977: out = 32'b00000000000000000100011001111000; // input=-3.724609375, output=0.550544814076
			11'd1978: out = 32'b00000000000000000100011011100011; // input=-3.728515625, output=0.553801564881
			11'd1979: out = 32'b00000000000000000100011101001101; // input=-3.732421875, output=0.557049865356
			11'd1980: out = 32'b00000000000000000100011110111000; // input=-3.736328125, output=0.560289665936
			11'd1981: out = 32'b00000000000000000100100000100001; // input=-3.740234375, output=0.563520917184
			11'd1982: out = 32'b00000000000000000100100010001011; // input=-3.744140625, output=0.566743569797
			11'd1983: out = 32'b00000000000000000100100011110100; // input=-3.748046875, output=0.5699575746
			11'd1984: out = 32'b00000000000000000100100101011101; // input=-3.751953125, output=0.573162882552
			11'd1985: out = 32'b00000000000000000100100111000110; // input=-3.755859375, output=0.576359444743
			11'd1986: out = 32'b00000000000000000100101000101111; // input=-3.759765625, output=0.579547212398
			11'd1987: out = 32'b00000000000000000100101010010111; // input=-3.763671875, output=0.582726136876
			11'd1988: out = 32'b00000000000000000100101011111111; // input=-3.767578125, output=0.58589616967
			11'd1989: out = 32'b00000000000000000100101101100110; // input=-3.771484375, output=0.58905726241
			11'd1990: out = 32'b00000000000000000100101111001110; // input=-3.775390625, output=0.59220936686
			11'd1991: out = 32'b00000000000000000100110000110101; // input=-3.779296875, output=0.595352434924
			11'd1992: out = 32'b00000000000000000100110010011011; // input=-3.783203125, output=0.598486418642
			11'd1993: out = 32'b00000000000000000100110100000010; // input=-3.787109375, output=0.601611270194
			11'd1994: out = 32'b00000000000000000100110101101000; // input=-3.791015625, output=0.604726941898
			11'd1995: out = 32'b00000000000000000100110111001101; // input=-3.794921875, output=0.607833386213
			11'd1996: out = 32'b00000000000000000100111000110011; // input=-3.798828125, output=0.610930555738
			11'd1997: out = 32'b00000000000000000100111010011000; // input=-3.802734375, output=0.614018403215
			11'd1998: out = 32'b00000000000000000100111011111101; // input=-3.806640625, output=0.617096881526
			11'd1999: out = 32'b00000000000000000100111101100010; // input=-3.810546875, output=0.620165943698
			11'd2000: out = 32'b00000000000000000100111111000110; // input=-3.814453125, output=0.623225542901
			11'd2001: out = 32'b00000000000000000101000000101010; // input=-3.818359375, output=0.626275632449
			11'd2002: out = 32'b00000000000000000101000010001101; // input=-3.822265625, output=0.629316165801
			11'd2003: out = 32'b00000000000000000101000011110001; // input=-3.826171875, output=0.632347096563
			11'd2004: out = 32'b00000000000000000101000101010100; // input=-3.830078125, output=0.635368378486
			11'd2005: out = 32'b00000000000000000101000110110110; // input=-3.833984375, output=0.638379965469
			11'd2006: out = 32'b00000000000000000101001000011001; // input=-3.837890625, output=0.64138181156
			11'd2007: out = 32'b00000000000000000101001001111011; // input=-3.841796875, output=0.644373870953
			11'd2008: out = 32'b00000000000000000101001011011101; // input=-3.845703125, output=0.647356097993
			11'd2009: out = 32'b00000000000000000101001100111110; // input=-3.849609375, output=0.650328447176
			11'd2010: out = 32'b00000000000000000101001110011111; // input=-3.853515625, output=0.653290873148
			11'd2011: out = 32'b00000000000000000101010000000000; // input=-3.857421875, output=0.656243330704
			11'd2012: out = 32'b00000000000000000101010001100000; // input=-3.861328125, output=0.659185774794
			11'd2013: out = 32'b00000000000000000101010011000000; // input=-3.865234375, output=0.662118160521
			11'd2014: out = 32'b00000000000000000101010100100000; // input=-3.869140625, output=0.665040443139
			11'd2015: out = 32'b00000000000000000101010101111111; // input=-3.873046875, output=0.667952578058
			11'd2016: out = 32'b00000000000000000101010111011111; // input=-3.876953125, output=0.670854520842
			11'd2017: out = 32'b00000000000000000101011000111101; // input=-3.880859375, output=0.673746227212
			11'd2018: out = 32'b00000000000000000101011010011100; // input=-3.884765625, output=0.676627653043
			11'd2019: out = 32'b00000000000000000101011011111010; // input=-3.888671875, output=0.679498754369
			11'd2020: out = 32'b00000000000000000101011101011000; // input=-3.892578125, output=0.68235948738
			11'd2021: out = 32'b00000000000000000101011110110101; // input=-3.896484375, output=0.685209808425
			11'd2022: out = 32'b00000000000000000101100000010010; // input=-3.900390625, output=0.688049674011
			11'd2023: out = 32'b00000000000000000101100001101111; // input=-3.904296875, output=0.690879040805
			11'd2024: out = 32'b00000000000000000101100011001011; // input=-3.908203125, output=0.693697865636
			11'd2025: out = 32'b00000000000000000101100100100111; // input=-3.912109375, output=0.69650610549
			11'd2026: out = 32'b00000000000000000101100110000011; // input=-3.916015625, output=0.699303717518
			11'd2027: out = 32'b00000000000000000101100111011110; // input=-3.919921875, output=0.702090659032
			11'd2028: out = 32'b00000000000000000101101000111001; // input=-3.923828125, output=0.704866887506
			11'd2029: out = 32'b00000000000000000101101010010100; // input=-3.927734375, output=0.707632360579
			11'd2030: out = 32'b00000000000000000101101011101110; // input=-3.931640625, output=0.710387036053
			11'd2031: out = 32'b00000000000000000101101101001000; // input=-3.935546875, output=0.713130871894
			11'd2032: out = 32'b00000000000000000101101110100001; // input=-3.939453125, output=0.715863826236
			11'd2033: out = 32'b00000000000000000101101111111011; // input=-3.943359375, output=0.718585857376
			11'd2034: out = 32'b00000000000000000101110001010011; // input=-3.947265625, output=0.72129692378
			11'd2035: out = 32'b00000000000000000101110010101100; // input=-3.951171875, output=0.723996984081
			11'd2036: out = 32'b00000000000000000101110100000100; // input=-3.955078125, output=0.726685997079
			11'd2037: out = 32'b00000000000000000101110101011100; // input=-3.958984375, output=0.729363921742
			11'd2038: out = 32'b00000000000000000101110110110011; // input=-3.962890625, output=0.732030717209
			11'd2039: out = 32'b00000000000000000101111000001010; // input=-3.966796875, output=0.734686342788
			11'd2040: out = 32'b00000000000000000101111001100001; // input=-3.970703125, output=0.737330757958
			11'd2041: out = 32'b00000000000000000101111010110111; // input=-3.974609375, output=0.739963922367
			11'd2042: out = 32'b00000000000000000101111100001101; // input=-3.978515625, output=0.742585795837
			11'd2043: out = 32'b00000000000000000101111101100011; // input=-3.982421875, output=0.745196338362
			11'd2044: out = 32'b00000000000000000101111110111000; // input=-3.986328125, output=0.747795510107
			11'd2045: out = 32'b00000000000000000110000000001101; // input=-3.990234375, output=0.750383271413
			11'd2046: out = 32'b00000000000000000110000001100001; // input=-3.994140625, output=0.752959582793
			11'd2047: out = 32'b00000000000000000110000010110101; // input=-3.998046875, output=0.755524404937
		endcase
	end
	converter U0 (a, index);

endmodule

module converter(a, index);
	input  [31:0] a;
	output [10:0] index;

	assign index[10]	= a[31];
	assign index[9:8]	= a[16:15];
	assign index[7:0]	= a[14:7];
endmodule
