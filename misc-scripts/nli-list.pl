#!/usr/bin/perl -w
#
# Prints out a list of jpg files of the form XXX_nnn.jpg
# where XXX is given on the command line and nnn runs from 1 to N
#
# Usage: nli-list.pl XXX N
#
# (c) David Haworth

$XXX = $ARGV[0];
$N = $ARGV[1];
$i = 0;

$url = $XXX =~ m{^http};

while ( $i < $N )
{
	$i++;		# Filenames run from 1..N

	if ( $url )
	{
		printf("%s_%03d.jpg\n", $XXX, $i);
	}
	else
	{
		printf("https://registers.nli.ie/static/high/%s/vtls%s_%03d.jpg\n", $XXX, $XXX, $i);
	}
}
