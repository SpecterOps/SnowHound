# <img src="../Icons/SNOW_StorageIntegration.png" width="50"/> Storage Integration

A Snowflake storage integration that links Snowflake-managed access to external cloud storage. Storage integrations are commonly referenced by external stages and are represented as concrete integration nodes that also carry the shared `SNOW_Integration` kind.

**Created by:** `Invoke-SnowHound`

## Properties

| Property Name | Data Type | Description |
|---|---|---|
| name | string | Display name of the storage integration |
| fqdn | string | Fully qualified domain name |
| type | string | Integration type |
| category | string | Integration category (`STORAGE`) |
| created_on | datetime | Timestamp when the integration was created |
| (conditional) | various | Additional normalized properties from `DESCRIBE STORAGE INTEGRATION` |

## Edges

### Outbound Edges

| Edge Kind | Target Node | Traversable | Description |
|---|---|---|---|
| (none) | | | Storage integrations currently have no integration-specific outbound edges |

### Inbound Edges

| Edge Kind | Source Node | Traversable | Description |
|---|---|---|---|
| SNOW_Contains | SNOW_Account | No | Account contains this storage integration |
| SNOW_UsesStorageIntegration | SNOW_Stage | Yes | Stage uses this storage integration |
| SNOW_Usage | SNOW_Role | Yes | Role has usage privilege |
| SNOW_Ownership | SNOW_Role | Yes | Role owns this storage integration |

## Diagram

```mermaid
flowchart TD
    SNOW_Account["SNOW_Account"]:::account -.->|SNOW_Contains| SNOW_StorageIntegration["SNOW_StorageIntegration"]:::integration
    SNOW_Stage["SNOW_Stage"]:::stage -->|SNOW_UsesStorageIntegration| SNOW_StorageIntegration
    SNOW_Role1["SNOW_Role"]:::role -->|SNOW_Usage| SNOW_StorageIntegration
    SNOW_Role2["SNOW_Role"]:::role -->|SNOW_Ownership| SNOW_StorageIntegration

    classDef integration fill:#BFFFD1,stroke:#333,color:#000
    classDef account fill:#5FED83,stroke:#333,color:#000
    classDef stage fill:#80E0C6,stroke:#333,color:#000
    classDef role fill:#C06EFF,stroke:#333,color:#000
```
