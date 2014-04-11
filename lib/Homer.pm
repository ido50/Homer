package Homer;

# ABSTRACT: Simple prototype-based object system

use warnings;
use strict;

use Carp;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

Homer - Simple prototype-based object system

=head1 SYNOPSIS

	use Homer;

	# create a prototype object
	my $person = Homer->new(
		first_name => 'Generic',
		last_name => 'Person',
		say_hi => sub {
			my $self = shift;
			print "Hi, my name is ", $self->first_name, ' ', $self->last_name, "\n";
		}
	);

	# create a new object based on it
	my $homer = $person->extend(
		first_name => 'Homer',
		last_name => 'Simpson'
	);

	$homer->say_hi; # prints 'Hi, my name is Homer Simpson'

	# let's extend even more
	my $bart = $homer->extend(
		first_name => 'Bart',
		father => sub { print "My father's name is ", $_[0]->prot->first_name, "\n" }
	);

	$bart->say_hi; # prints 'Hi, my name is Bart Simpson'
	$bart->father; # prints "My father's name is Homer"

=head1 DESCRIPTION

C<Homer> is a very simple B<prototype-based object system>, similar to JavaScript.
In a prototype based object system there are no classes. Objects are either directly created
with some attributes and methods, or cloned from existing objects, in which case the object
being cloned becomes the prototype of the new object. The new object inherits all attributes
and methods from the prototype. Attributes and methods can be overridden, and new ones can be
added. The new object can be cloned as well, becoming the prototype of yet another new object,
thus creating a possibly endless chain of prototypes.

Prototype-based objects can be very powerful and useful in certain cases. They can provide a
quick way of solving problems. Plus, sometimes you just really need an object, but don't need
a class. I like to think of prototype-based OO versus class-based OO as being similar to
schema-less database systems versus relational database systems.

C<Homer> is a quick and dirty implementation of such a system in Perl. As Perl is a class-based
language, this is merely a hack. When an object is created, C<Homer> creates a specific class just
for it behind the scenes. When an object is cloned, a new class is created for the clone, with the
parent object's class pushed to the new one's C<@ISA> variable, thus providing inheritance.

I can't say this implementation is particularly smart or efficient, but it gives me what I need
and is very lightweight (C<Homer> has no non-core dependencies). If you need a more robust
solution, L<Class::Prototyped> might fit your need.

=head1 HOMER AT A GLANCE

=over

=item * Prototypes are created by calling C<new()> on the C<Homer> class with a hash, holding
attributes and methods:

	my $prototype = Homer->new(
		attr1 => 'value1',
		attr2 => 'value2',
		meth1 => sub { print "meth1" }
	);

	$prototype->attr1; # value1
	$prototype->attr2; # value2
	$prototype->meth1; # prints "meth1"

=item * A list of all pure-attributes of an object (i.e. not methods) can be received by
calling C<attributes()> on the object.

	$prototype->attributes; # ('attr1', 'attr2')

=item * Every object created by Homer can be cloned using C<extend( %attrs )>. The hash can
contain new attributes and methods, and can override existing ones.

	my $clone = $prototype->extend(
		attr2 => 'value3',
		meth2 => sub { print "meth2" }
	);

	$clone->attr1; # value1
	$clone->attr2; # value3
	$clone->meth1; # prints "meth1"
	$clone->meth2; # prints "meth2"

=item * Objects based on a prototype can refer to their prototype using the C<prot()> method:

	$clone->prot->attr2; # value2

=item * All attributes are read-write:

	$clone->attr1('value4');
	$clone->attr1; # value4
	$clone->prot->attr1; # still value1

=item * New methods can be added to an object after its construction. If the object is a
prototype of other objects, they will immediately receive the new methods too.

	$prototype->add_method('meth3' => sub { print "meth3" });
	$clone->can('meth3'); # true

=item * New attributes can't be added after construction (for now).

=item * Cloned objects can be cloned too, creating a chain of prototypes:

	my $clone2 = $clone->extend;
	my $clone3 = $clone2->extend;
	$clone3->prot->prot->prot; # the original $prototype

=back

=head1 CONSTRUCTOR

=head2 new( [ %attrs ] )

Creates a new prototype object with the provided attributes and methods (if any).

=cut

sub new {
	my ($this_class, %attrs) = @_;

	my $new_class = $this_class->_generate_class;

	return $this_class->_generate_object($new_class, %attrs);
}

sub _generate_class {
	my $this_class = shift;

	my @caller = caller(1);

	return join('::', $this_class, @caller[3,2]);
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

		*{"${new_class}::prot"} = sub { $prot };

		return $this_class->_generate_object($new_class, %attrs);
	};

	*{"${new_class}::add_method"} = sub {
		my ($self, $name, $code) = @_;

		croak "You must provide the name of the method"
			unless $name && !ref $name;
		croak "You must provide an anonymous subroutine"
			unless $code && ref $code && ref $code eq 'CODE';

		*{"${new_class}::$name"} = $code;
	};

	return bless \%attrs, $new_class;
}

=head1 CONFIGURATION AND ENVIRONMENT
  
C<Homer> requires no configuration files or environment variables.

=head1 DEPENDENCIES

None other than L<Carp>.

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
