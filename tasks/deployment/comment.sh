#!/bin/sh

set -eu

  
github_user=${GITHUB_PR_COMMENTER:?"Missing GITHUB_PR_COMMENTER environment variable"}

github_token=${GITHUB_PR_TOKEN:?"Missing GITHUB_PR_TOKEN environment variable"}

if ! repository=$(curl -s \
                  -X GET \
                  -H "Authorization: bearer ${GITHUB_PR_TOKEN}" \
                  -d "{}" \
                  -H "Content-Type: application/json" \
                  "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"); then
  echo "Could not fetch repository data" 1>&2
  exit 1
fi

if ! repository_id=$(echo "${repository}" | python -c 'import sys, json; print json.load(sys.stdin)["id"]'); then
  echo "Could not extract repository ID from API response" 1>&2
  exit 1
fi

artifacts_url="https://${CIRCLE_BUILD_NUM}-${repository_id}-gh.circle-artifacts.com/0"

sudo apt-get install jq

pr_response=$(curl --location --request GET "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls?head=$CIRCLE_PROJECT_USERNAME:$CIRCLE_BRANCH&state=open" \
-u $github_user:$github_token)

if [ $(echo $pr_response | jq length) -eq 0 ]; then
  echo "No PR found to update"
else
  pr_comment_url=$(echo $pr_response | jq -r ".[]._links.comments.href")
  echo ${pr_response}
  echo "pr comment url"
  echo ${pr_comment_url}

    curl --location --request POST "$pr_comment_url" \
    -u $github_user:$github_token \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "body": "Link for the Storybook (Active only for 30 days) '${artifacts_url}'/storybook-static/index.html \n Link for the Coverage (Active only for 30 days) '${artifacts_url}'/coverage/lcov-report/src/index.html"
    }'
fi
