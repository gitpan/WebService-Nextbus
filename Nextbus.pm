package WebService::Nextbus;
@ISA = qw(LWP::UserAgent);
use 5.006;
use strict;
use warnings;
use WebService::Nextbus::Agency;
use LWP::UserAgent;

our $VERSION = '0.10';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		_domain => 'www.nextbus.com',
		_site => {
			_base => 'wireless/',
			_region => 'miniRegion.shtml',
			_agency => 'miniAgency.shtml',
			_route => 'miniRoute.shtml',
			_dir => 'miniDirection.shtml',
			_stop => 'miniStop.shtml',
			_to => 'miniToStop.shtml',
			_predict => 'miniPrediction.shtml',
		},
		_keys => {
			region => 're',
			agency => 'a',
			route => 'r',
			dir => 'd',
			stop => 's',
			to => 'ts',
		},
		_ua => new LWP::UserAgent,
		_agencies => {},
	};
	bless ($self, $class);
}

sub _parseLinks {
	my ($content, $getKey) = @_;
	my $linkRegExp1 = '(<a href=[^>]+>[^<]*<\/a>)';
	my $linkRegExp2 = '^<a href=["\']([^"\']*)["\'][^>]*>([^<]*)<\/a>';
	my $keyRegExp = "$getKey=([^&]*)";

	my $links = undef;
	my @rawLinks = ($content =~ /$linkRegExp1/gi);
	foreach my $link (@rawLinks) {
		my ($url, $name) = ($link =~ /$linkRegExp2/i);
		next unless my ($code) = ($url =~/$keyRegExp/);
		$links->{$name} = $code;
	}
	return $links;
}

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

sub getStops {
	my $self = shift;
	my ($agency, $route, $dir) = @_;

	my $getKeys = '?' . $self->keys->{agency} . '=' . $agency . 
		'&' . $self->keys->{route} . '=' . $route .
		'&' . $self->keys->{dir} . '=' . $dir;
	my $url = $self->baseURL . $self->dir . $getKeys;

	my $response = $self->ua->get($url);
	if ($response->is_success) {
		my $content = $response->content;
		my $links = _parseLinks($content, $self->keys->{stop});
	}
}

sub getDirs {
	my $self = shift;
	my ($agency, $route) = @_;

	my $getKeys = '?' . $self->keys->{agency} . '=' . $agency . 
		'&' . $self->keys->{route} . '=' . $route;
	my $url = $self->baseURL . $self->dir . $getKeys;

	my $response = $self->ua->get($url);
	if ($response->is_success) {
		my $content = $response->content;
		my $links = _parseLinks($content, $self->keys->{dir});
	}
}

sub getRoutes {
	my $self = shift;
	my ($agency) = @_;

	my $getKeys = '?' . $self->keys->{agency} . '=' . $agency;
	my $url = $self->baseURL . $self->route . $getKeys;

	my $response = $self->ua->get($url);
	if ($response->is_success) {
		my $content = $response->content;
		my $links = _parseLinks($content, $self->keys->{route});
	}
}

sub getAgencies {
	my $self = shift;
	my ($region) = @_;

	my $getKeys = '?' . $self->keys->{region} . '=' . $region;
	my $url = $self->baseURL . $self->agency . $getKeys;

	my $response = $self->ua->get($url);
	if ($response->is_success) {
		my $content = $response->content;
		my $links = _parseLinks($content, $self->keys->{agency});
	}
}

sub getRegions {
	my $self = shift;
	my $url = $self->baseURL . $self->region;

	my $response = $self->ua->get($url);
	if ($response->is_success) {
		my $content = $response->content;
		my $links = _parseLinks($content, $self->keys->{region});
	}
}

sub setupAgency {
	my $self = shift;
	my ($nameCode) = @_;

	my $a = new WebService::Nextbus::Agency;
	$a->nameCode($nameCode);

	$self->agencies->{$nameCode} = $a;
}

sub baseURL {
	my $self = shift;
	return 'http://' . $self->domain . '/' . $self->base;
}

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

sub tree {
      my $self = shift;
      if (@_) { %{$self->{_tree}} = %{$_[0]} }
      return \%{$self->{_tree}};
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

sub base {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_base}} = shift }
	return $self->{_site}->{_base};
}

sub region {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_region}} = shift }
	return $self->{_site}->{_region};
}

sub agency {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_agency}} = shift }
	return $self->{_site}->{_agency};
}

sub route {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_route}} = shift }
	return $self->{_site}->{_route};
}

sub dir {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_dir}} = shift }
	return $self->{_site}->{_dir};
}

sub stop {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_stop}} = shift }
	return $self->{_site}->{_stop};
}

sub to {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_to}} = shift }
	return $self->{_site}->{_to};
}

sub predict {
	my $self = shift;
	if (@_) { ${$self->{_site}->{_predict}} = shift }
	return $self->{_site}->{_predict};
}

1
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WebService::Nextbus - Perl extension for blah blah blah

=head1 SYNOPSIS

  use WebService::Nextbus;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for WebService::Nextbus, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 SEE ALSO

L<perl>.

=cut
