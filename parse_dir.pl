#!/usr/bin/perl

use warnings;
use strict; 
use File::Find; #core function of Perl

use XML::Writer; #need to add with CPAN

my $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2, );
$writer->xmlDecl('UTF-8');
$writer->startTag('node', TEXT => "Root");

#currently hard coded, can be passed in later on command line (see following comment)
my $start_dir = "/Users/BPC/workspace/slidegen/temp_v2";

#OR die "Usage: $0 DIRs" if not @ARGV;

#find function performs recursive call through all directories to wanted{} subroutine
find(\&wanted, $start_dir);

my $dirname = "";
my $filename = "";
my $slash = "/";
my $count = 0;
my $depth = 0;
my $pdepth = 0;

#$writer->endTag;

my $xml = $writer->end();

print "xml";
print $xml;


#-----------start subroutine
sub wanted {
#	print "start\n";

#directories are processed here 
	if (-d) {
#		print "directory:$_\n";

		$depth = $File::Find::dir =~ tr[/][];
		
		#need to pass $pdepth into the subroutine
		if ($pdepth < $depth) {
#			print "open\n;";
			$writer->startTag('node', TEXT => $_);
		} 
		
		if ($pdepth > $depth) {
#			print "close\n;"
			$writer->endTag;
		} 
		
		if ($pdepth == $depth) {
#			print "same\n";
		}

		$pdepth = $depth;
		return;
	}

#filenames are processed here		
	$filename = $File::Find::name; 
	$writer->emptyTag('node', TEXT => $filename);
	
	return;
}
#-----------end subroutine wanted{}
