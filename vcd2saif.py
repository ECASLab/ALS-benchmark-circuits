from sys import argv
import re
import datetime


def get_time_stamp():
	now = datetime.datetime.now()
	year = '{:02d}'.format(now.year)
	month = '{:02d}'.format(now.month)
	day = '{:02d}'.format(now.day)
	hour = '{:02d}'.format(now.hour)
	minute = '{:02d}'.format(now.minute)
	second = '{:02d}'.format(now.second)
	date_string = '{}-{}-{} {}:{}:{}'.format(month, day, year, hour, minute, second)
	return date_string
	
def saif_indent_level(level):
	space = ''
	for i in range(level):
		space += '  '
	return space
	
	
print('Print: '+str(argv))
module_name = argv[1]
vcd_file_path = argv[2]
saif_file_path = argv[3]
if len(argv)==5:
	if argv[4]==True:
		verbose=True
	else:
		verbose==False

#TODO: check saif information
saifversion = '2.0'
direction = 'backward'
design = module_name
#date = 'Fri Jun 4 19:00:00 2021'
vendor = 'AxPy Inc'
program_name = 'open_vcd2saif'
version = 'v0'
divider = '/ '
timescale = '1 ps'

def file_read(filename):
	for row in open(filename,'r'):
		yield row

# open vcd file
vcd_file = file_read(vcd_file_path)

# 1st pass: get variables
var_list = []
level = 0

prev_name = ''
count=0
total=0
if verbose:
	for line in vcd_file:
		total+=1
		
vcd_file = file_read(vcd_file_path)

for line in vcd_file:
	search = re.search(r'\$scope', line)	
	if search is not None:
		ls = line.split()
		parent = ls[2]
		level += 1
		continue	

	search = re.search(r'\$upscope', line)	
	if search is not None:
		level -= 1
		continue

	search = re.search(r'\$var', line)	
	if search is not None:
		ls = line.split()
		name = ls[4]
		alias = ls[3]
		var_len = int(ls[2])		
		m = re.findall("\d+", ls[5])
		flag_mult = 0
		if(len(m) == 2):
			n0 = int(m[1])
			n1 = int(m[0])
			flag_mult = 1
		elif (len(m) == 1):
			n0 = int(m[0])
			flag_mult = 1
		else:
			n0 = 1

		#if prev_name != name:
		var_len_fix = n0		
		
		if var_len == 1:
			var_list.append({	'name': name, \
						'alias': alias, \
						'parent': parent, \
						'level': level, \
						'len': 1, \
						'bit_index': n0, \
						'multi_bit': flag_mult, \
						'high': 0, \
						'low': 0, \
						'x': 0, \
						'ig': 0, \
						'last': "2", \
						'toggle': 0 })
		else:
			for i in range(var_len):
				var_list.append({ 'name': name, \
						  'alias': alias, \
						  'parent': parent, \
						  'level': level, \
						  'len': var_len, \
						  'bit_index': i, \
   						  'multi_bit': flag_mult, \
						  'high': 0, \
						  'low': 0, \
						  'x': 0, \
						  'ig': 0, \
						  'last': "2", \
						  'toggle': 0 })
		prev_name = name
		continue
	if verbose:
		count+=1
		print(f'Pass #1: {count}/{total}')
	#x = var['name']
		

# 2nd pass: get values
x=0
time_step = 0
last_step = 0

count=0
vcd_file = file_read(vcd_file_path)

for line in vcd_file:
	
	if line != '':
		if line[0] == '#':
			time_step = int(line[1:])
			
			#print('Time step: %d' % time_step)
			time_diff = time_step - last_step
			for var in var_list:
				if var['last'] == "1":
					var['high'] += time_diff
				elif var['last'] == "0":
					var['low']  += time_diff
				elif var['last'] == "x":
					var['x']  += time_diff
			last_step = time_step
			
		elif line[0] == 'b' and line[1] != 'x':
			val, alias = line.split()
			val_len = len(val[1:])
			
			bit_index = val_len - 1
			for bit_char in val[1:]:

				bit_val = bit_char
				for var in var_list:
					if alias == var['alias']:
						templateSize = "{0:0%db}" % (var['len'])
						word = templateSize.format(int(val[1:],2))
						rev_word = word[::-1]
						if var['last'] != '2' and var['last'] != rev_word[var['bit_index']]:
							var['toggle'] += 1
						var['last'] = rev_word[var['bit_index']]

				bit_index -= 1

		elif line[0] == "0" or line[0] == "1" or line[0] == "x":
			bit_val = line[0]
			alias = line[1:]
			for var in var_list:
				if alias == var['alias'] and var['len'] == 1:
					if var['last'] != "2" and var['last'] != bit_val:
						var['toggle'] += 1
					var['last'] = bit_val
	if verbose:
		count+=1
		print(f'Pass #2: {count}/{total}')	
		
duration = time_step-1

# 3rd pass: write file

text_level = 0
level = 0

count=0
vcd_file = file_read(vcd_file_path)

saifile = open(saif_file_path, 'w')

saifile.write('(SAIFILE\n')
saifile.write('(SAIFVERSION "%s")\n' % saifversion)
saifile.write('(DIRECTION "%s")\n' % direction)
saifile.write('(DESIGN "%s")\n' % design)
saifile.write('(DATE "%s")\n' % get_time_stamp())
saifile.write('(VENDOR "%s")\n' % vendor)
saifile.write('(PROGRAM_NAME "%s")\n' % program_name)
saifile.write('(VERSION "%s")\n' % version)
saifile.write('(DIVIDER %s)\n' % divider)
saifile.write('(TIMESCALE %s)\n' % timescale)
saifile.write('(DURATION %ld)\n' % duration)

for line in vcd_file:
	search = re.search(r'\$scope', line)
	if search is not None:
		ls = line.split()
		name = ls[2]
		saifile.write('%s(INSTANCE %s\n' % (saif_indent_level(text_level), name))
		text_level += 1
		level += 1
		saifile.write('%s(NET\n' % (saif_indent_level(text_level)))
		text_level += 1

		# put variables
		for var in var_list:
			if var['parent'] == name and var['level'] == level:
				if var['multi_bit'] == 0:
					saifile.write('%s(%s\n' % ( \
						saif_indent_level(text_level), \
						var['name']))
				else:
					saifile.write('%s(%s\\[%d\\]\n' % ( \
						saif_indent_level(text_level), \
						var['name'], \
						var['bit_index']))

				saifile.write('%s  (T0 %d) (T1 %d) (TX %d)\n' % ( \
					saif_indent_level(text_level), \
					var['low'], \
					var['high'], \
					var['x']))

				saifile.write('%s  (TC %d) (IG %d)\n' % ( \
					saif_indent_level(text_level), \
					var['toggle'], \
					var['ig']))

				saifile.write('%s)\n' % ( \
					saif_indent_level(text_level)))

		text_level -= 1
		saifile.write('%s)\n' % (saif_indent_level(text_level)))
		continue

	search = re.search(r'\$upscope', line)
	if search is not None:
		text_level -= 1
		level -= 1
		saifile.write('%s)\n' % (saif_indent_level(text_level)))

	if verbose:
		count+=1
		print(f'Pass #3: {count}/{total}')
		
saifile.write(')\n')
saifile.close()
	


