# Tor-SOCKS Farm Automation

Автоматическое развёртывание пула Tor-нод на сервере Linux (Ubuntu 22.04+). Каждая нода предоставляет SOCKS5-прокси с аутентификацией, ротацией IP и возможностью выбора страны выхода.

## Возможности

- ✅ Автоматическое развёртывание от 50 до 500 Tor-нод
- ✅ SOCKS5-прокси с аутентификацией для каждой ноды
- ✅ Автоматическая ротация IP-адресов по расписанию
- ✅ Выбор страны выхода для каждой ноды
- ✅ Полная изоляция DNS (без утечек)
- ✅ IPv6 отключен (без утечек)
- ✅ Управление через systemd
- ✅ CLI-скрипты для управления

## Требования

- **ОС**: Ubuntu 22.04 LTS / 24.04 LTS
- **Права**: root
- **Пакеты**: tor, 3proxy, netcat-traditional, jq (устанавливаются автоматически)

## Структура проекта

```
/opt/tor-socks-farm/
├─ scripts/              # Скрипты управления
│   ├─ install.sh       # Установка системы
│   ├─ deploy_tor_instances.sh    # Развёртывание Tor-нод
│   ├─ deploy_3proxy_endpoints.sh # Развёртывание прокси-эндпоинтов
│   ├─ rotate.sh        # Ротация IP-адресов
│   ├─ enable_rotation.sh         # Включение автоматической ротации
│   └─ tor_iptables_apply.sh      # Настройка firewall
├─ systemd/             # Systemd unit-файлы
│   ├─ tor@.service
│   ├─ 3proxy@.service
│   ├─ rotate.service
│   └─ rotate.timer
├─ config/              # Конфигурационные файлы
│   ├─ torfarm.env      # Основные параметры
│   ├─ countries.map    # Карта стран для каждой ноды
│   ├─ users.csv        # Логины и пароли
│   └─ control.password # Пароль для Tor ControlPort
├─ 3proxy/              # Шаблоны конфигураций
│   └─ instance.cfg.tpl
└─ firewall/            # Скрипты безопасности
    └─ hardening.sh
```

## Быстрый старт

### 1. Установка проекта на сервер

```bash
# Скопируйте проект в /opt
sudo mkdir -p /opt
sudo cp -r opt/tor-socks-farm /opt/

# Убедитесь, что скрипты исполняемые
sudo chmod +x /opt/tor-socks-farm/scripts/*.sh
sudo chmod +x /opt/tor-socks-farm/firewall/*.sh
```

### 2. Полное развёртывание (50 нод)

```bash
# Установка системы
sudo bash /opt/tor-socks-farm/scripts/install.sh

# Развёртывание Tor-нод
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50

# Развёртывание прокси-эндпоинтов
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50

# Включение автоматической ротации
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh

# Применение правил безопасности
sudo bash /opt/tor-socks-farm/firewall/hardening.sh
```

### 3. Проверка работы

```bash
# Проверить статус Tor-нод
sudo systemctl list-units | grep tor@

# Проверить статус прокси-эндпоинтов
sudo systemctl list-units | grep 3proxy@

# Проверить статус таймера ротации
sudo systemctl status rotate.timer

# Посмотреть логи конкретной ноды
sudo journalctl -u tor@001
sudo journalctl -u 3proxy@001
```

## Использование

### Подключение к прокси

После развёртывания доступны SOCKS5-прокси на портах 20001-20050:

```bash
# Пример подключения с curl
curl -x socks5://user001:pass001@SERVER_IP:20001 https://api.ipify.org

# Пример настройки браузера
# Прокси-сервер: SERVER_IP
# Порт: 20001
# Логин: user001
# Пароль: pass001
```

### Логины и пароли

Учётные данные находятся в файле `/opt/tor-socks-farm/config/users.csv`:

```csv
instance,user,password
001,user001,pass001
002,user002,pass002
...
```

### Настройка стран выхода

Редактируйте файл `/opt/tor-socks-farm/config/countries.map`:

```
001=us    # США
002=de    # Германия
003=gb    # Великобритания
004=*     # Любая страна
```

После изменения запустите ротацию:

```bash
sudo systemctl start rotate.service
```

### Изменение интервала ротации

Отредактируйте `/opt/tor-socks-farm/config/torfarm.env`:

```bash
ROTATE_EVERY_MIN=30  # Ротация каждые 30 минут
```

Затем примените изменения:

```bash
sudo bash /opt/tor-socks-farm/scripts/enable_rotation.sh
```

### Ручная ротация

```bash
# Запустить ротацию всех нод прямо сейчас
sudo bash /opt/tor-socks-farm/scripts/rotate.sh

# Или через systemd
sudo systemctl start rotate.service
```

## Масштабирование

### Увеличение количества нод

```bash
# Развернуть 100 нод вместо 50
sudo bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 100
sudo bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 100
```

**Важно**: 
- Максимум 500 нод (ограничение в конфигурации)
- Перед масштабированием до 100+ нод добавьте соответствующие записи в `users.csv` и `countries.map`
- Убедитесь, что сервер имеет достаточно ресурсов (ОЗУ, CPU, дескрипторы файлов)

### Генерация дополнительных пользователей

```bash
# Скрипт для генерации users.csv до 500 нод
for i in {51..500}; do
  printf "%03d,user%03d,pass%03d\n" $i $i $i
done | sudo tee -a /opt/tor-socks-farm/config/users.csv
```

## Конфигурация

### Основные параметры (torfarm.env)

| Параметр | Значение | Описание |
|----------|----------|----------|
| MIN_INSTANCES | 50 | Стартовое количество |
| MAX_INSTANCES | 500 | Максимальный лимит |
| BASE_SOCKS_PORT | 9000 | Локальные SOCKS (9001..) |
| BASE_CTRL_PORT | 9100 | ControlPort (9101..) |
| BASE_DNS_PORT | 9200 | DNSPort (9201..) |
| BASE_TRANS_PORT | 9300 | TransPort (9301..) |
| BASE_PUBLIC_PORT | 20000 | Внешние SOCKS (20001..) |
| ROTATE_EVERY_MIN | 30 | Интервал ротации (мин.) |
| DEFAULT_COUNTRY | * | Страна по умолчанию |

## Безопасность

### Реализованные меры

1. **DNS-изоляция**: Все DNS-запросы разрешены только пользователю `debian-tor`
2. **IPv6 отключен**: Предотвращение утечек через IPv6
3. **Локальные привязки**: Tor слушает только на 127.0.0.1
4. **Аутентификация**: Обязательная для всех публичных прокси
5. **Минимальные права**: Сервисы работают от непривилегированных пользователей

### Проверка безопасности

```bash
# Проверка утечек DNS
curl -x socks5://user001:pass001@localhost:20001 https://dnsleaktest.com

# Проверка IPv6
curl -x socks5://user001:pass001@localhost:20001 https://ipv6leak.com

# Проверка правил iptables
sudo iptables -L OUTPUT -n -v
```

### Откат firewall-правил

```bash
# Найти backup-файл
ls -la /root/iptables.backup.*

# Восстановить правила
sudo iptables-restore < /root/iptables.backup.TIMESTAMP
```

## Мониторинг

### Проверка статуса

```bash
# Все Tor-ноды
sudo systemctl list-units 'tor@*'

# Все прокси-эндпоинты
sudo systemctl list-units '3proxy@*'

# Статус конкретной ноды
sudo systemctl status tor@001
sudo systemctl status 3proxy@001
```

### Логи

```bash
# Логи Tor-ноды
sudo journalctl -u tor@001 -f

# Логи прокси-эндпоинта
sudo journalctl -u 3proxy@001 -f

# Логи ротации
sudo journalctl -u rotate.service -f

# Файловые логи Tor
sudo tail -f /var/log/tor/instance001.log
```

### Тестирование прокси

```bash
# Проверить доступность прокси
nc -zv 127.0.0.1 20001

# Проверить получение IP
curl -x socks5://user001:pass001@localhost:20001 https://api.ipify.org

# Проверить страну выхода
curl -x socks5://user001:pass001@localhost:20001 https://ipapi.co/json/
```

## Устранение неполадок

### Tor-нода не запускается

```bash
# Проверить статус
sudo systemctl status tor@001

# Посмотреть логи
sudo journalctl -u tor@001 -n 50

# Проверить конфигурацию
sudo tor -f /etc/tor/torrc.instance001 --verify-config

# Проверить права на каталоги
ls -la /var/lib/tor/instance001
```

### 3proxy не запускается

```bash
# Проверить статус
sudo systemctl status 3proxy@001

# Посмотреть логи
sudo journalctl -u 3proxy@001 -n 50

# Проверить конфигурацию
cat /etc/3proxy/instance001.cfg

# Проверить, запущен ли Tor
sudo systemctl status tor@001
```

### Ротация не работает

```bash
# Проверить таймер
sudo systemctl status rotate.timer

# Посмотреть когда последний запуск
sudo systemctl list-timers rotate.timer

# Запустить ротацию вручную
sudo bash /opt/tor-socks-farm/scripts/rotate.sh

# Проверить пароль ControlPort
cat /opt/tor-socks-farm/config/control.password
```

### Проблемы с производительностью

```bash
# Проверить использование ресурсов
top
htop

# Проверить лимиты дескрипторов
ulimit -n
cat /proc/sys/fs/file-max

# Увеличить лимиты (если нужно)
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
```

## Удаление

### Полное удаление системы

```bash
# Остановить и отключить все сервисы
for i in {001..050}; do
  sudo systemctl stop tor@$i 3proxy@$i
  sudo systemctl disable tor@$i 3proxy@$i
done

sudo systemctl stop rotate.timer
sudo systemctl disable rotate.timer

# Удалить systemd-юниты
sudo rm /etc/systemd/system/tor@.service
sudo rm /etc/systemd/system/3proxy@.service
sudo rm /etc/systemd/system/rotate.service
sudo rm /etc/systemd/system/rotate.timer

# Удалить конфигурации
sudo rm -rf /etc/tor/torrc.instance*
sudo rm -rf /etc/3proxy/instance*

# Удалить данные
sudo rm -rf /var/lib/tor/instance*
sudo rm -rf /var/log/tor/instance*

# Удалить проект
sudo rm -rf /opt/tor-socks-farm

# Перезагрузить systemd
sudo systemctl daemon-reload

# Откатить iptables (опционально)
sudo iptables-restore < /root/iptables.backup.TIMESTAMP
```

## Системные требования

### Минимальные (50 нод)

- **CPU**: 2-4 ядра
- **RAM**: 2-4 GB
- **Диск**: 10 GB
- **Сеть**: 10 Mbps

### Рекомендуемые (100+ нод)

- **CPU**: 8+ ядер
- **RAM**: 8+ GB
- **Диск**: 20+ GB
- **Сеть**: 100+ Mbps

### Максимальные (500 нод)

- **CPU**: 16+ ядер
- **RAM**: 32+ GB
- **Диск**: 50+ GB
- **Сеть**: 1+ Gbps

## Техническая документация

Полная техническая спецификация доступна в файле [TZ](TZ).

## Лицензия

Этот проект предназначен для образовательных целей. Используйте ответственно и в соответствии с законодательством вашей страны.

## Поддержка

При возникновении проблем:

1. Проверьте логи: `journalctl -u tor@001 -u 3proxy@001`
2. Проверьте конфигурацию: файлы в `/opt/tor-socks-farm/config/`
3. Проверьте статус сервисов: `systemctl status tor@001 3proxy@001`
4. Обратитесь к разделу "Устранение неполадок" выше

---

**Важно**: Использование Tor для обхода блокировок может быть незаконным в некоторых юрисдикциях. Убедитесь, что вы соблюдаете местное законодательство.
