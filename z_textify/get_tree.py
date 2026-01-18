import os
from pathlib import Path

def generate_tree():
    # --- パス設定 ---
    # スクリプトの場所 (root/z_textify) から見たルート (root) を取得
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    
    # 出力先 (root/z_text/tree.txt)
    output_dir = project_root / "z_text"
    output_file = output_dir / "tree.txt"
    
    # 出力ディレクトリ作成
    output_dir.mkdir(parents=True, exist_ok=True)

    # ターゲット
    lib_dir = project_root / "lib"
    yaml_file = project_root / "pubspec.yaml"
    
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(".\n")
        
        # 1. libフォルダ内のツリー構造を再帰的に取得
        if lib_dir.exists():
            f.write("├── lib/\n")
            # libの中身なので、接頭辞に "│   " を渡して開始
            _walk_dir(lib_dir, "│   ", f)
        
        # 2. ルートにある主要ファイルの表示
        if yaml_file.exists():
            f.write(f"└── {yaml_file.name}\n")

    print(f"Done! {output_file} generated.")

def _walk_dir(directory, prefix, f):
    # 無視するディレクトリ（必要に応じて追加）
    ignore_dirs = {'.DS_Store', '__pycache__'}
    
    items = sorted([item for item in os.listdir(directory) if item not in ignore_dirs])
    
    for i, item in enumerate(items):
        path = os.path.join(directory, item)
        is_last = (i == len(items) - 1)
        
        # ツリーの記号
        connector = "└── " if is_last else "├── "
        
        # ディレクトリの場合は末尾に / を付ける
        display_name = item + "/" if os.path.isdir(path) else item
        f.write(f"{prefix}{connector}{display_name}\n")
        
        if os.path.isdir(path):
            # 次の階層へのインデント設定
            new_prefix = prefix + ("    " if is_last else "│   ")
            _walk_dir(path, new_prefix, f)

if __name__ == "__main__":
    generate_tree()