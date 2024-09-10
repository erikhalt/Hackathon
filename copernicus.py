import xarray as xr
import matplotlib.pyplot as plt

file_path = './c_gls_LST_202409100000_GLOBE_GEO_V2.1.2_CZ0_LST.nc'

ds = xr.open_dataset(file_path)

print(ds)

lst_variable = ds['LST']

print(lst_variable)

lst_data = lst_variable.isel(time=0)

plt.figure(figsize=(10, 6))
lst_data.plot(cmap='coolwarm')
plt.title('Land Surface Temperature (LST)')
plt.show()
