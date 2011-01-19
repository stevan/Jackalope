
test(
    "Core test",
    function() {
        expect(32);

        var tester   = new Test.Jackalope ();
        var repo     = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "fixtures/",
            "repo"        : repo
        });

        var types = ['ref', 'linkrel', 'hyperlink'];

        for (var i = 0; i < types.length; i++) {
            tester.validation_pass(
                repo.validate(
                    { "$ref" : "jackalope/core/types/object" },
                    repo.get_compiled_schema_by_uri("jackalope/core/" + types[i])
                ),
                "... validate the " + types[i] + " schema with the object type"
            );
            fixtures.run_fixtures_for_type( types[i] );
        }

        tester.validation_pass(
            repo.validate(
                { "$ref" : "jackalope/core/spec" },
                repo.spec.get_spec()
            ),
            "... validate the spec schema with the spec"
        );

    }

);
