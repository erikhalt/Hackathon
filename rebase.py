import pandas as pd

def load_csv(file_path):
    try:
        return pd.read_csv(file_path)
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None
    
csv_meteostat = ''
csv_copernicus = ''

df_meteo = load_csv(csv_meteostat)
df_copernicus = load_csv(csv_copernicus)

if df_meteo is not None and df_copernicus is not None:
    
    merged_df = pd.merge(df_meteo, df_copernicus, on='id', how='outer') 
    print("Merged DataFrame:")
    print(merged_df)

    
    merged_df.to_csv('merged_data.csv', index=False)
    print("Merged CSV saved as 'merged_data.csv'")