
test(
    "Fixture tests for boolean",
    function () {

        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "../fixtures/",
            "validator"   : new Jackalope.Schema.Validator ()
        });

        fixtures.run_fixtures_for_type('boolean');
    }
);