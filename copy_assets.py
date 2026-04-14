import os
import glob
import shutil

source_dir = r"C:\Users\Hp\.gemini\antigravity\brain\c802d8ef-b200-43aa-a6ba-1ff11a76d827"
dest_dir = r"c:\FENG 498\feng_498\assets\crops"

png_files = glob.glob(os.path.join(source_dir, "*.png"))

for file_path in png_files:
    basename = os.path.basename(file_path)
    parts = basename.rsplit("_", 1)
    if len(parts) == 2 and parts[1].split('.')[0].isdigit():
        new_name = parts[0] + ".png"
        dest_path = os.path.join(dest_dir, new_name)
        shutil.copy2(file_path, dest_path)
        print(f"Copied {basename} to {new_name}")
