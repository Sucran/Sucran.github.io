#!/bin/bash

# 通用脚本库 - 包含所有脚本的通用功能

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependency() {
    local cmd="$1"
    local install_guide="$2"
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd 未安装"
        if [ -n "$install_guide" ]; then
            echo "$install_guide"
        fi
        exit 1
    fi
}

# 检查文件是否存在
check_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        log_error "文件不存在: $file"
        exit 1
    fi
}

# 检查目录是否存在，不存在则创建
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_info "创建目录: $dir"
    fi
}

# 清理临时目录
cleanup_temp_dir() {
    local temp_dir="$1"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        log_info "清理临时目录: $temp_dir"
    fi
}

# 加载配置文件
load_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        log_info "加载配置文件: $config_file"
        source "$config_file"
        log_success "配置文件加载完成"
        return 0
    else
        log_warning "配置文件不存在: $config_file"
        return 1
    fi
}

# 提取图片URL
extract_image_urls() {
    local article_file="$1"
    local output_file="$2"
    local pattern="${3:-https://[^)]*\.(webp|jpg|jpeg|png)}"
    
    grep -oE "$pattern" "$article_file" > "$output_file"
    local count=$(wc -l < "$output_file")
    log_info "找到 $count 个图片URL"
    echo "$count"
}

# 下载图片
download_image() {
    local url="$1"
    local output_path="$2"
    
    curl -s -o "$output_path" "$url"
    return $?
}

# 转换图片格式 (macOS sips)
convert_image() {
    local input_path="$1"
    local output_path="$2"
    local format="${3:-png}"
    
    sips -s format "$format" "$input_path" --out "$output_path" > /dev/null 2>&1
    return $?
}

# 更新markdown文件中的链接
update_markdown_links() {
    local file="$1"
    local old_pattern="$2"
    local new_pattern="$3"
    local backup="${4:-true}"
    
    if [ "$backup" = "true" ]; then
        cp "$file" "${file}.backup"
    fi
    
    sed -i '' "s|$old_pattern|$new_pattern|g" "$file"
}

# 显示进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    
    printf "\r["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=filled; i<width; i++)); do printf " "; done
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# 显示帮助信息
show_help() {
    local script_name="$1"
    local description="$2"
    local usage="$3"
    local examples="$4"
    
    echo "用法: $script_name $usage"
    echo ""
    echo "描述: $description"
    echo ""
    if [ -n "$examples" ]; then
        echo "示例:"
        echo "$examples"
    fi
}

# 验证参数数量
validate_args() {
    local expected="$1"
    local actual="$2"
    local usage="$3"
    
    if [ "$actual" -ne "$expected" ]; then
        log_error "参数数量错误，期望 $expected 个，实际 $actual 个"
        echo "用法: $usage"
        exit 1
    fi
}

# 检查OSS配置
check_oss_config() {
    if [[ "$OSS_ENDPOINT" == "your-oss-endpoint.aliyuncs.com" ]]; then
        log_error "请先配置OSS相关参数"
        echo "请编辑脚本中的OSS配置变量或创建 oss_config.sh 配置文件"
        exit 1
    fi
}

# 配置ossutil
setup_ossutil() {
    log_info "配置ossutil..."
    
    cat > ~/.ossutilconfig << EOF
[Credentials]
language=CH
endpoint=$OSS_ENDPOINT
accessKeyID=$OSS_ACCESS_KEY_ID
accessKeySecret=$OSS_ACCESS_KEY_SECRET
region=cn-beijing
EOF
    
    log_success "ossutil配置完成"
}

# 上传文件到OSS
upload_to_oss() {
    local local_path="$1"
    local oss_path="$2"
    local dry_run="${3:-false}"
    
    if [ "$dry_run" = "true" ]; then
        log_warning "[试运行] 将上传: $local_path -> oss://$OSS_BUCKET/$oss_path"
        return 0
    fi
    
    ossutil cp "$local_path" "oss://$OSS_BUCKET/$oss_path" --force
    
    if [ $? -eq 0 ]; then
        log_success "✓ 上传成功: $oss_path"
        return 0
    else
        log_error "✗ 上传失败: $local_path"
        return 1
    fi
}
