/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : R-2020.09-SP5-1
// Date      : Fri Aug 12 12:45:59 2022
/////////////////////////////////////////////////////////////


module fir_DW01_add_0 ( A, B, CI, SUM, CO );
  input [8:0] A;
  input [8:0] B;
  output [8:0] SUM;
  input CI;
  output CO;

  wire   [8:1] carry;

  FA_X1 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  FA_X1 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  FA_X1 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  FA_X1 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  FA_X1 U1_2 ( .A(A[2]), .B(B[2]), .CI(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  FA_X1 U1_1 ( .A(A[1]), .B(B[1]), .CI(carry[1]), .CO(carry[2]), .S(SUM[1]) );
  AND2_X1 U1 ( .A1(carry[7]), .A2(A[7]), .Z(SUM[8]) );
  AND2_X1 U2 ( .A1(A[0]), .A2(B[0]), .Z(carry[1]) );
  XOR2_X1 U3 ( .A1(A[7]), .A2(carry[7]), .Z(SUM[7]) );
  XOR2_X1 U4 ( .A1(B[0]), .A2(A[0]), .Z(SUM[0]) );
endmodule


module fir ( clk, rst, x, dataout );
  input [7:0] x;
  output [9:0] dataout;
  input clk, rst;
  wire   d13_1_, u2_N10, u2_N9, u2_N8, u2_N7, u2_N6, u2_N5, u2_N4, u4_N10,
         u4_N9, u4_N8, u4_N7, u4_N6, u4_N5, u4_N4, u6_N10, u6_N9, u6_N8, u6_N7,
         u6_N6, u6_N5, u6_N4, u8_N10, u8_N9, u8_N8, u8_N7, u8_N6, u8_N5, u8_N4,
         d3_7_, d3_6_, d3_5_, d3_4_, d3_3_, d3_2_, d3_1_, d3_0_, d2_4_, d2_3_,
         d2_2_, d2_1_, d2_0_, d1_6_, d1_5_, d1_4_, d1_3_, d1_2_, d1_1_, d1_0_,
         add_0_root_add_0_root_add_23_carry_1_,
         add_0_root_add_0_root_add_23_carry_2_,
         add_0_root_add_0_root_add_23_carry_3_,
         add_0_root_add_0_root_add_23_carry_4_,
         add_0_root_add_0_root_add_23_carry_5_,
         add_0_root_add_0_root_add_23_carry_6_, n38;
  wire   [3:1] d11;
  wire   [3:0] m2;
  wire   [2:1] d12;
  wire   [4:0] m3;
  wire   [5:0] m4;
  wire   [6:0] m5;
  wire   [3:1] add_2_root_add_0_root_add_23_carry;
  wire   [5:1] add_1_root_add_0_root_add_23_carry;
  assign dataout[9] = 1'b0;

  DFFSNQ_X1 u2_q_reg_1_ ( .D(u2_N4), .CLK(clk), .SN(1'b1), .Q(d11[1]) );
  DFFSNQ_X1 u2_q_reg_2_ ( .D(u2_N5), .CLK(clk), .SN(1'b1), .Q(d11[2]) );
  DFFSNQ_X1 u2_q_reg_3_ ( .D(u2_N6), .CLK(clk), .SN(1'b1), .Q(d11[3]) );
  DFFSNQ_X1 u2_q_reg_4_ ( .D(u2_N7), .CLK(clk), .SN(1'b1), .Q(m2[0]) );
  DFFSNQ_X1 u2_q_reg_5_ ( .D(u2_N8), .CLK(clk), .SN(1'b1), .Q(m2[1]) );
  DFFSNQ_X1 u2_q_reg_6_ ( .D(u2_N9), .CLK(clk), .SN(1'b1), .Q(m2[2]) );
  DFFSNQ_X1 u2_q_reg_7_ ( .D(u2_N10), .CLK(clk), .SN(1'b1), .Q(m2[3]) );
  DFFSNQ_X1 u4_q_reg_1_ ( .D(u4_N4), .CLK(clk), .SN(1'b1), .Q(d12[1]) );
  DFFSNQ_X1 u4_q_reg_2_ ( .D(u4_N5), .CLK(clk), .SN(1'b1), .Q(d12[2]) );
  DFFSNQ_X1 u4_q_reg_3_ ( .D(u4_N6), .CLK(clk), .SN(1'b1), .Q(m3[0]) );
  DFFSNQ_X1 u4_q_reg_4_ ( .D(u4_N7), .CLK(clk), .SN(1'b1), .Q(m3[1]) );
  DFFSNQ_X1 u4_q_reg_5_ ( .D(u4_N8), .CLK(clk), .SN(1'b1), .Q(m3[2]) );
  DFFSNQ_X1 u4_q_reg_6_ ( .D(u4_N9), .CLK(clk), .SN(1'b1), .Q(m3[3]) );
  DFFSNQ_X1 u4_q_reg_7_ ( .D(u4_N10), .CLK(clk), .SN(1'b1), .Q(m3[4]) );
  DFFSNQ_X1 u6_q_reg_1_ ( .D(u6_N4), .CLK(clk), .SN(1'b1), .Q(d13_1_) );
  DFFSNQ_X1 u6_q_reg_2_ ( .D(u6_N5), .CLK(clk), .SN(1'b1), .Q(m4[0]) );
  DFFSNQ_X1 u6_q_reg_3_ ( .D(u6_N6), .CLK(clk), .SN(1'b1), .Q(m4[1]) );
  DFFSNQ_X1 u6_q_reg_4_ ( .D(u6_N7), .CLK(clk), .SN(1'b1), .Q(m4[2]) );
  DFFSNQ_X1 u6_q_reg_5_ ( .D(u6_N8), .CLK(clk), .SN(1'b1), .Q(m4[3]) );
  DFFSNQ_X1 u6_q_reg_6_ ( .D(u6_N9), .CLK(clk), .SN(1'b1), .Q(m4[4]) );
  DFFSNQ_X1 u6_q_reg_7_ ( .D(u6_N10), .CLK(clk), .SN(1'b1), .Q(m4[5]) );
  DFFSNQ_X1 u8_q_reg_1_ ( .D(u8_N4), .CLK(clk), .SN(1'b1), .Q(m5[0]) );
  DFFSNQ_X1 u8_q_reg_2_ ( .D(u8_N5), .CLK(clk), .SN(1'b1), .Q(m5[1]) );
  DFFSNQ_X1 u8_q_reg_3_ ( .D(u8_N6), .CLK(clk), .SN(1'b1), .Q(m5[2]) );
  DFFSNQ_X1 u8_q_reg_4_ ( .D(u8_N7), .CLK(clk), .SN(1'b1), .Q(m5[3]) );
  DFFSNQ_X1 u8_q_reg_5_ ( .D(u8_N8), .CLK(clk), .SN(1'b1), .Q(m5[4]) );
  DFFSNQ_X1 u8_q_reg_6_ ( .D(u8_N9), .CLK(clk), .SN(1'b1), .Q(m5[5]) );
  DFFSNQ_X1 u8_q_reg_7_ ( .D(u8_N10), .CLK(clk), .SN(1'b1), .Q(m5[6]) );
  AND2_X1 U31 ( .A1(m4[4]), .A2(n38), .Z(u8_N9) );
  AND2_X1 U32 ( .A1(m4[3]), .A2(n38), .Z(u8_N8) );
  AND2_X1 U33 ( .A1(m4[2]), .A2(n38), .Z(u8_N7) );
  AND2_X1 U34 ( .A1(m4[1]), .A2(n38), .Z(u8_N6) );
  AND2_X1 U35 ( .A1(m4[0]), .A2(n38), .Z(u8_N5) );
  AND2_X1 U36 ( .A1(d13_1_), .A2(n38), .Z(u8_N4) );
  AND2_X1 U37 ( .A1(m4[5]), .A2(n38), .Z(u8_N10) );
  AND2_X1 U38 ( .A1(m3[3]), .A2(n38), .Z(u6_N9) );
  AND2_X1 U39 ( .A1(m3[2]), .A2(n38), .Z(u6_N8) );
  AND2_X1 U40 ( .A1(m3[1]), .A2(n38), .Z(u6_N7) );
  AND2_X1 U41 ( .A1(m3[0]), .A2(n38), .Z(u6_N6) );
  AND2_X1 U42 ( .A1(d12[2]), .A2(n38), .Z(u6_N5) );
  AND2_X1 U43 ( .A1(d12[1]), .A2(n38), .Z(u6_N4) );
  AND2_X1 U44 ( .A1(m3[4]), .A2(n38), .Z(u6_N10) );
  AND2_X1 U45 ( .A1(m2[2]), .A2(n38), .Z(u4_N9) );
  AND2_X1 U46 ( .A1(m2[1]), .A2(n38), .Z(u4_N8) );
  AND2_X1 U47 ( .A1(m2[0]), .A2(n38), .Z(u4_N7) );
  AND2_X1 U48 ( .A1(d11[3]), .A2(n38), .Z(u4_N6) );
  AND2_X1 U49 ( .A1(d11[2]), .A2(n38), .Z(u4_N5) );
  AND2_X1 U50 ( .A1(d11[1]), .A2(n38), .Z(u4_N4) );
  AND2_X1 U51 ( .A1(m2[3]), .A2(n38), .Z(u4_N10) );
  AND2_X1 U52 ( .A1(x[6]), .A2(n38), .Z(u2_N9) );
  AND2_X1 U53 ( .A1(x[5]), .A2(n38), .Z(u2_N8) );
  AND2_X1 U54 ( .A1(x[4]), .A2(n38), .Z(u2_N7) );
  AND2_X1 U55 ( .A1(x[3]), .A2(n38), .Z(u2_N6) );
  AND2_X1 U56 ( .A1(x[2]), .A2(n38), .Z(u2_N5) );
  AND2_X1 U57 ( .A1(x[1]), .A2(n38), .Z(u2_N4) );
  AND2_X1 U58 ( .A1(x[7]), .A2(n38), .Z(u2_N10) );
  fir_DW01_add_0 add_32 ( .A({1'b0, d3_7_, d3_6_, d3_5_, d3_4_, d3_3_, d3_2_, 
        d3_1_, d3_0_}), .B({1'b0, 1'b0, m5}), .CI(1'b0), .SUM(dataout[8:0]) );
  FA_X1 add_0_root_add_0_root_add_23_U1_1 ( .A(d2_1_), .B(d1_1_), .CI(
        add_0_root_add_0_root_add_23_carry_1_), .CO(
        add_0_root_add_0_root_add_23_carry_2_), .S(d3_1_) );
  FA_X1 add_0_root_add_0_root_add_23_U1_2 ( .A(d2_2_), .B(d1_2_), .CI(
        add_0_root_add_0_root_add_23_carry_2_), .CO(
        add_0_root_add_0_root_add_23_carry_3_), .S(d3_2_) );
  FA_X1 add_0_root_add_0_root_add_23_U1_3 ( .A(d2_3_), .B(d1_3_), .CI(
        add_0_root_add_0_root_add_23_carry_3_), .CO(
        add_0_root_add_0_root_add_23_carry_4_), .S(d3_3_) );
  FA_X1 add_0_root_add_0_root_add_23_U1_4 ( .A(d2_4_), .B(d1_4_), .CI(
        add_0_root_add_0_root_add_23_carry_4_), .CO(
        add_0_root_add_0_root_add_23_carry_5_), .S(d3_4_) );
  FA_X1 add_2_root_add_0_root_add_23_U1_1 ( .A(x[6]), .B(m2[1]), .CI(
        add_2_root_add_0_root_add_23_carry[1]), .CO(
        add_2_root_add_0_root_add_23_carry[2]), .S(d2_1_) );
  FA_X1 add_2_root_add_0_root_add_23_U1_2 ( .A(x[7]), .B(m2[2]), .CI(
        add_2_root_add_0_root_add_23_carry[2]), .CO(
        add_2_root_add_0_root_add_23_carry[3]), .S(d2_2_) );
  FA_X1 add_1_root_add_0_root_add_23_U1_1 ( .A(m3[1]), .B(m4[1]), .CI(
        add_1_root_add_0_root_add_23_carry[1]), .CO(
        add_1_root_add_0_root_add_23_carry[2]), .S(d1_1_) );
  FA_X1 add_1_root_add_0_root_add_23_U1_2 ( .A(m3[2]), .B(m4[2]), .CI(
        add_1_root_add_0_root_add_23_carry[2]), .CO(
        add_1_root_add_0_root_add_23_carry[3]), .S(d1_2_) );
  FA_X1 add_1_root_add_0_root_add_23_U1_3 ( .A(m3[3]), .B(m4[3]), .CI(
        add_1_root_add_0_root_add_23_carry[3]), .CO(
        add_1_root_add_0_root_add_23_carry[4]), .S(d1_3_) );
  FA_X1 add_1_root_add_0_root_add_23_U1_4 ( .A(m3[4]), .B(m4[4]), .CI(
        add_1_root_add_0_root_add_23_carry[4]), .CO(
        add_1_root_add_0_root_add_23_carry[5]), .S(d1_4_) );
  INV_X1 U59 ( .I(rst), .ZN(n38) );
  AND2_X1 U60 ( .A1(add_0_root_add_0_root_add_23_carry_6_), .A2(d1_6_), .Z(
        d3_7_) );
  XOR2_X1 U61 ( .A1(d1_6_), .A2(add_0_root_add_0_root_add_23_carry_6_), .Z(
        d3_6_) );
  AND2_X1 U62 ( .A1(d1_5_), .A2(add_0_root_add_0_root_add_23_carry_5_), .Z(
        add_0_root_add_0_root_add_23_carry_6_) );
  XOR2_X1 U63 ( .A1(d1_5_), .A2(add_0_root_add_0_root_add_23_carry_5_), .Z(
        d3_5_) );
  AND2_X1 U64 ( .A1(d1_0_), .A2(d2_0_), .Z(
        add_0_root_add_0_root_add_23_carry_1_) );
  XOR2_X1 U65 ( .A1(d1_0_), .A2(d2_0_), .Z(d3_0_) );
  AND2_X1 U66 ( .A1(add_2_root_add_0_root_add_23_carry[3]), .A2(m2[3]), .Z(
        d2_4_) );
  XOR2_X1 U67 ( .A1(m2[3]), .A2(add_2_root_add_0_root_add_23_carry[3]), .Z(
        d2_3_) );
  AND2_X1 U68 ( .A1(m2[0]), .A2(x[5]), .Z(
        add_2_root_add_0_root_add_23_carry[1]) );
  XOR2_X1 U69 ( .A1(m2[0]), .A2(x[5]), .Z(d2_0_) );
  AND2_X1 U70 ( .A1(add_1_root_add_0_root_add_23_carry[5]), .A2(m4[5]), .Z(
        d1_6_) );
  XOR2_X1 U71 ( .A1(m4[5]), .A2(add_1_root_add_0_root_add_23_carry[5]), .Z(
        d1_5_) );
  AND2_X1 U72 ( .A1(m4[0]), .A2(m3[0]), .Z(
        add_1_root_add_0_root_add_23_carry[1]) );
  XOR2_X1 U73 ( .A1(m4[0]), .A2(m3[0]), .Z(d1_0_) );
endmodule

