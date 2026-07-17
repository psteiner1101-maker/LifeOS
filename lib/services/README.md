# lib/services

The only home for protected server-side write services (D17). Every polymorphic
or multi-step write (tags, attachments, relationships, reminders, Inbox
conversion, permanent deletion, Bill Occurrence generation, payment recording,
Appointment+Event paired writes, invitations, member removal, Space visibility
changes) must live here as a single transaction. Empty until the relevant
feature phase begins.
