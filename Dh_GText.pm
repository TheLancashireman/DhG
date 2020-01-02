#!/usr/bin/perl -w
#
# Dh_GText.pm - assorted functions for formatting text output 
#
# (c) 2014 David Haworth
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

package Dh_GText;

use Template;
use Dh_GCard;

use Exporter();
@ISA = qw(Exporter);
@EXPORT  =
(
	DhG_TextFamily,
	DhG_TextCard,
	DhG_TextDescTree,
	DhG_NewPersonCard
);

sub DhG_TextFamily;
sub DhG_TextCard;
sub DhG_TextDescTree;
sub DhG_NewPersonCard;

my $tt = undef;

return 1;

sub DhG_TextInit
{
	if ( !defined $tt )
	{
		my $td = DhG_GetTemplateDir();

		if ( -d $td )
		{
			$tt = Template->new({
				INCLUDE_PATH => $td,
				INTERPOLATE => 0,
			}) || die "$Template::ERROR\n";
		}
		else
		{
			print STDERR "Template directory $td not found.\n";
		}
	}
}

# DhG_TextFamily() - output a text family report for a given person.
# A family report is a subset of the card report -- no timeline.
# Collects all the data then uses Template.
sub DhG_TextFamily
{
	my ($id, $privacy) = @_;

	DhG_TextInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetCardTemplateVars($id, $privacy, 'text');
	my $filebase = DhG_GetFilebase($id);

	# Omitted 3rd parameter to tt->process ==> output goes to stdout
	if ( $tt->process("person-family-text.tmpl", $template_vars) )
	{
	}
	else
	{
		print STDERR "Template generation failed: " . $tt->error() . "\n";
	}
}

# DhG_TextCard() - output a text "card file" for a given person.
# Collects all the data then uses Template.
sub DhG_TextCard
{
	my ($id, $privacy) = @_;

	DhG_TextInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetCardTemplateVars($id, $privacy, 'text');
	my $filebase = DhG_GetFilebase($id);

	# Omitted 3rd parameter to tt->process ==> output goes to stdout
	if ( $tt->process("person-card-text.tmpl", $template_vars) )
	{
	}
	else
	{
		print STDERR "Template generation failed: " . $tt->error() . "\n";
	}
}

# DhG_TextDescTree() - output a text "descendant tree" for a given person.
# Collects all the data then uses Template.
sub DhG_TextDescTree
{
	my ($id, $privacy) = @_;

	DhG_TextInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetDescendantTreeTemplateVars($id, $privacy, 0);
	my $filebase = DhG_GetFilebase($id);

	# Omitted 3rd parameter to tt->process ==> output goes to stdout
	if ( $tt->process("descendant-tree-text.tmpl", $template_vars) )
	{
	}
	else
	{
		print STDERR "Template generation failed: " . $tt->error() . "\n";
	}
}

# DhG_TextAhnentafel() - output a text "ancestor tree" (Ahnentafel) for a given person.
# Collects all the data then uses Template.
sub DhG_TextAhnentafel
{
	my ($id) = @_;

	DhG_TextInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetAhnentafelTemplateVars($id);
	my $filebase = DhG_GetFilebase($id);

	# Omitted 3rd parameter to tt->process ==> output goes to stdout
	if ( $tt->process("ahnentafel-text.tmpl", $template_vars) )
	{
	}
	else
	{
		print STDERR "Template generation failed: " . $tt->error() . "\n";
	}
}

# DhG_NewPersonCard() - create a new person in the database using a template card file
# Collects all the data then uses Template.
sub DhG_NewPersonCard
{
	my ($person_name, $father, $mother) = @_;

	DhG_TextInit();
	return if ( !defined $tt );

	my ($cardfullpath, $template_vars) = DhG_GetNewPersonTemplateVars($person_name, $father, $mother);

	if ( defined $template_vars )
	{
		if ( $tt->process("person-card.tmpl", $template_vars, $cardfullpath) )
		{
			DhG_EditFile($cardfullpath);
		}
		else
		{
			print STDERR "Template generation failed: " . $tt->error() . "\n";
		}
	}
}
