`timescale 1ns / 1ps

module invk2j_tb(); 

 wire [31:0] out0;
 wire [31:0] out1;
 reg [31:0] in0;
 reg [31:0] in1;
 reg clk, rst;

 integer i, file, mem, temp;
 invk2j U0(in0,in1,out0,out1, clk, rst);
 
 always begin
  #5 clk <= 0;
  #5 clk <= 1;
 end

 initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./invk2j.vcd");
 $dumpvars(0,invk2j_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset","r");
 in0 = 0;
 in1 = 0;
 rst = 1;
 #1000
 rst = 0;
 #1000
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%h %h \n",in0,in1);
  #1000
  $fwrite(file, "%d\n",{out0,out1});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $display("-- Ending Simulation --");
 $finish;
 end
endmodule
