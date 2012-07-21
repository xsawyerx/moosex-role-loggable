use strict;
use warnings;
package MooseX::Role::Loggable;
# ABSTRACT: Extensive, yet simple, logging role using Log::Dispatchouli

use Moo::Role;
use MooX::Types::MooseLike::Base qw<Bool Str>;
use Sub::Quote 'quote_sub';
use Log::Dispatchouli;

# FIXME: enable this when Moo fixes it
# use namespace::autoclean;

has debug => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has logger_facility => (
    is      => 'ro',
    isa     => Str,
    default => sub {'local6'},
);

has logger_ident => (
    is      => 'ro',
    isa     => Str,
    default => sub {__PACKAGE__},
);

has log_to_file => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_to_stdout => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_to_stderr => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_file => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_log_file',
);

has log_path => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_log_path',
);

has log_pid => (
    is      => 'ro',
    isa     => Bool,
    default => sub {1},
);

has log_fail_fatal => (
    is      => 'ro',
    isa     => Bool,
    default => sub {1},
);

has log_muted => (
    is      => 'ro',
    isa     => Bool,
    default => sub {0},
);

has log_quiet_fatal => (
    is      => 'ro',
    isa     => quote_sub(q{
        use Safe::Isa;
        $_[0] || $_[0]->$_isa( ref [] )
            or die "$_[0] must be a string or arrayref"
    }),
    default => sub {'stderr'},
);

has logger => (
    is      => 'lazy',
    isa     => quote_sub(q{
        use Safe::Isa;
        $_[0]->$_isa('Log::Dispatchouli')
            or die "$_[0] must be a Log::Dispatchouli object";
    }),
    handles => [ qw/
        log log_fatal log_debug
        set_debug clear_debug set_prefix clear_prefix set_muted clear_muted
    / ],
);

sub _build_logger {
    my $self     = shift;
    my %optional = ();

    foreach my $option ( qw/log_file log_path/ ) {
        my $method = "has_$option";
        if ( $self->$method ) {
            $optional{$option} = $self->$option;
        }
    }

    my $logger = Log::Dispatchouli->new( {
        debug       => $self->debug,
        ident       => $self->logger_ident,
        facility    => $self->logger_facility,
        to_file     => $self->log_to_file,
        to_stdout   => $self->log_to_stdout,
        to_stderr   => $self->log_to_stderr,
        log_pid     => $self->log_pid,
        fail_fatal  => $self->log_fail_fatal,
        muted       => $self->log_muted,
        quiet_fatal => $self->log_quiet_fatal,
        %optional,
    } );

    return $logger;
}

sub log_fields {
    my $self  = shift;
    my @attrs = qw/
        debug logger_facility logger_ident
        log_to_file log_to_stdout log_to_stderr
        log_file log_path log_pid log_fail_fatal log_muted log_quiet_fatal
    /;

    return map { $_ => $self->$_ } grep { defined $self->$_ } @attrs;
};

1;

__END__

=head1 SYNOPSIS

    package My::Object;

    use Moose; # or Moo
    with 'MooseX::Role::Loggable';

    sub do_this {
        my $self = shift;
        $self->set_prefix('[do_this] ');
        $self->log_debug('starting...');
        ...
        $self->log_debug('more stuff');
        $self->clear_prefix;
    }

=head1 DESCRIPTION

This is a role to provide logging ability to whoever consumes it using
L<Log::Dispatchouli>. Once you consume this role, you have the attributes and
methods documented below.

You can propagate your logging definitions to another object that uses
L<MooseX::Role::Loggable> using the C<log_fields> attribute as such:

    package Parent;
    use Moo; # replaces Any::Moose and Mouse (and Moose)
    use MooseX::Role::Loggable; # picking Moo or Moose

    has child => (
        is      => 'ro',
        isa     => 'Child',
        lazy    => 1,
        builder => '_build_child',
    );

    sub _build_child {
        my $self = shift;
        return Child->new( $self->log_fields );
    }

This module uses L<Moo> so it takes as little resources as it can by default,
and can seamlessly work if you're using either L<Moo> or L<Moose>.

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

=head2 log_file

The leaf name for the log file.

Default: B<undef>

=head2 log_path

The path for the log file.

Default: B<undef>

=head2 log_pid

Whether to append the PID to the log filename.

Default: B<yes>

=head2 log_fail_fatal

Whether failure to log is fatal.

Default: B<yes>

=head2 log_muted

Whether only fatals are logged.

Default: B<no>

=head2 log_quiet_fatal

From L<Log::Dispatchouli>:
I<'stderr' or 'stdout' or an arrayref of zero, one, or both fatal log messages
will not be logged to these>.

Default: B<stderr>

=head2 log_fields

A hash of the fields definining how logging is being done.

This is very useful when you want to propagate your logging onwards to another
object which uses L<MooseX::Role::Loggable>.

It will return the following attributes and their values in a hash: C<debug>,
C<debug>, C<logger_facility>, C<logger_ident>, C<log_to_file>,
C<log_to_stdout>, C<log_to_stderr>, C<log_file>, C<log_path>, C<log_pid>,
C<log_fail_fatal>, C<log_muted>, C<log_quiet_fatal>.

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

=head2 set_debug

Set the debug flag.

=head2 clear_debug

Clear the debug flag.

=head2 set_prefix

Set a prefix for all next messages.

=head2 clear_prefix

Clears the prefix for all next messages.

=head2 set_muted

Sets the mute property, which makes only fatal messages logged.

=head2 clear_muted

Clears the mute property.

