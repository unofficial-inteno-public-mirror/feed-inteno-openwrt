#!/bin/sh

# function
# param: filename
# Parses a openvpn conf file and writes /etc/confif/openvpn
openvpn_conf_from_gui() {
        file=$1

        [ -f "$file" ] || return

        cafile=$(dirname $file)"/openvpn-ca.crt"
        certfile=$(dirname $file)"/openvpn-client.crt"
        keyfile=$(dirname $file)"/openvpn-client.key"

        # remove carriage return
        sed -i 's/\r//' $file

        local name="" enabled=0
        local remotes proto dev
        local auth_user auth_pass ns_cert_type tls_auth
        local resolv_retry comp_lzo
        local nobind persist_tun persist_key
        local verb mute mute_replay_warnings

        # ###
        # parse the options
        # ###

        while read line; do
                opt=${line%% *}
                arg=${line#* }
                [ -z "$opt" ] && continue

                case "$opt" in

                        client)
                                name="client"
                                enabled=1;
                                ;;
                        remote)
                                remotes=${remotes:+"$remotes"$'\n'}"$arg";
                                ;;
                        proto)
                                proto=$arg
                                ;;
                        dev)
                                dev=$arg
                                ;;

                        auth-user)
                                auth_user=$arg
                                ;;
                        auth-pass)
                                auth_pass=$arg
                                ;;
                        auth-user-pass)
                                # ignore this
                                ;;

                        auth)
                                auth=$arg
                                ;;
                        cipher)
                                cipher=$arg
                                ;;
                        ns-cert-type)
                                ns_cert_type=$arg
                                ;;
                        tls-auth)
                                tls_auth=$arg
                                ;;

                        resolv-retry)
                                resolv_retry=$arg
                                ;;
                        comp-lzo)
                                comp_lzo=yes
                                ;;

                        nobind)
                                nobind=1
                                ;;
                        persist-tun)
                                persist_tun=$arg
                                ;;
                        persist-key)
                                persist_key=$arg
                                ;;
                        verb)
                                verb=$arg
                                ;;
                        mute)
                                mute=$arg
                                ;;
                        mute-replay-warnings)
                                mute_replay_warnings=1
                                ;;

                        "<ca>")
                                write_ca=1
                                echo $line > $cafile
                                ;;
                        "</ca>")
                                echo $line >> $cafile
                                write_ca=0;
                                ;;
                        "<cert>")
                                write_cert=1
                                echo $line > $certfile
                                ;;
                        "</cert>")
                                echo $line >> $certfile
                                write_cert=0;
                                ;;
                        "<key>")
                                write_key=1
                                echo $line > $keyfile
                                ;;
                        "</key>")
                                echo $line >> $keyfile
                                write_key=0;
                                ;;

                        *)
                                [ "$write_ca" == "1" ] && echo $line >> $cafile
                                [ "$write_cert" == "1" ] && echo $line >> $certfile
                                [ "$write_key" == "1" ] && echo $line >> $keyfile
                                ;;
                esac

        done < $file

        [ -n "$name" ] || return
        [ "$enabled" == "1" ] || return

        # ###
        # write the options in uci
        # ###

        ubus call uci delete '{"config":"openvpn", "type":"openvpn"}'
        uci commit openvpn

        uci set openvpn.$name=openvpn
        uci set openvpn.$name.enabled="1"
        uci set openvpn.$name.client="1"

        [ -n "$dev" ] &&                uci set openvpn.$name.dev="$dev"
        [ -n "$proto" ] &&              uci set openvpn.$name.proto="$proto"

        while read remote; do
                [ -n "$remote" ] &&     uci add_list openvpn.$name.remote="$remote"
        done <<-EOF
		$remotes
		EOF

        [ -n "$auth_user" ] &&          uci set openvpn.$name.auth_user="$auth_user"
        [ -n "$auth_pass" ] &&          uci set openvpn.$name.auth_pass="$auth_pass"

        [ -n "$auth" ] &&               uci set openvpn.$name.auth="$auth"
        [ -n "$cipher" ] &&             uci set openvpn.$name.cipher="$cipher"
        [ -n "$ns_cert_type" ] &&       uci set openvpn.$name.ns_cert_type="$ns_cert_type"
        [ -n "$tls_auth" ] &&           uci set openvpn.$name.tls_auth="$tls_auth"

        [ -n "$resolv_retry" ] &&       uci set openvpn.$name.resolv_retry="$resolv_retry"
        [ -n "$comp_lzo" ] &&           uci set openvpn.$name.comp_lzo="$comp_lzo"

        [ -n "$nobind" ] &&             uci set openvpn.$name.nobind="$nobind"
        [ -n "$persist_tun" ] &&        uci set openvpn.$name.persist_tun="$persist_tun"
        [ -n "$persist_key" ] &&        uci set openvpn.$name.persist_key="$persist_key"
        [ -n "$verb" ] &&               uci set openvpn.$name.verb="$verb"
        [ -n "$mute" ] &&               uci set openvpn.$name.mute="$mute"
        [ -n "$mute_replay_warnings" ] && uci set openvpn.$name.mute_replay_warnings="$mute_replay_warnings"

        [ -f "$cafile" ] &&             uci set openvpn.$name.ca="$cafile"
        [ -f "$certfile" ] &&           uci set openvpn.$name.cert="$certfile"
        [ -f "$keyfile" ] &&            uci set openvpn.$name.key="$keyfile"

        uci commit openvpn
}

openvpn_conf_from_gui $@
