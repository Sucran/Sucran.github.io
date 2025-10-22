#!/bin/bash

# 通用OSS上传脚本
# 用于将本地文件上传到阿里云OSS并更新markdown链接

# 引入通用函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 默认配置
DEFAULT_OSS_PREFIX="blog-images"
DEFAULT_IMG_DIR="static/img"

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项] <源路径> [OSS路径前缀]

选项:
  -h, --help     显示此帮助信息
  -d, --dry-run  试运行模式，不实际上传文件
  -b, --bucket   指定OSS bucket名称
  -p, --prefix   OSS路径前缀 (默认: blog-images)
  -u, --update   上传后更新markdown文件中的链接
  -f, --file     指定要更新的markdown文件 (与--update一起使用)

参数:
  源路径         要上传的本地文件或目录路径
  OSS路径前缀    OSS中的路径前缀 (默认: blog-images)

示例:
  $0 static/img/cs231n/
  $0 static/img/cs231n/ cs231n-images
  $0 --dry-run static/img/cs231n/
  $0 -u -f content/article.md static/img/cs231n/
  $0 -b my-bucket static/img/cs231n/

环境变量:
  OSS_ENDPOINT            OSS endpoint
  OSS_BUCKET             OSS bucket名称
  OSS_ACCESS_KEY_ID      AccessKey ID
  OSS_ACCESS_KEY_SECRET  AccessKey Secret

EOF
}

# 解析命令行参数
parse_args() {
    DRY_RUN="false"
    UPDATE_LINKS="false"
    OSS_PREFIX="$DEFAULT_OSS_PREFIX"
    
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
            -b|--bucket)
                OSS_BUCKET="$2"
                shift 2
                ;;
            -p|--prefix)
                OSS_PREFIX="$2"
                shift 2
                ;;
            -u|--update)
                UPDATE_LINKS="true"
                shift
                ;;
            -f|--file)
                MARKDOWN_FILE="$2"
                shift 2
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$SOURCE_PATH" ]; then
                    SOURCE_PATH="$1"
                elif [ -z "$OSS_PREFIX" ]; then
                    OSS_PREFIX="$1"
                fi
                shift
                ;;
        esac
    done
}

# 上传单个文件
upload_single_file() {
    local local_path="$1"
    local oss_path="$2"
    
    if [ "$DRY_RUN" = "true" ]; then
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

# 上传目录
upload_directory() {
    local local_dir="$1"
    local oss_prefix="$2"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "[试运行] 将上传目录: $local_dir -> oss://$OSS_BUCKET/$oss_prefix/"
        return 0
    fi
    
    log_info "开始上传目录: $local_dir"
    
    # 使用ossutil批量上传
    ossutil cp -r "$local_dir/" "oss://$OSS_BUCKET/$oss_prefix/"
    
    if [ $? -eq 0 ]; then
        log_success "✓ 目录上传成功: $oss_prefix/"
        return 0
    else
        log_error "✗ 目录上传失败: $local_dir"
        return 1
    fi
}

# 更新markdown链接
update_markdown_links() {
    local markdown_file="$1"
    local local_dir="$2"
    local oss_prefix="$3"
    
    if [ "$UPDATE_LINKS" != "true" ] || [ -z "$markdown_file" ]; then
        return 0
    fi
    
    check_file_exists "$markdown_file"
    
    local oss_base_url="https://$OSS_BUCKET.$OSS_ENDPOINT/$oss_prefix"
    local local_img_path="/img/$(basename "$local_dir")"
    
    log_info "更新markdown文件中的图片链接: $markdown_file"
    
    # 备份原文件
    cp "$markdown_file" "${markdown_file}.backup"
    
    # 更新链接
    sed -i '' "s|$local_img_path/|$oss_base_url/|g" "$markdown_file"
    
    local updated_count=$(grep -c "$oss_base_url" "$markdown_file")
    log_success "✓ 更新了 $updated_count 个图片链接"
}

# 主处理函数
main() {
    # 解析参数
    parse_args "$@"
    
    # 验证必需参数
    if [ -z "$SOURCE_PATH" ]; then
        log_error "缺少必需参数: 源路径"
        show_help
        exit 1
    fi
    
    # 检查源路径是否存在
    if [ ! -e "$SOURCE_PATH" ]; then
        log_error "源路径不存在: $SOURCE_PATH"
        exit 1
    fi
    
    # 加载OSS配置
    load_config "$SCRIPT_DIR/oss_config.sh"
    
    # 检查OSS配置
    check_oss_config
    
    # 检查依赖
    check_dependency "ossutil" "请从 https://help.aliyun.com/document_detail/120075.html 下载并安装 ossutil"
    
    # 配置ossutil
    if [ "$DRY_RUN" != "true" ]; then
        setup_ossutil
    else
        log_warning "[试运行] 跳过ossutil配置"
    fi
    
    log_info "=== OSS文件上传工具 ==="
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "运行模式: 试运行 (不会实际上传文件)"
    else
        log_info "运行模式: 正式运行"
    fi
    
    log_info "源路径: $SOURCE_PATH"
    log_info "OSS Bucket: $OSS_BUCKET"
    log_info "OSS前缀: $OSS_PREFIX"
    
    # 执行上传
    if [ -d "$SOURCE_PATH" ]; then
        upload_directory "$SOURCE_PATH" "$OSS_PREFIX"
    else
        local filename=$(basename "$SOURCE_PATH")
        upload_single_file "$SOURCE_PATH" "$OSS_PREFIX/$filename"
    fi
    
    # 更新markdown链接
    update_markdown_links "$MARKDOWN_FILE" "$SOURCE_PATH" "$OSS_PREFIX"
    
    log_success "=== 处理完成 ==="
    
    if [ "$DRY_RUN" != "true" ]; then
        log_info "OSS访问地址: https://$OSS_BUCKET.$OSS_ENDPOINT/$OSS_PREFIX/"
    fi
}

# 脚本入口点
main "$@"
