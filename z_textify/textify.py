import os
from pathlib import Path

def textify_files():
    # --- パス設定 ---
    # スクリプトの場所 (root/z_textify) から見たルート (root) を取得
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    
    # ターゲットディレクトリ (root/lib)
    target_dir = project_root / 'lib'
    
    # 出力先 (root/z_text/combined_code.txt)
    output_dir = project_root / "z_text"
    output_file = output_dir / "combined_code.txt"

    # 出力ディレクトリ作成
    output_dir.mkdir(parents=True, exist_ok=True)

    if not target_dir.exists():
        print(f"エラー: {target_dir} フォルダが見つかりません。")
        return

    # --- ユーザー入力 ---
    print(f"Project Root: {project_root}")
    print("どのファイルをテキスト化しますか？")
    print("(例: gacha login main  ※スペース区切り、拡張子不要)")
    user_input = input(">> ").split()

    if not user_input:
        print("ファイル名が入力されませんでした。")
        return

    found_files = []

    # --- ファイルの探索 ---
    # libフォルダ内を再帰的にチェック
    all_files = list(target_dir.rglob('*'))
    
    for search_name in user_input:
        match_count = 0
        for file_path in all_files:
            # 拡張子なしのファイル名 (stem) が一致するか確認
            if file_path.is_file() and file_path.stem == search_name:
                found_files.append(file_path)
                match_count += 1
        
        if match_count == 0:
            print(f"警告: '{search_name}' に一致するファイルは見つかりませんでした。")

    if not found_files:
        print("書き出し対象のファイルがありません。終了します。")
        return

    # --- 書き出し ---
    try:
        with open(output_file, "w", encoding="utf-8") as f:
            for file_path in found_files:
                # AIがパスを理解しやすいよう、ルートからの相対パスを表示
                relative_path = file_path.relative_to(project_root)
                
                f.write("=" * 50 + "\n")
                f.write(f"PATH: {relative_path}\n")
                f.write(f"FILE: {file_path.name}\n")
                f.write("=" * 50 + "\n\n")
                
                try:
                    # file_path.read_text() でも良いが、念のため open で
                    with open(file_path, "r", encoding="utf-8") as target_f:
                        f.write(target_f.read())
                except Exception as e:
                    f.write(f"[エラー: ファイルを読み込めませんでした - {e}]\n")
                
                f.write("\n\n")

        print("-" * 30)
        print(f"完了！ {len(found_files)} 個のファイルを '{output_file}' にまとめました。")

    except Exception as e:
        print(f"書き込み中にエラーが発生しました: {e}")

if __name__ == "__main__":
    textify_files()