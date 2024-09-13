import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# GDD formula: GDD = (T_max + T_min)/2 - T_base
T_Base = 10

df_hourly = pd.read_csv("meteostat tempratures.csv")

df_hourly['time'] = pd.to_datetime(df_hourly['time'])

df_hourly.set_index('time', inplace=True)

df_daily = df_hourly.resample('D').mean()
df_daily_max = df_hourly.resample('D').max()
df_daily_min = df_hourly.resample('D').min()

df_weekly = df_hourly.resample('W').mean()
df_weekly_max = df_hourly.resample('W').max()
df_weekly_min = df_hourly.resample('W').min()

print("\nHourly Data:")
print(df_hourly.head())

print("Daily Data:")
print(df_daily.head())

print("\nWeekly Data:")
print(df_weekly.head())

df_hourly.plot(title="Hourly Temperatures", figsize=(10, 6))
df_daily.plot(title="Daily Temperatures", figsize=(10, 6))
df_weekly.plot(title="Weekly Temperatures", figsize=(10, 6))

plt.show()



