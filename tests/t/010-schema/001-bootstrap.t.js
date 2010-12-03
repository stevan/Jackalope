
test(
    "Bootstrap test",
    function() {

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec_url  : "../spec/spec.json",
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, '... we are an instance of Jackalope.Schema.Repository');

        var types = ['any', 'null', 'boolean', 'number', 'integer', 'string', 'array', 'object'];

        for (var i = 0; i < types.length; i++) {
            tester.validation_pass(
                repo.validate(
                    { "$ref" : "schema/types/schema" },
                    repo.compiled_schemas["schema/types/" + types[i]]
                ),
                "... validate the " + types[i] + " schema with the schema type"
            );
        }

        tester.validation_pass(
            repo.validate(
                { "$ref" : "schema/types/schema" },
                repo.compiled_schemas["schema/types/schema"]
            ),
            "... validate the schema schema with the schema type (bootstrap)"
        );

    }

);
