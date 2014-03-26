#!/usr/bin/perl -w
#
# Dh_GText.pm - assorted functions for formatting text output 
#
# (c) 2014 David Haworth
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
	DhG_TextDescTree
);

sub DhG_TextFamily;
sub DhG_TextCard;
sub DhG_TextDescTree;

my $tt = Template->new({
	INCLUDE_PATH => "/data/family-history/tools/DhG/templates",
	INTERPOLATE => 0,
}) || die "$Template::ERROR\n";

return 1;

# DhG_TextFamily() - output a text family report for a given person.
# A family report is a subset of the card report -- no timeline.
# Collects all the data then uses Template.
sub DhG_TextFamily
{
	my ($id, $privacy) = @_;

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

	my $template_vars = DhG_GetDescendantTreeTemplateVars($id, $privacy);
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
