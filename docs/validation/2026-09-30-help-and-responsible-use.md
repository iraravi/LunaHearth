# Help and responsible-use validation

Scope: expanded More → Help & guides with 11 searchable troubleshooting and responsible-use articles and 16 FAQ answers. Relevant quick guides link to recovery steps. More → Privacy & data links to product limitations. The bundled policy now explains the existing local AI diagnostics.

Domain and privacy: static support content only; no household model, schema, account, permission, telemetry or synchronization changes. Help works offline. The explicitly labelled Apple licence link opens an external website when selected. No support submission or data upload was added.

Documents: `docs/support/help-and-faq.html`, `product-guide.html` and publisher-only `legal-review.html` are standalone responsive, printable documents. Local links, anchors, unique IDs, heading structure and print/viewport metadata were checked. Browser visual preview was blocked by the browser URL policy; rendered HTML has not been visually verified.

Validation:
- XcodeGen and simulator build completed.
- 272 Swift Testing tests in 51 suites passed, including search normalization and unique support identifiers; log `/tmp/luna-help-final.log`.
- The first large-text UI run reached the first article, but the second search lost keyboard focus after clearing text. The test explicitly refocuses the search field before entering the next query.
- Final iPad large-text UI test passed: searched Focus, opened notification troubleshooting, returned, searched allergens and opened safety guidance; `/tmp/luna-help-ui.log`.
- `git diff --check` passed.

Release boundaries: this work is not in TestFlight build 65. Publisher identity, public support/privacy contact and publication details still need confirmation. The privacy policy is explicitly a draft. Responsible-use help does not establish a custom EULA or legal clearance; the internal review document records the outstanding legal review and publication steps. Existing point-of-use receipt, pantry photo and meal warnings remain in place.
