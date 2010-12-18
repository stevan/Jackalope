# Jackalope

Jackalope is a framework for building REST style web services with embedded
hypermedia controls. It was heavily inspired by the description of "Level 3"
web services as described in [this article](http://martinfowler.com/articles/richardsonMaturityModel.html#level3)
by Martin Fowler and the book [REST in Practice](http://restinpractice.com/default.aspx).

## Core Concepts

Jackalope is built of a couple of different parts. The first part is the
schema language, which describes the messages to be sent and recieved. The
second part is the hypermedia controls, which are themselves described
in the schema language. And the last part is the REST style web services.

### Schema Language

The schema language is actually just Perl data structures, but it is simple enough
that it could be written in most any simple data serialization language, like JSON,
YAML or a dialect of XML. The schema language is also self-describing, meaning that
each core element of the language is described with the language itself. There is
support for a set of core types which are shown below in the type heirarchy.

    Any
        Null
        Boolean
        Number
            Integer
        String
        Array[ T ]
        Object[ String, T ]
          Schema

Additionally the core schema language also supports references (using the JSPON
$ref syntax) and through the use of references it is also possible to 'extend'
a schema, which is similar to object oriented inheritance, but different.

It should be noted that the schema language draws much of it's syntactic inspiration
from [JSON-Schema](http://www.json-schema.org) however the underlying implementation
and core philosophy differ greatly.

The documentation for the schema types themselves is contained within the
schema (see, like really self-decribing), take a look at Jackalope::Schema::Spec
to see this documentation. I recommend reading that document from top to bottom,
after which you should have all the information to understand what you just read,
so I recommend re-reading it then. Hopefully at that point, it will all make sense.

### Hypermedia controls

In the core set of schemas we also provide a basic 'hyperlink' schema and an 'xlink'
schema. The 'hyperlink' schema is for describing the concept of a link enough so that
a link could easily be created from the available metadata. The 'xlink' schema is
for describing the concrete implementation of a 'hyperlink'. It is perhaps useful to
think of a 'hyperlink' like a class and 'xlink' like an object instance, they have
a similar relationship to one another.

The base 'any' schema type provides an optional 'links' property, which is an array
of 'hyperlinks'. These are meant to describe the possible actions that can be taken
against a given schema. Think of them as methods, where the schema is the class. These
are also used by the REST style web services to generate the routes that can be called
on the service, and used to generate a set of hypermedia controls for an instance of
the schema.

### REST style web services

This part of Jackalope starts to get more opinionated. Currently it provides a
basic set of tools for exposing discoverable services to manage a collection a
resources in a CRUD like manner. It borrows some of the basic HTTP interactions
from the ATOM publishing protocol and Microsoft's Cannonical REST Entity model,
then mixed up with some of my personal opinions.

It should be noted that there is more to REST then simple CRUD actions on
resource collections, but currently this is what is available "out of the box"
with plans for more later on. At this point if you wanted a more complex flow
it would be possible to do it manually with the tools in Jackalope.

We extend the base Jackalope spec for this part, adding to it a 'web/resource' and
'web/resource/ref schemas and an 'web/service' schema, those can seen in
Jackalope::REST::Schema::Spec. These are the two core components of the REST part
of Jackalope.

#### Resources

Within resources there are two key concepts; resources and resource repositories.
A resource is the transport format, it looks something like this:

    {
        id      : <string id>,
        body    : <data structure modeled by your schema>,
        version : <digest of the body>,
        links   : [ <array of xlink items> ]
    }

The 'id' field is the lookup key for this given resource in the repository and the
'body' is what you have stored in the resource repository. The 'version' is a digest
of the body constructed by creating an SHA-256 hash of the cannonical JSON of the body.
And then finally the optional 'links' is an array of 'xlink' items which represent
the other available services for this resource (ex: read, update, delete, etc.)

We also have a concept of resource references, which is a representation of a
reference to a resource. It looks something like this:

     {
        $id     : <string id>,
        type_of : <schema uri of resource this refers to>,
        version : <digest of the body of the resource this refers to>,
        link    : <xlink to read this resource>
     }

The '$id' field is the same as the 'id' field in a resource, the 'type_of' field
is the schema this '$id' refers too. Then optionally we have a 'version', which is
as described above and could be used in your code to check that the resource being
referred to has not changed. We also optionally have a 'link', which is an 'xlink'
of the 'read' service for this resource (basically a link to the resource itself).

The next concept is the resource repository. Currently we supply a role that will
wrap around your data repository, you only need worry about the 'body' of the resource
and it will handle wrapping that into a proper resource as well as the generation and
checking the version string.

So, once you have a resource and a repository for them, you can plug them into a
service.

#### Services

Currently the services in Jackalope only offer a basic set of services for managing
a collection of resources, however this is not all it can do, just what is written
right now. The services take a schema, typically one that extends the 'web/service'
schema from Jackalope::REST::Schema::Spec, and a resource repository and creates
a web service with the following features.

- describedby
    - This is done by doing a GET to the describedby URI (/schema)
    - This returns the schema that the service was created with.
- listing
    - This is done by doing a GET to the URI of a collection (/)
    - The result is a list of resources, each with embedded hypermedia controls
        - It returns a 200 (OK) status code
    - TODO:
        - This should take search params and paging params as well
- creation
    - Creation is done by doing a POST to the specified creation URI (/create) with the body of a resource as the content
    - The newly created resource is returned in the body of the response
        - the resource will include links that provide hrefs for the various other actions
        - It returns a 201 (Created) status code
        - the response Location header provides the link to read the resource
            - NOTE: this may be removed since it duplicates what is in the hypermedia controls
- read
    - Reading is done by doing a GET the specified reading URI (/:id) with the ID for the resource embedded in the URL
    - The resource is returned in the body of the response
        - It returns a 200 (OK) status code
        - If the resource is not found it returns a 404 (Not Found) status code
- update
    - Updating is done by doing a PUT to the specified update URI (/:id/edit) with ...
        - The resource id embedded in the URL
        - You need to PUT the full wrapped resource (minus the links metadata) so that it can test the version string to make sure it is in sync
    - the updated resource is sent back in the body of the request
        - It returns a 202 (Accepted) status code
        - If the resource is not found it returns a 404 (Not Found) status code
        - If the resource is out of sync (versions don't match), a 409 (Conflict) status is returned with no content
        - If the ID in the URL does not match the ID in the resource, a 400 (Bad Request) status is returned with no content
- delete
    - deletion is done by doing a DELETE to the specified deletion URI (/:id/delete) with the ID for the resource embedded in the URL
        - It returns a 204 (No Content) status code
        - An optional If-Matches header is supported for version checking
            - it should contain the version string of the resource you want to delete and we will check it against the current one before deletion
            - if it does not match it returns a 409 (Conflict) status with no content

We also check to make sure that the proper HTTP method is used for the proper
URI and throw a 405 (Method Not Allowed) error with an 'Allow' header properly
populated.

## References

* [Richardson Maturity Model](http://martinfowler.com/articles/richardsonMaturityModel.html)
* [REST in Practice](http://restinpractice.com/default.aspx)
* [REST on Wikipedia](http://en.wikipedia.org/wiki/Representational_State_Transfer)
* [ATOM publishing protocol](http://www.atomenabled.org/)
* [HTTP Status Codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
* [Link relations](http://www.iana.org/assignments/link-relations/link-relations.xhtml)
* [Cannonical REST Entity](http://code.msdn.microsoft.com/cannonicalRESTEntity)


