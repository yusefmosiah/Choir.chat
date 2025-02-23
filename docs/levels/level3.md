# Level 3 Documentation



=== File: docs/plan_anonymity_by_default.md ===



==
plan_anonymity_by_default
==


==
anonymity_by_default.md
==

# Anonymity by Default: A Core Principle of Choir

VERSION anonymity_by_default: 7.0

Anonymity is not just a feature of Choir; it's a fundamental principle, a design choice that shapes the platform's architecture and informs its values. By making anonymity the default state for all users, Choir prioritizes privacy, freedom of expression, and the creation of a space where ideas are judged on their merits, not on the identity of their author.

**Core Tenets:**

1. **Privacy as a Fundamental Right:** Choir recognizes that privacy is a fundamental human right, essential for individual autonomy and freedom of thought. Anonymity protects users from surveillance, discrimination, and the potential chilling effects of being constantly identified and tracked online.
2. **Freedom of Expression:** Anonymity fosters a space where users can express themselves freely, without fear of judgment or reprisal. This is particularly important for discussing sensitive topics, challenging প্রচলিত norms, or exploring unconventional ideas.
3. **Focus on Ideas, Not Identities:** By separating ideas from their authors, anonymity encourages users to evaluate contributions based on their intrinsic value, rather than on the reputation or status of the contributor. This promotes a more meritocratic and intellectually rigorous environment.
4. **Protection from Bias:** Anonymity can help to mitigate the effects of unconscious bias, such as those based on gender, race, or other personal characteristics. It allows ideas to be judged on their own merits, rather than through the lens of preconceived notions about the author.
5. **Lower Barrier to Entry:** Anonymity makes it easier for new users to join the platform and start contributing, as they don't need to go through a complex verification process or share personal information.

**How Anonymity Works on Choir:**

- **Default State:** All users are anonymous by default upon joining the platform. They can interact, contribute content, and earn CHIP tokens without revealing their real-world identity.
- **Unique Identifiers:** Users are assigned unique, randomly generated identifiers that allow them to build a consistent presence on the platform without compromising their anonymity.
- **No Personal Data Collection:** Choir does not collect or store any personally identifiable information about anonymous users.
- **"Priors" and Anonymity:** The "priors" system, which shows the lineage of ideas, maintains anonymity by design. It reveals the connections between ideas, not the identities of the individuals who proposed them.

**Balancing Anonymity with Accountability:**

- **CHIP Staking:** The requirement to stake CHIP tokens to post new messages acts as a deterrent against spam and malicious behavior, even for anonymous users.
- **Community Moderation:** The platform relies on community moderation to maintain the quality of discourse and address any issues that arise.
- **Reputation Systems:** While users are anonymous by default, they can still build reputations based on the quality of their contributions, as tracked through the "priors" system and potentially through community ratings.

**The Value of Anonymity in a High-Information Environment:**

- **Encourages Honest Discourse:** Anonymity can encourage more honest and open discussions, particularly on sensitive or controversial topics.
- **Promotes Intellectual Risk-Taking:** Users may be more willing to take intellectual risks and explore unconventional ideas when they are not worried about the potential repercussions for their personal or professional lives.
- **Facilitates Whistleblowing and Dissent:** Anonymity can provide a safe space for whistleblowers and those who wish to express dissenting views without fear of retaliation.
- **Protects Vulnerable Users:** Anonymity can be particularly important for users in marginalized or vulnerable communities who may face risks if their identities are revealed.

**Conclusion:**

Anonymity by default is a core design principle of Choir, one that reflects the platform's commitment to privacy, freedom of expression, and the creation of a truly meritocratic space for the exchange of ideas. It's a bold choice in a world where online platforms increasingly demand real-name identification, but it's a choice that has the potential to unlock new levels of creativity, honesty, and collective intelligence. By prioritizing anonymity, Choir is not just building a platform; it's building a new model for online interaction, one that empowers individuals and fosters a more open and equitable exchange of ideas.

This document will be integrated into **Level 1: Basic Mechanics**, as it describes a fundamental aspect of how users interact with the platform and each other. It also connects to **Level 3: Value Creation**, as anonymity is a key value proposition for many users, particularly those concerned about privacy and freedom of expression.

=== File: docs/plan_identity_as_a_service.md ===



==
plan_identity_as_a_service
==


# Identity as a Service (IDaaS)

VERSION identity_service: 7.1

Identity on Choir is optional yet valuable. By default, users can participate anonymously, preserving privacy and free expression. However, those who opt into KYC-based verification unlock the ability to participate in binding governance decisions, operate Social AI (SAI) agents under their account, and gain additional social trust signals. This document explains how Identity as a Service (IDaaS) fits into the Choir platform.

---

## Overview

Traditional online platforms typically force users to accept a real-name policy or harvest personal data without explicit consent. Choir takes a different stance:

• **Default Anonymity**: Everyone can read messages, post anonymously, and earn CHIP tokens without providing personal data.
• **Paid Identity**: Those requiring the social or governance benefits of verified status can pay for IDaaS, enabling official KYC-based identity on the platform.

The result is a tiered approach that preserves anonymity for casual or privacy-conscious users, while offering valuable identity features to those who want or need them.

---

## Core Principles

1. **Anonymity First**: No user is required to reveal their personal information to use the basic features of Choir.
2. **Paid Identity**: Identity verification introduces real-world accountability and signals commitment to the community.
3. **Signaling, Not Pay-to-Win**: Verified status does not grant better content visibility—it grants governance participation, the ability to run SAIs, and optional social credibility.
4. **Jurisdictional Compliance**: KYC standards vary globally, so IDaaS is flexible enough to accommodate region-specific regulations.
5. **Privacy Respect**: Despite verification, Choir stores personally identifying information offline and only retains essential proofs on-chain.

---

## Benefits of Verified Identity

- **Governance Participation**: Only verified users can submit binding on-chain votes in futarchy or other proposals.
- **SAI Operator Verification**: KYC ensures that an AI-driven account is mapped to a real individual for accountability.
- **Jurisdictional Compliance**: Verification aligns Choir with relevant regulations, which is critical for the platform’s long-term viability.

Additionally, verified accounts may enjoy intangible benefits like higher reputational trust within the community, though this is a social dynamic rather than a platform-engineered outcome.

---

## IDaaS Workflow

1. **Voluntary Enrollment**: You choose if/when to enroll in IDaaS.
2. **KYC Process**: Provide a government-issued ID or other documentation; a third-party service verifies authenticity.
3. **On-Chain Confirmation**: A non-reversible cryptographic link is posted on-chain (no personally identifying information, just proof of verification).
4. **Subscription or One-Time Fee**: Payment for IDaaS can be structured as recurring or one-time.
5. **Privileges Granted**: The verified user can now vote in binding governance proposals, run SAI agents, and optionally display a verified badge or signal in UI.

---

## Use Cases

- **Governance**: Ensuring that major decisions are made by real individuals with accountability.
- **SAI Execution**: Operating advanced AI software that can influence the platform, under the direct responsibility of a verified user.
- **Enterprise Collaboration**: In corporate settings, having verified internal team members fosters trust and ensures compliance with company or legal requirements.

---

## Monetization and Sustainability

Because IDaaS revenues support the system’s operational costs, they help offset free-tier usage by anonymous participants. This aligns the business model, ensuring that those who need additional capabilities also help fund the platform’s continued growth and stability.

---

## Conclusion

By offering Identity as a Service, Choir establishes a nuanced balance: anonymity remains a core value and default, while verified identity is treated as a premium feature. This approach ensures that governance decisions are accountable, advanced AI operations remain traceable to real individuals, and the platform remains compliant with jurisdictional regulations. Through IDaaS, Choir invites each user to choose the identity model that suits their needs, forging a new path forward for responsible digital communities.
