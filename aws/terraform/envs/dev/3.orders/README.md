# Service: 3. Orders

Đây là service xử lý đơn hàng bất đồng bộ sau khi thanh toán thành công qua Stripe.

## Sơ đồ Kiến trúc

...Updating

## Luồng Hoạt động

1.  **Stripe Webhook**: Stripe gửi một sự kiện `checkout.session.completed` đến API Gateway.
2.  **API Gateway**: Trigger Lambda `webhook_validator`.
3.  **Lambda `webhook_validator`**:
    *   Xác thực chữ ký của webhook để đảm bảo request đến từ Stripe.
    *   Lấy webhook secret từ AWS Secrets Manager.
    *   Nếu hợp lệ, đẩy toàn bộ payload của đơn hàng vào SNS Topic `orders`.
4.  **SNS Topic `orders`**: Phân phối message đến tất cả các SQS queue đã đăng ký.
5.  **SQS Queues**:
    *   `email-queue`: Hàng đợi cho tác vụ gửi email.
    *   `db-update-queue`: Hàng đợi cho tác vụ cập nhật cơ sở dữ liệu.
    *   *(Có thể mở rộng thêm các queue khác như `inventory-queue`)*.
6.  **Lambdas Xử lý**:
    *   `email_processor`: Được trigger bởi `email-queue`, gửi email xác nhận đơn hàng cho khách hàng qua SES.
    *   `db_update_processor`: Được trigger bởi `db-update-queue`, lưu thông tin chi tiết đơn hàng vào bảng DynamoDB `orders`.
7.  **Dead-Letter Queues (DLQ)**: Mỗi SQS queue chính được cấu hình với một DLQ. Nếu một message không thể được xử lý thành công sau một số lần thử nhất định, nó sẽ được chuyển vào DLQ để phân tích và xử lý thủ công.

## Triển khai

### Yêu cầu
*   Terraform `~> 1.3.9`
*   Cấu hình AWS credentials cho môi trường `dev`.
*   Tạo một secret trong AWS Secrets Manager với tên `my-stripe-system/dev/stripe`. Secret này phải chứa một key là `webhook_secret` với giá trị là signing secret từ Stripe Webhook của bạn.

### Các bước
1.  Di chuyển vào thư mục của service:
    ```bash
    cd aws/terraform/envs/dev/3.orders
    ```
2.  Khởi tạo Terraform:
    ```bash
    terraform init
    ```
3.  Xem kế hoạch triển khai:
    ```bash
    terraform plan
    ```
4.  Áp dụng các thay đổi:
    ```bash
    terraform apply
    ```

### Outputs
*   `api_gateway_invoke_url`: Endpoint của API Gateway. Bạn cần cung cấp URL này (`${api_gateway_invoke_url}/webhook`) cho Stripe để cấu hình webhook.
