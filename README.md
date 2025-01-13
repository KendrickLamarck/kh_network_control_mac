# kh_network_control_mac

Mac app to control Neumann KH series speakers over the network.

Currently, this is just a simple menu bar app offering volume control. Uses local python and https://github.com/schwinn/khtool. More parameters and a more portable app bundle might come in the future.

## Installation (in theory):

Prerequisites:

* Install Xcode
* Make sure you have python3

**Note:** You can use a different main path (for auxiliary files), python executable and khtoolPath, but if you do, you have to change the variables in `init()` in `ContentView.swift`.

Create a directory in your home directory. The default is `~/code/kh_120`. Clone the dependencies into this directory:

``` sh
cd ~/code/kh_120
git clone git@github.com:schwinn/khtool.git
git clone git@github.com:KendrickLamarck/kh_network_control_mac.git
```

Now create a python venv in the directory and install the necessary python library:

``` sh
python3 -m .venv
source .venv/bin/activate
pip install install https://github.com/schwinn/pyssc/archive/master.zip#egg=pyssc
```

Now open `KH Volume slider.xcodeproj` in Xcode, build and run the app.

I can imagine the last step won't work because of code signage/ownership issues or something.
