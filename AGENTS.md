# Project Rules

## Commit Messages

Use Conventional Commits style:

- `feat:` 新功能
- `fix:` 修复问题
- `docs:` 文档修改
- `test:` 测试相关
- `refactor:` 代码重构
- `chore:` 杂项维护

## Fingerprint Direction Convention

The displayed direction field must represent fingerprint ridge tangent direction, not the raw Sobel gradient normal. After Sobel/CORDIC orientation calculation, preserve the verified horizontal and vertical axis mappings, and rotate non-axis/oblique bins by 90 degrees so HDMI/preview line segments follow the fingerprint ridges.
