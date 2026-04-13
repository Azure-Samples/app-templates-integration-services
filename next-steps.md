# Next Steps after `azd init`

## Table of Contents

1. [Next Steps](#next-steps)
   1. [Provision infrastructure](#provision-infrastructure-and-deploy-application-code)
   2. [Modify infrastructure](#modify-infrastructure)
   3. [Getting to production-ready](#getting-to-production-ready)
2. [Billing](#billing)
3. [Troubleshooting](#troubleshooting)

## Next Steps

### Provision infrastructure and deploy application code

Run `azd up` to provision your infrastructure and deploy to Azure in one step (or run `azd provision` then `azd deploy` to accomplish the tasks separately). Visit the service endpoints listed to see your application up-and-running!

This deploys two services:
- **function** — An Azure Function App (Flex Consumption) that processes Service Bus messages and writes to Cosmos DB.
- **logicapp** — An Azure Logic App (Standard) that runs a stateful workflow doing the same: Service Bus trigger → Cosmos DB upsert.

To troubleshoot any issues, see [troubleshooting](#troubleshooting).

### Modify infrastructure

To describe the infrastructure and application, `azure.yaml` was added. This file contains all services and resources that describe your application.

The infrastructure is defined in the `infra/` directory using Bicep modules:
- `main.bicep` — Top-level orchestration
- `modules/` — Individual resource modules (APIM, Service Bus, Function, Logic App, Cosmos DB, etc.)
- `modules/configure/` — Post-deployment configuration (app settings, RBAC role assignments, APIM policies)

To modify infrastructure, edit the Bicep files directly and run `azd provision` to apply changes.

### Getting to production-ready

Consider the following before moving to production:

1. **Networking**: A `vnet.bicep` module is included but not wired up. Enable VNet integration and private endpoints for Service Bus, Cosmos DB, and Storage.
2. **Key Vault**: Move the Logic App's internal storage connection string to Azure Key Vault using Key Vault references.
3. **Monitoring**: Configure alerts on Application Insights for both the Function App and Logic App.
4. **CI/CD**: Run `azd pipeline config` to configure a CI/CD deployment pipeline.
5. **APIM tier**: The Developer tier is not suitable for production. Consider Standard or Premium tiers.
6. **Fan-out**: If both consumers should process every message, switch from a queue to a Service Bus topic with subscriptions.

## Billing

Visit the *Cost Management + Billing* page in Azure Portal to track current spend. For more information about how you're billed, and how you can monitor the costs incurred in your Azure subscriptions, visit [billing overview](https://learn.microsoft.com/azure/developer/intro/azure-developer-billing).

## Troubleshooting

Q: I deployed with `azd up` but one of the services failed.

A: To investigate:

1. Run `azd show`. Click on the link under "View in Azure Portal" to open the resource group in Azure Portal.
2. Check the **Function App** → **Log stream** or **Application Insights** for function execution errors.
3. Check the **Logic App** → **Workflows** → **SimpleFlow** → **Run History** for workflow failures. Click on a failed run to see the action-level error details.
4. For infrastructure issues, review the deployment in **Resource Group** → **Deployments** to see which Bicep module failed.

Q: Messages are only being processed by one service (Function or Logic App) but not the other.

A: This is expected behavior. Both services are **competing consumers** on the same Service Bus queue. Each message is delivered to only one consumer. Send multiple messages to observe both services picking up work.

Q: The Logic App workflow shows authentication errors connecting to Service Bus or Cosmos DB.

A: Verify that the RBAC role assignments completed successfully:
- The Logic App's managed identity needs **Service Bus Data Receiver** on the Service Bus namespace.
- The Logic App's managed identity needs **Cosmos DB Built-in Data Contributor** on the Cosmos DB account.
- Role assignments can take a few minutes to propagate after deployment.

### Additional information

For additional information about setting up your `azd` project, visit our official [docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-convert).
