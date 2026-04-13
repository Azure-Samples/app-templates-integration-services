using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace SB_Integration_CosmosDB
{
    public class SBtoCosmosDB
    {
        private readonly ILogger<SBtoCosmosDB> _logger;

        public SBtoCosmosDB(ILogger<SBtoCosmosDB> logger)
        {
            _logger = logger;
        }

        [Function(nameof(SBtoCosmosDB))]
        [CosmosDBOutput("demo-database", "demo-container", Connection = "CosmosDbConnectionString", CreateIfNotExists = true)]
        public object? Run(
            [ServiceBusTrigger("demo-queue", Connection = "SBConnectionString")] string myQueueItem)
        {
            if (IsValidJson(myQueueItem))
            {
                _logger.LogInformation("C# ServiceBus queue trigger function processed message: {Message}", myQueueItem);
                return myQueueItem;
            }

            _logger.LogError("The message failed JSON validation. Please provide valid JSON: {Message}", myQueueItem);
            throw new InvalidOperationException($"Failed to process message: {myQueueItem}");
        }

        private bool IsValidJson(string potentialJson)
        {
            try
            {
                JsonDocument.Parse(potentialJson);
                return true;
            }
            catch (JsonException)
            {
                return false;
            }
        }
    }
}
