package Homer;

# ABSTRACT: Simple prototype-based object system

use warnings;
use strict;

use Carp;
use Data::UUID;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

Homer - Simple prototype-based object system

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new()

=cut

sub new {
	my ($this_class, %attrs) = @_;

	my $new_class = $this_class->_generate_class;

	return $this_class->_generate_object($new_class, %attrs);
}

sub _generate_class {
	my $this_class = shift;

	my $uuid = Data::UUID->new;
	return $this_class.'::C'.$uuid->create_str;
}

sub _generate_object {
	my ($this_class, $new_class, %attrs) = @_;

	no strict 'refs';
	foreach my $a (keys %attrs) {
		if (ref $attrs{$a} && ref $attrs{$a} eq 'CODE') {
			# method
			*{"${new_class}::$a"} = delete($attrs{$a});
		} else {
			*{"${new_class}::$a"} = sub {
				my ($self, $newval) = @_;

				$self->{$a} = $newval
					if $newval;

				return $self->{$a};
			};
		}
	}

	*{"${new_class}::attributes"} = sub { keys %attrs };

	*{"${new_class}::extend"} = sub {
		my ($prot, %attrs) = @_;

		foreach ($prot->attributes) {
			$attrs{$_} = $prot->$_
				unless exists $attrs{$_};
		}

		my $new_class = $this_class->_generate_class;
		@{"${new_class}::ISA"} = (ref($prot));
		return $this_class->_generate_object($new_class, %attrs);
	};

	return bless \%attrs, $new_class;
}

=head1 CONFIGURATION AND ENVIRONMENT
  
C<Homer> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Homer> depends on the following CPAN modules:

=over

=item * Carp

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Homer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Homer>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Homer

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Homer>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Homer>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Homer>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Homer/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2014, Ido Perlmuter C<< ido@ido50.net >>.
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.
 
The full text of the license can be found in the
LICENSE file included with this module.
 
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
