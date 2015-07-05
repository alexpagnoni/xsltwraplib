#!/bin/bash

WHERE=`pwd`

if [ -a .encoded ]; then
  TGZ_NAME="xsltwraplib-enc-1.0.0.tgz"
  DIR_NAME="xsltwraplib-enc"
else
  TGZ_NAME="xsltwraplib-1.0.0.tgz"
  DIR_NAME="xsltwraplib"
fi

cd ..
tar -cvz --exclude=OLD --exclude=*~ --exclude=CVS --exclude=.?* --exclude=np --exclude=.cvsignore -f $TGZ_NAME $DIR_NAME
cd $WHERE
