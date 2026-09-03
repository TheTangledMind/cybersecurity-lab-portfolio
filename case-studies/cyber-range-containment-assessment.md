# Private Cyber-Range Containment Assessment

> **Authorization:** This assessment was performed against an owner-operated cyber range with explicit authorization. The public case study has been sanitized to remove identifying and operational details. It is not a guide for attacking third-party virtualization hosts.

## At a glance

| Item | Detail |
|---|---|
| Assessment period | August 2026 |
| Environment | Linux host using libvirt, QEMU/KVM, segmented lab networks, and a monitoring sensor |
| Objective | Determine whether an untrusted guest could cross the intended network or virtualization boundary |
| Method | Configuration review, bounded runtime probes, source/advisory review, and controlled proof-of-concept validation |
| Overall result | Critical containment weaknesses were proven; the range was judged unsuitable for untrusted malware until remediated and retested |

## AI-assisted workflow

OpenAI Daybreak Blue was used as an AI-assisted research and testing aid for hypothesis development, source review, test planning, and evidence organization. The range owner set the scope, explicitly authorized potentially disruptive actions, supervised execution, and retained responsibility for interpreting and validating the results. AI output was not treated as evidence without independent confirmation.

## Assessment question

Could code running inside the intended hostile-workload zone reach the host, trusted networks, external networks, or a vulnerable virtualization path—and which existing controls would still limit impact?

## Scope and safeguards

The review covered the virtualization host, guest definitions, virtual network routing, filtering, monitoring, selected host services, and the attack surface exposed to an authorized test guest.

Safety measures included:

- explicit approval before crash-capable testing;
- recovery checkpoints before disruptive probes;
- narrow, host-owned targets rather than broad network scanning;
- small, reversible test artifacts followed by cleanup verification;
- staged testing, beginning with non-destructive configuration and reachability checks;
- separate reporting of positive, negative, and source-only findings.

Unrelated devices on the physical network were out of scope. The work did not attempt persistence, credential collection, destructive modification, or development of a new guest-to-host code-execution exploit.

## Simplified architecture

The range used separate logical zones for management, attack activity, targets, and monitoring. A routing layer connected the active zones and provided external connectivity. The assessment found that segmentation existed as an architectural concept, but filtering did not enforce a sufficient security boundary between hostile guests, the host, and external networks.

Exact addresses, interface names, service ports, hostnames, and management paths have been removed from this public version.

## Executive findings

| ID | Severity | Finding | Evidence status |
|---|---:|---|---|
| CR-01 | Critical | A guest could reach host-owned and external network surfaces because routing and filtering were overly permissive | Proven from multiple lab zones |
| CR-02 | High | Direct IPv6 link-local adjacency provided a path to host services outside the intended routed boundary | Proven |
| CR-03 | Critical | An unauthenticated local model-management service exposed through the range enabled host-initiated requests and a constrained host-side write | Proven with bounded custom probes |
| CR-04 | Critical | A public KVM vulnerability was applicable with nested virtualization exposed; the authorized public proof of concept triggered host-kernel warnings and terminated the test VM process | Proven denial of service; host command execution not demonstrated |
| CR-05 | High | The range setup automated connectivity and monitoring but did not establish deny-by-default containment | Confirmed by configuration and runtime rules |
| CR-06 | Medium | Unnecessary virtual devices and guest/host integration channels increased attack surface | Observed |
| CR-07 | Medium | Writable disks, memory-sharing features, and resource settings increased persistence, side-channel, and availability risk | Observed |
| CR-08 | Medium | Startup and cleanup behaviour could leave partial network or monitoring state | Reproduced |
| CR-09 | High candidate | Later source review identified a possible out-of-store temporary-file write in an experimental model-transfer path | Source-confirmed and externally reported; not dynamically reproduced on the host |

## Finding analysis

### 1. Network containment did not match the architecture

The design separated workloads into zones, but default-allow forwarding and insufficient host-input controls allowed guests to reach destinations outside the intended range. Testing from more than one zone confirmed that this was a systemic policy problem rather than a single incorrectly attached VM.

IPv6 required separate attention. Disabling IPv6 forwarding did not prevent a guest on the same virtual segment from contacting a host link-local address. This demonstrated why an IPv4-only firewall review would have produced false assurance.

### 2. A host service became a pivot across the boundary

A locally hosted model-management API was reachable from the range without authentication. Controlled tests established metadata disclosure, a constrained content-addressed write, and the ability to make the host service request selected internal resources. Several loopback-only services responded through this path, although no tested endpoint provided a command-execution sink.

The key reporting distinction was maintained:

- host-side request capability and response disclosure were **proven**;
- a constrained write was **proven** and cleaned up;
- arbitrary command execution through the service was **not demonstrated**;
- a later transfer-path issue was **source-confirmed but not dynamically validated** on this host.

### 3. A vulnerable KVM path was reachable

The host configuration exposed nested virtualization to the test guest while running a kernel affected by [CVE-2026-53359](https://ubuntu.com/security/CVE-2026-53359). After owner approval and a recovery checkpoint, the researcher's public proof of concept triggered host KVM warnings and caused the test VM's QEMU process to terminate.

This result established guest-triggered host-kernel integrity impact and denial of service. It did **not** establish attacker-selected host command execution. QEMU process confinement reduced userspace risk but could not prevent a vulnerability in the host KVM kernel path.

### 4. Negative results still narrowed the risk

Selected QEMU device paths and guest/host channels were tested with configuration-specific, bounded probes. The tested conditions did not produce host code execution. In one case, the vulnerable error path was reached but the observed overwrite remained within allocator slack; in another, the required concurrency precondition was absent from the active configuration.

These results did not prove the devices safe. They supported a more precise recommendation: remove unnecessary virtual hardware and keep the remaining virtualization stack patched instead of claiming an exploit that the evidence did not show.

## Controls that worked

- QEMU ran as an unprivileged service account.
- Mandatory access control and per-domain confinement were active.
- Process sandboxing and privilege-reduction controls were enabled.
- No remote management listener for the virtualization service was exposed to the range.
- A previously configured shared filesystem had been removed before boundary testing.
- IOMMU and host CPU mitigations provided additional defense in depth.
- Monitoring captured target-zone traffic after its mirror was correctly rebound.

These controls reduced parts of the attack surface but did not compensate for permissive networking or a vulnerable kernel path.

## Remediation priorities

### Before running untrusted malware

1. Disable nested virtualization for hostile-workload guests and boot only a kernel release that the vendor marks fixed for the applicable KVM vulnerability.
2. Enforce deny-by-default host and router filtering for both IPv4 and IPv6.
3. Prevent range guests from reaching host, private-network, link-local, and physical-LAN destinations.
4. Replace unrestricted Internet access with an in-range simulator or a tightly controlled, logged egress proxy.
5. Remove the model-management service from the range boundary and restrict its outbound registry access.
6. Verify that monitoring covers host-bound and egress attempts from every active range zone.

### Hardening improvements

7. Minimize virtual hardware and remove unused guest agents, clipboard integration, USB redirection, audio, and storage controllers.
8. Use disposable overlays and attach evidence media read-only.
9. Disable shared-memory deduplication for hostile workloads and enforce resource limits.
10. Make range startup transactional: validate prerequisites, apply containment before connectivity, and roll back partial state on failure.
11. Use a dedicated sacrificial host for serious live-malware research, isolated from personal accounts, trusted networks, and unrelated services.

## Retest criteria

The range should not be described as contained until testing from every active workload zone confirms that:

- host-owned addresses are unreachable except for explicitly documented management endpoints;
- host link-local paths are absent or blocked;
- trusted/private networks and unrestricted Internet destinations are unreachable;
- the exposed model-management API and other host applications cannot be reached;
- nested virtualization is unavailable to hostile guests;
- the running kernel maps to a vendor-confirmed fixed package;
- shared filesystems and unnecessary interaction channels are absent;
- evidence disks are read-only and execution uses disposable overlays;
- monitoring records denied host-bound and egress attempts;
- repeated startup and shutdown leave no stale routing, service, or mirror state.

## Professional outcomes

This assessment demonstrated more than vulnerability identification. It required maintaining authorization boundaries, designing bounded tests, preparing for failure, interpreting positive and negative evidence, separating denial of service from code execution, and translating technical findings into an ordered containment plan.

## Public references

- [Canonical — CVE-2026-53359](https://ubuntu.com/security/CVE-2026-53359)
- [Openwall oss-security disclosure](https://www.openwall.com/lists/oss-security/2026/07/06/7)
- [Januscape researcher repository](https://github.com/V4bel/Januscape)
- [Ollama security policy](https://github.com/ollama/ollama/security)
