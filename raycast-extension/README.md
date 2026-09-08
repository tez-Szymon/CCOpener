# CCOpener for Raycast

Lokalne rozszerzenie Raycast pokazujące projekty skonfigurowane w CCOpener.

## Instalacja

1. Zbuduj CCOpener poleceniem `./scripts/build-app.sh`.
2. Przenieś `dist/CCOpener.app` do `/Applications` i uruchom aplikację przynajmniej raz.
3. W katalogu głównym repozytorium uruchom `./scripts/install-raycast-extension.sh`.
4. Gdy komenda pojawi się w Raycast, możesz zatrzymać proces developerski skrótem `Control-C`. Rozszerzenie pozostanie dostępne lokalnie.

W Raycast wyszukaj komendę **Open Claude Code Project**. Możesz przypisać jej alias lub globalny skrót klawiszowy w ustawieniach Raycast.

Pole `author` w `package.json` jest potrzebne głównie do walidacji i publikowania w Raycast Store. Jeśli chcesz uruchamiać `npm run lint` lub publikować rozszerzenie, wpisz tam swój Raycast Store handle.

CCOpener zapisuje listę projektów w `~/Library/Application Support/CCOpener/projects.json`. Rozszerzenie odczytuje wyłącznie ten plik i uruchamia wybrany projekt przez deeplink `ccopener://`.
