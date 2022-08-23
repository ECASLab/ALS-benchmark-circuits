/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : R-2020.09-SP5-1
// Date      : Thu Aug 18 19:33:49 2022
/////////////////////////////////////////////////////////////


module CSkipA_16b ( a, b, sum );
  input [15:0] a;
  input [15:0] b;
  output [16:0] sum;
  wire   n47, n48, n49, n50, n51, n52, n53, n54, n55, n56, n57, n58, n59, n60,
         n61, n62, n63, n64, n65, n66, n67, n68, n69, n70, n71, n72, n73, n74,
         n75, n76, n77, n78, n79, n80, n81, n82, n83, n84, n85, n86, n87, n88,
         n89, n90, n91;

  XNOR2_X1 U65 ( .A1(n47), .A2(n48), .ZN(sum[9]) );
  XNOR2_X1 U66 ( .A1(n49), .A2(n50), .ZN(sum[8]) );
  XNOR2_X1 U67 ( .A1(n51), .A2(n52), .ZN(sum[7]) );
  XNOR2_X1 U68 ( .A1(n53), .A2(n54), .ZN(sum[6]) );
  XNOR2_X1 U69 ( .A1(n55), .A2(n56), .ZN(sum[5]) );
  XNOR2_X1 U70 ( .A1(n57), .A2(n58), .ZN(sum[4]) );
  XNOR2_X1 U71 ( .A1(n59), .A2(n60), .ZN(sum[3]) );
  XNOR2_X1 U72 ( .A1(n61), .A2(n62), .ZN(sum[2]) );
  XOR2_X1 U73 ( .A1(n63), .A2(n64), .Z(sum[1]) );
  INV_X1 U74 ( .I(n65), .ZN(sum[16]) );
  AOI22_X1 U75 ( .A1(b[15]), .A2(a[15]), .B1(n66), .B2(n67), .ZN(n65) );
  INV_X1 U76 ( .I(n68), .ZN(n66) );
  XNOR2_X1 U77 ( .A1(n68), .A2(n67), .ZN(sum[15]) );
  XOR2_X1 U78 ( .A1(a[15]), .A2(b[15]), .Z(n67) );
  AOI22_X1 U79 ( .A1(b[14]), .A2(a[14]), .B1(n69), .B2(n70), .ZN(n68) );
  INV_X1 U80 ( .I(n71), .ZN(n69) );
  XNOR2_X1 U81 ( .A1(n70), .A2(n71), .ZN(sum[14]) );
  AOI22_X1 U82 ( .A1(b[13]), .A2(a[13]), .B1(n72), .B2(n73), .ZN(n71) );
  INV_X1 U83 ( .I(n74), .ZN(n72) );
  XOR2_X1 U84 ( .A1(a[14]), .A2(b[14]), .Z(n70) );
  XNOR2_X1 U85 ( .A1(n74), .A2(n73), .ZN(sum[13]) );
  XOR2_X1 U86 ( .A1(a[13]), .A2(b[13]), .Z(n73) );
  AOI22_X1 U87 ( .A1(b[12]), .A2(a[12]), .B1(n75), .B2(n76), .ZN(n74) );
  INV_X1 U88 ( .I(n77), .ZN(n75) );
  XNOR2_X1 U89 ( .A1(n76), .A2(n77), .ZN(sum[12]) );
  AOI22_X1 U90 ( .A1(b[11]), .A2(a[11]), .B1(n78), .B2(n79), .ZN(n77) );
  INV_X1 U91 ( .I(n80), .ZN(n78) );
  XOR2_X1 U92 ( .A1(a[12]), .A2(b[12]), .Z(n76) );
  XNOR2_X1 U93 ( .A1(n80), .A2(n79), .ZN(sum[11]) );
  XOR2_X1 U94 ( .A1(a[11]), .A2(b[11]), .Z(n79) );
  AOI22_X1 U95 ( .A1(b[10]), .A2(a[10]), .B1(n81), .B2(n82), .ZN(n80) );
  INV_X1 U96 ( .I(n83), .ZN(n81) );
  XNOR2_X1 U97 ( .A1(n82), .A2(n83), .ZN(sum[10]) );
  AOI22_X1 U98 ( .A1(b[9]), .A2(a[9]), .B1(n84), .B2(n48), .ZN(n83) );
  XOR2_X1 U99 ( .A1(a[9]), .A2(b[9]), .Z(n48) );
  INV_X1 U100 ( .I(n47), .ZN(n84) );
  AOI22_X1 U101 ( .A1(b[8]), .A2(a[8]), .B1(n85), .B2(n49), .ZN(n47) );
  XOR2_X1 U102 ( .A1(a[8]), .A2(b[8]), .Z(n49) );
  INV_X1 U103 ( .I(n50), .ZN(n85) );
  AOI22_X1 U104 ( .A1(b[7]), .A2(a[7]), .B1(n86), .B2(n52), .ZN(n50) );
  XOR2_X1 U105 ( .A1(a[7]), .A2(b[7]), .Z(n52) );
  INV_X1 U106 ( .I(n51), .ZN(n86) );
  AOI22_X1 U107 ( .A1(b[6]), .A2(a[6]), .B1(n87), .B2(n53), .ZN(n51) );
  XOR2_X1 U108 ( .A1(a[6]), .A2(b[6]), .Z(n53) );
  INV_X1 U109 ( .I(n54), .ZN(n87) );
  AOI22_X1 U110 ( .A1(b[5]), .A2(a[5]), .B1(n88), .B2(n56), .ZN(n54) );
  XOR2_X1 U111 ( .A1(a[5]), .A2(b[5]), .Z(n56) );
  INV_X1 U112 ( .I(n55), .ZN(n88) );
  AOI22_X1 U113 ( .A1(b[4]), .A2(a[4]), .B1(n89), .B2(n57), .ZN(n55) );
  XOR2_X1 U114 ( .A1(a[4]), .A2(b[4]), .Z(n57) );
  INV_X1 U115 ( .I(n58), .ZN(n89) );
  AOI22_X1 U116 ( .A1(b[3]), .A2(a[3]), .B1(n90), .B2(n60), .ZN(n58) );
  XOR2_X1 U117 ( .A1(a[3]), .A2(b[3]), .Z(n60) );
  INV_X1 U118 ( .I(n59), .ZN(n90) );
  AOI22_X1 U119 ( .A1(b[2]), .A2(a[2]), .B1(n91), .B2(n61), .ZN(n59) );
  XOR2_X1 U120 ( .A1(a[2]), .A2(b[2]), .Z(n61) );
  INV_X1 U121 ( .I(n62), .ZN(n91) );
  AOI22_X1 U122 ( .A1(n64), .A2(n63), .B1(a[1]), .B2(b[1]), .ZN(n62) );
  AND2_X1 U123 ( .A1(b[0]), .A2(a[0]), .Z(n63) );
  XOR2_X1 U124 ( .A1(a[1]), .A2(b[1]), .Z(n64) );
  XOR2_X1 U125 ( .A1(a[10]), .A2(b[10]), .Z(n82) );
  XOR2_X1 U126 ( .A1(b[0]), .A2(a[0]), .Z(sum[0]) );
endmodule

