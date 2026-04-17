# SNOW_UseAnyRole

## Edge Schema

- Source: [SNOW_Role](../NodeDescriptions/SNOW_Role.md), [SNOW_ApplicationRole](../NodeDescriptions/SNOW_ApplicationRole.md)
- Destination: [SNOW_Account](../NodeDescriptions/SNOW_Account.md)

## General Information

The non-traversable `SNOW_UseAnyRole` edge grants the ability to assume any role on the account. This is an extremely powerful privilege that effectively grants all permissions of every role in the account. A principal with USE ANY ROLE can impersonate any role, making this one of the most dangerous privileges in Snowflake. Any role or user that can reach a role with this privilege through the role hierarchy can effectively become ACCOUNTADMIN or any other role.

```mermaid
graph LR
    role("SNOW_Role PRIVILEGED_SERVICE_ROLE")
    account("SNOW_Account ACME_CORP")
    accountadmin("SNOW_Role ACCOUNTADMIN")
    securityadmin("SNOW_Role SECURITYADMIN")
    sysadmin("SNOW_Role SYSADMIN")
    role -- SNOW_UseAnyRole --> account
    account -. "can assume" .-> accountadmin
    account -. "can assume" .-> securityadmin
    account -. "can assume" .-> sysadmin
```
