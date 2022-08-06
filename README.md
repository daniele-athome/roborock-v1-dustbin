Roborock Dustbin
================

Xiaomi Roborock 1st generation vacuum robot (`rockrobo.vacuum.v1`) [doesn't publish dustbin status](https://github.com/Hypfer/Valetudo/issues/1269#issuecomment-989857760) through its API.  

This shell script will watch a log file written by one of the original firmware processes for a special string that can
tell us when the dustbin is removed and put back into place. It will then publish a message to the standard Valetudo
attachment state MQTT topic `valetudo/<identifier>/AttachmentStateAttribute/dustbin` with a payload of either "true"
(dustbin installed) of "false" (dustbin removed).

## Installation

You will require a rooted vacuum robot with Valetudo already installed. You will also need to install with apt-get:

* mosquitto-clients (depends on libmosquitto0)
* jq

Copy `dustbin.sh` into `/usr/local/bin/dustbin` and give it execution permissions.

To start it at boot there is a sample upstart configuration file in `upstart/dustbin.conf` that should do the job
(although I just copied it from Valetudo and I didn't really know what I was doing :P). Place that into `/etc/init` and
reboot the robot.

## Internals

The log file we are watching is `/var/run/shm/EVENTTASK_normal.log`.

Whenever the dustbin is removed the following lines will appear:

```
51304923 T908 pRecvEventInternal:2182 [stat] IPCWrapper: received 76 bytes from 0x4, Id = 0x104001e(30)
51304923 T908 TransformPacketToEvent:1326 [stat] IPCWrapper: transformed Message ID 0x104001e as Event 0xb5100478(RE_Mcu_BinOut)
51304923 T908 ListenerRoutineInternal:1375 [stat] Queue: Listener push event 0xb5100478(RE_Mcu_BinOut) into MediumQ(Size = 0)
51304923 T895 GetEvent:2535 [stat] Queue: Pop event 0xb5100478(RE_Mcu_BinOut) from the MediumQ(Size = 0)
51304924 T895 main:1376 [stat] Processing Event 0xb5100478(21)
51304925 T909 DoSpeaker:200 [stat] Speaker /mnt/data/rockrobo/sounds/bin_out.wav, Volume 90
```

And the following after putting back the dustbin into place:

```
51308003 T908 pRecvEventInternal:2182 [stat] IPCWrapper: received 76 bytes from 0x4, Id = 0x104001e(30)
51308003 T908 TransformPacketToEvent:1326 [stat] IPCWrapper: transformed Message ID 0x104001e as Event 0xb5100478(RE_Mcu_BinIn)
51308003 T908 ListenerRoutineInternal:1375 [stat] Queue: Listener push event 0xb5100478(RE_Mcu_BinIn) into MediumQ(Size = 0)
51308003 T895 GetEvent:2535 [stat] Queue: Pop event 0xb5100478(RE_Mcu_BinIn) from the MediumQ(Size = 0)
51308003 T895 main:1376 [stat] Processing Event 0xb5100478(20)
51308004 T909 DoSpeaker:200 [stat] Speaker /mnt/data/rockrobo/sounds/bin_in.wav, Volume 90
```

What we do in the script is just tailing the log file and watching for those "RE_Mcu_Bin" strings.

MQTT connection data is read directly from Valetudo config file at `/mnt/data/valetudo_config.json`.
