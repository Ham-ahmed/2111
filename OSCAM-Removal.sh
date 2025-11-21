remove_oscam

#!/bin/sh
# Advanced OSCAM Removal Script

LOG_FILE="/tmp/oscam_removal.log"
echo "OSCAM Removal started at: $(date)" > $LOG_FILE

echo "=========================================="
echo "🛠️ Advanced OSCAM Removal Tool"
echo "=========================================="

# Check if user is root
if [ $(id -u) -ne 0 ]; then
    echo "❌ Error: This script must be run as root!"
    exit 1
fi

# Function to check if OSCAM is running
check_oscam() {
    if ps | grep -v grep | grep oscam > /dev/null; then
        echo "⚠️ OSCAM is currently running"
        return 0
    else
        echo "✅ OSCAM is not running"
        return 1
    fi
}

# Function to stop OSCAM
stop_oscam() {
    echo "⏳ Stopping OSCAM service..."
    killall -9 oscam 2>/dev/null
    sleep 2
    
    # Double check
    if check_oscam; then
        echo "❌ Failed to stop OSCAM, trying force kill..."
        killall -KILL oscam 2>/dev/null
        sleep 1
    fi
    
    if ! check_oscam; then
        echo "✅ OSCAM stopped successfully"
    else
        echo "❌ Warning: Could not stop OSCAM completely"
    fi
}

# Function to remove package
remove_package() {
    echo "📦 Checking for OSCAM packages..."
    
    # List all OSCAM related packages
    PACKAGES=$(opkg list-installed | grep -i oscam | cut -d' ' -f1)
    
    if [ -z "$PACKAGES" ]; then
        echo "ℹ️ No OSCAM packages found installed via opkg"
        return 0
    fi
    
    echo "Found packages: $PACKAGES"
    
    for pkg in $PACKAGES; do
        echo "🗑️ Removing package: $pkg"
        opkg remove $pkg >> $LOG_FILE 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Removed: $pkg"
        else
            echo "❌ Failed to remove: $pkg"
        fi
    done
}

# Function to clean residual files
clean_files() {
    echo "🧹 Cleaning up residual files..."
    
    # List of directories and files to remove
    DIRS_TO_REMOVE="
    /usr/bin/oscam*
    /etc/oscam*
    /usr/keys/oscam*
    /var/keys/oscam*
    /var/etc/oscam*
    /tmp/oscam*
    /var/tmp/oscam*
    /etc/init.d/softcam.oscam*
    /etc/rc0.d/*oscam*
    /etc/rc1.d/*oscam*
    /etc/rc2.d/*oscam*
    /etc/rc3.d/*oscam*
    /etc/rc4.d/*oscam*
    /etc/rc5.d/*oscam*
    /etc/rc6.d/*oscam*
    "
    
    for pattern in $DIRS_TO_REMOVE; do
        if [ -e $pattern ] || ls $pattern >/dev/null 2>&1; then
            echo "Removing: $pattern"
            rm -rf $pattern 2>/dev/null
        fi
    done
}

# Function to verify removal
verify_removal() {
    echo "🔍 Verifying removal..."
    
    local removed=true
    
    # Check if binary exists
    if [ -f "/usr/bin/oscam" ]; then
        echo "❌ OSCAM binary still exists!"
        removed=false
    fi
    
    # Check if package is still installed
    if opkg list-installed | grep -i oscam > /dev/null; then
        echo "❌ OSCAM packages still installed!"
        removed=false
    fi
    
    # Check if process is running
    if check_oscam; then
        echo "❌ OSCAM is still running!"
        removed=false
    fi
    
    if $removed; then
        echo "✅ OSCAM successfully removed!"
    else
        echo "⚠️ OSCAM removal may be incomplete"
    fi
}

# Main execution
main() {
    echo "Starting OSCAM removal process..."
    
    # Stop OSCAM
    stop_oscam
    
    # Remove packages
    remove_package
    
    # Clean files
    clean_files
    
    # Verify removal
    verify_removal
    
    echo ""
    echo "=========================================="
    echo "🎉 OSCAM removal process completed!"
    echo "📋 Log file: $LOG_FILE"
    echo "🔄 Please restart your receiver"
    echo "=========================================="
}

# Run main function
main