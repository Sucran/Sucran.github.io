#!/bin/bash

# 通用图片处理脚本
# 用于下载、转换和更新markdown文件中的图片链接

# 引入通用函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 默认配置
DEFAULT_IMG_DIR="static/img"
DEFAULT_TEMP_DIR="temp_images"
DEFAULT_PREFIX="image"

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项] <文章文件> [图片前缀] [图片目录]

选项:
  -h, --help     显示此帮助信息
  -d, --dry-run  试运行模式，不实际下载图片
  -t, --temp-dir 指定临时目录 (默认: temp_images)
  -o, --output   指定输出目录 (默认: static/img)

参数:
  文章文件       要处理的markdown文件路径
  图片前缀       图片文件名前缀 (默认: image)
  图片目录       图片保存目录 (默认: static/img)

示例:
  $0 content/article.md
  $0 content/article.md myprefix
  $0 content/article.md myprefix static/images
  $0 --dry-run content/article.md
  $0 -o custom/images content/article.md

EOF
}

# 解析命令行参数
parse_args() {
    DRY_RUN="false"
    TEMP_DIR="$DEFAULT_TEMP_DIR"
    IMG_DIR="$DEFAULT_IMG_DIR"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -t|--temp-dir)
                TEMP_DIR="$2"
                shift 2
                ;;
            -o|--output)
                IMG_DIR="$2"
                shift 2
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$ARTICLE_FILE" ]; then
                    ARTICLE_FILE="$1"
                elif [ -z "$PREFIX" ]; then
                    PREFIX="$1"
                elif [ -z "$IMG_DIR" ]; then
                    IMG_DIR="$1"
                fi
                shift
                ;;
        esac
    done
}

# 处理单个图片
process_image() {
    local url="$1"
    local filename="$2"
    local counter="$3"
    local total="$4"
    
    log_info "处理第 $counter 个图片: $filename"
    
    # 显示进度
    show_progress "$counter" "$total"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[试运行] 将下载: $url"
        return 0
    fi
    
    # 下载原文件
    local temp_file="$TEMP_DIR/${filename}.webp"
    if ! download_image "$url" "$temp_file"; then
        log_error "✗ 下载失败: $filename"
        return 1
    fi
    
    # 转换为PNG格式
    local output_file="$IMG_DIR/${filename}.png"
    if ! convert_image "$temp_file" "$output_file"; then
        log_error "✗ 转换失败: $filename"
        rm -f "$temp_file"
        return 1
    fi
    
    # 更新文章中的图片引用
    local new_link="/img/$(basename "$IMG_DIR")/${filename}.png"
    update_markdown_links "$ARTICLE_FILE" "$url" "$new_link" false
    
    # 删除临时文件
    rm -f "$temp_file"
    
    log_success "✓ 已处理: $filename.png"
    return 0
}

# 主处理函数
main() {
    # 解析参数
    parse_args "$@"
    
    # 验证必需参数
    if [ -z "$ARTICLE_FILE" ]; then
        log_error "缺少必需参数: 文章文件"
        show_help
        exit 1
    fi
    
    # 设置默认值
    PREFIX="${PREFIX:-$DEFAULT_PREFIX}"
    
    # 检查文件是否存在
    check_file_exists "$ARTICLE_FILE"
    
    # 创建必要的目录
    ensure_directory "$IMG_DIR"
    ensure_directory "$TEMP_DIR"
    
    log_info "开始处理文章: $ARTICLE_FILE"
    log_info "图片将保存到: $IMG_DIR"
    log_info "图片前缀: $PREFIX"
    log_info "临时目录: $TEMP_DIR"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "运行模式: 试运行 (不会实际下载图片)"
    fi
    
    # 提取图片URL
    local url_file="$TEMP_DIR/image_urls.txt"
    local image_count=$(extract_image_urls "$ARTICLE_FILE" "$url_file")
    
    if [ "$image_count" -eq 0 ]; then
        log_info "没有找到需要处理的图片"
        cleanup_temp_dir "$TEMP_DIR"
        exit 0
    fi
    
    # 批量处理图片
    local counter=1
    local success_count=0
    
    while IFS= read -r url; do
        local filename="${PREFIX}_image${counter}"
        
        if process_image "$url" "$filename" "$counter" "$image_count"; then
            ((success_count++))
        fi
        
        ((counter++))
    done < "$url_file"
    
    # 清理临时文件
    cleanup_temp_dir "$TEMP_DIR"
    
    # 显示处理结果
    echo ""
    log_success "处理完成！成功处理 $success_count/$image_count 个图片"
    
    if [ "$DRY_RUN" = "false" ] && [ "$success_count" -gt 0 ]; then
        log_info "处理结果："
        ls -la "$IMG_DIR"
    fi
}

# 脚本入口点
main "$@"
