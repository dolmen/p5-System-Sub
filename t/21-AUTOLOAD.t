
use strict;
use warnings;

use Test::More (-x '/bin/hostname' ? (tests => 3)
                                   : (skip_all => 'No /bin/hostname'));

{
    package cmd;
    use System::Sub::AutoLoad;
}

my $expected = `hostname`;
chomp $expected;

my $got = cmd::hostname();
is($got, $expected, 'scalar context');

$_ = 'canary';
my @got = cmd::hostname();
is_deeply(\@got, [ $expected ], 'list context');
is( $_, 'canary', '$_ not changed' );

# vim:set et sw=4 sts=4:
