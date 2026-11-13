#!/usr/bin/env bash
# Обвязка запуска; решения пунктов находятся в scripts/01..04.
set -euo pipefail
export LC_ALL=C.UTF-8
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ -e "$HOME/lab0" || -L "$HOME/lab0" ]]; then
  echo 'Остановка: ~/lab0 уже существует. Сохрани предыдущую работу; скрипт её не перезаписывает.' >&2
  exit 1
fi
if [[ -e "$source_dir/evidence/01_create.log" ]]; then
  echo 'Остановка: логи предыдущего выполнения уже существуют.' >&2
  exit 1
fi
export GIT_AUTHOR_NAME='Жуков Никита Андреевич'
export GIT_AUTHOR_EMAIL='262412475+bald-monkey-perapinak@users.noreply.github.com'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
mkdir -p "$source_dir/evidence"
mkdir "$HOME/lab0"
cd "$HOME/lab0"
git init -b execution
# Git не хранит rwx, каталоги без файлов и отношения жёстких ссылок.
# Авторитетная проверка прав и inode — логи живой файловой системы.
for stage in 01_create 02_copy 03_search 04_remove; do
  echo "Выполняется $stage"
  bash -euxo pipefail "$source_dir/scripts/$stage.sh" > "$source_dir/evidence/$stage.log" 2>&1
  cat "$source_dir/evidence/$stage.log"
  case "$stage" in
    01_create) message='Create variant 11 tree and set access permissions' ;;
    02_copy) message='Copy files create links and move advertising plan' ;;
    03_search) continue ;;
    04_remove) message='Complete queries and remove specified files and links' ;;
  esac
  git status
  git add .
  git commit -m "$message"
done
git log --oneline > "$source_dir/evidence/git-history.log"
git status --porcelain > "$source_dir/evidence/git-status.log"
echo 'Завершены все локальные пункты варианта 11. Для публикации см. README.'
