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
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use Data::Dumper;
    use File::Copy; # for copying generated files
    use Glade::PerlRun qw( :METHODS :VARS !&_); 
                                            # Our run-time methods and vars
                                            # but not &_ since we do that ourselves.
    use File::Basename qw( basename );      # in check_gettext_strings
    use Text::Wrap     qw( wrap $columns ); # in write_gettext_strings
    use subs        qw(
                        _
                        start_checking_gettext_strings
                    );
    use vars        qw( 
                        @ISA 
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        @VARS @METHODS 
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $widgets 
                        $data
                        $forms 
                        $work 

                        $handlers
                        $need_handlers
                        $autosubs
                        $subs

                        $radiobuttons 
                        $radiomenuitems 
                        $current_data
                        $current_name
                        $current_form
                        $current_form_name
                        $current_window
                        $first_form
                        $init_string
                      );
    @VARS         = qw( 
                        $PACKAGE 
                        $VERSION
                        $AUTHOR
                        $DATE
                        $PARTYPE $LOOKUP $BOOL $DEFAULT $KEYSYM $LOOKUP_ARRAY

                        $Glade_Perl
                        $widgets 
                        $data
                        $forms 
                        $work 

                        $handlers
                        $need_handlers
                        $autosubs
                        $subs
                        $convert
                        @use_modules
                        $NOFILE
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
                        $init_string
                    );
    @METHODS      = qw( 
                        _
                        S_
                        D_
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
    @EXPORT       = qw(  );
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

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#=========== Utilities to write output file                         ============
#===============================================================================
sub Stop_Writing_to_File { shift->Write_to_File('-1') }

sub Write_to_File {
    my ($class) = @_;
    my $me = __PACKAGE__."::Write_to_File";
    my $filename = $class->source->write;
    if (fileno UI or fileno SIGS or fileno SUBCLASS or 
        $class->Building_UI_only) {
        # Files are already open or we are not writing source
        if ($class->Writing_to_File) {
            if ($filename eq '-1') {
                close UI;
                close SUBCLASS;
                close SIGS;
                $class->diag_print (2, "%s- Closing output file in %s",
                    $indent, $me);
                $class->source->write(undef);
            } else {
                $class->diag_print (2, "%s- Already writing to %s in %s",
                    $indent, $class->Writing_to_File, $me);
            }
        }

    } elsif ($filename && ($filename eq '1')) {
        $class->diag_print (3, "%s- Using default output files ".
            "in Glade <project><source_directory> in %s", 
            $indent, $me);

    } elsif ($filename && ($filename ne '-1') ) {
        # We want to write source
        if ($filename eq 'STDOUT') {
            $class->source->write('>&STDOUT');
        }
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'UI  ', $filename, $me);
        open UI,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'SUBS', $filename, $me);
        open SIGS,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'SUBCLASS', $filename, $me);
        open SUBCLASS,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        UI->autoflush(1);
        SIGS->autoflush(1);
        SUBCLASS->autoflush(1);
    } else {
        # Nothing to do
    }
}

sub add_to_UI {
    my ($class, $depth, $expr, $tofileonly, $notabs) = @_;
    my $me = "$class->add_to_UI";
    my $mydebug = ($Glade_Perl->verbosity >= 6);
    if ($depth < 0) {
        $mydebug = 1;
        $depth = -$depth;
    }
    if ($Glade_Perl->Writing_to_File) {
        my $UI_String = ($indent x ($depth)).$expr;
        if (!$notabs && $tab) {
            # replace multiple spaces with tabs
            $UI_String =~ s/$tab/\t/g;
        }
        eval "push \@{${current_form}\{'UI_Strings'}}, \$UI_String";
    }
    unless ($tofileonly) {
        eval $expr or 
            ($@ && die  "\n\nin $me\n\twhile trying to eval".
                "'$expr'\n\tFAILED with Eval error '$@'\n");
    }
    if ($mydebug) {
        $expr =~ s/\%/\%\%/g;
        $Glade_Perl->diag_print (2, "UI%s'%s'", $indent, $expr);
    }
}

#===============================================================================
#=========== Documentation files
#===============================================================================
sub doc_COPYING {
}

sub doc_Changelog {
}

sub doc_FAQ {
}

sub doc_INSTALL {
}

sub doc_NEWS {
}

sub doc_README {
}

sub doc_ROADMAP {
}

sub doc_TODO {
}

#===============================================================================
#=========== Distribution files
#===============================================================================
sub dist_MANIFEST {
}

sub dist_Makefile_PL {
}

sub dist_spec {
}

sub dist_test_pl {
}

#===============================================================================
#=========== Source code 
#===============================================================================
sub warning {
    my ($class, $oktoedit) = @_;
    if ($oktoedit && $oktoedit eq 'OKTOEDIT') {
        return "#
# ".S_("You can safely edit this file, any changes that you make will be preserved")."
# ".S_("and this file will not be overwritten by the next run of")." $class
#
";

    } else {
        return "#
# ".S_("DO NOT EDIT THIS FILE, ANY CHANGES THAT YOU MAKE WILL BE LOST WHEN")."
# ".S_("THIS FILE WILL BE OVERWRITTEN BY THE NEXT RUN OF")." $class
#
";
    }
}

sub perl_preamble {
    my ($class, $proto, $name) = @_;
    my $me = __PACKAGE__."->perl_preamble";
    my $project = $proto->app;
    my $glade2perl = $proto->glade2perl;
    $name ||= $project->{name};
#print "$me - ",Dumper($project);
    return 
"#==============================================================================
#=== ".S_("This is the")." '$name' class                              
#==============================================================================
package $name;
require 5.000; use strict \'vars\', \'refs\', \'subs\';
# UI class '$name' (".S_("version")." $project->{'version'})
# 
# ".S_("Copyright")." (c) ".S_("Date")." $project->{'date'}
# ".S_("Author")." $project->{'author'}
#
#$project->{'copying'} $project->{'author'}
#
#==============================================================================
# ".S_("This perl source file was automatically generated by")." 
# $class ".S_("version")." $glade2perl->{version} - $glade2perl->{date}
# ".S_("Copyright")." (c) ".S_("Author")." $glade2perl->{author}
#
# ".S_("from Glade file")." $proto->{'glade'}{'file'}
# $glade2perl->{'start_time'}
#==============================================================================

";
}

sub perl_about {
    my ($class, $proto, $name) = @_;
    my $logo = "\$Glade::PerlRun::pixmaps_directory";
    my $project = $proto->app;
    $logo .= '/' if $logo;
    $logo .= $project->{'logo'};

    if ($proto->app->allow_gnome) {
        return
#${indent}${indent}\"$name\", 
#${indent}${indent}\"$project->{'version'}\", 
"sub about_Form {
${indent}my (\$class) = \@_;
${indent}my \$gtkversion = 
${indent}${indent}Gtk->major_version.\".\".
${indent}${indent}Gtk->minor_version.\".\".
${indent}${indent}Gtk->micro_version;
${indent}my \$name = \$0;
${indent}#
${indent}# ".S_("Create a")." Gnome::About '\$ab'
${indent}my \$ab = new Gnome::About(
${indent}${indent}\$PACKAGE, 
${indent}${indent}\$VERSION, 
${indent}${indent}_(\"Copyright\").\" \$DATE\", 
${indent}${indent}\$AUTHOR, 
${indent}${indent}_(\"$project->{'description'}\").\"\\n\".
${indent}${indent}\"Gtk \".     _(\"version\").\": \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl \"._(\"version\").\": \$Gtk::VERSION\\n\".
${indent}${indent}`gnome-config --version`.\"\\n\".
${indent}${indent}_(\"run from file\").\": \$name\\n\".
${indent}${indent}\"$project->{'copying'}\", 
${indent}${indent}\"$logo\", 
${indent});
${indent}\$ab->set_title(_(\"About\").\" $name\" );
${indent}\$ab->position('mouse' );
${indent}\$ab->set_policy(1, 1, 0 );
${indent}\$ab->set_modal(1 );
${indent}\$ab->show;
} # ".S_("End of sub")." about_Form";

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
${indent}${indent}__PACKAGE__.\" (\"._(\"version\").\" \$VERSION - \$DATE)\\n\".
${indent}${indent}_(\"Written by\").\" \$AUTHOR \\n\\n\".
${indent}${indent}_(\"$project->{'description'}\").\" \\n\\n\".
${indent}${indent}\"Gtk \".     _(\"version\").\": \$gtkversion\\n\".
${indent}${indent}\"Gtk-Perl \"._(\"version\").\": \$Gtk::VERSION\\n\".
${indent}${indent}_(\"run from file\").\": \$name\";
${indent}__PACKAGE__->message_box(\$message, _(\"About\").\" \\u\".__PACKAGE__, [_('Dismiss'), _('Quit Program')], 1,
${indent}${indent}\"$logo\", 'left' );
} # ".S_("End of sub")." about_Form";
    }
}

sub perl_load_translations {
    my ($class, $name, $dir, $LANG) = @_;
    $LANG ||= 'fr';
    return
"${indent}\$class->load_translations('$name');
${indent}# ".S_("You can use the line below to load a test .mo file before it is installed in ")."
${indent}# ".S_("the normal place")." (eg /usr/local/share/locale/".
    $LANG."/LC_MESSAGES/$name.mo)
#${indent}\$class->load_translations('$name', 'test', undef, ".
    "'$dir/ppo/$name.mo');\n";
}

sub perl_signal_handler {
    my ($class, $handler, $type) = @_;
    my ($body);
    my $project = $Glade_Perl->app;
    if ($type eq 'SIGS') {
        $body = "
${indent}my (\$class, \$data, \$object, \$instance, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";
${indent}# ".S_("Get ref to hash of all widgets on our form")."
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};

${indent}# ".S_("REPLACE the line below with the actions to be taken when").
    " __PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, \"\$Glade::PerlRun::pixmaps_directory/$project->{logo}\");

";
    } elsif ($type eq 'SUBCLASS') {
        $body = "
${indent}my (\$class, \$data, \$object, \$instance, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";
${indent}# ".S_("Get ref to hash of all widgets on our form")."
${indent}my \$form = \$__PACKAGE__::all_forms->{\$instance};

${indent}# ".S_("REPLACE the lines below with the actions to be taken when").
    " __PACKAGE__.\"->$handler.\" is called
#${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, \"\$Glade::PerlRun::pixmaps_directory/$project->{logo}\");
${indent}shift->SUPER::$handler(\@_);

";
    } elsif ($type eq 'Libglade') {
        $body = "
${indent}my (\$class, \$data, \$event) = \@_;
${indent}my \$me = __PACKAGE__.\"->$handler\";

${indent}# ".S_("REPLACE the line below with the actions to be taken when").
    " __PACKAGE__.\"->$handler.\" is called
${indent}__PACKAGE__->show_skeleton_message(\$me, \\\@_, ".
    "__PACKAGE__, \"\$Glade::PerlRun::pixmaps_directory/$project->{logo}\");

";
    }

    return "sub $handler {$body} # ".S_("End of sub")." $handler
";
}

sub perl_constructor_bottom {
    my ($class, $proto, $formname) = @_;
    my $project = $proto->app;
    my $about_string = $class->perl_about($proto, $project->{'name'});
    return "

${indent}#
${indent}# ".S_("Return the constructed UI")."
${indent}bless \$self, \$class;
${indent}\$self->FORM(\$forms->{'$formname'});
${indent}\$self->TOPLEVEL(\$self->FORM->{'$formname'});
${indent}\$self->FORM->{'TOPLEVEL'} = (\$self->TOPLEVEL);
${indent}\$self->INSTANCE(\"$formname-\$instance\");
${indent}\$self->CLASS_HIERARCHY(\$self->FORM->{'__WH'});
${indent}\$self->WIDGET_HIERARCHY(\$self->FORM->{'__CH'});
${indent}\$__PACKAGE__::all_forms->{\$self->INSTANCE} = \$self->FORM;
${indent}
${indent}return \$self;
} # ".S_("End of sub")." new";
}

sub perl_doc {
    my ($class, $proto, $use_module, $first_form) = @_;
    $use_module ||= $proto->app->name;
    my $project = $proto->app;
#print Dumper($project);
    $use_module ||= $project->{name};
# FIXME I18N
return 
"
1;

\__END__

#===============================================================================
#==== ".S_("Documentation")."
#===============================================================================
\=pod

\=head1 NAME

$use_module - ".S_("version")." $project->{'version'} $project->{'date'}

".S_("$project->{'description'}")."

\=head1 SYNOPSIS

 use $use_module;

 ".S_("To construct the window object and show it call")."
 
 Gtk->init;
 my \$window = ${first_form}->new;
 \$window->TOPLEVEL->show;
 Gtk->main;
 
 ".S_("OR use the shorthand for the above calls")."
 
 ${first_form}->app_run;

\=head1 DESCRIPTION

".S_("Unfortunately, the author has not yet written any documentation :-(")."

\=head1 AUTHOR

$project->{'author'}

\=cut
";
}

# if (\$".S_("we_want_to_subclass_this_class").") {
#   # ".S_("Inherit the AUTOLOAD dynamic methods from")." ${first_form}
#   *AUTOLOAD = \\\&$first_form\::AUTOLOAD;
#
#   # ".S_("Tell interpreter who we are inheriting from")."
#   use vars qw( \@ISA ); \@ISA = qw( ${first_form} );
# }
 
#===============================================================================
#=========== Base class using AUTOLOAD
#===============================================================================
sub write_UI {
    my ($class, $proto, $forms) = @_;
#$Glade_Perl->diag_print(2, $proto);
    my $me = "$class->write_UI";
    my @code;
    my ($permitted_stubs, $UI_String);
    my ($handler, $module, $form );
#$Glade_Perl->diag_print(2, $proto);
    unless (fileno UI) {            # ie user has supplied a filename
        # Open UI for output unless the filehandle is already open 
        open UI,     ">".($proto->module->ui->file)    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->module->ui->file);
        $Glade_Perl->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'UI  ', $proto->module->ui->file, $me);
        UI->autoflush(1) if $proto->diag->autoflush;
#        if ($proto->diag->autoflush) { UI->autoflush(1); }
    }
    foreach $form (keys %$forms) {
#        next if $form =~ /^__/;
        $Glade_Perl->diag_print(4, "%s- Writing %s for class %s",
            $indent, 'source', $form);
        $permitted_stubs = '';
        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            $permitted_stubs .= "\n${indent}'$handler' => undef,";
        }
        # FIXME Now generate different source code for each user choice
        push @code, $class->perl_AUTOLOAD_top($proto, $form, $permitted_stubs)."\n";
        $UI_String = join("\n", @{$forms->{$form}{'UI_Strings'}});
        push @code, $UI_String;
        push @code, $class->perl_constructor_bottom($proto, $form);
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc($proto, $proto->{'UI_class'}, $first_form);

    print UI "#!/usr/bin/perl -w\n";
    print UI "#\n# ".S_("This is the (re)generated UI construction class.")."\n";
    print UI $class->warning;
    print UI join("\n", @code);
    close UI;
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
    my ($class, $proto, $name, $permitted_stubs) = @_;
#    my ($class, $project, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->AUTOLOAD_top";
    my $project = $proto->app;
#print "$me - ",Dumper($project);
    my $module;
    $init_string = '';
    my $ISA_string = 'Glade::PerlRun';
    my $use_string = '';
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $ISA_string .= " $module";
    }
    $init_string .= $class->perl_load_translations(
        $proto->app->name, $proto->glade->directory, $proto->source->LANG);

    if ($proto->app->allow_gnome) {
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
        $use_string .="\n${indent}# ".
                        S_("We need the Gnome bindings as well").
                        "\n${indent}use Gnome;"
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    $module = $project->{'name'};
    # remove double spaces
    $ISA_string =~ s/  / /g;

return $class->perl_preamble($proto, $name).
"BEGIN {
${indent}# ".S_("Run-time utilities and vars")."
${indent}use Glade::PerlRun; 
${indent}# ".S_("Existing signal handler modules")."${use_string}
${indent}use vars qw( 
${indent}             \@ISA
${indent}             \%fields
${indent}             \%stubs
${indent}             \$PACKAGE
${indent}             \$VERSION
${indent}             \$AUTHOR
${indent}             \$DATE
${indent}             \$AUTOLOAD
${indent}             \$permitted_fields
${indent}         );
${indent}# ".S_("Tell interpreter who we are inheriting from")."
${indent}\@ISA     = qw( $ISA_string );
${indent}\$PACKAGE = '$project->{'name'}';
${indent}\$VERSION = '$project->{'version'}';
${indent}\$AUTHOR  = '$project->{'author'}';
${indent}\$DATE    = '$project->{'date'}';
${indent}\$permitted_fields = '_permitted_fields';             
} # ".S_("End of sub")." BEGIN

${indent}\$Glade::PerlRun::pixmaps_directory ||= '$Glade_Perl->{glade}{pixmaps_directory}';

%fields = (
${indent}# ".S_("These are the data fields that you can set/get using the dynamic")."
${indent}# ".S_("calls provided by AUTOLOAD (and their initial values).")."
${indent}# eg \$class->FORM(\$new_value);      ".S_("sets the value of FORM")."
${indent}#    \$current_value = \$class->FORM; ".S_("gets the current value of FORM")."
${indent}TOPLEVEL => undef,
${indent}FORM     => undef,
${indent}PACKAGE  => '$module',
${indent}VERSION  => '$project->{'version'}',
${indent}AUTHOR   => '$project->{'author'}',
${indent}DATE     => '$project->{'date'}',
${indent}INSTANCE => '$first_form',
${indent}CLASS_HIERARCHY => undef,
${indent}WIDGET_HIERARCHY => undef,
);

\%stubs = (
${indent}# ".S_("These are signal handlers that will cause a message_box to be")."
${indent}# ".S_("displayed by AUTOLOAD if there is not already a sub of that name")."
${indent}# ".S_("in any module specified in 'use_modules'.")."
$permitted_stubs
);

sub AUTOLOAD {
${indent}my \$self = shift;
${indent}my \$type = ref(\$self)
${indent}${indent}or die \"\$self is not an object so we cannot '\$AUTOLOAD'\\n\",
${indent}${indent}${indent}\"We were called from \".join(\", \", caller).\"\\n\\n\";
${indent}my \$name = \$AUTOLOAD;
${indent}\$name =~ s/.*://;       # ".S_("strip fully-qualified portion")."

${indent}if (exists \$self->{\$permitted_fields}->{\$name} ) {
${indent}${indent}# ".S_("This allows dynamic data methods - see hash fields above")."
${indent}${indent}# eg \$class->UI('".S_("new_value")."');
${indent}${indent}# or \$current_value = \$class->UI;
${indent}${indent}if (\@_) {
${indent}${indent}${indent}return \$self->{\$name} = shift;
${indent}${indent}} else {
${indent}${indent}${indent}return \$self->{\$name};
${indent}${indent}}

${indent}} elsif (exists \$stubs{\$name} ) {
${indent}${indent}# ".S_("This shows dynamic signal handler stub message_box - see hash stubs above")."
${indent}${indent}__PACKAGE__->show_skeleton_message(
${indent}${indent}${indent}\$AUTOLOAD.\"\\n (\"._(\"AUTOLOADED by\").\" \".__PACKAGE__.\")\", 
${indent}${indent}${indent}\[\$self, \@_], 
${indent}${indent}${indent}__PACKAGE__, 
${indent}${indent}${indent}'$proto->{app}{'logo'}');
${indent}${indent}
${indent}} else {
${indent}${indent}die \"Can't access method\ `\$name' in class \$type\\n\".
${indent}${indent}${indent}\"We were called from \".join(\", \", caller).\"\\n\\n\";

${indent}}
} # ".S_("End of sub")." AUTOLOAD

sub run {
${indent}my (\$class) = \@_;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->TOPLEVEL->show;
${indent}Gtk->main;
} # ".S_("End of sub")." run

sub DESTROY {
${indent}# This sub will be called on object destruction
} # ".S_("End of sub")." DESTROY

sub new {
#
# ".S_("This sub will create the UI window")."
${indent}my \$that  = shift;
${indent}my \$class = ref(\$that) || \$that;
${indent}my \$self  = {
${indent}${indent}\$permitted_fields   => \\\%fields, \%fields,
${indent}${indent}_permitted_stubs    => \\\%stubs,  \%stubs,
${indent}};
${indent}my (\$forms, \$widgets, \$data, \$work);
${indent}my \$instance = 1;
${indent}# ".S_("Get a unique toplevel widget structure")."
${indent}while (defined \$__PACKAGE__::all_forms->{\"$name-\$instance\"}) {\$instance++;}
";
}

#===============================================================================
#=========== SIGS signal handler class
#===============================================================================
sub write_split_SIGS {
    my ($class, $proto, $forms) = @_;
    my $me = "$class->write_APP";
    my ($permitted_stubs);
    my ($handler, $module, $form, $filename );
    my @code;

    foreach $form (keys %$forms) {
        # Open SIGS for output unless the filehandle is already open 
        @code = ();
        $filename = $proto->module->sigs->base."_".$form.".pm";
        open SIGS, ">$filename"    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $Glade_Perl->diag_print (2, "%s- Writing %s source to %s - in %s",
            $indent, 'SIGS', $filename, $me);
        SIGS->autoflush(1) if $proto->diag->autoflush;
#        if ($proto->diag->autoflush) { SIGS->autoflush(1); }
        $autosubs &&
            $Glade_Perl->diag_print (4, "%s- Automatically generated SUBS are '%s' by %s",
                $indent, $autosubs, $me);

        $Glade_Perl->diag_print(4, "%s- Writing %s for class %s", 
            $indent, 'SIGS', $form);
        $permitted_stubs = '';

        push @code, $class->perl_SIGS_top( $proto, $form, $permitted_stubs);
        push @code,  "
#==============================================================================
#=== ".S_("Below are the signal handlers for")." '$form' class 
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'SIGS');
            }
        }

        print SIGS "#!/usr/bin/perl -w\n";
        print SIGS "#
# ".S_("This is the (re)generated signal handler class")."
# ".S_("You can cut and paste the skeleton signal handler subs from this file")."
# ".S_("into the relevant classes in your application or its subclasses")."\n";
        print SIGS $class->warning;
        print SIGS join("\n", @code);
        print SIGS $class->perl_doc($proto, $form, $form);
        close SIGS; # flush buffers

        $filename = $proto->module->app->base."_".$form.".pm";
        unless (-f $filename) {
            open SIGS, ">$filename" or 
                die sprintf((
                    "error %s - can't open file '%s' for output"),
                    $me, $filename);
            $Glade_Perl->diag_print(4, "%s- Creating %s file %s",
                $indent, 'app', $filename);
            $Glade_Perl->diag_print (2, "%s- Writing %s to %s - in %s",
                $indent, 'App', $filename, $me);
            SIGS->autoflush(1) if $proto->diag->autoflush;
#            if ($proto->diag->autoflush) { SIGS->autoflush(1); }
            print SIGS "#!/usr/bin/perl -w\n";
            print SIGS "#
# ".S_("This is the basis of an application with signal handlers")."\n
";
            print SIGS $class->warning('OKTOEDIT');
            print SIGS "# ".
S_("Skeleton subs of any missing signal handlers can be copied from")."
# ".$proto->module->app->base."_".$form."SIGS.pm
#
";
            print SIGS join("\n", @code);
            print SIGS $class->perl_doc($proto, $proto->module->app->class."_".$form, $form);
        }
    }
}

sub write_SIGS {
    my ($class, $proto, $forms) = @_;
    my $me = "$class->write_SIGS";
    my ($permitted_stubs);
    my ($handler, $module, $form );

    my @code;
    unless (fileno SIGS) {            # ie user has supplied a filename
        # Open SIGS for output unless the filehandle is already open 
        open SIGS,     ">".($proto->module->sigs->file)    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->module->sigs->file);
        $Glade_Perl->diag_print (2, "%s- Writing %s source to %s - in %s",
            $indent, 'SIGS', $proto->module->sigs->file, $me);
        SIGS->autoflush(1) if $proto->diag->autoflush;
#        if ($proto->diag->autoflush) { SIGS->autoflush(1); }
    }
    $autosubs &&
        $Glade_Perl->diag_print (4, "%s- Automatically generated SUBS are '%s' by %s",
            $indent, $autosubs, $me);

    $Glade_Perl->diag_print(4, "%s- Writing %s for class %s", 
        $indent, 'SIGS', $first_form);
    $permitted_stubs = '';
    foreach $form (keys %$forms) {
        push @code, $class->perl_SIGS_top($proto, $form, $permitted_stubs);
        push @code,  "
#==============================================================================
#=== ".S_("Below are the signal handlers for")." '$form' class 
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'SIGS');
            }
        }
        push @code, "\n\n\n\n\n\n\n\n";
    }

    print SIGS "#!/usr/bin/perl -w\n";
    print SIGS "#
# ".S_("This is the (re)generated signal handler class")."
# ".S_("You can cut and paste the skeleton signal handler subs from this file")."
# ".S_("into the relevant classes in your application or its subclasses")."\n";
    print SIGS $class->warning;
    print SIGS join("\n", @code);
    print SIGS $class->perl_doc($proto, $proto->module->sigs->class, $first_form);
    close SIGS; # flush buffers

    unless (-f $proto->module->app->file) {
        open SIGS,     ">".($proto->module->app->file)    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->module->app->file);
        $Glade_Perl->diag_print(4, "%s- Creating %s file %s",
            $indent, 'app', $proto->module->app->file);
        $Glade_Perl->diag_print (2, "%s- Writing %s to %s - in %s",
            $indent, 'App', $proto->module->app->file, $me);
        SIGS->autoflush(1) if $proto->diag->autoflush;
#        if ($proto->diag->autoflush) { SIGS->autoflush(1); }
        print SIGS "#!/usr/bin/perl -w\n";
        print SIGS "#
# ".S_("This is the basis of an application with signal handlers")."
";
        print SIGS $class->warning('OKTOEDIT');
            print SIGS "# ".
S_("Skeleton subs of any missing signal handlers can be copied from")."
# ".$proto->module->app->base."SIGS.pm
#
";
        print SIGS join("\n", @code);
        print SIGS $class->perl_doc($proto, $proto->module->app->class, $first_form);
    }
}

sub perl_SIGS_top {
    my ($class, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_SIGS_top";
#use Data::Dumper; print Dumper(\@_;); exit
    my @code;
    my ($module, $super);
    my $project = $proto->app;
#    my $about_string = $class->perl_about($project, $name);
    my $about_string = $class->perl_about($proto, $name);
    $super = $proto->module->directory;
    $super =~ s/$proto->{glade}{'directory'}//;
    $super =~ s/.*\/(.*)$/$1/;
    $super .= "::" if $super;
    $module = $proto->module->ui->class;
    my $init_string = '';
    my $use_string = "${indent}use ${super}${module};";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
    }
    $init_string .= $class->perl_load_translations(
        $proto->app->name, $proto->glade->directory, $proto->source->LANG);
    if ($proto->app->allow_gnome) {
        $use_string .="\n${indent}# ".S_("We need the Gnome bindings as well")."\n".
                        "${indent}use Gnome;";
        $init_string .= "${indent}Gnome->init(\"\$PACKAGE\", \"\$VERSION\");";
#        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
    } else {
        $init_string .= "${indent}Gtk->init;";
    }

return $class->perl_preamble($proto, $name).
"BEGIN {
$use_string
} # ".S_("End of sub")." BEGIN

sub app_run {
${indent}my (\$class) = \@_;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->TOPLEVEL->show;

${indent}# ".S_("Put any extra UI initialisation (eg signal_connect) calls here")."

${indent}# ".S_("Now let Gtk handle signals")."
${indent}Gtk->main;

${indent}\$window->TOPLEVEL->destroy;

${indent}return \$window;

} # ".S_("End of sub")." app_run

#===============================================================================
#=== ".S_("Below are the default signal handlers for")." '$name' class
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
} # ".S_("End of sub")." destroy_Form

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }";
}

#===============================================================================
#=========== Derived class (subclass)
#===============================================================================
sub write_SUBCLASS {
    my ($class, $proto, $forms) = @_;
    my $me = "$class->write_SUBCLASS";
    return if (-f $proto->module->subapp->file);
    my @code;
    my ($permitted_stubs);
    my ($handler, $module, $form );
    unless (fileno SUBCLASS) {            # ie user has supplied a filename
        open SUBCLASS,     ">".($proto->module->subapp->file)    or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $proto->module->subapp->file);
        $Glade_Perl->diag_print(2, 
            "%s- Writing %s file %s",
            $indent, 'App Subclass', $proto->module->subapp->file);
#        $Glade_Perl->diag_print (2, "%s- Writing %s to %s - in %s",
#            $indent, 'Subclass', $proto->module->subclass->file, $me);
#        SUBCLASS->autoflush(1) if $proto->diag->autoflush;
        if ($proto->diag->autoflush) { SUBCLASS->autoflush(1); }
    }
#    $autosubs &&
#        $Glade_Perl->diag_print (4, "%s- Automatically generated SUBS are '%s' by %s",
#               $indent, $autosubs, $me);

    $form = $first_form;
    $Glade_Perl->diag_print(4, "%s- Writing %s for class %s",
        $indent, 'SUBCLASS', $form);
    $permitted_stubs = '';

    foreach $form (keys %$forms) {
        push @code, $class->perl_SUBCLASS_top($proto, $form, $permitted_stubs);
        push @code, "
#==============================================================================
#=== ".S_("Below are (overloaded) signal handlers for")." '$form' class 
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'SUBCLASS');
            }
        }
        push @code, "\n\n\n\n\n\n\n\n";
    }
    push @code, $class->perl_doc($proto, $proto->module->subapp->class, "Sub".$first_form);

    print SUBCLASS "#!/usr/bin/perl -w\n";
    print SUBCLASS "#
# ".S_("This is an example of a subclass of the generated application")."\n";
    print SUBCLASS $class->warning('OKTOEDIT');
    print SUBCLASS join("\n", @code);
    close SUBCLASS;
}

sub perl_SUBCLASS_top {
    my ($class, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_SUBCLASS_top";
#use Data::Dumper; print Dumper(\@_;); exit
    my ($module, $super);
    my $project = $proto->app;
#    my $about_string = $class->perl_about($project, $name);
    my $about_string = $class->perl_about($proto, "Sub$project->{'name'}");
    my $init_string = '';
    my $ISA_string = 'Glade::PerlRun';
    $super = $proto->module->directory;
    $super =~ s/$proto->{glade}{directory}//;
    $super =~ s/.*\/(.*)$/$1/;
    $super .= "::" if $super;
    my $use_string = "\n${indent}use $super$proto->{module}{app}{class};";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $ISA_string .= " $module";
    }
    if ($proto->app->allow_gnome) {
        $use_string .="\n${indent}# ".S_("We need the Gnome bindings as well")."\n".
                        "${indent}use Gnome;";
        $init_string .= "${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');";
    } else {
        $init_string .= "${indent}Gtk->init;";
    }
    # remove double spaces
    $ISA_string =~ s/  / /g;
# FIXME I18N
return $class->perl_preamble($proto, "Sub$name").
"BEGIN {
${indent}use vars qw( 
${indent}             \@ISA
${indent}             \%fields
${indent}             \$PACKAGE
${indent}             \$VERSION
${indent}             \$AUTHOR
${indent}             \$DATE
${indent}             \$permitted_fields
${indent}         );
${indent}# ".S_("Existing signal handler modules")."${use_string}
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}use Glade::PerlSource;
${indent}# ".S_("Tell interpreter who we are inheriting from")."
${indent}\@ISA     = qw( $name );
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}\@ISA      = qw( $name Glade::PerlSource );
${indent}\$PACKAGE = 'Sub$project->{'name'}';
${indent}\$VERSION = '$project->{'version'}';
${indent}\$AUTHOR  = '$project->{'author'}';
${indent}\$DATE    = '$project->{'date'}';
${indent}\$permitted_fields = '_permitted_fields';             
${indent}# ".S_("Inherit the AUTOLOAD dynamic methods from")." $name
${indent}*AUTOLOAD = \\\&$name\::AUTOLOAD;
} # ".S_("End of sub")." BEGIN

\%fields = (
# ".S_("Insert any extra data access methods that you want to add to")." 
#   ".S_("our inherited super-constructor (or overload)")."
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

sub DESTROY {
${indent}# This sub will be called on object destruction
} # ".S_("End of sub")." DESTROY

#==============================================================================
#=== ".S_("Below are the overloaded class constructors")."
#==============================================================================
sub new {
${indent}my \$that  = shift;
${indent}# ".S_("Allow indirect constructor so that we can call eg. ")."
${indent}#   \$window1 = BusFrame->new; \$window2 = \$window1->new;
${indent}my \$class = ref(\$that) || \$that;

${indent}# ".S_("Call our super-class constructor to get an object and reconsecrate it")."
${indent}my \$self = bless \$that->SUPER::new(), \$class;

${indent}# ".S_("Add our own data access methods to the inherited constructor")."
${indent}my(\$element);
${indent}foreach \$element (keys \%fields) {
${indent}${indent}\$self->{\$permitted_fields}->{\$element} = \$fields{\$element};
${indent}}
${indent}\@{\$self}{keys \%fields} = values \%fields;
${indent}return \$self;
} # ".S_("End of sub")." new

sub app_run {
${indent}my (\$class) = \@_;
$init_string
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}\$class->check_gettext_strings;
${indent}my \$window = \$class->new;
${indent}# ".S_("Insert your subclass user data key/value pairs ")."
${indent}\$window->USERDATA({
#${indent}${indent}'Key1'   => 'Value1',
#${indent}${indent}'Key2'   => 'Value2',
#${indent}${indent}'Key3'   => 'Value3',
${indent}});
${indent}\$window->TOPLEVEL->show;
#${indent}my \$window2 = \$window->new;
#${indent}\$window2->TOPLEVEL->show;
${indent}Gtk->main;
${indent}# ".S_("Uncomment the line below to enable gettext checking")."
#${indent}\$window->write_gettext_strings(\"__\", '$proto->{module}{pot}{file}');
${indent}\$window->TOPLEVEL->destroy;

${indent}return \$window;
} # ".S_("End of sub")." run
#===============================================================================
#=== ".S_("Below are (overloaded) default signal handlers for")." '$name' class 
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
} # ".S_("End of sub")." destroy_Form

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }";
}

#===============================================================================
#=========== Libglade class
#===============================================================================
sub write_LIBGLADE {
    my ($class, $proto, $forms) = @_;
    my $me = "$class->write_LIBGLADE";
    my @code;
    my ($permitted_stubs);
    my ($handler, $module, $form );
    return if -f $proto->module->libglade->file;
    unless (fileno LIBGLADE) {            # ie user has supplied a filename
        # Open LIBGLADE for output unless the filehandle is already open 
        open LIBGLADE,     ">".($proto->module->libglade->file)    or 
            die sprintf(
                "error %s - can't open file '%s' for output",
                $me, $proto->module->libglade->file);
    }
    $autosubs &&
        $Glade_Perl->diag_print (4, "%s- Automatically generated %s are '%s' by %s",
            $indent, 'SUBS', $autosubs, $me);

#    $form = $first_form;
    $form = $proto->module->libglade->class."LIBGLADE";
    $Glade_Perl->diag_print(4, "%s- Writing %s for class %s", 
        $indent, 'LIBGLADE', $form);
    $permitted_stubs = '';

#    push @code, $class->perl_LIBGLADE_top($proto, $form, $permitted_stubs)."\n";
    foreach $form (keys %$forms) {
        push @code, $class->perl_LIBGLADE_top($proto, $form, $permitted_stubs)."\n";
        push @code, "
#==============================================================================
#=== ".S_("Below are the signal handlers for")." '".$form."' UI
#==============================================================================";

        foreach $handler (sort keys (%{$forms->{$form}{'_HANDLERS'}})) {
            unless ($autosubs =~ / $handler /) {
                push @code, $class->perl_signal_handler($handler, 'Libglade');
            }
        }
    }
    push @code, $class->perl_doc($proto, $form, $first_form);

    open LIBGLADE,     ">".($proto->module->libglade->file)    or 
        die sprintf((
            "error %s - can't open file '%s' for output"),
            $me, $proto->module->libglade->file);
    $Glade_Perl->diag_print(2, 
        "%s- Creating %s file %s",
        $indent, 'libglade app', $proto->module->libglade->file);
    $Glade_Perl->diag_print (2, "%s- Writing %s source to %s - in %s",
        $indent, 'LIBGLADE App', $proto->module->libglade->file, $me);
    LIBGLADE->autoflush(1) if $proto->diag->autoflush;

    print LIBGLADE "#!/usr/bin/perl -w\n";
    print LIBGLADE "#\n# ".S_("This is the basis of a LIBGLADE application with signal handlers")."\n";
    print LIBGLADE $class->warning('OKTOEDIT');
    print LIBGLADE join("\n", @code);
    close LIBGLADE;
}

sub perl_LIBGLADE_top {
    my ($class, $proto, $name, $permitted_stubs) = @_;
    my $me = "$class->perl_LIBGLADE_top";
#use Data::Dumper; print Dumper(\@_); exit
    my ($module, $super);
    my $project = $proto->app;
    my $about_string = $class->perl_about($proto, $proto->module->libglade->class);
    my $init_string = '';
    my $ISA_string = 'Glade::PerlRun Gtk::GladeXML';
    my $use_string = "
${indent}use Glade::PerlRun;
${indent}use Gtk::GladeXML;";
    $permitted_stubs = $permitted_stubs || '';
    foreach $module (@use_modules) {
        $use_string .= "\n${indent}use $module;";
        $ISA_string .= " $module";
    }
    if ($proto->app->allow_gnome) {
        $use_string .="\n${indent}# ".S_("We need the Gnome bindings as well")."\n".
                        "${indent}use Gnome;";
        $init_string .= "
${indent}Gnome->init('$project->{'name'}', '$project->{'version'}');
${indent}Gtk::GladeXML->init();";
    } else {
        $init_string .= "
${indent}Gtk->init();
${indent}Gtk::GladeXML->init();";
    }
    $super = "$proto->{glade}{directory}";
    $super =~ s/.*\/(.*)$/$1/;
    $module = $project->{'name'};
    # remove double spaces
    $ISA_string =~ s/  / /g;
# FIXME I18N
#return $class->perl_preamble($proto, $proto->module->libglade->class).
return $class->perl_preamble($proto, $name).
"BEGIN {
${indent}use vars qw( 
${indent}             \@ISA
${indent}             \%fields
${indent}             \$AUTOLOAD
${indent}             \$PACKAGE
${indent}             \$VERSION
${indent}             \$AUTHOR
${indent}             \$DATE
${indent}             );
${indent}\$PACKAGE = '$project->{'name'}';
${indent}\$VERSION = '$project->{'version'}';
${indent}\$AUTHOR  = '$project->{'author'}';
${indent}\$DATE    = '$project->{'date'}';
$use_string
${indent}# ".S_("Tell interpreter who we are inheriting from")."
${indent}\@ISA     = qw( Glade::PerlRun Gtk::GladeXML);
} # ".S_("End of sub")." BEGIN

${indent}\$Glade::PerlRun::pixmaps_directory ||= '$Glade_Perl->{glade}{pixmaps_directory}';

\%fields = (
# ".S_("Insert any extra data access methods that you want to add to")."
#   ".S_("our inherited super-constructor (or overload)")."
${indent}USERDATA    => undef,
${indent}VERSION     => '0.01',
);

sub DESTROY {
${indent}# This sub will be called on object destruction
} # ".S_("End of sub")." DESTROY

#==============================================================================
#=== ".S_("Below are the class constructors")."
#==============================================================================
sub new {
${indent}my \$that  = shift;
${indent}# ".S_("Allow indirect constructor so that we can call eg.")."
${indent}#   \$window1 = BusFrame->new; \$window2 = \$window1->new;
${indent}my \$class = ref(\$that) || \$that;

${indent}my \$glade_file = '$proto->{glade}{file}';
${indent}unless (-f \$glade_file) {
${indent}${indent}die \"Unable to find Glade file '\$glade_file'\";
${indent}}
${indent}# ".S_("Call Gtk::GladeXML to get an object and reconsecrate it")."
${indent}my \$self = bless new Gtk::GladeXML(\$glade_file, '$name'), \$class;

${indent}# ".S_("Add our own data access methods to the inherited constructor")."
${indent}my(\$element);
${indent}foreach \$element (keys \%fields) {
${indent}${indent}\$self->{\$permitted_fields}->{\$element} = \$fields{\$element};
${indent}}
${indent}\@{\$self}{keys \%fields} = values \%fields;
${indent}return \$self;
} # ".S_("End of sub")." new

sub app_run {
${indent}my (\$class) = \@_;
$init_string
${indent}my \$window = \$class->new;
${indent}\$window->signal_autoconnect_from_package('$name');

${indent}Gtk->main;
${indent}return \$window;
} # ".S_("End of sub")." run
#===============================================================================
#=== ".S_("Below are the default signal handlers for")." '$name' class 
#===============================================================================
$about_string

sub destroy_Form {
${indent}my (\$class, \$data, \$object, \$instance) = \@_;
${indent}Gtk->main_quit; 
} # ".S_("End of sub")." destroy_Form

sub toplevel_hide    { shift->get_toplevel->hide    }
sub toplevel_close   { shift->get_toplevel->close   }
sub toplevel_destroy { shift->get_toplevel->destroy }";
}

1;

__END__
