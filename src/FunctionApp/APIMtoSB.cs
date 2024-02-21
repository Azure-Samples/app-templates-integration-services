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

            var nameValueDictionary = new Dictionary<string, object>();
            nameValueDictionary.Add("Key1", "Value1");
            nameValueDictionary.Add("Key2", "Value2");
            nameValueDictionary.Add("KeyJSON", "{ \"Key3\": \"Value3\", \"Key4\": \"Value4\" }");
            using (log.BeginScope(nameValueDictionary))  //doesn't show values
            {
                log.LogInformation("test log message with scope using dictionary");
            }

            //Trace logs will only show up if you set the function logging level to Trace in the host.json file
            //See this article for more info: https://stackoverflow.com/questions/63674551/cannot-see-trace-logs-when-loglevel-set-to-trace-in-azure-function
            //The results of the logtrace call look the same as the logInformation call
            // log.LogTrace(1,"LogTraceTest with dictionary", nameValueDictionary);   
            // log.LogTrace(1, "LogTraceTest with {string}", "string value");
            // log.LogTrace(1, "LogTraceTest with json string", "{ \"Key3\": \"Value3\", \"Key4\": \"Value4\" }");       

            //Iterate over all headers
            // foreach (var header in req.Headers) //this logs each of the headers... 
            // {
            //     log.LogInformation($"Header: {header.Key} = {header.Value}");
            //     log.LogTrace("LogTraceTest", "LogTraceTestValue");         //this doesn't seem to be working
            // }

            // using (log.BeginScope(nameValueDictionary))  //doesn't show values
            // {
            //     log.LogInformation("Headers received by function");
            // }

            // using (log.BeginScope(req.Query))  //doesn't show values
            // {
            //     log.LogInformation("Query strings received by function");
            // }

            
            //get the callerTrackingId from the header if it exists
            string callerTrackingId = "";
            if(string.IsNullOrEmpty(req.Headers["callerTrackingId"].ToString())==false) 
            {
                callerTrackingId = req.Headers["callerTrackingId"];
            }

            log.LogInformation("callerTrackingId: {callerTrackingId}", callerTrackingId);

            //Create a new message
            var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(requestBody));

            // Add custom properties to the message.
            message.ApplicationProperties.Add("CustomProperty1", "Value1");
            message.ApplicationProperties.Add("CustomProperty2", "Value2");
            message.ApplicationProperties.Add("CustomProperty3", "Value3");
            message.ApplicationProperties.Add("callerTrackingId", callerTrackingId);  //value showing empty

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
