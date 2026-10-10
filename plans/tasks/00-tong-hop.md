# Tổng hợp task — AM (Agent Manage)

Plan gốc: [`../2026-10-10-agent-task-management.md`](../2026-10-10-agent-task-management.md)

**Trạng thái:** mới có danh sách. File task riêng sẽ được `business-analyst` tạo từ
[`_TEMPLATE.md`](_TEMPLATE.md) sau khi chốt các Open questions trong plan. Mỗi task là một file;
tiến độ, nhật ký agent và công nghệ mới nằm ở **đầu file** — xem `.claude/rules/task-tracking.md`.

## Cách agent làm một task

1. Đọc file task và kiểm tra `depends_on` đã `done` hết chưa. Chưa → ghi `blocker`, không làm lấn.
2. Cập nhật header: `status: in-progress`, `assignee`, `started_at`; ghi nhật ký `start`.
3. Tạo branch: `feature/am-T05-agent-task-entity`.
4. Làm theo **Việc cần làm**; mỗi tiêu chí tick xong → cập nhật `progress` + nhật ký `progress`.
5. Công nghệ lần đầu dùng → thêm vào bảng `## Công nghệ áp dụng`; ngoài tech-defaults → `proposed`, dừng chờ duyệt.
6. Trước khi bàn giao: `dotnet build`, `dotnet test`, `dotnet format` qua → `handoff` sang tester/reviewer.
7. Reviewer đạt → `status: done`, `progress: 100`, `done_at`, nhật ký `done`.

## Danh sách task (dự kiến)

| Mã | Task | Layer | Phụ thuộc | Ước lượng |
|---|---|---|---|---|
| T01 | Chạy solution, PostgreSQL local, cài runtime .NET 9 | — | — | 0.5 ngày |
| T02 | Tạo `Domain.Tests`, `Application.Tests` | Test | T01 | 0.5 ngày |
| T03 | Thêm NuGet packages (sau khi duyệt YamlDotNet/Testcontainers) | — | T01 | 0.5 ngày |
| T04 | Enum trạng thái/loại + `DomainException` | Domain | T02 | 0.5 ngày |
| T05 | Entity `Project` | Domain | T04 | 0.5 ngày |
| T06 | Entity `AgentTask`: chuyển trạng thái, tiêu chí, progress | Domain | T05 | 1.5 ngày |
| T07 | `AgentNote` + câu hỏi/trả lời | Domain | T06 | 0.5 ngày |
| T08 | `TechAdoption` + duyệt/từ chối | Domain | T06 | 0.5 ngày |
| T09 | Interface, exception, DTO, validator, `AddApplication` | Application | T07, T08 | 1 ngày |
| T10 | `ProjectService` | Application | T09 | 0.5 ngày |
| T11 | `TaskProgressService` | Application | T09 | 1 ngày |
| T12 | `TechAdoptionService`, `QuestionService` | Application | T09 | 1 ngày |
| T13 | `TaskSyncService` (đồng bộ từ `ParsedTask`) | Application | T09 | 1.5 ngày |
| T14 | `OverviewQuery` | Application | T09 | 1 ngày |
| T15 | `AppDbContext`, mapping, migration `InitialAgentManage` | Infrastructure | T03, T08 | 1.5 ngày |
| T16 | Repository, `UnitOfWork`, `SystemClock`, `AddInfrastructure` | Infrastructure | T15 | 1 ngày |
| T17 | `MarkdownTaskFileReader` + test với file mẫu | Infrastructure | T03, T09 | 1.5 ngày |
| T18 | Exception middleware → ProblemDetails | WebAPI | T09 | 0.5 ngày |
| T19 | `ProjectsController`, `TasksController` | WebAPI | T10, T11, T13, T14, T16, T18 | 1 ngày |
| T20 | `TechController`, `QuestionsController`; xóa WeatherForecast | WebAPI | T12, T18 | 0.5 ngày |
| T21 | Chuyển 31 task của Auth sang template mới | Docs | — (chờ duyệt) | 0.5 ngày |
| T22 | Integration test sync Auth → overview | Test | T17, T19, T20, T21 | 1.5 ngày |
| T23 | Kiểm tra cuối + `architect-doc` sync rules | Docs | T22 | 0.5 ngày |

**Tổng ước lượng:** khoảng 19 ngày công cho một agent làm tuần tự. Nhánh Application
(T10–T14) và nhánh Infrastructure (T15–T17) có thể chạy song song sau T09.
