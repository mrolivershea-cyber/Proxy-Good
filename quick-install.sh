#!/bin/bash
# Быстрая установка Tor-SOCKS Farm
# Автоматически скачивает и устанавливает все необходимые файлы

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Tor-SOCKS Farm - Автоматическая установка             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "❌ ОШИБКА: Запустите скрипт с правами root (sudo)"
  exit 1
fi

echo "🔧 Шаг 1/6: Установка необходимых инструментов..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y wget unzip curl

echo ""
echo "📥 Шаг 2/6: Скачивание файлов проекта..."
cd /tmp
rm -f copilot-update-documentation-for-project.zip
rm -rf Proxy-Good-copilot-update-documentation-for-project

wget --show-progress -O copilot-update-documentation-for-project.zip https://github.com/mrolivershea-cyber/Proxy-Good/archive/refs/heads/copilot/update-documentation-for-project.zip

echo ""
echo "📦 Шаг 3/6: Распаковка архива..."
unzip -q copilot-update-documentation-for-project.zip

echo ""
echo "📁 Шаг 4/6: Копирование файлов в /opt..."
cd Proxy-Good-copilot-update-documentation-for-project
cp -r opt/tor-socks-farm /opt/
chmod +x /opt/tor-socks-farm/scripts/*.sh
chmod +x /opt/tor-socks-farm/firewall/*.sh

echo ""
echo "🔧 Шаг 5/6: Установка системных пакетов..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y tor 3proxy netcat-traditional jq

echo ""
echo "👤 Шаг 6/6: Создание системных пользователей..."
useradd -r -s /usr/sbin/nologin debian-tor 2>/dev/null || true
useradd -r -s /usr/sbin/nologin proxy 2>/dev/null || true

echo ""
echo "✅ Базовая установка завершена!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 СЛЕДУЮЩИЕ ШАГИ:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Полная установка системы:"
echo "   bash /opt/tor-socks-farm/scripts/install.sh"
echo ""
echo "2️⃣  Развёртывание 50 Tor-нод:"
echo "   bash /opt/tor-socks-farm/scripts/deploy_tor_instances.sh 50"
echo ""
echo "3️⃣  Развёртывание прокси-эндпоинтов:"
echo "   bash /opt/tor-socks-farm/scripts/deploy_3proxy_endpoints.sh 50"
echo ""
echo "4️⃣  Включение автоматической ротации:"
echo "   bash /opt/tor-socks-farm/scripts/enable_rotation.sh"
echo ""
echo "5️⃣  Применение правил безопасности:"
echo "   bash /opt/tor-socks-farm/firewall/hardening.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 ДОКУМЕНТАЦИЯ:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Руководства находятся в:"
echo "   /tmp/Proxy-Good-copilot-update-documentation-for-project/"
echo ""
echo "- README.md - Полное руководство (русский)"
echo "- DEPLOYMENT_GUIDE.md - Пошаговая установка"
echo "- QUICK_REFERENCE.md - Справочник команд"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Готово! Файлы установлены в /opt/tor-socks-farm/"
echo ""
