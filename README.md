# Wipeout - Fast, secure, interactive disk erase utility

This utility quickly and securely erases a device (hard drive) that implements 
the ATA Secure Erase capablity.

Features include:

* Automatic discovery of device to erase.
* Verifies device supports ATA Secure Erase feature.
* Interactive confirmation of erase.
* Read-back after erase to verify successful wipe.
* Fast. (My test 240GB SSD completes in less than a minute.)


Information on the ATA Secure Erase feature here: 
https://ata.wiki.kernel.org/index.php/ATA_Secure_Erase

Latest version of this utility here: https://github.
com/courtney-rosenthal/wipeout

## Instructions

* Initially device (hard drive) is not connected to the system.
* Start up the program with _root_ privileges.
* Connect the hard drive to the system.
* Wait a few seconds for the device to be recognized.
* Confirm the erase can proceed.

Here is an example run:

    $ sudo ./wipeout.rb

    Insert drive now .......... done!
    Detected device = /dev/sdc
      Model Number: INTEL SSDSC2CW240A3
      Estimated erase time: 4min

    Current partition table:
      Disk /dev/sdc: 223.57 GiB, 240057409536 bytes, 468862128 sectors
      Disk model: DSC2CW240A3     
      Units: sectors of 1 * 512 = 512 bytes
      Sector size (logical/physical): 512 bytes / 512 bytes
      I/O size (minimum/optimal): 512 bytes / 512 bytes
      Disklabel type: dos
      Disk identifier: 0x997b5757
      
      Device     Boot Start       End   Sectors   Size Id Type
      /dev/sdc1        2048 468862127 468860080 223.6G 83 Linux

    THIS DEVICE IS ABOUT TO BE COMPLETELY ERASED !!!
    Proceed to erase /dev/sdc? (yes/no) : yes

    + hdparm --user-master u --security-set-pass secretPassword /dev/sdc
    security_password: "secretPassword"

    /dev/sdc:
    Issuing SECURITY_SET_PASS command, password="secretPassword", user=user, mode=high
    + hdparm --user-master u --security-erase secretPassword /dev/sdc
    security_password: "secretPassword"

    /dev/sdc:
     Issuing SECURITY_ERASE command, password="secretPassword", user=user
    Wipe command has completed.

    Confirming wipe was successful ... stand by ~30 seconds ...
    Wipe is successful!

<address>
---<br />
Courtney Rosenthal<br />
cr@crosenthal.com
</address>