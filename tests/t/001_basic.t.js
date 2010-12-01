
test(
    "Basic test",
    function() {

        var jackalope = new Jackalope ();
        ok(jackalope instanceof Jackalope, '... we are an instance of Jackalope');


        var validator = new Jackalope.Validator ();
        ok(validator instanceof Jackalope.Validator, '... we are an instance of Jackalope.Validator');

        validation_pass( validator.validate( { "type" : "any" }, 1 ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, null ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, true ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, "Hello" ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, [] ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, {} ), '... validation passed for any');

        validation_fail( validator.validate( { "type" : "null" }, 1 ), '... validation passed for null');
        validation_pass( validator.validate( { "type" : "null" }, null ), '... validation passed for null');
        validation_fail( validator.validate( { "type" : "null" }, true ), '... validation passed for null');
        validation_fail( validator.validate( { "type" : "null" }, "Hello" ), '... validation passed for null');
        validation_fail( validator.validate( { "type" : "null" }, [] ), '... validation passed for null');
        validation_fail( validator.validate( { "type" : "null" }, {} ), '... validation passed for null');

        validation_fail( validator.validate( { "type" : "boolean" }, 1 ), '... validation passed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, null ), '... validation passed for boolean');
        validation_pass( validator.validate( { "type" : "boolean" }, true ), '... validation passed for boolean');
        validation_pass( validator.validate( { "type" : "boolean" }, false ), '... validation passed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, "Hello" ), '... validation passed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, [] ), '... validation passed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, {} ), '... validation passed for boolean');

    }
);
