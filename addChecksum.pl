#!/usr/bin/perl

#############################################################################
# This is a reference script to add checksums to downloadable               #
# subscriptions. The checksum will be validated by AutoProxy on download    #
# and checksum mismatches (broken downloads) will be rejected.              #
#                                                                           #
# To add a checksum to a subscription file, run the script like this:       #
#                                                                           #
#   perl addChecksum.pl subscription.txt                                    #
#                                                                           #
# Note: your subscription file should be saved in UTF-8 encoding, otherwise #
# the generated checksum might be incorrect.                                #
#                                                                           #
#############################################################################

use strict;
use warnings;
use Digest::MD5 qw(md5_base64);
use File::stat;
use POSIX qw(locale_h);
use POSIX qw(strftime);

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $data = readFile($file);

# Remove already existing checksum
$data =~ s/^.*!\s*checksum[\s\-:]+([\w\+\/=]+).*\n//gmi;

# Update timestamp
setlocale(LC_TIME, "C");
my $timestamp = strftime("%a, %d %b %Y %H:%M:%S %z", localtime(stat($file)->mtime));
$data =~ s/^!\s*Last Modified:.*$/! Last Modified: $timestamp/mi;

# Calculate new checksum: remove all CR symbols and empty
# lines and get an MD5 checksum of the result (base64-encoded,
# without the trailing = characters).
my $checksumData = $data;
$checksumData =~ s/\r//g;
$checksumData =~ s/\n+/\n/g;

# Calculate new checksum
my $checksum = md5_base64($checksumData);

# Insert checksum into the file
$data =~ s/(\r?\n)/$1! Checksum: $checksum$1/;

writeFile($file, $data);

sub readFile
{
  my $file = shift;

  open(local *FILE, "<", $file) || die "Could not read file '$file'";
  binmode(FILE);
  local $/;
  my $result = <FILE>;
  close(FILE);

  return $result;
}

sub writeFile
{
  my ($file, $contents) = @_;

  open(local *FILE, ">", $file) || die "Could not write file '$file'";
  binmode(FILE);
  print FILE $contents;
  close(FILE);
}
