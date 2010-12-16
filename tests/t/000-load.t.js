
test(
    "Basic test",
    function() {
        expect(2);

        var jackalope = new Jackalope ();
        ok(jackalope instanceof Jackalope, '... we are an instance of Jackalope');

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, '... we are an instance of Jackalope.Schema.Repository');
    }

);
