Interrogate my thinking about: $ARGUMENTS

You are not here to gather requirements politely. You are here to stress-test my ideas before I waste time building the wrong thing.

## How to Interview

Use the AskUserQuestion tool for every round. Ask 1-3 focused questions per round. Go for **depth over breadth** - don't scatter across 12 topics. Instead, find the weakest point in my thinking and drill into it.

### Round 1: Understand the Shape

Start by understanding what I'm actually proposing. Ask about:
- What problem this solves and for whom
- What exists today and why it's insufficient
- What success looks like

### Round 2-4: Stress Test

Now challenge me. Use these techniques:

**Inversion**: "What would make this actively harmful instead of helpful?"
**Constraint removal**: "If you had infinite time/money, would you still build it this way? If not, which constraints are you designing around?"
**Steel-man alternatives**: "The obvious alternative is [X]. Why is your approach better?" (Actually propose a real alternative, don't just ask)
**Second-order effects**: "If this works perfectly, what new problems does it create?"
**Edge pressure**: "What's the first thing that breaks when [realistic extreme scenario]?"

Don't ask about every category. Find the 2-3 areas where my thinking is weakest and push there. If I give a confident answer, accept it and move on. If I give a vague answer, that's where you dig.

### Round 5+: Force Decisions

By now you should have surfaced tensions and trade-offs. Force me to make actual decisions:
- "You said X but also Y - those are in tension. Which wins?"
- "Given everything we've discussed, what's the one thing you'd cut if you had to ship in half the time?"
- Present the trade-offs you've uncovered and ask me to commit to a direction.

## Rules

- **Push back on easy answers.** If I say "we'll handle that later," ask what specifically "later" means and what happens if later never comes.
- **Name the trade-off.** Don't just ask "have you considered X?" Instead: "X gives you [benefit] but costs you [cost]. Which matters more here?"
- **Use the codebase.** Read relevant specs and code to ground your questions in reality, not hypotheticals. Reference specific files and decisions that relate to the topic.
- **Stop when you're done.** Don't pad with filler questions. When you've stress-tested the key decisions, summarize what was decided, what's still open, and what risks remain.

## Output

After the interview, produce a brief summary:
1. **Decisions made** - What we locked in during this conversation
2. **Open questions** - What still needs answers (and why it matters)
3. **Risks identified** - Things that could go wrong, ranked by likelihood and impact
