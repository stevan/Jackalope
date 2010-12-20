
test(
    "Web Service Extends test",
    function() {
        expect(8);

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, "... we are an instance of Jackalope.Schema.Repository");

        try {
            repo.register_schema(
                {
                    "id"         : 'simple/person',
                    "title"      : 'This is a simple person schema',
                    "extends"    : { '$ref' : 'schema/web/service/crud' },
                    "properties" : {
                        "first_name" : { "type" : 'string' },
                        "last_name"  : { "type" : 'string' },
                        "age"        : { "type" : 'integer', "greater_than" : 0 },
                    }
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        var person = repo.get_compiled_schema_by_uri("simple/person");

        ok(person.links.list.target_schema.items.properties.body === person, '... self referring schema for LIST');
        ok(person.links.create.data_schema === person, '... self referring schema for POST');
        ok(person.links.create.target_schema.properties.body === person, '... self referring schema for POST');
        ok(person.links.read.target_schema.properties.body === person, '... self referring schema for GET');
        ok(person.links.edit.data_schema.properties.body === person, '... self referring schema for UPDATE');
        ok(person.links.edit.target_schema.properties.body === person, '... self referring schema for UPDATE');

    }

);
