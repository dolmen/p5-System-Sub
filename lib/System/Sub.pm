use strict;
use warnings;
package System::Sub;

use File::Which ();
use Sub::Name ();

my %OPTIONS = (
    # Value is the expected ref of the option value
    # undef is no value
    '$0' => '',
    '@ARGV' => 'HASHREF',
    '>' => '',
    '<' => '',
);

sub croak
{
    require Carp;
    goto &Carp::croak;
}

sub carp
{
    require Carp;
    goto &Carp::carp
}

sub import
{
    my $pkg = (caller)[0];
    shift;

    while (@_) {
        my $name = shift;
        # Must be a scalar
        croak "invalid arg: SCALAR expected" unless defined ref $cmd && ! ref $cmd;
        my %options;
        my $options = (@_ && ref $_[0]) ? shift : [];
        while (@$options) {
            my $opt = shift @$options;
            if ($opt eq '--') {
                croak "duplicate \@ARGV" if $options{'@ARGV'};
                $options{'@ARGV'} = $options;
                last;
            } elsif (exists ($OPTIONS{$opt}) {
                carp "unknown option $opt"
            } elsif (defined $OPTIONS{$opt}) {
                my $value = shift @$options;
                if (ref $OPTIONS{$opt}) {
                    croak "invalid value for option $opt"
                } elsif (ref($value) ne $OPTIONS{$opt}) {
                    croak "invalid value for option $opt"
                }
                $options{$opt} = $value;
            } else {
                $options{$opt} = 1;
            }
        }
        $options{'@ARGV'} = [] unless exists $options{'@ARGV'};
        $options{'$0'} = $name  unless exists $options{'$0'};

        my $sub;

        # The result might be undef
        unless (my $cmdpath = File::Which::which(delete $options{'$0'}) {
            $sub = sub { croak "'$cmd' not found in PATH" }
        } else {
            $sub = 
        }

        my $fq_name = $pkg.'::'.$name;
        no strict 'refs';
        ${$fq_name} = Sub::Name::subname $fq_name, $sub;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

System::Sub - Wraps external command with a DWIM sub

=head1 SYNOPSIS

    use System::Sub 'hostname';  # Just an example (use Sys::Hostname instead)

    # Scalar context : returns the first line of the output
    my $hostname = hostname;

=head1 DESCRIPTION

B<This is beta.> This documentation is either incomplete or wrong!

=head1 IMPORT OPTIONS

I<TODO>

=head1 SUB USAGE

=head2 Arguments

=head2 Return value(s)

=over 4

=item *

Scalar context

Returns just the first line (based on C<$/>), chomped or undef if no output.

=item *

List context

Returns a list of the lines of the output, based C<$/>.
The end-of-line chars (C<$/> are not in the output.

=back

I<TODO>

=head1 TRIVIA

I dreamed about such a facility for a long time. I even worked for two years on
a ksh framework that I created from scratch just because at the start of the
project I didn't dare to bet on Perl because of the lack of readability of the
code when most of the work is running other programs.

After that project I never really had the need to run the same command
in many places of the code, and in many different ways. Until I had the need
to wrap L<Git|http://git-scm.org/> in the
L<release|https://github.com/github-keygen/> script of my
L<github-keygen|https://github.com/github-keygen> project. I wrote the first
version of the wrapper there, and quickly extracted it as this module.
So, here is it!

Last but not least, the pun in the package name is intended.

=head1 AUTHOR

Olivier MenguE<eacute>, C<dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2012 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut

# vim:set et sw=4 sts=4:
