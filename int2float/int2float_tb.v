`timescale 1ns / 1ps 

module int2float_tb(); 

wire [3:0] out0;
wire [2:0] out1;
 reg [10:0] in0;

integer i, file, mem, temp;

int2float U0(in0,out0,out1);

initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./int2float.vcd");
 $dumpvars(0,int2float_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 #10
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%d \n",in0);
  #10
  $fwrite(file, "%d\n",{out1,out0});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $finish;
end
endmodule
