# CLAUDE.md

## Scheduled / recurring PR watch tasks

- Any repeating or scheduled PR-babysitting routine (hourly check-in loops via
  `send_later`/`create_trigger`, or similar auto-renewing background checks)
  must default to **Sonnet or Opus**, never the Fable model, unless the user
  explicitly asks for Fable.
- Before setting up a routine that will actually run under the Fable model,
  warn the user that repeated/hourly firings can burn through Fable usage
  limits quickly, and get explicit confirmation before creating it.
