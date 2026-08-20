# QuickStart Samples — Oracle Fusion ERP

A collection of Ballerina integrations for Oracle Fusion ERP.

## Integrations

### Upload File to UCM
Compresses a CSV file into a ZIP, encodes it as Base64, and uploads it to Oracle WebCenter Content (UCM) using the ERP Integrations API.

### Bulk Import
Compresses a CSV file, encodes it as Base64, and submits it as a bulk data import job via the ERP Integrations API.

### Submit ESS Job
Submits an Enterprise Scheduler Service (ESS) job using the ERP Integrations API and polls until the job completes.

### Scheduler
Submits an ESS job request, fetches the job details by request ID, and queries submitted job requests using the Oracle Fusion Common Scheduler API.

## Configuration

Each integration requires a `Config.toml` with the following common fields:

```toml
serviceUrl   = "<Oracle Fusion ERP base URL>"
erpUsername  = "<username>"
erpPassword  = "<password>"
```

Refer to each integration's `config.bal` for additional required fields.
