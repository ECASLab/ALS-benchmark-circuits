`timescale 1ns / 1ps 

module div_64b_tb(); 

 wire [63:0] out0;
 wire [63:0] out1;
 reg [63:0] in0;
 reg [63:0] in1;

 integer i, file, mem, temp;

 div_64b U0(in0,in1,out0,out1);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./div_64b.vcd");
 $dumpvars(0,div_64b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 #10
 for (i=0;i<100000;i=i+1) begin
  temp=$fscanf(mem,"%d %d \n",in0,in1);
  #10
  $fwrite(file, "%d\n",{out1,out0});
  end
  $fclose(file);
   $fclose(mem);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
