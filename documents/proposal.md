# SCHOOL OF INFORMATION SCIENCES

## DEPARTMENT OF APPLIED INFORMATICS

## MSc in Enterprise Software Systems Development

---

**Student Full Name:** Themistoklis Darelis
**Student Registration Number:** [006]

**Supervisor:** [To be completed]

---

## Indicative Title

**ACL-Aware Retrieval-Augmented Generation (RAG) System with Integrated Database Access Control**

---

## Detailed Proposal Description / Preliminary Research Outline

This thesis proposes the design and implementation of an Access-Control-List (ACL) Aware Retrieval-Augmented Generation (RAG) system. The system will integrate database-level access control directly into the retrieval pipeline to ensure that Large Language Model (LLM) generated responses are grounded exclusively on documents that the requesting user is authorized to access.

The deliverable will be a full-stack web application consisting of:

- A frontend (likely React-based)
- A backend service exposing secured RAG endpoints
- A database infrastructure with fine-grained access control
- A vector store integrated with ACL-aware filtering
- LLM integration (self-hosted or API-based)

The system will demonstrate secure, enterprise-grade RAG architecture suitable for corporate environments such as consulting firms, financial institutions, or regulated industries.(Πολλη σαλτα?)

---

# Research Field - Problem (minimum 250 words)

(λιγα λογια για το RAG)
Retrieval-Augmented Generation (RAG) has emerged as one of the most effective paradigms for improving Large Language Model (LLM) performance in enterprise environments. By combining semantic retrieval with generative models, RAG reduces hallucinations and enables responses grounded in private organizational knowledge. However, most existing RAG implementations assume uniform access to the underlying document corpus.

(Το προβλημα)
In enterprise settings, data access is governed by strict Access Control Lists (ACLs), Role-Based Access Control (RBAC), or Attribute-Based Access Control (ABAC) policies. A critical but underexplored problem arises when integrating RAG into such environments: the retrieval stage may return documents that the querying user is not authorized to access, resulting in potential data leakage through generated responses.

(Κάποιες αναφορές σε academic literature)
Recent literature highlights challenges in secure and controllable RAG systems. The paper **Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks** established the foundational RAG architecture but does not address multi-user access control scenarios. More recent work such as **Self-RAG: Learning to Retrieve, Generate, and Critique through Self-Reflection** improves retrieval reasoning but still assumes homogeneous access to the corpus. Additionally, **Corrective Retrieval Augmented Generation** focuses on retrieval correction mechanisms but does not incorporate database-level authorization constraints.(θα εχουμε DB layer constrains ή application layer constraints? πρεπει να το πουμε απο τώρα)

The literature gap lies in the absence of architectures that formally integrate fine-grained access control policies into the retrieval pipeline itself. Without ACL-awareness, RAG systems deployed in enterprises risk violating compliance frameworks such as GDPR, ISO 27001, or internal data governance policies.

This research addresses this gap by proposing and evaluating an ACL-aware RAG architecture that ensures strict enforcement of database authorization rules prior to semantic retrieval and generation.

---

# Objectives of the Thesis and/or Research Hypotheses

### Primary Objective

The primary objective of the thesis is to design, implement, and evaluate an ACL-aware Retrieval-Augmented Generation architecture that guarantees that generated responses are derived exclusively from documents authorized for the querying user.

### Secondary Objectives

1. To design a retrieval pipeline that integrates ACL filtering before vector similarity search.
2. To implement fine-grained access control (e.g., RBAC or ABAC) at the database layer or application layer(?).
3. To evaluate the system in terms of:
   - Security correctness (zero unauthorized leakage)
   - Retrieval quality (precision/recall)
   - Latency overhead introduced by ACL filtering

4. To compare the proposed approach against a baseline non-ACL RAG architecture.

### Research Hypothesis

H1: Integrating access control policies directly into the retrieval layer of a RAG system can prevent unauthorized information leakage without significantly degrading retrieval performance.

---

# Methodology

(Να ναι καλα το LLM!!!)
This thesis will follow the **Design Science Research (DSR)** methodology as described by Hevner et al. Design Science is appropriate because the objective is the construction and evaluation of an IT artifact (ACL-aware RAG system).

The research will proceed through the following steps:

1. **Systematic Literature Review**
   - Review RAG architectures
   - Review access control models (ACL, RBAC, ABAC)
   - Review secure AI system design

2. **Problem Formalization**
   - Formal modeling of RAG pipeline
   - Identification of leakage attack surfaces

3. **Artifact Design**
   - Architecture design of ACL-aware RAG
   - Definition of authorization enforcement points
   - Selection of database and vector store technology

4. **Implementation**
   - Backend API (e.g., Node.js / Java / Python)
   - Vector database integration
   - Authentication and authorization mechanism
   - React-based frontend
   - Infrastructure deployment

5. **Evaluation**
   - Security validation testing
   - Performance benchmarking
   - Retrieval effectiveness analysis
   - Comparative analysis with non-ACL baseline

6. **Documentation and Analysis**
   - Discussion of trade-offs
   - Generalization potential
   - Limitations and future work

---

# Bibliography / References (at least 3 references)

1. Lewis, P., et al. (2020). **Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks**.

2. Asai, A., et al. (2023). **Self-RAG: Learning to Retrieve, Generate, and Critique through Self-Reflection**.

3. Yan, J., et al. (2023). **Corrective Retrieval Augmented Generation**.

4. Hevner, A. R., et al. (2004). Design Science in Information Systems Research. MIS Quarterly.

---
