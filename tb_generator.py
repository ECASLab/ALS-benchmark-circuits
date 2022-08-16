import os.path
import sys
from data_generator import *

iter_num=1_000_000; #How iterations (outputs, data readings...)

def tb_generator(topmodule: str, path:str, inputs_length, outputs_length, samples, dump_vcd=False):
    '''
    Writes a general testbench .v file for a circuit. Assumes a dataset in the same directory,
    generated with data_generator.py script.

    Dataset must be a file named 'dataset' (without extension).
    The output will be a txt file named 'output.txt'

    :param topmodule: string
        Name of the circuit's top module
    :param path: path-like string
        Where to save the testbench. File's name is formatted as {topmodule}_tb.v.
    :param inputs_length: integer list
        A list of bitwidth for each input in the circuit. The length of the list tells how many inputs
        does the circuit have, each element indicates how many bits the input has.
    :param outputs_length: integer list
        A list of bitwidth for each output in the circuit. The length of the list tells how many inputs
        does the circuit have, each element indicates how many bits the output has.
    :param samples: integer
        How many samples the input dataset has.
    :param dump_vcd: boolean
        Whether to dump or not the wave information into a vcd file.


    :return: path-like string
        Path to the generated testbench file.
    '''

    text= f'`timescale 1ns / 1ps \n' \
          f'\n' \
          f'module {topmodule}_tb(); \n' \
          f'\n'
    i=0
    inputs=[]
    outputs=[]
    for l in outputs_length:
        if l==1:
            text= f'{text}wire out{i};\n'
        else:
            text= f'{text}wire [{l-1}:0] out{i};\n'
        outputs.append(f'out{i}')
        i+=1
    i=0
    for l in inputs_length:
        if l==1:
            text= f'{text} reg in{i};\n'
        else:
            text= f'{text} reg [{l-1}:0] in{i};\n'
        inputs.append(f'in{i}')
        i+=1

    text= f'{text}\n' \
          f'integer i, file, mem, temp;\n' \
          f'\n' \
          f'{topmodule} U0('
    for i in inputs:
        text= f'{text}{i},'
    for o in outputs[0:-1]:
        text= f'{text}{o},'
    text= f'{text}{outputs[-1]});\n' \
          f'\n' \
          f'initial begin\n'
    if dump_vcd:
        text=f'{text} $display("-- Begining Simulation --");\n' \
             f'\n' \
             f' $dumpfile("./{topmodule}.vcd");\n' \
             f' $dumpvars(0,{topmodule}_tb);\n'
    text=f'{text} file=$fopen("output.txt","w");\n' \
         f' mem=$fopen("dataset", "r");\n'
    for i in inputs:
        text=f'{text} {i} = 0;\n'
    text=f'{text} #10\n' \
         f' for (i=0;i<{samples};i=i+1) begin\n' \
         f'  temp=$fscanf(mem,"'
    for i in range(len(inputs)):
        text=f'{text}%h '
    text=f'{text}\\n"'
    for i in inputs:
        text=f'{text},{i}'
    text=f'{text});\n' \
         f'  #10\n' \
         f'  $fwrite(file, "%d\\n",'+'{'
    for o in outputs[::-1][0:-1]:
        text= f'{text}{o},'
    text= f'{text}{outputs[0]}'+'});\n'\
        + f'  $display("-- Progress: %d/{samples} --",i+1);\n'\
          f' end\n' \
          f' $fclose(file);\n' \
          f' $fclose(mem);\n' \
          f' $finish;\n' \
          f'end\n' \
          f'endmodule\n'
    with open(os.path.join(path, topmodule + '_tb.v'), 'w') as file:
        file.write(text)
        file.close()

    return os.path.join(path, topmodule + '_tb.v')

def test_tb(name: str, path:str):
    kon= f'iverilog -o {path}/{name} {path}/{name}.v {path}/{name}_tb.v'
    os.system(kon)
    result=os.system(f'cd {path}; ./{name}')
    print (result)
    os.system('rm '+ os.path.join(path,name))




'''TEST'''
name=[
# 'BK_16b',
# 'BK_32b',
# #Fir no incluido, tb propio secuencial# 'fir',
# 'KS_16b',
# 'KS_32b',
# 'Mul_16b',
# 'Mul_32b',
# 'adder_128b',
# 'barshift_128b',
'div_64b', #Particularmente lento de simular
'hyp_128b', #Particularmente lento de simular
'log2_32b',
'max_128b',
'mul_64b',
'sin_24b',
'sqrt_128b',
'square_64b',
'CLA_16b',
'CSkipA_16b',
'LFA_16b',
'RCA_4b',
'WT_8b',
'fwrdk2j',
#'invk2j', #Testbench Secuencial
'voter',
'int2float',
'dec',
'sobel'
]
path=name
inputs=[
# [16, 16], #BK_16b
# [32, 32], #BK_12b
# #Entradas de fir [8,2] #fir
# [16, 16], #KS_16b
# [32, 32], #KS_32b
# [16, 16], #Mul16b
# [32, 32], #Mul32b
# [128, 128], #adder_128b
# [128, 7], #barshift_128b
[64,64], #div_64b
[128, 128], #hyp_128b
[32], #log2_32b
[128, 128, 128, 128], #max_128b
[64, 64], #mul_64b
[24], #sin_24b
[128], #sqt_128b
[64], #square_64b
[16, 16, 1], #CLA_16b
[16, 16], #CSkipA_16b
[16, 16], #LFA_16b
[4, 4, 1],  #RCA_4b
[8, 8], #WT_8b
[32, 32], #fwrdk2j
#[32, 32], #invk2j
[1001], #voter
[11], #int2float
[8], #dec
[9, 9, 9, 9, 9, 9, 9, 9, 9] #sobel
]
outputs=[
# [17], #BK_16b
# [33], #BK_32b
# #Salidas de FIR [10], #FIR
# [17], #KS_16b
# [33], #KS_32b
# [32], #Mul_16b
# [64], #Mul_32b
# [128,1], #adder_128b
# [128], #barshitf_128b
[64,64], #div_64b
[128], #hyp_128b
[32], #log2_32b
[128,2], #max_128b
[128], #mul_64b
[25], #sin_24b
[64], #sqrt_128b
[128], #square_64b
[17], #CLA_16b
[17], #CSkipA_16b
[17], #LFA_16b
[5], #RCA_4b
[16], #WT_8b
[32, 32], #fwrdk2j
#[32, 32], #invk2j
[1], #voter
[4,3], #int2float
[128, 128], #dec
[8] #sobel
]
for n,p,i,o in zip(name,path,inputs,outputs):
    print(f'Generating {n} testbench and dataset...')
    dataset_gen(file=os.path.join(p,'dataset'),inputs=i,samples=iter_num)
    tb_generator(n,p,i,o, dump_vcd=True, samples=iter_num)
    #test_tb(n,p)

