#!/bin/bash

# 批量图片上传到阿里云OSS并修改markdown链接脚本
# 用于将本地图片上传到阿里云OSS，并更新markdown文件中的图片链接

# 配置变量 - 优先从环境变量读取，否则使用默认值
OSS_ENDPOINT="${OSS_ENDPOINT:-your-oss-endpoint.aliyuncs.com}"  # 例如: oss-cn-hangzhou.aliyuncs.com
OSS_BUCKET="${OSS_BUCKET:-your-bucket-name}"                   # 你的OSS bucket名称
OSS_ACCESS_KEY_ID="${OSS_ACCESS_KEY_ID:-your-access-key-id}"         # 你的AccessKey ID
OSS_ACCESS_KEY_SECRET="${OSS_ACCESS_KEY_SECRET:-your-access-key-secret}" # 你的AccessKey Secret
OSS_PREFIX="${OSS_PREFIX:-blog-images}"                        # OSS中的路径前缀

# 处理参数
ARTICLE_FILE=""                 # 要处理的markdown文件路径
IMG_DIR="static/img"            # 图片目录路径
DRY_RUN="false"                 # 是否为试运行模式

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}检查依赖...${NC}"
    
    # 检查ossutil是否安装
    if ! command -v ossutil &> /dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "${YELLOW}警告: ossutil 未安装 (试运行模式，跳过此检查)${NC}"
            echo "请从 https://help.aliyun.com/document_detail/120075.html 下载并安装 ossutil"
        else
            echo -e "${RED}错误: ossutil 未安装${NC}"
            echo "请从 https://help.aliyun.com/document_detail/120075.html 下载并安装 ossutil"
            exit 1
        fi
    fi
    
    # 检查配置文件
    if [[ "$OSS_ENDPOINT" == "your-oss-endpoint.aliyuncs.com" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "${YELLOW}警告: OSS配置未设置 (试运行模式，跳过此检查)${NC}"
            echo "请编辑脚本中的OSS配置变量或创建 oss_config.sh 配置文件"
        else
            echo -e "${RED}错误: 请先配置OSS相关参数${NC}"
            echo "请编辑脚本中的OSS配置变量或创建 oss_config.sh 配置文件"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}依赖检查通过${NC}"
}

# 配置ossutil
setup_ossutil() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[试运行] 跳过ossutil配置${NC}"
        return 0
    fi
    
    echo -e "${BLUE}配置ossutil...${NC}"
    
    # 创建配置文件
    cat > ~/.ossutilconfig << EOF
[Credentials]
language=CH
endpoint=$OSS_ENDPOINT
accessKeyID=$OSS_ACCESS_KEY_ID
accessKeySecret=$OSS_ACCESS_KEY_SECRET
region=cn-beijing
EOF
    
    echo -e "${GREEN}ossutil配置完成${NC}"
}

# 上传单个图片到OSS
upload_image() {
    local local_path="$1"
    local oss_path="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[试运行] 将上传: $local_path -> oss://$OSS_BUCKET/$oss_path${NC}"
        return 0
    fi
    
    # 上传文件
    ossutil cp "$local_path" "oss://$OSS_BUCKET/$oss_path" --force
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 上传成功: $oss_path${NC}"
        return 0
    else
        echo -e "${RED}✗ 上传失败: $local_path${NC}"
        return 1
    fi
}

# 更新markdown文件中的图片链接
update_markdown_links() {
    local article_file="$1"
    local old_pattern="$2"
    local new_url="$3"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[试运行] 将替换: $old_pattern -> $new_url${NC}"
        return 0
    fi
    
    # 备份原文件
    cp "$article_file" "${article_file}.backup"
    
    # 替换链接
    sed -i '' "s|$old_pattern|$new_url|g" "$article_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 链接更新成功${NC}"
        return 0
    else
        echo -e "${RED}✗ 链接更新失败${NC}"
        # 恢复备份
        mv "${article_file}.backup" "$article_file"
        return 1
    fi
}

# 处理单个markdown文件
process_article() {
    local article_file="$1"
    
    if [[ ! -f "$article_file" ]]; then
        echo -e "${RED}错误: 文件不存在: $article_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}处理文章: $article_file${NC}"
    
    # 提取文章中的所有本地图片链接（排除已经处理过的OSS链接）
    local temp_file=$(mktemp)
    grep -oE '/img/[^)]*\.(png|jpg|jpeg|gif|webp)' "$article_file" | grep -v 'https://' > "$temp_file"
    
    local image_count=$(wc -l < "$temp_file")
    echo -e "${BLUE}找到 $image_count 个本地图片链接${NC}"
    
    if [[ $image_count -eq 0 ]]; then
        echo -e "${YELLOW}没有找到需要处理的图片${NC}"
        rm "$temp_file"
        return 0
    fi
    
    # 处理每个图片
    local success_count=0
    while IFS= read -r img_path; do
        # 构建本地文件路径
        local local_file="static$img_path"
        
        if [[ ! -f "$local_file" ]]; then
            echo -e "${RED}✗ 本地文件不存在: $local_file${NC}"
            continue
        fi
        
        # 构建OSS路径
        local filename=$(basename "$img_path")
        local oss_path="$OSS_PREFIX$img_path"
        
        echo -e "${BLUE}处理图片: $filename${NC}"
        
        # 上传到OSS
        if upload_image "$local_file" "$oss_path"; then
            # 构建OSS URL
            local oss_url="https://$OSS_BUCKET.$OSS_ENDPOINT/$oss_path"
            
            # 更新markdown链接
            if update_markdown_links "$article_file" "$img_path" "$oss_url"; then
                ((success_count++))
            fi
        fi
        
    done < "$temp_file"
    
    rm "$temp_file"
    
    echo -e "${GREEN}处理完成: $success_count/$image_count 个图片成功上传并更新链接${NC}"
}

# 批量处理目录中的所有markdown文件
process_directory() {
    local img_dir="$1"
    
    echo -e "${BLUE}批量处理目录: $img_dir${NC}"
    
    # 查找所有markdown文件
    local markdown_files=$(find content -name "*.md" -type f)
    local file_count=$(echo "$markdown_files" | wc -l)
    
    echo -e "${BLUE}找到 $file_count 个markdown文件${NC}"
    
    local processed_count=0
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            echo -e "\n${BLUE}=== 处理文件 $((processed_count + 1))/$file_count ===${NC}"
            if process_article "$file"; then
                ((processed_count++))
            fi
        fi
    done <<< "$markdown_files"
    
    echo -e "\n${GREEN}批量处理完成: $processed_count/$file_count 个文件处理成功${NC}"
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [选项] [文章文件] [图片目录]"
    echo ""
    echo "选项:"
    echo "  --dry-run    试运行模式，不实际上传文件"
    echo "  --help       显示此帮助信息"
    echo ""
    echo "参数:"
    echo "  文章文件     要处理的markdown文件路径 (可选，默认处理所有markdown文件)"
    echo "  图片目录     图片目录路径 (可选，默认: static/img)"
    echo ""
    echo "示例:"
    echo "  $0 --dry-run                                    # 试运行模式，处理所有文件"
    echo "  $0 content/cources/cs231n/lec_1.zh.md          # 处理单个文件"
    echo "  $0 content/cources/cs231n/lec_1.zh.md static/img/cs231n  # 指定图片目录"
}

# 加载配置文件
load_config() {
    local config_file="oss_config.sh"
    
    if [[ -f "$config_file" ]]; then
        echo -e "${BLUE}加载配置文件: $config_file${NC}"
        source "$config_file"
        echo -e "${GREEN}配置文件加载完成${NC}"
    else
        echo -e "${YELLOW}未找到配置文件: $config_file${NC}"
        echo -e "${YELLOW}请参考 oss_config_template.sh 创建配置文件${NC}"
    fi
}

# 主函数
main() {
    # 加载配置文件
    load_config
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}未知选项: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$ARTICLE_FILE" ]]; then
                    ARTICLE_FILE="$1"
                elif [[ -z "$IMG_DIR" ]]; then
                    IMG_DIR="$1"
                fi
                shift
                ;;
        esac
    done
    
    echo -e "${BLUE}=== 阿里云OSS图片批量上传工具 ===${NC}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}运行模式: 试运行 (不会实际上传文件)${NC}"
    else
        echo -e "${GREEN}运行模式: 正式运行${NC}"
    fi
    
    # 检查依赖
    check_dependencies
    
    # 配置ossutil64
    setup_ossutil
    
    # 处理文件
    if [[ -n "$ARTICLE_FILE" ]]; then
        # 处理单个文件
        process_article "$ARTICLE_FILE"
    else
        # 批量处理所有文件
        process_directory "$IMG_DIR"
    fi
    
    echo -e "\n${GREEN}=== 处理完成 ===${NC}"
}

# 运行主函数
main "$@"
