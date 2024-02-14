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
using System.Collections.Generic;

namespace SB_Integration_ComosDB
{
    public static class APIMtoSB
    {
        [FunctionName("APIMtoSB")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [ServiceBus("%queueName%", Connection = "sbConnString")] IAsyncCollector<ServiceBusMessage> outputQueueItem,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

            //log.LogInformation("Logging a custom trace message......");

            // Iterate over all query strings
            // foreach (var query in req.Query)
            // {
            //     log.LogInformation($"Query: {query.Key} = {query.Value}");
            //     log.LogTrace(query.Key, query.Value.ToString());
            //     log.BeginScope(query.Key, query.Value.ToString());
            // }

            var nameValueDictionary = new Dictionary<string, string>();


            //Iterate over all headers
            foreach (var header in req.Headers)
            {
                log.LogInformation($"Header: {header.Key} = {header.Value}");
                log.LogTrace(header.Key, header.Value.ToString());
                nameValueDictionary.Add(header.Key, header.Value.ToString());
            }

            string callerTrackingId = "";
            if(string.IsNullOrEmpty(req.Headers["callerTrackingId"].ToString()))
            {
                callerTrackingId = req.Headers["callerTrackingId"];
            }

            using (log.BeginScope(nameValueDictionary))
            {
                log.LogInformation("Headers received by function");
            }

            using (log.BeginScope(req.Query))
            {
                log.LogInformation("Query strings received by function");
            }
            //Create a new message
            var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(requestBody));

            // Add custom properties to the message.
            message.ApplicationProperties.Add("CustomProperty1", "Value1");
            message.ApplicationProperties.Add("CustomProperty2", "Value2");
            message.ApplicationProperties.Add("CustomProperty3", "Value3");
            message.ApplicationProperties.Add("callerTrackingId", callerTrackingId);

            // Log the message properties as a single log entry.
            using (log.BeginScope(message.ApplicationProperties))
            {
                log.LogInformation("Properties set on service bus message");
            }

            await outputQueueItem.AddAsync(message);

            return requestBody != null
                ? (ActionResult)new OkObjectResult($"Message sent: {requestBody}")
                : new BadRequestObjectResult("Please pass a message in the request body");
        }
    }
}
