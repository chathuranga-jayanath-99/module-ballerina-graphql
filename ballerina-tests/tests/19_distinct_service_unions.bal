// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

import ballerina/test;

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServiceObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("union_of_distinct_service_objects.graphql");
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {
                name: "Walter White",
                subject: "Chemistry"
            }
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union", "negative"]
}
isolated function testInvalidQueryWithDistinctServiceUnions() returns error? {
    string document = check getGraphQLDocumentFromFile("invalid_query_with_distinct_service_unions.graphql");
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = {
        errors: [
            {
                message: string `Cannot query field "name" on type "StudentService_TeacherService". Did you mean to use a fragment on "StudentService" or "TeacherService"?`,
                locations: [
                    {
                        line: 3,
                        column: 9
                    }
                ]
            }
        ]
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServicesQueryOnSelectedTypes() returns error? {
    string document = string`query { profile(id: 200) { ... on StudentService { name } } }`;
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            profile: {}
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServicesArrayQueryOnSelectedTypes() returns error? {
    string document = string`query { search { ... on TeacherService { name } } }`;
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            search: [
                {},
                {
                    name: "Walter White"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionOfDistinctServicesArrayQueryOnSelectedTypesFragmentOnRoot() returns error? {
    string document = string`query { ... on Query { search { ... on TeacherService { name } } } }`;
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            search: [
                {},
                {
                    name: "Walter White"
                }
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionTypesWithFieldReturningEnum() returns error? {
    string graphqlUrl = "http://localhost:9092/unions";
    string document = string`query { profile(id: 101) { ... on TeacherService { name holidays } } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data:{
            profile:{
                name:"Walter White",
                holidays:["SATURDAY", "SUNDAY"]
            }
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testUnionTypesWithNestedObjectIncludesFieldReturningEnum() returns error? {
    string graphqlUrl = "http://localhost:9092/unions";
    string document = string`query { profile(id: 101) { ... on TeacherService { holidays school { name openingDays } } } }`;
    json result = check getJsonPayloadFromService(graphqlUrl, document);
    json expectedPayload = {
        data:{
            profile:{
                holidays:["SATURDAY", "SUNDAY"],
                school:{
                    name:"CHEM",
                    openingDays:["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"]
                }
            }
        }
    };
    assertJsonValuesWithOrder(result, expectedPayload);
}

@test:Config {
    groups: ["service", "union"]
}
isolated function testNullableUnionOfDistinctServicesArrayQueryOnSelectedTypes() returns error? {
    string document = string`query { services { ... on TeacherService { name } } }`;
    string url = "http://localhost:9092/unions";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data: {
            services: [
                {},
                {
                    name: "Walter White"
                },
                null
            ]
        }
    };
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["service", "union", "introspection"]
}
isolated function testUnionTypeNames() returns error? {
    string document = check getGraphQLDocumentFromFile("union_type_names.graphql");
    string url = "http://localhost:9092/union_type_names";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("union_type_names.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
