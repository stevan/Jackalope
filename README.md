# Jackalope

Jackalope is a framework for building REST style web services with embedded
hypermedia controls. It was heavily inspired by the description of "Level 3"
web services as described in [this article](http://martinfowler.com/articles/richardsonMaturityModel.html#level3)
by Martin Fowler.

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


## References

[Richardson Maturity Model](http://martinfowler.com/articles/richardsonMaturityModel.html)
[REST on Wikipedia](http://en.wikipedia.org/wiki/Representational_State_Transfer)
[ATOM publishing protocol](http://www.atomenabled.org/)
[HTTP Status Codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
[Link relations](http://www.iana.org/assignments/link-relations/link-relations.xhtml)
[Cannonical REST Entity](http://code.msdn.microsoft.com/cannonicalRESTEntity)


