`timescale 10ns / 1ps 

module DTree_tb(); 

wire [4:0] out0;
 reg [9:0] in0;
 reg [9:0] in1;
 reg [9:0] in2;
 reg [9:0] in3;
 reg [9:0] in4;
 reg [9:0] in5;
 reg [9:0] in6;
 reg [9:0] in7;
 reg [9:0] in8;
 reg [9:0] in9;
 reg [9:0] in10;
 reg [9:0] in11;
 reg [9:0] in12;
 reg [9:0] in13;
 reg [9:0] in14;
 reg [9:0] in15;
 reg [9:0] in16;
 reg [9:0] in17;
 reg [9:0] in18;
 reg [9:0] in19;
 reg [9:0] in20;
 reg [9:0] in21;
 reg [9:0] in22;
 reg [9:0] in23;
 reg [9:0] in24;
 reg [9:0] in25;
 reg [9:0] in26;
 reg [9:0] in27;
 reg [9:0] in28;
 reg [9:0] in29;

integer i, file, mem, temp;

DTree U0(in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29,out0);

initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./DTree.vcd");
 $dumpvars(0,DTree_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 in2 = 0;
 in3 = 0;
 in4 = 0;
 in5 = 0;
 in6 = 0;
 in7 = 0;
 in8 = 0;
 in9 = 0;
 in10 = 0;
 in11 = 0;
 in12 = 0;
 in13 = 0;
 in14 = 0;
 in15 = 0;
 in16 = 0;
 in17 = 0;
 in18 = 0;
 in19 = 0;
 in20 = 0;
 in21 = 0;
 in22 = 0;
 in23 = 0;
 in24 = 0;
 in25 = 0;
 in26 = 0;
 in27 = 0;
 in28 = 0;
 in29 = 0;
 #10
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h \n",in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20,in21,in22,in23,in24,in25,in26,in27,in28,in29);
  #10
  $fwrite(file, "%d\n",{out0});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $finish;
end
endmodule
