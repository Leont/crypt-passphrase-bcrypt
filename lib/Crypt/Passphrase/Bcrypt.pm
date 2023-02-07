package Crypt::Passphrase::Bcrypt;

use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Carp 'croak';
use Crypt::Bcrypt 0.008 qw/bcrypt bcrypt_hashed bcrypt_check_hashed bcrypt_needs_rehash/;

sub new {
	my ($class, %args) = @_;
	my $subtype = $args{subtype} || '2b';
	croak "Unknown subtype $subtype" unless $subtype =~ / \A 2 [abxy] \z /x;
	croak 'Invalid hash' if exists $args{hash} && $args{hash} ne 'sha256';
	return bless {
		cost    => $args{cost} || 14,
		subtype => $subtype,
		hash    => $args{hash} || '',
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes(16);
	return bcrypt_hashed($password, $self->{subtype}, $self->{cost}, $salt, $self->{hash});
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return bcrypt_needs_rehash($hash, @{$self}{qw/subtype cost hash/});
}

sub crypt_subtypes {
	return qw/2a 2b 2x 2y bcrypt-sha256/;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return bcrypt_check_hashed($password, $hash);
}

1;

#ABSTRACT: A bcrypt encoder for Crypt::Passphrase

=head1 DESCRIPTION

This class implements a bcrypt encoder for Crypt::Passphrase. For high-end parameters L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2> is recommended over this module as an encoder, as that provides memory-hardness and more easily allows for long passwords.

=method new(%args)

=over 4

=item * cost

This is the cost factor that is used to hash passwords.

=item * subtype

=over 4

=item * C<2b>

This is the subtype the rest of the world has been using since 2014

=item * C<2y>

This type is considered equivalent to C<2b>.

=item * C<2a>

This is an old and subtly buggy version of bcrypt. This is mainly useful for Crypt::Eksblowfish compatibility.

=item * C<2x>

This is a very broken version that is only useful for compatibility with ancient php versions.

=back

This is C<2b> by default, and you're unlikely to want to change this.

=item * hash

Pre-hash the password using the specified hash. Currently only sha256 is supported. This is mainly useful to get around the 72 character limit. This uses a salt-keyed hash to prevent password shucking.

=back

=method hash_password($password)

This hashes the passwords with bcrypt according to the specified settings and a random salt (and will thus return a different result each time).

=method needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, if any of the cost is lower that desired by the encoder or if the prehashing doesn't match.

=method crypt_types()

This returns the above described subtypes, as well as C<bcrypt-sha256> for prehashed bcrypt.

=method verify_password($password, $hash)

This will check if a password matches a bcrypt hash.
