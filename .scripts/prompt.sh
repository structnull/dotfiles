#!/bin/bash

cmd=$(rofi -dmenu "Input your prompt")

result=$(engine.sh "$cmd")


