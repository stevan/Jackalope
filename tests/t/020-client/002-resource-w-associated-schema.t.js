
test(
    "Resource With Associated Schema test",
    function() {

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
                    "type"       : "object",
                    "properties" : {
                        "first_name" : { "type" : 'string' },
                        "last_name"  : { "type" : 'string' },
                        "age"        : { "type" : 'integer', "greater_than" : 0 },
                    },
                    "additional_properties" : {
                        "nickname" : { "type" : "string" }
                    }
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        var person = repo.get_compiled_schema_by_uri("simple/person");

        var resource = new Jackalope.Client.Resource ({
            "id"   : "stevan",
            "body" : {
                "first_name" : "Stevan",
                "last_name"  : "Little",
                "age"        : 37
            },
            "version" : "fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2",
            "links"   : [
                { "rel" : "create", "href" : "/",  "method" : "POST"   },
                { "rel" : "delete", "href" : "/1", "method" : "DELETE" },
                { "rel" : "edit",   "href" : "/1", "method" : "PUT"    },
                { "rel" : "list",   "href" : "/",  "method" : "GET"    },
                { "rel" : "read",   "href" : "/1", "method" : "GET"    }
            ]
        });

        resource.associate_schema( person, repo );

        ok(resource.has_associated_schema(), '... we have an associated schema');

        try {
            resource.set({ age : 38 });
            ok(true, "... set the attributes successfully");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }

        equal(resource.get('age'), 38, '... the change happened');

        try {
            resource.set({ first_name : "Scott", age : 35 });
            ok(true, "... set the attributes successfully");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }

        equal(resource.get('first_name'), 'Scott', '... the change happened');
        equal(resource.get('age'), 35, '... the change happened');

        try {
            resource.set({ first_name : 100 });
            ok(false, "... set the attributes should fail");
        } catch (e) {
            ok(true, "... correctly failed to set the attributes");
            equal(e.reason, '100 is not a string', '... got the right error message');
        }

        equal(resource.get('age'), 35, '... the change did not happen');

        try {
            resource.set({ furst_name : "Who" });
            ok(false, "... set the attributes should fail");
        } catch (e) {
            ok(true, "... correctly failed to set the attributes");
            equal(e.reason, 'The property (furst_name) is not a valid property for this resource', '... got the right error message');
        }

        ok(resource.get("furst_name") == undefined, "... the property was not set");

        try {
            resource.set({ nickname : "Scottie" });
            ok(true, "... set the attributes successfully");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }

        equal(resource.get('nickname'), 'Scottie', '... the change happened');

        try {
            resource.set({ nickname : ["Scottie", "Scotto"] });
            ok(false, "... set the attributes should fail");
        } catch (e) {
            ok(true, "... correctly failed to set the attributes");
            equal(e.reason, 'Scottie,Scotto is not a string', '... got the right error message');
        }

        equal(resource.get('nickname'), 'Scottie', '... the change did not happen');
    }
);