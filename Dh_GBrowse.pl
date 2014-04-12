#!/usr/bin/perl -w
#
# Dh_GBrowse.pl - browses the database, printing parents and children of specified persons.
#
# (c) 2010 David Haworth
#
# $Id$

use Dh_GCard;
use Dh_GHtml;
use Dh_GText;
use Term::ReadLine;

sub DhG_PrintHelp;

my @commands =
(
	"ancestors",
    "card",
	"close",
	"descendants",
	"olddescendants",
	"edit",
	"family",
	"find",
	"help",
	"htmlcard",
	"hc",
	"htmldesc",
	"hd",
	"htmlprivdesc",
	"hpd",
	"htmlanc",
	"ha",
	"list",
	"new",
	"open",
	"quit",
	"reload",
	"search",
	"set",
	"vi",
	"zzz"
);

my $DBG = 0;

my $line;
my $term = Term::ReadLine->new('Test by Dave');
my $prompt = 'What now? ';
$term->ornaments(0);

DhG_LoadDatabase(@ARGV);
DhG_AnalyseRelations();
DhG_PrintHelp();

while ( defined ($line = $term->readline($prompt)) )
{
	chomp $line;
	$line = DhG_Trim($line);
	if ( $line ne "" )
	{
		my ($cmd, $params);
		if ( $line =~ m{\s} )
		{
			($cmd, $params) = $line =~ m{^(\S*)\s(.*)$};
			$params = DhG_Trim($params);
		}
		else
		{
			$cmd = $line;
			$params = "";
		}

		my $nmatch = 0;		# No. of matches
		my $match1 = 0;		# 1st match

		my $i;
		for ( $i=0; defined $commands[$i]; $i++ )
		{
			if ( index($commands[$i], $cmd) == 0 )
			{
				if ( $nmatch == 0 )
				{
					$match1 = $i;
				}
				else
				{
					printf STDERR "Ambiguous command: $commands[$match1]" if ($nmatch == 1);
					printf STDERR ", $commands[$i]";
				}

				$nmatch++;
			}
		}

		if ( $nmatch == 0 )
		{
			print STDERR "Eh?\n";
		}
		elsif ( $nmatch > 1 )
		{
			print STDERR "\n";
		}
		else
		{
			$cmd = $commands[$match1];

			print STDERR "cmd=\"$cmd\"\n" if ( $DBG > 99 );

			if ( $cmd eq "quit" )
			{
				if ( $params eq "" )
				{
					exit 0;
				}
				else
				{
					print STDERR "Eh?\n";
				}
			}
			elsif ( $cmd eq "list" )
			{
				if ( $params eq "" )
				{
					DhG_Dump();
				}
				else
				{
					print STDERR "Eh?\n";
				}
			}
			elsif ( $cmd eq "reload" )
			{
				if ( $params eq "" )
				{
					DhG_ClearDatabase();
					DhG_LoadDatabase(@ARGV);
					DhG_AnalyseRelations();
				}
				else
				{
					print STDERR "Eh?\n";
				}
			}
			elsif ( $cmd eq "new" )
			{
				DhG_NewPerson($params);
			}
			elsif ( $cmd eq "edit" || $cmd eq "vi" )
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_EditCard($uniq);
				}
			}
			elsif ( $cmd eq "family" )
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_TextFamily($uniq, "private");
				}
			}
			elsif ( $cmd eq "card" )
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_TextCard($uniq, "private");
				}
			}
			elsif ( $cmd eq "descendants" )
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_TextDescTree($uniq, "all");
				}
			}
			elsif ( $cmd eq "olddescendants" )				# To be removed
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_PrintDescendantTree($uniq);
				}
			}
			elsif ( $cmd eq "ancestors" )
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_PrintAncestorTree($uniq);
				}
			}
			elsif ( $cmd eq "search" || $cmd eq "find" )
			{
				DhG_Search($params);
			}
			elsif ( $cmd eq "set" )
			{
				DhG_SetVariable($params);
				$DBG = DhG_GetDebugLevel();
			}
			elsif ( $cmd eq "open" )
			{
				DhG_OpenOutputFile($params);
			}
			elsif ( $cmd eq "close" )
			{
				if ( $params eq "" )
				{
					DhG_CloseOutputFile();
				}
				else
				{
					print STDERR "Eh?\n";
				}
			}
			elsif ( $cmd eq "help" )
			{
				if ( $params eq "" )
				{
					DhG_PrintHelp();
				}
				else
				{
					print STDERR "Eh?\n";
				}
			}
			elsif ( $cmd eq "htmlcard" || $cmd eq "hc" )
			{
				my $lcpar = lc($params);
				if ( $lcpar eq "public" || $lcpar eq "all" )
				{
					DhG_MultiHtmlCard($lcpar);
				}
				else
				{
					my $uniq = DhG_GetUniq($params);
					if ( $uniq > 0 )
					{
						DhG_HtmlCard($uniq);
					}
				}
			}
			elsif ( $cmd eq "htmldesc" || $cmd eq "hd" ||
					$cmd eq "htmlprivdesc" || $cmd eq "hpd" )
			{
				my $privacy = "public";

				$privacy = "all" if ( $cmd eq "htmlprivdesc" || $cmd eq "hpd" );
				
				if ( index($params, "@") == 0 )
				{
					$params = substr($params, 1);
					
					if ( open(SCRIPTFILE, "<$params") )
					{
						while ( <SCRIPTFILE> )
						{
							chomp;
							my $scriptline = $_;
							my $uniq = DhG_GetUniq($scriptline);
							if ( $uniq > 0 )
							{
								# Only show public persons
								DhG_HtmlDescTree($uniq, $privacy);
							}
						}
						close(SCRIPTFILE);
					}
					else
					{
						print STDERR "Unable to open $params for reading\n";
					}
				}
				else
				{
					my $uniq = DhG_GetUniq($params);
					if ( $uniq > 0 )
					{
						# Only show public persons
						DhG_HtmlDescTree($uniq, $privacy);
					}
				}
			}
			elsif ( $cmd eq "htmlanc" || $cmd eq "ha" )
			{
				my $uniq = DhG_GetUniq($params);
				if ( $uniq > 0 )
				{
					DhG_HtmlAhnentafel($uniq);
				}
			}
			elsif ( $cmd eq "zzz" )
			{
				DhG_Test($params);
			}
			else
			{
				print STDERR "Unimplemented command! Please file bug report :-)\n";
			}
		}
	}
}

exit 0;

sub DhG_PrintHelp
{
	print STDERR "help                     = Print this text\n";
	print STDERR "list                     = List all people\n";
	print STDERR "family <person>          = Print family of a single person\n";
	print STDERR "descendants <person>     = Print all descendants of a single person\n";
	print STDERR "ancestors <person>       = Print all ancestors of a single person\n";
	print STDERR "search <pattern>         = Print name of people that match given terms\n";
	print STDERR "find <pattern>           = Print name of people that match given terms\n";
	print STDERR "quit                     = Close program\n";
	print STDERR "edit <person>            = Edit a person's card\n";
	print STDERR "vi                       = (alias for edit)\n";
	print STDERR "reload                   = Reload the database\n";
	print STDERR "set <name>=<value>       = Set a variable\n";
	print STDERR "open <filename>          = Open a file for alternative output\n";
	print STDERR "close                    = Close the alternative output file\n";
	print STDERR "htmlcard <person>        = Output a card file in HTML\n";
	print STDERR "htmlcard all             = Output a card file in HTML for every person in the database\n";
	print STDERR "htmlcard public          = Output a card file in HTML for every \"public\" person in the database\n";
	print STDERR "hc                       = (alias for htmlcard)\n";
	print STDERR "htmldesc <person>        = Output a public descendant tree in HTML\n";
	print STDERR "htmldesc @<filename>     = Output a public descendant tree in HTML for each person listed in the file\n";
	print STDERR "hd                       = (alias for htmldesc)\n";
	print STDERR "htmlprivdesc <person>    = Output a private descendant tree in HTML\n";
	print STDERR "htmlprivdesc @<filename> = Output a private descendant tree in HTML for each person listed in the file\n";
	print STDERR "hpd                      = (alias for htmlprivdesc)\n";

#	print STDERR "D   = Print all descendants of a single person (HTML)\n";
#	print STDERR "f   = Create .fig file for all partnerships of single person\n";
#	print STDERR "v   = Create .svg file for all partnerships of single person\n";
}
