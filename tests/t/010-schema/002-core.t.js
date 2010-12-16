
test(
    "Core test",
    function() {
        expect(25);

        var tester   = new Test.Jackalope ();
        var repo     = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "fixtures/",
            "repo"        : repo
        });

        var types = ['ref', 'hyperlink', 'xlink'];

        for (var i = 0; i < types.length; i++) {
            tester.validation_pass(
                repo.validate(
                    { "$ref" : "schema/types/object" },
                    repo.get_compiled_schema_by_uri("schema/core/" + types[i])
                ),
                "... validate the " + types[i] + " schema with the object type"
            );
            fixtures.run_fixtures_for_type( types[i] );
        }

        tester.validation_pass(
            repo.validate(
                { "$ref" : "schema/core/spec" },
                repo.spec.get_spec()
            ),
            "... validate the spec schema with the spec"
        );

    }

);
