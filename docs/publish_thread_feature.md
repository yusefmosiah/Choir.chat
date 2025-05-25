# Publish Thread Feature: From Private to Public Discourse

VERSION publish_thread: 1.0 (Public Thread Discovery)

## Overview

The Publish Thread feature enables users to transform private conversations into public discourse by spending CHOIR tokens to make threads discoverable and accessible to the broader Choir community. This creates a natural bridge between intimate AI-enhanced conversations and community knowledge sharing.

## Core Mechanics

### Publishing Process
- **Cost**: Requires CHOIR token payment (amount TBD based on thread length/complexity)
- **Action**: Converts private thread to publicly accessible via unique URL
- **Persistence**: Published threads remain accessible indefinitely
- **Ownership**: Original thread creator retains ownership and moderation rights

### Access Model
- **Public Discovery**: Published threads appear in community feed/search
- **URL Sharing**: Threads can be shared via direct links across devices/platforms
- **Cross-Device Access**: Any device with Choir app can open published thread URLs
- **Continuation**: Anyone can add to published threads (subject to normal CHOIR economics)

## Technical Implementation

### Minimal Changes Required
The feature leverages existing infrastructure with simple authentication modifications:

**Current State**: All threads require wallet authentication to access
**New State**: Published threads bypass authentication requirement for read access

### API Modifications
```
GET /api/threads/{thread_id}
- Current: Requires Sui signature authentication
- Published: Public read access, authentication only required for contributions
```

### Database Changes
```sql
ALTER TABLE threads ADD COLUMN is_published BOOLEAN DEFAULT FALSE;
ALTER TABLE threads ADD COLUMN published_at TIMESTAMP NULL;
ALTER TABLE threads ADD COLUMN publish_cost DECIMAL(18,8) NULL;
```

### URL Structure
```
https://choir.chat/thread/{thread_id}
- Automatically opens in Choir app if installed
- Web fallback for sharing/preview
```

## Economic Design

### Publishing Costs
- **Base Cost**: Minimum CHOIR tokens required (e.g., 10 CHOIR)
- **Length Multiplier**: Additional cost based on thread complexity/length
- **Quality Bonus**: Reduced cost for threads with high citation/novelty scores
- **Burn Mechanism**: Published thread costs are burned, reducing CHOIR supply

### Incentive Alignment
- **Quality Filter**: Token cost ensures only valuable content gets published
- **Creator Investment**: Publishers have skin in the game for thread quality
- **Community Benefit**: High-quality public threads benefit entire ecosystem
- **Deflationary Pressure**: Burning tokens for publishing creates scarcity

## User Experience Flow

### Publishing Flow
1. User completes private conversation with AI
2. "Publish Thread" option appears with cost estimate
3. User confirms payment and thread becomes public
4. Shareable URL generated for cross-platform distribution

### Discovery Flow
1. Published threads appear in community feed
2. Users can search/filter published content
3. Clicking opens thread in full conversation view
4. Users can continue conversation by staking CHOIR tokens

### Sharing Flow
1. Published thread URLs work across devices
2. Links open directly in Choir app if installed
3. Web preview available for non-users
4. Seamless transition from viewing to participating

## Strategic Benefits

### For Individual Users
- **Monetize Insights**: Turn valuable private conversations into public contributions
- **Build Reputation**: Published threads showcase thinking quality
- **Extend Conversations**: Enable broader community engagement with ideas
- **Cross-Platform Sharing**: Share insights beyond Choir ecosystem

### For Community
- **Knowledge Base**: Accumulate high-quality conversations as searchable resource
- **Discovery Mechanism**: Find valuable content and compatible thinkers
- **Quality Curation**: Economic barriers ensure published content meets quality threshold
- **Network Effects**: More published content attracts more users

### For Platform
- **Content Flywheel**: Private conversations become public value
- **User Acquisition**: Shareable URLs bring new users to platform
- **Token Utility**: New use case for CHOIR tokens beyond rewards
- **Viral Mechanics**: Quality content spreads organically through sharing

## Relationship to Core Features

### Enhances Relationship Staking
- Published threads become venues for relationship formation
- Users can stake tokens to respond to published insights
- Quality published content attracts high-value relationship opportunities

### Amplifies Citation Rewards
- Published threads increase citation opportunities
- Authors earn rewards when published content is referenced
- Creates incentive cycle: publish → get cited → earn tokens → publish more

### Supports Anonymous Discourse
- Published threads maintain anonymity while enabling attribution
- Wallet-based identity emerges through published content quality
- Reputation builds through contribution value, not social metrics

## Implementation Phases

### Phase 1: Basic Publishing
- Simple publish button with fixed CHOIR cost
- Public thread access without authentication
- Basic URL sharing functionality

### Phase 2: Enhanced Discovery
- Community feed of published threads
- Search and filtering capabilities
- Quality-based ranking algorithms

### Phase 3: Advanced Features
- Dynamic pricing based on thread quality
- Thread collections and curation tools
- Integration with relationship staking for published content

## Success Metrics

### Engagement Metrics
- **Publish Rate**: Percentage of private threads that get published
- **View Rate**: Average views per published thread
- **Continuation Rate**: Percentage of published threads that receive responses

### Quality Metrics
- **Citation Rate**: How often published threads get referenced
- **Token Efficiency**: Relationship between publish cost and thread value
- **User Retention**: Impact of published content on user engagement

### Network Effects
- **Viral Coefficient**: How often published threads get shared externally
- **User Acquisition**: New users arriving via published thread URLs
- **Cross-Platform Reach**: Published content impact beyond Choir app

## Conclusion: Bridging Private and Public Discourse

The Publish Thread feature creates a natural evolution from private AI-enhanced conversations to public community discourse. By requiring CHOIR token investment, it ensures quality while creating new utility for the token economy.

This feature transforms Choir from a private AI chat app into a platform for public intellectual discourse, where the best private conversations become community resources. The economic design aligns individual incentives (sharing valuable insights) with community benefits (access to quality content) and platform growth (viral sharing and user acquisition).

Most importantly, it maintains Choir's core values: anonymous merit-based discourse, economic alignment through token mechanics, and AI that amplifies rather than replaces human connection. Published threads become venues for discovering like minds and forming meaningful relationships based on intellectual compatibility rather than social metrics.
