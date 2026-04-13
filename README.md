# Integration using Azure Service Bus and API Management

This is a sample integration app template that walks through setting up API Management policy for sending data to Azure Service Bus. The API Management uses Managed Identity to access the Service Bus REST APIs. A Function App and a Logic App (Standard) are both triggered when messages arrive in Service Bus, and they write message data to Cosmos DB. Both services authenticate to Service Bus and Cosmos DB using Managed Identity. This is a typical integration scenario leveraging APIs.

> Refer to the [App Templates](https://github.com/microsoft/App-Templates) repo Readme for more samples that are compatible with [Azure Developer CLI (azd)](https://github.com/Azure/azure-dev/)

## Architecture

Below architecture is deployed in this demonstration.

![Integration Architecture](media/s8.png)

### Data Flow

```
Client -> APIM (via Managed Identity) -> Service Bus Queue ("demo-queue")
                                              |
                               +--------------+--------------+
                               v                              v
                       Function App                    Logic App (Standard)
                    (SB trigger -> Cosmos)           (SB trigger -> Cosmos)
                               |                              |
                               +--------------+--------------+
                                              v
                                    Cosmos DB ("demo-database")
```

1. A client sends an HTTP POST to API Management.
2. APIM authenticates to Service Bus using its system-assigned managed identity and forwards the message to the `demo-queue`.
3. Both the **Function App** and **Logic App** listen on `demo-queue` as **competing consumers** - each message is processed by one or the other (not both).
4. The consumer writes the message data to Cosmos DB's `demo-database`/`demo-container`.

> **Note**: Because both services consume from the same queue, each message is delivered to only one of them. If you need both to process every message, replace the queue with a Service Bus **topic and two subscriptions**.

### Azure Services

| Service | SKU / Plan | Purpose |
|---------|-----------|---------|
| API Management | Developer | HTTP API gateway; routes requests to Service Bus |
| Service Bus | Standard | Message broker with `demo-queue` |
| Function App | Flex Consumption (FC1) | .NET 8 isolated worker; SB trigger -> Cosmos DB output |
| Logic App (Standard) | WorkflowStandard (WS1) | Stateful workflow; SB trigger -> Cosmos DB upsert |
| Application Insights | - | Monitoring for Function App (separate instance for Logic App) |
| Storage Account | StorageV2 | Function App runtime (identity-based); Logic App runtime |
| Cosmos DB | Serverless | Document store with `demo-database` / `demo-container` |

### Technology Stack

- **Function App Runtime**: .NET 8 (LTS) with Azure Functions isolated worker model
- **Logic App**: Standard (single-tenant) with a Stateful workflow (`SimpleFlow`)
- **Infrastructure**: Bicep (Infrastructure as Code)
- **Deployment**: Azure Developer CLI (azd) or Azure CLI

The client can be simulated using curl, or any other tool that can send HTTP requests to the APIM gateway.

## Project Structure

```
+-- azure.yaml                          # azd service definitions
+-- infra/
|   +-- main.bicep                      # Top-level deployment orchestration
|   +-- main.parameters.json            # azd parameter mappings (env vars -> Bicep params)
|   +-- modules/
|       +-- apim.bicep                  # API Management
|       +-- cosmosdb.bicep              # Cosmos DB account, database, container
|       +-- function.bicep              # Function App (Flex Consumption)
|       +-- logicapp.bicep              # Logic App Standard (WS1)
|       +-- service-bus.bicep           # Service Bus namespace and queue
|       +-- telemetry.bicep             # Telemetry deployment
|       +-- vnet.bicep                  # Virtual network (not wired up; for future use)
|       +-- configure/
|           +-- configure-apim.bicep                # APIM -> SB policy
|           +-- configure-function.bicep            # Function app settings (SB + Cosmos)
|           +-- configure-logicapp.bicep            # Logic App app settings (SB + Cosmos)
|           +-- append-function-appsettings.bicep   # Merge function settings
|           +-- append-logicapp-appsettings.bicep   # Merge logic app settings
|           +-- roleAssign-apim-service-bus.bicep   # APIM -> SB Data Sender
|           +-- roleAssign-function-service-bus.bicep # Function -> SB Data Receiver
|           +-- roleAssign-logicapp-service-bus.bicep # Logic App -> SB Data Receiver
|           +-- roleAssign-logicapp-cosmosdb.bicep   # Logic App -> Cosmos DB Data Contributor
+-- src/
    +-- Program.cs                      # Function App entry point
    +-- SBtoCosmosDB.cs                 # Function: SB trigger -> Cosmos output
    +-- host.json                       # Function App host configuration
    +-- SB-Integration-ComosDB.csproj   # Function App project file
    +-- LogicApp/
        +-- host.json                   # Logic App host config (workflow extension bundle)
        +-- connections.json            # Service provider connections (SB + Cosmos, managed identity)
        +-- SimpleFlow/
            +-- workflow.json           # Stateful workflow definition
```

## Identity and Security

All service-to-service communication uses **Managed Identity** - no secrets or connection strings are shared between services.

### Function App

The Function App runs on a **Flex Consumption (FC1)** plan with fully identity-based storage access:

- A **user-assigned managed identity** authenticates to storage for deployment packages (blob container) and runtime operations (queues, tables).
- The storage account has **shared key access disabled** (`allowSharedKeyAccess: false`).
- RBAC roles assigned: Storage Blob Data Owner, Storage Queue Data Contributor, Storage Table Data Contributor.
- The Function App's **system-assigned managed identity** holds the **Service Bus Data Receiver** role on the Service Bus namespace.

### Logic App (Standard)

The Logic App runs on a **WorkflowStandard (WS1)** plan with:

- A **system-assigned managed identity** for authenticating to Service Bus and Cosmos DB.
- RBAC roles assigned:
  - **Service Bus Data Receiver** on the Service Bus namespace.
  - **Cosmos DB Built-in Data Contributor** on the Cosmos DB account (data plane role).
- Service provider connections in `connections.json` use `ManagedServiceIdentity` authentication - no connection strings for external services.
- A **user-assigned managed identity** authenticates to the Logic App's own runtime storage (blob, queue, table). The storage account has **shared key access disabled** (`allowSharedKeyAccess: false`), matching the Function App's identity-based approach.

### API Management

- A **system-assigned managed identity** holds the **Service Bus Data Sender** role on the Service Bus namespace.
- APIM authenticates to Service Bus using `authentication-managed-identity` in the API policy.

## Benefits of this Architecture

1. Integrate backend systems using a message broker to decouple services for scalability and reliability.
2. Allows work to be queued when backend systems are unavailable.
3. API Management provides publishing capability for HTTP APIs, promoting reuse and discoverability. It manages cross-cutting concerns such as authentication, throughput limits, and response caching.
4. Provide load leveling to handle bursts in workloads.
5. Multiple consumers (Function App + Logic App) demonstrate competing consumer patterns for parallel processing.
6. The Logic App provides a low-code workflow option alongside the code-first Function App.

### Potential Extensions

1. The Function can be converted to a durable function that orchestrates normalization and correlation of data prior to persisting to Cosmos DB.
2. Replace the queue with a **Service Bus topic and subscriptions** so both consumers process every message (fan-out pattern).
3. An Azure Event Grid could be integrated with Service Bus for cost optimization when messages arrive infrequently.
4. APIM can be configured to expose additional synchronous REST APIs.
5. The Logic App workflow can be extended with additional steps such as data transformation, error handling, or calling external APIs.
6. The Service Bus could be replaced by other messaging technology such as Event Hubs or Event Grid.

## Deploy solution to Azure

### Prerequisites

1. [Azure Developer CLI (azd)](https://aka.ms/azure-dev/install)
1. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
1. [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
1. Azure Subscription. [Create one for free](https://azure.microsoft.com/free/).
1. Clone or fork of this repository.

### Deploy with Azure Developer CLI (Recommended)

Login to Azure:

```bash
azd auth login
```

Initialize and deploy from the repository directory:

```bash
cd app-templates-integration-services
azd up
```

During `azd up` you will be prompted for:

| Prompt | Description |
|--------|-------------|
| Environment name | A short name used to prefix all Azure resources (3-16 characters, e.g. `myintegration`) |
| Azure subscription | The subscription to deploy into |
| Azure location | The region for all resources (defaults to `westus2` if not specified). Override at any time with `azd env set AZURE_LOCATION "<region>"` |
| Publisher email | The email address for the API Management publisher |
| Publisher name | The display name for the API Management publisher |

The deployment provisions all infrastructure and deploys both the Function App and Logic App in a single step.

> **NOTE**: The deployment is ordered so that Service Bus, Cosmos DB, Function App, and Logic App deploy first. APIM only begins provisioning after those succeed. The APIM resource can take over an hour to provision.

To override the default location before deploying:

```bash
azd env set AZURE_LOCATION "westeurope"
azd up
```

To re-deploy after code changes without re-provisioning infrastructure:

```bash
azd deploy
```

To re-deploy only the Function App or Logic App individually:

```bash
azd deploy function
azd deploy logicapp
```

### Deploy with Azure CLI (Alternative)

Login to your Azure in your terminal.

```bash
az login
```

To check your subscription.

```bash
az account show
```

Run the deployment. The deployment will create the resource group "rg-\<Name suffix for resources\>". Make sure you are in the 'app-templates-integration-services' directory.

```bash
cd app-templates-integration-services

az deployment sub create --name "<unique deployment name>" --location "<Your Chosen Location>" --template-file infra/main.bicep --parameters name="<Name suffix for resources>" publisherEmail="<Publisher Email for APIM>" publisherName="<Publisher Name for APIM>"
```

> **NOTE**: When using `az deployment`, the Bicep templates provision all infrastructure including RBAC role assignments. However, you will need to deploy the Function App and Logic App code separately (e.g., via VS Code, GitHub Actions, or `az functionapp deployment`).

The following deployments will run:

![deployment times](media/s9.png)

>**NOTE**: The deployment is ordered so that APIM deploys last, after Service Bus, Cosmos DB, Function App, and Logic App succeed. The APIM deployment can take over an hour to complete.

## Validate Deployment

1. Use Curl or another tool to send a request as shown below to the "demo-queue" created during deployment. Make sure to send in the API key in the header "Ocp-Apim-Subscription-Key".

    ```bash
    curl -X POST https://<Your APIM Gateway URL>/sb-operations/demo-queue \
      -H 'Ocp-Apim-Subscription-Key:<Your APIM Subscription Key>' \
      -H 'Content-Type: application/json' \
      -d '{ "date" : "2026-04-11", "id" : "1", "data" : "Sending data via APIM->Service Bus->Function/LogicApp->CosmosDB" }'
    ```

    If using PowerShell use Invoke-WebRequest:

    ```powershell
    Invoke-WebRequest -Uri "https://<Your APIM Gateway URL>/sb-operations/demo-queue" `
      -Headers @{
        'Ocp-Apim-Subscription-Key' = '<Your APIM Subscription Key>'
        'Content-Type' = 'application/json'
      } `
      -Method 'POST' `
      -Body '{ "date" : "2026-04-11", "id" : "1", "data" : "Sending data via APIM->Service Bus->Function/LogicApp->CosmosDB" }'
    ```

2. Go to your deployment of **Cosmos DB** in Azure Portal, click on **Data Explorer**, select `demo-database` -> `demo-container` -> **Items**. Select the first item and view the content. It will match the data submitted to the APIM gateway in step 1.

    ![Data in Cosmos DB](media/s10.png)

3. To verify which service processed the message:
    - **Function App**: Check the Function App's **Application Insights** -> **Live Metrics** or **Transaction Search** for the `SBtoCosmosDB` function invocation.
    - **Logic App**: In the Azure Portal, navigate to the Logic App -> **Workflows** -> **SimpleFlow** -> **Run History** to see completed workflow runs.

> **Tip**: Since the Function App and Logic App are competing consumers, send multiple messages to observe both services processing messages.

## Disclaimer

The code and deployment Bicep templates are for demonstration purposes only.
