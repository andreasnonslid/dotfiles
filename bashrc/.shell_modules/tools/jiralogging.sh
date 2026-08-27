# Jira time logging aliases. Requires 'jiralog' command.
# Customize via env vars, e.g. export JIRA_LOGCH=TIME-123
#
# Definition-time expansion is the point: the ':=' defaults below resolve each
# ticket when this file is sourced, and every alias carries that value. Escaping
# them per SC2139 would defer to use-time and break the documented "export
# JIRA_* before sourcing" override.
# shellcheck disable=SC2139
: "${JIRA_LOGCH:=TIME-195}"
: "${JIRA_ASIOS:=TIME-164}"
: "${JIRA_ASIO3:=TIME-76}"
: "${JIRA_FUSION:=TIME-25}"
: "${JIRA_VERSA:=TIME-13}"
: "${JIRA_MEETING:=TIME-182}"

alias logch="jiralog log $JIRA_LOGCH today"
alias logasios="jiralog log $JIRA_ASIOS today"
alias logasio3="jiralog log $JIRA_ASIO3 today"
alias logfusion="jiralog log $JIRA_FUSION today"
alias logversa="jiralog log $JIRA_VERSA today"
alias logmeeting="jiralog log $JIRA_MEETING today"
