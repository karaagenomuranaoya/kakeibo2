import os

# --- 設定 ---
# スクリプトの場所を基準にパスを解決する
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)  # 1つ上がルート
OUTPUT_FILE = os.path.join(PROJECT_ROOT, "z_text", "ai_context.txt")

# 1. AIへの指令書
SYSTEM_PROMPT = """
# Application Overview
This is a **Household Account Book (Kakeibo) app combined with a Gacha game element**.
... (省略) ...
--- START OF CONTEXT ---
"""

# 2. 必須設定ファイル (ルートからの相対パス)
ESSENTIAL_FILES = [
    "pubspec.yaml",
    "analysis_options.yaml",
]

# 3. 重要なディレクトリ (ルートからの相対パス)
IMPORTANT_DIRS = [
    "lib/models",
    "lib/repositories",
    "lib/services",
    "lib/utils",
    "lib/constants",
]

# ノイズ除去設定
IGNORE_DIRS = {
    ".git", ".dart_tool", ".idea", ".vscode", "build", 
    "android", "ios", "web", "macos", "linux", "windows", 
    "assets", "test", "fonts", "z_text", "z_textify"
}
IGNORE_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".lock", 
    ".ttf", ".otf", ".pdf", ".mp3", ".wav", ".DS_Store"
}

def is_target_file(filename):
    return not any(filename.endswith(ext) for ext in IGNORE_EXTENSIONS)

def generate_tree(startpath):
    """ディレクトリツリーを生成"""
    tree_str = "## Project Tree\n```\n"
    if not os.path.exists(startpath):
        return "## Project Tree\n(Root directory not found)\n"
        
    for root, dirs, files in os.walk(startpath):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        # 表示用にルートからの相対パスを取得
        rel_root = os.path.relpath(root, startpath)
        if rel_root == ".":
            display_name = os.path.basename(startpath) or "root"
        else:
            display_name = os.path.basename(root)
            
        level = 0 if rel_root == "." else rel_root.count(os.sep) + 1
        indent = ' ' * 4 * (level)
        tree_str += '{}{}/\n'.format(indent, display_name)
        
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            if is_target_file(f):
                tree_str += '{}{}\n'.format(subindent, f)
    tree_str += "```\n"
    return tree_str

def read_file_content(relative_path):
    """ルート基準の相対パスからファイルを読み込む"""
    full_path = os.path.join(PROJECT_ROOT, relative_path)
    if not os.path.exists(full_path):
        return f"\n## File: {relative_path}\n(File not found)\n"
    try:
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
            return f"\n## File: {relative_path}\n```dart\n{content}\n```\n"
    except Exception as e:
        return f"\n## File: {relative_path}\n(Error reading file: {e})\n"

def main():
    print(f"Project Root Detected: {PROJECT_ROOT}")

    # 出力先ディレクトリの作成 (z_text)
    output_dir = os.path.dirname(OUTPUT_FILE)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    content = []
    content.append(SYSTEM_PROMPT)

    # 1. Tree の生成 (ルートから)
    print("- Mapping Project Structure (Tree)...")
    content.append(generate_tree(PROJECT_ROOT))

    # 2. 必須ファイルの読み込み
    print("- Reading Essential Configs...")
    for f in ESSENTIAL_FILES:
        content.append(read_file_content(f))

    # 3. 重要ディレクトリの読み込み
    print("- Reading Core Logic (lib/)...")
    for directory in IMPORTANT_DIRS:
        target_path = os.path.join(PROJECT_ROOT, directory)
        if os.path.exists(target_path):
            print(f"  > Inclusion: {directory}")
            for root, _, files in os.walk(target_path):
                for file in files:
                    if is_target_file(file):
                        # ルートからの相対パスに変換して読み込む
                        rel_path = os.path.relpath(os.path.join(root, file), PROJECT_ROOT)
                        content.append(read_file_content(rel_path))
        else:
            print(f"  [Skip] Directory not found: {directory}")

    # 4. 書き出し
    full_text = "".join(content)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_text)

    print("-" * 30)
    print(f"DONE! Output file: {OUTPUT_FILE}")
    print(f"Estimated Token Count: ~{int(len(full_text) / 4)}")
    print("-" * 30)

if __name__ == "__main__":
    main()