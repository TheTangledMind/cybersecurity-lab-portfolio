# thetangledmind | Cybersecurity Lab Portfolio

I am a cybersecurity student at TAFE in Sydney, developing practical skills across penetration testing, vulnerability assessment, defensive validation, and technical reporting.

This portfolio presents work completed in intentionally vulnerable training environments. It focuses on the reasoning behind each assessment: defining scope, gathering evidence, validating impact, communicating limitations, and recommending proportionate remediation.

## Featured work

### Live systems

| Work | Environment | Focus |
|---|---|---|
| [Cyber-range containment assessment](featured-work/Cyber-Range/cyber-range-containment-assessment.md) | Owner-operated private lab | Network isolation, virtualization boundaries, evidence-led validation |
| [Cr-router-init.sh](featured-work/Cyber-Range/scripts/cr-router-init.sh) | Initialisation Script for Range Network | bash, namespace, veths |
| [Network Image](featured-work/images/cyber-ranger-v2.png) | Cyber-range.png | visual map of the range design |

### TAFE

#### Healthcare: 1 assessment submission

A multi-document TAFE assessment based on the public, intentionally vulnerable Healthcare: 1 VulnHub CTF.

| Document | Focus |
|---|---|
| [Security assessment case study](case-studies/healthcare-1.md) | Web application testing, risk analysis, remediation, and reporting |
| [Formal penetration-test report (student ID redacted)](featured-work/Cl_NetWebPenTest_AE_Pro2of2-Report_AB_redacted.pdf) | Assessment submission with findings, risk analysis, and remediation |
| [Submitted CherryTree notes](featured-work/healthcare-cherry.ctb.pdf) | Technical notes and evidence; contains CTF spoilers |

#### Incident-response assessment

A two-document TAFE group assessment covering an incident-response plan (IRP) and an incident-response exercise (IRX). The public versions preserve the group assessment material and Andrew Byrne's privilege-escalation playbook; peer-authored playbooks and all student identifiers are replaced with clear in-document notices.

| Document | Focus |
|---|---|
| [Incident response plan](featured-work/incident-response-assessment/Gelos_Incident_Response_Plan_Public_Portfolio.docx) | IRP governance, response process, and privilege-escalation playbook |
| [IRX implementation report](featured-work/incident-response-assessment/Gelos_IRX_Implementation_Public_Portfolio.docx) | IRX planning, execution, monitoring observations, and after-action reporting |

### CTFs

| Case study | Environment | Focus |
|---|---|---|
| [Jangow: 1.0.1 completion summary](case-studies/jangow-1.0.1.md) | Public VulnHub CTF | Enumeration discipline and boot-to-root methodology |

## Skills demonstrated

- Authorized penetration-testing methodology and scope control
- Network and service enumeration
- Web application vulnerability assessment
- Linux privilege-escalation analysis in training environments
- Risk classification and business-impact communication
- Defensive control validation and retest planning
- Clear separation of proven impact, negative results, and unresolved risk
- Professional Markdown and formal report writing

## Tools and frameworks

Tools used across these exercises include Nmap, Burp Suite Community Edition, OWASP ZAP, Wireshark, SQLmap, and Linux command-line utilities. Assessment structure was informed by OWASP testing guidance, PTES concepts, NIST SP 800-115, and risk-based remediation practices.

## Ethics and authorization

All testing described here was performed against systems I owned or was explicitly authorized to assess. Healthcare: 1 and Jangow: 1.0.1 are intentionally vulnerable machines published for security training. No real client systems, production patient records, or third-party infrastructure were targeted.

Technical details are deliberately limited where publishing them would add little professional value or turn a portfolio summary into a copy-ready solution guide.

## Evidence standard

I distinguish between:

- **Proven:** reproduced directly with recorded evidence.
- **Observed:** confirmed in configuration or runtime state.
- **Source-confirmed:** supported by code or authoritative advisory review but not dynamically reproduced.
- **Not demonstrated:** considered or tested without establishing the claimed impact.

This prevents a crash, exposed service, or theoretical attack path from being overstated as full system compromise.
