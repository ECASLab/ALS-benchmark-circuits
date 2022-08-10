`timescale 10ns / 1ps 

module fir_tb(); 

 wire [9:0] out0;
 reg [7:0] in0;
 reg clk, rst;

 integer i, file, mem,temp;
 fir U0(clk,rst,in0,out0);
 
 always begin
 clk<=0;
 #5;
 clk<=1;
 #5;
 end
 

 initial begin
 $display("-- Begining Simulation --");
 
 $dumpfile("./fir.vcd");
 $dumpvars(0,fir_tb);
 
 file=$fopen("output.txt","w");
 mem=$fopen("dataset","r");
 in0 = 0;
 rst= 1;
 #5
 rst= 0;
 #5
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%d \n",in0);
  #10
  $fwrite(file, "%d\n",out0);
  $display("--Progress: %d/1000000--",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $display("-- Ending Simulation --");
 $finish;
 end
endmodule
