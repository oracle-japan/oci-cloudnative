#!/bin/bash

# エラー発生時にスクリプトを終了
set -e

# ログ出力用の関数
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# ディレクトリとDockerfileのマッピング
declare -A DOCKERFILE_PATHS
DOCKERFILE_PATHS=(
    ["../src/api"]="Dockerfile"
    ["../src/orders"]="Dockerfile"
    ["../src/fulfillment"]="Dockerfile.jvm"
    ["../src/storefront"]="Dockerfile"
    ["../src/carts"]="Dockerfile"
)

# ディレクトリの配列
DIRECTORIES=(
    "../src/api"
    "../src/orders"
    "../src/fulfillment"
    "../src/storefront"
    "../src/carts"
)

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 結果を保存する連想配列
declare -A BUILD_RESULTS

# ディレクトリの処理
process_directory() {
    local dir="$1"
    local dockerfile_path="${dir}/${DOCKERFILE_PATHS[$2]}"
    
    # ディレクトリの存在確認
    if [ ! -d "${dir}" ]; then
        log_error "ディレクトリが存在しません: ${dir}"
        return 1
    fi

    # Dockerfileの存在確認
    if [ ! -f "${dockerfile_path}" ]; then
        log_error "Dockerfileが見つかりません: ${dockerfile_path}"
        return 1
    fi

    # ディレクトリ名からイメージ名を生成
    local image_name="$(basename "${dir}")"
    
    # Dockerfileのハッシュ値を計算
    local hash="$(sha256sum "${dockerfile_path}" | cut -c1-8)"
    
    # Dockerイメージをビルドしてタグをつける
    build_and_tag "${image_name}" "${hash}" "${dir}" "${dockerfile_path}"
    return $?
}

# Dockerイメージのビルドとタグ付け
build_and_tag() {
    local image_name="$1"
    local hash="$2"
    local context="$3"
    local dockerfile="$4"
    
    log_info "ビルド開始: ${image_name}"
    log_info "Dockerfile: ${dockerfile}"
    
    # Dockerイメージをビルド
    if ! docker build -t "${image_name}:latest" -f "${dockerfile}" "${context}"; then
        log_error "ビルド失敗: ${image_name}"
        return 1
    fi

    # ハッシュタグを付与
    if ! docker tag "${image_name}:latest" "${image_name}:${hash}"; then
        log_error "タグ付け失敗: ${image_name}:${hash}"
        return 1
    fi

    log_info "ビルド成功: ${image_name}:${hash}"
    return 0
}

# 結果の表示
display_results() {
    echo "===== ビルド結果 ====="
    for dir in "${DIRECTORIES[@]}"; do
        echo "${dir}: ${BUILD_RESULTS[$dir]}"
    done
}

# メイン処理
main() {
    # 各ディレクトリに対して処理を実行
    for dir in "${DIRECTORIES[@]}"; do
        # 絶対パスに変換
        absolute_dir="$(cd "${SCRIPT_DIR}" && cd "${dir}" 2>/dev/null && pwd)"
        
        if ! process_directory "${absolute_dir}" "${dir}"; then
            BUILD_RESULTS[$dir]="失敗"
            continue
        fi
        
        BUILD_RESULTS[$dir]="成功"
    done

    # 結果の表示
    display_results
}

# メイン処理の実行
main "$@"