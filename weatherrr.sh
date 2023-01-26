#!/bin/bash

# Default location
location="Warszawa"

# Fahrenheit flag
fahrenheit=false

# Dynamic update flag
dynamic=false

# API key
apikey=XXX

# Temporary data directory
temp_dir="/tmp/weather"

# Create temporary data directory if it doesn't exist
if [ ! -d "$temp_dir" ]; then
    mkdir "$temp_dir"
fi

# Process command line options
while getopts ":l:df" opt; do
  case $opt in
    l) location="$OPTARG" ;;
    d) dynamic=true ;;
    f) fahrenheit=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1 ;;
  esac
done

# Function to retrieve weather data
function get_weather() {
    # Check if data is already available in the temporary directory
    if [ -f "$temp_dir/$location" ]; then
        # Check if data is less than 5 minutes old
        if [ $(($(date +%s) - $(date +%s -r "$temp_dir/$location"))) -lt 300 ]; then
            # Use the data from the temporary file
            weather_data=$(cat "$temp_dir/$location")
        else
            # Retrieve new data from API
            weather_data=$(curl "api.weatherstack.com/current?access_key=$apikey&query=$location")
            # Save data to temporary file
            echo "$weather_data" > "$temp_dir/$location"
        fi
    else
        # Retrieve new data from API
        weather_data=$(curl "api.weatherstack.com/current?access_key=$apikey&query=$location")
        # Save data to temporary file
        echo "$weather_data" > "$temp_dir/$location"
    fi

    # Parse data using jq
    temp=$(echo "$weather_data" | jq '.current.temperature')
    condition=$(echo "$weather_data" | jq '.current.weather_descriptions' | awk '{print substr ($0, 3 ) }' )
    # Convert to Fahrenheit if flag is set
    if $fahrenheit; then
        temp=$(echo "scale=2; ($temp * 9/5) + 32" | bc)
        temp="$temp F"
    else
        temp="$temp C"
    fi

    # Print the data
    echo "Temperature in $location: $temp"
    echo "Weather condition: $condition"
}

# Call the function to get the weather
get_weather

# Loop to update weather data every 5 minutes if -d option is set
if $dynamic; then
    while true; do
        get_weather
        sleep 300
    done
fi
