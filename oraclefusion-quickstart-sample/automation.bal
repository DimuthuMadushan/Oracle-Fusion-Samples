// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// One call to every operation both Oracle Fusion connectors expose, printing whatever comes back,
// in three phases that are enabled independently:
//
//   enableUploadOperations     uploadFileToUcm, submitEssJobRequest    (erp.integrations)
//   enableImportOperations     importBulkData, getEssJobStatus         (erp.integrations)
//   enableSchedulerOperations  queryJobRequests, submitJobRequest,
//                              getJobRequest                           (common.scheduler)
//
// The phases are separate because each stands on its own: phases 1 and 2 cover the same ground two
// different ways - staging the file and submitting a job over it, against the single call Oracle
// recommends for FBDI imports - and phase 3 submits a scheduled process instead of loading data.
// Which of them an instance permits, and which one is being investigated, differ from run to run.
// Each phase also needs configuration the others do not, so turning one off drops its requirements
// with it.
//
// Nothing is asserted and no call is retried. Each result is printed and the run continues, so one
// operation being unavailable on the instance does not hide the rest.
//
// The ids the later calls need come from the earlier responses, not from configuration: the
// document `submitEssJobRequest` submits is the one `uploadFileToUcm` returned, the request
// `getEssJobStatus` reads is the one `importBulkData` submitted, and the request `getJobRequest`
// reads is the one `submitJobRequest` created. That is why the pairs stay together in one phase.
//
// This file holds only the gating. Each phase, and the `prepareArchive` step the two upload phases
// share, is in `functions.bal`.
//
// The archive the two uploads carry is built by the run as well, from the FBDI CSV files on disk, so
// the run starts from what Oracle's FBDI template produces rather than from a zip made by hand.

import ballerina/io;

public function main() returns error? {
    // The archive is only built when a phase carries it, so a scheduler-only run needs no CSV
    // files on disk. Both upload phases send the same bytes, so it is built once for the two.
    if enableUploadOperations || enableImportOperations {
        string documentContent = check prepareArchive();

        if enableUploadOperations {
            check runUploadOperations(documentContent);
        } else {
            io:println("\n=== Upload and submit === skipped: enableUploadOperations is false");
        }

        if enableImportOperations {
            check runImportOperations(documentContent);
        } else {
            io:println("\n=== Bulk import === skipped: enableImportOperations is false");
        }
    } else {
        io:println("\n=== Upload and submit, bulk import === skipped: both phases are false");
    }

    if enableSchedulerOperations {
        check runSchedulerOperations();
    } else {
        io:println("\n=== Scheduler === skipped: enableSchedulerOperations is false");
    }
}
