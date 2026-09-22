###azure-container-lab - Vorgehen

##Step1: Planung

Repo "azure-container-lab" anlegen
	Ordner modules/ mit acr.bicep, network.bicep, aci.bicep, plus main.bicep
	Recherche nach SKU für VNet-integration/private Endpoints
	VNet + Subnet mit Delegation an Microsoft.ContainerInstance/containerGroups — Subnet-Delegation-Property  nachschlagen
	Managed Identity + RBAC statt Admin-Credentials
	
	Zielarchitektur:
	
	
	Azure Container Registry
        ↑
        │ AcrPull RBAC
        │
User-Assigned Managed Identity
        ↑
        │ verwendet von
        │
Azure Container Instance
        │
        ↓
Delegated Subnet
Microsoft.ContainerInstance/containerGroups
        │
        ↓
       VNet



##Step2: erstellen der ordnerstruktur
1. in das verzeichnis wechseln in dem die Ordner liegen sollen
2. erstellen der ordnerstruktur_
								mkdir azure-container-lab; cd azure-container-lab
								git init
								mkdir modules
								New-Item main.bicep, modules/acr.bicep, modules/network.bicep, modules/aci.bicep
	
	
3. Microsoft.ContainerRegistry/registries - ressource in der ACR.bicp erstellt
4. properties-Block ausfüllen
	sku.name: 'Premium'
	properties.adminUserEnabled: <false> _-> Managed Identity + AcrPull-RBAC
	properties.publicNetworkAccess: 'Enabled'  — Private Endpoint kommt erst in network.bicep
	Output: acr.bicep sollte output acrId string und output acrLoginServer string - für die Identity-Zuweisung und den Image-Pull

fehler: 1. "symbolicName" nicht ersetzt durch acr
		2. quotes um location und resourceName 
		3. Identity{} drin gelassen und auch offen
		4. SKU tier braucht nur "name" kein "tier" feld
		5. ACR Name darf nur alphanumerisch sein (Buchstaben + zahlen)

##Step3: erstellen einer test RG und vorbereiten für einen what-if durchlauf

1. Subscription check:
		az account show --query name -o tsv
	
2. test RG erstellen:
		az group create --name rg-container-lab-test --location westeurope

3. acr.bicep als Module in main.bicep einbinden (modulblock in Main.bicep schreiben):
		module acr './modules/acr.bicep' = {
		name: 'acrDeployment'
	params: {
		resourceName: 'azure-container-lab'
		location: 'westeurope'
  }
}
	
4. Bicep-Syntax lokal checken:
		az bicep build --file main.bicep
		az bicep build --file acr.bicep
		
5. what-if laufen lassen:
		az deployment group what-if --resource-group rg-container-lab-test --template-file main.bicep
	
6. richtig deployen:
		az deployment group create --resource-group rg-container-lab-test --template-file main.bicep

	
Deployment Output:
     {
        "apiVersion": null,
        "extension": null,
        "id": "/subscriptions/9b3cd840-1281-4760-ab6b-ec8aaa705605/resourceGroups/rg-container-lab-test/providers/Microsoft.ContainerRegistry/registries/azurecontainerlab",
        "identifiers": null,
        "resourceGroup": "rg-container-lab-test",
        "resourceType": "Microsoft.ContainerRegistry/registries"
      }
    ],
    "outputs": {
      "acrLoginServer": {
        "type": "String",
        "value": "azurecontainerlab.azurecr.io"
      }
    },
    "parameters": null,
    "parametersLink": null,
    "providers": [
      {
        "id": null,
        "namespace": "Microsoft.Resources",
        "providerAuthorizationConsentState": null,
        "registrationPolicy": null,
        "registrationState": null,
        "resourceTypes": [
          {
            "aliases": null,
            "apiProfiles": null,
            "apiVersions": null,
            "capabilities": null,
            "defaultApiVersion": null,
            "locationMappings": null,
            "locations": [
              null
            ],
            "properties": null,
            "resourceType": "deployments",
            "zoneMappings": null
          }
        ]
      }
    ],
    "provisioningState": "Succeeded",
    "templateHash": "10771815402842442914",
    "templateLink": null,
    "timestamp": "2026-09-04T10:01:58.411239+00:00",
    "validatedResources": null,
    "validationLevel": null
  },
  "resourceGroup": "rg-container-lab-test",
  "tags": null,
  "type": "Microsoft.Resources/deployments"
}


Output in main.bicep vergessen:

main.bicep um	<output acrLoginServer string = acr.outputs.acrLoginServer> ergänzen

acrLoginServer: "azurecontainerlab.azurecr.io"
	
##Step4: Image Push

Docker identifiziert Images intern über eine Image-ID (Hash des Contents), nicht über den Namen. 
Der Name (mcr.microsoft.com/hello-world) ist nur ein Label, das auf diese ID zeigt. 
docker tag erstellt ein zweites Label für dieselbe ID — beide Namen zeigen danach auf identische Daten:

lokales Metadaten-Update:
az acr login --name azurecontainerlab
docker pull mcr.microsoft.com/hello-world
docker tag mcr.microsoft.com/hello-world azurecontainerlab.azurecr.io/hello-world:v1
docker push azurecontainerlab.azurecr.io/hello-world:v1


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
##Begriffserklärungen	
	
Subnet Delegation: designate a specific subnet for an Azure PaaS service -> 
ACR = Azure Container registry
ACI = Azure Container instances