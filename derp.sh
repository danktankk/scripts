#!/bin/bash

# Get the current date in MM-DD-YYYY format
current_date=$(date "+%m-%d-%Y")

# Calculate the date 30 days ahead
new_date=$(date -d "$current_date + 30 days" "+%m-%d-%Y")

echo "Current Date: $current_date"
echo "New Date: $new_date"
