package Glade::PerlUIExtra;
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
    use Glade::PerlSource qw( :VARS :METHODS );
    use vars              qw( 
                            $PACKAGE
                            $VERSION
                            $enums
                          );
    $PACKAGE =          __PACKAGE__;
    $VERSION            = q(0.52);
    # These cannot be looked up in the include files
    $enums =      {
        'GNOME_ANIMATOR_LOOP_NONE'      => 'none',
        'GNOME_ANIMATOR_LOOP_RESTART'   => 'restart',
        'GNOME_ANIMATOR_LOOP_PING_PONG' => 'ping_pong',
    };
}

#===============================================================================
#=========== Gnome utilities                                        ============
#===============================================================================
sub lookup {
    my ($class, $self) = @_;
    my $me = __PACKAGE__."->lookup";
#print "$indent- Trying to convert '$self' in $me\n";
    # Check cached enums first
    my $lookup = $enums->{$self};

    unless ($lookup) {
        my $work = $self;
        foreach my $type ( 
            'GNOME_MESSAGE_BOX',  
            'GNOME_FONT_PICKER_MODE',
            'GNOME_PREFERENCES',  
            'GNOME_DOCK',               
#            'GNOMEUIINFO_MENU',
            ) {
            # Remove leading GTK type
            if ($work =~ s/^${type}_//) {
                $lookup = lc($work);
                last;   # finish early
            }
        }
    }
    
    unless ($lookup) {
        # We still don't have a value so grep the gnome .h files
        my ($grep, $inc_dir, $gnome_incs, $command, $hfiles);
        $inc_dir = `gnome-config --includedir`;
        chomp $inc_dir;
        $gnome_incs = "$inc_dir/libgnomeui";
        $lookup = $self;
        
        # Grep recursively in case one const points to another
        while ($lookup =~ /^GNOME/) {
            $grep = '';
            if ($lookup =~ /^GNOME_KEY_/) {
                $hfiles = "gnome-uidefs.h";

            } elsif ($lookup =~ /^GNOME_MENU_/) {
                $hfiles = 'gnome-app-helper.h';

            } elsif ($lookup =~ /^GNOME_STOCK_/) {
                $hfiles = 'gnome-stock.h';

            } else {
                $hfiles = "*.h";
            }

            $command = "\$grep = `grep -h \"define.*\\\\b$lookup\\\\b\" $gnome_incs/$hfiles`";
#print "$command\n";
            eval $command;
#print "Looking for '$self' grep returned '$grep'\n";
            if ($grep) {
#                $class->diag_print(2, "warn  Unable to find '$lookup' ".
#                    "in Gnome header file(s) $gnome_incs/$hfiles");
#                return undef;
#            }
                $grep =~ s/.*$lookup\s+//g;   # Remove upto and including our enum name
                $grep =~ s/^D_*//g;         # Strip leading D_ gettext call
                $grep =~ s/^[\'\"\s\(]*//g; # Strip leading spaces brackets or quotes
                $grep =~ s/[\'\"\s\)]*$//g; # Strip trailing spaces brackets or quotes
#print "grep grepped to '$grep'\n";
            }
            $lookup = $grep;
        }
    }
    # Cache this enum for later use
    $enums->{$self} = $lookup;
#    $class->diag_print(2, $Glade::PerlUIExtra::gnome_enums);
#print "$indent- I have converted from '$self' to '$lookup' in $me\n" unless $lookup;
    return $lookup;
}

#===============================================================================
#=========== Gnome widget constructors                              ============
#===============================================================================
sub frig_Gnome_Dialog_buttons {
    my ($class, $parent, $proto, $depth) = @_;
    my $typekey = $class->typeKey;
    my ($stock_button, $sensitive, $visible);
    my ($can_default, $has_default, $can_focus, $has_focus);
    my ($key, $work, $subkey, $subwork);
    my $current_button = 0;
    use Data::Dumper; 
#print Dumper(\@_);
    foreach $key (keys %{$proto}) {
        $work = $proto->{$key};
        next unless ref $work;
        if ($work->{$typekey} eq 'widget') {
            $stock_button = $class->use_par($work, 'stock_button', $LOOKUP);
# FIXME Glade saves all these but surely it's pointless 
# We can't get at the button to set them in any case
#            $visible = $class->use_par($work, 'visible', $BOOL, 1);
#            $can_focus   = $class->use_par($work, 'can_focus', $BOOL, 1);
#            $has_focus   = $class->use_par($work, 'has_focus', $BOOL, 0);
            $can_default = $class->use_par($work, 'can_default', $BOOL, 1);
            $has_default = $class->use_par($work, 'has_default', $BOOL, 0);
            $sensitive = $class->use_par($work, 'sensitive', $BOOL, 1);
            $class->add_to_UI( $depth, 
                "$current_window\->append_button('$stock_button');");
            (defined $sensitive) && !$sensitive &&
                $class->add_to_UI( $depth, 
                    "$current_window\->set_sensitive(".
                        "'$current_button', $sensitive);");
            $has_default && $can_default &&
                $class->add_to_UI( $depth, 
                    "$current_window\->set_default('$current_button');");

            foreach $subkey (keys %$work) {
#               print Dumper($work->{$subkey});
                next unless ref $work->{$subkey};
                $subwork = $work->{$subkey};
                if ($subwork->{$typekey} eq 'accelerator') {
                    $class->new_accelerator($parent, $subwork,
                        $depth, $current_button);
                    
                } elsif ($subwork->{$typekey} eq 'signal') {
                    $class->diag_print(1, "warn  You have specified a signal".
                        "'%s' (handler '%s') for Gnome::Dialog button '%s' ".
                        "but Gtk-Perl cannot add it and it has been ignored",
                        $subwork->{'name'}, $subwork->{'handler'},
                        $work->{'name'}); 
                }
            }

            delete $proto->{$key};
            $current_button++;
        }
    }
}

sub new_GnomeAbout {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeAbout";
    my $name = $proto->{name};
    my $title     = $class->use_par($proto, 'title',     $DEFAULT, $Glade_Perl->{'options'}{'name'} );
    my $version   = $class->use_par($proto, 'version',   $DEFAULT, $Glade_Perl->{'options'}{'version'} );
    my $logo      = $class->use_par($proto, 'logo',      $DEFAULT, $Glade_Perl->{'options'}{'logo'} );
    my $copyright = $class->use_par($proto, 'copyright', $DEFAULT, S_("Copyright")." $Glade_Perl->{'options'}{'date'}" );
    my $authors   = $class->use_par($proto, 'authors',   $DEFAULT, $Glade_Perl->{'options'}{'author'} );
    my $comments  = $class->use_par($proto, 'comments',  $DEFAULT, $Glade_Perl->{'options'}{'copying'} );
#    $logo = $class->full_Path(
#            $logo, 
#            $Glade_Perl->{'pixmaps_directory'}, 
#            '' );
    $logo = "\"\$Glade::PerlRun::pixmaps_directory/$logo\"";

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::About(".
        "_('$title'), '$version', _('$copyright'), '$authors', _('$comments'), $logo);" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(".
        "_('About').' $title' );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeAnimator {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeAnimator";
    my $name = $proto->{name};
    my $playback_direction = 
        $class->use_par($proto, 'playback_direction', $BOOL, 0 ) ? '-1' : '1';
    my $playback_speed = $class->use_par($proto, 'playback_speed', $DEFAULT, 1 );
    my $loop_type = $class->use_par($proto, 'loop_type',  $LOOKUP, 'none' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
        "new_with_size Gnome::Animator(190, 141);" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_playback_speed(".
        "$playback_speed );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_playback_direction(".
        "$playback_direction );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_loop_type(".
        "'$loop_type' );" );
    
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeApp {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeApp";
    my $name = $proto->{name};
    my $appname   = $class->use_par($proto, 'title',  $DEFAULT,  $Glade_Perl->{'options'}{'name'}  );
    my $title     = $class->use_par($proto, 'title',  $DEFAULT,  $Glade_Perl->{'options'}{'name'}  );
    my $enable_layout_config = $class->use_par($proto, 'enable_layout_config',  $BOOL, 'True'  );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::App(".
        "'$appname', _('$title'));" );
    if ($class->my_perl_gtk_can_do('gnome_app_enable_layout_config')) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->enable_layout_config(".
            "$enable_layout_config );" );
    }
    
    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeAppBar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeAppBar";
    my $name = $proto->{name};
    my $has_progress  = $class->use_par($proto, 'has_progress',  $BOOL, 'True'  );
    my $has_status    = $class->use_par($proto, 'has_status',    $BOOL, 'True'  );
    my $interactivity = $class->use_par($proto, 'interactivity', $LOOKUP, 'user'  );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::AppBar(".
        "$has_progress, $has_status, '$interactivity');" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeCalculator {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeCalculator";
    my $name = $proto->{name};

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
        "${current_form}\{$parent}->new_child('Gnome::Calculator');" );

# FIXME move this to internal_pack_widget or somewhere more central 
#   perhaps gnome_pack_widget
    $class->add_to_UI($depth, "\$widgets->{'$name'}->show;" );
    $class->add_to_UI( $depth, 
        "${current_form}\{$name} = \$widgets->{'$name'};" );
    # Delete the $widget to show that it has been packed
    delete $widgets->{$name};
#    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeCanvas {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeCanvas";
    my $name = $proto->{name};
    my $pixels_per_unit = $class->use_par($proto, 'pixels_per_unit', $DEFAULT, 1 );
    my $scroll_x1 = $class->use_par($proto, 'scroll_x1',$DEFAULT, 0 );
    my $scroll_y1 = $class->use_par($proto, 'scroll_y1',$DEFAULT, 0 );
    my $scroll_x2 = $class->use_par($proto, 'scroll_x2',$DEFAULT, 100 );
    my $scroll_y2 = $class->use_par($proto, 'scroll_y2',$DEFAULT, 100 );
    my $anti_aliased = $class->use_par($proto, 'anti_aliased', $BOOL, 'False' );

    if ($anti_aliased) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new_aa Gnome::Canvas;" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new Gnome::Canvas;" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_scroll_region(".
        "$scroll_x1, $scroll_y1, $scroll_x2, $scroll_y2 );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_pixels_per_unit(".
        "$pixels_per_unit );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeColorPicker {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeColorPicker";
    my $name = $proto->{name};
    my $dither    = $class->use_par($proto, 'dither',   $BOOL, 'True' );
    my $use_alpha = $class->use_par($proto, 'use_alpha',$BOOL, 'False' );
    my $title     = $class->use_par($proto, 'title', $DEFAULT, '' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
        "new Gnome::ColorPicker;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_dither(".
        "$dither );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_use_alpha(".
        "$use_alpha );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(".
        "_('$title') );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDateEdit {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDateEdit";
    my $name = $proto->{name};
    my $show_time     = $class->use_par($proto, 'show_time', $BOOL, 'True' );
    my $use_24_format = $class->use_par($proto, 'use_24_format', $BOOL, 'True' );
    my $week_start_monday = $class->use_par($proto, 'week_start_monday', $BOOL, 'False' );
    my $lower_hour    = $class->use_par($proto, 'lower_hour', $DEFAULT, 7 );
    my $upper_hour    = $class->use_par($proto, 'upper_hour', $DEFAULT, 19 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::DateEdit(".
        "0, $show_time, $use_24_format);" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_popup_range(".
        "$lower_hour, $upper_hour );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDialog";
    my $name = $proto->{name};
    my $title         = $class->use_par($proto, 'title', $DEFAULT, '' );
    my $auto_close    = $class->use_par($proto, 'auto_close',    $BOOL, 'True' );
    my $hide_on_close = $class->use_par($proto, 'hide_on_close', $BOOL, 'True' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::Dialog(".
        "_('$title'));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->close_hides(".
        "$hide_on_close );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_close(".
        "$auto_close );" );

#use Data::Dumper; print Dumper($widgets->{$name}->buttons);
    $class->set_window_properties($parent, $name, $proto, $depth );

    return $widgets->{$name};
}

sub new_GnomeDock {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDock";
    my $name = $proto->{name};
    my $allow_floating = $class->use_par($proto, 'allow_floating', $BOOL, 'True' );
    my $child_name = $class->use_par($proto, 'child_name', $DEFAULT, 'True' );

    if ($child_name) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "$current_form\{'$parent'}->get_dock;" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::Dock;" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->allow_floating_items(".
        "$allow_floating );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDockItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDockItem";
    my $name = $proto->{name};
    my $shadow_type      = $class->use_par($proto, 'shadow_type',      $LOOKUP, 'out'  );

    my @options;
    push @options, 'exclusive'       if 
        $class->use_par($proto, 'exclusive',        $BOOL, 'True' );
    push @options, 'never_horizontal'     if 
        $class->use_par($proto, 'never_horizontal', $BOOL, 'False' );
    push @options, 'never_vertical'    if 
        $class->use_par($proto, 'never_vertical',   $BOOL, 'True' );
    push @options, 'locked'  if 
        $class->use_par($proto, 'locked', $BOOL, 'True' );
    push @options, 'never_float'  if 
        $class->use_par($proto, 'never_floating', $BOOL, 'False' );
    # 'exclusive', 'never_horizontal', 'never_vertical', 'normal', 'locked', or 'never_float' 
# FIXME where do I get 'normal' ?
#    push @options, 'normal'  if 
#        $class->use_par($proto, 'normal', $BOOL, 'False' );
    my $behavior;
    if (scalar @options) {
        $behavior = "['".join("', '", @options)."']",
    } else {
        $behavior = '[]'
    }
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::DockItem(".
        "'$name', $behavior );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_shadow_type(".
        "'$shadow_type' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDruid {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDruid";
    my $name = $proto->{name};

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::Druid;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDruidPageStart {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDruidPageStart";
    my ($type, $value, $command, $color_string, $red, $blue, $green);
    my $name = $proto->{name};
    my $title = $class->use_par($proto, 'title', $DEFAULT, '' );
    my $text  = $class->use_par($proto, 'text',  $DEFAULT, '' );
    my $logo_image = $class->use_par($proto, 'logo_image',  $DEFAULT, '' );
    my $watermark_image = $class->use_par($proto, 'watermark_image',  $DEFAULT, '' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::DruidPageStart;" );
    foreach $type ('background', 'textbox', 'logo_background', 'title', 'text') {
        $value = $class->use_par($proto, "$type\_color",  $DEFAULT, '' );
        if ($value) {
           ($red, $green, $blue) = split(',', $value);
            $red   *= 257; $green *= 257; $blue  *= 257;
            $color_string = "${current_form}\{$parent}->get_toplevel->".
                "get_colormap->color_alloc({red => $red, green => $green, blue => $blue})";
            $command = $type;
            $command =~ s/background/bg/;
            $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_$command\_color(".
                "$color_string);");
        }
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(_('$title') );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_text(_('$text') );" );
    $logo_image && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_logo(".
            "\$class->create_image('$logo_image'));" );
    $watermark_image && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_watermark(".
            "\$class->create_image('$watermark_image'));" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDruidPageStandard {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDruidPageStandard";
    my ($type, $value, $command, $color_string, $red, $blue, $green);
    my $name = $proto->{name};
    my $title = $class->use_par($proto, 'title', $DEFAULT, '' );
    my $logo_image = $class->use_par($proto, 'logo_image',  $DEFAULT, '' );
    my $watermark_image = $class->use_par($proto, 'watermark_image',  $DEFAULT, '' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::DruidPageStandard;" );
    foreach $type ('background', 'textbox', 'logo_background', 'title', 'text') {
        $value = $class->use_par($proto, "$type\_color",  $DEFAULT, '' );
        if ($value) {
           ($red, $green, $blue) = split(',', $value);
            $red   *= 257; $green *= 257; $blue  *= 257;
            $command = $type;
            $command =~ s/background/bg/;
            $color_string = "${current_form}\{$parent}->get_toplevel->".
                "get_colormap->color_alloc({red => $red, green => $green, blue => $blue})";
            $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_$command\_color(".
                "$color_string);");
        }
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(_('$title') );" );
    $logo_image && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_logo(".
            "\$class->create_image('$logo_image' ));" );
    $watermark_image && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_watermark(".
            "\$class->create_image('$watermark_image' ));" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeDruidPageFinish {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeDruidPageFinish";
    my ($type, $value, $command, $color_string, $red, $blue, $green);
    my $name = $proto->{name};
    my $title = $class->use_par($proto, 'title', $DEFAULT, '' );
    my $text  = $class->use_par($proto, 'text',  $DEFAULT, '' );
    my $logo_image = $class->use_par($proto, 'logo_image',  $DEFAULT, '' );
    my $watermark_image = $class->use_par($proto, 'watermark_image',  $DEFAULT, '' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::DruidPageFinish;" );
    foreach $type ('background', 'textbox', 'logo_background', 'title', 'text') {
        $value = $class->use_par($proto, "$type\_color",  $DEFAULT, '' );
        if ($value) {
           ($red, $green, $blue) = split(',', $value);
            $red   *= 257; $green *= 257; $blue  *= 257;
            $color_string = "${current_form}\{$parent}->get_toplevel->".
                "get_colormap->color_alloc({red => $red, green => $green, blue => $blue})";
            $command = $type;
            $command =~ s/background/bg/;
            $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_$command\_color(".
                "$color_string);");
        }
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(_('$title') );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_text(_('$text') );" );
    $logo_image && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_logo(".
            "\$class->create_image('$logo_image' ));" );
    $watermark_image && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_watermark(".
            "\$class->create_image('$watermark_image' ));" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeEntry";
    my $name = $proto->{name};
    my $max_saved = $class->use_par($proto, 'max_saved', $DEFAULT, 10 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::Entry(".
        "$max_saved);" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeFileEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeFileEntry";
    my $name = $proto->{name};
    my $history_id = $class->use_par($proto, 'history_id',  $DEFAULT, '' );
    my $title      = $class->use_par($proto, 'title',       $DEFAULT, '' );
    my $max_saved  = $class->use_par($proto, 'max_saved',   $DEFAULT, 10 );
    my $directory  = $class->use_par($proto, 'directory',   $BOOL, 'False' );
    my $modal      = $class->use_par($proto, 'modal',       $BOOL, 'False' );

    if ($proto->{'child_name'}) {
        my $type =  $class->use_par($proto, 'child_name' ,$DEFAULT, '');
        if ($type eq 'GnomePixmapEntry:file-entry') {
            $type = 'gnome_file_entry';
        } else {
            $type =~ s/.*:(.*)/$1/;
        }
        $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
            "$current_form\{'$parent'}->$type;" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::FileEntry(".
            "'$history_id', _('$title'));" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->gnome_entry->set_max_saved(".
        "$max_saved );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_directory(".
        "$directory );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_modal(".
        "$modal);" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeFontPicker {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeFontPicker";
    my $name = $proto->{name};
    my $the_time  = localtime;
    my $title     = $class->use_par($proto, 'title', $DEFAULT, '' );
    my $preview_text = $class->use_par($proto, 'preview_text',   $DEFAULT, 'The quick brown fox jumped over the lazy dog' );
    my $mode = $class->use_par($proto, 'mode', $LOOKUP, 'pixmap' );
    my $show_size = $class->use_par($proto, 'show_size',    $BOOL, 'True' );
    my $use_font  = $class->use_par($proto, 'use_font',     $BOOL, 'False' );
    my $use_font_size  = $class->use_par($proto, 'use_font_size', $DEFAULT, 14);

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
        "new Gnome::FontPicker;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(".
        "_('$title') );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_mode(".
        "'$mode' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->fi_set_show_size(".
        "$show_size );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_preview_text(".
        "_('$preview_text' ));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->fi_set_use_font_in_label(".
        "$use_font, $use_font_size );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeHRef {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeHRef";
    my $name = $proto->{name};
    my $url = $class->use_par($proto, 'url', $DEFAULT, '' );
    my $label = $class->use_par($proto, 'label', $DEFAULT, '' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::HRef(".
        "'$url', _('$label'));" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeIconEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeIconEntry";
    my $name = $proto->{name};
    my $history_id = $class->use_par($proto, 'history_id',  $DEFAULT, '' );
    my $title      = $class->use_par($proto, 'title',       $DEFAULT, '' );
    my $max_saved  = $class->use_par($proto, 'max_saved',   $DEFAULT, 10 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::IconEntry(".
        "'$history_id', _('$title'));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->gnome_entry->set_max_saved(".
        "$max_saved );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeIconList {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeIconList";
    my $name = $proto->{name};
    my $text_editable  = $class->use_par($proto, 'text_editable',  $BOOL, 'False' );
    my $icon_width     = $class->use_par($proto, 'icon_width',     $DEFAULT, 78);
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP, 'single' );
    my $row_spacing    = $class->use_par($proto, 'row_spacing',    $DEFAULT, 4 );
    my $column_spacing = $class->use_par($proto, 'column_spacing', $DEFAULT, 2 );
    my $text_spacing   = $class->use_par($proto, 'text_spacing',   $DEFAULT, 2 );
    my $text_static    = $class->use_par($proto, 'text_static',    $BOOL,   'False' );
    my $flags = $text_editable + 2 * $text_static;
# FIXME possibly use new_flags() ?
    if ($class->my_perl_gtk_can_do('gnome_iconlist_new_undef')) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::IconList(".
            "$icon_width, undef, $flags);" );    
    } else {
        $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::IconList(".
            "$icon_width, ".
            "new Gtk::Adjustment( 0.0, 0.0, 101.0, 0.1, 1.0, 1.0), ".
            "$flags);" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_row_spacing(".
        "$row_spacing );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_col_spacing(".
        "$column_spacing );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_text_spacing(".
        "$text_spacing );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_selection_mode(".
        "'$selection_mode' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeIconSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeIconSelection";
    my $name = $proto->{name};

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::IconSelection();" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}


sub new_GnomeLess {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeLess";
    my $name = $proto->{name};

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::Less;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeMessageBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeMessageBox";
    my $name = $proto->{name};
    my $type    = $class->use_par($proto, 'type',    $LOOKUP );
    my $message = $class->use_par($proto, 'message', $DEFAULT, '' );
    my $message_box_type = $class->use_par($proto, 'message_box_type', $LOOKUP );
    my $auto_close    = $class->use_par($proto, 'auto_close',    $BOOL, 'True' );
    my $hide_on_close = $class->use_par($proto, 'hide_on_close', $BOOL, 'True' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::MessageBox(".
        "'$message', '$message_box_type');" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->close_hides(".
        "$hide_on_close );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_close(".
        "$auto_close );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomeNumberEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeNumberEntry";
    my $name = $proto->{name};
    my $history_id = $class->use_par($proto, 'history_id',  $DEFAULT, '' );
    my $title      = $class->use_par($proto, 'title',       $DEFAULT, '' );
    my $max_saved  = $class->use_par($proto, 'max_saved',   $DEFAULT, 10 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::NumberEntry(".
        "'$history_id', _('$title'));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->gnome_entry->set_max_saved(".
        "$max_saved );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomePixmap {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomePixmap";
    my $name = $proto->{name};
    my $filename = $class->use_par($proto, 'filename',  $DEFAULT, '' );
    unless ($filename) {
        $class->diag_print(2, "warn  No pixmap file specified for GtkPixmap ".
            "'%s' so we are using the project logo instead", $name);
        $filename = $Glade_Perl->logo;
    }
    $filename = "\"\$Glade::PerlRun::pixmaps_directory/$filename\"";
#    $filename = $class->full_Path(
#        $filename, 
#        $Glade_Perl->pixmaps_directory );
    my $scaled_width   = $class->use_par($proto, 'scaled_width',  $DEFAULT, 0);
    my $scaled_height  = $class->use_par($proto, 'scaled_height', $DEFAULT, 0);
    if ($scaled_width) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new_from_file_at_size Gnome::Pixmap(".
            "$filename, $scaled_width, $scaled_height".
            " );" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new_from_file Gnome::Pixmap(".
            "$filename );" );
    }

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomePixmapEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomePixmapEntry";
    my $name = $proto->{name};
    my $history_id = $class->use_par($proto, 'history_id',  $DEFAULT, '' );
    my $title      = $class->use_par($proto, 'title',       $DEFAULT, '' );
    my $preview    = $class->use_par($proto, 'preview',     $BOOL,    'True' );
    my $max_saved  = $class->use_par($proto, 'max_saved',   $DEFAULT, 10 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::PixmapEntry(".
        "'$history_id', _('$title'), $preview);" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->gnome_entry->set_max_saved(".
        "$max_saved );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomePaperSelector {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomePaperSelector";
    my $name = $proto->{name};

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::PaperSelector;");

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GnomePropertyBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomePropertyBox";
    my $name = $proto->{name};

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gnome::PropertyBox(".
        ");");
# FIXME - Glade 0.5.3 doesn't generate these params, perhaps it should?
#    $class->add_to_UI( $depth, "\$widgets->{'$name'}->close_hides(".
#        "'$hide_on_close' );" );
#    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_close(".
#        "'$auto_close' );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}


sub new_GnomeSpell {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GnomeSpell";
    my $name = $proto->{name};

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gnome::Spell;");

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkClock {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkClock";
    my $name = $proto->{name};
    my $type     = $class->use_par($proto, 'type',     $LOOKUP,  'realtime' );
    my $format   = $class->use_par($proto, 'format',   $DEFAULT, '%H:%M' );
    my $seconds  = $class->use_par($proto, 'seconds',  $DEFAULT, 0 );
    my $interval = $class->use_par($proto, 'interval', $DEFAULT, 60 );

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gtk::Clock('$type');" );
    unless ($class->my_gnome_libs_can_do('gtk_clock_new')) {
        $class->diag_print(1, "warn  Your clock will start at 00:00 until ".
            "you upgrade your gnome-libs");
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_format(_('$format' ));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_seconds($seconds );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_interval($interval );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->start();" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkDial {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkDial";
    my $name = $proto->{name};
    my $view_only    = $class->use_par($proto, 'view_only',    $BOOL, 'False' );
    my $update_policy= $class->use_par($proto, 'update_policy',$LOOKUP, 'continuous' );
    my $value        = $class->use_par($proto, 'value',        $DEFAULT, 0 );
    my $lower        = $class->use_par($proto, 'lower',        $DEFAULT, 0 );
    my $upper        = $class->use_par($proto, 'upper',        $DEFAULT, 100 );
    my $step         = $class->use_par($proto, 'step',         $DEFAULT, 0 );
    my $page         = $class->use_par($proto, 'page',         $DEFAULT, 0 );
    my $page_size    = $class->use_par($proto, 'page_size',    $DEFAULT, 0 );

    $class->add_to_UI( $depth,  "\$work->{'$name-adj'} = new Gtk::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size );" );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Dial(".
        "\$work->{'$name-adj'});" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_view_only($view_only );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy('$update_policy' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkPixmapMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkPixmapMenuItem";
    my $name = $proto->{name};
    my $work;
    my $stock_item = uc($class->use_par($proto, 'stock_item', $DEFAULT, '' ));
    my $stock_icon = $class->use_par($proto, 'stock_icon', $LOOKUP, '' );
    my $label = $class->use_par($proto, 'label', $DEFAULT, '' );
    my $right_justify = $class->use_par($proto, 'right_justify', $BOOL, 'False' );
#    $class->diag_print(2, $Glade::PerlUIExtra::gnome_enums);
# FIXME - decide how to mix accellabels and labels with visible accelerators
# with menuitems. pixmapmenuitems and stock_icons
# FIXME parse_uline
    if ($stock_item) {
        $stock_item =~ s/GNOMEUIINFO_MENU_(.*)_ITEM/$1/;
        $label = __PACKAGE__->lookup("GNOME_MENU_$stock_item\_STRING") unless $label;
        $label = ucfirst(lc($stock_item)) unless $label;
        $stock_icon = __PACKAGE__->lookup("GNOME_STOCK_PIXMAP_$stock_item");
        $stock_item =~ s/^PROPERTIES$/PROP/;    # What is this shit?
        $stock_item =~ s/^PREFERENCES$/PREF/;   # What is this shit?
        $work->{'sim'} = __PACKAGE__->lookup("GNOME_STOCK_MENU_$stock_item");
    }
    if ($work->{'sim'}) {
#        $work->{'sip'} = __PACKAGE__->lookup("GNOME_STOCK_PIXMAP_$stock_item");
        $work->{'ak'}  = __PACKAGE__->lookup("GNOME_KEY_NAME_$stock_item");
        $work->{'am'}  = __PACKAGE__->lookup("GNOME_KEY_MOD_$stock_item");
#        $stock_item = $gnome_enums->{"GNOME_STOCK_PIXMAP_$stock_item"};
#use Data::Dumper;print Dumper($work);
# FIXME make this add to a Gnome::UIInfo structure for later use by 
#   Gnome->create_menus() - see also toolbars
#   GNOME_KEY_NAME_$stock_item and GNOME_KEY_MOD_$stock_item

        my ($ac_mods, @ac_mods);
        my $accel_flags = "['visible', 'locked']";
        if ($work->{'sim'}) {
            $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                "Gnome::Stock->menu_item('$work->{'sim'}', _('$label'));" );

        } else {
            $stock_item = ucfirst(lc($stock_item));
            $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                "new Gtk::MenuItem('$stock_item');" );
        }            
#        use Data::Dumper; print Dumper($widgets->{$name}->child->children->[1]->parse_uline);

#        my $accelerator_key = __PACKAGE__->lookup($work->{'ak'});
        my $accelerator_key = $work->{'ak'};
        $accelerator_key =~ s/GDK_//;
        $accelerator_key = $Gtk::Keysyms{$accelerator_key} if $accelerator_key;

        my $work = $class->use_par($proto, 'ac_mods', $DEFAULT, '0' ) ||
            $work->{'am'};
        foreach $work (split(/\|/, $work)) {
            push @ac_mods, Glade::PerlUIGtk->lookup($work);
        }
        $ac_mods = '';
        $ac_mods = join("', '", @ac_mods) if $#ac_mods >= 0;

        if ($accelerator_key || $ac_mods) {
#print "Found accelerator_key of '$accelerator_key' and ac_mods of '$ac_mods'\n\n";
            $class->add_to_UI( $depth, "${current_form}\{accelgroup}->add(".
                "$accelerator_key, \['$ac_mods'\], $accel_flags, ".
                "\$widgets->{'$name'}, 'activate');");
        }

    } elsif ($stock_icon) {
        $stock_icon = ucfirst($stock_icon);
        # Remove any underline accelerators
        if ($label =~ s/_(.)/$1/) {
            $class->diag_print(2, 
                "warn  underline accelerator removed from '%s' in %s",
                $name, $me);
        }
#        $stock_icon = $gnome_enums->{$stock_icon};
        $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
            "Gnome::Stock->menu_item('$stock_icon', _('$label'));" );
            
    } elsif ($label) {
        my $pattern = $label;
        # The line below replaces Gtk+ function gtk_label_parse_uline
        if ($label =~ s/_(.)/$1/) {
            # We have an accelerator key indicated by $1
            my $accel_key = $1;
            # Replace chars with spaces (except '_')
            $pattern =~ tr/_/ /c;
            if ($stock_icon) {
#                $stock_icon = $gnome_enums->{$stock_icon};
                $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                    "Gnome::Stock->menu_item('$stock_icon', _('$label'));" );
             } else {
                $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                    "new Gtk::PixmapMenuItem;" );
            }
            if ($right_justify) { 
                $class->add_to_UI( $depth, "\$widgets->{'$name'}->right_justify;" );
            }
            # Underline accelerators - uuurrrggghhh
            $class->add_to_UI( $depth, "\$widgets->{'$name-accel'} = ".
                "new Gtk::AccelLabel( _('$label') );" );
            $class->add_to_UI( $depth, "\$widgets->{'$name-accel'}->show;");
            $class->add_to_UI( $depth, "\$widgets->{'$name'}->add(".
                "\$widgets->{'$name-accel'});" );
#            $class->add_to_UI( $depth, "\$widgets->{'$name-accel'}->parse_uline;" );
            $class->add_to_UI( $depth, "\$widgets->{'$name-accel'}->set_pattern(".
                "'$pattern');" );
            $class->add_to_UI( $depth, "${current_form}\{accelgroup}->add(".
                ord(lc($accel_key)).", ['mod1_mask'], ['visible', 'locked'], ".
                "\$widgets->{'$name'}, 'activate_item');");
            $class->add_to_UI( $depth, "${current_form}\{'$name-accel'} = ".
                "\$widgets->{'$name-accel'};" );
            delete $widgets->{"$name-accel"};

        } else {
            # There is no '_' underline accelerator
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new Gtk::PixmapMenuItem(_('$label'));" );
            if ($right_justify) { 
                $class->add_to_UI( $depth, "\$widgets->{'$name'}->right_justify;" );
            }
        }
    } else {
        # There is no label
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::PixmapMenuItem;" );
    }
    if ($right_justify) { 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->right_justify;" );
    }

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

1;

__END__

