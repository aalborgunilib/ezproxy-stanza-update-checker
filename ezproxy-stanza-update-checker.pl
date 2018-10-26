#!/usr/bin/perl

use Modern::Perl;
use LWP::Simple();
use Getopt::Long();
use XML::Simple qw(:strict);
use Date::Parse();
use File::Slurp();
use Date::Format();
use Term::ANSIColor;

# Download RSS feed for OCLC EZproxy stanza changes
my $rss = LWP::Simple::get("https://www.oclc.org/support/services/ezproxy/database-setup.en.rss");

# Get list from command line of configuration files to check
my @files;
Getopt::Long::GetOptions ("file=s" => \@files);

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

# If the RSS file is available
if ( $rss ) {
	# Parse the stanza using a simple XML parser (yes - deprecated but excellent in this simple case)
	my $stanza_list = XML::Simple::XMLin($rss,
		'ForceArray' => 0,
		'KeyAttr' => []
		);

	# Iterate through the <item></item> parts of the feed
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
			# Check link against content of config files (one at a time)
			for ( my $c = 0; $c < scalar(@configfiles); $c++ ) {
				# REM config file number: $c
				# REM config file name: $files[$c]
				# REM config file contents: $configfiles[$c]
				
				# Match content of config file with the occurence of our "foreign" key (the link)
				if ( $configfiles[$c] =~ m/$link\n/sxm && $configfiles[$c] =~ m/$link(.*?\n\n)/sxm ) {
					say "Checking stanza from: " . color('yellow') . "$link" . color('reset') if $c == 0;
					my $stanza = $1;
					my $updated;
					# Try to get the "updated on" info from the local stanza and convert to epoch
					if ( $stanza =~ m/updated[ ](\d{8})/sxm ) {
						$updated = Date::Parse::str2time($1);
					}
					# Display matching file
					print color('bold blue');
					say "    in: $files[$c]";
					print color('reset');
					say "    found local copy of OCLC official stanza for: \"$title\"";
					# If possible, try to compare the RSS "updated on" with the local "updated on" epoch time
					if ( $updated ) {
						# The local stanza is older than the one in the RSS feed
						if ( $updated < $date ) {
							print color('red');
							print "    Local stanza needs updating... ";
							print color('reset');
							say "Stanza updated on "
								. Date::Format::time2str("%d-%m-%Y", $updated) 
								. " and feed updated on " 
								. Date::Format::time2str("%d-%m-%Y", $date);
							say "    " . $link;
						}
						# The local stanza is equal to the one in the RSS feed
						elsif ( $updated == $date ) {
							print color('green');
							print "    Local stanza is up-to-date...";
							print color('reset');
						}
					}
					# It was impossible to check if the stanza is older or equal to the one from the RSS feed
					else {
						print "    Local stanza needs manual checking...";
						say "    " . $link;
					}
					say "";
				}
				# We have no reference to the updated stanza in our config files
				else {
					say "Checking stanza from: " . color('yellow') . "$link" . color('reset') if $c == 0;
				}
			}
		}
	}
}

