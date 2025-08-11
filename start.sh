*)
    echo "Starting gvmd & openvas in a single container !!"
    echo "single" > /usr/local/etc/running-as
    /scripts/single.sh "$@"

    echo "Waiting for gvmd to be ready..."
    until gvmd --get-users > /dev/null 2>&1; do
        sleep 5
    done

    # Create Low Risk Ports list
    if ! gvmd --get-port-lists | grep -q "Low Risk Ports"; then
        echo "Creating Low Risk Ports list..."
        gvmd --create-port-list="Low Risk Ports"
        gvmd --modify-port-list="Low Risk Ports" --add-port="53, tcp"
        gvmd --modify-port-list="Low Risk Ports" --add-port="123, udp"
        gvmd --modify-port-list="Low Risk Ports" --add-port="631, tcp"
        gvmd --modify-port-list="Low Risk Ports" --add-port="514, udp"
        gvmd --modify-port-list="Low Risk Ports" --add-port="9100, tcp"
    else
        echo "Low Risk Ports list already exists."
    fi

    # Get Port List ID
    PORT_LIST_ID=$(gvmd --get-port-lists | awk '/Low Risk Ports/ {print $1}')
    if [ -z "$PORT_LIST_ID" ]; then
        echo "Error: Failed to retrieve Port List ID."
        exit 1
    fi

    # Create Scan Config
    if ! gvmd --get-configs | grep -q "Low Risk Scan"; then
        echo "Creating Low Risk Scan config..."
        SCAN_CONFIG_ID=$(gvmd --create-config="Low Risk Scan")
