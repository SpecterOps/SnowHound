# <img src="../Icons/SNOW_Database.png" width="50"/> Database

A Snowflake database that serves as a logical container for schemas and data objects. Databases are the primary organizational unit in Snowflake's object hierarchy, sitting between the account and schema levels.

**Created by:** `Invoke-SnowHound`

## Properties

| Property Name | Data Type | Description |
|---|---|---|
| name | string | Display name of the Database |
| fqdn | string | Fully qualified domain name |
| created_on | datetime | Timestamp when the database was created |
| is_default | string | Whether this is the default database |
| is_current | string | Whether this is the current database |
| origin | string | Origin of the database if shared or replicated |
| owner | string | Role that owns this database |
| comment | string | Administrative comment |
| options | string | Database options |
| retention_time | string | Data retention time in days |
| kind | string | Database kind |
| owner_role_type | string | Type of the owner role |
| object_visibility | string | Object visibility setting |

## Edges

### Outbound Edges

| Edge Kind | Target Node | Traversable | Description |
|---|---|---|---|
| SNOW_Contains | SNOW_Schema | No | Database contains schemas |

### Inbound Edges

| Edge Kind | Source Node | Traversable | Description |
|---|---|---|---|
| SNOW_Contains | SNOW_Account | No | Account contains this database |
| SNOW_Usage | SNOW_Role | Yes | Role has USAGE privilege on this database |
| SNOW_Ownership | SNOW_Role | Yes | Role owns this database |
| SNOW_Modify | SNOW_Role | Yes | Role can modify database properties |
| SNOW_Monitor | SNOW_Role | Yes | Role can monitor this database |
| SNOW_CreateSchema | SNOW_Role | Yes | Role can create schemas in this database |
| SNOW_CreateDatabaseRole | SNOW_Role | Yes | Role can create database roles in this database |

## Diagram

```mermaid
flowchart TD
    SNOW_Account["SNOW_Account"]:::account -.->|SNOW_Contains| SNOW_Database["SNOW_Database"]:::database
    SNOW_Database -.->|SNOW_Contains| SNOW_Schema["SNOW_Schema"]:::schema
    SNOW_Role1["SNOW_Role"]:::role -->|SNOW_Usage| SNOW_Database
    SNOW_Role2["SNOW_Role"]:::role -->|SNOW_Ownership| SNOW_Database
    SNOW_Role3["SNOW_Role"]:::role -->|SNOW_CreateSchema| SNOW_Database

    classDef account fill:#5FED83,stroke:#333,color:#000
    classDef database fill:#FF80D2,stroke:#333,color:#000
    classDef schema fill:#DEFEFA,stroke:#333,color:#000
    classDef role fill:#C06EFF,stroke:#333,color:#000
```
