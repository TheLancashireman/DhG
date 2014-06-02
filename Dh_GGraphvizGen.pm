#!/usr/bin/perl -w
#
# Dh_GGraphvizGen.pm - assorted functions for creating a family tree in Graphviz format.
#
# Calling sequence:
#
# (c) 2012 David Haworth
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

package Dh_GGraphvizGen;

use Exporter();
@ISA = qw(Exporter);
@EXPORT  =
(
	DhG_GvGen_BeginFamily,
	DhG_GvGen_AddChild,
	DhG_GvGen_EndFamily,
);

return 1;

# DhG_GvGen_BeginFamily() -Âbegins a family block output. Subgraph and marriage with links to parents if they exist.
sub DhG_GvGen_BeginFamily
{
	my ($f_id, $father, $m_id, $mother, $marriage) = @_;
	my $outstring = "\n";

	$outstring .= "    subgraph\n";
    $outstring .= "    {\n";
	$outstring .= "            $marriage [label=\"<father>$father|<children>+|<mother>$mother\", ATT_MARR];\n";
	$outstring .= "            P$f_id:s -- $marriage:father:n [ATT_MARR_EDGE];\n" if ( defined $f_id );
	$outstring .= "            P$m_id:s -- $marriage:mother:n [ATT_MARR_EDGE];\n" if ( defined $m_id );

	return $outstring;
}

# DhG_GvGen_EndFamily() - ends a family block output.
sub DhG_GvGen_EndFamily
{
	my $outstring = "    }\n";

	return $outstring;
}

# DhG_GvGen_AddChild() - begins a family block output. Subgraph and marriage with links to parents if they exist.
sub DhG_GvGen_AddChild
{
	my ($c_id, $child, $marriage) = @_;
	my $outstring = "\n";

	$outstring .= "            P$c_id [label=\"$child\", ATT_PERSON];\n";
	if ( defined $marriage )
	{
		$outstring .= "            $marriage:children:s -- P$c_id:n [ATT_CHILD_EDGE];\n";
	}

	return $outstring;
}
