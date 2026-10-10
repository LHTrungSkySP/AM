# Plan: AM — Quản lý task do agent thực hiện

## Goal
Các dự án (vd Auth) được agent lập plan rồi chia thành task trong `plans/tasks/`; agent cũng là
bên làm task. Người cần một chỗ để theo dõi mà không phải mở từng file:
- Mỗi task đang ở trạng thái nào, tiến độ bao nhiêu %, agent nào đang giữ.
- Agent đã ghi chú gì: quyết định, chỗ bị chặn, câu hỏi chờ người trả lời, bàn giao.
- Công nghệ mới nào được đưa vào, ở task nào, vì sao, đã được duyệt chưa.

## Quyết định đề xuất (chờ người chốt — xem Open questions)
- **Nguồn sự thật là file task trong repo** (frontmatter + `## Nhật ký agent` +
  `## Công nghệ áp dụng`, mẫu `plans/tasks/_TEMPLATE.md`). Agent đang làm việc với file và git
  nên ghi ở đó là tự nhiên nhất, có lịch sử qua git. AM **đọc và đồng bộ** vào DB để truy vấn,
  tổng hợp, theo dõi qua nhiều dự án.
- Hành động của **người** (duyệt/từ chối công nghệ, trả lời câu hỏi, gỡ chặn) đi qua API của AM
  và lưu trong DB của AM; ở bước sau AM có thể ghi ngược vào file task.
- DB: PostgreSQL + EF Core, giống Auth.

## Scope
In (MVP):
- Đăng ký dự án (key, tên, đường dẫn repo, thư mục task).
- Đồng bộ task từ file Markdown: parse frontmatter, nhật ký, bảng công nghệ, checklist tiêu chí.
- API cập nhật tiến độ cho agent (start, progress, note, block, handoff, complete) — để agent ở
  nơi không có file vẫn ghi được.
- Duyệt/từ chối công nghệ mới; trả lời câu hỏi của agent.
- Truy vấn tổng quan: theo dự án (% hoàn thành, task bị chặn, câu hỏi đang mở, công nghệ chờ duyệt),
  timeline nhật ký, danh mục công nghệ mới theo dự án.
- Chuyển định dạng 31 task của Auth sang template mới (chỉ thêm header, không đổi nội dung).

Out (làm sau): giao diện web, đăng nhập (dự kiến dùng JWT từ dự án Auth), ghi ngược vào file
task, MCP server để agent gọi trực tiếp, thông báo realtime, tự động dispatch agent.

## Design

### Domain
- `Project` — `Key` (unique, vd `AUTH`), `Name`, `RepoPath`, `TasksPath`.
- `AgentTask` — `ProjectId`, `Code` (unique trong project, vd `T11`), `Title`, `Phase`, `Layer`,
  `Status` (`Todo | InProgress | Blocked | Review | Done`), `Assignee`, `DependsOn` (mã task),
  `Estimate`, `StartedAt`, `UpdatedAt`, `DoneAt`, `Criteria` (danh sách tiêu chí + đã tick),
  `SourceFile`, `SourceHash`.
  - `Progress` tính từ `Criteria` (tick / tổng), không nhập tay.
  - Hành vi: `Start(agent, now, depsDone)` (không cho start khi phụ thuộc chưa xong),
    `CheckCriterion`, `Block(reason)`, `Handoff(toAgent)`, `SubmitForReview`, `Complete(now)`
    (chỉ khi mọi tiêu chí đã tick), `Reopen`.
- `AgentNote` — chỉ thêm, không sửa: `TaskId`, `Agent`, `Kind`
  (`Start | Progress | Decision | Blocker | Question | Handoff | Done`), `Content`, `CreatedAt`;
  với `Question`: `Answer`, `AnsweredBy`, `AnsweredAt`.
- `TechAdoption` — `TaskId`, `Name`, `Version`, `Category` (`Library | Pattern | Tool | Service`),
  `Reason`, `Status` (`Proposed | Approved | Rejected`), `DecidedBy`, `DecidedAt`, `DecisionNote`.
  Hành vi `Approve/Reject` chỉ từ `Proposed`.

### Application
- Interface: `IProjectRepository`, `ITaskRepository`, `IUnitOfWork`, `IClock`,
  `ITaskFileReader` (liệt kê + đọc file task của một project, trả `ParsedTask` — DTO thuần,
  không lộ kiểu của thư viện parse).
- Use case: `ProjectService` (CRUD), `TaskSyncService` (đọc file → tạo/cập nhật task, nhận
  nhật ký mới theo (thời gian, agent, nội dung), bỏ qua file không đổi hash), `TaskProgressService`
  (các hành động của agent), `TechAdoptionService` (đề xuất, duyệt, từ chối),
  `QuestionService` (trả lời câu hỏi), `OverviewQuery` (tổng quan theo dự án).
- DTO + FluentValidation; exception nghiệp vụ `NotFound/Conflict/Validation`.

### Infrastructure
- `AppDbContext` + configuration, index unique (`Project.Key`; `ProjectId+Code` của task),
  migration `InitialAgentManage`.
- Repository + `UnitOfWork`, `SystemClock`.
- `MarkdownTaskFileReader`: tách frontmatter YAML, parse dòng nhật ký theo regex
  `^- (\d{4}-\d{2}-\d{2} \d{2}:\d{2})Z · (\S+) · (\w+) — (.+)$`, bảng công nghệ, checklist
  `- [ ]` / `- [x]` trong `## Tiêu chí hoàn thành`. File sai định dạng → ghi cảnh báo, không làm
  hỏng cả lần sync.

### WebAPI
- `ProjectsController` — `GET/POST /api/projects`, `POST /api/projects/{key}/sync`,
  `GET /api/projects/{key}/overview`.
- `TasksController` — `GET /api/projects/{key}/tasks?status=&assignee=`,
  `GET /api/projects/{key}/tasks/{code}` (kèm nhật ký + công nghệ),
  `POST .../{code}/start|block|handoff|complete`, `POST .../{code}/notes`.
- `TechController` — `GET /api/tech?status=proposed`, `POST /api/tech/{id}/approve|reject`.
- `QuestionsController` — `GET /api/questions?open=true`, `POST /api/questions/{id}/answer`.
- Exception middleware → ProblemDetails; xóa WeatherForecast mẫu.

### Test
- `Domain.Tests` (luật chuyển trạng thái, tính progress), `Application.Tests` (sync, các use
  case), test parser với file mẫu (gồm một file thật của Auth), integration test luồng
  sync → overview.

## Steps
1. Chuẩn bị: test projects, packages (sau khi chốt Open questions).
2. Domain + Domain.Tests.
3. Application + Application.Tests.
4. Infrastructure: DbContext, migration, repository, `MarkdownTaskFileReader`.
5. WebAPI: controllers, ProblemDetails.
6. Chuyển 31 task của Auth sang template mới; đăng ký Auth vào AM và chạy sync thử.
7. Integration test; `dotnet build`, `dotnet test`, `dotnet format`; `architect-doc` sync rules.

## Open questions
| Câu hỏi | Đề xuất | Ảnh hưởng |
|---|---|---|
| Nguồn sự thật: file task hay DB của AM? | File task; AM đồng bộ, hành động của người lưu ở AM | Toàn bộ thiết kế sync |
| Parse frontmatter YAML bằng gì? | `YamlDotNet` (công nghệ mới, cần duyệt) | Parser |
| Integration test với DB thật | Testcontainers.PostgreSql (cần duyệt) | Test |
| Được phép chỉnh 31 file task của Auth sang template mới? | Có, chỉ thêm header, không đổi nội dung | Bước 6 |
| Giữ `net9.0` dù máy chỉ có SDK 10? | Giữ cho đồng bộ với Auth; cài runtime 9 để chạy/test | Mọi project |
| Có cần đăng nhập ở MVP? | Không; sau dùng JWT của Auth | WebAPI |
