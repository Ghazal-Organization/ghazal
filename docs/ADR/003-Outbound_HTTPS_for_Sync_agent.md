# ADR-003: Outbound HTTPS only for the Sync Agent

**Decision**: Agent initiates all connections outward to the cloud. No public IP, no inbound ports.

**Rationale**: Security and simplicity. Works on any consumer/business internet without firewall changes.

**Consequence**: Agent uses long-polling or WebSocket/SignalR for "push" semantics from the cloud to branch.