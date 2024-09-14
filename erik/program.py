import argparse
import math
from pathlib import Path
from typing import List, Tuple

import pandas as pd

from tools.logger import logger

DATA = Path('datasets')


def gdd_sine_method(t_min: float, t_max: float, t_base: float) -> float:
    if t_max <= t_base:
        return 0
    elif t_min >= t_base:
        return (t_max + t_min) / 2 - t_base

    alpha = (t_max - t_min) / 2
    mid = (t_max + t_min) / 2

    theta_base = math.asin((t_base - mid) / alpha) if alpha != 0 else 0

    day_length_above_base = 2 * (math.pi / 2 - theta_base)
    gdd_sine = (day_length_above_base / math.pi) * ((mid - t_base) + alpha * math.sin(day_length_above_base / 2))

    return gdd_sine


def gdd(t_max: float, t_min: float, t_base: float) -> float:
    average_temp = (t_max + t_min) / 2
    daily_gdd = max(0.0, average_temp - t_base)  # Ensure GDD is not negative

    return daily_gdd


def cumulative_gdd(temperature_data: List[Tuple], t_base: float, calc_fn) -> float:
    cgdd = 0
    for T_max, T_min in temperature_data:
        daily_gdd = calc_fn(T_max[0], T_min[0], t_base)
        cgdd += daily_gdd
    return cgdd


def min_max_df(df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.DataFrame]:
    daily_max = df.resample('D').max()
    daily_min = df.resample('D').min()

    return daily_max, daily_min


def normalize_df(start: str, end: str, df: pd.DataFrame) -> pd.DataFrame:
    df['time'] = pd.to_datetime(df['time'])
    df.set_index('time', inplace=True)
    df = df.loc[start:end]
    return df


def get_different_gdds(df_max: pd.DataFrame, df_min: pd.DataFrame, t_base: float) -> Tuple[float, float]:
    _gdd = cumulative_gdd(list(zip(df_max.values, df_min.values)), t_base, gdd)
    _gdd_sine = cumulative_gdd(list(zip(df_max.values, df_min.values)), t_base, gdd_sine_method)

    return int(_gdd), int(_gdd_sine)


def main(start: str, end: str, t_base: float):
    df_cop = pd.read_csv(DATA / "LST_Copernicus.csv", )
    df_mod = pd.read_csv(DATA / "LST_MODIS.csv", )
    df_meteo = pd.read_csv(DATA / "meteostat_tempratures.csv", )

    df_cop = normalize_df(start, end, df_cop)
    df_mod = normalize_df(start, end, df_mod)
    df_meteo = normalize_df(start, end, df_meteo)

    cop_max, cop_min = min_max_df(df_cop)
    mod_max, mod_min = min_max_df(df_mod)
    meteo_max, meteo_min = min_max_df(df_meteo)

    cop_gdd, cop_gdd_sine = get_different_gdds(cop_max, cop_min, t_base)
    mod_gdd, mod_gdd_sine = get_different_gdds(mod_max, mod_min, t_base)
    meteo_gdd, meteo_gdd_sine = get_different_gdds(meteo_max, meteo_min, t_base)

    logger.info(f'Copernicus -> GDD: {cop_gdd} | Sine: {cop_gdd_sine}')
    logger.info(f'MODIS -> GDD: {mod_gdd} | Sine: {mod_gdd_sine}')
    logger.info(f'MeteoStat -> GDD: {meteo_gdd} | Sine: {meteo_gdd_sine}')

    data_out = [
        ['DataSet', 'GDD', 'GDD Sine'],
        ['Copernicus', cop_gdd, cop_gdd_sine],
        ['Modis', mod_gdd, mod_gdd_sine],
        ['Meteostat', meteo_gdd, meteo_gdd_sine],
    ]

    df_out = pd.DataFrame(data_out)
    df_out.to_csv('reCal.csv', index=False, header=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate CGDD based on input dates and base temperature")
    parser.add_argument('--start', type=str, required=True, help="Please input the start date (EX 2011-2-1 00:00:00)")
    parser.add_argument('--end', type=str, required=True, help="Please input the end date (EX 2011-2-1 00:00:00)")
    parser.add_argument('--tbase', type=float, default=5, help="Please input the T_Base (default is 5)")
    args = parser.parse_args()

    main(args.start, args.end, args.tbase)
