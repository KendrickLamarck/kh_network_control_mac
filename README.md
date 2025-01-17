# kh_network_control_mac

Mac app to control Neumann KH series speakers over the network.

Currently, this is just a simple menu bar app offering volume control. Uses local python and https://github.com/schwinn/khtool. More parameters and a more portable app bundle might come in the future.

## Installation (in theory):

Prerequisites:

* Install Xcode
* Make sure you have python3

**Note:** You can use a different python executable path, but if you do, you have to change the variable `pythonPath` in `KH Volume slider/Sources/KHAccess.swift`.

Create a directory in your home directory. The default is `~/code/kh_120`. Clone the project into this directory:

``` sh
mkdir -p ~/code/kh_120
cd ~/code/kh_120
git clone git@github.com:KendrickLamarck/kh_network_control_mac.git
```

Now create a python venv in the directory and install the necessary python library:

``` sh
python3 -m venv .venv
source .venv/bin/activate
pip install https://github.com/schwinn/pyssc/archive/master.zip#egg=pyssc
```

Make sure the network interface assumed by the GUI is correct:

``` sh
python khtool/khtool.py -i en0 -q
```

This command should produce some output. If not, you need to find out the correct interface name and change the `networkInterface` variable in `KH Volume slider/Sources/KHAccess.swift`.

Now open `KH Volume slider.xcodeproj` in Xcode, build and run the app. At this point we probably get stuck because of code signage/ownership issues or something.
