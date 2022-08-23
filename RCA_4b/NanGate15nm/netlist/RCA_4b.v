/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : R-2020.09-SP5-1
// Date      : Thu Aug 18 19:36:50 2022
/////////////////////////////////////////////////////////////


module RCA_4b ( in1, in2, cin, out );
  input [3:0] in1;
  input [3:0] in2;
  output [4:0] out;
  input cin;
  wire   n12, n13, n14, n15, n16, n17, n18, n19, n20, n21, n22;

  OAI22_X1 U17 ( .A1(n12), .A2(n13), .B1(n14), .B2(n15), .ZN(out[4]) );
  INV_X1 U18 ( .I(in2[3]), .ZN(n12) );
  XOR2_X1 U19 ( .A1(n15), .A2(n14), .Z(out[3]) );
  AOI22_X1 U20 ( .A1(in2[2]), .A2(in1[2]), .B1(n16), .B2(n17), .ZN(n14) );
  XOR2_X1 U21 ( .A1(n13), .A2(in2[3]), .Z(n15) );
  INV_X1 U22 ( .I(in1[3]), .ZN(n13) );
  XOR2_X1 U23 ( .A1(n16), .A2(n17), .Z(out[2]) );
  XOR2_X1 U24 ( .A1(in1[2]), .A2(in2[2]), .Z(n17) );
  INV_X1 U25 ( .I(n18), .ZN(n16) );
  AOI22_X1 U26 ( .A1(in2[1]), .A2(in1[1]), .B1(n19), .B2(n20), .ZN(n18) );
  XOR2_X1 U27 ( .A1(n20), .A2(n19), .Z(out[1]) );
  INV_X1 U28 ( .I(n21), .ZN(n19) );
  AOI22_X1 U29 ( .A1(in2[0]), .A2(in1[0]), .B1(n22), .B2(cin), .ZN(n21) );
  XOR2_X1 U30 ( .A1(in1[1]), .A2(in2[1]), .Z(n20) );
  XOR2_X1 U31 ( .A1(cin), .A2(n22), .Z(out[0]) );
  XOR2_X1 U32 ( .A1(in1[0]), .A2(in2[0]), .Z(n22) );
endmodule

