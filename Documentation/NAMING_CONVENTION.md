# Naming Convention

## Background

Snowflake does not assign globally unique identifiers to objects. Instead, it relies on a contextual naming hierarchy where uniqueness is scoped to the object's parent container:

| Scope | Uniqueness Requirement | Examples |
|-------|----------------------|----------|
| Account-level | Unique within the account | Users, Roles, Warehouses, Databases, Integrations |
| Database-level | Unique within the database | Schemas |
| Schema-level | Unique within the schema | Tables, Views, Stages, Functions, Procedures |

Within a single Snowflake session, objects can be referenced using short names because the current database and schema provide implicit context. For example, a table can be referenced as just `CUSTOMERS` if the session's active database and schema already point to the right location. Snowflake's fully qualified name format for schema-level objects is:

```
<database_name>.<schema_name>.<object_name>
```

This works well within a single account, but BloodHound graphs can contain data from **multiple Snowflake accounts simultaneously**. Two different accounts could each have a database called `ANALYTICS` with a schema called `PUBLIC` and a table called `CUSTOMERS` — and Snowflake's native naming would produce identical references for both. SnowHound extends the naming convention to guarantee global uniqueness across accounts.

## SnowHound Object Identifiers

Every node in the BloodHound graph is assigned an `id` that uniquely identifies it across all accounts in the graph. The identifier is constructed by prefixing Snowflake's contextual name with the organization and account name.

### Account Identifier (Base Prefix)

All object IDs begin with the account identifier, which combines the Snowflake organization name and account name:

```
<org_name>-<account_name>
```

For example, an account named `main` in the organization `acme` produces the base prefix `acme-main`.

### Account-Level Objects

Objects that are unique within a Snowflake account append the object name directly to the account identifier:

```
<org_name>-<account_name>.<object_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Account | `<org>-<account>` | `acme-main` |
| User | `<org>-<account>.<login_name>` | `acme-main.ALICE` |
| Role | `<org>-<account>.<role_name>` | `acme-main.ANALYST` |
| Application | `<org>-<account>.<app_name>` | `acme-main.SNOWPARK_ML` |
| Warehouse | `<org>-<account>.<wh_name>` | `acme-main.COMPUTE_WH` |
| Database | `<org>-<account>.<db_name>` | `acme-main.ANALYTICS` |
| Integration | `<org>-<account>.<integration_name>` | `acme-main.S3_STORAGE` |

### Database-Level Objects

Schemas are scoped to a database, so the database name is included in the identifier:

```
<org_name>-<account_name>.<database_name>.<schema_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Schema | `<org>-<account>.<db>.<schema>` | `acme-main.ANALYTICS.PUBLIC` |

### Schema-Level Objects

Tables, views, stages, functions, and procedures are scoped to a schema, so the full database and schema path is included:

```
<org_name>-<account_name>.<database_name>.<schema_name>.<object_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Table | `<org>-<account>.<db>.<schema>.<table>` | `acme-main.ANALYTICS.PUBLIC.CUSTOMERS` |
| View | `<org>-<account>.<db>.<schema>.<view>` | `acme-main.ANALYTICS.PUBLIC.CUSTOMER_SUMMARY` |
| Stage | `<org>-<account>.<db>.<schema>.<stage>` | `acme-main.DATA.RAW.S3_INGEST` |
| Function | `<org>-<account>.<db>.<schema>.<function>` | `acme-main.ANALYTICS.PUBLIC.CALC_REVENUE` |
| Procedure | `<org>-<account>.<db>.<schema>.<procedure>` | `acme-main.ANALYTICS.PUBLIC.LOAD_DATA` |

### Application Roles

Application roles are a special case. They are scoped to their parent application, so the application name is included in the identifier:

```
<org_name>-<account_name>.<application_name>.<role_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Application Role | `<org>-<account>.<app>.<role>` | `acme-main.SNOWPARK_ML.APP_ADMIN` |

## FQDN Property

In addition to the graph `id`, each node carries an `fqdn` (fully qualified domain name) property that provides a more familiar, human-readable format inspired by Active Directory conventions. The FQDN places the object path on the left and the account context on the right, separated by `@`:

```
<object_path>@<account_name>.<org_name>
```

This format mirrors how users think about identity in enterprise environments (`user@domain`) and makes nodes easier to read in the BloodHound UI.

### FQDN Examples

| Object Type | FQDN Pattern | Example |
|-------------|-------------|---------|
| Account | `<account>.<org>` | `main.acme` |
| User | `<name>@<account>.<org>` | `ALICE@main.acme` |
| Role | `<role>@<account>.<org>` | `ANALYST@main.acme` |
| Database | `<db>@<account>.<org>` | `ANALYTICS@main.acme` |
| Schema | `<db>.<schema>@<account>.<org>` | `ANALYTICS.PUBLIC@main.acme` |
| Table | `<db>.<schema>.<table>@<account>.<org>` | `ANALYTICS.PUBLIC.CUSTOMERS@main.acme` |
| Stage | `<db>.<schema>.<stage>@<account>.<org>` | `DATA.RAW.S3_INGEST@main.acme` |
| Integration | `<integration>@<account>.<org>` | `S3_STORAGE@main.acme` |

## Display Name

Each node also has a `name` property that contains only the object's short name (e.g., `CUSTOMERS`, `ANALYST`, `COMPUTE_WH`). This is the label shown in the BloodHound graph visualization and keeps the UI clean when the full identifier would be too long to display.

## Summary

| Property | Purpose | Example |
|----------|---------|---------|
| `id` | Globally unique graph identifier | `acme-main.ANALYTICS.PUBLIC.CUSTOMERS` |
| `fqdn` | Human-readable qualified name | `ANALYTICS.PUBLIC.CUSTOMERS@main.acme` |
| `name` | Short display label | `CUSTOMERS` |

The `id` ensures no collisions across multiple Snowflake accounts in the same graph. The `fqdn` provides a readable reference that includes full context. The `name` keeps graph labels concise.
