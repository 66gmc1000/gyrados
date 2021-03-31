#!/usr/bin/env bash

# Leaving auth credentials in plain text or even in base64 encoding is not secure.  
# Consider heavily restricting access to this script and make it execute only, without read, or switching to the stronger OAuth approach
# At a minimum only store the base64 version of the combination
cloudusername=Ian.Ovenell@wecu.com
cloudpassword=Qk5VrEE5ojA5gyB3tFse9F28
cloudauth="$(echo -n "$username:$password" | base64 )"

cloudurl=wecu.atlassian.net

serverusername=Ian.Ovenell@wecu.com
serverpassword=Qk5VrEE5ojA5gyB3tFse9F28
serverauth="$(echo -n "$username:$password" | base64 )"

serverurl=helpdesk.wecu.com

function pause(){
  read -n 1 -r -s -p $'Press enter to continue...\n'
}

####################
# cloud functions #
###################

###### GET ######

function cloudgetapi2(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	  -X GET -H 'Content-Type: application/json' \
	  https://$cloudurl/rest/api/2/$api_path$query
}

function cloudgetapi3(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	  -X GET -H 'Content-Type: application/json' \
	  https://$cloudurl/rest/api/3/$api_path$query
}

function cloudgetagile(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	  -X GET -H 'Content-Type: application/json' \
	  https://$cloudurl/rest/agile/latest/$api_path$query
  # http://host:port/context/rest/api-name/api-version/resource-name
  # https://jira.example.com/rest/agile/latest/board/123
}

###### POST ######

function cloudpostapi2(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  https://$cloudurl/rest/api/2/$api_path
}

function cloudpostapi3(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  https://$cloudurl/rest/api/3/$api_path
}

function cloudpostagile(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  https://$cloudurl/rest/agile/latest/$api_path
  # http://host:port/context/rest/api-name/api-version/resource-name
  # https://jira.example.com/rest/agile/latest/board/123
}


####################
# server functions #
###################

###### GET ######

function servergetapi2(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $serverauth" \
	  -X GET -H 'Content-Type: application/json' \
	  https://$serverurl/rest/api/2/$api_path$query
}

function servergetapi3(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $cloudauth" \
	  -X GET -H 'Content-Type: application/json' \
	  https://$serverurl/rest/api/3/$api_path$query
}

function servergetagile(){
  api_path="$1"
  query="$2"
  curl -sb -D- -H "Authorization: Basic $serverauth" \
	  -X GET -H 'Content-Type: application/json' \
	  https://$serverurl/rest/agile/latest/$api_path$query
  # http://host:port/context/rest/api-name/api-version/resource-name
  # https://jira.example.com/rest/agile/latest/board/123
}

###### POST ######

function serverpostapi2(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $serverauth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  https://$serverurl/rest/api/2/$api_path
}

function serverpostapi3(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $serverauth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  https://$serverurl/rest/api/3/$api_path
}

function serverpostagile(){
  api_path="$1"
  json_data_input="$2"
  verb="${3:-POST}"
  curl -sb -D- -H "Authorization: Basic $serverauth" \
	 -X $verb -H 'Content-Type: application/json' \
    -d "$(echo "$json_data_input" | expand | jq -r '.')" \
	  https://$serverurl/rest/agile/latest/$api_path
  # http://host:port/context/rest/api-name/api-version/resource-name
  # https://jira.example.com/rest/agile/latest/board/123
}
