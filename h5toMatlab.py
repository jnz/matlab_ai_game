import numpy as np
# import tensorflow as tf
# from tensorflow import keras 
from keras.models import Sequential
from keras.layers import Dense
from keras.models import load_model

# This script will convert a Keras model saved in HDF5 format
# to a MATLAB script that can be used to test the model.
# The script will print the weights and biases for each layer
# but it is quite a bit taylored to the specific model I am
# using.  You will need to modify it to work with your model.

# You need to manually copy the output of this script into
# the MATLAB script: rlmain.m (function nnInit)
# Not the most elegant thing in the world, but I wanted to
# see how use a trained model outside of the Python environment.

# Print a numpy matrix as MATLAB code for copy/paste
def printMatlabMatrix(m, nameStr):
    print(nameStr + " = [ ...")
    for i in range(m.shape[0]):
        for j in range(m.shape[1]):
            print("%6.3f " % m[i, j], end="")
        if i < m.shape[0]-1:
             print("; ...")
    print(" ];")

# Print a numpy vector as MATLAB code for copy/paste
def printMatlabVector(m, nameStr):
    print(nameStr + " = [ ", end="")
    for i in range(m.shape[0]):
        print("%6.3f " % m[i], end="")
    print(" ];")

nn = load_model('mymodel.h5') # adjust filename as needed

# iterate over the layers and print the weights and biases
index = 0
for layer in nn.layers:
    weights = layer.get_weights() # list of numpy arrays
    printMatlabMatrix(weights[0], "W%i" % index)
    printMatlabVector(weights[1], "b%i" % index)
    index = index + 1

