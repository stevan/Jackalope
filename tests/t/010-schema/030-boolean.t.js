
test(
    "Fixture tests for boolean",
    function () {
        expect(10);

        var fixtures = new Test.Jackalope.Fixtures ({
            "fixture_dir" : "fixtures/",
            "repo"        : new Jackalope.Schema.Repository ({
                spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
                validator : new Jackalope.Schema.Validator ()
            })
        });

        fixtures.run_fixtures_for_type('boolean');
    }
);