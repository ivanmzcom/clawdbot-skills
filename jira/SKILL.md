---
name: jira
description: "Interact with Jira Server (jira.um.es) via REST API. List issues, create/update tickets, search with JQL, manage sprints and worklogs."
---

# Jira Server (Direct API)

Direct curl calls to Jira Server REST API. No CLI dependency needed.

## API Details

- **Base URL:** `https://jira.um.es`
- **API:** `/rest/api/2/`
- **User:** keychain (`security find-generic-password -s jira -a user_email -w`) (JIRAUSER34100)
- **Auth:** Bearer token from keychain
- **Jira Version:** 10.3.10 (Server/Data Center)

## Authentication

```bash
JIRA_USER=$(security find-generic-password -s jira -a user_email -w)
TOKEN=$(security find-generic-password -s jira -a "$JIRA_USER" -w)
AUTH="Authorization: Bearer $TOKEN"
```

All requests use: `curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/..."`

## Common Operations

### My open issues

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/search?jql=assignee%3DcurrentUser()%20AND%20resolution%3DUnresolved%20ORDER%20BY%20updated%20DESC&maxResults=50&fields=key,summary,status,priority,updated"
```

### Search with JQL

```bash
# URL-encode the JQL query
JQL="project=MOVIL AND status='Abierta' ORDER BY created DESC"
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/search" \
  -H "Content-Type: application/json" \
  -d "{\"jql\":\"$JQL\",\"maxResults\":20,\"fields\":[\"key\",\"summary\",\"status\",\"priority\",\"assignee\",\"updated\"]}"
```

### Get issue details

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/issue/MOVIL-3090"
```

### Get issue with specific fields

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/issue/MOVIL-3090?fields=summary,status,description,comment,assignee,priority,created,updated"
```

### Create issue

```bash
curl -s -H "$AUTH" -X POST "https://jira.um.es/rest/api/2/issue" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": {"key": "MOVIL"},
      "summary": "Título del issue",
      "description": "Descripción detallada",
      "issuetype": {"name": "Task"}
    }
  }'
```

### Update issue (edit fields)

```bash
curl -s -H "$AUTH" -X PUT "https://jira.um.es/rest/api/2/issue/MOVIL-3090" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "summary": "Nuevo título",
      "description": "Nueva descripción"
    }
  }'
```

### Add comment

```bash
curl -s -H "$AUTH" -X POST "https://jira.um.es/rest/api/2/issue/MOVIL-3090/comment" \
  -H "Content-Type: application/json" \
  -d '{"body": "Texto del comentario"}'
```

### Transition issue (change status)

```bash
# First, get available transitions
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/issue/MOVIL-3090/transitions"

# Then apply transition
curl -s -H "$AUTH" -X POST "https://jira.um.es/rest/api/2/issue/MOVIL-3090/transitions" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "TRANSITION_ID"}}'
```

### Assign issue

```bash
curl -s -H "$AUTH" -X PUT "https://jira.um.es/rest/api/2/issue/MOVIL-3090/assignee" \
  -H "Content-Type: application/json" \
  -d '{"name": "'"$JIRA_USER"'"}'
```

### Add worklog

```bash
curl -s -H "$AUTH" -X POST "https://jira.um.es/rest/api/2/issue/MOVIL-3090/worklog" \
  -H "Content-Type: application/json" \
  -d '{"timeSpent": "2h", "comment": "Descripción del trabajo"}'
```

## Boards & Sprints (Agile API)

### List boards

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/agile/1.0/board?maxResults=50"
```

### Get board sprints

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/agile/1.0/board/BOARD_ID/sprint?state=active"
```

### Get sprint issues

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/agile/1.0/sprint/SPRINT_ID/issue?fields=key,summary,status,assignee"
```

## Projects

### List all projects

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/project"
```

### Get project details

```bash
curl -s -H "$AUTH" "https://jira.um.es/rest/api/2/project/MOVIL"
```

## Useful JQL Queries

- **My open issues:** `assignee=currentUser() AND resolution=Unresolved ORDER BY updated DESC`
- **Recently updated:** `assignee=currentUser() AND updated>="-7d" ORDER BY updated DESC`
- **By project:** `project=MOVIL AND resolution=Unresolved ORDER BY priority DESC`
- **Created this week:** `assignee=currentUser() AND created>=startOfWeek()`
- **Due soon:** `assignee=currentUser() AND due<=endOfWeek() AND resolution=Unresolved`

## Key Projects

- **MOVIL** — UMUapp (main project)
- **PTFMV** — Platform Mobile

## Tips

- Jira Server uses `/rest/api/2/` (not `/rest/api/3/` like Cloud)
- User identification uses `name` field (email), not `accountId`
- JQL in GET requests must be URL-encoded; in POST body it can be plain text
- Max results default is 50, use `startAt` for pagination
- Issue types vary by project — check with: `GET /rest/api/2/project/KEY/statuses`
