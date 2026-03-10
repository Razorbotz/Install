#!/bin/bash

mv setup_can_gateway.sh /usr/local/bin/
mv can-gateway.service /etc/systemd/system/
systemctl enable can-gateway.service
systemctl start can-gateway.service