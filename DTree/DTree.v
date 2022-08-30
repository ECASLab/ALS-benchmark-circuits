`timescale 1ns / 1ps

module DTree(
	A1,
	A2,
	A3,
	A4,
	A5,
	A6,
	A7,
	A8,
	A9,
	A91,
	A92,
	A93,
	A94,
	A95,
	A96,
	A97,
	A98,
	A99,
	A991,
	A992,
	A993,
	A994,
	A995,
	A996,
	A997,
	A998,
	A999,
	A9991,
	A9992,
	A9993,
	decision
);


	input [9:0] A1;
	input [9:0] A2;
	input [9:0] A3;
	input [9:0] A4;
	input [9:0] A5;
	input [9:0] A6;
	input [9:0] A7;
	input [9:0] A8;
	input [9:0] A9;
	input [9:0] A91;
	input [9:0] A92;
	input [9:0] A93;
	input [9:0] A94;
	input [9:0] A95;
	input [9:0] A96;
	input [9:0] A97;
	input [9:0] A98;
	input [9:0] A99;
	input [9:0] A991;
	input [9:0] A992;
	input [9:0] A993;
	input [9:0] A994;
	input [9:0] A995;
	input [9:0] A996;
	input [9:0] A997;
	input [9:0] A998;
	input [9:0] A999;
	input [9:0] A9991;
	input [9:0] A9992;
	input [9:0] A9993;
	output [4:0] decision;

	wire [9:0] reg_A1;
	wire [9:0] reg_A2;
	wire [9:0] reg_A3;
	wire [9:0] reg_A4;
	wire [9:0] reg_A5;
	wire [9:0] reg_A6;
	wire [9:0] reg_A7;
	wire [9:0] reg_A8;
	wire [9:0] reg_A9;
	wire [9:0] reg_A91;
	wire [9:0] reg_A92;
	wire [9:0] reg_A93;
	wire [9:0] reg_A94;
	wire [9:0] reg_A95;
	wire [9:0] reg_A96;
	wire [9:0] reg_A97;
	wire [9:0] reg_A98;
	wire [9:0] reg_A99;
	wire [9:0] reg_A991;
	wire [9:0] reg_A992;
	wire [9:0] reg_A993;
	wire [9:0] reg_A994;
	wire [9:0] reg_A995;
	wire [9:0] reg_A996;
	wire [9:0] reg_A997;
	wire [9:0] reg_A998;
	wire [9:0] reg_A999;
	wire [9:0] reg_A9991;
	wire [9:0] reg_A9992;
	wire [9:0] reg_A9993;
	wire [4:0] reg_decision;

wire [0:0] comp_A1_853;
wire [0:0] comp_A2_238;
wire [0:0] comp_A3_57;
wire [0:0] comp_A4_306;
wire [0:0] comp_A5_697;
wire [0:0] comp_A6_9;
wire [0:0] comp_A7_660;
wire [0:0] comp_A4_314;
wire [0:0] comp_A6_777;
wire [0:0] comp_A8_865;
wire [0:0] comp_A9_741;
wire [0:0] comp_A91_52;
wire [0:0] comp_A91_27;
wire [0:0] comp_A92_164;
wire [0:0] comp_A93_973;
wire [0:0] comp_A6_859;
wire [0:0] comp_A91_284;
wire [0:0] comp_A94_293;
wire [0:0] comp_A91_104;
wire [0:0] comp_A95_271;
wire [0:0] comp_A96_325;
wire [0:0] comp_A97_288;
wire [0:0] comp_A91_79;
wire [0:0] comp_A6_827;
wire [0:0] comp_A98_335;
wire [0:0] comp_A91_812;
wire [0:0] comp_A99_63;
wire [0:0] comp_A91_842;
wire [0:0] comp_A94_301;
wire [0:0] comp_A91_306;
wire [0:0] comp_A1_827;
wire [0:0] comp_A93_938;
wire [0:0] comp_A91_103;
wire [0:0] comp_A98_782;
wire [0:0] comp_A991_729;
wire [0:0] comp_A97_606;
wire [0:0] comp_A992_414;
wire [0:0] comp_A993_573;
wire [0:0] comp_A2_809;
wire [0:0] comp_A1_146;
wire [0:0] comp_A994_648;
wire [0:0] comp_A993_605;
wire [0:0] comp_A6_898;
wire [0:0] comp_A995_96;
wire [0:0] comp_A996_502;
wire [0:0] comp_A1_805;
wire [0:0] comp_A997_640;
wire [0:0] comp_A7_347;
wire [0:0] comp_A97_580;
wire [0:0] comp_A1_151;
wire [0:0] comp_A998_280;
wire [0:0] comp_A91_515;
wire [0:0] comp_A992_413;
wire [0:0] comp_A999_400;
wire [0:0] comp_A996_981;
wire [0:0] comp_A9991_866;
wire [0:0] comp_A99_1019;
wire [0:0] comp_A93_688;
wire [0:0] comp_A9992_880;
wire [0:0] comp_A95_79;
wire [0:0] comp_A9993_534;
wire [0:0] comp_A98_374;
COMPS INST_COMP(
reg_A1, reg_A2, reg_A3, reg_A4, reg_A5, reg_A6, reg_A7, reg_A8, reg_A9, reg_A91, reg_A92, reg_A93, reg_A94, reg_A95, reg_A96, reg_A97, reg_A98, reg_A99, reg_A991, reg_A992, reg_A993, reg_A994, reg_A995, reg_A996, reg_A997, reg_A998, reg_A999, reg_A9991, reg_A9992, reg_A9993, comp_A1_853, comp_A2_238, comp_A3_57, comp_A4_306, comp_A5_697, comp_A6_9, comp_A7_660, comp_A4_314, comp_A6_777, comp_A8_865, comp_A9_741, comp_A91_52, comp_A91_27, comp_A92_164, comp_A93_973, comp_A6_859, comp_A91_284, comp_A94_293, comp_A91_104, comp_A95_271, comp_A96_325, comp_A97_288, comp_A91_79, comp_A6_827, comp_A98_335, comp_A91_812, comp_A99_63, comp_A91_842, comp_A94_301, comp_A91_306, comp_A1_827, comp_A93_938, comp_A91_103, comp_A98_782, comp_A991_729, comp_A97_606, comp_A992_414, comp_A993_573, comp_A2_809, comp_A1_146, comp_A994_648, comp_A993_605, comp_A6_898, comp_A995_96, comp_A996_502, comp_A1_805, comp_A997_640, comp_A7_347, comp_A97_580, comp_A1_151, comp_A998_280, comp_A91_515, comp_A992_413, comp_A999_400, comp_A996_981, comp_A9991_866, comp_A99_1019, comp_A93_688, comp_A9992_880, comp_A95_79, comp_A9993_534, comp_A98_374
);

ANDS INST_ANDS(
comp_A1_853, comp_A2_238, comp_A3_57, comp_A4_306, comp_A5_697, comp_A6_9, comp_A7_660, comp_A4_314, comp_A6_777, comp_A8_865, comp_A9_741, comp_A91_52, comp_A91_27, comp_A92_164, comp_A93_973, comp_A6_859, comp_A91_284, comp_A94_293, comp_A91_104, comp_A95_271, comp_A96_325, comp_A97_288, comp_A91_79, comp_A6_827, comp_A98_335, comp_A91_812, comp_A99_63, comp_A91_842, comp_A94_301, comp_A91_306, comp_A1_827, comp_A93_938, comp_A91_103, comp_A98_782, comp_A991_729, comp_A97_606, comp_A992_414, comp_A993_573, comp_A2_809, comp_A1_146, comp_A994_648, comp_A993_605, comp_A6_898, comp_A995_96, comp_A996_502, comp_A1_805, comp_A997_640, comp_A7_347, comp_A97_580, comp_A1_151, comp_A998_280, comp_A91_515, comp_A992_413, comp_A999_400, comp_A996_981, comp_A9991_866, comp_A99_1019, comp_A93_688, comp_A9992_880, comp_A95_79, comp_A9993_534, comp_A98_374, reg_decision
);


	assign reg_A1 = A1;

	assign reg_A2 = A2;

	assign reg_A3 = A3;

	assign reg_A4 = A4;

	assign reg_A5 = A5;

	assign reg_A6 = A6;

	assign reg_A7 = A7;

	assign reg_A8 = A8;

	assign reg_A9 = A9;

	assign reg_A91 = A91;

	assign reg_A92 = A92;

	assign reg_A93 = A93;

	assign reg_A94 = A94;

	assign reg_A95 = A95;

	assign reg_A96 = A96;

	assign reg_A97 = A97;

	assign reg_A98 = A98;

	assign reg_A99 = A99;

	assign reg_A991 = A991;

	assign reg_A992 = A992;

	assign reg_A993 = A993;

	assign reg_A994 = A994;

	assign reg_A995 = A995;

	assign reg_A996 = A996;

	assign reg_A997 = A997;

	assign reg_A998 = A998;

	assign reg_A999 = A999;

	assign reg_A9991 = A9991;

	assign reg_A9992 = A9992;

	assign reg_A9993 = A9993;

	assign decision = reg_decision;

endmodule


module COMPS(
reg_A1, reg_A2, reg_A3, reg_A4, reg_A5, reg_A6, reg_A7, reg_A8, reg_A9, reg_A91, reg_A92, reg_A93, reg_A94, reg_A95, reg_A96, reg_A97, reg_A98, reg_A99, reg_A991, reg_A992, reg_A993, reg_A994, reg_A995, reg_A996, reg_A997, reg_A998, reg_A999, reg_A9991, reg_A9992, reg_A9993, comp_A1_853, comp_A2_238, comp_A3_57, comp_A4_306, comp_A5_697, comp_A6_9, comp_A7_660, comp_A4_314, comp_A6_777, comp_A8_865, comp_A9_741, comp_A91_52, comp_A91_27, comp_A92_164, comp_A93_973, comp_A6_859, comp_A91_284, comp_A94_293, comp_A91_104, comp_A95_271, comp_A96_325, comp_A97_288, comp_A91_79, comp_A6_827, comp_A98_335, comp_A91_812, comp_A99_63, comp_A91_842, comp_A94_301, comp_A91_306, comp_A1_827, comp_A93_938, comp_A91_103, comp_A98_782, comp_A991_729, comp_A97_606, comp_A992_414, comp_A993_573, comp_A2_809, comp_A1_146, comp_A994_648, comp_A993_605, comp_A6_898, comp_A995_96, comp_A996_502, comp_A1_805, comp_A997_640, comp_A7_347, comp_A97_580, comp_A1_151, comp_A998_280, comp_A91_515, comp_A992_413, comp_A999_400, comp_A996_981, comp_A9991_866, comp_A99_1019, comp_A93_688, comp_A9992_880, comp_A95_79, comp_A9993_534, comp_A98_374
);

input [9:0] reg_A1;
input [9:0] reg_A2;
input [9:0] reg_A3;
input [9:0] reg_A4;
input [9:0] reg_A5;
input [9:0] reg_A6;
input [9:0] reg_A7;
input [9:0] reg_A8;
input [9:0] reg_A9;
input [9:0] reg_A91;
input [9:0] reg_A92;
input [9:0] reg_A93;
input [9:0] reg_A94;
input [9:0] reg_A95;
input [9:0] reg_A96;
input [9:0] reg_A97;
input [9:0] reg_A98;
input [9:0] reg_A99;
input [9:0] reg_A991;
input [9:0] reg_A992;
input [9:0] reg_A993;
input [9:0] reg_A994;
input [9:0] reg_A995;
input [9:0] reg_A996;
input [9:0] reg_A997;
input [9:0] reg_A998;
input [9:0] reg_A999;
input [9:0] reg_A9991;
input [9:0] reg_A9992;
input [9:0] reg_A9993;
output [0:0] comp_A1_853;
output [0:0] comp_A2_238;
output [0:0] comp_A3_57;
output [0:0] comp_A4_306;
output [0:0] comp_A5_697;
output [0:0] comp_A6_9;
output [0:0] comp_A7_660;
output [0:0] comp_A4_314;
output [0:0] comp_A6_777;
output [0:0] comp_A8_865;
output [0:0] comp_A9_741;
output [0:0] comp_A91_52;
output [0:0] comp_A91_27;
output [0:0] comp_A92_164;
output [0:0] comp_A93_973;
output [0:0] comp_A6_859;
output [0:0] comp_A91_284;
output [0:0] comp_A94_293;
output [0:0] comp_A91_104;
output [0:0] comp_A95_271;
output [0:0] comp_A96_325;
output [0:0] comp_A97_288;
output [0:0] comp_A91_79;
output [0:0] comp_A6_827;
output [0:0] comp_A98_335;
output [0:0] comp_A91_812;
output [0:0] comp_A99_63;
output [0:0] comp_A91_842;
output [0:0] comp_A94_301;
output [0:0] comp_A91_306;
output [0:0] comp_A1_827;
output [0:0] comp_A93_938;
output [0:0] comp_A91_103;
output [0:0] comp_A98_782;
output [0:0] comp_A991_729;
output [0:0] comp_A97_606;
output [0:0] comp_A992_414;
output [0:0] comp_A993_573;
output [0:0] comp_A2_809;
output [0:0] comp_A1_146;
output [0:0] comp_A994_648;
output [0:0] comp_A993_605;
output [0:0] comp_A6_898;
output [0:0] comp_A995_96;
output [0:0] comp_A996_502;
output [0:0] comp_A1_805;
output [0:0] comp_A997_640;
output [0:0] comp_A7_347;
output [0:0] comp_A97_580;
output [0:0] comp_A1_151;
output [0:0] comp_A998_280;
output [0:0] comp_A91_515;
output [0:0] comp_A992_413;
output [0:0] comp_A999_400;
output [0:0] comp_A996_981;
output [0:0] comp_A9991_866;
output [0:0] comp_A99_1019;
output [0:0] comp_A93_688;
output [0:0] comp_A9992_880;
output [0:0] comp_A95_79;
output [0:0] comp_A9993_534;
output [0:0] comp_A98_374;

wire [9:0] const_853_10;
assign const_853_10 = 10'b1101010101;
wire [9:0] const_238_10;
assign const_238_10 = 10'b0011101110;
wire [9:0] const_57_10;
assign const_57_10 = 10'b0000111001;
wire [9:0] const_306_10;
assign const_306_10 = 10'b0100110010;
wire [9:0] const_697_10;
assign const_697_10 = 10'b1010111001;
wire [9:0] const_9_10;
assign const_9_10 = 10'b0000001001;
wire [9:0] const_660_10;
assign const_660_10 = 10'b1010010100;
wire [9:0] const_314_10;
assign const_314_10 = 10'b0100111010;
wire [9:0] const_777_10;
assign const_777_10 = 10'b1100001001;
wire [9:0] const_865_10;
assign const_865_10 = 10'b1101100001;
wire [9:0] const_741_10;
assign const_741_10 = 10'b1011100101;
wire [9:0] const_52_10;
assign const_52_10 = 10'b0000110100;
wire [9:0] const_27_10;
assign const_27_10 = 10'b0000011011;
wire [9:0] const_164_10;
assign const_164_10 = 10'b0010100100;
wire [9:0] const_973_10;
assign const_973_10 = 10'b1111001101;
wire [9:0] const_859_10;
assign const_859_10 = 10'b1101011011;
wire [9:0] const_284_10;
assign const_284_10 = 10'b0100011100;
wire [9:0] const_293_10;
assign const_293_10 = 10'b0100100101;
wire [9:0] const_104_10;
assign const_104_10 = 10'b0001101000;
wire [9:0] const_271_10;
assign const_271_10 = 10'b0100001111;
wire [9:0] const_325_10;
assign const_325_10 = 10'b0101000101;
wire [9:0] const_288_10;
assign const_288_10 = 10'b0100100000;
wire [9:0] const_79_10;
assign const_79_10 = 10'b0001001111;
wire [9:0] const_827_10;
assign const_827_10 = 10'b1100111011;
wire [9:0] const_335_10;
assign const_335_10 = 10'b0101001111;
wire [9:0] const_812_10;
assign const_812_10 = 10'b1100101100;
wire [9:0] const_63_10;
assign const_63_10 = 10'b0000111111;
wire [9:0] const_842_10;
assign const_842_10 = 10'b1101001010;
wire [9:0] const_301_10;
assign const_301_10 = 10'b0100101101;
wire [9:0] const_938_10;
assign const_938_10 = 10'b1110101010;
wire [9:0] const_103_10;
assign const_103_10 = 10'b0001100111;
wire [9:0] const_782_10;
assign const_782_10 = 10'b1100001110;
wire [9:0] const_729_10;
assign const_729_10 = 10'b1011011001;
wire [9:0] const_606_10;
assign const_606_10 = 10'b1001011110;
wire [9:0] const_414_10;
assign const_414_10 = 10'b0110011110;
wire [9:0] const_573_10;
assign const_573_10 = 10'b1000111101;
wire [9:0] const_809_10;
assign const_809_10 = 10'b1100101001;
wire [9:0] const_146_10;
assign const_146_10 = 10'b0010010010;
wire [9:0] const_648_10;
assign const_648_10 = 10'b1010001000;
wire [9:0] const_605_10;
assign const_605_10 = 10'b1001011101;
wire [9:0] const_898_10;
assign const_898_10 = 10'b1110000010;
wire [9:0] const_96_10;
assign const_96_10 = 10'b0001100000;
wire [9:0] const_502_10;
assign const_502_10 = 10'b0111110110;
wire [9:0] const_805_10;
assign const_805_10 = 10'b1100100101;
wire [9:0] const_640_10;
assign const_640_10 = 10'b1010000000;
wire [9:0] const_347_10;
assign const_347_10 = 10'b0101011011;
wire [9:0] const_580_10;
assign const_580_10 = 10'b1001000100;
wire [9:0] const_151_10;
assign const_151_10 = 10'b0010010111;
wire [9:0] const_280_10;
assign const_280_10 = 10'b0100011000;
wire [9:0] const_515_10;
assign const_515_10 = 10'b1000000011;
wire [9:0] const_413_10;
assign const_413_10 = 10'b0110011101;
wire [9:0] const_400_10;
assign const_400_10 = 10'b0110010000;
wire [9:0] const_981_10;
assign const_981_10 = 10'b1111010101;
wire [9:0] const_866_10;
assign const_866_10 = 10'b1101100010;
wire [9:0] const_1019_10;
assign const_1019_10 = 10'b1111111011;
wire [9:0] const_688_10;
assign const_688_10 = 10'b1010110000;
wire [9:0] const_880_10;
assign const_880_10 = 10'b1101110000;
wire [9:0] const_534_10;
assign const_534_10 = 10'b1000010110;
wire [9:0] const_374_10;
assign const_374_10 = 10'b0101110110;

	assign comp_A1_853 = (reg_A1 <= const_853_10);
	assign comp_A2_238 = (reg_A2 <= const_238_10);
	assign comp_A3_57 = (reg_A3 <= const_57_10);
	assign comp_A4_306 = (reg_A4 <= const_306_10);
	assign comp_A5_697 = (reg_A5 <= const_697_10);
	assign comp_A6_9 = (reg_A6 <= const_9_10);
	assign comp_A7_660 = (reg_A7 <= const_660_10);
	assign comp_A4_314 = (reg_A4 <= const_314_10);
	assign comp_A6_777 = (reg_A6 <= const_777_10);
	assign comp_A8_865 = (reg_A8 <= const_865_10);
	assign comp_A9_741 = (reg_A9 <= const_741_10);
	assign comp_A91_52 = (reg_A91 <= const_52_10);
	assign comp_A91_27 = (reg_A91 <= const_27_10);
	assign comp_A92_164 = (reg_A92 <= const_164_10);
	assign comp_A93_973 = (reg_A93 <= const_973_10);
	assign comp_A6_859 = (reg_A6 <= const_859_10);
	assign comp_A91_284 = (reg_A91 <= const_284_10);
	assign comp_A94_293 = (reg_A94 <= const_293_10);
	assign comp_A91_104 = (reg_A91 <= const_104_10);
	assign comp_A95_271 = (reg_A95 <= const_271_10);
	assign comp_A96_325 = (reg_A96 <= const_325_10);
	assign comp_A97_288 = (reg_A97 <= const_288_10);
	assign comp_A91_79 = (reg_A91 <= const_79_10);
	assign comp_A6_827 = (reg_A6 <= const_827_10);
	assign comp_A98_335 = (reg_A98 <= const_335_10);
	assign comp_A91_812 = (reg_A91 <= const_812_10);
	assign comp_A99_63 = (reg_A99 <= const_63_10);
	assign comp_A91_842 = (reg_A91 <= const_842_10);
	assign comp_A94_301 = (reg_A94 <= const_301_10);
	assign comp_A91_306 = (reg_A91 <= const_306_10);
	assign comp_A1_827 = (reg_A1 <= const_827_10);
	assign comp_A93_938 = (reg_A93 <= const_938_10);
	assign comp_A91_103 = (reg_A91 <= const_103_10);
	assign comp_A98_782 = (reg_A98 <= const_782_10);
	assign comp_A991_729 = (reg_A991 <= const_729_10);
	assign comp_A97_606 = (reg_A97 <= const_606_10);
	assign comp_A992_414 = (reg_A992 <= const_414_10);
	assign comp_A993_573 = (reg_A993 <= const_573_10);
	assign comp_A2_809 = (reg_A2 <= const_809_10);
	assign comp_A1_146 = (reg_A1 <= const_146_10);
	assign comp_A994_648 = (reg_A994 <= const_648_10);
	assign comp_A993_605 = (reg_A993 <= const_605_10);
	assign comp_A6_898 = (reg_A6 <= const_898_10);
	assign comp_A995_96 = (reg_A995 <= const_96_10);
	assign comp_A996_502 = (reg_A996 <= const_502_10);
	assign comp_A1_805 = (reg_A1 <= const_805_10);
	assign comp_A997_640 = (reg_A997 <= const_640_10);
	assign comp_A7_347 = (reg_A7 <= const_347_10);
	assign comp_A97_580 = (reg_A97 <= const_580_10);
	assign comp_A1_151 = (reg_A1 <= const_151_10);
	assign comp_A998_280 = (reg_A998 <= const_280_10);
	assign comp_A91_515 = (reg_A91 <= const_515_10);
	assign comp_A992_413 = (reg_A992 <= const_413_10);
	assign comp_A999_400 = (reg_A999 <= const_400_10);
	assign comp_A996_981 = (reg_A996 <= const_981_10);
	assign comp_A9991_866 = (reg_A9991 <= const_866_10);
	assign comp_A99_1019 = (reg_A99 <= const_1019_10);
	assign comp_A93_688 = (reg_A93 <= const_688_10);
	assign comp_A9992_880 = (reg_A9992 <= const_880_10);
	assign comp_A95_79 = (reg_A95 <= const_79_10);
	assign comp_A9993_534 = (reg_A9993 <= const_534_10);
	assign comp_A98_374 = (reg_A98 <= const_374_10);
endmodule


module ANDS(
comp_A1_853, comp_A2_238, comp_A3_57, comp_A4_306, comp_A5_697, comp_A6_9, comp_A7_660, comp_A4_314, comp_A6_777, comp_A8_865, comp_A9_741, comp_A91_52, comp_A91_27, comp_A92_164, comp_A93_973, comp_A6_859, comp_A91_284, comp_A94_293, comp_A91_104, comp_A95_271, comp_A96_325, comp_A97_288, comp_A91_79, comp_A6_827, comp_A98_335, comp_A91_812, comp_A99_63, comp_A91_842, comp_A94_301, comp_A91_306, comp_A1_827, comp_A93_938, comp_A91_103, comp_A98_782, comp_A991_729, comp_A97_606, comp_A992_414, comp_A993_573, comp_A2_809, comp_A1_146, comp_A994_648, comp_A993_605, comp_A6_898, comp_A995_96, comp_A996_502, comp_A1_805, comp_A997_640, comp_A7_347, comp_A97_580, comp_A1_151, comp_A998_280, comp_A91_515, comp_A992_413, comp_A999_400, comp_A996_981, comp_A9991_866, comp_A99_1019, comp_A93_688, comp_A9992_880, comp_A95_79, comp_A9993_534, comp_A98_374, reg_decision
);

input [0:0] comp_A1_853;
input [0:0] comp_A2_238;
input [0:0] comp_A3_57;
input [0:0] comp_A4_306;
input [0:0] comp_A5_697;
input [0:0] comp_A6_9;
input [0:0] comp_A7_660;
input [0:0] comp_A4_314;
input [0:0] comp_A6_777;
input [0:0] comp_A8_865;
input [0:0] comp_A9_741;
input [0:0] comp_A91_52;
input [0:0] comp_A91_27;
input [0:0] comp_A92_164;
input [0:0] comp_A93_973;
input [0:0] comp_A6_859;
input [0:0] comp_A91_284;
input [0:0] comp_A94_293;
input [0:0] comp_A91_104;
input [0:0] comp_A95_271;
input [0:0] comp_A96_325;
input [0:0] comp_A97_288;
input [0:0] comp_A91_79;
input [0:0] comp_A6_827;
input [0:0] comp_A98_335;
input [0:0] comp_A91_812;
input [0:0] comp_A99_63;
input [0:0] comp_A91_842;
input [0:0] comp_A94_301;
input [0:0] comp_A91_306;
input [0:0] comp_A1_827;
input [0:0] comp_A93_938;
input [0:0] comp_A91_103;
input [0:0] comp_A98_782;
input [0:0] comp_A991_729;
input [0:0] comp_A97_606;
input [0:0] comp_A992_414;
input [0:0] comp_A993_573;
input [0:0] comp_A2_809;
input [0:0] comp_A1_146;
input [0:0] comp_A994_648;
input [0:0] comp_A993_605;
input [0:0] comp_A6_898;
input [0:0] comp_A995_96;
input [0:0] comp_A996_502;
input [0:0] comp_A1_805;
input [0:0] comp_A997_640;
input [0:0] comp_A7_347;
input [0:0] comp_A97_580;
input [0:0] comp_A1_151;
input [0:0] comp_A998_280;
input [0:0] comp_A91_515;
input [0:0] comp_A992_413;
input [0:0] comp_A999_400;
input [0:0] comp_A996_981;
input [0:0] comp_A9991_866;
input [0:0] comp_A99_1019;
input [0:0] comp_A93_688;
input [0:0] comp_A9992_880;
input [0:0] comp_A95_79;
input [0:0] comp_A9993_534;
input [0:0] comp_A98_374;
output [4:0] reg_decision;

wire [0:0] and_0;
wire [0:0] and_1;
wire [0:0] and_2;
wire [0:0] and_3;
wire [0:0] and_4;
wire [0:0] and_5;
wire [0:0] and_6;
wire [0:0] and_7;
wire [0:0] and_8;
wire [0:0] and_9;
wire [0:0] and_10;
wire [0:0] and_11;
wire [0:0] and_12;
wire [0:0] and_13;
wire [0:0] and_14;
wire [0:0] and_15;
wire [0:0] and_16;
wire [0:0] and_17;
wire [0:0] and_18;
wire [0:0] and_19;
wire [0:0] and_20;
wire [0:0] and_21;
wire [0:0] and_22;
wire [0:0] and_23;
wire [0:0] and_24;
wire [0:0] and_25;
wire [0:0] and_26;
wire [0:0] and_27;
wire [0:0] and_28;
wire [0:0] and_29;
wire [0:0] and_30;
wire [0:0] and_31;
wire [0:0] and_32;
wire [0:0] and_33;
wire [0:0] and_34;
wire [0:0] and_35;
wire [0:0] and_36;
wire [0:0] and_37;
wire [0:0] and_38;
wire [0:0] and_39;
wire [0:0] and_40;
wire [0:0] and_41;
wire [0:0] and_42;
wire [0:0] and_43;
wire [0:0] and_44;
wire [0:0] and_45;
wire [0:0] and_46;
wire [0:0] and_47;
wire [0:0] and_48;
wire [0:0] and_49;
wire [0:0] and_50;
wire [0:0] and_51;
wire [0:0] and_52;
wire [0:0] and_53;
wire [0:0] and_54;
wire [0:0] and_55;
wire [0:0] and_56;
wire [0:0] and_57;
wire [0:0] and_58;
wire [0:0] and_59;
wire [0:0] and_60;
wire [0:0] and_61;
wire [0:0] and_62;
wire [0:0] and_63;

assign and_0 = comp_A1_853 & comp_A2_238 & comp_A3_57 & ~(comp_A4_306) & ~(comp_A6_9) & ~(comp_A4_314) & ~(comp_A9_741);

assign and_1 = comp_A1_853 & comp_A2_238 & comp_A3_57 & comp_A4_306 & ~(comp_A5_697);

assign and_2 = comp_A1_853 & comp_A2_238 & comp_A3_57 & ~(comp_A4_306) & comp_A6_9 & comp_A7_660;

assign and_3 = comp_A1_853 & comp_A2_238 & comp_A3_57 & ~(comp_A4_306) & ~(comp_A6_9) & comp_A4_314 & comp_A6_777;

assign and_4 = comp_A1_853 & comp_A2_238 & comp_A3_57 & ~(comp_A4_306) & ~(comp_A6_9) & ~(comp_A4_314) & comp_A8_865;

assign and_5 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & comp_A94_293 & comp_A91_104 & comp_A95_271;

assign and_6 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & ~(comp_A94_293) & comp_A97_288 & comp_A91_79;

assign and_7 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & ~(comp_A94_293) & ~(comp_A97_288) & comp_A6_827;

assign and_8 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & comp_A98_335 & comp_A91_812 & ~(comp_A99_63);

assign and_9 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & comp_A98_335 & ~(comp_A91_812) & ~(comp_A91_842);

assign and_10 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & comp_A91_79 & comp_A93_938 & comp_A91_103;

assign and_11 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & comp_A93_938 & ~(comp_A91_103) & ~(comp_A98_782) & ~(comp_A97_606);

assign and_12 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & comp_A992_414 & comp_A993_573 & ~(comp_A2_809);

assign and_13 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & ~(comp_A1_151) & comp_A998_280 & comp_A91_515;

assign and_14 = ~(comp_A1_853) & ~(comp_A9991_866);

assign and_15 = ~(comp_A1_853) & ~(comp_A99_1019);

assign reg_decision[0] = and_0 | and_1 | and_2 | and_3 | and_4 | and_5 | and_6 | and_7 | and_8 | and_9 | and_10 | and_11 | and_12 | and_13 | and_14 | and_15;

assign and_16 = comp_A1_853 & comp_A2_238 & ~(comp_A3_57);

assign and_17 = comp_A1_853 & comp_A2_238 & comp_A4_306 & comp_A5_697;

assign and_18 = comp_A1_853 & comp_A2_238 & ~(comp_A4_306) & comp_A6_9 & ~(comp_A7_660);

assign and_19 = comp_A1_853 & comp_A2_238 & ~(comp_A4_306) & ~(comp_A6_9) & comp_A4_314 & ~(comp_A6_777);

assign and_20 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & comp_A94_293 & comp_A91_104 & ~(comp_A95_271);

assign and_21 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & ~(comp_A94_293) & ~(comp_A97_288) & ~(comp_A6_827);

assign and_22 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & comp_A98_335 & comp_A91_812 & comp_A99_63;

assign and_23 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & comp_A98_335 & ~(comp_A91_812) & comp_A91_842;

assign and_24 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & ~(comp_A98_335) & comp_A94_301 & comp_A91_306;

assign and_25 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A91_79) & comp_A93_938 & comp_A91_103;

assign and_26 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & comp_A992_414 & ~(comp_A993_573) & ~(comp_A1_146);

assign and_27 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & ~(comp_A992_414) & comp_A994_648 & ~(comp_A993_605);

assign and_28 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & comp_A995_96 & comp_A996_502;

assign and_29 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & comp_A995_96 & comp_A1_805 & comp_A997_640 & ~(comp_A7_347);

assign and_30 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & ~(comp_A1_151) & comp_A998_280 & ~(comp_A91_515) & ~(comp_A992_413);

assign and_31 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & ~(comp_A1_151) & ~(comp_A998_280) & ~(comp_A999_400) & comp_A996_981;

assign reg_decision[1] = and_16 | and_17 | and_18 | and_19 | and_20 | and_21 | and_22 | and_23 | and_24 | and_25 | and_26 | and_27 | and_28 | and_29 | and_30 | and_31;

assign and_32 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & ~(comp_A98_335) & comp_A94_301 & ~(comp_A91_306);

assign and_33 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & ~(comp_A98_335) & ~(comp_A94_301) & ~(comp_A1_827);

assign and_34 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & comp_A93_938 & ~(comp_A91_103) & comp_A98_782 & comp_A991_729;

assign and_35 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & ~(comp_A992_414) & ~(comp_A994_648) & comp_A6_898;

assign and_36 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & comp_A995_96 & ~(comp_A996_502) & comp_A1_805 & comp_A997_640 & comp_A7_347;

assign and_37 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & ~(comp_A1_151) & ~(comp_A998_280) & ~(comp_A999_400) & ~(comp_A996_981);

assign reg_decision[2] = and_32 | and_33 | and_34 | and_35 | and_36 | and_37;

assign and_38 = comp_A1_853 & ~(comp_A2_238) & comp_A91_52 & comp_A91_27 & comp_A92_164;

assign and_39 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & comp_A94_293 & ~(comp_A91_104) & comp_A96_325;

assign and_40 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & ~(comp_A94_293) & comp_A97_288 & ~(comp_A91_79);

assign and_41 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & ~(comp_A91_284) & ~(comp_A98_335) & ~(comp_A94_301) & comp_A1_827;

assign and_42 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & comp_A93_938 & ~(comp_A91_103) & comp_A98_782 & ~(comp_A991_729);

assign and_43 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & comp_A992_414 & comp_A993_573 & comp_A2_809;

assign and_44 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & comp_A992_414 & ~(comp_A993_573) & comp_A1_146;

assign and_45 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & ~(comp_A992_414) & comp_A994_648 & comp_A993_605;

assign and_46 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & comp_A995_96 & ~(comp_A996_502) & comp_A1_805 & ~(comp_A997_640) & comp_A97_580;

assign and_47 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & ~(comp_A1_151) & comp_A998_280 & ~(comp_A91_515) & comp_A992_413;

assign and_48 = ~(comp_A1_853) & comp_A9991_866 & comp_A99_1019 & comp_A93_688;

assign and_49 = ~(comp_A1_853) & comp_A9991_866 & comp_A99_1019 & comp_A9992_880 & comp_A95_79 & comp_A9993_534;

assign and_50 = ~(comp_A1_853) & comp_A9991_866 & comp_A99_1019 & ~(comp_A9992_880) & comp_A98_374;

assign reg_decision[3] = and_38 | and_39 | and_40 | and_41 | and_42 | and_43 | and_44 | and_45 | and_46 | and_47 | and_48 | and_49 | and_50;

assign and_51 = comp_A1_853 & comp_A2_238 & comp_A3_57 & ~(comp_A4_306) & ~(comp_A6_9) & ~(comp_A4_314) & ~(comp_A8_865) & comp_A9_741;

assign and_52 = comp_A1_853 & ~(comp_A2_238) & comp_A91_52 & ~(comp_A91_27);

assign and_53 = comp_A1_853 & ~(comp_A2_238) & comp_A91_52 & ~(comp_A92_164);

assign and_54 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & comp_A6_859 & comp_A91_284 & comp_A94_293 & ~(comp_A91_104) & ~(comp_A96_325);

assign and_55 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & comp_A93_938 & ~(comp_A91_103) & ~(comp_A98_782) & comp_A97_606;

assign and_56 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & comp_A93_973 & ~(comp_A6_859) & ~(comp_A93_938) & ~(comp_A992_414) & ~(comp_A994_648) & ~(comp_A6_898);

assign and_57 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & comp_A995_96 & ~(comp_A996_502) & ~(comp_A1_805);

assign and_58 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & comp_A995_96 & ~(comp_A996_502) & ~(comp_A997_640) & ~(comp_A97_580);

assign and_59 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & comp_A1_151;

assign and_60 = comp_A1_853 & ~(comp_A2_238) & ~(comp_A91_52) & ~(comp_A93_973) & ~(comp_A995_96) & ~(comp_A998_280) & comp_A999_400;

assign and_61 = ~(comp_A1_853) & comp_A9991_866 & comp_A99_1019 & ~(comp_A93_688) & comp_A9992_880 & ~(comp_A95_79);

assign and_62 = ~(comp_A1_853) & comp_A9991_866 & comp_A99_1019 & ~(comp_A93_688) & comp_A9992_880 & ~(comp_A9993_534);

assign and_63 = ~(comp_A1_853) & comp_A9991_866 & comp_A99_1019 & ~(comp_A93_688) & ~(comp_A9992_880) & ~(comp_A98_374);

assign reg_decision[4] = and_51 | and_52 | and_53 | and_54 | and_55 | and_56 | and_57 | and_58 | and_59 | and_60 | and_61 | and_62 | and_63;


endmodule
