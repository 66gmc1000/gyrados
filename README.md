# gyrados - Jira Software (Boards/Sprints etc) and Cloning Issues

The steps to clone an issue in jira are fairly complex.  This example has a `bash` + `curl` + `jq v1.6` tested on Jira Software running inside the jira docker container (tested on `Jira v8.12`).

This assumes that your favorite/default project is named `TRAC`.  Change where appropriate.

Using the REST API Browser Plugin makes learning these calls much easier.

https://marketplace.atlassian.com/apps/1211542/atlassian-rest-api-browser?hosting=server&tab=overview

## Helpful Links

https://developer.atlassian.com/server/jira/platform/jira-rest-api-examples/#searching-for-issues-examples

https://jqplay.org/

https://community.atlassian.com/t5/Jira-questions/Clone-Issue-in-java-with-rest-api/qaq-p/932948

https://community.atlassian.com/t5/Jira-questions/Clone-issue-using-JIRA-Rest-api/qaq-p/339566

https://community.atlassian.com/t5/Answers-Developer-Questions/Jira-REST-Api-Clone-an-Issue/qaq-p/561045

https://stackoverflow.com/questions/53549596/how-do-i-clone-an-issue-in-jira

https://developer.atlassian.com/server/jira/platform/rest-apis/

## Commercial Solutions

https://marketplace.atlassian.com/search?query=clone+issue

https://marketplace.atlassian.com/apps/1213072/repeating-issues?hosting=datacenter&tab=overview

## Before running the scripts

1. Create a custom field of type Radio button named `Auto clone this issue` with at least one option of `When closed`.  Leave this as an optional field.
1. Modify the screens for the field, and click the checkbox next to `TRAC: Scrum Default Issue Screen`.
1. Create a Basic Authentication scheme or hook up the OAuth authentication for getting a token for API calls.
1. Download jq 1.6 x64 into your docker container and make it executable.
1. Run these scripts using bash not dash.  (Maybe one day I'll learn to write POSIX compilant scripts instead of using bash-isms)
1. Now create two scripts in your favorite language that can do curl like `GET` and `POST` calls, or download and use the two scripts below on this page.
1. Go into Jira, modify or create an issue, and set `Auto clone this issue` to anything besides `None` and move the now "cloneable" issue into Done.
1. Run the `find_and_clone_issues.sh` script and it should clone the issue and put it into the TODO of the active sprint on the board.

## Pseudocode of scripts

Most of the GET and POST calls use `rest/api/2` and a few calls with `rest/agile/latest`

For some reason `rest/api/3` is missing a bunch of the endpoints I wanted to use.

```
get the custom field id for `Auto clone this issue`
get the custom field id for `Sprint`

get the list of all issues that have a value set for `Auto clone this issue`

for each cloneable issue in the list

  read the value of the fields: auto_clone_custom_field, key, project, srpint, board, issuelinks, status
  
  continue if the .fields.status.statusCategory.key is not done (aka the clone template is in todo or inprogress)
  
  get all the inward issue ids of the issuelinks of type.name `Cloners`
  
  for each existing clone (inwardIssue.key) in the issuelinks `Cloners`
  
    read just the status.statusCategory.key
    
    if it is not done, continue and skip cloning this cloneable issue
    
    # repeat for all existing clones found
  
  
  if all existing clones are in a done state, and the cloneable is in a done state, then proceed with a clone
  
  scrap a board_id by finding a board that matches the project_id of the clonable
  
  find a sprint_id by finding a sprint on the board_id with the state=active,future
  
  sort the results by startDate and pick the first as the sprint to add to
  
  get a copy of the entire cloneable issue
  strip out null elements
  strip out the following fields:
    comment
    id
    self
    key
    watches
    created
    creator
    votes
    updated
    subtasks
    reporter
    aggregateprogress
    resolution
    timetracking
    attachment
    flagged
    versions
    resolutiondate
    closedSprints
    workratio
    progress
    issuelinks
    worklog
    status
    sprint
    $auto_clone_custom_field_id

  Set the custom_field_id for sprint equal to the sprint_id as a number
  Set the project field as project_id as a number

  Prefix the summary with "CLONE - "

  Create an issue with the json

  Get the new issue key for the cloned issue
  
  Create an issueLink of type Cloners with the inward issue being the clone_issue_key and the outwardIssue being the cloneable_issue_key
  
  Post a comment on the cloneable issue summarizing the action for traceability.
  e.g.  {"body": "This issue has been cloned by $clone_issue_key by the auto clone script."}
    
  # repeat for all cloneable issues found
```