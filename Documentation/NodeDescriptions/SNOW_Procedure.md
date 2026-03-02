# <img src="../Icons/SNOW_Procedure.png" width="50"/> Procedure

A stored procedure registered in a Snowflake schema. Procedures encapsulate procedural logic that can be executed to perform operations such as data transformations, administrative tasks, and complex multi-step workflows within Snowflake.

> **Note:** Currently commented out in the collector but defined in the schema.

**Created by:** `Invoke-SnowHound`

## Properties

| Property Name | Data Type | Description |
|---|---|---|
| name | string | Display name of the Procedure |
| fqdn | string | Fully qualified domain name (db.schema.procedure@account.org) |
| created_on | datetime | Timestamp when the procedure was created |
| schema_name | string | Parent schema name |
| is_builtin | string | Whether this is a built-in procedure |
| is_aggregate | string | Whether this is an aggregate procedure |
| is_ansi | string | Whether this is an ANSI-compliant procedure |
| min_num_arguments | integer | Minimum number of arguments |
| max_num_arguments | integer | Maximum number of arguments |
| arguments | string | Procedure argument signature |
| description | string | Procedure description |
| catalog_name | string | Parent database (catalog) name |
| is_table_function | string | Whether this returns a table |
| valid_for_clustering | string | Whether valid for clustering |
| is_secure | string | Whether this is a secure procedure |
| secrets | string | Associated secrets |
| external_access_integrations | string | External access integrations |

## Edges

### Outbound Edges

| Edge Kind | Target Node | Traversable | Description |
|---|---|---|---|
| (none) | | | Procedures have no outbound edges |

### Inbound Edges

| Edge Kind | Source Node | Traversable | Description |
|---|---|---|---|
| SNOW_Contains | SNOW_Account | No | Account contains this procedure |
| SNOW_Contains | SNOW_Schema | No | Schema contains this procedure |
| SNOW_Usage | SNOW_Role | Yes | Role has usage privilege |
| SNOW_Ownership | SNOW_Role | Yes | Role owns this procedure |

## Diagram

```mermaid
flowchart TD
    SNOW_Schema["SNOW_Schema"]:::schema -.->|SNOW_Contains| SNOW_Procedure["SNOW_Procedure"]:::procedure
    SNOW_Role1["SNOW_Role"]:::role -->|SNOW_Usage| SNOW_Procedure
    SNOW_Role2["SNOW_Role"]:::role -->|SNOW_Ownership| SNOW_Procedure

    classDef procedure fill:#D8C8F8,stroke:#333,color:#000
    classDef schema fill:#DEFEFA,stroke:#333,color:#000
    classDef role fill:#C06EFF,stroke:#333,color:#000
```
