#!/usr/bin/perl -w
#
# Dh_FileList.pm - assorted functions for creating a list of files
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

package Dh_FileList;

use File::Find;
use Exporter();
@ISA = qw(Exporter);
@EXPORT  =
(
	DhFL_FileList
);

sub DhFL_Found;
sub DhFL_Filter;

my %find_options =
(	"wanted" => \&DhFL_Found,
	"preprocess" => \&DhFL_Filter
);

my $DBG = 0;
my @file_list;
my $n_files = 0;

return 1;

# DhFL_FileList() - return a list of files
#
# Parameter(s): list of filenames, directory names ...
#
# Returns a list of all the (readable, normal) files in the given list.
# Directories are recursed.
# "Hidden" files and directories are ignored.
sub DhFL_FileList
{
	my @args = @_;
	my $i = 0;
	my $arg;
	my @dir_list;
	my $n_dirs = 0;

	@file_list = ();
	$n_files = 0;

	while ( defined $args[$i] )
	{
		$arg = $args[$i];
		if ( -r $arg )
		{
			if ( -f $arg )
			{
				print "Given: $arg\n" if ( $DBG > 99 );
				$file_list[$n_files] = $arg;
				$n_files++;
			}
			elsif ( -d $arg )
			{
				$dir_list[$n_dirs] = $arg;
				$n_dirs++;
			}
			else
			{
				print "Special file: $arg\n" if ( $DBG > 99 );
			}
		}
		else
		{
			print "Unreadable: $arg\n" if ( $DBG > 99 );
		}

		$i++;
	}

	find(\%find_options, @dir_list);

	return @file_list;
}

# DhFL_Found() - callback for find().
#
# $File::Find::dir is the current directory name,
# $_ is the current filename within that directory
# $File::Find::name is the complete pathname to the file.
sub DhFL_Found
{
	my $f = $File::Find::name;
	my $b = $_;
	print "Found: $f\n" if ( $DBG > 99 );

	if ( -r $b && -f $b )
	{
		$file_list[$n_files] = $f;
		$n_files++;
	}
}

# DhFL_Filter() - callback for find().
#
# Parameters: list of files
# $File::Find::dir
#
# Returns: filtered list of files
sub DhFL_Filter
{
	my @in = @_;
	my @out;
	my $i = 0;
	my $j = 0;

	print "Preprocess: $File::Find::dir\n" if ( $DBG > 99 );

	while ( defined $in[$i] )
	{
		if ( $in[$i] =~ m{^\.} )
		{
			print "Ignored: $in[$i]\n" if ( $DBG > 99 );
		}
		else
		{
			$out[$j] = $in[$i];
			$j++;
		}
		$i++;
	}

	return @out;
}
