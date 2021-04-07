#!/bin/bash
while getopts u:p:t: flag
do
    case "${flag}" in
        u) user=${OPTARG};;
        p) password=${OPTARG};;
        t) token=${OPTARG};;
    esac
done
echo "User: $user";
echo "password: $password";
echo "Token Name: $token";

sed -i '' 's/<SIP_USER>/'"$user"'/g' WebRTCSDKTests/TestConstants.swift
sed -i '' 's/<SIP_PASSWORD>/'"$password"'/g' WebRTCSDKTests/TestConstants.swift
sed -i '' 's/<SIP_TOKEN>/'"$token"'/g' WebRTCSDKTests/TestConstants.swift