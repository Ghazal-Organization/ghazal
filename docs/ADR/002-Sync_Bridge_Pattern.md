# ADR-002: Sync Bridge Pattern instead of direct could -> POS calls

**Decision**: A sync agent (Windows Service) runs on or the POS P and is the only component that touches the local DB. The cloud never connects directly to the restaurant network.

**Rationale**: No inbound ports on restaurant LAN; works behind any router/4G; isolates POS-specific code; survives offline periods.

**Alternatives**: VPN + direct cloud access (rejected - networking + security overhead); cloud-only with manual re-entry (rejected - operational burden);

**Consequence**: Need agent install, auto-update, monitoring, signed per-branch credentials.