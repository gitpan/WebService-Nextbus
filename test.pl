use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 3 };
BEGIN { use_ok('WebService::Nextbus') };

my $nb = new WebService::Nextbus;
isa_ok($nb, 'WebService::Nextbus', 'new agency');

can_ok($nb, qw(site));
