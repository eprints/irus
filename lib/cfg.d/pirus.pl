=pod

=head1 PIRUS 'PUSH' implementation

Provide data for COUNTER-compliant usage statistics.

Copyright 2012 University of Southampton

Released to the public domain (or CC0 depending on your juristiction).

USE OF THIS EXTENSION IS ENTIRELY AT YOUR OWN RISK

=head2 Installation

Copy this file into your repository's cfg.d/ directory and restart Apache.

=head2 Implementation

This code will PING the configured tracker server whenever a full-text object
is requested from EPrints.

These pings can be aggregated together with data from other sources
(publishers, other repositories) to create a fuller picture of the usage of
individual articles.


The data transferred are:

	- eprint.eprintid - the eprint's internal identifier
	- eprint.datestamp - the datetime the access started
	- IP address - the user's IP address
	- User Agent - the user's browser user agent
	- eprint.date - the publication date

And either (if id_number is defined):

	- eprint.id_number - the DOI

Or:

	- eprint.creators_name - first named author
	- eprint.title - eprint title
	- eprint.jtitle - publication title
	- eprint.issn - publication ISSN
	- eprint.volume - publication volume
	- eprint.issue - publication issue

=head2 Changes

1.05 Sebastien Francois <sf2@ecs.soton.ac.uk>

Conform to 2014 guidelines (see Event::PIRUS.pm)

1.02 Justin Bradley <jb4@ecs.soton.ac.uk>

Compatibility fixes for 3.2.

1.01 Tim Brody <tdb2@ecs.soton.ac.uk>

Fixed reference to 'jtitle' instead of 'publication'

1.00 Tim Brody <tdb2@ecs.soton.ac.uk>

Initial version

=cut

require LWP::UserAgent;
require LWP::ConnCache;

# modify the following URL to the PIRUS tracker location
$c->{pirus}->{tracker} = "https://irus.jisc.ac.uk/counter/";
# during testing (or on a test server), the following should be used:
#$c->{pirus}->{tracker} = "https://irus.jisc.ac.uk/counter/test/";

# you may want to revise the settings for the user agent e.g. increase or
# decrease the network timeout
$c->{pirus}->{ua} = LWP::UserAgent->new(
	from => $c->{adminemail},
	agent => $c->{version},
	timeout => 20,
	conn_cache => LWP::ConnCache->new,
);

$c->{plugins}->{"Event::PIRUS"}->{params}->{disable} = 0;

##############################################################################

$c->add_dataset_trigger( 'access', EPrints::Const::EP_TRIGGER_CREATED, sub {
	my( %args ) = @_;

	my $repo = $args{repository};
	my $access = $args{dataobj};

	my $plugin = $repo->plugin( "Event::PIRUS" );

	my $r = $plugin->log( $access, $repo->current_url( host => 1 ) );

	if( defined $r && !$r->is_success )
	{
		my $event = $repo->dataset( "event_queue" )->dataobj_class->create_unique( $repo, {
			eventqueueid => Digest::MD5::md5_hex( "Event::PIRUS::replay" ),
			pluginid => "Event::PIRUS",
			action => "replay",
		});
		if( defined $event )
		{
			$event->set_value( "params", [$access->id] );
			$event->commit;
		}
	}
});
