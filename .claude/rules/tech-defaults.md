# Tech defaults

Đây là danh sách công nghệ **đã được duyệt** cho AM. Thứ gì ngoài danh sách này là "công nghệ
mới": phải ghi vào bảng `## Công nghệ áp dụng` của task với trạng thái `proposed` và chờ người
duyệt trước khi thêm (xem `.claude/rules/task-tracking.md`). Khi được duyệt, bổ sung vào đây.

- **Target framework**: `net9.0` everywhere (already set in all four `.csproj`; máy dev có thể
  chỉ cài SDK 10 — SDK 10 build được `net9.0`, chạy cần runtime 9).
- **Testing**: xUnit + `Microsoft.NET.Test.Sdk`, NSubstitute cho mock, một test project mỗi
  layer cần coverage (`Domain.Tests`, `Application.Tests`), `WebApplicationFactory` cho
  integration test.
- **Persistence**: Entity Framework Core + PostgreSQL (Npgsql) trong `Infrastructure`, sau
  repository interface khai báo ở `Application` — giống dự án Auth. Không để `DbContext` hay
  EF type lọt vào `Application`/`Domain`.
- **Validation**: FluentValidation in `Application` for use-case input validation.
- **Logging**: built-in `Microsoft.Extensions.Logging`; no Serilog/NLog unless there's a
  concrete need.
- **API docs**: `Microsoft.AspNetCore.OpenApi` (đã có từ template).
- **Nullable reference types**: enabled everywhere — don't suppress with `!` unless
  genuinely unavoidable.

## Đang chờ duyệt (xem `plans/2026-10-10-agent-task-management.md`, mục Open questions)
- `YamlDotNet` — parse frontmatter YAML của file task.
- Testcontainers.PostgreSql — DB thật cho integration test.
