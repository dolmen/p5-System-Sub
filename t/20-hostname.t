
use strict;
use warnings;

use Test::More (-x '/bin/hostname' ? (tests => 2)
                                   : (skip_all => 'No /bin/hostname'));

use System::Sub hostname => [ '$0' => '/bin/hostname' ];

my $expected = `hostname`;
chomp $expected;

my $got = hostname;
is($got, $expected, 'scalar context');

my @got = hostname;
is_deeply(\@got, [ $expected ], 'list context');

# vim:set et sw=4 sts=4:
