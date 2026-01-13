import os
import zipfile
from pathlib import Path

def create_flutter_zip(output_filename="flutter_project.zip"):
    # 除外ディレクトリ（Flutter特有の巨大な生成物を除外）
    exclude_dirs = {
        '.git', '.dart_tool', 'build', 'ios', 'android', 
        'windows', 'linux', 'macos', '.idea', '.vscode'
    }
    # 除外ファイル
    exclude_files = {'.DS_Store', output_filename, 'extract_flutter.py'}

    print(f"Archiving to: {output_filename}...")
    
    with zipfile.ZipFile(output_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk('.'):
            # 除外ディレクトリをスキップ
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file in exclude_files:
                    continue
                
                file_path = os.path.join(root, file)
                # ★ここが重要：相対パスを維持して、フォルダ構造を保つ
                arcname = os.path.relpath(file_path, '.')
                
                zipf.write(file_path, arcname)
                print(f"  Added: {arcname}")

    print(f"\nDone! Upload {output_filename} to AI Studio.")

if __name__ == "__main__":
    create_flutter_zip()