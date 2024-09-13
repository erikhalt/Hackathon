from pathlib import Path

import pandas as pd

P_DATABASE = Path('resources/LST_noisy.csv')
P_OUT = Path('resources/LST_interpolated.csv')


def main():
    df = pd.read_csv(P_DATABASE, index_col=0, header=None)
    df = df.interpolate(method='linear')

    df = df.interpolate(method='linear', axis=1)
    df.to_csv(P_OUT, header=False)


if __name__ == '__main__':
    main()
