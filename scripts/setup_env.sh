#!/bin/bash
while getopts u:p:t:f: flag
do
    case "${flag}" in
        u) user=${OPTARG};;
        p) password=${OPTARG};;
        t) token=${OPTARG};;
        f) token_file=${OPTARG};;
    esac
done

if [[ -n "${token_file:-}" ]]; then
    if [[ -n "${token:-}" ]]; then
        echo "Pass the SIP token with either -t or -f, not both." >&2
        exit 1
    fi
    if [[ ! -r "$token_file" ]]; then
        echo "SIP token file is not readable: $token_file" >&2
        exit 1
    fi
    token=$(< "$token_file")
fi

: "${user:?SIP user is required (-u)}"
: "${password:?SIP password is required (-p)}"
: "${token:?SIP token or token file is required (-t or -f)}"

sed -i '' 's/<SIP_USER>/'"$user"'/g' TelnyxRTCTests/TestConstants.swift
sed -i '' 's/<SIP_PASSWORD>/'"$password"'/g' TelnyxRTCTests/TestConstants.swift
sed -i '' 's/<SIP_TOKEN>/'"$token"'/g' TelnyxRTCTests/TestConstants.swift
