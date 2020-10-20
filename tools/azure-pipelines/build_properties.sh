#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#
# Returns 0 if the change is a documentation-only pull request
#
function is_docs_only_pullrequest() {
	# check if it is a pull request branch, as generated by ci-bot:
	if [[ ! $BUILD_SOURCEBRANCHNAME == ci_* ]] ; then
		echo "INFO: Not a pull request.";
		return 1
	fi
	PR_ID=`echo "$BUILD_SOURCEBRANCHNAME" | cut -f2 -d_`
	if ! [[ "$PR_ID" =~ ^[0-9]+$ ]] ; then
		echo "ERROR: Extracted PR_ID is not a number, but this: '$PR_ID'"
	 	return 1
	fi
	# check if it is docs only pull request
	# 1. Get PR details
	GITHUB_PULL_DETAIL=`curl --silent "https://api.github.com/repos/apache/flink/pulls/$PR_ID"`

	# 2. Check if this build is in sync with the PR
	GITHUB_PULL_HEAD_SHA=`echo $GITHUB_PULL_DETAIL | jq -r ".head.sha"`
	THIS_BRANCH_SHA=`git rev-parse HEAD`

	if [[ "$GITHUB_PULL_HEAD_SHA" != "$THIS_BRANCH_SHA" ]] ; then
		echo "INFO: SHA mismatch: GITHUB_PULL_HEAD_SHA=$GITHUB_PULL_HEAD_SHA != THIS_BRANCH_SHA=$THIS_BRANCH_SHA";
		# sha mismatch. There's some timing issue, and we can't trust the result
		return 1
	fi

	# 3. Get number of commits in PR
	GITHUB_NUM_COMMITS=`echo $GITHUB_PULL_DETAIL | jq -r ".commits"`

	if [[ $(git diff --name-only HEAD..HEAD~$GITHUB_NUM_COMMITS | grep -v "docs/") == "" ]] ; then
		echo "INFO: This is a docs only change. Changed files:"
		git diff --name-only HEAD..HEAD~$GITHUB_NUM_COMMITS
		return 0
	fi
	return 1
}