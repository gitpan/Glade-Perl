package Glade::PerlUI;
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
    use UNIVERSAL         qw( can );          # in lots of subs
    use Gtk               qw(  );             # Everywhere
# Comment out the line below if you have a really old version of Gtk-Perl
    use Gtk::Keysyms;
    use Glade::PerlSource qw( :VARS );
    use Glade::PerlUIGtk  qw( :VARS );;
    use Glade::PerlUIExtra;
    use vars              qw( 
        @ISA 
        @EXPORT @EXPORT_OK %EXPORT_TAGS 
        $PACKAGE
        $VERSION
        @VARS @METHODS

        $gnome_libs_depends
        $perl_gtk_depends
        $concept_widgets
        $ignore_widgets
        $ignored_widgets
        $missing_widgets
        );
    $PACKAGE =          __PACKAGE__;
    $VERSION        = q(0.44);

    $ignored_widgets = 0;
    $missing_widgets = 0;
    @METHODS =          qw(  );
    @VARS =             qw(
        $gnome_libs_depends
        $perl_gtk_depends
        $concept_widgets
        $ignore_widgets
        $ignored_widgets
        $missing_widgets
        );
    # Tell interpreter who we are inheriting from
    @ISA            =   qw( Glade::PerlUIGtk Glade::PerlUIExtra );
    # These symbols (globals and functions) are always exported
    @EXPORT         =   qw(  );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS );
    # Tags (groups of symbols) to export		
    %EXPORT_TAGS  = (
                        'METHODS' => [@METHODS] , 
                        'VARS'    => [@VARS]    
                    );
}

#===============================================================================
#=========== Constants and globals                                          ====
#===============================================================================
my $gnome_widgets       = join( " ",
    'GnomeAbout',
    'GnomeApp',
    'GnomeAppBar',
    'GnomeCalculator',
    'GnomeColorPicker',
    'GnomeDateEdit',
    'GnomeDialog',
    'GnomeDock',
    'GnomeDockItem',
    'GnomeDruid',
    'GnomeDruidPageFinish',
    'GnomeDruidPageStandard',
    'GnomeDruidPageStart',
    'GnomeEntry',
    'GnomeFileEntry',
    'GnomeFontPicker',
    'GnomeHRef',
    'GnomeIconEntry',
    'GnomeIconList',
    'GnomeIconSelection',
    'GnomeLess',
    'GnomeMessageBox',
    'GnomeNumberEntry',
    'GnomePaperSelector',
    'GnomePixmap',
    'GnomePixmapEntry',
    'GnomePropertyBox',
    'GnomeSpell',
    'GtkCalendar',          # In Gtk after CVS-19990914
    'GtkClock',
    'GtkDial',
    'GtkPixmapMenuItem',
    );
$gnome_libs_depends     = { 
    'MINIMUM REQUIREMENTS' => '1.0.08',
    'gtk_clock_new'         => '1.0.16',
    'GnomeDruid'            => '1.0.50',
    'GnomeDruidPageFinish'  => '1.0.50',
    'GnomeDruidPageStandard'=> '1.0.50',
    'GnomeDruidPageStart'   => '1.0.50',
    };
$perl_gtk_depends       = { 
    'MINIMUM REQUIREMENTS' => '0.6123',
    # Those below don't work yet even in the latest CVS version
    'GnomeDruidPageStandard::vbox'
                        => '19991107',
    # Those below work in the CVS version after 19991025
    'GnomeDruid'        => '19991025',
    # Those below work in the CVS version after 19991001
    'gnome_iconlist_new_undef'  => '19991001',
    'gnome_stock_pixmap_widget' => '19991001',
    'gnome_stock_button' => '19991001',
    'gtk_colorselectiondialog_ok_button->child' => '19991001',
     # Those below work in the CVS version after 19990922
    'gnome_app_enable_layout_config'   => '19990922',
    'gtk_layout_undef'  => '19990922',
    'gtk_pixmap_set_build_insensitive' => '19990922',
     # Those below work in the CVS version after 19990920
    'GnomeApp'          => '19990920',
    'GnomeIconList'     => '19990920',
    'GnomeIconSelection'=> '19990920',
    'GnomeMessageBox'   => '19990920',
    'GnomePropertyBox'  => '19990920',
     # Those below work in the CVS version after 19990914
    'gdk_pixmap_colormap_create_from_xpm'       => '19990914',
    'GnomeAppBar'       => '19990914',
    'GnomeDock'         => '19990914',
    'GnomeDockItem'     => '19990914',
    'GnomeSpell'        => '19990914',
    'GnomeStock'        => '19990914',
    'GtkCalendar'       => '19990914',
    };
$ignore_widgets         = join (' ', 
    'Placeholder',
    'Custom',
    );
my $dialogs             = join(' ',
    'Gnome::About',
    'Gnome::App',
    'Gnome::Dialog',
    'Gnome::MessageBox',
    'Gnome::PropertyBox',
    'Gtk::ColorSelectionDialog',
    'Gtk::Dialog',
    'Gtk::FileSelection',
    'Gtk::FontSelectionDialog',
    'Gtk::InputDialog',
    );
my $composite_widgets   = join(' ',
    'Gnome::Entry',
    'Gnome::FileEntry',
    'Gnome::NumberEntry',
    'Gnome::PixmapEntry',
    'Gtk::Combo',
    );
my $toplevel_widgets    = join(' ',
    'Gnome::About',
    'Gnome::App',
    'Gnome::Dialog',
    'Gnome::MessageBox',
    'Gnome::PropertyBox',
    'Gtk::Dialog',
    'Gtk::InputDialog',
    'Gtk::Window',
    );
#===============================================================================
#=========== Version utilities                                      ============
#===============================================================================
sub my_perl_gtk_can_do {
    my ($class, $action) = @ARG;
    unless ($perl_gtk_depends->{$action}) { return 1;}
    if ($perl_gtk_depends->{$action} <= 
        $main::Glade_Perl_Generate_options->my_perl_gtk) {
        return 1;
    } else {
        if ($perl_gtk_depends->{$action} >= 19990914) {
            # We need a CVS version
            if ($perl_gtk_depends->{$action} > 29990000) {
                # The CVS version can't even do it yet
                $class->diag_print(1, "warn  Gtk-Perl version ".
                    $main::Glade_Perl_Generate_options->my_perl_gtk.
                    " cannot do '$action' (properly) and neither can".
                    " the CVS version !!!");
            } else {
                # We need a new CVS version
                $class->diag_print(1, "warn  Gtk-Perl version ".
                    $main::Glade_Perl_Generate_options->my_perl_gtk.
                    " cannot do '$action' (properly) we need".
                    " CVS module 'gnome-perl' after $perl_gtk_depends->{$action}");
            }
        } else {
            # We need a new CPAN version
            $class->diag_print(1, "warn  Gtk-Perl version ".
                $main::Glade_Perl_Generate_options->my_perl_gtk.
                " cannot do '$action' (properly) we need".
                " CPAN version $perl_gtk_depends->{$action}");
        }
        return undef;
    }
}

sub my_gnome_libs_can_do {
    my ($class, $action) = @ARG;
    unless ($gnome_libs_depends->{$action}) { return 1;}
    if ($gnome_libs_depends->{$action} le 
        $main::Glade_Perl_Generate_options->my_gnome_libs) {
        return 1;
    } else {
        if ($gnome_libs_depends->{$action} ge 19990914) {
            # We need a CVS version
            if ($gnome_libs_depends->{$action} gt 29990000) {
                # The CVS version can't even do it yet
                $class->diag_print(1, "warn  gnome_libs version ".
                    $main::Glade_Perl_Generate_options->my_gnome_libs.
                    " cannot do '$action' (properly) and neither can".
                    " the CVS version !!!");
            } else {
                # We need a new CVS version
                $class->diag_print(1, "warn  gnome_libs version ".
                    $main::Glade_Perl_Generate_options->my_gnome_libs.
                    " cannot do '$action' (properly) we need".
                    " CVS module 'gnome-libs' after $gnome_libs_depends->{$action}");
            }
        } else {
            # We need a new CPAN version
            $class->diag_print(1, "warn  gnome_libs version ".
                $main::Glade_Perl_Generate_options->my_gnome_libs.
                " cannot do '$action' (properly) we need".
                " version $gnome_libs_depends->{$action}");
        }
        return undef;
    }
}

#===============================================================================
#=========== Utilities to construct UI                              ============
#===============================================================================
sub use_par {
    my ($class, $proto, $key, $request, $default, $dont_undef) = @ARG;
    my $me = "$class->use_par";
    my $options = $main::Glade_Perl_Generate_options;
    my $type;
    my $self = $proto->{$key};
    unless (defined $self) {
        if (defined $default) {
            $self = $default;
#            $class->diag_print (8, "$indent- No value in proto->{'$key'} ".
#                "so using DEFAULT of '$default' in $me");
        } else {
            # We have no value and no default to use so bale out here
            $class->diag_print (1, "error No value in supplied ".
                "$proto->{'name'}\->{'$key'} and NO default was supplied in ".
                "$me called from ".(caller)[0]." line ".(caller)[2]);
            return undef;
        }
    } else {
        # We have a value to use
#        $class->diag_print (8, "$indent- Value supplied in ".
#            "proto->{'$key'} was '$self'");
    }
    # We must have some sort of value to use by now
    unless ($request) {
        # Nothing to do, we are already $proto->{$key} so
        # just drop through to undef the supplied prot->{$key}
#        $class->diag_print(8, "I have used par->{'$key'} => '$self' in $me");
        
    } elsif ($request eq $DEFAULT) {
        # Nothing to do, we are already $proto->{$key} (or default) so
        # just drop through to undef the supplied prot->{$key}
#        $class->diag_print(8, "I have converted '$key' from ".($proto->{$key} || 'undef').
#            " to default ('$self') in $me");
        
    } elsif ($request == $LOOKUP) {
        return '' unless $self;
        
        # make an effort to convert from Gtk to Gtk-Perl constant/enum name
        my $lookup;
        if ($self =~ /^GNOME/) {
            # Check cached enums first
            $lookup = $Glade::PerlUIExtra::gnome_enums->{$self};
            
            if ($lookup) {
                unless ($dont_undef) {undef $proto->{$key};}
                return $lookup;

            } else {
                $lookup = $self;
                foreach $type ( 
                    'GNOME_MESSAGE_BOX',  
                    'GNOME_FONT_PICKER_MODE',
                    'GNOME_PREFERENCES',  
                    'GNOME_DOCK',               
#                    'GNOMEUIINFO_MENU',
        #            'GNOME_STOCK_ICON',         'GNOME_STOCK_MENU',
        #            'GNOME_STOCK_PIXMAP_TYPE',  'GNOME_STOCK_PIXMAP',
        #            'GNOME_STOCK_BUTTON',       'GNOME_STOCK',
                    ) {
                    # Remove leading GTK type
                    $lookup =~ s/^${type}_// && last    # finish early
                }
            }
            unless ($lookup eq $self) {
                $self = lc($lookup);
#                $class->diag_print(2, "$indent- I have converted '$key' from '".
#                    ($proto->{$key} || $default)."' to '$self' (GNOME LOOKUP) in $me");
            } else {
                # We still don't have a value so grep the gnome .h files
                my ($grep, $inc_dir, $gnome_incs, $command);
                while ($self =~ /^GNOME/) {
                    $grep = '';
                    $inc_dir = `gnome-config --includedir`;
                    chomp $inc_dir;
                    $gnome_incs = "$inc_dir/libgnomeui";
                    $command = "\$grep = `grep -h \" $self \" $gnome_incs/*.h`";
                    eval $command;
#print "grep returned '$grep'\n";
                    $grep =~ s/.*$self\s+//g;
                    $grep =~ s/^[\"\s]*//g;
                    $grep =~ s/[\"\s]*$//g;
                    $self = $grep if $grep;
#print "grep grepped to '$grep'\n";
                }
                $Glade::PerlUIExtra::gnome_enums->{$lookup} = $grep;
#                $class->diag_print(2, $Glade::PerlUIExtra::gnome_enums);
                # Cache this enum for later use
#                $class->diag_print(8, "$indent- I have converted '$key' from '".
#                    "$lookup' to '$self' (GNOME GREP) in $me");
            }
            
        } else {
            # Check cached enums first
            $lookup = $Glade::PerlUIExtra::gnome_enums->{$self};
            unless ($lookup) {
                $self =~ s/^G[DT]K_//;    # strip off leading GDK_ or GTK_
                foreach $type ( 
                    'WINDOW',       'WIN_POS',      'JUSTIFY',      
                    'POLICY',       'SELECTION',    'ORIENTATION',
                    'TOOLBAR_SPACE','EXTENSION_EVENTS',
                    'TOOLBAR',      'TOOLBAR_CHILD','TREE_VIEW', 
                    'BUTTONBOX',    'UPDATE',       'PACK',
                    'POS',          'ARROW',        'BUTTONBOX', 
                    'CURVE_TYPE',   'PROGRESS',     'VISUAL',       
                    'IMAGE',        'CALENDAR',     'SHADOW',
                    'CLOCK',        'RELIEF',       'SIDE',
                    'ANCHOR', 
                    ) {
                    # Remove leading GTK type
                    $self =~ s/^${type}_// && last    # finish early
                }
                $self = lc($self);        # convert to lower case
                return '' unless $self;
                if ($self) {$Glade::PerlUIGtk::gtk_enums->{($proto->{$key} || $default)} = $self;}
            }
        }
#        $class->diag_print(8, "$indent- I have converted '$key' from '".
#            ($proto->{$key} || $default)."' to '$self' (LOOKUP) in $me");

    } elsif ($request == $BOOL) {
        # Now convert whatever we have ended up with to a BOOL
        # undef becomes 0 (== false)
        $type = $self;
        $self = ('*true*y*yes*on*1*' =~ m/\*$self\*/i) ? '1' : '0';
#        $class->diag_print(8, "$indent- I have converted proto->{'$key'} ".
#            "from '$type' to $self (BOOL) in $me");

    } elsif ($request == $KEYSYM) {
        $self =~ s/GDK_//;
# If you have an old version of Gtk-Perl that doesn't have Gtk::Keysyms
# use the next line instead of the Gtk::Keysyms{$self} line below it
#        $self = ord ($self );
        $self = $Gtk::Keysyms{$self};
#        $class->diag_print(8, "$indent- I have converted '$key' from ".
#            ($proto->{$key})." to '$self' (Gtk::Keysyms)in $me");
    } 
    # undef the parameter so that we can report any unused attributes later
    unless ($dont_undef) {undef $proto->{$key};}
    return $self;
}

sub Widget_from_Proto {
    my ($class, $parentname, $proto, $depth, $app) = @ARG;
    my $me = "$class->Widget_from_Proto";
    my $typekey = $class->typeKey;
    my ($name, $childname, $constructor, $window, $sig );
    my ($key, $dm, $self, $expr, $object, $refself, $packing );
    unless ($parentname) {$parentname = 'No Parent'}
    if ($depth) {
        # We are a widget of some sort (toplevel window or child)
        unless ($proto->{'name'}) {
            $class->diag_print (2, "You have supplied a proto without a name to $me");
            $class->diag_print (2, $proto);
        } else {
            $name = $proto->{'name'};
        }
        if ($depth == 1) {
            $forms->{$name} = {};
            # We are a toplevel window so create a new hash and 
            # set $current_form with its name
            # All these back-slashes are really necessary as this string
            # is passed through so many others
            $current_form_name = "$name-\\\\\\\$instance";
            $current_form = "\$forms->{'$name'}";
            $current_data = "\$data->{'$name'}\{'_DATA'}";
            $current_window = "\$forms->{'$name'}\{'$name'}";
            unless ($first_form) {$first_form = $name};
        }
        $class->add_to_UI( $depth,  "#" );
        $class->add_to_UI( $depth,  "# Construct a $proto->{'class'} '$name'" );
        $constructor = "new_$proto->{'class'}";
        if ($class->can($constructor)) {
            # Construct the widget
            $expr =  "\$widgets->{'$proto->{'name'}'} = ".
                "$class->$constructor('$parentname', \$proto, $depth, '$app' );";
            eval $expr or 
                ($EVAL_ERROR && die  "\nin $me\n\twhile trying to eval ".
                    "'$expr'\n\tFAILED with Eval error '$EVAL_ERROR'\n" );
        } else {
            die "error $me\n\tI don't have a constructor called ".
                "'$class->$constructor' - I guess that it isn't written yet :-)\n";
        }
    } else {
        # We are a complete GTK-Interface - ie we are the application
        unless ($main::Glade_Perl_Generate_options->allow_gnome) {
            $ignore_widgets .= " $gnome_widgets";
        }
    }
    $self = $widgets->{$proto->{'name'}};
    $refself = ref $self;
    foreach $key (sort keys %{$proto}) {
        # Iterate through keys looking for sub widgets
        if (ref $proto->{$key}) {
            # this is a ref to a sub hash so expand it
            $object = $proto->{$key}{$typekey};
            if ( $object eq 'widget') {
                if ($class->my_perl_gtk_can_do($proto->{$key}{'class'})) {
                    unless (" $ignore_widgets " =~ / $proto->{$key}{'class'} /) {
                        # This is a real widget subhash so recurse to expand
                        $childname = $class->Widget_from_Proto( $proto->{'name'}, 
                            $proto->{$key}, $depth + 1, $app );
                        $class->set_child_packing(
                            $proto->{'name'}, $childname, $proto->{$key}, $depth+1 );
                        if ($class->diagnostics) {
                            $class->unused_elements($proto->{$key} );
                        }

                    } else {
#                        if (" $concept_widgets " =~ / $proto->{$key}{'class'} /) {
#                            $class->diag_print(4, "warn  ".
#                                "$proto->{$key}{'class'} widget ignored - was that correct?");
#                        } else {
                            $class->diag_print(4, "warn  ".
                                "$proto->{$key}{'class'} widget ignored in $me");
#                        }
                        $ignored_widgets++;
                    }
                }
                
            } elsif ($object eq 'signal') {
                # we are a SIGNAL
                $class->new_signal($proto->{'name'}, 
                    $proto->{$key}, $depth, $app );

            } elsif ($object eq 'accelerator') {
                # we are an ACCELERATOR
                $class->new_accelerator($proto->{'name'}, 
                    $proto->{$key}, $depth, $app );

            } elsif ($object eq 'style') {
                # Perhaps should be in set_widget_properties
                if ($current_form) {
                    $class->new_style($proto->{'name'}, 
                        $proto->{$key}, $depth, $app );
                }
                    
            } elsif ($object eq 'project') {
                # We rely on this appearing before the rest of the proto
                # so that we know which files to write (if needed)
                # It was dealt with in new_from_Glade so just ignore it
                
            } elsif ($object eq 'child') {
                # Already dealt with above so just ignore it
                
            } else {
                # I don't recognise it so do nothing but report it
                $class->diag_print (2, "Object '$object' not recognised ".
                    "or processed for ".
                    "$proto->{'class'} '$proto->{'name'}' by $me");
            }
        }
    }
#================== Check this and TIDY it up
    if ($depth == 1) {
        # We are a toplevel window so now connect all signals
        if (eval "scalar(\@{${current_form}\{'Signal_Strings'}})") {
            # We have some signals to connect
            $class->add_to_UI( $depth,  "#" );
            $class->add_to_UI( $depth,  "# Connect all signals now that widgets are constructed" );
            $expr = "foreach \$sig (\@{${current_form}\{'Signal_Strings'}}) {
                eval \$sig;
            }";
            eval $expr;
        }
    }
    unless ($depth)             {
        # We are the Application level (above all toplevel windows)
        return $childname;
    } elsif ($proto->{'name'})     {
        # We are the bottom widget in the branch of the proto tree
        return $proto->{'name'};
    } elsif ($childname)         {
        # We are somewhere in the middle of the tree
        return $childname;
    } else                         {
        # What has happened?
        die 'error $me - failed to return anything';
    }
}

#===============================================================================
#=========== Utilities to build UI                                    ============
#===============================================================================
sub internal_pack_widget {
    my ($class, $parentname, $childname, $proto, $depth) = @ARG;
    my $me = "$class->internal_pack_widget";
    my $refpar;
    # When we add/pack/append we do it to ${current_form}->{$parentname} 
    # rather than $widgets->{$parentname} so that we are sure that everything 
    # is packed in the right order and we can check for duplicate names
    my $refwid = (ref $widgets->{$childname} );
    my $child_type;
    my $postpone_show;
    if ($current_form && eval "exists ${current_form}\{'$childname'}") {
        die "\nerror $me - There is already a widget called ".
            "'$childname' constructed and packed - I will not overwrite it !";
    }
    if (" $dialogs $toplevel_widgets " =~ m/ $refwid /) {
        # We are a window so don't have a parent to pack into
        $class->diag_print (4, "$indent- Constructing a component ".
            "(window/dialog) '$childname'");
        $child_type = $widgets->{$childname}->type;
        if (' toplevel dialog '=~ m/ $child_type /) {
            # Add a default delete_event signal connection
            $class->add_to_UI($depth,   
                "${current_form}\{'tooltips'} = new Gtk::Tooltips;" );
            $class->add_to_UI($depth,   
                "${current_form}\{'accelgroup'} = new Gtk::AccelGroup;" );
            $class->add_to_UI( $depth, 
                "${current_form}\{'accelgroup'}->attach(\$widgets->{'$childname'} );" );
        } else {
            die "\nerror F$me   $indent- This is a $child_type type Window".
                " - what should I do?";
        }
        $postpone_show = 1;

    } else {
        # We have a parent to pack into somehow
        eval "\$refpar = (ref ${current_form}\{'$parentname'})||'UNDEFINED !!';";
        unless (eval "exists ${current_form}\{'$parentname'}") {
            if ('Gtk::Menu' eq $refwid) {
                # We are a popup menu so we don't have a root window
#            $class->add_to_UI( $depth, "${first_form}->popup_enable;" );
                $postpone_show = 1;
            } else {
                die "\nerror $me - Unable to find a widget called '$parentname' - ".
                    "I can not pack widget '$childname' into a non-existant widget!";
            }
        }
        if ($postpone_show) {
            # Do nothing
            
#---------------------------------------
        } elsif (" $composite_widgets " =~ m/ $refpar /) {
            # We do not need to do anything for this widget
            
#---------------------------------------
        } elsif (eval "${current_form}\{'$parentname'}->can(".
            "'query_child_packing')") {# and !defined $proto->{'child_name'}) {
            # We have a '$refpar' widget '$parentname' that can query_child_packing
            my $ignore = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->add(".
                    "\$widgets->{'$childname'} );");

#---------------------------------------
        } elsif (' Gtk::CList ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if ($child_type eq 'CList:title') {
                # We are a CList column widget (title widget)
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_column_widget(".
                        "$CList_column, \$widgets->{'$childname'} );" );
                $CList_column++;
            } else {
                $class->diag_print (1, "error I don't know what to do with ".
                    "$refpar element $child_type");
            }

#---------------------------------------
        } elsif (' Gtk::CTree ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if ($child_type eq 'CTree:title') {
                # We are a CTree column widget (title widget)
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_column_widget(".
                        "$CTree_column, \$widgets->{'$childname'} );" );
                $CTree_column++;
            } else {
                $class->diag_print (1, "error I don't know what to do with ".
                    "$refpar element $child_type");
            }

#---------------------------------------
        } elsif (' Gtk::Layout ' =~ m/ $refpar /) {
#            $class->diag_print(2, $proto);
            my $x      = $class->use_par($proto, 'x');
            my $y      = $class->use_par($proto, 'y');
#            my $width  = $class->use_par($proto, 'width');
#            my $height = $class->use_par($proto, 'height');
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->put(".
                    "\$widgets->{'$childname'}, '$x', '$y');" );

#---------------------------------------
        } elsif (' Gtk::MenuBar Gtk::Menu ' =~ m/ $refpar /) {
            # We are a menuitem
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->append(".
                    "\$widgets->{'$childname'} );" );

#---------------------------------------
        } elsif (' Gtk::MenuItem ' =~ m/ $refpar /) {
            # We are a menu for a meuitem
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->set_submenu(".
                    "\$widgets->{'$childname'} );" );
            $postpone_show = 1;

#---------------------------------------
        } elsif (' Gtk::OptionMenu ' =~ m/ $refpar /) {
            # We are a menu for an optionmenu
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->set_menu(".
                    "\$widgets->{'$childname'} );" );
            $postpone_show = 1;

#---------------------------------------
        } elsif (' Gtk::Notebook ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if ($child_type eq 'Notebook:tab') {
                # We are a notebook tab widget (eg label) so we can add the 
                # previous notebook page with ourself as the  label
#                unless (eval "ref ${current_form}\{'$Notebook_panes[$Notebook_tab]'}") {
                unless ($Notebook_panes[$Notebook_tab]) {
                    $class->diag_print (1, "warn  There is no widget on the ".
                        "notebook page linked to notebook tab '$childname' - ".
                        "a Placeholder label was used instead");
                    $class->add_to_UI( $depth, 
                        "${current_form}\{'Placeholder_label'} = ".
                            "new Gtk::Label('This is a message generated by $PACKAGE\n\n".
                                "No widget was specified for the page linked to\n".
                                "notebook tab \"$childname\"\n\n".
                                "You should probably use Glade to create one');");
                    $class->add_to_UI( $depth, 
                        "${current_form}\{'Placeholder_label'}->show;");
                    $Notebook_panes[$Notebook_tab] = 'Placeholder_label';
                }
#                $class->diag_print(2, $proto);
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->append_page(".
                        "${current_form}\{'$Notebook_panes[$Notebook_tab]'}, ".
                        "\$widgets->{'$childname'} );" );
                $Notebook_tab++;

            } else {
                # We are a notebook page so just store for adding later 
                # when we get the tab widget
                push @Notebook_panes, $childname;
                $Notebook_pane++;
            }

#---------------------------------------
        } elsif (' Gtk::Packer ' =~ m/ $refpar /) {
#            $class->diag_print(2, $proto);
#            $class->diag_print(2, $proto->{'child'});
            my $anchor  = $class->use_par($proto->{'child'}, 'anchor', $LOOKUP, 'center', 'DONT_UNDEF');
            my $side    = $class->use_par($proto->{'child'}, 'side',   $LOOKUP, 'top', 'DONT_UNDEF');
            my $expand  = $class->use_par($proto->{'child'}, 'expand', $BOOL,   'False', 'DONT_UNDEF');
            my $xfill   = $class->use_par($proto->{'child'}, 'xfill',  $BOOL,   'False', 'DONT_UNDEF');
            my $yfill   = $class->use_par($proto->{'child'}, 'yfill',  $BOOL,   'False', 'DONT_UNDEF');
            my $use_default = $class->use_par($proto->{'child'}, 'use_default',  $BOOL,'True', 'DONT_UNDEF');
            my $options = "";
            $expand && ($options .= "'pack_expand', ");
            $xfill  && ($options .= "'fill_x', ");
            $yfill  && ($options .= "'fill_y', ");
            $options =~ s/, $//;
            if ($options) {$options = "[$options]";} else {$options = "[]";}
            if ($use_default) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add_defaults(".
                        "\$widgets->{'$childname'}, ".
                        "'$side', '$anchor', $options);" );
            } else {
                my $border_width = $class->use_par($proto->{'child'}, 'border_width', $DEFAULT, 0, 'DONT_UNDEF');
                my $xipad   = $class->use_par($proto->{'child'}, 'xipad',  $DEFAULT, 0, 'DONT_UNDEF');
                my $xpad    = $class->use_par($proto->{'child'}, 'xpad',   $DEFAULT, 0, 'DONT_UNDEF');
                my $yipad   = $class->use_par($proto->{'child'}, 'yipad',  $DEFAULT, 0, 'DONT_UNDEF');
                my $ypad    = $class->use_par($proto->{'child'}, 'ypad',   $DEFAULT, 0, 'DONT_UNDEF');
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add(".
                        "\$widgets->{'$childname'}, ".
                        "'$side', '$anchor', $options, '$border_width', ".
                        "'$xpad', '$ypad', '$xipad', '$yipad');" );
            }
                      
#---------------------------------------
        } elsif (' Gtk::ScrolledWindow ' =~ m/ $refpar /) {
            if (' Gtk::CList Gtk::CTree ' =~ m/ $refwid /) {
                # These handle their own scrolling and column labels are fixed
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add(".
                        "\$widgets->{'$childname'} );" );
            } else {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add_with_viewport(".
                        "\$widgets->{'$childname'} );" );
            }
            
#---------------------------------------
        } elsif (' Gtk::Table ' =~ m/ $refpar /) {
            # We are adding to a table so do the child packing
            my $left_attach =   $class->use_par($proto->{'child'}, 'left_attach'   );
            my $right_attach =  $class->use_par($proto->{'child'}, 'right_attach'  );
            my $top_attach =    $class->use_par($proto->{'child'}, 'top_attach'    );
            my $bottom_attach = $class->use_par($proto->{'child'}, 'bottom_attach' );

            my (@xoptions, @yoptions);
            my ($xoptions, $yoptions);
            push @xoptions, 'expand' if $class->use_par($proto->{'child'}, 'xexpand', $BOOL, 'True' );
            push @xoptions, 'fill'   if $class->use_par($proto->{'child'}, 'xfill',   $BOOL, 'True' );
            push @xoptions, 'shrink' if $class->use_par($proto->{'child'}, 'xshrink', $BOOL, 'False');
            push @yoptions, 'expand' if $class->use_par($proto->{'child'}, 'yexpand', $BOOL, 'True' );
            push @yoptions, 'fill'   if $class->use_par($proto->{'child'}, 'yfill',   $BOOL, 'True' );
            push @yoptions, 'shrink' if $class->use_par($proto->{'child'}, 'yshrink', $BOOL, 'False');
            if (scalar @xoptions) {$xoptions = "['".join("', '", @xoptions)."']"} else {$xoptions = '[]'};
            if (scalar @yoptions) {$yoptions = "['".join("', '", @yoptions)."']"} else {$yoptions = '[]'};

            my $xpad =    $class->use_par($proto->{'child'}, 'xpad',    $DEFAULT, 0 );
            my $ypad =    $class->use_par($proto->{'child'}, 'ypad',    $DEFAULT, 0 );

            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->attach(".
                    "\$widgets->{'$childname'}, ".
                    "'$left_attach', '$right_attach', '$top_attach', '$bottom_attach', ".
                    "$xoptions, $yoptions, '$xpad', '$ypad' );" );
            
#---------------------------------------
        } elsif (' Gtk::Toolbar ' =~ m/ $refpar /) {
# FIXME - toolbar buttons with a removed label don't have a child_name
#   but can have a sub-widget. allow for this
#   test all possibilities
            # Untested possibilities
            # 4 Other type of widget
            my $tooltip =  $class->use_par($proto, 'tooltip',  $DEFAULT, '' );
            if (eval "$current_form\{'$parentname'}{'tooltips'}" && 
                !$tooltip &&
                (' Gtk::VSeparator Gtk::HSeparator Gtk::Combo Gtk::Label ' !~ / $refwid /)) {
                $class->diag_print (1, "warn  Toolbar '$parentname' is expecting ".
                    "a tooltip but you have not set one for $refwid '$childname'");
            }            
            # We must have a widget already constructed
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->append_widget(".
                    "\$widgets->{'$childname'}, '$tooltip', '' );" );
            
#---------------------------------------
        } elsif (" Gnome::App "=~ m/ $refpar /) {
            my $type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if (' Gnome::AppBar ' =~ m/ $refwid /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_statusbar(".
                        "\$widgets->{'$childname'} );" );
            
            } elsif (' GnomeApp:appbar ' =~ m/ $type /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_statusbar(".
                        "\$widgets->{'$childname'} );" );
            
            } elsif (' Gnome::Dock ' =~ m/ $refwid /) {
# FIXME why have I commented this out?
#                $class->add_to_UI( $depth, 
#                    "${current_form}\{'$parentname'}->set_contents(".
#                        "\$widgets->{'$childname'} );" );

            } elsif (' Gtk::MenuBar ' =~ m/ $refwid /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_menus(".
                        "\$widgets->{'$childname'} );" );

            } else {
                $class->diag_print (1, "error Don't know how to pack $refwid ".
                    "${current_form}\{'${childname}'}{'child_name'} ".
                    "(type '$type') - what should I do?");
            }
                        
#---------------------------------------
        } elsif (" Gnome::Dock "=~ m/ $refpar /) {
            # We are a Gnome::DockItem
            my $placement= $class->use_par($proto, 'placement', $LOOKUP, 'top' );
            my $band     = $class->use_par($proto, 'band',      $DEFAULT, 0 );
            my $position = $class->use_par($proto, 'position',  $DEFAULT, 0 );
            my $offset   = $class->use_par($proto, 'offset',    $DEFAULT, 0 );
            my $in_new_band = $class->use_par($proto, 'in_new_band', $DEFAULT, 0 );

            # 'Usage: Gnome::Dock::add_item(dock, item, placement, band_num, position, offset, in_new_band)
# FIXME Above is how it should be done, adding to App's contents for now
            if (" Gnome::DockItem " =~/ $refwid /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add_item(".
                        "\$widgets->{'$childname'}, '$placement', '$band', ".
                        "'$position', '$offset', '$in_new_band' );" );
            } else {
                $class->add_to_UI( $depth, 
                    "${current_window}->set_contents(".
                        "\$widgets->{'$childname'} );" );
            }
            
#---------------------------------------
        } elsif (" Gnome::Druid "=~ m/ $refpar /) {
            # We are a Gnome::DruidPage of some sort
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->append_page(".
                    "\$widgets->{'$childname'} );" );
            if (' Gnome::DruidPageStart ' =~ / $refwid /) {
                $class->add_to_UI( $depth, "${current_form}\{'$parentname'}->".
                    "set_page(\$widgets->{'$childname'});" );
            }
            
#---------------------------------------
        } elsif (" $dialogs "=~ m/ $refpar /) {
            # We use a dialog->method to get a ref to our widget
#            my $ignore = $class->use_par($proto, 'label', $DEFAULT,  '' );
            my $type =  $class->use_par($proto, 'child_name' );
            $type =~ s/.*:(.*)/$1/;
            $class->add_to_UI( -$depth, "\$widgets->{'$childname'} = ".
                "${current_form}\{'$parentname'}->$type;" );

#---------------------------------------
        } else {
            # We are not a special case
            $class->add_to_UI( $depth, "${current_form}\{'$parentname'}->add(".
                "\$widgets->{'$childname'} );" );
        }
    }
    unless ($postpone_show || !$class->use_par($proto, 'visible', $BOOL, 'True') ) {
#        $class->add_to_UI($depth, "\$widgets->{'$childname'}->realize( );" );
        $class->add_to_UI($depth, "\$widgets->{'$childname'}->show( );" );
    }
    $class->add_to_UI( $depth, 
        "${current_form}\{'$childname'} = \$widgets->{'$childname'};" );

    # Delete the $widget to show that it has been packed
    delete $widgets->{$childname};

    return;
}

sub set_child_packing {
    my ($class, $parentname, $childname, $proto, $depth) = @ARG;
    my $me = "$class->set_child_packing";
    if ($proto->{'child'} && eval "${current_form}\{'$parentname'}->can("."
        'set_child_packing')") {
        my ($refpar, $refwid);
        eval "\$refpar = ref ${current_form}\{'$parentname'}";
        eval "\$refwid = ref ${current_form}\{'$childname'}";
        unless (' Gtk::Packer ' =~ / $refpar /) {
            my $expand =   $class->use_par( $proto->{'child'}, 
                'expand', $BOOL, 'False' );
            my $fill =     $class->use_par( $proto->{'child'}, 
                'fill', $BOOL, 'True' );
            my $padding =  $class->use_par( $proto->{'child'}, 
                'padding', $BOOL, 'False' );
            my $pack =        $class->use_par( $proto->{'child'}, 
                'pack', $LOOKUP, 'start' );
            $class->add_to_UI( $depth,  
                "${current_form}\{'$parentname'}->set_child_packing(".
                    "${current_form}\{'$childname'}, ".
                    "'$expand', '$fill', '$padding', '$pack' );" );
        }
    }
}

sub set_tooltip {
    my ($class, $parentname, $proto, $depth) = @ARG;
    my $me = "$class->set_tooltip";
    my $tooltip = $class->use_par($proto, 'tooltip', $DEFAULT, '');
    
# FIXME What do we do if tooltip is '' - set or not ?
    if ($tooltip ne '') {
        $class->add_to_UI( $depth, "${current_form}\{'tooltips'}->set_tip(".
            "${current_form}\{'$parentname'}, \"$tooltip\" );" );

    } elsif (!defined $proto->{'name'}) {
        my $message = "Could not set tooltip for unnamed $proto->{'class'}";
        $class->diag_print (1, "error $message");

    } else {
        $class->diag_print(6, "warn  No tooltip specified for widget '$proto->{'name'}'");
    }    
}

sub set_container_properties {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    my $me = "$class->set_container_properties";
    if ($proto->{'border_width'}) {
        if (eval "$current_form\{'$name'}->can('border_width')") {
            my $border_width  = $class->use_par($proto, 'border_width', $DEFAULT, 0);
            $class->add_to_UI( $depth, "$current_form\{'$name'}->border_width(".
                "'$border_width' );" );
        }
    }
}

sub set_range_properties {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    my $me = "$class->set_range_properties";
# FIXME - call this from range type widgets
# For use by HScale, VScale, HScrollbar, VScrollbar
#    my $name = $proto->{'name'};
    my $hvalue     = $class->use_par($proto, 'hvalue',     $DEFAULT, 0 );
    my $hlower     = $class->use_par($proto, 'hlower',     $DEFAULT, 0 );
    my $hupper     = $class->use_par($proto, 'hupper',     $DEFAULT, 0 );
    my $hstep      = $class->use_par($proto, 'hstep',      $DEFAULT, 0 );
    my $hpage      = $class->use_par($proto, 'hpage',      $DEFAULT, 0 );
    my $hpage_size = $class->use_par($proto, 'hpage_size', $DEFAULT, 0 );
    my $policy     = $class->use_par($proto, 'policy',     $LOOKUP );

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );
}

sub set_misc_properties {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    my $me = "$class->set_alignment";
    # For use by Arrow, Image, Label, (TipsQuery), Pixmap
#    $class->diag_print(8, "Setting misc properties for '$name'");
    # Cater for all the usual properties (defaults not stored in XML file)
    return unless ($proto->{'xalign'} || $proto->{'yalign'} || $proto->{'xpad'} || $proto->{'ypad'});
    my $xalign = $class->use_par($proto, 'xalign', $DEFAULT, 0 );
    my $yalign = $class->use_par($proto, 'yalign', $DEFAULT, 0 );
    my $xpad   = $class->use_par($proto, 'xpad',   $DEFAULT, 0 );
    my $ypad   = $class->use_par($proto, 'ypad',   $DEFAULT, 0 );

    if ($xalign || $yalign) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_alignment(".
            "'$xalign', '$yalign' );" );
    }
    if ($xpad || $ypad) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_padding(".
            "'$xpad', '$ypad' );" );
    }
}

sub set_widget_properties {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    my $me = "$class->set_widget_properties";
    # For use by all widgets
    # Cater for all the usual properties (defaults not stored in XML file)
    my $can_default = $class->use_par($proto, 'can_default',$BOOL,      'False' );
    my $has_default = $class->use_par($proto, 'has_default',$BOOL,      'False' );
    my $can_focus   = $class->use_par($proto, 'can_focus',  $BOOL,      'False' );
    my $has_focus   = $class->use_par($proto, 'has_focus',  $BOOL,      'False' );
# FIXME Use these ???
#    my $events      = $class->use_par($proto, 'events',     $DEFAULT,   0       );
#    my $extension_events_string    = $class->use_par(
#                        $proto, 'extension_events_string',  $LOOKUP,    'none'  );
    
    if ( (defined $proto->{'x'}) || (defined $proto->{'y'}) ) {
        my $x = $class->use_par($proto, 'x',  $DEFAULT, 0 );
        my $y = $class->use_par($proto, 'y',  $DEFAULT, 0 );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_uposition(".
            "'$x', '$y' );" );
    }
    if ( (defined $proto->{'width'}) || (defined $proto->{'height'}) ) {
        my $width  = $class->use_par($proto, 'width',  $DEFAULT, 0 );
        my $height = $class->use_par($proto, 'height', $DEFAULT, 0 );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_usize(".
            "'$width', '$height' );" );
    }
    if ( $proto->{'sensitive'} ) {
        my $sensitive = $class->use_par($proto, 'sensitive', $BOOL, 'True'  );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_sensitive('$sensitive');");
    }

    if ( $can_default ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->can_default(".
            "'$can_default' );" );
    }
    if ( $can_focus ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->can_focus(".
            "'$can_focus' );" );
    }
    if ($has_default) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->has_default(".
            "'$has_default' );" );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->grab_default;");
    }
    if ( $has_focus ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->has_focus(".
            "'$has_focus' );" );
    }
}

sub set_window_properties {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    my $me = "$class->set_window_properties";
# For use by Window, (ColorSelectionDialog, Dialog (InputDialog), FileSelection)
    my $title        = $class->use_par($proto,'title',        $DEFAULT, '' );
    my $position     = $class->use_par($proto,'position',     $LOOKUP,  'mouse' );
    my $allow_grow   = $class->use_par($proto,'allow_grow',   $BOOL,    'True' );
    my $allow_shrink = $class->use_par($proto,'allow_shrink', $BOOL,    'True' );
    my $auto_shrink  = $class->use_par($proto,'auto_shrink',  $BOOL,    'False' );
    my $modal        = $class->use_par($proto,'modal',        $BOOL,    'False' );
    my $wmclass_name  = $class->use_par($proto, 'wmclass_name',  $DEFAULT, '' );
    my $wmclass_class = $class->use_par($proto, 'wmclass_class', $DEFAULT, '' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->position('$position' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->allow_grow('$allow_grow' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->allow_shrink('$allow_shrink' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->auto_shrink('$auto_shrink' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_modal('$modal' );" );
    if ($wmclass_name && $wmclass_class) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_wmclass(".
            "'$wmclass_name', '$wmclass_class' );" );
    }
    $class->add_to_UI( $depth,  "\$widgets->{'$name'}->realize;" );

	$widgets->{$name}->signal_connect("destroy" => \&Gtk::main_quit);
	$widgets->{$name}->signal_connect("delete_event" => \&Gtk::main_exit);
# FIXME we don't want to shut the app when someone closes a dialog with the wm
# What is the right thing to do for every window - perhaps nothing and let the
# user do it themselves.
#    $class->add_to_UI( $depth, "\$widgets->{'$name'}->signal_connect(".
#        "'destroy', \\\&Gtk::main_quit );" );
#    $class->add_to_UI( $depth, "\$widgets->{'$name'}->signal_connect(".
#        "'delete_event', \\\&Gtk::exit );" );

    $class->pack_widget($parent, $name, $proto, $depth );
}

sub pack_widget {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    my $me = "$class->pack_widget";

    $class->internal_pack_widget($parent, $name, $proto, $depth );
    $class->set_widget_properties($parent, $name, $proto, $depth);
    $class->set_container_properties($parent, $name, $proto, $depth);
    $class->set_tooltip($name, $proto, $depth );
}

sub new_accelerator {
    my ($class, $parentname, $proto, $depth) = @ARG;
    my $me = "$class->new_accelerator";
#$class->diag_print(2, $proto);
    my $mods = '[]';
    my $accel_flags = "['visible', 'locked']";
#    my $key      = ucfirst($class->use_par($proto, 'key', $LOOKUP ));
    my $key       = $class->use_par($proto, 'key',          $KEYSYM );
    my $modifiers = $class->use_par($proto, 'modifiers',    $DEFAULT, 0);
    my $signal    = $class->use_par($proto, 'signal');
    unless (defined $need_handlers->{$parentname}{$signal}) {
        $need_handlers->{$parentname}{$signal} = undef;
    }

# FIXME move this to use_par
#--------------------------------------
    # Turn GDK values into array of $LOOKUPs
    unless ($modifiers eq 0) {
        $modifiers =~ s/ *//g;
        $modifiers =~ s/GDK_//g;
        $mods = "['".lc(join ("', '", split(/\|/, $modifiers)))."']";
    }
#--------------------------------------

#  gtk_widget_add_accelerator (accellabel3, "button_press_event", accel_group,
#                              GDK_L, GDK_MOD1_MASK,
#                              GTK_ACCEL_VISIBLE);
#    $class->add_to_UI( $depth, "${current_form}\{'$parentname'}->add_accelerator(".
#        "'$signal', ${current_form}\{'accelgroup'}, '$key', $mods, $accel_flags);");

    if (eval "${current_form}\{'$parentname'}->can('$signal')") {
        $class->add_to_UI( $depth, "${current_form}\{'accelgroup'}->add(".
            "'$key', $mods, $accel_flags, ".
            "${current_form}\{'$parentname'}, '$signal');");
    } else {
        $class->diag_print (1, "error Widget '$parentname' can't emit signal ".
            "'$signal' as requested - what's wrong?");
    }
}

sub new_style {
    my ($class, $parentname, $proto, $depth) = @ARG;
    my $me = "$class->new_style";
#    $class->diag_print(2, $proto);
    my ($state, $color, $value, $element, $lc_state);
    my ($red, $green, $blue);
    $class->add_to_UI( $depth, "$current_form\{'$parentname-style'} = ".
        "new Gtk::Style;");
#    $class->add_to_UI( $depth, "$current_form\{'$parentname-style'} = ".
#       "$current_form\{'$parentname'}->style;");
    my $style_font = $class->use_par($proto, 'style_font', $DEFAULT, '');
    if ($style_font) {
        $class->add_to_UI( $depth, "$current_form\{'$parentname-style'}".
            "->font(Gtk::Gdk::Font->load('$style_font'));");
    }
    foreach $state ("NORMAL", "ACTIVE", "PRELIGHT", "SELECTED", "INSENSITIVE") {
        $lc_state = lc($state);
        foreach $color ('fg', 'bg', 'text', 'base') {
            $element = "$color-$state";
            if ($proto->{$element}) {
                $value = $class->use_par($proto, $element, $DEFAULT, '');
                $class->diag_print(6, "$indent- We have a style element ".
                    "'$element' which is '$value'");
                ($red, $green, $blue) = split(',', $value);
                # Yes I really mean multiply by 257 (0x101)
                # We scale these so that 0x00 -> 0x0000
                #                        0x0c -> 0x0c0c
                #                        0xff -> 0xffff
                # This spreads the values 0x00 - 0xff throughout the possible 
                # Gdk values of 0x0000 - 0xffff rather than 0x00 - 0xff00
                $red   *= 257;
                $green *= 257;
                $blue  *= 257;
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'} ".
                    "= $current_form\{'$parentname-style'}->$color('$lc_state');");
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->red($red);");
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->green($green);");                
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->blue($blue);");                
                $class->add_to_UI( $depth, "$current_form\{'$parentname-style'}".
                    "->$color('$lc_state', $current_form\{'$parentname-$color-$lc_state'});");
            }
        }
        $element = "bg_pixmap-${state}";
        if ($proto->{$element}) {
        	$class->add_to_UI( $depth, "($current_form\{'$parentname-bg_pixmap-$lc_state'}, ".
                "$current_form\{'$parentname-bg_mask-$lc_state'}) = ".
                    "Gtk::Gdk::Pixmap->create_from_xpm($current_window->get_toplevel->window, ".
                        "$current_form\{'$parentname-style'}, '$proto->{$element}' );");
            $class->add_to_UI( $depth, "$current_form\{'$parentname-style'}".
                "->bg_pixmap('$lc_state', $current_form\{'$parentname-bg_pixmap-$lc_state'});");
        }
    }
    if (eval "$current_form\{'$parentname'}->can('child')") {
        $class->add_to_UI( $depth, "$current_form\{'$parentname'}->child->set_style(".
            "$current_form\{'$parentname-style'});");
    }
    $class->add_to_UI( $depth, "$current_form\{'$parentname'}->set_style(".
            "$current_form\{'$parentname-style'});");
}

sub new_signal {
    my ($class, $parentname, $proto, $depth) = @ARG;
    my $me = "$class->new_signal";
    my $signal  = $proto->{'name'};
    my ($call, $expr);
# FIXME to do signals properly
    if ($proto->{'handler'}) {
        my $ignore = $class->use_par($proto, 'last_modification_time');
        my $handler = $class->use_par($proto, 'handler');
        my $object  = $class->use_par($proto, 'object', $DEFAULT, '');
        my $data    = $class->use_par($proto, 'data', $DEFAULT, '');
        my $after   = $class->use_par($proto, 'after', $BOOL, 'False');
        unless ($object) {$object = $parentname}
        if ($after)  {
            $call .= 'signal_connect_after'
        } else {
            $call .= 'signal_connect'
        }
        # We can check dynamically below
        # Flag that we are done
        delete $need_handlers->{$parentname}{$signal};
        # We must log the sub name for dynamic stub handlers
        unless ( ($Glade::PerlSource::subs =~ m/ $handler /) or    
            (defined $handlers->{$handler}) or 
            ($class->Building_UI_only) ) {
            $subs .= "$handler\n$indent".(' ' x 19 );
            eval "$current_form\{_HANDLERS}{$handler} = 'signal'";
        }
        if ($class->can($handler)) {
            # All is hunky-dory - no need to generate a stub
            # First connect the signal handler as best we can
            unless ($class->Writing_Source_only) {
            $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                "\"\\${current_form}\{'$object'}->$call( ".
                "'$signal', '$handler', '$data', '$object', ".
                "'name of form instance' )\"";
#                print $expr."\n";
                eval $expr
            }
            # Now write a signal_connect for generated code
            # All these back-slashes are really necessary as these strings
            # are passed through so many others (evals and so on)
            $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                "\"$class->add_to_UI( 1, ".
                "\\\"\\\\\\${current_form}\{'$object'}->$call( ".
                "'$signal', '$handler', '$data', '$object', ".
                "\\\\\\\"$current_form_name\\\\\\\" );\\\", 'TO_FILE_ONLY' );\"";
#                print $expr."\n";
                eval $expr
            
        } else {
            # First we'll connect a default handler to hijack the signal 
            # for us to use during the Build run
            $class->diag_print (2, "warn  Missing signal handler '$handler' ".
                "connected to widget '$object' needs to be written");
            unless ($class->Writing_Source_only) {
            $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                "\"\\${current_form}\{'$object'}->$call(".
                "'$signal', \\\"missing_handler\\\", ".
                "'$parentname', '$signal', '$handler', '".
                $project->logo."' )\"";
#                print $expr."\n";
                eval $expr
            }
            # Now write a signal_connect for generated code
            # All these back-slashes are really necessary as these strings
            # are passed through so many others (evals and so on)
            $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                "\"$class->add_to_UI( 1, ".
                "\\\"\\\\\\${current_form}\{'$object'}->$call( ".
                "'$signal', '$handler', '$data', '$object', ".
                "\\\\\\\"$current_form_name\\\\\\\" );\\\", 'TO_FILE_ONLY' );\"";
#            print $expr."\n";
            eval $expr
        }

    } else {
        # This is a signal that we will cause
        $class->diag_print(4, $proto);
    }
}

sub new_from_child_name {
    my ($class, $parent, $name, $proto, $depth) = @ARG;
    return undef unless $proto->{'child_name'};

    my $type = $class->use_par($proto, 'child_name' );
    if ($type eq 'GnomeEntry:entry') {
        $type = 'gtk_entry';
#        $type =~ s/.*:(.*)/gtk_$1/;

    } elsif ($type eq 'GnomePixmapEntry:file-entry') {
        $type = 'gnome_file_entry';

    } elsif (' Toolbar:button GnomeDock:contents GnomeDruidPageStandard:vbox ' =~ m/ $type /) {
        # Keep the full child_name for later use

    } else {
        # Just use the bit after the colon
        $type =~ s/.*:(.*)/$1/;

    }
#---------------------------------------
    if ($type eq 'action_area') {
        # Gtk|Gnome::Dialog have widget tree that is not reflected by
        # the methods that access them. $dialog->action_area() points to
        # a child of $dialog->vbox() and not of $dialog. In any case, they
        # cannot be used/accessed until something is added to them.
        return undef;
#        $class->add_to_UI( $depth, 
#            "\$widgets->{'$name'} = ".
#                "${current_window}->$type;" );

#---------------------------------------
    } elsif ($type eq 'Toolbar:button') {
        my $pixmap_widget_name = 'undef';
        my $label   = $class->use_par($proto, 'label',         $DEFAULT, '');
        my $icon    = $class->use_par($proto, 'icon',          $DEFAULT, '' );
#        my $stock_button = $class->use_par($proto, 'stock_button',  $LOOKUP, '' );
        my $tooltip = $class->use_par($proto, 'tooltip',       $DEFAULT, '' );
        if (eval "$current_form\{'$parent'}{'tooltips'}" && !$tooltip) {
            $class->diag_print (1, "warn  Toolbar '$parent' is expecting ".
                "a tooltip but you have not set one for $proto->{'class'} '$name'");
        }            
        if ($icon) {
            $pixmap_widget_name = "${current_form}\{'${name}-pixmap'}";
            $icon = $class->full_Path( 
                $icon, $project->pixmaps_directory );
            $class->add_to_UI( $depth, 
                "$pixmap_widget_name = \$class->create_pixmap(".
                    "${current_window}, '$icon' );" ); 

            # We have label and so on to add
            $type =~ s/.*:(.*)/$1/;
            $class->add_to_UI( $depth, 
                "\$widgets->{'$name'} = ".
                    "${current_form}\{'$parent'}->append_element(".
                        "'$type', \$widgets->{'$name'}, '$label', ".
                        "'$tooltip', '', $pixmap_widget_name );" );

        } elsif ($proto->{'stock_pixmap'}) {
            my $stock_pixmap = $class->use_par($proto, 'stock_pixmap',  $LOOKUP, '' );
            $pixmap_widget_name = "${current_form}\{'${name}-pixmap'}";
            if ($class->my_perl_gtk_can_do('gnome_stock_pixmap_widget')) {
                $class->add_to_UI( $depth, 
                    "$pixmap_widget_name = Gnome::Stock->pixmap_widget(".
                        "$current_window, '$stock_pixmap');" ); 
            } else {
                $class->add_to_UI( $depth, 
                    "$pixmap_widget_name = Gnome::Stock->new_with_icon(".
                        "'$stock_pixmap');" ); 
            }
            $type =~ s/.*:(.*)/$1/;
            $class->add_to_UI( $depth, 
                "\$widgets->{'$name'} = ".
                    "${current_form}\{'$parent'}->append_element(".
                        "'$type', \$widgets->{'$name'}, '$label', ".
                        "'$tooltip', '', $pixmap_widget_name );" );

        }

#---------------------------------------
    } elsif (' GnomeDock:contents ' =~ / $type /) {
        return undef;
        # FIXME This doesn't make sense to me, get_client_area wants a DockItem
#            $class->add_to_UI( $depth, 
#                "\$widgets->{'$name'} = ".
#                    "${current_form}\{'$parent'}->get_client_area;" );
#            $class->add_to_UI( $depth, 
#                "\$widgets->{'$name'} = ".
#                    "${current_form}\{'$parent'}->get_client_area;" );

#---------------------------------------
    } elsif (' GnomeDruidPageStandard:vbox ' =~ / $type /) {
        if ($class->my_perl_gtk_can_do('GnomeDruidPageStandard::vbox')) {
            $class->add_to_UI( $depth, 
                "\$widgets->{'$name'} = ".
                    "${current_form}\{'$parent'}->vbox;" );
        } else {
            return undef;
        }

#---------------------------------------
    } elsif (eval "${current_form}\{'$parent'}->can('$type')") {
        my $label   = $class->use_par($proto, 'label', $DEFAULT, '');
        $class->add_to_UI( $depth, 
            "\$widgets->{'$name'} = ".
                "${current_form}\{'$parent'}->$type;" );

        if ($label) {
            if ($widgets->{$name}->can('child')) {
                my $childref = ref $widgets->{$name}->child;
                if ($childref eq 'Gtk::Label') {
                    $class->add_to_UI( $depth, 
                        "\$widgets->{'$name'}->child->set_text('$label');", 
                        'TO_FILE_ONLY' );
                } else {
                    $class->diag_print (1, "error We have a label ".
                        "('$label') to set but the child of ${current_form}\{'${name}'} ".
                        "isn't a label (actually it's a $childref)");
                }
            } else {
                $class->diag_print (1, "error We have a label ('$label') to ".
                    "set but ${current_form}\{'${name}'} doesn't have a ".
                    "->child() accessor");
            }
        }

#---------------------------------------
    } else {
        $class->diag_print (1, "error Don't know how to get a ref to  ".
            "${current_form}\{'${name}'}{'child_name'} (type '$type')");
        return undef;
    }

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->show( );" );
    $class->add_to_UI( $depth, 
        "${current_form}\{'$name'} = \$widgets->{'$name'};" );
    # Delete the $widget to show that it has been packed
    delete $widgets->{$name};

    # Deal with all the other widget properties that might be set
    $class->set_widget_properties($parent, $name, $proto, $depth);
    $class->set_container_properties($parent, $name, $proto, $depth);
    $class->set_tooltip($name, $proto, $depth );

    # we have constructed the widget so caller doesn't need to
    return 1;
}

1;

__END__
