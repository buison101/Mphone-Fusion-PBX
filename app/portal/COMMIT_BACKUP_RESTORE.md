# Mphone Portal: commit, backup và khôi phục

Tài liệu này mô tả các thành phần cần lưu để có thể dựng lại Portal, ghi âm,
transcript và summary. Chỉ commit thư mục `/var/www/fusionpbx` là **chưa đủ**:
source nằm trong nhiều Git repository, còn dữ liệu và model nằm ngoài Git.

## 1. Phạm vi cần lưu

| Thành phần | Vị trí | Cách lưu |
|---|---|---|
| Portal và tích hợp FusionPBX | `/var/www/fusionpbx` | Git repository chính |
| Local Whisper | `app/transcribe` | Git repository lồng |
| Local language model | `app/language_model` | Git repository lồng |
| Transcript, summary, tags, notes và cấu hình Domain | PostgreSQL database `fusionpbx` | `pg_dump` |
| Whisper Small model | `/var/lib/mphone-whisper/models/faster-whisper-small` | Kho model/backup riêng, không Git |
| Qwen model | `/var/lib/mphone-llama/models/Qwen3-4B-Q4_K_M.gguf` | Kho model/backup riêng, không Git |
| Python virtual environment | `/opt/mphone-whisper` | Dựng lại từ `requirements.txt`, không backup vào Git |
| llama.cpp runtime | `/opt/mphone-llama` | Cài/dựng lại, không backup vào Git |
| Unit đang cài | `/etc/systemd/system/*.service` | Dựng lại từ template trong source |
| File ghi âm | đường dẫn ghi âm của FusionPBX/FreeSWITCH | Backup storage riêng nếu cần giữ audio |

Template service trong source:

- `app/transcribe/resources/service/mphone-whisper.service`
- `app/transcribe/resources/service/debian.service` (cài thành `transcribe_queue.service`)
- `app/language_model/resources/service/mphone-summary.service`
- `app/language_model/resources/service/mphone-summary-finalize.sh`

## 2. Thứ tự commit an toàn

`app/transcribe` và `app/language_model` là repository lồng (gitlink). Phải commit
và push chúng trước, sau đó repository chính mới lưu SHA mới của từng repo.

Không dùng `git add -A` tại repository chính vì máy đang có nhiều thay đổi thử
nghiệm không thuộc Portal.

### 2.1 Transcribe

```sh
cd /var/www/fusionpbx/app/transcribe
git status --short
git add .gitignore README.md app_config.php app_languages.php app_menu.php \
  resources/classes/transcribe_local.php \
  resources/classes/transcribe_queue_service.php \
  resources/jobs/process.php resources/local_whisper \
  resources/service/debian.service resources/service/mphone-whisper.service
git diff --cached --stat
git commit -m "Them pipeline phien am noi bo"
git push origin main
```

### 2.2 Language model

```sh
cd /var/www/fusionpbx/app/language_model
git status --short
git add README.md app_config.php app_languages.php app_menu.php \
  resources/classes/language_model.php \
  resources/classes/language_model_llama.php resources/service
git diff --cached --stat
git commit -m "Them tom tat cuoc goi noi bo"
git push origin main
```

Không tự động đưa thay đổi trong `app/device_logs` và `app/speech` vào hai commit
trên. Hai repo đó cần được kiểm tra nguồn gốc thay đổi riêng trước khi commit.

### 2.3 Repository FusionPBX chính

Các đường dẫn thuộc phạm vi Portal hiện tại:

```sh
cd /var/www/fusionpbx
git add app/portal \
  app/call_recordings/app_config.php \
  app/call_recordings/resources/classes/call_recordings.php \
  app/xml_cdr/app_config.php \
  app/transcribe app/language_model
git diff --cached --stat
git diff --cached --submodule=short
git commit -m "Trien khai Mphone Portal va AI cuoc goi"
git push origin develop
```

Trước khi commit, phải đọc `git diff --cached` và bảo đảm không có credential,
file ghi âm, database dump, model hoặc file runtime.

## 3. Backup dữ liệu

Nên backup toàn bộ database vì transcript/summary liên kết với CDR, Domain,
permission và các bảng Portal. Dump có thể chứa dữ liệu nhạy cảm nên không commit.

```sh
sudo install -d -m 0700 /var/backups/mphone
sudo -u postgres pg_dump --format=custom --file=/var/backups/mphone/fusionpbx.dump fusionpbx
sudo chmod 0600 /var/backups/mphone/fusionpbx.dump
```

Backup các unit đang cài để đối chiếu khi cần:

```sh
sudo cp -a /etc/systemd/system/mphone-whisper.service /var/backups/mphone/
sudo cp -a /etc/systemd/system/mphone-summary.service /var/backups/mphone/
sudo cp -a /etc/systemd/system/transcribe_queue.service /var/backups/mphone/
```

Nếu cần giữ file audio, backup thêm cây thư mục ghi âm đang được cấu hình trên
máy. Database chỉ lưu metadata/path, không chứa nội dung audio.

## 4. Model và checksum

Không đưa model vào Git. Chép chúng sang storage/backup riêng và kiểm tra SHA-256:

```text
Whisper model.bin
3e305921506d8872816023e4c273e75d2419fb89b24da97b4fe7bce14170d671

Whisper config.json
b55496ac7940a7ae47d2c01eab40edfd8701feec1229d9cce3b40014383fb828

Whisper tokenizer.json
fb7b63191e9bb045082c79fd742a3106a12c99513ab30df4a0d47fa6cb6fd0ab

Qwen3-4B-Q4_K_M.gguf
7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5
```

Kiểm tra lại sau khi sao chép bằng `sha256sum <file>`.

## 5. Khôi phục trên máy mới

Thứ tự đề xuất:

1. Clone repository chính và khởi tạo/checkout đúng SHA của các repo lồng.
2. Khôi phục PostgreSQL bằng `pg_restore` vào database FusionPBX phù hợp.
3. Khôi phục storage ghi âm nếu cần giữ audio cũ.
4. Đặt model đúng các đường dẫn trong mục 1 và xác minh checksum.
5. Tạo Python venv rồi cài `app/transcribe/resources/local_whisper/requirements.txt`.
6. Cài llama.cpp runtime vào `/opt/mphone-llama`.
7. Copy ba template unit vào `/etc/systemd/system`, chạy `systemctl daemon-reload`,
   rồi `systemctl enable --now` theo thứ tự Whisper, Summary, Transcribe Queue.
8. Chạy upgrade/schema của FusionPBX và kiểm tra quyền Portal theo Domain.
9. Thử một cuộc gọi ghi âm; xác nhận audio, transcript, summary, tag và note.

Ví dụ restore database (chỉ thực hiện trên database đích đã chuẩn bị):

```sh
sudo -u postgres pg_restore --dbname=fusionpbx --clean --if-exists /path/to/fusionpbx.dump
```

`--clean` thay thế object hiện có; không chạy trên database đang phục vụ nếu chưa
có kế hoạch downtime và backup xác nhận được.

