package Glade::PerlProject;
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
    use File::Path     qw( mkpath );        # in use_Glade_Project
    use File::Basename qw( dirname );       # in use_Glade_Project
    use Cwd            qw( chdir cwd );     # in use_Glade_Project
    use Sys::Hostname  qw( hostname );      # in use_Glade_Project
    use Text::Wrap     qw( wrap $columns ); # in options, diag_print
    use Glade::PerlSource qw(:VARS);        # Source writing vars and methods
    use Glade::PerlXML;
    use vars           qw( 
                            @ISA 
                            $AUTOLOAD
                            $PACKAGE 
                            $VERSION
                       );
    $PACKAGE        = __PACKAGE__;
    $VERSION        = q(0.41);
    # Tell interpreter who we are inheriting from
    @ISA            = qw( 
                            Glade::PerlXML 
                            Glade::PerlRun
                        );
}

my %fields = (
    # These are the data fields that you can set/get using
    # the dynamic calls provided by AUTOLOAD.
    # eg $class->UI($new_value);        sets the value of UI
    #    $current_value = $class->UI;   gets the current value of UI
# Project
    'author'            => undef,   # Name to appear in generated source
    'version'           => '0.01',  # Version to appear in generated source
    'date'              => undef,   # Date to appear in generated source
    'copying'           =>          # Copying policy to appear in generated source
        '# Unspecified copying policy, please contact the author\n# ',
    'description'       => undef,   # Description for About box etc.
    'use_modules'       => undef,   # Existing signal handler modules
    'allow_gnome'       => undef,   # Don't allow gnome widgets
    'start_time'        => undef,   # Time that this run started
    'options_filename'  => undef,   # Don't read or save options in disk file
    'options_set'       => 'DEFAULT', # Who set the options
# UI
    'GTK_Interface'     => undef,
    'pixmaps_directory' => undef,
    'logo'              => undef,   # No defined project logo
# Source code
    'indent'            => '    ',  # Source code indent per Gtk 'nesting'
    'tabwidth'          => 8,       # Replace each 8 spaces with a tab in sources
    'write_source'      => undef,   # Don't write source code
    'dont_show_UI'      => undef,   # Show UI and wait
    'style'             => undef,   # Generate code using functional closures
                                    # 'closures' as above
                                    # 'AUTOLOAD' generate OO AUTOLOAD code
                                    # 'Export'   generate non-OO code
# Diagnostics
    'verbose'           => 2,       # Show errors and main diagnostics
    'diag_wrap'         => 0,       # Max diagnostic line length (approx)
    'diag_file'         => undef,   # Diagnostics log file name
    'autoflush'         => undef,   # Don't change the policy
    'benchmark'         => undef,   # Don't add time to the diagnostic messages
    'log_file'          => undef,   # Write diagnostics to STDOUT 
                                    # or Filename to write diagnostics to
# Distribution
    'dist_type'         => undef,   # Type of distribution
    'dist_compress'     => undef,   # How to compress the distribution
    'dist_scripts'      => undef,   # Scripts that should be installed
    'dist_docs'         => undef,   # Documentation that should be included
# Helpers
    'editors'           => undef,   # Editor calls that are available
    'active_editor'     => undef,   # Index of editor that we are using
    'my_perl_gtk'       => undef,   # Get the version number from Perl/Gtk
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

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or die "$self is not an object";
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
    die "Can't access method `$name' in class $type";

  }
}

#===============================================================================
#=========== Diagnostics utilities                                  ============
#===============================================================================
sub verbosity            { $main::Glade_Perl_Generate_options->verbose }
sub Writing_to_File      { $main::Glade_Perl_Generate_options->write_source }
sub Building_UI_only     {!defined $main::Glade_Perl_Generate_options->write_source }
sub Writing_Source_only  { $main::Glade_Perl_Generate_options->dont_show_UI }

sub diagnostics { 
    ($ARG[1] || 1) <= ($main::Glade_Perl_Generate_options->verbose);
}

sub diag_print {
    my ($class, $level, $message, $desc, $pad) = @ARG;
    my ($key, $val, $ref);
    my $options = $main::Glade_Perl_Generate_options;
    my $padkey = $pad || 17;
    my $title = "      ".($desc || "");
    my @times = times;
    my $time='';
    if ($class->diagnostics($level)) {
        $ref = ref $message;
        if ($main::Glade_Perl_Generate_options->benchmark) {
            $time = int( $times[0] + $times[1] );
        }
        unless ($ref) {
             print STDOUT wrap($time, 
                $time.$options->indent.$options->indent, "$message\n");

        } elsif (($ref eq 'HASH') or ( $ref =~ /Glade::/)) {
            print STDOUT "$title $ref contains:\n";
            foreach $key (sort keys %$message) {
                my $ref = ref $message->{$key};
                if (ref $message->{$key}) {
                    print STDOUT "        {'$key'}".
                        (' ' x ($padkey-length($key))).
                        " => is a reference to a $ref\n";
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
            print STDOUT "$title $ref contains:\n";
		    my $im_count = 0;
	    	foreach $val (@$message) {
				$key = sprintf "[%d]", $im_count;
				$ref = ref $val;
                if ($ref) {
                    print STDOUT "        $key".(' ' x ($padkey-length($key))).
                        " = is a reference to a $ref\n";
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
                "Unknown reference type '$ref'\n");
        }
        
#    } else {
    # Nothing needs to be done
    
    }
}

#===============================================================================
#=========== Project utilities                                      ============
#===============================================================================
sub merge_options {
    my ($class, $filename, $base_options) = @ARG;
    my $me = "$class->merge_options";
    my $options = $base_options;
    my ($file_options, $key);
    if ($filename && -f $filename) {
        # Override the defaults with values from the options file
        $file_options = $class->Proto_from_File(
             $filename, '  ', '');
#             $filename, ' project file helper source diag dist ', '');
        foreach $key (keys %$file_options) {
            if ($file_options->{$key}) {
                if ($file_options->{$key} eq 'True') {
                    $file_options->{$key} = 1;
                } elsif ($file_options->{$key} eq 'False') {
                    $file_options->{$key} = 0;
                }
                $options->{$key} = $file_options->{$key};
            }
        }
    }
    bless $options, $PACKAGE;
    return $options;
}

sub save_options {
    my ($class, $filename, $supplied_options) = @ARG;
    my $me = "$class->save_options";
    my ($file_options, $key);
    my %project_options = %{$supplied_options};
    my $user_filename = $project_options{'user_options'};
    $class->diag_print(6, $supplied_options, 'Options to save');
    if ($user_filename && -f $user_filename) {
        # Only save options that are different to user_options in file
        $file_options = $class->Proto_from_File(
             $user_filename, 
             '  ', '');
#             ' project file helper source diag dist ', '');
        $class->diag_print(8, $file_options, 'User options');
    }
    foreach $key (keys %project_options) {
        if (!defined $project_options{$key}) {
            $class->diag_print (6, "NOT saving option '$key' (no value)");
            delete $project_options{$key};

        } elsif ($file_options->{$key} &&
            ($file_options->{$key} eq $project_options{$key})) {
            $class->diag_print (6, "NOT saving option '$key' (eq user_option)");
            delete $project_options{$key};

        } elsif ($key eq '_permitted_fields') {
            # Ignore the AUTOLOAD dynamic data access hash
            delete $project_options{$key};
        }
    }
    $project_options{'glade2perl_version'} = $VERSION;
    $class->diag_print (2, "${indent}- Saving project options in file '$filename'");
    my $xml = $class->XML_from_Proto('', '  ', 'G2P-Options', 
            \%project_options);
    $class->diag_print(6, $xml);
    open OPTIONS, ">".($filename) or 
        die "error $me - can't open file '$filename' for output";
    print OPTIONS $xml;
    close OPTIONS or
        die "error $me - can't close file '$filename'";
}

sub options {
    my ($class, %params) = @ARG;
    my $me = "$class->options";
    my ($key, $first_time, $file);
    my $options;
    if (ref $main::Glade_Perl_Generate_options eq __PACKAGE__) {
        $options = $main::Glade_Perl_Generate_options;
    } else {
        # This is first time through
        $options = $PACKAGE->new;
        $first_time = 1;
        # Mege default, site , user options
        foreach $file ( 
                $params{'site_options'} || "/etc/glade2perl.xml", 
                $params{'user_options'} || "$ENV{'HOME'}/.glade2perl.xml", 
                $params{'project_options'} ) {
            $options = $options->merge_options($file, $options);
        }
    }
    # merge in the supplied arg options
    foreach $key (keys %params) {
        if ($params{$key}) {
            if ($params{$key} eq 'True') {
                $params{$key} = 1;
            } elsif ($params{$key} eq 'False') {
                $params{$key} = 0;
            }
        }
        # Override the defaults/file options with args
        $options->{$key} = $params{$key};
    }
    unless ($options->my_perl_gtk &&
            ($options->my_perl_gtk > $Gtk::VERSION)) {
        $options->my_perl_gtk($Gtk::VERSION);
    }
    if ( $options->dont_show_UI && !$options->write_source) {
        die "$me - Much as I like an easy life, please alter options ".
            "to, at least, show_UI or write_source\n    Run abandoned";
    }
    if ($options->verbose == 0 )    { 
        open STDOUT, ">/dev/null";
    }
    $indent = $options->indent; 
    $tab = (' ' x $options->tabwidth);
    if ($options->diag_wrap == 0) {
        $columns = 999;
    } else {
        $columns = $options->diag_wrap;
    }
    $options->options_set($me);
    $tab = (' ' x $options->tabwidth);
# FIXME check that this is portable and always works
#   why does it give BST interactively but UTC from Glade??
#        $key = sprintf(" (%+03d00)", (localtime)[8]);
#        $key = (localtime).$key;
    $key = `date`;
    chomp $key;
    $options->start_time($key);
    $main::Glade_Perl_Generate_options = $options;
    if ($first_time) {
        my $log_file = $options->log_file;
        if ($log_file) {
            open STDOUT, ">$log_file" or
                die "error $me - can't open file '$log_file' for diagnostics";
            open STDERR, ">&1" or
                die "error $me - can't redirect STDERR to file '$log_file'";
        }
        if ($class->diagnostics(2)) {
            $class->diag_print (2, 
                "--------------------------------------------------------");
            $class->diag_print (2, 
                $options->indent."  DIAGNOSTICS (verbosity ".$options->verbose.
                ") started by $PACKAGE (version $VERSION) at ".$options->start_time);
            $class->Write_to_File;
            $class->diag_print(6, $options, 'Options used for Generate run');    
        }
    }
    if ($first_time && $params{'project_options'}) {
        # Save the current project options
        my $work = $options;
        $work->save_options( $params{'project_options'}, $work, );
    }
    bless $options, $PACKAGE;
    return $options;
}

sub get_versions {
    my ($class, $options) = @ARG;
    if ($options->my_perl_gtk &&
            ($options->my_perl_gtk > $Gtk::VERSION)) {
        $class->diag_print (2, 
            $options->indent."- Perl/Gtk reported version $Gtk::VERSION".
            " but user overrode with version ".$options->my_perl_gtk);
    } else {
        $options->my_perl_gtk($Gtk::VERSION);
        $class->diag_print (2, 
            $options->indent."- Perl/Gtk reported version $Gtk::VERSION");
    }
    my $gnome_libs_version = `gnome-config --version`;
    chomp $gnome_libs_version;
    $gnome_libs_version =~ s/gnome-libs //;
    if ($options->my_gnome_libs &&
            ($options->my_gnome_libs > $gnome_libs_version)) {
        $class->diag_print (2, 
            $options->indent."- gnome_libs reported version $gnome_libs_version".
            " but user overrode with version ".$options->my_gnome_libs);
    } else {
        $options->my_gnome_libs($gnome_libs_version);
        $class->diag_print (2, 
            $options->indent."- gnome_libs reported version $gnome_libs_version");
    }
}

sub use_Glade_Project {
    my ($class, $proto) = @ARG;
    my $me = "$class->use_Glade_Project";
    $class->diag_print(6, $proto->{'project'}, 'Input Proto project');
    my $options = $main::Glade_Perl_Generate_options;
    # Ensure that the options are set (use defaults, site, user, project)
    $options->options('options_set' => $me);
    my $form = {};
    bless $form, $PACKAGE;
    $class->get_versions($options);
    # Glade assumes that all directories are named relative to the Glade 
    # project (.glade) file (not <directory>) !
    my $glade_file_dirname = dirname($proto->{'glade_filename'});
    $form->{'name'}  = $proto->{'project'}{'name'};
    $form->{'glade_filename'} = $proto->{'glade_filename'};
    $form->{'directory'} = 
        $class->full_Path(
            $proto->{'project'}{'directory'}, 
            $glade_file_dirname);
    $form->{'source_directory'} = 
        $class->full_Path(
            $proto->{'project'}{'source_directory'},     
            $glade_file_dirname,
            $form->{'directory'} );
    if ($class->Writing_to_File && 
        !-d $form->{'source_directory'}) { 
        $class->diag_print (2, "$indent- Creating source_directory ".
            "'$form->{'source_directory'}' in $me");
        mkpath($form->{'source_directory'} );   # In case it doesn't exist
    }
    $form->{'pixmaps_directory'} = 
        $class->full_Path(
            $proto->{'project'}{'pixmaps_directory'},    
            $glade_file_dirname, 
            $form->{'directory'} );
    # FIXME
    # Make sure that generated subs source filename is not included 
    # in 'use'd packages supplied to us
    $form->{'UI_filename'} = 
        $class->full_Path(
            $proto->{'project'}{'name'}.".pm",         
            $form->{'source_directory'} );
    $form->{'SUBCLASS_filename'} = 
        $class->full_Path(
            "Sub".$proto->{'project'}{'name'}.".pm",         
            $form->{'source_directory'} );
    $form->{'GTK-Interface'}     = $proto;
    $form->{'logo'} = 
        $class->full_Path(
            'Logo.xpm', 
            $form->{'pixmaps_directory'}, 
            '' );
#        $proto->{'project'}{'pixmaps_directory'}."/Logo.xpm";
        unless ( -f "$form->{'logo'}") { $form->{'logo'} = '';}

    if ($options->author) {
        $form->{'author'} = $options->author;
    } else {
        my $host = hostname;
        my $pwuid = [(getpwuid($<))];
        my $user = $pwuid->[0];
        my $fullname = $pwuid->[6];
        my $hostname = [split(" ", $host)];
        $form->{'author'} = "$fullname <$user\\\@$hostname->[0]>";
    }
    my $gnome_support = $proto->{'project'}{'gnome_support'};
    # If allow_gnome is not specified, use glade project <gnome_support> property
    unless (defined $options->{'allow_gnome'}) {
        $options->{'allow_gnome'} = 
            ('*true*y*yes*on*1*' =~ m/\*$gnome_support\*/i) ? '1' : '0';
    }
    $form->{'version'}      = $options->version;
    $form->{'date'}         = $options->date        || $options->start_time;
    $form->{'copying'}      = $options->copying;
    $form->{'description'}  = $options->description || 'No description';
    # Clear out project elements that we are not interested in
    undef $proto->{'project'}{'gettext_support'};
    undef $proto->{'project'}{'gettext_support'};
    undef $proto->{'project'}{'handler_header_file'};
    undef $proto->{'project'}{'handler_source_file'};
    undef $proto->{'project'}{'language'};
    undef $proto->{'project'}{'main_header_file'};
    undef $proto->{'project'}{'main_source_file'};
    undef $proto->{'project'}{'use_widget_names'};
    $class->diag_print(6, $form);
    # Now change to the <project><directory> so that we can find modules
    chdir $form->{'directory'};
    $form = {_permitted_fields => \%fields, %fields, %$form};
    bless $form, $PACKAGE;
#    $class->diag_print(2, $form);
    return $form;
}

1;

__END__
