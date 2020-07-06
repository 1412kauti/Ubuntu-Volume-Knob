# Ubuntu-Volume-Knob
Reprograming an Inexpensive USB Volume Knob on Ubuntu

## The Homework
Getting the devices like the Surface Dial in Ubuntu is a hastle, So I got this inexpensive USB Volume Knob in EBay for about 25$.

By default, The Volume knob functions as its supposed to, turning the wheel to change the volume by increment/decreemnts of 2 units per ratcheted rotation and a single button press to mute/unmute the Device.

My device had an STM32 MicroController and I know that the functions can be remapped, and thus I hit my first road block. I could do 2 things

 1. Solder a few jumper wires to the Pins and Bypass the Write-Protection
 2. Bypass the write protection by remapping the Output on a per-device basis

## A Detailed Explaination

As the Device is recognized in the system, We can check its basic functionality i.e. Volume Up, Volume Down and Mute.

I had a few issues recognizing the device using lsusb, I had to run the command once with the device unplugged and arun it again to find my device.

In my case the device was as follows:
```
0483:572d STMicroelectronics
```

I wanted some more details about my little aluminium knob, so I used the ```cat``` command at ```proc/bus/input/devices```
```
$ cat /proc/bus/input/devices

I: Bus=0003 Vendor=0483 Product=572d Version=0111
N: Name="STMicroelectronics USB Volume Control"
P: Phys=usb-0000:00:14.0-5.2/input0
S: Sysfs=/devices/pci0000:00/0000:00:14.0/usb1/1-5/1-5.2/1-5.2:1.0/0003:0483:572D.0008/input/input13
U: Uniq=2042353B5852
H: Handlers=kbd event12 
B: PROP=0
B: EV=13
B: KEY=3800000000 108000000000 4000000000000
B: MSC=10
```

from here,I could recognise my device from the leist of devices currently connected to my computer , in this case "STMicroelectronics USB Volume Control".

The important snippets of code required are:

1. The device vendor for my device is 0483 (the “I:” line).
2. The product ID for my device is 572d (also on the “I:” line).
2. The device is attached on /dev/input/event12 (on the “H:” line).

Now run the keylogging tool( of sorts) called ```evtest```.
If you don't have evtest installed, DuckDuckGo is your best friend, just kidding.

Install it with:
```
sudo apt-get install evtest
```
Now to know what kind of inputs the Knob can take.
run evtest on the devices' runnning instance, in this case event12.
```
sudo evtest /dev/input/event12
```
now rotate the the knob once to clockwise, then once to anticlockwise, and press the beatiful aluminium knob once. We can see 3 inputs , their MSC_SCAN values and their outputs.

By default it should look something like this.
```
Event: time 1594052623.421147, type 4 (EV_MSC), code 4 (MSC_SCAN), value c00ea
Event: time 1594052623.421147, type 1 (EV_KEY), code 103 (KEY_VOLUMEDOWN), value 0
Event: time 1594052623.421147, -------------- SYN_REPORT ------------
Event: time 1594052628.741172, type 4 (EV_MSC), code 4 (MSC_SCAN), value c00e9
Event: time 1594052628.741172, type 1 (EV_KEY), code 108 (KEY_VOLUMEUP), value 1
Event: time 1594052628.741172, -------------- SYN_REPORT ------------
Event: time 1594052628.749228, type 4 (EV_MSC), code 4 (MSC_SCAN), value c00e9
Event: time 1594052628.749228, type 1 (EV_KEY), code 108 (KEY_VOLUMEUP), value 0
Event: time 1594052628.749228, -------------- SYN_REPORT ------------
Event: time 1594052630.221247, type 4 (EV_MSC), code 4 (MSC_SCAN), value c00e2
Event: time 1594052630.221247, type 1 (EV_KEY), code 50 (KEY_MUTE), value 1
Event: time 1594052630.221247, -------------- SYN_REPORT ------------
Event: time 1594052630.237224, type 4 (EV_MSC), code 4 (MSC_SCAN), value c00e2
Event: time 1594052630.237224, type 1 (EV_KEY), code 50 (KEY_MUTE), value 0
Event: time 1594052630.237224, -------------- SYN_REPORT ------------
```
If your keen eyed, you can see that the knob can take even more inputs.
May the Force be with you, if you ever manage to figure out how to use em.

From the above output, We can makeout some interesting stuff, like:
1. When I turn the knob to the right, I get an MSC_SCAN event of type c00e9 (along with a KEY_VOLUMEUP event)
2. When I turn the knob to the left, I get an MSC_SCAN event of type c00ea (along with a KEY_VOLUMEDOWN event)
3. When I push on the knob, I get an MSC_SCAN event of type c00e2 (along with a KEY_MUTE event)

Now that I have my info, its hardware hacking time, All we have to do is to remap the MSC_SCAN values of all three of the inputs from the defaults to whatever we wnat.
But (with a Big B)
The device is write protected and its setup in such a way that it doesnt come with a configuration file.
Hence, we shall create our own config.

I named it ```99-usb-knob.hwdb``` and its stored at ```/etc/udev/hwdb.d/```.
Within this file, the contents were:
```
evdev:input:b*v0483p572D*
 KEYBOARD_KEY_c00ea=left
 KEYBOARD_KEY_c00e9=right
 KEYBOARD_KEY_c00e2=esc
```
We can recognize the vendor(0483) and the device (572d) from the earlier commands.

Here, we have remapped the MSC_SCAN values from the knobs inputs and remapped to what I use it for, Yeah I know , I'm a lazy geek to use a knob for side scrolling.

You can find all the other valid keycommands here:
https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h

Now that the mapping is done, we can use the following commands to update the hardware database.
```
sudo systemd-hwdb update
sudo udevadm trigger
```
Although the knob has now been setup to do our bidding, there's one major problem, The knob's new inputs are not recognized as keyboard inputs, so
I created a rules file just to mitigate that. A new USB rule has to set in.

I named it ```99-usb-knob.rules``` and have stored it at ```etc/udev/rules.d/```
The contents of this file are as follows:
```
ACTION=="add|change", KERNEL=="event[0-9]*", 
 ATTRS{idVendor}=="0483", ATTRS{idProduct}=="572d",
 ENV{ID_INPUT_KEYBOARD}="1"
 ```
 
 Now everything is basically Setup.
 But (With a Bigger B)

 plug out the knob from the PC end and replug it.

 ### It does not work by just unplugging the micro-usb end and repluging it.

## For the Lazy Folks

Just Clone this repository, and run the ```install.sh``` script

```
git clone https://github.com/1412kauti/Ubuntu-Volume-Knob.git
cd /Ubuntu-Volume-Knob
chmod +x install.sh
sudo ./install.sh
```
Post install, if you wanna edit the config, run the ```edit-config.sh``` script.

Use this link to find all the valid keys, and use a similar cofig as whats already there.
https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
```
chmod +x edit-config.sh
sudo ./edit-config.sh
```
This script uses nano by default, feel free to change your editor.

## Note
VS-Code users, add ```--user-data-dir``` along with changing ```nano``` to ```code```.

Now the Finale'
plug out the knob from the PC end, replug it and

Voila