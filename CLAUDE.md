# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## AM là gì

AM (Agent Manage) giúp **người theo dõi các task do agent thực hiện**. Task được agent tạo ra
(như 31 task trong dự án `../Auth/plans/tasks/`) và cũng do agent làm. Người cần biết, cho mỗi
task: tiến độ tới đâu, agent đã ghi chú/quyết định gì, đang kẹt ở đâu, và công nghệ mới nào
được đưa vào. Plan: `plans/2026-10-10-agent-task-management.md`.

Chính dự án này cũng làm theo cách đó: mọi task trong `plans/tasks/` có header tiến độ do agent
tự cập nhật — **đọc `.claude/rules/task-tracking.md` trước khi nhận task.**

## Tech Stack

- .NET 9 (`net9.0`) + ASP.NET Core
- Clean Architecture: Domain / Application / Infrastructure / WebAPI
- Entity Framework Core + PostgreSQL (Npgsql) cho persistence
- xUnit + NSubstitute cho unit test, `WebApplicationFactory` cho integration test (chưa có test project nào)
- FluentValidation cho validate input ở Application layer
- `Microsoft.Extensions.Logging` (ILogger) cho logging

Không tự ý thêm dependency ngoài danh sách trên — ghi vào task ở trạng thái `proposed` và hỏi
trước (xem `.claude/rules/tech-defaults.md` và `.claude/rules/task-tracking.md`).

## Commands

Run all commands from the repo root (where `AgentManage.slnx` lives).

```bash
dotnet build                              # build entire solution
dotnet run --project WebAPI               # run the API (see WebAPI/Properties/launchSettings.json for ports)
dotnet watch --project WebAPI run         # run with hot reload
dotnet test                               # run all tests (no test project exists yet)
dotnet test --filter "FullyQualifiedName~ClassName.MethodName"   # run a single test, once test projects exist
dotnet format                             # format theo .editorconfig
```

There is no `.sln` file — `AgentManage.slnx` is the new XML-based solution format. `dotnet sln`, `dotnet build`, and `dotnet test` all accept it directly.

Máy dev hiện chỉ có SDK 10: build `net9.0` được, nhưng `dotnet run`/`dotnet test` cần runtime .NET 9 (hoặc đổi target sau khi người quyết).

## Architecture

Clean Architecture layering across 4 projects, all targeting `net9.0`. Dependency direction strictly inward:

```
WebAPI → Infrastructure, Application → Domain
```

- **Domain** — no project references. Entities (`Project`, `AgentTask`, `AgentNote`, `TechAdoption` theo plan), value objects, domain logic.
- **Application** — references `Domain` only. Use cases, interfaces cho repository, đọc file task (`ITaskFileReader`), clock... mà `Infrastructure` sẽ implement.
- **Infrastructure** — references `Domain` và `Application`. EF Core, repository, parser Markdown/frontmatter của file task.
- **WebAPI** — references `Application` và `Infrastructure`. Composition root (DI trong `Program.cs`), controllers mỏng.

`Domain` và `Application` không bao giờ được reference `Infrastructure` hay `WebAPI`. Chi tiết và các red flag cần bắt khi review nằm ở `.claude/rules/design.md`.

The solution is currently a bare scaffold: `Domain`, `Application`, and `Infrastructure` are empty class libraries, and `WebAPI` still has the default ASP.NET Core template (`WeatherForecastController`).

## Cấu trúc thư mục

- `Domain/` — Entities, value objects, domain logic. Không có project reference nào ra ngoài.
- `Application/` — Use cases (service), interfaces, DTOs, validators (FluentValidation), exception nghiệp vụ.
- `Infrastructure/` — EF Core `DbContext` + migrations, repository, đọc/parse file task trong repo khác.
- `WebAPI/` — Controllers (mỏng), `Program.cs`, `appsettings*.json`, exception handling middleware tập trung.
- `plans/` — plan cho feature không nhỏ (xem `plans/README.md`); `plans/tasks/` — task chia nhỏ, mẫu ở `plans/tasks/_TEMPLATE.md`.

## Quy tắc code

- Theo layered/Clean Architecture: Controller → Application (use case) → Domain/Infrastructure qua interface.
- Dùng constructor injection, không dùng service locator hay static singleton.
- Mỗi public method ở Application nên có unit test tương ứng.
- Exception handling tập trung qua middleware, không bắt lỗi rải rác trong controller.
- Logging bằng `ILogger<T>`, không dùng `Console.WriteLine`.
- Nullable reference types bật ở tất cả project — không suppress bằng `!` trừ khi thực sự không tránh được.
- Thời gian lưu UTC (`DateTimeOffset`), lấy qua `IClock` để test được.

## Quy trình làm việc

1. Trước khi code: `dotnet build` để chắc solution compile được.
2. Nhận task: cập nhật header file task (`status`, `assignee`, nhật ký `start`) — `.claude/rules/task-tracking.md`.
3. Trước khi commit: `dotnet test` (và `dotnet format`) — xem `.claude/hooks/pre-commit.sh` / `pre-push.sh` (wire bằng `git config core.hooksPath .claude/hooks`).
4. Dùng conventional commits: `feat/fix/chore/docs/refactor/test`.
5. Non-trivial feature: viết plan trong `plans/` trước khi code.
6. Dispatch đúng subagent cho từng việc — xem mục "Specialized subagents".

## Không được làm

- Không push `--force` hay commit thẳng lên `main` nếu chưa được yêu cầu rõ ràng.
- Không xóa/sửa EF Core migration đã apply.
- Không để business logic trong Controller.
- Không để interface của `Application` leak type của `Infrastructure` vào signature.
- Không skip git hook bằng `--no-verify` trừ khi người dùng yêu cầu rõ ràng.
- Không thêm package đang ở trạng thái `proposed` khi người chưa duyệt.
- **AM chỉ đọc file task của dự án khác** (vd `../Auth/plans/tasks/`) — không ghi vào repo khác trừ khi plan/task nói rõ.

## Database

PostgreSQL + EF Core (Npgsql), cùng lựa chọn với dự án Auth. Migration trong `Infrastructure` (`dotnet ef migrations add {Name}`), connection string qua user-secrets, không commit. Chưa có migration nào.

## Plans

Check `plans/` for existing context before starting work on a feature. Task tổng hợp: `plans/tasks/00-tong-hop.md`.

## Rules

`.claude/rules/` holds the detailed rules that back this file — read them before non-trivial work:

- **task-tracking.md** — header tiến độ / nhật ký agent / công nghệ mới ở đầu mỗi task; khi nào agent phải cập nhật.
- **workflow.md** — dev workflow, subagent dispatch, commit/push conventions.
- **design.md** — Clean Architecture layering rules and the red flags a review should catch.
- **tech-defaults.md** — công nghệ đã duyệt; thứ ngoài danh sách là "công nghệ mới" cần duyệt.

## Memory

`.claude/memory/` holds durable, project-specific notes that aren't obvious from the code. `CLAUDE.local.md` (gitignored) is for personal notes.

## Specialized subagents

`.claude/agents/` — mọi agent làm task đều phải ghi tiến độ vào header task:

- **business-analyst** — làm rõ yêu cầu, viết plan trong `plans/`, chia task theo `_TEMPLATE.md`. Không viết code.
- **researcher** — read-only. Nghiên cứu kỹ thuật, đề xuất công nghệ kèm dòng `proposed` để dán vào task.
- **coder** — implement across the four layers.
- **tester** — writes/runs unit and integration tests.
- **reviewer** — review diff; chỉ được ghi nhật ký review vào file task.
- **architect-doc** — sync `.claude/rules/` và `CLAUDE.md` với code. Chỉ ghi trong `.claude/` và `CLAUDE.md`.

## Skills

`.claude/skills/security-scan/` — scans for known-vulnerable NuGet packages and formatting drift; run before a PR or after touching dependencies.
