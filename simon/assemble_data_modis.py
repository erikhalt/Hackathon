from collections import defaultdict
from pathlib import Path
from typing import List, Dict

import pandas as pd
import xarray as xr
from cftime import DatetimeJulian
from tqdm import tqdm

from tools.logger import logger

P_DL = Path.cwd() / 'MODIS_NC'


def get_mean_temp(subset) -> float:
    mean_value = float(subset.mean(dim=["ydim", "xdim"]))
    total_values = subset.size
    nan_values = subset.isnull().sum()
    nan_percentage = float(nan_values / total_values)

    if nan_percentage > 0.95:
        mean_value = float('nan')

    return mean_value


def main():
    files = list(sorted(P_DL.iterdir()))
    logger.info(f'Loaded {len(files)} files')

    daily_data: Dict[tuple, List[float]] = defaultdict(lambda: [float('nan') for _ in range(2)])

    for i in tqdm(range(0, len(files), 2)):
        file1 = xr.open_dataset(files[i])
        file2 = xr.open_dataset(files[i + 1])
        merged = xr.concat([file1, file2], dim='ydim')
        lst_day = merged['LST_Day_1km']
        lst_night = merged['LST_Night_1km']
        sub_day = lst_day.sel(ydim=slice(7 * 1e6, 6.25 * 1e6), xdim=slice(0.4 * 1e6, 1 * 1e6))
        sub_night = lst_night.sel(ydim=slice(7 * 1e6, 6.25 * 1e6), xdim=slice(0.4 * 1e6, 1 * 1e6))

        temp_day = get_mean_temp(sub_day)
        temp_night = get_mean_temp(sub_night)

        date: DatetimeJulian = xr.decode_cf(merged).time.values[0]
        daily_data[(date.month, date.day)][0] = temp_night
        daily_data[(date.month, date.day)][1] = temp_day

        logger.info(f'temp_day: {temp_day}, temp_night:{temp_night}')

    df_base = []

    for k in sorted(daily_data.keys()):
        row = [f'{k[0]}-{k[1]}', *daily_data[k]]
        df_base.append(row)

    df = pd.DataFrame(df_base)
    df.to_csv('resources/LST_MODIS_noisy.csv', index=False, header=False)


if __name__ == '__main__':
    main()
