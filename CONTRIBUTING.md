# Contributing to spec-kit-archive-extension

Thank you for your interest in contributing! This project aims to eventually integrate with [spec-kit](https://github.com/context7-labs/spec-kit) core, so we appreciate all contributions that help us reach that goal.

## 🎯 Project Goals

1. **Production-Ready**: Ensure the extension works reliably across different projects
2. **Community Validation**: Gather feedback and use cases from multiple projects
3. **Integration Path**: Build towards official spec-kit integration
4. **Documentation**: Maintain clear, comprehensive documentation

## 🚀 How to Contribute

### 1. Use It in Your Project

The best contribution is **real-world usage**:

```bash
# Install in your Spec-Kit project
./install.sh --target /path/to/your-project

# Use it and report your experience
```

**Please share**:
- What worked well
- What was confusing
- Edge cases you encountered
- Your constitution.md examples

### 2. Report Issues

Found a bug or have a suggestion? [Open an issue](https://github.com/YOUR_USERNAME/spec-kit-archive-extension/issues)!

**Good bug reports include**:
- Your project structure (anonymized if needed)
- Steps to reproduce
- Expected vs actual behavior
- Relevant constitution.md sections
- Merge rules configuration

**Feature requests should explain**:
- The use case
- Why current functionality doesn't address it
- How it would help your project

### 3. Improve Documentation

Documentation improvements are always welcome:

- Fix typos or unclear explanations
- Add examples from your projects
- Translate to other languages
- Create video tutorials or blog posts

### 4. Share Constitution Examples

Help others by sharing your `constitution.md` structure:

- What principles work well for your project type?
- What merge strategies did you customize?
- What patterns should others adopt or avoid?

Submit as:
- Pull request to `examples/constitutions/`
- Gist linked in Discussions
- Blog post (we'll link to it)

### 5. Code Contributions

Before major changes, please:
1. Open an issue to discuss the approach
2. Ensure it aligns with spec-kit integration goals
3. Add tests if applicable
4. Update documentation

## 🛠 Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/spec-kit-archive-extension.git
cd spec-kit-archive-extension

# Test locally
./install.sh --target /path/to/test-project

# Run tests (when available)
bash tests/test-merge.sh
```

## 📝 Coding Standards

### Shell Scripts

- Use `bash` (not `sh`)
- Include `set -euo pipefail` at the top
- Add comments for complex logic
- Follow existing code style
- Use `shellcheck` if available

### Documentation

- Use clear, concise language
- Include examples
- Keep line length reasonable (~80-100 chars)
- Use markdown features (tables, code blocks, etc.)

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(merge): add support for custom entity patterns
fix(install): handle spaces in project paths
docs(readme): add constitution setup examples
test(merge): add Japanese section name tests
```

## 🔄 Pull Request Process

1. **Fork** the repository
2. **Create a branch** with a descriptive name:
   - `feat/custom-merge-strategies`
   - `fix/install-path-handling`
   - `docs/constitution-examples`
3. **Make your changes**
4. **Test** with real projects if possible
5. **Submit PR** with clear description

**PR Description should include**:
- What problem it solves
- How it was tested
- Any breaking changes
- Screenshots if UI/output changed

## 🎯 spec-kit Integration Path

Our goal is to contribute this back to spec-kit. To support this:

### Design Principles

- **Minimal Dependencies**: Use bash, awk, standard Unix tools
- **Spec-Kit Compatible**: Follow spec-kit conventions
- **Backward Compatible**: Don't break existing workflows
- **Well Documented**: Every decision should have a rationale

### Integration Checklist

For a feature to be integration-ready:
- [ ] Works across multiple project types
- [ ] Has clear documentation
- [ ] Includes tests
- [ ] No project-specific assumptions
- [ ] Follows spec-kit philosophy

## 🌟 Recognition

Contributors will be:
- Listed in README.md
- Mentioned in release notes
- Credited in spec-kit PR (if integrated)

## 📞 Communication

- **Quick questions**: [Discussions](https://github.com/YOUR_USERNAME/spec-kit-archive-extension/discussions)
- **Bugs**: [Issues](https://github.com/YOUR_USERNAME/spec-kit-archive-extension/issues)
- **Major changes**: Open an issue first to discuss

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Every contribution helps make this tool better for the entire Spec-Kit community. Whether it's code, documentation, bug reports, or just using it in your project, we appreciate it!

---

**Questions?** Open a [Discussion](https://github.com/YOUR_USERNAME/spec-kit-archive-extension/discussions) or reach out to the community.

