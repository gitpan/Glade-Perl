package Glade::PerlXML;
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
    use XML::Parser   qw(  );              # for new, parse, parsefile
    use vars          qw( 
                            @ISA 
                            @EXPORT @EXPORT_OK %EXPORT_TAGS 
                            $PACKAGE $VERSION $AUTHOR $DATE
                       );
    $PACKAGE        = __PACKAGE__;
    $VERSION        = q(0.40);
    $AUTHOR         = q(Dermot Musgrove <dermot.musgrove\@virgin.net>);
    $DATE           = q(30 June 1999);
    # Tell interpreter who we are inheriting from
    @ISA            = qw(  );
}

#===============================================================================
#=========== Utilities to read XML and build the Proto                ==========
#===============================================================================
sub typeKey     { return ' type'; }
#sub keyFormat  { if (shift) {return '%04u-%s' } else {return '%04u' } }
sub keyFormat   { return '%04u' } 

sub QuoteXMLChars {
    my $text = shift;
    # Suggested by Eric Bohlman <ebohlman@netcom.com> on perl-xml mailling list
    my %ents=('&'=>'amp','<'=>'lt','>'=>'gt',"'"=>'apos','"'=>'quot');
    $text =~ s/([&<>'"])/&$ents{$1};/g;
    $text =~ s/([\x80-\xFF])/&XmlUtf8Encode(ord($1))/ge;
    return $text;
}

sub XmlUtf8Encode {
    # This was ripped from XML::DOM - thanks to
    # Enno Derksen (official maintainer), enno@att.com
    # and Clark Cooper, coopercl@sch.ge.com
    my $n = shift;
    my $me = "XmlUtf8Encode";
    if ($n < 0x80)    { 
        return chr ($n);

    } elsif ($n < 0x800) {
        return pack ("CC", (($n >> 6) | 0xc0), 
                    (($n & 0x3f) | 0x80));

    } elsif ($n < 0x10000) {
        return pack ("CCC", (($n >> 12) | 0xe0), 
                    ((($n >> 6) & 0x3f) | 0x80),
                     (($n & 0x3f) | 0x80));

    } elsif ($n < 0x110000) {
        return pack ("CCCC", (($n >> 18) | 0xf0), 
                    ((($n >> 12) & 0x3f) | 0x80),
                     ((($n >> 6) & 0x3f) | 0x80), 
                      (($n & 0x3f) | 0x80));
    }
    __PACKAGE__->diag_print(1, "error Number is too large for Unicode ".
        "[$n] in $me");
    return "#";
}

sub Proto_from_File {
    my ($class, $filename, $special, $repeated) = @ARG;
    my $me = "$class->Proto_from_File";
    my $tree = new XML::Parser(
        Style =>'Tree', ErrorContext => 2)->parsefile($filename );
    return $class->Proto_from_XML_Parser_Tree(
        $tree->[1], 0, $special, $repeated );
}

sub Proto_from_XML {
    my ($class, $xml, $special, $repeated) = @ARG;
    my $me = "$class->Proto_from_XML";
    my $tree = new XML::Parser(Style =>'Tree', ErrorContext => 2)->parse($xml );
    return $class->Proto_from_XML_Parser_Tree($tree->[1], 
        0, $special, $repeated );
}

sub Proto_from_XML_Parser_Tree {
    my ($class, $self, $depth, $special, $repeated) = @ARG;
    my $me = "$class->Proto_from_XML_Parser_Tree";
    # Tree[0]      contains fileelement name
    # Tree[1]      contains fileelement contents
    
    # Tree[1][n]      contains element name
    # Tree[1][n+1]    contains element contents
    # Tree[1][n+1][0] contains ref to hash of element attributes
    # Tree[1][n+1][1] contains '0' ie next element is text
    # Tree[1][n+1][2] contains text before subelement

    # Tree[1][n+1][3] contains subelement name
    # Tree[1][n+1][4] contains subelement contents
    # Tree[1][n+1][5] contains '0' ie next element is text
    # Tree[1][n+1][6] contains text before subelement
    #        recursed
    
    # Tree[3] cannot exist since the fileelement must enclose everything
    my ($tk, $i, $ilimit );
    my ($count, $np, $key, $work );
    my $limit = scalar(@$self );
    my $child;
    $key = 0;
    for ($count = 3; $count < $limit; $count += 4) {
        $key++;
        $ilimit = scalar @{$self->[$count+1]};
        if (" $repeated " =~ / $self->[$count] /) {
            # this is a repeated container so use a sequence no to preserve order
            if ($ilimit <= 3)  {
#                $class->diag_print(4, "Found a scalar called '".
#                    "$self->[$count]' which contains '$self->[$count+1][2]'".
#                    " in a repeated container type element !" );
                $np->{$self->[$count]} = $self->[$count+1][2];
            } else {
                # call ourself to expand nested xml but use sequence no
                $work = $class->Proto_from_XML_Parser_Tree($self->[$count + 1], 
                    ++$depth, $special, $repeated );
                $work->{&typeKey} = $self->[$count];
                # prefix with tilde to force to end (alphabetically)
                $tk = "~$self->[$count]-".sprintf(&keyFormat, $key, $self->[$count] );
                $np->{$tk} = $work;
            }

        } elsif (" $special " =~ / $self->[$count] /) {
            # this is a unique container definition so 
            # expand and store it with no sequence no
#            $class->diag_print(2, "Found a signal length ".(scalar $self->[$count+1]) );
            $work = $class->Proto_from_XML_Parser_Tree($self->[$count + 1], 
                ++$depth, $special, $repeated );
            $work->{&typeKey} = $self->[$count];
            $np->{$self->[$count]} = $work;

        } elsif ($ilimit > 3) {
            # We have several (widget) attributes to store
            $work = {};
            for ($i = 3; $i < $ilimit; $i += 4) {
                $work->{$self->[$count+1][$i]} = $self->[$count+1][$i+1][2];
            }
            $work->{&typeKey} = $work->{'class'} || $self->[$count];
            # prefix with tilde to force to end (alphabetically)
            $tk = "~$self->[$count]-".
            sprintf(&keyFormat, $key, $self->[$count] );
            $np->{$tk} = $work;

        } else {
            # this is a simple element to add with 
            # key in $self->[$count] and val in $self->[$count+1][2]
            $np->{$self->[$count]} = $self->[$count+1][2];
        }
    }
    return $np;
}

sub XML_from_Proto {
    # usage my $xmlstring = 
    #   XML::UTIL->XML_from_Proto($prefix, '  ', $tag, $protohashref);
    # This proc will compose XML from a proto hash in 
    #   Proto_from_XML's return format
    my ($class, $prefix, $tab, $tag, $proto) = @ARG;
	my $me = "$class->XML_from_Proto";
	my ($key, $val, $xml, $limit);
	my $typekey = &typeKey;
	my $contents = '';
	my $newprefix = "$tab$prefix";

	# make up the start tag 
	foreach $key (sort keys %$proto) {
		unless ($key eq $typekey) {
			if (ref $proto->{$key}) {
				# call ourself to expand nested xml
				$contents .= "\n".$class->XML_from_Proto($newprefix, $tab, 
                    $proto->{$key}{$typekey}, $proto->{$key})."\n";
			} else {
				# this is a vanilla string so trim and add to output
				if (defined $proto->{$key}) {
                    $contents .= "\n$newprefix<$key>".&QuoteXMLChars($proto->{$key})."</$key>";
				} else {
					$contents .= "\n$newprefix<$key></$key>";
#					$contents .= "\n$newprefix<$key />";
				}
			}
		}
	}

	# make up the string to return
	if ($contents eq '') {
		if ($tag ne '') {
			$xml .= "\n$prefix<$tag />";
		}
	} else {
		if ($tag ne '') {
			$xml .= "$prefix<$tag>$contents\n$prefix</$tag>";
		} else {
			$xml .= "\n$contents\n";
		}
	}
	return $xml
}
	
1;

__END__
