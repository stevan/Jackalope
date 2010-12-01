#!perl

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../lib";

use Jackalope;
use Jackalope::Script::GenerateSpec;

Jackalope::Script::GenerateSpec->new_with_options->run;