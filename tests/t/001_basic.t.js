
test(
    "Basic test",
    function() {

        var jackalope = new Jackalope ();
        ok(jackalope instanceof Jackalope, '... we are an instance of Jackalope');

        var validator = new Jackalope.Schema.Validator ();
        ok(validator instanceof Jackalope.Schema.Validator, '... we are an instance of Jackalope.Schema.Validator');

        validation_pass( validator.validate( { "type" : "any" }, 1 ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, 1.5 ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, null ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, true ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, "Hello" ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, [] ), '... validation passed for any');
        validation_pass( validator.validate( { "type" : "any" }, {} ), '... validation passed for any');

        validation_fail( validator.validate( { "type" : "null" }, 1 ), '... validation failed for null');
        validation_fail( validator.validate( { "type" : "null" }, 1.5 ), '... validation failed for null');
        validation_pass( validator.validate( { "type" : "null" }, null ), '... validation passed for null');
        validation_fail( validator.validate( { "type" : "null" }, true ), '... validation failed for null');
        validation_fail( validator.validate( { "type" : "null" }, "Hello" ), '... validation failed for null');
        validation_fail( validator.validate( { "type" : "null" }, [] ), '... validation failed for null');
        validation_fail( validator.validate( { "type" : "null" }, {} ), '... validation failed for null');

        validation_fail( validator.validate( { "type" : "boolean" }, 1 ), '... validation failed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, 1.5 ), '... validation failed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, null ), '... validation failed for boolean');
        validation_pass( validator.validate( { "type" : "boolean" }, true ), '... validation passed for boolean');
        validation_pass( validator.validate( { "type" : "boolean" }, false ), '... validation passed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, "Hello" ), '... validation failed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, [] ), '... validation failed for boolean');
        validation_fail( validator.validate( { "type" : "boolean" }, {} ), '... validation failed for boolean');

        validation_pass( validator.validate( { "type" : "number" }, 1 ), '... validation passed for number');
        validation_pass( validator.validate( { "type" : "number" }, 1.5 ), '... validation passed for number');
        validation_fail( validator.validate( { "type" : "number" }, null ), '... validation failed for number');
        validation_fail( validator.validate( { "type" : "number" }, false ), '... validation failed for number');
        validation_fail( validator.validate( { "type" : "number" }, "Hello" ), '... validation failed for number');
        validation_fail( validator.validate( { "type" : "number" }, [] ), '... validation failed for number');
        validation_fail( validator.validate( { "type" : "number" }, {} ), '... validation failed for number');

        validation_pass( validator.validate( { "type" : "number", "less_than" : 5 }, 1 ), '... validation passed for number with less than');
        validation_fail( validator.validate( { "type" : "number", "less_than" : 5 }, 5 ), '... validation failed for number with less than');
        validation_fail( validator.validate( { "type" : "number", "less_than" : 5 }, 6 ), '... validation failed for number with less than');

        validation_pass( validator.validate( { "type" : "number", "less_than_or_equal_to" : 5 }, 1 ), '... validation passed for number with less than or equal to');
        validation_pass( validator.validate( { "type" : "number", "less_than_or_equal_to" : 5 }, 5 ), '... validation passed for number with less than or equal to');
        validation_fail( validator.validate( { "type" : "number", "less_than_or_equal_to" : 5 }, 6 ), '... validation failed for number with less than or equal to');

        validation_pass( validator.validate( { "type" : "number", "greater_than" : 5 }, 6 ), '... validation passed for number with greater than');
        validation_fail( validator.validate( { "type" : "number", "greater_than" : 5 }, 5 ), '... validation failed for number with greater than');
        validation_fail( validator.validate( { "type" : "number", "greater_than" : 5 }, 1 ), '... validation failed for number with greater than');

        validation_pass( validator.validate( { "type" : "number", "greater_than_or_equal_to" : 5 }, 6 ), '... validation passed for number with greater than or equal to');
        validation_pass( validator.validate( { "type" : "number", "greater_than_or_equal_to" : 5 }, 5 ), '... validation passed for number with greater than or equal to');
        validation_fail( validator.validate( { "type" : "number", "greater_than_or_equal_to" : 5 }, 1 ), '... validation failed for number with greater than or equal to');

        validation_pass( validator.validate( { "type" : "number", "enum" : [ 5, 1 ] }, 1 ), '... validation passed for number in enum');
        validation_pass( validator.validate( { "type" : "number", "enum" : [ 5, 1 ] }, 5 ), '... validation passed for number in enum');
        validation_fail( validator.validate( { "type" : "number", "enum" : [ 5, 1 ] }, 6 ), '... validation failed for number in enum');
    }

);
