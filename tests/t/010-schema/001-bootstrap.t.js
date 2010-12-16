
test(
    "Bootstrap test",
    function() {
        expect(11);

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, '... we are an instance of Jackalope.Schema.Repository');

        var types = repo.spec.valid_types();

        for (var i = 0; i < types.length; i++) {
            tester.validation_pass(
                repo.validate(
                    { "$ref" : "schema/types/schema" },
                    repo.get_compiled_schema_for_type( types[i] )
                ),
                "... validate the " + types[i] + " schema with the schema type"
            );
        }

        tester.validation_pass(
            repo.validate(
                { "$ref" : "schema/types/schema" },
                repo.get_compiled_schema_for_type("schema")
            ),
            "... validate the schema schema with the schema type (bootstrap)"
        );

    }

);
