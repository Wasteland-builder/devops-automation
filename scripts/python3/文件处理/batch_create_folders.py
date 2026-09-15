import os
from datetime import date, timedelta

start = date(2026, 9, 1)
end = date(2026, 9, 30)

current = start
while current <= end:
    folder_name = current.strftime("%Y%m%d")
    os.makedirs(folder_name, exist_ok=True)
    print(f"已创建: {folder_name}")
    current += timedelta(days=1)

print(f"\n完成！共创建 {(end - start).days + 1} 个文件夹")
