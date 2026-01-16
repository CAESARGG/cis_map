# Рабочие сценарии

## Ежедневный запуск
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\wizard.ps1
```

## Обновление игровых файлов (Drive mode)
1. Включите `mode: drive` в `config/settings.json`.
2. Запустите мастер и выберите обновление больших папок.

## Обновление исходников сцен
1. Запустите мастер.
2. Выберите DCC: 3ds Max / Blender / Both.
3. Синхронизация произойдёт в `../_source`.

## Синхронизация общих текстур
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync_shared_textures.ps1
```

## Диагностика
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```
