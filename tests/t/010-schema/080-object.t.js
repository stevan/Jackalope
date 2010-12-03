
test(
    "Fixture tests for object",
    function () {

        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "../fixtures/",
            "validator"   : new Jackalope.Schema.Validator ()
        });

        fixtures.run_fixtures_for_type('object');
    }
);