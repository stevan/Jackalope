
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
                "height" : { "units" : "inches", "value" : "68" },
                "computers" : [
                    "iPad", 'Macbook', 'NeXT Slab'
                ],
                "books" : [
                    { "title" : "REST in Practice" },
                    { "title" : "MongoDB" }
                ]
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

        var update_age_months_event = 0;
        r.bind('update:age.months', function (self, value) {
            ok(true, '... age.months has been changed correctly');
            equal(value, 5, '... age.months has been passed to the event correctly');
            ok(self === r, '... passed in our self');
            update_age_months_event++;
        });

        r.set({ 'age.months' : 5 });
        equal(r.get('age.months'), 5, '... got the value for age.months');
        equal(update_age_months_event, 1, '... our event fired');

        r.set({ 'computers.1' : 'MacBook' });
        equal(r.get('computers.1'), "MacBook", '... got the updated value for computer.1');

        r.set({ 'computers.3' : 'Android' });
        equal(r.get('computers.3'), "Android", '... got the updated value for computer.3');

        equal(r.get('books.0.title'), "REST in Practice", '... got the value for books.0.title');

        r.set({ 'books.1.title' : 'MongoDB : The definitive guide' });
        equal(r.get('books.1.title'), "MongoDB : The definitive guide", '... got the updated value for books.1.title');

    }
);