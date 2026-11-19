<?php
require 'config.php';

if (isset($_SESSION['user_id'])) {
    header("Location: " . ($_SESSION['role'] == 'admin' ? 'admin.php' : 'dashboard.php'));
    exit();
}

$message = "";

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['register'])) {
    $name = $conn->real_escape_string($_POST['name']);
    $email = $conn->real_escape_string($_POST['email']);
    $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
    $role = $_POST['role'];

    $sql = "INSERT INTO users (name, email, password, role) VALUES ('$name', '$email', '$password', '$role')";
    if ($conn->query($sql)) {
        $message = "Registration successful! Please login.";
    } else {
        $message = "Error: Email already exists.";
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['login'])) {
    $email = $conn->real_escape_string($_POST['email']);
    $password = $_POST['password'];

    $result = $conn->query("SELECT * FROM users WHERE email='$email'");
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        if (password_verify($password, $user['password'])) {
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['name'] = $user['name'];
            $_SESSION['role'] = $user['role'];
            header("Location: " . ($user['role'] == 'admin' ? 'admin.php' : 'dashboard.php'));
            exit();
        } else {
            $message = "Invalid password!";
        }
    } else {
        $message = "User not found!";
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CrowdSignal - Login</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="navbar">
        <h2>📡 CrowdSignal - Campus Issue Reporting</h2>
    </div>

    <div class="auth-container">
        <?php if($message) echo "<p style='color:red; margin-bottom:1rem; text-align:center;'>$message</p>"; ?>

        <form id="login-form" method="POST">
            <h2 style="margin-bottom: 1.5rem;">Login</h2>
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" required>
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit" name="login">Login</button>
            <p class="toggle-link" onclick="toggleAuth()">Don't have an account? Register</p>
        </form>

        <form id="register-form" method="POST" style="display: none;">
            <h2 style="margin-bottom: 1.5rem;">Register</h2>
            <div class="form-group">
                <label>Full Name</label>
                <input type="text" name="name" required>
            </div>
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" required>
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" required>
            </div>
            <div class="form-group">
                <label>Select Role</label>
                <select name="role">
                    <option value="user">Student / Faculty</option>
                    <option value="admin">Administrator</option>
                </select>
            </div>
            <button type="submit" name="register">Register</button>
            <p class="toggle-link" onclick="toggleAuth()">Already have an account? Login</p>
        </form>
    </div>
    <script src="script.js"></script>
</body>
</html>
