
test(
    "Extends in Properties test",
    function() {
        expect(4);

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, "... we are an instance of Jackalope.Schema.Repository");

        try {
            repo.register_schema(
                {
                    "id"         : 'simple/employee',
                    "title"      : 'This is a simple employee schema',
                    "type"       : 'object',
                    "properties" : {
                        "id"         : { "type" : 'integer' },
                        "first_name" : { "type" : 'string' },
                        "last_name"  : { "type" : 'string' },
                        "age"        : { "type" : 'integer', "greater_than" : 0 },
                        "sex"        : { "type" : 'string', "enum" : [ "male", "female" ] },
                        "pay_scale"  : { "type" : "string", "enum" : [ "low", "medium", "high" ]  }
                    }
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        try {
            repo.register_schema(
                {
                    "id"         : 'simple/manager',
                    "title"      : 'This is a simple manager schema',
                    "extends"    : { '$ref' : 'simple/employee' },
                    "properties" : {
                        "title"     : { "type" : 'string' },
                        "pay_scale" : { "type" : "string", "literal" : "high" },
                        "assistant" : {
                            "extends"    : { '$ref' : 'simple/employee' },
                            "properties" : {
                                "pay_scale" : { "type" : "string", "literal" : "medium" }
                            }
                        }
                    }
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        var employee = repo.get_compiled_schema_by_uri("simple/employee");
        var manager = repo.get_compiled_schema_by_uri("simple/manager");

        deepEqual(
            manager,
            {
                "id": "simple/manager",
                "title": "This is a simple manager schema",
                "properties": {
                    "id": {
                        "type": "integer"
                    },
                    "first_name": {
                        "type": "string"
                    },
                    "last_name": {
                        "type": "string"
                    },
                    "age": {
                        "type": "integer",
                        "greater_than": 0
                    },
                    "sex": {
                        "type": "string",
                        "enum": ["male", "female"]
                    },
                    "title": {
                        "type": "string"
                    },
                    "pay_scale" : { "type" : "string", "literal" : "high" },
                    "assistant": {
                        "title": "This is a simple employee schema",
                        "type": "object",
                        "properties": {
                            "id": {
                                "type": "integer"
                            },
                            "first_name": {
                                "type": "string"
                            },
                            "last_name": {
                                "type": "string"
                            },
                            "age": {
                                "type": "integer",
                                "greater_than": 0
                            },
                            "sex": {
                                "type": "string",
                                "enum": ["male", "female"]
                            },
                            "pay_scale" : { "type" : "string", "literal" : "medium" }
                        },
                        "additional_properties": {}
                    }
                },
                "type": "object",
                "additional_properties": {}
            },
            '... manager schema is inflated correctly'
        );

    }

);
