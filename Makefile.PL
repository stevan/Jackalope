use strict;
use warnings;
use inc::Module::Install;

name 'Jackalope';
all_from 'lib/Jackalope.pm';
license 'perl';

requires 'Moose'                      => 0;
requires 'MooseX::Getopt'             => 0;
requires 'MooseX::Types::Path::Class' => 0;
requires 'MooseX::Params::Validate'   => 0;
requires 'Bread::Board'               => 0;
requires 'JSON::XS'                   => 0;
requires 'Try::Tiny'                  => 0;
requires 'Class::Load'                => 0;
requires 'Clone'                      => 0;
requires 'List::AllUtils'             => 0;
requires 'Data::Visitor::Callback'    => 0;
requires 'Scalar::Util'               => 0;
requires 'Data::UUID'                 => 0;
requires 'Data::Peek'                 => 0;
requires 'Data::Dumper'               => 0;
requires 'Devel::PartialDump'         => 0;
requires 'Template'                   => 0;
requires 'FindBin'                    => 0;

build_requires 'Test::More'            => 0;
build_requires 'Test::Moose'           => 0;
build_requires 'Test::Fatal'           => 0;
build_requires 'Test::Builder'         => 0;

tests('t/*.t t/*/*.t');

WriteAll();