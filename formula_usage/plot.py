import pandas as pd

class plot():
    def __init__(self):
        dfs = []

    def setup(self,datasets: list):
        for x in datasets:
            new_df = pd.read_csv(x)
            self.dfs.appen(new_df)


        