#!/usr/bin/env perl
# bmp.pl -- read, parse and operate on BMP headers and data, because why the fuck not?

use warnings;
use strict;

sub word { (pop() <<  8) | pop() }
sub unpack_w { map { $_[0] >> $_ & 0xff } 0, 8 }
sub read_w {
	sysread pop, my $buf, 2;
	word(unpack "C*", $buf);
}

sub dword { (pop() << 24) | (pop() << 16) | (pop() << 8) | pop() }
sub unpack_dw { map { $_[0] >> $_ & 0xff } 0, 8, 16, 24 }
sub read_dw {
	sysread pop, my $buf, 4;
	dword(unpack "C*", $buf);
}

open my $fin, '<', $ARGV[0] or die $!;

#
# BMP header
#

use constant BMP_HEADER_SIZE => 14;

printf "BMP header size: 0x%02x (%db)\n", BMP_HEADER_SIZE, BMP_HEADER_SIZE;

my $magic = read_w($fin);
printf "magic: 0x%02x (%c%c)\n", $magic, unpack_w($magic);

my $bmp_file_sz = read_dw($fin);
printf "file size: 0x%04x (%db)\n", $bmp_file_sz, $bmp_file_sz;

# possible bytes to hide data in?
read_w($fin);  # reserved, not used
read_w($fin);  # reserved, not used

my $px_array_offset = read_dw($fin);
printf "pixel array offset: 0x%04x\n", $px_array_offset;
print "\n";

#
# DIB header
#

my $dib_sz = read_dw($fin);
printf "DIB header size: 0x%02x (%db)\n", $dib_sz, $dib_sz;
die "only handles 40-byte DIB headers, for now\n" unless $dib_sz == 40;

my ($img_w, $img_h) = (read_dw($fin), read_dw($fin));
printf "image size: %dx%d\n", $img_w, $img_h;

my $n_planes = read_w($fin);

my $bpp = read_w($fin);
printf "bits per pixel: %d\n", $bpp;
die "only supports bpp > 8, for now\n" if $bpp < 8;

my $compression_type = read_dw($fin);
die "we don't do compressed images, yet\n" if $compression_type != 0;

my $image_size = read_dw($fin);
my ($res_horiz, $res_vert) = (read_dw($fin), read_dw($fin));
my $n_colors = read_dw($fin);
my $n_colors_imptnt = read_dw($fin);

print "\n";

#
# pixel array
#

my %unpack_px_f = (
	1  => sub {},  # handling these two will required
	4  => sub {},  # some code change down there.
	8  => sub {},
	16 => sub {},
	24 => sub { @_[2,1,0], undef },  # b, g, r
	32 => sub {},
);

my $px_sz = $bpp / 8;
die "we don't operate on the bit level here, yet\n" if $px_sz < 0;

my $row_sz = 4 * int(($bpp * $img_w + 31) / 32);
printf "row size: %d\n", $row_sz;

my $px_arr_sz = $row_sz * abs($img_h);
printf "pixel array size: %d\n", $px_arr_sz;

my $file_sz = BMP_HEADER_SIZE + $dib_sz + $px_arr_sz;
printf "file size: 0x%x (%db)\n", $file_sz, $file_sz;

for (1 .. abs($img_h)) {
	sysread($fin, my $row, $row_sz) or die "unexpected EOF";

	my @b = unpack "C*", $row;
	my $i = 0;
	while ($i < @b) {
		#printf "[%d, %d]\n", $i, $i + $px_sz - 1;
		if ($i + $px_sz > @b) {
			# padding bytes
			#printf "padding: 0x%02x 0x%02x\n", @b[$i .. $i + $px_sz - 1];
			last;
		}

		my ($r, $g, $b, $a) = $unpack_px_f{$bpp}->(@b[$i .. $i + $px_sz - 1]);

		###############################
		# do something with the pixel #
		###############################

		$i += $px_sz;
	}
}

close $fin;
