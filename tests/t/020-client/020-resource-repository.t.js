test(
    "Resource Repository test",
    function() {

        var repo = new Jackalope.Schema.Repository ({
            spec      : new Jackalope.Schema.Spec({ spec_url : "spec/spec.json" }),
            validator : new Jackalope.Schema.Validator ()
        });
        ok(repo instanceof Jackalope.Schema.Repository, "... we are an instance of Jackalope.Schema.Repository");

        try {
            repo.register_schema(
                {
                    "id"         : 'simple/person',
                    "title"      : 'This is a simple person schema',
                    "extends"    : { '$ref' : 'jackalope/rest/service/crud' },
                    "properties" : {
                        "first_name" : { "type" : 'string' },
                        "last_name"  : { "type" : 'string' },
                        "age"        : { "type" : 'integer', "greater_than" : 0 },
                    }
                }
            );
            ok(true, "... successfully registered the schema");
        } catch (e) {
            ok(false, "... failed to register the schema because " + e);
        }

        var person = repo.get_compiled_schema_by_uri("simple/person");

        var resource_repo = new Jackalope.Client.Resource.Repository({
            base_url          : '/-',
            schema            : person,
            schema_repository : repo
        });

        var success = function () { return 'SUCCESS' };
        var failure = function () { return 'FAILURE' };

        var current_ajax_opts;
        resource_repo._call_ajax = function ( opts ) {
            // I can't really check these easily
            delete opts['success'];
            delete opts['error'];
            current_ajax_opts = opts;
        };

        resource_repo.list( {}, success, failure );
        deepEqual(
            current_ajax_opts,
            {
                'url'     : "/-/",
                'type'    : "GET",
                'data'    : {}
            },
            '... got the set of opts we expected for list'
        );

        resource_repo.create( { first_name : "Stevan", last_name : "Little", age : 38 }, success, failure );
        deepEqual(
            current_ajax_opts,
            {
                'url'     : "/-/",
                'type'    : "POST",
                'data'    : '{"first_name":"Stevan","last_name":"Little","age":38}'
            },
            '... got the set of opts we expected for create'
        );

        resource_repo.read( 10, success, failure );
        deepEqual(
            current_ajax_opts,
            {
                'url'     : "/-/10",
                'type'    : "GET"
            },
            '... got the set of opts we expected for read'
        );

        var resource = new Jackalope.Client.Resource ({
            "id"   : "10",
            "body" : {
                "first_name" : "Stevan",
                "last_name"  : "Little",
                "age"        : 37
            },
            "version" : "fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2",
            "links"   : [
                { "rel" : "create", "href" : "/",  "method" : "POST"   },
                { "rel" : "delete", "href" : "/1", "method" : "DELETE" },
                { "rel" : "edit",   "href" : "/1", "method" : "PUT"    },
                { "rel" : "list",   "href" : "/",  "method" : "GET"    },
                { "rel" : "read",   "href" : "/1", "method" : "GET"    }
            ]
        });

        resource_repo.edit( resource, success, failure );
        deepEqual(
            current_ajax_opts,
            {
                'url'     : "/-/10",
                'type'    : "PUT",
                'data'    : JSON.stringify({
                    id      : resource.id,
                    version : resource.version,
                    body    : resource.body
                })
            },
            '... got the set of opts we expected for update'
        );

        resource_repo.destroy( resource, success, failure );
        deepEqual(
            current_ajax_opts,
            {
                'url'     : "/-/10",
                'type'    : "DELETE",
                'headers' : { 'If-Matches' : 'fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2' }
            },
            '... got the set of opts we expected for update'
        );
    }
);