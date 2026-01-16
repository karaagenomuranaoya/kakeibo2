import os
from pathlib import Path

def aggregate_lib_and_yaml(output_file="a.txt"):
    """
    ルートにある pubspec.yaml と、lib/ 以下のファイルをまとめて出力する。
    ただし、指定した「虎の子バックアップ」などは除外する。
    """
    
    project_root = Path.cwd()
    
    # ▼▼ 除外したいファイル（相対パス）をここに追加 ▼▼
    exclude_files = {
        'lib/data/gacha_data_backup.dart',  # 虎の子バックアップ
        'pubspec.lock',                     # これも長くなりがちなので除外推奨
    }
    
    # 対象とする拡張子
    include_extensions = {'.dart', '.yaml', '.json'}

    print(f"--- 処理開始 ---")
    
    with open(output_file, "w", encoding="utf-8") as f:
        
        # 1. pubspec.yaml の処理
        pubspec_path = project_root / 'pubspec.yaml'
        if pubspec_path.exists():
            _write_file_content(f, pubspec_path, project_root)
        
        # 2. lib/ ディレクトリ以下の処理
        lib_dir = project_root / 'lib'
        if lib_dir.exists():
            for root, dirs, files in os.walk(lib_dir):
                files.sort()
                for file in files:
                    file_path = Path(root) / file
                    
                    # 拡張子チェック
                    if not any(file.endswith(ext) for ext in include_extensions):
                        continue

                    # 相対パスを取得して除外判定
                    # WindowsでもMacでもパス区切りを '/' に統一して判定します
                    relative_path = file_path.relative_to(project_root).as_posix()
                    
                    if relative_path in exclude_files:
                        print(f"スキップ(除外): {relative_path}")
                        continue
                    
                    _write_file_content(f, file_path, project_root)
        else:
            print("警告: lib ディレクトリが見つかりません。")

    print(f"--- 作成完了: {output_file} ---")


def _write_file_content(file_handle, file_path, project_root):
    try:
        relative_path = file_path.relative_to(project_root).as_posix()
        
        lang = ''
        if file_path.suffix == '.dart':
            lang = 'dart'
        elif file_path.suffix == '.yaml':
            lang = 'yaml'
        elif file_path.suffix == '.json':
            lang = 'json'

        content = file_path.read_text(encoding="utf-8")
        
        file_handle.write(f"\n\n--- FILE: {relative_path} ---\n")
        file_handle.write(f"```{lang}\n")
        file_handle.write(content)
        file_handle.write("\n```\n")
        
        print(f"追加: {relative_path}")

    except Exception as e:
        print(f"エラー: {relative_path} の読み込みに失敗 ({e})")
        file_handle.write(f"// Error reading file: {file_path.name}\n")


if __name__ == "__main__":
    aggregate_lib_and_yaml()