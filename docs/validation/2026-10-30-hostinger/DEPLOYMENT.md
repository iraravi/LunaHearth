# Hostinger deployment — 30 October 2026

Published the existing Nam Illam website to https://neuralluna.com and https://namillam.neuralluna.com after explicit owner approval to replace the previous NeuralLuna AI Workforce site on both addresses.

- Static source: sites/orynvi-preview; deployed output: dist only.
- Subdomain shares the primary public directory; future deployments update both.
- Hostinger SSL active and HTTPS redirects verified for both domains.
- All eight HTML pages on each domain returned HTTP 200 and matched local output (16 checks).
- All 31 published files returned HTTP 200. HTML/CSS/JS matched; image bytes may be optimised by CDN. Homepage rendered and screenshot saved alongside this note.
- Local validator: 317 references, no errors. Six content tests passed.
- DNS before: @ ALIAS, www CNAME, ftp A. After: only namillam ALIAS added. No MX/TXT records were present. Prior DNS snapshot: 134743413.
- Hosting disclosures updated from planned Firebase/private Sites to Hostinger. Public-preview label replaces private-preview label. Legal policies remain drafts and noindex is retained.
- Support mailbox delivery, legal operator details, effective policy date, retention decisions and App Store public release remain unverified or pending. No new legal compliance or trademark claim is made.
- No native application changes or native build were required for this deployment.
