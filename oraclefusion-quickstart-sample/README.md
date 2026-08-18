# Oracle Fusion Connector Quickstart

## Description

One call to every operation both Oracle Fusion connectors expose, printing whatever comes back —
the response payload, or the error. Nothing is asserted, nothing is retried, and no report is
written. This is the smallest thing that shows both connectors working against a live instance.

| Connector | Operations called |
| :--- | :--- |
| `ballerinax/oraclefusion.erp.integrations` | `uploadFileToUcm`, `submitEssJobRequest`, `importBulkData`, `getEssJobStatus` |
| `ballerinax/oraclefusion.common.scheduler` | `queryJobRequests`, `submitJobRequest`, `getJobRequest` |

For a run that checks the results, covers the query parameters and error paths, and produces a
Markdown report you can send on, use
[`../oraclefusion-verification-sample`](../oraclefusion-verification-sample) instead.

## Prerequisites

1. **WSO2 Integrator**, or Ballerina 2201.12.0 (Swan Lake Update 12) or later.
2. **A non-production Fusion pod** and an integration user with the ERP Integration privileges.
3. **A small FBDI zip** for the interface being tested.

## Usage Instructions

### Step 1 — Fill in the configuration

Edit `Config.toml`. It holds only the values the seven calls cannot work without:

| Key | What it is for |
| :--- | :--- |
| `erpServiceUrl` | `https://<pod>.fa.<region>.oraclecloud.com/fscmRestApi/resources/11.13.18.05` |
| `schedulerServiceUrl` | `https://<pod>.fa.<region>.oraclecloud.com/ess/rest/scheduler/v1` |
| `username`, `password` | The Fusion integration user |
| `filePath`, `fileName` | The FBDI zip to upload, and the name UCM files it under |
| `documentAccount` | Interface-specific UCM account, e.g. `fin$/payables$/import$` |
| `jobName`, `parameterList` | The `importBulkData` job and its positional parameters |
| `jobPackageName`, `jobDefName`, `essParameters` | The same job as `submitEssJobRequest` addresses it |
| `jobDefinitionId` | The scheduled process `submitJobRequest` submits |

`Config.toml` is git-ignored. To keep credentials outside the working tree, put them elsewhere and
point Ballerina at the file:

```bash
BAL_CONFIG_FILES=/secure/path/oracle-quickstart.toml bal run
```

Everything else each operation accepts is either optional, or taken from an earlier response — see
[How It Works](#how-it-works).

### Step 2 — Run

Use the Run button in WSO2 Integrator, or:

```bash
bal run
```

## How It Works

The calls run in dependency order, and the ids the later ones need come from the earlier responses
rather than from configuration:

| # | Call | Input that comes from an earlier call |
| ---: | :--- | :--- |
| 1 | `uploadFileToUcm` | — |
| 2 | `submitEssJobRequest` | `documentId` from call 1 |
| 3 | `importBulkData` | — |
| 4 | `getEssJobStatus` | `reqstId` from call 3 |
| 5 | `queryJobRequests` | — |
| 6 | `submitJobRequest` | — |
| 7 | `getJobRequest` | request id from call 6 |

Every call prints its own line and the run continues regardless, so one operation being unavailable
on the instance does not hide the rest. When a call cannot run because the response it depends on
did not arrive, it says so rather than staying silent.

Calls 3 and 4 cover the same ground as 1, 2 and the status read, in one operation instead of two —
`importBulkData` is what Oracle recommends for FBDI imports, and both are called because instances
differ in which they permit.

## Example Log Output

```
=== ERP Integrations ===
uploadFileToUcm -> {"operationName":"uploadFileToUCM", "documentId":"UCMFA00123456", ...}
submitEssJobRequest -> {"operationName":"submitESSJobRequest", "reqstId":"301457", ...}
importBulkData -> {"operationName":"importBulkData", "documentId":"UCMFA00123457", "reqstId":"301458", ...}
getEssJobStatus -> {"items":[{"reqstId":"301458", "requestStatus":"RUNNING", ...}], "count":1, ...}

=== Scheduler ===
queryJobRequests -> {"items":[{"requestId":301458, "state":"RUNNING", ...}], "count":25, ...}
submitJobRequest -> {"id":301459, "links":[...]}
getJobRequest -> {"requestId":301459, "state":"WAIT", "submitter":"INTEGRATION_USER", ...}
```

A failure prints the message and the error detail, which is where Fusion puts the useful part:

```
uploadFileToUcm -> error: Forbidden | {"body":{"detail":"...","status":403},"statusCode":403}
```

An ESS job that ends in `ERROR` is not a connector failure — the file, the job parameters, or the
privileges are wrong, and the reason lives in the job log under Tools → Scheduled Processes.

## Safety and Cleanup

Run this against a **non-production pod**. It uploads two files to UCM and submits three real
requests: `submitEssJobRequest`, `importBulkData` and `submitJobRequest` all run to completion.

- Uploaded UCM documents persist after the run.
- Cancel any request that hangs from Tools → Scheduled Processes.

## Project Layout

```
oraclefusion-quickstart-sample/
├── Ballerina.toml       package + the two local connector dependencies
├── Config.toml          the values the calls cannot work without
├── automation.bal       the seven calls, in dependency order
├── config.bal           the configurable values
├── connections.bal      the two connector clients
├── functions.bal        printOutcome - prints a response or an error
├── types.bal            (empty)
├── data_mappings.bal    (empty)
└── agents.bal           (empty)
```

## References

- [Oracle ERP Integration Service REST API](https://docs.oracle.com/en/cloud/saas/financials/25b/farfa/api-erp-integration-service.html)
- [Oracle Enterprise Scheduler Service (ESS) REST API](https://docs.oracle.com/en/cloud/saas/applications-common/25b/farca/api-scheduler-requests.html)
