use strict;
use warnings;
package MooseX::Role::Loggable;
# ABSTRACT: Extensive, yet simple, logging role using Log::Dispatchouli

use Moose::Role;
use Log::Dispatchouli;
use namespace::autoclean;

has debug => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    trigger => sub { shift->logger->set_debug(shift) },
);

has logger_facility => (
    is      => 'ro',
    isa     => 'Str',
    default => 'local6',
);

has logger_ident => (
    is      => 'ro',
    isa     => 'Str',
    default => __PACKAGE__,
);

has log_to_file => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has log_to_stdout => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has log_to_stderr => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has logger => (
    is         => 'ro',
    isa        => 'Log::Dispatchouli',
    handles    => [ 'log', 'log_fatal', 'log_debug', 'set_prefix' ],
    lazy_build => 1,
);

sub _build_logger {
    my $self   = shift;
    my $logger = Log::Dispatchouli->new( {
        ident     => $self->logger_ident,
        facility  => $self->logger_facility,
        to_file   => $self->log_to_file,
        to_stdout => $self->log_to_stdout,
        to_stderr => $self->log_to_stderr,
    } );

    return $logger;
}

no Moose::Role;

1;

__END__

=head1 SYNOPSIS

    package My::Object;

    use Moose;
    with 'MooseX::Role::Loggable';

    sub do_this {
        my $self = shift;
        $self->set_prefix('[do_this] ');
        $self->log_debug('starting...');
        ...
        $self->log_debug('more stuff');
    }

=head1 DESCRIPTION

This is a role to provide logging ability to whoever consumes it using
L<Log::Dispatchouli>.

Once you consume this role, you have the attributes and methods documented
below.

=head1 ATTRIBUTES

=head2 debug

A boolean for whether you're in debugging mode or not.

Default: B<no>.

Read-only.

=head2 logger_facility

The facility the logger would use. This is useful for syslog.

Default: B<local6>.

=head2 logger_ident

The ident the logger would use. This is useful for syslog.

Default: B<MooseX::Role::Loggable>.

Read-only.

=head2 log_to_file

A boolean that determines if the logger would log to a file.

Default location of the file is in F</tmp>.

Default: B<no>.

Read-only.

=head2 log_to_stdout

A boolean that determines if the logger would log to STDOUT.

Default: B<no>.

=head2 log_to_stderr

A boolean that determines if the logger would log to STDERR.

Default: B<no>.

=head2 logger

A L<Log::Dispatchouli> object.

=head1 METHODS

All methods here are imported from L<Log::Dispatchouli>. You can read its
documentation to understand them better.

=head2 log

Log a message.

=head2 log_debug

Log a message only if in debug mode.

=head2 log_fatal

Log a message and die.

=head2 set_prefix

Set a prefix for all next messages.

