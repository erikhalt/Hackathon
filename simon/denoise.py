import sys
from pathlib import Path

import pandas as pd

P_DATABASE = Path(sys.argv[1])
P_OUT = Path(sys.argv[2])


def main():
    df = pd.read_csv(P_DATABASE, index_col=0, header=None)
    df = df.interpolate(method='linear')

    df = df.interpolate(method='linear', axis=1)
    df.to_csv(P_OUT, header=False)


if __name__ == '__main__':
    main()
