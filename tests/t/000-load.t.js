
test(
    "Basic test",
    function() {

        var jackalope = new Jackalope ();
        ok(jackalope instanceof Jackalope, '... we are an instance of Jackalope');

        var repo = new Jackalope.Schema.Repository ();
        ok(repo instanceof Jackalope.Schema.Repository, '... we are an instance of Jackalope.Schema.Repository');

        var validator = new Jackalope.Schema.Validator ();
        ok(validator instanceof Jackalope.Schema.Validator, '... we are an instance of Jackalope.Schema.Validator');

        var validator_core = new Jackalope.Schema.Validator.Core ();
        ok(validator_core instanceof Jackalope.Schema.Validator.Core, '... we are an instance of Jackalope.Schema.Validator.Core');
    }

);
