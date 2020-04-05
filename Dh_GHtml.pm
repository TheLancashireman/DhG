#!/usr/bin/perl -w
#
# Dh_GHtml.pm - assorted functions for creating family history web pages
#
# (c) 2013 David Haworth
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

package Dh_GHtml;

use Template;
use Dh_GCard;

use Exporter();
@ISA = qw(Exporter);
@EXPORT  =
(
	DhG_HtmlCard,
	DhG_MultiHtmlCard,
	DhG_HtmlDescTree,
	DhG_HtmlAhnentafel,
	DhG_HtmlSurnameIndex
);

sub DhG_HtmlCard;
sub DhG_MultiHtmlCard;
sub DhG_HtmlDescTree;
sub DhG_HtmlAhnentafel;
sub DhG_HtmlSurnameIndex;

my $tt = undef;

return 1;

sub DhG_HtmlInit
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


# DhG_HtmlCard() - output an HTML "card file" for a given person.
# Collects all the data then uses Template.
sub DhG_HtmlCard
{
	my ($id, $privacy) = @_;

	DhG_HtmlInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetCardTemplateVars($id, $privacy, 'html');
	my $filebase = DhG_GetFilebase($id);

	my $htmlfilename = "html/cards/".$filebase.".html";

	if ( $tt->process("person-card-html.tmpl", $template_vars, $htmlfilename) )
	{
#		print STDOUT "Generated $htmlfilename\n";
	}
	else
	{
		print STDERR "Template generation failed: $tt->error()\n";
	}
}

# DhG_MultiHtmlCard() - output an HTML "card file" for a each person.
# Parameter: select --- all or public
# Temporary: ignores Kellys
sub DhG_MultiHtmlCard
{
	my ($select) = @_;
	my ($last, $id, $name, $fn);

	DhG_HtmlInit();
	return if ( !defined $tt );

	$last = DhG_GetNoOfNames();

	foreach $id ( 1 .. $last )
	{
		$name = DhG_GetName($id);

		if ( defined $name )
		{
			$fn = DhG_GetFilename($id);

#			if ( $fn =~ m{\/Tidswells\/} )
#			{
#				# Ignoring Tidswells for now.
#				# print STDOUT "DBG: $id: $name - ignored (Tidswell)!\n";
#			}
#			elsif ( $select eq "all" || !DhG_IsPrivate($id) )
			if ( $select eq "all" || !DhG_IsPrivate($id) )
			{
				DhG_HtmlCard($id, $select);
			}
			else
			{
				# print STDOUT "DBG: $id: $name - ignored (private)!\n";
			}
		}
	}
}

# DhG_HtmlDescTree() - output an HTML "descendant tree" for a given person.
# Collects all the data then uses Template.
sub DhG_HtmlDescTree
{
	my ($id, $privacy) = @_;

	DhG_HtmlInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetDescendantTreeTemplateVars($id, $privacy, 1);
	my $filebase = DhG_GetFilebase($id);

	my $htmlfilename = "html/trees/";
	$htmlfilename .= "private/" if ( $privacy ne "public" );
	$htmlfilename .= $filebase."-descendants.html";

	if ( $tt->process("descendant-tree-html.tmpl", $template_vars, $htmlfilename) )
	{
		print STDOUT "Generated $htmlfilename\n";
	}
	else
	{
		print STDERR "Template generation failed: $tt->error()\n";
	}
}

# DhG_HtmlAhnentafel() - output an HTML "ancestor tree" (Ahnentafel) for a given person.
# Collects all the data then uses Template.
sub DhG_HtmlAhnentafel
{
	my ($id) = @_;

	DhG_HtmlInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetAhnentafelTemplateVars($id);
	my $filebase = DhG_GetFilebase($id);

	my $htmlfilename = "html/trees/";
	$htmlfilename .= $filebase."-ancestors.html";

	if ( $tt->process("ahnentafel-html.tmpl", $template_vars, $htmlfilename) )
	{
		print STDOUT "Generated $htmlfilename\n";
	}
	else
	{
		print STDERR "Template generation failed: " . $tt->error() . "\n";
	}
}

# DhG_HtmlSurnameIndex() - output an HTML index by surname
# Collects all the data then uses Template.
sub DhG_HtmlSurnameIndex
{
	my ($privacy) = @_;

	DhG_HtmlInit();
	return if ( !defined $tt );

	my $template_vars = DhG_GetSurnameIndexTemplateVars($privacy, 'html');

	my $htmlfilename = "html/surname-index.html";

	if ( $tt->process("surname-index-html.tmpl", $template_vars, $htmlfilename) )
	{
		print STDOUT "Generated $htmlfilename\n";
	}
	else
	{
		print STDERR "Template generation failed: $tt->error()\n";
	}
}
