package EPrints::Plugin::Event::PIRUS;

our $VERSION = v1.1.0;

@ISA = qw( EPrints::Plugin::Event );

use strict;

# @jesusbagpuss
# Counter v5 - send data about abstract page views (invesitgations) as well as downloads

# borrowed from EPrints 3.3's EPrints::OpenArchives::archive_id
sub _archive_id
{
	my( $repo, $any ) = @_;

	my $v1 = $repo->config( "oai", "archive_id" );
	my $v2 = $repo->config( "oai", "v2", "archive_id" );

	$v1 ||= $repo->config( "host" );
	$v2 ||= $v1;

	return $any ? ($v1, $v2) : $v2;
}


sub replay
{
	my( $self, $accessid ) = @_;

	my $repo = $self->{session};

	local $SIG{__DIE__};
	eval { $repo->dataset( "access" )->search(filters => [
				{ meta_fields => [qw( accessid )], value => "$accessid..", },
			],
			limit => 1000, # lets not go crazy ...
	)->map(sub {
		(undef, undef, my $access) = @_;

		my $r = $self->log( $access );
		die "failed\n" if !$r->is_success;
		$accessid = $access->id;
	}) };
	if( $@ eq "failed\n" )
	{
		$repo->log( "Attempt to re-send PIRUS trackback failed, trying again in 24 hours time" );

		my $event = $self->{event};
		$event->set_value( "params", [$accessid] );
		$event->set_value( "start_time", EPrints::Time::iso_datetime( time + 86400 ) );
		#return EPrints::Const::HTTP_RESET_CONTENT;
		return 0;
	}
	elsif( $@ )
	{
		die $@;
	}

	return;
}

sub log
{
	my( $self, $access, $request_url ) = @_;

	my $repo = $self->{session};

	my $url = URI->new(
		$repo->config( "pirus", "tracker" )
	);

	my $url_tim = $access->value( "datestamp" );
	$url_tim =~ s/^(\S+) (\S+)$/$1T$2Z/;

	my $artnum = EPrints::OpenArchives::to_oai_identifier(
		_archive_id( $repo ),
		$access->value( "referent_id" ),
	);

	my %qf_params = (
		url_ver => "Z39.88-2004",
		url_tim => $url_tim,
		req_id => "urn:ip:".$access->value( "requester_id" ),
		req_dat => $access->value( "requester_user_agent" ),
		'rft.artnum' => $artnum,
		rfr_id => $repo->config( "host" ) ? $repo->config( "host" ) : $repo->config( "securehost" ),
		svc_dat => $request_url,
	);
	
	if( $access->is_set( "referring_entity_id" ) )
	{
		$qf_params{rfr_dat} = $access->value( "referring_entity_id" );
	}

	# Counter v5 is interested in summary page views as well as downloads.
	if( $access->is_set( "service_type_id" ) )
	{
		$qf_params{rft_dat} = $access->value( "service_type_id" ) eq "?fulltext=yes" ? "Request" : "Investigation";
	}
	
	$url->query_form( %qf_params );

	my $ua = $repo->config( "pirus", "ua" );

	return $ua->head( $url );
}

1;
