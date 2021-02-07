#!/bin/sh

LOGINS_FILE=$1
PATH_TO_REPO=$2
TASK_NAME=$3

if [ -z "$LOGINS_FILE" ] && [ -f "$LOGINS_FILE" ]; then
	echo "The first argument must be path to file with students' logins"
	exit 1
fi
LOGINS_FILE=$(realpath "$LOGINS_FILE")

if [ -z "$PATH_TO_REPO" ] && [ -d "$PATH_TO_REPO" ]; then
	echo "The second argument must be path to grading-system repository"
	exit 1
fi
PATH_TO_REPO=$(realpath "$PATH_TO_REPO")

if [ -z "$TASK_NAME" ]; then
	echo "The third argument must be name of the task"
	exit 1
fi

TASK_PREFIX="$TASK_NAME-"

cd "$PATH_TO_REPO" || exit
git submodule update --init --recursive

if ! grep -q "allowed_updates:" .dependabot/config.yml; then
	sed -i '/update_schedule: "daily"/a \    allowed_updates:' .dependabot/config.yml
fi

while IFS= read -r login
do
	SUBMODULE_NAME=${TASK_PREFIX}${login}
	printf "\n------- Try to add %s submodule -------" "$SUBMODULE_NAME" 
	git submodule add https://github.com/spbu-coding/"$SUBMODULE_NAME".git && \
	cd ./"$SUBMODULE_NAME" && \
	git reset --hard "$(git log --grep="Setting up GitHub Classroom Feedback" --pretty=format:"%H")" && \
	cd .. && \
	git add ./"$SUBMODULE_NAME" && \
	sed -i "/allowed_updates:/a \      - match:\n          dependency_name: \"${SUBMODULE_NAME}\"" .dependabot/config.yml && \
	git add .dependabot/config.yml && \
	git commit -m "Added ${SUBMODULE_NAME} submodule" && \
	echo "------- Submodule $SUBMODULE_NAME was added  -------"
done < "$LOGINS_FILE"

echo
git push

