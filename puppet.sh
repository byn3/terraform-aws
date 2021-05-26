#!/bin/sh
# debian family example; swap out 'apt' and package names where necessary
# prep puppet
sudo apt-get update && sudo apt-get install ruby -y
sudo gem install --no-document puppet
# apply puppet
