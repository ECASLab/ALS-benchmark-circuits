
module sobel(p0, p1, p2, p3, p5, p6, p7, p8, p4, out);

	input  [8:0] p0,p1,p2,p3,p5,p6,p7,p8, p4;	//p4 not used

	output [7:0] out;					

	wire [8:0] p2_p0, p8_p6, p0_p6, p2_p8, p5_p3, p1_p7, center_rm, center_tm;
	wire [9:0] center_1, center_2, center_3, center_4, gx_temp, gy_temp;

	wire or_out, add_out_1, add_out_2, add_out_3, add_out_4;
	wire [10:0] gx , gy, gx_comp, gy_comp;
	wire [10:0] gx_2s_comp, gy_2s_comp;   
				 	
	wire [10:0] abs_gx,abs_gy;	
	wire [10:0] sum;

	//Horizontal Gradient
	sobel_add_nb #(9) S0 (.a(p2),.b(p0),.ans_out(p2_p0),.subtract(1'b1),.cout()); 		//9-bit Subtractor
	sobel_add_nb #(9) S1 (.a(p5),.b(p3),.ans_out(p5_p3),.subtract(1'b1),.cout()); 		//9-bit Subtractor
	assign center_1 = p5_p3 << 1;
	sobel_add_nb #(9) S2 (.a(p8),.b(p6),.ans_out(p8_p6),.subtract(1'b1),.cout()); 		//9-bit Subtractor
	sobel_add_nb #(9) S3 (.a(p2_p0),.b(p8_p6),.ans_out(center_rm),.subtract(1'b0),.cout(add_out_1)); 	//9-bit Adder
	assign center_2 = {add_out_1,center_rm};
	sobel_add_nb #(10) S4 (.a(center_1),.b(center_2),.ans_out(gx_temp),.subtract(1'b0),.cout(add_out_2)); 	//10-bit Adder
	assign gx = {add_out_2,gx_temp};


	//Vertical Gradient
	sobel_add_nb #(9) S5 (.a(p0),.b(p6),.ans_out(p0_p6),.subtract(1'b1),.cout()); 		//9-bit Subtractor
	sobel_add_nb #(9) S6 (.a(p1),.b(p7),.ans_out(p1_p7),.subtract(1'b1),.cout()); 		//9-bit Subtractor
	assign center_3 = p1_p7 << 1; 
	sobel_add_nb #(9) S7 (.a(p2),.b(p8),.ans_out(p2_p8),.subtract(1'b1),.cout()); 		//9-bit Subtractor
	sobel_add_nb #(9) S8 (.a(p2_p8),.b(p0_p6),.ans_out(center_tm),.subtract(1'b0),.cout(add_out_3));  	//9-bit Adder
	assign center_4 = {add_out_3,center_tm};
	sobel_add_nb #(10) S9 (.a(center_3),.b(center_4),.ans_out(gy_temp),.subtract(1'b0),.cout(add_out_4));  //10-bit Adder
	assign gy = {add_out_4,gy_temp};



	not_11b N0 (gx,gx_comp);
	not_11b N1 (gy,gy_comp);
	
	sobel_add_nb #(11) S10 (.a(11'b1), .b(gx_comp), .ans_out(gx_2s_comp), .subtract(1'b0), .cout());	//11-bit Adder
	sobel_add_nb #(11) S11 (.a(11'b1), .b(gy_comp), .ans_out(gy_2s_comp), .subtract(1'b0), .cout());	//11-bit Adder

	mux_11b M0 (gx, gx_2s_comp, gx[8], abs_gx);
	mux_11b M1 (gy, gy_2s_comp, gy[8], abs_gy);

	sobel_add_nb #(11) S12 (.a(abs_gx), .b(abs_gy), .ans_out(sum), .subtract(1'b0), .cout());	//11-bit Adder

	//or_4b O0 (sum[8], sum[9], sum[10], sum[11], or_out);
	mux_8b M2 (sum[7:0], 8'hff, sum[8], out); 

endmodule

module mux_11b (in0, in1, sel, out);
	
	input [10:0] in0, in1;
	input sel;
	output [10:0] out;

assign out = (sel) ? in1 : in0;

endmodule

module mux_8b (in0, in1, sel, out);
	
	input [7:0] in0, in1;
	input sel;
	output [7:0] out;

assign out = (sel) ? in1 : in0;

endmodule

module not_11b(in, out);

	input[10:0] in;
	output[10:0] out;

	assign out = ~(in);
endmodule

module exoor(in1,in2,out);
	input in1, in2;
	output out;

	assign out = in1 ^ in2;
endmodule

module fa(a, b, c_in, s, c_out);

	input a, b, c_in;
	output c_out, s;

	wire w0, w1, w2, w3;

	xor x0(w0, a, b);
	xor x1(s, w0, c_in);

	and u2(w1, a, b);
	and u3(w2, a, c_in);
	and u4(w3, b, c_in);

	or u5(c_out, w1, w2, w3);
endmodule
module sobel_add_nb #(parameter bitwidth = 8) (a,b,ans_out,cout,subtract); //parameter here
	
	input  [bitwidth-1:0] a;  
	input  [bitwidth-1:0] b;  
	input  subtract;  
	output cout;
	output [bitwidth-1:0] ans_out;
	wire [bitwidth-2:0] carry; 
	wire [bitwidth-1:0] bcomp;

	exoor X_0 (b[0],subtract,bcomp[0]);
	fa fa_0  (a[0],bcomp[0],subtract,ans_out[0],carry[0]);

	genvar i;

	generate
		for(i = 1; i < bitwidth-1; i = i + 1) begin:gen_fa
			exoor X_i (b[i],subtract,bcomp[i]);
			fa fa_i (a[i],bcomp[i],carry[i-1],ans_out[i],carry[i]);
		end
	endgenerate 

	exoor X_bitwidth (b[bitwidth-1],subtract,bcomp[bitwidth-1]);
	fa fa_bitwidth (a[bitwidth-1],bcomp[bitwidth-1],carry[bitwidth-2],ans_out[bitwidth-1],cout);

	
endmodule
