#!/usr/bin/env bash

# Leaving auth credentials in plain text or even in base64 encoding is not secure.  
# Consider heavily restricting access to this script and make it execute only, without read, or switching to the stronger OAuth approach
# At a minimum only store the base64 version of the combination
username=user@company.com
password=badpassword
auth="$(echo -n "$username:$password" | base64 )"

url=localhost:8080

function pause(){
  read -n 1 -r -s -p $'Press enter to continue...\n'
}

function postapi2(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $auth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  http://$url/rest/api/2/$api_path
}

function postapi3(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $auth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  http://$url/rest/api/3/$api_path
}

function postagile(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $auth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  http://$url/rest/agile/latest/$api_path
  # http://host:port/context/rest/api-name/api-version/resource-name
  # https://jira.example.com/rest/agile/latest/board/123
}

function getapi2(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $auth" \
	  -X GET -H 'Content-Type: application/json' \
	  http://$url/rest/api/2/$api_path$query
}

function getapi3(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $auth" \
	  -X GET -H 'Content-Type: application/json' \
	  http://$url/rest/api/3/$api_path$query
}

function getagile(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $auth" \
	  -X GET -H 'Content-Type: application/json' \
	  http://$url/rest/agile/latest/$api_path$query
  # http://host:port/context/rest/api-name/api-version/resource-name
  # https://jira.example.com/rest/agile/latest/board/123
}