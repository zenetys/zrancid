package zrancid_cisco_sb;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{inloop_pre_hook} = sub {
    my($fd_in, $fd_out) = @_;

    $fd_in = zrancid::_modraw($fd_in, sub {
        my $line = $_;
        $line =~ s/\x1b\[A//g; # Sx220
        $line =~ s/\x1b\[0m//g; # CBS250-8T-D
        return undef if (/^\S+ uptime is [0-9]+/); # Sx220
        return undef if (/^! System Up Time: [0-9]+/); # Sx220, Planet GS421024T2S
        return undef if (/^SYSTEM CONFIG FILE ::= BEGIN/); # Planet GS421024T2S
        return $line;
    });

    iossb::inloop($fd_in, $fd_out);
    return ($fd_in, $fd_out, 1);
};

return 1;
