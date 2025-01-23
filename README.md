# kh_network_control_mac

Mac app to control Neumann KH series speakers over the network.

Currently, this is just a simple menu bar app offering volume control. Uses local python and https://github.com/schwinn/khtool. More parameters and a more portable app bundle might come in the future.

## Installation (in theory):

Prerequisites:

* Install Xcode
* Make sure you have `python3` available in the terminal.

**Note:** You can change the python executable path in the settings.

Clone the project. Find out the network interface your speakers are connected via. If it's not `en0`, change it in the settings.

Now open `KH Volume slider.xcodeproj` in Xcode, build and run the app. At this point we probably get stuck because of code signage/ownership issues or something.
