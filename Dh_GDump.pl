#!/usr/bin/perl -w
#
# Dh_GDump.pl - dumps a list of people with parents and DoB/DoD from the cards database
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
