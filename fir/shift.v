module shift(A1, A2, A3, A4, A5, O1, O2, O3 , O4, O5);
	input [7:0] A1, A2, A3, A4, A5;
	output [7:0] O1, O2, O3, O4, O5;

	assign O1 = A1 >> 3'b101;
	assign O2 = A2 >> 3'b100;
	assign O3 = A3 >> 3'b011;
	assign O4 = A4 >> 3'b010;
	assign O5 = A5 >> 3'b001;
endmodule

