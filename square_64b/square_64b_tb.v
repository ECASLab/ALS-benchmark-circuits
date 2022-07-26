`timescale 1ns / 1ps 

module square_64b_tb(); 

 wire [127:0] out0;
 reg [63:0] in0;

 integer i, file, mem, temp;

 square_64b U0(in0,out0);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./square_64b.vcd");
 $dumpvars(0,square_64b_tb);
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
