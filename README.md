# CIS_MAP — мастер настройки рабочего окружения (GTA:SA)

Этот репозиторий — единственная точка входа для разработчиков карты. Запуск мастера:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\wizard.ps1
```

## Быстрый старт (Mock)
1. Склонируйте репозиторий `CIS_MAP`.
2. Запустите мастер `scripts/wizard.ps1`.
3. Выберите `mode: mock` (значение по умолчанию в `config/settings.example.json`).
4. Следуйте вопросам мастера — он создаст локальные папки, наполнит их мок-данными и синхронизирует общие текстуры.

## Как перейти в режим Drive
1. Установите и настройте rclone (см. `docs/DRIVE_SETUP.md`).
2. Скопируйте `config/settings.example.json` в `config/settings.json`.
3. Вставьте реальные значения в `settings.json`:
   - `game_repo_url`: URL репозитория `CIS_GAME` (PUT HERE).
   - `drive_remote`: имя rclone-remote (PUT HERE).
   - `drive_base_game_path`, `drive_source_max_path`, `drive_source_blender_path`: пути на Google Drive (PUT HERE).
4. Измените `mode` на `drive`.

## Где что хранится (Git vs Drive)
- **Git (CIS_MAP):** скрипты, манифесты `.example.json`, общие текстуры `assets_textures`, документация.
- **Google Drive (Drive mode):** большие игровые файлы и исходники сцен (MAX/Blender).
- **Локально (по умолчанию в этой папке):** `./CIS_GAME`, `./_source`, `./_cache` (не коммитятся).

## Ручной экспорт
Экспорт DFF/COL/TXD не автоматизирован. После экспорта вручную копируйте файлы в:
- `./CIS_GAME/gta/models` или
- `./CIS_GAME/modloader/DEV_MIAMI` (пример, замените на ваш мод-путь).

## Локальный тест (Mock)
Команды:
```powershell
# 1) git clone CIS_MAP
# 2) cd CIS_MAP
powershell -ExecutionPolicy Bypass -File .\scripts\wizard.ps1
```
Ответы для теста:
- DirectPlay: **No** (если нет прав администратора)
- Setup game: **Yes**
- Download big files: **Yes**
- Setup sources: **Yes**, выбрать **Both**

Ожидаемый результат:
- `./CIS_GAME` создан (stub, если нет доступа к удалённому репо)
- `./CIS_GAME/gta/audio` и др. заполнены из `mock_drive`
- `./_source/max` и `./_source/blender` заполнены
- `./_source/_shared_textures` синхронизирован из `assets_textures`

Подробнее о рабочих сценариях — в `docs/WORKFLOWS.md`.
