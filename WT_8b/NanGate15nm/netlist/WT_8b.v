/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : R-2020.09-SP5-1
// Date      : Thu Aug 18 19:38:24 2022
/////////////////////////////////////////////////////////////


module WT_8b ( A, B, S );
  input [7:0] A;
  input [7:0] B;
  output [15:0] S;
  wire   n300, n301, n302, n303, n304, n305, n306, n307, n308, n309, n310,
         n311, n312, n313, n314, n315, n316, n317, n318, n319, n320, n321,
         n322, n323, n324, n325, n326, n327, n328, n329, n330, n331, n332,
         n333, n334, n335, n336, n337, n338, n339, n340, n341, n342, n343,
         n344, n345, n346, n347, n348, n349, n350, n351, n352, n353, n354,
         n355, n356, n357, n358, n359, n360, n361, n362, n363, n364, n365,
         n366, n367, n368, n369, n370, n371, n372, n373, n374, n375, n376,
         n377, n378, n379, n380, n381, n382, n383, n384, n385, n386, n387,
         n388, n389, n390, n391, n392, n393, n394, n395, n396, n397, n398,
         n399, n400, n401, n402, n403, n404, n405, n406, n407, n408, n409,
         n410, n411, n412, n413, n414, n415, n416, n417, n418, n419, n420,
         n421, n422, n423, n424, n425, n426, n427, n428, n429, n430, n431,
         n432, n433, n434, n435, n436, n437, n438, n439, n440, n441, n442,
         n443, n444, n445, n446, n447, n448, n449, n450, n451, n452, n453,
         n454, n455, n456, n457, n458, n459, n460, n461, n462, n463, n464,
         n465, n466, n467, n468, n469, n470, n471, n472, n473, n474, n475,
         n476, n477, n478, n479, n480, n481, n482, n483, n484, n485, n486,
         n487, n488, n489, n490, n491, n492, n493, n494, n495, n496, n497,
         n498, n499, n500, n501, n502, n503, n504, n505, n506, n507, n508,
         n509, n510, n511, n512, n513, n514, n515, n516, n517, n518, n519,
         n520, n521, n522, n523, n524, n525, n526, n527, n528, n529, n530,
         n531, n532, n533, n534, n535, n536, n537, n538, n539, n540, n541,
         n542, n543, n544, n545, n546, n547, n548, n549, n550, n551, n552,
         n553, n554, n555, n556, n557, n558, n559, n560, n561, n562, n563,
         n564, n565, n566, n567, n568, n569, n570, n571, n572, n573, n574,
         n575, n576, n577, n578, n579, n580, n581, n582, n583, n584, n585,
         n586, n587, n588, n589, n590, n591, n592, n593, n594, n595, n596,
         n597;

  XOR2_X1 U316 ( .A1(n300), .A2(n301), .Z(S[9]) );
  XOR2_X1 U317 ( .A1(n302), .A2(n303), .Z(S[8]) );
  XOR2_X1 U318 ( .A1(n304), .A2(n305), .Z(S[7]) );
  XNOR2_X1 U319 ( .A1(n306), .A2(n307), .ZN(S[6]) );
  XOR2_X1 U320 ( .A1(n308), .A2(n309), .Z(S[5]) );
  NOR2_X1 U321 ( .A1(n310), .A2(n311), .ZN(n309) );
  XNOR2_X1 U322 ( .A1(n312), .A2(n311), .ZN(S[4]) );
  XOR2_X1 U323 ( .A1(n313), .A2(n314), .Z(S[3]) );
  XOR2_X1 U324 ( .A1(n315), .A2(n316), .Z(S[2]) );
  XOR2_X1 U325 ( .A1(n317), .A2(n318), .Z(S[1]) );
  NAND2_X1 U326 ( .A1(A[0]), .A2(B[1]), .ZN(n318) );
  NAND2_X1 U327 ( .A1(A[1]), .A2(B[0]), .ZN(n317) );
  NAND4_X1 U328 ( .A1(n319), .A2(n320), .A3(n321), .A4(n322), .ZN(S[15]) );
  AOI22_X1 U329 ( .A1(n323), .A2(n324), .B1(n325), .B2(n326), .ZN(n322) );
  NAND2_X1 U330 ( .A1(n327), .A2(n328), .ZN(n321) );
  XOR2_X1 U331 ( .A1(n328), .A2(n327), .Z(S[14]) );
  NOR2_X1 U332 ( .A1(n329), .A2(n330), .ZN(n327) );
  XOR2_X1 U333 ( .A1(n324), .A2(n323), .Z(n328) );
  XOR2_X1 U334 ( .A1(n325), .A2(n326), .Z(n323) );
  NOR2_X1 U335 ( .A1(n331), .A2(n332), .ZN(n326) );
  AND2_X1 U336 ( .A1(n320), .A2(n333), .Z(n325) );
  OAI21_X1 U337 ( .A1(n334), .A2(n335), .B(n336), .ZN(n333) );
  OR3_X1 U338 ( .A1(n335), .A2(n334), .A3(n336), .Z(n320) );
  NAND3_X1 U339 ( .A1(B[7]), .A2(n319), .A3(A[7]), .ZN(n336) );
  NAND3_X1 U340 ( .A1(A[7]), .A2(B[7]), .A3(n337), .ZN(n319) );
  OAI21_X1 U341 ( .A1(n338), .A2(n339), .B(n340), .ZN(n324) );
  XOR2_X1 U342 ( .A1(n329), .A2(n330), .Z(S[13]) );
  XNOR2_X1 U343 ( .A1(n339), .A2(n338), .ZN(n330) );
  AOI22_X1 U344 ( .A1(n341), .A2(n342), .B1(n343), .B2(n344), .ZN(n338) );
  OAI21_X1 U345 ( .A1(n345), .A2(n346), .B(n340), .ZN(n339) );
  NAND3_X1 U346 ( .A1(n347), .A2(n348), .A3(n346), .ZN(n340) );
  XOR2_X1 U347 ( .A1(n331), .A2(n332), .Z(n346) );
  XNOR2_X1 U348 ( .A1(n334), .A2(n335), .ZN(n332) );
  XOR2_X1 U349 ( .A1(n349), .A2(n350), .Z(n335) );
  NOR2_X1 U350 ( .A1(n351), .A2(n352), .ZN(n350) );
  INV_X1 U351 ( .I(n353), .ZN(n334) );
  OAI22_X1 U352 ( .A1(n349), .A2(n354), .B1(n352), .B2(n355), .ZN(n353) );
  NAND2_X1 U353 ( .A1(A[5]), .A2(n356), .ZN(n355) );
  NAND2_X1 U354 ( .A1(A[7]), .A2(B[6]), .ZN(n349) );
  NAND2_X1 U355 ( .A1(n357), .A2(n358), .ZN(n331) );
  AND2_X1 U356 ( .A1(n348), .A2(n347), .Z(n345) );
  NAND2_X1 U357 ( .A1(n359), .A2(n360), .ZN(n329) );
  XOR2_X1 U358 ( .A1(n359), .A2(n360), .Z(S[12]) );
  XOR2_X1 U359 ( .A1(n341), .A2(n342), .Z(n360) );
  XOR2_X1 U360 ( .A1(n343), .A2(n344), .Z(n342) );
  XOR2_X1 U361 ( .A1(n348), .A2(n347), .Z(n344) );
  XOR2_X1 U362 ( .A1(n358), .A2(n357), .Z(n347) );
  XNOR2_X1 U363 ( .A1(n361), .A2(n356), .ZN(n357) );
  XNOR2_X1 U364 ( .A1(n362), .A2(n337), .ZN(n356) );
  NOR2_X1 U365 ( .A1(n351), .A2(n363), .ZN(n337) );
  NAND2_X1 U366 ( .A1(B[7]), .A2(A[5]), .ZN(n361) );
  OAI21_X1 U367 ( .A1(n362), .A2(n364), .B(n365), .ZN(n358) );
  NAND2_X1 U368 ( .A1(A[7]), .A2(B[5]), .ZN(n362) );
  OAI22_X1 U369 ( .A1(n366), .A2(n367), .B1(n368), .B2(n369), .ZN(n348) );
  OAI21_X1 U370 ( .A1(n370), .A2(n371), .B(n372), .ZN(n343) );
  OAI22_X1 U371 ( .A1(n373), .A2(n374), .B1(n375), .B2(n376), .ZN(n341) );
  NOR3_X1 U372 ( .A1(n377), .A2(n378), .A3(n379), .ZN(n359) );
  XNOR2_X1 U373 ( .A1(n377), .A2(n380), .ZN(S[11]) );
  NOR2_X1 U374 ( .A1(n378), .A2(n379), .ZN(n380) );
  XNOR2_X1 U375 ( .A1(n376), .A2(n375), .ZN(n377) );
  AOI21_X1 U376 ( .A1(n381), .A2(n382), .B(n383), .ZN(n375) );
  INV_X1 U377 ( .I(n384), .ZN(n383) );
  XNOR2_X1 U378 ( .A1(n374), .A2(n373), .ZN(n376) );
  AOI22_X1 U379 ( .A1(n385), .A2(n386), .B1(n387), .B2(n388), .ZN(n373) );
  XNOR2_X1 U380 ( .A1(n371), .A2(n370), .ZN(n374) );
  XNOR2_X1 U381 ( .A1(n369), .A2(n368), .ZN(n370) );
  XNOR2_X1 U382 ( .A1(n367), .A2(n366), .ZN(n368) );
  INV_X1 U383 ( .I(n389), .ZN(n366) );
  OAI22_X1 U384 ( .A1(n390), .A2(n364), .B1(n391), .B2(n392), .ZN(n389) );
  NAND2_X1 U385 ( .A1(A[5]), .A2(n393), .ZN(n392) );
  OAI21_X1 U386 ( .A1(n394), .A2(n395), .B(n365), .ZN(n367) );
  NAND3_X1 U387 ( .A1(A[5]), .A2(n395), .A3(B[6]), .ZN(n365) );
  XNOR2_X1 U388 ( .A1(n354), .A2(n396), .ZN(n395) );
  NOR2_X1 U389 ( .A1(n397), .A2(n398), .ZN(n396) );
  NAND2_X1 U390 ( .A1(A[6]), .A2(B[5]), .ZN(n354) );
  NOR2_X1 U391 ( .A1(n399), .A2(n363), .ZN(n394) );
  NAND2_X1 U392 ( .A1(n400), .A2(n401), .ZN(n369) );
  OAI21_X1 U393 ( .A1(n400), .A2(n402), .B(n372), .ZN(n371) );
  NAND2_X1 U394 ( .A1(n400), .A2(n402), .ZN(n372) );
  OAI22_X1 U395 ( .A1(n403), .A2(n404), .B1(n405), .B2(n406), .ZN(n402) );
  NOR2_X1 U396 ( .A1(n352), .A2(n407), .ZN(n400) );
  XOR2_X1 U397 ( .A1(n379), .A2(n378), .Z(S[10]) );
  AOI22_X1 U398 ( .A1(n408), .A2(n409), .B1(n300), .B2(n301), .ZN(n378) );
  XOR2_X1 U399 ( .A1(n409), .A2(n408), .Z(n301) );
  OAI22_X1 U400 ( .A1(n303), .A2(n302), .B1(n410), .B2(n411), .ZN(n300) );
  NAND2_X1 U401 ( .A1(n305), .A2(n304), .ZN(n302) );
  OAI22_X1 U402 ( .A1(n412), .A2(n413), .B1(n414), .B2(n307), .ZN(n304) );
  XNOR2_X1 U403 ( .A1(n413), .A2(n412), .ZN(n307) );
  INV_X1 U404 ( .I(n306), .ZN(n414) );
  OAI22_X1 U405 ( .A1(n415), .A2(n416), .B1(n311), .B2(n417), .ZN(n306) );
  NAND2_X1 U406 ( .A1(n308), .A2(n312), .ZN(n417) );
  INV_X1 U407 ( .I(n310), .ZN(n312) );
  XNOR2_X1 U408 ( .A1(n418), .A2(n419), .ZN(n310) );
  XNOR2_X1 U409 ( .A1(n415), .A2(n420), .ZN(n308) );
  NOR2_X1 U410 ( .A1(n419), .A2(n418), .ZN(n420) );
  NAND2_X1 U411 ( .A1(n314), .A2(n313), .ZN(n311) );
  XOR2_X1 U412 ( .A1(n421), .A2(n422), .Z(n313) );
  NOR2_X1 U413 ( .A1(n315), .A2(n316), .ZN(n314) );
  XNOR2_X1 U414 ( .A1(n423), .A2(n424), .ZN(n316) );
  NAND2_X1 U415 ( .A1(S[0]), .A2(n423), .ZN(n315) );
  OR2_X1 U416 ( .A1(n418), .A2(n419), .Z(n416) );
  AOI22_X1 U417 ( .A1(n425), .A2(n426), .B1(n422), .B2(n421), .ZN(n419) );
  XNOR2_X1 U418 ( .A1(n426), .A2(n427), .ZN(n421) );
  XNOR2_X1 U419 ( .A1(n428), .A2(n429), .ZN(n422) );
  NAND2_X1 U420 ( .A1(A[1]), .A2(B[2]), .ZN(n428) );
  INV_X1 U421 ( .I(n427), .ZN(n425) );
  AOI22_X1 U422 ( .A1(n430), .A2(S[0]), .B1(n424), .B2(n423), .ZN(n427) );
  NOR2_X1 U423 ( .A1(n431), .A2(n432), .ZN(n423) );
  XNOR2_X1 U424 ( .A1(n433), .A2(n434), .ZN(n424) );
  NOR2_X1 U425 ( .A1(n435), .A2(n436), .ZN(n434) );
  NAND2_X1 U426 ( .A1(A[0]), .A2(B[2]), .ZN(n433) );
  INV_X1 U427 ( .I(n437), .ZN(n430) );
  OAI21_X1 U428 ( .A1(n438), .A2(n439), .B(n440), .ZN(n418) );
  XNOR2_X1 U429 ( .A1(n441), .A2(n442), .ZN(n415) );
  OAI21_X1 U430 ( .A1(n443), .A2(n444), .B(n445), .ZN(n413) );
  INV_X1 U431 ( .I(n446), .ZN(n412) );
  OAI22_X1 U432 ( .A1(n447), .A2(n448), .B1(n442), .B2(n441), .ZN(n446) );
  NAND2_X1 U433 ( .A1(n426), .A2(n449), .ZN(n441) );
  NOR2_X1 U434 ( .A1(n450), .A2(n451), .ZN(n426) );
  XOR2_X1 U435 ( .A1(n452), .A2(n448), .Z(n442) );
  OAI21_X1 U436 ( .A1(n453), .A2(n454), .B(n455), .ZN(n448) );
  INV_X1 U437 ( .I(n452), .ZN(n447) );
  OAI21_X1 U438 ( .A1(n456), .A2(n457), .B(n440), .ZN(n452) );
  NAND2_X1 U439 ( .A1(n438), .A2(n439), .ZN(n440) );
  OAI22_X1 U440 ( .A1(n458), .A2(n459), .B1(n431), .B2(n460), .ZN(n439) );
  NAND2_X1 U441 ( .A1(B[2]), .A2(n429), .ZN(n460) );
  XOR2_X1 U442 ( .A1(n459), .A2(n458), .Z(n429) );
  NAND2_X1 U443 ( .A1(A[2]), .A2(B[1]), .ZN(n459) );
  NAND2_X1 U444 ( .A1(A[3]), .A2(B[0]), .ZN(n458) );
  XOR2_X1 U445 ( .A1(n456), .A2(n457), .Z(n438) );
  XOR2_X1 U446 ( .A1(n461), .A2(n462), .Z(n457) );
  NOR2_X1 U447 ( .A1(n451), .A2(n397), .ZN(n462) );
  NAND2_X1 U448 ( .A1(B[3]), .A2(A[1]), .ZN(n461) );
  XNOR2_X1 U449 ( .A1(n437), .A2(n463), .ZN(n456) );
  XOR2_X1 U450 ( .A1(n464), .A2(n465), .Z(n305) );
  XNOR2_X1 U451 ( .A1(n411), .A2(n410), .ZN(n303) );
  AOI22_X1 U452 ( .A1(n466), .A2(n467), .B1(n465), .B2(n464), .ZN(n410) );
  XOR2_X1 U453 ( .A1(n467), .A2(n466), .Z(n464) );
  XOR2_X1 U454 ( .A1(n468), .A2(n469), .Z(n465) );
  XOR2_X1 U455 ( .A1(n470), .A2(n471), .Z(n467) );
  OAI21_X1 U456 ( .A1(n472), .A2(n473), .B(n445), .ZN(n466) );
  NAND2_X1 U457 ( .A1(n443), .A2(n444), .ZN(n445) );
  XOR2_X1 U458 ( .A1(n474), .A2(n475), .Z(n444) );
  XOR2_X1 U459 ( .A1(n473), .A2(n472), .Z(n443) );
  XOR2_X1 U460 ( .A1(n476), .A2(n477), .Z(n473) );
  NAND2_X1 U461 ( .A1(B[6]), .A2(A[0]), .ZN(n476) );
  AOI21_X1 U462 ( .A1(n478), .A2(n479), .B(n480), .ZN(n472) );
  INV_X1 U463 ( .I(n455), .ZN(n480) );
  NAND2_X1 U464 ( .A1(n453), .A2(n454), .ZN(n455) );
  OAI22_X1 U465 ( .A1(n463), .A2(n437), .B1(n432), .B2(n481), .ZN(n454) );
  NAND2_X1 U466 ( .A1(A[3]), .A2(n482), .ZN(n481) );
  NAND2_X1 U467 ( .A1(B[2]), .A2(A[2]), .ZN(n437) );
  XOR2_X1 U468 ( .A1(n483), .A2(n484), .Z(n463) );
  NOR2_X1 U469 ( .A1(n485), .A2(n432), .ZN(n484) );
  XOR2_X1 U470 ( .A1(n479), .A2(n478), .Z(n453) );
  XNOR2_X1 U471 ( .A1(n486), .A2(n487), .ZN(n479) );
  NAND2_X1 U472 ( .A1(B[5]), .A2(A[0]), .ZN(n486) );
  XNOR2_X1 U473 ( .A1(n488), .A2(n489), .ZN(n478) );
  NAND2_X1 U474 ( .A1(B[2]), .A2(A[3]), .ZN(n488) );
  XNOR2_X1 U475 ( .A1(n490), .A2(n491), .ZN(n411) );
  XOR2_X1 U476 ( .A1(n492), .A2(n493), .Z(n409) );
  OAI22_X1 U477 ( .A1(n494), .A2(n495), .B1(n491), .B2(n490), .ZN(n408) );
  XNOR2_X1 U478 ( .A1(n494), .A2(n495), .ZN(n490) );
  XNOR2_X1 U479 ( .A1(n496), .A2(n497), .ZN(n491) );
  OAI21_X1 U480 ( .A1(n498), .A2(n499), .B(n500), .ZN(n495) );
  INV_X1 U481 ( .I(n501), .ZN(n494) );
  OAI21_X1 U482 ( .A1(n471), .A2(n470), .B(n502), .ZN(n501) );
  NAND2_X1 U483 ( .A1(n502), .A2(n503), .ZN(n470) );
  INV_X1 U484 ( .I(n504), .ZN(n503) );
  AOI21_X1 U485 ( .A1(n474), .A2(n475), .B(n505), .ZN(n504) );
  NAND3_X1 U486 ( .A1(n474), .A2(n475), .A3(n505), .ZN(n502) );
  OAI22_X1 U487 ( .A1(n506), .A2(n507), .B1(n363), .B2(n508), .ZN(n505) );
  NAND2_X1 U488 ( .A1(A[0]), .A2(n477), .ZN(n508) );
  XOR2_X1 U489 ( .A1(n506), .A2(n507), .Z(n477) );
  OAI21_X1 U490 ( .A1(n509), .A2(n510), .B(n511), .ZN(n507) );
  NOR2_X1 U491 ( .A1(n407), .A2(n512), .ZN(n509) );
  OAI21_X1 U492 ( .A1(n513), .A2(n514), .B(n515), .ZN(n506) );
  NOR2_X1 U493 ( .A1(n391), .A2(n431), .ZN(n513) );
  OAI22_X1 U494 ( .A1(n483), .A2(n516), .B1(n512), .B2(n517), .ZN(n475) );
  NAND2_X1 U495 ( .A1(A[3]), .A2(n489), .ZN(n517) );
  XNOR2_X1 U496 ( .A1(n518), .A2(n519), .ZN(n489) );
  NOR2_X1 U497 ( .A1(n407), .A2(n432), .ZN(n519) );
  INV_X1 U498 ( .I(n482), .ZN(n483) );
  NOR2_X1 U499 ( .A1(n435), .A2(n407), .ZN(n482) );
  OAI22_X1 U500 ( .A1(n520), .A2(n521), .B1(n391), .B2(n522), .ZN(n474) );
  NAND2_X1 U501 ( .A1(A[0]), .A2(n487), .ZN(n522) );
  XNOR2_X1 U502 ( .A1(n521), .A2(n449), .ZN(n487) );
  INV_X1 U503 ( .I(n449), .ZN(n520) );
  NOR2_X1 U504 ( .A1(n397), .A2(n431), .ZN(n449) );
  XNOR2_X1 U505 ( .A1(n523), .A2(n524), .ZN(n471) );
  OAI21_X1 U506 ( .A1(n525), .A2(n526), .B(n384), .ZN(n379) );
  NAND2_X1 U507 ( .A1(n525), .A2(n526), .ZN(n384) );
  OAI22_X1 U508 ( .A1(n527), .A2(n528), .B1(n493), .B2(n492), .ZN(n526) );
  OAI21_X1 U509 ( .A1(n529), .A2(n530), .B(n531), .ZN(n492) );
  XOR2_X1 U510 ( .A1(n532), .A2(n527), .Z(n493) );
  INV_X1 U511 ( .I(n532), .ZN(n528) );
  OAI21_X1 U512 ( .A1(n533), .A2(n534), .B(n535), .ZN(n532) );
  AOI21_X1 U513 ( .A1(n497), .A2(n496), .B(n536), .ZN(n527) );
  INV_X1 U514 ( .I(n537), .ZN(n496) );
  OAI21_X1 U515 ( .A1(n538), .A2(n539), .B(n540), .ZN(n537) );
  NOR2_X1 U516 ( .A1(n431), .A2(n352), .ZN(n538) );
  INV_X1 U517 ( .I(A[1]), .ZN(n431) );
  NOR2_X1 U518 ( .A1(n536), .A2(n541), .ZN(n497) );
  AOI21_X1 U519 ( .A1(n469), .A2(n468), .B(n542), .ZN(n541) );
  AND3_X1 U520 ( .A1(n469), .A2(n468), .A3(n542), .Z(n536) );
  OAI22_X1 U521 ( .A1(n543), .A2(n544), .B1(n524), .B2(n523), .ZN(n542) );
  NAND2_X1 U522 ( .A1(n545), .A2(n546), .ZN(n523) );
  OAI21_X1 U523 ( .A1(n451), .A2(n352), .B(n547), .ZN(n546) );
  INV_X1 U524 ( .I(n498), .ZN(n545) );
  XNOR2_X1 U525 ( .A1(n543), .A2(n544), .ZN(n524) );
  OAI21_X1 U526 ( .A1(n548), .A2(n549), .B(n550), .ZN(n544) );
  NOR2_X1 U527 ( .A1(n436), .A2(n391), .ZN(n548) );
  INV_X1 U528 ( .I(B[5]), .ZN(n391) );
  OAI21_X1 U529 ( .A1(n551), .A2(n552), .B(n553), .ZN(n543) );
  NOR2_X1 U530 ( .A1(n512), .A2(n399), .ZN(n551) );
  INV_X1 U531 ( .I(B[2]), .ZN(n512) );
  OAI21_X1 U532 ( .A1(n521), .A2(n533), .B(n515), .ZN(n468) );
  NAND3_X1 U533 ( .A1(B[5]), .A2(n514), .A3(A[1]), .ZN(n515) );
  XNOR2_X1 U534 ( .A1(n554), .A2(n555), .ZN(n514) );
  NOR2_X1 U535 ( .A1(n436), .A2(n397), .ZN(n555) );
  NAND2_X1 U536 ( .A1(B[3]), .A2(A[3]), .ZN(n554) );
  NAND2_X1 U537 ( .A1(B[3]), .A2(A[2]), .ZN(n521) );
  OAI21_X1 U538 ( .A1(n518), .A2(n556), .B(n511), .ZN(n469) );
  NAND3_X1 U539 ( .A1(A[4]), .A2(n510), .A3(B[2]), .ZN(n511) );
  XNOR2_X1 U540 ( .A1(n516), .A2(n557), .ZN(n510) );
  NOR2_X1 U541 ( .A1(n435), .A2(n351), .ZN(n557) );
  NAND2_X1 U542 ( .A1(A[5]), .A2(B[1]), .ZN(n516) );
  NAND2_X1 U543 ( .A1(A[5]), .A2(B[0]), .ZN(n518) );
  XOR2_X1 U544 ( .A1(n381), .A2(n382), .Z(n525) );
  XOR2_X1 U545 ( .A1(n386), .A2(n385), .Z(n382) );
  XOR2_X1 U546 ( .A1(n388), .A2(n387), .Z(n385) );
  INV_X1 U547 ( .I(n558), .ZN(n387) );
  AOI22_X1 U548 ( .A1(n559), .A2(n560), .B1(n561), .B2(n562), .ZN(n558) );
  OAI22_X1 U549 ( .A1(n563), .A2(n564), .B1(n352), .B2(n565), .ZN(n388) );
  NAND2_X1 U550 ( .A1(A[2]), .A2(n566), .ZN(n565) );
  XOR2_X1 U551 ( .A1(n404), .A2(n403), .Z(n386) );
  INV_X1 U552 ( .I(n567), .ZN(n403) );
  OAI22_X1 U553 ( .A1(n568), .A2(n390), .B1(n397), .B2(n569), .ZN(n567) );
  NAND2_X1 U554 ( .A1(A[5]), .A2(n570), .ZN(n569) );
  XNOR2_X1 U555 ( .A1(n406), .A2(n405), .ZN(n404) );
  XOR2_X1 U556 ( .A1(n564), .A2(n571), .Z(n405) );
  NOR2_X1 U557 ( .A1(n485), .A2(n352), .ZN(n571) );
  NAND2_X1 U558 ( .A1(B[6]), .A2(A[4]), .ZN(n564) );
  XOR2_X1 U559 ( .A1(n572), .A2(n393), .Z(n406) );
  XOR2_X1 U560 ( .A1(n390), .A2(n364), .Z(n393) );
  NAND2_X1 U561 ( .A1(A[6]), .A2(B[4]), .ZN(n364) );
  NAND2_X1 U562 ( .A1(A[7]), .A2(B[3]), .ZN(n390) );
  NAND2_X1 U563 ( .A1(B[5]), .A2(A[5]), .ZN(n572) );
  OAI21_X1 U564 ( .A1(n573), .A2(n574), .B(n531), .ZN(n381) );
  NAND2_X1 U565 ( .A1(n529), .A2(n530), .ZN(n531) );
  XNOR2_X1 U566 ( .A1(n575), .A2(n573), .ZN(n530) );
  XOR2_X1 U567 ( .A1(n559), .A2(n560), .Z(n529) );
  XOR2_X1 U568 ( .A1(n562), .A2(n561), .Z(n560) );
  XNOR2_X1 U569 ( .A1(n576), .A2(n566), .ZN(n561) );
  XNOR2_X1 U570 ( .A1(n534), .A2(n401), .ZN(n566) );
  NOR2_X1 U571 ( .A1(n363), .A2(n485), .ZN(n401) );
  NAND2_X1 U572 ( .A1(B[5]), .A2(A[4]), .ZN(n534) );
  NAND2_X1 U573 ( .A1(B[7]), .A2(A[2]), .ZN(n576) );
  XNOR2_X1 U574 ( .A1(n577), .A2(n570), .ZN(n562) );
  XNOR2_X1 U575 ( .A1(n578), .A2(n579), .ZN(n570) );
  NOR2_X1 U576 ( .A1(n450), .A2(n351), .ZN(n579) );
  NAND2_X1 U577 ( .A1(B[4]), .A2(A[5]), .ZN(n577) );
  OAI21_X1 U578 ( .A1(n556), .A2(n578), .B(n580), .ZN(n559) );
  NAND2_X1 U579 ( .A1(A[7]), .A2(B[2]), .ZN(n578) );
  INV_X1 U580 ( .I(n575), .ZN(n574) );
  OAI21_X1 U581 ( .A1(n581), .A2(n582), .B(n540), .ZN(n575) );
  NAND3_X1 U582 ( .A1(A[1]), .A2(n539), .A3(B[7]), .ZN(n540) );
  XOR2_X1 U583 ( .A1(n581), .A2(n582), .Z(n539) );
  OAI21_X1 U584 ( .A1(n583), .A2(n584), .B(n535), .ZN(n582) );
  NAND3_X1 U585 ( .A1(A[2]), .A2(n584), .A3(B[6]), .ZN(n535) );
  XNOR2_X1 U586 ( .A1(n563), .A2(n585), .ZN(n584) );
  NOR2_X1 U587 ( .A1(n407), .A2(n397), .ZN(n585) );
  NAND2_X1 U588 ( .A1(B[5]), .A2(A[3]), .ZN(n563) );
  NOR2_X1 U589 ( .A1(n436), .A2(n363), .ZN(n583) );
  INV_X1 U590 ( .I(B[6]), .ZN(n363) );
  INV_X1 U591 ( .I(A[2]), .ZN(n436) );
  OAI21_X1 U592 ( .A1(n586), .A2(n587), .B(n580), .ZN(n581) );
  NAND3_X1 U593 ( .A1(A[5]), .A2(n587), .A3(B[3]), .ZN(n580) );
  XNOR2_X1 U594 ( .A1(n568), .A2(n588), .ZN(n587) );
  NOR2_X1 U595 ( .A1(n432), .A2(n398), .ZN(n588) );
  NAND2_X1 U596 ( .A1(A[6]), .A2(B[2]), .ZN(n568) );
  NOR2_X1 U597 ( .A1(n399), .A2(n450), .ZN(n586) );
  INV_X1 U598 ( .I(A[5]), .ZN(n399) );
  AOI21_X1 U599 ( .A1(n589), .A2(n590), .B(n591), .ZN(n573) );
  INV_X1 U600 ( .I(n500), .ZN(n591) );
  NAND2_X1 U601 ( .A1(n498), .A2(n499), .ZN(n500) );
  XOR2_X1 U602 ( .A1(n589), .A2(n590), .Z(n499) );
  NOR3_X1 U603 ( .A1(n352), .A2(n451), .A3(n547), .ZN(n498) );
  NAND2_X1 U604 ( .A1(B[6]), .A2(A[1]), .ZN(n547) );
  INV_X1 U605 ( .I(B[7]), .ZN(n352) );
  NAND2_X1 U606 ( .A1(n550), .A2(n592), .ZN(n590) );
  NAND3_X1 U607 ( .A1(B[3]), .A2(A[4]), .A3(n593), .ZN(n592) );
  NAND3_X1 U608 ( .A1(A[2]), .A2(n549), .A3(B[5]), .ZN(n550) );
  XNOR2_X1 U609 ( .A1(n533), .A2(n594), .ZN(n549) );
  NOR2_X1 U610 ( .A1(n407), .A2(n450), .ZN(n594) );
  INV_X1 U611 ( .I(B[3]), .ZN(n450) );
  INV_X1 U612 ( .I(A[4]), .ZN(n407) );
  INV_X1 U613 ( .I(n593), .ZN(n533) );
  NOR2_X1 U614 ( .A1(n397), .A2(n485), .ZN(n593) );
  INV_X1 U615 ( .I(A[3]), .ZN(n485) );
  INV_X1 U616 ( .I(B[4]), .ZN(n397) );
  NAND2_X1 U617 ( .A1(n553), .A2(n595), .ZN(n589) );
  NAND3_X1 U618 ( .A1(A[7]), .A2(B[0]), .A3(n596), .ZN(n595) );
  NAND3_X1 U619 ( .A1(B[2]), .A2(n552), .A3(A[5]), .ZN(n553) );
  XNOR2_X1 U620 ( .A1(n556), .A2(n597), .ZN(n552) );
  NOR2_X1 U621 ( .A1(n435), .A2(n398), .ZN(n597) );
  INV_X1 U622 ( .I(A[7]), .ZN(n398) );
  INV_X1 U623 ( .I(n596), .ZN(n556) );
  NOR2_X1 U624 ( .A1(n351), .A2(n432), .ZN(n596) );
  INV_X1 U625 ( .I(B[1]), .ZN(n432) );
  INV_X1 U626 ( .I(A[6]), .ZN(n351) );
  NOR2_X1 U627 ( .A1(n451), .A2(n435), .ZN(S[0]) );
  INV_X1 U628 ( .I(B[0]), .ZN(n435) );
  INV_X1 U629 ( .I(A[0]), .ZN(n451) );
endmodule
