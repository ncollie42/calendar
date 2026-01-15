# Claude Code Instructions

## Spec-Driven Development

This is a **spec-driven development** repository. The specs in `specs/` are the source of truth.

### Before implementing any feature:
1. **Update the spec first** - All features, behaviors, and design decisions must be documented in the appropriate spec file before writing code
2. **Workshop unclear requirements** - Use `/workshop` to clarify ambiguities before adding to spec
3. **Get approval on spec changes** - Ensure the spec addition is complete and unambiguous before implementation

### Workflow:
1. Discuss feature requirements with user
2. Draft spec addition with precise details
3. Update the appropriate spec file with the new section
4. Implement code that matches the spec exactly

### Specification files:
- `specs/frontend.md` - Frontend design specification (UI, layout, interactions)
- `specs/backend.md` - Backend server specification (API, data, deployment)
- `specs/hey-library.md` - HEY Calendar library specification (auth, events, sync)

### Generation order:
When generating code from specs, follow this order (due to dependencies):
1. `specs/hey-library.md` - No dependencies
2. `specs/frontend.md` - No dependencies
3. `specs/backend.md` - Depends on hey-library and frontend

### Implementation files:
- `index.html` - Frontend implementation
- `main.go` - Backend server
- `hey/` - HEY Calendar client library

### Environment:
- `env` - Local environment variables for development. Source with `source env` before running.

### Local Development:
```bash
redis-server                  # Terminal 1
source env && go run main.go  # Terminal 2
# Open http://localhost:8080
```
