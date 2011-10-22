use Test::More;

BEGIN { use_ok('Jackalope'); use_ok('JSON::XS'); }

isa_ok(Jackalope::Util::true, 'JSON::XS::Boolean');
is(Jackalope::Util::true, JSON::XS::true, 'True value is true');
isnt(Jackalope::Util::true, JSON::XS::false, 'True value is not false');
is(Jackalope::Util::true, 1, 'One value coerces to boolean true');
isnt(Jackalope::Util::true, 0, 'Zero value is not true');

isa_ok(Jackalope::Util::false, 'JSON::XS::Boolean');
is(Jackalope::Util::false, JSON::XS::false, 'False value is false');
isnt(Jackalope::Util::false, JSON::XS::true, 'False value is not true');
is(Jackalope::Util::false, 0, 'Zero value coerces to boolean false');
isnt(Jackalope::Util::false, 1, 'Non-zero value is not false');

is(Jackalope::Util::is_bool(JSON::XS::true), JSON::XS::true, 'True value is boolean');
is(Jackalope::Util::is_bool(1), undef, 'One value is not a real boolean');
is(Jackalope::Util::is_bool(JSON::XS::false), JSON::XS::true, 'False value is boolean');
is(Jackalope::Util::is_bool(0), undef, 'Zero value is not a real boolean');
is(Jackalope::Util::is_bool(2), undef, 'Non-one/zero value is not boolean');

is_deeply(Jackalope::Util::encode_json({ foo => 'bar'}), '{"foo":"bar"}', 'Basic JSON encoding');
is_deeply(Jackalope::Util::encode_json({ foo => 'bar', baz => 'qux' },
    { space_before => 1, space_after => 1 }),
    '{"baz" : "qux", "foo" : "bar"}',
    'JSON encoding with params');

is_deeply(Jackalope::Util::decode_json('{"foo":"bar"}'), {'foo' => 'bar'}, 'Basic JSON decoding');
is_deeply(Jackalope::Util::decode_json('{"foo":"bar","baz":"qux",}',
    { relaxed => 1 }),
    {'foo' => 'bar', 'baz' => 'qux'},
    'JSON decoding with params');

isa_ok(Jackalope::Util::load_class('Jackalope'), 'Jackalope');
isa_ok(Jackalope::Util::load_class('Core', 'Jackalope::Schema::Validator'), 'Jackalope::Schema::Validator::Core');
isa_ok(Jackalope::Util::load_class('Jackalope::Schema::Validator::Core', 'Jackalope::Schema::Validator'), 'Jackalope::Schema::Validator::Core');
isa_ok(Jackalope::Util::load_class('+Jackalope::Schema::Validator::Core', "Foo::Bar"), 'Jackalope::Schema::Validator::Core');
isa_ok(Jackalope::Util::load_class('Jackalope::Schema::Validator::Core'), 'Jackalope::Schema::Validator::Core');

done_testing();