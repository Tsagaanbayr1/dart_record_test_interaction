## 0.1.1

- Security: an obscured (password) field's value is no longer recorded. Its
  `textInput` event keeps `obscureText: true` with no `textValue`, and loading a
  recording written by 0.1.0 drops any stored value.

## 0.1.0

- Initial release
- `RecorderOverlay` with draggable record button
- `TestId` widget and `.withTestId()` extension
- `TestIdTextField` for text input recording
- `NavigationTracker` for page/route tracking
- `PointerTracker` for tap and scroll capture
- `RecordingStorage` with JSON persistence and multi-account support
- `TestCodeGenerator` with flow extraction and componentization
- `testKey()` helper for both Flutter and Patrol test code
- `TestFramework` enum (`flutter` / `patrol`) for dual-framework code generation
- Patrol integration: generates `patrolTest`, `$(testKey('id'))`, `$.native`, `.scrollTo()`
