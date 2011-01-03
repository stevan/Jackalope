
test(
    "Resource Deep Accessor test",
    function() {

        var r = new Jackalope.Client.Resource ({
            "id"   : "stevan",
            "body" : {
                "name" : {
                    "first"  : "Stevan",
                    "middle" : "Calvert",
                    "last"   : "Little"
                },
                "height" : { "units" : "inches", "value" : "68" }
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

        equal(r.get('name.first'), "Stevan", '... got the right value for name.first');

        r.set({ 'name.first' : 'Steve' });
        equal(r.get('name.first'), "Steve", '... got the updated value for name.first');

        r.set({ 'age.years' : 37 });
        equal(r.get('age.years'), 37, '... got the autovivified value for age.years');

        r.set({ 'age.months' : 4 });
        equal(r.get('age.months'), 4, '... got the autovivified value for age.months');
    }
);