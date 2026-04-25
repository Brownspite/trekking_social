import os
import re

dir_path = r'e:\trekking_social\lib'
for root, dirs, files in os.walk(dir_path):
    for f in files:
        if f.endswith('.dart'):
            file_path = os.path.join(root, f)
            with open(file_path, 'r', encoding='utf-8') as file:
                lines = file.readlines()
            new_lines = [line for line in lines if not re.match(r'^\s*//', line)]
            with open(file_path, 'w', encoding='utf-8') as file:
                file.writelines(new_lines)
