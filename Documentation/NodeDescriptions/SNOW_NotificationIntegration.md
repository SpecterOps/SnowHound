# <img src="../Icons/SNOW_Integration.png" width="50"/> Notification Integration

A Snowflake notification integration that connects Snowflake events or features to an external messaging or notification service. Notification integrations are represented as concrete integration nodes and also carry the shared `SNOW_Integration` kind.

**Created by:** `Invoke-SnowHound`

## Properties

| Property Name | Data Type | Description |
|---|---|---|
| name | string | Display name of the notification integration |
| fqdn | string | Fully qualified domain name |
| type | string | Integration type |
| category | string | Integration category (`NOTIFICATION`) |
| created_on | datetime | Timestamp when the integration was created |
| (conditional) | various | Additional normalized properties from `DESCRIBE NOTIFICATION INTEGRATION` |

## Edges

### Outbound Edges

| Edge Kind | Target Node | Traversable | Description |
|---|---|---|---|
| (none) | | | Notification integrations currently have no integration-specific outbound edges |

### Inbound Edges

| Edge Kind | Source Node | Traversable | Description |
|---|---|---|---|
| SNOW_Contains | SNOW_Account | No | Account contains this notification integration |
| SNOW_Usage | SNOW_Role | Yes | Role has usage privilege |
| SNOW_Ownership | SNOW_Role | Yes | Role owns this notification integration |

## Diagram

```mermaid
flowchart TD
    SNOW_Account["SNOW_Account"]:::account -.->|SNOW_Contains| SNOW_NotificationIntegration["SNOW_NotificationIntegration"]:::integration
    SNOW_Role1["SNOW_Role"]:::role -->|SNOW_Usage| SNOW_NotificationIntegration
    SNOW_Role2["SNOW_Role"]:::role -->|SNOW_Ownership| SNOW_NotificationIntegration

    classDef integration fill:#BFFFD1,stroke:#333,color:#000
    classDef account fill:#5FED83,stroke:#333,color:#000
    classDef role fill:#C06EFF,stroke:#333,color:#000
```
