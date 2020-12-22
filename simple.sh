#!/bin/sh
echo "id is: " $(id)
echo "this has been written via cloud-init" + $(date) >> /tmp/myScript.txt