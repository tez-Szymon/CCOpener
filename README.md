# CCOpener

Natywna aplikacja paska menu macOS do szybkiego uruchamiania Claude Code w wybranym projekcie.

## Funkcje

- ręczne dodawanie projektów,
- dodawanie folderów, których bezpośrednie podfoldery są automatycznie widoczne jako projekty,
- przypinanie ulubionych projektów na górze listy,
- wyszukiwanie po nazwie i ścieżce,
- uruchamianie `claude` w nowym oknie systemowego Terminala,
- działanie z górnego paska menu, bez dodatkowej ikony w Docku,
- lokalne zapisywanie konfiguracji.

## Uruchomienie

Wymagane są macOS 14+, Xcode Command Line Tools i zainstalowana komenda `claude`.

```bash
swift run CCOpener
```

Przy pierwszym uruchomieniu macOS może poprosić o zgodę na sterowanie aplikacją Terminal.

## Budowanie aplikacji `.app`

```bash
./scripts/build-app.sh
open dist/CCOpener.app
```

Gotową aplikację z katalogu `dist` można przenieść do `/Applications`.

## Xcode

Pakiet można otworzyć bez generowania projektu:

```bash
open Package.swift
```

Następnie wybierz schemat `CCOpener` i uruchom aplikację.
