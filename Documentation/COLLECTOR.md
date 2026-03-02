# Collector Setup & Usage

SnowHound uses the [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow`) to collect metadata from your Snowflake account and transform it into a BloodHound OpenGraph payload.

## Prerequisites

- **[Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation)** (`snow`) installed and on your PATH
- **PowerShell** (5.1+ or PowerShell Core 7+) to run the `Invoke-SnowHound` function
- **BloodHound Community Edition** with OpenGraph support enabled
- A Snowflake account with sufficient privileges (see [Required Privileges](#required-privileges))

---

## Setup

### Step 1: Generate a Key Pair

Snowflake supports public/private key pair authentication for non-interactive use. Follow the [official documentation](https://docs.snowflake.com/en/user-guide/key-pair-auth#generate-the-private-keys) to generate the key pair.

- The **private key** stays on your local machine and is used by the Snow CLI.
- The **public key** must be registered with the service account in Snowflake.

### Step 2: Create a Service Account

Create a dedicated Snowflake user for data collection:

```sql
CREATE USER SNOW_HOUND_SVC
  PASSWORD = 'StrongPassword!'
  DEFAULT_ROLE = ACCOUNTADMIN
  MUST_CHANGE_PASSWORD = FALSE
  RSA_PUBLIC_KEY = '<public_key_contents>';
```

Replace `<public_key_contents>` with your actual public key (without the `-----BEGIN PUBLIC KEY-----` / `-----END PUBLIC KEY-----` headers and without newlines).

### Step 3: Assign Roles and Privileges

Grant the service account an appropriate role:

```sql
GRANT ROLE ACCOUNTADMIN TO USER SNOW_HOUND_SVC;
```

> **Production note:** For production deployments, consider creating a custom role with only the minimum privileges required for collection. See [Required Privileges](#required-privileges) for details.

### Step 4: Configure the Snow CLI Connection

```bash
snow connection add \
  --connection-name snowhound \
  --account <account_name> \
  --user SNOW_HOUND_SVC \
  --private-key-path ~/.ssh/snowflake_key.p8 \
  --role ACCOUNTADMIN \
  --warehouse <warehouse_name>
```

Verify connectivity:

```bash
snow sql -q "SELECT CURRENT_USER(), CURRENT_ROLE();"
```

### Step 5: Run the Collector

1. Open a PowerShell terminal and navigate to the repository root.

2. Dot-source the collector script:

   ```powershell
   . ./snowhound.ps1
   ```

3. Run the collection:

   ```powershell
   Invoke-SnowHound
   ```

4. The collector will output a file named `snowhound_<org>-<account>.json` in the current directory.

### Step 6: Upload to BloodHound

Upload the generated JSON payload via BloodHound's **File Ingest** page.

---

## Required Privileges

The collector queries several Snowflake metadata views that require specific access. The table below summarizes what is needed:

| Data Source | Minimum Privilege | Notes |
|-------------|-------------------|-------|
| `snowflake.organization_usage.accounts` | `ORGADMIN` role | Required to resolve the account's organization and name |
| `snow object list user` | `ACCOUNTADMIN` or `SECURITY_VIEWER` database role | Lists all users in the account |
| `snow object list role` | Any role (limited results) or `ACCOUNTADMIN` | Unprivileged roles see a subset |
| `SHOW APPLICATIONS` | Any role with USAGE on at least one application | Returns only applications visible to the current role |
| `snow object list warehouse` | Role with USAGE or MANAGE WAREHOUSES privilege | Only returns warehouses the role can see |
| `snow object list database` | Any role (limited results) or `ACCOUNTADMIN` | Unprivileged roles see only databases they can access |
| `snow object list schema` | Any role (limited) | Returns schemas visible to the current role |
| `snow object list stage` | Any role (limited) | Returns stages visible to the current role |
| `snow object list table` | Any role (limited) | Returns tables visible to the current role |
| `snow object list view` | Any role (limited) | Returns views visible to the current role |
| `snow object list integration` | `ACCOUNTADMIN` or role with USAGE on integrations | Security integration details require additional access |
| `account_usage.grants_to_users` | `ACCOUNTADMIN` or `SECURITY_VIEWER` database role | Critical for mapping user-to-role relationships |
| `account_usage.grants_to_roles` | `ACCOUNTADMIN` or `SECURITY_VIEWER` database role | Critical for mapping role-to-object permissions |

### Granting SECURITY_VIEWER Access

If you prefer not to use `ACCOUNTADMIN` directly, you can grant the `SECURITY_VIEWER` database role to a custom role for read-only access to the `ACCOUNT_USAGE` schema:

```sql
GRANT DATABASE ROLE snowflake.SECURITY_VIEWER TO ROLE <your_custom_role>;
```

This grants read access to the `grants_to_users`, `grants_to_roles`, `users`, `roles`, and `databases` views within `snowflake.account_usage`.

---

## What Gets Collected

The collector gathers metadata about the following Snowflake objects and their relationships:

| Object Type | Node Kind | Identifier Pattern |
|-------------|-----------|-------------------|
| Account | `SNOW_Account` | `<org>-<account>` |
| User | `SNOW_User` | `<org>-<account>.<login_name>` |
| Role | `SNOW_Role` | `<org>-<account>.<role_name>` |
| Application | `SNOW_Application` | `<org>-<account>.<app_name>` |
| Application Role | `SNOW_ApplicationRole` | `<org>-<account>.<app_name>.<role_name>` |
| Database | `SNOW_Database` | `<org>-<account>.<db_name>` |
| Schema | `SNOW_Schema` | `<org>-<account>.<db_name>.<schema_name>` |
| Warehouse | `SNOW_Warehouse` | `<org>-<account>.<wh_name>` |
| Integration | `SNOW_Integration` | `<org>-<account>.<integration_name>` |
| Table | `SNOW_Table` | `<org>-<account>.<db>.<schema>.<table_name>` |
| View | `SNOW_View` | `<org>-<account>.<db>.<schema>.<view_name>` |
| Stage | `SNOW_Stage` | `<org>-<account>.<db>.<schema>.<stage_name>` |

Privilege grants (`grants_to_roles` and `grants_to_users`) are mapped to edges in the graph. Each Snowflake privilege becomes a typed edge (e.g., `SNOW_Usage`, `SNOW_Ownership`, `SNOW_Select`) connecting the grantee to the target object.

For a complete list of edge types, see [Edges.md](Edges.md).

---

## Sample Data

If you do not have a Snowflake environment or want to test SnowHound before collecting from production, a sample dataset is included at [`samples/example.json`](../samples/example.json). Upload it directly to BloodHound's File Ingest page.

---

## Troubleshooting

### Snow CLI connection fails

- Verify your private key path and format (PKCS#8 `.p8` is expected).
- Ensure the public key registered in Snowflake matches your private key.
- Check that the account identifier uses the correct format (`<org>-<account>` or the legacy account locator).
- Run `snow connection test -c snowhound` to diagnose connection issues.

### Missing objects in the graph

- The collector only returns objects visible to the role configured in the Snow CLI connection. Switch to `ACCOUNTADMIN` or a role with broader visibility for a complete collection.
- Warehouses in particular require explicit privilege grants. Consider granting `MANAGE WAREHOUSES` to the collection role for full warehouse visibility.

### Grant data is incomplete

- The `account_usage.grants_to_users` and `account_usage.grants_to_roles` views require `ACCOUNTADMIN` or the `SECURITY_VIEWER` database role. Without this access, the graph will have nodes but very few edges.

### Security integration details are missing

- The collector runs `DESCRIBE SECURITY INTEGRATION <name>` for security-type integrations to extract properties like `RUN_AS_ROLE`. This requires ownership or sufficient privileges on the integration object.
