package zrancid_cisco_ucs;

sub import { return 0; }
sub init { return 0; }

$zrancid::options{commands}{'show version brief'}{prefix} = '!Version: ';
$zrancid::options{commands}{'show configuration all | no-more'}{subs} = [
    [ '  (           set date )\d\d? 202\d \d\d? \d\d? \d\d?$', ' !$1<removed>' ],
    [ '(^\s*!\s*enter backup .*)(20\d\d-\d\d-\d\dT\d\d-\d\d-\d\d\.\d\d\d)(.*)(enabled|disabled)(.*)', '$1<removed>$3<removed>$5' ],
    [ '(^\s*!\s*enter backup .*[^0-9])(\d{10,})(.*)(enabled|disabled)(.*)', '$1<removed>$3<removed>$5' ],
    [ '(^\s*!\s*enter backup .* )(enabled|disabled)(.*)', '$1<removed>$3' ],
    [ '(^\s*!\s*set remote-file .*)(20\d\d-\d\d-\d\dT\d\d-\d\d-\d\d\.\d\d\d)(.*)', '$1<removed>$3' ],
    [ '(^\s*!\s*set remote-file .*[^0-9])(\d{10,})(.*)', '$1<removed>$3' ],
];

return 1;
