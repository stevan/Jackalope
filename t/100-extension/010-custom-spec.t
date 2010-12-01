#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Jackalope;

BEGIN {
    use_ok('Jackalope');
}

{
    package Dahut;
    use Moose;
    use Bread::Board;

    extends 'Jackalope';

    override 'typemapping' => sub {
        typemap 'Jackalope::Schema::Spec' => infer( class => 'Dahut::Schema::Spec' );
        super();
    };

    package Dahut::Schema::Spec;
    use Moose;
    extends 'Jackalope::Schema::Spec';
}

my $dahut = Dahut->new;
isa_ok($dahut, 'Dahut');
isa_ok($dahut, 'Jackalope');

is($dahut->name, 'Dahut', '... got the right name');

my $repo = $dahut->resolve( type => 'Jackalope::Schema::Repository' );
isa_ok($repo, 'Jackalope::Schema::Repository');

isa_ok($repo->spec, 'Dahut::Schema::Spec');

# now this typemap is explicit ..
my $spec = $dahut->resolve( type => 'Jackalope::Schema::Spec' );
isa_ok($spec, 'Dahut::Schema::Spec');
isa_ok($spec, 'Jackalope::Schema::Spec');

done_testing;