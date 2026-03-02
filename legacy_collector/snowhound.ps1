function New-SnowflakeNode
{
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Id,

        [Parameter(Position = 1, Mandatory = $true)]
        [String]
        $Kind,

        [Parameter(Position = 2, Mandatory = $true)]
        [PSObject]
        $Properties
    )

    $props = [pscustomobject]@{
        id = $Id
        kinds = @($Kind, 'SNOW_Base')
        properties = $Properties
    }

    Write-Output $props
}

function New-SnowflakeEdge
{
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $Kind,

        [Parameter(Position = 1, Mandatory = $true)]
        [PSObject]
        $StartId,

        [Parameter(Position = 2, Mandatory = $true)]
        [PSObject]
        $EndId
    )

    $edge = [PSCustomObject]@{
        kind = $Kind
        start = [PSCustomObject]@{
            value = $StartId
        }
        end = [PSCustomObject]@{
            value = $EndId
        }
        properties = @{}
    }

    Write-Output $edge
}

function Normalize-Null
{
    param($Value)
    if ($null -eq $Value) { return "" }
    return $Value
}

function Get-MD5Hash
{
    param($String)

    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $Hash = ([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($String)))).replace("-","").ToLower()
    Write-Output $Hash
}

function Invoke-SnowHound
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $Path = (Get-Location).Path
    )

    $nodes = New-Object System.Collections.ArrayList
    $edges = New-Object System.Collections.ArrayList

    # SELECT * FROM snowflake.organization_usage.accounts WHERE account_locator = CURRENT_ACCOUNT();
    $account = Get-Content "$($Path)/accounts.csv" | ConvertFrom-Csv

    $accountProps = [PSCustomObject]@{
        organization_name = Normalize-Null $account.organization_name
        account_name      = Normalize-Null $account.account_name
        created_on        = Normalize-Null $account.created_on
        region            = Normalize-Null $account.region
        region_group      = Normalize-Null $account.region_group
        edition           = Normalize-Null $account.edition
        is_org_admin      = Normalize-Null $account.is_org_admin
        is_locked         = Normalize-Null $account.is_locked
        account_url       = Normalize-Null $account.account_url
        account_locator   = Normalize-Null $account.account_locator
        managed_accounts  = Normalize-Null $account.managed_accounts
        is_managed        = Normalize-Null $account.is_managed
        parent_account    = Normalize-Null $account.parent_account
    }
    
    $accountId = Get-MD5Hash -String "$($account.account_locator)-ACCOUNT-$($account.account_locator)"
    $null = $nodes.Add((New-SnowflakeNode -Id $accountId -Kind SNOW_Account -Properties $accountProps))

    # SELECT * FROM snowflake.account_usage.users;
    foreach($user in (Get-Content "$($Path)/users.csv" | ConvertFrom-Csv | Where-Object {$_.DELETED_ON -eq ""}))
    {
        $userProps = [PSCustomObject]@{
            user_id              = Normalize-Null $user.user_id
            name                 = Normalize-Null $user.name
            created_on           = Normalize-Null $user.created_on
            login_name           = Normalize-Null $user.login_name
            display_name         = Normalize-Null $user.display_name
            first_name           = Normalize-Null $user.first_name
            last_name            = Normalize-Null $user.last_name
            email                = Normalize-Null $user.email
            must_change_password = Normalize-Null $user.must_change_password
            has_password         = Normalize-Null $user.has_password
            snowflake_lock       = Normalize-Null $user.snowflake_lock
            default_warehouse    = Normalize-Null $user.default_warehouse
            default_namespace    = Normalize-Null $user.default_namespace
            default_role         = Normalize-Null $user.default_role
            ext_authn_duo        = Normalize-Null $user.ext_authn_duo
            ext_authn_uid        = Normalize-Null $user.ext_authn_uid
            has_mfa              = Normalize-Null $user.has_mfa
            last_success_login   = Normalize-Null $user.last_success_login
            has_rsa_public_key   = Normalize-Null $user.has_rsa_public_key
        }

        $userId = Get-MD5Hash -String "$($account.account_locator)-USER-$($user.login_name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $userId -Kind SNOW_User -Properties $userProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $userId))
        if($user.owner -ne "")
        {
            $ownerId = Get-MD5Hash -String "$($account.account_locator)-ROLE-$($user.owner)"
            $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Owns -StartId $ownerId -EndId $userId))
        }
    }

    # SELECT * FROM snowflake.account_usage.roles;
    foreach($role in (Get-Content "$($Path)/roles.csv" | ConvertFrom-Csv | Where-Object {$_.DELETED_ON -eq ""}))
    {
        $roleProps = [PSCustomObject]@{
            role_id            = Normalize-Null $role.role_id
            created_on         = Normalize-Null $role.created_on
            name               = Normalize-Null $role.name
            role_type          = Normalize-Null $role.role_type
            role_database_name = Normalize-Null $role.role_database_name
            role_instance_id   = Normalize-Null $role.role_instance_id
        }

        $roleId = Get-MD5Hash -String "$($account.account_locator)-ROLE-$($role.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $roleId -Kind 'SNOW_Role' -Properties $roleProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $roleId))
        if($role.owner -ne "")
        {
            $ownerId = Get-MD5Hash -String "$($account.account_locator)-$($role.owner_role_type)-$($role.owner)"
            $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Owns -StartId $ownerId -EndId $roleId))
        }
    }

    # SHOW WAREHOUSES;
    foreach($warehouse in (Get-Content "$($Path)/warehouses.csv" | ConvertFrom-Csv))
    {
        $warehouseProps = [PSCustomObject]@{
            name  = Normalize-Null $warehouse.name
            state = Normalize-Null $warehouse.state
            type  = Normalize-Null $warehouse.type
            size  = Normalize-Null $warehouse.size
            owner = Normalize-Null $warehouse.owner
        }

        $warehouseId = Get-MD5Hash -String "$($account.account_locator)-WAREHOUSE-$($warehouse.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $warehouseId -Kind SNOW_Warehouse -Properties $warehouseProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $warehouseId))
        if($warehouse.owner -ne "")
        {
            $ownerId = Get-MD5Hash -String "$($account.account_locator)-$($warehouse.owner_role_type)-$($warehouse.owner)"
            $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Owns -StartId $ownerId -EndId $warehouseId))
        }
    }

    # SHOW APPLICATIONS;
    foreach($application in (Get-Content "$($Path)/applications.csv" | ConvertFrom-Csv))
    {
        $applicationProps = [PSCustomObject]@{
            name = $application.name
            created_on = $application.created_on
            source_type = $application.source_type
            source = $application.source
        }

        $applicationId = Get-MD5Hash -String "$($account.account_locator)-APPLICATION-$($application.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $applicationId -Kind SNOW_Application -Properties $applicationProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $applicationId))
        #if($application.owner -ne "")
        #{
        #    $ownerId = Get-MD5Hash -String "$($account.account_locator)-$($database.owner_role_type)-$($application.owner)"
        #    $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Owns -StartId $ownerId -EndId $applicationId))
        #}
    }

    # SELECT * FROM snowflake.account_usage.databases;
    foreach($database in (Get-Content "$($Path)/databases.csv" | ConvertFrom-Csv))
    {
        $databaseProps = [PSCustomObject]@{
            database_id       = Normalize-Null $database.id
            name              = Normalize-Null $database.database_name
            is_transient      = Normalize-Null $database.is_transient
            created           = Normalize-Null $database.created_on
            last_altered      = Normalize-Null $database.last_altered
            retention_time    = Normalize-Null $database.retention_time
            resource_group    = Normalize-Null $database.resource_group
            type              = Normalize-Null $database.type
            owner_role_type   = Normalize-Null $database.owner_role_type
            object_visibility = Normalize-Null $database.object_visibility
        }

        $databaseId = Get-MD5Hash -String "$($account.account_locator)-DATABASE-$($database.database_name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $databaseId -Kind SNOW_Database -Properties $databaseProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $databaseId))
        if($database.database_owner -ne "")
        {
            $ownerId = Get-MD5Hash -String "$($account.account_locator)-$($database.owner_role_type)-$($database.database_owner)"
            $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Owns -StartId $ownerId -EndId $databaseId))
        }
    }

    # SHOW SCHEMAS;
    foreach($schema in (Get-Content "$($Path)/schemas.csv" | ConvertFrom-Csv))
    {
        $schemaProps = [PSCustomObject]@{
            name = $schema.name
            created_on = $schema.created_on
            is_default = $schema.is_default
            is_current = $schema.is_current
        }

        $schemaId = Get-MD5Hash -String "$($account.account_locator)-SCHEMA-$($schema.database_name)\$($schema.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $schemaId -Kind SNOW_Schema -Properties $schemaProps))
        $databaseId = Get-MD5Hash -String "$($account.account_locator)-DATABASE-$($schema.database_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $schemaId))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $databaseId -EndId $schemaId))
        if($schema.owner -ne "")
        {
            $ownerId = Get-MD5Hash -String "$($account.account_locator)-$($schema.owner_role_type)-$($schema.owner)"
            $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Owns -StartId $ownerId -EndId $schemaId))
        }
    }

    # SHOW INTEGRATIONS;
    # This will eventually need to be much more detailed because there are several integration types that each have more detailed information
    # e.g. DESC SECURITY INTEGRATION PINGONE_SSO
    foreach($integration in (Get-Content "$($Path)/integrations.csv" | ConvertFrom-Csv))
    {
        $integrationProps = [PSCustomObject]@{
            name       = Normalize-Null $integration.name
            type       = Normalize-Null $integration.type
            category   = Normalize-Null $integration.category
            enabled    = Normalize-Null $integration.enabled
            created_on = Normalize-Null $integration.created_on
        }

        $integrationId = Get-MD5Hash -String "$($account.account_locator)-INTEGRATION-$($integration.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $integrationId -Kind SNOW_Integration -Properties $integrationProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Contains -StartId $accountId -EndId $integrationId))
    }

    # SELECT * FROM snowflake.account_usage.grants_to_users;
    foreach($grant_to_user in (Get-Content "$($Path)/grants_to_users.csv" | ConvertFrom-Csv | Where-Object {$_.DELETED_ON -eq ""}))
    {
        $userId = Get-MD5Hash -String "$($account.account_locator)-$($grant_to_user.GRANTED_TO)-$($grant_to_user.GRANTEE_NAME)"
        $roleId = Get-MD5Hash -String "$($account.account_locator)-ROLE-$($grant_to_user.ROLE)"
        $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Usage -StartId $userId -EndId $roleId))
    }

    # SELECT * FROM snowflake.account_usage.grants_to_roles WHERE GRANTED_ON IN ('ACCOUNT', 'APPLICATION', 'DATABASE', 'INTEGRATION', 'ROLE', 'SCHEMA', 'USER', 'WAREHOUSE'); 
    foreach($grant_to_role in (Get-Content "$($Path)/grants_to_roles.csv" | ConvertFrom-Csv))
    {
        switch($grant_to_role.GRANTED_TO)
        {
            APPLICATION_ROLE { $type = 'ROLE' }
            DEFAULT { $type = $grant_to_role.GRANTED_TO }
        }
        $startId = Get-MD5Hash -String "$($account.account_locator)-$($type)-$($grant_to_role.GRANTEE_NAME)"
        if($grant_to_role.GRANTED_ON -eq "SCHEMA")
        {
            $name = "$($grant_to_role.TABLE_CATALOG)\$($grant_to_role.NAME)"
        }
        else 
        {
            $name = $grant_to_role.NAME
        }
        $endId = Get-MD5Hash -String "$($account.account_locator)-$($grant_to_role.GRANTED_ON)-$($name)"
        #Write-Host "$($name)->$($endId)"

        switch($grant_to_role.PRIVILEGE){
            'USAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Usage -StartId $startId -EndId $endId)) }
            'OWNERSHIP'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Ownership -StartId $startId -EndId $endId)) }
            'APPLYBUDGET'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyBudget -StartId $startId -EndId $endId)) }
            'AUDIT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Audit -StartId $startId -EndId $endId)) }
            'MODIFY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Modify -StartId $startId -EndId $endId)) }
            'MONITOR'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Monitor -StartId $startId -EndId $endId)) }
            'OPERATE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Operate -StartId $startId -EndId $endId)) }
            'APPLY AGGREGATION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyAggregationPolicy -StartId $startId -EndId $endId)) }
            'APPLY AUTHENTICATION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyAuthenticationPolicy -StartId $startId -EndId $endId)) }
            'APPLY MASKING POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyMaskingPolicy -StartId $startId -EndId $endId)) }
            'APPLY PACKAGES POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyPackagesPolicy -StartId $startId -EndId $endId)) }
            'APPLY PASSWORD POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyPasswordPolicy -StartId $startId -EndId $endId)) }
            'APPLY PROTECTION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyProtectionPolicy -StartId $startId -EndId $endId)) }
            'APPLY ROW ACCESS POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyRowAccessPolicy -StartId $startId -EndId $endId)) }
            'APPLY SESSION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplySessionPolicy -StartId $startId -EndId $endId)) }
            'ATTACH POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_AttachPolicy -StartId $startId -EndId $endId)) }
            'BIND SERVICE ENDPOINT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_BindServiceEndpoint -StartId $startId -EndId $endId)) }
            'CANCEL QUERY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CancelQuery -StartId $startId -EndId $endId)) }
            'CREATE ACCOUNT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateAccount -StartId $startId -EndId $endId)) }
            'CREATE API INTEGRATION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateApiIntegration -StartId $startId -EndId $endId)) }
            'CREATE APPLICATION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateApplication -StartId $startId -EndId $endId)) }
            'CREATE APPLICATION PACKAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateApplicationPackage -StartId $startId -EndId $endId)) }
            'CREATE COMPUTE POOL'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateComputerPool -StartId $startId -EndId $endId)) }
            'CREATE CREDENTIAL'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateCredential -StartId $startId -EndId $endId)) }
            'CREATE DATA EXCHANGE LISTING'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateDataExchangeListing -StartId $startId -EndId $endId)) }
            'CREATE DATABASE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateDatabase -StartId $startId -EndId $endId)) }
            'CREATE DATABASE ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateDatabaseRole -StartId $startId -EndId $endId)) }
            'CREATE EXTERNAL VOLUME'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateExternalVolume -StartId $startId -EndId $endId)) }
            'CREATE INTEGRATION' { $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateIntegration -StartId $startId -EndId $endId)) }
            'CREATE NETWORK POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateNetworkPolicy -StartId $startId -EndId $endId)) }
            'CREATE REPLICATION GROUP'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateReplicationGroup -StartId $startId -EndId $endId)) }
            'CREATE ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateRole -StartId $startId -EndId $endId)) }
            'CREATE SCHEMA'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateSchema -StartId $startId -EndId $endId)) }
            'CREATE SHARE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateShare -StartId $startId -EndId $endId)) }
            'CREATE USER'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateUser -StartId $startId -EndId $endId)) }
            'CREATE WAREHOUSE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_CreateWarehouse -StartId $startId -EndId $endId)) }
            'EXECUTE DATA METRIC FUNCTION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ExecuteDataMetricFunction -StartId $startId -EndId $endId)) }
            'EXECUTE MANAGED ALERT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ExecuteManagedAlert -StartId $startId -EndId $endId)) }
            'EXECUTE TASK'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ExecuteTask -StartId $startId -EndId $endId)) }
            'IMPORT SHARE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ImportShare -StartId $startId -EndId $endId)) }
            'MANAGE GRANTS'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ManageGrants -StartId $startId -EndId $endId)) }
            'MANAGE WAREHOUSES'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ManageWarehouses -StartId $startId -EndId $endId)) }
            'MANAGEMENT SHARING'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ManagementSharing -StartId $startId -EndId $endId)) }
            'MONITOR EXECUTION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_MonitorExecution -StartId $startId -EndId $endId)) }
            'OVERRIDE SHARE RESTRICTIONS'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_OverrideShareRestrictions -StartId $startId -EndId $endId)) }
            'PURCHASE DATA EXCHANGE LISTING'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_PurchaseDataExchangeListing -StartId $startId -EndId $endId)) }
            'REFERENCE USAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ReferenceUsage -StartId $startId -EndId $endId)) }
            'USE ANY ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_UseAnyRole -StartId $startId -EndId $endId)) }
        }
    }

    $payload = [PSCustomObject]@{
        metadata = [PSCustomObject]@{
            source_kind = "SNOW_Base"
        }
        graph = [PSCustomObject]@{
            nodes = $nodes.ToArray()
            edges = $edges.ToArray()
        }
    } | ConvertTo-Json -Depth 10

    $payload | Out-File -FilePath "./snowhound_$($account.account_locator).json"
    #$payload | BHDataUploadJSON -Verbose
}
