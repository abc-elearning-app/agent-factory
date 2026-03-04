# 🤖 Agent Factory

> Tự động tạo AI agent từ mô tả tự nhiên — chạy ngay, cải tiến qua feedback loop.

**Standalone tool** — hoạt động trên bất kỳ project nào, không cần CCPM hay framework khác.

## Quick Start

### 1. Cài đặt

```bash
# Copy workflow vào project của bạn
./install.sh

# Hoặc thủ công:
mkdir -p .agent/workflows/
cp agent-factory.md .agent/workflows/
```

### 2. Sử dụng

3 lệnh chính — dùng trên Claude Code, Gemini CLI, hoặc Antigravity:

| Lệnh | Mục đích |
|------|----------|
| `/agent-factory "..."` | Tạo agent mới từ mô tả |
| `/agent-shared` | Duyệt, cài và đẩy agent lên kho chung |
| `/run-agent` | Chạy nhanh agent đã có trên máy |

#### `/agent-factory` — Tạo agent mới

```
/agent-factory "thu thập tiêu đề và URL bài viết từ một trang web"
/agent-factory "review code Python và đưa ra gợi ý cải thiện"
/agent-factory "tổng hợp các key points từ một tài liệu dài"
```

Tool sẽ:
1. 🔍 Phân tích mô tả → xác định loại agent
2. 🏗️ Generate agent definition (YAML + system prompt)
3. 🚀 Chạy agent ngay lập tức
4. 🔄 Hỏi feedback → cải tiến → chạy lại (refinement loop)
5. 📤 Hỏi có muốn share lên kho chung không

Agent file được lưu tại `./agents/<name>.md` — sẵn sàng dùng lại.

#### `/agent-shared` — Kho agent dùng chung

Menu-driven, chọn số để thao tác:

```
1. 📂 Browse  — Xem agents theo nhóm (dev, qa, ops, data, content, marketing, general)
2. 📥 Install — Cài agent vào project hiện tại
3. 🔍 Search  — Tìm agent theo từ khoá
4. 📤 Push    — Đẩy agent của bạn lên kho chung (tạo PR tự động)
```

Kho chung: [`abc-elearning-app/agents-shared`](https://github.com/abc-elearning-app/agents-shared). Auto-clone lần đầu, silent pull mỗi lần mở.

> **Lưu ý:** Agent push lên qua PR — phải được admin review và merge vào `main` thì mới available cho team.

#### `/run-agent` — Chạy agent nhanh

Liệt kê agents trên máy, filter theo từ khoá, chọn số, nhập task và spawn ngay:

```
🤖 Agents trên máy — .claude/agents/ (12 agents)

#    Type  Name                    Description
1.   🟢    hanoi-weather-forecast  Thu thập dự báo thời tiết Hà Nội
2.   🔴    code-analyzer           Phân tích code changes tìm bugs
...

Gõ số để chọn, hoặc tìm kiếm: ___
```

## Agent Types

| Type | Color | Use Case |
|------|-------|----------|
| 🔵 Strategic | blue | Research, planning, analysis |
| 🟢 Implementation | green | Code writing, data collection |
| 🔴 Quality | red | Testing, review, audit |
| 🟣 Coordination | purple | Orchestration, workflow management |

Type được auto-detect từ mô tả — hỗ trợ cả tiếng Anh và tiếng Việt.

## Tool Safety

Agent Factory áp dụng hệ thống 3-tier bảo vệ:

| Tier | Tools | Hành vi |
|------|-------|---------|
| ✅ Safe | Read, Glob, Grep, WebFetch, WebSearch | Auto-enable |
| ⚠️ Cautious | Write, Edit | Enable + cảnh báo |
| 🔒 Restricted | Bash, Task, Agent | Phải hỏi user |

## Agent Directory

Tool tự động detect agent directory theo thứ tự:
1. `./agents/` (default)
2. `.claude/agents/` (CCPM projects)
3. `.agent/agents/` (Antigravity projects)

## Examples

Xem thư mục [`examples/`](examples/) để tham khảo 3 agent mẫu:
- `web-scraper.md` — Thu thập dữ liệu từ web
- `code-reviewer.md` — Review code tìm bugs & anti-patterns
- `data-analyzer.md` — Phân tích dữ liệu có cấu trúc

## Hướng dẫn cho người mới (không cần biết code)

### Terminal là gì?

Terminal (hay Command Line) là ứng dụng cho phép bạn gõ lệnh để điều khiển máy tính bằng text, thay vì click chuột.

### Cách mở Terminal

**Mac:**
- Cách 1: Nhấn `Cmd + Space`, gõ **Terminal**, nhấn Enter
- Cách 2: Mở **Finder** → **Applications** → **Utilities** → **Terminal**

**Windows:**
- Cách 1: Nhấn `Win + R`, gõ **cmd**, nhấn Enter
- Cách 2: Nhấn `Win`, gõ **Command Prompt** hoặc **PowerShell**, nhấn Enter

**Linux:**
- Nhấn `Ctrl + Alt + T`

### Các lệnh cơ bản cần biết

| Lệnh | Ý nghĩa | Ví dụ |
|-------|----------|-------|
| `cd <thư_mục>` | Di chuyển vào thư mục | `cd Desktop` |
| `cd ..` | Quay lại thư mục cha | |
| `ls` (Mac/Linux) hoặc `dir` (Windows) | Xem danh sách file trong thư mục hiện tại | |
| `pwd` | Xem đang ở thư mục nào | |

### Cài đặt từng bước

**Bước 1: Cài Claude Code (nếu chưa có)**

Mở Terminal, chạy lệnh:

```bash
npm install -g @anthropic-ai/claude-code
```

> Nếu báo lỗi `npm: command not found`, bạn cần cài Node.js trước tại https://nodejs.org (chọn bản LTS, tải về và cài như app bình thường).

**Bước 2: Di chuyển vào thư mục project của bạn**

```bash
cd đường/dẫn/tới/project
```

Ví dụ nếu project nằm trên Desktop:

```bash
cd ~/Desktop/my-project
```

> **Mẹo:** Trên Mac, bạn có thể gõ `cd ` (có dấu cách) rồi kéo thả thư mục từ Finder vào Terminal — nó sẽ tự điền đường dẫn.

**Bước 3: Tải code Agent Factory về máy**

Có 2 cách:

**Cách 1: Dùng `git clone` (khuyến khích)**

```bash
git clone https://github.com/abc-elearning-app/agent-factory.git
```

Lệnh này sẽ tạo thư mục `agent-factory/` chứa toàn bộ code. Sau này muốn cập nhật phiên bản mới, chỉ cần:

```bash
cd agent-factory
git pull
```

> Nếu báo `command not found: git`, bạn cần cài Git trước:
> - **Mac:** Mở Terminal, chạy `xcode-select --install`, nhấn Install trong popup
> - **Windows:** Tải từ https://git-scm.com → cài như app bình thường → **khởi động lại Terminal**

**Cách 2: Tải file ZIP (không cần cài Git)**

1. Mở trình duyệt, vào https://github.com/abc-elearning-app/agent-factory
2. Nhấn nút **Code** (màu xanh) → chọn **Download ZIP**
3. Giải nén file ZIP ra thư mục tuỳ ý (ví dụ Desktop)

> Lưu ý: Cách này không hỗ trợ `git pull` để cập nhật — mỗi lần muốn cập nhật bạn phải tải ZIP lại.

**Bước 4: Chạy script cài đặt**

```bash
cd agent-factory
./install.sh
```

> Nếu báo `Permission denied`, chạy: `chmod +x install.sh` rồi thử lại.

**Bước 5: Quay lại project và mở Claude Code**

```bash
cd ~/Desktop/my-project
claude
```

**Bước 6: Dùng Agent Factory**

Trong giao diện Claude Code, gõ:

```
/agent-factory "mô tả agent bạn muốn tạo"
```

Ví dụ:

```
/agent-factory "thu thập tiêu đề bài viết từ VnExpress"
```

### Minh hoạ toàn bộ quy trình

```
[Mở Terminal]
                    ↓
cd ~/Desktop/my-project        ← vào thư mục project
                    ↓
claude                         ← mở Claude Code
                    ↓
/agent-factory "..."           ← tạo agent
                    ↓
Xem kết quả → gõ feedback → agent tự cải tiến
                    ↓
/run-agent                     ← chạy lại agent đã tạo
```

### Gặp lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|----------|
| `command not found: claude` | Chưa cài Claude Code | Chạy `npm install -g @anthropic-ai/claude-code` |
| `command not found: npm` | Chưa cài Node.js | Tải từ https://nodejs.org |
| `command not found: git` | Chưa cài Git | Mac: chạy `xcode-select --install`. Windows: tải từ https://git-scm.com |
| `Permission denied` | File chưa có quyền chạy | Chạy `chmod +x install.sh` |
| `No such file or directory` | Sai đường dẫn thư mục | Kiểm tra lại bằng `ls` và `pwd` |

## License

MIT
