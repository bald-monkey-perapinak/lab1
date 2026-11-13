#!/usr/bin/env bash
echo '4.1 Пять самых больших обычных файлов без copy'
ls -lR | grep '^-' | grep -v 'copy' | sort -k5,5nr | head -n 5
echo '4.2 Нагиев или Баринов, без реклам, в обратном порядке'
grep -rhiE 'нагиев|баринов' claude_monet archive | grep -vi 'реклам' | sort -r | head -n 5
echo '4.3 Число файлов со словом поставщик'
# -r не следует по встреченным внутри каталогов символическим ссылкам.
# Жёсткая ссылка является вторым именем файла и тоже учитывается.
grep -ril 'поставщик' claude_monet/contracts claude_monet/owner_office | wc -l
echo '4.4 Первая и последняя строки исходных договоров'
# Явные имена исключают добавленный supplier_duplicate.
{
  head -n 1 claude_monet/contracts/supplier_contract
  tail -n 1 claude_monet/contracts/supplier_contract
  head -n 1 claude_monet/contracts/concert_contract
  tail -n 1 claude_monet/contracts/concert_contract
} | grep -iE 'поставщик|музыкант|оплат' | sort
echo '4.5 Число слов в выбранных строках meeting_notes'
grep -v 'согласен' claude_monet/owner_office/meeting_notes | grep -E 'меню|кухн' | sort -r | wc -w
echo '4.6 Символические ссылки по имени в обратном порядке'
ls -lR | grep '^l' | sort -k9,9r
echo '4.7 Число слов о рекламе без имени Нагиев'
# Здесь отсутствие выбранных строк ожидаемо. Код grep 1 не является ошибкой;
# ошибки чтения (код 2) по-прежнему останавливают запуск с pipefail.
grep -h 'реклам' claude_monet/owner_office/advertising_backup/* | { grep -v 'Нагиев' || [[ $? -eq 1 ]]; } | sort | wc -w
