# PIRUS 'PUSH' implementation

Provide data for [COUNTER R5](https://www.projectcounter.org/code-of-practice-five-sections/abstract/) compliant usage statistics.

## Installation

This EPrints plugin should be available from the [EPrints Bazaar](https://bazaar.eprints.org/), 
and can be installed from within your repository.

To manually install it, you can use the GitHub repository and the [Gitaar](https://github.com/eprintsug/gitaar) tool.

### Testing / use on development servers

In the file `lib/cfg.d/pirus.pl` there is a URL for a test COUNTER server in the comments.

`#$c->{pirus}->{tracker} = "https://jusp.jisc.ac.uk/testcounter/";`

if you are testing the plugin, or have it installed on a test/development machine, you can add the configuration
above to a file in the archive specific configuration e.g.  `~/archives/ARCHIVEID/cfg/cfg.d/z_pirus.pl`.

## Implementation

This code will PING the configured tracker server whenever a full-text or item summary page is requested from EPrints.

These pings can be aggregated together with data from other sources
(publishers, other repositories) to create a fuller picture of the usage
of individual articles.

The data transferred are:

- `url_ver` - set to `Z39.88-2004` (OpenURL)
- `url_tim` - the datestamp of the 'access' dataobject
- `req_id` - requesting IP address
- `req_dat` - User-agent making request
- `rft.artnum` - the OpenArchives OAI identifier for the accessed item
- `rfr_id` - the hostname of the repository
- `svc_dat` - the URL requested
- `rfr_dat` - the HTTP referrer (when set)
- `rft_dat` - whether it was a full-text download, or a summary page access.


## Changes
 
* 1.1.0 John Salter <J.Salter@leeds.ac.uk>

Update to COUNTER R5:

Set `rft_dat` to `Request` (for fulltext downloads)

Set `rft_dat` to `Investigation` (for summary page views)


* 1.06 Justin Bradley <jb4@ecs.soton.ac.uk>

Perl syntax bug Fix.

* 1.05 Sebastien Francois <sf2@ecs.soton.ac.uk>

* 1.04 Tim Brody <tdb2@ecs.soton.ac.uk>

Set svc_format to mime_type (was commented out???)

Set svc_dat to the requested URL (works only for live)

* 1.03 ???

* 1.02 Justin Bradley <jb4@ecs.soton.ac.uk>

Compatibility fixes for 3.2.

* 1.01 Tim Brody <tdb2@ecs.soton.ac.uk>

Fixed reference to 'jtitle' instead of 'publication'

* 1.00 Tim Brody <tdb2@ecs.soton.ac.uk>

Initial version

## Reuse / licence information

Copyright 2012 University of Southampton

Released to the public domain (or CC0 depending on your juristiction).

Updated 2018 [John Salter](https://github.com/jesusbagpuss) on behalf of White Rose Libraries and IRUS-UK CAG.

With thanks to [Alan Stiles](https://github.com/Ainmhidh) (Open University) and [Paul Needham](https://orcid.org/0000-0001-9771-3469) (Cranfield University)

__USE OF THIS EXTENSION IS ENTIRELY AT YOUR OWN RISK__
