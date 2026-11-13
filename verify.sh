#!/usr/bin/env bash
# Проверка живой Linux-ФС; не заменяется проверкой Git checkout на Windows.
set -euo pipefail
fail() { echo "FAIL: $*" >&2; exit 1; }
stage=${1:?Укажи этап 01_create, 02_copy или 04_remove}
[[ $(pwd) == "$HOME/lab0" ]] || fail 'Рабочий каталог должен быть ~/lab0'
if [[ $stage == 01_create ]]; then
  while read -r expected path; do
    line=$(ls -ld -- "$path")
    [[ ${line:0:10} == "$expected" ]] || fail "Неверные права $path"
  done <<'MODES'
drwxr-xr-x claude_monet
drwxr-x--- claude_monet/owner_office
-rw-r----- claude_monet/owner_office/owner_order
-rw-r----- claude_monet/owner_office/expense_plan
drwxr-x--- claude_monet/contracts
-rw-r----- claude_monet/contracts/supplier_contract
-rw-r----- claude_monet/contracts/concert_contract
drwxr-x--- claude_monet/advertising
-rw-r--r-- claude_monet/advertising/promo_plan
drwxr-x--- claude_monet/kitchen
-rw-r----- claude_monet/kitchen/chef_order
-rw-r--r-- claude_monet/kitchen/menu_prices
drwxr-x--- claude_monet/chef_office
-rw-r----- claude_monet/chef_office/barinov_reply
drwxr-xr-x claude_monet/hall
-rw-r--r-- claude_monet/hall/vip_guests
drwxr-x--- archive
-rw-r----- nagiev_call
MODES
  [[ $(wc -l < claude_monet/kitchen/menu_prices) == 4 ]] || fail 'menu_prices'
elif [[ $stage == 02_copy ]]; then
  [[ -L owner_contract && -L claude_monet/owner_office/hall_access ]] || fail 'Нет символических ссылок'
  [[ -f owner_contract && -d claude_monet/owner_office/hall_access ]] || fail 'Символическая ссылка не разрешается'
  read -r inode1 rest <<< "$(ls -i claude_monet/contracts/supplier_contract)"
  read -r inode2 rest <<< "$(ls -i claude_monet/contracts/supplier_duplicate)"
  [[ $inode1 == "$inode2" ]] || fail 'Различаются inode жёстких ссылок'
  [[ $(cat nagiev_call) == "$(cat claude_monet/owner_office/nagiev_call_copy)
$(cat claude_monet/kitchen/chef_order)" ]] || fail 'Содержимое дополненного nagiev_call'
  [[ $(cat claude_monet/owner_office/meeting_notes) == "$(cat claude_monet/owner_office/owner_order)
$(cat claude_monet/chef_office/barinov_reply)" ]] || fail 'Содержимое meeting_notes'
  [[ $(cat archive/promo_final) == "$(cat claude_monet/owner_office/advertising_backup/promo_plan)" ]] || fail 'Архив рекламы'
  [[ ! -e claude_monet/advertising/promo_plan ]] || fail 'promo_plan не перемещён'
elif [[ $stage == 04_remove ]]; then
  for path in claude_monet/owner_office/nagiev_call_copy owner_contract claude_monet/owner_office/hall_access claude_monet/contracts/supplier_duplicate claude_monet/hall claude_monet/advertising claude_monet/owner_office/advertising_backup; do
    [[ ! -e $path && ! -L $path ]] || fail "Не удалён $path"
  done
  [[ -f claude_monet/contracts/supplier_contract && -f archive/promo_final ]] || fail 'Удалён нужный исходный файл'
else
  fail "Неизвестный этап $stage"
fi
echo "PASS: $stage"
