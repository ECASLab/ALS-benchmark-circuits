import os.path
import random
import sys
iter_num=100_000;
def dataset_gen(path:str, inputs: list, length :int):
    text=''
    for r in range(length):
        for n in inputs:
            n=10
            text=text+str(random.getrandbits(n)) + ' '
        text=text+'\n'

    with open(path,"w") as file:
        file.write(text)
        file.close

def tb_generator(name: str, path:str, inputs_length, outputs_length):



    text= '`timescale 1ns / 1ps \n' \
        '\n' \
        'module ' + name + '_tb(); \n' \
        '\n'
    i=0
    inputs=[]
    outputs=[]
    for l in outputs_length:
        if l==1:
            text= text+' wire out'+str(i)+';\n'
        else:
            text= text+' wire ['+ str(l-1)+':0] out'+str(i)+';\n'
        outputs.append('out'+str(i))
        i+=1
    i=0
    for l in inputs_length:
        if l==1:
            text= text+' reg in'+str(i)+';\n'
        else:
            text= text+' reg ['+ str(l-1)+':0] in'+str(i)+';\n'
        inputs.append('in'+str(i))
        i+=1

    text= text+ '\n' \
                ' integer i, file, mem, temp;\n' \
                '\n' \
                ' '+ name +' U0('
    for i in inputs:
        text=text+i+','
    for o in outputs[0:-1]:
        text=text+o+','
    text=text+outputs[-1]+');\n' \
                        '\n' \
                        ' initial begin\n' \
                        ' //$display("-- Begining Simulation --");\n' \
                        '\n' + f' $dumpfile("./{name}.vcd");\n' \
                        ' $dumpvars(0,'+name+'_tb);\n' \
                        ' file=$fopen("output.txt","w");\n' \
                        ' mem=$fopen("dataset", "r");\n'
    for i in inputs:
        text=text+ ' '+ i+' = 0;\n'
    text=text+' #10\n' \
              ' for (i=0;i<'+str(iter_num)+';i=i+1) begin\n' \
              '  temp=$fscanf(mem,"'
    for i in range(len(inputs)):
        text=text+'%d '
    text=text+'\\n"'
    for i in inputs:
        text=text+ ','+ str(i)
    text=text+');\n' \
              '  #10\n' \
              '  $fwrite(file, "%d\\n",{'
    for o in outputs[::-1][0:-1]:
        text=text+o+','
    text=text+outputs[0]+'});\n' \
                          '  end\n' \
                          '  $fclose(file);\n' \
                         '   $fclose(mem);\n' \
                          '  //$display("-- Ending Simulation --");\n' \
                          '  $finish;\n' \
                          ' end\n' \
                          'endmodule\n'
    with open(os.path.join(path,name+'_tb.v'),'w') as file:
        file.write(text)
        file.close()

def test_tb(name: str, path:str):
    kon= f'iverilog -o {path}/{name} {path}/{name}.v {path}/{name}_tb.v'
    os.system(kon)
    result=os.system(f'cd {path}; ./{name}')
    print (result)
    os.system('rm '+ os.path.join(path,name))




'''TEST'''
# name=[
# 'BK_16b',
# 'BK_32b',
# #Fir no incluido, tb propio secuencial# 'fir',
# 'KS_16b',
# 'KS_32b',
# 'Mul_16b',
# 'Mul_32b',
# 'adder_128b',
# 'barshift_128b',
# 'div_64b', #Particularmente lento de simular
# 'hyp_128b', #Particularmente lento de simular
# 'log2_32b',
# 'max_128b',
# 'mul_64b',
# 'sin_24b',
# 'sqrt_128b',
# 'square_64b',
# 'CLA_16b',
# 'CSkipA_16b',
# 'LFA_16b',
# 'RCA_4b',
# 'WT_8b',
# 'fwrdk2j',
# 'voter',
# 'int2float',
# 'dec',
# 'sobel'
# ]
# path=name
# inputs=[
# [16, 16],
# [32, 32],
# #Entradas de fir [8,2]
# [16, 16],
# [32, 32],
# [16, 16],
# [32, 32],
# [128, 128],
# [128, 7],
# [64,64],
# [128, 128],
# [32],
# [128, 128, 128, 128],
# [64, 64],
# [24],
# [128],
# [64],
# [16, 16, 1],
# [16, 16],
# [16, 16],
# [4, 4, 1],
# [8, 8],
# [32, 32],
# [1001],
# [11],
# [8],
# [9, 9, 9, 9, 9, 9, 9, 9, 9]
# ]
# outputs=[
# [17],
# [33],
# #Salidas de FIR [10],
# [17],
# [33],
# [32],
# [64],
# [128,1],
# [128],
# [64,64],
# [128],
# [32],
# [128,2],
# [128],
# [25],
# [64],
# [128],
# [17],
# [17],
# [17],
# [5],
# [16],
# [32, 32],
# [1],
# [4,3],
# [128, 128],
# [8]
# ]
# for n,p,i,o in zip(name,path,inputs,outputs):
#     print(f'Generating {n} testbench and dataset...')
#     #dataset_gen(path=os.path.join(p,'dataset'),inputs=i,length=iter_num)
#     #tb_generator(n,p,i,o)
#     test_tb(n,p)

