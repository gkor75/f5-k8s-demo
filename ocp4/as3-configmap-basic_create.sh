#!/bin/bash
oc create configmap -n static-as3 --from-file=template=./as3-configmap-basic.json f5demo-as3-configmap
oc label configmap f5demo-as3-configmap f5type=virtual-server as3=true