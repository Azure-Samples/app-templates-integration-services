using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Schema;
using System.Threading.Tasks;

namespace SB_Integration_ComosDB
{
    public class SBtoCosmosDB
    {
        [FunctionName("SBtoCosmosDB")]
        public async Task Run([ServiceBusTrigger("demo-queue", Connection = "SBConnectionString")]string myQueueItem,
            [CosmosDB(
        databaseName: "demo-database",
        collectionName: "demo-container",
        CreateIfNotExists = true,
        ConnectionStringSetting = "CosmosDbConnectionString")]IAsyncCollector<dynamic> documentsOut,
            ILogger log)
        {
            if (IsValidJsonString(myQueueItem, log))
            {
                // Add a JSON document to the output container.
                try
                {
                    await documentsOut.AddAsync(myQueueItem);
                }
                catch(Exception ex)
                {
                    log.LogError($"Failed to process message: {myQueueItem}");
                    log.LogError($"The message failed with exception : {ex.Message} : Details: {ex.InnerException}");
                    throw;
                }
            }
            else
            {
                log.LogError($"The message failed JSON validation. Please provide valid JSON. : {myQueueItem}");
                throw new Exception($"Failed to process message: {myQueueItem}");
            }

            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");

        }

        private bool IsValidJsonString(string potentialJson, ILogger log)
        {
            try
            {
                var jsonModel = JObject.Parse(potentialJson);
                return true;
            }
            catch(JsonReaderException ex)
            {
                log.LogError($"JSON validation failed. Exception : {ex.Message} : Details: {ex.InnerException}");
                return false;
            }
        }
    }
}
