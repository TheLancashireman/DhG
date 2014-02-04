#!/usr/bin/perl -w
#
# Renames a card file to <single-directory>/<name>-<uid>.card
# Run separately in each branch.

die "This script is too dangerous to leave lying around!\n";

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
				print STDERR "$filename does not contain a Name record\n";
				$err++;
			}
			if ( !defined $old_uniq )
			{
				print STDERR "$filename does not contain a Uniq record\n";
				$err++;
			}

			if ( $err == 0 )
			{
				$name =~ s/^Name://;
				$name = Standardise($name);
				$name =~ s/_/Unknown/g;

				$old_uniq =~ s/^Uniq://;
				$old_uniq = Standardise($old_uniq);

				$directory = $filename;
				$directory =~ s/^([^\/]*)\/.*$/$1/;

				$new_filename = "$directory/$name-$old_uniq.card";

				$svn_command = "svn mv $filename $new_filename";

				$funny_chars = $name;
				$funny_chars =~ s/[a-zA-Z]//g;

				if ( $funny_chars ne "" )
				{
					print STDERR "$filename Name contains non-alpha characters; will not rename $filename\n";
				}
				elsif ( -f $new_filename )
				{
					print STDERR "$new_filename already exists; will not rename $filename\n";
				}
				else
				{
					print STDOUT "$svn_command\n";
					system $svn_command;
				}
			}
			else
			{
				print LOGFILE "$filename has errors; not renamed\n";
			}
		}
		else
		{
			print LOGFILE "Unable to open $filename for reading.\n";
		}
	}
}

exit 0;

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
	$person =~ s/\.//g;
	$person =~ s/\'//g;

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
