package zrancid_cisco_ios;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{inloop_pre_hook} = sub {
    my($fd_in, $fd_out) = @_;

    $fd_in = zrancid::_modraw($fd_in, sub {
        my $line = $_;

        # too much flapping
        $line =~ s/... .. .... ..:..:.. ...:..(\s+)ssd/Jan 01 1970 00:00:00 +00:00$1ssd !<date-removed>/;
        $line =~ s/ ... . .... ..:..:.. ...:..(\s+)ssd/Jan 01 1970 00:00:00 +00:00$1ssd !<date-removed>/;
        $line =~ s/(Smart Account: .* [aA]s of) (.+)/$1 <date-removed>/;

        return $line;
    });

    ios::inloop($fd_in, $fd_out);
    return ($fd_in, $fd_out, 1);
};

return 1;
