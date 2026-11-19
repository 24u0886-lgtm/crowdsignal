#!/bin/bash

# Create uploads folder and fix permissions
mkdir -p uploads
chmod -R 777 uploads

# 1. db.sql
cat << 'EOPHP' > db.sql
CREATE DATABASE IF NOT EXISTS crowdsignal_db;
USE crowdsignal_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS issues (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    location VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    image_path VARCHAR(255) DEFAULT NULL,
    department VARCHAR(50) DEFAULT 'Unassigned',
    status ENUM('Pending', 'In Progress', 'Resolved') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
EOPHP

# 2. config.php
cat << 'EOPHP' > config.php
<?php
session_start();
$host = "localhost";
$user = "root";
$pass = "";
$dbname = "crowdsignal_db";

$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
EOPHP

# 3. style.css
cat << 'EOPHP' > style.css
:root {
    --primary: #2563eb;
    --secondary: #1e40af;
    --bg: #f3f4f6;
    --white: #ffffff;
    --text: #1f2937;
    --pending: #ef4444;
    --progress: #f59e0b;
    --resolved: #10b981;
}

* { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
body { background-color: var(--bg); color: var(--text); }

.navbar { background: var(--primary); color: var(--white); padding: 1rem 2rem; display: flex; justify-content: space-between; align-items: center; }
.navbar a { color: var(--white); text-decoration: none; background: var(--secondary); padding: 0.5rem 1rem; border-radius: 5px; }

.container { max-width: 1200px; margin: 2rem auto; padding: 0 1rem; }
.auth-container { max-width: 400px; margin: 5rem auto; background: var(--white); padding: 2rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
.card { background: var(--white); padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); margin-bottom: 2rem; }

.form-group { margin-bottom: 1rem; }
.form-group label { display: block; margin-bottom: 0.5rem; font-weight: bold; }
.form-group input, .form-group select, .form-group textarea { width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 5px; }
button { background: var(--primary); color: var(--white); border: none; padding: 0.75rem 1.5rem; border-radius: 5px; cursor: pointer; font-size: 1rem; width: 100%; }
button:hover { background: var(--secondary); }

.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-bottom: 2rem; }
.stat-card { background: var(--white); padding: 1.5rem; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
.stat-card h3 { font-size: 2rem; color: var(--primary); }

table { width: 100%; border-collapse: collapse; background: var(--white); border-radius: 8px; overflow: hidden; }
th, td { padding: 1rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
th { background: #f9fafb; font-weight: bold; }

.badge { padding: 0.25rem 0.75rem; border-radius: 20px; color: var(--white); font-size: 0.85rem; font-weight: bold; }
.status-Pending { background: var(--pending); }
.status-In-Progress { background: var(--progress); }
.status-Resolved { background: var(--resolved); }

.issue-img { width: 80px; height: 60px; object-fit: cover; border-radius: 4px; cursor: pointer; }
.toggle-link { text-align: center; margin-top: 1rem; cursor: pointer; color: var(--primary); }
EOPHP

# 4. script.js
cat << 'EOPHP' > script.js
function toggleAuth() {
    const loginForm = document.getElementById('login-form');
    const regForm = document.getElementById('register-form');
    if (loginForm.style.display === 'none') {
        loginForm.style.display = 'block';
        regForm.style.display = 'none';
    } else {
        loginForm.style.display = 'none';
        regForm.style.display = 'block';
    }
}

function previewImage(event) {
    const reader = new FileReader();
    reader.onload = function(){
        const output = document.getElementById('img-preview');
        output.src = reader.result;
        output.style.display = 'block';
    };
    reader.readAsDataURL(event.target.files[0]);
}
EOPHP

# 5. index.php
cat << 'EOPHP' > index.php
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
EOPHP

# 6. dashboard.php
cat << 'EOPHP' > dashboard.php
<?php
require 'config.php';
if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'user') {
    header("Location: index.php");
    exit();
}

$user_id = $_SESSION['user_id'];
$msg = "";

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['submit_issue'])) {
    $title = $conn->real_escape_string($_POST['title']);
    $category = $conn->real_escape_string($_POST['category']);
    $location = $conn->real_escape_string($_POST['location']);
    $description = $conn->real_escape_string($_POST['description']);
    
    $image_path = "";
    if (!empty($_FILES['image']['name'])) {
        $target_dir = "uploads/";
        $image_path = $target_dir . time() . "_" . basename($_FILES["image"]["name"]);
        move_uploaded_file($_FILES["image"]["tmp_name"], $image_path);
    }

    $sql = "INSERT INTO issues (user_id, title, category, location, description, image_path) 
            VALUES ('$user_id', '$title', '$category', '$location', '$description', '$image_path')";
    
    if ($conn->query($sql)) {
        $msg = "Issue reported successfully!";
    } else {
        $msg = "Error reporting issue.";
    }
}

$issues = $conn->query("SELECT * FROM issues WHERE user_id='$user_id' ORDER BY created_at DESC");
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User Dashboard - CrowdSignal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="navbar">
        <h2>📡 CrowdSignal</h2>
        <div>
            <span style="margin-right: 1rem;">Welcome, <?php echo $_SESSION['name']; ?></span>
            <a href="logout.php">Logout</a>
        </div>
    </div>

    <div class="container">
        <div class="card">
            <h3 style="margin-bottom: 1rem;">Report a Campus Issue</h3>
            <?php if($msg) echo "<p style='color:green; margin-bottom:1rem;'>$msg</p>"; ?>
            <form method="POST" enctype="multipart/form-data">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                    <div class="form-group">
                        <label>Issue Title</label>
                        <input type="text" name="title" placeholder="e.g., Projector not working" required>
                    </div>
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category" required>
                            <option value="Electrical">Electrical</option>
                            <option value="IT / Projector">IT / Projector</option>
                            <option value="Plumbing / Water">Plumbing / Water</option>
                            <option value="Lab Equipment">Lab Equipment</option>
                            <option value="Furniture / Civil">Furniture / Civil</option>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label>Exact Location</label>
                    <input type="text" name="location" placeholder="e.g., Block B, Room 204" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3" placeholder="Describe the problem in detail..." required></textarea>
                </div>
                <div class="form-group">
                    <label>Upload Photo (Optional)</label>
                    <input type="file" name="image" accept="image/*" onchange="previewImage(event)">
                    <img id="img-preview" style="display:none; width: 100px; margin-top: 10px; border-radius: 5px;">
                </div>
                <button type="submit" name="submit_issue" style="width: auto;">Submit Report</button>
            </form>
        </div>

        <h3>My Reported Issues</h3>
        <table style="margin-top: 1rem;">
            <thead>
                <tr>
                    <th>Image</th>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Location</th>
                    <th>Assigned Dept.</th>
                    <th>Status</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                <?php while($row = $issues->fetch_assoc()): ?>
                <tr>
                    <td>
                        <?php if($row['image_path']): ?>
                            <a href="<?php echo $row['image_path']; ?>" target="_blank">
                                <img src="<?php echo $row['image_path']; ?>" class="issue-img">
                            </a>
                        <?php else: ?> No Image <?php endif; ?>
                    </td>
                    <td><strong><?php echo $row['title']; ?></strong><br><small><?php echo $row['description']; ?></small></td>
                    <td><?php echo $row['category']; ?></td>
                    <td><?php echo $row['location']; ?></td>
                    <td><?php echo $row['department']; ?></td>
                    <td>
                        <?php $statusClass = str_replace(' ', '-', $row['status']); ?>
                        <span class="badge status-<?php echo $statusClass; ?>"><?php echo $row['status']; ?></span>
                    </td>
                    <td><?php echo date('d M Y', strtotime($row['created_at'])); ?></td>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
    <script src="script.js"></script>
</body>
</html>
EOPHP

# 7. admin.php
cat << 'EOPHP' > admin.php
<?php
require 'config.php';
if (!isset($_SESSION['user_id']) || $_SESSION['role'] != 'admin') {
    header("Location: index.php");
    exit();
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['update_issue'])) {
    $issue_id = $_POST['issue_id'];
    $department = $_POST['department'];
    $status = $_POST['status'];

    $conn->query("UPDATE issues SET department='$department', status='$status' WHERE id='$issue_id'");
}

$total = $conn->query("SELECT COUNT(*) as count FROM issues")->fetch_assoc()['count'];
$pending = $conn->query("SELECT COUNT(*) as count FROM issues WHERE status='Pending'")->fetch_assoc()['count'];
$progress = $conn->query("SELECT COUNT(*) as count FROM issues WHERE status='In Progress'")->fetch_assoc()['count'];
$resolved = $conn->query("SELECT COUNT(*) as count FROM issues WHERE status='Resolved'")->fetch_assoc()['count'];

$issues = $conn->query("SELECT issues.*, users.name as reporter FROM issues JOIN users ON issues.user_id = users.id ORDER BY created_at DESC");
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard - CrowdSignal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="navbar">
        <h2>📡 CrowdSignal - Admin Portal</h2>
        <div>
            <span style="margin-right: 1rem;">Admin: <?php echo $_SESSION['name']; ?></span>
            <a href="logout.php">Logout</a>
        </div>
    </div>

    <div class="container">
        <div class="stats-grid">
            <div class="stat-card"><h3><?php echo $total; ?></h3><p>Total Issues</p></div>
            <div class="stat-card"><h3 style="color: var(--pending);"><?php echo $pending; ?></h3><p>Pending</p></div>
            <div class="stat-card"><h3 style="color: var(--progress);"><?php echo $progress; ?></h3><p>In Progress</p></div>
            <div class="stat-card"><h3 style="color: var(--resolved);"><?php echo $resolved; ?></h3><p>Resolved</p></div>
        </div>

        <h3>All Campus Complaints</h3>
        <table style="margin-top: 1rem;">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Photo</th>
                    <th>Issue Details</th>
                    <th>Reporter & Location</th>
                    <th>Current Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <?php while($row = $issues->fetch_assoc()): ?>
                <tr>
                    <td>#<?php echo $row['id']; ?></td>
                    <td>
                        <?php if($row['image_path']): ?>
                            <a href="<?php echo $row['image_path']; ?>" target="_blank">
                                <img src="<?php echo $row['image_path']; ?>" class="issue-img">
                            </a>
                        <?php else: ?> N/A <?php endif; ?>
                    </td>
                    <td>
                        <strong><?php echo $row['title']; ?></strong> <span style="color:gray;">(<?php echo $row['category']; ?>)</span>
                        <p style="font-size: 0.9rem; margin-top: 5px;"><?php echo $row['description']; ?></p>
                    </td>
                    <td>
                        <strong>By:</strong> <?php echo $row['reporter']; ?><br>
                        <strong>Loc:</strong> <?php echo $row['location']; ?><br>
                        <small style="color:gray;"><?php echo date('d M Y, h:i A', strtotime($row['created_at'])); ?></small>
                    </td>
                    <td>
                        <?php $statusClass = str_replace(' ', '-', $row['status']); ?>
                        <span class="badge status-<?php echo $statusClass; ?>"><?php echo $row['status']; ?></span><br>
                        <small style="display:block; margin-top:5px;"><strong>Dept:</strong> <?php echo $row['department']; ?></small>
                    </td>
                    <td>
                        <form method="POST" style="display: flex; gap: 5px; flex-direction: column;">
                            <input type="hidden" name="issue_id" value="<?php echo $row['id']; ?>">
                            
                            <select name="department" style="padding: 5px;">
                                <option value="Unassigned" <?php if($row['department']=='Unassigned') echo 'selected'; ?>>Assign Dept...</option>
                                <option value="IT Support" <?php if($row['department']=='IT Support') echo 'selected'; ?>>IT Support</option>
                                <option value="Electrical Maintenance" <?php if($row['department']=='Electrical Maintenance') echo 'selected'; ?>>Electrical</option>
                                <option value="Plumbing" <?php if($row['department']=='Plumbing') echo 'selected'; ?>>Plumbing</option>
                                <option value="Civil / Housekeeping" <?php if($row['department']=='Civil / Housekeeping') echo 'selected'; ?>>Civil / Housekeeping</option>
                            </select>

                            <select name="status" style="padding: 5px;">
                                <option value="Pending" <?php if($row['status']=='Pending') echo 'selected'; ?>>Pending</option>
                                <option value="In Progress" <?php if($row['status']=='In Progress') echo 'selected'; ?>>In Progress</option>
                                <option value="Resolved" <?php if($row['status']=='Resolved') echo 'selected'; ?>>Resolved</option>
                            </select>

                            <button type="submit" name="update_issue" style="padding: 5px; font-size: 0.85rem;">Update</button>
                        </form>
                    </td>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
EOPHP

# 8. logout.php
cat << 'EOPHP' > logout.php
<?php
session_start();
session_unset();
session_destroy();
header("Location: index.php");
exit();
?>
EOPHP

echo "🎉 All project files created successfully!"
