from collections import defaultdict
from pathlib import Path
from typing import List, Dict

import pandas as pd
import xarray as xr
from tqdm import tqdm

from tools.logger import logger

LAT_MIN = 56.5811257052445
LAT_MAX = 62.58388786908255

LONG_MIN = 6.79013731297628
LONG_MAX = 16.263719829170924

P_DL = Path.cwd() / 'clms_LST'


def main():
    files = list(sorted(P_DL.iterdir()))
    logger.info(f'Loaded {len(files)} files')

    daily_data: Dict[tuple, List[float]] = defaultdict(lambda: [float('nan') for _ in range(24)])

    for path_nc in tqdm(files):
        ds = xr.open_dataset(path_nc)
        lst = ds['LST']
        subset = lst.sel(lat=slice(LAT_MAX, LAT_MIN), lon=slice(LONG_MIN, LONG_MAX))

        mean_value = float(subset.mean(dim=["lat", "lon"]))
        total_values = subset.size
        nan_values = subset.isnull().sum()
        nan_percentage = float(nan_values / total_values)
        date = pd.Timestamp(xr.decode_cf(ds).time.values[0])

        if nan_percentage > 0.95:
            mean_value = float('nan')

        hour = int(date.hour)

        daily_data[(date.month, date.day)][hour] = mean_value

    df_base = []

    for k in sorted(daily_data.keys()):
        row = [f'{k[0]}-{k[1]}', *daily_data[k]]
        df_base.append(row)

    df = pd.DataFrame(df_base)
    df.to_csv('resources/LST_noisy.csv', index=False, header=False)


if __name__ == '__main__':
    main()
