param service_apim2_4z34nm_name string = 'apim2-4z34nm'

resource service_apim2_4z34nm_name_resource 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: service_apim2_4z34nm_name
  location: 'East US'
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'integrationSampleUser@sample.com'
    publisherName: 'Integration Sample User'
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${service_apim2_4z34nm_name}.azure-api.net'
        negotiateClientCertificate: false
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'False'
    }
    virtualNetworkType: 'None'
    disableGateway: false
    natGatewayState: 'Disabled'
    apiVersionConstraint: {}
    publicNetworkAccess: 'Enabled'
    legacyPortalStatus: 'Enabled'
    developerPortalStatus: 'Enabled'
  }
}

resource service_apim2_4z34nm_name_function_operations 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'function-operations'
  properties: {
    displayName: 'Function Operations'
    apiRevision: '1'
    subscriptionRequired: true
    path: 'func-operations'
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
}

resource service_apim2_4z34nm_name_service_bus_operations 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'service-bus-operations'
  properties: {
    displayName: 'Service Bus Operations'
    apiRevision: '1'
    subscriptionRequired: true
    path: 'sb-operations'
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
}

resource service_apim2_4z34nm_name_function_backend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'function-backend'
  properties: {
    url: 'https://somefunctionuri.azurewebsites.net'
    protocol: 'http'
    credentials: {
      header: {
        'x-functions-key': [
          '12345abcde'
        ]
      }
    }
  }
}

resource service_apim2_4z34nm_name_testbackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'testbackend'
  properties: {
    url: 'https://func-4z34nm.azurewebsites.net/api/APIMtoSB'
    protocol: 'http'
    resourceId: 'https://management.azure.com/subscriptions/1680f467-523b-453d-9cc0-59ab9a7052b8/resourceGroups/rg-IntegrationSample-4z34nm/providers/Microsoft.Web/sites/func-4z34nm'
    credentials: {
      query: {}
      header: {
        'x-functions-key': [
          '{{function-api-key}}'
        ]
      }
    }
    tls: {
      validateCertificateChain: false
      validateCertificateName: false
    }
  }
}

resource service_apim2_4z34nm_name_function_api_key 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'function-api-key'
  properties: {
    displayName: 'function-api-key'
    tags: [
      'key'
      'function'
    ]
    secret: true
  }
}

resource service_apim2_4z34nm_name_policy 'Microsoft.ApiManagement/service/policies@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'policy'
  properties: {
    value: '<!--\r\n    IMPORTANT:\r\n    - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.\r\n    - Only the <forward-request> policy element can appear within the <backend> section element.\r\n    - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.\r\n    - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.\r\n    - To add a policy position the cursor at the desired insertion point and click on the round button associated with the policy.\r\n    - To remove a policy, delete the corresponding policy statement from the policy document.\r\n    - Policies are applied in the order of their appearance, from the top down.\r\n-->\r\n<policies>\r\n  <inbound></inbound>\r\n  <backend>\r\n    <forward-request />\r\n  </backend>\r\n  <outbound></outbound>\r\n</policies>'
    format: 'xml'
  }
}

resource Microsoft_ApiManagement_service_properties_service_apim2_4z34nm_name_function_api_key 'Microsoft.ApiManagement/service/properties@2019-01-01' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'function-api-key'
  properties: {
    displayName: 'function-api-key'
    value: 'this is my api key'
    tags: [
      'key'
      'function'
    ]
    secret: true
  }
}

resource service_apim2_4z34nm_name_master 'Microsoft.ApiManagement/service/subscriptions@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_resource
  name: 'master'
  properties: {
    scope: '${service_apim2_4z34nm_name_resource.id}/'
    displayName: 'Built-in all-access subscription'
    state: 'active'
    allowTracing: false
  }
}

resource service_apim2_4z34nm_name_function_operations_send_func_message 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_function_operations
  name: 'send-func-message'
  properties: {
    displayName: 'Send Message'
    method: 'POST'
    urlTemplate: '/func'
    templateParameters: []
    responses: []
  }
  dependsOn: [

    service_apim2_4z34nm_name_resource
  ]
}

resource service_apim2_4z34nm_name_service_bus_operations_send_sb_message 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_service_bus_operations
  name: 'send-sb-message'
  properties: {
    displayName: 'Send Message'
    method: 'POST'
    urlTemplate: '/{queue_or_topic}'
    templateParameters: [
      {
        name: 'queue_or_topic'
        type: 'string'
        values: []
      }
    ]
    responses: []
  }
  dependsOn: [

    service_apim2_4z34nm_name_resource
  ]
}

resource service_apim2_4z34nm_name_function_operations_default 'Microsoft.ApiManagement/service/apis/wikis@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_function_operations
  name: 'default'
  properties: {
    documents: []
  }
  dependsOn: [

    service_apim2_4z34nm_name_resource
  ]
}

resource service_apim2_4z34nm_name_service_bus_operations_default 'Microsoft.ApiManagement/service/apis/wikis@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_service_bus_operations
  name: 'default'
  properties: {
    documents: []
  }
  dependsOn: [

    service_apim2_4z34nm_name_resource
  ]
}

resource service_apim2_4z34nm_name_function_operations_send_func_message_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_function_operations_send_func_message
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <!-- <set-backend-service id="apim-generated-policy" backend-id="inbound-kriss" /> -->\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [

    service_apim2_4z34nm_name_function_operations
    service_apim2_4z34nm_name_resource
  ]
}

resource service_apim2_4z34nm_name_service_bus_operations_send_sb_message_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-03-01-preview' = {
  parent: service_apim2_4z34nm_name_service_bus_operations_send_sb_message
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-variable name="queue_or_topic" value="@(context.Request.MatchedParameters[&quot;queue_or_topic&quot;])" />\r\n    <set-variable name="trackingid" value="@(Guid.NewGuid().ToString())" />\r\n    <!-- Create a tracking id to return to the customer and track through the system-->\r\n    <authentication-managed-identity resource="https://servicebus.azure.net" output-token-variable-name="msi-access-token" ignore-error="false" />\r\n    <set-header name="Authorization" exists-action="override">\r\n      <value>@((string)context.Variables["msi-access-token"])</value>\r\n    </set-header>\r\n    <set-header name="testheader" exists-action="override">\r\n      <value>this is a test</value>\r\n    </set-header>\r\n    <set-header name="trackingId" exists-action="override">\r\n      <value>@((string)context.Variables["trackingid"])</value>\r\n    </set-header>\r\n    <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />\r\n    <emit-metric name="testmetric" namespace="testnamespace">\r\n      <dimension name="dimension name" value="dimension value" />\r\n    </emit-metric>\r\n    <!-- remove the subscription key so credentials are not leaked to the backend -->\r\n    <set-method>POST</set-method>\r\n    <set-body>@{                 JObject json = context.Request.Body.As&lt;JObject&gt;(preserveContent: true);                 return JsonConvert.SerializeObject(json);         }</set-body>\r\n    <set-backend-service base-url="https://sb-4z34nm.servicebus.windows.net:443/" />\r\n    <rewrite-uri template="@(&quot;/&quot; + (string)context.Variables[&quot;queue_or_topic&quot;] +&quot;/messages&quot; )" copy-unmatched-params="false" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n    <return-response>\r\n      <set-status code="201" reason="OK" />\r\n      <set-header name="Content-Type" exists-action="override">\r\n        <value>application/json</value>\r\n      </set-header>\r\n      <set-body template="liquid">\r\n            {\r\n                "trackingId":"{{context.Variables["trackingid"]}}"\r\n            }\r\n            </set-body>\r\n    </return-response>\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n    <set-variable name="errorMessage" value="@{             return new JObject(                 new JProperty(&quot;EventTime&quot;, DateTime.UtcNow.ToString()),                 new JProperty(&quot;ErrorMessage&quot;, context.LastError.Message),                 new JProperty(&quot;ErrorReason&quot;, context.LastError.Reason),                 new JProperty(&quot;ErrorSource&quot;, context.LastError.Source),                 new JProperty(&quot;ErrorScope&quot;, context.LastError.Scope),                 new JProperty(&quot;ErrorSection&quot;, context.LastError.Section)              ).ToString();         }" />\r\n    <return-response>\r\n      <set-status code="500" reason="Error" />\r\n      <set-header name="Content-Type" exists-action="override">\r\n        <value>application/json</value>\r\n      </set-header>\r\n      <set-body>@((string)context.Variables["errorMessage"])</set-body>\r\n    </return-response>\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [

    service_apim2_4z34nm_name_service_bus_operations
    service_apim2_4z34nm_name_resource
  ]
}