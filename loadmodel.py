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

import numpy as np
# import tensorflow as tf
# from tensorflow import keras 
from keras.models import Sequential
from keras.layers import Dense
from keras.models import load_model

nn = load_model('mymodel.h5')

dataset=np.loadtxt("data.csv", delimiter=",")
# split into input (X) and output (Y) variables
xtrain=dataset[:,0:26]
ytrain=dataset[:,26:]

# set column 25 (velocity) to zero
xtrain[:,25] = 0

# Select a random subset of the training data
# to test the model
n = 50
xtest = xtrain[0:n,:]
ytest = ytrain[0:n,:]
for i in range(n):
    inputLayer = xtest[i:i+1,:]
    output = nn.predict(inputLayer)
    printMatlabMatrix(inputLayer, "inputLayer%i" % i)
    printMatlabMatrix(output, "outputLayer%i" % i)
    printMatlabMatrix(ytest[i:i+1,:], "expectedLayer%i" % i)


index = 0
for layer in nn.layers:
    weights = layer.get_weights() # list of numpy arrays
    printMatlabMatrix(weights[0], "W%i" % index)
    printMatlabVector(weights[1], "b%i" % index)
    index = index + 1

    # print("W: %i x %i" % (weights[0].shape[0], weights[0].shape[1]))
    # print(weights[0])
    # print("b: %i" % (weights[1].shape[0]))
    # print(weights[1])


# x = np.array([[ 5,40,0,10,40,0,15,40,0,20,37,10,25,40,0,30,40,0,35,19,10,40,2,10,26,10 ]]);  # expected: 1,0,0
# y = nn.predict(x);
# print("y=");
# print(y);

# x = np.array([[5, 0, 10, 10, 40, 0, 15, 40, 0, 20, 40, 0, 25, 40, 0, 30, 40, 0, 35, 36, 10, 40, 19, 10, 20, 0 ]])
# y = nn.predict(x);
# print("y=");
# print(y);

