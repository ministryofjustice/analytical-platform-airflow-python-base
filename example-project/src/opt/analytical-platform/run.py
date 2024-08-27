import sys
import tensorflow as tf

print("Python version:", sys.version)

devices = tf.config.list_physical_devices()
print("TensorFlow devices:", devices)
