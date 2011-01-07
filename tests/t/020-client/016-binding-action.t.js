
test(
    "Action Binding test",
    function() {

        var object = {
            test_one : function () {
                ok(this === object, '... got the right context');
            }
        };

        var a = new Jackalope.Client.Binding.Action ({
            element       : $('<input type="button" />'),
            event_type    : 'click',
            target        : object,
            target_action : 'test_one'
        });

        a.element.click();

    }
);