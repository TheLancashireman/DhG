#!/usr/bin/perl -w
#
# Dh_GDump.pl - dumps a list of people with parents and DoB/DoD from the cards database
#
# (c) 2010 David Haworth
#
# $Id$

use Dh_GCard;

my $DBG = 0;

my $id = 0;
for my $fn (@ARGV)
{
	DhG_LoadCard($id, $fn);
	$id++;
}
DhG_AnalyseRelations();
DhG_Dump();
exit 0;
