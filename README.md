# खाता (Khata)

An offline loan / sapati record-keeping app for Nepali users.
Flutter + SQLite (`sqflite`). No accounts, no cloud, no network access.
English and नेपाली. AD and BS (Bikram Sambat) dates. Android.

## Features

- Records tab: name, amount, date and status badge (Unpaid / Half Paid / Paid), with search by name or phone and sort by name, date or amount
- People tab: every person with their outstanding balance, add / edit / delete
- Person detail: summary card and the list of that person's records
- Summary tab: total given, interest accrued, paid and outstanding
- Half-paid payments: interest accrues only on the principal still remaining after each payment
- AD / BS date toggle and English / नेपाली language switch, both remembered

## Data

All data is stored on the device in a SQLite database (`khata_local.db`) with three tables: `people`, `records` and `payments`. It persists across app restarts. The release build declares no `INTERNET` permission.

## Run

```
sh setup.sh
flutter run
```
