#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通用脚本：拆分中英文混合的markdown文件，下载图片并上传到OSS
"""

import os
import re
import sys
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path
from typing import List, Tuple, Dict

# 添加scripts目录到路径以导入配置
SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_ROOT = SCRIPT_DIR.parent

# 颜色输出
class Colors:
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def log_info(msg):
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")

def log_success(msg):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {msg}")

def log_warning(msg):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {msg}")

def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")

def is_chinese_text(text: str) -> bool:
    """判断文本是否主要是中文"""
    if not text.strip():
        return False
    chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', text))
    total_chars = len(re.sub(r'\s+', '', text))
    if total_chars == 0:
        return False
    return chinese_chars / total_chars > 0.3

def is_english_text(text: str) -> bool:
    """判断文本是否主要是英文"""
    if not text.strip():
        return False
    english_chars = len(re.findall(r'[a-zA-Z]', text))
    total_chars = len(re.sub(r'\s+', '', text))
    if total_chars == 0:
        return False
    return english_chars / total_chars > 0.5

def extract_frontmatter(content: str) -> Tuple[Dict, str]:
    """提取frontmatter"""
    if not content.startswith('---'):
        return {}, content
    
    parts = content.split('---', 2)
    if len(parts) < 3:
        return {}, content
    
    frontmatter_str = parts[1].strip()
    body = parts[2]
    
    # 简单的YAML解析（只处理基本格式）
    frontmatter = {}
    for line in frontmatter_str.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"')
            frontmatter[key] = value
    
    return frontmatter, body

def split_content(content: str) -> Tuple[List[str], List[str]]:
    """拆分内容为中文和英文部分"""
    lines = content.split('\n')
    chinese_lines = []
    english_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # 跳过frontmatter和图片行
        if line.strip().startswith('---') or line.strip().startswith('!['):
            # 图片行保留在两个版本中
            chinese_lines.append(line)
            english_lines.append(line)
            i += 1
            continue
        
        # 如果是空行，都保留
        if not line.strip():
            chinese_lines.append(line)
            english_lines.append(line)
            i += 1
            continue
        
        # 尝试识别整个段落（直到空行或图片）
        paragraph_lines = []
        j = i
        while j < len(lines) and lines[j].strip() and not lines[j].strip().startswith('!['):
            paragraph_lines.append(lines[j])
            j += 1
        
        paragraph = '\n'.join(paragraph_lines)
        
        # 判断段落是中文还是英文
        if is_chinese_text(paragraph):
            chinese_lines.extend(paragraph_lines)
            chinese_lines.append('')  # 添加空行分隔
        elif is_english_text(paragraph):
            english_lines.extend(paragraph_lines)
            english_lines.append('')  # 添加空行分隔
        else:
            # 不确定的内容，检查是否包含中文字符
            if re.search(r'[\u4e00-\u9fff]', paragraph):
                chinese_lines.extend(paragraph_lines)
                chinese_lines.append('')
            elif re.search(r'[a-zA-Z]', paragraph):
                english_lines.extend(paragraph_lines)
                english_lines.append('')
            else:
                # 都不包含，保留在两个版本中
                chinese_lines.extend(paragraph_lines)
                chinese_lines.append('')
                english_lines.extend(paragraph_lines)
                english_lines.append('')
        
        i = j
    
    return chinese_lines, english_lines

def extract_image_urls(content: str) -> List[str]:
    """提取所有图片URL"""
    pattern = r'!\[.*?\]\((https://[^)]+)\)'
    urls = re.findall(pattern, content)
    return list(set(urls))  # 去重

def download_image(url: str, output_dir: Path) -> Path:
    """下载图片到本地"""
    # 从URL提取文件名
    parsed_url = urllib.parse.urlparse(url)
    filename = os.path.basename(parsed_url.path)
    if not filename:
        # 如果没有文件名，使用URL的hash
        filename = f"{hash(url) % 1000000}.webp"
    
    output_path = output_dir / filename
    
    if output_path.exists():
        log_info(f"图片已存在: {filename}")
        return output_path
    
    try:
        log_info(f"下载图片: {filename}")
        urllib.request.urlretrieve(url, output_path)
        log_success(f"下载成功: {filename}")
        return output_path
    except Exception as e:
        log_error(f"下载失败 {filename}: {e}")
        return None

def load_oss_config():
    """加载OSS配置"""
    config_file = SCRIPT_DIR / 'oss_config.sh'
    if not config_file.exists():
        log_error(f"OSS配置文件不存在: {config_file}")
        return None
    
    config = {}
    with open(config_file, 'r') as f:
        for line in f:
            if 'export' in line and '=' in line:
                parts = line.split('export')[1].strip().split('=')
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = parts[1].strip().strip('"').strip("'")
                    config[key] = value
    
    return config

def update_image_links(content: str, url_mapping: Dict[str, str]) -> str:
    """更新markdown文件中的图片链接"""
    for old_url, new_url in url_mapping.items():
        content = content.replace(old_url, new_url)
    return content

def main():
    if len(sys.argv) < 2:
        log_error("用法: python3 split_markdown.py <markdown文件路径>")
        sys.exit(1)
    
    input_file = Path(sys.argv[1])
    if not input_file.is_absolute():
        input_file = PROJECT_ROOT / input_file
    
    if not input_file.exists():
        log_error(f"文件不存在: {input_file}")
        sys.exit(1)
    
    log_info(f"开始处理文件: {input_file}")
    
    # 读取文件
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 提取frontmatter和正文
    frontmatter, body = extract_frontmatter(content)
    
    # 拆分内容
    log_info("拆分中英文内容...")
    chinese_lines, english_lines = split_content(body)
    
    # 创建输出目录
    output_dir = input_file.parent
    base_name = input_file.stem
    zh_file = output_dir / f'{base_name}.zh.md'
    en_file = output_dir / f'{base_name}.en.md'
    
    # 提取图片URL
    log_info("提取图片URL...")
    image_urls = extract_image_urls(content)
    log_info(f"找到 {len(image_urls)} 张图片")
    
    # 创建临时图片目录（使用文件名作为目录名）
    img_dir = PROJECT_ROOT / 'static' / 'img' / base_name
    img_dir.mkdir(parents=True, exist_ok=True)
    
    # 下载图片
    log_info("下载图片...")
    url_mapping = {}
    
    for i, url in enumerate(image_urls, 1):
        log_info(f"处理图片 {i}/{len(image_urls)}: {url}")
        
        # 下载图片
        local_path = download_image(url, img_dir)
        if not local_path:
            continue
    
    # 上传到OSS
    oss_config = load_oss_config()
    if oss_config:
        log_info("上传图片到OSS...")
        source_path = str(img_dir)
        oss_prefix = f"blog-images/{base_name}"
        
        try:
            result = subprocess.run(
                ['bash', str(SCRIPT_DIR / 'oss_uploader.sh'), source_path, oss_prefix],
                cwd=PROJECT_ROOT,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                log_success("图片上传到OSS成功")
                # 构建URL映射
                bucket = oss_config.get('OSS_BUCKET', 'congo-blog')
                endpoint = oss_config.get('OSS_ENDPOINT', 'oss-cn-beijing.aliyuncs.com')
                oss_base_url = f"https://{bucket}.{endpoint}/blog-images"
                
                for url in image_urls:
                    filename = os.path.basename(urllib.parse.urlparse(url).path)
                    new_url = f"{oss_base_url}/{filename}"
                    url_mapping[url] = new_url
            else:
                log_warning(f"OSS上传失败: {result.stderr}")
        except Exception as e:
            log_warning(f"OSS上传异常: {e}")
    
    # 更新frontmatter
    zh_frontmatter = frontmatter.copy()
    en_frontmatter = frontmatter.copy()
    
    # 构建frontmatter字符串
    def build_frontmatter(fm):
        lines = ['---']
        for key, value in fm.items():
            lines.append(f'{key}: "{value}"')
        lines.append('---')
        return '\n'.join(lines) + '\n\n'
    
    # 写入中文版本
    zh_content = build_frontmatter(zh_frontmatter)
    zh_content += '\n'.join(chinese_lines)
    if url_mapping:
        zh_content = update_image_links(zh_content, url_mapping)
    
    with open(zh_file, 'w', encoding='utf-8') as f:
        f.write(zh_content)
    log_success(f"中文版本已保存: {zh_file}")
    
    # 写入英文版本
    en_content = build_frontmatter(en_frontmatter)
    en_content += '\n'.join(english_lines)
    if url_mapping:
        en_content = update_image_links(en_content, url_mapping)
    
    with open(en_file, 'w', encoding='utf-8') as f:
        f.write(en_content)
    log_success(f"英文版本已保存: {en_file}")
    
    log_success("处理完成！")
    log_info(f"请检查以下文件:")
    log_info(f"  中文版本: {zh_file}")
    log_info(f"  英文版本: {en_file}")

if __name__ == '__main__':
    main()
