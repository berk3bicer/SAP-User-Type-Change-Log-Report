# SAP User Type Change Monitor 🔍

##  What This Does

I built this ABAP report because I needed a reliable way to monitor user type changes in our SAP system for audit compliance. The program automatically detects when someone changes a user's type (like converting a Dialog user to a System user), captures all the details, and sends out professional HTML email reports to your compliance team.

What makes this different from basic change logs is that it's intelligent - it only reports actual changes, not just log entries. Plus it translates those cryptic SAP codes into readable descriptions and shows you exactly who made each change with their full name.

##  Key Features

- **Smart Change Detection** - Only captures real user type modifications, filters out noise
- **Beautiful HTML Reports** - Professional email formatting that non-technical people can understand  
- **Full Audit Trail** - Shows what changed, who changed it, and exactly when it happened
- **Automated Scheduling** - Set it up once as a background job and forget about it
- **Multi-recipient Support** - Send reports to your entire compliance team automatically

##  Start

### Prerequisites

Make sure your SAP system has:
- Email configuration (SMTP) properly set up
- Access to tables `USH02` and `ADR6`
- Authorization to use `CL_BCS` class for sending emails

### Installation

1. **Create the program**
   ```
   Transaction: SE38
   Program Type: Executable Program  
   Program Name: ZBRK3_USER_TYPE_LOG_MAIL
   ```

2. **Copy the code**
   
   Grab the complete ABAP code from this repository and paste it into your new program

3. **Activate and test**
   
   Hit `Ctrl+F3` to activate, then run it with `F8`

### Basic Usage

The selection screen is simple:
- **Days to Monitor** (`P_DAY`): How many days back to check (default is 1 for daily monitoring)
- **Email Recipients** (`P_EMAIL`): Add all the email addresses that should get the report

That's it! Run the program and it will scan for changes and email your team.

##  Sample Report

When the program finds user type changes, it generates an HTML table that looks something like this:

| User ID | Old Type | New Type | Changed By | Date | Time |
|---------|----------|----------|------------|------|------|
| EBA | A - Dialog | B - System | Berke Bicer | 19/09/2025 | 09:30:15 |
| BBICER | B - System | A - Dialog | Mert Tetik | 19/09/2025 | 14:22:08 |

The email includes professional styling with alternating row colors and highlighted changes so it's easy to spot what happened at a glance.

##  Setting Up Daily Monitoring

This is where the real value comes in - I designed this specifically to run as a daily background job for continuous compliance monitoring. Here's how to set that up:

### Create a Variant
1. Run the program manually first
2. Set `P_DAY = 1` (to check yesterday)  
3. Add all your compliance team emails
4. Save these settings as a variant called `DAILY_AUDIT_REPORT`

### Schedule the Background Job
```
Transaction: SM36
Job Name: USER_TYPE_CHANGE_MONITOR  
Program: ZBRK3_USER_TYPE_LOG_MAIL
Variant: DAILY_AUDIT_REPORT
Schedule: Daily at 06:00 AM
```

Now your compliance team gets automatic reports every morning about any user type changes from the previous day. No manual work required, and you'll never miss an important change again.

##  How It Works

The program follows a straightforward approach:

1. **Query the change logs** - Pulls records from `USH02` table for your specified date range
2. **Find real changes** - For each log entry, looks up what the user type was before to see if it actually changed
3. **Enrich the data** - Uses `BAPI_USER_GET_DETAIL` to get the full name of whoever made the change
4. **Generate HTML** - Creates a clean, professional-looking email with proper formatting
5. **Send emails** - Distributes the report using SAP's native `CL_BCS` framework

The key insight is in step 2 - most change monitoring just dumps all log entries, but this program is smart enough to only report meaningful changes.

##  User Type Translations

The program automatically converts SAP's technical codes into readable descriptions:

| Code | Full Description |
|------|------------------|
| A | Dialog User |
| B | System User |
| C | Communication User |
| L | Reference User |
| S | Service User |

##  Security & Compliance

I built this with audit requirements in mind. The program operates in read-only mode so it can't accidentally modify anything. It uses standard SAP authorizations and doesn't expose sensitive data in the emails - just the information auditors actually need to see.

The automated nature means you get consistent monitoring without relying on someone remembering to run reports manually. That's crucial for compliance frameworks that require continuous oversight.

##  Future Improvements

While the current version does exactly what I needed, there are some enhancements I'm considering:

**Performance optimization** - Right now it makes database calls inside loops, which works fine for most organizations but could be optimized for high-volume systems.

**Additional filtering** - Maybe add options to monitor specific user groups or roles instead of all users.

**Export formats** - Could add PDF or Excel output options alongside the HTML emails.

**Object-oriented refactoring** - Converting to ABAP OO would make the code more maintainable and testable.

**Real-time Alerting for Critical Changes** - To supplement the daily report, an event-driven mechanism could be implemented to send instant notifications for high-risk modifications. For example, an immediate alert could be triggered if a 'System' or 'Service' user is converted to a 'Dialog' user, as this could represent a significant security vulnerability. This would likely involve implementing a user-exit or BAdI on user master data maintenance.

##  Why I Built This

Every SAP shop needs to monitor user changes for security and compliance, but the standard tools either give you too much noise or require manual effort. I wanted something that would:

- Only alert on changes that actually matter
- Present information in a format business users can understand  
- Run automatically without anyone having to remember it
- Provide the detailed audit trail compliance teams need

This program hits all those goals and has been running reliably in our production environment.

##  Contributing

Found a bug or have an idea for improvement? I'd love to hear about it! Open an issue or submit a pull request. Just make sure to test thoroughly in a development system first.

##  License

This project is licensed under the MIT License - feel free to use it in your organization.

##  Contact

Questions? Issues? Feel free to reach out through GitHub issues or connect with me directly.
