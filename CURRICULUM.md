# Curriculum Coverage

Exam: Certified GitOps Associate (CGOA). Domain: GitOps Patterns (20%).

The [official objectives](https://training.linuxfoundation.org/certification/certified-gitops-associate-cgoa/) were checked on 2026-10-11. Teaching structure is independently authored and does not add official requirements.

| Section | Official objective | Modules |
| --- | --- | --- |
| 010 | Deployment and Release Patterns | 2 |
| 020 | Progressive Delivery Patterns | 2 |
| 030 | Pull vs. Event-driven | 2 |
| 040 | Architecture Patterns (in-cluster and external reconciler, state store management, etc.) | 2 |

| Section / module | Module |
| --- | --- |
| 010 / 01 | Rolling Updates And Health Gates |
| 010 / 02 | Blue-Green And Canary With Services |
| 020 / 01 | Canary Steps And Blue-Green With Argo Rollouts |
| 020 / 02 | AnalysisTemplate And AnalysisRun Decisions |
| 030 / 01 | Pull-Based Reconciliation With Argo CD |
| 030 / 02 | Event-Driven Triggers With Argo Events |
| 040 / 01 | Agent Placement, Credentials And Failure Domains |
| 040 / 02 | Repository Layout And State Store Management |

AUTHORING.yaml records measurable goals and adaptation sources. Every objective retains its section ID. Each module has a playground and a graded lab, each section has a capstone lab and a quiz, and the course has a final domain quiz. Labs and playgrounds are built but UNTESTED: only static checks (astrona validate, bash -n, YAML parsing) have been run.
