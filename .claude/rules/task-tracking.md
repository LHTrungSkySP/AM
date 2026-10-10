# Task tracking — agent tự ghi tiến độ vào đầu file task

Task trong `plans/tasks/` do agent thực hiện, người theo dõi. Vì vậy **phần đầu mỗi file task
là nguồn sự thật về tiến độ**: frontmatter YAML + mục `## Nhật ký agent` + mục
`## Công nghệ áp dụng`. Mẫu: `plans/tasks/_TEMPLATE.md`. AM (chính dự án này) sẽ đọc các
file này để dựng dashboard, nên giữ đúng định dạng.

## Khi nào phải cập nhật

| Thời điểm | Frontmatter | Nhật ký |
|---|---|---|
| Nhận task | `status: in-progress`, `assignee`, `started_at`, `updated_at` | `start` — hiểu task thế nào, định làm theo hướng nào |
| Xong một bước đáng kể / tick một tiêu chí | `progress`, `updated_at` | `progress` — đã làm gì, còn gì |
| Chọn giữa nhiều phương án | `updated_at` | `decision` — chọn gì, vì sao, bỏ phương án nào |
| Bị chặn (thiếu quyết định, phụ thuộc chưa xong, lỗi môi trường) | `status: blocked` | `blocker` — kẹt ở đâu, cần ai làm gì |
| Cần người trả lời ("hỏi lead", "chờ xác nhận") | giữ nguyên status | `question` — câu hỏi cụ thể + phương án đề xuất |
| Chuyển cho agent khác (coder → tester → reviewer) | `assignee` mới, `status: review` nếu chờ review | `handoff` — bên nhận cần biết gì |
| Hoàn thành (mọi tiêu chí đã tick, build/test xanh) | `status: done`, `progress: 100`, `done_at` | `done` — tóm tắt kết quả, lệch so với task (nếu có) |

## Quy tắc

- `progress` = số tiêu chí đã tick / tổng tiêu chí × 100, làm tròn xuống. Không tự ước lượng.
- Không đặt `done` khi còn tiêu chí chưa tick hoặc `dotnet build`/`dotnet test` chưa xanh.
- Không bắt đầu task khi `depends_on` còn task chưa `done` — ghi `blocker` thay vì làm lấn.
- Nhật ký chỉ thêm, không sửa/xóa mục cũ; mục mới nhất ở trên cùng. Thời gian là UTC.
- Mỗi dòng nhật ký đúng định dạng: `- 2026-10-10 14:30Z · coder · progress — nội dung`.
- **Công nghệ mới**: mỗi thư viện/pattern/tool lần đầu xuất hiện trong codebase phải có một dòng
  trong bảng `## Công nghệ áp dụng` và tên trong `tech:` ở frontmatter. Thứ nằm ngoài
  `.claude/rules/tech-defaults.md` ghi trạng thái `proposed` và ghi `question` vào nhật ký —
  chưa được thêm package cho tới khi người đổi sang `approved`. Sau khi được duyệt, nhờ
  `architect-doc` bổ sung vào `tech-defaults.md`.
- Không ghi secret, token, connection string hay dữ liệu cá nhân vào nhật ký.
