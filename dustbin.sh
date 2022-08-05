#!/bin/bash
# Publish dustbin state by watching a log written by the RobotController
# WORK IN PROGRESS

# very ugly way to retrieve information from Valetudo (we could probably read this from valetudo_config.json though)
MQTT_INFO="$(wget -q -O - http://rockrobo/api/v2/valetudo/config/interfaces/mqtt)"
#MQTT_INFO="$(cat /mnt/data/valetudo_config.json)"
MQTT_HOST="$(echo "$MQTT_INFO" | grep '"host":'| sed -E 's/.*"host":[ ]*"(.*?)".*/\1/' | cut -d'"' -f1)"
# FIXME doesn't work by reading from valetudo_config.json (property conflict)
MQTT_PORT="$(echo "$MQTT_INFO" | grep '"port":'| sed -E 's/.*"port":[ ]*(.*?).*/\1/' | cut -d',' -f1)"
MQTT_TOPIC="valetudo/$(echo "$MQTT_INFO" | grep '"identifier":'| sed -E 's/.*"identifier":[ ]*"(.*?)".*/\1/' | cut -d'"' -f1)/AttachmentStateAttribute/dustbin"

echo "HOST:<$MQTT_HOST>"
echo "PORT:<$MQTT_PORT>"
echo "TOPIC:<$MQTT_TOPIC>"

WATCH_LOG=/var/run/shm/EVENTTASK_normal.log

# TODO this should probably be a shellfire application... we would have MQTT and JSON modules.

# TODO json parsing https://github.com/fkalis/bash-json-parser or just sed/awk/grep/whatever
# TODO mqtt client https://github.com/raphaelcohn/bish-bosh

tail -0f "$WATCH_LOG" |
  grep --line-buffered -E ".*GetEvent:.*(RE_Mcu_Bin).*" |
  grep --line-buffered -E -o "BinIn|BinOut" |
while read -r line; do
    if [[ "$line" == "BinIn" ]]; then
        PAYLOAD="true"
    elif [[ "$line" == "BinOut" ]]; then
        PAYLOAD="false"
    else
        continue
    fi
    mosquitto_pub -d -h "$MQTT_HOST" -r -t "$MQTT_TOPIC" -m "$PAYLOAD"
done
