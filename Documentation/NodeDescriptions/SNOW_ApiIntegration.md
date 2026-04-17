# <img src="../Icons/SNOW_Integration.png" width="50"/> API Integration

A Snowflake API integration used to connect Snowflake-managed features to an external API endpoint or service. API integrations are represented as concrete integration nodes and also carry the shared `SNOW_Integration` kind.

**Created by:** `Invoke-SnowHound`

## Properties

| Property Name | Data Type | Description |
|---|---|---|
| name | string | Display name of the API integration |
| fqdn | string | Fully qualified domain name |
| type | string | Integration type |
| category | string | Integration category (`API`) |
| created_on | datetime | Timestamp when the integration was created |
| (conditional) | various | Additional normalized properties from `DESCRIBE API INTEGRATION` |

## Edges

### Outbound Edges

| Edge Kind | Target Node | Traversable | Description |
|---|---|---|---|
| (none) | | | API integrations currently have no integration-specific outbound edges |

### Inbound Edges

| Edge Kind | Source Node | Traversable | Description |
|---|---|---|---|
| SNOW_Contains | SNOW_Account | No | Account contains this API integration |
| SNOW_Usage | SNOW_Role | Yes | Role has usage privilege |
| SNOW_Ownership | SNOW_Role | Yes | Role owns this API integration |

## Diagram

```mermaid
flowchart TD
    SNOW_Account["SNOW_Account"]:::account -.->|SNOW_Contains| SNOW_ApiIntegration["SNOW_ApiIntegration"]:::integration
    SNOW_Role1["SNOW_Role"]:::role -->|SNOW_Usage| SNOW_ApiIntegration
    SNOW_Role2["SNOW_Role"]:::role -->|SNOW_Ownership| SNOW_ApiIntegration

    classDef integration fill:#BFFFD1,stroke:#333,color:#000
    classDef account fill:#5FED83,stroke:#333,color:#000
    classDef role fill:#C06EFF,stroke:#333,color:#000
```
