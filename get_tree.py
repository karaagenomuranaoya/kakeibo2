import os

def generate_tree():
    output_file = "tree.txt"
    target_dir = "lib"
    yaml_file = "pubspec.yaml"
    
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(".\n")
        
        # 1. libフォルダ内のツリー構造
        if os.path.exists(target_dir):
            _walk_dir(target_dir, "", f)
        
        # 2. ルートにあるpubspec.yaml
        if os.path.exists(yaml_file):
            f.write(f"└── {yaml_file}\n")

    print(f"Done! {output_file} generated.")

def _walk_dir(directory, prefix, f):
    items = sorted(os.listdir(directory))
    for i, item in enumerate(items):
        path = os.path.join(directory, item)
        is_last = (i == len(items) - 1)
        
        # ツリーの記号を決定
        connector = "└── " if is_last else "├── "
        f.write(f"{prefix}{connector}{item}\n")
        
        if os.path.isdir(path):
            # 次の階層へのインデントを決定
            new_prefix = prefix + ("    " if is_last else "│   ")
            _walk_dir(path, new_prefix, f)

if __name__ == "__main__":
    generate_tree()