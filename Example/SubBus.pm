package SubBus;
require 5.000; use English; use strict 'vars', 'refs', 'subs';

BEGIN {
    use vars       qw( 
                        @ISA
                        $AUTOLOAD
                        %fields
                   );
    # Tell interpreter who we are inheriting from
    use Generated::BusForm;
    use Example::BusForm_mySUBS;
    @ISA         = qw( BusFrame );
    # Inherit the AUTOLOAD dynamic methods from BusFrame
    *AUTOLOAD      = \&BusFrame::AUTOLOAD;
}

%fields = (
# Insert any extra data access methods that you want to add to 
#   our inherited super-constructor (or overload)
    USERDATA    => undef,
    VERSION     => '9.9.9',
);

#==============================================================================
#=== These are the overloaded class constructors and so on                  ===
#==============================================================================
sub new {
    my $that  = shift;
    # Allow indirect constructor so that we can call eg. 
    #   $window1 = BusFrame->new; $window2 = $window1->new;
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

sub run {
    my ($class) = @ARG;
    Gtk->init;
    my $window = $class->new;
    $window->USERDATA({
        'Key1'   => 'Value1',
        'Key2'   => 'Value2',
        'Key3'   => 'Value3',
        });
    $window->TOPLEVEL->show;
    my $window2 = $class->new;
    $window2->TOPLEVEL->show;
    Gtk->main;
    return $window;
}
#===============================================================================
#==== Below are overloaded signal handlers                                  ====
#===============================================================================
sub about_Form {
    my ($class) = @ARG;
    my $gtkversion = 
        Gtk->major_version.".".
        Gtk->minor_version.".".
        Gtk->micro_version;
    my $name = $0;
    my $message = 
        __PACKAGE__." (version 9.9.9 - Fri Jul 23 21:52:05 BST 1999)\n".
        "Written by         A subclass programmer\n\n".
        "Gtk version:        $gtkversion\n".
        "Gtk-Perl version:    $Gtk::VERSION\n\n".
        "run from file:        $name";
    __PACKAGE__->message_box(
        $message, 
        "About \u".__PACKAGE__, 
        ['Dismiss', 'Quit Program'], 
        1,
        'pixmaps/Logo.xpm', 'left' );
}

sub destroy_Form {
#    my ($class, $data, $object, $form) = @ARG;
#    $form->TOPLEVEL->get_toplevel->destroy;
#    __PACKAGE__->destroy_all_forms;
    Gtk->main_quit; 
}

sub Skeleton_Handler {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->Skeleton_Handler";
    # REPLACE the line below with the actions to be taken when $me is called
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/Logo.xpm');
}

sub on_Contents_activate {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_Contents_activate";
    # REPLACE the line below with the actions to be taken when $me is called
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/Logo.xpm');
}

sub on_Index_activate {
#	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_Index_activate";
    # REPLACE the line below with the actions to be taken when $me is called
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/Logo.xpm');
}

sub on_New_activate {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_New_activate";
    my $filesel = fileselection1->new->TOPLEVEL;
    $filesel->set_title("New file selection triggered in $me");
    $filesel->show;
}

sub on_Search_activate {
	my ($class, $data) = @ARG;
    my $me = __PACKAGE__."->on_Search_activate";
    # REPLACE the line below with the actions to be taken when $me is called
    __PACKAGE__->show_skeleton_message($me, \@ARG, __PACKAGE__, 'pixmaps/Logo.xpm');
}

1;

__END__

#===============================================================================
#==== Documentation ============================================================
#===============================================================================
=pod

=head1 NAME

 SubBus - version 9.9.9 Sat Aug 14 19:57:02 BST 1999
 This is an example of how to subclass a generated UI class

=head1 SYNOPSIS

 use SubBus;

 SubBus->run;

=head1 DESCRIPTION

This is just an example of subclassing a generated UI class. It inherits
from my example UI class BusForm and adds some fields and data methods and
overloads some signal handlers.

=head1 AUTHOR

Dermot Musgrove <dermot.musgrove\@virgin.net>

=cut



