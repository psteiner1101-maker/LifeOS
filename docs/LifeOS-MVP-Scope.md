# LifeOS MVP Scope

*A daily scope-control checklist. If it's not on this list, it doesn't belong in v1.*

---

## Must Have for Private MVP

- [ ] **Authentication (closed sign-up)** — Done when: the first account can sign up (creating the workspace), sign in, sign out, and reset a forgotten password; thereafter public sign-up is closed, and the second account can be created only via a valid invitation (amendment Part 7).
- [ ] **Automatic account setup** — Done when: sign-up silently creates a profile, workspace, owner membership, and default settings in one transaction, with no user-visible "workspace" concept.
- [ ] **Spaces** — Done when: a member can create and view a Space using only a name, and its Space Owner can archive/reopen it and set it Private or Shared with confirmation (amendment Part 6; Clarification 2).
- [ ] **Invitation & member removal** — Done when: the Workspace Owner can invite exactly one Member, revoke or let an invitation expire, and remove the Member with P6-D transfers applied atomically — with zero leakage of either member's private content throughout (P6-B).
- [ ] **Dashboard** — Done when: Today's Schedule, Overdue, Due Today, Due Soon, Upcoming Bills, and Quick Capture are all visible and correct with zero setup.
- [ ] **Quick Capture & Inbox** — Done when: a user can save raw text in one tap/keystroke, see a suggested type, and confirm/edit/dismiss it without the suggestion ever auto-saving.
- [ ] **Tasks** — Done when: a user can create a Task with only a title, mark it complete/incomplete, and undo that action.
- [ ] **Notes** — Done when: a user can create and autosave a Note with no required organization.
- [ ] **Classes & Assignments** — Done when: a user can add a Class by name only, then add an Assignment with title + Class + due date, and move it through all five statuses.
- [ ] **Bills & Bill Occurrences** — Done when: a user can add a Bill with name + amount + due date, see generated Occurrences, and record a payment without any bank-transfer language.
- [ ] **Calendar (Month/Week/Day)** — Done when: Events, Appointments, Class meeting times, and Task/Assignment/Bill deadlines all appear correctly, visually distinguished by type.
- [ ] **Events & Appointments** — Done when: an Appointment can be created with a paired Event in one action, and deleting one offers a clear choice about the other.
- [ ] **Contacts** — Done when: a Contact can be created and selected as an Instructor/Payee/Provider from the relevant forms.
- [ ] **Reminders** — Done when: a reminder fires reliably in-app at its resolved time, with snooze and dismiss both working.
- [ ] **Search** — Done when: a query returns exact, then title-similar, then content matches across all searchable record types, correctly excluding deleted/archived/Restricted content by default.
- [ ] **Privacy levels** — Done when: a Restricted record never appears in Dashboard, Search, or previews unless the user deliberately opens it.
- [ ] **Archive, Trash, Recovery** — Done when: archiving a Space and deleting a record are two clearly separate, correctly working flows, each restorable from its own screen.
- [ ] **Files** — Done when: a file can be uploaded, attached to more than one record, and downloaded only by an authorized request.

## Present in Schema but Soft-Hidden

- [ ] **Projects** — schema exists; no onboarding/nav/default-form presence; discoverable only inside Space Detail.
- [ ] **Folders** — same treatment as Projects.
- [ ] **Tags** — fully functional but optional; surfaced only under "More options" or in filters, never required.
- [ ] **Workspace / workspace_members** — exists for every account; the word "Workspace" never appears anywhere in the UI.
- [ ] **assigned_to** — column exists on Task; unused and invisible in v1 (no assignee UI).
- [ ] **Audit events** — recorded for every meaningful operation; never exposed in the normal interface.
- [ ] **Daily Priorities table** — powers the one-tap "Today's Priority" star; its underlying table and history are never exposed as a browsable feature.

## Deferred Until Later

- [ ] Full budgeting (Income Entry, Budget Entry)
- [ ] Bank account connections / automatic transaction import
- [ ] Advanced grade forecasting / GPA projection
- [ ] Vehicles and vehicle maintenance records
- [ ] Household inventory tracking
- [ ] Health records and health-specific reminders
- [ ] Travel planning
- [ ] Multi-user / household / family collaboration **beyond the approved two-member model** (structurally prepared, not built)
- [ ] Advanced AI actions (any AI-initiated write)
- [ ] Complex automations / conditional workflows
- [ ] Offline synchronization
- [ ] Native mobile apps
- [ ] Calendar Agenda view (→ v1.1)
- [ ] External calendar sync (connections/mappings tables not built in v1)
- [ ] Field-level AI provenance (only record-level `ai_assisted` in v1)

## Explicitly Prohibited

- Storing full bank account numbers, full card numbers, security codes, or passwords in any field, ever.
- Any button or message implying LifeOS sends or transfers a payment ("Pay," "Send," "Transfer").
- Any AI action (create, edit, delete, reschedule, send, financial action) without explicit user confirmation first.
- Turning every due date into a duplicate Event record.
- Rewriting historical, already-generated Bill Occurrences when a recurrence rule changes.
- Cascading a Space's archive date onto its contained records' own archive fields.
- Exposing technical terms (database, schema, entity, polymorphic, foreign key, junction table, query, object type, property configuration, "workspace") anywhere in the user interface.
- Requiring Tags, Projects, Folders, attachments, relationships, or privacy changes during ordinary record creation.
- Ordinary (non-server-validated) client writes to any polymorphic table (tags, attachments, relationships, reminders, daily_priorities, Inbox conversion references).
- Any interface path that reveals another member's Private-Space or "Only me" content — including titles, previews, counts, storage summaries, or hints (P6-B; amendment Part 8).
