package Glade::PerlSource;
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
#                              or dermot@glade.perl.connrctfree.co.uk

BEGIN {
    use File::Copy; # for copying generated files
    use Glade::PerlRun qw( :METHODS :VARS ); # Our run-time utilities and vars
    use vars        qw( 
                        @ISA 
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE 
                        $VERSION
                        @VARS @METHODS 
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $glade2perl
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
                        $current_name
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                      );
    $PACKAGE      = __PACKAGE__;
    $VERSION        = q(0.48);
    @VARS         = qw( 
                        $VERSION
                        $AUTHOR
                        $DATE
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $glade2perl
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
                        $current_name
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                    );
    @METHODS      = qw( 
                        missing_handler
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
    my ($class) = @_;
    my $me = "$class->Write_to_File";
    my $filename = $main::Glade_Perl_Generate_options->write_source;
    if (fileno UI or fileno SIGS or fileno SUBCLASS or $class->Building_UI_only) {
        # Files are already open or we are not writing source
        if ($class->Writing_to_File) {
            if ($filename eq '-1') {
                close UI;
                close SUBCLASS;
                close SIGS;
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
        open SIGS,     ">$filename" or 
            die "error $me -can't open file '$filename' for output";
        $class->diag_print (2, "$indent- Writing SUBCLASS to '$filename' in $me");
        open SUBCLASS,     ">$filename" or 
            die "error $me -can't open file '$filename' for output";
        UI->autoflush(1);
        SUBCLASS->autoflush(1);
        SIGS->autoflush(1);
    } else {
        # Nothing to do
    }
}

sub add_to_UI {
    my ($class, $depth, $expr, $tofileonly, $notabs) = @_;
    my $me = "$class->add_to_UI";
    my $mydebug = ($class->verbosity >= 6);
    if ($depth < 0) {
        $mydebug = 1;
        $depth = -$depth;
    }
    if ($class->Writing_to_File) {
        my $UI_String = ($indent x ($depth)).$expr;
        if (!$notabs && $tab) {
            # replace multiple spaces with tabs
            $UI_String =~ s/$tab/\t/g;
        }
        eval "push \@{${current_form}\{'UI_Strings'}}, \$UI_String";
    }
    $mydebug && $class->diag_print (2, "UI    '$expr'");    
    unless ($tofileonly) {
        eval $expr or 
            ($@ && die  "\n\nin $me\n\twhile trying to eval ".
                "'$expr'\n\tFAILED with Eval error '$@'\n" );
    }
}

#===============================================================================
#=========== Source code templates                                  ============
#===============================================================================
sub warning {
    my ($class, $oktoedit) = @_;
    if ($oktoedit && $oktoedit eq 'OKTOEDIT') {
        return "#
# You can safely edit this file, any changes that you make will be preserved
# and this file will not be overwritten by the next run of $class
#
";

    } else {
        return"#
# DO NOT EDIT THIS FILE, any changes that you make will be lost when
# the file is overwritten by the next run of $class
#
";
    }
}

sub perl_UI_preamble {
    my ($class, $package, $project, $proto, $name, $oktoedit) = @_;
    my $localtime = localtime;
    my $warning_string;
    return 
"#==============================================================================
#=== This is the '$name' UI construction class                              
#==============================================================================
package $name;
require 5.000; use strict \'vars\', \'refs\', \'subs\';
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
# $class       - version $VERSION
#   Copyright (c) Date   $DATE
#                 Author $AUTHOR
#==============================================================================

";
}

sub perl_about {
    my ($class, $project, $name) = @_;
#use Data::Dumper;print Dumper($project);
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        return
"sub about_Form {
${indent}my (\$class) = \@_;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}#
${indent}# Create a GnomeAbout 'Gnome_About2'
${indent}my \$ab = new Gnome::About(
${indent}${indent}\"$name\", 
${indent}${indent}\"$project->{'version'}\", 
${indent}${indent}\"Copyright $project->{'date'}\", 
${indent}${indent}\"$project->{'author'}\", 
${indent}${indent}\"$project->{'description'} \\n\".
${indent}${indent}\"Gtk version:        \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl version:    \$Gtk::VERSION\\n\".
${indent}${indent}\"run from file:        \$name\\n\".
${indent}${indent}\"$project->{'copying'}\", 
${indent}${indent}\"$project->{'logo_filename'}\", 
${indent});
${indent}\$ab->set_title(\"About $project->{'name'}\" );
${indent}\$ab->position('mouse' );
${indent}\$ab->set_policy(1, 1, 0 );
${indent}\$ab->set_modal(1 );
${indent}\$ab->show;
}";
    } else {
       return
"sub about_Form {
${indent}my (\$class) = \@_;
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
${indent}${indent}'$project->{'logo_filename'}', 'left' );
}";
    }
}

sub perl_constructor_bottom {
    my ($class, $project, $formname) = @_;
    my $about_string = $class->perl_about($project, $project->{'name'});
    return "

${indent}#
${indent}# Return the constructed UI
${indent}bless \$self, \$class;
${indent}\$self->FORM(\$forms->{'$formname'});
${indent}\$self->TOPLEVEL(\$self->FORM->{'$formname'});
${indent}\$self->INSTANCE(\"$formname-\$instance\");
${indent}\$__PACKAGE__::all_forms->{\$self->INSTANCE} = \$self->FORM;
${indent}return \$self;
}";
}

sub perl_doc {
    my ($class, $project, $name, $first_form) = @_;
return 
"
1;

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

 # Inherit the AUTOLOAD dynamic methods from ${first_form}
 *AUTOLOAD = \\\&$first_form\::AUTOLOAD;

 # Tell interpreter who we are inheriting from
 use vars qw( \@ISA ); \@ISA = qw( ${first_form} );

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

#===============================================================================
#=========== Base class using AUTOLOAD
#===============================================================================
sub write_UI {
    my ($class, $proto) = @_;
#$class->diag_print(2, $proto);
    my $me = "$class->write_UI";
    my @code;
    my ($permitted_stubs, $UI_String);
    my ($handler, $module, $form );
#$class->diag_print(2, $proto);
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

    foreach $form (keys %$forms) {
        $class->diag_print(4, "$indent- Writing source for class $form");
        $permitted_stubs = '';
        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            $permitted_stubs .= "\n${indent}'$handler' => undef,";
        }
        # FIXME Now generate different source code for each user choice
        push @code, $class->perl_AUTOLOAD_top(
            $glade2perl, $proto, $form, $permitted_stubs)."\n";
        $UI_String = join("\n", @{$forms->{$form}{'UI_Strings'}});
        push @code, $UI_String;
        push @code, $class->perl_constructor_bottom($glade2perl, $form);
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc($glade2perl, $proto->{'UI_class'}, $first_form);

    print UI "#!/usr/bin/perl -w\n";
    print UI "#
# This is the (re)generated UI construction class.\n";
    print UI $class->warning;
    print UI join("\n", @code);
# FIXME write these files if necessary
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_Changelog;
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_Makefile;
#    print STDOUT "-------------------------------------------\n";
#    print STDOUT $class->dist_file_README;
#    print STDOUT "-------------------------------------------\n";
}

sub perl_AUTOLOAD_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->AUTOLOAD_top";
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
return $class->perl_UI_preamble($module, $project, $proto, $name, undef).
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
${indent}${indent}or die \"\$self is not an object so we cannot '\$AUTOLOAD'\\n\",
${indent}${indent}${indent}\"We were called from \",join(\", \", caller),\"\\n\\n\";
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
${indent}${indent}${indent}\[\$self, \@_], 
${indent}${indent}${indent}__PACKAGE__, 
${indent}${indent}${indent}'$project->{'logo_filename'}');
${indent}${indent}
${indent}} else {
${indent}${indent}die \"Can't access method `\$name' in class \$type\\n\",
${indent}${indent}${indent}\"We were called from \",join(\", \", caller),\"\\n\\n\";

${indent}}
}

sub run {
${indent}my (\$class) = \@_;
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

#===============================================================================
#=========== SIGS signal handler class
#===============================================================================
sub write_SIGS {
    my ($class, $proto) = @_;
    my $me = "$class->write_SUBCLASS";
    my ($permitted_stubs);
    my ($handler, $module, $form );
    my @code;
    unless (fileno SIGS) {            # ie user has supplied a filename
        # Open SIGS for output unless the filehandle is already open 
        open SIGS,     ">".($proto->{'SIGS_filename'})    or 
            die "error $me - can't open file ".
                "'$proto->{'SIGS_filename'}' for output";
        $class->diag_print (4, "$indent- Writing SIGS source     to ".
            "$proto->{'SIGS_filename'} - in $me");
        if ($main::Glade_Perl_Generate_options->autoflush) {
            SIGS->autoflush(1);
        }
    }
#    $autosubs &&
#        $class->diag_print (2, "$indent- Automatically generated SUBS are ".
#            "'$autosubs' by $me");

    $form = $first_form;
    $class->diag_print(4, "$indent- Writing SIGS for class $form");
    $permitted_stubs = '';
#$class->diag_print(2, $proto);
    foreach $form (keys %$forms) {
        push @code, $class->perl_SIGS_top(
            $glade2perl, $proto, $form, $permitted_stubs);
        push @code,  "
#==============================================================================
#=== Below are the signal handlers for '$form' UI construction class 
#==============================================================================
";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code,  
"sub $handler {
${indent}my (\$class, \$data, \$object, \$instance, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";
${indent}# Get ref to hash of all widgets on our form
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};

${indent}# REPLACE the line below with the actions to be taken when ".
    "__PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, '$glade2perl->{'logo_filename'}');

} # End of sub $handler

";
            }
        }
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc(
        $glade2perl, $proto->{'APP_class'}, $first_form);

    print SIGS "#!/usr/bin/perl -w\n";
        print SIGS "#
# This is the (re)generated signal handler class 
# You can cut and paste the skeleton signal handler subs from this file 
# into the relevant classes in your application or its subclasses\n";
    print SIGS $class->warning;
    print SIGS join("\n", @code);
    close SIGS; # flush buffers

    unless (-f $proto->{'APP_filename'}) {
        open SIGS,     ">".($proto->{'APP_filename'})    or 
            die "error $me - can't open file ".
                "'$proto->{'APP_filename'}' for output";
        $class->diag_print(2, 
            "${indent}- Creating app file $proto->{'APP_filename'}");
        print SIGS "#!/usr/bin/perl -w\n";
        print SIGS "#
# This is the basis of an application with signal handlers\n";
        print SIGS $class->warning('OKTOEDIT');
        print SIGS join("\n", @code);
    }
}

sub perl_SIGS_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_SIGS_top";
#use Data::Dumper; print Dumper(\@_;); exit
    my @code;
    my ($module, $super);
#    my $about_string = $class->perl_about($project, $name);
    my $about_string = $class->perl_about($project, $project->{'name'});
    $super = $project->{'source_directory'};
    $super =~ s/$project->{'directory'}//;
    $super =~ s/.*\/(.*)$/$1/;
    $super .= "::" if $super;
    $module = $project->{'UI_class'};
    my $init_string = '';
#    my $isa_string = 'Glade::PerlRun';
    my $use_string = "${indent}use ${super}${module};";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
#        $isa_string .= " $module";
    }
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $use_string .="\n${indent}# We need the Gnome bindings as well\n".
                        "${indent}use Gnome;";
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    # remove double spaces
#    $isa_string =~ s/  / /g;
return $class->perl_UI_preamble($module, $project, $proto, "$name").
"BEGIN {
$use_string
}

#===============================================================================
#==== Below are signal handlers
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
}

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }
";
}

#===============================================================================
#=========== Derived class (subclass)
#===============================================================================
sub write_SUBCLASS {
    my ($class, $proto) = @_;
    my $me = "$class->write_SUBCLASS";
    my @code;
    my ($permitted_stubs);
    my ($handler, $module, $form );
#    unless (fileno SUBCLASS) {            # ie user has supplied a filename
#        # Open SUBCLASS for output unless the filehandle is already open 
#        open SUBCLASS,     ">".($proto->{'SUBCLASS_filename'})    or 
#            die "error $me - can't open file ".
#                "'$proto->{'SUBCLASS_filename'}' for output";
#        $class->diag_print (4, "$indent- Writing SUBCLASS source     to ".
#            "$proto->{'SUBCLASS_filename'} - in $me");
#        if ($main::Glade_Perl_Generate_options->autoflush) {
#            SUBCLASS->autoflush(1);
#        }
#    }
#    $autosubs &&
#        $class->diag_print (2, "$indent- Automatically generated SUBS are ".
#            "'$autosubs' by $me");

    $form = $first_form;
    $class->diag_print(4, "$indent- Writing SUBCLASS for class $form");
    $permitted_stubs = '';
    # FIXME Now generate different source code for each user choice
#    push @code, $class->perl_SUBCLASS_top(
#        $project, $proto, $form, $permitted_stubs)."\n";
    foreach $form (keys %$forms) {
        push @code, $class->perl_SUBCLASS_top(
            $glade2perl, $proto, $form, $permitted_stubs);
        push @code, "
#==============================================================================
#=== Below are overloaded signal handlers for '$form' class 
#==============================================================================
";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, 
"sub $handler {
${indent}my (\$class, \$data, \$object, \$instance, \$event) = \@_;

${indent}my \$me = __PACKAGE__.\"->on_button2_clicked\";
${indent}# Get ref to hash of all widgets on our form
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};

${indent}# REPLACE the line below with the actions to be taken when ".
"__PACKAGE__.\"->on_button2_clicked.\" is called
#${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, '$glade2perl->{'logo_filename'}');
${indent}shift->SUPER::$handler(\@_);

} # End of sub $handler

";
            }
        }
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc(
        $glade2perl, $proto->{'SUBAPP_class'}, "Sub".$first_form);

#    print SUBCLASS "#!/usr/bin/perl -w\n";
#    print SUBCLASS $class->warning;
#    print SUBCLASS join("\n", @code);
#    close SUBCLASS; # flush buffers
    
    unless (-f $proto->{'SUBAPP_filename'}) {
        open SUBCLASS,     ">".($proto->{'SUBAPP_filename'})    or 
            die "error $me - can't open file ".
                "'$proto->{'SUBAPP_filename'}' for output";
        $class->diag_print(2, 
            "${indent}- Creating app subclass file $proto->{'SUBAPP_filename'}");
        print SUBCLASS "#!/usr/bin/perl -w\n";
        print SUBCLASS "#
# This is an example of a subclass of the generated application\n";
        print SUBCLASS $class->warning('OKTOEDIT');
        print SUBCLASS join("\n", @code);
    }
}

sub perl_SUBCLASS_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_SUBCLASS_top";
#use Data::Dumper; print Dumper(\@_;); exit
    my ($module, $super);
#    my $about_string = $class->perl_about($project, $name);
    my $about_string = $class->perl_about($project, "Sub$project->{'name'}");
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun';
    $super = $project->{'source_directory'};
    $super =~ s/$project->{'directory'}//;
    $super =~ s/.*\/(.*)$/$1/;
    $super .= "::" if $super;
    my $use_string = "\n${indent}use $super$project->{'APP_class'};";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $use_string .="\n${indent}# We need the Gnome bindings as well\n".
                        "${indent}use Gnome;";
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    # remove double spaces
    $isa_string =~ s/  / /g;
return $class->perl_UI_preamble($module, $project, $proto, "Sub$name").
"BEGIN {
${indent}use vars    qw( 
${indent}                 \@ISA
${indent}                 \%fields
${indent}             );
${indent}# Existing signal handler modules${use_string}
${indent}# Tell interpreter who we are inheriting from
${indent}\@ISA      = qw( $name );
${indent}# Inherit the AUTOLOAD dynamic methods from $name
${indent}*AUTOLOAD = \\\&$name\::AUTOLOAD;
}

\%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

#==============================================================================
#=== Below are the overloaded class constructors
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
${indent}my (\$class) = \@_;
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
#==== Below are any overloaded signal handlers
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
}

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }
";
}

#===============================================================================
#=========== Libglade class
#===============================================================================
sub write_LIBGLADE {
    my ($class, $proto) = @_;
    my $me = "$class->write_SUBCLASS";
    my ($permitted_stubs);
    my ($handler, $module, $form );
    unless (fileno LIBGLADE) {            # ie user has supplied a filename
        # Open LIBGLADE for output unless the filehandle is already open 
        open LIBGLADE,     ">".($proto->{'LIBGLADE_filename'})    or 
            die "error $me - can't open file ".
                "'$proto->{'LIBGLADE_filename'}' for output";
        $class->diag_print (4, "$indent- Writing LIBGLADE source     to ".
            "$proto->{'LIBGLADE_filename'} - in $me");
        if ($main::Glade_Perl_Generate_options->autoflush) {
            LIBGLADE->autoflush(1);
        }
    }
    $autosubs &&
        $class->diag_print (2, "$indent- Automatically generated SUBS are ".
            "'$autosubs' by $me");

    print LIBGLADE "#!/usr/bin/perl -w\n";
    print LIBGLADE $class->warning;
    $form = $first_form;
    $class->diag_print(4, "$indent- Writing LIBGLADE for class $form");
    $permitted_stubs = '';
    # FIXME Now generate different source code for each user choice
    print LIBGLADE $class->perl_LIBGLADE_top(
        $glade2perl, $proto, $form, $permitted_stubs)."\n";
#    print LIBGLADE $class->perl_LIBGLADE_AUTOLOAD_new_bottom($project, $form);
    foreach $form (keys %$forms) {
    print LIBGLADE "
#==============================================================================
#=== Below are the signal handlers for '$form' UI construction class 
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                print LIBGLADE "
sub $handler {
${indent}my (\$class, \$data, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";

${indent}# REPLACE the line below with the actions to be taken when ".
    "__PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, '$glade2perl->{'logo_filename'}');

} # End of sub $handler
";
            }
        }
    }
    print LIBGLADE $class->perl_doc(
        $glade2perl, $proto->{'LIBGLADE_class'}, $proto->{'LIBGLADE_class'});

}

sub perl_LIBGLADE_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_LIBGLADE_Header";
#use Data::Dumper; print Dumper(\@_;); exit
    my ($module, $super);
    my $about_string = $class->perl_about($project, $project->{'LIBGLADE_class'});
    my $init_string = '';
    my $isa_string = 'Glade::PerlRun Gtk::GladeXML';
    my $use_string = "
${indent}use Glade::PerlRun;
${indent}use Gtk::GladeXML;";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $isa_string .= " $module";
    }
    if ($main::Glade_Perl_Generate_options->{'allow_gnome'}) {
        $use_string .="\n${indent}# We need the Gnome bindings as well\n".
                        "${indent}use Gnome;";
        $init_string .= "
${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');
${indent}Gtk::GladeXML->init();";
    } else {
        $init_string .= "
${indent}Gtk->init();
${indent}Gtk::GladeXML->init();";
    }
    $super = "$project->{'source_directory'}";
    $super =~ s/.*\/(.*)$/$1/;
    $module = $project->{'name'};
    # remove double spaces
    $isa_string =~ s/  / /g;
return $class->perl_UI_preamble($module, $project, $proto, $project->{'LIBGLADE_class'}, undef).
"BEGIN {
${indent}use vars    qw( 
${indent}                 \@ISA
${indent}                 \$AUTOLOAD
${indent}                 \%fields
${indent}             );
$use_string
${indent}# Tell interpreter who we are inheriting from
${indent}\@ISA      = qw( Glade::PerlRun Gtk::GladeXML);
}

\%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

#==============================================================================
#=== Below are the class constructors
#==============================================================================
sub new {
${indent}my \$that  = shift;
${indent}# Allow indirect constructor so that we can call eg. 
${indent}#   \$window1 = BusFrame->new; \$window2 = \$window1->new;
${indent}my \$class = ref(\$that) || \$that;

${indent}# Call our super-class constructor to get an object and reconsecrate it
${indent}my \$self = bless new Gtk::GladeXML('$project->{'glade_filename'}'), \$class;

${indent}# Add our own data access methods to the inherited constructor
${indent}my(\$element);
${indent}foreach \$element (keys \%fields) {
${indent}${indent}\$self->{_permitted_fields}->{\$element} = \$fields{\$element};
${indent}}
${indent}\@{\$self}{keys \%fields} = values \%fields;
${indent}return \$self;
}

sub run {
${indent}my (\$class) = \@_;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->signal_autoconnect_from_package('$project->{'LIBGLADE_class'}');

${indent}Gtk->main;
${indent}return \$window;
}
#===============================================================================
#==== Below are signal handlers
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
}

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }
";
}

#===============================================================================
#=========== Base class using closures
#===============================================================================
sub perl_Closure_top {
    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_Closure_top";
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
return $class->perl_UI_preamble($module, $project, $proto, $name, undef).
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
${indent}${indent}${indent}\[\$self, \@_], 
${indent}${indent}${indent}__PACKAGE__, 
${indent}${indent}${indent}'$project->{'logo_filename'}');
${indent}${indent}
${indent}} else {
${indent}${indent}die \"Can't access method `\$name' in class \$type\";

${indent}}
}

sub run {
${indent}my (\$class) = \@_;
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

1;

__END__
