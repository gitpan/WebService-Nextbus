use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 5 };
BEGIN { use_ok('WebService::Nextbus') };

my $nb = new WebService::Nextbus;
isa_ok($nb, 'WebService::Nextbus', 'new nextbus');

can_ok($nb, qw(buildAgency getStops getDirs getRoutes getAgencies getRegions setupAgency baseURL agencies ua domain site keys));

isa_ok($nb->ua, 'LWP::UserAgent', 'new lwpUserAgent');
isa_ok($nb->setupAgency(''), 'WebService::Nextbus::Agency', 'new agency');
