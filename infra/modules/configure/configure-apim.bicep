@description('The name of the API Management service instance')
param apimServiceName string

@description('The Service Bus Namespace Endpoint')
param sbEndpoint string

resource apimInstance 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apimServiceName
}

resource api 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: 'service-bus-operations'
  parent: apimInstance
  properties: {
    displayName: 'Service Bus Operations'
    path: 'sb-operations'
    apiType: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

resource apiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'send-message'
  parent: api
  properties:{
    displayName: 'Send Message'
    method: 'POST'
    urlTemplate: '/{queue_or_topic}'
    templateParameters: [
      {
        name: 'queue_or_topic'
        type: 'string'
      }
    ]
  }
}

resource operationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name:'policy'
  parent: apiOperation
  properties: {
    format: 'rawxml'
    value: '<policies>     <inbound>         <base />         <set-variable name="queue_or_topic" value="@(context.Request.MatchedParameters["queue_or_topic"])" />         <authentication-managed-identity resource="https://servicebus.azure.net" output-token-variable-name="msi-access-token" ignore-error="false" />         <set-header name="Authorization" exists-action="override">             <value>@((string)context.Variables["msi-access-token"])</value>         </set-header>         <set-method>POST</set-method>         <set-body>@{                 JObject json = context.Request.Body.As<JObject>(preserveContent: true);                 return JsonConvert.SerializeObject(json);         }</set-body>         <set-backend-service base-url="${sbEndpoint}" />         <rewrite-uri template="@("/" + (string)context.Variables["queue_or_topic"] +"/messages" )" copy-unmatched-params="false" />     </inbound>     <backend>         <base />     </backend>     <outbound>         <base />     </outbound>     <on-error>         <base />         <set-variable name="errorMessage" value="@{             return new JObject(                 new JProperty("EventTime", DateTime.UtcNow.ToString()),                 new JProperty("ErrorMessage", context.LastError.Message),                 new JProperty("ErrorReason", context.LastError.Reason),                 new JProperty("ErrorSource", context.LastError.Source),                 new JProperty("ErrorScope", context.LastError.Scope),                 new JProperty("ErrorSection", context.LastError.Section)              ).ToString();         }" />         <return-response>             <set-status code="500" reason="Error" />             <set-header name="Content-Type" exists-action="override">                 <value>application/json</value>             </set-header>             <set-body>@((string)context.Variables["errorMessage"])</set-body>         </return-response>     </on-error> </policies>'
  }
}
