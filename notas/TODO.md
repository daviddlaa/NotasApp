# TODO: Fix "Guardando..." animation issue when offline

## Problem
When offline, the app waits for Firebase response, keeping the "Guardando..." animation visible.

## Solution
Save to SQLite first (instant), then upload to Firebase in background without waiting.

## Completed Steps

### Step 1: Modified `storage_service.dart`
- [x] Save to SQLite first (instant)
- [x] Upload to Firebase in background without await
- [x] Created `_syncNoteToCloudBackground()` method
- [x] Also modified `updateNote()` to use background sync

### Step 2: Modified `note_editor_page.dart`
- [x] Changed button to green "Guardar" (instant save)
- [x] Added checkmark icon for better visual feedback

### Step 3: Added automatic sync on app open
- [x] Sync pending notes when opening the app (_syncPendingNotes in home_page.dart)
