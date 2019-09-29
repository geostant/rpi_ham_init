# Raspberry Pi for Ham Radio
I operate only portable and tend to do a lot of FT8
Since I upgrade and replace my Raspberry Pis very often and I don't want to
have an image that include it all pre-made (as far as I know cloning SD card will capture the whole card, hence an image will be 32-64G!)

In addition,
When I re-install it all from scratch I get the latest versions, so it's another pro.

I recommend using the latest Raspberry Pi unit (current 4) with the max RAM (currently 4G) as we use the desktop version.

## This shell script will install and configure the following
- Direwolf
- WSJT-X
- RaspAP

# How to apply?
On a new Rpi run<br>
`cd ~ && git clone https://github.com/geostant/rpi_ham_init.git && cd rpi_ham_init`<br>
`./install.sh`
