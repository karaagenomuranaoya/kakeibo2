import os
from pathlib import Path

def aggregate_flutter_code():
    # --- パス設定 ---
    # スクリプトの場所 (root/z_textify) から見たルート (root) を取得
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    
    # 出力ファイルパス (root/z_text/all_code.txt)
    output_dir = project_root / "z_text"
    output_file = output_dir / "all_code.txt"

    # 出力ディレクトリが存在しない場合は作成
    output_dir.mkdir(parents=True, exist_ok=True)

    # --- 除外設定 ---
    exclude_dirs = {
        '.git', '.dart_tool', 'build', 'ios', 'android', 
        'windows', 'linux', 'macos', 'z_textify', 'z_text'
    }
    
    exclude_files = {
        'lib/data/gacha_data_backup.dart',
        'pubspec.lock',
    }
    
    include_extensions = {'.dart', '.yaml', '.json'}

    print(f"Project Root: {project_root}")
    print(f"Output File: {output_file}")

    with open(output_file, "w", encoding="utf-8") as f:
        # project_root を起点に探索
        for root, dirs, files in os.walk(project_root):
            # 除外ディレクトリのスキップ
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                file_path = Path(root) / file
                
                # プロジェクトルートからの相対パスを計算
                try:
                    relative_path = file_path.relative_to(project_root)
                except ValueError:
                    continue

                # 除外条件の判定
                if str(relative_path).replace(os.sep, '/') in exclude_files:
                    continue
                if not any(file.endswith(ext) for ext in include_extensions):
                    continue
                
                # 書き込み
                f.write(f"\n\n--- FILE: {relative_path} ---\n")
                f.write("```dart\n" if file.endswith('.dart') else "```\n")
                try:
                    f.write(file_path.read_text(encoding="utf-8"))
                except Exception as e:
                    f.write(f"// Error reading file: {e}")
                f.write("\n```\n")

    print(f"作成完了: {output_file}")

if __name__ == "__main__":
    aggregate_flutter_code()