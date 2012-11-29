use strict;
use warnings;
package System::Sub::AutoLoad;

use System::Sub ();

sub _croak
{
    require Carp;
    goto &Carp::croak
}

# Storage for sub options until they are installed with the AUTOLOAD
my %AutoLoad;

sub import
{
    my $pkg = caller;
    shift;

    while (@_) {
        my $name = shift;
        _croak "invalid arg: SCALAR expected" unless defined ref $name && ! ref $name;
        my $fq_name = $pkg.'::'.$name;

        $AutoLoad{$fq_name} = shift if @_ && ref $_[0];

        # Create a forward declaration that will be usable by the Perl
        # parser. See subs.pm
        no strict 'refs';
        *{$fq_name} = \&{$fq_name};
    }

    # Install the AUTOLOAD sub
    no strict 'refs';
    *{$pkg.'::AUTOLOAD'} = \&_AUTOLOAD;
}

sub _AUTOLOAD
{
    my $fq_name = our $AUTOLOAD;

    my $options = delete $AutoLoad{$fq_name};
    System::Sub->import($fq_name, $options ? ($options) : ());

    no strict 'refs';
    goto &$fq_name
}

1;
__END__


# vim:set et sw=4 sts=4:
