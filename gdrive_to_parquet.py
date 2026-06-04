"""
Stream a public Google Drive CSV file directly to Parquet.
No intermediate CSV file is stored on disk.

Flow: gdown (thread) → os.pipe() → pyarrow streaming CSV reader → ParquetWriter

Usage:
    uv run python gdrive_to_parquet.py
"""

import os
import threading
import gdown
import pyarrow as pa
import pyarrow.csv as pacsv
import pyarrow.parquet as pq

GDRIVE_FILE_ID = "1N744AnNIz7GNkfBNqMAk5zru7svIWn12"
PARQUET_PATH = "data.parquet"


def stream_to_parquet() -> None:
    read_fd, write_fd = os.pipe()
    download_error = []

    def download():
        try:
            with os.fdopen(write_fd, "wb") as f:
                gdown.download(id=GDRIVE_FILE_ID, output=f, quiet=False, resume=False)
        except Exception as e:
            download_error.append(e)

    t = threading.Thread(target=download, daemon=True)
    t.start()

    writer = None
    row_count = 0
    try:
        with os.fdopen(read_fd, "rb") as f:
            reader = pacsv.open_csv(f)
            for batch in reader:
                table = pa.Table.from_batches([batch])
                if writer is None:
                    writer = pq.ParquetWriter(PARQUET_PATH, table.schema, compression="zstd")
                writer.write_table(table)
                row_count += len(batch)
                print(f"\r[convert] {row_count:,} rows written...", end="", flush=True)
    finally:
        if writer:
            writer.close()

    t.join()
    if download_error:
        raise download_error[0]

    print(f"\n[done] {row_count:,} rows → {PARQUET_PATH}")


if __name__ == "__main__":
    stream_to_parquet()
