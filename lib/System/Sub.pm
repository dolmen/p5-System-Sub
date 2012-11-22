use strict;
use warnings;
package System::Sub;

use File::Which ();
use Sub::Name 'subname';
use Symbol 'gensym';
use IPC::Run qw(start finish);


my %OPTIONS = (
    # Value is the expected ref of the option value
    # undef is no value
    '>' => '',
    '<' => '',
);

sub _croak
{
    require Carp;
    goto &Carp::croak
}

sub _carp
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
        _croak "invalid arg: SCALAR expected" unless defined ref $name && ! ref $name;
        my $fq_name;
        if (index($name, ':') > 0) {
            $fq_name = $name;
            $name = substr($fq_name, 1+rindex($fq_name, ':'));
        } else {
            $fq_name = $pkg.'::'.$name;
        }

        if ($name eq 'AUTOLOAD') {
            no strict 'refs';
            *{$fq_name} = \&_AUTOLOAD;
            next
        }

        my $cmd = $name;
        my @args;
        my %options;
        my $options = (@_ && ref $_[0]) ? shift : [];
        while (@$options) {
            my $opt = shift @$options;
            if ($opt eq '--') {
                _croak 'duplicate @ARGV' if $options{'@ARGV'};
                $options{'@ARGV'} = $options;
                last
            } elsif ($opt eq '$0') {
                $cmd = shift @$options;
            } elsif ($opt eq '@ARGV') {
                @args = @{ shift @$options };
            } elsif (! exists ($OPTIONS{$opt})) {
                _carp "unknown option $opt";
            } elsif (defined $OPTIONS{$opt}) {
                my $value = shift @$options;
                if (ref $OPTIONS{$opt}) {
                    _croak "invalid value for option $opt"
                } elsif (ref($value) ne $OPTIONS{$opt}) {
                    _croak "invalid value for option $opt"
                }
                $options{$opt} = $value;
            } else {
                $options{$opt} = 1;
            }
        }

        my $sub;

        # The result might be undef
        #unless (my $cmdpath = File::Which::which(delete $options{'$0'})) {
        #unless (my $cmdpath = File::Which::which(delete $options{'$0'})) {
        if (0) {
            $sub = sub { _croak "'$name' not found in PATH" };
        } else {
            $sub = _build_sub($name, [ $cmd, @args ], \%options);
        }

        no strict 'refs';
        *{$fq_name} = subname $fq_name, $sub;
    }
}

sub _build_sub
{
    my ($name, $cmd, $options) = @_;

    return sub {
        my ($input, $output_cb);
        $output_cb = pop if ref $_[$#_] eq 'CODE';
        $input = pop if ref $_[$#_];
        my @cmd = (@$cmd, @_);
        print join(' ', '[', (map { / / ? qq{"$_"} : $_ } @cmd), ']'), "\n";
        my $h;
        my $out = gensym; # IPC::Run needs GLOBs
        if ($input) {
            my $in = gensym;
            $h = start \@cmd,
                       '<pipe', $in, '>pipe', $out or die $!;
            binmode($in, $options->{'>'}) if exists $options->{'>'};
            if (ref $input eq 'ARRAY') {
                print $in map { "$_$/" } @$input;
            } elsif (ref $input eq 'SCALAR') {
                # use ${$input}} as raw input
                print $in $$input;
            }
            close $in;
        } else {
            $h = start \@cmd, \undef, '>pipe', $out or die $!;
        }
        binmode($out, $options->{'<'}) if exists $options->{'<'};
        if (wantarray) {
            my @output;
            if ($output_cb) {
                while (<$out>) {
                    chomp;
                    push @output, $output_cb->($_)
                }
            } else {
                while (<$out>) {
                    chomp;
                    push @output, $_
                }
            }
            close $out;
            finish $h;
            _croak "$name error ".($?>>8) if $? >> 8;
            return @output
        } elsif (defined wantarray) {
            # Only the first line
            my $output;
            defined($output = <$out>) and chomp $output;
            close $out;
            finish $h;
            _croak "$name error ".($?>>8) if $? >> 8;
            _croak "no output" unless defined $output;
            return $output
        } else { # void context
            if ($output_cb) {
                while (<$out>) {
                    chomp;
                    $output_cb->($_)
                }
            }
            close $out;
            finish $h;
            _croak "$name error ".($?>>8) if $? >> 8;
            return
        }
    }
}

sub _AUTOLOAD
{
    no strict 'refs';
    my $fq_name = our $AUTOLOAD;
    my $name = substr($fq_name, 1+rindex($fq_name, ':'));
    my $path = File::Which::which($name);
    _croak "'$name' not found in PATH" unless defined $path;
    *$fq_name = subname $name, _build_sub($name, [ $path ], { });
    goto &$fq_name
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
