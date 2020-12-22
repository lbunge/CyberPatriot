#!/bin/sh
echo "id is: " $(id) >> /tmp/myScript.txt
echo "this has been written via cloud-init" + $(date) >> /tmp/myScript.txt