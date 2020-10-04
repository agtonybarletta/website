#!/bin/bash
http-server . & sleep 0.5 && xdotool search -name ".*Firefox.*" key F5
