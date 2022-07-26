`timescale 1ns / 1ps 

module dec_tb(); 

 wire [127:0] out0;
 wire [127:0] out1;
 reg [7:0] in0;

 integer i, file, mem, temp;

 dec U0(in0,out0,out1);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./dec.vcd");
 $dumpvars(0,dec_tb);
 file=$fopen("output.txt","w");
 mem=$fopen("dataset", "r");
 in0 = 0;
 #10
 for (i=0;i<100000;i=i+1) begin
  temp=$fscanf(mem,"%d \n",in0);
  #10
  $fwrite(file, "%d\n",{out1,out0});
  end
  $fclose(file);
   $fclose(mem);
  //$display("-- Ending Simulation --");
  $finish;
 end
endmodule
