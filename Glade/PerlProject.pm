package Glade::PerlProject;
require 5.000; use strict 'vars', 'refs', 'subs';

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
    use Carp qw(cluck);
    $SIG{__DIE__}  = \&Carp::confess;
    $SIG{__WARN__} = \&Carp::cluck;

    use File::Path     qw( mkpath );        # in use_Glade_Project
    use File::Basename qw( dirname );       # in use_Glade_Project
    use Cwd            qw( chdir cwd );     # in use_Glade_Project
    use Sys::Hostname  qw( hostname );      # in use_Glade_Project
    use Text::Wrap     qw( wrap $columns ); # in options, diag_print
    use Glade::PerlSource qw(:VARS :METHODS ); # Source writing vars and methods
    use Glade::PerlXML;
    use vars           qw( 
                            @ISA 
                            $PACKAGE 
                            $VERSION
                            $xAUTOLOAD
                       );
    $PACKAGE        = __PACKAGE__;
    $VERSION        = q(0.52);
    # Tell interpreter who we are inheriting from
    @ISA            = qw( 
                            Glade::PerlXML 
                            Glade::PerlSource
                        );
}

my %fields = (
    # These are the data fields that you can set/get using
    # the dynamic calls provided by AUTOLOAD.
    # eg $class->UI($new_value);        sets the value of UI
    #    $current_value = $class->UI;   gets the current value of UI
# Project
#--------
    'author'            => undef,   # Name to appear in generated source
    'version'           => '0.01',  # Version to appear in generated source
    'date'              => undef,   # Date to appear in generated source
    'copying'           =>          # Copying policy to appear in generated source
        '# Unspecified copying policy, please contact the author\n# ',
    'description'       => undef,   # Description for About box etc.
    'use_modules'       => undef,   # Existing signal handler modules
    'allow_gnome'       => undef,   # Dont allow gnome widgets
    'gettext'           => undef,   # Do we want gettext type code
    'start_time'        => undef,   # Time that this run started
    'project_options'   => undef,   # Dont read or save options in disk file
#    'options_filename'  => undef,   # Dont read or save options in disk file
    'options_set'       => 'DEFAULT', # Who set the options

# UI
#---
    'glade_proto'       => undef,
    'pixmaps_directory' => undef,
    'logo'              => 'Logo.xpm', # Use specified logo
    'glade2perl_logo'   => 'glade2perl_logo.xpm',
#    'logo'              => undef,   # No defined project logo

# Source code
#------------
    'indent'            => '    ',  # Source code indent per Gtk 'nesting'
    'tabwidth'          => 8,       # Replace each 8 spaces with a tab in sources
    'write_source'      => undef,   # Dont write source code
    'dont_show_UI'      => undef,   # Show UI and wait
    'hierarchy'         => '',      # Dont generate any hierarchy
                                    # widget... 
                                    #   eg $hier->{'vbox2'}{'table1'}...
                                    # class... startswith class
                                    #   eg $hier->{'GtkVBox'}{'vbox2'}{'GtkTable'}{'table1'}...
                                    # both...  widget and class
    'style'             => 'AUTOLOAD', # Generate code using OO AUTOLOAD code
                                    # Libglade generate libglade code
                                    # closures generate code using closures
                                    # Export   generate non-OO code
    'source_LANG'       => ($ENV{'LANG'} || ''), 
                                    # Which language we want the source to be in
    
# Diagnostics
#------------
    'verbose'           => 2,       # Show errors and main diagnostics
    'diag_wrap'         => 0,       # Max diagnostic line length (approx)
    'diag_file'         => undef,   # Diagnostics log file name
    'autoflush'         => undef,   # Dont change the policy
    'benchmark'         => undef,   # Dont add time to the diagnostic messages
    'log_file'          => undef,   # Write diagnostics to STDOUT 
                                    # or Filename to write diagnostics to
    'diag_LANG'         => ($ENV{'LANG'} || ''),
                                    # Which language we want the diagnostics
#    'debug'             => 'True',  # For my testing and debugging.

# Distribution
#--------------
    'dist_type'         => undef,   # Type of distribution
    'dist_compress'     => undef,   # How to compress the distribution
    'dist_scripts'      => undef,   # Scripts that should be installed
    'dist_docs'         => undef,   # Documentation that should be included

# Helpers
#--------
    'editors'           => undef,   # Editor calls that are available
    'active_editor'     => undef,   # Index of editor that we are using
    'my_perl_gtk'       => undef,   # Get the version number from Gtk-Perl
                                    # '0.6123'   we have CPAN release 0.6123 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
    'my_gnome_libs'     => undef,   # Get the version number from gnome_libs
                                    # '1.0.8'    we have release 1.0.8 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
);

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self  = {
    _permitted_fields   => \%fields, %fields,
  };
  bless $self, $class;
  return $self;
}

sub xAUTOLOAD {
  my $self = shift;
  my $i = 1;
  my $AUTOLOAD;
  my $type = ref($self)
    or die "$self is not an object so we cannot '$AUTOLOAD'\n",
      "We were called from ".join(", ", caller)."\n\n";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;       # strip fully-qualified portion

  if (exists $self->{_permitted_fields}->{$name} ) {
    # This allows dynamic data methods - see %fields above
    # eg $class->UI('new_value');
    # or $current_value = $class->UI;
    if (@_) {
      return $self->{$name} = shift;
    } else {
      return $self->{$name};
    }

  } else {
      die sprintf("Can't access method `%s' in class %s\n",
          $name, $type);

  }
}

#===============================================================================
#=========== Diagnostics utilities                                  ============
#===============================================================================
sub verbosity            { $Glade_Perl->{'options'}->verbose }
sub Writing_to_File      { $Glade_Perl->{'options'}->write_source }
sub Building_UI_only     {!defined $Glade_Perl->{'options'}->write_source }
sub Writing_Source_only  { $Glade_Perl->{'options'}->dont_show_UI }

sub diagnostics { 
    ($_[1] || 1) <= ($Glade_Perl->{'options'}->verbose);
}

sub diag_print {
    my $class = shift;
    my $level = shift;
    return unless $class->diagnostics($level);
    my $message = shift;
    my $options = $Glade_Perl->{'options'};
    my @times = times;
    my $time='';
    if ($options->benchmark) {
        $time = int( $times[0] + $times[1] );
    }
    unless (ref $message) {
        $message = sprintf(D_($message, 2), @_);
        print STDOUT wrap($time, 
            $options->indent.$options->indent, "$message\n");

    } else {
        $class->diag_ref_print($level, $message, @_);
    }
}

sub diag_ref_print {
    my ($class, $level, $message, $desc, $pad) = @_;
    return unless $class->diagnostics($level);
    my $options = $Glade_Perl->{'options'};
    my ($key, $val, $ref);
    my $padkey = $pad || 17;
    my $title = D_($desc || "");
    my @times = times;
    my $time='';
    $ref = ref $message;
    if ($options->benchmark) {
        $time = int( $times[0] + $times[1] );
    }
    unless ($ref) {
         print STDOUT wrap($time, 
            $time.$options->indent.$options->indent, "$message\n");

    } elsif (($ref eq 'HASH') or ( $ref =~ /Glade::/)) {
        print STDOUT "$title $ref ",D_("contains"), ":\n";
        foreach $key (sort keys %$message) {
            my $ref = ref $message->{$key};
            if (ref $message->{$key}) {
                print STDOUT "        {'$key'}".
                    (' ' x ($padkey-length($key))).
                    " => ", D_("is a reference to a"), " $ref\n";
            } elsif (defined $message->{$key}) {
                print STDOUT "        {'$key'}".
                    (' ' x ($padkey-length($key))).
                    " => '$message->{$key}'\n";
            } else {
                print STDOUT "        {'$key'}\n";
            }
            $val = (ref ) || $message->{$key} || 'undef';
        }

    } elsif ($ref eq 'ARRAY') {
        print STDOUT "$title $ref ", D_("contains"), ":\n";
		my $im_count = 0;
	    foreach $val (@$message) {
			$key = sprintf "[%d]", $im_count;
			$ref = ref $val;
            if ($ref) {
                print STDOUT "        $key".(' ' x ($padkey-length($key))).
                    " = ", D_("is a reference to a"), " $ref\n";
            } elsif (defined $message->[$im_count]) {
                print STDOUT "        $key".(' ' x ($padkey-length($key))).
                    " = '$message->[$im_count]'\n";
            } else {
                print STDOUT "        $key\n";
            }
			$im_count++;
	   	}

    } else {
        # Unknown ref type
        print STDOUT wrap($time, $time.$indent.$indent, 
            D_("Unknown reference type"), " '$ref'\n");
    }
}

#===============================================================================
#=========== Project utilities                                      ============
#===============================================================================
sub get_versions {
    my ($class, $options) = @_;
    # We use the CPAN release date (or CVS date) for version checking
    my $cpan_date = $Glade::PerlUI::perl_gtk_depends->{$Gtk::VERSION};
    # If we dont recognise the version number we use the latest CVS 
    # version that was available at our release date
    $cpan_date ||= $Glade::PerlUI::perl_gtk_depends->{'LATEST_CVS'};
    # If we have a version number rather than CVS date we look it up again
    $cpan_date = $Glade::PerlUI::perl_gtk_depends->{$cpan_date}
        if ($cpan_date < 19000000);
#    $options->my_perl_gtk($cpan_date);# if $options->my_perl_gtk < 10000;
    if ($options->my_perl_gtk && ($options->my_perl_gtk > $cpan_date)) {
        $options->diag_print (2, "%s- %s reported version %s".
            " but user overrode with version %s",
            $indent, "Gtk-Perl", "$Gtk::VERSION (CVS $cpan_date)",
            $options->my_perl_gtk);
#        $options->diag_print (2, 
#            $options->indent."- Gtk-Perl ".
#            D_("reported version").
#            " $Gtk::VERSION (CVS $cpan_date) ".
#            D_("but user overrode with version").
#            " ".$options->my_perl_gtk);
##        $options->my_perl_gtk($cpan_date);

    } else {
        $options->my_perl_gtk($cpan_date);
        $options->diag_print (2, "%s- %s reported version %s",
            $indent, "Gtk-Perl", "$Gtk::VERSION (CVS $cpan_date)");
#            $options->indent."- Gtk-Perl ".D_("reported version").
#            " $Gtk::VERSION (CVS $cpan_date) ");
    }
    unless ($class->my_perl_gtk_can_do('MINIMUM REQUIREMENTS')) {
        die "You need to upgrade your Gtk-Perl";
    }

    if ($options->allow_gnome) {
        my $gnome_libs_version = `gnome-config --version`;
        chomp $gnome_libs_version;
        $gnome_libs_version =~ s/gnome-libs //;
        if ($options->my_gnome_libs && ($options->my_gnome_libs gt $gnome_libs_version)) {
            $options->diag_print (2, "%s- %s reported version %s".
                " but user overrode with version %s",
                $indent, "gnome-libs", $gnome_libs_version,
                $options->my_gnome_libs);
        } else {
            $options->my_gnome_libs($gnome_libs_version);
            $options->diag_print (2, "%s- %s reported version %s",
                $indent, "gnome-libs", $gnome_libs_version);
#            $class->diag_print (2, 
#                $options->indent."- gnome_libs reported version $gnome_libs_version");
        }
#        unless (Gnome::Stock->can('button')) {
        unless ($class->my_gnome_libs_can_do('MINIMUM REQUIREMENTS')) {
            die "You need to upgrade your gnome-libs";
        }
    }
    return $options;
}

#===============================================================================
#=========== Options utilities                                      ============
#===============================================================================
sub add_to_hash_from {
    my ($class, $to_hash, $from_hash) = @_;
    my ($key, $value);
    foreach $key (keys %$from_hash) {
        if ($from_hash->{$key}) {
            if ($from_hash->{$key} =~ /^(true|y|yes|on)$/i) {
                $from_hash->{$key} = 1;
            } elsif ($from_hash->{$key} =~ /^(false|n|no|off)$/i) {
                $from_hash->{$key} = 0;
            }
            $to_hash->{$key} = $from_hash->{$key};
        }
    }    
}

sub save_options {
    my ($class, $filename) = @_;
#use Data::Dumper; print Dumper(\@_);print Dumper($Glade_Perl);
    my $me = __PACKAGE__."->save_options";
    my ($user_options, $site_options, $key, $default);
    # Take a copy of the options supplied and work on that (for deleting keys)
    # so that we still have some options to use (verbode etc) :)
    my %options = %{$class};
    my $site_filename = $class->{'site_options'} || "/etc/glade2perl.xml";
    if (-f $site_filename) {
        # Only save options that are different to user_options in file
#        $site_options = $class->simple_Proto_from_File(
#             $site_filename, '')->{'G2P-Options'};
        $site_options = $class->Proto_from_File(
             $site_filename, '', '');
        $class->diag_print(4, $site_options, "Site options");
    }

    my $user_filename = $class->{'user_options'} || "$ENV{'HOME'}/.glade2perl.xml";
    if (-f $user_filename) {
        # Only save options that are different to user_options in file
#        $user_options = $class->simple_Proto_from_File(
#             $user_filename, '')->{'G2P-Options'};
        $user_options = $class->Proto_from_File(
             $user_filename, '', '');
        $class->diag_print(4, $user_options, "User options");
    }

    $class->diag_print(4, $class, "Options to save");
    foreach $key (sort keys %{$class}) {
        if (!defined $class->{$key}) {
            $class->diag_print (6, 
                "%s- NOT saving option '%s' (no value)", $indent, $key);
            delete $options{$key};

        } elsif ($key eq '_permitted_fields') {
            # Ignore the AUTOLOAD dynamic data access hash
            delete $options{$key};

        } else {
            if (defined $user_options->{$key}) {
                $default = $user_options->{$key};
            } elsif (defined $site_options->{$key}) {
                $default = $site_options->{$key};
            } elsif (defined $fields{$key}) {
                $default = $fields{$key};
            } else {
                $default = '__IMPOSSIBLE_DEFAULT__';
            }
            if ($class->{$key} eq $default) {
                $class->diag_print (6, 
                    "%s- NOT saving option '%s' (default value)", $indent, $key);
            delete $options{$key};
            }
        }
    }
    $options{'glade2perl_version'} = $VERSION;
    $class->diag_print (2, "%s- Saving project options in file '%s'", 
        $indent, $filename);
#    $class->diag_print (2, "${indent}- Saving project options in file '$filename'");
    my $xml = $class->XML_from_Proto('', '  ', 'G2P-Options', \%options);
    $class->diag_print(6, $xml);
    open OPTIONS, ">".($filename) or 
        die sprintf("error %s - can't open file '%s' for output", 
            $me, $filename);
    print OPTIONS $xml;
    close OPTIONS or
        die sprintf("error %s - can't close file '%s'", 
            $me, $filename);
}

sub options {
    my ($class, %params) = @_;
    my $me = (ref $class || $class)."->options";
    my ($key, $first_time, $file);
    my $options;
    my $file_options;
    if (ref $Glade_Perl->{'options'} eq __PACKAGE__) {
        $options = $Glade_Perl->{'options'};
    } else {
        # This is first time through
        $options = $PACKAGE->new;
        $first_time = 1;
        # Mege default, site , user options, project options and args
        foreach $file ( 
                $params{'site_options'} || "/etc/glade2perl.xml", 
                $params{'user_options'} || "$ENV{'HOME'}/.glade2perl.xml", 
                $params{'project_options'} ) {
            if ($file && -f $file) {
                # Override the defaults with values from the options file
#                $file_options = $class->simple_Proto_from_File(
#                    $filename, '')->{'G2P-Options'};
                $file_options = $class->Proto_from_File($file, '', '');
                $class->add_to_hash_from($options, $file_options);
            }
        }
    }
#use Data::Dumper; print Dumper($options);
    # merge in the supplied arg options
    $class->add_to_hash_from($options, \%params);

    if ($options->verbose == 0 ) { 
        open STDOUT, ">/dev/null"; 
    } else {
        # Load the diagnostics gettext translations
#        $class->load_translations('Glade-Perl', $options->diag_LANG, undef, undef, '__D', undef);
        $class->load_translations('Glade-Perl', $options->diag_LANG, undef, 
            '/home/dermot/Devel/Glade-Perl/ppo/en.mo', '__D', undef);
#        $class->check_gettext_strings("__D");
    }
    unless ($options->my_perl_gtk &&
            ($options->my_perl_gtk > $Gtk::VERSION)) {
        $options->my_perl_gtk($Gtk::VERSION);
    }
    if ( $options->dont_show_UI && !$options->write_source) {
        die "$me - Much as I like an easy life, please alter options ".
            "to, at least, show_UI or write_source\n    Run abandoned";
    }
#    if ($options->{'debug'}) {$options->verbose(0);}
    $indent = $options->indent; 
    $tab = (' ' x $options->tabwidth);
    if ($options->diag_wrap == 0) {
        $columns = 999;
    } else {
        $columns = $options->diag_wrap;
    }
    $tab = (' ' x $options->tabwidth);
# FIXME check that this is portable and always works
#   why does it give BST interactively but UTC from Glade??
#        $key = sprintf(" (%+03d00)", (localtime)[8]);
#        $key = (localtime).$key;
    $key = `date`;
    chomp $key;
    $options->start_time($key);
    $Glade_Perl->{'options'} = $options;
    if ($first_time) {
        my $log_file = $options->log_file;
        if ($log_file) {
            open STDOUT, ">$log_file" or
                die sprintf("error %s - can't open file '%s' for output", 
                    $me, $log_file);
            open STDERR, ">&1" or
                die sprintf("error %s - can't redirect STDERR to file '%s'",
                    $me, $log_file);
        }
        if ($class->diagnostics(2)) {
            $class->diag_print (2, 
                "--------------------------------------------------------");
            $class->diag_print (2, "%s  DIAGNOSTICS (locale <%s> verbosity %s) ".
                "started by %s (version %s) at %s", 
                $indent, $options->diag_LANG, $options->verbose, 
                $PACKAGE, $VERSION, $options->start_time);
            $class->Write_to_File;
            $class->diag_print(6, $options, "Options used for Generate run");
        }
    }
    $options->options_set($params{'options_set'} || $me);
    if ($first_time && $params{'project_options'}) {
        $options->save_options( $params{'project_options'} );
    }
    bless $options, $PACKAGE;
    return $options;
}

sub use_Glade_Project {
    my ($class, $glade_proto) = @_;
    my $me = "$class->use_Glade_Project";
    $class->diag_print(6, $glade_proto->{'project'}, "Input Proto project");
    my $options = $Glade_Perl->{'options'};
    # Ensure that the options are set (use defaults, site, user, project)
    $options->options_set($me);
    my $project_options = {};
    bless $project_options, $PACKAGE;
    my $gnome_support = $glade_proto->{'project'}{'gnome_support'};
    $options->allow_gnome(
        ($glade_proto->{'project'}{'gnome_support'} || 'True')
            eq 'True');
    $options->gettext(
        ($glade_proto->{'project'}{'output_translatable_strings'} || 'False') 
            eq 'True');
    $class->get_versions($options);
#    $options = $class->get_versions($options;
    # Glade assumes that all directories are named relative to the Glade 
    # project (.glade) file (not <directory>) !
    my $glade_file_dirname = dirname($options->{'glade_filename'});
    # Replace any spaces with underlines
    my $replaced = $glade_proto ->{'project'}{'name'} =~ s/[ -\.]//g;
    if ($replaced) {
        $class->diag_print(2, "%s- %s Space(s), minus(es) or dot(s) ".
            "removed from project name - it is now '%s'",
            $indent, $replaced, $glade_proto->{'project'}{'name'});
    }
    $project_options->{'name'}  = $glade_proto->{'project'}{'name'};
    $project_options->{'directory'} = $class->full_Path(
        $glade_proto->{'project'}{'directory'}, 
        $glade_file_dirname);
    $project_options->{'glade_filename'} = $class->full_Path(
        $Glade_Perl->{'options'}{'glade_filename'},
        $project_options->{'directory'});

    $project_options->{'source_directory'} = $class->full_Path(
        ($glade_proto->{'project'}{'source_directory'} || './src'),     
        $glade_file_dirname,
        $project_options->{'directory'} );
    if ($class->Writing_to_File && 
        !-d $project_options->{'source_directory'}) { 
        # Source directory does not exist yet so create it
        $class->diag_print (2, "%s- Creating source_directory '%s' in %s", 
            $indent, $project_options->{'source_directory'}, $me);
        mkpath($project_options->{'source_directory'} );
    }

    $project_options->{'pixmaps_directory'} = $class->full_Path(
        ($glade_proto->{'project'}{'pixmaps_directory'} || './pixmaps'),    
        $glade_file_dirname, 
        $project_options->{'directory'} );
    if ($class->Writing_to_File && 
        !-d $project_options->{'pixmaps_directory'}) { 
        # Source directory does not exist yet so create it
        $class->diag_print (2, "%s- Creating pixmaps_directory '%s' in %s",
            $indent, $project_options->{'pixmaps_directory'}, $me);
        mkpath($project_options->{'pixmaps_directory'} );
    }

    $project_options->{'SIGS_class'} = $project_options->{'name'}."SIGS";
    $project_options->{'SIGS_filename'} = $class->full_Path(
        "$project_options->{'SIGS_class'}.pm",         
        $project_options->{'source_directory'} );
    $project_options->{'UI_class'} = $project_options->{'name'}."UI";
    $project_options->{'UI_filename'} = $class->full_Path(
        "$project_options->{'UI_class'}.pm",         
        $project_options->{'source_directory'} );
    $project_options->{'APP_class'} = $project_options->{'name'};
    $project_options->{'APP_filename'} = $class->full_Path(
        "$project_options->{'APP_class'}.pm",         
        $project_options->{'source_directory'} );
    $project_options->{'SUBAPP_class'} = "Sub".$project_options->{'APP_class'};
    $project_options->{'SUBAPP_filename'} = $class->full_Path(
        "$project_options->{'SUBAPP_class'}.pm",         
        $project_options->{'source_directory'} );
    $project_options->{'SUBCLASS_class'} = "Sub".$project_options->{'SIGS_class'};
    $project_options->{'SUBCLASS_filename'} = $class->full_Path(
        "$project_options->{'SUBCLASS_class'}.pm",         
        $project_options->{'source_directory'} );
    $project_options->{'LIBGLADE_class'} = $project_options->{'name'}."LIBGLADE";
    $project_options->{'LIBGLADE_filename'} = $class->full_Path(
        "$project_options->{'LIBGLADE_class'}.pm",         
        $project_options->{'source_directory'} );
    $project_options->{'POT_filename'} = $class->full_Path(
        $project_options->{'name'}.".pot",
        $project_options->{'source_directory'} );

    $project_options->{'glade_proto'} = $glade_proto;

    $project_options->{'logo_filename'} = $class->full_Path(
        $options->logo, 
        $project_options->{'pixmaps_directory'}, 
        '' );

    $project_options->{'glade2perl_logo_filename'} = $class->full_Path(
        $options->glade2perl_logo, 
        $project_options->{'pixmaps_directory'}, 
        '' );

    unless (-f $project_options->{'glade2perl_logo_filename'}) {             
        $class->diag_print (2, "%s- Writing our own logo to '%s' in %s",
            $indent, $project_options->{'glade2perl_logo_filename'}, $me);
        open LOGO, ">$project_options->{'glade2perl_logo_filename'}" or 
            die sprintf("error %s - can't open file '%s' for output", 
                $me, $project_options->{'glade2perl_logo_filename'});
        print LOGO $class->our_logo;
        close LOGO or
        die sprintf("error %s - can't close file '%s'", 
            $me, $project_options->{'glade2perl_logo_filename'});
    }
    
    unless ($project_options->{'logo_filename'} && -f $project_options->{'logo_filename'}) {
        $options->logo($options->glade2perl_logo);
        $project_options->{'logo_filename'} = $project_options->{'glade2perl_logo_filename'};
    }            
#use Data::Dumper; print Dumper($project_options);
#exit;
    if ($options->author) {
        $project_options->{'author'} = $options->author;
    } else {
        my $host = hostname;
        my $pwuid = [(getpwuid($<))];
        my $user = $pwuid->[0];
        my $fullname = $pwuid->[6];
        my $hostname = [split(" ", $host)];
        $project_options->{'author'} = "$fullname <$user\\\@$hostname->[0]>";
    }
    # If allow_gnome is not specified, use glade project <gnome_support> property
    unless (defined $options->{'allow_gnome'}) {
# FIXME This might have to be changed for Glade >= 0.5.8 to default to True
        $options->{'allow_gnome'} = 
            ('*true*y*yes*on*1*' =~ m/\*$gnome_support\*/i) ? '1' : '0';
        if ($options->project_options) {
            $options->save_options( $options->project_options );
        }
    }
    $project_options->{'logo'}         = $options->logo;
    $project_options->{'version'}      = $options->version;
    $project_options->{'date'}         = $options->date        || $options->start_time;
    $project_options->{'copying'}      = $options->copying;
    $project_options->{'description'}  = $options->description || 'No description';
    $class->diag_print(6, $project_options);
    # Now change to the <project><directory> so that we can find modules
    chdir $project_options->{'directory'};
    $project_options->{'_permitted_fields'} = \%fields;
    bless $project_options, $PACKAGE;
#    $class->diag_print(2, $project_options);exit;

    return $project_options;
}

1;

__END__
