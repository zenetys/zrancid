package zrancid_huawei;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{inloop_pre_hook} = sub {
    my($fd_in, $fd_out) = @_;

    $fd_in = zrancid::_modraw($fd_in, sub {
        my $line = $_;
        return undef if /Error: No file found "flash:\/off"/;
        return undef if /Error: Unrecognized command found/;
        return $line;
    });

    vrp::inloop($fd_in, $fd_out);
    return ($fd_in, $fd_out, 1);
};

return 1;
