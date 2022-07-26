`timescale 1ns / 1ps 

module sin_24b_tb(); 

 wire [24:0] out0;
 reg [23:0] in0;

 integer i, file, mem, temp;

 sin_24b U0(in0,out0);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./sin_24b.vcd");
 $dumpvars(0,sin_24b_tb);
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
