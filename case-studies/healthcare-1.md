# Healthcare: 1 — Web Application Security Assessment

> **Authorization and spoiler notice:** This assessment was performed in an isolated lab against [Healthcare: 1](https://www.vulnhub.com/entry/healthcare-1,522/), an intentionally vulnerable public VulnHub machine. It discusses the vulnerability classes encountered but omits flags, credentials, hashes, payloads, and copy-ready exploitation steps.

## At a glance

| Item | Detail |
|---|---|
| Context | TAFE cybersecurity study and authorized CTF practice |
| Target type | Linux host running a legacy healthcare web application |
| Assessment style | Black-box discovery followed by evidence-led validation |
| Primary focus | Web vulnerabilities, exposed services, privilege boundaries, and remediation |
| Outcome | Multiple high-impact weaknesses were validated and translated into a prioritized remediation plan |

## Objective

Assess the security posture of a deliberately vulnerable healthcare-themed web application, demonstrate the impact of identified weaknesses within the lab, and communicate the results in a form useful to both technical and non-technical readers.

Although the original study exercise used a fictional healthcare engagement scenario, this was not a real healthcare provider or production electronic medical-record system. All apparent records and credentials belonged to the CTF.

## Approach

1. **Scope and rules:** Confirmed the target, testing boundaries, authorization, and evidence requirements.
2. **Discovery:** Identified the lab host and enumerated exposed network services.
3. **Web enumeration:** Mapped reachable content, application behaviour, authentication surfaces, and legacy components.
4. **Vulnerability validation:** Tested suspected weaknesses with the least intrusive method that could establish impact.
5. **Post-compromise review:** Examined privilege boundaries and the consequences of application-level compromise.
6. **Risk analysis:** Connected technical findings to confidentiality, integrity, and availability impact.
7. **Remediation:** Prioritized fixes, compensating controls, and verification steps.

## Key findings

| Finding | Risk | Demonstrated impact |
|---|---:|---|
| Injection weakness in the legacy application | Critical | Unauthorized access to application data and authentication material within the CTF |
| Insecure application file handling | Critical | Server-side code execution in the training environment |
| Weak authentication and access control | High | Access beyond the permissions expected for an unauthenticated or lower-privileged user |
| Insecure direct object access | High | Records could be accessed without adequate object-level authorization checks |
| Weak local privilege boundary | Critical | Application compromise could be extended to full control of the intentionally vulnerable VM |

The findings were treated as a chain rather than isolated defects. Information disclosure and authentication weaknesses enabled deeper application access; application compromise then exposed the effect of weak operating-system privilege controls.

## Remediation priorities

1. Upgrade or replace unsupported application and server components.
2. Use parameterized queries and centralized server-side input validation.
3. Prevent executable uploads and remove web-based file-editing capability from production environments.
4. Enforce authorization on every object and action, not only at the user-interface layer.
5. Store passwords using a modern adaptive password-hashing scheme and require stronger credentials.
6. Remove unsafe privileged executables and apply least privilege to the web-service account.
7. Add centralized logging, alerting, tested backups, and a formal patch-management process.
8. Retest each weakness after remediation and verify that the complete attack chain has been broken.

## Skills demonstrated

- Translating raw enumeration into an assessment plan
- Manual and tool-assisted web testing
- Validating injection and access-control weaknesses
- Linux post-compromise enumeration in a CTF
- Assessing chained technical and business impact
- Writing an executive summary, risk register, remediation timeline, and technical findings
- Avoiding claims beyond the evidence obtained

## Reflection

The most useful lesson was that professional penetration testing is not a list of successful tools or payloads. The report becomes valuable when it explains why the weakness matters, how confident the tester is, what was not established, and how the organization can verify that remediation worked.

## Source

- [Healthcare: 1 — official VulnHub listing](https://www.vulnhub.com/entry/healthcare-1,522/)
