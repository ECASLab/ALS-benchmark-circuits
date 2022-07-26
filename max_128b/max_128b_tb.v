`timescale 1ns / 1ps 

module max_128b_tb(); 

 wire [127:0] out0;
 wire [1:0] out1;
 reg [127:0] in0;
 reg [127:0] in1;
 reg [127:0] in2;
 reg [127:0] in3;

 integer i, file, mem, temp;

 max_128b U0(in0,in1,in2,in3,out0,out1);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./max_128b.vcd");
 $dumpvars(0,max_128b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 in2 = 0;
 in3 = 0;
 #10
 for (i=0;i<100000;i=i+1) begin
  temp=$fscanf(mem,"%d %d %d %d \n",in0,in1,in2,in3);
  #10
  $fwrite(file, "%d\n",{out1,out0});
  end
  $fclose(file);
   $fclose(mem);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
