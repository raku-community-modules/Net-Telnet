use v6.c;
use Net::Telnet::Chunk;
unit class Net::Telnet::Client;

has IO::Socket::Async $.socket;

method host(--> Str) { $!socket.peer-host }
method port(--> Int) { $!socket.peer-port }

multi method connect(::?CLASS:U: Str $host, Int $port = 23 --> Promise) {
    my $client = self.new;
    $client.connect($host, $port);
}
multi method connect(::?CLASS:D: Str $host, Int $port = 23 --> Promise) {
    IO::Socket::Async.connect($host, $port).then(-> $p {
        my Buf[uint8] $buf .= new;
        $!socket = $p.result;
        $!socket.Supply(:bin, :$buf).tap(-> $data {
            self.parse($data);
        });
        self;
    });
}

method parse(Blob $data) {
    my $match = Net::Telnet::Chunk::Grammar.parse(
        $data.decode('latin1'),
        actions => Net::Telnet::Chunk::Actions.new
    );
    .say for $match.made;
}

multi method send(Blob $data) { $!socket.write($data) }
multi method send(Str $data)  { $!socket.print($data) }

method close(--> Bool) { $!socket.close }
