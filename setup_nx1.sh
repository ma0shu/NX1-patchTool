#!/bin/bash

set -e

# --- 配置区 ---
# 定义您的个人仓库。格式：["目标路径"]="仓库地址 Branch/Revision"
declare -A REPOS=(
    ["vendor/hardware_overlay"]="https://github.com/ma0shu/Bluefox-NX1-Overlay.git main"
    ["patches"]="https://github.com/ma0shu/NX1-patches.git main"
    ["vendor/mediatek/ims"]="https://github.com/XagaForge/android_vendor_mediatek_ims.git 16"
)
# --- 配置区结束 ---

if [ -z "$1" ]; then
  echo "错误: 请提供 ROM 源码的根目录作为参数。"
  echo "用法: bash $0 /path/to/your/rom/source"
  echo "例如: bash $0 ."
  exit 1
fi

# 脚本的根目录，也就是 nx1_tools 目录
TOOLS_DIR=$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")
# 用于存放克隆代码的临时目录
CLONES_DIR="${TOOLS_DIR}/clones"
# ROM源码的根目录，从第一个参数获取
ROM_ROOT=$(realpath "$1")

# 检查是否提供了 ROM 根目录参数
if [ -z "$ROM_ROOT" ]; then
  echo "错误: 请提供 ROM 源码的根目录作为参数。"
  echo "用法: bash $0 /path/to/your/rom/source"
  exit 1
fi

echo ">>> ROM 源码目录: ${ROM_ROOT}"
echo ">>> 工具目录: ${TOOLS_DIR}"
mkdir -p "${CLONES_DIR}"


# --- 步骤 1: 克隆或更新所有个人仓库 ---
echo ""
echo ">>> 正在克隆/更新您的个人仓库..."
for path in "${!REPOS[@]}"; do
    # 从值中分离出 URL 和 Branch
    repo_info=(${REPOS[$path]})
    repo_url=${repo_info[0]}
    repo_branch=${repo_info[1]}
    # 从 URL 中获取仓库名作为目录名
    repo_name=$(basename "${repo_url}" .git)
    clone_path="${CLONES_DIR}/${repo_name}"

    echo "--- 处理仓库: ${repo_name} ---"
    if [ -d "${clone_path}" ]; then
        echo "    仓库已存在，正在更新 (git pull)..."
        (cd "${clone_path}" && git pull)
    else
        echo "    仓库不存在，正在克隆 (git clone)..."
        git clone --depth=1 "${repo_url}" -b "${repo_branch}" "${clone_path}"
    fi
done


# --- 步骤 2: 将仓库内容同步到 ROM 源码目录 ---
echo ""
echo ">>> 正在将仓库同步到源码目录..."
for path in "${!REPOS[@]}"; do
    repo_info=(${REPOS[$path]})
    repo_url=${repo_info[0]}
    repo_name=$(basename "${repo_url}" .git)
    source_path="${CLONES_DIR}/${repo_name}"
    dest_path="${ROM_ROOT}/${path}"

    echo "--- 同步: ${source_path} -> ${dest_path} ---"
    # 确保目标父目录存在
    mkdir -p "$(dirname "${dest_path}")"
    # 使用 rsync 进行同步，它比 cp 更快、更智能，并且会删除多余的文件
    rsync -a --delete "${source_path}/" "${dest_path}/"
done

echo ""
echo ">>> 所有个人化仓库已成功设置！"