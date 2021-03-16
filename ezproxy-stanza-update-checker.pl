#!/usr/bin/perl

use Modern::Perl;
use LWP::Simple();
use Getopt::Long();
use XML::Simple qw(:strict);
use Date::Parse();
use File::Slurp();
use Date::Format();
use Term::ANSIColor;

# Configuration
my $date_format = "%d-%m-%Y";
my $rss_feed_address = "https://www.oclc.org/support/services/ezproxy/database-setup.en.rss";
my $most_recent_address = "https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/000_Database_stanzas_recent?sl=en";

# Get list from command line of configuration files to check
my @files;
Getopt::Long::GetOptions("file=s" => \@files);

# Default to standard config.txt file
$files[0] = "config.txt" if ( ! $files[0] );

# Read local config file(s) into memory
my @configfiles;
foreach my $filename ( @files ) {
	if ( -f $filename ) {
		my $content = File::Slurp::read_file($filename);
		push @configfiles, $content;
	}
	else {
		# ...or give up!
		die "File not found: $filename";
	}
}

# Download RSS feed for OCLC EZproxy stanza changes
my $rss = LWP::Simple::get($rss_feed_address);

# If the RSS file is available
if ( $rss ) {
	# Parse the stanza using a simple XML parser (yes - deprecated but excellent in this simple case)
	my $stanza_list = XML::Simple::XMLin($rss,
		'ForceArray' => 0,
		'KeyAttr' => []
		);

	# Header
	print color('bold blue');
	say $stanza_list->{channel}->{description};
	say "-" x length($stanza_list->{channel}->{description});
	print "\n\n" . color('reset');

	# Iterate through the <item></item> parts of the feed
	my @stanzas_seen;
	foreach my $item ( @{$stanza_list->{channel}->{item}} ) {
		# Get database title
		my $title = $item->{title};
		$title =~ s/^\s*//;
		$title =~ s/\s*$//;

		# Get the modified / updated date from the feed
		my $date;
		if ( $item->{pubDate} =~ m/(\w{3}, \d\d \w{3} \d{4})/ ) {
			# Convert to epoch time (if possible)
			$date = Date::Parse::str2time($1);
		}

		# If a <link> section is found
		# The link points back to the OCLC help page with the current stanza (our "foreign" key)
		if ( $item->{link} ) {
			my $link = $item->{link};

			# It the stanza was updated before in the current RSS feed then skip it
			next if grep $_  eq $link, @stanzas_seen;
			push @stanzas_seen, $link;

			# Check link against content of config files (one at a time)
			for ( my $c = 0; $c < scalar(@configfiles); $c++ ) {
				# REM config file number: $c
				# REM config file name: $files[$c]
				# REM config file contents: $configfiles[$c]
				
				# Match content of config file with the occurence of our "foreign" key (the link)
				if ( $configfiles[$c] =~ m/$link\n/sxm && $configfiles[$c] =~ m/$link(.*?\n\n)/sxm ) {
					say "Checking OCLC official stanza for: " . color('bold black') . "$title" . color('reset') if $c == 0;
					my $stanza = $1;
					my $updated;
					# Try to get the "updated on" info from the local stanza and convert to epoch
					if ( $stanza =~ m/(?:updated[ ])?(\d{4}-?\d{2}-?\d{2})/sxm ) {
						$updated = Date::Parse::str2time($1);
					}
					# Display matching file
					print color('bold blue');
					say "    found local copy in file: $files[$c]";
					print color('reset');
					# If possible, try to compare the RSS "updated on" with the local "updated on" epoch time
					if ( $updated ) {
						# The local stanza is older than the one in the RSS feed
						if ( $updated < $date ) {
							say "    Local stanza updated on "
								. color('bold')
								. Date::Format::time2str($date_format, $updated) 
								. color('reset')
								. " and official stanza updated on " 
								. color('bold')
								. Date::Format::time2str($date_format, $date)
								. color('reset');
							print color('red');
							print "    Local stanza needs updating...\n";
							print color('reset');
							say "    " . $link;
							
						}
						# The local stanza is equal to the one in the RSS feed
						elsif ( $updated == $date ) {
							print color('green');
							print "    Local stanza is up-to-date...\n";
							print color('reset');
						}
					}
					# It was impossible to check if the stanza is older or equal to the one from the RSS feed
					else {
						print color('red');
						print "    Local stanza needs manual checking (no datestamp to compare)...\n";
						print color('reset');
						say "    " . $link;
					}
					say "";
				}
				# We have no reference to the updated stanza in our config files
				else {
					if ( $c == 0 ) {
						say "Checking OCLC official stanza for: " . color('bold black') . "$title" . color('reset') if $c == 0;
						print color('bold blue');
						say "    not found\n";
						print color('reset');
					}
				}
			}
		}
	}
}

# Footer
say "\nCheck the full list of recently updated database stanzas (previous three months) at:";
say $most_recent_address;


