#!perl

use strict;
use warnings;

use JSON::XS;
use Path::Class;
use Benchmark 'cmpthese';

my $canonical     = JSON::XS->new->canonical;
my $non_canonical = JSON::XS->new;

my $json = file( 'spec/spec.json' )->slurp;

my $data = $non_canonical->decode( $json );

cmpthese( 100_000, {
        'canonical' => sub {
            $canonical->encode( $data );
        },
        'non-canonical' => sub {
            $non_canonical->encode( $data );
        }
});
