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

import ballerinax/oraclefusion.common.scheduler;
import ballerinax/oraclefusion.erp.integrations;

// The ERP Integrations API carries the file as base64 inside the JSON body, so uploads need more
// than the connector's 60 second default.
final integrations:Client erpClient = check new ({auth: {username, password}, timeout: 180}, erpServiceUrl);

final scheduler:Client schedulerClient = check new ({auth: {username, password}}, schedulerServiceUrl);
