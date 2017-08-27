#!/usr/bin/perl

use warnings;
use strict; 
use File::Find; #core function of Perl

use XML::Writer; #need to add with CPAN

#currently hard coded, can be passed in later on command line (see following comment)
my $start_dir = "/Users/BPC/workspace/slidegen/temp_v2";
#my $start_dir = "/Users/BPC/workspace";

#OR die "Usage: $0 DIRs" if not @ARGV;

our $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2, UNSAFE => 1 );
$writer->xmlDecl('UTF-8');
$writer->startTag('node', TEXT => $start_dir, LOCALIZED_STYLE_REF=>"AutomaticLayout.level.root", FOLDED=>"false");

#insert the styletags from FreePlane
fpmapstyle();


our $initdepth = -1;
our $olddepth = -1;
our $newdepth = -1;
our $pathchar = "/"; 
our @status = ();

#find function performs recursive call through all directories to wanted{} subroutine
find(\&wanted, $start_dir);

print "stats: $status[0] $status[1] $status[2]\n";

foreach($status[0]..$status[2]) {$writer->endTag();}


my $xml = $writer->end();

print $xml;


#-----------start subroutine
sub wanted {
#	print "start\n";
my $level=1;

#directories are processed here 
	if (-d) {
		#print "close\n";
		#print "$File::Find::dir\t";
		#print "$_\n";
		
		#this count's the number of $pathchar in the full path to use as a relative guide for how
		#the wanted function is traversing and therefore determine the right use of opening and 
		#closing XML tags
		#--need initdepth so that whenever the end is hit we can determine how many closing tags are needed
		$newdepth = () = $File::Find::dir =~ /$pathchar/g;
		$level = $newdepth-$initdepth+1;
			
		if ($initdepth == -1) { 
			$initdepth = $newdepth; 
			#print "initdepth found as $newdepth\n";
			return;
		}
		
		#<node TEXT=".metadata" LOCALIZED_STYLE_REF="AutomaticLayout.level,1" POSITION="right"

		if ($newdepth > $olddepth) {
			$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,$level", POSITION=>"right");
		}

		if ($newdepth == $olddepth) {
			$writer->endTag();
			$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,$level", POSITION=>"right");
		}

		if ($newdepth < $olddepth) {
			foreach($newdepth..$olddepth) {$writer->endTag();}
			$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,$level", POSITION=>"right");
		}

		@status = ($initdepth,$newdepth,$olddepth);
		$olddepth = $newdepth;
		
		return;
	}

#filenames are processed here		
		
	$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"styles.subsubtopic", POSITION=>"right" );
	$writer->endTag();
	#print "file\t$_\n";
	
	return;
}
#-----------end subroutine wanted{}
	
sub fpmapstyle {
	$writer->startTag('hook', NAME=>"MapStyle");
		$writer->startTag('properties', fit_to_viewport=>"false;"); $writer->endTag();
		$writer->startTag('map_styles');
			$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.root_node", STYLE=>"oval", UNIFORM_SHAPE=>"true", VGAP_QUANTITY=>"24.0 pt");
				$writer->startTag('font', SIZE=>"24"); $writer->endTag();
				$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.predefined", POSITION=>"right", STYLE=>"bubble");
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"default", COLOR=>"#000000", STYLE=>"fork");
						$writer->startTag('font', NAME=>"SansSerif", SIZE=>"10", BOLD=>"false", ITALIC=>"false"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"defaultstyle.details"); $writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"defaultstyle.attributes");
						$writer->startTag('font', SIZE=>"9"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"defaultstyle.note", COLOR=>"#000000", BACKGROUND_COLOR=>"#ffffff", TEXT_ALIGN=>"LEFT"); $writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"defaultstyle.floating");
						$writer->startTag('edge', STYLE=>"hide_edge"); $writer->endTag();
						$writer->startTag('cloud', COLOR=>"#f0f0f0", SHAPE=>"ROUND_RECT"); $writer->endTag();
					$writer->endTag();
				$writer->endTag();
				$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.user-defined", POSITION=>"right", STYLE=>"bubble");
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.topic", COLOR=>"#18898b", STYLE=>"fork");
						$writer->startTag('font', NAME=>"Liberation Sans", SIZE=>"10", BOLD=>"true"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.subtopic", COLOR=>"#cc3300", STYLE=>"fork");
						$writer->startTag('font', NAME=>"Liberation Sans", SIZE=>"10", BOLD=>"true"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.subsubtopic", COLOR=>"#669900");
						$writer->startTag('font', NAME=>"Liberation Sans", SIZE=>"10", BOLD=>"true"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.important");
						$writer->startTag('icon', BUILTIN=>"yes"); $writer->endTag();
					$writer->endTag();
				$writer->endTag();
				$writer->startTag('stylenode', LOCALIZED_TEXT=>"styles.AutomaticLayout", POSITION=>"right", STYLE=>"bubble");
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level.root", COLOR=>"#000000", STYLE=>"oval", SHAPE_HORIZONTAL_MARGIN=>"10.0 pt", SHAPE_VERTICAL_MARGIN=>"10.0 pt");
						$writer->startTag('font', SIZE=>"18"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,1", COLOR=>"#0033ff");
						$writer->startTag('font', SIZE=>"16"); $writer->endTag();
						$writer->startTag('edge', COLOR=>"#ff0000"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,2", COLOR=>"#00b439");
						$writer->startTag('font', SIZE=>"14"); $writer->endTag();
						$writer->startTag('edge', COLOR=>"#0000ff"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,3", COLOR=>"#990000");
						$writer->startTag('font', SIZE=>"12"); $writer->endTag();
						$writer->startTag('edge', COLOR=>"#00ff00"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,4", COLOR=>"#111111");
						$writer->startTag('font', SIZE=>"10"); $writer->endTag();
						$writer->startTag('edge', COLOR=>"#ff00ff"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,5");
						$writer->startTag('edge', COLOR=>"#00ffff"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,6");
						$writer->startTag('edge', COLOR=>"#7c0000"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,7");
						$writer->startTag('edge', COLOR=>"#00007c"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,8");
						$writer->startTag('edge', COLOR=>"#007c00"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,9");
						$writer->startTag('edge', COLOR=>"#7c007c"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,10");
						$writer->startTag('edge', COLOR=>"#007c7c"); $writer->endTag();
					$writer->endTag();
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,11");
						$writer->startTag('edge', COLOR=>"#7c7c00"); $writer->endTag();
					$writer->endTag();
				$writer->endTag();
			$writer->endTag();
		$writer->endTag();
	$writer->endTag();

	return; 
} 
#-----------end subroutine fpmapstyle{}
