package Crypt::Passphrase::Bcrypt;

use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Carp 'croak';
use Crypt::Eksblowfish::Bcrypt qw/bcrypt en_base64/;

sub new {
	my ($class, %args) = @_;
	my $subtype = $args{subtype} || '2a';
	croak "Unknown subtype $subtype" unless $subtype =~ / \A 2 a? \z /x;
	return bless {
		cost    => $args{cost} ||  14,
		subtype => $subtype,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes(16);
	return bcrypt($password, sprintf '$%s$%02d$%s', $self->{subtype}, $self->{cost}, en_base64($salt))
}

sub needs_rehash {
	my ($self, $hash) = @_;
	my ($type, $cost, $salt) = $hash =~ qr/ \A \$ (2a?) \$ ([0-9]{2}) \$ ([.\/A-Za-z0-9]{22}) ([.\/A-Za-z0-9]{31}) \z /x or return 1;
	return 1 if $type ne $self->{subtype} || $cost < $self->{cost};
}

sub crypt_subtypes {
	return qw/2 2a/;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	my ($settings) = $hash =~ / \A ( \$ .* \$ [^\$]{22} ) [^\$]{31} \z  /x or return;
	return bcrypt($password, $settings) eq $hash;
}

1;

#ABSTRACT: A bcrypt encoder for Crypt::Passphrase

=method new(%args)

=over 4

=item * cost

This is the cost factor that is used to hash passwords.

=item * subtype

This is C<2a> by default, and you're unlikely to want to change this.

=back

=method hash_password($password)

This hashes the passwords with bcrypt according to the specified settings and a random salt (and will thus return a different result each time).

=method needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, or if any of the cost is lower that desired by the encoder.

=method crypt_types()

This class supports the following crypt types: C<2a> and C<2>.

=method verify_password($password, $hash)

This will check if a password matches a bcrypt hash.
