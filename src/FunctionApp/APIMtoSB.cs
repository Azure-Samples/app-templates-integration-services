using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Azure.Messaging.ServiceBus;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using System.Text;

namespace SB_Integration_ComosDB
{
    public static class APIMtoSB
    {
        [FunctionName("APIMtoSB")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [ServiceBus("testqueue", Connection = "sbConnString")] IAsyncCollector<ServiceBusMessage> outputQueueItem,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

            //Create a new message
            var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(requestBody));

            // Add custom properties to the message.
            message.ApplicationProperties.Add("CustomProperty1", "Value1");
            message.ApplicationProperties.Add("CustomProperty2", "Value2");
            message.ApplicationProperties.Add("CustomProperty3", "Value3");

            log.LogInformation("Logging a custom trace message......");

            // Log the message properties as individual log entries.
            foreach (var property in message.ApplicationProperties)
            {
                log.LogInformation("Property: {Key}, Value: {Value}", property.Key, property.Value);
            }

            // Log the message properties as a single log entry.
            using (log.BeginScope(message.ApplicationProperties))
            {
                log.LogInformation("Received Service Bus message with properties");
            }

            await outputQueueItem.AddAsync(message);

            return requestBody != null
                ? (ActionResult)new OkObjectResult($"Message sent: {requestBody}")
                : new BadRequestObjectResult("Please pass a message in the request body");
        }
    }
}
