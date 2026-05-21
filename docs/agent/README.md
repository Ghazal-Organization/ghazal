# Ghazal — Sync Agent (design + skeleton)

**Last updated**: 2026-05-22
**Status**: Skeleton ready; concrete POS mappings filled in during Phase 3 (on-site)

## 1. Mission

Run on the cashier PC. Bridge **cloud (Neon + Functions)** and the **local POS SQLite DB**. Outbound HTTPS only, no inbound ports (ADR-003).

Three jobs:
1. **Pull orders** from cloud, write into POS DB.
2. **Push status** changes from POS back to cloud.
3. **Sync menu/stock** from POS to cloud.

Plus: heartbeat, schema fingerprint, auto-update, local outbox for retries.

## 2. High-level data flow

```
                  Cloud (Azure Functions + Neon)
                  ▲                              │
   POST /sync/inbox │                              │ GET /sync/outbox?since=…
   POST /sync/heartbeat                            │ POST /sync/outbox/{id}/ack
                  │                              │
   ┌──────────────┴──────────────────────────────▼───────────┐
   │              Sync Agent (Windows Service)              │
   │                                                        │
   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
   │  │ OrderPuller  │  │ StatusPusher │  │ MenuSyncer   │  │
   │  └──────┬───────┘  └──────▲───────┘  └──────┬───────┘  │
   │         │ insert order    │ POS status      │ read menu│
   │         ▼                 │ change          ▼          │
   │   ┌─────────────────────────────────────────────────┐  │
   │   │           IPosAdapter  (per-vendor impl)        │  │
   │   │   • InsertOnlineOrder   • ReadMenu              │  │
   │   │   • ListStatusChanges   • ReadStock             │  │
   │   │   • ComputeSchemaFingerprint                    │  │
   │   └────────────────────────┬────────────────────────┘  │
   │                            │                            │
   │                            ▼                            │
   │            ┌───────────────────────────────┐            │
   │            │   POS SQLite DB (WAL mode)    │            │
   │            └───────────────────────────────┘            │
   │                                                        │
   │   Local store (SQLite, agent-owned):                   │
   │     - cloud-side cursor                                │
   │     - local outbox (events that failed to POST)        │
   │     - dedupe table (processed cloud event ids)         │
   │                                                        │
   │   Cross-cutting: HeartbeatPinger, Updater, Logging     │
   └────────────────────────────────────────────────────────┘
```

## 3. Solution layout

```
agents/sync-agent/
├── Ghazal.SyncAgent.sln
├── src/
│   ├── Ghazal.SyncAgent.Host/                  # Worker Service entry point
│   │   ├── Program.cs
│   │   ├── Worker.cs
│   │   ├── appsettings.json
│   │   ├── appsettings.Development.json
│   │   └── Ghazal.SyncAgent.Host.csproj
│   ├── Ghazal.SyncAgent.Core/                  # Domain logic, no IO
│   │   ├── Abstractions/
│   │   │   ├── IPosAdapter.cs
│   │   │   ├── ICloudClient.cs
│   │   │   ├── ILocalStore.cs
│   │   │   ├── ISystemClock.cs
│   │   │   └── ISchemaGuard.cs
│   │   ├── Mapping/
│   │   │   ├── MappingConfig.cs                # parsed YAML
│   │   │   ├── MappingLoader.cs
│   │   │   └── FieldMapper.cs
│   │   ├── Workers/
│   │   │   ├── OrderPullerLoop.cs
│   │   │   ├── StatusPusherLoop.cs
│   │   │   ├── MenuSyncerLoop.cs
│   │   │   └── HeartbeatLoop.cs
│   │   ├── Events/                             # DTOs for /sync/outbox & /sync/inbox
│   │   └── Result.cs
│   ├── Ghazal.SyncAgent.Infrastructure/        # IO impls
│   │   ├── Pos/
│   │   │   └── GenericSqlitePosAdapter.cs      # YAML-driven; default impl
│   │   ├── Cloud/
│   │   │   ├── HttpCloudClient.cs              # Refit + Polly
│   │   │   └── ICloudApi.cs                    # Refit interface
│   │   ├── Local/
│   │   │   └── SqliteLocalStore.cs
│   │   ├── Time/
│   │   │   └── SystemClock.cs
│   │   ├── Update/
│   │   │   └── SelfUpdater.cs                  # signed manifest checker
│   │   └── Logging/
│   │       └── AppInsightsConfigurator.cs
│   ├── Ghazal.SyncAgent.Cli/                   # dev tool: dry-run, schema-dump
│   │   └── Program.cs
│   └── Ghazal.SyncAgent.Installer/             # WiX or velopack bundle (later)
├── tests/
│   ├── Ghazal.SyncAgent.Core.UnitTests/
│   ├── Ghazal.SyncAgent.Infrastructure.IntegrationTests/  # temp SQLite fixture
│   └── Ghazal.SyncAgent.E2E.Fixtures/          # canned POS DB files per vendor
└── deploy/
    ├── install-service.ps1
    ├── uninstall-service.ps1
    └── update-manifest.example.json
```

Why three projects? Lets `Core` be pure (no `Microsoft.Data.Sqlite`, no HttpClient) so unit tests run without any infra. The mapping rules, idempotency logic, and state machine for outbox/inbox live in `Core` and are TDD-friendly.

## 4. Configuration model

Two layers:
- **`appsettings.json`** — operator-tuned, ships with the install.
- **`mapping.yaml`** — POS-specific. Edited per branch / per POS vendor. Loaded at startup.

### `appsettings.json` (committed defaults; secrets via env or DPAPI-encrypted file)

```json
{
  "Agent": {
    "BranchId": "00000000-0000-0000-0000-000000000000",
    "AgentVersion": "1.0.0",
    "LocalStorePath": "%ProgramData%\\Ghazal\\state.sqlite",
    "PosDbPath": "C:\\CashierApp\\data\\pos.sqlite",
    "MappingConfigPath": "%ProgramData%\\Ghazal\\mapping.yaml",
    "Loops": {
      "OrderPullIntervalSeconds": 5,
      "StatusPushIntervalSeconds": 3,
      "MenuSyncIntervalMinutes": 15,
      "HeartbeatIntervalSeconds": 30
    },
    "Retry": {
      "MaxAttempts": 8,
      "InitialDelaySeconds": 2,
      "MaxDelaySeconds": 60
    },
    "SchemaGuard": {
      "FailFastOnMismatch": true
    }
  },
  "Cloud": {
    "BaseUrl": "https://api.ghazal.example",
    "JwtSecretSource": "Env:GHAZAL_AGENT_JWT",
    "TimeoutSeconds": 30
  },
  "ApplicationInsights": {
    "ConnectionString": "Env:APPINSIGHTS_CONNECTION_STRING"
  },
  "Logging": {
    "LogLevel": { "Default": "Information", "Ghazal.SyncAgent": "Debug" }
  }
}
```

### `mapping.yaml` (per POS vendor)

This is the only file an integrator edits on-site. Until the on-site discovery, this stays a template with placeholders.

```yaml
vendor: acme-pos
version: 1                 # bump when this file changes
schema_fingerprint:        # SHA-256 of sqlite_master.sql values for the tables we read/write
  expected: TBD_AFTER_DISCOVERY
  tables: [Items, Categories, Modifiers, ModifierGroups, ItemModifiers, Orders, OrderLines, OrderLineModifiers]

connection:
  pragma:
    journal_mode: WAL
    foreign_keys: ON
  open_mode: read_write    # for orders inbox; menu uses 'read_only'

# ---- READ: menu items ----
menu:
  items:
    table: Items
    where: "IsDeleted = 0"
    columns:
      external_id: ItemId
      name_ar:     NameAr
      name_en:     NameEn
      base_price:  Price
      tax_percent: TaxRate
      category_external_id: CategoryId
      is_available: NOT IsBlocked
  categories:
    table: Categories
    columns:
      external_id: CategoryId
      name_ar:     NameAr
      name_en:     NameEn
      sort_order:  SortOrder
  modifier_groups:
    table: ModifierGroups
    columns:
      external_id: GroupId
      name_ar:     NameAr
      name_en:     NameEn
      min_select:  MinSelect
      max_select:  MaxSelect
  modifiers:
    table: Modifiers
    columns:
      external_id: ModifierId
      group_external_id: GroupId
      name_ar:     NameAr
      name_en:     NameEn
      price_delta: PriceDelta
      is_available: NOT IsBlocked
  item_modifier_groups:
    table: ItemModifiers
    columns:
      item_external_id:  ItemId
      group_external_id: GroupId

# ---- WRITE: online orders go into a table WE OWN inside the POS DB ----
order_inbox:
  table: online_orders_inbox   # created by the agent on first run
  columns:
    external_id:   text  primary_key
    payload_json:  text  not_null     # full order DTO
    received_at:   text  not_null
    processed_at:  text
    pos_order_id:  text                # filled by POS app import script
    pos_ticket_no: text
    status:        text  default('NEW') check("status IN ('NEW','IMPORTED','REJECTED')")
  triggers:
    - name: import_to_pos
      sql_file: ./triggers/acme/import_to_pos.sql   # ships with the mapping

# ---- READ: status changes ----
status_signals:
  - cloud_status: ACCEPTED
    sql: "SELECT external_id, accepted_at FROM online_orders_inbox WHERE status='IMPORTED' AND pos_order_id IS NOT NULL"
  - cloud_status: PREPARING
    sql: "SELECT external_id, started_at FROM Orders WHERE external_id LIKE 'ONLINE-%' AND state='IN_KITCHEN'"
  - cloud_status: READY
    sql: "SELECT external_id, ready_at FROM Orders WHERE state='READY'"
  - cloud_status: COMPLETED
    sql: "SELECT external_id, closed_at FROM Orders WHERE state='CLOSED'"
  - cloud_status: CANCELLED_BY_BRANCH
    sql: "SELECT external_id, voided_at AS occurred_at, voided_reason AS reason FROM Orders WHERE state='VOID'"
```

The agent never embeds vendor-specific SQL in code. Code reads YAML; SQL is data.

## 5. Core abstractions

```csharp
// Abstractions/IPosAdapter.cs
namespace Ghazal.SyncAgent.Core.Abstractions;

public interface IPosAdapter
{
    Task<SchemaFingerprint> ComputeSchemaFingerprintAsync(CancellationToken ct);

    // Menu (read)
    IAsyncEnumerable<PosMenuItemDto>      ReadMenuItemsAsync(CancellationToken ct);
    IAsyncEnumerable<PosCategoryDto>      ReadCategoriesAsync(CancellationToken ct);
    IAsyncEnumerable<PosModifierGroupDto> ReadModifierGroupsAsync(CancellationToken ct);
    IAsyncEnumerable<PosModifierDto>      ReadModifiersAsync(CancellationToken ct);

    // Orders (write to inbox)
    Task<InsertResult> InsertOnlineOrderAsync(OnlineOrder order, CancellationToken ct);

    // Status (read signals)
    IAsyncEnumerable<PosStatusSignal> ReadStatusSignalsSinceAsync(
        DateTimeOffset since, CancellationToken ct);
}

public enum InsertResult { Inserted, DuplicateIgnored, Failed }
```

```csharp
// Abstractions/ICloudClient.cs
public interface ICloudClient
{
    Task PingHeartbeatAsync(HeartbeatPayload payload, CancellationToken ct);

    Task<OutboxBatch> PullOutboxAsync(string? cursor, int limit, CancellationToken ct);
    Task AckOutboxAsync(Guid eventId, CancellationToken ct);

    Task PushInboxAsync(InboxEvent evt, string idempotencyKey, CancellationToken ct);
}
```

```csharp
// Abstractions/ILocalStore.cs
public interface ILocalStore
{
    // cursor for outbox pull
    Task<string?> GetCursorAsync(string scope, CancellationToken ct);
    Task          SetCursorAsync(string scope, string cursor, CancellationToken ct);

    // dedupe for processed outbox events
    Task<bool>    HasProcessedAsync(Guid cloudEventId, CancellationToken ct);
    Task          MarkProcessedAsync(Guid cloudEventId, CancellationToken ct);

    // local outbox for events the cloud refused or that failed to POST
    Task          EnqueueOutboxAsync(InboxEvent evt, string idempotencyKey, CancellationToken ct);
    IAsyncEnumerable<PendingOutboxEntry> ReadPendingAsync(int limit, CancellationToken ct);
    Task          MarkSentAsync(long entryId, CancellationToken ct);
    Task          MarkFailedAsync(long entryId, string error, CancellationToken ct);
}
```

```csharp
// Abstractions/ISchemaGuard.cs
public interface ISchemaGuard
{
    Task EnsureMatchOrThrowAsync(CancellationToken ct);
}
```

## 6. Local store schema (SQLite, agent-owned)

Lives at `%ProgramData%\Ghazal\state.sqlite`. Never touched by the POS app.

```sql
-- Cursors for pulling cloud outbox per scope
create table if not exists cursors (
    scope     text primary key,
    cursor    text not null,
    updated_at text not null
);

-- Cloud events we've already processed (idempotent replay shield)
create table if not exists processed_cloud_events (
    cloud_event_id text primary key,    -- uuid as text
    processed_at   text not null
);
create index if not exists ix_processed_age on processed_cloud_events(processed_at);

-- Local outbox: events the agent failed to deliver to the cloud
create table if not exists outbox (
    id              integer primary key autoincrement,
    idempotency_key text    not null unique,
    payload_json    text    not null,
    enqueued_at     text    not null,
    attempts        integer not null default 0,
    last_attempt_at text,
    last_error      text,
    status          text    not null default 'pending' check (status in ('pending','sent','failed'))
);
create index if not exists ix_outbox_pending on outbox(status, enqueued_at);

-- Snapshot of last menu hash per entity to detect what actually changed
create table if not exists menu_hashes (
    entity_type    text not null,                -- 'item', 'category', 'modifier_group', 'modifier'
    external_id    text not null,
    content_hash   text not null,
    last_synced_at text not null,
    primary key (entity_type, external_id)
);

-- One-row table for agent metadata
create table if not exists agent_meta (
    key   text primary key,
    value text not null
);
-- Example rows:
--  ('schema_fingerprint', '<sha256>')
--  ('last_heartbeat_at', '2026-05-22T13:00:00Z')
```

A nightly job inside the agent prunes `processed_cloud_events` rows older than 30 days.

## 7. Loops

All loops are `BackgroundService` instances, scheduled by `IHostedService`. They share a single `IPosAdapter` and `ICloudClient` from DI.

```csharp
// Workers/OrderPullerLoop.cs (excerpt)
public sealed class OrderPullerLoop(
    ICloudClient cloud,
    IPosAdapter pos,
    ILocalStore store,
    AgentOptions opts,
    ILogger<OrderPullerLoop> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        var period = TimeSpan.FromSeconds(opts.Loops.OrderPullIntervalSeconds);
        using var timer = new PeriodicTimer(period);

        while (await timer.WaitForNextTickAsync(ct))
        {
            try { await PullOnceAsync(ct); }
            catch (Exception ex) { log.LogError(ex, "Order pull failed"); }
        }
    }

    private async Task PullOnceAsync(CancellationToken ct)
    {
        var cursor = await store.GetCursorAsync("orders", ct);
        var batch  = await cloud.PullOutboxAsync(cursor, limit: 50, ct);

        foreach (var evt in batch.Items.Where(e => e.EventType == "order.created"))
        {
            if (await store.HasProcessedAsync(evt.Id, ct)) { await cloud.AckOutboxAsync(evt.Id, ct); continue; }

            var order  = evt.Payload.Deserialize<OnlineOrder>();
            var result = await pos.InsertOnlineOrderAsync(order, ct);

            if (result is InsertResult.Inserted or InsertResult.DuplicateIgnored)
            {
                await store.MarkProcessedAsync(evt.Id, ct);
                await cloud.AckOutboxAsync(evt.Id, ct);
            }
            else
            {
                log.LogWarning("Insert failed for order {OrderId}; will retry next tick", order.Id);
            }
        }

        if (batch.NextCursor is not null)
            await store.SetCursorAsync("orders", batch.NextCursor, ct);
    }
}
```

```csharp
// Workers/StatusPusherLoop.cs (sketch)
public sealed class StatusPusherLoop : BackgroundService
{
    // 1. Read signals from POS since last check
    // 2. For each signal:
    //    - Build InboxEvent { type=pos.status_changed, payload={externalId, newStatus, occurredAt} }
    //    - Try POST /sync/inbox with idempotencyKey = sha256(externalId + newStatus + occurredAt)
    //    - On failure -> store.EnqueueOutboxAsync
    // 3. Drain store.outbox at the end of every tick
}
```

```csharp
// Workers/MenuSyncerLoop.cs (sketch)
// Reads menu via pos adapter; hashes each item; if hash differs from menu_hashes,
// pushes a 'menu.upserted' inbox event. Deletes detected by absence -> 'menu.removed'.
```

```csharp
// Workers/HeartbeatLoop.cs (sketch)
// Every 30s POST /sync/heartbeat with { agentVersion, posDbPath, metrics:
//   { outboxDepth, lastOrderPullAt, lastStatusPushAt, lastMenuSyncAt, posDbBytes } }
```

## 8. Cloud client — auth, retries, idempotency

- HTTP via **Refit** (`ICloudApi` interface mirrors OpenAPI) with **Polly** policies:
  - 8 attempts, exponential backoff 2s → 60s with jitter.
  - Retry only on `5xx`, `408`, `429`. Honour `Retry-After`.
  - Circuit-breaker: 5 consecutive failures → open for 30s, then half-open.
- Auth handler injects `Authorization: Bearer <jwt>`. JWT loaded from env var or DPAPI-encrypted file.
- `Idempotency-Key` set per request using `Guid.NewGuid().ToString()` or a deterministic key for replays.
- `Activity` (System.Diagnostics) propagates `traceparent` end-to-end.

```csharp
// Infrastructure/Cloud/ICloudApi.cs (Refit)
public interface ICloudApi
{
    [Post("/v1/sync/heartbeat")]
    Task PostHeartbeatAsync([Body] HeartbeatPayload p, CancellationToken ct);

    [Get("/v1/sync/outbox")]
    Task<OutboxBatch> GetOutboxAsync([Query] string? since, [Query] int limit, CancellationToken ct);

    [Post("/v1/sync/outbox/{eventId}/ack")]
    Task AckAsync(Guid eventId, CancellationToken ct);

    [Post("/v1/sync/inbox")]
    Task PushInboxAsync([Body] InboxEvent body, [Header("Idempotency-Key")] string idem, CancellationToken ct);
}
```

## 9. Schema fingerprint guard

On startup:

```csharp
var actual   = await pos.ComputeSchemaFingerprintAsync(ct);   // SHA-256 over sqlite_master.sql for mapped tables
var expected = mappingConfig.SchemaFingerprint.Expected;
if (actual.Hex != expected)
{
    log.LogCritical("POS schema fingerprint mismatch. Expected {Expected}, got {Actual}. Refusing to start.",
                    expected, actual.Hex);
    Environment.Exit(78);  // EX_CONFIG (BSD sysexits)
}
```

This catches POS app updates that silently change column names. The on-call gets a paging alert; integrator fixes the YAML, ships a new version, agent self-updates.

## 10. Observability

- **App Insights** via `Microsoft.Extensions.Logging.ApplicationInsights` + the Worker SDK.
- Standard fields on every log scope: `branchId`, `agentVersion`, `loop`, `traceId`.
- Custom metrics emitted from each loop:
  - `agent.orders.pulled` (counter), `agent.orders.failed` (counter)
  - `agent.status.pushed` (counter), `agent.outbox.depth` (gauge, sampled)
  - `agent.menu.upserts`, `agent.menu.removes`
  - `agent.heartbeat.success_rate` (computed cloud-side)
- Alerts (defined in App Insights, see ADR-022): no heartbeat > 2 min during branch hours; outbox depth > 100; schema mismatch.

## 11. Deployment

- **Windows Service** registered via `sc.exe` from `deploy/install-service.ps1`:
  ```powershell
  sc.exe create GhazalSyncAgent binPath= "C:\Program Files\Ghazal\SyncAgent\Ghazal.SyncAgent.Host.exe" start= auto
  sc.exe failure GhazalSyncAgent reset= 86400 actions= restart/5000/restart/15000/restart/60000
  sc.exe description GhazalSyncAgent "Ghazal online ordering bridge"
  ```
- Runs as a dedicated low-privilege local account that has:
  - Read on the POS folder.
  - Read/write only on `%ProgramData%\Ghazal\`.
  - Outbound HTTPS to `api.ghazal.example`.
- **Auto-updater** (`SelfUpdater`): every 6 hours, GET a signed `update-manifest.json` from a cloud endpoint (e.g. R2 with Cloudflare WAF). Verify Ed25519 signature; if version > current and `branchAllowList` includes us, download MSI/zip → verify signature → run silently via scheduled task → service restarts.

## 12. Testing

Aligned with the TDD discipline in [mvp.md](../plan/mvp.md).

### Core unit tests (no IO)
- **MappingLoader**: valid YAML; missing required field; wrong type; unknown top-level key → clear error.
- **FieldMapper**: column → property coercions, including `NOT IsBlocked` expressions, NULL handling, AR/EN strings.
- **OrderPullerLoop** with **fakes** for `ICloudClient`, `IPosAdapter`, `ILocalStore`:
  - first pull stores cursor;
  - second pull resumes from cursor;
  - duplicate cloud event → `DuplicateIgnored` → ack but no re-insert;
  - insert failure → no ack, no cursor advance.
- **StatusPusherLoop**: idempotency key is deterministic for the same `(externalId, newStatus, occurredAt)`; failure path enqueues local outbox.
- **SchemaGuard**: mismatch → exit code 78.

### Infrastructure integration tests
- **SqliteLocalStore** against a temp file: cursor get/set, processed dedupe, outbox enqueue/drain.
- **GenericSqlitePosAdapter** against fixture DBs under `tests/Ghazal.SyncAgent.E2E.Fixtures/`:
  - `acme-v1.sqlite` → expected items / categories / modifiers list.
  - `acme-v1.sqlite` → status signals after staged updates.
  - Order insert is idempotent on repeat with same `external_id`.

### Cloud client contract tests
- `WireMock.Net` simulates `/sync/*`:
  - 200/202 happy path;
  - `429` with `Retry-After` honoured;
  - `5xx` triggers retry, eventually opens circuit;
  - `401` → no retry, log + exit code 77 (`EX_PROTOCOL`).

### End-to-end (CI, scriptable)
- Spin up the Functions API (Testcontainers) + Neon test branch + agent process + canned POS SQLite.
- Place an order via `POST /v1/orders` → assert it appears in the fixture POS within 60s.
- Flip a status row in the fixture POS → assert the cloud's `orders.{id}` shows the new state within 30s.
- Restart the agent mid-test → assert no duplicate inserts and no lost status changes.

## 13. What is intentionally TBD until on-site (Phase 3)

- `mapping.yaml` table/column names and the `schema_fingerprint.expected` hash.
- The optional `triggers/acme/import_to_pos.sql` — whether the POS app picks up rows from `online_orders_inbox` automatically (trigger) or requires a staff "Import" tap in the admin (manual signal).
- WAL behaviour with this specific POS — confirm read concurrency, confirm the cashier app doesn't reject our table.
- Whether the cashier app prints a kitchen ticket automatically when our import script writes the order, or if we need ESC/POS direct printing as a fallback (see backlog).
- Real status-signal columns and their meanings (e.g. is `READY` a column flag or a row in another table?).

The skeleton above is designed so that **only `mapping.yaml` + a fingerprint constant** change for a new POS vendor. If a POS is too weird for YAML (custom blob columns, encrypted fields, etc.), implement a vendor-specific `IPosAdapter` and register it in DI — the loops, store, cloud client, and tests stay the same.

## 14. Backlog (not in MVP)

- Direct ESC/POS thermal printing (USB/LAN) for branches where the POS won't auto-print.
- Web UI for the agent (local-only `http://127.0.0.1:9009`) showing live loop state — useful during integration visits.
- Health page exposed via Cloudflare Tunnel for remote support.
- Multi-vendor live switching (one binary, multiple `IPosAdapter` impls selected by config).
