from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import List

import requests
from tqdm import tqdm

from tools.logger import logger

P_MANIFEST = Path('resources/manifest_clms_global_lst_5km_v1_hourly_netcdf_latest.txt')

P_DL = Path.cwd() / 'clms_LST'

YEAR = 2011
MONTH_FROM = 2
MONTH_TO = 5


def download_file(url, destination):
    response = requests.get(url, stream=True)

    if Path(destination).exists():
        logger.error(f'{destination} already exists!')

    if response.ok:
        with open(destination, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
    else:
        logger.error(f'error downloading {url}')


def main():
    with open(P_MANIFEST, mode='r', encoding='utf-8') as f:
        records: List[str] = list(f.readlines())
        records = [rec.strip() for rec in records]

    logger.info(f'Loaded {len(records)} records')

    year_key: str = f'{YEAR}/{YEAR}'
    logger.info(f'Maching according to year: {year_key}')
    records = [rec for rec in records if year_key in rec]
    logger.info(f'Filtered {len(records)} keys')

    filtered_records = []
    for rec in records:
        tokens: List[str] = rec.split('/')
        s_date: str = tokens[8]
        month: int = int(s_date[4:6])

        if MONTH_FROM <= month <= MONTH_TO:
            filtered_records.append(rec)

    records = filtered_records
    logger.info(f'Filtered {len(records)} records between months {MONTH_FROM}--{MONTH_TO}')

    if not P_DL.exists():
        P_DL.mkdir(parents=True)

    pool = ThreadPoolExecutor(max_workers=16)
    futures = []
    for rec in records:
        destination = P_DL / Path(rec).name

        if destination.is_file():
            logger.info(f'SKIP {destination}')
            continue

        future = pool.submit(download_file, rec, destination)
        futures.append(future)

    for future in tqdm(futures):
        future.result()


if __name__ == "__main__":
    main()
