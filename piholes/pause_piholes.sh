#!/bin/bash

# This will show you your hashed password – Shell into your pihole instance
# Copy and paste everything after the = and append it to the end of the URL above.
# cat /etc/pihole/setupVars.conf |grep WEBPASSWORD
# Then just add you ip and add the hashed password to AUTH_TOKEN.
# Dont forgot to make it executable!

# Pi-hole API URLs and authentication tokens
API_URL_1="http://192.168.1.51/admin/api.php?disable=300&auth="
AUTH_TOKEN_1="=d9303b5929b8e5952626661f1fec70ebaf252ca4a165fd1a546e0e60cb07d7c3"

API_URL_2="http://192.168.1.51/admin/api.php?disable=300&auth"
AUTH_TOKEN_2="=d9303b5929b8e5952626661f1fec70ebaf252ca4a165fd1a546e0e60cb07d7c3"

# Duration for which to pause Pi-hole in seconds (300 seconds = 5 minutes)
PAUSE_DURATION=300

pause_pihole() {
    local api_url="$1"
    local auth_token="$2"
    local result
    result=$(curl -s "${api_url}?disable=${PAUSE_DURATION}&auth=${auth_token}")

    if [ $? -eq 0 ]; then
        # Display a notification if the Pi-hole was successfully paused
        notify-send "Pi-hole Paused" "Pi-hole at $api_url is paused for ${PAUSE_DURATION} seconds." --hint=int:y:400 --app-name="$unique_id1"
    else
        # Display a notification if pausing the Pi-hole failed
        notify-send "Pi-hole Pause Failed" "Failed to pause Pi-hole at $api_url." --hint=int:y:200 --app-name="$unique_id2"
    fi
}

# Pause the first Pi-hole instance
pause_pihole "$API_URL_1" "$AUTH_TOKEN_1"

# Pause the second Pi-hole instance
pause_pihole "$API_URL_2" "$AUTH_TOKEN_2"
