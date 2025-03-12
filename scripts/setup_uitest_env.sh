#!/bin/bash
while getopts u:p:t:d:c: flag
do
    case "${flag}" in
        u) user=${OPTARG};;
        p) password=${OPTARG};;
        t) token=${OPTARG};;
        d) destination=${OPTARG};;
        c) caller=${OPTARG};;
    esac
done

sed -i '' 's/<SIP_USER>/'"$user"'/g' TelnyxWebRTCDemoUITests/TestConstants.swift
sed -i '' 's/<SIP_PASSWORD>/'"$password"'/g' TelnyxWebRTCDemoUITests/TestConstants.swift
sed -i '' 's/<SIP_TOKEN>/'"$token"'/g' TelnyxWebRTCDemoUITests/TestConstants.swift
sed -i '' 's/<DESTINATION_NUMBER>/'"$destination"'/g' TelnyxWebRTCDemoUITests/TestConstants.swift
sed -i '' 's/<CALLER_NUMBER>/'"$caller"'/g' TelnyxWebRTCDemoUITests/TestConstants.swift


# EXAMPLE
# sh scripts/setup_uitest_env.sh -u exampleUser -p examplePassword -t exampleToken -d exampleDestination -c exampleCaller