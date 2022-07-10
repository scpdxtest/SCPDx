#!/bin/bash
DATADIR="./bootbios"
PRIVKEY="your_producer_private_key"
PUBKEY="your_producer_public_key"
PRODNAME="your_producer_name"
HTTPSRVADDR="your_http_server_address"
SRVPORT="your_http_server_port"
LISTENADDR="your_p2p_listen_endpoint_address"
P2PPEERADDR="peer_address"
if [ ! -d $DATADIR ]; then  mkdir -p $DATADIR;
fi
nodeos -e \
--genesis-json $DATADIR"/genesis.json" \
--signature-provider $PUBKEY=KEY:$PRIVKEY \
--producer-name $PRODNAME \
--plugin eosio::producer_plugin \
--plugin eosio::producer_api_plugin \
--plugin eosio::chain_plugin \
--plugin eosio::chain_api_plugin \
--plugin eosio::http_plugin \
--plugin eosio::history_api_plugin \
--plugin eosio::history_plugin \
--data-dir $DATADIR"/data" \
--blocks-dir $DATADIR"/blocks" \
--config-dir $DATADIR"/config" \
--http-server-address $HTTPSRVADDR \
--p2p-listen-endpoint $LISTENADDR \
--producer-threads 20 \
--txn-reference-block-lag 0 \
--p2p-max-nodes-per-host 150 \
--trace-history \
--trace-history-debug-mode \
--max-clients 150 \
--connection-cleanup-period 30 \
--access-control-allow-origin=* \
--contracts-console \
--http-validate-host=true \
--verbose-http-errors \
--allowed-connection "any" \
--sync-fetch-span 2000 \
--p2p-peer-address $P2PPEERADDR
cleos -u http://127.0.0.1:$SRVPORT system newaccount eosio --transfer $PRODNAME $PUBKEY --stake-net "100000000.0000 SYS" --stake-cpu "100000000.0000 SYS" --buy-ram-kbytes 8192
cleos -u http://127.0.0.1:$SRVPORT system regproducer $PRODNAME $PUBKEY
cleos -u http://127.0.0.1:$SRVPORT system listproducers
cleos -u http://127.0.0.1:$SRVPORT system voteproducer prods $PRODNAME $PRODNAME
cleos -u http://127.0.0.1:$SRVPORT system listproducers
cleos -u http://127.0.0.1:$SRVPORT push action eosio.token transfer '[ "eosio", "$PRODNAME", "1000.0000 SYS", "m" ]' -p eosio@active
