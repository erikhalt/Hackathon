from meteostat import Hourly,Point
from datetime import datetime
import matplotlib.pyplot as plt


start = datetime(2010,11,1)
end = datetime(2011,3,1)

loc = Point(59.9114,10.7579)

data = Hourly(loc,start,end)
data = data.fetch()

print(data)

data = data.iloc[:,[0]]
data = data.reset_index()
print(data)


csv_filename = 'temp.csv'
data.to_csv(csv_filename, index=False)  # 'index=True' to include the DataFrame index in the CSV

print(f"Data saved to {csv_filename}")