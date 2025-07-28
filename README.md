# SnowHound

## Overview

The BloodHound extension for Snowflake provides a powerful way to visualize access control and potential attack paths within a Snowflake environment. By mapping key entities such as Users, Roles, Databases, Warehouses, and Integrations, along with the permissions that connect them, this extension enables security teams to gain a comprehensive understanding of their Snowflake landscape. The extension leverages Snowflake’s Role-Based Access Control (RBAC) model, allowing organizations to identify and address attack paths in their Snowflake tenants. With this tool, users can explore how access is granted, track potential attack paths, and implement effective security strategies to mitigate risk in their Snowflake accounts.

## Collector Setup & Usage



## Schema

Below is the complete set of nodes and edges as defined in the [model](./model.json).

### Nodes

Nodes correspond to each object type.

| Node                                                                           | Description                                                                                                                                | Icon        | Color   |
|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|-------------|---------|
| <img src="./images/black_SNOWAccount.png" width="30"/> SNOWAccount             | The top-level container for all Snowflake resources such as users, roles, databases, and integrations.                                     | building    | #5FED83 |
| <img src="./images/black_SNOWUser.png" width="30"/> SNOWUser                   | Represents an individual user in a Snowflake account, linked to roles, warehouses, and databases that define their access.                 | user        | #FF8E40 |
| <img src="./images/black_SNOWRole.png" width="30"/> SNOWRole                   | Represents a role in Snowflake that defines a set of permissions, which can be assigned to users or other roles.                           | user-group  | #C06EFF |
| <img src="./images/black_SNOWWarehouse.png" width="30"/> SNOWWarehouse         | Represents a Snowflake virtual warehouse providing computational resources for running queries, with access controlled by roles and users. | warehouse   | #9EECFF |
| <img src="./images/black_SNOWDatabase.png" width="30"/> SNOWDatabase           | Represents a Snowflake database, linked to users, roles, and warehouses that have access to it.                                            | database    | #FF80D2 |
| <img src="./images/black_SNOWIntegration.png" width="30"/> SNOWIntegration     | Represents an integration with an external system or service in Snowflake, such as a data pipeline or third-party application.             | user-tie    | #BFFFD1 |

### Edges



## Usage Examples



## Contributing

We welcome and appreciate your contributions! To make the process smooth and efficient, please follow these steps:

1. **Discuss Your Idea**  
   - If you’ve found a bug or want to propose a new feature, please start by opening an issue in this repo. Describe the problem or enhancement clearly so we can discuss the best approach.

2. **Fork & Create a Branch**  
   - Fork this repository to your own account.  
   - Create a topic branch for your work:
     ```bash
     git checkout -b feat/my-new-feature
     ```

3. **Implement & Test**  
   - Follow the existing style and patterns in the repo.  
   - Add or update any tests/examples to cover your changes.  
   - Verify your code runs as expected:
     ```bash
     # e.g. dot-source the collector and run it, or load the model.json in BloodHound
     ```

4. **Submit a Pull Request**  
   - Push your branch to your fork:
     ```bash
     git push origin feat/my-new-feature
     ```  
   - Open a Pull Request against the `main` branch of this repository.  
   - In your PR description, please include:
     - **What** you’ve changed and **why**.  
     - **How** to reproduce/test your changes.

5. **Review & Merge**  
   - I’ll review your PR, give feedback if needed, and merge once everything checks out.  
   - For larger or more complex changes, review may take a little longer—thanks in advance for your patience!

Thank you for helping improve this extension! 🎉  

## Licensing

```
Copyright 2025 Jared Atkinson

Licensed under the Apache License, Version 2.0
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

Unless otherwise annotated by a lower-level LICENSE file or license header, all files in this repository are released
under the `Apache-2.0` license. A full copy of the license may be found in the top-level [LICENSE](LICENSE) file.
