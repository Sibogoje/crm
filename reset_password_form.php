<?php
session_start();
// Step 1: Email input form
if (!isset($_POST['step'])) {
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your Password</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f4f7f6;
            color: #333;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            background-color: #ffffff;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
            box-sizing: border-box;
        }
        h2 {
            text-align: center;
            color: #2c3e50;
            margin-bottom: 24px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #555;
        }
        input[type="email"],
        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
            transition: border-color 0.3s;
        }
        input[type="email"]:focus,
        input[type="text"]:focus,
        input[type="password"]:focus {
            border-color: #667eea;
            outline: none;
        }
        .btn {
            width: 100%;
            padding: 12px;
            border: none;
            border-radius: 4px;
            background: linear-gradient(to right, #667eea, #764ba2);
            color: white;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: opacity 0.3s;
        }
        .btn:hover {
            opacity: 0.9;
        }
        .message {
            text-align: center;
            padding: 10px;
            margin-top: 20px;
            border-radius: 4px;
        }
        .message.success {
            background-color: #d4edda;
            color: #155724;
        }
        .message.error {
            background-color: #f8d7da;
            color: #721c24;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Reset Your Password</h2>
        <form method="POST" action="reset_password_form.php">
            <input type="hidden" name="step" value="email">
            <div class="form-group">
                <label for="email">Enter your email address</label>
                <input type="email" id="email" name="email" required>
            </div>
            <button type="submit" class="btn">Send Code</button>
        </form>
    </div>
</body>
</html>
<?php
exit;
}

require_once 'backend/config/database.php';
require_once 'backend/classes/User.php';

function sendResetCodeEmail($email, $code) {
    $subject = 'EBS Your Password Reset Code';
    $message = "Your password reset code is: $code\n\nIf you did not request this, please ignore this email.";
    $headers = "From: sibandzesiboniso0@gmail.com\r\n" .
               "Reply-To: sibandzesiboniso0@gmail.com\r\n" .
               "X-Mailer: PHP/" . phpversion();
    if (mail($email, $subject, $message, $headers)) {
        echo '<div class="message success">A reset code has been sent to your email.</div>';
    } else {
        echo '<div class="message error">Failed to send email. Please check your mail server configuration.</div>';
    }
}

if (isset($_POST['step']) && $_POST['step'] === 'email') {
    $email = trim($_POST['email']);
    $database = new Database();
    $db = $database->getConnection();
    $user = new User($db);
    $user->email = $email;
    if ($user->emailExists()) {
        // Generate a 6-digit code
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        // Save code in DB
        $stmt = $db->prepare("UPDATE users SET reset_code = :code WHERE email = :email");
        $stmt->bindParam(':code', $code);
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        // Send code to email (demo: show on page)
        sendResetCodeEmail($email, $code);
        // Show code input form (styled)
        echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enter Reset Code</title>
    <style>' . file_get_contents(__FILE__, false, null, strpos(file_get_contents(__FILE__), '<style>'), strpos(file_get_contents(__FILE__), '</style>') - strpos(file_get_contents(__FILE__), '<style>') + 8) . '</style>
</head>
<body>
    <div class="container">
        <h2>Enter Reset Code</h2>
        <form method="POST" action="reset_password_form.php">
            <input type="hidden" name="step" value="code">
            <input type="hidden" name="email" value="' . htmlspecialchars($email) . '">
            <div class="form-group">
                <label for="code">Enter the code sent to your email</label>
                <input type="text" id="code" name="code" required maxlength="6">
            </div>
            <button type="submit" class="btn">Verify Code</button>
        </form>
    </div>
</body>
</html>';
        exit;
    } else {
        echo '<div class="message error">Email not found.</div>';
        exit;
    }
}

if (isset($_POST['step']) && $_POST['step'] === 'code') {
    $email = trim($_POST['email']);
    $code = trim($_POST['code']);
    $database = new Database();
    $db = $database->getConnection();
    $stmt = $db->prepare("SELECT id FROM users WHERE email = :email AND reset_code = :code");
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':code', $code);
    $stmt->execute();
    if ($stmt->rowCount() > 0) {
        // Show new password form (styled)
        echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Set New Password</title>
    <style>' . file_get_contents(__FILE__, false, null, strpos(file_get_contents(__FILE__), '<style>'), strpos(file_get_contents(__FILE__), '</style>') - strpos(file_get_contents(__FILE__), '<style>') + 8) . '</style>
</head>
<body>
    <div class="container">
        <h2>Set New Password</h2>
        <form method="POST" action="reset_password_form.php">
            <input type="hidden" name="step" value="reset">
            <input type="hidden" name="email" value="' . htmlspecialchars($email) . '">
            <div class="form-group">
                <label for="password">New Password</label>
                <input type="password" id="password" name="password" required minlength="6">
            </div>
            <div class="form-group">
                <label for="confirm_password">Confirm New Password</label>
                <input type="password" id="confirm_password" name="confirm_password" required minlength="6">
            </div>
            <button type="submit" class="btn">Reset Password</button>
        </form>
    </div>
</body>
</html>';
        exit;
    } else {
        echo '<div class="message error">Invalid code. Please try again.</div>';
        exit;
    }
}

if (isset($_POST['step']) && $_POST['step'] === 'reset') {
    $email = trim($_POST['email']);
    $password = $_POST['password'];
    $confirm_password = $_POST['confirm_password'];
    if ($password !== $confirm_password) {
        echo '<div class="message error">Passwords do not match.</div>';
        exit;
    }
    if (strlen($password) < 6) {
        echo '<div class="message error">Password must be at least 6 characters.</div>';
        exit;
    }
    $database = new Database();
    $db = $database->getConnection();
    $password_hash = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $db->prepare("UPDATE users SET password = :password_hash, reset_code = NULL WHERE email = :email");
    $stmt->bindParam(':password_hash', $password_hash);
    $stmt->bindParam(':email', $email);
    if ($stmt->execute()) {
        echo '<div class="message success">Your password has been reset successfully!</div>';
        exit;
    } else {
        echo '<div class="message error">Error updating password. Please try again.</div>';
        exit;
    }
}
