`timescale 1ns / 1ps 

module sqrt_128b_tb(); 

wire [63:0] out0;
 reg [127:0] in0;

integer i, file, mem, temp;

sqrt_128b U0(in0,out0);

initial begin
 $display("-- Begining Simulation --");

 $dumpfile("./sqrt_128b.vcd");
 $dumpvars(0,sqrt_128b_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 #10
 for (i=0;i<1000000;i=i+1) begin
  temp=$fscanf(mem,"%h \n",in0);
  #10
  $fwrite(file, "%d\n",{out0});
  $display("-- Progress: %d/1000000 --",i+1);
 end
 $fclose(file);
 $fclose(mem);
 $finish;
end
endmodule
