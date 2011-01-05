
test(
    "Basic Resource test",
    function() {

        var resource = new Jackalope.Client.Resource ({
            "id"   : "stevan",
            "body" : {
                "first_name" : "Stevan",
                "last_name"  : "Little"
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

        equal(resource.id, "stevan", '... got the expected id');
        equal(resource.version, "fe982ce14ce2b2a1c097629adecdeb1522a1e0a2ca390673446c930ca5fd11d2", '... got the expected version');
        deepEqual(
            resource.links,
            [
                { "rel" : "create", "href" : "/",  "method" : "POST"   },
                { "rel" : "delete", "href" : "/1", "method" : "DELETE" },
                { "rel" : "edit",   "href" : "/1", "method" : "PUT"    },
                { "rel" : "list",   "href" : "/",  "method" : "GET"    },
                { "rel" : "read",   "href" : "/1", "method" : "GET"    }
            ],
            "... got the expected links"
        );

        equal(resource.get('first_name'), 'Stevan', '... got the first name correctly');
        equal(resource.get('last_name'), 'Little', '... got the last name correctly');

        var update_event                   = 0;
        var update_first_name_event        = 0;
        var update_first_name_second_event = 0;

        resource.bind('update', function (self, attrs) {
            ok(true, '... update event has been fired');
            ok(self === resource, '... passed in our self');
            update_event++;
        });

        resource.bind('update:first_name', function (self, value) {
            ok(true, '... first name has been changed correctly');
            equal(value, 'Steve', '... first name has been passed to the event correctly');
            ok(self === resource, '... passed in our self');
            update_first_name_event++;
        });

        resource.set({ 'first_name' : 'Steve' });
        equal(resource.get('first_name'), 'Steve', '... got the first name correctly');
        equal(update_event, 1, '... the update event fired once');
        equal(update_first_name_event, 1, '... the update:first_name event fired once');

        resource.bind('update:first_name', function (self, value) {
            ok(true, '... the second event fires as well');
            ok(self === resource, '... passed in our self');
            update_first_name_second_event++;
        });

        resource.set('first_name', 'Steve');
        equal(update_event, 2, '... the update event fired twice');
        equal(update_first_name_event, 2, '... the update:first_name event fired twice');
        equal(update_first_name_second_event, 1, '... the second update:first_name event fired once');

        resource.set({ 'last_name' : 'Little Jr.' });
        equal(resource.get('last_name'), 'Little Jr.', '... got the last name correctly (and only "update" event fired)');
        equal(update_event, 3, '... the update event fired three times');
        equal(update_first_name_event, 2, '... the update:first_name event (still) fired twice only');
        equal(update_first_name_second_event, 1, '... the second update:first_name event (still) fired once only');

        resource.set(
            {
                'first_name' : 'Stevan',
                'last_name'  : 'Little'
            },
            { silent : true }
        );
        equal(resource.get('first_name'), 'Stevan', '... got the first name correctly (and no events fired)');
        equal(resource.get('last_name'), 'Little', '... got the last name correctly (and no events fired)');
        equal(update_event, 3, '... the update event fired three times');
        equal(update_first_name_event, 2, '... the update:first_name event (still) fired twice only');
        equal(update_first_name_second_event, 1, '... the second update:first_name event (still) fired once only');
    }
);