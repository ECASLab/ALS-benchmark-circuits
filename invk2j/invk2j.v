//invk2j.v
//theta1 = acos((x^2+y^2-11^2-12^2)/(2*11*12))
//
//
//theta2  = asin [y(11+12*cos(theta2))-x(12*sin(theta2))/(x^2+y^2)]
//

`timescale 1ns/1ps

`define BIT_WIDTH 32
`define FRACTIONS 15
`include "invk2j_combi.v"
module invk2j(x, y, theta1, theta2, clk,rst);

	input [`BIT_WIDTH-1:0] x, y;

	output [`BIT_WIDTH-1:0] theta1, theta2;
	input clk;
	input rst;

	wire [`BIT_WIDTH-1:0] xy_sum, cos_theta2, sin_theta2;

	wire [`BIT_WIDTH-1:0] theta2_num, theta1_num, theta2_in,theta1_in;
	wire [`BIT_WIDTH-1:0] x_sqr, y_sqr, part_y, part_x, cos12, sin12, part_1;
	reg [`BIT_WIDTH-2:0] throw_away;
	reg signed_bit;


	wire overflow_flag;
	reg start, done;
	parameter const_1 = `BIT_WIDTH'b10000000100001001000000000000000;  // -(11^2 + 12^2)
	parameter const_2 = `BIT_WIDTH'b00000000100001000000000000000000;  // 11*12*2

		// theta 2
		// x_sqr = x*x
		// y_sqr = y*y
		// xy_sum = x_sqr + y_sqr
		// theta2_num = xy_sum - (11^2+12^2)
		// theta2_in = theta2_num / (2*11*12)	
		// theta2 = acos (theta2_in)

		qmult #(`FRACTIONS,`BIT_WIDTH) x_multiplier(.i_multiplicand(x), .i_multiplier(x),
	                                                    .o_result(x_sqr), .ovr(overflow_flag));
		qmult #(`FRACTIONS,`BIT_WIDTH) y_multiplier(.i_multiplicand(y), .i_multiplier(y),
		                                            .o_result(y_sqr), .ovr(overflow_flag));
		qadd #(`FRACTIONS,`BIT_WIDTH) xy_adder(.a(x_sqr), .b(y_sqr), .c(xy_sum));
		qadd #(`FRACTIONS,`BIT_WIDTH) num_adder(.a(const_1), .b(xy_sum), .c(theta2_num));
		qdiv #(`FRACTIONS,`BIT_WIDTH) my_divider(.i_dividend(theta2_num), .i_divisor(const_2), 
		                                         .i_start(1'b1), .i_clk(clk), .o_quotient_out(theta2_in), .rst(rst), 
		                                         .o_complete(), .o_overflow());

		acos_lut U0 (theta2_in,theta2);

		


		// theta 1
		// cos_theta2 = cos(theta2)
		// sin_theta2 = sin(theta2)
		// cos12 = 12 * cos_theta2
		// sin12 = 12 * sin_theta2
		// part_1 = 11 + cos12
		// part_y = part_1 * y
		// part_x = sin12 * x
		// theta1_num = part_y - part_x
		// theta1_in = theta1_num / xy_sum
		// theta1 = asin(theta1_in)





		cos_lut U1 (theta2,cos_theta2);
		sin_lut U2 (theta2,sin_theta2);
		qmult #(`FRACTIONS,`BIT_WIDTH) cos_multiplier(.i_multiplicand(cos_theta2), .i_multiplier(`BIT_WIDTH'b00000000000001100000000000000000),
		                                              .o_result(cos12), .ovr(overflow_flag));		
		qmult #(`FRACTIONS,`BIT_WIDTH) sin_multiplier(.i_multiplicand(sin_theta2), .i_multiplier(`BIT_WIDTH'b00000000000001100000000000000000), 
		                                              .o_result(sin12), .ovr(overflow_flag));
		qadd #(`FRACTIONS,`BIT_WIDTH) n_adder(.a(cos12), .b(`BIT_WIDTH'b00000000000001011000000000000000), .c(part_1));
		qmult #(`FRACTIONS,`BIT_WIDTH) multiplier_1(.i_multiplicand(part_1), .i_multiplier(y), .o_result(part_y), .ovr(overflow_flag));
		qmult #(`FRACTIONS,`BIT_WIDTH) multiplier_2(.i_multiplicand(sin12), .i_multiplier(x), .o_result(part_x), .ovr(overflow_flag));

	always@(part_x) begin
		if (part_x[31]) begin
			signed_bit=1'b0;
		end
		else begin
			signed_bit=1'b1;
		end
	end
		qadd #(`FRACTIONS,`BIT_WIDTH) adder_123 (.a({signed_bit,part_x[30:0]}), .b(part_y), .c(theta1_num));
		qdiv #(`FRACTIONS,`BIT_WIDTH) m_divider(.i_dividend(theta1_num), .i_divisor(xy_sum),
		                                        .i_start(1'b1), .i_clk(clk), .rst(rst), .o_quotient_out(theta1_in), 
		                                        .o_complete(), .o_overflow());
		asin_lut U3 (theta1_in,theta1);

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 			Burke
// Engineer: 			Tom Burke
// 
// Create Date:		19:39:14 08/24/2011 
// Design Name: 	
// Module Name:		qdiv.v
// Project Name:		Fixed-point Math Library (Verilog)
// Target Devices: 
// Tool versions:		Xilinx ISE WebPack v14.7
// Description: 		Fixed-point division in (Q,N) format
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
//	Revision 0.02 - 25 May 2014
//							Updated to fix an error
//
// Additional Comments: Based on my description on youtube:
//			http://youtu.be/TEnaPMYiuR8
//
//////////////////////////////////////////////////////////////////////////////////
 
module qdiv #(
	//Parameterized values
	parameter Q = 15,
	parameter N = 32
	)
	(
	input 	[N-1:0] i_dividend,
	input 	[N-1:0] i_divisor,
	input 	i_start,
	input 	i_clk,
	input   rst,
	output 	[N-1:0] o_quotient_out,
	output 	o_complete,
	output	o_overflow
	);
 
	reg [2*N+Q-3:0]	reg_working_quotient;	//	Our working copy of the quotient
	reg [N-1:0] 		reg_quotient;				//	Final quotient
	reg [N-2+Q:0] 		reg_working_dividend;	//	Working copy of the dividend
	reg [2*N+Q-3:0]	reg_working_divisor;		// Working copy of the divisor
 
	reg [N-1:0] 			reg_count; 		//	This is obviously a lot bigger than it needs to be, as we only need 
													//		count to N-1+Q but, computing that number of bits requires a 
													//		logarithm (base 2), and I don't know how to do that in a 
													//		way that will work for everyone
										 
	reg					reg_done;			//	Computation completed flag
	reg					reg_sign;			//	The quotient's sign bit
	reg					reg_overflow;		//	Overflow flag
 
	//initial reg_done = 1'b1;				//	Initial state is to not be doing anything
	//initial reg_overflow = 1'b0;			//		And there should be no woverflow present
	//initial reg_sign = 1'b0;				//		And the sign should be positive

	//initial reg_working_quotient = 0;	
	//initial reg_quotient = 0;				
	//initial reg_working_dividend = 0;	
	//initial reg_working_divisor = 0;		
 	//initial reg_count = 0; 		

 
	assign o_quotient_out[N-2:0] = reg_quotient[N-2:0];	//	The division results
	assign o_quotient_out[N-1] = reg_sign;			    //	The sign of the quotient
	assign o_complete = reg_done;
	assign o_overflow = reg_overflow;
 
	always @( posedge i_clk ) begin

		if(rst) begin
			reg_done  <= 1'b1;
			reg_sign  <= 1'b0;
			reg_overflow <= 1'b0;

			reg_working_quotient <= 0;
			reg_quotient <= 0;
			reg_working_dividend <= 0;
			reg_working_divisor <= 0;
			reg_count <= 0;
		end
		else begin
			if( reg_done && i_start ) begin										//	This is our startup condition
				//  Need to check for a divide by zero right here, I think....
				reg_done <= 1'b0;												//	We're not done			
				reg_count <= N+Q-1;											//	Set the count
				reg_working_quotient <= 0;									//	Clear out the quotient register
				reg_working_dividend <= 0;									//	Clear out the dividend register 
				reg_working_divisor <= 0;									//	Clear out the divisor register 
				reg_overflow <= 1'b0;										//	Clear the overflow register

				reg_working_dividend[N+Q-2:Q] <= i_dividend[N-2:0];				//	Left-align the dividend in its working register
				reg_working_divisor[2*N+Q-3:N+Q-1] <= i_divisor[N-2:0];		//	Left-align the divisor into its working register

				reg_sign <= i_dividend[N-1] ^ i_divisor[N-1];		//	Set the sign bit
				end 
			else if(!reg_done) begin
				reg_working_divisor <= reg_working_divisor >> 1;	//	Right shift the divisor (that is, divide it by two - aka reduce the divisor)
				reg_count <= reg_count - 1;								//	Decrement the count

				//	If the dividend is greater than the divisor
				if(reg_working_dividend >= reg_working_divisor) begin
					reg_working_quotient[reg_count] <= 1'b1;										//	Set the quotient bit
					reg_working_dividend <= reg_working_dividend - reg_working_divisor;	//		and subtract the divisor from the dividend
					end
	 
				//stop condition
				if(reg_count == 0) begin
					reg_done <= 1'b1;										//	If we're done, it's time to tell the calling process
					reg_quotient <= reg_working_quotient;			//	Move in our working copy to the outside world
					if (reg_working_quotient[2*N+Q-3:N]>0)
						reg_overflow <= 1'b1;
						end
				else
					reg_count <= reg_count - 1;	
				end
			end
		end
endmodule
