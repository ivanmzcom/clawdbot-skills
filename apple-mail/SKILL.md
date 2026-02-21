---
name: apple-mail
description: "Search and read emails from Apple Mail using AppleScript. Use when the user asks to find emails, check orders, search receipts, or look up purchase history."
---

# Apple Mail via AppleScript

Interact with Apple Mail without needing Full Disk Access.

## List Accounts

```bash
osascript -e '
tell application "Mail"
    return name of every account
end tell
'
```

## Search Emails by Subject

```bash
osascript -e '
tell application "Mail"
    set searchResults to {}
    repeat with acct in every account
        repeat with mb in every mailbox of acct
            try
                set msgs to (every message of mb whose subject contains "SEARCH_TERM")
                repeat with m in msgs
                    set msgDate to date received of m
                    set msgSubject to subject of m
                    set msgSender to sender of m
                    set end of searchResults to msgSubject & " | " & (msgDate as string) & " | " & msgSender
                end repeat
            end try
        end repeat
    end repeat
    return searchResults
end tell
'
```

## Search Emails by Sender

```bash
osascript -e '
tell application "Mail"
    set searchResults to {}
    repeat with acct in every account
        repeat with mb in every mailbox of acct
            try
                set msgs to (every message of mb whose sender contains "amazon")
                repeat with m in msgs
                    set end of searchResults to (subject of m) & " | " & (date received of m as string)
                end repeat
            end try
        end repeat
    end repeat
    return searchResults
end tell
'
```

## Get Recent Emails (Inbox)

```bash
osascript -e '
tell application "Mail"
    set searchResults to {}
    set inboxMsgs to messages 1 thru 10 of inbox
    repeat with m in inboxMsgs
        set msgDate to date received of m
        set msgSubject to subject of m
        set msgSender to sender of m
        set end of searchResults to msgSubject & " | " & (msgDate as string) & " | " & msgSender
    end repeat
    return searchResults
end tell
'
```

## Read Email Content

```bash
osascript -e '
tell application "Mail"
    set msgs to (messages of inbox whose subject contains "SEARCH_TERM")
    if (count of msgs) > 0 then
        set m to item 1 of msgs
        set msgContent to content of m
        return msgContent
    end if
end tell
'
```

## Get Unread Count

```bash
osascript -e '
tell application "Mail"
    return unread count of inbox
end tell
'
```

## List Mailboxes

```bash
osascript -e '
tell application "Mail"
    set mbList to {}
    repeat with acct in every account
        set acctName to name of acct
        repeat with mb in every mailbox of acct
            set end of mbList to acctName & "/" & (name of mb)
        end repeat
    end repeat
    return mbList
end tell
'
```

## Search by Date Range

```bash
osascript -e '
tell application "Mail"
    set startDate to date "01/01/2025"
    set endDate to date "31/12/2025"
    set searchResults to {}
    repeat with acct in every account
        repeat with mb in every mailbox of acct
            try
                set msgs to (every message of mb whose date received > startDate and date received < endDate and subject contains "SEARCH_TERM")
                repeat with m in msgs
                    set end of searchResults to (subject of m) & " | " & (date received of m as string)
                end repeat
            end try
        end repeat
    end repeat
    return searchResults
end tell
'
```

## Tips

- **Timeout**: Add `timeout` parameter for large mailboxes (searches can be slow)
- **Case sensitivity**: AppleScript `contains` is case-insensitive by default
- **Performance**: Searching all mailboxes can be slow; target specific accounts/mailboxes when possible
- **Encoding**: Some special characters in subjects may cause issues; handle with try/catch
