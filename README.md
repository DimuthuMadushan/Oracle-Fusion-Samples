# Oracle-Fusion-Samples

Ballerina samples for Oracle Fusion ERP integrations and the Enterprise Scheduler Service (ESS),
built on the two connectors below:

| Connector | What it covers |
| :--- | :--- |
| `ballerinax/oraclefusion.erp.integrations` | ERP Integration Service — UCM file upload, FBDI bulk import, ESS job submission and status |
| `ballerinax/oraclefusion.common.scheduler` | Enterprise Scheduler Service — submitting, querying and reading scheduled process requests |

## Samples

### [`oraclefusion-quickstart-sample`](./oraclefusion-quickstart-sample) &nbsp;·&nbsp; [README](./oraclefusion-quickstart-sample/README.md)

The smallest thing that shows both connectors working against a live instance: one call to every
operation they expose, printing whatever comes back — the response payload, or the error. Nothing
is asserted, nothing is retried, and no report is written.

The run packs the FBDI CSV files into the archive itself, with
[`ballerina/zip`](https://central.ballerina.io/ballerina/zip), so it starts where Oracle's FBDI
template leaves off. Then seven calls, in dependency order, with the ids the later ones need taken
from the earlier responses:

| # | Call | Connector | Input from an earlier call |
| ---: | :--- | :--- | :--- |
| 0 | `zip:compress` | — | — |
| 1 | `uploadFileToUcm` | ERP integrations | the archive from step 0 |
| 2 | `submitEssJobRequest` | ERP integrations | `documentId` from call 1 |
| 3 | `importBulkData` | ERP integrations | — |
| 4 | `getEssJobStatus` | ERP integrations | `reqstId` from call 3 |
| 5 | `queryJobRequests` | Scheduler | — |
| 6 | `submitJobRequest` | Scheduler | — |
| 7 | `getJobRequest` | Scheduler | request id from call 6 |

Every call prints its own line and the run continues regardless, so one operation being unavailable
on the instance does not hide the rest.

**Run it:**

```bash
cd oraclefusion-quickstart-sample
# drop the FBDI CSV files in ./fbdi-data and fill in Config.toml — see the sample README
bal run
```

Details on the configuration keys, the expected log output, and the safety notes are in the
[sample README](./oraclefusion-quickstart-sample/README.md).

## Prerequisites

Common to every sample here:

1. **WSO2 Integrator**, or Ballerina 2201.12.0 (Swan Lake Update 12) or later.
2. **A non-production Fusion pod** and an integration user with the ERP Integration privileges.
3. **A small set of FBDI CSV files** for the interface being tested, in one directory.

> These samples upload files to UCM and submit real scheduled processes. Point them at a
> **non-production pod** only.

## Configuration

Each sample carries its own git-ignored `Config.toml`. To keep credentials outside the working
tree, put them elsewhere and point Ballerina at the file:

```bash
BAL_CONFIG_FILES=/secure/path/oracle-fusion.toml bal run
```

## References

- [Oracle ERP Integration Service REST API](https://docs.oracle.com/en/cloud/saas/financials/25b/farfa/api-erp-integration-service.html)
- [Oracle Enterprise Scheduler Service (ESS) REST API](https://docs.oracle.com/en/cloud/saas/applications-common/25b/farca/api-scheduler-requests.html)
- [WSO2 Integrator](https://wso2.com/integration-platform/integrator/)
- [Oracle Fusion ERP Integration Connector](https://central.ballerina.io/ballerinax/oraclefusion.erp.integrations/latest)
- [Oracle Fusion Scheduler Connector](https://central.ballerina.io/ballerinax/oraclefusion.common.scheduler/latest)
- [Ballerina Zip Connector](https://central.ballerina.io/ballerina/zip/latest)
