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
        kinds = @($Kind, 'SNOWBase')
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

function Invoke-ShowHound
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]
        $Path = (Get-Location).Path
    )

    $nodes = New-Object System.Collections.ArrayList
    $edges = New-Object System.Collections.ArrayList

    foreach($account in (Get-Content "$($Path)/account.csv" | ConvertFrom-Csv))
    {
        $accountProps = [PSCustomObject]@{
            organization_name = $account.organization_name
            account_name = $account.account_name
            snowflake_region = $account.snowflake_region
            edition = $account.edition
            account_url = $account.account_url
            created_on = $account.created_on
            account_locator = $account.account_locator
            account_locator_url = $account.account_locator_url
            managed_accounts = $account.managed_accounts
        }
        $null = $nodes.Add((New-SnowflakeNode -Id $account.account_name -Kind SNOWAccount -Properties $accountProps))
    }

    foreach($user in (Get-Content "$($Path)//user.csv" | ConvertFrom-Csv))
    {
        $userProps = [PSCustomObject]@{
            name = $user.name
            created_on = $user.created_on
            login_name = $user.login_name
            display_name = $user.display_name
            first_name = $user.first_name
            last_name = $user.last_name
            email = $user.email
            disabled = $user.disabled
            must_change_password = $user.must_change_password
            snowflake_lock = $user.snowflake_lock
            default_warehouse = $user.default_warehouse
            default_namespace = $user.default_namespace
            default_role = $user.default_role
            ext_authn_duo = $user.ext_authn_duo
            owner = $user.owner
            last_success_login = $user.last_success_login
            has_password = $user.has_password
            has_rsa_public_key = $user.has_rsa_public_key
        }
         $null = $nodes.Add((New-SnowflakeNode -Id $user.login_name -Kind SNOWUser -Properties $userProps))
    }

    foreach($role in (Get-Content "$($Path)/role.csv" | ConvertFrom-Csv))
    {
        $roleProps = [PSCustomObject]@{
            created_on = $role.created_on
            name = $role.Name
            is_default = $role.is_default
            is_current = $role.is_current
            is_inherited = $role.is_inherited
            assigned_to_users = $role.assigned_to_users
            grated_to_roles = $role.granted_to_roles
            granted_roles = $role.granted_roles
            owner = $role.owner
        }
         $null = $nodes.Add((New-SnowflakeNode -Id $role.name -Kind SNOWRole -Properties $roleProps))
    }

    foreach($warehouse in (Get-Content "$($Path)/warehouse.csv" | ConvertFrom-Csv))
    {
        $warehouseProps = [PSCustomObject]@{
            name = $warehouse.name
            state = $warehouse.state
            type = $warehouse.type
            size = $warehouse.size
            owner = $warehouse.owner
        }
         $null = $nodes.Add((New-SnowflakeNode -Id $warehouse.name -Kind SNOWWarehouse -Properties $warehouseProps))
    }

    foreach($database in (Get-Content "$($Path)/database.csv" | ConvertFrom-Csv))
    {
        $databaseProps = [PSCustomObject]@{
            created_on = $database.created_on
            name = $database.Name
            is_default = $database.is_default
            is_current = $database.is_current
            origin = $database.origin
            owner = $database.owner
            kind = $database.kind
            #owner_role_type = $database.owner_role_type
        }
        $null =  $nodes.Add((New-SnowflakeNode -Id $database.name -Kind SNOWDatabase -Properties $databaseProps))
    }

    foreach($integration in (Get-Content "$($Path)/integration.csv" | ConvertFrom-Csv))
    {
        $integrationProps = [PSCustomObject]@{
            name = $integration.name
            type = $integration.type
            category = $integration.category
            enabled = $integration.enabled
            created_on = $integration.created_on
        }
         $null = $nodes.Add((New-SnowflakeNode -Id $integration.name -Kind SNOWIntegration -Properties $integrationProps))
    }

    foreach($grant_to_user in (Get-Content "$($Path)/grants_to_users.csv" | ConvertFrom-Csv))
    {
         $null = $edges.Add((New-SnowflakeEdge -Kind SNOWUsage -StartId $grant_to_user.GRANTEE_NAME -EndId $grant_to_user.ROLE))
    }

    foreach($grant_to_role in (Get-Content "$($Path)/grants_to_roles.csv" | ConvertFrom-Csv))
    {
        switch($grant_to_role.PRIVILEGE){
            'USAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWUsage -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'OWNERSHIP'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWOwnership -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLYBUDGET'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyBudget -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'AUDIT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWAudit -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'MODIFY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWModify -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'MONITOR'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWMonitor -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'OPERATE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWOperate -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY AGGREGATION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyAggregationPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY AUTHENTICATION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyAuthenticationPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY MASKING POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyMaskingPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY PACKAGES POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyPackagesPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY PASSWORD POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyPasswordPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY PROTECTION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyProtectionPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY ROW ACCESS POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplyRowAccessPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'APPLY SESSION POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWApplySessionPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'ATTACH POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWAttachPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'BIND SERVICE ENDPOINT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWBindServiceEndpoint -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CANCEL QUERY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCancelQuery -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE ACCOUNT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateAccount -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE API INTEGRATION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateApiIntegration -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE APPLICATION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateApplication -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE APPLICATION PACKAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateApplicationPackage -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE COMPUTE POOL'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateComputerPool -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE CREDENTIAL'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateCredential -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE DATA EXCHANGE LISTING'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateDataExchangeListing -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE DATABASE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateDatabase -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE DATABASE ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateDatabaseRole -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE EXTERNAL VOLUME'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateExternalVolume -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE INTEGRATION' { $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateIntegration -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE NETWORK POLICY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateNetworkPolicy -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE REPLICATION GROUP'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateReplicationGroup -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateRole -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE SCHEMA'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateSchema -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE SHARE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateShare -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE USER'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateUser -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'CREATE WAREHOUSE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWCreateWarehouse -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'EXECUTE DATA METRIC FUNCTION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWExecuteDataMetricFunction -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'EXECUTE MANAGED ALERT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWExecuteManagedAlert -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'EXECUTE TASK'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWExecuteTask -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'IMPORT SHARE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWImportShare -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'MANAGE GRANTS'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWManageGrants -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'MANAGE WAREHOUSES'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWManageWarehouses -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'MANAGEMENT SHARING'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWManagementSharing -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'MONITOR EXECUTION'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWMonitorExecution -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'OVERRIDE SHARE RESTRICTIONS'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWOverrideShareRestrictions -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'PURCHASE DATA EXCHANGE LISTING'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWPurchaseDataExchangeListing -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'REFERENCE USAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWReferenceUsage -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
            'USE ANY ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOWUseAnyRole -StartId $grant_to_role.GRANTEE_NAME -EndId $grant_to_role.NAME)) }
        }
    }

    $payload = [PSCustomObject]@{
        graph = [PSCustomObject]@{
            nodes = $nodes.ToArray()
            edges = $edges.ToArray()
        }
    } | ConvertTo-Json -Depth 10

    $payload | Out-File -FilePath ./snowhound_output.json
    #$payload | BHDataUploadJSON -Verbose
}
