_Last Modified: 2026-08-07_

# 00. Platform Domain Model & Architectural Vision

Quest has evolved from a single application into a **Social Operating System**. To support this scale, the platform architecture is organized around **Platform Domains** rather than isolated features.

This document serves as the foundational mental map for all engineering, design, and AI decisions across the platform.

---

## 1. The Platform Domain Model

The following diagram illustrates the fundamental relationships between Quest's core entities. Every database schema, API, UI flow, and AI interaction can be traced back to this model.

```mermaid
graph TD
    %% Core Entities
    User((User)) --> Identity
    
    %% Identity Sub-graph
    subgraph Identity Layer
        Identity --> Reputation[Reputation Engine]
        Identity --> Genome[Identity Genome]
    end
    
    %% Society Sub-graph
    subgraph Society Layer
        Reputation --> Communities
        Genome --> Communities
        Communities --> Organizations
    end
    
    %% Interaction & Event Sub-graph
    Communities --> Events
    
    %% World Sub-graph
    subgraph World Layer
        Events --> Presence
        Presence --> Places
        Places --> World
    end
    
    %% The Feed
    World --> Feed[Experience Feed]
    
    %% Cross-Cutting Intelligence Layer
    AI((AI Platform)) -.-> Identity Layer
    AI -.-> Society Layer
    AI -.-> World Layer
    AI -.-> Feed
```

---

## 2. Platform Layers

Instead of standalone features, Quest is structured into six cohesive platform layers.

### 2.1. Identity Layer
*The multidimensional representation of a member.*
- **Profiles:** User avatars, titles, and public representation.
- **Reputation:** Multi-dimensional trust and participation scoring (Reliability, Professionalism, etc.).
- **Levels & Badges:** Gamified progression based on XP.
- **Genome:** AI-derived behavioral models and growth paths.

### 2.2. Interaction Layer
*How members communicate and engage.*
- **Messaging:** Direct and group chat capabilities.
- **Stage:** Live audio rooms, hand-raising, and reactions.
- **Feed:** The Experience Feed and Mission Control, optimized for participation over attention.

### 2.3. Society Layer
*How members organize and collaborate.*
- **Communities:** Persistent social groups, guilds, and clubs.
- **Organizations:** Enterprise, campus, or workspace management.
- **Events:** RSVPs, gatherings, and event timelines.
- **Roles:** Hierarchical governance (Hosts, Moderators, Mentors).

### 2.4. World Layer
*Bridging the digital and physical worlds.*
- **Places:** Persistent digital representations of real-world locations.
- **Presence:** Live or scheduled activities tied to a Place.
- **Radar:** Proximity discovery and geofencing.
- **Geography:** World, regions, cities, and campuses.

### 2.5. Intelligence Layer (AI Platform)
*Cross-cutting AI capabilities woven throughout the OS.*
- **Personal Coach:** 1:1 guidance based on the Identity Genome.
- **Community AI:** Moderation, facilitation, and ice-breaking.
- **Recommendation Engine:** Matchmaking for events, people, and opportunities.
- **Smart Analytics:** Insight generation for members and organizations.

### 2.6. Economy Layer (The Experience Economy)
*Facilitating the exchange of value, skills, and opportunities.*
The Quest Economy is not just an e-commerce marketplace; it is an **Experience Economy** where buying and selling emerge naturally from participation.

```text
Quest Economy
├── Commerce
│   ├── Marketplace (Products, merchandise, textbooks)
│   ├── Services (Tutoring, design, photography)
│   ├── Classifieds (Buy/sell/trade/rent)
│   ├── Local Commerce (Nearby food, vendors)
│   └── Campus Commerce (University-specific exchanges)
│
├── Experiences
│   ├── Events & Tickets
│   ├── Bookings (Rooms, equipment, mentors)
│   ├── Experience Packs (e.g., Freshers Week Pack)
│   └── Memberships
│
├── Creator Economy
│   ├── Digital Goods (Templates, Avatar packs)
│   ├── Courses & Community Assets
│   └── AI Assets
│
├── Opportunities
│   ├── Jobs & Internships
│   ├── Volunteering & Mentorship
│   ├── Research & Hackathons
│   └── Scholarships
│
├── Exchange
│   ├── Skill Swaps (Non-monetary bartering)
│   ├── Donations & Sponsorships
│   └── Crowdfunding
│
└── Financial Infrastructure
    ├── Wallet (Quest Coins & Real Money)
    ├── Payments & Payouts
    └── Escrow (Trust-based transaction holds)
```

---

## 3. Architectural Maturity

The following table tracks the implementation maturity of the platform domains. This indicates where engineering effort is currently focused.

| Domain | Status | Notes |
|---|---|---|
| **Authentication** | 🟡 Prototype | Integrated with Supabase, currently offline/bypassed. |
| **Communities** | 🟢 Mature | Core UI and state management established. |
| **Events** | 🟢 Mature | UI and RSVP state management established. |
| **Identity** | 🟡 Core Implemented | XP and levels active; Reputation/Genome pending. |
| **Interaction (Feed/Chat)** | 🟡 Prototype | UI scaffolded; backend sync pending. |
| **Interaction (Stage)** | 🟡 Prototype | UI scaffolded; Agora/LiveKit pending. |
| **World (Radar/Places)** | 🔵 Planned | Requires refactoring into a unified `world` module and PostGIS. |
| **Presence** | 🔵 Planned | Core to bridging Events and Places. |
| **Reputation** | 🔵 Planned | Foundational for the Experience Economy. |
| **AI Platform** | 🟡 Prototype | Prompting and basic integration scaffolded; comprehensive cross-cutting AI planned. |
| **Economy (Marketplace)** | 🟡 Prototype | Core models and providers scaffolded. |
| **Economy (Opportunities)** | 🟡 Prototype | Core models and providers scaffolded. |
| **Enterprise / Org** | ⚪ Future | Scaffolded, pending multi-tenancy architecture. |

> [!TIP]
> **To all agents and engineers:** When designing a new feature, database schema, or API, first identify which **Platform Layer** it belongs to. Do not build isolated features; build capabilities that enrich the interconnected Domain Model.
