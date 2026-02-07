# API Versioning Presentation Outline

**Duration:** 20-25 minutes
**Audience:** Development teams, architects, product owners
**Goal:** Get buy-in for versioning guidelines and APIM Version Sets

---

## Slide 1: Title Slide

**Title:** API Versioning Strategy for APIM Integration

**Subtitle:** Solving the "Only v1 Visible" Problem

**Your Name/Team**
**Date**

**Speaker Notes:**
- Welcome everyone
- Quick intro to the topic
- Set expectations: 20 minutes presentation, 10 minutes Q&A

---

## Slide 2: The Problem We're Facing

**Title:** Current State: What's Not Working

**Content:**
- Screenshot: APIM showing only v1
- Screenshot: Swagger UI showing v1, v2 dropdown
- Bullet points:
  - ❌ Multiple versions exist but only v1 visible in APIM
  - ❌ Different teams using different versioning methods
  - ❌ API consumers can't discover newer versions
  - ❌ Increased support burden
  - ❌ Technical debt growing

**Visual:** Side-by-side comparison
- Left: Swagger with version dropdown (what we have)
- Right: APIM with only v1 (what consumers see)

**Speaker Notes:**
- "Has anyone experienced this?"
- "Show of hands: who has multiple API versions?"
- Real example: "Product team has v1 and v2, but customers only see v1"

---

## Slide 3: Why This Matters

**Title:** Business Impact

**Content:**

**For API Consumers:**
- 😕 Can't find new features
- 📉 Stuck on old versions
- ⏱️ Time wasted contacting support

**For Our Teams:**
- 📞 Increased support tickets
- 🐛 Bug fixes needed in multiple versions
- 📚 Duplicate documentation

**For the Business:**
- 💰 Slower feature adoption
- 😞 Poor developer experience
- 🏗️ Growing technical debt

**Speaker Notes:**
- Real cost: "We spend X hours per week answering 'where is v2?'"
- Customer feedback: Share actual quote if available

---

## Slide 4: Root Cause Analysis

**Title:** Why Does This Happen?

**Content:**

**The Missing Piece: APIM Version Sets**

**Diagram:**
```
Without Version Set:
C# API (v1, v2) → Single OpenAPI Spec → APIM Import → Only v1 shows ❌

With Version Set:
C# API (v1, v2) → Separate OpenAPI Specs → APIM Version Set → All versions visible ✅
```

**Key Points:**
- APIM needs explicit Version Set configuration
- Can't infer versions from a combined OpenAPI spec
- Version Sets group related API versions

**Speaker Notes:**
- "This is the core issue - not a bug, it's how APIM works"
- "We've been missing this configuration step"

---

## Slide 5: What Are Version Sets?

**Title:** Understanding APIM Version Sets

**Content:**

**Version Set = Logical Grouping of API Versions**

**Visual: Hierarchy**
```
Products API (Version Set)
├── Products API v1 (/v1/products)
├── Products API v2 (/v2/products)
└── Products API v3 (/v3/products)
```

**Key Characteristics:**
- All versions live simultaneously
- Each has its own URL
- Grouped in APIM portal
- Consumers can choose version

**vs. Revisions:**
- Revisions = non-breaking changes
- Only one revision is "current"
- Same URL

**Speaker Notes:**
- "Think of it like a family - Version Set is the family name"
- Quick poll: "Who's familiar with Version Sets?"

---

## Slide 6: Current State Audit

**Title:** How Are Teams Versioning Today?

**Content:**

**Survey Results:** (Fill in your actual data)

| Team | Method | Works in APIM? |
|------|--------|----------------|
| Team A | Query String | ⚠️ Partial |
| Team B | URL Path | ✅ (with manual config) |
| Team C | Headers | ❌ Not visible |
| Team D | No versioning | N/A |

**Problems Identified:**
- 3 different approaches
- No standardization
- Inconsistent consumer experience
- Manual APIM configuration error-prone

**Speaker Notes:**
- "This variety creates confusion"
- "Support team doesn't know which approach to expect"

---

## Slide 7: The Solution - Three Pillars

**Title:** Our Standardized Approach

**Content:**

**1. URL Path Versioning in C#**
```
/v1/products
/v2/products
```
✅ Visible, cacheable, standard

**2. Separate OpenAPI Specs**
```
/swagger/v1/swagger.json
/swagger/v2/swagger.json
```
✅ One spec per version

**3. APIM Version Sets**
```bicep
- Create Version Set
- Link v1 to Version Set
- Link v2 to Version Set
```
✅ All versions visible

**Speaker Notes:**
- "Three simple requirements"
- "We have templates and examples for all three"

---

## Slide 8: C# Configuration

**Title:** How to Configure Your API

**Content:**

**Required: Asp.Versioning Packages**
```xml
<PackageReference Include="Asp.Versioning.Http" Version="8.0.0" />
<PackageReference Include="Asp.Versioning.Mvc.ApiExplorer" Version="8.0.0" />
```

**Key Configuration:**
```csharp
// 1. URL Segment Versioning
options.ApiVersionReader = new UrlSegmentApiVersionReader();

// 2. Replace {version:apiVersion} in routes
options.SubstituteApiVersionInUrl = true;

// 3. Separate Swagger docs
options.SwaggerDoc("v1", ...);
options.SwaggerDoc("v2", ...);
```

**Controller:**
```csharp
[ApiVersion("1.0")]
[Route("v{version:apiVersion}/products")]
```

**Resources:** Complete example in `/api/VersionedAPI/`

**Speaker Notes:**
- "Don't worry about memorizing this"
- "We have a project template ready to use"

---

## Slide 9: APIM Configuration

**Title:** Setting Up Version Sets

**Content:**

**Step 1: Create Version Set**
```bicep
resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@...' = {
  properties: {
    displayName: 'Products API'
    versioningScheme: 'Segment'  // URL path
  }
}
```

**Step 2: Link APIs to Version Set**
```bicep
resource apiV1 '...' = {
  properties: {
    apiVersion: 'v1'
    apiVersionSetId: versionSet.id  // 🔑 Critical!
    path: 'products'  // Base path, no version prefix
  }
}
```

**Resources:** Bicep templates in `/bicep/modules/`

**Speaker Notes:**
- "This is what we were missing!"
- "Can also do via Azure Portal, but Bicep is reproducible"

---

## Slide 10: Before & After Comparison

**Title:** The Transformation

**Content:**

**Before:**
- Screenshot: APIM showing only "Products API v1"
- Consumer confusion: "Where is v2?"
- Manual questions to support team

**After:**
- Screenshot: APIM showing "Products API" with v1 and v2 grouped
- Clear version selection dropdown
- Self-service discovery

**Metrics:**
- Support tickets: -40% (projected)
- v2 adoption: +60% (projected)
- Developer satisfaction: ↑

**Speaker Notes:**
- "This is what success looks like"
- "Consumers can discover and choose versions themselves"

---

## Slide 11: Migration Path

**Title:** How We Get There

**Content:**

**Three Tracks:**

**Track 1: New APIs**
- Mandatory from Day 1
- Use project template
- Guidelines enforced in PR review

**Track 2: Active APIs**
- Migrate when adding next version
- Timeline: Next 6 months
- Support available

**Track 3: Stable/Legacy APIs**
- Migrate when convenient
- Low priority
- No rush if not actively developing

**Support:**
- Project template ready
- Office hours: Fridays 2-3 PM
- 1:1 pairing available
- Documentation complete

**Speaker Notes:**
- "We're not asking everyone to drop everything"
- "Pragmatic approach based on API lifecycle"

---

## Slide 12: Proposed Guidelines Summary

**Title:** Key Requirements

**Content:**

**Mandatory for All New APIs:**
1. ✅ URL path versioning (`/v1/resource`)
2. ✅ Separate OpenAPI specs per version
3. ✅ APIM Version Sets configured
4. ✅ Semantic versioning (v1, v2, v3)
5. ✅ Migration guides for breaking changes

**When to Create New Version:**
- Breaking changes: Removing/renaming fields, changing types
- NOT for: Bug fixes, optional new fields (use revisions)

**Deprecation:**
- 12 months notice for external APIs
- 6 months for internal APIs
- Clear communication plan

**Full Guidelines:** `/docs/api-versioning-guidelines.md`

**Speaker Notes:**
- "Full document available - this is the summary"
- "Seems like a lot, but templates make it easy"

---

## Slide 13: Success Criteria

**Title:** How We'll Measure Success

**Content:**

**Technical Metrics:**
- 100% of new APIs follow guidelines
- All versions visible in APIM
- Zero "where is v2?" support tickets

**Adoption Metrics:**
- 50% on current version within 6 months
- Decreasing usage of deprecated versions
- Increasing v2+ adoption rate

**Developer Experience:**
- Positive feedback in surveys
- Reduced confusion
- Faster onboarding for new developers

**Timeline:**
- Month 1: Pilot with 2 APIs
- Month 2: Template refinement
- Month 3: All new APIs
- Month 6: Key active APIs migrated

**Speaker Notes:**
- "We'll track these metrics monthly"
- "Adjust guidelines based on feedback"

---

## Slide 14: Pilot Program

**Title:** Let's Prove It Works

**Content:**

**Pilot APIs:** (Select 2)
- API 1: [Name] - Team [X]
- API 2: [Name] - Team [Y]

**Selection Criteria:**
- Has v2 planned or in progress
- Team willing to be early adopter
- Represents common scenario

**Timeline:**
- Week 1: Setup and configuration
- Week 2: Implementation
- Week 3: Testing and APIM deployment
- Week 4: Lessons learned and refinement

**Success Criteria:**
- Both versions visible in APIM ✅
- All tests passing ✅
- Documentation complete ✅
- Positive team feedback ✅

**Speaker Notes:**
- "Looking for volunteers!"
- "We'll provide hands-on support"
- "Your feedback will shape final guidelines"

---

## Slide 15: What We Need From You

**Title:** Decisions Today

**Content:**

**Decision 1: Adopt Guidelines?**
- ☑️ Yes - Mandatory for all new APIs
- ☐ Yes - Recommended with exceptions
- ☐ No - Need more information

**Decision 2: Migration Timeline**
- ☐ Aggressive: All APIs by [Date]
- ☑️ Pragmatic: New APIs now, active APIs within 6 months
- ☐ Gradual: As needed basis

**Decision 3: Pilot Participation**
- Which teams will participate?
- When can we start?

**Decision 4: Ownership**
- Version Sets: [DevOps Team]
- Templates: [Platform Team]
- Guidelines: [Architecture Team]

**Speaker Notes:**
- "Need agreement to move forward"
- "Open to feedback and concerns"

---

## Slide 16: Common Concerns Addressed

**Title:** "But What About...?"

**Content:**

**Concern: "This will slow us down"**
→ *Response:* Templates make it fast. Saves time long-term.

**Concern: "Our API is different"**
→ *Response:* Guidelines cover 95% of cases. Exceptions allowed with approval.

**Concern: "We already have versioning"**
→ *Response:* Keep it, but consumers can't see all versions in APIM.

**Concern: "What about existing APIs?"**
→ *Response:* Migrate when adding next version. No rush for stable APIs.

**Concern: "Too much change at once"**
→ *Response:* Start with pilot, iterate, then roll out gradually.

**Speaker Notes:**
- "These came up in pre-meetings"
- "Happy to discuss more in Q&A"

---

## Slide 17: Resources & Support

**Title:** You're Not Alone

**Content:**

**Available Now:**
- 📚 Complete guidelines document
- 💻 Working C# example project
- 🏗️ Bicep templates
- 📋 Test examples (.http files)
- 📖 Troubleshooting guide
- 🎥 Video walkthrough (coming soon)

**Getting Help:**
- Office hours: Fridays 2-3 PM
- Slack: #api-versioning-help
- 1:1 pairing: Request via Slack
- Email: architecture-team@company.com

**Timeline:**
- Today: Decision on guidelines
- Next week: Pilot kickoff
- Month 1: Pilot complete
- Month 2: Rollout to all teams

**Speaker Notes:**
- "Lots of support available"
- "Not figuring this out alone"

---

## Slide 18: Next Steps

**Title:** What Happens Next

**Content:**

**Immediate (This Week):**
1. ✅ Decisions from this meeting
2. ✅ Select pilot teams
3. ✅ Finalize guidelines based on feedback
4. ✅ Schedule pilot kickoff

**Short-term (Month 1):**
1. Pilot implementation
2. Template refinement
3. Create training materials
4. Update CI/CD pipelines

**Medium-term (Months 2-3):**
1. All new APIs follow guidelines
2. Active APIs begin migration
3. Metrics tracking in place
4. Regular review and iteration

**Long-term (Months 4-6):**
1. Guidelines embedded in process
2. Reduced versioning-related issues
3. Positive developer feedback
4. Considering advanced patterns

**Speaker Notes:**
- "Clear path forward"
- "Measurable milestones"

---

## Slide 19: Call to Action

**Title:** Let's Make This Happen

**Content:**

**Today:**
- ✅ Vote on adopting guidelines
- ✅ Volunteer for pilot program
- ✅ Voice any concerns or questions
- ✅ Commit to support this initiative

**This Week:**
- Read full guidelines document
- Review example code
- Prepare your questions for office hours
- Identify which of your APIs will migrate first

**Quote:**
> "The best time to standardize was when we started.
> The second best time is now."

**Thank you!**

**Questions?**

**Speaker Notes:**
- Open to discussion
- Collect feedback
- Get commitments for pilot

---

## Slide 20: Questions & Discussion

**Title:** Open Discussion

**Content:**

**Guiding Questions:**
- What concerns do you have?
- What would make this easier to adopt?
- What's missing from the guidelines?
- Who wants to volunteer for pilot?

**Format:**
- Open floor
- Capture all feedback
- Parking lot for detailed technical questions

**Next Meeting:**
- Date: [To be scheduled]
- Topic: Pilot results and lessons learned

**Speaker Notes:**
- Encourage honest feedback
- Take notes on common themes
- Schedule follow-ups as needed

---

## Backup Slides

### Backup 1: Detailed Timeline

**Pilot Phase (Month 1):**
- Week 1: Environment setup, template configuration
- Week 2: Implementation in pilot APIs
- Week 3: Testing and APIM deployment
- Week 4: Documentation and lessons learned

**Rollout Phase (Months 2-3):**
- All new APIs use template from Day 1
- Training sessions for all teams
- Office hours for migration support
- Bi-weekly check-ins on progress

**Optimization Phase (Months 4-6):**
- Measure adoption metrics
- Refine based on feedback
- Advanced patterns and optimizations
- Case studies and success stories

---

### Backup 2: Technology Stack Details

**Required Technologies:**
- .NET 8+
- Asp.Versioning.Http 8.0+
- Asp.Versioning.Mvc.ApiExplorer 8.0+
- Azure APIM (any tier)
- Bicep for infrastructure

**Optional:**
- OpenAPI Generator for client SDKs
- Spectral for OpenAPI linting
- REST Client for VS Code testing

---

### Backup 3: Cost-Benefit Analysis

**Costs:**
- Initial setup time: 4-8 hours per API
- Migration time for existing APIs: 2-4 hours each
- Training time: 2 hours per developer
- Template maintenance: 2 hours/month

**Benefits:**
- Reduced support tickets: -40% (est.)
- Faster feature discovery: -50% time to adoption
- Better developer experience: Qualitative improvement
- Reduced technical debt: Prevent future issues
- Consistency: Easier onboarding and maintenance

**ROI:** Positive within 3 months for actively developed APIs

---

### Backup 4: Competitive Analysis

**Industry Standards:**
- Google APIs: URL path versioning
- Stripe API: URL path versioning
- GitHub API: URL path + custom headers
- Microsoft Graph: URL path versioning

**Recommendation:** URL path is industry standard for REST APIs

---

### Backup 5: Technical Architecture

**Detailed flow diagram:**
```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP Request
       ▼
┌─────────────────┐
│  APIM Gateway   │
│  (Version Set)  │
└────┬────┬───────┘
     │    │
     │    │ /v1/*  ──▶  Backend v1
     │    │
     │    └ /v2/*  ──▶  Backend v2
     │
     ▼
  Response
```

---

## Presentation Tips

### Before Presenting

- [ ] Test all demos in advance
- [ ] Have APIM portal open and ready
- [ ] Load example code in IDE
- [ ] Print/share handouts of guidelines
- [ ] Set up virtual whiteboard for notes
- [ ] Test screen sharing
- [ ] Have backup laptop ready

### During Presentation

- [ ] Encourage questions throughout
- [ ] Use concrete examples
- [ ] Show real screenshots, not generic images
- [ ] Keep energy high
- [ ] Watch the clock
- [ ] Capture all concerns
- [ ] Get commitments

### After Presentation

- [ ] Send slides to all attendees
- [ ] Share meeting notes
- [ ] Follow up on action items
- [ ] Schedule pilot kickoff
- [ ] Address concerns individually if needed

---

## Presenter Notes Summary

**Key Messages:**
1. This is a real problem affecting API consumers
2. Solution is proven and straightforward
3. We have all the resources ready
4. Support is available
5. Pragmatic migration path

**Tone:**
- Collaborative, not prescriptive
- "We're in this together"
- Acknowledge challenges
- Emphasize support

**Body Language:**
- Confident but open
- Make eye contact
- Encourage participation
- Positive energy

**Handle Objections:**
- Listen fully
- Acknowledge concern
- Provide factual response
- Offer to discuss offline if needed

**Time Management:**
- 15-20 min presentation
- 10-15 min Q&A
- 5 min decisions and next steps
- Don't rush decisions if more discussion needed

---

Good luck with your presentation! 🎯
