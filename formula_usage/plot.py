import pandas as pd
import matplotlib.pyplot as plt

def plot(csv):
    csv.plot(y=['time'])
    plt.show()