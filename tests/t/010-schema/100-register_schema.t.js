
test(
    "Register Schema test",
    function() {
        expect(5);

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, '... we are an instance of Jackalope.Schema.Repository');

        try {
            repo.register_schema(
                {
                    "id"          : "/my_schemas/product",
                    "description" : "Product",
                    "type"        : "object",
                    "properties"  : {
                        "id" : {
                              "type"        : "number",
                              "description" : "Product identifier"
                        },
                        "name" : {
                              "description" : "Name of the product",
                              "type"        : "string"
                        }
                    },
                    "links" : [
                        {
                            "rel"           : "self",
                            "method"        : "GET",
                            "href"          : "product/{id}/view",
                            "target_schema" : { "$ref" : "#" }
                        },
                        {
                            "rel"         : "edit",
                            "href"        : "product/{id}/update",
                            "method"      : "POST",
                            "data_schema" : { "$ref" : "#" }
                        }
                    ]
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        try {
            repo.register_schema(
                {
                    "id"          : "/my_schemas/product/list",
                    "description" : "Product List",
                    "type"        : "array",
                    "items"       : {
                        "$ref" : "/my_schemas/product"
                    },
                    "links" : [
                        {
                            "rel"           : "/my_schemas/link/product_listing",
                            "method"        : "GET",
                            "href"          : "product/list",
                            "target_schema" : { "$ref" : "#" }
                        },
                        {
                            "rel"         : "create",
                            "href"        : "product/create",
                            "method"      : "POST",
                            "data_schema" : { "$ref" : "/my_schemas/product" }
                        }
                    ]
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        tester.validation_pass(
            repo.validate(
                { "$ref" : "/my_schemas/product" },
                { "id" : 10, "name" : "Log" }
            ),
            '... validate against the registered product type'
        );

        tester.validation_pass(
            repo.validate(
                { "$ref" : "/my_schemas/product/list" },
                [
                    { "id" : 10, "name" : "Log" },
                    { "id" : 11, "name" : "Phone" }
                ]
            ),
            '... validate against the registered product type'
        );

    }

);
