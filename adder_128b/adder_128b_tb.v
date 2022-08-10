`timescale 1ns / 1ps 

module adder_128b_tb(); 

wire [127:0] out0;
wire out1;
 reg [127:0] in0;
 reg [127:0] in1;

integer i, file, mem, temp;

adder_128b U0(in0,in1,out0,out1);

initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./adder_128b.vcd");
 $dumpvars(0,adder_128b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 #10
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%d %d \n",in0,in1);
  #10
  $fwrite(file, "%d\n",{out1,out0});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $finish;
end
endmodule
