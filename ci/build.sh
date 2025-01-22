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

# ディレクトリの配列
DIRECTORIES=(
    "../src/api"
    "../src/carts"
    "../src/orders"
    "../src/fulfillment"
)

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 結果を保存する連想配列
declare -A BUILD_RESULTS

# メイン処理
main() {
    # 各ディレクトリに対して処理を実行
    for dir in "${DIRECTORIES[@]}"; do
        # 絶対パスに変換
        absolute_dir="$(cd "${SCRIPT_DIR}" && cd "${dir}" && pwd)"
        
        if ! process_directory "${absolute_dir}"; then
            BUILD_RESULTS["${dir}"]="失敗"
            continue
        fi
        
        BUILD_RESULTS["${dir}"]="成功"
    done

    # 結果の表示
    display_results
}

# ディレクトリの処理
process_directory() {
    local dir="$1"
    local dockerfile="${dir}/Dockerfile"
    
    # ディレクトリの存在確認
    if [ ! -d "${dir}" ]; then
        log_error "ディレクトリが存在しません: ${dir}"
        return 1
    fi

    # Dockerfileの存在確認
    if [ ! -f "${dockerfile}" ]; then
        log_error "Dockerfileが見つかりません: ${dockerfile}"
        return 1
    }

    # ディレクトリ名からイメージ名を生成
    local image_name="$(basename "${dir}")"
    
    # Dockerfileのハッシュ値を計算
    local hash="$(sha256sum "${dockerfile}" | cut -c1-8)"
    
    # Dockerイメージをビルドしてタグをつける
    if ! build_and_tag "${image_name}" "${hash}" "${dir}"; then
        return 1
    fi

    return 0
}

# Dockerイメージのビルドとタグ付け
build_and_tag() {
    local image_name="$1"
    local hash="$2"
    local context="$3"
    
    log_info "ビルド開始: ${image_name}"
    
    # Dockerイメージをビルド
    if ! docker build -t "${image_name}:latest" "${context}"; then
        log_error "ビルド失敗: ${image_name}"
        return 1
    fi

    # ハッシュタグを付与
    if ! docker tag "${image_name}:latest" "${image_name}:${hash}"; then
        log_error "タグ付け失敗: ${image_name}:${hash}"
        return 1
    }

    log_info "ビルド成功: ${image_name}:${hash}"
    return 0
}

# 結果の表示
display_results() {
    echo "===== ビルド結果 ====="
    for dir in "${DIRECTORIES[@]}"; do
        echo "${dir}: ${BUILD_RESULTS["${dir}"]}"
    done
}

# メイン処理の実行
main "$@"