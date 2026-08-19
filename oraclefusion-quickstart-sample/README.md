# Oracle Fusion Connector Quickstart

## Description

One call to every operation both Oracle Fusion connectors expose, printing whatever comes back —
the response payload, or the error. Nothing is asserted, nothing is retried, and no report is
written. This is the smallest thing that shows both connectors working against a live instance.

The run is split into three phases, each switched on its own in `Config.toml`, so a phase an
instance does not permit — or that is simply not the one being investigated — can be left out:

| Phase | Config key | Connector | Operations called |
| :--- | :--- | :--- | :--- |
| Upload and submit | `enableUploadOperations` | `oraclefusion.erp.integrations` | `uploadFileToUcm`, `submitEssJobRequest` |
| Bulk import | `enableImportOperations` | `oraclefusion.erp.integrations` | `importBulkData`, `getEssJobStatus` |
| Scheduler | `enableSchedulerOperations` | `oraclefusion.common.scheduler` | `queryJobRequests`, `submitJobRequest`, `getJobRequest` |

The two ERP phases are on by default and the scheduler phase is off. A phase that is off reads none
of its own configuration, so only the keys the enabled phases need have to be filled in.

The archive the two uploads carry is built by the run itself, with
[`ballerina/zip`](https://central.ballerina.io/ballerina/zip), from the FBDI CSV files on disk — so
the sample starts where Oracle's FBDI template leaves off rather than from a zip made by hand.

For a run that checks the results, covers the query parameters and error paths, and produces a
Markdown report you can send on, use
[`../oraclefusion-verification-sample`](../oraclefusion-verification-sample) instead.

## Prerequisites

1. **WSO2 Integrator**, or Ballerina 2201.12.0 (Swan Lake Update 12) or later.
2. **A non-production Fusion pod** and an integration user with the ERP Integration privileges.
3. **A small set of FBDI CSV files** for the interface being tested, in one directory.

## Usage Instructions

### Step 1 — Fill in the configuration

Edit `Config.toml`. It holds only the values the seven calls cannot work without:

| Key | What it is for |
| :--- | :--- |
| `erpServiceUrl` | `https://<pod>.fa.<region>.oraclecloud.com/fscmRestApi/resources/11.13.18.05` |
| `schedulerServiceUrl` | `https://<pod>.fa.<region>.oraclecloud.com/ess/rest/scheduler/v1` |
| `username`, `password` | The Fusion integration user |
| `dataDirPath` | Directory holding the FBDI CSV files, or a single file |
| `zipFilePath` | Where the archive is written. Must be outside `dataDirPath` |
| `fileName` | The name UCM files the archive under |
| `documentAccount` | Interface-specific UCM account, e.g. `fin$/payables$/import$` |
| `enableUploadOperations` | Run the upload-and-submit phase. `true` by default |
| `enableImportOperations` | Run the bulk-import phase. `true` by default |
| `enableSchedulerOperations` | Run the scheduler phase. `false` by default |
| `jobPackageName`, `jobDefName`, `essParameters` | The `submitEssJobRequest` job — upload phase only |
| `jobName`, `parameterList` | The `importBulkData` job and its positional parameters — import phase only |
| `jobDefinitionId` | The scheduled process `submitJobRequest` submits — scheduler phase only |

`Config.toml` is git-ignored. To keep credentials outside the working tree, put them elsewhere and
point Ballerina at the file:

```bash
BAL_CONFIG_FILES=/secure/path/oracle-quickstart.toml bal run
```

Both service URLs and the credentials are always needed, because both clients are created at
startup. Everything else is read only by the phase that uses it, so the keys of a disabled phase can
be left empty.

The scheduler phase is off by default: unlike the ERP calls, `submitJobRequest` starts a scheduled
process on the pod rather than only reading from it. Set `enableSchedulerOperations = true` with a
`jobDefinitionId` that is safe to run there to include it.

Everything else each operation accepts is either optional, or taken from an earlier response — see
[How It Works](#how-it-works).

### Step 2 — Run

Use the Run button in WSO2 Integrator, or:

```bash
bal run
```

## How It Works

Within each phase the calls run in dependency order, and the ids the later ones need come from the
earlier responses rather than from configuration — which is why each pair stays together in one
phase:

| Phase | # | Call | Input that comes from an earlier call |
| :--- | ---: | :--- | :--- |
| — | 0 | `zip:compress` | — |
| Upload and submit | 1 | `uploadFileToUcm` | the archive from step 0 |
| Upload and submit | 2 | `submitEssJobRequest` | `documentId` from call 1 |
| Bulk import | 3 | `importBulkData` | the archive from step 0 |
| Bulk import | 4 | `getEssJobStatus` | `reqstId` from call 3 |
| Scheduler | 5 | `queryJobRequests` | — |
| Scheduler | 6 | `submitJobRequest` | — |
| Scheduler | 7 | `getJobRequest` | request id from call 6 |

Step 0 belongs to no phase: it runs when either ERP phase is on, once for the two, and is skipped
entirely when both are off — so a scheduler-only run needs no CSV files on disk.

Every call prints its own line and the run continues regardless, so one operation being unavailable
on the instance does not hide the rest. When a call cannot run because the response it depends on
did not arrive, it says so rather than staying silent. Step 0 is the exception: the phases that
follow it cannot run without the archive, so a failure there ends the run.

### Why step 0 passes `includeSourceDirectory: false`

Oracle matches each entry name in the archive against the interface table it feeds, so the CSV files
have to sit at the **root** of the zip. `includeSourceDirectory` defaults to `true`, which makes the
source directory a wrapping entry and gives every name a prefix — the upload still succeeds, and the
import then fails on an instance that accepted the same data yesterday. The other option the run
sets is `overwrite: true`, so the sample can be re-run.

`zipFilePath` must be outside `dataDirPath`: an archive cannot contain itself, and `compress`
rejects the attempt rather than producing a broken file.

The entry names are printed after packing, because a missing or misnamed CSV is otherwise the
failure that surfaces much later as an ESS job in `ERROR` with nothing wrong on the Ballerina side.

The bulk-import phase covers the same ground as the upload-and-submit phase, in one operation
instead of two — `importBulkData` is what Oracle recommends for FBDI imports. Both are on by default
because instances differ in which they permit; once you know which one your instance takes, turn the
other off.

## Example Log Output

```
compress -> ./APInvoiceImport.zip (ApInvoicesInterface.csv, ApInvoiceLinesInterface.csv)

=== Upload and submit ===
uploadFileToUcm -> {"operationName":"uploadFileToUCM", "documentId":"UCMFA00123456", ...}
submitEssJobRequest -> {"operationName":"submitESSJobRequest", "reqstId":"301457", ...}

=== Bulk import ===
importBulkData -> {"operationName":"importBulkData", "documentId":"UCMFA00123457", "reqstId":"301458", ...}
getEssJobStatus -> {"items":[{"reqstId":"301458", "requestStatus":"RUNNING", ...}], "count":1, ...}

=== Scheduler === skipped: enableSchedulerOperations is false
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
├── Ballerina.toml       package definition
├── Config.toml          the values the calls cannot work without
├── fbdi-data/           the FBDI CSV files (git-ignored, yours to provide)
├── automation.bal       the archive, then the seven calls in dependency order
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
- [WSO2 Integrator](https://wso2.com/integration-platform/integrator/)
- [Oracle Fusion ERP Integration Connector](https://central.ballerina.io/ballerinax/oraclefusion.erp.integrations/latest)
- [Oracle Fusion Scheduler Connector](https://central.ballerina.io/ballerinax/oraclefusion.common.scheduler/latest)
- [Ballerina Zip Connector](https://central.ballerina.io/ballerina/zip/latest)
