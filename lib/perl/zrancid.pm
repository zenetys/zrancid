package zrancid;

use rancid;
use Data::Dumper;
use File::Temp qw/ tempfile /;
use Hash::Merge::Simple qw/ merge /;

sub import { return 0; }
sub init { return 0; }

our %options = (
    'comment' => '!',
    'prompt' => '#>',
    'devtype' => 1,
    'clean_run' => 'exit|logout',
    'config_end_mark' => 'end|exit',
    'config_end_on_prompt' => 0, # set to 1 if there is no end mark
    'prefix' => '',
    'skip_until' => undef,
);

sub _dstrip {
    my ($x) = @_;
    $x =~ s/\x1b/<0x1b>/;
    $x =~ s/\r?\n$//;
    return $x;
}

sub _modraw {
    my ($fd, $on_line_callback) = @_;
    my ($fd_new, $fname_new) = tempfile(UNLINK=>1, PERMS=>0600);
    while (<$fd>) {
        my $line_ori = $_;
        my $line_new = &{$on_line_callback}($line_ori);
        if (!defined($line_new)) {
            print(STDERR "zrancid::_modraw: delete> -"._dstrip($line_ori)."\n");
            next;
        }
        if ($line_new ne $line_ori) {
            print(STDERR "zrancid::_modraw: update> -"._dstrip($line_ori)."\n".
                         "zrancid::_modraw:         +"._dstrip($line_new)."\n");
        }
        print($fd_new $line_new);
    }
    close($fd);
    close($fd_new);
    # reopen for read and return the fd
    open($fd_new, "< $fname_new");
    return $fd_new;
}


sub _subs {
    my ($line, $subs) = @_;
    for my $sub (@{$subs}) {
        my $replace = @$sub[1];
        $replace =~ s/"/\\"/g;
        $line =~ s/@$sub[0]/'"'.$replace.'"'/ee;
    }
    return $line;
}

sub _dels {
    my ($line, $dels) = @_;
    for my $del (@{$dels}) {
        return 1 if ($line =~ /$del/);
    }
    return 0;
}

sub _generic {
    my ($INPUT, $OUTPUT, $cmd, %_options) = @_;
    %_options = %{merge(\%options, \%_options, $options{commands}{$cmd})};
    print(STDERR "    In zrancid::config: \$_ = <"._dstrip($_)) if ($debug);
    print(STDERR "    In zrancid::config: \$cmd = <$cmd>\n") if ($debug);
    print(STDERR "    In zrancid::config: %_options = ") if ($debug);
    print STDERR Dumper(\%_options);

    my $indent;
    my $tell, $tell_prev;
    my $skipping_until = defined($_options{skip_until}) ? 1 : undef;

    while (<$INPUT>) {
        $tell_prev = $tell;
        $tell = tell($INPUT);

        tr/\015//d;

        if ($_options{is_config} && defined($indent) &&
            $_options{config_end_mark} ne '' &&
            /^$indent($_options{config_end_mark})$/) {
            $found_end = 1;
        }

        if (/^$prompt/) {
            if ($_options{is_config} && $_options{config_end_on_prompt}) {
                $found_end = 1;
                seek($INPUT, $tell_prev, 0);
            }
            last;
        }

        next if (/^(\s*|\s*$cmd\s*)$/);

        if (!defined($indent)) {
            $indent = ($_ =~ /^(\s*)/)[0];
            print STDERR "    In zrancid::_generic: Initial indent = <$indent>\n";
        }

        next if _dels($_, $_options{dels});

        if (defined($skipping_until)) {
            $skipping_until = 0 if ($skipping_until && /$_options{skip_until}/);
            next if ($skipping_until);
        }

        $output = _subs($_, $_options{subs});
        print($OUTPUT $_options{prefix}.$output);
    }

    print($OUTPUT "$_options{comment}\n");
    return 0;
}

sub config {
    return _generic(@_, ( 'is_config' => 1 ));
}
sub comment {
    return _generic(@_, ( 'prefix' => $options{comment} ));
}

sub inloop {
    my($INPUT, $OUTPUT) = @_;
    my($cmd, $rval);

    if (defined($options{inloop_pre_hook})) {
        my $stop = 0;
        ($INPUT, $OUTPUT, $stop) = $options{inloop_pre_hook}(@_);
        return if ($stop);
    }

    if ($options{devtype}) {
        ProcessHistory("", "", "", "$options{comment}RANCID-CONTENT-TYPE: $devtype\n".
                                   "$options{comment}\n");
    }

TOP:
    while(<$INPUT>) {
        print STDERR ("TOP: $_") if ($debug);
        tr/\015//d;
        if (/[$options{prompt}]\s*($options{clean_run})\s*$/) {
            $clean_run = 1;
            last;
        }
        if (/^Error:/) {
            print STDOUT ("$host login script error: $_");
            print STDERR ("$host login script error: $_") if ($debug);
            $clean_run = 0;
            last;
        }
        while (/[$options{prompt}]\s*($cmds_regexp)\s*$/) {
            $cmd = $1;
            if (!defined($prompt)) {
                # ^<not-prompt-chars>+<not-prompt-chars>
                $prompt = ($_ =~ /^([^$options{prompt}]+[$options{prompt}])/)[0];
                $prompt =~ s/([][}{)(+\\])/\\$1/g;
                print STDERR ("PROMPT MATCH: $prompt\n") if ($debug);
            }

            print STDERR ("HIT COMMAND: $_") if ($debug);

            # ignore empty prompt lines with no command
            if ($cmd =~ /^$options{comment} ignore me.*/) {
                print STDERR ("SKIP IGNORE COMMAND\n") if ($debug);
                next TOP;
            }

            if (!defined($commands{$cmd})) {
                print STDERR "$host: found unexpected command - \"$cmd\"\n";
                $clean_run = 0;
                last TOP;
            }
            if (!defined(&{$commands{$cmd}})) {
                printf(STDERR "$host: undefined function - \"%s\"\n", $commands{$cmd});
                $clean_run = 0;
                last TOP;
            }
            $rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
            delete($commands{$cmd});
            if ($rval == -1) {
                $clean_run = 0;
                last TOP;
            }
        }
    }

    # cleanup ignored commands, if any left, those are not required
    foreach $cmd (keys %commands) {
        if ($cmd =~ /^$options{comment} ignore me.*/) {
            delete($commands{$cmd});
        }
    }
}

return 1;
