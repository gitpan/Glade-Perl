package Glade::PerlGenerate;
require 5.000; use English; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to the
# author, who can be contacted at dermot.musgrove@virgin.net

BEGIN {
    use Glade::PerlProject;             # Project vars and methods
    use Glade::PerlSource qw( :VARS  ); # Source writing vars and methods
    use Glade::PerlUI     qw( :VARS );  # UI construction vars and methods
    use vars              qw( 
                            @ISA 
                            $VERSION
                            $PACKAGE 
                          );
    $PACKAGE        = __PACKAGE__;
    $VERSION        = q(0.43);
    # Tell interpreter who we are inheriting from
    @ISA            = qw(
                            Glade::PerlProject
                            Glade::PerlSource 
                            Glade::PerlUI
                        );
}

#===============================================================================
#=========== Utilities to run Generate phase                        ============
#===============================================================================
sub about_Form {
    my ($class) = @ARG;
    my $gtkversion     = 
        Gtk->major_version.".".Gtk->minor_version.".".Gtk->micro_version;
    my $name = $0;
    my $message = 
        "$PACKAGE (".
        "version: $VERSION - $DATE)\n".
        "Written by: $AUTHOR\n\n".
        "Gtk version: $gtkversion\n".
        "Gtk-Perl version:    $Gtk::VERSION\n\n".
        "run from file:        $name";
    my $widget = $PACKAGE->message_box($message, 
        "About \u$PACKAGE", 
        ['Dismiss', 'Quit Program'], 1, $project->logo, 'left' );
}

sub destroy_Form {
    my ($class) = @ARG;
    $class->get_toplevel->destroy;
    Gtk->main_quit; 
}

#===============================================================================
#=========== Utilities to construct the form from a Proto                   ====
#===============================================================================
sub Form_from_Glade_File {
    my ($class, %params) = @ARG;
    my $me = "$class->Form_from_Glade_File";
    my $glade_proto = $class->Proto_from_File( $params{'glade_filename'}, 
        ' project child accelerator ', ' signal widget ' );
    $params{'use_modules'} = ($params{'use_modules'} || 
        [split (/\n/, ($main::Glade_Perl_Generate_options->use_modules || '' ))]);
    $glade_proto->{'glade_filename'} = $params{'glade_filename'};    
    $glade_proto->{'name'} = $glade_proto->{'project'}{'name'};
    $project = $class->use_Glade_Project($glade_proto );
    $project->GTK_Interface($glade_proto->{'project'});
    $current_form && eval "$current_form = {};";
    my $window = $class->Form_from_Pad_Proto($project, $glade_proto, \%params );
    return $window;
}

sub Form_from_XML {
    my ($class, %params) = @ARG;
    my $me = "$class->Form_from_XML";
    my $save_options = $main::Glade_Perl_Generate_options;
    $main::Glade_Perl_Generate_options->verbose(0);
    $main::Glade_Perl_Generate_options->write_source(undef);
    my $glade_proto = $class->Proto_from_XML( $params{'xml'}, 
        ' project child accelerator ', ' signal widget ' );
    $glade_proto->{'glade_filename'} = 'XML String';
    my $form;
    $indent = ' ';
    $form->{'GTK_Interface'} = $glade_proto->{'project'};
    $project = $form;
    if ($main::Glade_Perl_Generate_options->allow_gnome) {
        $class->diag_print (6, "$indent- Use()ing Gnome in $me");
        Gnome->init('Form_from_XML', '0.0.0');
    } else {
        Gtk->init;
    }
    my $window = $class->Widget_from_Proto(
        'No Parent', $glade_proto, 0, 'Form from string' );
    $forms->{$first_form}{$first_form}->show( );
    Gtk->main;
    $main::Glade_Perl_Generate_options = $save_options;
    return $window;
}

# FIXME to read a stream (not just a string) and parse/build as we go
# This means providing handlers for XML::Parser (Start, End, Char)
# when it is run in 'Stream' mode
sub Form_from_XML_Stream {
    my ($class, $params) = @ARG;
    my $me = "$class->Form_from_XML";
    my $save_options = $main::Glade_Perl_Generate_options;
    $main::Glade_Perl_Generate_options->verbose(0);
    $main::Glade_Perl_Generate_options->write_source(undef);
    my $proto = $class->Proto_from_XML( $params->{'xml'}, 
        ' project child accelerator ', ' signal widget ' );
    $proto->{'class'} = 'Application';    
    my $form = $class->use_Glade_Project($proto );
    $form->{'GTK_Interface'} = $proto->{'project'};
    $project = $form;
    if ($main::Glade_Perl_Generate_options->allow_gnome) {
        $class->diag_print (6, "$indent- Use()ing Gnome in $me");
        Gnome->init('Form_from_XML', '0.0.0');
    } else {
        Gtk->init;
    }
    my $window = $class->Widget_from_Proto(
        'No Parent', $proto, 0, $proto->{'class'} );
    eval "${first_form}->show( );" ;
    Gtk->main;
    $main::Glade_Perl_Generate_options = $save_options;
    return $window;
}

sub Form_from_Pad_Proto {
    my ($class, $proto, $glade_proto, $params) = @ARG;
    my $me = "$class->Form_from_Pad_Proto";
    my $depth = 0;
    $forms = {};
    $widgets = {};
    my ($module);
#    my ($handler, $module, $form );
    foreach $module (@{$params->{'use_modules'}}) {
        if ($module && $module ne '') {
            eval "use $module;" or
                ($EVAL_ERROR && 
                    die  "\n\nin $me\n\twhile trying to eval 'use $module'".
                         "\n\tFAILED with Eval error '$EVAL_ERROR'\n" );
            push @use_modules, $module;
            $class->diag_print (2, "$indent- Use()ing existing module '$module' in $me");
        }
    }
    if ($main::Glade_Perl_Generate_options->allow_gnome) {
        $class->diag_print (6, "$indent- Use()ing Gnome in $me");
        eval "use Gnome;";
        Gnome->init(__PACKAGE__, $VERSION);
    } else {
        Gtk->init;
    }

    # Recursively generate the UI
    my $window = $class->Widget_from_Proto( $glade_proto->{'name'}, 
        $glade_proto, $depth, 'Top Level Application' );

    # And show it if necessary
    unless ($class->Writing_Source_only) { 
        $forms->{$first_form}{$first_form}->show;
    }

    # Now write the disk files
    if ($class->Writing_to_File) {
        $class->write_UI($proto, $glade_proto);
# FIXME write these subs in PerlSource
        $class->write_SUBCLASS($proto, $glade_proto);
#        $class->write_Documentation($proto, $glade_proto);
#        $class->write_dist($proto, $glade_proto);
    }
    $module = "$glade_proto->{'project'}{'source_directory'}";
    $module =~ s/.*\/(.*)$/$1/;
    # Look through $proto and report any unused attributes (still defined)
    if ($class->diagnostics(2)) {
        $class->diag_print (2, "-----------------------------------------------------------------------------");
        $class->diag_print (2, "$indent  CONSISTENCY CHECKS");
        $class->diag_print (2, "$indent- $missing_widgets unused widget properties");
        $class->diag_print (2, "$indent- $ignored_widgets widgets were ignored (one or more of '$ignore_widgets')");
        $class->diag_print (2, "$indent- ".$class->unpacked_widgets." unpacked widgets");
#        $class->diag_print (2, "$indent- ".$class->unhandled_signals." unhandled signals");
        $class->diag_print (2, "-----------------------------------------------------------------------------");
        $class->diag_print (2, "$indent  UI MESSAGES - showing missing_handler calls that you triggered, ".
                "don't worry, $PACKAGE will generate dynamic stubs for them all");
    }

    my $endtime = `date`;
    chomp $endtime;
    $class->diag_print (2, 
        $indent."  GENERATION RUN COMPLETED by $PACKAGE (version $VERSION) at $endtime");
        $class->diag_print (2, 
            "-----------------------------------------------------------------------------");
    $class->diag_print (2, 
        "$indent- One way to run the generated source from dir '$project->{'directory'}/':\n".
        "${indent}${indent}perl -e 'use $module\::".
            "$glade_proto->{'project'}{'name'}; ".
            "${first_form}->run'");
    $class->diag_print (2, 
            "-----------------------------------------------------------------------------");
    unless ($class->Writing_Source_only) { Gtk->main; }
    # We are finished with these attributes now so 'use them up'
    undef $glade_proto->{'project'}{'directory'};
    undef $glade_proto->{'project'}{'pixmaps_directory'};
    undef $glade_proto->{'project'}{'source_directory'};
    undef $glade_proto->{'glade_filename'};

    return $proto;
}

#===============================================================================
#=========== Diagnostic utilities                                   ============
#===============================================================================
sub unused_elements {
    my ($class, $proto) = @ARG;
    my $me = "$class->unused_elements";
    my $typekey = $class->typeKey;
    my $key;
    my ($object,$name );
    foreach $key (sort keys %{$proto}) {
        if (defined $proto->{$key}) {
            unless (" class $typekey name " =~ m/ $key /) {
                unless (ref $proto->{$key}) {
                    # We have found an unused element
                    unless ($proto->{$typekey} eq 'project') {
                    $object = $proto->{'class'} || '';
                        $name = $proto->{'name'} || '(no name)';
                        $class->diag_print (1, "error Unused widget property for ".
                            "$proto->{$typekey} $object ".
                            "{'$name'}{'$key'} => '$proto->{$key}' seen by $me");
                        $missing_widgets++;
                    }
                }
            }
        }
    }
    return $missing_widgets;
}

sub unpacked_widgets {
    my ($class) = @ARG;
    my $me = "$class->unpacked_widgets";
    my $count = 0;
    my $key;
    foreach $key (sort keys %{$widgets}) {
        if (defined $widgets->{$key}) {
            # We have found an unpacked widget
            $count++;
            $class->diag_print (1, "error Unpacked widget '$key' has not been packed ".
                "(nor correctly added to the UI file) from $me");
        }
    }
    return $count;
}

sub unhandled_signals {
    my ($class) = @ARG;
    my $me = "$class->unhandled_signals";
    my ($widget, $signal);
    my $count = 0;
# FIXME This is all tosh - what do we need here?    
# FIXME Should we produce stubs for these ? if so, do this in perl_sub etc

    foreach $widget (sort keys %{$need_handlers}) {
#        if (keys (%{$need_handlers->{$widget})) {
            foreach $signal (sort keys %{$need_handlers->{$widget}}) {
                # We have found an unhandled signal (eg from accelerator)
                $count++;
                $class->diag_print (1, "error Widget '$widget' emits a ".
                    "signal '$need_handlers->{$widget}{$signal}' that ".
                    "does not have a handler specified - in $me");
                    
            }
#        } else {
#            # Nothing to be done
#        }
    }
    return $count;
}

1;

__END__

#===============================================================================
#==== Documentation ============================================================
#===============================================================================
=pod

=head1 NAME

Glade::PerlGenerate - Generate Perl source from a Glade XML project file.

=head1 SYNOPSIS

 use Glade::PerlGenerate;


 # Choose the Generate run options. Some other examples are in test.pl script
 Glade::PerlGenerate->options(
  #  User option       Value       Meaning                         Default
 #  -----------       -----       -------                         -------
   'author'        => 'Dermot Musgrove <dermot.musgrove\@virgin.net>',
 # 'author'        => undef,      # Author string for sources eg  values from Perl's
                                  # 'My Name <my.email@some.org>' (gethostbyname("localhost"))
 # 'version'       => undef,      # Version number to use         0.0.1
 # 'date'          => undef,      # The date to show in sources   Build time of
 # 'copying'       => undef,      # Copying text to include     
   'description'   => "This is an example of the Glade-Perl
 source code generator",
   'verbose'       => 2,          # Level of verbosity            1
                                  # 0 (quiet) to 10 (all)
   'indent'        => '    ',     # Indent for source code        4 spaces)
   'tabwidth'      => 4,          # Number of spaces to replace   8
                                  # with a tab in source code
   'diag_wrap'     => 0,          # Wrap diagnostic messages      0 = no wrap
                                  # at this character (approx). 
                                  # 0 = no breaks (not easy to
                                  # read on 80 column displays)

   'write_source'  => 'True',     # Write to the default files    No source
 # 'write_source'  => 'STDOUT',   # Write sources to STDOUT
                                  # but there will be nothing 
                                  # to run later
 # 'write_source'  => 'File.pm',  # Write sources to File.pm
                                  # They will not run from here
                                  # you must cut-paste them
 # 'write_source'  => undef,      # Don't write source code

   'dont_show_UI'  => 'True',     # Show UI during the Build     Show UI
                                  # and wait for user action
   'autoflush'     => 'True',
   'use_modules'   => 'Example::BusForm_mySUBS',
 # 'site_options'  => 'File.xml', # Site options file name       /etc/gpgrc.xml
 # 'user_options'  => 'File.xml', # User options file name       ~/.gpgrc.xml
   'project_options' => $project_options_file, 
                                  # Project-specific options     Don't read file
   'allow_gnome'   => undef,      # Ignore/report Gnome widgets  Ignore Gnome
 # 'my_perl_gtk'   => '0.6123',   # I have CPAN version 0.6123   Use Gtk-Perl's version no
 # 'my_perl_gtk'   => '19991001', # I have the gnome.org CVS     Use Gtk-Perl's version no
                                  # version of 'gnome-perl' that 
                                  # I downloaded on Oct 1st 1999
 # 'my_gnome_libs' => '19991001', # I have the gnome.org CVS     Use gnome-libs version no
                                  # version of 'gnome-libs' that 
                                  # I downloaded on Oct 1st 1999
   'log_file'      => 'Test.log', # Diagnostics log file         use STD[OUT|ERR]
 );
        
 Then to generate the UI defined in a file
 Glade::PerlGenerate->Form_from_Glade_File(
   'glade_filename'=> "Example/BusForm.glade"
 );


 OR if you want to generate  the UI directly from an XML string
 Glade::PerlGenerate->Form_from_XML(
   'xml'           => $xml_string,
   'use_modules'   => ['Example::Project_mySUBS']
 );

=head1 DESCRIPTION

Glade::PerlGenerate reads a <GTK-Interface> definition from a Glade
file (or a string) using XML::Parser, converts it into a hash of hashes 
and works its way through this to show the UI using Gtk-Perl bindings. 
The module can also optionally generate Perl source code to show the UI 
and handle the signals. Any signal handlers that are specified in the 
project file but not visible at Generate time will be hijacked to show 
a 'missing_handler' message_box and a stub for it will be defined in the 
the UI class for dynamic AUTOLOAD()ing.

The stub will simply show a message_box to prove that the handler has been 
called and you can write your own with the same name in another module. You 
then quote this module to the next Generate run and Glade::PerlGenerate will 
use these handlers and not define stubs.


=head1 ERRORS and WARNINGS

The module will report several errors or warnings that warn of problems 
with the Glade file or other unexpected occurences. These are to help me 
cater for new widgets or widget properties and not because Glade creates 
inconsistent project files but they do point out errors in hand-edited XML.

=head1 FILES GENERATED

The Perl source to construct the UI is written to a .pm file called 
<project><name>.pm. . Each toplevel window/dialog has a class generated with 
code to construct it. 
An example subclass is generated in another .pm file called 
Sub<project><name>.pm which contains skeleton subs for every missing signal 
handler. It can be copied and edited to make a complete app.

=head1 SEE ALSO

Documentation that came with the module is in Directory 'Documentation' in 
files README, Changelog, FAQ, TODO, NEWS, ROADMAP etc.
 
The test file for 'make test' is test.pl which is runnable and has
examples of user options.
 
Perl script to generate source code from the Glade 'Build' button or menuitem
is in file 'glade2perl'

A module that subclasses the test example is in file Example/SubBus.pm. This
module will use inherit (subclass) the generated perl classes and also use
the supplied signal handlers module (Example/BusForm_mySUBS.pm)

=cut

