from pathlib import Path

import pandas
import pandas as pd

P_DATA = Path('resources/LST_MODIS_interpolated.csv')

df = pd.read_csv(P_DATA, index_col=0, header=None)

df_new_source = [['time', 'temp']]
for item in df.index:
    tokens = item.split('-')

    values = df.loc[item]
    for hour, val in enumerate(list(values)):
        time = f'2011-{tokens[0]}-{tokens[1]} {hour * 12:02d}:00:00'
        df_new_source.append([time, val - 273.15])

df_new = pandas.DataFrame(df_new_source)
df_new.to_csv('LST_MODIS.csv', index=False, header=False)
