# API Versioning Meeting Plan

## Meeting Details

**Topic:** API Versioning Strategy & Guidelines for APIM Integration
**Duration:** 90 minutes
**Attendees:** Development teams, architects, product owners, DevOps
**Goal:** Establish consistent API versioning standards that work seamlessly with Azure APIM

---

## Meeting Agenda

### 1. Introduction & Context (10 minutes)

**Presenter:** Lead/Architect

**Topics:**
- Current state: What problems are we experiencing?
  - Only v1 visible in APIM despite multiple versions existing
  - Different teams using different versioning approaches
  - Inconsistent APIM imports and configuration
  - Confusion around version sets vs revisions
- Business impact: Why this matters
  - API consumers can't discover newer versions
  - Support burden from outdated API versions
  - Technical debt accumulating
- Meeting objectives: What we'll decide today

**Materials Needed:**
- Screenshots showing current APIM state (only v1 visible)
- Examples of different versioning approaches currently in use

---

### 2. Current State Review (15 minutes)

**Presenter:** Development Team Representatives

**Activity:** Quick survey of current approaches

**Questions to answer:**
1. How many teams have versioned APIs?
2. What versioning methods are teams using?
   - URL path (e.g., /v1/products)
   - Query string (e.g., /products?api-version=1)
   - Headers (e.g., Api-Version: 1)
   - Multiple methods
3. What problems has each team encountered?
4. What's working well?

**Format:** Round-robin, 2 minutes per team

**Capture:** Document on whiteboard/shared screen

---

### 3. Technical Deep Dive (20 minutes)

**Presenter:** Technical Lead

**Topics:**

#### A. Versioning Concepts (5 minutes)
- Semantic versioning (major.minor.patch)
- Version Sets vs Revisions in APIM
  - Version Set: Breaking changes, multiple versions live
  - Revision: Non-breaking changes, only one current
- When to create new version vs revision

#### B. APIM Version Sets (10 minutes)
- What are Version Sets and why they're required
- Live demo: Show APIM with and without Version Sets
- How Version Sets group API versions
- Three versioning schemes: Path, Query, Header

#### C. The Solution (5 minutes)
- Working example walkthrough
- C# configuration that works with APIM
- Bicep templates for automated deployment
- End-to-end flow demonstration

**Materials Needed:**
- Live APIM instance showing both correct and incorrect setups
- Code examples from `/api/VersionedAPI/`
- Architecture diagrams from `/diagrams/`

---

### 4. Proposed Guidelines Presentation (15 minutes)

**Presenter:** Architect/Lead

**Present the proposed guidelines document**

**Key Points to Cover:**
1. **Standardized Approach:** URL path versioning for all teams
2. **C# Configuration:** Required packages and setup
3. **When to Version:** Clear criteria for major versions
4. **APIM Integration:** Version Sets requirements
5. **Deprecation Strategy:** How to sunset old versions
6. **Migration Path:** How existing APIs transition

**Format:** Walk through guidelines document section by section

**Materials Needed:**
- Proposed guidelines document (see separate file)
- Examples of compliant vs non-compliant implementations

---

### 5. Discussion & Concerns (20 minutes)

**Facilitator:** Meeting organizer

**Discussion Points:**

#### A. Technical Concerns (10 minutes)
- "What about our existing APIs using query string versioning?"
- "How much effort to migrate?"
- "What about APIs that don't need versioning?"
- "Performance implications?"
- "Backwards compatibility?"

#### B. Process Concerns (10 minutes)
- "Who maintains Version Sets in APIM?"
- "How do we test versioned APIs?"
- "What's the approval process for new versions?"
- "How do we communicate changes to API consumers?"
- "Timeline for adoption?"

**Format:** Open discussion, capture all concerns

**Action:** Assign owners to each concern for follow-up

---

### 6. Decision Points (10 minutes)

**Facilitator:** Architect/Lead

**Decisions to Make:**

#### Decision 1: Adopt Standard?
**Question:** Do we adopt URL path versioning as the standard?
- ✅ Yes - Adopt as mandatory for all new APIs
- 🔶 Yes - Adopt but allow exceptions with approval
- ❌ No - Need more research

**Vote/Consensus:**

#### Decision 2: Migration Timeline
**Question:** When should existing APIs migrate?
- Option A: All APIs by [Date]
- Option B: New versions only, grandfather old APIs
- Option C: As APIs need updates naturally

**Decision:**

#### Decision 3: Enforcement
**Question:** How do we ensure compliance?
- Option A: PR template checklist
- Option B: Automated CI/CD checks
- Option C: Architecture review gate
- Option D: All of the above

**Decision:**

#### Decision 4: Ownership
**Question:** Who owns what?
- Version Sets in APIM: [Team/Role]
- C# template maintenance: [Team/Role]
- Bicep templates: [Team/Role]
- Documentation: [Team/Role]

**Decision:**

---

### 7. Action Items & Next Steps (10 minutes)

**Facilitator:** Meeting organizer

**Action Items Template:**

| Action | Owner | Due Date | Dependencies |
|--------|-------|----------|--------------|
| Finalize guidelines document | [Name] | [Date] | Decisions from today |
| Create C# project template | [Name] | [Date] | Finalized guidelines |
| Update Bicep deployment pipeline | [Name] | [Date] | DevOps approval |
| Migrate [API Name] as pilot | [Name] | [Date] | Template ready |
| Create developer training | [Name] | [Date] | Pilot complete |
| Update PR checklist | [Name] | [Date] | Guidelines approved |
| Document APIM Version Set process | [Name] | [Date] | - |

**Pilot Program:**
- Select 1-2 APIs for pilot migration
- Timeline: 2 weeks
- Success criteria: Both versions visible in APIM, tests pass
- Lessons learned: Share with all teams

**Communication Plan:**
- Send guidelines to all teams: [Date]
- Host Q&A session: [Date]
- Update wiki/documentation: [Date]
- Include in onboarding for new developers

---

## Pre-Meeting Preparation

### For Meeting Organizer

**1 Week Before:**
- [ ] Send calendar invite with agenda
- [ ] Share pre-reading materials:
  - `/docs/concepts/versioning-complete-guide.md`
  - `/docs/concepts/versioning-troubleshooting.md`
- [ ] Set up shared document for notes
- [ ] Prepare APIM demo environment
- [ ] Compile current state data from teams

**3 Days Before:**
- [ ] Finalize proposed guidelines document
- [ ] Create presentation slides
- [ ] Test demo scenarios
- [ ] Send reminder with agenda

**1 Day Before:**
- [ ] Confirm all presenters ready
- [ ] Test screen sharing/demo setup
- [ ] Print handouts if in-person
- [ ] Set up virtual whiteboard/collaboration tool

### For Attendees (Pre-Reading)

**Required:**
- [ ] Read: `/docs/concepts/versioning-complete-guide.md`
- [ ] Review: Current versioning approach in your API(s)
- [ ] Prepare: 1-2 minute summary of your team's situation

**Optional:**
- [ ] Read: `/docs/concepts/versioning-troubleshooting.md`
- [ ] Explore: `/api/VersionedAPI/` example code

---

## Meeting Materials

### Physical/Shared

- [ ] Proposed guidelines document (printed/digital)
- [ ] Whiteboard or virtual collaboration tool
- [ ] Voting mechanism (hands, poll, etc.)
- [ ] Shared document for notes and action items

### Digital Resources

- [ ] APIM portal access for demo
- [ ] GitHub repository with examples
- [ ] Presentation slides
- [ ] Code examples ready to share screen
- [ ] Architecture diagrams

---

## Presentation Outline

### Slide Deck Structure

**Slide 1: Title**
- API Versioning Strategy & APIM Integration
- Date and attendees

**Slide 2: Current Problems**
- Screenshots of APIM showing only v1
- List of pain points from teams
- Business impact

**Slide 3: What We're Solving**
- Clear version visibility in APIM
- Consistent approach across teams
- Easier API consumer experience
- Reduced support burden

**Slide 4: Versioning Concepts**
- Version Sets vs Revisions
- When to create new version
- Semantic versioning

**Slide 5: The Technical Problem**
- Code example: Current inconsistent approaches
- Diagram: What happens in APIM without Version Sets

**Slide 6: The Solution - C# Configuration**
- Code snippet: Correct Asp.Versioning setup
- Highlight key configuration points

**Slide 7: The Solution - APIM Version Sets**
- Bicep template snippet
- Architecture diagram

**Slide 8: Before & After**
- Side-by-side comparison
- APIM portal screenshots

**Slide 9: Proposed Guidelines Summary**
- Key requirements
- Timeline
- Support resources

**Slide 10: Migration Path**
- Existing APIs: Timeline and approach
- New APIs: Mandatory from day 1
- Support available

**Slide 11: Discussion**
- Open for questions and concerns

**Slide 12: Decisions Needed**
- List of decisions with options

**Slide 13: Next Steps**
- Action items
- Timeline
- Resources

---

## Success Criteria

This meeting is successful if we achieve:

1. ✅ **Shared Understanding**
   - Everyone understands why Version Sets are required
   - Teams know the difference between versions and revisions
   - Clear on what problem we're solving

2. ✅ **Agreement on Standard**
   - Consensus on URL path versioning
   - Approved guidelines document
   - Clear migration path

3. ✅ **Clear Ownership**
   - Assigned owners for action items
   - Defined who manages what
   - Support structure in place

4. ✅ **Pilot Plan**
   - Selected pilot API(s)
   - Timeline established
   - Success criteria defined

5. ✅ **Next Steps Clear**
   - Action items with owners and dates
   - Follow-up meeting scheduled
   - Documentation plan

---

## Follow-Up Actions

### Immediate (Within 1 Week)

- [ ] Send meeting notes to all attendees
- [ ] Publish finalized guidelines
- [ ] Share recording (if recorded)
- [ ] Create tracking board for action items
- [ ] Schedule pilot kickoff

### Short-term (Within 1 Month)

- [ ] Complete pilot migration
- [ ] Hold lessons learned session
- [ ] Update guidelines based on pilot
- [ ] Create developer training materials
- [ ] Update CI/CD pipelines

### Long-term (Within 3 Months)

- [ ] All new APIs following guidelines
- [ ] Migration plan for existing APIs underway
- [ ] Metrics tracking adoption
- [ ] Regular review of guidelines

---

## Potential Objections & Responses

### "This will slow us down"

**Response:**
- Initial setup takes time, but saves time long-term
- Template and automation reduce friction
- Support available during transition
- Pilot will validate timeline estimates

### "Our API is different"

**Response:**
- Guidelines accommodate most scenarios
- Exception process for true edge cases
- Consistency benefits outweigh customization
- Let's discuss your specific needs

### "We already have versioning working"

**Response:**
- It works for you, but consumers can't see all versions in APIM
- Standardization helps the broader ecosystem
- Migration path makes it low-risk
- We can learn from what you've done well

### "Can't we just use query strings?"

**Response:**
- Query strings work but have limitations
- URL paths are more visible and cacheable
- APIM Version Sets work best with URL paths
- Industry best practice

---

## Meeting Facilitation Tips

### Keep on Track
- Assign timekeeper
- Use parking lot for off-topic items
- Focus on decisions, not debates

### Encourage Participation
- Round-robin for team updates
- Anonymous voting if needed
- Call on quiet participants

### Capture Everything
- Designated note-taker
- Action items in real-time
- Decisions documented clearly

### Handle Conflicts
- Focus on business value
- Use data/examples
- Find common ground
- Defer to pilot for unknowns

---

## Resources for Reference During Meeting

- **Complete Guide**: `/docs/concepts/versioning-complete-guide.md`
- **Troubleshooting**: `/docs/concepts/versioning-troubleshooting.md`
- **Example Code**: `/api/VersionedAPI/`
- **Bicep Templates**: `/bicep/modules/api-version-set.bicep`
- **Tests**: `/tests/versioned-api.http`

---

## Post-Meeting Survey (Optional)

Send to attendees:

1. How well do you understand the proposed versioning approach? (1-5)
2. Do you support adopting this standard? (Yes/No/Need more info)
3. What's your biggest concern about implementation?
4. What additional support do you need?
5. Any other feedback?

Use results to refine approach and address concerns.
