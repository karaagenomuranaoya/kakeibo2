import os

# --- 設定 ---
OUTPUT_FILE = "ai_context.txt"

# 1. AIへの指令書（プロンプト）
#    ここに「家計簿×ガチャ」というアプリの前提を追加しました。
SYSTEM_PROMPT = """
# Application Overview
This is a **Household Account Book (Kakeibo) app combined with a Gacha game element**.
- Users record daily expenses/incomes.
- Recording entries rewards users with points or tickets to spin a Gacha.
- The Gacha allows users to collect characters/items.

# Project Context for Flutter/Dart
This document provides the **Project Structure**, **Dependencies**, and **Core Logic/Data Definitions**.

## Instructions for AI
1. **Context Understanding**:
   - Use the **Tree** to understand the file organization.
   - Use the **Core Logic Files** (Models, Repositories, Services, Utils) to understand data types, global functions, and the "Kakeibo x Gacha" logic.
2. **Task Execution**:
   - I will provide the **Specific Modification Task** and the **Target Code** (UI/Widget files) in the next message.
   - When modifying the target code, assume existing custom widgets work as they are used in the snippet, unless I ask to modify them.
3. **Missing Information**:
   - If the task requires modifying a file NOT included here (e.g., a specific Custom Widget definition), **explicitly ask me to provide that file.**
   - **Do not hallucinate** methods or parameters for unknown classes.

--- START OF CONTEXT ---
"""

# 2. 必須設定ファイル
ESSENTIAL_FILES = [
    "pubspec.yaml",
    "analysis_options.yaml",
]

# 3. 重要なディレクトリ（中身を全て読み込む）
#    UI(Screens/Widgets)は除外し、ロジックの要となる部分を網羅します。
IMPORTANT_DIRS = [
    "lib/models",       # データ型
    "lib/repositories", # データの保存・取得・ガチャの処理
    "lib/services",     # アプリの機能ロジック
    "lib/utils",        # 計算処理やフォーマット関数
    "lib/constants",    # 定数
]

# ノイズ除去設定
IGNORE_DIRS = {
    ".git", ".dart_tool", ".idea", ".vscode", "build", 
    "android", "ios", "web", "macos", "linux", "windows", 
    "assets", "test", "fonts"
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
    for root, dirs, files in os.walk(startpath):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * 4 * (level)
        tree_str += '{}{}/\n'.format(indent, os.path.basename(root))
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            if is_target_file(f):
                tree_str += '{}{}\n'.format(subindent, f)
    tree_str += "```\n"
    return tree_str

def read_file_content(filepath):
    """ファイルの中身を読み込む"""
    if not os.path.exists(filepath):
        return ""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            return f"\n## File: {filepath}\n```dart\n{content}\n```\n"
    except Exception as e:
        return f"\n## File: {filepath}\n(Error reading file: {e})\n"

def main():
    print("Generating intelligent context file...")
    content = []

    # プロンプト
    content.append(SYSTEM_PROMPT)

    # Tree
    print("- Mapping Project Structure (Tree)...")
    content.append(generate_tree("."))

    # 必須ファイル
    print("- Reading Essential Configs...")
    for f in ESSENTIAL_FILES:
        content.append(read_file_content(f))

    # 重要ディレクトリの読み込み
    print("- Reading Core Logic (Models, Utils, Services, etc.)...")
    for directory in IMPORTANT_DIRS:
        if os.path.exists(directory):
            print(f"  > Inclusion: {directory}")
            for root, _, files in os.walk(directory):
                for file in files:
                    if is_target_file(file):
                        path = os.path.join(root, file)
                        content.append(read_file_content(path))

    # 書き出し
    full_text = "".join(content)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_text)

    print("-" * 30)
    print(f"DONE! Output file: {OUTPUT_FILE}")
    print(f"Estimated Token Count: ~{int(len(full_text) / 4)}")
    print("-" * 30)
    print("【次のステップ】")
    print(f"1. {OUTPUT_FILE} の中身をコピーしてAIに送信")
    print("2. 続けて「やりたいこと」と「修正したいファイルのコード」を送信")

if __name__ == "__main__":
    main()