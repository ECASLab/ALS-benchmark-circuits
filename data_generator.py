'''
Data_Generator:
A set of random dataset generation functions for circuits

'''
import math
from random import *
import numpy as np


def dataset_gen(file:str, inputs: list, samples :int, distribution='uniform',**kwargs):
    '''

    Generates a file with columns of random data, corresponding to n-bits circuit inputs.
    Data are stored in Hex numbers.

    :param file: File to save the dataset.
    :param inputs: A list of number of bits for each input. For each number n in the list,
                   a column of n bits numbers will be generated, corresponding to each input.
    :param samples: How many samples of input data to generate.
    :param distribution: Desired distribution of probability for the random data.
                         could be: 'uniform'(default), 'normal','triangular',...
    :param kwargs: Additional parameters for uniform distributions. For example:
                   mean: Data mean for normal distribution. Behaves as peak for some distributions.
                   variance: Data variance for the normal distribution.
                   min: minimum allowed number. Behaves as lower threshold for some distributions.
                   max: maximum allowed number. Behaves as upper threshold for some distributions.
    :return: path to generated file
    '''
    text=''
    data=[]
    for n in inputs:
        s=get_random(n,distribution,samples,**kwargs)
        data.append([hex(i)[2:] for i in s])
    data=list(zip(*data))
    file=np.savetxt(file, data, fmt='%s')

    return file

def get_random(bits: int, distribution='uniform', samples=1, **kwargs):
    '''

    Generates a random number according to a probability distribution.

    :param bits: Number of bits for generated data.
    :param distribution: Desired distribution of probability for the random data.
                         could be: 'uniform'(default), 'normal','triangular',...
    :param samples: How many data samples to generate. Default:1
    :param kwargs: Additional parameters for uniform distributions. For example:
                   median: Data median for normal distribution. Behaves as peak for some distributions.
                   variance: Data variance for the normal distribution.
                   low_limit: minimum allowed number. Behaves as lower threshold for some distributions.
                   high_limit: maximum allowed number. Behaves as upper threshold for some distributions.

    :return: a random integer that follows the given distribution
    '''

    '''Pasing kwargs'''
    if not 'low_limit' in kwargs:
        low_limit=0 #Lower threshold for generated numbers
    else:
        low_limit=np.min([kwargs['low_limit'],2**bits])
    if not 'high_limit' in kwargs:
        high_limit=2**bits #Upper threshold for the generated data
    else:
        high_limit=np.min([kwargs['high_limit'],2**bits])
    if not 'median' in kwargs:
        median=(high_limit+low_limit)/2
    else:
        median=kwargs['median']
    if not 'variance' in kwargs:
        variance=1
    else:
        variance=kwargs['variance']

    '''Distributions case'''
    data=[]
    if distribution in {'uniform', 'rectangular'}:
        data=[int(math.floor(uniform(low_limit,high_limit))) for i in range(samples)]
    elif distribution=='triangular':
        data=[int(math.floor(triangular(low_limit,high_limit,mode=median))) for i in range(samples)]
    elif distribution in {'normal', 'gaussian'}:
        while len(data)<samples:
            i=int(math.floor(gauss(median,variance)))
            if low_limit<=i<=high_limit: data.append(i)
    else:
        raise ValueError(f'{distribution} is not a valid distribution name')

    return data

# from matplotlib import pyplot as plt
# from scipy.interpolate import UnivariateSpline
# path='/home/roger/Desktop/Electronica/ALS-benchmark-circuits/sample.txt'
# dataset_gen(path,[1,2,3,4,5,6,7,8],samples=1000000,distribution='uniform', variance=1)

# data=np.loadtxt(path)
# data=np.transpose(data)


# N=1000
# n=N//1
# for d in data:
#     p,x=np.histogram(d,bins=n)
#     x=x[:-1]+(x[1]-x[0])/2
#     f=UnivariateSpline(x,p,s=n)
#     plt.plot(x,f(x))
#     plt.show()

