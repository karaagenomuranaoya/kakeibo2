import os
from pathlib import Path

def aggregate_flutter_code(output_file="all_code.txt"):
    # 除外ディレクトリ
    exclude_dirs = {'.git', '.dart_tool', 'build', 'ios', 'android', 'windows', 'linux', 'macos'}
    # 対象とする拡張子
    include_extensions = {'.dart', '.yaml', '.json'}

    project_root = Path.cwd()
    
    with open(output_file, "w", encoding="utf-8") as f:
        for root, dirs, files in os.walk(project_root):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if any(file.endswith(ext) for ext in include_extensions):
                    file_path = Path(root) / file
                    relative_path = file_path.relative_to(project_root)
                    
                    # AIがファイル境界を認識しやすいようにフォーマット
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