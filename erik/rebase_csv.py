import pandas as pd


df = pd.read_csv('resources\meteostat_tempratures.csv')
df.head()


time = df["time"].to_list()
temp = df['temp'].to_list()
day_list = []
columns = ['Date',]

for indx,x in enumerate(time,start=0):
    day,hour = x.split(" ")
    columns.append(hour)
    if indx==23:
        break

for x in range(0,len(time),24):
    day,hour = time[x].split(" ")
    day_list.append(day)


print(columns)
print(day_list)



new_df = pd.DataFrame(columns=columns)
new_df['Date'] = day_list
    

print(new_df.head())