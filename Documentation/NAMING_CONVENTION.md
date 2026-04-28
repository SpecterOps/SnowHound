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

Every node in the BloodHound graph is assigned an `id` that uniquely identifies it across all accounts in the graph. The identifier is constructed by prefixing Snowflake's contextual name with a Snowflake-style environment identifier.

### Account Identifier (Base Prefix)

All object IDs begin with the account identifier, which combines the Snowflake account name and organization name:

```
<account_name>.<org_name>
```

For example, an account named `main` in the organization `acme` produces the base prefix `main.acme`.

### Account-Level Objects

Objects that are unique within a Snowflake account append the object name directly to the account identifier:

```
<account_name>.<org_name>.<object_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Account | `<account>.<org>` | `main.acme` |
| User | `<account>.<org>.<login_name>` | `main.acme.ALICE` |
| Role | `<account>.<org>.<role_name>` | `main.acme.ANALYST` |
| Application | `<account>.<org>.<app_name>` | `main.acme.SNOWPARK_ML` |
| Warehouse | `<account>.<org>.<wh_name>` | `main.acme.COMPUTE_WH` |
| Database | `<account>.<org>.<db_name>` | `main.acme.ANALYTICS` |
| Integration | `<account>.<org>.<integration_name>` | `main.acme.S3_STORAGE` |

### Database-Level Objects

Schemas are scoped to a database, so the database name is included in the identifier:

```
<account_name>.<org_name>.<database_name>.<schema_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Schema | `<account>.<org>.<db>.<schema>` | `main.acme.ANALYTICS.PUBLIC` |

### Schema-Level Objects

Tables, views, stages, functions, and procedures are scoped to a schema, so the full database and schema path is included:

```
<account_name>.<org_name>.<database_name>.<schema_name>.<object_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Table | `<account>.<org>.<db>.<schema>.<table>` | `main.acme.ANALYTICS.PUBLIC.CUSTOMERS` |
| View | `<account>.<org>.<db>.<schema>.<view>` | `main.acme.ANALYTICS.PUBLIC.CUSTOMER_SUMMARY` |
| Stage | `<account>.<org>.<db>.<schema>.<stage>` | `main.acme.DATA.RAW.S3_INGEST` |
| Function | `<account>.<org>.<db>.<schema>.<function>` | `main.acme.ANALYTICS.PUBLIC.CALC_REVENUE` |
| Procedure | `<account>.<org>.<db>.<schema>.<procedure>` | `main.acme.ANALYTICS.PUBLIC.LOAD_DATA` |

### Application Roles

Application roles are a special case. They are scoped to their parent application, so the application name is included in the identifier:

```
<account_name>.<org_name>.<application_name>.<role_name>
```

| Object Type | ID Pattern | Example |
|-------------|-----------|---------|
| Application Role | `<account>.<org>.<app>.<role>` | `main.acme.SNOWPARK_ML.APP_ADMIN` |

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

Each node also has a `name` property that contains the object's display label. For most object kinds this is the short name (e.g., `CUSTOMERS`, `ANALYST`, `COMPUTE_WH`). For `SNOW_Account`, the display label is the full environment identifier (for example `main.acme`) for clarity.

## Summary

| Property | Purpose | Example |
|----------|---------|---------|
| `id` | Globally unique graph identifier | `main.acme.ANALYTICS.PUBLIC.CUSTOMERS` |
| `fqdn` | Human-readable qualified name | `ANALYTICS.PUBLIC.CUSTOMERS@main.acme` |
| `name` | Short display label | `CUSTOMERS` |

The `id` ensures no collisions across multiple Snowflake accounts in the same graph. The `fqdn` provides a readable reference that includes full context. The `name` keeps graph labels concise.
