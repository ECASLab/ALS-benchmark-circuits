`timescale 1ns / 1ps 

module sobel_tb(); 

 wire [7:0] out0;
 reg [8:0] in0;
 reg [8:0] in1;
 reg [8:0] in2;
 reg [8:0] in3;
 reg [8:0] in4;
 reg [8:0] in5;
 reg [8:0] in6;
 reg [8:0] in7;
 reg [8:0] in8;
 integer i, file, mem, temp;
 sobel U0(in0,in1,in2,in3,in5,in6,in7,in8,in4,out0);

 initial begin
 //$display("-- Begining Simulation --");

 /*
 $dumpfile("./test.vcd");
 $dumpvars(0,sobel_tb);
 */
 mem=$fopen ("dataset","r");
 file=$fopen("output.txt","w");
 in0 = 0;
 in1 = 0;
 in2 = 0;
 in3 = 0;
 in4 = 0;
 in5 = 0;
 in6 = 0;
 in7 = 0;
 in8 = 0;
 
 #10
 for (i=0;i<512*512;i=i+1) begin
  temp=$fscanf(mem,"%d %d %d %d %d %d %d %d %d\n",in0,in1,in2,in3,in4,in5,in6,in7,in8);
  #10
  $fwrite(file, "%d\n",{out0});
  end
  $fclose(file);
  $fclose(mem);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
