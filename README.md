# MQC-Aegis

**MQC-Aegis** is the real-time decision engine behind **SignalDesk**.

Where **SignalDesk** is the operator dashboard and decision panel, **MQC-Aegis** is the intelligence layer under the hood — correlating fragmented risk signals, applying memory and pattern logic, and escalating outcomes from observation to action.

It is built to move beyond isolated alerts and toward **explainable, structured decisioning in real time**.

---

## Overview

Most alerting systems stop at detection.

MQC-Aegis is designed to go further. It evaluates live events, compares baseline and escalated logic, applies memory across sessions, and produces clear operational outcomes such as:

- `log`
- `rate_limit`
- `manual_review`
- `block`

This makes it possible to distinguish between:

- a harmless anomaly
- a borderline case
- a repeated offender
- a structured risk pattern that should be stopped

---

## Relationship to SignalDesk

This repository is focused on the **decision engine**.

### In practice

- **SignalDesk** = operator interface, dashboard, decision panel
- **MQC-Aegis** = engine, correlation layer, escalation logic

SignalDesk shows what the system is seeing.  
MQC-Aegis determines why the system reacts, how strongly it reacts, and whether a baseline decision should be escalated.

---

## Core capabilities

- Real-time event ingestion for login, payment, and risk events
- Baseline decisioning through local risk scoring and convergence logic
- MQC comparison layer for shadow or primary escalation
- User memory weighting based on trust, incident history, review history, block history, and known IP patterns
- Pattern escalation across repeated or clustered events
- Explainable decisions with labels, confidence levels, and reason codes
- Real-time operator visibility through the SignalDesk dashboard
- Adaptive learning hooks for threshold and baseline recalibration

---

## Why this matters

A single event can be noisy.

A sequence of events can tell the truth.

MQC-Aegis is built around that difference.

It does not just ask:

> “Was this event risky?”

It also asks:

> “Does this event belong to a pattern?”  
> “Has this actor shown this behavior before?”  
> “Should this still be treated as review-only, or should it now be blocked?”

That is the difference between a passive dashboard and a real decision system.

---

## Architecture

MQC-Aegis is structured as a lightweight real-time decision engine with a clear separation between ingestion, evaluation, comparison, memory, and operator output.

### 1. Event ingestion

The engine accepts live events such as:

- login attempts
- payment activity
- location anomalies
- velocity spikes
- suspicious user behavior

These events enter through the API layer and are immediately evaluated.

### 2. Baseline risk evaluation

Each event is scored using baseline risk logic.

This includes:

- event type
- event risk
- amount
- IP familiarity
- geo mismatch
- velocity behavior
- convergence between signals

This produces the first decision layer.

### 3. Memory adjustment

The engine then adjusts the baseline risk using user memory.

Examples include:

- prior incident history
- prior review history
- prior block history
- trust score
- known IP patterns
- recent user momentum

This allows the system to treat repeated behavior differently from first-time noise.

### 4. MQC layer

The MQC layer runs alongside the baseline logic.

Depending on configuration, it can run in:

- **shadow mode** — compare and escalate without fully replacing the baseline engine
- **primary mode** — act as the main decision authority

MQC is responsible for identifying structured risk such as:

- payment clustering
- repeat offender behavior
- auth cascades
- latent escalation patterns

### 5. Decision comparison

The system tracks how baseline decisions and MQC decisions differ.

This includes:

- local risk score
- merged risk score
- local action
- final action
- MQC risk delta
- MQC recommendation
- divergence state
- whether MQC promoted the final decision

This comparison layer is one of the most important parts of the system, because it makes escalation explainable.

### 6. Operator output

The final result is shown through SignalDesk.

Operators can see:

- incidents
- actions
- memory factors
- divergence explanations
- recent event streams
- system reflection
- live comparison between baseline and MQC behavior

---

## Decision model

MQC-Aegis is built around a layered decision flow:

1. Ingest event  
2. Calculate baseline risk  
3. Apply user memory adjustments  
4. Run MQC shadow or primary logic  
5. Merge outcomes  
6. Persist comparison and incident records  
7. Display result in SignalDesk  

This allows the system to answer not only:

- **What happened?**

but also:

- **Why did the system escalate?**
- **What historical context mattered?**
- **Did MQC change the final decision?**

---

## Demo scenarios

The current system is especially effective when demonstrated through scenario-based flows.

### Trusted user

A known user with strong trust history and familiar IP behavior should remain low-friction.

This scenario shows that MQC-Aegis is not just aggressive — it can also reduce pressure when context supports trust.

**What it demonstrates**
- trust-based de-escalation
- known IP weighting
- avoiding unnecessary friction

---

### Borderline review

A medium-risk case that sits near the decision threshold.

This scenario demonstrates how the engine behaves when a case is suspicious enough to monitor, but not yet strong enough to justify a hard block.

**What it demonstrates**
- threshold sensitivity
- controlled escalation
- review-oriented decisioning

---

### Payment cluster

A sequence of payment events that becomes more suspicious over time.

This is one of the clearest MQC scenarios:

- the first payment increases attention
- the second confirms a pattern
- the third, with history and higher amount, can escalate from `manual_review` to `block`

**What it demonstrates**
- structured risk recognition
- multi-event pattern escalation
- memory-aware decisioning
- MQC promotion beyond baseline logic

---

### Auth cascade

A login event with multiple aligned signals such as:

- geo mismatch
- velocity spike
- elevated baseline risk

This scenario shows how both baseline logic and MQC can recognize convergent threat conditions quickly.

**What it demonstrates**
- multi-signal threat convergence
- fast escalation
- explainable hard response

---

### Repeat offender

A user whose incident history grows over time and whose trust score declines.

This scenario demonstrates how repeated behavior matters more than any single event in isolation.

**What it demonstrates**
- memory-driven hardening
- trust degradation
- persistent behavioral weighting

---

### Known user, new IP

A user with otherwise trusted history, but a new environmental signal.

This creates tension between trust and anomaly detection.

**What it demonstrates**
- balance between trust and caution
- anomaly handling without immediate overreaction
- contextual calibration

---

## Example outcome progression

One of the strongest demonstrations of MQC-Aegis is the payment cluster flow:

- **Event 1**  
  Baseline sees moderate risk. MQC increases attention.

- **Event 2**  
  The system recognizes a continued pattern. MQC keeps pressure on the decision.

- **Event 3**  
  With repeated history, higher amount, and pattern continuity, MQC escalates from review to block.

This progression shows the core value of the engine:

> The baseline sees a risky event.  
> MQC sees a risky pattern.

---

## Project structure

A typical structure in this repository looks like this:

```text
MQC-Aegis/
├── src/
│   ├── lib/
│   │   ├── engine.js
│   │   ├── risk.js
│   │   ├── memory.js
│   │   ├── utils.js
│   │   └── ...
│   ├── server.js
│   └── ...
├── public_dashboard/
│   ├── index.html
│   ├── app.js
│   └── ...
├── scripts/
├── backups/
├── data/
├── db/
└── README.md
