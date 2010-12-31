
test(
    "Register Schema test",
    function() {
        expect(3);

        var tester = new Test.Jackalope ();

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, '... we are an instance of Jackalope.Schema.Repository');

        var schemas = [
            {
                id         : "/schemas/patient",
                type       : "object",
                properties : {
                    name : { type : "string" },
                }
            },
            {
                id         : "/schemas/doctor",
                type       : "object",
                properties : {
                    name : { type : "string" }
                },
                links : {
                    "doctor.open_slots" : {
                        rel          : "doctor.open_slots",
                        href         : "doctors/:id/slots/open",
                        method       : "GET",
                        uri_schema   : { id : { type : "number" } },
                        data_schema  : {
                            type       : "object",
                            properties : {
                                date : { type : "number" }
                            }
                        },
                        target_schema : {
                            type  : "array",
                            items : { "$ref" : "/schemas/slot" }
                        },
                    }
                }
            },
            {
                id         : "/schemas/slot",
                type       : "object",
                properties : {
                    date   : { type : "number" },
                    start  : { type : "number" },
                    end    : { type : "number" },
                    doctor : { "$ref" : "/schemas/doctor" },
                },
                links : {
                    "slot.book" : {
                        rel           : "slot.book",
                        href          : "slots/:id",
                        method        : "POST",
                        uri_schema    : { id : { type : "number" } },
                        data_schema   : { "$ref" : "/schemas/patient" },
                        target_schema : { "$ref" : "/schemas/appointment" }
                    }
                }
            },
            {
                id         : "/schemas/appointment",
                type       : "object",
                properties : {
                    slot    : { "$ref" : "/schemas/slot" },
                    patient : { "$ref" : "/schemas/patient" },
                },
                links : {
                    "appointment.read" : {
                        rel           : "appointment.read",
                        href          : "appointment/:id",
                        method        : "GET",
                        uri_schema    : { id : { type : "number" } },
                        target_schema : { "$ref" : "#" }
                    },
                    "appointment.cancel" : {
                        rel          : "appointment.cancel",
                        href         : "appointment/:id",
                        method       : "DELETE",
                        uri_schema   : { id : { type : "number" } },
                        data_schema  : {
                            type       : "object",
                            properties : {
                                reason : { type : "string" }
                            }
                        },
                    },
                }
            }
        ];

        var compiled;
        try {
            compiled = repo.register_schemas( schemas );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        equal(compiled.length, 4, '... got the right number of compiled schemas back');
    }

);
