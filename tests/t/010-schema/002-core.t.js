
test(
    "Core test",
    function() {

        var tester   = new Test.Jackalope ();
        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "../fixtures/",
            "repo"        : new Jackalope.Schema.Repository ({
                spec      : new Jackalope.Schema.Spec({ spec_url : "../spec/spec.json" }),
                validator : new Jackalope.Schema.Validator ()
            })
        });

        var types = ['ref', 'hyperlink'];

        for (var i = 0; i < types.length; i++) {
            tester.validation_pass(
                fixtures.repo.validate(
                    { "$ref" : "schema/types/object" },
                    fixtures.repo.compiled_schemas["schema/core/" + types[i]]
                ),
                "... validate the " + types[i] + " schema with the object type"
            );
            fixtures.run_fixtures_for_type( types[i] );
        }

    }

);
