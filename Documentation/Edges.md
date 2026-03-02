# Edge Documentation

## Structural Edges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_Contains](EdgeDescriptions/SNOW_Contains.md) | No | Structural containment relationship indicating the source object contains the target object within the Snowflake hierarchy |

## Identity and Access Edges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_Usage](EdgeDescriptions/SNOW_Usage.md) | No | Indicates the source principal has USAGE privilege on the target object |
| [SNOW_RunAsRole](EdgeDescriptions/SNOW_RunAsRole.md) | No | Indicates a security integration executes operations under the specified role |
| [SNOW_Ownership](EdgeDescriptions/SNOW_Ownership.md) | No | Indicates the source role owns the target object, granting full control |
| [SNOW_UseAnyRole](EdgeDescriptions/SNOW_UseAnyRole.md) | No | Grants the ability to assume any role on the target object |
| [SNOW_ManageGrants](EdgeDescriptions/SNOW_ManageGrants.md) | No | Grants the ability to manage privilege grants on the target object |

## Object Management Privileges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_Modify](EdgeDescriptions/SNOW_Modify.md) | No | Grants the ability to modify the target object |
| [SNOW_Monitor](EdgeDescriptions/SNOW_Monitor.md) | No | Grants the ability to monitor the target object |
| [SNOW_MonitorExecution](EdgeDescriptions/SNOW_MonitorExecution.md) | No | Grants the ability to monitor execution of operations |
| [SNOW_Operate](EdgeDescriptions/SNOW_Operate.md) | No | Grants the ability to operate (start, stop, suspend, resume) the target object |
| [SNOW_ManageWarehouses](EdgeDescriptions/SNOW_ManageWarehouses.md) | No | Grants the ability to manage warehouses |
| [SNOW_ManagementSharing](EdgeDescriptions/SNOW_ManagementSharing.md) | No | Grants the ability to manage sharing configurations |
| [SNOW_Audit](EdgeDescriptions/SNOW_Audit.md) | No | Grants the ability to audit operations |
| [SNOW_Rebuild](EdgeDescriptions/SNOW_Rebuild.md) | No | Grants the ability to rebuild the target object |

## Data Access Privileges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_Select](EdgeDescriptions/SNOW_Select.md) | No | Grants the ability to select (query) data from the target object |
| [SNOW_Insert](EdgeDescriptions/SNOW_Insert.md) | No | Grants the ability to insert data into the target object |
| [SNOW_Update](EdgeDescriptions/SNOW_Update.md) | No | Grants the ability to update data in the target object |
| [SNOW_Delete](EdgeDescriptions/SNOW_Delete.md) | No | Grants the ability to delete data from the target object |
| [SNOW_Truncate](EdgeDescriptions/SNOW_Truncate.md) | No | Grants the ability to truncate the target object |
| [SNOW_Read](EdgeDescriptions/SNOW_Read.md) | No | Grants the ability to read data from the target object |
| [SNOW_Write](EdgeDescriptions/SNOW_Write.md) | No | Grants the ability to write data to the target object |
| [SNOW_References](EdgeDescriptions/SNOW_References.md) | No | Grants the ability to reference the target object's foreign keys and constraints |
| [SNOW_ReferenceUsage](EdgeDescriptions/SNOW_ReferenceUsage.md) | No | Grants the ability to reference the target object in other objects |
| [SNOW_ServiceRead](EdgeDescriptions/SNOW_ServiceRead.md) | No | Grants the ability to read from services on the target object |
| [SNOW_ServiceWrite](EdgeDescriptions/SNOW_ServiceWrite.md) | No | Grants the ability to write to services on the target object |

## Create Privileges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_CreateAccount](EdgeDescriptions/SNOW_CreateAccount.md) | No | Grants the ability to create accounts |
| [SNOW_CreateApiIntegration](EdgeDescriptions/SNOW_CreateApiIntegration.md) | No | Grants the ability to create API integrations |
| [SNOW_CreateApplication](EdgeDescriptions/SNOW_CreateApplication.md) | No | Grants the ability to create applications |
| [SNOW_CreateApplicationPackage](EdgeDescriptions/SNOW_CreateApplicationPackage.md) | No | Grants the ability to create application packages |
| [SNOW_CreateComputePool](EdgeDescriptions/SNOW_CreateComputePool.md) | No | Grants the ability to create compute pools |
| [SNOW_CreateCredential](EdgeDescriptions/SNOW_CreateCredential.md) | No | Grants the ability to create credentials |
| [SNOW_CreateDataExchangeListing](EdgeDescriptions/SNOW_CreateDataExchangeListing.md) | No | Grants the ability to create data exchange listings |
| [SNOW_CreateDatabase](EdgeDescriptions/SNOW_CreateDatabase.md) | No | Grants the ability to create databases |
| [SNOW_CreateDatabaseRole](EdgeDescriptions/SNOW_CreateDatabaseRole.md) | No | Grants the ability to create database roles |
| [SNOW_CreateExternalVolume](EdgeDescriptions/SNOW_CreateExternalVolume.md) | No | Grants the ability to create external volumes |
| [SNOW_CreateIntegration](EdgeDescriptions/SNOW_CreateIntegration.md) | No | Grants the ability to create integrations |
| [SNOW_CreateNetworkPolicy](EdgeDescriptions/SNOW_CreateNetworkPolicy.md) | No | Grants the ability to create network policies |
| [SNOW_CreateReplicationGroup](EdgeDescriptions/SNOW_CreateReplicationGroup.md) | No | Grants the ability to create replication groups |
| [SNOW_CreateRole](EdgeDescriptions/SNOW_CreateRole.md) | No | Grants the ability to create roles |
| [SNOW_CreateSchema](EdgeDescriptions/SNOW_CreateSchema.md) | No | Grants the ability to create schemas |
| [SNOW_CreateShare](EdgeDescriptions/SNOW_CreateShare.md) | No | Grants the ability to create shares |
| [SNOW_CreateUser](EdgeDescriptions/SNOW_CreateUser.md) | No | Grants the ability to create users |
| [SNOW_CreateWarehouse](EdgeDescriptions/SNOW_CreateWarehouse.md) | No | Grants the ability to create warehouses |

## Execution Privileges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_ExecuteTask](EdgeDescriptions/SNOW_ExecuteTask.md) | No | Grants the ability to execute tasks |
| [SNOW_ExecuteManagedAlert](EdgeDescriptions/SNOW_ExecuteManagedAlert.md) | No | Grants the ability to execute managed alerts |
| [SNOW_ExecuteDataMetricFunction](EdgeDescriptions/SNOW_ExecuteDataMetricFunction.md) | No | Grants the ability to execute data metric functions |
| [SNOW_CancelQuery](EdgeDescriptions/SNOW_CancelQuery.md) | No | Grants the ability to cancel queries |

## Policy Privileges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_ApplyAggregationPolicy](EdgeDescriptions/SNOW_ApplyAggregationPolicy.md) | No | Grants the ability to apply aggregation policies |
| [SNOW_ApplyAuthenticationPolicy](EdgeDescriptions/SNOW_ApplyAuthenticationPolicy.md) | No | Grants the ability to apply authentication policies |
| [SNOW_ApplyBudget](EdgeDescriptions/SNOW_ApplyBudget.md) | No | Grants the ability to apply budget controls |
| [SNOW_ApplyMaskingPolicy](EdgeDescriptions/SNOW_ApplyMaskingPolicy.md) | No | Grants the ability to apply data masking policies |
| [SNOW_ApplyPackagesPolicy](EdgeDescriptions/SNOW_ApplyPackagesPolicy.md) | No | Grants the ability to apply packages policies |
| [SNOW_ApplyPasswordPolicy](EdgeDescriptions/SNOW_ApplyPasswordPolicy.md) | No | Grants the ability to apply password policies |
| [SNOW_ApplyProtectionPolicy](EdgeDescriptions/SNOW_ApplyProtectionPolicy.md) | No | Grants the ability to apply protection policies |
| [SNOW_ApplyRowAccessPolicy](EdgeDescriptions/SNOW_ApplyRowAccessPolicy.md) | No | Grants the ability to apply row access policies |
| [SNOW_ApplySessionPolicy](EdgeDescriptions/SNOW_ApplySessionPolicy.md) | No | Grants the ability to apply session policies |
| [SNOW_AttachPolicy](EdgeDescriptions/SNOW_AttachPolicy.md) | No | Grants the ability to attach policies |

## Sharing and Replication Privileges

| Edge Kind | Traversable | Description |
|---|---|---|
| [SNOW_ImportShare](EdgeDescriptions/SNOW_ImportShare.md) | No | Grants the ability to import shares |
| [SNOW_OverrideShareRestrictions](EdgeDescriptions/SNOW_OverrideShareRestrictions.md) | No | Grants the ability to override share restrictions |
| [SNOW_PurchaseDataExchangeListing](EdgeDescriptions/SNOW_PurchaseDataExchangeListing.md) | No | Grants the ability to purchase data exchange listings |
| [SNOW_BindServiceEndpoint](EdgeDescriptions/SNOW_BindServiceEndpoint.md) | No | Grants the ability to bind service endpoints |
| [SNOW_ApplyBudget](EdgeDescriptions/SNOW_ApplyBudget.md) | No | Grants the ability to apply budget controls |
