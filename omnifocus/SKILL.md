---
name: omnifocus
description: "Manage OmniFocus 4 Pro via AppleScript on macOS. Create, complete, delete, and search tasks. Manage projects, tags, and folders. Use when the user asks to add tasks, check todos, manage projects, or organize their GTD system."
---

# OmniFocus 4 Pro (AppleScript)

Direct AppleScript automation for OmniFocus 4 Pro. Requires macOS.

## Inbox

### List inbox tasks

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set results to {}
        repeat with t in every inbox task
            set end of results to name of t
        end repeat
        return results
    end tell
end tell
'
```

### Add task to inbox

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        make new inbox task with properties {name:"Task name"}
    end tell
end tell
'
```

### Add task with due date and note

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        make new inbox task with properties {name:"Task name", due date:date "18/02/2026", note:"Details here"}
    end tell
end tell
'
```

### Add task with tag

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set theTag to first flattened tag whose name is "En Espera"
        set newTask to make new inbox task with properties {name:"Task name"}
        add theTag to tags of newTask
    end tell
end tell
'
```

### Add task to specific project

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set proj to first flattened project whose name is "Project Name"
        tell proj
            make new task with properties {name:"Task name"}
        end tell
    end tell
end tell
'
```

## Complete / Delete Tasks

### Complete a task by name

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        repeat with t in every flattened task
            if name of t is "Task name" then
                set completed of t to true
            end if
        end repeat
    end tell
end tell
'
```

### Delete inbox task by name

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        repeat with t in every inbox task
            if name of t is "Task name" then
                delete t
            end if
        end repeat
    end tell
end tell
'
```

## Projects

### List all projects

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        return name of every flattened project
    end tell
end tell
'
```

### List tasks in a project

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set proj to first flattened project whose name is "Project Name"
        set results to {}
        repeat with t in every flattened task of proj
            if completed of t is false then
                set end of results to name of t
            end if
        end repeat
        return results
    end tell
end tell
'
```

### Create a project

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        make new project with properties {name:"New Project"}
    end tell
end tell
'
```

### Create project in folder

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set theFolder to first folder whose name is "Folder Name"
        tell theFolder
            make new project with properties {name:"New Project"}
        end tell
    end tell
end tell
'
```

## Tags

### List all tags

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        return name of every flattened tag
    end tell
end tell
'
```

### Create a tag

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        make new tag with properties {name:"Tag Name"}
    end tell
end tell
'
```

## Folders

### List folders

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        return name of every folder
    end tell
end tell
'
```

## Search

### Search tasks by name (contains)

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set results to {}
        repeat with t in every flattened task
            if completed of t is false and name of t contains "search term" then
                set end of results to name of t
            end if
        end repeat
        return results
    end tell
end tell
'
```

## Flagged Tasks

### List flagged tasks

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        set results to {}
        repeat with t in every flattened task
            if completed of t is false and flagged of t is true then
                set end of results to name of t
            end if
        end repeat
        return results
    end tell
end tell
'
```

### Flag a task

```bash
osascript -e '
tell application "OmniFocus"
    tell default document
        repeat with t in every flattened task
            if name of t is "Task name" then
                set flagged of t to true
            end if
        end repeat
    end tell
end tell
'
```

## Quick Add (via URL scheme)

For simple task creation, OmniFocus also supports URL schemes:

```bash
open "omnifocus:///add?name=Task%20name&note=Details"
```

## Tips

- **Date format:** Uses system locale. For Spain: `"dd/MM/yyyy"` 
- **Performance:** `every flattened task` can be slow with large databases. Use `every inbox task` or target a specific project when possible.
- **Defer dates:** Use `defer date` property to set start dates.
- **Estimated duration:** Use `estimated minutes` property (integer).
