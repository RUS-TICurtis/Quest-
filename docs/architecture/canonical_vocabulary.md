_Last Modified: 2026-08-07_

# Canonical Vocabulary Registry

> [!IMPORTANT]
> **Single Source of Truth**
> This registry is the authoritative source for terminology across the Quest Constitution, codebase, API, database schema, UI copy, AI prompts, and developer documentation. Maintaining strict adherence to this vocabulary prevents semantic drift and ensures human and AI contributors remain aligned.

## 1. Identity & People

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Quest** | The overall Social Operating System platform. | Active | Implemented |
| **Quest Member** | An authenticated participant on the platform. | Active | Implemented |
| **Member** | Shorthand for Quest Member or a participant within a specific Community. | Active | Implemented |
| **Guest** | An unauthenticated or limited-access visitor. | Active | Partial |
| **Visitor** | An individual temporarily accessing a space or event. | Active | Planned |
| **Identity** | The foundational representation of a user, encompassing their Profile, Reputation, and Genome. | Active | Core Implemented |
| **Identity Dashboard** | A profile view centered on personal growth, participation, and XP rather than vanity metrics (e.g., follower counts). | Active | Implemented |
| **Identity Genome** | AI-derived multidimensional model of a member based on their behavior, preferences, and participation. | Active | Planned |
| **Identity Dimensions** | The specific axes/vectors making up the Identity Genome. | Active | Planned |
| **Archetype** | A categorized persona (e.g., Leader, Creator, Supporter) derived from a member's primary participation style. | Active | Prototype |
| **Personality Expression** | How a member's Identity Genome manifests in their public interactions. | Active | Planned |
| **Growth Path** | Suggested quests, challenges, and opportunities tailored by AI to evolve a member's Identity. | Active | Planned |
| **Reputation** | The cumulative measure of a member's trustworthiness and value to the community. | Active | Planned |
| **Reputation Dimension** | Specific metrics like Reliability, Helpfulness, or Professionalism. | Active | Planned |
| **Trust Score** | A calculated metric indicating safety and reliability for transactions or moderation. | Active | Planned |
| **Participation Score** | A metric reflecting active engagement in communities and events. | Active | Planned |
| **Public Appeal** | How favorably a member's contributions are received by the broader society. | Active | Planned |
| **Verification** | The process of authenticating a member's real-world identity or credentials. | Active | Planned |
| **Verification Level** | Tiers of verified trust (e.g., Email, Phone, Institutional ID, Government ID). | Active | Planned |
| **Profile** | The basic public-facing information (Name, Avatar, Bio). | Active | Implemented |
| **Avatar** | Visual representation of the member. | Active | Implemented |
| **Badge** | Visual achievement markers granted for specific accomplishments. | Active | Planned |
| **Achievement** | A completed milestone that contributes to the member's legacy. | Active | Implemented |
| **Title** | An earned prefix or suffix displayed alongside a member's name. | Active | Planned |
| **Hidden Title** | Easter egg titles discovered through unique, unprompted behaviors. | Active | Planned |
| **Easter Egg** | Undocumented interactions or rewards designed for delight and discovery. | Active | Planned |
| **Milestone** | A significant threshold crossed in a member's Growth Path or XP. | Active | Implemented |
| **XP** | Experience Points; the core currency of participation and progression. | Active | Implemented |
| **Level** | A discrete rank achieved by accumulating a specific threshold of XP (`baseXp * level^1.4`). | Active | Implemented |
| **Streak** | Consecutive days of completing at least one Daily Quest. | Active | Implemented |
| **Journey** | A long-term narrative or series of related quests and challenges. | Active | Planned |
| **Quest Path** | A curated sequence of challenges leading to a specific Outcome or Badge. | Active | Planned |
| **Quest History** | The immutable log of all completed quests and achievements. | Active | Implemented |
| **Growth Analytics** | Data visualizing a member's personal development over time. | Active | Planned |
| **Social Analytics** | Data visualizing a member's impact on their network and communities. | Active | Planned |

## 2. Communities & Society

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Community** | A persistent, interest- or location-based social group within Quest. | Active | Mature |
| **Organization** | A formalized, top-level entity (e.g., a University or Company) that can host multiple Communities. | Active | Scaffolded |
| **Guild** | A specialized Community focused on a specific craft, skill, or shared endeavor. | Active | Prototype |
| **Circle** | A smaller, highly curated or private sub-group within a Community. | Active | Planned |
| **Club** | A hobby or recreational Community. | Active | Mature |
| **Society** | A large-scale Community, often academic or cultural. | Active | Planned |
| **Council** | The governing body or leadership tier of a Community. | Active | Planned |
| **Team** | A group of members collaborating on a specific objective or Challenge. | Active | Planned |
| **Household** | A micro-community representing shared living spaces. | Active | Planned |
| **Family** | A micro-community representing familial bonds. | Active | Planned |
| **Campus** | A geographical Organization representing a university or corporate grounds. | Active | Planned |
| **Department** | An administrative subset of an Organization. | Active | Planned |
| **Faculty** | Academic staff subset within a Campus Organization. | Active | Planned |
| **Enterprise** | A commercial Organization leveraging Quest for its workspace. | Future | Planned |
| **Workspace** | A digital environment configured for Enterprise or organizational productivity. | Future | Planned |
| **Chapter** | A localized branch of a larger regional or global Community. | Active | Planned |
| **Chapter Leader** | The primary Organizer of a Chapter. | Active | Planned |
| **Moderator** | A member empowered to enforce Community Standards and governance. | Active | Planned |
| **Ambassador** | A recognized representative of a Community to the broader World Layer. | Active | Planned |
| **Mentor** | An experienced member designated to guide newer members on their Growth Path. | Active | Planned |
| **Coach** | A member (or AI) actively training others in specific skills. | Active | Planned |
| **Organizer** | A member responsible for logistical coordination of Events or Communities. | Active | Planned |
| **Volunteer** | A member participating in the logistical operation of an Event without financial compensation. | Active | Planned |
| **Host** | The primary creator or sponsor of an Event or Stage room. | Active | Implemented |
| **Judge** | A member evaluating submissions for a Challenge or Tournament. | Active | Planned |
| **Creator** | A member producing templates, assets, or experiences for the Economy. | Active | Planned |
| **Contributor** | A member who adds measurable value to a Community or project. | Active | Implemented |

## 3. Places & Geography

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **World** | The macro-layer encompassing all geographical maps and Places. | Active | Planned |
| **Region** | A large geographical grouping (e.g., a state or province). | Active | Planned |
| **Country** | A nation-state boundary. | Active | Planned |
| **City** | An urban geographical boundary. | Active | Planned |
| **District** | A neighborhood or specific zone within a City. | Active | Planned |
| **Campus** | A physical footprint of an Organization (University/Corporate). | Active | Planned |
| **Building** | A specific physical structure within the World Layer. | Active | Planned |
| **Venue** | A location specifically designated for hosting Events. | Active | Planned |
| **Room** | A specific partitioned space within a Building or Venue. | Active | Planned |
| **Place** | A digital representation of a physical location. | Active | Planned |
| **Quest Place** | A persistent digital representation of a real-world location, enhanced with digital experiences and presence tracking. | Active | Planned |
| **Presence** | A live or scheduled activity/entity associated with a Place. | Active | Planned |
| **Presence Zone** | A geofenced area that enables local discovery, check-ins, and participation. | Active | Planned |
| **Activity Zone** | A subset of a Presence Zone where specific mechanics (e.g., Stage streaming) are unlocked. | Active | Planned |
| **Smart Presence** | AI-inferred location context (e.g., knowing a user is at a gym based on routine and sensors). | Active | Planned |
| **Scheduled Presence** | An intent to be at a specific Place at a future time (e.g., an Event). | Active | Planned |
| **Temporary Presence** | A transient existence of a member at a Place (e.g., walking through). | Active | Planned |
| **Check-in** | The explicit action of a member verifying their location at a Place. | Active | Prototype |
| **Geo Check-in** | A check-in strictly validated by GPS/Radar proximity. | Active | Prototype |
| **Geo Fence** | The exact GPS polygon or radius defining a Presence Zone. | Active | Planned |
| **Geo Radius** | A circular boundary originating from a point coordinate. | Active | Planned |
| **Nearby** | Content or Presence located within a member's immediate geographic radius. | Active | Planned |
| **Discovery Radius** | The configurable distance a member can see on their Radar. | Active | Planned |
| **Live Presence** | Real-time visibility of a member or Event at a Place. | Active | Planned |
| **Historical Presence** | The logged record of past check-ins and activities at a Place. | Active | Planned |

## 4. Events

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Event** | A scheduled gathering with a defined start, end, and Location/Place. | Active | Mature |
| **Event Series** | A recurring set of linked Events. | Active | Planned |
| **Meetup** | An informal, highly localized Event. | Active | Planned |
| **Gathering** | A generic term for a physical or digital assembly of members. | Active | Planned |
| **Session** | A discrete segment within a larger Event (e.g., a 1-hour workshop at a conference). | Active | Planned |
| **Workshop** | An interactive, skill-focused Session. | Active | Planned |
| **Tournament** | A competitive Event, often linked to Challenges or gaming. | Active | Planned |
| **Challenge Event** | An Event centered around completing a specific Mission. | Active | Planned |
| **RSVP** | Répondez s'il vous plaît; the state of a member intending to attend. | Active | Implemented |
| **Attendance** | Verified physical or digital presence at an Event. | Active | Planned |
| **Attendance Verification** | The process (e.g., QR scan, Geo Check-in) of proving Attendance. | Active | Planned |
| **Event Timeline** | The chronological feed of activities, sessions, and media within an Event. | Active | Planned |
| **Event Space** | The digital hub containing all Event-related Interaction (Feed, Stage). | Active | Planned |
| **Event Feed** | The isolated Experience Feed scoped only to attendees of the Event. | Active | Planned |
| **Event Bulletin** | A pinned, high-visibility notice board for Event Organizers. | Active | Planned |
| **Event Stage** | The Live Audio/Video room attached to the Event. | Active | Planned |
| **Event Host** | The ultimate owner/sponsor of the Event. | Active | Implemented |
| **Event Organizer** | Members with administrative access to manage the Event. | Active | Planned |

## 5. Interaction

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Feed** | A chronologically or algorithmically sorted stream of content. | Active | Implemented |
| **Experience Feed** | A feed optimized for active participation and action rather than passive consumption/attention. | Active | Implemented |
| **Mission Control** | The action-oriented home screen prioritizing personal goals, active quests, and immediate participation opportunities before general feeds. | Active | Implemented |
| **Home Feed** | The primary Experience Feed on Mission Control. | Active | Implemented |
| **Community Feed** | The Experience Feed scoped to a specific Community. | Active | Implemented |
| **Event Feed** | The Experience Feed scoped to an Event. | Active | Planned |
| **Learning Feed** | A feed curated strictly for educational resources and Growth Paths. | Active | Planned |
| **Creator Feed** | A feed highlighting new Templates, Assets, and Experiences in the Economy. | Active | Planned |
| **Nearby Feed** | A feed displaying activity currently happening within the Discovery Radius. | Active | Planned |
| **Discovery Feed** | Algorithmic suggestions for Communities, Events, and Members outside the immediate network. | Active | Planned |
| **Broadcast** | A one-to-many communication push. | Active | Planned |
| **Bulletin** | A persistent, pinned announcement within a Community or Place. | Active | Planned |
| **Notice** | A formal administrative alert. | Active | Planned |
| **Announcement** | A high-priority message from Hosts or Organizers. | Active | Planned |
| **Discussion** | A threaded, asynchronous conversation. | Active | Implemented |
| **Conversation** | A continuous exchange of messages (sync or async). | Active | Implemented |
| **Thread** | A linear or branching sequence of replies to a specific Discussion. | Active | Implemented |
| **Direct Message** | A private 1:1 text or voice communication. | Active | Prototype |
| **Group Chat** | A private multi-member messaging room. | Active | Prototype |
| **Voice Room** | An informal, always-on audio space. | Active | Planned |
| **Stage** | A structured Live Audio room with distinct speaker/audience roles. | Active | Prototype |
| **Live Stage** | An active, currently streaming Stage session. | Active | Prototype |
| **Hand Raise** | An audience action requesting permission to speak on Stage. | Active | Implemented |
| **Reaction** | A lightweight emoji or haptic response to content or speakers. | Active | Implemented |
| **Icebreaker** | A prompt (often AI-generated) designed to initiate Conversation. | Active | Planned |
| **Introduction** | A formal or AI-facilitated connection between two Members. | Active | Planned |
| **Networking Session** | A structured period of rapid Introductions, often during an Event. | Active | Planned |

## 6. Challenges & Growth

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Quest** | A specific, actionable task that yields XP upon completion. | Active | Implemented |
| **Daily Quest** | Short, routine quests resetting every 24 hours. | Active | Implemented |
| **Weekly Quest** | Larger tasks requiring sustained effort over a week. | Active | Planned |
| **Monthly Quest** | Major, narrative-driven challenges spanning a month. | Active | Planned |
| **Challenge** | A broader goal that may encompass multiple Quests or competitive elements. | Active | Planned |
| **Challenge Chain** | A sequential series of Challenges requiring completion in order. | Active | Planned |
| **Mission** | A high-level objective, often aligned with a member's Growth Path. | Active | Planned |
| **Objective** | A measurable, binary component of a Mission. | Active | Planned |
| **Task** | The smallest atomic unit of work within a Quest. | Active | Planned |
| **Milestone** | A significant marker of progress on a Journey. | Active | Implemented |
| **Exposure Challenge** | A Quest specifically designed to push a member out of their comfort zone. | Active | Planned |
| **Confidence Challenge** | A Quest focused on self-improvement and social assertion. | Active | Planned |
| **Team Challenge** | A Quest requiring the coordinated effort of multiple Members. | Active | Planned |
| **Community Challenge** | A macro-goal achieved through the aggregate XP/effort of a Community. | Active | Planned |
| **Personal Goal** | A privately set objective tracked via Mission Control. | Active | Planned |
| **Habit** | A repeating Personal Goal tracked for Streaks. | Active | Planned |
| **Reflection** | A post-Quest journaling entry to capture lessons learned. | Active | Planned |
| **Journal** | A private repository of Reflections. | Active | Planned |
| **Progress** | The quantified advancement toward a Milestone or Level. | Active | Implemented |

## 7. Reputation System

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Reputation Engine** | The core subsystem that calculates and tracks multi-dimensional trust metrics. | Active | Planned |
| **Trust** | The aggregate metric of a member's safety and reliability. | Active | Planned |
| **Contribution** | The metric of value added to Communities (e.g., content, volunteering). | Active | Planned |
| **Leadership** | The metric of organizing, guiding, and mentoring others. | Active | Planned |
| **Reliability** | The metric of fulfilling commitments (e.g., Event attendance vs. flaking). | Active | Planned |
| **Creativity** | The metric of generating novel Templates, Assets, or Experiences. | Active | Planned |
| **Confidence** | The metric of undertaking Exposure and Confidence Challenges. | Active | Planned |
| **Communication** | The metric of constructive Interaction and Discussion. | Active | Planned |
| **Helpfulness** | The metric of assisting others (e.g., answering questions, tutoring). | Active | Planned |
| **Sportsmanship** | The metric of fair play in Tournaments and Team Challenges. | Active | Planned |
| **Professionalism** | The metric of appropriate conduct in Enterprise or Service transactions. | Active | Planned |
| **Influence** | The metric of reach and impact on the Social Graph. | Active | Planned |
| **Community Health** | An aggregate Reputation metric applied to an entire Community. | Active | Planned |
| **Endorsement** | A permanent, public backing of one Member's specific Reputation Dimension by another. | Active | Planned |
| **Recommendation** | A written testimonial validating a Member's Skills or Services. | Active | Planned |
| **Recognition** | Official acknowledgment of a Contributor by a Community Council. | Active | Planned |
| **Reputation Badge** | A visual Badge earned strictly by maintaining high scores in a Reputation Dimension. | Active | Planned |

## 8. AI Platform

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Quest AI** | The overarching intelligence layer powering the Social OS. | Active | Prototype |
| **Personal AI** | The scoped instance of Quest AI tailored to a specific Member's Identity Genome. | Active | Planned |
| **Community AI** | The scoped instance of Quest AI assisting a specific Community. | Active | Planned |
| **Organization AI** | The scoped instance of Quest AI operating across an Enterprise/Campus. | Active | Planned |
| **AI Coach** | A persona of Personal AI focused on Growth Paths and Challenges. | Active | Planned |
| **Social Coach** | A persona focused on improving Confidence and Communication. | Active | Planned |
| **AI Companion** | A conversational interface for general interaction and reflection. | Active | Planned |
| **AI Facilitator** | A persona of Community AI that manages Stage rooms and Discussions. | Active | Planned |
| **AI Guardian** | A persona focused on safety, monitoring for self-harm or harassment. | Active | Planned |
| **AI Moderator** | A persona enforcing Community Standards and Governance Rules. | Active | Planned |
| **AI Assistant** | A utility persona for executing tasks (e.g., scheduling, booking). | Active | Planned |
| **AI Recommendation Engine** | The subsystem matching Members with Opportunities, Places, and People. | Active | Planned |
| **AI Observation** | An inference made by the AI based on member behavior. | Active | Planned |
| **AI Insight** | A distilled, actionable piece of knowledge presented to the Member. | Active | Planned |
| **Behavioral Analysis** | The continuous processing of interactions to update the Identity Genome. | Active | Planned |
| **Identity Analysis** | The synthesis of the Identity Genome into Archetypes and Paths. | Active | Planned |
| **Reputation Analysis** | The AI validation of Reputation Dimensions to prevent gaming the system. | Active | Planned |
| **Context Awareness** | The AI's understanding of the Member's current Place, Presence, and State. | Active | Planned |
| **Smart Suggestion** | A proactive prompt to take an action (e.g., "Join this Stage"). | Active | Planned |
| **Smart Notification** | A context-aware Alert delivered at the optimal time and priority. | Active | Planned |

## 9. Economy (The Experience Economy)

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Quest Coins** | The primary internal currency used for micro-transactions and rewards. | Planned | Planned |
| **Quest Credits** | Fiat-backed balance stored in the Wallet. | Planned | Planned |
| **Quest Stars** | A non-transferable prestige currency used to tip Creators or highlight posts. | Planned | Planned |
| **Reward** | Economic or XP compensation for completing an Objective. | Active | Planned |
| **Incentive** | A pre-offered Reward designed to drive specific Participation. | Active | Planned |
| **Creator Economy** | The subsystem allowing Members to monetize Templates, Assets, and Content. | Planned | Planned |
| **Marketplace** | The subsystem for buying, selling, and trading physical goods. | Planned | Planned |
| **Store** | A dedicated storefront for a Community, Organization, or Creator. | Planned | Planned |
| **Subscription** | Recurring payments for exclusive Community access or Services. | Planned | Planned |
| **Sponsor** | An entity providing financial backing for an Event or Community. | Planned | Planned |
| **Treasury** | The collective Wallet owned by a Community or Organization. | Planned | Planned |
| **Wallet** | The interface for managing Quest Coins, Credits, and Payouts. | Planned | Planned |
| **Transaction** | A recorded exchange of value within the Economy Layer. | Planned | Planned |
| **Redemption** | Converting Quest Coins/Credits into external value or real-world perks. | Planned | Planned |
| **Commerce** | The exchange of products, services, and rentals. | Planned | Planned |
| **Experiences (Economy)** | The purchasing of Tickets, Bookings, and Experience Packs. | Planned | Planned |
| **Opportunities** | The marketplace for Jobs, Internships, Mentorships, and Volunteering. | Planned | Planned |
| **Exchange (Economy)** | Non-monetary bartering, Skill Swaps, and Crowdfunding. | Planned | Planned |
| **Financial Infrastructure** | The underlying systems handling Escrow, Payments, and History. | Planned | Planned |
| **Escrow** | Trust-based holding of funds until Reputation/Delivery conditions are met. | Planned | Planned |

## 10. Discovery

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Discovery** | The act of finding new Communities, Events, or Members. | Active | Planned |
| **Nearby Discovery** | Discovery strictly scoped to the Radar and Geo Check-ins. | Active | Planned |
| **Social Discovery** | Discovery driven by the Social Graph (e.g., "Friends of Friends"). | Active | Planned |
| **Opportunity Discovery** | Surfacing Jobs, Roles, and Challenges matching the Genome. | Active | Planned |
| **Matchmaking** | AI-driven pairing of Members for specific interactions. | Active | Planned |
| **Skill Match** | Matchmaking based on complementary Skills (e.g., teaching for learning). | Active | Planned |
| **Interest Match** | Matchmaking based on shared Communities or hobbies. | Active | Planned |
| **Compatibility** | An AI-derived score predicting the success of a Match. | Active | Planned |
| **Suggested Member** | An algorithmic recommendation to connect with someone. | Active | Planned |
| **Suggested Community** | An algorithmic recommendation to join a Guild or Club. | Active | Planned |
| **Suggested Event** | An algorithmic recommendation to RSVP based on Context Awareness. | Active | Planned |

## 11. Governance

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Constitution** | The foundational set of rules and ethics governing the Quest Platform. | Active | Planned |
| **Constitutional Invariant** | A core principle that cannot be altered by Communities or Organizations. | Active | Planned |
| **Principle** | A guiding philosophy for behavior and design. | Active | Planned |
| **Policy** | A specific, enforceable rule derived from a Principle. | Active | Planned |
| **Guideline** | A recommended best practice that is not strictly enforced. | Active | Planned |
| **Rule** | A strict constraint configured by a Community Council. | Active | Planned |
| **Permission** | The technical authorization to perform an action. | Active | Planned |
| **Role** | A bundled set of Permissions granted to a Member (e.g., Admin, Moderator). | Active | Planned |
| **Moderation** | The process of reviewing and actioning Content or Behavior against Policies. | Active | Planned |
| **Appeal** | A Member's request to review a Moderation Enforcement action. | Active | Planned |
| **Report** | A Member-submitted flag indicating a Policy violation. | Active | Planned |
| **Enforcement** | The application of penalties (e.g., muting, banning, XP reduction). | Active | Planned |
| **Consent** | Explicit Member agreement required for data sharing or AI Analysis. | Active | Planned |
| **Transparency** | The visibility of Governance actions and AI Observations to Members. | Active | Planned |
| **Community Standards** | The global baseline Rules expected of all Quest Members. | Active | Planned |
| **Safety** | The overarching priority protecting Members from physical and digital harm. | Active | Planned |

## 12. Platform Architecture

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Social Operating System** | Quest's overarching architectural identity; a foundational platform rather than a siloed app. | Active | Implemented |
| **Participation Layer** | A conceptual abstraction emphasizing action over passive consumption. | Active | Planned |
| **Identity Layer** | The Platform Domain handling Profiles, Reputation, Levels, and Genome. | Active | Implemented |
| **Society Layer** | The Platform Domain handling Communities, Organizations, Roles, and Events. | Active | Implemented |
| **World Layer** | The Platform Domain handling Places, Presence, Radar, and Geography. | Active | Planned |
| **Intelligence Layer** | The Platform Domain handling the AI Platform and Analytics. | Active | Prototype |
| **Economy Layer** | The Platform Domain handling the Experience Economy and Wallet. | Planned | Planned |
| **Communication Layer** | A sub-layer of Interaction handling Messaging and Stage. | Active | Implemented |
| **Experience Layer** | A sub-layer of Interaction handling the Feed and Mission Control. | Active | Implemented |
| **Platform Service** | A backend microservice or Supabase RPC providing a specific Capability. | Active | Planned |
| **Module** | A cohesive bundle of code within `lib/features/` representing a subsystem. | Active | Implemented |
| **Capability** | A specific functional ability exposed by the platform (e.g., Geofencing). | Active | Planned |
| **Feature** | A user-facing implementation of one or more Capabilities. | Active | Implemented |
| **Experience** | An end-to-end user journey involving multiple Features. | Active | Planned |

## 13. Design System

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Design Token** | A fundamental visual constant (Color, Typography, Spacing) defined in code. | Active | Implemented |
| **Motion** | The animation principles (e.g., fluid springs) applied to UI transitions. | Active | Implemented |
| **Haptic** | Tactile feedback (vibrations) triggered by Interaction. | Active | Implemented |
| **Interaction Language** | The consistent patterns (swipes, taps, long-presses) used to navigate the OS. | Active | Implemented |
| **Theme** | A globally applied set of Design Tokens (e.g., Dark Mode). | Active | Implemented |
| **Brand** | The visual identity and voice of Quest. | Active | Implemented |
| **Accessibility** | Constraints ensuring the OS is usable by people with disabilities. | Active | Planned |
| **Responsive Layout** | Architecture allowing UI to scale from mobile phones to desktop monitors. | Active | Planned |

## 14. Enterprise

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Campus Instance** | A customized deployment of Quest scoped to a specific University. | Future | Planned |
| **Enterprise Instance** | A customized deployment scoped to a Corporation. | Future | Planned |
| **Organization Space** | The isolated digital footprint of an Enterprise on the global Quest network. | Future | Planned |
| **Tenant** | A discrete logical isolation of data for an Organization (Multi-tenancy). | Future | Planned |
| **Multi-tenancy** | The database architecture securely separating different Tenants. | Future | Planned |
| **Admin Portal** | The web interface for Organizations to manage their Campus Instance. | Future | Scaffolded |
| **Analytics Dashboard** | The UI providing Community Health and Growth Insights to Organizers. | Future | Planned |

## 15. Analytics

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Engagement** | The raw metric of interactions (views, clicks, replies). | Active | Planned |
| **Participation** | The qualitative metric of active contribution (attending, speaking, leading). | Active | Planned |
| **Growth Trend** | Vector data showing the trajectory of a Member's Identity Genome over time. | Active | Planned |
| **Social Graph** | The network mapping of connections between Members, Communities, and Places. | Active | Planned |
| **Activity History** | The chronological log of a Member's past actions. | Active | Implemented |
| **Achievement Timeline** | A curated view of Milestones and Badges earned. | Active | Implemented |
| **Insights** | AI-generated conclusions drawn from Analytics. | Active | Planned |
| **Metrics** | Raw, un-synthesized data points. | Active | Planned |

## 16. Creator Platform

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Studio** | The interface where Creators build Templates, Mini Apps, and Assets. | Future | Planned |
| **Published Experience** | An end-to-end Interaction bundle made available in the Economy. | Future | Planned |
| **Template** | A reusable configuration for an Event, Challenge, or Community. | Future | Planned |
| **Event Template** | A blueprint (e.g., "Standard Hackathon") specifying required Roles and Sessions. | Future | Planned |
| **Challenge Template** | A blueprint (e.g., "7-Day Coding Streak") for Missions. | Future | Planned |
| **Community Template** | A blueprint setting default Channels, Roles, and Governance. | Future | Planned |
| **Mini App** | A small Flutter module injected into a Community Space by a Creator. | Future | Planned |
| **Extension** | A third-party integration augmenting a Platform Capability. | Future | Planned |
| **Plugin** | A specialized tool added to a specific Community or Event. | Future | Planned |

## 17. Content

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Resource** | A piece of static informational media (PDF, Link) attached to a Community. | Active | Planned |
| **Course** | A structured sequence of Learning Feeds and Quests. | Active | Planned |
| **Learning Path** | A curated Curriculum driving a Member toward a specific Outcome. | Active | Planned |
| **Reading List** | A grouped set of Articles or Resources. | Active | Planned |
| **Podcast** | Audio media, often recorded from a Live Stage session. | Active | Planned |
| **Video** | Visual media, used in Feeds or Courses. | Active | Planned |
| **Article** | Long-form text content published within Quest. | Active | Planned |
| **Discussion Prompt** | A specific question posed to a Thread to drive Engagement. | Active | Planned |

## 18. Notifications

| Canonical Name | Definition | Status | Implementation |
|---|---|---|---|
| **Alert** | A high-priority, time-sensitive system notification. | Active | Planned |
| **Reminder** | A prompted notification regarding a scheduled Event or pending Quest. | Active | Planned |
| **Invitation** | A request to join a Community, Event, or Stage. | Active | Planned |
| **Prompt** | An AI-generated nudge suggesting an action based on Context Awareness. | Active | Planned |
| **Smart Reminder** | A Reminder dynamically timed by AI based on the Member's habits. | Active | Planned |
| **Smart Invitation** | An Invitation suggested by the Recommendation Engine. | Active | Planned |
| **Digest** | A summarized batch of Notifications delivered at a set cadence. | Active | Planned |
