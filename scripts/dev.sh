#!/bin/bash

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly SERVICE_NAME="blog"

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado."
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose não está disponível."
        exit 1
    fi
}

start_dev() {
    print_message "Iniciando ambiente..."
    docker compose up --build -d
    print_message "Servidor em: http://localhost:1313"
}

stop_dev() {
    print_message "Parando ambiente..."
    docker compose down
}

rebuild() {
    print_message "Rebuildando..."
    docker compose down
    docker compose build --no-cache
    docker compose up -d
}

logs() {
    docker compose logs -f
}

exec_command() {
    if [ -z "${1:-}" ]; then
        print_error "Comando não especificado"
        exit 1
    fi

    print_message "Executando: $1"
    docker compose exec "$SERVICE_NAME" "$@"
}

generate_index() {
    print_message "Gerando índice..."
    docker compose exec "$SERVICE_NAME" ruby scripts/generate_index.rb
}

test_recommendations() {
    print_message "Testando recomendações cronológicas..."
    docker compose run --rm "$SERVICE_NAME" ruby scripts/test_chronological_next.rb
}

new_post() {
    # Runs locally (no Docker needed): see scripts/new_post.rb
    ruby "$(dirname "$0")/new_post.rb" "$@"
}

show_help() {
    echo "Comandos:"
    echo "  start          - Inicia o ambiente"
    echo "  stop           - Para o ambiente"
    echo "  restart        - Reinicia o ambiente"
    echo "  rebuild        - Rebuilda a imagem"
    echo "  logs           - Mostra os logs"
    echo "  exec <cmd>     - Executa comando no container"
    echo "  generate-index - Gera o índice de posts"
    echo "  test-recommendations - Testa as recomendações cronológicas"
    echo "  new-post <title> [--tags a,b] - Cria um novo post (rascunho)"
    echo "  help           - Mostra esta ajuda"
}

main() {
    case "${1:-help}" in
        new-post|help|--help|-h) ;;
        *) check_docker ;;
    esac

    case "${1:-help}" in
        start)
            start_dev
            ;;
        stop)
            stop_dev
            ;;
        restart)
            stop_dev
            start_dev
            ;;
        rebuild)
            rebuild
            ;;
        logs)
            logs
            ;;
        exec)
            shift
            exec_command "$@"
            ;;
        generate-index)
            generate_index
            ;;
        test-recommendations)
            test_recommendations
            ;;
        new-post)
            shift
            new_post "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Comando desconhecido: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
