#!/bin/bash

# Script to calculate average CPU temperature and output JSON for Waybar

# --- Configuration ---
default_icon="" # Normal temperature icon (e.g., thermometer three-quarters)
critical_icon="" # Critical temperature icon (e.g., thermometer full, or a fire icon 🔥)
critical_threshold=80 # Degrees Celsius

# --- Logic ---
total_temp=0
core_count=0
class_name="normal" # Default CSS class

# (The hwmon discovery logic remains the same as before)
for hwmon_path in /sys/class/hwmon/hwmon*/; do
    if [ -f "${hwmon_path}name" ] && (grep -qi "coretemp" "${hwmon_path}name" || grep -qi "k10temp" "${hwmon_path}name" || grep -qi "zenpower" "${hwmon_path}name"); then
        for temp_input_file in $(find "$hwmon_path" -name "temp*_input"); do
            label_file="${temp_input_file/_input/_label}"
            is_cpu_temp=false
            if [ -f "$label_file" ]; then
                label_content=$(cat "$label_file")
                if [[ "$label_content" == "Package id "* || "$label_content" == "Core "* || "$label_content" == "Tdie" || "$label_content" == "Tctl" ]]; then
                    is_cpu_temp=true
                fi
            else
                is_cpu_temp=true # Assume relevant if no label under CPU hwmon
            fi

            if $is_cpu_temp && [ -f "$temp_input_file" ]; then
                raw_temp=$(cat "$temp_input_file")
                if [[ "$raw_temp" =~ ^[0-9]+$ ]]; then
                    actual_temp_c=$((raw_temp / 1000))
                    total_temp=$((total_temp + actual_temp_c))
                    core_count=$((core_count + 1))
                fi
            fi
        done
    fi
done

if [ "$core_count" -gt 0 ]; then
  average_temp_c=$((total_temp / core_count))

  # --- Determine icon and class based on temperature ---
  current_icon="$default_icon"
  if [ "$average_temp_c" -ge "$critical_threshold" ]; then
    current_icon="$critical_icon"
    class_name="critical"
  fi

  # --- Optional: Still apply the -5 degree visual adjustment if desired ---
  # display_temp_c=$((average_temp_c - 5))
  # text_output="${current_icon} ${display_temp_c}°C"

  # Displaying the actual average temperature
  text_output="${current_icon} ${average_temp_c}°C"

  # --- Output JSON for Waybar ---
  printf '{"text": "%s", "class": "%s", "tooltip": "Avg CPU Temp: %s°C"}\n' \
    "$text_output" \
    "$class_name" \
    "$average_temp_c"
else
  # Fallback if no CPU temperatures found
  printf '{"text": "%s N/A", "class": "unknown", "tooltip": "CPU Temperature N/A"}\n' "$default_icon"
fi
