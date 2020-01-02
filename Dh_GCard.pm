#!/usr/bin/perl -w
#
# Dh_GCard.pm - assorted functions for browsing a "GCard" database
#
# (c) 2010 David Haworth
#
# This file is part of DhG.
#
# DhG is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# DhG is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with DhG.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

package Dh_GCard;

use POSIX;
use Exporter();
@ISA = qw(Exporter);
@EXPORT  =
(
	# Data
	DhG_FileList,		# List of all files in database
	DhG_Fileno,			# Array mapping person ID to index in DhG_FileList
	DhG_Name,			# Array mapping person ID to names. undef means doesn't exist.
	DhG_Gender,			# Array mapping person ID to gender
	DhG_Father_Name,	# Array mapping person ID to their father's name
	DhG_Father_Id,		# Array mapping person ID to their father's ID
	DhG_Mother_Name,	# Array mapping person ID to their mother's name
	DhG_Mother_Id,		# Array mapping person ID to their mother's ID
	DhG_Marriage_Dates,	# Array mapping person ID to their marriage dates (tokenised string)
	DhG_Marriage_Names,	# Array mapping person ID to their spouses (tokenised string)
	DhG_Marriage_Ids,	# Array mapping person ID to their spouses IDs (tokenised string)
	DhG_Birth_Date,		# Array mapping person ID to their birth date
	DhG_Baptism_Date,	# Array mapping person ID to their baptism date
	DhG_Death_Date,		# Array mapping person ID to their death date
	DhG_Burial_Date,	# Array mapping person ID to their burial date
	DhG_Private,		# Array of privacy flags (read from card file)
	DhG_Private_Calc,	# Array of calculated privacy flags

	# Functions
	DhG_LoadDatabase,
	DhG_ClearDatabase,
	DhG_LoadCard,
	DhG_LoadCard_All,
	DhG_LoadCard_FindFirstEvent,
	DhG_LoadCard_GetNextEvent,
	DhG_AnalyseRelations,
	DhG_ParseName,
	DhG_GetNoOfNames,
	DhG_GetName,
	DhG_GetFather,
	DhG_GetMother,
	DhG_GetSiblings,
	DhG_GetOffspring,
	DhG_GetSpouses,
	DhG_GetPartners,
	DhG_IsAlive,
	DhG_IsPrivate,
	DhG_GetFilename,
	DhG_GetFilebase,
	DhG_GetCardTemplateVars,
	DhG_GetDescendantTreeTemplateVars,
	DhG_GetAhnentafelTemplateVars,
	DhG_GetNewPersonTemplateVars,
	DhG_GetSurnameIndexTemplateVars,
	DhG_GetPersonInfoLine,
	DhG_Normalise,
	DhG_Trim,
	DhG_MungeUrl,
	DhG_XMLify,
	DhG_GetUniq,
	DhG_EditCard,
	DhG_EditFile,
	DhG_SetVariable,
	DhG_GetDebugLevel,
	DhG_GetTemplateDir,

	DhG_GetYearRange,

# These should go to another module
	DhG_Dump,
	DhG_PrintAncestorTree,
	DhG_Search,


	DhG_Test
);
use Dh_FileList;

sub DhG_LoadDatabase;
sub DhG_LoadCard;
sub DhG_LoadCard_Event;
sub DhG_NameToFilename;
sub DhG_Trim;
sub DhG_MungeUrl;
sub DhG_FormatDate;
sub DhG_GetTemplateDir;
sub DhG_ReadTranscriptFile;
sub DhG_ReadFileIntoVariable;

# Initialisation, "global-my" variables go here.

# Variables that can be changed with the set command.
my $DhG_DebugLevel = 0;
my $DhG_OutputFormat = "none";
my $DhG_DateFormat = "raw";
my $DhG_CardBase = undef;
my $DhG_TextBase = "/data1/family-history/transcript";
my $DhG_TemplateDir = "/data1/toolbox/DhG/templates";

# Internal variables
my $outputfile_name = undef;
my $last_id = 0;
my %DhG_NameGenderMap;
my %DhG_printed;

return 1;

# DhG_Normalise() - "normalises" a string by replacing each multiple space-tab combination with a single space.
sub DhG_Normalise
{
	my ($txt) = @_;
	$txt = join(' ', split(/\s+/, DhG_Trim($txt)));
	return $txt;
}

# DhG_XMLify() - converts some special characters to XML entities
# Returns an array!
sub DhG_XMLify
{
    my @txt = @_;

	for (@txt)
	{
		if ( defined $_ )
		{
    		s/&/&amp;/g;
    		s/</&lt;/g;
    		s/>/&gt;/g;
		}
	}
    return @txt;
}

# DhG_Trim() - trims leading and trailing spaces from string, returns result.
sub DhG_Trim
{
	my ($txt) = @_;
	$txt =~ s/^\s*(\S.*)$/$1/;
	$txt =~ s/^(.*\S)\s*$/$1/;
	return $txt;
}

# DhG_MungeUrl() - trims leading and trailing spaces from URL, translate, ..., returns result.
sub DhG_MungeUrl
{
	my ($url) = @_;

	# First, get rid of the junk
	$url = DhG_Trim($url);

	# The we can translate URLs for sites that are known to have changed
	# This could also cope with "virtual URLs", variables etc. TBD
	# Nothing defined yet.

	# Finally, return the munged URL
	return $url;
}

# DhG_SetVariable() sets a variable to the given value
sub DhG_SetVariable
{
	my ($params) = @_;

	my ($varname, $varvalue) = $params =~ m{^(.*)=(.*)$};

	if ( defined $varname && defined $varvalue )
	{
		$varname = DhG_Trim($varname);
		$varvalue = DhG_Trim($varvalue);

		if ( $varname eq "DBG" )
		{
			$DhG_DebugLevel = $varvalue;
		}
		elsif ( $varname eq "FORMAT" )
		{
			# Values: html, wikidot, ...?
			$DhG_OutputFormat = $varvalue;
		}
		elsif ( $varname eq "DATE" )
		{
			# Values: year, full, ...?
			$DhG_DateFormat = $varvalue;
		}
		elsif ( $varname eq "CARDBASE" )
		{
			# Base directory for new card files
			$DhG_CardBase = $varvalue;
		}
		elsif ( $varname eq "TEMPLATEDIR" )
		{
			# Directory containing templates
			$DhG_TemplateDir = $varvalue;
		}
		elsif ( $varname eq "TEXTBASE" )
		{
			# Base directory for transcript (.text) files
			$DhG_TextBase = $varvalue;
		}
		else
		{
			print STDERR "Unknown or unrecognised variable $varname\n";
		}
	}
	else
	{
		print STDERR "Eh?\n";
	}
}

# DhG_LoadDatabase
#
# Loads the database consisting of all the .card files in the directory trees specified by the parameters 
sub DhG_LoadDatabase
{
	my @args = @_;

	$DhG_Name[0] = "(Unknown)";
	$DhG_Gender[0] = "?";
	$DhG_Private[0] = 0;
	$DhG_Private_Calc[0] = 0;

	@DhG_FileList = DhFL_FileList(@args);

	my $index = 0;
	my $id;
	my $fileno = 0;
	my $filename;

	while ( defined $DhG_FileList[$fileno] )
	{
		my $filename  = $DhG_FileList[$fileno];

		if ( $filename =~ m{\.card$} )
		{
			print "Loading $fileno: $filename\n" if ($DhG_DebugLevel > 9 );
			$id = DhG_LoadCard($fileno);
			if ( defined $id )
			{
				if ( $id > $last_id )
				{
					$last_id = $id;
				}
			}
		}

		$fileno++;
	}
}

# DhG_LoadCard
#
# Loads the index card whose filename is given in the first parameter. The second parameter is
# intended to enable some plausibilty checks but isn't implemented at the moment.
sub DhG_LoadCard
{
	my ($fileno, $check) = @_;
	my $filename = $DhG_FileList[$fileno];
	my $name = undef;
	my $uniq = undef;
	my $gender = undef;
	my $privacy = undef;
	my $father_name = undef;
	my $father_uniq = undef;
	my $mother_name = undef;
	my $mother_uniq = undef;
	my $id = undef;
	my $err = 0;
	my $stored = 0;

	if ( !defined $check )
	{
		$check = 0;
	}

	open(DhG_INFILE, "<$filename") or die "Unable to open $filename for reading\n";

	print STDOUT "Reading person from $filename\n" if ($DhG_DebugLevel > 99 );

	while ( <DhG_INFILE> )
	{
		chomp;
		my $line = DhG_Normalise($_);

		if ( $line eq "" )
		{
			# Ignore blank lines
			print STDOUT "Blank line\n" if ($DhG_DebugLevel > 99);
		}
		elsif ( $line eq "EOF" )
		{
			# Skip out of read loop if an EOF marker is found.
			last;
		}
		else
		{
			$firstchar = substr($line, 0, 1);
			$firstdigit = index("0123456789?", $firstchar);

			if ( $firstchar eq "#" )
			{
				# Comment line: ignore
				print STDOUT "Comment line \"$line\"\n" if ($DhG_DebugLevel > 99);
			}
			elsif ( $line eq "Male" || $line eq "Female" )
			{
				print STDOUT "Gender line \"$line\"\n" if ($DhG_DebugLevel > 99);
				if ( defined $gender )
				{
					printf STDERR "$filename: multiple Gender entries\n";
				}
				else
				{
					$gender = $firstchar;
					if ( defined $id )
					{
						$DhG_Gender[$id] = $gender;
					}
				}
			}
			elsif ( $line eq "Private" || $line eq "Public" )
			{
				print STDOUT "Privacy line \"$line\"\n" if ($DhG_DebugLevel > 99);
				if ( defined $privacy )
				{
					printf STDERR "$filename: multiple Privacy entries\n";
				}
				else
				{
					if ( $line eq "Private" )
					{
						$privacy = 1;
					}
					else
					{
						$privacy = 0;
					}
					if ( defined $id )
					{
						$DhG_Private[$id] = $privacy;
					}
				}
			}
			elsif ( $firstchar eq "+" || $firstchar eq "-" )
			{
				# Supplementary information line
				print STDOUT "Supplementary info line \"$line\"\n" if ($DhG_DebugLevel > 99);
			}
			elsif ( $firstchar eq "|" )
			{
				# Continuation line
				print STDOUT "Continuation line \"$line\"\n" if ($DhG_DebugLevel > 99);
			}
			elsif ( $firstdigit >= 0 )
			{
				# Event entry
				print STDOUT "Event line \"$line\"\n" if ($DhG_DebugLevel > 99);
				if ( defined $id )
				{
					DhG_LoadCard_Event($filename, $id, $line) if ( $err == 0 );
				}
				else
				{
					printf STDERR "$filename: ERROR: Event record before identity has been defined\n";
				}
			}
			else
			{
				my($keyword,$rest) = $line =~ m{^(\S*):\s*(\S.*)$};

				if ( defined $keyword )
				{
					print STDOUT "Keyword line \"$keyword\" : Rest = \"$rest\"\n" if ($DhG_DebugLevel > 99);

					if ( $keyword eq "Name" )
					{
						if ( defined $name )
						{
							printf STDERR "$filename: ERROR: multiple Name entries\n";
						}
						else
						{
							$name = $rest;
						}
					}
					elsif ( $keyword eq "Uniq" )
					{
						if ( defined $uniq )
						{
							printf STDERR "$filename: ERROR: multiple Uniq entries\n";
						}
						else
						{
							$uniq = $rest;

							if ( defined $DhG_Name[$uniq] )
							{
								printf STDERR "$filename: ERROR: duplicate ID ($uniq); ignoring file\n";
								$err++;
							}
						}
					}
					elsif ( $keyword eq "Father" )
					{
						if ( defined $father )
						{
							printf STDERR "$filename: ERROR: multiple Father entries\n";
						}
						else
						{
							($father_name, $father_uniq) = DhG_ParseName($rest);
							if ( defined $id )
							{
								$DhG_Father_Name[$id] = $father_name;
								$DhG_Father_Id[$id] = $father_uniq;
							}
							if ( !defined $father_uniq )
							{
								printf STDERR "$filename: WARNING: Father has no unique ID\n"
									if ( $DhG_DebugLevel > 9 );
							}
						}
					}
					elsif ( $keyword eq "Mother" )
					{
						if ( defined $mother )
						{
							printf STDERR "$filename: ERROR: multiple Mother entries\n";
						}
						else
						{
							($mother_name, $mother_uniq) = DhG_ParseName($rest);
							if ( defined $id )
							{
								$DhG_Mother_Name[$id] = $mother_name;
								$DhG_Mother_Id[$id] = $mother_uniq;
							}
							if ( !defined $mother_uniq )
							{
								printf STDERR "$filename: WARNING: Mother has no unique ID\n"
									if ( $DhG_DebugLevel > 9 );
							}
						}
					}
				}
				else
				{
					print STDERR "$filename: WARNING: Mystery line \"$line\"\n" if ($DhG_DebugLevel > 49);
				}

				# As soon as we have a name and uniq ID, store them!
				if ( !$stored && defined $name && defined $uniq )
				{
					print STDOUT "Storing $name with ID $uniq\n" if ($DhG_DebugLevel > 49);

					$id = $uniq;
					$DhG_Name[$id] = $name;
					$DhG_Gender[$id] = $gender;
					$DhG_Father_Name[$id] = $father_name;
					$DhG_Father_Id[$id] = $father_uniq;
					$DhG_Mother_Name[$id] = $mother_name;
					$DhG_Mother_Id[$id] = $mother_uniq;
					$DhG_Fileno[$id] = $fileno;
					$DhG_Marriage_Dates[$id] = "";
					$DhG_Marriage_Names[$id] = "";
					$DhG_Marriage_Ids[$id] = "";
					$DhG_Private[$id] = $privacy;

					$stored = 1;
				}
			}
		}
	}

	close(DhG_INFILE);


	if ( $DhG_DebugLevel > 79 && $err == 0 )
	{
		print STDOUT "\n";
		print STDOUT "$DhG_Fileno[$id] ($DhG_FileList[$DhG_Fileno[$id]])\n";
		print STDOUT "Name:";
		print STDOUT "     $DhG_Name[$id]"					if ( defined $DhG_Name[$id] );
		print STDOUT "\n";
		print STDOUT "Gender:   $DhG_Gender[$id]\n"			if ( defined $DhG_Gender[$id] );
		print STDOUT "Father:   $DhG_Father_Name[$id]\n"	if ( defined $DhG_Father_Name[$id] );
		print STDOUT "F.Uniq:   $DhG_Father_Id[$id]\n"		if ( defined $DhG_Father_Id[$id] );
		print STDOUT "Mother:   $DhG_Mother_Name[$id]\n"	if ( defined $DhG_Mother_Name[$id] );
		print STDOUT "M.Uniq:   $DhG_Mother_Id[$id]\n"		if ( defined $DhG_Mother_Id[$id] );
	}

	return $id;
}

# DhG_LoadCard_Event() loads an event from a card file.
# INTERNAL
# Event line is in the form "DATE  EVENT   MORE-INFO"
#    Since version 2, MORE-INFO is only for marriages.
sub DhG_LoadCard_Event
{
	my ($filename, $id, $evline) = @_;

	my ($date, $event, $rest) = $evline =~ m{^(\S*)\s*(\S*)\s*(.*)$};

	printf STDOUT "Event line: $date : $event : \"$rest\"\n" if ( $DhG_DebugLevel > 99 );

	if ( $event eq "Birth" )
	{
		# Record date and place of birth
		$DhG_Birth_Date[$id] = $date;
	}
	elsif ( $event eq "Baptism" )
	{
		# Record date and place of baptism
		$DhG_Baptism_Date[$id] = $date;
	}
	elsif ( $event eq "Marriage" )
	{
		# Record date of marriage and spouse. Trickier - there might be more than one!
		if ( $DhG_Marriage_Dates[$id] ne "" )
		{
			$DhG_Marriage_Dates[$id] .= "|";
			$DhG_Marriage_Names[$id] .= "|";
			$DhG_Marriage_Ids[$id] .= "|";
		}
		$DhG_Marriage_Dates[$id] .= $date;
		my ($spouse_name, $spouse_id) = DhG_ParseName($rest);

		$DhG_Marriage_Names[$id] .= $spouse_name;
		if ( defined $spouse_id )
		{
			$DhG_Marriage_Ids[$id] .= $spouse_id;
		}
		else
		{
			$DhG_Marriage_Ids[$id] .= "?";
			printf STDERR "$filename: WARNING: Spouse $spouse_name has no unique ID\n";
		}
	}
	elsif ( $event eq "Death" )
	{
		# Record date and place of death
		$DhG_Death_Date[$id] = $date;
	}
	elsif ( $event eq "Burial" )
	{
		# Record date and place of burial
		$DhG_Burial_Date[$id] = $date;
	}
}

# DhG_LoadCard_All() - reads the entire file from a named card file into an array
sub DhG_LoadCard_All
{
	my ($cardname) = @_;

	my $tmpstr;
	my $err = 0;
	my $skip_leading = 1;

	@file_lines = ();

	if ( open(DhG_INFILE, "<$cardname") )
	{
		while ( <DhG_INFILE> )
		{
			chomp;
			$line = DhG_Trim($_);

			if ( $line eq "EOF" )
			{
				# Skip out of reading loop if an EOF marker is found.
				last;
			}

			push(@file_lines, $line);
		}

		close(DhG_INFILE);
	}
	else
	{
		print STDERR "Unable to open $cardname for reading\n";
	}

	return @file_lines;
}

# DhG_LoadCard_FindFirstEvent() - find the first event in a preloaded card file.
sub DhG_LoadCard_FindFirstEvent
{
	my ($lref) = @_;
	my ($lno, $line);

	$lno = 0;

	while ( defined ${$lref}[$lno] )
	{
		# Look at each line
		$line = ${$lref}[$lno];
		if ( $line =~ m{^[1-9?]} )
		{
			# Found an event. Return its line number.
			print STDOUT "DBG: Found first event \"$line\" at $lno.\n" if ( $DhG_DebugLevel >= 100 );
			return $lno;
		}
		$lno++;
	}

	# No events found; return -1 to indicate it.
	return (-1);
}

# DhG_LoadCard_GetNextEvent() - extract the next event
sub DhG_LoadCard_GetNextEvent
{
	my ($mark, $lref, $mode, $t_index, $tref) = @_;
	my ($date, $event, $info, $source) = ("", "", "", "");
    my ($spouse, $spouse_file) = ("", "");
	my ($line);
	my ($e_d, $e_t, $e_r);
	my $in_source = 0;
	my $in_transcript = 0;
	my $transcript_text = undef;
	my $transcript_type = undef;
	my $newline = "\n";
	my ($source_name, $source_nLinks) = ("", 0);
	my @source_link = ();

	print STDOUT "DBG: DhG_LoadCard_GetNextEvent: mode = \"$mode\"\n" if ( $DhG_DebugLevel >= 100 );
	if ( $mode eq 'html' )
	{
		$newline = "<br/>"
	}
	print STDOUT "DBG: DhG_LoadCard_GetNextEvent: newline = \"$newline\"\n" if ( $DhG_DebugLevel >= 100 );

	$line = ${$lref}[$mark];

	($e_d, $e_t, $e_r) = $line =~ m{^([^\s]+)\s+([^\s]+)(.*)$};
	$e_r = DhG_Trim($e_r);
	$e_t = ucfirst(lc(DhG_Trim($e_t)));

	$date = DhG_FormatDate($e_d, "?", "full");

	# DECISION: where the spouse goes (event or info) is decided by the template
	# DECISION: apart from some exceptions, the entire rest of line is the event.
	#           IMPLICATIONS: First word of event will be normalised
	#                         Marriage is a special case
    #                         Misc is a special case for backwards compatibility.
	$event = $e_t;

	if ( $event eq "Marriage" )
	{
		my ($spouse_name, $spouse_id) = DhG_ParseName($e_r);
		if ( defined $spouse_id )
		{
			$spouse = DhG_GetName($spouse_id);
		}
		if ( (defined $spouse) && ($spouse ne "") )
		{
			my $spouse_years = DhG_GetYearRange($spouse_id);
			$spouse .= " ($spouse_years)" if ( defined $spouse_years && $spouse_years ne "" );
			$spouse_file = DhG_GetFilebase($spouse_id);
		}
		else
		{
			$spouse = $spouse_name;
		}
	}
	elsif ( $event eq "Misc" )
	{
		# Event is Misc: replace it with what it really is (which might be a phrase).
		# This is just for backwards compatibility
		$event = $e_r;
	}
	else
	{
		# Join the first word (case-adjusted) onto the rest.
		$event .=  " ".$e_r;
	}

	print STDOUT "DBG: Found event \"$date $event\" at $mark.\n" if ( $DhG_DebugLevel >= 100 );

	$mark++;

	# Convert basic data to XML-friendly format. info and source have been selectively converted.
	($date, $event, $spouse, $spouse_file) = DhG_XMLify($date, $event, $spouse, $spouse_file);

	# Process the event
	while ( defined ${$lref}[$mark] )
	{
		# Look at each line
		$line = ${$lref}[$mark];
		if ( $line =~ m{^[1-9?]} )
		{
			# Found next event. Output the remaining transcript if there is one.
			if ( $in_transcript )
			{
				if ( defined $transcript_text )
				{
					my $tline = "";
					$tline .= "<$transcript_type>" if ( $mode eq 'html' );
					$tline .= $transcript_text;
					$tline .= "</$transcript_type>" if ( $mode eq 'html' );
					$tline .= "\n";
					${$tref}[$t_index] = $tline;
					$t_index++;
					$source_link[$source_nLinks++] = "<a href=\"#transcript_$t_index\">[transcript $t_index]</a>";
				}
				$in_transcript = 0;
			}

			# Output the remaining source if there is one.
			if ( $in_source )
			{
				$source .= $newline if ( $source ne "" );
				$source .= "Source: ".$source_name;
				if ( $mode eq 'html' )
				{
					my $i;
					for ( $i = 0; $i < $source_nLinks; $i++ )
					{
						my $tag = "[".($i+1)."]";
						$source .= "&nbsp;&nbsp;$source_link[$i]"
					}
				}
			}

			# Return the line number of the next event and the data for this event.
			return ($mark, $date, $event, $spouse, $spouse_file, $info, $source, $t_index);
		}
		elsif ( $line =~ m{^\+} )
		{
			# New primary info line

			# Output the current transcript if there is one
			if ( $in_transcript )
			{
				if ( defined $transcript_text )
				{
					my $tline = "";
					$tline .= "<$transcript_type>" if ( $mode eq "html" );
					$tline .= $transcript_text;
					$tline .= "</$transcript_type>" if ( $mode eq "html" );
					$tline .= "\n";
					${$tref}[$t_index] = $tline;
					$t_index++;
					$source_link[$source_nLinks++] = "<a href=\"#transcript_$t_index\">[transcript $t_index]</a>";
				}
				$in_transcript = 0;
			}

			# Output the current source if there is one
			if ( $in_source )
			{
				$source .= $newline if ( $source ne "" );
				$source .= "Source: ".$source_name;
				if ( $mode eq 'html' )
				{
					my $i;
					for ( $i = 0; $i < $source_nLinks; $i++ )
					{
						$source .= "&nbsp;&nbsp;$source_link[$i]";
					}
				}

				# Clear out the previous source.
				$source_link = ();
				$source_nLinks = 0;
				$in_source = 0;
			}

			if ( $line =~ m{^\+Source} )
			{
				# Switch to SOURCE mode
				($source_name) = $line =~ m{^\+Source (.*)$};
				$source_name = DhG_Trim($source_name);
				if ( $source_name eq "" )
				{
					print STDERR "Event source line $line hase no source name - ignoring.\n";
				}
				else
				{
					($source_name) = DhG_XMLify($source_name);
					$in_source = 1;
				}
			}
			else
			{
				my ($info_type, $info_val) = $line =~ m{^\+(\S*)\s(.*)$};
				if ( defined $info_type && defined $info_val )
				{
					$info_type = ucfirst(lc(DhG_Trim($info_type)));
					$info_val = ucfirst(DhG_Trim($info_val));
					print STDOUT "DBG: Event info line \"$info_type - $info_val\" at $mark.\n"
																					if ( $DhG_DebugLevel >= 100 );
					($info_type, $info_val) = DhG_XMLify($info_type, $info_val);

					$info .= $newline if ( $info ne "" );
					$info .= $info_type . ": " . $info_val;
				}
				else
				{
					print STDOUT "DBG: Ignoring event info line \"$line\" at $mark.\n"
																					if ( $DhG_DebugLevel >= 100 );
				}
			}
		}
		elsif ( $line =~ m{^\-} )
		{
			# New secondary info line

			# Output the transcript if there is one.
			if ( $in_transcript )
			{
				if ( defined $transcript_text )
				{
					my $tline = "";
					$tline .= "<$transcript_type>" if ( $mode eq "html" );
					$tline .= $transcript_text;
					$tline .= "</$transcript_type>" if ( $mode eq "html" );
					$tline .= "\n";
					${$tref}[$t_index] = $tline;
					$t_index++;
					$source_link[$source_nLinks++] = "<a href=\"#transcript_$t_index\">[transcript $t_index]</a>";
				}
				$in_transcript = 0;
			}

			if ( $in_source )
			{
				# Secondary lines that are part of source records: we recognise URL and Transcript
				if ( $line =~ m{^-URL} )
				{
					# A link to an arbitrary web site
					my ($url) = $line =~ m{^\-URL (.*)$};
					$url = DhG_MungeUrl($url);
					$source_link[$source_nLinks++] = "<a href=\"$url\">[link]</a>";
				}
				elsif ( $line =~ m{^-Transcript} )
				{
					# A transcript
					($transcript_type) = $line =~ m{^-Transcript (.*)$};
					$transcript_type = DhG_Trim($transcript_type) if ( defined $transcript_type );
					$transcript_type = "pre" if ( !defined $transcript_type || $transcript_type eq "" );
					$in_transcript = 1;
					$transcript_text = undef
				}
				elsif ( $line =~ m{^-File} )
				{
					# A file source. Does it specify a Transcript file with the ".text" suffix?
					my ($transcript_type) = $line =~ m{^\-File (.*)$};
					$transcript_type = DhG_Trim($transcript_type);

					if ( $transcript_type =~ m{^Transcript .*\.text$} )
					{
						# File is the correct type
						my ($transcript_file) = $transcript_type =~ m{^Transcript (.*)$};
						$transcript_file = DhG_Trim($transcript_file);
						$transcript_text = DhG_ReadTranscriptFile($transcript_file);
						if ( defined $transcript_text )
						{
							my $tline = "";
							$tline .= "<pre>" if ( $mode eq "html" );
							$tline .= $transcript_text;
							$tline .= "</pre>" if ( $mode eq "html" );
							$tline .= "\n";
							${$tref}[$t_index] = $tline;
							$t_index++;
							$source_link[$source_nLinks++] = "<a href=\"#transcript_$t_index\">[transcript $t_index]</a>";
							$transcript_text = undef
						}
					}
				}
			}
			else
			{
				# Secondary lines that are parts of other info records
				# Make sure there has been an info record first - ognore otherwise
				if ( $info ne "" )
				{
					if ( $line =~ m{^-URL} )
					{
						# A link to an arbitrary web site
						my ($url) = $line =~ m{^\-URL (.*)$};
						$url = DhG_MungeUrl($url);
						$info .= " <a href=\"$url\">[link]</a>";
					}
				}
			}
		}
		elsif ( $line =~ m{^\|} )
		{
			# Continuation line
			if ( $in_transcript )
			{
				my ($transcript_line) = $line =~ m{^\|(.*)$};
				if ( defined $transcript_line )
				{
					($transcript_line) = DhG_XMLify($transcript_line);
					if ( defined $transcript_text )
					{
						$transcript_text .= "\n".$transcript_line;
					}
					else
					{
						$transcript_text = $transcript_line;
					}
				}
			}
		}
		else
		{
			# Ignore anything else
		}

		$mark++;
	}

	# No further event found. Output the remaining transcript and source if there is one.

	if ( $in_transcript )
	{
		if ( defined $transcript_text )
		{
			my $tline = "";
			$tline .= "<$transcript_type>" if ( $mode eq "html" );
			$tline .= $transcript_text;
			$tline .= "</$transcript_type>" if ( $mode eq "html" );
			$tline .= "\n";
			${$tref}[$t_index] = $tline;
			$t_index++;
			$source_link[$source_nLinks++] = "<a href=\"#transcript_$t_index\">[transcript $t_index]</a>";
		}
		$in_transcript = 0;
	}

	if ( $source_name ne "" )
	{
		$source .= $newline if ( $source ne "" );
		$source .= "Source: ".$source_name;
		if ( $mode eq 'html' )
		{
			my $i;
			for ( $i = 0; $i < $source_nLinks; $i++ )
			{
				my $tag = "[".($i+1)."]";
				$source .= "&nbsp;&nbsp;$source_link[$i]"
			}
		}
	}

	# Return (-1) to indicate end, and the data for this event.
	return ((-1), $date, $event, $spouse, $spouse_file, $info, $source, $t_index);
}

# DhG_ClearDatabase() - removes all records from database
sub DhG_ClearDatabase
{
	@DhG_Name = undef;
	@DhG_Gender = undef;
	@DhG_FileList = undef;
	@DhG_Name = undef;
	@DhG_Gender = undef;
	@DhG_Father_Name = undef;
	@DhG_Father_Uniq = undef;
	@DhG_Mother_Name = undef;
	@DhG_Mother_Uniq = undef;
	@DhG_Fileno = undef;
	@DhG_Marriage_Dates = undef;
	@DhG_Marriage_Names = undef;
	@DhG_Marriage_Ids = undef;
	@DhG_Private = undef;
	@DhG_Private_Calc = undef;
	%DhG_NameGenderMap = ();

	%DhG_TranscriptFiles = ();
}

# DhG_GetNewPersonTemplateVars() - creates template variables for new person card
sub DhG_GetNewPersonTemplateVars
{
	my ($person_name, $father, $mother) = @_;
	my $fullpath = undef;
	my $template_vars = undef;

	my @names = split /\s+/,$person_name;

	if ( $#names >= 1 )
	{
		if ( defined $DhG_CardBase && -d $DhG_CardBase )
		{
			my $subdirname = $names[$#names];
			my $filename = join("", @names);
			my $gender = $DhG_NameGenderMap{$names[0]};

			$fullpath = $DhG_CardBase."/".$subdirname;

			if ( defined $gender )
			{
				if ( $gender eq "M" )
				{
					$gender = "Male";
				}
				elsif ( $gender eq "F" )
				{
					$gender = "Female";
				}
			}
			else
			{
				$gender = "";
			}

			if ( ! -e $fullpath )
			{
				if ( ! mkdir($fullpath) )
				{
					print STDERR "Failed to create new subdirectory $fullpath\n";
					return;
				}
			}

			if ( -d $fullpath )
			{
				my $id = $last_id + 1;

				$fullpath = $fullpath."/".$filename."-".$id.".card";

				if ( -e $fullpath )
				{
					print STDERR "File $fullpath already exists - will not overwrite\n";
				}
				else
				{
					# Now we've got all the stuff, put it in the vars hash for the template.
					$template_vars =
					{
						name			=> $person_name,			# Name of person
						uniq			=> $id,						# Id of person
						gender			=> $gender,					# Gender of person
						father			=> "",						# Name + id of father (temp - not given)
						mother			=> "",						# Name + id of mother
					};
				}
	
				$last_id++;
			}
			else
			{
				print STDERR "$fullpath is not a directory\n";
			}
		}
		else
		{
			print STDERR "Set the CARDBASE variable to an existing directory first.";
		}
	}
	else
	{
		print STDERR "Person's name must be at least Forename Surname\n";
	}

	return ( $fullpath, $template_vars);
}

# DhG_ParseName() splits the [unique identification] from a name and returns both.
sub DhG_ParseName
{
	my ($param) = @_;

	my ($name, $uniq) = $param =~ m{^(.*)\[(.*)\].*$};

	if ( defined $name && defined $uniq )
	{
		$name = DhG_Normalise($name);
		$uniq = DhG_Normalise($uniq);
	}
	else
	{
		$name = DhG_Normalise($param);
		$uniq = undef;
	}

	return ($name, $uniq);
}

# DhG_GetName() - returns the name of the specified person (id)
sub DhG_GetName
{
	my ($id) = @_;	# Parameter is person's ID

	return $DhG_Name[$id];
}

# DhG_GetNoOfNames() - returns the index of the last name in DhG_Name
sub DhG_GetNoOfNames
{
	return $#DhG_Name;
}

# DhG_GetFather() - returns the id and name of the father of the specified person (id)
sub DhG_GetFather
{
	my ($id) = @_;	# Parameter is person's ID

	return ($DhG_Father_Id[$id], $DhG_Father_Name[$id]);
}

# DhG_GetMother() - returns the id and name of the mother of the specified person (id)
sub DhG_GetMother
{
	my ($id) = @_;	# Parameter is person's ID

	return ($DhG_Mother_Id[$id], $DhG_Mother_Name[$id]);
}

# DhG_GetSiblings() - returns a list of sibling ids, in order of DoB
sub DhG_GetSiblings
{
	my ($id) = @_;	# Parameter is person's ID

	# Get mother and father ids
	my $fid = $DhG_Father_Id[$id];
	my $mid = $DhG_Mother_Id[$id];

	# Hash of siblings versus DoB
	my %sib_dob = ();

	my @sibs = ();
	my ($sid,$sdob);

	# Run through all the ids in the dataset
	foreach $sid ( 1 .. $#DhG_Name )
	{
		# Ignore gaps
		if ( defined $DhG_Name[$sid] )
		{
			# Get potential sibling's father and mother
			my $sfid = $DhG_Father_Id[$sid];
			my $smid = $DhG_Mother_Id[$sid];

			if ( ( defined $sfid && defined $fid && $sfid == $fid ) ||
				 ( defined $smid && defined $mid && $smid == $mid ) )
			{
				# Found a sibling! Get DoB
				$sdob = $DhG_Birth_Date[$sid];

				# Replace DoB with ? if not found
				if ( !defined $sdob )
				{
					$sdob = "?";
				}

				# Guarantee DoB is unique
				while ( defined $sib_dob{$sdob} )
				{
					$sdob .= _;
				}

				$sib_dob{$sdob} = $sid;
			}
		}
	}

	# Pull the siblings out of the hash in DoB order and return
	foreach $sdob (sort keys %sib_dob)
	{
		push @sibs, $sib_dob{$sdob};
	}

	return @sibs;
}

# DhG_GetOffspring() - returns a list of offspring ids, in order of DoB
sub DhG_GetOffspring
{
	my ($id) = @_;	# Parameter is person's ID

	# Hash of offsring versus DoB
	my %off_dob = ();

	my @offs = ();
	my ($oid,$odob);

	# Run through all the ids in the dataset
	foreach $oid ( 1 .. $#DhG_Name )
	{
		# Ignore gaps
		if ( defined $DhG_Name[$oid] )
		{
			# Get potential offspring's father and mother
			my $ofid = $DhG_Father_Id[$oid];
			my $omid = $DhG_Mother_Id[$oid];

			if ( ( (defined $ofid) && ($ofid == $id) ) ||
				 ( (defined $omid) && ($omid == $id) ) )
			{
				# Found offspring! Get DoB
				my $odob = $DhG_Birth_Date[$oid];

				# Replace DoB with ? if not found
				if ( !defined $odob )
				{
					$odob = "?";
				}

				# Guarantee DoB is unique
				while ( defined $off_dob{$odob} )
				{
					$odob .= _;
				}

				$off_dob{$odob} = $oid;
			}
		}
	}

	# Pull the offspring out of the hash in DoB order and return
	foreach $odob (sort keys %off_dob)
	{
		push @offs, $off_dob{$odob};
	}

	return @offs;
}

# DhG_GetSpouses() - returns a list of spouse ids
sub DhG_GetSpouses
{
	my ($id) = @_;	# Parameter is person's ID
	my $spouse;
	my @spouses = ();

	print STDOUT "DBG: DhG_GetSpouses($id) - \"$DhG_Marriage_Ids[$id]\"\n" if ( $DhG_DebugLevel >= 110 );

	if ( defined $DhG_Marriage_Ids[$id] )
	{
		my @sp_id = split /\|/,$DhG_Marriage_Ids[$id];

		foreach $spouse (@sp_id)
		{
			if ( defined $spouse && $spouse ne "" )
			{
				push(@spouses, $spouse);
			}
		}
	}
	else
	{
		print STDERR "No marriage ID string for $id $DhG_Name[$id]\n";
	}

	return @spouses;
}

# DhG_GetPartners() - returns a list of partner ids, in order of "encounter"
sub DhG_GetPartners
{
	my ($id) = @_;	# Parameter is person's ID

	# TEMPORARY Just return the list of known spouses. For a refinement later we can
	# add the other parents of the person's children.

	return DhG_GetSpouses($id);
}

# DhG_GetFilename() - returns the filename for a person
sub DhG_GetFilename
{
	my ($id) = @_;	# Parameter is person's ID
	my ($filename);

	$filename  = $DhG_FileList[$DhG_Fileno[$id]];

	return $filename;
}

# DhG_GetFilebase() - returns the "base filename" for a person. Includes the surname directory
sub DhG_GetFilebase
{
	my ($id) = @_;	# 1st parameter is person's ID

	return "" if ( !defined $id );

	my ($filename, $basename);

	$filename  = $DhG_FileList[$DhG_Fileno[$id]];

	($basename) = $filename =~ m{^.*/([^/]+/[^/]+)\.card};

	return $basename;
}


# DhG_GetFilebaseOnly() - returns the "base filename" for a person - no directory parts
sub DhG_GetFilebaseOnly
{
	my ($id) = @_;	# 1st parameter is person's ID

	return "" if ( !defined $id );

	my ($filename, $basename);

	$filename  = $DhG_FileList[$DhG_Fileno[$id]];

	($basename) = $filename =~ m{^.*/([^/]+)\.card};

	return $basename;
}


# DhG_GetYearRange() - returns the DoB-DoD string (year only, with parentheses)
sub DhG_GetYearRange
{
	my ($id) = @_;	# Parameter is person's ID
	my $dob_dod = "";

	if ( defined $id )
	{
		my $dob = DhG_FormatDate($DhG_Birth_Date[$id], "?", "yearonly");
	    my $dod = DhG_FormatDate($DhG_Death_Date[$id], "", "yearonly");

		if ( $dob ne "?" || $dod ne "?" )
		{
			$dob_dod = "$dob-$dod";
		}
	}

	return $dob_dod;
}

# DhG_IsAlive() - returns TRUE if the person is still alive
sub DhG_IsAlive
{
    my ($id) = @_;  # Parameter is person's ID

	if ( $id eq "?" )
	{
		return 0;	# Insufficient information available
	}

	if ( defined $DhG_Death_Date[$id] )
	{
		return 0;	# Date of death is defined (may be unknown), so person is dead.
	}

	return 1;		# Alive!
}

# DhG_IsPrivate() - returns TRUE if the person is "private"
sub DhG_IsPrivate
{
    my ($id) = @_;  # Parameter is person's ID

	if ( defined $DhG_Private[$id] )
	{
		return $DhG_Private[$id];
	}

	if ( defined $DhG_Private_Calc[$id] )
	{
		return $DhG_Private_Calc[$id];
	}

	return 0;
}

# DhG_FormatDate() converts a date to the selected format.
sub DhG_FormatDate
{
	my ($in_date, $dflt, $fmt) = @_;

	$fmt = $DhG_DateFormat if ( !defined $fmt);

	# For undefined dates, return a default or "?"
	if ( !defined $in_date )
	{
		if ( defined $dflt )
		{
			return $dflt;
		}
		else
		{
			return "?";
		}
	}

	# For "raw" format, don't do any transformation
	if ( $fmt eq "raw" )
	{
		return $in_date;
	}

	my ($rest, $work_date, $modifier, $formatted_date, $Y, $M, $D, $Q);

	$work_date = $in_date;

	($rest, $modifier) = $work_date =~ m{^(.*)([~<>])$};

	if ( defined $rest && defined $modifier )
	{
		$work_date = $rest;
		print STDERR "Date modifier is $modifier (rest is $rest)\n" if ( $DhG_DebugLevel >= 10 );
	}
	else
	{
		$modifier = undef;
	}

	($Y,$M,$D) = $work_date =~ m{^([0-9]+)-([0-9]+)-([0-9]+)$};

	if ( defined $Y && defined $M && defined $D )
	{
		# Format is (probably) yyyy-mm-dd
		if ( $fmt eq "yearonly" )
		{
			# Take year as exact, discard modifier
			$formatted_date = $Y;
			$modifier = undef;
		}
		else
		{
			$formatted_date = $work_date;
		}
	}
	else
	{
		($Y,$M) = $work_date =~ m{^([0-9]+)-([0-9]+)$};

		if ( defined $Y && defined $M )
		{
			# Format is (probably) yyyy-mm
			if ( $fmt eq "yearonly" )
			{
				# Take year as exact, discard modifier
				$formatted_date = $Y;
				$modifier = undef;
			}
			else
			{
				$formatted_date = $work_date;
			}
		}
		else
		{
			($Y,$Q) = $work_date =~ m{^([0-9]+)-Q([1-4])$};

			if ( defined $Y && defined $Q )
			{
				# Format is (probably) yyyy-Qn. Ignore any modifiers
				$modifier = undef;

				if ( $fmt eq "yearonly" )
				{
					# Take year as exact, FIXME: might be in quarter prior to registration
					$formatted_date = $Y;
				}
				elsif ( $fmt eq "noquarter" )
				{
					# Convert quarter number into "before end-of-quarter"
					$modifier = "<";
					if ( $Q eq "1" )
					{
						$formatted_date = "$Y-03-31";
					}
					elsif ( $Q eq "2" )
					{
						$formatted_date = "$Y-06-30";
					}
					elsif ( $Q eq "3" )
					{
						$formatted_date = "$Y-09-30";
					}
					elsif ( $Q eq "4" )
					{
						$formatted_date = "$Y-12-31";
					}
					else
					{
						$formatted_date = "$Y-QQ";
					}
				}
				else
				{
					$formatted_date = $work_date;
				}
			}
			else
			{
				($Y) = $work_date =~ m{^([0-9]+)$};

				if ( defined $Y )
				{
					$formatted_date = "$Y";
				}
				else
				{
					#Format is (probably) CC?? or ? or blank
					# If it contains two or more question marks, convert it to a single ?
					$formatted_date = $work_date;
					my ($tmp) = $formatted_date =~ m{\?\?};
					if ( defined $tmp )
					{
						$formatted_date = "?";
					}
					$modifier = undef;
				}
			}
		}
	}

	# No recognised date form found
	if ( !defined $formatted_date )
	{
		$formatted_date = $in_date;
	}
	elsif ( defined $modifier )
	{
		if ( $modifier eq "~" )
		{
			$formatted_date = "abt.$formatted_date";
		}
		elsif ( $modifier eq "<" )
		{
			$formatted_date = "bef.$formatted_date";
		}
		elsif ( $modifier eq ">" )
		{
			$formatted_date = "aft.$formatted_date";
		}
	}

	return $formatted_date;
}

# DhG_GetCardTemplateVars() - fill a hash with the variables for a "person card", and return the hash
sub DhG_GetCardTemplateVars
{
	my ($id, $privacy, $mode) = @_;

	my ($name, $years, $file, $filebase);
	my ($father_id, $father_name, $father_years, $father_file, $father);
	my ($mother_id, $mother_name, $mother_years, $mother_file, $mother);
	my (@sibling_id, @siblings, @sib_files, $n_sibs);
    my (@sibs_other_rel, @sibs_other_file, @sibs_other, @sibs_other_id);
	my (@child_id, @children, @child_files, $n_children, $children_priv);
	my (@child_parent, @child_parent_id, @child_parent_rel, @child_parent_file);
	my ($n_events, @e_date, @e_type, @e_spouse, @e_spousefile, @e_info, @e_source);
	my ($n_transcripts, @transcripts);
	my ($xxid, $xxname, $xxyears);
	my (@filelines);
	my ($mark, $date, $event, $spouse, $spouse_file, $info, $source);

	$name = DhG_GetName($id);
	$years = DhG_GetYearRange($id);
	$file = DhG_GetFilename($id);
	$filebase = DhG_GetFilebase($id);

	($father_id, $father_name) = DhG_GetFather($id);
	if ( defined $father_id )
	{
		$father_years = DhG_GetYearRange($father_id);
		$father_file = DhG_GetFilebase($father_id);
	}
	else
	{
		$father_years = "";
		$father_file = "";
	}
	if ( defined $father_name )
	{
		$father = "$father_name";
		$father .= " ($father_years)" if ( $father_years ne "" );
	}
	else
	{
		$father = "";
	}

	($mother_id, $mother_name) = DhG_GetMother($id);
	if ( defined $mother_id )
	{
		$mother_years = DhG_GetYearRange($mother_id);
		$mother_file = DhG_GetFilebase($mother_id);
	}
	else
	{
		$mother_years = "";
		$mother_file = "";
	}
	if ( defined $mother_name )
	{
		$mother = "$mother_name";
		$mother .= " ($mother_years)" if ( $mother_years ne "" );

	}
	else
	{
		$mother = "";
	}

	@sibling_id = DhG_GetSiblings($id);		# Ordered by DoB
	$n_sibs = 0;
	@siblings = ();
	@sib_files = ();
    @sibs_other_rel = ();
	@sibs_other_file = ();
	@sibs_other = ();
	@sibs_other_id = ();

	foreach $xxid ( @sibling_id )
	{
		if ( $xxid == $id )
		{
			$siblings[$n_sibs] = "$name (self)";
			$sib_files[$n_sibs] = "";
		}
		else
		{
			$siblings[$n_sibs] = DhG_GetName($xxid);
			$xxyears = DhG_GetYearRange($xxid);
			$siblings[$n_sibs] .= " ($xxyears)" if ( defined $xxyears );
			$sib_files[$n_sibs] = DhG_GetFilebase($xxid);

			my ($xxparent_id, $xxparent) = DhG_GetFather($xxid);
			if ( defined $father_id && defined $xxparent_id && $xxparent_id == $father_id )
			{
				# Same father. Different mother?
				($xxparent_id, $xxparent) = DhG_GetMother($xxid);
				if ( defined $mother_id && defined $xxparent_id && $xxparent_id == $mother_id )
				{
					# Same father and mother
				}
				else
				{
					# Different mother
					$sibs_other_rel[$n_sibs] = "mother";
				}
			}
			else
			{
				# Different father
				$sibs_other_rel[$n_sibs] = "father";
			}
	
			if ( defined $sibs_other_rel[$n_sibs] )
			{
				$sibs_other[$n_sibs] = $xxparent;
				$sibs_other_id[$n_sibs] = $xxparent_id;
				$sibs_other_file[$n_sibs] = DhG_GetFilebase($xxparent_id);
			}
		}

		$n_sibs++;
	}

	@child_id = DhG_GetOffspring($id);		# Ordered by DoB
	$n_children = 0;
	@children = ();
	@child_files = ();
	@child_parent = ();
	@child_parent_id = ();
	@child_parent_rel = ();
	@child_parent_file = ();
	foreach $xxid ( @child_id )
	{
		$children[$n_children] = DhG_GetName($xxid);
		$xxyears = DhG_GetYearRange($xxid);
		$children[$n_children] .= " ($xxyears)" if ( defined $xxyears );
		$child_files[$n_children] = DhG_GetFilebase($xxid);

		my ($xxparent_id, $xxparent) = DhG_GetFather($xxid);
		if ( defined $xxparent_id && $xxparent_id == $id )
		{
			($xxparent_id, $xxparent) = DhG_GetMother($xxid);
			$child_parent_rel[$n_children] = "mother";
		}
		else
		{
			# Different father
			$child_parent_rel[$n_children] = "father";
		}
		$child_parent[$n_children] = $xxparent;
		$child_parent_id[$n_children] = $xxparent_id;
		$child_parent_file[$n_children] = DhG_GetFilebase($xxparent_id);

		$n_children++;
	}
	$children_priv = 0;
	if ( defined $privacy && $privacy eq "public" )
	{
		if ( ($n_children > 0) && DhG_IsPrivate($child_id[0]) )
		{
			$children_priv = 1;
		}
	}

	# Read all lines from file into array
	@filelines = DhG_LoadCard_All($file);

	# Work out where the events start.
	$mark = DhG_LoadCard_FindFirstEvent(\@filelines);

	$n_events = 0;
	$n_transcripts = 0;
	@e_date = ();
	@e_type = ();
	@e_spouse = ();
	@e_spousefile = ();
	@e_info = ();
	@e_source = ();
	@transcripts = ();

	while ( $mark > 0 )
	{
		# Get 4 parts of event and marker for next (-1 ==> end).
		($mark, $date, $event, $spouse, $spouse_file, $info, $source, $n_transcripts)
				= DhG_LoadCard_GetNextEvent($mark, \@filelines, $mode, $n_transcripts, \@transcripts);

		# Append each of the 4 parts of the event to the its respective array.
		push(@e_date, $date);
		push(@e_type, $event);
		push(@e_spouse, $spouse);
		push(@e_spousefile, $spouse_file);
		push(@e_info, $info);
		push(@e_source, $source);

		$n_events++;
	}

	# Convert all strings to XML-friendly format.
	if ( $mode eq "html" )
	{
		($name, $years, $father, $father_file, $mother, $mother_file) =
											DhG_XMLify($name, $years, $father, $father_file, $mother, $mother_file);
		@siblings = DhG_XMLify(@siblings);
		@sib_files = DhG_XMLify(@sib_files);
		@sibs_other = DhG_XMLify(@sibs_other);
		@sibs_other_rel = DhG_XMLify(@sibs_other_rel);
		@sibs_other_file = DhG_XMLify(@sibs_other_file);
		@children = DhG_XMLify(@children);
		@child_files = DhG_XMLify(@child_files);
		@child_parent = DhG_XMLify(@child_parent);
		@child_parent_rel = DhG_XMLify(@child_parent_rel);
		@child_parent_file = DhG_XMLify(@child_parent_file);
		# Event data is not converted here because it may contain XML/HTML
		# Transcript data is not converted here because it may be literal
	}

	my $last_update = strftime("%Y-%m-%d %H:%M GMT", gmtime());

	# Now we've got all the stuff, put it in the vars hash for the template.
	my $template_vars =
	{
		name			=> $name,					# Name of person
		id				=> $id,						# Id of person
		year_range		=> $years,					# (DoB-DoD)
		father			=> $father,					# Name of father
		father_id		=> $father_id,				# Id of father
		father_file		=> $father_file,			# Filename of father
		mother			=> $mother,					# Name of mother
		mother_id		=> $mother_id,				# Id of mother
		mother_file		=> $mother_file,			# Filename of mother
		n_sibs			=> $n_sibs,					# No. of siblings
		sibs			=> \@siblings,				# Names of siblings
		sibs_id			=> \@sibling_id,			# Ids of siblings
		sibs_file		=> \@sib_files,				# Filenames of siblings
		sibs_other		=> \@sibs_other,			# Other parent of siblings (if different)
		sibs_other_id	=> \@sibs_other_id,			# Id of other parent of siblings (if different)
		sibs_other_rel 	=> \@sibs_other_rel,		# Relationship of other parent (mother/father)
		sibs_other_file => \@sibs_other_file,		# File of other parent
		n_children		=> $n_children,				# No. of children
		children		=> \@children,				# Names of children
		children_id		=> \@child_id,				# Ids of children
		child_file		=> \@child_files,			# Filenames of children
		c_parent		=> \@child_parent,			# Other parent of children
		c_parent_id		=> \@child_parent_id,		# Id of other parent of children
		c_parent_rel	=> \@child_parent_rel,		# Relationship of other parent (mother/father)
		c_parent_file	=> \@child_parent_file,		# Filenames of other parent
		children_priv	=> $children_priv,			# TRUE if children are private
		n_events		=> $n_events,				# No of events
		e_date			=> \@e_date,				# Dates of events
		e_type			=> \@e_type,				# Types of events
		e_spouse		=> \@e_spouse,				# Names of spouses for "Marriage" events
		e_spousefile	=> \@e_spousefile,			# Filenames of spouses
		e_info			=> \@e_info,				# More info from event
		e_source		=> \@e_source,				# Sources for event
		n_transcripts	=> $n_transcripts,			# No of transcripts
		transcript		=> \@transcripts,			# Array of transcripts
		last_update		=> $last_update				# Date/time of last update
	};

	return $template_vars;
}

# DhG_GetDescendantTreeTemplateVars() - fill a hash with the variables for a "descendant tree", and return the hash
sub DhG_AppendDescendantTree;	# Forward

sub DhG_GetDescendantTreeTemplateVars
{
	my ($id, $privacy) = @_;
	my ($name, $years, $nlines);
	my @a_level = ();
	my @a_name = ();
	my @a_file = ();
	my @a_spname = ();
	my @a_spfile = ();

	# Get the name and the birth and death dates.
	$name = DhG_GetName($id);
	$years = DhG_GetYearRange($id);

	$nlines = DhG_AppendDescendantTree($id, 0, $privacy, 0,
													\@a_level, \@a_name, \@a_file, \@a_spname, \@a_spfile);

	my $last_update = strftime("%Y-%m-%d %H:%M GMT", gmtime());

	my $template_vars =
	{
		title_name		=> $name,					# Name of person
		title_years		=> $years,					# (DoB-DoD)
		nlines			=> $nlines,					# No of lines in the descendant tree
		level			=> \@a_level,				# For each line: level
		name			=> \@a_name,				# For each line: name of person
		file			=> \@a_file,				# For each line: base filename (for link)
		spouse			=> \@a_spname,				# For each line: spouse/partner
		spouse_file		=> \@a_spfile,				# For each line: base filename for spouse/partner
		last_update		=> $last_update				# Date/time of last update
	};

	return $template_vars;
}

sub DhG_AppendDescendantTree
{
	# The a_* variables are references to arrays.
	my ($id, $level, $privacy, $index, $a_level, $a_name, $a_file, $a_spname, $a_spfile) = @_;

	my ($name, $years, $printname, $file);
	my %partner_by_date;
	my %partner;
	my @spouses = ();
	my @sp_dates = ();
	my @sp_ids = ();
	my %children;
	my $c_id;
	my $n_spouses;

	# Get the name and the birth and death dates.
	$name = DhG_GetName($id);
	$years = DhG_GetYearRange($id);

	print STDOUT "DBG: AppendDescendantTree $name $id\n" if ( $DhG_DebugLevel >= 30 );

	# Construct name for output.
	$printname = $name;
	$printname .= " ($years)" if ( defined $years && $years ne "" );

	# Base filename
	$file = DhG_GetFilebase($id);

	# Now find a list of all the partners. Start with the marriages...
	if ( defined $DhG_Marriage_Names[$id] )
	{
		# Convert names, dates and ids into arrays. Remember: the id might be "-"!
		@spouses = split /\|/,$DhG_Marriage_Names[$id];
		@sp_dates = split /\|/,$DhG_Marriage_Dates[$id];
		@sp_ids = split /\|/,$DhG_Marriage_Ids[$id];

		$n_spouses = 0;

		while ( defined $spouses[$n_spouses] )
		{
			
			$partner_by_date{$sp_dates[$n_spouses]} = $n_spouses;
			$partner{$spouses[$n_spouses]} = $n_spouses;

			$n_spouses++;
		}
	}

	# Now see if there are children with other partners
	my $private = 0;
	foreach $c_id ( 1 .. $#DhG_Name )
	{
		if ( defined $DhG_Name[$c_id] )
		{
			my ($p_name, $p_id);
			my $is_child;

			if ( defined $DhG_Father_Id[$c_id] && $DhG_Father_Id[$c_id] == $id )
			{
				# Our person is father of this child.
				$p_name = $DhG_Mother_Name[$c_id];
				$p_id = $DhG_Mother_Id[$c_id];
				$is_child = 1;
#				print STDERR "Father. Mother is $p_name\n";
			}
			elsif ( defined $DhG_Mother_Id[$c_id] && $DhG_Mother_Id[$c_id] == $id )
			{
				# Our person is mother of this child.
				$p_name = $DhG_Father_Name[$c_id];
				$p_id = $DhG_Father_Id[$c_id];
				$is_child = 1;
#				print STDERR "Mother. Father is $p_name\n";
			}
			else
			{
				# Not interested in this child
				$is_child = 0;
			}

			if ( $is_child )
			{
				# This is a child of our person.

				# Record the child along with (modified) DoB (don't format this one!)
				my $c_dob = $DhG_Birth_Date[$c_id];
				if ( !defined $c_dob )
				{
					$c_dob = "0000-00-00";
				}

				# Add underscores to DoB until it becomes unique
				while ( defined $children{$c_dob} )
				{
					$c_dob .= _;
				}

				$children{$c_dob} = $c_id;

				# This is a child of our person. Record the other parent as a partner.
				if ( !defined $p_name )
				{
					$p_name = "unknown";
				}

				# Only add other parent as partner if not already there ---
				# we don't want to overwrite a marriage date!
				if ( defined $partner{$p_name} )
				{
				}
				else
				{
					# Ensure a "-" is used for an undefined id here.
					if ( !defined $p_id )
					{
						$p_id = "-";
					}

					push @sp_ids, $p_id;
					push @spouses, $p_name;
					push @sp_dates, $c_dob;		# Use child's DoB for "marriage" date

#						print STDERR "Push $p_name $p_id $c_dob\n";

					$partner_by_date{$c_dob} = $n_spouses;
					$partner{$p_name} = $n_spouses;
					$n_spouses++;
				}
			}
		}
	}

	# Now we have a list of partners and a list of children.
	my $partnerdate;
	my $npartner = 0;
	my $partner_idx;
	foreach $partnerdate (sort keys %partner_by_date)
	{
		$npartner++;
		$partner_idx = $partner_by_date{$partnerdate};

		my ($p_name, $p_id, $p_years, $p_printname, $p_file);
		$p_name = $spouses[$partner_idx];
		$p_id = $sp_ids[$partner_idx];
#		print STDERR "$partner_idx $p_name [$p_id] $partnerdate\n";

		if ( $p_id eq "-" )
		{
			$p_years = undef;
			$p_file = undef;
		}
		else
		{
			$p_years = DhG_GetYearRange($p_id);
			$p_file = DhG_GetFilebase($p_id);
		}
		$p_printname = $p_name;
		$p_printname .= " ($p_years)" if ( defined $p_years && $p_years ne "" );

		# Append the person and spouse to the arrays.
		${$a_level}[$index] = $level;
		${$a_name}[$index] = $printname;
		${$a_file}[$index] = $file;
		${$a_spname}[$index] = $p_printname;
		${$a_spfile}[$index] = $p_file;
		$index++;

		# Multiple lines for same person: use "see above".
		$printname = "$name (see above)";

		# How many children?
		my $n_children = 0;
		foreach $c_key (sort keys %children)
		{
			$c_id = $children{$c_key};
			if ( ( defined $DhG_Father_Name[$c_id] && $DhG_Father_Name[$c_id] eq $p_name ) ||
				 ( defined $DhG_Mother_Name[$c_id] && $DhG_Mother_Name[$c_id] eq $p_name ) )
			{
				$n_children++;
			}
		}

		if ( $n_children > 0 )
		{
			my $c_key;
			foreach $c_key (sort keys %children)
			{
				$c_id = $children{$c_key};

				if ( $privacy eq "all" || !DhG_IsPrivate($c_id) )
				{
					if ( ( defined $DhG_Father_Name[$c_id] && $DhG_Father_Name[$c_id] eq $p_name ) ||
						 ( defined $DhG_Mother_Name[$c_id] && $DhG_Mother_Name[$c_id] eq $p_name ) )
					{
						$index = DhG_AppendDescendantTree($c_id, $level+1, $privacy, $index,
																$a_level, $a_name, $a_file, $a_spname, $a_spfile);
					}
				}
				else
				{
					# Child is private. Due to privacy rules, this is the first child!
					# Add a "private" line and break out. The template knows what to do.
					${$a_level}[$index] = $level+1;
					${$a_name}[$index] = "Private";
					${$a_file}[$index] = "";
					${$a_spname}[$index] = "";
					${$a_spfile}[$index] = "";
					$index++;

					last;
				}
			}
		}
	}

	if ( $npartner == 0 )
	{
		# No partners/children found. Just append the person to the arrays. Spouse fields are blank.
		${$a_level}[$index] = $level;
		${$a_name}[$index] = $printname;
		${$a_file}[$index] = $file;
		${$a_spname}[$index] = "";
		${$a_spfile}[$index] = "";
		$index++;
	}

	return $index;
}

# DhG_GetAhnentafelTemplateVars() - fill a hash with the variables for an ahnentafel and return the hash
sub DhG_GetAhentafel;	# Forward

sub DhG_GetAhnentafelTemplateVars
{
	my ($id) = @_;
	my ($name, $years, $n_generations, $limit);
	my @a_id = ();
	my @a_name = ();
	my @a_forename = ();
	my @a_surname = ();
	my @a_daterange = ();
	my @a_file = ();

	# Get the name and the birth and death dates.
	$name = DhG_GetName($id);
	$years = DhG_GetYearRange($id);

	$n_generations = DhG_GetAhnentafel($id, \@a_id, \@a_name, \@a_forename, \@a_surname, \@a_daterange, \@a_file);
	$limit = 2 ** $n_generations;

	my $last_update = strftime("%Y-%m-%d %H:%M GMT", gmtime());

	my $template_vars =
	{
		title_name		=> $name,					# Name of person
		title_years		=> $years,					# (DoB-DoD)
		n_generations	=> $n_generations,			# No of generations (columns)
		limit			=> $limit,					# Limit index for last column
		id				=> \@a_id,					# For each person: id
		forename		=> \@a_forename,			# For each person: forename of person
		surname			=> \@a_surname,				# For each person: surname of person
		daterange		=> \@a_daterange,			# For each person: DoB-DoD of person
		file			=> \@a_file,				# For each person: base filename (for link)
		last_update		=> $last_update				# Date/time of last update
	};

	return $template_vars;
}

sub DhG_GetAhnentafel
{
	# The a_* variables are references to arrays.
	my ($id, $a_id, $a_name, $a_forename, $a_surname, $a_daterange, $a_file) = @_;
	my ($n_generations, $start, $end, $n_found, $i, $pid);
	my ($father, $mother);
	my ($name, $forename, $surname);


	# Force the first generation...
	$name = $DhG_Name[$id];
	($forename, $surname) = DhG_SplitName($name);

	${$a_id}[1] = $id;
	${$a_name}[1] = $name;
	${$a_forename}[1] = $forename;
	${$a_surname}[1] = $surname;
	${$a_daterange}[1] = DhG_GetYearRange($id);
	${$a_file}[1] = DhG_GetFilebase($id);

	print STDOUT "DBG: Ahnentafel $insert: $name\n" if ( $DhG_DebugLevel >= 0 );

	$n_found = 1;
	$insert = 2;
	$n_generations = 0;
	$start = 1;
	$end = 2;

	while ( $n_found > 0 )
	{
		$n_generations++;
		$n_found = 0;

		print STDOUT "DBG: n_generations = $n_generations, start = $start, end = $end\n" if ( $DhG_DebugLevel >= 0 );

		for ( $i = $start; $i < $end; $i++ )
		{
			$pid = ${$a_id}[$i];

			if ( defined $pid )
			{
				$father = $DhG_Father_Id[$pid];
				$mother = $DhG_Mother_Id[$pid];

				if ( defined $father )
				{
					$name = $DhG_Name[$father];
					($forename, $surname) = DhG_SplitName($name);
					$forename = undef if ( $forename eq "_" );
					$surname = undef if ( $surname eq "_" );
	
					${$a_id}[$insert] = $father;
					${$a_name}[$insert] = $name;
					${$a_forename}[$insert] = $forename;
					${$a_surname}[$insert] = $surname;
					${$a_daterange}[$insert] = DhG_GetYearRange($father);
					${$a_file}[$insert] = DhG_GetFilebase($father);

					print STDOUT "DBG: Ahnentafel $insert: $name\n" if ( $DhG_DebugLevel >= 0 );

					$n_found++;
				}
				$insert++;

				if ( defined $mother )
				{
					$name = $DhG_Name[$mother];
					($forename, $surname) = DhG_SplitName($name);
					$forename = undef if ( $forename eq "_" );
					$surname = undef if ( $surname eq "_" );

					${$a_id}[$insert] = $mother;
					${$a_name}[$insert] = $name;
					${$a_forename}[$insert] = $forename;
					${$a_surname}[$insert] = $surname;
					${$a_daterange}[$insert] = DhG_GetYearRange($mother);
					${$a_file}[$insert] = DhG_GetFilebase($mother);

					print STDOUT "DBG: Ahnentafel $insert: $name\n" if ( $DhG_DebugLevel >= 0 );

					$n_found++;
				}
				$insert++;
			}
			else
			{
				# Phantom parents
				$insert += 2;
			}
		}

		$start = $end;
		$end = $insert;
	}

	return $n_generations;
}

# DhG_GetSurnameIndexTemplateVars() - creates template variables for the surname index
sub DhG_GetSurnameIndexTemplateVars
{
	my ($privacy, $format) = @_;
	my %sorter = ();
	my $n_letters = 0;
	my @index_letter = ();
	my @n_surnames = ();
	my @surnames = ();
	my @n_people = ();
	my @person_name = ();
	my @person_fname = ();
	my $id;
	my $key;
	my ($p, $s, $l);
	my ($curr_letter, $curr_sname);
	my ($surname, $forename, $letter);

	# First, build a hash containing a key,id pair for each person to index.
	foreach $id ( 1 .. $#DhG_Name )
	{
		# Only defined names (ignore holes)
		if ( defined $DhG_Name[$id] )
		{
			# Ignore private cards unless generating a private index.
			if ( DhG_IsPrivate($id) && $privacy eq "public" )
			{
			}
			else
			{
				$name = $DhG_Name[$id];
				($forename, $surname) = DhG_SplitName($name);
				$forename = "unknown" if ( $forename eq "_" );
				$surname = "unknown" if ( $surname eq "_" );
				$key = "$surname $forename $id";
				$key =~ s/\s//g;
				$sorter{$key} = $id;
			}
		}
	}

	# Now run through the sorted hash and fill in the arrays
	$p = 0;
	$s = -1;
	$l = -1;
	$curr_letter = "";
	$curr_sname = "";

	foreach $key (sort keys %sorter)
	{
		$id = $sorter{$key};
		$name = $DhG_Name[$id];

		# Put the name and filename into the main array
		$person_name[$p] = $name;
		my $r = DhG_GetYearRange($id);
		$person_name[$p] .= " ($r)" if ( defined $r && $r ne "" );
		$person_fname[$p] = DhG_GetFilebaseOnly($id);
		$person_fnamewithdir[$p] = DhG_GetFilebase($id);

		print "Index entry: $person_name[$p]  [$id]\n" if ($DhG_DebugLevel > 0 );
		
		($forename, $surname) = DhG_SplitName($name);
		$forename = "unknown" if ( $forename eq "_" );
		$surname = "unknown" if ( $surname eq "_" );

		# Change of surname?
		if ( $surname eq $curr_sname )
		{
			# Same as last one - increment the counter
			$n_people[$s]++;
		}
		else
		{
			$s++;
			$n_people[$s] = 1;
			$surnames[$s] = $surname;
			$curr_sname = $surname;

			# Change of letter?
			($letter) = $surname =~ m{^(.)};
			if ( $letter eq $curr_letter )
			{
				# Same as last one - increment the counter
				$n_surnames[$l]++;
			}
			else
			{
				$l++;
				$n_surnames[$l] = 1;
				$index_letter[$l] = $letter;
				$curr_letter = $letter;
				$n_letters++;
			}
		}
		$p++;
	}

	if ( $DhG_DebugLevel > 0 )
	{
		$s = 0;
		print "Summary:\n";
		foreach $l ( 0 .. $#index_letter )
		{
			print "= $index_letter[$l] =\n";
			print "$surnames[$s]";
			$s++;
			for ( my $i = 1; $i < $n_surnames[$l]; $i++ )
			{
				print ", $surnames[$s]";
				$s++;
			}
			print "\n";
		}
	}

	my $last_update = strftime("%Y-%m-%d %H:%M GMT", gmtime());

	my $template_vars =
	{
		n_letters		=> $n_letters,				# Number of first letters 
		index_letter	=> \@index_letter,			# Array of first letter of surname
		n_surnames		=> \@n_surnames,			# Array of no. of surnames for each letter
		surnames		=> \@surnames,				# Array of all surnames
		n_people		=> \@n_people,				# Array of no. of people for each surname
		person_name		=> \@person_name,			# For each person: the name to display
		person_fname	=> \@person_fname,			# For each person: base filename
		person_fnamewithdir	=> \@person_fnamewithdir,	# For each person: base filename including subdirectory
		last_update		=> $last_update				# Date/time of last update
	};

	return $template_vars;
}

#======================================================================================
# FROM HERE NEEDS REFACTORING
#======================================================================================

# DhG_GetUniq() gets the unique person specified by the string.
# If the person is not unique a list of all the matches is printed and the return value is 0.
sub DhG_GetUniq
{
	my ($param) = @_;
	my $result = 0;

	if ( $param =~ m{^[1-9][0-9]*$} )
	{
		if ( defined $DhG_Name[$param] )
		{
			$result = $param;
		}
		else
		{
			print "There is nobody with id \"$param\" in the database\n";
		}
	}
	else
	{
		my ($name, $uniq) = DhG_ParseName($param);

		if ( defined $uniq )
		{
			# Might want to be more flexible than an exact match here. Let's see.
			if ( $name eq $DhG_Name[$uniq] )
			{
				$result = $uniq;
			}
			else
			{
				print "The person with id \"$uniq\" is called \"$DhG_Name[$uniq]\", not \"$name\"\n";
			}
		}
		else
		{
			my @matching = DhG_GetMatchingPersons($name);

			if ( @matching == 0 )
			{
				print "There is nobody called \"$name\" in the database\n";
			}
			elsif ( @matching == 1 )
			{
				$result = $matching[0];
			}
			else
			{
				print "More than one match for \"$name\":\n";
				DhG_PrintPersonList(@matching);
			}
		}
	}

	return $result;
}

# DhG_SetRelativesPrivate - set the calculated privacy flag of all partners and siblings of a person
sub DhG_SetRelativesPrivate
{
	my ($id, $priv) = @_;
	my (@sibs, $sib);
	my (@partners, $partner);
	my $localdbglvl = 999;

	print STDOUT "DBG: DhG_SetRelativesPrivate($id, $priv) ($DhG_Name[$id])" if ( $DhG_DebugLevel >= $localdbglvl );

	@partners = DhG_GetPartners($id);
	foreach $partner (@partners)
	{
		print STDOUT " p$partner" if ( $DhG_DebugLevel >= $localdbglvl );
		if ( !defined $DhG_Private_Calc[$partner] )
		{
			$DhG_Private_Calc[$partner] = $priv;
			print STDOUT "\n" if ( $DhG_DebugLevel >= $localdbglvl );
			DhG_SetRelativesPrivate($partner, $priv);
			print STDOUT "DBG: DhG_SetRelativesPrivate($id, $priv) ($DhG_Name[$id]) continued"
					if ( $DhG_DebugLevel >= $localdbglvl );
		}
	}

	@sibs = DhG_GetSiblings($id);
	foreach $sib (@sibs)
	{
		print STDOUT " s$sib" if ( $DhG_DebugLevel >= $localdbglvl );

		if ( !defined $DhG_Private_Calc[$sib] )
		{
			$DhG_Private_Calc[$sib] = $priv;
			print STDOUT "\n" if ( $DhG_DebugLevel >= $localdbglvl );
			DhG_SetRelativesPrivate($sib, $priv);
			print STDOUT "DBG: DhG_SetRelativesPrivate($id, $priv) ($DhG_Name[$id]) continued"
					if ( $DhG_DebugLevel >= $localdbglvl );
		}
	}

	print STDOUT "\n" if ( $DhG_DebugLevel >= $localdbglvl );
}


# DhG_AnalyseRelations() - calculate privacy flags, build name-->gender mapping.
sub DhG_AnalyseRelations
{
	my ($index, $id, $parent);
	my @spouse_names;
	my $i;
	my ($sp_id, $sp_name, $sp_uniq);

	foreach $id ( 1 .. $#DhG_Name )
	{
		if ( defined $DhG_Name[$id] )
		{
			# Fill name --> gender mapping based on first name only.
			if ( defined $DhG_Gender[$id] )
			{
				my @person_names = split /\s+/, $DhG_Name[$id];

				if ( defined $person_names[0] )
				{
					if ( defined $DhG_NameGenderMap{$person_names[0]} )
					{
						if ( $DhG_NameGenderMap{$person_names[0]} ne $DhG_Gender[$id] )
						{
							$DhG_NameGenderMap{$person_names[0]} = "";
							print STDERR "$person_names[0] could be a M or F name\n" if ( $DhG_DebugLevel >= 0 );
						}
					}
					else
					{
						$DhG_NameGenderMap{$person_names[0]} = $DhG_Gender[$id];
						print STDERR "$person_names[0] is a $DhG_Gender[$id] name\n" if ( $DhG_DebugLevel >= 100 );
					}
				}
			}

			# Calculate privacy
			if ( DhG_IsAlive($id) || (defined $DhG_Private[$id] && $DhG_Private[$id] == 1) )
			{
				if ( !defined $DhG_Private_Calc[$id] )
				{
					$DhG_Private_Calc[$id] = 1;
					DhG_SetRelativesPrivate($id, 1);
				}
			}
		}
	}
}

# DhG_FindPerson() returns the id of the person whose (name, uniq) is specified.
sub DhG_FindPerson
{
	my ($name, $uniq) = @_;
	my ($id, $index);

	foreach $id ( 1 .. $#DhG_Name )
	{
		if ( defined $DhG_Name[$id] )
		{
			if ( $DhG_Name[$id] eq $name )
			{
				# Same name: is there a uniqueness qualifier?
				if ( !defined $uniq || $id eq $uniq )
				{
					return $id;
				}
			}
		}
	}

	return undef;
}

# DhG_Dump() - dumps the database. Used for testing
sub DhG_Dump
{
	my ($id, $index);
	my ($father, $mother, $name, $dob, $dod);

	foreach $id ( 1 .. $#DhG_Name )
	{
		if ( defined $DhG_Name[$id] )
		{
			$name = $DhG_Name[$id];

			$father = $DhG_Father_Name[$id];
			if ( defined $father )
			{
				if ( defined $DhG_Father_Id[$id] )
				{
					$father .= " [$DhG_Father_Id[$id]]";
				}
			}
			else
			{
				$father = "?";
			}

			$mother = $DhG_Mother_Name[$id];
			if ( defined $mother )
			{
				if ( defined $DhG_Mother_Id[$id] )
				{
					$mother .= " [$DhG_Mother_Id[$id]]";
				}
			}
			else
			{
				$mother = "?";
			}

			$dob = DhG_FormatDate($DhG_Birth_Date[$id], "?");
			$dod = DhG_FormatDate($DhG_Death_Date[$id], "");

			print "$id : $name ($dob - $dod) : $father + $mother\n";
		}
	}
}

# DhG_PrintAncestorTree() - prints the entire ancestor tree of the specified person
sub DhG_PrintAncestors;	# Forward
sub DhG_PrintAncestorTree
{
	my ($uniq) = @_;

	my $name = $DhG_Name[$uniq];

	print "\n";
	print "Ancestors of $name\n";
	print "\n";
	DhG_PrintAncestors($uniq, "   ", "");
	print "\n";
}

sub DhG_PrintAncestors
{
	my ($id, $tag, $indent) = @_;
	my ($name, $personinfo);
	my ($father, $fid);
	my ($mother, $mid);

	$name = $DhG_Name[$id];
	$personinfo = DhG_GetPersonInfoLine($id);

	print "$indent$tag$personinfo\n";

	$father = $DhG_Father_Name[$id];
	if ( defined $father )
	{
		$fid = $DhG_Father_Id[$id];
		if ( defined $fid )
		{
			DhG_PrintAncestors($fid, "f: ", "$indent   ");
		}
		else
		{
			print("$indent   f: $father\n");
		}
	}

	$mother = $DhG_Mother_Name[$id];
	if ( defined $mother )
	{
		$mid = $DhG_Mother_Id[$id];
		if ( defined $mid )
		{
			DhG_PrintAncestors($mid, "m: ", "$indent   ");
		}
		else
		{
			print("$indent   m: $mother\n");
		}
	}
}

# DhG_GetMatchingPersons() returns a list of all people whose names match the search string
sub DhG_GetMatchingPersons
{
	my ($txt) = @_;
	my @hits = ();
	my $nhits = 0;
	my @tokens = split(/\s+/, DhG_Trim($txt));
	my ($matches,$tokidx);
	my ($index, $id, $name);

	printf STDERR "Looking for $tokens[0], $tokens[1], ...\n" if ( $DhG_DebugLevel > 100 );

	foreach $id ( 1 .. $#DhG_Name )
	{
		if ( defined $DhG_Name[$id] )
		{
			$name = $DhG_Name[$id];
			if ( defined $name )
			{
				printf STDERR "Examining $name\n" if ( $DhG_DebugLevel > 100 );

				$matches = 0;
				for ( $tokidx = 0; defined $tokens[$tokidx]; $tokidx++ )
				{
					if ( $name =~ m{$tokens[$tokidx]}i )
					{
						$matches++;
					}
				}

				if ( $matches == $tokidx )
				{
					$hits[$nhits] = $id;
					$nhits++;
				}
			}
		}
	}

	return @hits;
}


# DhG_PrintPersonList() prints the given list of people
sub DhG_PrintPersonList
{
	my @list = @_;
	my $i;

	for ( $i = 0; $i < @list; $i++ )
	{
		my $id = $list[$i];
		my $personinfo = DhG_GetPersonInfoLine($id);
		print "$personinfo\n";
	}
}

# DhG_Search() prints all the people whose names match the search string
sub DhG_Search
{
	my ($txt) = @_;
	my @list = DhG_GetMatchingPersons($txt);
	if ( @list == 0 )
	{
		print "No-one matching \"$txt\" found in the database\n";
	}
	else
	{
		DhG_PrintPersonList(@list);
	}

	return undef;
}

# DhG_GetPersonInfoLine() - returns info-line (name, id, dob, dod) for person
sub DhG_GetPersonInfoLine
{
	my ($name, $uniq) = @_;
	my $id = undef;
	my ($dob, $dod);
	my $infoline = "Unknown";

	if ( $name =~ m{^([0-9])} )
	{
		# ID is given. If person exists, use that person, otherwise return "Unknown"
		$id = $name;

		if ( defined $DhG_Name[$id] )
		{
			$name = $DhG_Name[$id];
		}
		else
		{
			$id = undef;
		}
	}
	else
	{
		# Name/Uniq give, Find the person. If not found, return "Name [Uniq]"
		$id = DhG_FindPerson($name, $uniq);

		if ( !defined $id )
		{
			$infoline = "$name";
			$infoline .= " [$uniq]" if ( defined $uniq && $uniq ne "" );
		}
	}

	if ( defined $id )
	{
		# This person exists in the database
		$dob = DhG_FormatDate($DhG_Birth_Date[$id], "?");
		$dod = DhG_FormatDate($DhG_Death_Date[$id], "");

		$infoline = "$name [$id]  ($dob - $dod)";
	}

	return $infoline;
}

# DhG_SplitName() - returns (forename, surname) from name
sub DhG_SplitName
{
	my ($name) = @_;
	my ($forename, $surname) = $name =~ m{^(.*)\s+([^\s]+)$};

	if ( defined $surname )
	{
		if ( !defined $forename )
		{
			$forename = "";
		}
	}
	else
	{
		$surname = $name;
		$forename = "";
	}

	return ($forename, $surname);
}

# DhG_GetDebugLevel() returns the debug level
sub DhG_GetDebugLevel
{
	return $DhG_DebugLevel;
}

# DhG_GetTemplateDir() returns the template directory 
sub DhG_GetTemplateDir
{
	return $DhG_TemplateDir;
}

# Function for testing stuff
sub DhG_Test
{
	my ($id) = @_;

	if ( DhG_IsPrivate($id) )
	{
		print STDOUT "Test: DhG_IsPrivate($id) returned TRUE\n";
	}
	else
	{
		print STDOUT "Test: DhG_IsPrivate($id) returned FALSE\n";
	}
}

# DhG_EditCard() - edits the card file for the specified person
sub DhG_EditCard
{
	my ($uniq) = @_;
	my ($fileno, $filename, $cmd);

	$fileno = $DhG_Fileno[$uniq];
	if ( defined $fileno )
	{
		$filename = $DhG_FileList[$fileno];
		if ( defined $filename )
		{
			if ( -r $filename && -w $filename )
			{
				DhG_EditFile($filename);
			}
			else
			{
				print STDERR "$filename : Insufficient access rights.\n";
			}
		}
		else
		{
			print STDERR "File name for give person is not defined.\n";
		}
	}
	else
	{
		print STDERR "File number for give person is not defined.\n";
	}
}

# DhG_EditFile() - edits an arbitrary file
sub DhG_EditFile
{
	my ($filename) = @_;

	print STDERR "Editing $filename...\n";
	if ( defined $ENV{"VISUAL"} )
	{
		$cmd = $ENV{"VISUAL"};
	}
	elsif ( defined $ENV{"EDITOR"} )
	{
		$cmd = $ENV{"EDITOR"};
	}
	else
	{
		$cmd = "vi";
	}
	$cmd = $cmd." ".$filename;
	system $cmd;
}

# DhG_ReadFileIntoVariable() - reads an entire file into a variable
sub DhG_ReadFileIntoVariable
{
	my ($fn) = @_;
	my $fc = undef;
	my $f;

	if ( -r $fn )
	{
		open $f, "<$fn";
		$fc = join("", <$f>);
		close $f;
	}

	return $fc;
}

# DhG_ReadTranscriptFile() - finds a transcript file then reads it into a variable
sub DhG_ReadTranscriptFile
{
	my ($fn) = @_;

	if ( ! -d $DhG_TextBase )
	{
		print STDERR "Transcript directory ($DhG_TextBase) does not exist.\n";
		return undef;
	}

	my @fl = DhFL_FileList($DhG_TextBase);
	my $i;

	for ($i = 0; $i <= $#fl; $i++)
	{
		if ( $fl[$i] =~ m{.*/$fn$} )
		{
			return DhG_ReadFileIntoVariable($fl[$i]);
		}
	}

	return undef;
}
