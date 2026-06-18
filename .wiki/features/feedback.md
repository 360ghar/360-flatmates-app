# Feedback

**Active contributors:** Saksham Mittal, Ravi Sahu

## Purpose

The feedback feature provides an in-app form for users to submit bug reports and feature requests. Both types are sent to the same backend endpoint (`POST /api/v1/bugs`), differentiated by the `bug_type` field.

## Key abstractions

| Abstraction | File | Description |
|------------|------|-------------|
| `FeedbackType` | `lib/features/feedback/domain/feedback_model.dart` | Enum: `bug` or `feature` |
| `BugReportRequest` | `lib/features/feedback/domain/feedback_model.dart` | Freezed request body model with source, bugType, severity, title, description, optional appVersion/deviceInfo/tags |
| `FeedbackController` | `lib/features/feedback/application/feedback_controller.dart` | Plain class wrapping the API call |
| `FeedbackFormPage` | `lib/features/feedback/presentation/feedback_form_page.dart` | UI page with title/description/severity fields |

## How it works

The `FeedbackFormPage` is opened from the Help & Safety page (`/help-safety/report-bug` or `/help-safety/request-feature`). The page receives a `FeedbackType` to configure the title, placeholder text, and bug_type value. On submit, `FeedbackController` sends the `BugReportRequest` to the backend via `POST /api/v1/bugs`. The endpoint is a global endpoint, not under `/flatmates`.

## Integration points

- Accessed from `HelpSafetyPage` sub-routes: `/help-safety/report-bug` and `/help-safety/request-feature`
- Sends `BugReportRequest` via `apiClientProvider`

## Key source files

| File | Purpose |
|------|---------|
| `lib/features/feedback/domain/feedback_model.dart` | BugReportRequest freezed model and FeedbackType enum |
| `lib/features/feedback/application/feedback_controller.dart` | Controller that submits the feedback to the backend |
| `lib/features/feedback/presentation/feedback_form_page.dart` | UI form with title, description, and severity fields |
