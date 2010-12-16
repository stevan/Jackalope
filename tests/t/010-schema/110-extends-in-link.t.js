
test(
    "Extends in Link test",
    function() {
        expect(3);

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, "... we are an instance of Jackalope.Schema.Repository");

        try {
            repo.register_schema(
                {
                    "id"         : "simple/person",
                    "title"      : "This is a simple person schema",
                    "type"       : "object",
                    "properties" : {
                        "id"         : { "type" : "integer" },
                        "first_name" : { "type" : "string" },
                        "last_name"  : { "type" : "string" },
                        "age"        : { "type" : "integer", "greater_than" : 0 },
                        "sex"        : { "type" : "string", "enum" : [ "male", "female" ] }
                    },
                    "links" : [
                        {
                            "rel"         : "create",
                            "href"        : "/create",
                            "method"      : "PUT",
                            "data_schema" : {
                                "extends"    : { "$ref" : "#" },
                                "properties" : {
                                    "id" : { "type" : "null" }
                                },
                                "links" : []
                            }
                        }
                    ]
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        var person = repo.get_compiled_schema_by_uri("simple/person");

        deepEqual(
            person.links[0].data_schema.properties,
            {
                "id"         : { "type" : "null" },
                "first_name" : { "type" : "string" },
                "last_name"  : { "type" : "string" },
                "age"        : {
                    "type"         : "integer",
                    "greater_than" : 0
                },
                "sex"        : {
                    "type" : "string",
                    "enum" : [ "male", "female" ]
                }
            },
            "... the extended schema embedded in the link is resolved correctly"
        );

    }

);
