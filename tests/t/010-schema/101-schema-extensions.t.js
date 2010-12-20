
test(
    "Schema Extension test",
    function() {
        expect(12);

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
                    "links" : {
                        "self" : {
                            "rel"           : 'self',
                            "href"          : '/:id/read',
                            "method"        : 'GET',
                            "target_schema" : { '$ref' : '#' }
                        },
                        "edit" : {
                            "rel"           : 'edit',
                            "href"          : '/:id/update',
                            "method"        : 'GET',
                            "target_schema" : { '$ref' : '#' }
                        }
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
                    "id"         : "simple/employee",
                    "title"      : "This is a simple employee schema",
                    "extends"    : { "$ref" : "simple/person" },
                    "properties" : {
                        "title"   : { type : "string" },
                        "manager" : { "$ref" : "#" }
                    },
                    "links" : {
                        "self" : {
                            "rel"           : 'self',
                            "href"          : '/:id',
                            "method"        : 'GET',
                            "target_schema" : { '$ref' : '#' }
                        }
                    }
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        var person = repo.get_compiled_schema_by_uri("simple/person");
        var employee = repo.get_compiled_schema_by_uri("simple/employee");

        ok(employee.type != undefined, "... employee has the type key");
        ok(employee.type == "object", "... employee has the right type");

        ok(employee.links != undefined, "... employee has the links key");
        ok(employee.links !== person.links, "... employee links is not the same object as person links");

        ok(employee.properties.manager === employee, "... embedded manager schema is the same as employee");

        ok(employee.links.self.target_schema === employee, "... employee links target_schema is the same object as employee");
        ok(person.links.self.target_schema === person, "... person links target_schema is the same object as person");

        ok(employee.links.edit.target_schema === employee, "... employee links target_schema is the same object as employee");
        ok(person.links.edit.target_schema === person, "... person links target_schema is the same object as person");

    }

);
