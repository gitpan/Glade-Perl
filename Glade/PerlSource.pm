package Glade::PerlSource;
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
    use Glade::PerlRun qw( :METHODS :VARS ); # Our run-time utilities and vars
    use vars        qw( 
                        @ISA 
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE 
                        $VERSION
                        @VARS @METHODS 
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $project
                        $widgets 
                        $data
                        $forms 
                        $work 

                        $handlers
                        $need_handlers
                        $autosubs
                        $subs
                        @use_modules
                        $indent
                        $tab

                        $radiobuttons 
                        $radiomenuitems 
                        $current_data
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                      );
    $PACKAGE      = __PACKAGE__;
    $VERSION        = q(0.42);
    @VARS         = qw( 
                        $VERSION
                        $AUTHOR
                        $DATE
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $project
                        $widgets 
                        $data
                        $forms 
                        $work 

                        $handlers
                        $need_handlers
                        $autosubs
                        $subs
                        @use_modules
                        $indent
                        $tab

                        $radiobuttons 
                        $radiomenuitems 
                        $current_data
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                    );
    @METHODS      = qw( 
                    );
    $subs =             '';
    $autosubs =         ' destroy_Form about_Form '.
                        ' toplevel_hide toplevel_close toplevel_destroy ';
    $LOOKUP       = 2;
    $BOOL         = 4;
    $DEFAULT      = 8;
    $KEYSYM       = 16;
    $LOOKUP_ARRAY = 32;
    # Tell interpreter who we are inheriting from
    @ISA          = qw( Exporter Glade::PerlRun );
    # These symbols (globals and functions) are always exported
    @EXPORT       = qw( );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @VARS, @METHODS );
    # Tags (groups of symbols) to export        
    %EXPORT_TAGS  = (   'METHODS'   => [@METHODS],
                        'VARS'      => [@VARS]  );
}

%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
    USERDATA    => undef,
);

sub new {
    my $that  = shift;
    # Allow indirect constructor so that we can call eg. 
    #   $window1 = BusForm_mySUBS->new; # and then
    #   $window2 = $window1->new;
    my $class = ref($that) || $that;

    # Call our super-class constructor to get an object and reconsecrate it
    my $self = bless $that->SUPER::new(), $class;

    # Add our own data access methods to the inherited constructor
    my($element);
    foreach $element (keys %fields) {
        $self->{_permitted_fields}->{$element} = $fields{$element};
    }
    @{$self}{keys %fields} = values %fields;
    return $self;
}

#===============================================================================
#=========== Utilities to write output file                         ============
#===============================================================================
sub Stop_Writing_to_File { shift->Write_to_File('-1') }

sub Write_to_File {
    my ($class) = @ARG;
    my $me = "$class->Write_to_File";
    my $filename = $main::Glade_Perl_Generate_options->write_source;
    if (fileno UI or fileno SUBS or fileno SUBCLASS or $class->Building_UI_only) {
        # Files are already open or we are not writing source
        if ($class->Writing_to_File) {
            if ($filename eq '-1') {
                close UI;
                close SUBCLASS;
                close SUBS;
                $class->diag_print (2, "$indent- Closing output file in $me");
                $main::Glade_Perl_Generate_options->write_source(undef);
            } else {
                $class->diag_print (2, "$indent- Already writing to ".
                    "$class->Writing_to_File in $me");
            }
        }

    } elsif ($filename && ($filename eq '1')) {
        $class->diag_print (2, "$indent- Using default output files ".
            "in Glade <project><source_directory> in $me");

    } elsif ($filename && ($filename ne '-1') ) {
        # We want to write source
        if ($filename eq 'STDOUT') {
            $main::Glade_Perl_Generate_options->write_source('>&STDOUT');
        }
        $class->diag_print (2, "$indent- Writing UI   to '$filename' in $me");
        open UI,     ">$filename" or 
            die "error $me - can't open file '$filename' for output";
        $class->diag_print (2, "$indent- Writing SUBS to '$filename' in $me");
        open SUBS,     ">$filename" or 
            die "error $me -can't open file '$filename' for output";
        $class->diag_print (2, "$indent- Writing SUBCLASS to '$filename' in $me");
        open SUBCLASS,     ">$filename" or 
            die "error $me -can't open file '$filename' for output";
        UI->autoflush(1);
        SUBCLASS->autoflush(1);
        SUBS->autoflush(1);
    } else {
        # Nothing to do
    }
}

sub add_to_UI {
    my ($class, $depth, $expr, $tofileonly, $notabs) = @ARG;
    my $me = "$class->add_to_UI";
    my $mydebug = ($class->verbosity >= 6);
    if ($depth < 0) {
        $mydebug = 1;
        $depth = -$depth;
    }
    if ($class->Writing_to_File) {
        my $UI_String = ($indent x ($depth)).$expr;
        if ($tab && !$notabs) {
            # replace multiple spaces with tabs
            $UI_String =~ s/$tab/\t/g;
        }
        eval "push \@{${current_form}\{'UI_Strings'}}, \$UI_String";
    }
    $mydebug && $class->diag_print (2, "UI    '$expr'");    
    unless ($tofileonly) {
        eval $expr or 
            ($EVAL_ERROR && die  "\n\nin $me\n\twhile trying to eval ".
                "'$expr'\n\tFAILED with Eval error '$EVAL_ERROR'\n" );
    }
}

#===============================================================================
#=========== Source code templates                                  ============
#===============================================================================
# FIXME Write these subs
sub perl_UI_SUBS_header {}
sub perl_SUBS {}
sub perl_SubClass {}

sub write_UI {
    my ($class, $proto, $glade_proto) = @ARG;
    my $me = "$class->write_UI";
    my ($permitted_stubs, $UI_String);
    my ($handler, $module, $form );
    unless (fileno UI) {            # ie user has supplied a filename
        # Open UI for output unless the filehandle is already open 
        open UI,     ">".($proto->{'UI_filename'})    or 
            die "error $me - can't open file ".
                "'$proto->{'UI_filename'}' for output";
        $class->diag_print (4, "$indent- Writing UI source     to ".
            "$proto->{'UI_filename'} - in $me");
        if ($main::Glade_Perl_Generate_options->autoflush) {
            UI->autoflush(1);
        }
    }
    $autosubs &&
        $class->diag_print (2, "$indent- Automatically generated SUBS are ".
            "'$autosubs' by $me");

    print UI "#!/usr/bin/perl -w\n";
    foreach $form (keys %$forms) {
        $class->diag_print(4, "$indent- Writing source for class $form");
        $permitted_stubs = '';
        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            $permitted_stubs .= "\n${indent}'$handler' => undef,";
        }
        # FIXME Now generate different source code for each user choice
        print UI $class->perl_UI_AUTOLOAD_header(
            $project, $proto, $form, $permitted_stubs)."\n";
        $UI_String = join("\n", @{$forms->{$form}{'UI_Strings'}});
        print UI $UI_String;
        print UI $class->perl_UI_AUTOLOAD_new_bottom($project, $form);
    }
    print UI $class->perl_UI_footer($project, $proto->{'name'}, $first_form);

# FIXME write these files if necessary
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_Changelog;
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_Makefile;
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_README;
#    print STDOUT "-------------------------------------------\n";
}

sub write_SUBCLASS {
    my ($class, $proto, $glade_proto) = @ARG;
    my $me = "$class->write_SUBCLASS";
    my ($permitted_stubs);
    my ($handler, $module, $form );
    unless (fileno SUBCLASS) {            # ie user has supplied a filename
        # Open SUBCLASS for output unless the filehandle is already open 
        open SUBCLASS,     ">".($proto->{'SUBCLASS_filename'})    or 
            die "error $me - can't open file ".
                "'$proto->{'SUBCLASS_filename'}' for output";
        $class->diag_print (4, "$indent- Writing SUBCLASS source     to ".
            "$proto->{'SUBCLASS_filename'} - in $me");
        if ($main::Glade_Perl_Generate_options->autoflush) {
            SUBCLASS->autoflush(1);
        }
    }
    $autosubs &&
        $class->diag_print (2, "$indent- Automatically generated SUBS are ".
            "'$autosubs' by $me");

    print SUBCLASS "#!/usr/bin/perl -w\n";
    $form = $first_form;
#    foreach $form (keys %$forms) {
        $class->diag_print(4, "$indent- Writing SUBCLASS for class $form");
        $permitted_stubs = '';
        # FIXME Now generate different source code for each user choice
        print SUBCLASS $class->perl_SUBCLASS_AUTOLOAD_header(
            $project, $proto, $form, $permitted_stubs)."\n";
#        print SUBCLASS $class->perl_SUBCLASS_AUTOLOAD_new_bottom($project, $form);
        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                print SUBCLASS "sub $handler {
${indent}my (\$class, \$data, \$object, \$instance) = \@ARG;
${indent}my \$me = __PACKAGE__.\"->$handler\";
${indent}# Get ref to hash of all widgets on our form
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};
${indent}# REPLACE the line below with the actions to be taken when ".
    "__PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@ARG, ".
    "__PACKAGE__, '$project->{'logo'}');
}

";
            }
#        }
    }
    print SUBCLASS $class->perl_UI_footer(
        $project, "Sub".$proto->{'name'}, "Sub".$first_form);

}

sub perl_preamble {
    my ($class, $package, $project, $proto, $name) = @ARG;
    my $localtime = localtime;
    return 
"#==============================================================================
#=== This is the '$name' UI construction class                              
#==============================================================================
package $name;
require 5.000; use English; use strict \'vars\', \'refs\', \'subs\';
# UI class '$name' (version $project->{'version'})
# 
# Copyright (c) Date   $project->{'date'}
#               Author $project->{'author'}
#
$project->{'copying'} $project->{'author'}
#
#==============================================================================
# This perl source file was automatically generated by $class from
#   Glade file $project->{'glade_filename'}
#   on Date    $project->{'date'}
#
# Do not edit this file, any changes that you make will be lost when
#   the file is overwritten by the next run of $class
#
# $class       - version $VERSION
#   Copyright (c) Date   $DATE
#                 Author $AUTHOR
#==============================================================================

";
}

sub perl_SUBCLASS_AUTOLOAD_header {
    my ($class, $project, $proto, $name, $permitted_stubs) = @ARG;
    my $me = "$class->perl_UI_Header";
#use Data::Dumper; print Dumper(\@ARG); exit
    my ($module, $super);
    my $about_string = $class->perl_about($project, $name);
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun';
    my $use_string = '';
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
        $use_string .="\n${indent}# We need the Gnome bindings as well\n".
                        "${indent}use Gnome;"
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    $super = "$project->{'source_directory'}";
    $super =~ s/.*\/(.*)$/$1/;
    $module = $project->{'name'};
    # remove double spaces
    $isa_string =~ s/  / /g;
return $class->perl_preamble($module, $project, $proto, "Sub$name").
"BEGIN {
${indent}use vars    qw( 
${indent}                 \@ISA
${indent}                 \$AUTOLOAD
${indent}                 \%fields
${indent}             );
${indent}# Tell interpreter who we are inheriting from
${indent}use $super\::$module;
${indent}\@ISA      = qw( $name );
${indent}# Inherit the AUTOLOAD dynamic methods from BusFrame
${indent}*AUTOLOAD = \\\&$name\::AUTOLOAD;
}

\%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

#==============================================================================
#=== These are the overloaded class constructors and so on                  ===
#==============================================================================
sub new {
${indent}my \$that  = shift;
${indent}# Allow indirect constructor so that we can call eg. 
${indent}#   \$window1 = BusFrame->new; \$window2 = \$window1->new;
${indent}my \$class = ref(\$that) || \$that;

${indent}# Call our super-class constructor to get an object and reconsecrate it
${indent}my \$self = bless \$that->SUPER::new(), \$class;

${indent}# Add our own data access methods to the inherited constructor
${indent}my(\$element);
${indent}foreach \$element (keys \%fields) {
${indent}${indent}\$self->{_permitted_fields}->{\$element} = \$fields{\$element};
${indent}}
${indent}\@{\$self}{keys \%fields} = values \%fields;
${indent}return \$self;
}

sub run {
${indent}my (\$class) = \@ARG;
$init_string
${indent}my \$window = \$class->new;
${indent}# Insert your subclass user data key/value pairs 
${indent}\$window->USERDATA({
#${indent}${indent}'Key1'   => 'Value1',
#${indent}${indent}'Key2'   => 'Value2',
#${indent}${indent}'Key3'   => 'Value3',
${indent}});
${indent}\$window->TOPLEVEL->show;
#${indent}my \$window2 = \$window->new;
#${indent}\$window2->TOPLEVEL->show;
${indent}Gtk->main;
${indent}return \$window;
}
#===============================================================================
#==== Below are overloaded signal handlers                                  ====
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@ARG;
#${indent}__PACKAGE__->destroy_all_forms(\$__PACKAGE__::all_forms); 
${indent}Gtk->main_quit; 
}

sub toplevel_hide                   { shift->get_toplevel->hide         }
sub toplevel_close                  { shift->get_toplevel->close        }
sub toplevel_destroy                { shift->get_toplevel->destroy      }
";
}

sub perl_UI_AUTOLOAD_header {
    my ($class, $project, $proto, $name, $permitted_stubs) = @ARG;
    my $me = "$class->perl_UI_Header";
    my $module;
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun';
    my $use_string = '';
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
        $use_string .="\n${indent}# We need the Gnome bindings as well\n".
                        "${indent}use Gnome;"
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    $module = $project->{'name'};
    # remove double spaces
    $isa_string =~ s/  / /g;
return $class->perl_preamble($module, $project, $proto, $name).
"BEGIN {
${indent}# Run-time utilities and vars
${indent}use Glade::PerlRun; 
${indent}# Existing signal handler modules${use_string}
${indent}use vars        qw( \@ISA \$AUTOLOAD \%fields \%stubs);
${indent}# Tell interpreter who we are inheriting from
${indent}\@ISA          = qw( $isa_string );
}

%fields = (
${indent}# These are the data fields that you can set/get using the dynamic
${indent}# calls provided by AUTOLOAD (and their initial values).
${indent}# eg \$class->FORMS(\$new_value);      sets the value of FORMS
${indent}#    \$current_value = \$class->FORMS; gets the current value of FORMS
${indent}TOPLEVEL => undef,
${indent}FORM     => undef,
${indent}PACKAGE  => '$module',
${indent}VERSION  => '$project->{'version'}',
${indent}AUTHOR   => '$project->{'author'}',
${indent}DATE     => '$project->{'date'}',
${indent}INSTANCE => '$first_form',
);

\%stubs = (
${indent}# These are signal handlers that will cause a message_box to be
${indent}# displayed by AUTOLOAD if there is not already a sub of that name
${indent}# in any module specified in 'use_modules'.
$permitted_stubs
);

sub AUTOLOAD {
${indent}my \$self = shift;
${indent}my \$type = ref(\$self)
${indent}${indent}or die \"\$self is not an object so we cannot '\$AUTOLOAD'\";
${indent}my \$name = \$AUTOLOAD;
${indent}\$name =~ s/.*://;       # strip fully-qualified portion

${indent}if (exists \$self->{_permitted_fields}->{\$name} ) {
${indent}${indent}# This allows dynamic data methods - see \%fields above
${indent}${indent}# eg \$class->UI('new_value');
${indent}${indent}# or \$current_value = \$class->UI;
${indent}${indent}if (\@_) {
${indent}${indent}${indent}return \$self->{\$name} = shift;
${indent}${indent}} else {
${indent}${indent}${indent}return \$self->{\$name};
${indent}${indent}}

${indent}} elsif (exists \$stubs{\$name} ) {
${indent}${indent}# This shows dynamic signal handler stub message_box - see \%stubs above
${indent}${indent}__PACKAGE__->show_skeleton_message(
${indent}${indent}${indent}\$AUTOLOAD.\"\\n (AUTOLOADED by \".__PACKAGE__.\")\", 
${indent}${indent}${indent}\[\$self, \@ARG], 
${indent}${indent}${indent}__PACKAGE__, 
${indent}${indent}${indent}'pixmaps/Logo.xpm');
${indent}${indent}
${indent}} else {
${indent}${indent}die \"Can't access method `\$name' in class \$type\";

${indent}}
}

sub run {
${indent}my (\$class) = \@ARG;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->TOPLEVEL->show;
${indent}Gtk->main;
}

sub new {
#
# This sub will create the UI window
${indent}my \$that  = shift;
${indent}my \$class = ref(\$that) || \$that;
${indent}my \$self  = {
${indent}${indent}_permitted_fields   => \\\%fields, \%fields,
${indent}${indent}_permitted_stubs    => \\\%stubs,  \%stubs,
${indent}};
${indent}my (\$forms, \$widgets, \$data, \$work);
${indent}my \$instance = 1;
${indent}# Get a unique toplevel widget structure
${indent}while (defined \$__PACKAGE__::all_forms->{\"$name-\$instance\"}) {\$instance++;}
";
}

sub perl_new_window {
my ($class, $name) = @ARG;
my $me = "$class->perl_form";
return "
sub new_${name}_Window {
#
# This sub will create the UI window $name
${indent}my (\$class) = \@ARG;

";
}

sub perl_about {
    my ($class, $project, $name) = @ARG;
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        return
"sub about_Form {
${indent}my (\$class) = \@ARG;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}#
${indent}# Create a GnomeAbout 'Gnome_About2'
${indent}my \$ab = new Gnome::About(
${indent}${indent}\"$project->{'name'}\", 
${indent}${indent}\"$project->{'version'}\", 
${indent}${indent}\"Copyright $project->{'date'}\", 
${indent}${indent}\"$project->{'author'}\", 
${indent}${indent}\"$project->{'description'} \\n\".
${indent}${indent}\"Gtk version:        \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl version:    \$Gtk::VERSION\\n\".
${indent}${indent}\"run from file:        \$name\\n\".
${indent}${indent}\"$project->{'copying'}\", 
${indent}${indent}\"$project->{'logo'}\", 
${indent});
${indent}\$ab->set_title(\"About $project->{'name'}\" );
${indent}\$ab->position('mouse' );
${indent}\$ab->allow_grow('1' );
${indent}\$ab->allow_shrink('1' );
${indent}\$ab->auto_shrink('0' );
${indent}\$ab->set_modal('1' );
${indent}\$ab->show;
}";
    } else {
       return
"sub about_Form {
${indent}my (\$class) = \@ARG;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}my \$message = 
${indent}${indent}__PACKAGE__.\" (version $project->{'version'} - $project->{'date'})\\n\".
${indent}${indent}\"Written by         $project->{'author'} \\n\\n\".
${indent}${indent}\"$project->{'description'} \\n\\n\".
${indent}${indent}\"Gtk version:        \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl version:    \$Gtk::VERSION\\n\\n\".
${indent}${indent}\"run from file:        \$name\";
${indent}__PACKAGE__->message_box(\$message, \"About \\u\".__PACKAGE__, ['Dismiss', 'Quit Program'], 1,
${indent}${indent}'$project->{'logo'}', 'left' );
}";
    }
}

sub perl_UI_AUTOLOAD_new_bottom {
    my ($class, $project, $name) = @ARG;
    my $about_string = $class->perl_about($project, $name);
    return "

${indent}#
${indent}# Return all forms in the constructed UI
${indent}bless \$self, \$class;
${indent}\$self->FORM(\$forms->{'$name'});
${indent}\$self->TOPLEVEL(\$self->FORM->{'$name'});
${indent}\$self->INSTANCE(\"$name-\$instance\");
#${indent}\$__PACKAGE__::all_forms->{\"$name-\$instance\"} = \$self->FORM;
${indent}\$__PACKAGE__::all_forms->{\$self->INSTANCE} = \$self->FORM;
${indent}return \$self;

}

#===============================================================================
#==== Below are signal handlers that could be triggered                     ====
#===============================================================================
$about_string

sub destroy_Form {
#${indent}my (\$class, \$data, \$object, \$form_name) = \@ARG;
#${indent}__PACKAGE__->destroy_all_forms(\$__PACKAGE__::all_forms); 
${indent}Gtk->main_quit; 
}

";
}

sub perl_UI_Closure_header {
    my ($class, $project, $proto, $name, $permitted_stubs) = @ARG;
    my $me = "$class->perl_UI_Header";
    my $module;
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun';
    my $use_string = '';
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
        $use_string .="\n${indent}# We need the Gnome bindings as well\n".
                        "${indent}use Gnome;"
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    $module = $project->{'name'};
    # remove double spaces
    $isa_string =~ s/  / /g;
return $class->perl_preamble($module, $project, $proto, $name).
"BEGIN {
${indent}# Run-time utilities and vars
${indent}use Glade::PerlRun; 
${indent}# Existing signal handler modules${use_string}
${indent}use vars        qw( \@ISA \$AUTOLOAD \%fields \%stubs);
${indent}# Tell interpreter who we are inheriting from
${indent}\@ISA          = qw( $isa_string );
}

%fields = (
${indent}# These are the data fields that you can set/get using the dynamic
${indent}# calls provided by AUTOLOAD (and their initial values).
${indent}# eg \$class->FORMS(\$new_value);      sets the value of FORMS
${indent}#    \$current_value = \$class->FORMS; gets the current value of FORMS
${indent}TOPLEVEL => undef,
${indent}FORM     => undef,
${indent}PACKAGE  => '$module',
${indent}VERSION  => '$project->{'version'}',
${indent}AUTHOR   => '$project->{'author'}',
${indent}DATE     => '$project->{'date'}',
${indent}INSTANCE => 'Guide-App',
);

\%stubs = (
${indent}# These are signal handlers that will cause a message_box to be
${indent}# displayed by AUTOLOAD if there is not already a sub of that name
${indent}# in any module specified in 'use_modules'.
$permitted_stubs
);

sub AUTOLOAD {
${indent}my \$self = shift;
${indent}my \$type = ref(\$self)
${indent}${indent}or die \"\$self is not an object so we cannot '\$AUTOLOAD'\";
${indent}my \$name = \$AUTOLOAD;
${indent}\$name =~ s/.*://;       # strip fully-qualified portion

${indent}if (exists \$self->{_permitted_fields}->{\$name} ) {
${indent}${indent}# This allows dynamic data methods - see \%fields above
${indent}${indent}# eg \$class->UI('new_value');
${indent}${indent}# or \$current_value = \$class->UI;
${indent}${indent}if (\@_) {
${indent}${indent}${indent}return \$self->{\$name} = shift;
${indent}${indent}} else {
${indent}${indent}${indent}return \$self->{\$name};
${indent}${indent}}

${indent}} elsif (exists \$stubs{\$name} ) {
${indent}${indent}# This shows dynamic signal handler stub message_box - see \%stubs above
${indent}${indent}__PACKAGE__->show_skeleton_message(
${indent}${indent}${indent}\$AUTOLOAD.\"\\n (AUTOLOADED by \".__PACKAGE__.\")\", 
${indent}${indent}${indent}\[\$self, \@ARG], 
${indent}${indent}${indent}__PACKAGE__, 
${indent}${indent}${indent}'pixmaps/Logo.xpm');
${indent}${indent}
${indent}} else {
${indent}${indent}die \"Can't access method `\$name' in class \$type\";

${indent}}
}

sub run {
${indent}my (\$class) = \@ARG;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->TOPLEVEL->show;
${indent}Gtk->main;
}

sub new {
#
# This sub will create the UI window
${indent}my \$that  = shift;
${indent}my \$class = ref(\$that) || \$that;
${indent}my \$self  = {
${indent}${indent}_permitted_fields   => \\\%fields, \%fields,
${indent}${indent}_permitted_stubs    => \\\%stubs,  \%stubs,
${indent}};
${indent}my (\$forms, \$widgets, \$data, \$work);
${indent}my \$instance = 1;
${indent}# Get a unique toplevel widget structure
${indent}while (defined \$__PACKAGE__::all_forms->{\"$name-\$instance\"}) {\$instance++;}
";
}

sub perl_UI_Closure_new_bottom {
    my ($class, $project, $name) = @ARG;
    my $about_string;
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $about_string = 
"sub about_Form {
${indent}my (\$class) = \@ARG;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}#
${indent}# Create a GnomeAbout 'Gnome_About2'
${indent}my \$ab = new Gnome::About(
${indent}${indent}\"$project->{'name'}\", 
${indent}${indent}\"$project->{'version'}\", 
${indent}${indent}\"Copyright $project->{'date'}\", 
${indent}${indent}\"$project->{'author'}\", 
${indent}${indent}\"$project->{'description'} \\n\".
${indent}${indent}\"Gtk version:        \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl version:    \$Gtk::VERSION\\n\".
${indent}${indent}\"run from file:        \$name\\n\".
${indent}${indent}\"$project->{'copying'}\", 
${indent}${indent}\"$project->{'logo'}\", 
${indent});
${indent}\$ab->set_title(\"About $project->{'name'}\" );
${indent}\$ab->position('mouse' );
${indent}\$ab->allow_grow('1' );
${indent}\$ab->allow_shrink('1' );
${indent}\$ab->auto_shrink('0' );
${indent}\$ab->set_modal('1' );
${indent}\$ab->show;
}";
    } else {
       $about_string = 
"sub about_Form {
${indent}my (\$class) = \@ARG;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}my \$message = 
${indent}${indent}__PACKAGE__.\" (version $project->{'version'} - $project->{'date'})\\n\".
${indent}${indent}\"Written by         $project->{'author'} \\n\\n\".
${indent}${indent}\"$project->{'description'} \\n\\n\".
${indent}${indent}\"Gtk version:        \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl version:    \$Gtk::VERSION\\n\\n\".
${indent}${indent}\"run from file:        \$name\";
${indent}__PACKAGE__->message_box(\$message, \"About \\u\".__PACKAGE__, ['Dismiss', 'Quit Program'], 1,
${indent}${indent}'$project->{'logo'}', 'left' );
}";
    }

return "

${indent}#
${indent}# Return all forms in the constructed UI
${indent}bless \$self, \$class;
${indent}\$self->FORM(\$forms->{'$name'});
${indent}\$self->TOPLEVEL(\$self->FORM->{'$name'});
${indent}\$self->INSTANCE(\"$name-\$instance\");
#${indent}\$__PACKAGE__::all_forms->{\"$name-\$instance\"} = \$self->FORM;
${indent}\$__PACKAGE__::all_forms->{\$self->INSTANCE} = \$self->FORM;
${indent}return \$self;

}

#===============================================================================
#==== Below are signal handlers that could be triggered                     ====
#===============================================================================
$about_string

sub destroy_Form {
#${indent}my (\$class, \$data, \$object, \$form_name) = \@ARG;
#${indent}__PACKAGE__->destroy_all_forms(\$__PACKAGE__::all_forms); 
${indent}Gtk->main_quit; 
}

";
}

sub perl_UI_footer {
    my ($class, $project, $name, $first_form) = @ARG;
return 
"1;

\__END__

#===============================================================================
#==== Documentation ============================================================
#===============================================================================
\=pod

\=head1 NAME

${name} - version $project->{'version'} $project->{'date'}

$project->{'description'}

\=head1 SYNOPSIS

 use ${name};

 # Inherit the AUTOLOAD dynamic methods from ${name}
 *AUTOLOAD = \\\&${name}::AUTOLOAD;

 # Tell interpreter who we are inheriting from
 use vars qw( \@ISA ); \@ISA = qw( ${name} );

 To construct the window object and show it call 
 
 Gtk->init;
 my \$window = ${first_form}->new;
 \$window->TOPLEVEL->show;
 Gtk->main;
 
 OR use the shorthand for the above calls
 
 ${first_form}->run;

\=head1 DESCRIPTION

Unfortunately, the author has not yet written any documentation :-(

\=head1 AUTHOR

$project->{'author'}

\=cut
";
}

1;

__END__
