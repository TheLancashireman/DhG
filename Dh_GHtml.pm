#!/usr/bin/perl -w
#
# Dh_GHtml.pm - assorted functions for creating family history web pages
#
# (c) 2013 David Haworth
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
	DhG_HtmlAhnentafel
);

sub DhG_HtmlCard;
sub DhG_MultiHtmlCard;
sub DhG_HtmlDescTree;
sub DhG_HtmlAhnentafel;

my $tt = Template->new({
	INCLUDE_PATH => "/data/family-history/svn/tools/DhG/templates",
	INTERPOLATE => 0,
}) || die "$Template::ERROR\n";

return 1;

# DhG_HtmlCard() - output an HTML "card file" for a given person.
# Collects all the data then uses Template.
sub DhG_HtmlCard
{
	my ($id, $privacy) = @_;

	my $template_vars = DhG_GetCardTemplateVars($id, $privacy, 'html');
	my $filebase = DhG_GetFilebase($id);

	my $htmlfilename = "html/cards/".$filebase.".html";

	if ( $tt->process("person-card-html.tmpl", $template_vars, $htmlfilename) )
	{
		print STDOUT "Generated $htmlfilename\n";
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

	$last = DhG_GetNoOfNames();

	foreach $id ( 1 .. $last )
	{
		$name = DhG_GetName($id);

		if ( defined $name )
		{
			$fn = DhG_GetFilename($id);

			if ( $fn =~ m{\/Kellys\/} )
			{
				# Ignoring Kellys for now.
				# print STDOUT "DBG: $id: $name - ignored (Kelly)!\n";
			}
			elsif ( $select eq "all" || !DhG_IsPrivate($id) )
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

	my $template_vars = DhG_GetDescendantTreeTemplateVars($id, $privacy);
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
