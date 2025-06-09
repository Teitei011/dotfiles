#!/bin/bash
# Script to calculate average CPU temperature and output JSON for Waybar
# - More robust sensor detection and improved error handling -

# --- Configuration ---
icon_very_cold="❄️"      # Below 30°C
icon_cool="🌬️"            # 30–39°C
icon_mild="☁️"            # 40–49°C
icon_warm="☀️"            # 50–59°C
icon_hot="🔥"             # 60–69°C
icon_very_hot="☢️"        # 70–79°C
icon_critical="💀"        # 80°C and above
icon_error="⚠️"           # Error icon
critical_threshold=75    # Fixed threshold for critical

# --- Logic ---
total_temp=0
core_count=0
# Find all temperature sensor input files
sensor_paths=$(find /sys/class/hwmon/hwmon*/ -name "temp*_input")

for temp_input_file in $sensor_paths; do
    hwmon_path=$(dirname "$temp_input_file")
    # Check if the sensor name matches common CPU sensor names
    if [ -f "${hwmon_path}/name" ] && grep -qiE "coretemp|k10temp|zenpower|acpitz|pch_" "${hwmon_path}/name"; then
        if [ -f "$temp_input_file" ]; then
            raw_temp=$(cat "$temp_input_file")
            # Ensure the temperature reading is a valid number
            if [[ "$raw_temp" =~ ^[0-9]+$ ]]; then
                actual_temp_c=$((raw_temp / 1000))
                # Ignore readings that are clearly incorrect (e.g., 0°C or >120°C)
                if [ "$actual_temp_c" -gt 0 ] && [ "$actual_temp_c" -lt 120 ]; then
                    total_temp=$((total_temp + actual_temp_c))
                    core_count=$((core_count + 1))
                fi
            fi
        fi
    fi
done

# --- Output ---
if [ "$core_count" -gt 0 ]; then
  average_temp_c=$((total_temp / core_count))

  # Determine icon and class based on temperature
  if [ "$average_temp_c" -lt 30 ]; then
    current_icon="$icon_very_cold"; class_name="very-cold"
  elif [ "$average_temp_c" -lt 40 ]; then
    current_icon="$icon_cool"; class_name="cool"
  elif [ "$average_temp_c" -lt 50 ]; then
    current_icon="$icon_mild"; class_name="mild"
  elif [ "$average_temp_c" -lt 60 ]; then
    current_icon="$icon_warm"; class_name="warm"
  elif [ "$average_temp_c" -lt 70 ]; then
    current_icon="$icon_hot"; class_name="hot"
  elif [ "$average_temp_c" -lt "$critical_threshold" ]; then
    current_icon="$icon_very_hot"; class_name="very-hot"
  else
    current_icon="$icon_critical"; class_name="critical"
  fi

  # *** THIS IS THE MODIFIED LINE ***
  text_output="${current_icon} ${average_temp_c}°C"
  
  # The tooltip can remain more descriptive
  tooltip_output="Avg CPU Temp: ${average_temp_c}°C"

  # Output JSON for Waybar
  printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
    "$text_output" "$class_name" "$tooltip_output"
else
  # --- IMPROVED ERROR HANDLING ---
  # If no sensors were found, output a clear error message.
  printf '{"text": "%s CPU Error", "class": "critical", "tooltip": "Error: No valid CPU temperature sensor found in /sys/class/hwmon/"}\n' "$icon_error"
fi