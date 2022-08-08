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
        outputs.append(f'out {i}')
        i+=1
    i=0
    for l in inputs_length:
        if l==1:
            text= f'{text} reg in{i};\n'
        else:
            text= f'{text} reg [{l-1}:0] in{i};\n'
        inputs.append(f'in {i}')
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
        text=f'{text} //$display("-- Begining Simulation --");\n' \
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
        text=f'{text}%d '
    text=f'{text}\\n"'
    for i in inputs:
        text=f'{text},{i}'
    text=f'{text});\n' \
         f'  #10\n' \
         f'  $fwrite(file, "%d\\n",'+'{'
    for o in outputs[::-1][0:-1]:
        text= f'{text}{o},'
    text= f'{text}{outputs[0]}'+'});\n'\
        + f'  $display("--Progress: %d/{samples}--",i+1);\n'\
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
'BK_16b',
'BK_32b',
#Fir no incluido, tb propio secuencial# 'fir',
'KS_16b',
'KS_32b',
'Mul_16b',
'Mul_32b',
'adder_128b',
'barshift_128b',
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
'voter',
'int2float',
'dec',
'sobel'
]
path=name
inputs=[
[16, 16],
[32, 32],
#Entradas de fir [8,2]
[16, 16],
[32, 32],
[16, 16],
[32, 32],
[128, 128],
[128, 7],
[64,64],
[128, 128],
[32],
[128, 128, 128, 128],
[64, 64],
[24],
[128],
[64],
[16, 16, 1],
[16, 16],
[16, 16],
[4, 4, 1],
[8, 8],
[32, 32],
[1001],
[11],
[8],
[9, 9, 9, 9, 9, 9, 9, 9, 9]
]
outputs=[
[17],
[33],
#Salidas de FIR [10],
[17],
[33],
[32],
[64],
[128,1],
[128],
[64,64],
[128],
[32],
[128,2],
[128],
[25],
[64],
[128],
[17],
[17],
[17],
[5],
[16],
[32, 32],
[1],
[4,3],
[128, 128],
[8]
]
for n,p,i,o in zip(name,path,inputs,outputs):
    print(f'Generating {n} testbench and dataset...')
    dataset_gen(file=os.path.join(p,'dataset'),inputs=i,samples=iter_num)
    tb_generator(n,p,i,o, dump_vcd=False, samples=iter_num)
    #test_tb(n,p)

