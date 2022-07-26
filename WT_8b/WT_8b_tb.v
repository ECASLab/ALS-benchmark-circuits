`timescale 1ns / 1ps 

module WT_8b_tb(); 

 wire [15:0] out0;
 reg [7:0] in0;
 reg [7:0] in1;

 integer i, file, mem, temp;

 WT_8b U0(in0,in1,out0);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./WT_8b.vcd");
 $dumpvars(0,WT_8b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 #10
 for (i=0;i<100000;i=i+1) begin
  temp=$fscanf(mem,"%d %d \n",in0,in1);
  #10
  $fwrite(file, "%d\n",{out0});
  end
  $fclose(file);
   $fclose(mem);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
