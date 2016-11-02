#!/bin/bash

curl -L -u blzq-mu:21d7e8d40db1924d92576e1f70f11cc9e6e2a807 \
https:/github.com/blzq/strange-references-mirror/archive/master.zip \
> strange-references.zip
unzip strange-references.zip

mv strange-references-mirror-master strange-references

