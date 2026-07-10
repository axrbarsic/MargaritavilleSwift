# Установка на iPhone по Wi-Fi

## Нормальный Путь

Для уже спаренного iPhone повторное подключение кабеля и включённый экран обычно
не требуются. Основная команда проекта:

```sh
Tools/install_on_iphone.sh
```

Скрипт проверяет CoreDevice до сборки, при необходимости один раз перезапускает
пользовательские discovery-сервисы, затем собирает, устанавливает и запускает
приложение.

## Симптом Зависшего Discovery

- `xcrun devicectl list devices` показывает `unavailable`.
- iPhone находится в той же подсети и отвечает по сети.
- TCP-порт lockdown `62078` доступен.
- `_apple-mobdev2._tcp` временно отсутствует в Bonjour.

В таком состоянии pairing и Developer Mode могут быть исправны. Не нужно сразу
удалять доверие, менять bundle ID или заново настраивать provisioning.

## Безопасное Восстановление

Перезапустить только пользовательские XPC-сервисы CoreDevice:

```sh
launchctl kickstart -k user/$(id -u)/com.apple.CoreDevice.CoreDeviceService
launchctl kickstart -k user/$(id -u)/com.apple.CoreDevice.remotepairingd
xcrun devicectl list devices
```

Важно использовать домен `user/$(id -u)`, а не `gui/$(id -u)`: CoreDevice XPC
зарегистрирован именно в пользовательском launchd-домене.

## Диагностика Сети

```sh
xcrun xcdevice list --timeout 10
arp -a
ping -c 3 <iphone-ip>
nc -vz -w 3 <iphone-ip> 62078
```

Если телефон не отвечает по IP или отсутствует в ARP, проблема уже не в
CoreDevice: проверить Wi-Fi телефона, подсеть/VLAN и client isolation роутера.
