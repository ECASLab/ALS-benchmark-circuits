import os


def dc_synth(topmodule, path, overwrite=False):
 '''
  param: topmodule: string
     The name of the topmodule (and source .v file) of the benchmark circuit.
  param: path: path-like string
     Where to find the source files.
  param: overwrite: boolean
     Whether to overwrite existing files or not.
  returns: path-like string
     path to synthetized file.
 '''

 ''' Create folders to store the results '''
 os.makedirs(f'./{topmodule}/rtl', exist_ok=True)

 ''' Copy DC scripts and modify them '''
 if not os.path.exists(f'{topmodule}/dc_setup.tcl') or not os.path.exists(f'{topmodule}/dc_synth.tcl') or overwrite:
 
  os.system(f'cp dc_setup.tcl ./{topmodule}/dc_setup.tcl')
 
  with open('dc_synth.tcl','r') as file:
   text=file.read()
   file.close()
 
  text=text.replace('[TOPMODULE]',topmodule)
  text=text.replace('[SRCPATH]',os.path.abspath(path))
 
  with open(f'./{topmodule}/dc_synth.tcl','w') as file:
   file.write(text)
   file.close()

 ''' Run Synthesis '''
 print(f'-- Running Synthesis for {topmodule} --')
 os.system(f'cd {topmodule}; dc_shell-t -f dc_synth.tcl; cd ..')
 print('-- Done --')

 return f'./{topmodule}/netlist/{topmodule}.v'
 
def vcs_simulate(testbench, source, tech='', dump_saif=False):
 '''
  param: testbench: path-like string
     Path to testbench file.
  param: source: path-like string
     Path to the source .v file instantiated in the testbench.
  param: tech: path-like string
     Path to the technology .v source. If tech is provided, it is assumed that simulation is post-synthesis
  param: dump_saif: boolean
     Whether to modify or not the testbench to dump saif.
  returns: 0
 '''
  
 topmodule=source.split('/')[-1].split('.v')[0] #topmodule's name
 tech=tech.split('/')[-1] #tech's name
 
 ''' Create some folders '''
 if not os.path.exists(f'./{topmodule}/rtl/'):
  os.makedirs(f'./{topmodule}/rtl')

 ''' Move sources '''

 command=f'vcs +vcs+flush+all +warn=all -R -full64 {topmodule}_tb.v {topmodule}.v'
 if tech!='': #Assumes post-synthesis
  if not os.path.exists(f'./{topmodule}/post_syn/'):
   os.makedirs(f'./{topmodule}/post_syn')
  path=f'./{topmodule}/post_syn/'
  os.system(f'cp {source} {path}/{topmodule}.v') #copy source
  os.system(f'cp {tech} {path}/{tech}') #copy tech
  command=f'{command} -v {tech}'
 else: #Assumes pre-synthesis
  if not os.path.exists(f'./{topmodule}/pre_syn/'):
   os.makedirs(f'./{topmodule}/pre_syn')
  path=f'./{topmodule}/pre_syn/'
  os.system(f'cp {source} {path}/{topmodule}.v') #copy source

 if not os.path.exists(f'{path}/{topmodule}_tb.v'):
  with open(testbench,'r') as file:
   text=file.read()
   if dump_saif:
    text=text.replace(f'$dumpfile("./{topmodule}.vcd");\n $dumpvars(0,{topmodule}_tb);\n',f'$dumpfile("./{topmodule}.vcd");\n $dumpvars(0,{topmodule}_tb);\n $set_toggle_region({topmodule}_tb);\n $toggle_start();\n')
    text=text.replace(f'$fclose(file);\n',f'$toggle_stop();\n $toggle_report("{topmodule}.saif",10.0e-9,{topmodule}_tb);\n $fclose(file);\n')
   file.close()
  with open(f'{path}/{topmodule}_tb.v', 'w') as file:
   file.write(text)
   file.close()

 tb_path=os.path.dirname(testbench)
 if os.path.exists(f'{tb_path}/dataset'):
  os.system(f'cp {tb_path}/dataset {path}')
 else:
  print('Dataset error: testbench must have (and read) a "dataset" file, but no one was found')
  return 1
 
 ''' Simulate '''
 print('-- Running Simulation --')
 os.system(f'cd {path};{command};cd ../..')
 print('-- Done --') 

 return 0

''' TEST '''
'''
circuits=[
'BK_16b',
'BK_32b',
'fir',
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
'invk2j',
'voter',
'int2float',
'dec',
'sobel'
]

tech='./NanGate15nm.v'

paths=[f'../ALS-benchmark-circuits/{n}' for n in circuits]

for t,p in zip(circuits, paths):
 rtl=f'{p}/{t}.v'
 tb=f'{p}/{t}_tb.v'
 vcs_simulate(tb,rtl)
 synth_rtl=dc_synth(t,p, overwrite=True)
 vcs_simulate(tb,synth_rtl,tech,dump_saif=True)
'''

