`timescale 1ns / 1ps 

module LFA_16b_tb(); 

wire [16:0] out0;
 reg [15:0] in0;
 reg [15:0] in1;

integer i, file, mem, temp;

LFA_16b U0(in0,in1,out0);

initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./LFA_16b.vcd");
 $dumpvars(0,LFA_16b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 in1 = 0;
 #10
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%h %h \n",in0,in1);
  #10
  $fwrite(file, "%d\n",{out0});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $finish;
end
endmodule
