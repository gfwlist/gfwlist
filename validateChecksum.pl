#!/usr/bin/perl

#############################################################################
# This is a reference script to validate the checksum in downloadable       #
# subscription. This performs the same validation as Adblock Plus when it   #
# downloads the subscription.                                               #
#                                                                           #
# To validate a subscription file, run the script like this:                #
#                                                                           #
#   perl validateChecksum.pl subscription.txt                               #
#                                                                           #
# Note: your subscription file should be saved in UTF-8 encoding, otherwise #
# the validation result might be incorrect.                                 # 
#                                                                           #
# 20100418: Stolen from ABP with minor modification for AutoProxy project   #
#############################################################################

use strict;
use warnings;
use Digest::MD5 qw(md5_base64);

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $data = readFile($file);

# Normalize data
$data =~ s/\r//g;
$data =~ s/\n+/\n/g;

# Extract checksum

# Remove checksum
$data =~ s/^\s*!\s*checksum[\s\-:]+([\w\+\/=]+).*\n//mi;
my $checksum = $1;
die "Error: couldn't find a checksum in the file\n" unless $checksum;

# Calculate new checksum
my $checksumExpected = md5_base64($data);

# Compare checksums
die "Error: invalid checksum\n" unless $checksum eq $checksumExpected;

sub readFile
{
  my $file = shift;

  open(local *FILE, "<", $file) || die "Error: could not read file '$file'";
  binmode(FILE);
  local $/;
  my $result = <FILE>;
  close(FILE);

  return $result;
}
