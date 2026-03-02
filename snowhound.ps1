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
        $EndId,

        [Parameter(Mandatory = $false)]
        [String]
        $StartKind,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('id', 'name')]
        [String]
        $StartMatchBy = 'id',

        [Parameter(Mandatory = $false)]
        [String]
        $EndKind,

        [Parameter(Mandatory = $false)]
        [ValidateSet('id', 'name')]
        [String]
        $EndMatchBy = 'id'
    )

    $edge = @{
        kind = $Kind
        start = @{
            value = $StartId
        }
        end = @{
            value = $EndId
        }
        properties = @{}
    }

    if($PSBoundParameters.ContainsKey('StartKind')) 
    {
        $edge.start.Add('kind', $StartKind)
    }
    if($PSBoundParameters.ContainsKey('StartMatchBy')) 
    {
        $edge.start.Add('match_by', $StartMatchBy)
    }
    if($PSBoundParameters.ContainsKey('EndKind'))
    {
        $edge.end.Add('kind', $EndKind)
    }
    if($PSBoundParameters.ContainsKey('EndMatchBy')) 
    {
        $edge.end.Add('match_by', $EndMatchBy)
    }

    Write-Output $edge
}

<#
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
#>

function Normalize-Null
{
    param($Value)
    if ($null -eq $Value) { return "" }
    return $Value
}

function ConvertTo-PascalCase {
    param (
        [string]$String
    )

    if ([string]::IsNullOrEmpty($String)) {
        return $String
    }

    # Replace common delimiters with spaces and convert to lowercase to handle various input formats
    $cleanedString = $String -replace '[-_]', ' ' | ForEach-Object { $_.ToLower() }

    # Use TextInfo.ToTitleCase to capitalize the first letter of each word
    # Then remove spaces to achieve PascalCase
    $pascalCaseString = (Get-Culture).TextInfo.ToTitleCase($cleanedString).Replace(' ', '')

    return $pascalCaseString
}

function Invoke-SnowHound
{
    $nodes = New-Object System.Collections.ArrayList
    $edges = New-Object System.Collections.ArrayList

    $account = snow sql -q "SELECT * FROM snowflake.organization_usage.accounts WHERE account_locator = CURRENT_ACCOUNT();" --format json | ConvertFrom-Json

    $accountProps = [PSCustomObject]@{
        name              = Normalize-Null $account.account_name
        organization_name = Normalize-Null $account.organization_name
        account_name      = Normalize-Null $account.account_name
        fqdn              = Normalize-Null "$($account.account_name).$($account.organization_name)"
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

    # Collect Account Information
    $accountId = "$($account.organization_name)-$($account.account_name)"
    $null = $nodes.Add((New-SnowflakeNode -Id $accountId -Kind "SNOW_Account" -Properties $accountProps))

    # Collect Users
    foreach($user in (snow object list user --format json | ConvertFrom-Json))
    {
        $userProps = [PSCustomObject]@{
            name                    = Normalize-Null $user.name
            fqdn                    = Normalize-Null "$($user.name)@$($account.account_name).$($account.organization_name)"
            created_on              = Normalize-Null $user.created_on
            login_name              = Normalize-Null $user.login_name
            display_name            = Normalize-Null $user.display_name
            first_name              = Normalize-Null $user.first_name
            last_name               = Normalize-Null $user.last_name
            email                   = Normalize-Null $user.email
            mins_to_unlock          = Normalize-Null $user.mins_to_unlock
            days_to_expiry          = Normalize-Null $user.days_to_expiry
            comment                 = Normalize-Null $user.comment
            disabled                = Normalize-Null $user.disabled
            must_change_password    = Normalize-Null $user.must_change_password
            snowflake_lock          = Normalize-Null $user.snowflake_lock
            default_warehouse       = Normalize-Null $user.default_warehouse
            default_namespace       = Normalize-Null $user.default_namespace
            default_role            = Normalize-Null $user.default_role
            default_secondary_roles = Normalize-Null $user.default_secondary_roles -join ","
            ext_authn_duo           = Normalize-Null $user.ext_authn_duo
            ext_authn_uid           = Normalize-Null $user.ext_authn_uid
            mins_to_bypass_mfa      = Normalize-Null $user.mins_to_bypass_mfa
            owner                   = Normalize-Null $user.owner
            last_successful_login   = Normalize-Null $user.last_successful_login
            expires_at_time         = Normalize-Null $user.expires_at_time
            locked_until_time       = Normalize-Null $user.locked_until_time
            has_password            = Normalize-Null $user.has_password
            has_rsa_public_key      = Normalize-Null $user.has_rsa_public_key
            type                    = Normalize-Null $user.type
            has_mfa                 = Normalize-Null $user.has_mfa
            has_pat                 = Normalize-Null $user.has_pat
            has_workload_identity   = Normalize-Null $user.has_workload_identity
        }

        $userId = "$($accountId).$($user.login_name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $userId -Kind "SNOW_User" -Properties $userProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $userId))
    }

    # Collect Roles
    foreach($role in (snow object list role --format json | ConvertFrom-Json))
    {
        $roleProps = [PSCustomObject]@{
            name              = Normalize-Null $role.name
            fqdn              = Normalize-Null "$($role.name)@$($account.account_name).$($account.organization_name)"
            created_on        = Normalize-Null $role.created_on
            is_default        = Normalize-Null $role.is_default
            is_current        = Normalize-Null $role.is_current
            is_inherited      = Normalize-Null $role.is_inherited
            assigned_to_users = Normalize-Null $role.assigned_to_users
            granted_to_roles  = Normalize-Null $role.granted_to_roles
            granted_roles     = Normalize-Null $role.granted_roles
            owner             = Normalize-Null $role.owner
            comment           = Normalize-Null $role.comment
        }

        $roleId = "$($accountId).$($role.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $roleId -Kind "SNOW_Role" -Properties $roleProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $roleId))
    }

    # Collect Applications and Application Roles
    foreach ($application in (snow sql -q "SHOW APPLICATIONS" --format json | ConvertFrom-Json))
    {
        $appProps = [PSCustomObject]@{
            name                 = Normalize-Null $application.name
            fqdn                 = Normalize-Null "$($application.name)@$($account.account_name).$($account.organization_name)"
            created_on           = Normalize-Null $application.created_on
            is_default           = Normalize-Null $application.is_default
            is_current           = Normalize-Null $application.is_current
            source_type          = Normalize-Null $application.source_type
            owner                = Normalize-Null $application.owner
            comment              = Normalize-Null $application.comment
            version              = Normalize-Null $application.version
            label                = Normalize-Null $application.label
            patch                = Normalize-Null $application.patch
            options              = Normalize-Null $application.options
            retention_time       = Normalize-Null $application.retention_time
            upgrade_state        = Normalize-Null $application.upgrade_state
            disablement_reasons  = Normalize-Null $application.disablement_reasons
            last_upgraded_on     = Normalize-Null $application.last_upgraded_on
            release_channel_name = Normalize-Null $application.release_channel_name
            type                 = Normalize-Null $application.type    
        }

        $appId = "$($accountId).$($application.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $appId -Kind "SNOW_Application" -Properties $appProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $appId))

        foreach($appRole in (snow sql -q "SHOW APPLICATION ROLES IN APPLICATION $($application.name)" --format json | ConvertFrom-Json))
        {
            $appRoleProps = [PSCustomObject]@{
                name            = Normalize-Null $appRole.name
                created_on      = Normalize-Null $appRole.created_on
                owner           = Normalize-Null $appRole.owner
                comment         = Normalize-Null $appRole.comment
                owner_role_type = Normalize-Null $appRole.owner_role_type
            }

            # This one is maybe questionable whether it is the appropriate object identifier
            $appRoleId = "$($accountId).$($appRole.owner).$($appRole.name)"
            $null = $nodes.Add((New-SnowflakeNode -Id $appRoleId -Kind "SNOW_ApplicationRole" -Properties $appRoleProps))
            $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $appId -EndId $appRoleId))
            $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $appRoleId))
        }
    }

    # Collect Warehouses
    foreach($wh in (snow object list warehouse --format json | ConvertFrom-Json))
    {
        $warehouseProps = [PSCustomObject]@{
            name                   = Normalize-Null $wh.name
            fqdn                   = Normalize-Null "$($wh.name)@$($account.account_name).$($account.organization_name)"
            state                  = Normalize-Null $wh.state
            type                   = Normalize-Null $wh.type
            size                   = Normalize-Null $wh.size
            running                = Normalize-Null $wh.running
            queued                 = Normalize-Null $wh.queued
            is_default             = Normalize-Null $wh.is_default
            is_current             = Normalize-Null $wh.is_current
            auto_suspend           = Normalize-Null $wh.auto_suspend
            auto_resume            = Normalize-Null $wh.auto_resume
            available              = Normalize-Null $wh.available
            provisioning           = Normalize-Null $wh.provisioning
            quiescing              = Normalize-Null $wh.quiescing
            other                  = Normalize-Null $wh.other
            created_on             = Normalize-Null $wh.created_on
            resumed_on             = Normalize-Null $wh.resumed_on
            updated_on             = Normalize-Null $wh.updated_on
            owner                  = Normalize-Null $wh.owner
            comment                = Normalize-Null $wh.comment
            resource_monitor       = Normalize-Null $wh.resource_monitor
            actives                = Normalize-Null $wh.actives
            pendings               = Normalize-Null $wh.pendings
            failed                 = Normalize-Null $wh.failed
            suspended              = Normalize-Null $wh.suspended
            uuid                   = Normalize-Null $wh.uuid
            owner_role_type        = Normalize-Null $wh.owner_role_type
            resource_constraint    = Normalize-Null $wh.resource_constraint
            warehouse_credit_limit = Normalize-Null $wh.warehouse_credit_limit
            target_statement_size  = Normalize-Null $wh.target_statement_size
            disabled_reasons       = Normalize-Null $wh.disabled_reasons
        }

        $warehouseId = "$($accountId).$($wh.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $warehouseId -Kind "SNOW_Warehouse" -Properties $warehouseProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $warehouseId))
    }

    # Collect Databases
    foreach($db in (snow object list database --format json | ConvertFrom-Json))
    {
        $databaseProps = [PSCustomObject]@{
            name              = Normalize-Null $db.name
            fqdn              = Normalize-Null "$($db.name)@$($account.account_name).$($account.organization_name)"
            created_on        = Normalize-Null $db.created_on
            is_default        = Normalize-Null $db.is_default
            is_current        = Normalize-Null $db.is_current
            origin            = Normalize-Null $db.origin
            owner             = Normalize-Null $db.owner
            comment           = Normalize-Null $db.comment
            options           = Normalize-Null $db.options
            retention_time    = Normalize-Null $db.retention_time
            kind              = Normalize-Null $db.kind
            owner_role_type   = Normalize-Null $db.owner_role_type
            object_visibility = Normalize-Null $db.object_visibility
        }

        $databaseId = "$($accountId).$($db.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $databaseId -Kind "SNOW_Database" -Properties $databaseProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $databaseId))

        # Need to figure out how to handle Database Roles
        <#
        foreach($dbRole in (snow sql -q "SHOW DATABASE ROLES IN DATABASE $($db.name)" --format json | ConvertFrom-Json))
        {
            $dbRoleProps = [PSCustomObject]@{
                name                      = Normalize-Null $dbRole.name
                created_on                = Normalize-Null $dbRole.created_on
                is_default                = Normalize-Null $dbRole.is_default
                is_current                = Normalize-Null $dbRole.is_current
                is_inherited              = Normalize-Null $dbRole.is_inherited
                granted_to_roles          = Normalize-Null $dbRole.granted_to_roles
                granted_to_database_roles = Normalize-Null $dbRole.granted_to_database_roles
                granted_database_roles    = Normalize-Null $dbRole.granted_database_roles
                owner                     = Normalize-Null $dbRole.owner
                comment                   = Normalize-Null $dbRole.comment
                owner_role_type           = Normalize-Null $dbRole.owner_role_type
            }

            $dbRoleId = "$($accountId).$($db.name).$($dbRole.name)"
            $null = $nodes.Add((New-SnowHoundNode -Id $dbRoleId -Kind "SNOW_DatabaseRole" -Properties $dbRoleProps))
            $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $databaseId -EndId $dbRoleId))
            $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $dbRoleId))
        }
        #>
    }

    # Collect Schemas
    # Naming Convention Derived from: https://docs.snowflake.com/en/sql-reference/identifiers
    foreach($schema in (snow object list schema --format json | ConvertFrom-Json))
    {
        $schemaProps = [PSCustomObject]@{
            name                            = Normalize-Null $schema.name
            fqdn                            = Normalize-Null "$($schema.database_name).$($schema.name)@$($account.account_name).$($account.organization_name)"
            database_name                   = Normalize-Null $schema.database_name
            created_on                      = Normalize-Null $schema.created_on
            is_default                      = Normalize-Null $schema.is_default
            is_current                      = Normalize-Null $schema.is_current
            owner                           = Normalize-Null $schema.owner
            comment                         = Normalize-Null $schema.comment
            options                         = Normalize-Null $schema.options
            retention_time                  = Normalize-Null $schema.retention_time
            owner_role_type                 = Normalize-Null $schema.owner_role_type
            classification_profile_database = Normalize-Null $schema.classification_profile_database
            classification_profile_schema   = Normalize-Null $schema.classification_profile_schema
            classification_profile          = Normalize-Null $schema.classification_profile
            object_visibility               = Normalize-Null $schema.object_visibility
        }

        $schemaId = "$($accountId).$($schema.database_name).$($schema.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $schemaId -Kind "SNOW_Schema" -Properties $schemaProps))
        $databaseId = "$($accountId).$($schema.database_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $schemaId))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $databaseId -EndId $schemaId))
    }

    <#
    # Collect Functions
    foreach($function in (snow object list function --format json | ConvertFrom-Json | Where-Object {$_.catalog_name -ne ""}))
    {
        $functionProps = [PSCustomObject]@{
            name                         = Normalize-Null $function.name
            fqdn                         = Normalize-Null "$($function.catalog_name).$($function.schema_name).$($function.name)@$($account.account_name).$($account.organization_name)"
            created_on                   = Normalize-Null $function.created_on
            schema_name                  = Normalize-Null $function.schema_name
            is_builtin                   = Normalize-Null $function.is_builtin
            is_aggregate                 = Normalize-Null $function.is_aggregate
            is_ansi                      = Normalize-Null $function.is_ansi
            min_num_arguments            = Normalize-Null $function.min_num_arguments
            max_num_arguments            = Normalize-Null $function.max_num_arguments
            arguments                    = Normalize-Null $function.arguments
            description                  = Normalize-Null $function.description
            catalog_name                 = Normalize-Null $function.catalog_name
            is_table_function            = Normalize-Null $function.is_table_function
            valid_for_clustering         = Normalize-Null $function.valid_for_clustering
            is_secure                    = Normalize-Null $function.is_secure
            secrets                      = Normalize-Null $function.secrets
            external_access_integrations = Normalize-Null $function.external_access_integrations
            is_external_function         = Normalize-Null $function.is_external_function
            language                     = Normalize-Null $function.language
            is_memoizable                = Normalize-Null $function.is_memoizable
            is_data_metric               = Normalize-Null $function.is_data_metric
        }

        $functionId = "$($accountId).$($function.catalog_name).$($function.schema_name).$($function.name)"
        $null = $nodes.Add((New-SnowHoundNode -Id $functionId -Kind "SNOW_Function" -Properties $functionProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $functionId))
        $schemaId = "$($accountId).$($function.catalog_name).$($function.schema_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $schemaId -EndId $functionId))
    }

    # Collect Procedures
    foreach($procedure in (snow object list procedure --format json | ConvertFrom-Json | Where-Object {$_.catalog_name -ne ""}))
    {
        $procedureProps = [PSCustomObject]@{
            name                         = Normalize-Null $procedure.name
            fqdn                         = Normalize-Null "$($procedure.catalog_name).$($procedure.schema_name).$($procedure.name)@$($account.account_name).$($account.organization_name)"
            created_on                   = Normalize-Null $procedure.created_on
            schema_name                  = Normalize-Null $procedure.schema_name
            is_builtin                   = Normalize-Null $procedure.is_builtin
            is_aggregate                 = Normalize-Null $procedure.is_aggregate
            is_ansi                      = Normalize-Null $procedure.is_ansi
            min_num_arguments            = Normalize-Null $procedure.min_num_arguments
            max_num_arguments            = Normalize-Null $procedure.max_num_arguments
            arguments                    = Normalize-Null $procedure.arguments
            description                  = Normalize-Null $procedure.description
            catalog_name                 = Normalize-Null $procedure.catalog_name
            is_table_function            = Normalize-Null $procedure.is_table_function
            valid_for_clustering         = Normalize-Null $procedure.valid_for_clustering
            is_secure                    = Normalize-Null $procedure.is_secure
            secrets                      = Normalize-Null $procedure.secrets
            external_access_integrations = Normalize-Null $procedure.external_access_integrations
        }

        $procedureId = "$($accountId).$($procedure.catalog_name).$($procedure.schema_name).$($procedure.name)"
        $null = $nodes.Add((New-SnowHoundNode -Id $procedureId -Kind "SNOW_Procedure" -Properties $procedureProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $procedureId))
        $schemaId = "$($accountId).$($procedure.catalog_name).$($procedure.schema_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $schemaId -EndId $procedureId))
    }
    #>

    # Collect Stages
    foreach($stage in (snow object list stage --format json | ConvertFrom-Json))
    {
        $stageProps = [PSCustomObject]@{
            name                 = Normalize-Null $stage.name
            fqdn                 = Normalize-Null "$($stage.database_name).$($stage.schema_name).$($stage.name)@$($account.account_name).$($account.organization_name)"
            created_on           = Normalize-Null $stage.created_on
            database_name        = Normalize-Null $stage.database_name
            schema_name          = Normalize-Null $stage.schema_name
            url                  = Normalize-Null $stage.url
            has_credentials      = Normalize-Null $stage.has_credentials
            has_encryption_key   = Normalize-Null $stage.has_encryption_key
            owner                = Normalize-Null $stage.owner
            comment              = Normalize-Null $stage.comment
            region               = Normalize-Null $stage.region
            type                 = Normalize-Null $stage.type
            cloud                = Normalize-Null $stage.cloud
            notification_channel = Normalize-Null $stage.notification_channel
            storage_integration  = Normalize-Null $stage.storage_integration
            endpoint             = Normalize-Null $stage.endpoint
            owner_role_type      = Normalize-Null $stage.owner_role_type
            directory_enabled    = Normalize-Null $stage.directory_enabled
        }

        $stageId = "$($accountId).$($stage.database_name).$($stage.schema_name).$($stage.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $stageId -Kind "SNOW_Stage" -Properties $stageProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $stageId))
        $schemaId = "$($accountId).$($stage.database_name).$($stage.schema_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $schemaId -EndId $stageId))
    }

    # Collect Tables
    foreach($table in (snow object list table --format json | ConvertFrom-Json))
    {
        $tableProps = [PSCustomObject]@{
            name                    = Normalize-Null $table.name
            fqdn                    = Normalize-Null "$($table.database_name).$($table.schema_name).$($table.name)@$($account.account_name).$($account.organization_name)"
            created_on              = Normalize-Null $table.created_on
            database_name           = Normalize-Null $table.database_name
            schema_name             = Normalize-Null $table.schema_name
            kind                    = Normalize-Null $table.kind
            comment                 = Normalize-Null $table.comment
            cluster_by              = Normalize-Null $table.cluster_by
            rows                    = Normalize-Null $table.rows
            bytes                   = Normalize-Null $table.bytes
            owner                   = Normalize-Null $table.owner
            retention_time          = Normalize-Null $table.retention_time
            change_tracking         = Normalize-Null $table.change_tracking
            is_external             = Normalize-Null $table.is_external
            enable_schema_evolution = Normalize-Null $table.enable_schema_evolution
            owner_role_type         = Normalize-Null $table.owner_role_type
            is_event                = Normalize-Null $table.is_event
            is_hybrid               = Normalize-Null $table.is_hybrid
            is_iceberg              = Normalize-Null $table.is_iceberg
            is_dynamic              = Normalize-Null $table.is_dynamic
            is_immutable            = Normalize-Null $table.is_immutable
        }

        $tableId = "$($accountId).$($table.database_name).$($table.schema_name).$($table.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $tableId -Kind "SNOW_Table" -Properties $tableProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $tableId))
        $schemaId = "$($accountId).$($table.database_name).$($table.schema_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $schemaId -EndId $tableId))
    }

    # Collect Views
    foreach($view in (snow object list view --format json | ConvertFrom-Json))
    {
        $viewProps = [PSCustomObject]@{
            name             = Normalize-Null $view.name
            fqdn             = Normalize-Null "$($view.database_name).$($view.schema_name).$($view.name)@$($account.account_name).$($account.organization_name)"
            created_on       = Normalize-Null $view.created_on
            reserved         = Normalize-Null $view.reserved
            database_name    = Normalize-Null $view.database_name
            schema_name      = Normalize-Null $view.schema_name
            owner            = Normalize-Null $view.owner
            comment          = Normalize-Null $view.comment
            text             = Normalize-Null $view.text
            is_secure        = Normalize-Null $view.is_secure
            isi_materialized = Normalize-Null $view.is_materialized
            owner_role_type  = Normalize-Null $view.owner_role_type
            change_tracking  = Normalize-Null $view.change_tracking
        }

        $viewId = "$($accountId).$($view.database_name).$($view.schema_name).$($view.name)"
        $null = $nodes.Add((New-SnowflakeNode -Id $viewId -Kind "SNOW_View" -Properties $viewProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $viewId))
        $schemaId = "$($accountId).$($view.database_name).$($view.schema_name)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $schemaId -EndId $viewId))
    }

    # Collect Integrations
    foreach($int in (snow object list integration --format json | ConvertFrom-Json))
    {
        $integrationProps = [PSCustomObject]@{
            name       = Normalize-Null $int.name
            fqdn       = Normalize-Null "$($int.name)@$($account.account_name).$($account.organization_name)"
            type       = Normalize-Null $int.type
            category   = Normalize-Null $int.category
            created_on = Normalize-Null $int.created_on
        }

        $integrationId = "$($accountId).$($int.name)"
        
        switch ($int.category)
        {
            'API' {}
            'CATALOG' {}
            'EXTERNAL_ACCESS' {}
            'NOTIFICATION' {}
            'SECURITY' {
                foreach($property in ($secIntegration = snow sql -q "DESCRIBE SECURITY INTEGRATION $($int.name)" --format json | ConvertFrom-Json))
                {
                    if($property.property.toLower() -eq 'run_as_role')
                    {
                        $runasroleId = "$($accountId).$($property.property_value)"
                        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_RunAsRole" -StartId $integrationId -EndId $runasroleId))
                    }
                    $integrationProps | Add-Member -MemberType NoteProperty -Name $property.property.toLower() -Value (Normalize-Null $property.property_value)
                }
            }
            'STORAGE' {}
        }
        
        $null = $nodes.Add((New-SnowflakeNode -Id $integrationId -Kind "SNOW_Integration" -Properties $integrationProps))
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Contains" -StartId $accountId -EndId $integrationId))
    }

    # Collect Grants to Users
    foreach($grant_to_user in (snow sql -q "SELECT * FROM snowflake.account_usage.grants_to_users" --format json | ConvertFrom-Json | Where-Object {$_.DELETED_ON -eq $null}))
    {
        $userId = "$($accountId).$($grant_to_user.GRANTEE_NAME)"
        $roleId = "$($accountId).$($grant_to_user.ROLE)"
        $null = $edges.Add((New-SnowflakeEdge -Kind "SNOW_Usage" -StartId $userId -EndId $roleId))
    }

    # Collect Grants to Roles
    foreach($grant_to_role in (snow sql -q "SELECT * FROM snowflake.account_usage.grants_to_roles WHERE GRANTED_ON IN ('ACCOUNT', 'APPLICATION', 'DATABASE', 'INTEGRATION', 'ROLE', 'SCHEMA', 'STAGE', 'TABLE', 'USER', 'VIEW', 'WAREHOUSE');" --format json | ConvertFrom-Json | Where-Object {$_.DELETED_ON -eq $null}))
    {
        $startKind = "SNOW_$(ConvertTo-PascalCase -String $grant_to_role.GRANTED_TO)"
        $edgeKind = "SNOW_$(ConvertTo-PascalCase -String $grant_to_role.PRIVILEGE)"
        $endKind = "SNOW_$(ConvertTo-PascalCase -String $grant_to_role.GRANTED_ON)"

        switch($grant_to_role.GRANTED_TO)
        {
            APPLICATION_ROLE { $startId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.GRANTEE_NAME)" }   
            DEFAULT { $startId = "$($accountId).$($grant_to_role.GRANTEE_NAME)" }
        }
        
        switch($grant_to_role.GRANTED_ON)
        {
            ACCOUNT { $endId = "$($accountId)" }
            #DATABASE_ROLE { $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.NAME)" }
            SCHEMA { $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.NAME)" }
            FUNCTION {
                if($grant_to_role.TABLE_CATALOG -ne "")
                {
                    $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.TABLE_SCHEMA).$($grant_to_role.NAME)"
                }
            }
            PROCEDURE {
                if($grant_to_role.TABLE_CATALOG -ne "")
                {
                    $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.TABLE_SCHEMA).$($grant_to_role.NAME)"
                }
            }
            TABLE { $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.TABLE_SCHEMA).$($grant_to_role.NAME)" }
            VIEW { $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.TABLE_SCHEMA).$($grant_to_role.NAME)" }
            STAGE { $endId = "$($accountId).$($grant_to_role.TABLE_CATALOG).$($grant_to_role.TABLE_SCHEMA).$($grant_to_role.NAME)" }
            DEFAULT { $endId = "$($accountId).$($grant_to_role.NAME)" }
        }

        $null = $edges.Add((New-SnowflakeEdge -Kind $edgeKind -StartId $startId -StartKind $startKind -EndId $endId -EndKind $endKind))

        <#
        switch($grant_to_role.PRIVILEGE){
            'APPLYBUDGET'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ApplyBudget -StartId $startId -EndId $endId)) }
            'AUDIT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Audit -StartId $startId -EndId $endId)) }
            'DELETE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Delete -StartId $startId -EndId $endId)) }
            'INSERT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Insert -StartId $startId -EndId $endId)) }
            'MODIFY'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Modify -StartId $startId -EndId $endId)) }
            'MONITOR'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Monitor -StartId $startId -EndId $endId)) }
            'OPERATE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Operate -StartId $startId -EndId $endId)) }
            'OWNERSHIP'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Ownership -StartId $startId -EndId $endId)) }
            'READ'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Read -StartId $startId -EndId $endId)) }
            'REBUILD'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Rebuild -StartId $startId -EndId $endId)) }
            'REFERENCES'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_References -StartId $startId -EndId $endId)) }
            'SELECT'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Select -StartId $startId -EndId $endId)) }
            'TRUNCATE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Truncate -StartId $startId -EndId $endId)) }
            'UPDATE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Update -StartId $startId -EndId $endId)) }
            'USAGE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Usage -StartId $startId -EndId $endId)) }
            'WRITE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_Write -StartId $startId -EndId $endId)) }
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
            'SERVICE READ'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ServiceRead -StartId $startId -EndId $endId)) }
            'SERVICE WRITE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_ServiceWrite -StartId $startId -EndId $endId)) }
            'USE ANY ROLE'{ $null = $edges.Add((New-SnowflakeEdge -Kind SNOW_UseAnyRole -StartId $startId -EndId $endId)) }
            default { Write-Host "$($grant_to_role.GRANTED_TO):$($grant_to_role.PRIVILEGE):$($grant_to_role.GRANTED_ON) not mapped."}
        }
        #>
    }

    $payload = [PSCustomObject]@{
        metadata = [PSCustomObject]@{
            source_kind = "SNOW_Base"
        }
        graph = [PSCustomObject]@{
            nodes = $nodes
            edges = $edges
        }
    } | ConvertTo-Json -Depth 10

    $payload | Out-File -FilePath "./snowhound_$($accountId).json"
}
