### ADR-001: POS DB is SQLite, no vendor API

- Engine confirmed: SQLite (single file, likely under %AppData%, %LocalAppData%, %ProgramData%, or the install folder).
- No official API → integration is direct SQLite read/write via the Sync Agent.
- Read menu/items/prices/availability with SELECT.
- Write online orders into a dedicated table we add ourselves (e.g. online_orders_inbox) — never into the app's own order tables blindly. A small import script/trigger (or staff "Accept" action in our admin) can then push them into the POS app's real flow if needed.
- Use WAL mode and read-only connections for read paths to avoid locking the cashier app.
- Take a file-level backup of the SQLite DB before every Sync Agent deployment / before any first-time write.
- Schema discovery: open the file with DB Browser for SQLite; run SELECT name, sql FROM sqlite_master WHERE type='table'; to dump full schema. Document mapping in a YAML config the agent loads (so different branches/POS versions can be handled without code changes).