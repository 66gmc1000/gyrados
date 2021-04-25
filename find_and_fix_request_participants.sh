#!/usr/bin/env bash

source jira_utils.sh

# default_board="TRAC"
# default_sprint_id=1

echo "Looking up custom field ids needed"
# req_participants_custom_field_id="$(getapi2 field | jq -r '.[] | select(.name == "Auto clone this issue") | .id')"
# sprint_custom_field_id="$(getapi2 field | jq -r '.[] | select(.name == "Sprint") | .id')"
req_participants_custom_field_id="$(cloudgetapi2 field | jq -r '.[] | select(.name == "Request participants") | .id')"

# # https://confluence.atlassian.com/jirakb/creating-an-issue-in-a-sprint-using-the-jira-rest-api-875321726.html
# sprint_custom_field_id="$(echo "$issue_json_data" \
#   | ./jq-linux64 -r '.fields | to_entries[]
#     | select(.key | startswith("custom"))
#     | select(.value | type == "array")
#     | select(.value[0]
#     | startswith("com.atlassian.greenhopper.service.sprint.Sprint"))
#     | .key')"

# Find all issues where "Auto clone this issue" != null
issue_key_list=$(cloudgetapi2 search?jql=%22Request%20participants%22%21%3Dnull | jq -r '.issues[].key' | sort -n)

# print state of each issue and list of participants in each ticket.
for issue_key in $issue_key_list; do
  echo "Found issue with participants: $issue_key"
  cloneable_info="$(cloudgetapi2 issue/$issue_key?fields=$req_participants_custom_field_id)"
  cloneable_option="$(echo "$cloneable_info" | jq -r --arg req_participants_custom_field_id "$req_participants_custom_field_id" '.fields[$req_participants_custom_field_id].displayName')"
  cloneable_status="$(echo "$cloneable_info" | jq -r '.fields.status.statusCategory.key')"
  # if [ "$cloneable_option" = "Never" ]; then
    note that default of None returns null, and we are finding all the not-null entries
    # continue
  # fi
  # get "Cloners" issue links for the cloneable, see if any of the clones are active (todo or in progress)
  # linked_key_list="$(echo "$cloneable_info" | jq -r '.fields.issuelinks[] | select(.type.name == "Cloners") | .inwardIssue.key')"
  echo "Found linked \"is cloned by\" the following issues"
  echo "$linked_key_list"
done

  # if issue links are empty or they are all done, then proceed with cloning the issue
  all_linked_issues_closed=true
  if [ "$cloneable_status" != "done" ]; then
  echo "Cloneable issue is not marked done.  Giving up on cloning $issue_key"
    continue
  fi
  echo "Checking progress of linked issues"
  for linked_issue_key in $linked_key_list; do
    if [ $linked_issue_key = "null" ] ; then
    continue
    fi

    issue_json_data="$(getapi2 issue/$linked_issue_key?fields=key,status | jq -r '.' )"
    status="$(echo "$issue_json_data" | jq -r '.fields.status.statusCategory.key')"
    
    # getapi2 status | jq -r '.[].statusCategory.key'
    # in progress aka indeterminate
    # todo aka new
    # closed aka done
    if [ $status != "done" ] ; then
      echo "Found a linked issue not in a done state; giving up on cloning $issue_key"
            all_linked_issues_closed=false
      pause
      break;
    fi
  done # end of linked_issue_key

  if $all_linked_issues_closed; then
    # Make a new clone!
        echo "All cloned issues are currently closed... creating a new clone..."
  pause
    issue_json_data="$(getapi2 issue/$issue_key | jq -r '.')"
  board_id=$(echo "$issue_json_data" | jq -r '.fields.sprint.originBoardId')
  project_id=$(echo "$issue_json_data" | jq -r '.fields.project.id')
  sprint_id=$(echo "$issue_json_data" | jq -r '.fields.sprint.id')
  if [ "$board_id" == "null" ]; then
    # search thru boards based on project
    echo "Finding a board id that matches the project $project_id"
    board_info="$(getagile board?projectKeyOrId=$project_id | jq -r '.values[0] | {id, name}')"
    echo "$board_info"
    board_id="$(echo "$board_info" | jq -r '.id')"
    echo "$board_id"
  fi


  if [ "$sprint_id" == "null" ]; then
    sprint_id=$default_sprint
    echo "Finding the active and future sprints on a board and sorting by start date, and grabbing the first one"
    sprint_info="$(getagile board/$board_id/sprint?state=future,active | jq -r '.values |= sort_by(.startDate) | .values[0] | {id, name}')"
    echo "$sprint_info"
    sprint_id="$(echo "$sprint_info" | jq -r '.id')"
    echo "Using sprint_id=$sprint_id"
  fi

  # deny list additions
  echo "Creating initial clone json data"
  json_data="$(getapi2 issue/$issue_key \
  | ./jq-linux64 'delpaths([path(..?) as $p | select(getpath($p) == null) | $p])' \
  | ./jq-linux64 -r --arg req_participants_custom_field_id $req_participants_custom_field_id \
        'delpaths([["fields","comment"],
            ["fields","id"],
            ["fields","self"],
            ["fields","key"],
            ["fields","watches"],
            ["fields","created"],
            ["fields","creator"],
            ["fields","votes"],
            ["fields","updated"],
            ["fields","subtasks"],
            ["fields","reporter"],
            ["fields","customfield_10000"],
            ["fields","aggregateprogress"],
            ["fields","customfield_10100"],
            ["fields","resolution"],
            ["fields","timetracking"],
            ["fields","customfield_10106"],
            ["fields","attachment"],
            ["fields","flagged"],
            ["fields","versions"],
            ["fields","resolutiondate"],
            ["fields","closedSprints"],
            ["fields","workratio"],
            ["fields","progress"],
            ["fields","issuelinks"],
            ["fields","worklog"],
            ["fields","status"],
            ["fields","sprint"],
            ["fields", $req_participants_custom_field_id ]
                        ])')"
  echo "Adding sprint, and project to the json data"
  json_data_with_additions=$(echo "$json_data" | jq -r --arg sprint_id "$sprint_id" \
                                               --arg project_id "$project_id" \
                 --arg sprint_custom_field_id "$sprint_custom_field_id" \
                 '.fields += { ($sprint_custom_field_id) :  $sprint_id|tonumber , "project": { "id": $project_id|tonumber}}')
  echo "Prefixing the summary field with \"CLONE - \""
  json_data_with_additions="$(echo "$json_data_with_additions" | jq -r '.fields.summary |= ("CLONE - " + .)')"
  echo "New Summary:"
  echo "$json_data_with_additions" | jq -r '.fields.summary'
  if false; then
    echo -e "JSON Data for Clone: /n$json_data_with_additons\n"
  fi
  echo "Creating issue"
  create_issue_resp=$(postapi2 issue "$json_data_with_additions")
  echo "$create_issue_resp" | jq -r '. | {key}'

  clone_issue_key=$(echo "$create_issue_resp" | jq -r '.key')
  echo "Clone issue key: $clone_issue_key"

  # Link back to the cloneable
  echo "Linking cloneable to the clone"
  echo "      $clone_issue_key clones $issue_key"
  echo "  aka $issue_key is cloned by $clone_issue_key"
  json_data="$(cat << HEREDOC
  {
    "type": {
      "name": "Cloners"
    },
    "inwardIssue": {
      "key": "$clone_issue_key"
    },
    "outwardIssue": {
      "key": "$issue_key"
    }
  }
HEREDOC
  )"
  issue_link_resp="$(postapi2 issueLink "$json_data")"
  echo "$issue_link_resp" | jq -r '.'

  echo "Marking cloneable $issue_key with a comment of what has happened"

  json_data="$(cat << HEREDOC
  {
      "body": "This issue has been cloned by $clone_issue_key by the auto clone script."
  }
HEREDOC
  )"
  comment_resp="$(postapi2 issue/$issue_key/comment "$json_data")"
  echo "$comment_resp" | jq -r '. | {body,created}'

  echo -e "/n/nDone cloning a jira issue"
  fi
done # end of issue_key