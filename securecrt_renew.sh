#!/bin/bash

# Get the current date in MM-DD-YYYY format
current_date=$(date "+%m-%d-%Y")

# Calculate the date 30 days ahead
new_date=$(date -d "30 days" "+%m-%d-%Y")

# Set the path to your file
file_path="/home/dankk/.vandyke/SecureFX/Config/SecureCRT_eval.lic"

# Update lines 4 and 5 in the file
sed -i "4s/Expiration: .*/Expiration: $new_date/" "$file_path"
sed -i "5s/Issue Date: .*/Issue Date: $current_date/" "$file_path"
