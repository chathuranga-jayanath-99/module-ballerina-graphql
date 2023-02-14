# Proposal: Generate Ballerina Service from GraphQL Schema

## Summary
There are two approaches in creating a GraphQL service. Currently, the Ballerina GraphQL package only supports code-first approach in writing a GraphQL service, where the Schema is not needed for writing a GraphQL service. This project intends to implement the schema-first approach, where the GraphQL service is generated using a GraphQL schema.

## Goals
 - Given the schema, enable to generate the Ballerina code for GraphQL service.

## Motivation
Schema-first approach allows the schema to act as an agreement between the client and the server. With the schema, it is possible to generate both GraphQL client and service directly. The existing Ballerina GraphQL tool can generate a GraphQL client with the given schema and documents. With the implementation of the schema-first approach, the GraphQL tool can generate GraphQL service definitions from the schema.

## Description
Some languages have both approaches implemented. Python and Javascript are examples of that.

In Ballerina, there are two main places with similar functionality. The Ballerina gRPC package uses ProtoBuf files to generate the gRPC client and/or the server. The Ballerina OpenAPI uses the OpenAPI contract file to generate the service and/or the client.

Similarly, this proposal proposes to generate the GraphQL service from the GraphQL schema file. The client generation is already handled by the Ballerina GraphQL tool.

GraphQL schema should be stored in a .graphql file. Following is an example usage of the tool, after implementing this proposal.

Consider the following GraphQL schema in the `sample.graphql` file.

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
After the execution of the following command, two Ballerina files will be generated. One will contain the service template, and the other will include the types.

`bal graphql -i sample.graphql -mode service`

When the `mode` flag is omitted in openAPI, it generates both the client and service by default.When the `mode` flag is omitted in gRPC, it generates general files for client and service without specific files.

With this implementation, the `mode` flag will be introduced to the Ballerina GraphQL tool as well, to maintain consistency. But since GraphQL tool can differentiate the client and service generation by the file name extension (.yaml for client and .graphql for service), this might be redundant and in that case, the `mode` flag can be deprecated in the future.

The port number of the generated service is specified as a configurable variable, with 9090 as its default value.

Generated service template will appear as below.
```ballerina
import ballerina/graphql;

configurable int port = 9090;

service /graphql on new graphql:Listener(port) {
    resource function get book(string id) returns Book? {}
    resource function get books() returns Book[]? {}
}
```
>**Note**: According to the query type in the schema, the resolver mapped for `books` should return a list of Book or null.

The generation of types that match the GraphQL schema types is done according to the Ballerina GraphQL specifications. To illustrate this, the following is an example.

Considering a single object,

<table>
<tr>
<th> Schema </th> <th> Ballerina Resolver </th> <th> Description </th>
</tr>
<tr>
<td>

```graphql
type Query { 
    book: Book! 
} 
```

</td>
<td>

```ballerina
resource function get book() returns Book {}
```

</td>
<td>
According to schema, return type required to be Book
</td>
</tr>

<tr>
<td>

```graphql
type Query { 
    book: Book
}
```

</td>
<td>

```ballerina
resource function get book() returns Book? {}
```

</td>
<td>
According to schema, return type can be Book
</td>
</tr>

</table>

Considering a list object,

<table>
<tr>
<th>Schema</th><th>Ballerina Resolver</th><th>Description</th>
</tr>
<tr>
<td>

```graphql
type Query { 
    books: [Book!]!
}
```

</td>
<td>

```ballerina
resource function get books() returns Book[] {}
```

</td>
<td>According to schema, return type required to be a list which contains Book objects. List can be empty but list elements can’t be null</td>
</tr>

<tr>
<td>

```graphql
type Query { 
    books: [Book!] 
}
```

</td>
<td>

```ballerina
resource function get books() returns Book[]? {}
```

</td>
<td>According to schema, return type can be a list which contains Book objects or return type can be null</td>

</tr>

<tr>
<td>

```graphql
type Query { 
    books: [Book] 
}
```

</td>
<td>

```ballerina
resource function get books() returns Book?[]? {}
```

</td>
<td>According to schema, return type can be a list or null. List elements can be Book objects or null</td>

</tr>

</table>

GraphQL output objects can be generated as either Ballerina record types or service types. As for the default method, all GraphQL types are generated using service types. Additionally, a flag named `–use-records-for-objects` is provided to allow for the generation of record types when there are no input arguments present in the type fields.

According to this approach, types of the above example will be generated as below.
```ballerina 
service class Book {
    resource function get title() returns string {}
    resource function get bookId() returns int {}
}
```
Here, service type is used because no flag is provided in the initial command.
If the command is provided as below, record type will be generated.

Command,

`bal graphql -i sample.graphql -mode service –use-records-for-objects`

Generated type,
```ballerina
type Book record {
    string title;
    int bookId;
}
```
If the ID type is present in the GraphQL schema, it is considered as a string in the type generation. The reasons are as follows,
-   ID type is still not supported in the ballerina GraphQL package.
-   String type is considered rather than any other because a field with type ID is serialized as a string at the end according to the GraphQL specification.

An available schema parser([link](https://github.com/graphql-java/graphql-java/blob/master/src/main/java/graphql/schema/idl/SchemaParser.java)) is intended to be used for the first iteration. If the time permits, Ballerina schema parser will be implemented.

Implementation is done under two phases. First phase will focus on generating service template and types from the schema. Second phase will focus on adding documentation using ballerina document comments and adding `deprecated` directive support.

Here is another example, considering different scenarios.
Consider the schema stored in `test.graphql`,
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

`bal graphql -i test.graphql -mode service`

Generated files are as below,

`service.bal`
```ballerina
import ballerina/graphql;

configurable int port = 9090;

service /graphql on new graphql:Listener(port) {
    resource function get book(string id) returns Book? {}
    resource function get books() returns Book[]? {}
    resource function get profiles() returns Profile[]? {}
    remote function addBook(string title, int? bookId) returns Book {}
    remote function addBookWithInfo(BookInfo bookInfo) returns Book? {}
    resource function subscribe titles() returns stream<string> {}
}
```

`types.bal`
```ballerina
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
