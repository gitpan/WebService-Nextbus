package WebService::Nextbus;
use 5.006;
use strict;
use warnings;
use integer;
use WebService::Nextbus::Agency;
use LWP::UserAgent;

our $VERSION = '0.11';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		# URL-building internals (basically #DEFINEs)
		_domain => 'www.nextbus.com',
		_site => {
			base => 'wireless/',
			region => 'miniRegion.shtml',
			agency => 'miniAgency.shtml',
			route => 'miniRoute.shtml',
			dir => 'miniDirection.shtml',
			stop => 'miniStop.shtml',
			to => 'miniToStop.shtml',
			predict => 'miniPrediction.shtml',
		},
		_keys => {
			region => 're',
			agency => 'a',
			route => 'r',
			dir => 'd',
			stop => 's',
			to => 'ts',
		},

		# The real workhorses
		_ua => new LWP::UserAgent,
		_agencies => {},
	};
	bless ($self, $class);
}

# To propagate a new Agency with screen scraped data
sub buildAgency {
	my $self = shift;
	my ($nameCode) = @_;
	my $a = $self->setupAgency($nameCode);

	my $routes = $self->getRoutes($nameCode);
	foreach my $routeCode (values(%$routes)) {
		my $dirs = $self->getDirs($nameCode, $routeCode);
		foreach my $dirCode (values(%$dirs)) {
			my $stops = $self->getStops($nameCode, $routeCode, $dirCode);
			$a->stops($routeCode, $dirCode, $stops);
		}
	}
}

# Private internal functions for getting and processing data from website
my $_parseLinks = sub {
	my $self = shift;
	my ($content, $getKey) = @_;

	my $linkRegExp1 = '(<a href=[^>]+>.*?<\/a>)';
	my $linkRegExp2 = '^<a href=["\']([^"\']*)["\'][^>]*>' .
		'(<[^>]+>)*' . '([^<]*)' . '(<\/[^>]+>)*<\/a>$';
	my $keyRegExp = "$getKey=([^&]*)";

	my @rawLinks = ($content =~ /$linkRegExp1/gi);
	my $links = undef;
	foreach my $link (@rawLinks) {
		my ($url, undef, $name) = ($link =~ /$linkRegExp2/i);
		next unless my ($code) = ($url =~/$keyRegExp/);
		$links->{$name} = $code;
	}
	return $links;
};

my $_getKeys = sub {
	my $self = shift;
	my ($url, $getKey) = @_;

	my $response = $self->ua->get($url);
	if ($response->is_success) {
		my $links = $self->$_parseLinks($response->content, $getKey);
	}
};

# Screen scraping functions for getting data from website
sub getStops {
	my $self = shift;
	my ($agency, $route, $dir) = @_;
	my $getKeys = '?' . $self->keys->{agency} . '=' . $agency . 
		'&' . $self->keys->{route} . '=' . $route .
		'&' . $self->keys->{dir} . '=' . $dir;
	my $url = $self->baseURL . $self->site->{stop} . $getKeys;
	$self->$_getKeys($url, $self->keys->{stop});
}

sub getDirs {
	my $self = shift;
	my ($agency, $route) = @_;
	my $getKeys = '?' . $self->keys->{agency} . '=' . $agency . 
		'&' . $self->keys->{route} . '=' . $route;
	my $url = $self->baseURL . $self->site->{dir} . $getKeys;
	$self->$_getKeys($url, $self->keys->{dir});
}

sub getRoutes {
	my $self = shift;
	my ($agency) = @_;
	my $getKeys = '?' . $self->keys->{agency} . '=' . $agency;
	my $url = $self->baseURL . $self->site->{route} . $getKeys;
	$self->$_getKeys($url, $self->keys->{route});
}

sub getAgencies {
	my $self = shift;
	my ($region) = @_;
	my $getKeys = '?' . $self->keys->{region} . '=' . $region;
	my $url = $self->baseURL . $self->site->{agency} . $getKeys;
	$self->$_getKeys($url, $self->keys->{agency});
}

sub getRegions {
	my $self = shift;
	my $url = $self->baseURL . $self->site->{region};
	$self->$_getKeys($url, $self->keys->{region});
}

# Initialize an Agency
sub setupAgency {
	my $self = shift;
	my ($nameCode) = @_;
	my $a = new WebService::Nextbus::Agency;
	$a->nameCode($nameCode);
	$self->agencies->{$nameCode} = $a;
}

# Doesn't really do much, but if website changes, will help us to adapt
sub baseURL {
	my $self = shift;
	return 'http://' . $self->domain . '/' . $self->site->{base};
}

# Standard methods for checking and resetting internals
sub agencies {
	my $self = shift;
	if (@_) { %{$self->{_agencies}} = %{$_[0]} }
	return \%{$self->{_agencies}};
}

sub ua {
	my $self = shift;
	if (@_) { $self->{_ua} = shift }
	return $self->{_ua};
}

sub domain {
      my $self = shift;
      if (@_) { $self->{_domain} = shift }
      return $self->{_domain};
}

sub site {
      my $self = shift;
      if (@_) { %{$self->{_site}} = %{$_[0]} }
      return \%{$self->{_site}};
}

sub keys {
      my $self = shift;
      if (@_) { %{$self->{_keys}} = %{$_[0]} }
      return \%{$self->{_keys}};
}

1
__END__

=head1 NAME
      
WebService::Nextbus - A screen scraper useful for propagating the data structure
of WebService::Nextbus::Agency.
      
            
=head1 SYNOPSIS
      
  use WebService::Nextbus;
  $nb = new WebService::Nextbus;
  $nb->buildAgency('sf-muni'); # Scraping the webpages repeatedly can take time
  @stops = $nb->agencies->{'sf-muni'}->str2stopCodes('N', 'judah', 'Chu Dub');

C<@stops> can now be used as valid GET arguments on the nextbus webpage.
      
 
=head1 DESCRIPTION

WebService::Nextbus can determine the relevant GET arguments for queries to the 
Nextbus website (www.nextbus.com) by screen scraping.  
WebService::Nextbus::Agency implements a basic data structure for storing and
retrieving the information gleaned by this screen scraping.

Once the proper GET code has been retrieved, a web useragent can use the
argument to build a URL for the desired information.  This useragent function
will probably eventually be incorporated into WebService::Nextbus.

The screen scraping is done without any additional required HTML parser module.
I did this to improve interoperability, but the parsing is therefore
necessarily crude and perhaps not as fast as it could be (it uses RegExps 
rather than a state machine).  This shouldn't be a major issue, however; 
although running the initial screen scraping, with buildAgency for example, can
be slow, you should be able to store the results (using Storable for example)
and then retrieve them quickly.  This should work well since the data don't
change all that frequently.

For example:

  # As above (use emery agency for example because it's smaller, faster)
  use WebService::Nextbus;
  $nb = new WebService::Nextbus;
  $nb->buildAgency('emery'); # Scraping the webpages repeatedly can take time

  # Now store the resulting agency, retrieve it, and dump its contents
  use Storable;
  store($nb->agencies->{'emery'}, 'emery.store');
  $agency = retrieve('emery.store');
  print $agency->routesAsString;

  # Or store just the routes tree, retrieve it, and dump its contents
  store($nb->agencies->{'emery'}->routes, 'emery_routes.store');
  $agency = new WebService::Nextbus::Agency;
  $agency->routes(retrieve('emery_routes.store'));
  print $agency->routesAsString;


=head2 EXPORT

None by default; OO interface.


=head1 REQUIRES

Requires the L<LWP::UserAgent> module and the L<WebService::Nextbus::Agency> 
package.
Tests require the Test::More module.


=head1 AUTHOR

Peter H. Li<lt>phli@cpan.org<gt>


=head1 COPYRIGHT

Licensed by Creative Commons
http://creativecommons.org/licenses/by-nc-sa/2.0/


=head1 SEE ALSO

L<WebService::Nextbus::Agency>, L<LWP::UserAgent>, L<perl>.

=cut
