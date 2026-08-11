# Contributing to Binance USDM Ruby SDK

Thank you for contributing to the Binance USDM Ruby SDK!

## Development Setup

```bash
git clone https://github.com/shubhamtaywade82/binance_usdm.git
cd binance_usdm
bundle install
bundle exec rake
```

## Running Tests

```bash
bundle exec rake spec
```

## Running Lint

```bash
bundle exec rubocop
```

## Running All Checks

```bash
bundle exec rake check
```

This runs:
- RuboCop linting
- Dependency security audit
- RSpec tests
- Gem build

## Pull Request Guidelines

1. **Add tests** for new behavior or bug fixes
2. **Keep the public API backward-compatible** unless the change is intentionally breaking
3. **Update documentation** (YARD comments and README)
4. **Use clear commit messages** following Conventional Commits:
   - `fix:` for bug fixes
   - `feat:` for new features
   - `docs:` for documentation changes
   - `chore:` for maintenance tasks
   - `refactor:` for code refactoring
5. **Ensure CI passes** before requesting review
6. **Update CHANGELOG.md** for user-facing changes

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **PATCH** (0.1.x): Backward-compatible bug fixes
- **MINOR** (0.x.0): Backward-compatible new features
- **MAJOR** (x.0.0): Breaking changes

Pre-1.0 versions may contain breaking changes, but all breaking changes will be documented in CHANGELOG.md.

## Code Style

This project uses RuboCop with custom configuration. Run:

```bash
bundle exec rubocop -a
```

to auto-correct style violations.

## Testing Philosophy

### Unit Tests
Test pure logic:
- Signature generation
- Timestamp handling
- BigDecimal serialization
- Order parameter validation
- WebSocket event parsing

### Contract Tests
Use VCR cassettes to record Binance API responses for deterministic testing.

### Integration Tests
Optional tests against Binance Testnet (run manually or on schedule).

## Questions?

Open an issue for questions or discussions about proposed changes.
