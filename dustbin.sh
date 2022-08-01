#!/bin/bash
# Publish dustbin state by watching a log written by the RobotController
# WORK IN PROGRESS

# TODO query http://rockrobo/api/v2/valetudo/config/interfaces/mqtt (.host)
MQTT_HOST=10.0.0.2
# TODO query http://rockrobo/api/v2/valetudo/config/interfaces/mqtt (.identity.identifier)
MQTT_TOPIC=valetudo/identifier/AttachmentStateAttribute/dustbin

WATCH_LOG=/var/run/shm/EVENTTASK_normal.log

# TODO json parsing https://github.com/fkalis/bash-json-parser or just sed/awk/grep/whatever
# TODO mqtt client https://github.com/raphaelcohn/bish-bosh

tail -0f "$WATCH_LOG" |grep --color=never --line-buffered -E ".*GetEvent:.*(RE_Mcu_Bin).*" |grep --color=never --line-buffered -E -o "BinIn|BinOut" |
while read line; do
    if [[ "$line" == "BinIn" ]]; then
        PAYLOAD="true"
    elif [[ "$line" == "BinOut" ]]; then
        PAYLOAD="false"
    else
        continue
    fi
    mosquitto_pub -d -h "$MQTT_HOST" -t "$MQTT_TOPIC" -m "$PAYLOAD"
done
