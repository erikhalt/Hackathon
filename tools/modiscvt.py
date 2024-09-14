# Use docker ghcr.io/osgeo/gdal:ubuntu-full-3.6.3
from pathlib import Path

from modisconverter import convert_file

from tools.logger import logger

DATA_DIR = Path('MODIS_DATA')
OUT_DIR = Path('MODIS_NC')

for file in DATA_DIR.iterdir():
    dst_name = OUT_DIR / f'{file.stem}.nc'
    logger.info(f'{file} -> {dst_name}')
    convert_file(str(file), str(dst_name))
