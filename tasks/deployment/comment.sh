  #!/bin/sh

  set -eu

  if ! artifacts_url=$(cat artifacts_url); then
    echo "Artifacts URL was not found" 1>&2
    exit 3
  fi
  
  github_user=${GITHUB_PR_COMMENTER:?"Missing GITHUB_PR_COMMENTER environment variable"}

  github_token=${GITHUB_PR_TOKEN:?"Missing GITHUB_PR_TOKEN environment variable"}

  sudo apt-get install jq

  pr_response=$(curl --location --request GET "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls?head=$CIRCLE_PROJECT_USERNAME:$CIRCLE_BRANCH&state=open" \
  -u $github_user:$github_token)

  if [ $(echo $pr_response | jq length) -eq 0 ]; then
    echo "No PR found to update"
  else
    pr_comment_url=$(echo $pr_response | jq -r ".[]._links.comments.href")
  fi

  curl --location --request POST "$pr_comment_url" \
  -u $github_user:$github_token \
  --header 'Content-Type: application/json' \
  --data-raw '{
  "body": "Link for the Storybook (Active only for 30 days) '${artifacts_url}'/storybook-static/index.html \n Link for the Coverage (Active only for 30 days) '${artifacts_url}'/coverage/lcov-report/src/index.html"
}'
