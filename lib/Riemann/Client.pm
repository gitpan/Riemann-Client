package Riemann::Client;
{
  $Riemann::Client::VERSION = '0.03';
}

use Moo;
use Net::Domain qw/hostfqdn/;

use Riemann::Client::Transport::TCP;
use Riemann::Client::Transport::UDP;

has host  => (is => 'ro',  default => sub { 'localhost' });
has port  => (is => 'ro',  default => sub { 5555 }       );
has proto => (is => 'rwp', default => sub { 'tcp' }      );

has transport => (is => 'rwp', lazy => 1, builder => 1);

sub send {
    my ($self, @opts) = @_;

    # Set default stuff
    map {
        $_->{host} = hostfqdn() unless defined $_->{host};
        $_->{time} = time()     unless defined $_->{time};
        $_->{metric_d} = delete $_->{metric} if $_->{metric};
    } @opts;

    return $self->transport->send({events => \@opts});
}

sub query {
    my ($self, $query) = @_;

    if (ref $self->transport eq 'Riemann::Client::Transport::UDP') {
        $self->_set_proto('tcp');
        $self->_set_transport($self->_build_transport);
    }

    return $self->transport->send({
        query => { string => $query }
    });
}

sub _build_transport {
    my $self  = shift;
    my $class = 'Riemann::Client::Transport::' . uc $self->proto;
    return $class->new(
        host    => $self->host,
        port    => $self->port,
    );
}

1;

__END__

=pod

=head1 NAME

Riemann::Client - A Perl client for the Riemann event system

=head1 SYNOPSIS

    use Riemann::Client;

    # host and port are optional
    my $r = Riemann::Client->new(
        host => 'localhost',
        port => 5555,
    );

    # send a simple event
    $r->send({service => 'testing', metric => 2.5});

    # Or a more complex one
    $r->send({
        host    => 'web3', # defaults to Net::Domain::hostfqdn()
        service => 'api latency',
        state   => 'warn',
        metric  => 63.5,
        time    => time() - 10, # defaults to time()
        description => '63.5 milliseconds per request',
    });

    # send several events at once
    my @events = (
        { service => 'service1', ... },
        { service => 'service2', ... },
    );
    $r->send(@events);

    # Get all the states from the server
    my $res = $r->query('true');

    # Or specific states matching a query
    $res = $r->query('host =~ "%.dc1" and state = "critical"');

=head1 DESCRIPTION

Riemann::Client sends events and/or queries to a Riemann server.

=head1 METHODS

=head2 new

Returns an instance of the Riemann::Client. These are the optional arguments
accepted:

=head3 host

The Riemann server. Defaults to C<localhost>

=head3 port

Port where the Riemann server is listening. Defaults to C<5555>

=head3 proto

By default Riemann::Client will use TCP to communicate over the network. You
can force the usage of UDP setting this argument to 'udp'.
UDP datagrams have a maximum size of 16384 bytes by Riemann's default. If you
force the usage of UDP and try to send a larger message, an exception will be
raised.
In TCP mode, the client will try to reconnect to the server in case the
connection is lost.

=head2 send

Accepts a list of events (as hashrefs) and sends them over the wire to the
server. In TCP mode, it will die if there are errors while communicating with
the server. In case the connection is lost, it will try to reconnect.

=head2 query

Accepts a string and returns a message.

=head1 MESSAGE SPECS

This is the specification of the messages in L<Google::ProtocolBuffers> format:

    message State {
      optional int64 time = 1;
      optional string state = 2;
      optional string service = 3;
      optional string host = 4;
      optional string description = 5;
      optional bool once = 6;
      repeated string tags = 7;
      optional float ttl = 8;
    }

    message Event {
      optional int64 time = 1;
      optional string state = 2;
      optional string service = 3;
      optional string host = 4;
      optional string description = 5;
      repeated string tags = 7;
      optional float ttl = 8;
      repeated Attribute attributes = 9;

      optional sint64 metric_sint64 = 13;
      optional double metric_d = 14;
      optional float metric_f = 15;
    }

    message Query {
      optional string string = 1;
    }

    message Msg {
      optional bool ok = 2;
      optional string error = 3;
      repeated State states = 4;
      optional Query query = 5;
      repeated Event events = 6;
    }

    message Attribute {
      required string key = 1;
      optional string value = 2;
    }

=head1 SEE ALSO

=over 4

=item *

All About Riemann L<http://aphyr.github.com/riemann/>

=item *

Ruby client L<https://github.com/aphyr/riemann-ruby-client>

=back

=head1 AUTHOR

=over 4

=item *

Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
