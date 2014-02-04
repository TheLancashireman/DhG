#!/usr/bin/perl -w
#
# Dh_GFigGen.pm - assorted functions for creating a single-family tree in xfig format.
#
# Calling sequence:
#	DhG_FigGen_OpenFile()		-- opens the fig file
#	DhG_FigGen_Head()			-- writes the xfig file header to the current output file
#	DhG_DhG_FigGen_Parents()	-- writes the parents partnership, initialises children vars.
#	DhG_FigGen_Child()			-- for each child, outputs the child's box
#	DhG_FigGen_CloseFile()		-- closes the current file
#
# (c) 2011 David Haworth
#
# $Id$

package Dh_GFigGen;

use Exporter();
@ISA = qw(Exporter);
@EXPORT  =
(
	DhG_FigGen_OpenFile,
	DhG_FigGen_CloseFile,
	DhG_FigGen_Head,
	DhG_FigGen_Parents,
	DhG_FigGen_Child,
	DhG_FigGen_Test
);

# Configuration constants
my $box_height = 1000;
my $box_width = 2000;
my $forename_pos = 270;
my $surname_pos = 570;
my $dobdod_pos = 820;

my $parent_top = 1600;
my $parent_left = 3600;
my $parent_gap = 2000;

my $child_top = $parent_top + 2 * $box_height;		# Top of child boxes (first row)
my $child_gap = 200;

my $max_children_line = 6;

my $min_left = ($parent_left + $box_width + $parent_gap/2)
				- (($max_children_line - 1) * ($box_width + $child_gap))/2;

my $forename_font = 4;
my $surname_font = 6;
my $dobdod_font = 0;
my $forename_pt = 12;
my $surname_pt = 12;
my $dobdod_pt = 10;

# State variables
my $child_left = 0;		# Left side of 1st child box
my $child_num = 0;		# No. of children already output
my $child_stagger = 0;	# Need to output 2 rows of children?

sub DhG_FigGen_Test;
sub DhG_FigGen_OpenFile;
sub DhG_FigGen_CloseFile;
sub DhG_FigGen_Head;
sub DhG_FigGen_Parents;
sub DhG_FigGen_Child;

return 1;

sub DhG_FigGen_Test
{
	my ($n_children) = @_;

	if ( DhG_FigGen_OpenFile("test.fig") == 0 )
	{
		DhG_FigGen_Head();

		DhG_FigGen_Parents("Gumby", "Dad", "1901", "2001", "Gummybum", "Mum", "1903", "1997", $n_children);

		DhG_FigGen_Child("Gumby", "Alice", "1920", "1960") if ( $n_children > 0 );
		DhG_FigGen_Child("Gumby", "Bob", "1922", "1965") if ( $n_children > 1 );
		DhG_FigGen_Child("Gumby", "Charlie", "1924", "1970") if ( $n_children > 2 );
		DhG_FigGen_Child("Gumby", "Dennis", "1926", "1975") if ( $n_children > 3 );

		DhG_FigGen_Child("Gumby", "Ethel", "1928", "1960") if ( $n_children > 4 );
		DhG_FigGen_Child("Gumby", "Fred", "1930", "1965") if ( $n_children > 5 );
		DhG_FigGen_Child("Gumby", "Gertie", "1932", "1970") if ( $n_children > 6 );
		DhG_FigGen_Child("Gumby", "Harriet", "1934", "1975") if ( $n_children > 7 );

		DhG_FigGen_Child("Gumby", "Ian", "1936", "1960") if ( $n_children > 8 );
		DhG_FigGen_Child("Gumby", "Julia", "1938", "1965") if ( $n_children > 9 );
		DhG_FigGen_Child("Gumby", "Kate", "1940", "1970") if ( $n_children > 10 );
		DhG_FigGen_Child("Gumby", "Len", "1942", "1975") if ( $n_children > 11 );

		DhG_FigGen_CloseFile();
	}
}
#	DhG_FigGen_OpenFile() - opens named file as current fig file, returns 0 if OK.
#
#	Parameters:
#		1:	name of file to open
sub DhG_FigGen_OpenFile
{
	my ($figfilename) = @_;
	my $error = 0;

	if ( !open(FIGFILE, ">$figfilename") )
	{
		print STDERR "Cannot open $figfilename for writing\n";
		$error = 1;
	}
	return $error;
}

#	DhG_FigGen_CloseFile() - closes current fig file
sub DhG_FigGen_CloseFile
{
	close FIGFILE;
}

#	DhG_FigGen_Head() - outputs xfig header to current fig file
sub DhG_FigGen_Head
{
	print FIGFILE "#FIG 3.2  Produced by xfig version 3.2.5b\n";	# This is a blatant lie!
	print FIGFILE "Landscape\n";
	print FIGFILE "Center\n";
	print FIGFILE "Metric\n";
	print FIGFILE "A4\n";
	print FIGFILE "100.00\n";
	print FIGFILE "Single\n";
	print FIGFILE "-2\n";
	print FIGFILE "1200 2\n";
}

#	DhG_FigGen_Parents() - outputs parents' partnership to current fig file
#		* boxes for mother and father, and joining line
#		* descender and family bar if there are children
#		* initialises variables for children
#
#	Parameters:
#		1: father's surname
#		2: father's forename
#		3: father's date-of-birth
#		4: father's date-of-death
#		5: mother's surname
#		6: mother's forename
#		7: mother's date-of-birth
#		8: mother's date-of-death
#		9: no. of children
sub DhG_FigGen_Parents
{
	my ($f_surname, $f_forename, $f_dob, $f_dod,
		$m_surname, $m_forename, $m_dob, $m_dod, $n_children) = @_;

	my $father_left = $parent_left;
	my $mother_left = $parent_left + $parent_gap + $box_width;
	my $mother_right = $mother_left + $box_width;
	my $parent_bottom = $parent_top + $box_height;

	my $join_left = $father_left + $box_width;
	my $join_right = $join_left + $parent_gap;
	my $join_top = ($parent_top + $parent_bottom)/2;
	my $join_bottom = $join_top + $box_height;
	my $join_middle = ($join_left + $join_right)/2;

	my $group_left = $father_left;
	my $group_right = $mother_right;
	my $group_top = $parent_top;
	my $group_bottom = $parent_bottom;
	my $bar_length = 0;
	my $bar_left = 0;
	my $bar_right = 0;

	my $n_children_line = $n_children;
	$n_children_line = (($n_children + 1)/2) if ( $n_children > $max_children_line );

	if ( $n_children > 0 )
	{
		$bar_length = ($n_children_line - 1) * ($box_width + $child_gap);
		$bar_left = $join_middle - $bar_length/2;
		$bar_left = $min_left if ( $bar_left < $min_left );
		$bar_right = $bar_left + $bar_length;

		$group_left = $bar_left if ( $bar_left < $father_left );
		$group_right = $bar_right if ( $bar_right > $mother_right );
		$group_bottom = $join_bottom;
	}

	print FIGFILE "6 $group_left $parent_top $group_right $join_bottom\n";

	DhG_FigGen_PersonBox($father_left, $parent_top, $f_surname, $f_forename, $f_dob, $f_dod, 0);

	print FIGFILE "2 1 0 1 0 7 50 -1 -1 0.000 0 0 7 0 0 2\n";
	print FIGFILE "\t $join_left $join_top\n";
	print FIGFILE "\t $join_right $join_top\n";

	DhG_FigGen_PersonBox($mother_left, $parent_top, $m_surname, $m_forename, $m_dob, $m_dod, 0);

	if ( $n_children > 0 )
	{
		print FIGFILE "2 1 0 1 0 7 50 -1 -1 0.000 0 0 7 0 0 2\n";
		print FIGFILE "\t $join_middle $join_top\n";
		print FIGFILE "\t $join_middle $join_bottom\n";

		if ( $n_children > 1 )
		{
			print FIGFILE "2 1 0 1 0 7 50 -1 -1 0.000 0 0 7 0 0 2\n";
			print FIGFILE "\t $bar_left $join_bottom\n";
			print FIGFILE "\t $bar_right $join_bottom\n";
		}
	}

	print FIGFILE "-6\n";

	# Initialise state variables for children
	$child_left = ($bar_left - $box_width/2);
	$child_num = 0;
	$child_stagger = ($n_children > $max_children_line);
}

#	DhG_FigGen_Child() -  outputs a child to current fig file
#
#	Parameters:
#		1: child's surname
#		2: child's forename
#		3: child's date-of-birth
#		4: child's daate-of-death
sub DhG_FigGen_Child
{
	my ($c_surname, $c_forename, $c_dob, $c_dod) = @_;
	my ($box_top, $box_left, $box_row);

	if ( $child_stagger )
	{
		$box_left = $child_left + ($child_num * ($box_width + $child_gap))/2;
		if ( ($child_num % 2) == 0 )
		{
			$box_top = $child_top;
			$box_row = 1;
		}
		else
		{
			$box_top = $child_top + $box_height + $box_height/2;
			$box_row = 2;
		}
	}
	else
	{
		$box_left = $child_left + $child_num * ($box_width + $child_gap);
		$box_row = 1;
		$box_top = $child_top;
	}

	DhG_FigGen_PersonBox($box_left, $box_top, $c_surname, $c_forename, $c_dob, $c_dod, $box_row);

	$child_num++;
}

#	DhG_FigGen_PersonBox()	- output a person box to the current fig file
#
#	Parameters:
#		1:	left side of box
#		2:	top of box
#		3:	surname
#		4:	forename
#		5:	date-of-birth
#		6:	date-of-death
#		7:	row number:
#			0: parents' row
#			1: first row of children
#			2: second row of children
sub DhG_FigGen_PersonBox
{
	my ($box_left, $box_top, $p_surname, $p_forename, $p_dob, $p_dod, $box_row) = @_;

	my $box_right = $box_left + $box_width;
	my $box_bottom = $box_top + $box_height;
	my $box_centre = ($box_left + $box_right)/2;
	my $text_1 = $box_top + 270;
	my $text_2 = $box_top + 540;
	my $text_3 = $box_top + 820;
	my $text_width = $box_width - 100;
	my $line_top = $box_top - $box_height/2;
	my $group_top = $box_top;

	if ( $box_row > 0 )
	{
		if ( $box_row > 1 )
		{
			$line_top = $box_top - 2 * $box_height;
		}
		else
		{
			$line_top = $box_top - $box_height/2;
		}

		$group_top = $line_top;
	}

	print FIGFILE "6 $box_left $group_top $box_right $box_bottom\n";

	if ( $box_row > 0 )
	{
		print FIGFILE "2 1 0 1 0 7 50 -1 -1 0.000 0 0 7 0 0 2\n";
		print FIGFILE "\t $box_centre $line_top\n";
		print FIGFILE "\t $box_centre $box_top\n";
	}

	print FIGFILE "2 4 0 1 0 7 50 -1 -1 0.000 0 0 7 0 0 5\n";
	print FIGFILE "\t $box_left $box_top\n";
	print FIGFILE "\t $box_right $box_top\n";
	print FIGFILE "\t $box_right $box_bottom\n";
	print FIGFILE "\t $box_left $box_bottom\n";
	print FIGFILE "\t $box_left $box_top\n";

	print FIGFILE "4 1 0 50 -1 $forename_font $forename_pt 0.0000 4 150 $text_width $box_centre $text_1 $p_forename\\001\n";
	print FIGFILE "4 1 0 50 -1 $surname_font $surname_pt 0.0000 4 150 $text_width $box_centre $text_2 $p_surname\\001\n";
	print FIGFILE "4 1 0 50 -1 $dobdod_font $dobdod_pt 0.0000 4 105 $text_width $box_centre $text_3 $p_dob - $p_dod\\001\n";

	print FIGFILE "-6\n";
}
