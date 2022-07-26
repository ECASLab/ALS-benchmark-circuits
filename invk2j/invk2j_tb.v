`timescale 1ns / 1ps 

module invk2j_tb(); 

 wire [31:0] out0;
 wire [31:0] out1;
 reg [31:0] in0;
 reg [31:0] in1;
 reg clk, rst;

 integer i, file;
 invk2j U0(in0,in1,out0,out1, clk, rst);
 
 always begin
  #5 clk <= 0;
  #5 clk <= 1;
 end

 initial begin
 //$display("-- Begining Simulation --");

 /*
 $dumpfile("./test.vcd");
 $dumpvars(0,fwrdk2j_tb);
 */
 file=$fopen("output.txt","w");
 in0 = 0;
 in1 = 0;
 rst = 1;
 #100
 rst = 0;
 #100
 for (i=0;i<10;i=i+1) begin
  in0 = $random;
  in1 = $random;
  #1000
  $fwrite(file, "%d\n",{out0,out1});
  end
  $fclose(file);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
