`timescale 1ns / 1ps 

module voter_tb(); 

 wire out0;
 reg [1000:0] in0;

 integer i, file, mem, temp;

 voter U0(in0,out0);

 initial begin
 //$display("-- Begining Simulation --");

 $dumpfile("./voter.vcd");
 $dumpvars(0,voter_tb);
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
