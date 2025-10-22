#!/bin/bash

# 通用批量处理脚本
# 用于批量处理多个文件的图片下载和OSS上传

# 引入通用函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项] <操作类型> <文件模式> [参数...]

操作类型:
  process-images   批量处理图片下载和转换
  upload-oss       批量上传到OSS
  full-pipeline    完整流程：下载图片 -> 上传OSS -> 更新链接

选项:
  -h, --help     显示此帮助信息
  -d, --dry-run  试运行模式
  -v, --verbose  详细输出模式

参数:
  文件模式        文件匹配模式 (例如: content/cs231n/lec_*.md)
  其他参数        传递给具体操作脚本的参数

示例:
  $0 process-images "content/cs231n/lec_*.md"
  $0 upload-oss "static/img/cs231n/lec*_*.png" --prefix cs231n-images
  $0 full-pipeline "content/cs231n/lec_*.md" --img-dir static/img/cs231n --oss-prefix cs231n-images

EOF
}

# 解析命令行参数
parse_args() {
    DRY_RUN="false"
    VERBOSE="false"
    
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
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$OPERATION" ]; then
                    OPERATION="$1"
                elif [ -z "$FILE_PATTERN" ]; then
                    FILE_PATTERN="$1"
                else
                    EXTRA_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done
}

# 批量处理图片
batch_process_images() {
    local pattern="$1"
    shift
    local extra_args=("$@")
    
    log_info "开始批量处理图片: $pattern"
    
    local file_count=0
    local success_count=0
    
    # 查找匹配的文件
    for file in $pattern; do
        if [ -f "$file" ]; then
            ((file_count++))
            
            log_info "处理文件: $file"
            
            # 提取文件名前缀
            local basename=$(basename "$file" .md)
            local prefix=$(echo "$basename" | sed 's/\.en$//; s/\.zh$//')
            
            # 构建参数
            local args=("$file" "$prefix")
            if [ "$DRY_RUN" = "true" ]; then
                args+=("--dry-run")
            fi
            args+=("${extra_args[@]}")
            
            # 执行图片处理
            if "$SCRIPT_DIR/image_processor.sh" "${args[@]}"; then
                ((success_count++))
            else
                log_error "处理失败: $file"
            fi
            
            echo ""
        fi
    done
    
    log_success "批量图片处理完成！成功处理 $success_count/$file_count 个文件"
}

# 批量上传OSS
batch_upload_oss() {
    local pattern="$1"
    shift
    local extra_args=("$@")
    
    log_info "开始批量上传OSS: $pattern"
    
    # 构建参数
    local args=("$pattern")
    if [ "$DRY_RUN" = "true" ]; then
        args+=("--dry-run")
    fi
    args+=("${extra_args[@]}")
    
    # 执行OSS上传
    "$SCRIPT_DIR/oss_uploader.sh" "${args[@]}"
}

# 完整流程处理
full_pipeline() {
    local pattern="$1"
    shift
    local extra_args=("$@")
    
    log_info "开始完整流程处理: $pattern"
    
    # 第一步：批量处理图片
    log_info "=== 第一步：批量处理图片 ==="
    batch_process_images "$pattern" "${extra_args[@]}"
    
    echo ""
    
    # 第二步：批量上传OSS
    log_info "=== 第二步：批量上传OSS ==="
    # 从extra_args中提取图片目录
    local img_dir="static/img"
    for arg in "${extra_args[@]}"; do
        if [[ "$arg" == "--img-dir" ]] || [[ "$arg" == "-o" ]]; then
            img_dir="${extra_args[$((i+1))]}"
            break
        fi
    done
    
    batch_upload_oss "$img_dir/*" "${extra_args[@]}"
}

# 主处理函数
main() {
    # 解析参数
    parse_args "$@"
    
    # 验证必需参数
    if [ -z "$OPERATION" ]; then
        log_error "缺少必需参数: 操作类型"
        show_help
        exit 1
    fi
    
    if [ -z "$FILE_PATTERN" ]; then
        log_error "缺少必需参数: 文件模式"
        show_help
        exit 1
    fi
    
    log_info "=== 批量处理工具 ==="
    log_info "操作类型: $OPERATION"
    log_info "文件模式: $FILE_PATTERN"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "运行模式: 试运行"
    fi
    
    # 根据操作类型执行相应功能
    case "$OPERATION" in
        "process-images")
            batch_process_images "$FILE_PATTERN" "${EXTRA_ARGS[@]}"
            ;;
        "upload-oss")
            batch_upload_oss "$FILE_PATTERN" "${EXTRA_ARGS[@]}"
            ;;
        "full-pipeline")
            full_pipeline "$FILE_PATTERN" "${EXTRA_ARGS[@]}"
            ;;
        *)
            log_error "未知操作类型: $OPERATION"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口点
main "$@"
