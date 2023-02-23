# Proposal: Generate Ballerina Service from GraphQL Schema

## Summary
There are two approaches in creating a graphql service. Currently, the Ballerina GraphQL package only supports code-first approach for writing a GraphQL service, where the Schema is not needed for writing a GraphQL service. This project intends to implement the schema-first approach, where the graphql service is generated using a GraphQL schema. 

## Goals
 - Provide a way to generate the Ballerina service from a given GraphQL schema.

## Motivation
Schema-first approach allows the schema to act as a contract between the client and the server. With the schema, it is possible to generate both GraphQL client and service directly. Some languages, such as Python and JavaScript, have support for both schema-first and code-first approaches.

In Ballerina, there are two main places with similar functionality. The Ballerina gRPC package uses ProtoBuf files to generate the gRPC client and/or the server. The Ballerina OpenAPI uses the OpenAPI contract file to generate the service and/or the client.
The existing Ballerina GraphQL tool can generate a GraphQL client with the given schema and documents. With the implementation of the schema-first approach, the GraphQL tool can generate GraphQL service definitions from the schema. 


## Description
This proposal intends to implement the schema-first approach by introducing a functionality to the existing Ballerina GraphQL tool. Currently, the tool supports generating a GraphQL client using the provided configurations. With this proposal, the GraphQL tool will be able to generate the corresponding Ballerina service for a given GraphQL schema.

Ballerina commands supported in the Ballerina GraphQL tool are as follows.

```
bal graphql [-i | –-input] <graphql-schema-file-path/config-file-path/service-file-path>
            [-o | –-output] <output-location>
            [--mode] <mode-type>
	        [-h | --help]
	        [-s | --service] <base-service-path>
	        [–-use-records-for-objects] 
```

The command-line arguments below can be used with the command for each particular purpose as described below.

<table>
<tr>
<th>Argument</th><th>Description</th>
</tr>
<tr>
<td>

```-i | --input```  

</td>
<td>
Depending on the situation values specified by the flag vary.
- GraphQL service generation - GraphQL schema path (eg: CustomerApi.graphql)
- GraphQL client generation - path of the GraphQL config file (eg: graphql-config.yaml) 
- GraphQL schema generation - path of the GraphQL service file (eg: service.bal) 
In every situation, this flag is mandatory. 
</td>
</tr>
<tr>
<td>

```-o | --output```

</td>
<td>
The ballerina files are generated at the same location from which the GraphQL command is executed. Optionally, they can be generated on another location specified by the optional flag `(-o | –output)`.  
</td>
</tr>
<tr>
<td>

```--mode```

</td>
<td>
Mode type is optional and can be either a service or a client. The Ballerina GraphQL service and client are generated according to the mode. Without the `--mode`, it generates a GraphQL client.
</td>
</tr>
<tr>
<td>

```-h | --help```

</td>
<td>
Help flag.
</td>
</tr>
<tr>
<td>

```-s | --service```

</td>
<td>
In GraphQL schema generation, the base path of the Ballerina GraphQL service which the schema needs to be generated can be specified with the optional flag `(-s | –service)`. If this parameter is not specified, the schema files will be generated for all the Ballerina GraphQL services declared in the input file.
</td>
</tr>
<tr>
<td>

```--use-records-for-objects```

</td>
<td>
This flag doesn’t take any values. Enabling this flag, force the GraphQL tool to generate record types for GraphQL object types wherever possible.
</td>
</tr>
</table>

The `mode` flag is not currently implemented in the GraphQL tool and it is indicated to be implemented. Mainly input, output, and mode flags are used for the scope of this project. 

GraphQL schema should be stored in a .graphql file. Following is an example usage of the tool, after implementing this proposal.

Consider the following GraphQL schema in the `customer-api.graphql` file.

```graphql
    type Query {
        book(bookId: Int!): Book 
        books: [Book!] 
    }
    type Book {
        title: String! 
        bookId: Int! 
    }
```

After the execution of the following command, two Ballerina files will be generated. One will contain the service template(`service.bal`), and the other will include the types(`types.bal`). 

`bal graphql -i customer-api.graphql --mode service`

When the `mode` flag is omitted in openAPI, it generates both the client and service by default. When the `mode` flag is omitted in gRPC, it generates general files for the client and service without specific files. 
With this implementation, the `mode` flag will be introduced to the Ballerina GraphQL tool as well, to maintain consistency. But since the GraphQL tool can differentiate the client and service generation by the file name extension (.yaml for client and .graphql for service), this might be redundant and in that case, the `mode` flag can be deprecated in the future. When the `mode` flag is not provided, the tool will identify the functionality by the input file extension. If the extension is invalid, an error will be thrown. 

This will generate two `.bal` files.

### The `types.bal` file.
This file contains a service object type and the ballerina types for the respective GraphQL types.  The service object type indicates the resolver functions that need to be implemented on the GraphQL service. 
According to the above example, the service object type will appear as below. 

```ballerina
type CustomerApi service object {
	*graphql:Service 
	
	resource function get book(string id) returns Book?;
	resource function get books() returns Book[]?;
}
```
>**Note**: Service type name is taken from the name of the .graphql file which contains the GraphQL schema.

The generation of types that match the GraphQL schema types is done according to the Ballerina GraphQL specification. Depending on the type semantics used in the GraphQL schema, there can be changes in the generated ballerina code. Following section provides examples of type generation.

#### Nullable and Non-null types
<table>
<tr>
<th> Schema </th> <th> Ballerina Resolver </th> <th> Description </th>
</tr>
<tr>
<td>

```graphql
type Query { 
    name: String! 
}
```

</td>
<td>

```ballerina
resource function get name() returns string {}
```

</td>
<td>
According to schema, return type required to be string
</td>
</tr>
<tr>
<td>

```graphql
type Query { 
    name: String 
}
```

</td>
<td>

```ballerina
resource function get name() returns string? {}
```

</td>
<td>
According to schema, return type can be string
</td>
</tr>
</table>

#### List Types
<table>
<tr>
<th> Schema </th> <th> Ballerina Resolver </th> <th> Description </th>
</tr>
<tr>
<td>

```graphql
type Query { 
    names: [String!]! 
}
```

</td>
<td>

```ballerina
resource function get names() returns string[] {}
```

</td>
<td>
According to schema, return type required to be a list which contains strings. List can be empty but list elements can’t be null.
</td>
</tr>
<tr>
<td>

```graphql
type Query { 
    names: [String!] 
}
```

</td>
<td>

```ballerina
resource function get names() returns string[]? {}
```

</td>
<td>
According to schema, return type can be a list which contains strings or return type can be null.
</td>
</tr>
<tr>
<td>

```graphql
type Query { 
    names: [String] 
}
```

</td>
<td>

```ballerina
resource function get names() returns string?[]? {}
```

</td>
<td>
According to schema, return type can be a list or null. List elements can be strings or null.
</td>
</tr>
</table>

If the ID type is present in the graphql schema, it is considered as a string in the type generation. The reasons are as follows,
- ID type is still not supported in the ballerina graphql package. 
- String type is considered rather than any other because a field with type ID is serialized as a string at the end according to the GraphQL specification.

GraphQL object types can be generated as either Ballerina record types or service types. As for the default method, all GraphQL types are generated using service types. Additionally, a flag named `--use-records-for-objects` is provided to allow for the generation of record types when there are no input arguments present in the type fields.

According to this approach, object types of the above graphql schema will be generated as below. 

```ballerina
service class Book {
    resource function get title() returns string {}
    resource function get bookId() returns int {}
}
```

Here, service type is used because no flag is provided in the initial command. Therefore, the generated `types.bal` file will be as below.

```ballerina
import ballerina/graphql;

type CustomerApi service object {
    *graphql:Service;

    resource function get book(string id) returns Book?;
    resource function get books() returns Book[]?;
};


service class Book {
    resource function get title() returns string {};
    resource function get bookId() returns int {};
}
```

If the command is provided as below, record types will be generated for the possible types. 

Command, 
`bal graphql -i customer-api.graphql --mode service --use-records-for-objects`

Generated type,

```ballerina
type Book record {
	string title;
	int bookId;
}
```

Any field in the `Book` object type doesn’t take input arguments. Therefore, the tool generates record types.

Generated `types.bal`
    
    ```ballerina
    import ballerina/graphql;

    type CustomerApi service object {
        *graphql:Service;

        resource function get book(string id) returns Book?;
        resource function get books() returns Book[]?;
    };

    type Book record {
        string title;
        int bookId;
    };
    ```

### The `service.bal` file.
This file will contain the GraphQL service implementation. After the execution of the GraphQL service generation command, this file will look like below.

```ballerina
import ballerina/graphql;

configurable int port = 9090;

service CustomerApi on new graphql:Listener(port) {
}
```

The port number of the generated service is specified as a configurable variable, with `9090` as its default value. 

Because of the service object type in the `types.bal` file , `service.bal` file will indicate a compilation error saying necessary resolvers are not implemented. Therefore, users need to implement all resolver functions that are defined in the service object type. This will avoid the scenario of the user missing to implement any resolver.

For the development of the tool, an available schema parser([link](https://github.com/graphql-java/graphql-java/blob/master/src/main/java/graphql/schema/idl/SchemaParser.java)) is intended to be used for the first iteration. If the time permits, Ballerina schema parser will be implemented. 

Implementation is done under two phases. First phase will focus on generating the service template and types from the schema. Second phase will focus on adding documentation using ballerina document comments and adding `deprecated` directive support.

Here is another example, considering various different scenarios.
Consider the schema stored in `test-api.graphql`,

```graphql 
type Query {
	book(id: Int!): Book
	books: [Book!]
profiles: [Profile!]
}
type Mutation {
addBook(
id: Int
title: String!
): Book!
}
type Subscription {
	bookTitles: String!
}
interface Info {
	name: String!
}
type Book {
	title: String!
	id: Int!
}
input BookInfo {
	id: Int!
	title: String!
}
type Teacher implements Info {
	name: String!
subject: String!
}
type Student implements Info {
	name: String!
	gpa: Float!
}
union Profile = Teacher | Student
enum Gender {
	MALE
	FEMALE
}
```

Execute the following command,

`bal graphql -i test-api.graphql --mode service`

Generated files are as below,

`service.bal`

```ballerina
import ballerina/graphql;

configurable int port = 9090;

service TestApi on new graphql:Listener(port) {
	
}

```

`types.bal`

```ballerina
import ballerina/graphql;

type TestApi service object {
	*graphql:Service;

	resource function get book(string id) returns Book?;
	resource function get books() returns Book[]?;
	resource function get profiles() returns Profile[]?;
	remote function addBook(string title, int? bookId) returns Book;
	remote function addBookWithInfo(BookInfo bookInfo) returns Book?;
	resource function subscribe titles() returns stream<string>;
};

service class Book {
    resource function get title() returns string {}
    resource function get bookId() returns int {}
}

type BookInfo record {|
    int id;
    string title;
|};

type Info distinct service object {
    resource function get name() returns string;
};


distinct service class Teacher {
    *Info;

    resource function get name() returns string {}

    resource function get subject() returns string {}
}

distinct service class Student {
    *Info;

    resource function get name() returns string {}

    resource function get gpa() returns float {}
}

type Profile Teacher|Student;

enum Gender {
    MALE,
    FEMALE
}
```

## Alternatives
-   During the generation of a GraphQL service, a default value for the port number is set, but it can also be initialized using a flag. Adding a flag can over complicate the process, because of that configuration variable is used to keep the port number.
    
-   When generating types, the default approach can be chosen to generate record types whenever possible. Other types can be generated as service types. Additionally, a flag can be provided to enforce the generation of service types only. Record type is generated for a type which has fields without input arguments. This can be complicated, in a scenario where some logic is involved with a field. Because of that, the default approach is chosen to generate service types for all the types.

## Future Tasks
- Resolver functions can return an error as well. It can be handled by adding `error` to the return type of all resolver methods by default, or providing an additional flag so that users can decide whether they need errors in resolver methods. This scenario is not handled in this proposal and may be added later. 
