`timescale 1ns / 1ps 

module RCA_4b_tb(); 

wire [4:0] out0;
 reg [3:0] in0;
 reg [3:0] in1;
 reg in2;

integer i, file, mem, temp;

RCA_4b U0(in0,in1,in2,out0);

initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./RCA_4b.vcd");
 $dumpvars(0,RCA_4b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 in2 = 0;
 #10
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%d %d %d \n",in0,in1,in2);
  #10
  $fwrite(file, "%d\n",{out0});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $finish;
end
endmodule
