# {{PROJECT_NAME}} Architecture

## System Overview

{{PROJECT_NAME}} is {{PROJECT_DESCRIPTION}}.

## Design Principles

1. **{{PRINCIPLE_1}}**: {{PRINCIPLE_1_DESCRIPTION}}
2. **{{PRINCIPLE_2}}**: {{PRINCIPLE_2_DESCRIPTION}}
3. **{{PRINCIPLE_3}}**: {{PRINCIPLE_3_DESCRIPTION}}

## Component Architecture

### {{COMPONENT_A}}

{{COMPONENT_A}} is responsible for:
- {{RESPONSIBILITY_1}}
- {{RESPONSIBILITY_2}}

```
┌─────────────────────────────────────────────────────────┐
│                    {{COMPONENT_A}}                       │
│                                                          │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Layer 1  │  │   Layer 2    │  │     Layer 3       │  │
│  │          │──│              │──│                   │  │
│  └──────────┘  └──────────────┘  └───────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### {{COMPONENT_B}}

{{COMPONENT_B}} is responsible for:
- {{RESPONSIBILITY_1}}
- {{RESPONSIBILITY_2}}

## Data Flow

```
User ──▶ {{COMPONENT_A}} ──▶ {{COMPONENT_B}} ──▶ Result
              │                    │
              ▼                    ▼
         [Side Effect 1]     [Side Effect 2]
```

## Infrastructure

### Deployment Target

- **Cloud Provider**: {{CLOUD_PROVIDER}}
- **Orchestration**: {{ORCHESTRATION}} (ECS, Kubernetes, etc.)
- **Storage**: {{STORAGE}}

### Network Topology

```
┌─────────────────────────────────────────────────────────┐
│                         VPC                              │
│                                                          │
│  ┌─────────────────────┐  ┌─────────────────────────┐   │
│  │   Public Subnet     │  │    Private Subnet       │   │
│  │   (Load Balancer)   │  │    (Application)        │   │
│  └─────────────────────┘  └─────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Security Model

### Authentication
{{AUTH_DESCRIPTION}}

### Authorization
{{AUTHZ_DESCRIPTION}}

### Data Protection
- Data at rest: {{ENCRYPTION_AT_REST}}
- Data in transit: {{ENCRYPTION_IN_TRANSIT}}

## Observability

### Logging
- Format: JSON (structured)
- Destination: {{LOG_DESTINATION}}

### Metrics
- Collection: {{METRICS_TOOL}}
- Key metrics: Request rate, error rate, latency (RED)

### Tracing
- Protocol: {{TRACING_PROTOCOL}} (OpenTelemetry, etc.)
- Backend: {{TRACING_BACKEND}}

## Development Model

### Branching Strategy
- `main` - Production-ready code
- `feat/*` - Feature branches
- `fix/*` - Bug fixes

### CI/CD Pipeline
1. Lint and format check
2. Unit tests
3. Integration tests (on PR)
4. Deploy to staging (on merge)
5. Deploy to production (manual trigger or auto)

## Future Considerations

### Planned
- {{PLANNED_FEATURE_1}}
- {{PLANNED_FEATURE_2}}

### Under Evaluation
- {{EVALUATION_ITEM_1}}

## Decision Records

See `docs/adr/` for architectural decision records.
