# getAllMisspelledWords
crysman (copyleft) 2021

- hnusně zbastlený rychloskript na nalezení nečeských (resp. neslovníkových dle `aspell`) slov na faktaoklimatu.cz
- kontroluje mutace cs,en a přiložený `.pws` custom slovník, kam je třeba vkládat přes přiložený skriptík nová legit slova (př: `./addWord.sh povolenkový`)

prereqs:
- `wget`
- `aspell`
- `elinks`
- write perms to `/tmp`

optional:
- `aha` (to save as colorized html output)
