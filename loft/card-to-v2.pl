#!/usr/bin/perl -w
#
# Converts v1 card files to v2
#
# (c) 2013 David Haworth
#
# $Id$

$argno = 0;
$filename = "foo";

$DBG = 0;

$name = "foo";
$uniq = "foo";
$gender = "foo";
$nick = "foo";
$father = "foo";
$mother = "foo";
$version = "foo";

@rest = ();
$n_rest = 0;
@eventline = ();
@eventsort = ();
$n_event = 0;

%eventhash = ();

@outline = ();
$n_out = 0;

$err = 0;

while ( defined $ARGV[$argno] )
{
	$filename = $ARGV[$argno];
	$argno++;

	if ( $filename =~ m{\.card$} )
	{

		if ( open(CARDFILE, "<$filename") )
		{
			print STDOUT "File: $filename\n";

			$err = ReadCardFile();

			close(CARDFILE);

			if ( defined $version && $version != 1 )
			{
				print STDERR "$filename is already at version 2: ignoring\n";
			}
			elsif ( $err == 0 )
			{
				$err += AnalyseCardFile();

				if ( $err == 0 )
				{
					if ( $DBG == 0 )
					{
						if ( open(CARDFILE, ">$filename") )
						{
							WriteCardFile();
							close(CARDFILE);
						}
						else
						{
							print STDERR "Unable to open $filename for writing.\n";
						}
					}
					else
					{
						print STDERR "DBG enabled: $filename not written.\n";
					}
				}
				else
				{
					$s = "";
					$s = "s" if ($err > 1);
					print "$err error$s found; $filename not written\n";
				}
			}
		}
		else
		{
			print STDERR "Unable to open $filename for reading.\n";
		}
	}
	else
	{
		print STDERR "$filename: ignored.\n";
	}
}

exit 0;

# Trim() - trims leading and trailing spaces from string, returns result.
sub Trim
{
	my ($txt) = @_;
	$txt =~ s/^\s*(\S.*\S)\s*$/$1/;		# Remove leading and trailing blanks if there's some text.
	$txt =~ s/^\s+$//;					# Remove all blanks if there's nothing but blanks
	return $txt;
}

# Out() - appends a line to the output buffer
sub Out
{
	my ($txt) = @_;
	$outline[$n_out] = $txt;
	$n_out++;

	print STDOUT "$txt\n" if ($DBG >= 80);
}

# ReadCardFile() - reads the card file from global CARDFILE into global variables
sub ReadCardFile
{
	my $tmpstr;
	my $err = 0;
	my $skip_leading = 1;

	undef $name;
	undef $uniq;
	undef $gender;
	undef $nick;
	undef $father;
	undef $mother;
	undef $version;
	@rest = ();
	$n_rest = 0;
	@eventline = ();
	$n_event = 0;

	while ( <CARDFILE> )
	{
		chomp;
		$line = Trim($_);

		if ( $line =~ m{^Name:} )
		{
			if ( defined $name )
			{
				print STDERR "$filename: two or more Name lines\n";
				$err++;
			}
			else
			{
				($tmpstr) = $line =~ m{^Name:(.*)$};
				$name = Trim($tmpstr);
				print STDOUT "DBG: Name: \"$name\"\n" if ($DBG >= 100);
			}
		}
		elsif ( $line =~ m{^Uniq:} )
		{
			if ( defined $uniq )
			{
				print STDERR "$filename: two or more Uniq lines\n";
				$err++;
			}
			else
			{
				($tmpstr) = $line =~ m{^Uniq:(.*)$};
				$uniq = Trim($tmpstr);
				print STDOUT "DBG: Uniq: \"$uniq\"\n" if ($DBG >= 100);
			}
		}
		elsif ( $line =~ m{^Nickname:} )
		{
			if ( defined $nick )
			{
				print STDERR "$filename: two or more Nickname lines\n";
				$err++;
			}
			else
			{
				($tmpstr) = $line =~ m{^Nickname:(.*)$};
				$nick = Trim($tmpstr);
				print STDOUT "DBG: Nickname: \"$nick\"\n" if ($DBG >= 100);
			}
		}
		elsif ( $line =~ m{^Father:} )
		{
			if ( defined $father )
			{
				print STDERR "$filename: two or more Father lines\n";
				$err++;
			}
			else
			{
				($tmpstr) = $line =~ m{^Father:(.*)$};
				$father = Trim($tmpstr);
				print STDOUT "DBG: Father: \"$father\"\n" if ($DBG >= 100);
			}
		}
		elsif ( $line =~ m{^Mother:} )
		{
			if ( defined $mother )
			{
				print STDERR "$filename: two or more Mother lines\n";
				$err++;
			}
			else
			{
				($tmpstr) = $line =~ m{^Mother:(.*)$};
				$mother = Trim($tmpstr);
				print STDOUT "DBG: Mother: \"$mother\"\n" if ($DBG >= 100);
			}
		}
		elsif ( $line =~ m{^Version:} )
		{
			if ( defined $version )
			{
				print STDERR "$filename: two or more Version lines\n";
				$err++;
			}
			else
			{
				($tmpstr) = $line =~ m{^Version:(.*)$};
				$version = Trim($tmpstr);
				print STDOUT "DBG: Version: \"$version\"\n" if ($DBG >= 100);
			}
		}
		elsif ( ($line =~ m{^Male$}) ||
				($line =~ m{^Female$}) ||
				($line =~ m{^Unknown$}) )
		{
			if ( defined $gender )
			{
				print STDERR "$filename: two or more gender lines\n";
				$err++;
			}
			else
			{
				$gender = $line;
				print STDOUT "DBG: Gender: \"$gender\"\n" if ($DBG >= 100);
			}
		}
		else
		{
			if ( $skip_leading && $line eq "" )
			{
				# Ignore all blank lines up to first event
			}
			else
			{
				if ( $line =~ m{^[1-9?]} )
				{
					# Start of a new event
					print STDOUT "DBG: Event $n_event in line $n_rest: \"$line\"\n" if ($DBG >= 100);
					$eventline[$n_event] = $n_rest;
					$n_event++;
				}
				$rest[$n_rest] = $line;
				$n_rest++;
				$skip_leading = 0;
			}
		}
	}

	if ( !defined($name) )
	{
		print STDERR "$filename: no Name line\n";
		$err++;
	}

	if ( !defined($uniq) )
	{
		print STDERR "$filename: no Uniq line\n";
		$err++;
	}

	if ( !defined($gender) )
	{
		print STDERR "$filename: no Gender line\n";
		$err++;
	}

	if ( $err > 0 )
	{
		my $s = "";
		$s = "s" if ($err > 1);
		print STDERR "$filename: $err error$s\n";
	}

	return $err;
}

# AnalyseCardFile() - analyses and reformats the card file
sub AnalyseCardFile
{
	my $errs = 0;
	my ($i,$n_pre);
	my @e_date = ();
	my @e_type = ();
	my @e_rest = ();

	%eventhash = ();
	@eventsort = ();

	# Clear the output buffer
	@outline = ();
	$n_out = 0;


	# Write the file header to the output buffer.
	Out("Name:       $name");
	Out("Uniq:       $uniq");
	Out("$gender");
	Out("Nickname:   $nick") if ( defined $nick );
	Out("Father:     $father") if ( defined $father );
	Out("Mother:     $mother") if ( defined $mother );
	Out("Version:    2");
	Out("");

	# Write out any lines that come before the first event.
	# If there's no first event, write out the rest of the file.
	# Ignore final blank lines, convert multiple blank lines to single.
	if ( $n_event > 0 )
	{
		$n_pre = $eventline[0];
	}
	else
	{
		$n_pre = $n_rest;
	}

	my $b_line = 0;
	for ( $i = 0; $i < $n_pre; $i++ )
	{
		my $r_line = $rest[$i];

		if ( $r_line eq "" )
		{
			$b_line = 1;
		}
		else
		{
			Out("") if ( $b_line );
			Out($r_line);
			$b_line = 0;
		}
	}

	if ( $n_event > 0 )
	{
		# Process the events in file order.
		for ( $i = 0; $i < $n_event; $i++ )
		{
			my $e_line = $rest[$eventline[$i]];
			my ($e_d,$e_t,$e_r) = $e_line =~ m{^([^\s]+)\s+([^\s]+)(.*)$};
			$e_r = Trim($e_r);
			$e_t = ucfirst(lc(Trim($e_t)));

			print STDOUT "DBG: Event $i: \"$e_d\"  \"$e_t\"  \"$e_r\"\n" if ($DBG >= 90);

			my $e_first = $eventline[$i]+1;
			my $e_last = $n_rest-1;
			$e_last = $eventline[$i+1]-1 if ( $i < ($n_event-1) );

			print STDOUT "DBG: Event $e_d $e_t $e_r from $e_first to $e_last\n" if ($DBG >= 90);

			$errs += AnalyseEvent($e_first, $e_last, $e_d, $e_t, $e_r);
		}
	}

	return $errs;
}

# AnalyseEvent() - analyse an event and write it to the output buffer
sub AnalyseEvent
{
	my ($e_first, $e_last, $e_d, $e_t, $e_r) = @_;
	my $errs = 0;
	my ($place, $abode, $spouse, $what, $source);

	if ( $e_r ne "" )
	{
		if ( $e_t eq "Birth" ||
			 $e_t eq "Baptism" ||
			 $e_t eq "Death" ||
			 $e_t eq "Cremation" ||
			 $e_t eq "Burial" )
		{
			# For births, baptisms, deaths and burials, v1 event line contained place.
			$place = $e_r if ( $e_r ne "" );
		}
		elsif ( $e_t eq "Census" )
		{
			# For census, v1 event line contained address.
			$abode = $e_r if ( $e_r ne "" );
		}
		elsif ( $e_t eq "Marriage" )
		{
			$spouse = $e_r if ( $e_r ne "" );
		}
		elsif ( $e_t eq "Other" )
		{
			$what = $e_r if ( $e_r ne "" );
		}
		else
		{
			print STDERR "Event type $e_t not known --- don't know what to do with \"$e_r\"\n";
			$errs++;
		}
	}

	if ( $e_t eq "Census" )
	{
		print STDOUT "DBG: Census record\n" if ($DBG >= 90);
		# In v1, census records had implicit +Source line
		$source = "Census record";
	}

	Out("");
	if ( $e_t eq "Marriage" )
	{
		Out(sprintf("%-12sMarriage    %s", $e_d, $spouse));
	}
	else
	{
		Out(sprintf("%-12s%s", $e_d, $e_t));
	}

	$errs += AnalyseEventInfo($e_d, $e_t, $e_first, $e_last, $what, $place, $abode);
	$errs += AnalyseEventSources($e_d, $e_t, $e_first, $e_last, $source);
	$errs += AnalyseEventRest($e_d, $e_t, $e_first, $e_last);

	return $errs;
}

# AnalyseEventInfo() - analyse info about the event and the person
sub AnalyseEventInfo
{
	my ($e_d, $e_t, $e_first, $e_last, $what, $place, $abode) = @_;
	my $errs = 0;
	my ($age, $occupation, $birthplace, $informant, $disability, $theory, $before, $after);
	my ($keyword, $rhs);
	my ($i);

	for ( $i = $e_first; $i <= $e_last; $i++ )
	{
		my $line = $rest[$i];
		if ( $line ne "" )
		{
			($keyword, $rhs) = $line =~ m{^(.)(.*)$};
			if ( $keyword eq "|" )
			{
				# Continuation line!
			}
			elsif ( $keyword eq "+" )
			{
				($keyword, $rhs) = $line =~ m{^\+([^\s]+)(.*)$};

				$rhs = "" if ( !defined $rhs );
				$rhs = Trim($rhs);
				
				if ( defined $keyword )
				{
					$keyword = ucfirst(lc(Trim($keyword)));

					if ( $keyword eq "Age" )
					{
						if ( defined $age )
						{
							print STDERR "Event $e_d - $e_t: multiple Age lines\n";
							$errs++;
						}
						else
						{
							$age = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Occupation" )
					{
						if ( defined $occupation )
						{
							print STDERR "Event $e_d - $e_t: multiple Occupation lines\n";
							$errs++;
						}
						else
						{
							$occupation = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Place" )
					{
						if ( defined $place )
						{
							print STDERR "Event $e_d - $e_t: multiple Place lines\n";
							$errs++;
						}
						else
						{
							$place = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Abode" ||
							$keyword eq "Address" )
					{
						if ( defined $abode )
						{
							print STDERR "Event $e_d - $e_t: multiple Abode/Address lines\n";
							$errs++;
						}
						else
						{
							$abode = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Birthplace" ||
							$keyword eq "Whereborn" )
					{
						if ( defined $birthplace )
						{
							print STDERR "Event $e_d - $e_t: multiple Birthplace/Whereborn lines\n";
							$errs++;
						}
						else
						{
							$birthplace = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Informant" )
					{
						if ( defined $informant )
						{
							print STDERR "Event $e_d - $e_t: multiple Informant lines\n";
							$errs++;
						}
						else
						{
							$informant = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Disability" )
					{
						if ( defined $disability )
						{
							print STDERR "Event $e_d - $e_t: multiple Disability lines\n";
							$errs++;
						}
						else
						{
							$disability = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Theory" )
					{
						if ( defined $theory )
						{
							print STDERR "Event $e_d - $e_t: multiple Theory lines\n";
							$errs++;
						}
						else
						{
							$theory = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "Before" )
					{
						if ( defined $before )
						{
							print STDERR "Event $e_d - $e_t: multiple Before lines\n";
							$errs++;
						}
						else
						{
							$before = $rhs
						}
						$rest[$i] = "";
					}
					elsif ( $keyword eq "After" )
					{
						if ( defined $after )
						{
							print STDERR "Event $e_d - $e_t: multiple After lines\n";
							$errs++;
						}
						else
						{
							$after = $rhs
						}
						$rest[$i] = "";
					}
				}
				else
				{
					print STDERR "Couldn't parse line \"$line\"\n";
					$errs++;
				}
			}
			elsif ( $keyword eq "#" )
			{
				# Ignoring comment lines on this pass
			}
			else
			{
				print STDERR "Couldn't parse line \"$line\"\n";
				$errs++;
			}
		}
	}

	Out("+Before     $before") if ( defined $before);
	Out("+After      $after") if ( defined $after);
	Out("+What       $what") if ( defined $what);
	Out("+Place      $place") if ( defined $place);
	Out("+Age        $age") if ( defined $age);
	Out("+Occupation $occupation") if ( defined $occupation);
	Out("+Abode      $abode") if ( defined $abode);
	Out("+Birthplace $birthplace") if ( defined $birthplace);
	Out("+Informant  $informant") if ( defined $informant);
	Out("+Disability $disability") if ( defined $disability);
	Out("+Theory     $theory") if ( defined $theory);

	return $errs;
}

# AnalyseEventSources() - analyse and print the event source records
sub AnalyseEventSources
{
	my ($e_d, $e_t, $e_first, $e_last, $source) = @_;
	my $errs = 0;
	my ($keyword, $type, $value, $rhs);
	my @url = ();
	my $n_url = 0;
	my @file = ();
	my $n_file = 0;
	my @transcript_buf = ();
	my $n_transcript_lines = 0;
	my $in_transcript = 0;
	my ($reference, $fileref);
	my ($i, $j);
	

	for ( $i = $e_first; $i <= $e_last; $i++ )
	{
		my $line = $rest[$i];
		if ( $line ne "" )
		{
			($keyword, $rhs) = $line =~ m{^(.)(.*)$};
			if ( $keyword eq "|" )
			{
				# Continuation line!
				if ( $in_transcript )
				{
					$rhs = "" if ( !defined $rhs );
					$rhs = Trim($rhs);
					$transcript_buf[$n_transcript_lines] = $rhs;
					$n_transcript_lines++;
					$rest[$i] = "";
				}
			}
			elsif ( $keyword eq "+" )
			{
				$in_transcript = 0;

				($keyword, $rhs) = $line =~ m{^\+([^\s]+)(.*)$};

				$rhs = "" if ( !defined $rhs );
				$rhs = Trim($rhs);
				
				if ( defined $keyword )
				{
					$keyword = ucfirst(lc(Trim($keyword)));

					if ( $keyword eq "Source" )
					{
						if ( defined $source )
						{
							# Print out the previous source
							if ( defined $reference )
							{
								Out("+Source     $source $reference");
							}
							elsif ( defined $fileref )
							{
								Out("+Source     $source $fileref");
							}
							else
							{
								Out("+Source     $source");
							}
							for ( $j = 0; $j < $n_url; $j++ )
							{
								Out("-URL        $url[$j]");
							}
							for ( $j = 0; $j < $n_file; $j++ )
							{
								Out("-File       $file[$j]");
							}
							if ( $n_transcript_lines > 0 )
							{
								Out("-Transcript");
							}
							for ( $j = 0; $j < $n_transcript_lines; $j++ )
							{
								Out("| $transcript_buf[$j]");
							}
						}

						$source = $rhs;
						$rest[$i] = "";

						# Clear out the last source
						@url = ();
						$n_url = 0;
						@file = ();
						$n_file = 0;
						@transcript_buf = ();
						$n_transcript_lines = 0;
						undef $reference;
						undef $fileref;
					}
					elsif ( $keyword eq "Reference" )
					{
                        if ( defined $reference )
                        {
                            print STDERR "Event $e_d - $e_t: multiple Reference lines\n";
                            $errs++;
                        }
                        else
                        {
                            $reference = $rhs
                        }
                        $rest[$i] = "";
					}
					elsif ( $keyword eq "Url" )
					{
						$url[$n_url] = $rhs;
						$n_url++;
						$rest[$i] = "";
					}
					elsif ( $keyword eq "File" )
					{
						($type, $value) = $rhs =~ m{^([^\s]+)(.*)$};
						$type = Trim($type);
						$value = Trim($value);
						$value =~ s/^.*\/([^\/]*)$/$1/;		#Remove all directory parts
						$file[$n_file] = sprintf("%-12s%s",$type, $value);
						$n_file++;
						$rest[$i] = "";

						if ( defined $source && $source eq "Census record" && $type eq "Image" && !defined $fileref )
						{
							$fileref = $value;
							$fileref =~ s/^Census-1[89][0-9]1-//;
							$fileref =~ s/\..*$//;
						}
					}
					elsif ( $keyword eq "Transcript" ||
							$keyword eq "Transcription" )
					{
						$in_transcript = 1;
						if ( $rhs ne "" )
						{
							$transcript_buf[$n_transcript_lines] = $rhs;
							$n_transcript_lines++;
						}
						$rest[$i] = "";
					}
				}
				else
				{
					print STDERR "Couldn't parse line \"$line\"\n";
					$errs++;
				}
			}
			elsif ( $keyword eq "#" )
			{
				# Ignoring comment lines on this pass
			}
			else
			{
				print STDERR "Couldn't parse line \"$line\"\n";
				$errs++;
			}
		}
	}

	if ( defined $source )
	{
		# Print out the remaining source
		if ( defined $reference )
		{
			Out("+Source     $source $reference");
		}
		elsif ( defined $fileref )
		{
			Out("+Source     $source $fileref");
		}
		else
		{
			Out("+Source     $source");
		}
		for ( $j = 0; $j < $n_url; $j++ )
		{
			Out("-URL        $url[$j]");
		}
		for ( $j = 0; $j < $n_file; $j++ )
		{
			Out("-File       $file[$j]");
		}
		if ( $n_transcript_lines > 0 )
		{
			Out("-Transcript");
		}
		for ( $j = 0; $j < $n_transcript_lines; $j++ )
		{
			Out("| $transcript_buf[$j]");
		}
	}

	return $errs;
}	

# AnalyseEventRest() - analyse and print notes etc. for event
sub AnalyseEventRest
{
	my ($e_d, $e_t, $e_first, $e_last) = @_;
	my $errs = 0;
	my ($keyword, $rhs);
	my $in_note = 0;
	my @comments = ();
	my $n_comment = 0;

	for ( $i = $e_first; $i <= $e_last; $i++ )
	{
		my $line = $rest[$i];
		if ( $line ne "" )
		{
			($keyword, $rhs) = $line =~ m{^(.)(.*)$};
			if ( $keyword eq "|" )
			{
				# Continuation line!
				if ( $in_note )
				{
					$rhs = "" if ( !defined $rhs );
					$rhs = Trim($rhs);
					Out("| $rhs");
					$rest[$i] = "";
				}
				else
				{
				}
			}
			elsif ( $keyword eq "+" )
			{
				$in_note = 0;

				($keyword, $rhs) = $line =~ m{^\+([^\s]+)(.*)$};

				$rhs = "" if ( !defined $rhs );
				$rhs = Trim($rhs);
				
				if ( defined $keyword )
				{
					$keyword = ucfirst(lc(Trim($keyword)));

					if ( $keyword eq "Note" || $keyword eq "Todo" )
					{
						$in_note = 1;
						Out("+$keyword");
						if ( $rhs ne "" )
						{
							Out("| $rhs");
						}
						$rest[$i] = "";
					}
					else
					{
						printf STDERR "Unrecognised keyword $keyword  $rhs\n";
						$errs++;
					}
				}
				else
				{
					print STDERR "Couldn't parse line \"$line\"\n";
					$errs++;
				}
			}
			elsif ( $keyword eq "#" )
			{
				$in_note = 0;
				$comment[$n_comment] = $line;
				$n_comment++;
			}
			else
			{
				print STDERR "Couldn't parse line \"$line\"\n";
				$errs++;
			}
		}
	}

	# Comments move to the end of the event. This covers the most common cases.
	Out("")	if ( $n_comment > 0 );
	for ( $i = 0; $i < $n_comment; $i++ )
	{
		Out($comment[$i]);
	}

	return $errs;
}

# WriteCardFile() - writes the card file from variables back to the global CARDFILE
sub WriteCardFile
{
	my $i;

	for ( $i = 0; $i < $n_out; $i++ )
	{
		print CARDFILE "$outline[$i]\n";
	}
}
