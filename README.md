# azure-container-lab

A Bicep-based Azure lab demonstrating credential-free container image pulls: Azure Container Registry (Premium), a VNet-injected Azure Container Instance, and a User-Assigned Managed Identity with RBAC — no admin credentials, no secrets in code.

## Architecture

```
                         ┌─────────────────────────────┐
                         │   Resource Group             │
                         │   rg-container-lab-test      │
                         │                               │
  ┌──────────────┐       │  ┌────────────────────────┐  │
  │ User-Assigned │──────┼─▶│  ACR (Premium)          │  │
  │ Managed       │ AcrPull │  azurecontainerlab      │  │
  │ Identity      │  RBAC │  └────────────────────────┘  │
  └───────┬───────┘       │              ▲                │
          │               │              │ image pull     │
          │ assigned to   │              │ (identity-based│
          ▼               │              │  auth)         │
  ┌──────────────────┐    │  ┌───────────┴────────────┐  │
  │ Container Group   │◀──┼──│  VNet (192.168.0.0/16)  │  │
  │ aci-container-lab │    │  │  Subnet: snet-aci        │  │
  │ (private IP only) │    │  │  (delegated to ACI)      │  │
  └──────────────────┘    │  └─────────────────────────┘  │
                         └─────────────────────────────┘
```

No public IP on the container group — it only has an address inside the delegated subnet. No `adminUserEnabled` on the ACR — pull authentication runs entirely through the Managed Identity + `AcrPull` role assignment.

## Repository structure

```
azure-container-lab/
├── main.bicep              # orchestrates all modules
└── modules/
    ├── acr.bicep            # Container Registry (Premium SKU)
    ├── network.bicep        # VNet + ACI-delegated subnet
    ├── identity.bicep        # User-Assigned Managed Identity
    ├── rbac.bicep            # AcrPull role assignment (identity → ACR)
    └── aci.bicep              # Container Instance (VNet-injected, identity-based pull)
```

## Prerequisites

- Azure CLI, logged in (`az login`)
- Bicep CLI (`az bicep upgrade`)
- Docker Desktop (only needed to build/push your own images; not required to redeploy the existing `hello-world:v1` image)

## Deploy

```powershell
az group create --name rg-container-lab-test --location westeurope
az deployment group create --resource-group rg-container-lab-test --template-file main.bicep
```

Preview changes first with:
```powershell
az deployment group what-if --resource-group rg-container-lab-test --template-file main.bicep
```

## Verify

```powershell
az container show --resource-group rg-container-lab-test --name aci-container-lab --query instanceView.state
az container logs --resource-group rg-container-lab-test --name aci-container-lab
```

Confirm the identity-only auth path (no admin fallback):
```powershell
az acr show --name azurecontainerlab --query adminUserEnabled
# expect: false
```

## Cleanup

```powershell
az group delete --name rg-container-lab-test --yes --no-wait
```

ACR Premium has a fixed daily cost regardless of usage — tear down when not actively working on the lab.

## Lessons learned / troubleshooting log

| Break | Root cause | Fix |
|---|---|---|
| Wrong resource picked for the VNet (`Microsoft.Network/networkManagers`) | Confused Azure Virtual Network Manager (a multi-VNet governance tool) with an actual VNet resource | Used `Microsoft.Network/virtualNetworks` instead |
| ACR deployment failed: `ResourceNameInvalid` | ACR names must be alphanumeric only — no hyphens | Renamed `azure-container-lab` → `azurecontainerlab` |
| Module output stayed `null` after adding an `output` statement | Output was added to `main.bicep` *after* the last successful deploy; `az deployment group show` only reads the stored deployment record, it doesn't re-run Bicep | Re-ran `az deployment group create` so the record picked up the new output |
| Duplicate property errors (`BCP025`) in `acr.bicep` | Pasted an updated `properties` block without deleting the old one | Removed the duplicate lines |
| Assumed System-Assigned Managed Identity would work for ACR image pulls | Incorrect assumption | Microsoft Learn confirms ACI does **not** support system-assigned identity for ACR pulls, regardless of OS — a User-Assigned Identity is required |
| `rbac.bicep` had no enforced build order relative to `acr.bicep` | The module only referenced the ACR via an `existing` name lookup, which Bicep doesn't track as a dependency (unlike an output reference) | Added explicit `dependsOn: [ acr ]` on the `rbac` module in `main.bicep` |
| `what-if` didn't list the `ContainerGroup` resource at all, even though it deployed successfully | Apparent display limitation of `what-if` with nested modules whose values resolve only at deploy time (same pattern seen in the `Unsupported` diagnostic on the RBAC role assignment's GUID) | Deployed directly and verified via `az resource list` / `az container logs` instead of relying on `what-if` |
| `docker` commands failed as unrecognized PowerShell commands | Docker Desktop wasn't installed yet | Installed Docker Desktop with WSL2 backend |
| WSL2 consuming large amounts of RAM in the background | Default unbounded VM memory allocation | Capped via `.wslconfig` (`memory=4GB`) |
| Recurring `~ Modify` noise on ACR/VNet in every `what-if` | Azure auto-sets several properties (`encryption`, `dataEndpointEnabled`, `roleAssignmentMode`, `privateEndpointVNetPolicies`, etc.) that weren't declared in the Bicep templates | Declared them explicitly to match actual state |

## Notes

- ACR SKU: **Premium** — required for VNet/Private Link support (Standard/Basic don't support it), even though this lab currently uses `publicNetworkAccess: 'Enabled'`.
- Role assignment uses `LegacyRegistryPermissions` (registry-scoped `AcrPull`), not the newer `AbacRepositoryPermissions` model — sufficient for this lab's single-repository scope.
