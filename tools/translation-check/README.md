# Translation check with blind back-translation

Goal: find problems in the translations. Each translation is translated back into German by
someone (or an AI agent) who sees neither the German original nor the context. An Excel table
then puts original, translation and back-translation side by side.

The work files go to `Stuff(gitignored)/translation-check/` (not in git).

1. `powershell -ExecutionPolicy Bypass -File tools\translation-check\extract.ps1`
   writes `only-<lang>.txt` (`id<TAB>translation`, no German) and `all.json`.
2. Back-translation: each `only-<lang>.txt` is translated into German, line by line with the same
   id, into `back-<lang>.txt`. The translator must not see the German texts or the app.
   After fixing translations: compare the new `only-<lang>.txt` with the old one and back-translate
   only the changed lines into `backchanged-<lang>.txt`. Those override `back-<lang>.txt` and are
   highlighted orange in the table.
3. `powershell -ExecutionPolicy Bypass -File tools\translation-check\make-xlsx.ps1`
   builds `Stuff(gitignored)/FaceZapper-translations-backcheck.xlsx` (needs Excel; close the file first).

`context.txt` has one short description per message, in the order of the `.ts` files
(`AboutPage`, `Controller`, `DeriveNamesTableView`, `SettingsPage`, `main`). Update it when
messages are added or removed (`tools\update-translations.ps1` changes the order).

Adding a language: add it to `TRANSLATIONS` in `FaceZapper.pro` and run `tools\update-translations.ps1`.
Fill the new `.ts` with `perl tools\fill-ts.pl i18n\FaceZapper_<lang>.ts <translations.txt>`
(same `id<TAB>text` format, id = 1-based message position). Then add the code to the lists in
`controller.cpp`, `android/res/xml/locales_config.xml`, `windows/FaceZapper.iss` and the two
scripts here.
