#!/bin/bash

LASTVER=$(curl -L https://dl.gitea.io/gitea/version.json 2>/dev/null | jq '.latest.version' | sed -e 's/"//g')
LOCALVER=/root/.gitea-update.version

if [[ -r ${LOCALVER} ]]; then
 if [[ "$(cat $LOCALVER)" == "${LASTVER}" ]]; then
  echo "No update required"
  exit 0
 else
  echo "New version ${LASTVER} will be installed over $(cat $LOCALVER)"
 fi
fi

REPOURL="https://dl.gitea.io/gitea/${LASTVER}"
BINURL="gitea-${LASTVER}-linux-amd64"
GETURL="${REPOURL}/${BINURL}"

_curl_result=$(curl -q -L $GETURL -o /usr/local/bin/${BINURL} 2>&1)

if [[ "$?" == "0" ]]; then

 echo "Stopping Gitea for update"
 _service_gitea_stop=$(service gitea stop 2>&1)
 if [[ "$?" == "0" ]]; then
  echo "Gitea stopped"
 else
  echo "Gitea stop returned non-zero code, exiting"
  echo $_service_gitea_stop
  exit 2
 fi

 echo "Setting chmod for new downloaded bin"
 chmod a+x /usr/local/bin/${BINURL}
 if [[ "$?" == "0" ]]; then
  echo "Chmod done"
 else
  echo "Chmod returned non-zero code, exiting"
  exit 2
 fi

 echo "Setting link to new bin"
 ln -sf /usr/local/bin/${BINURL} /usr/local/bin/gitea
 if [[ "$?" == "0" ]]; then
  echo "Ln done"
 else
  echo "Ln returned non-zero code, exiting"
  exit 2
 fi

 echo "Starting new Gitea"
 service gitea start
 if [[ "$?" == "0" ]]; then
  echo -n ${LASTVER} > ${LOCALVER}
  echo "Good"
 fi

else
 echo "Curl returned non-zero code - ${?}, exiting"
 echo $_curl_result
 exit 1
fi
