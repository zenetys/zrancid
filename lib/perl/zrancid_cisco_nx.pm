package zrancid_cisco_nx;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{inloop_pre_hook} = sub {
    my($fd_in, $fd_out) = @_;

    $fd_in = zrancid::_modraw($fd_in, sub {
        my $line = $_;
        $line =~ s/, (no sync exists|sync state exists)/, <sync-info-removed>/; # too much flapping
        return $line;
    });

    nxos::inloop($fd_in, $fd_out);
    return ($fd_in, $fd_out, 1);
};

return 1;
