
test(
    "Resource With Associated Schema and Deep Accessors test",
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
                        "name" : {
                            "type" : 'object',
                            "properties" : {
                                "first" : { "type" : "string" },
                                "middle" : { "type" : "string" },
                                "last" : { "type" : "string" }
                            }
                        },
                        "height" : {
                            "type" : 'object',
                            "properties" : {
                                "units" : { "type" : "string" },
                                "value" : { "type" : "number" }
                            }
                        }
                    },
                    "additional_properties" : {
                        "foo" : {
                            "type" : "object",
                            "properties" : {
                                "bar" : {
                                    "type" : "object",
                                    "additional_properties" : {
                                        "baz" : { "type" : "string" }
                                    }
                                }
                            }
                        },
                        "computers" : { "type" : "array", "items" : { "type" : "string" } }
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
                "name" : {
                    "first"  : "Stevan",
                    "middle" : "Calvert",
                    "last"   : "Little"
                },
                "height" : { "units" : "inches", "value" : 68 },
                "computers" : [
                    "iPad", 'Macbook', 'NeXT Slab'
                ]
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
            resource.set({ 'name.first' : 'Steve' });
            ok(true, "... set the attributes successfully");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }
        equal(resource.get('name.first'), "Steve", '... got the updated value for name.first');

        try {
            resource.set({ 'name.first' : 100 });
            ok(false, "... should have failed to set the attributes successfully");
        } catch (e) {
            ok(true, "... failed to set the attributes correctly");
            equal(e.message, 'The property (name.first) failed to validate', '... got the right error');
            equal(e.reason, 'property first didn\'t pass the schema for string', '... got the right error');
        }
        equal(resource.get('name.first'), "Steve", '... got the updated value for name');

        try {
            resource.set({ 'height.first' : 100 });
            ok(false, "... should have failed to set the attributes successfully");
        } catch (e) {
            ok(true, "... failed to set the attributes correctly");
            equal(e.reason, '[object Object] did not match all the expected properties', '... got the right error');
        }

        try {
            resource.set({ 'name.first.something' : 100 });
            ok(false, "... should have failed to set the attributes successfully");
        } catch (e) {
            ok(true, "... failed to set the attributes correctly");
            equal(e.reason, 'The property (name.first.something) is not a valid property', '... got the right error');
        }

        try {
            resource.set({ 'foo.bar.baz' : 'HELLO!' });
            ok(true, "... set the attributes successfully (with auto-vivification)");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }
        equal(resource.get('foo.bar.baz'), "HELLO!", '... got the updated value for foo.bar.baz');

        try {
            resource.set({ 'computers.1' : 'MacBook' });
            ok(true, "... set the array attributes successfully ");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }
        equal(resource.get('computers.1'), "MacBook", '... got the updated value for computer.1');

        try {
            resource.set({ 'computers.3' : 'Android' });
            ok(true, "... set the array attributes successfully (with auto-vivification)");
        } catch (e) {
            ok(false, "... failed to set the attributes successfully");
        }
        equal(resource.get('computers.3'), "Android", '... got the updated value for computer.3');

    }
);