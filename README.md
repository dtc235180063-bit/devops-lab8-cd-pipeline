# Lab 8: Phát hành Liên tục (CD) — Docker & Jenkins CD Pipeline

[![CD Pipeline](https://img.shields.io/badge/Jenkins%20CD-6%20Stages%20SUCCESS-brightgreen)](http://localhost:8080/job/DevOps-Lab8-CD-Pipeline/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage%20186MB-2496ED?logo=docker&logoColor=white)](./Dockerfile)
[![Nexus Registry](https://img.shields.io/badge/Nexus%20Docker%20Registry-localhost%3A8082-228B22)](http://localhost:8081/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-3%20Services-2496ED?logo=docker&logoColor=white)](./docker-compose.yml)
[![Node.js](https://img.shields.io/badge/Node.js-18--alpine-339933?logo=nodedotjs&logoColor=white)](./app/package.json)

> **Học phần:** Vận hành và Bảo trì Phần mềm (DevOps - 2026)  
> **Chuẩn đầu ra (CDR):** CDR 8.2 (Đóng gói Docker image) + CDR 8.3 (Triển khai CD với Jenkins)  
> **Sinh viên thực hiện:** Nguyễn Văn Hải — **MSSV:** `DTC235180063` — **Lớp:** `KTPMK22C` (ICTU)

---

## 1. Mục tiêu Bài thực hành
1. Viết `Dockerfile` áp dụng **multi-stage build**, tối ưu dung lượng image và chạy dưới non-root user (`appuser`) kèm `HEALTHCHECK`.
2. Sử dụng **Docker Compose** triển khai ứng dụng đa container (`app` Node.js + `redis` Cache + `nginx` Reverse Proxy).
3. Đẩy (push) và kéo (pull) Docker image qua **Sonatype Nexus Docker Registry** (`localhost:8082`, kế thừa từ Lab 7 — Bài tập mở rộng #4 thay thế Docker Hub).
4. Xây dựng **Jenkins CD Pipeline** 6 stages tự động: `Checkout` → `Docker Build` → `Docker Scan` → `Push to Registry` → `Deploy Container` → `Verify Deploy`.
5. Phân biệt rõ **CI (Bài 7)** vs **CD (Bài 8)** và thiết kế mẫu pipeline kết hợp CI+CD (`Jenkinsfile.cicd`).

---

## 2. Cấu trúc Dự án

```text
lab8/
├── app/
│   ├── package.json                       # Khai báo Express ^4.21.0
│   └── server.js                          # API "/" và "/health" trên cổng 3000
├── Dockerfile                             # Multi-stage build tối ưu (186MB)
├── Dockerfile.fat                         # Single-stage để so sánh dung lượng (196MB)
├── .dockerignore
├── docker-compose.yml                     # Stack 3 containers: app, redis, nginx
├── nginx.conf                             # Reverse proxy cổng 80 -> app:3000
├── Jenkinsfile                            # CD Pipeline 6 stages (mặc định Nexus localhost:8082, hỗ trợ Docker Hub)
├── Jenkinsfile.cicd                       # Bonus Bước 5.3: Pipeline kết hợp CI + CD
├── scripts/
│   ├── setup.ps1 / setup.sh               # Kiểm tra Docker, Compose, Node, Jenkins
│   ├── verify.ps1 / verify.sh             # Kiểm tra tiêu chí hoàn thành Lab 8
│   └── cleanup.ps1 / cleanup.sh           # Dọn dẹp containers & stack Lab 8
├── screenshots/                           # Ảnh minh chứng thực tế
├── ho_ten_mssv.txt                        # Báo cáo nộp bài
└── README.md
```

---

## 3. Kết quả Thực thi Thực tế

### Bước 1: Build & So sánh Docker Image (Multi-stage vs Non-multi-stage)
| Tag Image | Chiến lược Dockerfile | Disk Usage | Content Size | Ghi chú |
|---|---|---|---|---|
| `devops-lab8-app:1.0` | Multi-stage (`Dockerfile`) | **186 MB** | **45.6 MB** | `npm install --production`, user `appuser` (1001), có `HEALTHCHECK` |
| `devops-lab8-app:fat` | Single-stage (`Dockerfile.fat`) | **196 MB** | **47.4 MB** | `npm install` đầy đủ, chạy root |

Kiểm tra container đơn lẻ `lab8-app` trên cổng `3000`:
- `GET http://localhost:3000/` → `{"message":"🚀 DevOps Lab 8 — CD Pipeline","version":"2.0.0",...}`
- `GET http://localhost:3000/health` → `{"status":"OK","uptime":...}`

### Bước 2: Docker Compose (App + Redis + Nginx)
3 container khởi động thành công trong bridge network `app-network`:
- `lab8-redis` (`redis:7-alpine`, port `6379`)
- `lab8-app` (`devops-lab8-app:latest`, port `3000`, trạng thái `healthy`)
- `lab8-nginx` (`nginx:alpine`, port `80`, `depends_on` điều kiện `service_healthy`)

Kiểm tra qua Nginx Reverse Proxy (`http://localhost/` và `http://localhost/health`) trả về JSON hợp lệ.

### Bước 3: Private Docker Registry với Sonatype Nexus (`localhost:8082`)
Thay thế Docker Hub bằng **Nexus Docker Hosted Registry** trên container `lab7-nexus` (Bài tập mở rộng #4):
- Tạo repository `docker-hosted` (format `docker`, HTTP connector port `8082`, bật realm `DockerToken`).
- `docker login localhost:8082 -u admin` → `Login Succeeded`.
- `docker push localhost:8082/devops-lab8-app:1.0` & `:latest` → Thành công.
- Kiểm tra Nexus REST API (`http://localhost:8081/service/rest/v1/components?repository=docker-hosted`) ghi nhận image `devops-lab8-app` (tags `1.0`, `4`, `latest`).
- Xóa ảnh local và `docker pull localhost:8082/devops-lab8-app:1.0`, chạy container `lab8-test-pull` trên cổng `3001` thành công.

### Bước 4: Jenkins CD Pipeline (`DevOps-Lab8-CD-Pipeline`)
- Cấu hình Docker CLI (`docker-ce-cli`) và cấp quyền `/var/run/docker.sock` trong container `lab7-jenkins` (`http://localhost:8080`).
- Thêm credential `nexus-docker-credentials` (`admin` / `admin123`) trên Jenkins.
- Job `DevOps-Lab8-CD-Pipeline` Build `#4` đạt trạng thái **`SUCCESS`** (tổng thời gian **15,524 ms**):
  1. `Checkout` — Clone từ Git SCM commit `9d08c20`
  2. `Docker Build` — Build `localhost:8082/devops-lab8-app:4` & `:latest`
  3. `Docker Scan` — Kiểm tra `docker scout quickview` (fallback an toàn)
  4. `Push to Registry` — `docker login localhost:8082` + push tag `:4` & `:latest` lên Nexus
  5. `Deploy Container` — Khởi chạy `lab8-cd-production` trên cổng `3002:3000`
  6. `Verify Deploy` — Gọi `curl -f http://host.docker.internal:3002/health` & `/` thành công

> **Ghi chú nếu muốn dùng Docker Hub sau này:**  
> Chỉ cần thêm credential `docker-hub-credentials_1` trên Jenkins và chạy **Build with Parameters** với `DOCKER_REGISTRY=""`, `DOCKER_USER=<username>`, `CREDENTIALS_ID=docker-hub-credentials_1`.

---

## 4. Bước 5: So sánh CI (Bài 7) vs CD (Bài 8)

| Tiêu chí | CI — Continuous Integration (Bài 7) | CD — Continuous Delivery/Deployment (Bài 8) |
|---|---|---|
| **Mục đích** | Kiểm tra code có lỗi không (compile, test, SAST) | Đưa code đã đóng gói đến môi trường chạy / người dùng |
| **Output** | File `.jar` / artifact trên Nexus | Docker image trên Registry & Container đang chạy |
| **Công cụ** | Jenkins, Maven, JUnit 5, SonarQube, Nexus | Docker, Docker Compose, Nginx, Nexus Docker Registry, Jenkins |
| **Câu hỏi trả lời** | "An toàn để merge?" | "Sẵn sàng production?" |
| **Tần suất** | Mỗi commit | Mỗi lần CI pass |
| **Thất bại nghĩa là** | Code có bug / không đạt Quality Gate | Đóng gói hoặc deployment bị lỗi |

---

## 5. Hướng dẫn Kiểm tra, Dọn dẹp & Push lên GitHub

```powershell
# Kiểm tra các tiêu chí dự án
.\scripts\verify.ps1

# Dọn dẹp toàn bộ container Lab 8 (Bước 6)
.\scripts\cleanup.ps1

# Tạo repo trống trên GitHub (ví dụ: devops-lab8-cd-pipeline), rồi đẩy lên Git:
git remote set-url origin https://github.com/dtc235180063-bit/devops-lab8-cd-pipeline.git
git push -u origin main
```
