# Настройка Google Drive через rclone

## Шаг 1. Установка rclone
1. Скачайте rclone: https://rclone.org/downloads/
2. Распакуйте архив и добавьте `rclone.exe` в `PATH`.

## Шаг 2. Конфигурация remote
1. Выполните команду:
   ```powershell
   rclone config
   ```
2. Создайте новый remote (например, `gdrive`).
3. Тип хранилища: Google Drive.
4. Следуйте инструкциям rclone (без передачи токенов в документации).

## Шаг 3. Проверка доступа
Проверьте, что remote работает:
```powershell
rclone lsd gdrive:
```

## Шаг 4. Настройка CIS_MAP
Откройте `config/settings.json` и укажите:
- `drive_remote`: `gdrive:` (или другое имя)
- `drive_base_game_path`: путь к большим игровым папкам
- `drive_source_max_path`: путь к источникам MAX
- `drive_source_blender_path`: путь к источникам Blender

> Везде используйте плейсхолдеры `PUT HERE`, чтобы быстро находить нужные места.
