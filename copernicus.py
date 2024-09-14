import xarray as xr
import matplotlib.pyplot as plt

file_path = 'example-modis.nc'

ds = xr.open_dataset(file_path)

print(ds)

lst_variable = ds['LST_Day_1km']

print(lst_variable)

lst_data = lst_variable.isel()

plt.figure(figsize=(10, 6))
lst_data.plot(cmap='coolwarm')
plt.title('Land Surface Temperature (LST)')
plt.show()
