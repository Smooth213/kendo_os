# Provider Dependency Map

This document defines the strict unidirectional dependency hierarchy for Riverpod Providers in `kendo_os`.
To maintain deterministic behavior and prevent memory leaks, **Circular Dependencies are strictly prohibited**.

## 🏗️ Hierarchy and Dependency Direction

All providers must only depend on providers in the same tier or a lower tier. **Upward dependencies are strictly banned.**


```
[Tier 4: UI/Presentation View Layer] (Screens, Components)
│
▼
[Tier 3: View State / View Model Layer] (match_view_model_provider, viewer_view_state_provider, ui_message_provider)
│
▼
[Tier 2: Domain Logic & Command Orchestration Layer] (match_command_provider, match_timer_provider, bunaiksen_infinite_engine_provider)
│
▼
[Tier 1: Core Infra & Security Context Layer] (auth_provider, sync_provider, role_provider)
│
▼
[Tier 0: Internal Isolated Layer] (metrics_provider, audit_provider)
```

## 🚫 Absolute Rules

1. **No Circular Dependencies:** A provider must never depend on another provider that directly or indirectly depends back on it.
2. **Internal Isolation:** Tier 0 (`providers/internal/*`) must never be imported or read by public user-facing Tier 3/4 presentation layers under `RuntimeMode.publicBeta`.
3. **Unidirectional Flow:** State changes must always flow downwards or horizontally within the tier, never upwards.