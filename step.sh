#!/bin/bash

CLOSED_TASKS=$(git --no-pager log --pretty='format:%b' -n $commits_count | grep -oE "($project_key-[0-9]+)" | tr ' ' ',')
CLOSED_TASKS=$(echo $CLOSED_TASKS | tr ' ' ',')

if [ -z "$CLOSED_TASKS" ]; then
    echo "No tasks to transition found in git log"
    exit 0
fi

echo $CLOSED_TASKS

query=$(jq -n \
    --arg jql "project = $project_key AND status = '$from_status' AND key in ($CLOSED_TASKS)" \
    '{ jql: $jql, startAt: 0, maxResults: 20, fields: [ "id" ], fieldsByKeys: false }'
);

echo "Query to be executed in Jira: $query"

tasks_to_close=$(curl -s \
    -H "Content-Type: application/json" \
    --user "$jira_user_name:$jira_api_token" \
    --request POST \
    --data "$query" \
    "$jira_url/rest/api/2/search" | jq -r '.issues[].key'
)

tasks_to_close=$(echo $tasks_to_close | tr ' ' '|')
echo $tasks_to_close

envman add --key TASKS_TO_CLOSE --value $tasks_to_close
