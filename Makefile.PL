#
#   Makefile.PL for Glade-Perl based on a file donated by Robert Schwebel
#
require 5.000;
use ExtUtils::MakeMaker;

# Versions to check for held somewhere obvious
my $need_version = {
    'Perl'          => '5.000',     # Done above
    'gtk+'          => '1.2.3',     # Possibly trust Gtk-Perl to have done it
    'Gtk-Perl'      => '0.6123',
    'XML::Parser'   => '2.19',
    'glade'         => '0.5.3',     # Not absolutely necessary yet
};

# Do the version checking

# Last of all generate the Makefile
WriteMakefile(
    'DISTNAME'     => 'Glade-Perl',
    'NAME'         => 'Glade',
    'VERSION_FROM' => 'Glade/PerlRun.pm',
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);

exit(0);

# End of Makefile.PL
