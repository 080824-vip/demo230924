#!/bin/bash

# Đọc tên miền từ file domain.txt
DOMAIN=$(cat domain.txt)

# Cài đặt các gói cần thiết
sudo apt update
sudo apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d apache2 php libapache2-mod-php php-mysql roundcube roundcube-core roundcube-mysql roundcube-plugins

# Cấu hình Postfix
sudo bash -c "cat > /etc/postfix/main.cf <<EOF
myhostname = $DOMAIN
mydomain = $DOMAIN
myorigin = /etc/mailname
inet_interfaces = all
inet_protocols = ipv4
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
EOF"

sudo systemctl restart postfix

# Cấu hình Dovecot
sudo bash -c "cat > /etc/dovecot/dovecot.conf <<EOF
mail_location = maildir:~/Maildir
service imap {
  protocol imap {
    mail_plugins = \$mail_plugins imap_quota
  }
}
service pop3 {
  protocol pop3 {
    mail_plugins = \$mail_plugins pop3_quota
  }
}
EOF"

sudo systemctl restart dovecot

# Tạo thư mục cho ứng dụng web
sudo mkdir -p /var/www/html/temp_email
sudo chown -R www-data:www-data /var/www/html/temp_email

# Tạo file index.php cho ứng dụng web
sudo bash -c "cat > /var/www/html/temp_email/index.php <<EOF
<?php
if (\$_SERVER['REQUEST_METHOD'] == 'POST') {
    \$email_prefix = bin2hex(random_bytes(5));
    \$email = \$email_prefix . '@$DOMAIN';
    shell_exec('sudo useradd -m -s /bin/false ' . escapeshellarg(\$email));
    echo 'Tài khoản email đã được tạo: <strong>' . htmlspecialchars(\$email) . '</strong>';
}
?>
<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='UTF-8'>
    <title>Tạo Email Ngẫu Nhiên</title>
</head>
<body>
    <h1>Tạo Email Ngẫu Nhiên</h1>
    <form method='post'>
        <input type='submit' value='Tạo Email'>
    </form>
</body>
</html>
EOF"

# Cấp quyền cho Apache chạy lệnh useradd mà không cần mật khẩu
echo "www-data ALL=(ALL) NOPASSWD: /usr/sbin/useradd" | sudo tee -a /etc/sudoers

# Khởi động lại Apache để áp dụng cấu hình mới
sudo systemctl restart apache2

echo "Cài đặt hoàn tất! Truy cập http://$DOMAIN/temp_email để tạo email ngẫu nhiên."


