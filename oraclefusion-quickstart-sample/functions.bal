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

import ballerina/io;

# Prints what one call returned - the response payload, or the error.
#
# Fusion puts the useful part of a failure in the response body, which the Ballerina HTTP client
# carries in the error detail rather than the message, so both are printed.
#
# + operation - Connector operation that was called
# + outcome - What it returned
function printOutcome(string operation, anydata|error outcome) {
    if outcome is error {
        io:println(string `${operation} -> error: ${outcome.message()} | ${outcome.detail().toString()}`);
        return;
    }
    io:println(string `${operation} -> ${outcome.toJsonString()}`);
}
