#!/usr/bin/perl

use warnings;
use strict; 
use File::Find; #core function of Perl

use XML::Writer; #need to add with CPAN

our $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2); #, UNSAFE => 1 );
$writer->xmlDecl('UTF-8');
$writer->startTag('node', TEXT => "Root");

#currently hard coded, can be passed in later on command line (see following comment)
my $start_dir = "/Users/BPC/workspace/slidegen/temp_v2";

#OR die "Usage: $0 DIRs" if not @ARGV;

our $initdepth = -1;
our $olddepth = -1;
our $newdepth = -1;
our $pathchar = "/"; 

#find function performs recursive call through all directories to wanted{} subroutine
find(\&wanted, $start_dir);

$writer->endTag();
$writer->endTag();
$writer->endTag();

my $xml = $writer->end();

print $xml;


#-----------start subroutine
sub wanted {
#	print "start\n";


#directories are processed here 
	if (-d) {
		#print "close\n";
		print "$File::Find::dir\t";
		print "$_\n";
		
		#this count's the number of $pathchar in the full path to use as a relative guide for how
		#the wanted function is traversing and therefore determine the right use of opening and 
		#closing XML tags
		#--need initdepth so that whenever the end is hit we can determine how many closing tags are needed
		$newdepth = () = $File::Find::dir =~ /$pathchar/g;
				
		if ($initdepth == -1) { 
			$initdepth = $newdepth; 
			#print "initdepth found as $newdepth\n";
		}
		
		if ($newdepth > $olddepth) {
			$writer->startTag('node', TEXT=> $_);
		}

		if ($newdepth == $olddepth) {
			$writer->endTag();
			$writer->startTag('node', TEXT=> $_);
		}

		if ($newdepth < $olddepth) {
			$writer->endTag();
			$writer->endTag();
			$writer->startTag('node', TEXT=> $_);
		}

		print "i:$initdepth  o:$olddepth  n:$newdepth\n";
		$olddepth = $newdepth;
		
		return;
	}

#filenames are processed here		
		
	$writer->startTag('node', TEXT=> $_);
	$writer->endTag();
	print "file\t$_\n";
	
	return;
}
#-----------end subroutine wanted{}
