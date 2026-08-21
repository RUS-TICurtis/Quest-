_Last Modified: 2026-08-07_

# 02. Product Overview & UX Philosophy

Quest is built on a fundamental philosophy: **Optimization for participation, not attention.** 

If the home screen is an endless, passive content feed, Quest risks becoming another generic social media app. To prevent this, Quest physically separates **Action** from **Discovery**.

## 1. The Core UX Divide

### Home (Mission Control)
The Home screen is not a feed of what others are doing; it is a dashboard of what *you* can do right now. It is your **Mission Control**.
- Prioritizes active quests, XP progress, and immediate upcoming events.
- Displays nearby active communities and unread messages.
- AI coaching prompts encourage real-world action (e.g., "You haven't attended an event in 6 days").
- The Experience Feed is accessible, but pushed *below* the fold.

### Explore (The Discovery Engine)
This is Quest's answer to the TikTok vertical feed, but with a completely different algorithm. It is a full-screen, immersive, swipeable feed of **experiences**, not just content.
- **The Question:** Instead of asking "What keeps you watching?", the Explore feed asks "What gets you participating?"
- **Actionable Cards:** Every card in the feed has a direct action:
  - Event -> RSVP
  - Community -> Join
  - Challenge -> Accept
  - Marketplace Listing -> Buy
  - Live Stage -> Join
  - Nearby Activity -> Walk there
- **Dynamic Weighting:** The feed adapts to your current life mode (e.g., Exams = Tutors/Study Groups; Vacation = Events/Travel; Freshers Week = Orientations/Icebreakers).

## 2. Navigation Architecture

To support this philosophy, Quest utilizes a 5-tab persistent bottom navigation structure. Everything radiates from Home, and everything new enters through Explore.

| Tab | Icon | Purpose |
|---|---|---|
| **Home** | 🏠 | Mission Control. Focus on immediate goals, XP, and upcoming commitments. |
| **Explore** | 🧭 | The vertical discovery engine for finding new Communities, Events, and Opportunities. |
| **Create** | ➕ | The universal action button for publishing events, creating communities, or listing items. |
| **Inbox** | 💬 | Centralized messaging, group chats, and notifications. |
| **You** | 👤 | The Identity Dashboard. Profile, Reputation, Settings, and Growth Paths. |

## 3. The Experience Economy Integration
Marketplace listings and economic transactions do not live in a siloed "Shop" tab. They are integrated seamlessly into the **Explore** feed and **Home** screen based on proximity and relevance (e.g., a textbook for sale 40m away appears in your Explore feed if you are in a Learning Mode). This makes commerce a natural extension of community participation.
