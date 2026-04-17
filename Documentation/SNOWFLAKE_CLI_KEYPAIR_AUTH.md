# Snowflake CLI Key-Pair Authentication

Use a dedicated Snowflake service user with an RSA key pair so `Invoke-SnowHound` can run repeated `snow` subcommands without prompting for MFA on every call.

## Why this matters

`Invoke-SnowHound` shells out to the Snowflake CLI many times during a collection. If your default Snow CLI connection uses interactive username/password authentication with MFA, each subcommand may trigger another MFA prompt.

Using a Snow CLI connection backed by `SNOWFLAKE_JWT` and an RSA private key avoids that issue and is a better fit for scripted collection.

## Prerequisites

- Snowflake CLI installed
- A Snowflake user dedicated to collection
- An RSA key pair, with the public key registered on that Snowflake user
- A warehouse and role that can see the objects you want to collect

## Example `config.toml`

Depending on your Snow CLI setup, the connection may live in `~/.snowflake/config.toml` or another Snowflake CLI home directory.

Add or update a connection like this:

```toml
[connections.snowhound]
account = "myorg-myaccount"
user = "snowhound"
warehouse = "COMPUTE_WH"
role = "ACCOUNTADMIN"
authenticator = "SNOWFLAKE_JWT"
private_key_file = "/absolute/path/to/rsa_key.p8"
```

## Important details

- Use an absolute path for `private_key_file`. Relative paths are easy to break depending on the directory where `snow` is executed.
- The private key should be PKCS#8 `.p8` format.
- The corresponding public key must already be set on the Snowflake user.
- The connection name does not have to be `snowhound`, but using that name keeps it aligned with the collector examples.

## Make it the default connection

If you want SnowHound to use this connection without specifying `--connection` on each command:

```bash
snow connection set-default snowhound
```

Then verify:

```bash
snow connection list
snow sql --connection snowhound -q "select current_user(), current_role(), current_account();"
```

## Example Snowflake user setup

Register the RSA public key on the collection user:

```sql
ALTER USER SNOWHOUND SET RSA_PUBLIC_KEY = '<public_key_contents>';
```

If you are creating a fresh user:

```sql
CREATE USER SNOWHOUND
  DEFAULT_ROLE = ACCOUNTADMIN
  DEFAULT_WAREHOUSE = COMPUTE_WH
  MUST_CHANGE_PASSWORD = FALSE
  RSA_PUBLIC_KEY = '<public_key_contents>';
```

Then grant the role you want the collector to run with:

```sql
GRANT ROLE ACCOUNTADMIN TO USER SNOWHOUND;
```

## Troubleshooting

### No such file or directory for the private key

Your `private_key_file` path is wrong or relative to the wrong working directory. Switch it to an absolute path.

### The connection exists but `snow sql` returns nothing useful

Test the connection directly:

```bash
snow sql --connection snowhound -q "select 1"
```

If that fails, fix the CLI connection before troubleshooting SnowHound itself.

### MFA prompts still happen

Check `snow connection list` and confirm that the connection being used is the key-pair-backed one, not an interactive password connection.
