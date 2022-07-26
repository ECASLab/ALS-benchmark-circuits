`timescale 1ns / 1ps 

module log2_32b_tb(); 

 wire [31:0] out0;
 reg [31:0] in0;

 integer i, file, mem, temp;

 log2_32b U0(in0,out0);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./log2_32b.vcd");
 $dumpvars(0,log2_32b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 #10
 for (i=0;i<100000;i=i+1) begin
  temp=$fscanf(mem,"%d \n",in0);
  #10
  $fwrite(file, "%d\n",{out0});
  end
  $fclose(file);
   $fclose(mem);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
