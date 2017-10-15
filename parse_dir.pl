#!/usr/local/ActivePerl-5.24/bin/perl

use warnings; #always
use strict;   #always
use File::Find; #core function of Perl to recursively walk through directory structures safely
use XML::Writer; #or writing valid XML
use Tkx; #Gui toolkit for choose file dialog (newer Tkx API is much better than crufty Tk)
use Archive::Zip qw(:ERROR_CODES); #for zipping and unzipping the mso file
use DateTime::Tiny; #used for creating unique backup directory names in backupmso()

#NOTE: may want to consider making this program more generic for any MSOffice XML based files

# 1. Initial user interface for options and selecting the mso file
	#1A. Setup a user interface to select options
	#need a container with checkboxes e.g.:
		#_create mindmap file
		#_modify XML [this has a lot of sub-option potential e.g. updating based on input file need trigger to select input file, or specific instruction ??? feels like options would be presented graphically after mso file selection and unzipping]
	
	
	#1B. Get the mso file to work on
	my $filename = Tkx::tk___getOpenFile() || die "Exit program due to no filename selected\n";
	#print "fname: $filename\n";

	# 1A. parse the directory from the full path file name 
	#REGEX explanation: From the beginning^ find everything.+ until the last foward slash\/ and save it as $1(), then make sure everything from the last slash, non inclusive,[^\/]+ to the end$ is accounted for
	#this regex /^(.+)\/ 
	$filename =~ /^(.+)\/[^\/]+$/;

	my $selected_dir = $1; 
	#print "sdir: $selected_dir\n";
	#hard coded for dev purposes
	#$selected_dir = "/Users/BPC/workspace/slidegen/temp_v2";

# 2. Backup any existing mso extract directory and then unzip the mso file to a hardcoded directory name
	# 2A. if unzip directory already exists, back it up
	backupmso($selected_dir);
	# 2B. 
	openmso($filename, $selected_dir);

### Need a switch at the beginning to identify if this feature is needed, or we're just modifying the XML

# 3. Traverse the mso unzip directory and build the XML file for FreePlane consumption
#  NOTE: there's a lot of specific FreePlane items missing from this build, but while FreePlane will complain at first it will add it all in automatically once the .mm file is opened in FreePlane. 

	# 3A. Start building the XML file - a global variable so it can be appropriately built in sub wanted()
	our $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2); #, UNSAFE => 1 );
	$writer->xmlDecl('UTF-8');
	$writer->startTag('node', TEXT => $selected_dir, LOCALIZED_STYLE_REF=>"AutomaticLayout.level.root", FOLDED=>"false");

	# 3B. Insert the styletags from FreePlane
	fpmapstyle();

# 4. Use the Find function performs recursive call through all directories with the built-in wanted() subroutine

	#these global variables are needed to exist outside of wanted() 
	our $initdepth = -1;
	our $olddepth = -1;
	our $newdepth = -1;
	our $pathchar = "/"; 
	our @status = ();  #this is needed to save the 3 depth variables at a point in time to determine how many closing tags are needed to complete the XML file and stay compliant

	my $corrected_dir = $selected_dir . "/mso_temp"; #only need to parse the new temp directory
	find(\&wanted, $corrected_dir);

	# 4B. The difference in depth values captured provides the ability to close any remaining open XML tags the correct number of times
	print "stats: $status[0] $status[1] $status[2]\n";
	foreach($status[0]..$status[1]) {$writer->endTag();}

	# 4C. Close out the XML file
	my $xml = $writer->end();

	# 4D. Write $xml to a file with a *.mm suffix so that it can be opened by FreeMind software
	open(my $fhxml, ">", "$selected_dir/new.mm") || die "Cannot open file 'new.mm'.\n";
	print $fhxml $xml;
	close($fhxml);
	
# 5. Process Excel file for changes and update PowerPoint, or just always generate new mso from Excel?

exit;
###############               

#-----------start subroutine backupmso
sub backupmso {
	my $dirName = shift;
	print "dirName: $dirName\n";

	if (-d "$dirName/mso_temp") {
		my $dt = DateTime::Tiny->now;   # Stores current date and time as datetime object
		my $dtStamp = $dt->ymdhms;
		rename "$dirName/mso_temp", "$dirName/mso_temp_$dtStamp";
	} else {
	    print "mso_temp did not exist, so it was not backed up\n";
	}
	print "backup done\n";
	return;
}
#-----------end subroutine backupmso

#-----------start subroutine openmso
sub openmso {
	my $zipName = shift;
	my $dirName = shift;
	print "zName: $zipName\n";

	my $zip     = Archive::Zip->new();
	
	my $status  = $zip->read($zipName);
	my @members = $zip->memberNames();
	die "Read of $zipName failed\n" if $status != AZ_OK;
	foreach (@members) {
	    $zip->extractMember("$_", "$dirName/mso_temp/$_");
	}

	print "unzip done\n";
	return;
}
#-----------end subroutine openmso

#-----------start subroutine wanted
sub wanted {
#	print "start\n";
#my $level=1;

my $mdir = $File::Find::dir;
my $mname = $File::Find::name;

print "---------------\n";
print "Mdir: $mdir\n";
print "Mnm : $mname\n";
print "---------------\n\n";

#directories are processed here 
	if (-d) {
		print "Dir : $File::Find::name\n";
		
		#this count's the number of $pathchar in the full path to use as a relative guide for how
		#the wanted function is traversing and therefore determine the right use of opening and 
		#closing XML tags

		#--need initdepth so that whenever the end is hit we can determine how many closing tags are needed
		$newdepth = () = $File::Find::name =~ /$pathchar/g;
		my $level = $newdepth-$initdepth+1;
		print "Init: $initdepth\nNew : $newdepth\nLvl : $level\nOld  : $olddepth\n\n";
			
		if ($initdepth == -1) { 
			$initdepth = $newdepth; 
			print "initdepth found as $newdepth\n";
			return;
		}
		
		# Three options to whether we are a) going down a level, b) at the same level or c) coming up a level (or more)
		# a)
		if ($newdepth > $olddepth) {
			$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,$level", POSITION=>"right");
		}
		# b)
		if ($newdepth == $olddepth) {
			$writer->endTag();
			$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,$level", POSITION=>"right");
		}
		# c)
		if ($newdepth < $olddepth) {
			foreach($newdepth..$olddepth) {$writer->endTag();}
			$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,$level", POSITION=>"right");
		}

		#must save state before olddepth is overwritten in case this is the last call in wanted()
		@status = ($initdepth,$newdepth,$olddepth); 
		$olddepth = $newdepth;
		my $olddir = $File::Find::name;
		
		return;
	} #end of directory processing

#filenames are processed here		
		
	$writer->startTag('node', TEXT=> $_, LOCALIZED_STYLE_REF=>"styles.subsubtopic", POSITION=>"right" );
	print "File: $_\n";
	my $fname = $_;
	
	open(my $fh, "<", "$fname") || die "Cannot open file '$fname'.\n";
	my @lines = <$fh>;
	close($fh);

	#process @lines looking for references to other files using regex to match Target="(.+)"
	
	foreach my $line (@lines) {
		if ($line =~ /Target\=\"([^\"]+)/) {
			#print "Target:$fname:$1\n";	
			$writer->startTag('node', TEXT=> $1, LOCALIZED_STYLE_REF=>"AutomaticLayout.level,5", POSITION=>"right" );
			$writer->startTag('font', ITALIC=>"true");
			$writer->endTag();
			$writer->endTag();
									
		} #end if
	} #end foreach
	
	$writer->endTag();

	return; #end of filename processing
}
#-----------end subroutine wanted
	
#-----------start subroutine fpmapstyle
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
					$writer->startTag('stylenode', LOCALIZED_TEXT=>"AutomaticLayout.level,5", COLOR=>"#9228a8");
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
#-----------end subroutine fpmapstyle
