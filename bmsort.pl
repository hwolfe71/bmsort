#!/usr/bin/perl -s
#
# File:
#	bmsort.pl
#
# Version:
#	1.0 - September 2003
#
# Author:
#	Herb Wolfe, Jr
#	hwolfe@inetnebr.com
#	http://incolor.inetnebr.com/hwolfe
#	http://incolor.inetnebr.com/hwolfe/computer/mysoftware/bmsort
#
# Description:
#	This program sorts a Netscape/Mozilla bookmark file, creating a
#	backup copy. Bookmarks are sorted, case insensitive, with links before
#	folders and by web page title by default. Links with the same title
#	are sorted by url. Separators are kept in place, ie, links after the
#	separator are kept after it.
#
# Options:
#	$f = folders sorted first
#	$U = sort by urls instead of web page title

# Initialization

$file = "bookmarks.html";
$bakfile = "bookmarks.bak";

# <hr> string key, to keep groupings together
$HR = "_HR_"; 

# </dl> string key, for end of folder
$dlstr = "_3_"; 

# Strings to add to keys to sort with folders first, or urls first

if ($f) {
	$fstr = "_1_";
	$ustr = "_2_";
} else {
	$fstr = "_2_";
	$ustr = "_1_";
}

open (IN, $file) || 
	die "can't open bookmarks.html\n";

print "Processing bookmarks\n";

# Read heading
do {
	$_ = <IN>;
	$header .= $_;
	if (/<H1>/) {
		($folder) = />([^<]+)</;
	}
} until /<DL>/;

# $end is the last line in bookmark file, usually </dl><p>
$end = &ProcessFolder($folder);

close (IN);

rename ($file, $bakfile) ||
	die "can't rename $file\n";

open (OUT, ">$file") ||
	die "can't open $file for writing\n";
print OUT $header;

# Sort keys, ignoring case, printing out values

print "Writing output to $file\n";
foreach $keys (sort {uc($a) cmp uc($b)} (keys %bm ) ) {
	print OUT "$bm{$keys}";
}
print OUT $end;

close (OUT);

#-------------------------------------------------

sub ProcessFolder {
	local ($key) = @_;
	local ($tempkey, $value);
	$tempkey = $key;

	while (<IN>) {

		if (/<H3/) {
			# Create entry for folder & process it
			$bm{$tempkey} = $value unless $value eq "";
			$value = $_;
			($folder) = /<H3[^>]+>([^<]+)</;
			$tempkey = join("", $key, $fstr, $folder);
			do {
				$_ = <IN>;
				$value .= $_;
			} until /<DL>/;
			$bm{$tempkey} = $value unless $value eq "";
			$value = &ProcessFolder($tempkey);
			$tempkey .= $dlstr;
			$bm{$tempkey} = $value unless $value eq "";
			$tempkey = $key;
			$value = "";
		} elsif (/<HR>/) {
			# Create entry for separator
			$bm{$tempkey} = $value unless $value eq "";
			$key .= $HR;
			$tempkey = $key;
			$value = $_;
			$bm{$tempkey} = $value unless $value eq "";
			$value = "";
		} elsif (/<A HREF=/) {
			# Create entry for link
			$bm{$tempkey} = $value unless $value eq "";
			($url, $title) = /<A HREF="([^"]+)"[^>]+>([^<]+)</ ;
			$tempkey = join ("", $key, $ustr, ($U ? $url : $title.$url));
			$value = $_;
			$bm{$tempkey} = $value unless $value eq "";
		} elsif (m#</DL>#) {
			# End of folder, add and return
			$bm{$tempkey} = $value unless $value eq "";
			return ($_);
		} else {
			# Everything else, append to current value
			# should just be bookmark descriptions
			$value .= $_;
		} 
	} 
} 
