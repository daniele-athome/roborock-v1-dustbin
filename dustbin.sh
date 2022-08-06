#!/bin/bash
# Publish dustbin state by watching a log written by the RobotController
# Dependencies:
# - mosquitto_pub (package: mosquitto-clients)
# - jq (package: jq)

# configuration data - it SHOULDN'T need to be modified
VALETUDO_CONFIG=/mnt/data/valetudo_config.json
WATCH_LOG=/var/run/shm/EVENTTASK_normal.log

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 1; }
try() { "$@" || die "cannot $*"; }
check_for() { which "$@" >/dev/null || die "Unable to locate $*"; }

check_for mosquitto_pub
check_for jq

[[ -f "$VALETUDO_CONFIG" ]] || die "Valetudo configuration not found."
[[ -f "$WATCH_LOG" ]] || die "RobotController log file not found."

MQTT_HOST="$(jq -r .mqtt.connection.host < "$VALETUDO_CONFIG")"
MQTT_PORT="$(jq -r .mqtt.connection.port < "$VALETUDO_CONFIG")"
# TODO MQTT TLS settings
# TODO MQTT authentication data
MQTT_TOPIC="valetudo/$(jq -r .mqtt.identity.identifier < "$VALETUDO_CONFIG")/AttachmentStateAttribute/dustbin"

tail -0f "$WATCH_LOG" |
  grep --line-buffered -E ".*GetEvent:.*(RE_Mcu_Bin).*" |
  grep --line-buffered -E -o "BinIn|BinOut" |
while read -r line; do
    if [[ "$line" == "BinIn" ]]; then
        PAYLOAD="true"
    elif [[ "$line" == "BinOut" ]]; then
        PAYLOAD="false"
    else
        yell "Unexpected string found in log: <$line>"
        continue
    fi
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -r -t "$MQTT_TOPIC" -m "$PAYLOAD"
done
