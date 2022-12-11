# This script takes the actions of a human player and trains a small
# neural network to play.

import numpy as np
# import tensorflow as tf
# from tensorflow import keras 
from keras.models import Sequential
from keras.layers import Dense

# Variablen xtrain (Input, dimension XXX) u. ytrain (erwarteter Output)

dataset=np.loadtxt("humanplayer.csv", delimiter=",")
# split into input (X) and output (Y) variables
xtrain=dataset[:,0:26]  # input state
ytrain=dataset[:,26:]   # expected output action

# set column 25 (velocity) to zero, as velocity is already
# basically the output from the human player input, we don't
# want to train. This is basically a bug in the training
# data set of humanplayer.csv
xtrain[:,25] = 0

inputLayerSize = xtrain.shape[1];
outputLayerSize = ytrain.shape[1];

print("Size In: %i" % (inputLayerSize))
print("Size Out: %i" % (outputLayerSize))

x = np.array([[ 5,40,0,10,40,0,15,40,0,20,37,10,25,40,0,30,40,0,35,19,10,40,2,10,26,10]]);  # expected: 1,0,0
print(x.shape);

nn = Sequential()
nn.add(Dense(15, input_dim=inputLayerSize, kernel_initializer='normal', activation='relu'))
nn.add(Dense(outputLayerSize, kernel_initializer='normal', activation='sigmoid'))
nn.compile(optimizer='adam', loss='binary_crossentropy')
nn.fit(xtrain,ytrain,epochs=100,verbose=True) # ,batch_size=1, validation_split=0.05
nn.summary()
nn.save('mymodel.h5')
# Validate the model
nn.evaluate(xtrain,ytrain,verbose=True)
