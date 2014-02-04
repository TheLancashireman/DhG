#!/usr/bin/perl -w
#
# Generates a unique ID for each person.
# Creates a translation list.

die "This script is too dangerous to leave lying around!\n";

$fixupname = "translate.txt";
$logname = "fixup-log.txt";
$indexname = "index.txt";

$argno = 0;
$new_uniq = 1;
$name = "foo";
$old_uniq = "foo";
$gender = "foo";
$nick = "foo";
$father = "foo";
$mother = "foo";
@rest = ();
$n_rest = 0;
$filename = "foo";

@card_file = ();
@card_name = ();
@card_olduniq = ();

open(XLATEFILE, ">$fixupname") or die "Unable to open $fixupname for writing\n";
open(LOGFILE, ">$logname") or die "Unable to open $logname for writing\n";
open(INDEXFILE, ">$indexname") or die "Unable to open $indexname for writing\n";

while ( defined $ARGV[$argno] )
{
	$filename = $ARGV[$argno];
	$argno++;

	if ( $filename =~ m{\.card$} )
	{
		if ( open(CARDFILE, "<$filename") )
		{
			ReadCardFile();

			close(CARDFILE);

			if ( !defined $name )
			{
				print LOGFILE "$filename does not contain a Name record\n";
				$err++;
			}
			if ( !defined $gender )
			{
				print LOGFILE "$filename does not contain a gender record\n";
				$err++;
			}

			if ( $err == 0 )
			{
				if ( open(CARDFILE, ">$filename") )
				{
					WriteCardFile();

					close(CARDFILE);

					$name =~ s/^Name://;
					$name = Trim($name);
					if ( defined $old_uniq )
					{
						$old_uniq =~ s/^Uniq://;
						$old_uniq = Trim($old_uniq);
					}

					$card_file[$new_uniq] = $filename;
					$card_name[$new_uniq] = $name;
					$card_olduniq[$new_uniq] = $old_uniq;
					
					$new_uniq++;
				}
				else
				{
					print LOGFILE "Unable to open $filename for writing; card not updated\n";
				}
			}
			else
			{
				print LOGFILE "$filename has errors; card not updated\n";
			}
		}
		else
		{
			print LOGFILE "Unable to open $filename for reading.\n";
		}
	}
}

$ncf = $new_uniq;
for ( $cf = 1; $cf < $ncf; $cf++ )
{
	$new_uniq = $cf;
	$name = $card_name[$cf];
	$filename = $card_file[$cf];
	$old_uniq = $card_olduniq[$cf];
	$old_uniq = "" if ( !defined $old_uniq );

	print XLATEFILE "$name || $old_uniq || $cf || $filename\n";
	printf INDEXFILE "%4d: %s\n", $cf, $name;

	if ( open(CARDFILE, "<$filename") )
	{
		ReadCardFile();

		close(CARDFILE);

		if ( defined $father )
		{
			$father =~ s/^Father://;
			$father = TranslatePerson($father);
			$father = "Father: $father";
		}
		if ( defined $mother )
		{
			$mother =~ s/^Mother://;
			$mother = TranslatePerson($mother);
			$mother = "Mother: $mother";
		}
		my $i;
		for ( $i = 0; $i < $n_rest; $i++ )
		{
			my $xxline = $rest[$i];
			my ($marr, $person) = $xxline =~ m{^([?1].*Marriage *)([^ ].*)$};
			if ( defined $marr && defined $person )
			{
				$person = TranslatePerson($person);
				$rest[$i] = $marr . $person;
			}
		}

		if ( open(CARDFILE, ">$filename") )
		{
			WriteCardFile();

			close(CARDFILE);
		}
		else
		{
			print LOGFILE "Could not open $filename for writing in phase 2\n"
		}
	}
	else
	{
		print LOGFILE "Could not open $filename for reading in phase 2\n"
	}
}

exit 0;


close(XLATEFILE);
close(INDEXFILE);
close(LOGFILE);

# Trim() - trims leading and trailing spaces from string, returns result.
sub Trim
{
	my ($txt) = @_;
	$txt =~ s/^\s*(\S.*)$/$1/;
	$txt =~ s/^(.*\S)\s*$/$1/;
	return $txt;
}

# Standardise - removes all spaces from a person's name
sub Standardise
{
	my ($person) = @_;

	$person =~ s/ //g;

	return $person;
}

# TranslatePerson() - Translates the given person from old-style to new-style
sub TranslatePerson
{
	my ($person) = @_;

	$person = Trim($person);

	if ( $person =~ m{\[.*\]} )
	{
		my ($pname, $puniq) = $person =~ m{^(.*)\[(.*)\]};
		$pname = Trim($pname);
		my $std_pname = Standardise($pname);
		my $xx;
		my $found = 0;

#		print STDERR "Looking for \"$pname\", \"$puniq\"\n";
		for ( $xx = 1; $xx < $ncf && !$found; $xx++ )
		{
			if ( defined $card_olduniq[$xx] )
			{
#				print STDERR "Compare with \"$card_name[$xx]\", \"$card_olduniq[$xx]\"\n";
				if ( (Standardise($card_name[$xx]) eq $std_pname) && ($card_olduniq[$xx] eq $puniq) )
				{
					$person = "$pname [$xx]";
					$found = 1;
				}
			}
		}
		if ( !$found )
		{
			print LOGFILE "WARNING: in $filename, reference to $person does not exist\n";
		}
	}
	else
	{
		$person = Trim($person);
		my $std_person = Standardise($person);
		my $xx;
		my $n = 0;
		my $match = 0;
		for ( $xx = 1; $xx < $ncf; $xx++ )
		{
			if ( Standardise($card_name[$xx]) eq $std_person && !defined $card_olduniq[$xx] )
			{
				$match = $xx;
				$n++;
			}
		}
		if ( $n == 0 )
		{
			# No match found: do not change name
			print LOGFILE "WARNING: in $filename, reference to $person does not exist\n";
		}
		elsif ( $n == 1 )
		{
			# Exactly one match found. Add a unique ID where there wasn't one before
			$person = "$person [$match]";
		}
		else
		{
			print LOGFILE "WARNING: in $filename, reference to $person is not unique\n";
		}
	}

	return $person;
}

# ReadCardFile() - reads the card file from global CARDFILE into global variables
sub ReadCardFile
{
	undef $name;
	undef $old_uniq;
	undef $gender;
	undef $nick;
	undef $father;
	undef $mother;
	@rest = ();
	$n_rest = 0;
	$err = 0;

	while ( <CARDFILE> )
	{
		chomp;
		$line = Trim($_);

		if ( $line =~ m{^Name:} )
		{
			if ( defined $name )
			{
				print LOGFILE "$filename: two or more Name lines\n";
				$err++;
			}
			else
			{
				$name = $line;
			}
		}
		elsif ( $line =~ m{^Uniq:} )
		{
			if ( defined $old_uniq )
			{
				print LOGFILE "$filename: two or more Uniq lines\n";
				$err++;
			}
			else
			{
				$old_uniq = $line;
			}
		}
		elsif ( $line =~ m{^Nickname:} )
		{
			if ( defined $nick )
			{
				print LOGFILE "$filename: two or more Nickname lines\n";
				$err++;
			}
			else
			{
				$nick = $line;
			}
		}
		elsif ( $line =~ m{^Father:} )
		{
			if ( defined $father )
			{
				print LOGFILE "$filename: two or more Father lines\n";
				$err++;
			}
			else
			{
				$father = $line;
			}
		}
		elsif ( $line =~ m{^Mother:} )
		{
			if ( defined $mother )
			{
				print LOGFILE "$filename: two or more Mother lines\n";
				$err++;
			}
			else
			{
				$mother = $line;
			}
		}
		elsif ( ($line =~ m{^Male$}) || ($line =~ m{^Female$}) )
		{
			if ( defined $gender )
			{
				print LOGFILE "$filename: two or more gender lines\n";
				$err++;
			}
			else
			{
				$gender = $line;
			}
		}
		else
		{
			$rest[$n_rest] = $line;
			$n_rest++;
		}
	}
}

# WriteCardFile() - writes the card file from variables back to the global CARDFILE
sub WriteCardFile
{
	print CARDFILE "$name\n";
	print CARDFILE "Uniq: $new_uniq\n";
	print CARDFILE "$gender\n";
	print CARDFILE "$nick\n" if ( defined $nick );
	print CARDFILE "$father\n" if ( defined $father );
	print CARDFILE "$mother\n" if ( defined $mother );

	my $i;
	for ( $i = 0; $i < $n_rest; $i++ )
	{
		print CARDFILE "$rest[$i]\n";
	}
}
