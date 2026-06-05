# ki-wizard

CLI tool for generating KiCad deliverables. Tested with KiCad V9. BOM fields must be compatible with EAE libraries.

## Usage

```bash
ki-wizard <filename>
```

## Key facts

- `ki-wizard` is the main script (shell)
- `ki-wizard-bat.bat` is the Windows equivalent
- BOM field compatibility with EAE KiCad libraries is a hard requirement — incorrect fields will produce bad output silently

## In progress

A Python port is in progress on the `python` branch.
