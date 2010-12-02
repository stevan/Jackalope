
test(
    "Fixture tests for null",
    function () {

        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "../test_fixtures/",
            "validator"   : new Jackalope.Schema.Validator ()
        });

        fixtures.run_fixtures_for_type('null');
    }
);