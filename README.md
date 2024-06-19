# AutoDNS
Automatically Install DNS Server Based on Kominfo Database
* This script will work only for CentOS, feel free to edit the code to be work for ubuntu.

# How to Use
- git clone this repo ( git clone )
- cd AutoDNS
- chmod +x autoDNS.sh
- ./autoDNS.sh

# IP To Append?
- Fill the IP to your destination ip/web server for redirect when the web get blocked. eg, trustpositif web/your company web/etc

# How to make database auto update every month
- type nano /etc/cron.d/autodns
- copy paste this line "0 0 1 * * root /path/to/your/autodns.sh" edit the path to yours
- save
- this cron will automatically run every month to update the DNS Database

# Footer
Feel free to edit the code, just dont forget the credits.
