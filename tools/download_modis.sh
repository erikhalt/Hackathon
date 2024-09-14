#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (simonmanour): " username
    username=${username:-simonmanour}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011151.h18v02.061.2021195021624/MOD11A1.A2011151.h18v02.061.2021195021624.hdf"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011151.h18v02.061.2021195021624/MOD11A1.A2011151.h18v02.061.2021195021624.hdf -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011151.h18v02.061.2021195021624/MOD11A1.A2011151.h18v02.061.2021195021624.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011151.h18v02.061.2021195021624/MOD11A1.A2011151.h18v02.061.2021195021624.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011151.h18v03.061.2021195021835/MOD11A1.A2011151.h18v03.061.2021195021835.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011150.h18v02.061.2021195003748/MOD11A1.A2011150.h18v02.061.2021195003748.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011150.h18v03.061.2021195003720/MOD11A1.A2011150.h18v03.061.2021195003720.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011149.h18v03.061.2021195000817/MOD11A1.A2011149.h18v03.061.2021195000817.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011149.h18v02.061.2021195000829/MOD11A1.A2011149.h18v02.061.2021195000829.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011148.h18v03.061.2021194221858/MOD11A1.A2011148.h18v03.061.2021194221858.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011148.h18v02.061.2021194221900/MOD11A1.A2011148.h18v02.061.2021194221900.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011147.h18v02.061.2021194215744/MOD11A1.A2011147.h18v02.061.2021194215744.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011147.h18v03.061.2021194215800/MOD11A1.A2011147.h18v03.061.2021194215800.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011146.h18v03.061.2021194200138/MOD11A1.A2011146.h18v03.061.2021194200138.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011146.h18v02.061.2021194195939/MOD11A1.A2011146.h18v02.061.2021194195939.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011145.h18v02.061.2021194193221/MOD11A1.A2011145.h18v02.061.2021194193221.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011145.h18v03.061.2021194193248/MOD11A1.A2011145.h18v03.061.2021194193248.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011144.h18v03.061.2021194171722/MOD11A1.A2011144.h18v03.061.2021194171722.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011144.h18v02.061.2021194171858/MOD11A1.A2011144.h18v02.061.2021194171858.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011143.h18v03.061.2021194164824/MOD11A1.A2011143.h18v03.061.2021194164824.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011143.h18v02.061.2021194165400/MOD11A1.A2011143.h18v02.061.2021194165400.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011142.h18v03.061.2021194144209/MOD11A1.A2011142.h18v03.061.2021194144209.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011142.h18v02.061.2021194144254/MOD11A1.A2011142.h18v02.061.2021194144254.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011141.h18v02.061.2021194141654/MOD11A1.A2011141.h18v02.061.2021194141654.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011141.h18v03.061.2021194141726/MOD11A1.A2011141.h18v03.061.2021194141726.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011140.h18v02.061.2021194125443/MOD11A1.A2011140.h18v02.061.2021194125443.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011140.h18v03.061.2021194125445/MOD11A1.A2011140.h18v03.061.2021194125445.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011139.h18v03.061.2021194123459/MOD11A1.A2011139.h18v03.061.2021194123459.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011139.h18v02.061.2021194123826/MOD11A1.A2011139.h18v02.061.2021194123826.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011138.h18v02.061.2021194112445/MOD11A1.A2011138.h18v02.061.2021194112445.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011138.h18v03.061.2021194112444/MOD11A1.A2011138.h18v03.061.2021194112444.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011137.h18v02.061.2021194110547/MOD11A1.A2011137.h18v02.061.2021194110547.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011137.h18v03.061.2021194110632/MOD11A1.A2011137.h18v03.061.2021194110632.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011136.h18v03.061.2021194095140/MOD11A1.A2011136.h18v03.061.2021194095140.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011136.h18v02.061.2021194095141/MOD11A1.A2011136.h18v02.061.2021194095141.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011135.h18v02.061.2021194094031/MOD11A1.A2011135.h18v02.061.2021194094031.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011135.h18v03.061.2021194094031/MOD11A1.A2011135.h18v03.061.2021194094031.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011134.h18v03.061.2021194081740/MOD11A1.A2011134.h18v03.061.2021194081740.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011134.h18v02.061.2021194081433/MOD11A1.A2011134.h18v02.061.2021194081433.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011133.h18v03.061.2021194081448/MOD11A1.A2011133.h18v03.061.2021194081448.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011133.h18v02.061.2021194081222/MOD11A1.A2011133.h18v02.061.2021194081222.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011132.h18v02.061.2021194064436/MOD11A1.A2011132.h18v02.061.2021194064436.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011132.h18v03.061.2021194064451/MOD11A1.A2011132.h18v03.061.2021194064451.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011131.h18v03.061.2021194063621/MOD11A1.A2011131.h18v03.061.2021194063621.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011131.h18v02.061.2021194063628/MOD11A1.A2011131.h18v02.061.2021194063628.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011130.h18v02.061.2021194051355/MOD11A1.A2011130.h18v02.061.2021194051355.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011130.h18v03.061.2021194051357/MOD11A1.A2011130.h18v03.061.2021194051357.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011129.h18v02.061.2021194050302/MOD11A1.A2011129.h18v02.061.2021194050302.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011129.h18v03.061.2021194050310/MOD11A1.A2011129.h18v03.061.2021194050310.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011128.h18v02.061.2021194032538/MOD11A1.A2011128.h18v02.061.2021194032538.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011128.h18v03.061.2021194032523/MOD11A1.A2011128.h18v03.061.2021194032523.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011127.h18v03.061.2021194031151/MOD11A1.A2011127.h18v03.061.2021194031151.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011127.h18v02.061.2021194031129/MOD11A1.A2011127.h18v02.061.2021194031129.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011126.h18v03.061.2021194013129/MOD11A1.A2011126.h18v03.061.2021194013129.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011126.h18v02.061.2021194013105/MOD11A1.A2011126.h18v02.061.2021194013105.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011125.h18v02.061.2021194011047/MOD11A1.A2011125.h18v02.061.2021194011047.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011125.h18v03.061.2021194011835/MOD11A1.A2011125.h18v03.061.2021194011835.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011124.h18v03.061.2021193235346/MOD11A1.A2011124.h18v03.061.2021193235346.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011124.h18v02.061.2021193235123/MOD11A1.A2011124.h18v02.061.2021193235123.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011123.h18v02.061.2021193231225/MOD11A1.A2011123.h18v02.061.2021193231225.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011123.h18v03.061.2021193231229/MOD11A1.A2011123.h18v03.061.2021193231229.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011122.h18v03.061.2021193220308/MOD11A1.A2011122.h18v03.061.2021193220308.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011122.h18v02.061.2021193220343/MOD11A1.A2011122.h18v02.061.2021193220343.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011121.h18v03.061.2021193210841/MOD11A1.A2011121.h18v03.061.2021193210841.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011121.h18v02.061.2021193211427/MOD11A1.A2011121.h18v02.061.2021193211427.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011120.h18v02.061.2021193195109/MOD11A1.A2011120.h18v02.061.2021193195109.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011120.h18v03.061.2021193195155/MOD11A1.A2011120.h18v03.061.2021193195155.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011119.h18v03.061.2021193184353/MOD11A1.A2011119.h18v03.061.2021193184353.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011119.h18v02.061.2021193184351/MOD11A1.A2011119.h18v02.061.2021193184351.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011118.h18v03.061.2021193172311/MOD11A1.A2011118.h18v03.061.2021193172311.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011118.h18v02.061.2021193172400/MOD11A1.A2011118.h18v02.061.2021193172400.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011117.h18v03.061.2021193162216/MOD11A1.A2011117.h18v03.061.2021193162216.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011117.h18v02.061.2021193162214/MOD11A1.A2011117.h18v02.061.2021193162214.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011116.h18v03.061.2021193153146/MOD11A1.A2011116.h18v03.061.2021193153146.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011116.h18v02.061.2021193152655/MOD11A1.A2011116.h18v02.061.2021193152655.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011115.h18v03.061.2021193140404/MOD11A1.A2011115.h18v03.061.2021193140404.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011115.h18v02.061.2021193140359/MOD11A1.A2011115.h18v02.061.2021193140359.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011114.h18v03.061.2021193122247/MOD11A1.A2011114.h18v03.061.2021193122247.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011114.h18v02.061.2021193122239/MOD11A1.A2011114.h18v02.061.2021193122239.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011113.h18v03.061.2021193114755/MOD11A1.A2011113.h18v03.061.2021193114755.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011113.h18v02.061.2021193114735/MOD11A1.A2011113.h18v02.061.2021193114735.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011112.h18v03.061.2021193102213/MOD11A1.A2011112.h18v03.061.2021193102213.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011112.h18v02.061.2021193103150/MOD11A1.A2011112.h18v02.061.2021193103150.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011111.h18v03.061.2021193092634/MOD11A1.A2011111.h18v03.061.2021193092634.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011111.h18v02.061.2021193093544/MOD11A1.A2011111.h18v02.061.2021193093544.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011110.h18v03.061.2021193081525/MOD11A1.A2011110.h18v03.061.2021193081525.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011110.h18v02.061.2021193081533/MOD11A1.A2011110.h18v02.061.2021193081533.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011109.h18v02.061.2021193071935/MOD11A1.A2011109.h18v02.061.2021193071935.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011109.h18v03.061.2021193072526/MOD11A1.A2011109.h18v03.061.2021193072526.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011108.h18v03.061.2021193045307/MOD11A1.A2011108.h18v03.061.2021193045307.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011108.h18v02.061.2021193045309/MOD11A1.A2011108.h18v02.061.2021193045309.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011107.h18v02.061.2021193035644/MOD11A1.A2011107.h18v02.061.2021193035644.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011107.h18v03.061.2021193035657/MOD11A1.A2011107.h18v03.061.2021193035657.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011106.h18v03.061.2021193022855/MOD11A1.A2011106.h18v03.061.2021193022855.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011106.h18v02.061.2021193022859/MOD11A1.A2011106.h18v02.061.2021193022859.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011105.h18v03.061.2021193014629/MOD11A1.A2011105.h18v03.061.2021193014629.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011105.h18v02.061.2021193013713/MOD11A1.A2011105.h18v02.061.2021193013713.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011104.h18v03.061.2021193001717/MOD11A1.A2011104.h18v03.061.2021193001717.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011104.h18v02.061.2021193002445/MOD11A1.A2011104.h18v02.061.2021193002445.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011103.h18v02.061.2021192231325/MOD11A1.A2011103.h18v02.061.2021192231325.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011103.h18v03.061.2021192231228/MOD11A1.A2011103.h18v03.061.2021192231228.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011102.h18v02.061.2021192213748/MOD11A1.A2011102.h18v02.061.2021192213748.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011102.h18v03.061.2021192213752/MOD11A1.A2011102.h18v03.061.2021192213752.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011101.h18v03.061.2021192210009/MOD11A1.A2011101.h18v03.061.2021192210009.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011101.h18v02.061.2021192205656/MOD11A1.A2011101.h18v02.061.2021192205656.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011100.h18v02.061.2021192192444/MOD11A1.A2011100.h18v02.061.2021192192444.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011100.h18v03.061.2021192192921/MOD11A1.A2011100.h18v03.061.2021192192921.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011099.h18v02.061.2021192183939/MOD11A1.A2011099.h18v02.061.2021192183939.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011099.h18v03.061.2021192183930/MOD11A1.A2011099.h18v03.061.2021192183930.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011098.h18v02.061.2021192165007/MOD11A1.A2011098.h18v02.061.2021192165007.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011098.h18v03.061.2021192165606/MOD11A1.A2011098.h18v03.061.2021192165606.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011097.h18v02.061.2021192162345/MOD11A1.A2011097.h18v02.061.2021192162345.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011097.h18v03.061.2021192161713/MOD11A1.A2011097.h18v03.061.2021192161713.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011096.h18v02.061.2021191135843/MOD11A1.A2011096.h18v02.061.2021191135843.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011096.h18v03.061.2021191135756/MOD11A1.A2011096.h18v03.061.2021191135756.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011095.h18v03.061.2021191135346/MOD11A1.A2011095.h18v03.061.2021191135346.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011095.h18v02.061.2021191135537/MOD11A1.A2011095.h18v02.061.2021191135537.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011094.h18v02.061.2021191122649/MOD11A1.A2011094.h18v02.061.2021191122649.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011094.h18v03.061.2021191122648/MOD11A1.A2011094.h18v03.061.2021191122648.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011093.h18v03.061.2021191122137/MOD11A1.A2011093.h18v03.061.2021191122137.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011093.h18v02.061.2021191122133/MOD11A1.A2011093.h18v02.061.2021191122133.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011092.h18v02.061.2021191105357/MOD11A1.A2011092.h18v02.061.2021191105357.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011092.h18v03.061.2021191105407/MOD11A1.A2011092.h18v03.061.2021191105407.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011091.h18v03.061.2021191104146/MOD11A1.A2011091.h18v03.061.2021191104146.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011091.h18v02.061.2021191104146/MOD11A1.A2011091.h18v02.061.2021191104146.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011090.h18v02.061.2021191092308/MOD11A1.A2011090.h18v02.061.2021191092308.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011090.h18v03.061.2021191092312/MOD11A1.A2011090.h18v03.061.2021191092312.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011089.h18v03.061.2021191090055/MOD11A1.A2011089.h18v03.061.2021191090055.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011089.h18v02.061.2021191090058/MOD11A1.A2011089.h18v02.061.2021191090058.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011088.h18v03.061.2021191074947/MOD11A1.A2011088.h18v03.061.2021191074947.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011088.h18v02.061.2021191074909/MOD11A1.A2011088.h18v02.061.2021191074909.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011087.h18v02.061.2021191071928/MOD11A1.A2011087.h18v02.061.2021191071928.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011087.h18v03.061.2021191071929/MOD11A1.A2011087.h18v03.061.2021191071929.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011086.h18v02.061.2021191060837/MOD11A1.A2011086.h18v02.061.2021191060837.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011086.h18v03.061.2021191060824/MOD11A1.A2011086.h18v03.061.2021191060824.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011085.h18v02.061.2021191054143/MOD11A1.A2011085.h18v02.061.2021191054143.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011085.h18v03.061.2021191054141/MOD11A1.A2011085.h18v03.061.2021191054141.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011084.h18v02.061.2021191040734/MOD11A1.A2011084.h18v02.061.2021191040734.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011084.h18v03.061.2021191041020/MOD11A1.A2011084.h18v03.061.2021191041020.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011083.h18v02.061.2021191040419/MOD11A1.A2011083.h18v02.061.2021191040419.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011083.h18v03.061.2021191040648/MOD11A1.A2011083.h18v03.061.2021191040648.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011082.h18v02.061.2021191022554/MOD11A1.A2011082.h18v02.061.2021191022554.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011082.h18v03.061.2021191022542/MOD11A1.A2011082.h18v03.061.2021191022542.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011081.h18v02.061.2021191022141/MOD11A1.A2011081.h18v02.061.2021191022141.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011081.h18v03.061.2021191022139/MOD11A1.A2011081.h18v03.061.2021191022139.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011080.h18v03.061.2021191004847/MOD11A1.A2011080.h18v03.061.2021191004847.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011080.h18v02.061.2021191004851/MOD11A1.A2011080.h18v02.061.2021191004851.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011079.h18v03.061.2021191003552/MOD11A1.A2011079.h18v03.061.2021191003552.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011079.h18v02.061.2021191003606/MOD11A1.A2011079.h18v02.061.2021191003606.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011078.h18v02.061.2021190231421/MOD11A1.A2011078.h18v02.061.2021190231421.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011078.h18v03.061.2021190231421/MOD11A1.A2011078.h18v03.061.2021190231421.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011077.h18v03.061.2021190223237/MOD11A1.A2011077.h18v03.061.2021190223237.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011077.h18v02.061.2021190223401/MOD11A1.A2011077.h18v02.061.2021190223401.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011076.h18v03.061.2021190205346/MOD11A1.A2011076.h18v03.061.2021190205346.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011076.h18v02.061.2021190205348/MOD11A1.A2011076.h18v02.061.2021190205348.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011075.h18v03.061.2021190195958/MOD11A1.A2011075.h18v03.061.2021190195958.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011075.h18v02.061.2021190200003/MOD11A1.A2011075.h18v02.061.2021190200003.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011074.h18v03.061.2021190175530/MOD11A1.A2011074.h18v03.061.2021190175530.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011074.h18v02.061.2021190175409/MOD11A1.A2011074.h18v02.061.2021190175409.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011073.h18v02.061.2021190161049/MOD11A1.A2011073.h18v02.061.2021190161049.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011073.h18v03.061.2021190161254/MOD11A1.A2011073.h18v03.061.2021190161254.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011072.h18v03.061.2021190143529/MOD11A1.A2011072.h18v03.061.2021190143529.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011072.h18v02.061.2021190143507/MOD11A1.A2011072.h18v02.061.2021190143507.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011071.h18v02.061.2021190125011/MOD11A1.A2011071.h18v02.061.2021190125011.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011071.h18v03.061.2021190125002/MOD11A1.A2011071.h18v03.061.2021190125002.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011070.h18v03.061.2021190114955/MOD11A1.A2011070.h18v03.061.2021190114955.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011070.h18v02.061.2021190115346/MOD11A1.A2011070.h18v02.061.2021190115346.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011069.h18v03.061.2021190104739/MOD11A1.A2011069.h18v03.061.2021190104739.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011069.h18v02.061.2021190105116/MOD11A1.A2011069.h18v02.061.2021190105116.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011068.h18v03.061.2021190094927/MOD11A1.A2011068.h18v03.061.2021190094927.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011068.h18v02.061.2021190095645/MOD11A1.A2011068.h18v02.061.2021190095645.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011067.h18v02.061.2021190084854/MOD11A1.A2011067.h18v02.061.2021190084854.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011067.h18v03.061.2021190084138/MOD11A1.A2011067.h18v03.061.2021190084138.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011066.h18v03.061.2021190064241/MOD11A1.A2011066.h18v03.061.2021190064241.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011066.h18v02.061.2021190064251/MOD11A1.A2011066.h18v02.061.2021190064251.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011065.h18v03.061.2021190054008/MOD11A1.A2011065.h18v03.061.2021190054008.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011065.h18v02.061.2021190054105/MOD11A1.A2011065.h18v02.061.2021190054105.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011064.h18v02.061.2021190033911/MOD11A1.A2011064.h18v02.061.2021190033911.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011064.h18v03.061.2021190033909/MOD11A1.A2011064.h18v03.061.2021190033909.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011063.h18v02.061.2021190030548/MOD11A1.A2011063.h18v02.061.2021190030548.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011063.h18v03.061.2021190030554/MOD11A1.A2011063.h18v03.061.2021190030554.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011062.h18v03.061.2021190010513/MOD11A1.A2011062.h18v03.061.2021190010513.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011062.h18v02.061.2021190010516/MOD11A1.A2011062.h18v02.061.2021190010516.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011061.h18v02.061.2021190004323/MOD11A1.A2011061.h18v02.061.2021190004323.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011061.h18v03.061.2021190004307/MOD11A1.A2011061.h18v03.061.2021190004307.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011060.h18v02.061.2021189215456/MOD11A1.A2011060.h18v02.061.2021189215456.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011060.h18v03.061.2021189215459/MOD11A1.A2011060.h18v03.061.2021189215459.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011059.h18v03.061.2021189214505/MOD11A1.A2011059.h18v03.061.2021189214505.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011059.h18v02.061.2021189214354/MOD11A1.A2011059.h18v02.061.2021189214354.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011058.h18v03.061.2021189181407/MOD11A1.A2011058.h18v03.061.2021189181407.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011058.h18v02.061.2021189181412/MOD11A1.A2011058.h18v02.061.2021189181412.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011057.h18v02.061.2021189175848/MOD11A1.A2011057.h18v02.061.2021189175848.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011057.h18v03.061.2021189175842/MOD11A1.A2011057.h18v03.061.2021189175842.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011056.h18v02.061.2021189145607/MOD11A1.A2011056.h18v02.061.2021189145607.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011056.h18v03.061.2021189145600/MOD11A1.A2011056.h18v03.061.2021189145600.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011055.h18v03.061.2021189144843/MOD11A1.A2011055.h18v03.061.2021189144843.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011055.h18v02.061.2021189143853/MOD11A1.A2011055.h18v02.061.2021189143853.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011054.h18v02.061.2021189121041/MOD11A1.A2011054.h18v02.061.2021189121041.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011054.h18v03.061.2021189121034/MOD11A1.A2011054.h18v03.061.2021189121034.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011053.h18v03.061.2021189115307/MOD11A1.A2011053.h18v03.061.2021189115307.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011053.h18v02.061.2021189115110/MOD11A1.A2011053.h18v02.061.2021189115110.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011052.h18v02.061.2021189101627/MOD11A1.A2011052.h18v02.061.2021189101627.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011052.h18v03.061.2021189102045/MOD11A1.A2011052.h18v03.061.2021189102045.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011051.h18v03.061.2021189100130/MOD11A1.A2011051.h18v03.061.2021189100130.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011051.h18v02.061.2021189100009/MOD11A1.A2011051.h18v02.061.2021189100009.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011050.h18v03.061.2021189080305/MOD11A1.A2011050.h18v03.061.2021189080305.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011050.h18v02.061.2021189080111/MOD11A1.A2011050.h18v02.061.2021189080111.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011049.h18v03.061.2021189074316/MOD11A1.A2011049.h18v03.061.2021189074316.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011049.h18v02.061.2021189074641/MOD11A1.A2011049.h18v02.061.2021189074641.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011048.h18v03.061.2021189060303/MOD11A1.A2011048.h18v03.061.2021189060303.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011048.h18v02.061.2021189055539/MOD11A1.A2011048.h18v02.061.2021189055539.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011047.h18v03.061.2021189041126/MOD11A1.A2011047.h18v03.061.2021189041126.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011047.h18v02.061.2021189041141/MOD11A1.A2011047.h18v02.061.2021189041141.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011046.h18v02.061.2021189025152/MOD11A1.A2011046.h18v02.061.2021189025152.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011046.h18v03.061.2021189025730/MOD11A1.A2011046.h18v03.061.2021189025730.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011045.h18v03.061.2021189012216/MOD11A1.A2011045.h18v03.061.2021189012216.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011045.h18v02.061.2021189012223/MOD11A1.A2011045.h18v02.061.2021189012223.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011044.h18v03.061.2021189002220/MOD11A1.A2011044.h18v03.061.2021189002220.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011044.h18v02.061.2021189002203/MOD11A1.A2011044.h18v02.061.2021189002203.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011043.h18v02.061.2021188223649/MOD11A1.A2011043.h18v02.061.2021188223649.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011043.h18v03.061.2021188223650/MOD11A1.A2011043.h18v03.061.2021188223650.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011042.h18v03.061.2021188213414/MOD11A1.A2011042.h18v03.061.2021188213414.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011042.h18v02.061.2021188213417/MOD11A1.A2011042.h18v02.061.2021188213417.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011041.h18v03.061.2021188202809/MOD11A1.A2011041.h18v03.061.2021188202809.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011041.h18v02.061.2021188202417/MOD11A1.A2011041.h18v02.061.2021188202417.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011040.h18v03.061.2021188192128/MOD11A1.A2011040.h18v03.061.2021188192128.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011040.h18v02.061.2021188192625/MOD11A1.A2011040.h18v02.061.2021188192625.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011039.h18v02.061.2021188180353/MOD11A1.A2011039.h18v02.061.2021188180353.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011039.h18v03.061.2021188180314/MOD11A1.A2011039.h18v03.061.2021188180314.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011038.h18v02.061.2021188171436/MOD11A1.A2011038.h18v02.061.2021188171436.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011038.h18v03.061.2021188171512/MOD11A1.A2011038.h18v03.061.2021188171512.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011037.h18v02.061.2021188155701/MOD11A1.A2011037.h18v02.061.2021188155701.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011037.h18v03.061.2021188160341/MOD11A1.A2011037.h18v03.061.2021188160341.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011036.h18v02.061.2021188142518/MOD11A1.A2011036.h18v02.061.2021188142518.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011036.h18v03.061.2021188142629/MOD11A1.A2011036.h18v03.061.2021188142629.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011035.h18v02.061.2021188132016/MOD11A1.A2011035.h18v02.061.2021188132016.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011035.h18v03.061.2021188131936/MOD11A1.A2011035.h18v03.061.2021188131936.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011034.h18v03.061.2021188113850/MOD11A1.A2011034.h18v03.061.2021188113850.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011034.h18v02.061.2021188113903/MOD11A1.A2011034.h18v02.061.2021188113903.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011033.h18v03.061.2021188105831/MOD11A1.A2011033.h18v03.061.2021188105831.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011033.h18v02.061.2021188105824/MOD11A1.A2011033.h18v02.061.2021188105824.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011032.h18v02.061.2021188085918/MOD11A1.A2011032.h18v02.061.2021188085918.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2011032.h18v03.061.2021188090310/MOD11A1.A2011032.h18v03.061.2021188090310.hdf
EDSCEOF